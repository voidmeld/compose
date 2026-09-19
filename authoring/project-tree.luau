--!strict

local Diagnostics = require "./diagnostics"
local Digest = require "./digest"

export type Scalar = string | number | boolean

export type RojoValue = Diagnostics.RojoValue

export type Mount = {
	at: { string },
	name: string,
	path: string?,
	className: string?,
	properties: { [string]: RojoValue }?,
	attributes: { [string]: RojoValue }?,
	ignoreUnknownInstances: boolean?,
	siblings: { string }?,
	requires: { string }?,
	replace: boolean?,
}

export type ExcludeAt = {
	at: { string },
	name: string,
}

export type Variant = {
	name: string,
	excludeExact: { string }?,
	excludePrefixes: { string }?,
	excludeSuffixes: { string }?,
	excludeAt: { ExcludeAt }?,
	mounts: { Mount }?,
	properties: { [string]: { [string]: RojoValue } }?,
}

export type Identity = {
	at: { string },
	name: string,
	path: string?,
	values: { [string]: RojoValue },
}

export type Target = {
	name: string,
	document: string,
	variant: string?,
	identity: Identity?,
}

export type Plan = {
	className: string?,
	mounts: { Mount },
	variants: { Variant }?,
	targets: { Target },
	requirePolicy: ("alias-only" | "any")?,
}

export type Node = { [string]: any }

export type Document = {
	name: string,
	tree: Node,
}

export type ManifestEntry = {
	target: string,
	document: string,
	variant: string?,
	paths: { string },
	identityValues: { [string]: RojoValue }?,
}

export type Manifest = {
	targets: { ManifestEntry },
	digest: string,
}

export type ProjectTree = {
	documents: { [string]: Document },
	order: { string },
	manifest: Manifest,
}

local function copyRojoValues(source: { [string]: RojoValue }?): { [string]: RojoValue }?
	if source == nil then
		return nil
	end
	local copy: { [string]: RojoValue } = {}
	for key, value in source do
		if not Diagnostics.isRojoValue(value) then
			Diagnostics.raise("project-tree/not-property-shaped", ("value %q cannot become a property"):format(key), {
				key = key,
				actual = Diagnostics.describe(value),
				expected = "a scalar, an array of finite numbers, or a single-key typed value",
			})
		end
		copy[key] = Diagnostics.copyRojoValue(value)
	end
	return copy
end

local function startsWith(text: string, prefix: string): boolean
	return string.sub(text, 1, #prefix) == prefix
end

local function endsWith(text: string, suffix: string): boolean
	return #suffix <= #text and string.sub(text, #text - #suffix + 1) == suffix
end

local function mountLabel(mount: Mount): string
	return table.concat(mount.at, ".") .. "." .. mount.name
end

local function validateMount(mount: Mount, index: number)
	if type(mount.name) ~= "string" or mount.name == "" then
		Diagnostics.raise("project-tree/unnamed-mount", "a mount has no name", {
			index = index,
			expected = "a non-empty name",
		})
	end
	if type(mount.at) ~= "table" then
		Diagnostics.raise("project-tree/unplaced-mount", ("mount %q names no tree location"):format(mount.name), {
			index = index,
			expected = "at, an array of ancestor names",
		})
	end
	if mount.path == nil and mount.className == nil then
		Diagnostics.raise(
			"project-tree/empty-mount",
			("mount %q carries neither path nor className"):format(mount.name),
			{
				index = index,
				expected = "a source path, a className, or both",
			}
		)
	end
end

local function refuseBareRelativeRequires(mount: Mount)
	if mount.requires == nil then
		return
	end
	for _, request in mount.requires do
		if startsWith(request, "./") or startsWith(request, "../") then
			Diagnostics.raise(
				"project-tree/bare-relative-require",
				("mount %q requires %q by relative path"):format(mountLabel(mount), request),
				{
					key = request,
					expected = "an alias-prefixed request",
					contract = "a mounted module keeps its request stable wherever the tree places it",
					fix = "give the request an alias, or set requirePolicy to any",
				}
			)
		end
	end
end

local function locationKey(at: { string }, name: string): string
	return table.concat(at, "/") .. "/" .. name
end

local function excludedAt(mount: Mount, variant: Variant?): boolean
	if variant == nil or variant.excludeAt == nil then
		return false
	end
	local mountKey = locationKey(mount.at, mount.name)
	for _, entry in variant.excludeAt do
		local entryKey = locationKey(entry.at, entry.name)
		if mountKey == entryKey or startsWith(mountKey, entryKey .. "/") then
			return true
		end
	end
	return false
end

local function excluded(path: string?, variant: Variant?): boolean
	if path == nil or variant == nil then
		return false
	end
	if variant.excludeExact ~= nil then
		for _, candidate in variant.excludeExact do
			if candidate == path then
				return true
			end
		end
	end
	if variant.excludePrefixes ~= nil then
		for _, prefix in variant.excludePrefixes do
			if startsWith(path, prefix) then
				return true
			end
		end
	end
	if variant.excludeSuffixes ~= nil then
		for _, suffix in variant.excludeSuffixes do
			if endsWith(path, suffix) then
				return true
			end
		end
	end
	return false
end

local function selectMounts(plan: Plan, variant: Variant?): { Mount }
	local selected: { Mount } = {}
	for index, mount in plan.mounts do
		validateMount(mount, index)
		if not excluded(mount.path, variant) and not excludedAt(mount, variant) then
			table.insert(selected, mount)
		end
	end
	if variant ~= nil and variant.mounts ~= nil then
		for index, mount in variant.mounts do
			validateMount(mount, index)
			table.insert(selected, mount)
		end
	end
	return selected
end

local function enforceSiblingClosure(mounts: { Mount })
	local placed: { [string]: boolean } = {}
	for _, mount in mounts do
		if mount.path ~= nil then
			placed[table.concat(mount.at, "/") .. "\0" .. mount.path] = true
		end
	end
	for _, mount in mounts do
		if mount.siblings == nil then
			continue
		end
		local parent = table.concat(mount.at, "/")
		for _, sibling in mount.siblings do
			if not placed[parent .. "\0" .. sibling] then
				Diagnostics.raise(
					"project-tree/unmounted-sibling",
					("mount %q needs sibling %q beside it"):format(mountLabel(mount), sibling),
					{
						key = sibling,
						expected = ("a mount of %q under %s"):format(sibling, parent),
						contract = "a module reaches its script parent siblings at runtime",
						fix = "mount the sibling beside this module, or drop it from siblings",
					}
				)
			end
		end
	end
end

local function branch(root: Node, at: { string }, className: string): Node
	local node = root
	for _, name in at do
		local child = node[name]
		if child == nil then
			child = { ["$className"] = className }
			node[name] = child
		end
		if type(child) ~= "table" then
			Diagnostics.raise("project-tree/occupied-branch", ("tree location %q is not a branch"):format(name), {
				key = name,
				actual = Diagnostics.describe(child),
				expected = "a branch node",
			})
		end
		node = child :: Node
	end
	return node
end

local function nodeFor(mount: Mount): Node
	local node: Node = {}
	if mount.path ~= nil then
		node["$path"] = mount.path
	end
	if mount.className ~= nil then
		node["$className"] = mount.className
	end
	local properties = copyRojoValues(mount.properties)
	if properties ~= nil then
		node["$properties"] = properties
	end
	local attributes = copyRojoValues(mount.attributes)
	if attributes ~= nil then
		node["$attributes"] = attributes
	end
	if mount.ignoreUnknownInstances ~= nil then
		node["$ignoreUnknownInstances"] = mount.ignoreUnknownInstances
	end
	return node
end

local function identityNode(identity: Identity): Node
	local values = copyRojoValues(identity.values)
	if values == nil then
		Diagnostics.raise("project-tree/empty-identity", ("identity %q stamps no value"):format(identity.name), {
			expected = "at least one identity value",
		})
	end
	if identity.path ~= nil then
		return { ["$path"] = identity.path }
	end
	return { ["$className"] = "Configuration", ["$attributes"] = values }
end

local function applyVariantProperties(root: Node, variant: Variant?)
	if variant == nil or variant.properties == nil then
		return
	end
	for location, properties in variant.properties do
		local at: { string } = string.split(location, ".")
		local node = branch(root, at, "Folder")
		local existing = node["$properties"]
		local merged: { [string]: RojoValue } = if type(existing) == "table" then existing else {}
		local validated = copyRojoValues(properties)
		if validated ~= nil then
			for key, value in validated do
				merged[key] = value
			end
		end
		node["$properties"] = merged
	end
end

local function documentFor(plan: Plan, target: Target, mounts: { Mount }, variant: Variant?): (Document, { string })
	local root: Node = { ["$className"] = plan.className or "DataModel" }
	local paths: { string } = {}

	for _, mount in mounts do
		local parent = branch(root, mount.at, "Folder")
		local existing = parent[mount.name]
		if mount.replace == true then
			if existing == nil then
				Diagnostics.raise(
					"project-tree/replace-without-base",
					("mount %q replaces nothing"):format(mountLabel(mount)),
					{
						key = mount.name,
						expected = "a base mount already at this tree location",
					}
				)
			end
		elseif existing ~= nil then
			Diagnostics.raise("project-tree/duplicate-mount", ("two mounts claim %q"):format(mountLabel(mount)), {
				key = mount.name,
				expected = "one mount per tree location",
			})
		end
		parent[mount.name] = nodeFor(mount)
		if mount.path ~= nil then
			table.insert(paths, mount.path)
		end
	end

	if target.identity ~= nil then
		local parent = branch(root, target.identity.at, "Folder")
		if parent[target.identity.name] ~= nil then
			Diagnostics.raise(
				"project-tree/occupied-identity",
				("identity %q collides with a mount"):format(target.identity.name),
				{ key = target.identity.name, expected = "a free tree location for the identity" }
			)
		end
		parent[target.identity.name] = identityNode(target.identity)
	end

	applyVariantProperties(root, variant)
	table.sort(paths)

	return { name = target.name, tree = root }, paths
end

local function variantNamed(plan: Plan, name: string?): Variant?
	if name == nil then
		return nil
	end
	if plan.variants ~= nil then
		for _, variant in plan.variants do
			if variant.name == name then
				return variant
			end
		end
	end
	Diagnostics.raise("project-tree/unknown-variant", ("no variant is named %q"):format(name), {
		key = name,
		expected = "a variant declared by the plan",
	})
	return nil
end

local function projectTree(plan: Plan): ProjectTree
	if type(plan.mounts) ~= "table" or #plan.mounts == 0 then
		Diagnostics.raise("project-tree/empty-plan", "the plan mounts nothing", {
			expected = "at least one mount",
		})
	end
	if type(plan.targets) ~= "table" or #plan.targets == 0 then
		Diagnostics.raise("project-tree/no-targets", "the plan names no target", {
			expected = "at least one target",
		})
	end

	local policy = plan.requirePolicy or "alias-only"
	if policy == "alias-only" then
		for _, mount in plan.mounts do
			refuseBareRelativeRequires(mount)
		end
		if plan.variants ~= nil then
			for _, variant in plan.variants do
				if variant.mounts ~= nil then
					for _, mount in variant.mounts do
						refuseBareRelativeRequires(mount)
					end
				end
			end
		end
	end

	local documents: { [string]: Document } = {}
	local order: { string } = {}
	local entries: { ManifestEntry } = {}

	for _, target in plan.targets do
		if type(target.name) ~= "string" or target.name == "" then
			Diagnostics.raise("project-tree/unnamed-target", "a target has no name", {
				expected = "a non-empty target name",
			})
		end
		if documents[target.name] ~= nil then
			Diagnostics.raise("project-tree/duplicate-target", ("two targets are named %q"):format(target.name), {
				key = target.name,
				expected = "one target per name",
			})
		end

		local variant = variantNamed(plan, target.variant)
		local mounts = selectMounts(plan, variant)
		enforceSiblingClosure(mounts)

		local document, paths = documentFor(plan, target, mounts, variant)
		documents[target.name] = document
		table.insert(order, target.name)
		table.insert(entries, {
			target = target.name,
			document = target.document,
			variant = target.variant,
			paths = paths,
			identityValues = if target.identity ~= nil then copyRojoValues(target.identity.values) else nil,
		})
	end

	local manifest: Manifest = {
		targets = entries,
		digest = Digest.digestText(Digest.canonical(entries)),
	}

	return { documents = documents, order = order, manifest = manifest }
end

return {
	projectTree = projectTree,
}
