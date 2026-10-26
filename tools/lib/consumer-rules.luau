--!strict

local Syntax = require "./consumer-syntax"
local mask = Syntax.mask
local escapePattern = Syntax.escapePattern
local matching = Syntax.matching
local tableEntries = Syntax.tableEntries
local blockEnd = Syntax.blockEnd
local functionRanges = Syntax.functionRanges
local innermostFunction = Syntax.innermostFunction
local boundLocalFunctionCalls = Syntax.boundLocalFunctionCalls
local callForms = Syntax.callForms

local function requireString(value: unknown): string
	assert(type(value) == "string")
	return value
end

local function requireNumber(value: unknown, ...: unknown): number
	assert(type(value) == "number")
	return value
end

export type Confidence = "certain" | "likely"

export type Finding = {
	code: string,
	confidence: Confidence,
	offset: number,
	why: string,
	fix: string,
	caveat: string?,
}

local STRUCTURAL_FIELDS: { [string]: { [string]: true } } = {
	keyed = { from = true, key = true, render = true },
	TileCollection = { viewport = true, tileSize = true, overscan = true, read = true, render = true },
	OrderedCollection = {
		from = true,
		key = true,
		render = true,
		mode = true,
		viewport = true,
		direction = true,
		layout = true,
		overscan = true,
		measured = true,
		follow = true,
		followThreshold = true,
		status = true,
		controls = true,
	},
	SpatialCollection = {
		from = true,
		key = true,
		position = true,
		origin = true,
		tiers = true,
		render = true,
		cellSize = true,
		hysteresis = true,
		importance = true,
		pinned = true,
		budget = true,
		status = true,
	},
	LayerStack = { from = true, key = true, render = true, retention = true },
	MountBudget = {
		from = true,
		key = true,
		render = true,
		mountsPerFrame = true,
		priority = true,
		status = true,
	},
	createFocusScope = {
		from = true,
		key = true,
		disabled = true,
		position = true,
		wrap = true,
		initial = true,
		autoFocus = true,
	},
	createPool = { create = true, destroy = true, reset = true, maxRetained = true },
	accumulator = { from = true, reduce = true, initial = true, equals = true },
}

local REQUIRED_FIELDS: { [string]: { string } } = {
	keyed = { "from", "render" },
	TileCollection = { "viewport", "tileSize", "read", "render" },
	OrderedCollection = { "from", "render" },
	SpatialCollection = { "from", "position", "origin", "tiers", "render" },
	LayerStack = { "from", "render" },
	MountBudget = { "from", "mountsPerFrame", "render" },
	createFocusScope = { "from" },
	createPool = { "create", "destroy", "maxRetained" },
	accumulator = { "from", "reduce" },
}

local DIRECTIVES = {
	"show",
	"switch",
	"keyed",
	"indexes",
	"fragment",
	"portal",
	"presence",
	"boundary",
	"OrderedCollection",
	"SpatialCollection",
	"TileCollection",
	"LayerStack",
	"MountBudget",
}

local function normalizedPath(argument: string): string
	local out = string.lower(argument)
	out = string.gsub(out, "%[%s*['\"]([%w_%-]+)['\"]%s*%]", ".%1")
	out = string.gsub(out, "%s+", "")
	return out
end

local function coreAliases(contents: string, masked: string): { [string]: true }
	local aliases: { [string]: true } = { Compose = true }
	local from = 1
	while true do
		local start, stop, name = string.find(masked, "local%s+([%w_]+)%s*=%s*require%s*%(", from)
		if start == nil then
			break
		end
		local open = string.find(masked, "(", requireNumber(stop), true)
		if open == nil then
			break
		end
		local close = matching(masked, requireNumber(open), "(", ")")
		if close == nil then
			break
		end
		local path = normalizedPath(string.sub(contents, (requireNumber(open)) + 1, (requireNumber(close)) - 1))
		if string.find(path, "compose.core", 1, true) ~= nil then
			aliases[requireString(name)] = true
		end
		from = (requireNumber(close)) + 1
	end
	return aliases
end

local function memberAliases(masked: string, modules: { [string]: true }, member: string): { [string]: true }
	local aliases: { [string]: true } = {}
	for module in modules do
		local pattern = "local%s+([%w_]+)%s*=%s*" .. escapePattern(module) .. "%." .. member .. "%f[^%w_]"
		for alias in string.gmatch(masked, pattern) do
			aliases[alias] = true
		end
	end
	return aliases
end

local function lane(text: string, seed: number): number
	local hash = seed
	for index = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, index))
		local low = bit32.band(hash, 0xFFFF) * 16777619
		local high = bit32.rshift(hash, 16) * 16777619
		hash = bit32.band(low + bit32.lshift(bit32.band(high, 0xFFFF), 16), 0xFFFFFFFF)
	end
	return hash
end

local function digestText(text: string): string
	return ("%08x%08x"):format(lane(text, 2166136261), lane(text, 0x811C9DC7))
end

local BUILD_TOOLING_DIRS = { "/tools/", "/lute/", "/bench/", "/tests/" }

local SPECIFICATION_SUFFIXES = { "%.verify%.luau$", "%.spec%.luau$" }

local function isBuildTooling(relativePath: string?): boolean
	if relativePath == nil then
		return false
	end
	local normalized = "/" .. (string.gsub(relativePath, "\\", "/"))
	for _, piece in BUILD_TOOLING_DIRS do
		if string.find(normalized, piece, 1, true) ~= nil then
			return true
		end
	end
	for _, suffix in SPECIFICATION_SUFFIXES do
		if string.find(normalized, suffix) ~= nil then
			return true
		end
	end
	return false
end

local function namesAuthoringPackage(path: string): boolean
	return string.find(path, "%f[%w%-]compose%-authoring%f[^%w%-]") ~= nil
end

local function add(found: { Finding }, seen: { [string]: true }, finding: Finding)
	local key = finding.code .. ":" .. tostring(finding.offset)
	if seen[key] == nil then
		seen[key] = true
		table.insert(found, finding)
	end
end

local function scan(contents: string, relativePath: string?, masked: string?): { Finding }
	local source = masked or mask(contents)
	local modules = coreAliases(contents, source)
	local found: { Finding } = {}
	local seen: { [string]: true } = {}

	local structuralAliases: { [string]: { [string]: true } } = {}
	for primitive in STRUCTURAL_FIELDS do
		structuralAliases[primitive] = memberAliases(source, modules, primitive)
		local forms = callForms(source, modules, structuralAliases[primitive], primitive, "{")
		for _, call in callForms(source, modules, structuralAliases[primitive], primitive, "(") do
			local first = string.find(source, "%S", call.open + 1)
			if first == nil or string.sub(source, requireNumber(first), requireNumber(first)) ~= "{" then
				add(found, seen, {
					code = "CMP017",
					confidence = "certain",
					offset = call.offset,
					why = primitive .. " takes one table of named options",
					fix = "write " .. primitive .. " { ... } with the documented named fields",
					caveat = nil,
				})
			else
				table.insert(forms, { offset = call.offset, open = requireNumber(first) })
			end
		end

		local known = STRUCTURAL_FIELDS[primitive]
		local knownNames: { string } = {}
		for name in known do
			table.insert(knownNames, name)
		end
		table.sort(knownNames)
		for _, form in forms do
			local provided: { [string]: true } = {}
			local dynamic = false
			local required: { string } = REQUIRED_FIELDS[primitive] or {}
			for _, entry in tableEntries(source, form.open) do
				local field = string.match(entry.text, "^%s*([%a_][%w_]*)%s*=")
				if field ~= nil then
					provided[field] = true
				elseif string.find(entry.text, "%S") ~= nil then
					dynamic = true
				end
				if field ~= nil and known[field] == nil then
					add(found, seen, {
						code = "CMP018",
						confidence = "certain",
						offset = entry.offset,
						why = ("%s has no option named %s"):format(primitive, field),
						fix = "use only: " .. table.concat(knownNames, ", "),
						caveat = nil,
					})
				end
			end
			if not dynamic then
				for _, field in required do
					if provided[field] == nil then
						add(found, seen, {
							code = "CMP025",
							confidence = "certain",
							offset = form.offset,
							why = ("%s requires the %s option"):format(primitive, field),
							fix = ("add %s = ... to the options table"):format(field),
							caveat = nil,
						})
					end
				end
			end
		end
	end

	local requireFrom = 1
	while true do
		local start, stop = string.find(source, "%f[%w_]require%s*%(", requireFrom)
		if start == nil then
			break
		end
		local open = requireNumber(string.find(source, "(", requireNumber(start), true))
		local close = matching(source, open, "(", ")")
		if close == nil then
			break
		end
		local path = normalizedPath(string.sub(contents, open + 1, (requireNumber(close)) - 1))
		if
			string.find(path, "compose.core.", 1, true) ~= nil
			or string.find(path, "compose.roblox.", 1, true) ~= nil
			or string.find(path, "compose.src.", 1, true) ~= nil
		then
			add(found, seen, {
				code = "CMP019",
				confidence = "certain",
				offset = requireNumber(start),
				why = "the import reaches through Compose's documented package entry point",
				fix = "import compose.core or compose.roblox and use only their documented public exports",
				caveat = nil,
			})
		end
		if namesAuthoringPackage(path) and not isBuildTooling(relativePath) then
			add(found, seen, {
				code = "CMP032",
				confidence = "certain",
				offset = requireNumber(start),
				why = "the authoring layer is a build/edit-time companion -- a runtime require drags "
					.. "validation, codegen, and serialization machinery onto the hot path the library's "
					.. "performance contract protects",
				fix = "move the use into a build tool or spec, or consume the baked artifact (generated "
					.. "module, attributes) instead",
				caveat = nil,
			})
		end
		requireFrom = (requireNumber(stop)) + 1
	end

	local cleanupAliases = memberAliases(source, modules, "cleanup")
	local cleanupNames: { string } = {}
	for alias in cleanupAliases do
		table.insert(cleanupNames, alias)
	end
	for module in modules do
		table.insert(cleanupNames, module .. ".cleanup")
	end
	for _, cleanup in cleanupNames do
		for _, mount in { "mount", "mountFragment" } do
			local pattern = "%f[%w_]" .. escapePattern(cleanup) .. "%s*%(%s*[%w_.]+%." .. mount .. "%s*%("
			local from = 1
			while true do
				local start, stop = string.find(source, pattern, from)
				if start == nil then
					break
				end
				add(found, seen, {
					code = "CMP020",
					confidence = "likely",
					offset = requireNumber(start),
					why = "a nested mount already belongs to the active owner; registering its disposer again changes teardown order",
					fix = "call runtime.mount or runtime.mountFragment directly inside the component; retain its disposer only for a top-level mount",
					caveat = "this is valid when the mount runs with no active owner and this cleanup is its deliberate lifetime",
				})
				from = (requireNumber(stop)) + 1
			end
		end
	end
	for _, mount in { "mount", "mountFragment" } do
		for start in string.gmatch(source, "()([%w_.]+)%.own%s*%(%s*[%w_.]+%." .. mount .. "%s*%(") do
			local offset = requireNumber(tonumber(start))
			add(found, seen, {
				code = "CMP020",
				confidence = "likely",
				offset = offset,
				why = "a nested mount already belongs to the active owner; registering its disposer again changes teardown order",
				fix = "call the nested mount directly and let its active owner hold it",
				caveat = "this is valid when the mount ran outside that owner and is intentionally transferred into it",
			})
		end
	end

	local createAliases: { [string]: true } = { create = true }
	for alias in string.gmatch(source, "local%s+([%w_]+)%s*=%s*[%w_.]+%.create%f[^%w_]") do
		createAliases[alias] = true
	end
	local constructors: { [string]: true } = {}
	for create in createAliases do
		for _, suffix in { "%s*['\"]", "%s*%(%s*['\"]" } do
			local pattern = "local%s+([%w_]+)%s*=%s*" .. escapePattern(create) .. suffix
			for constructor in string.gmatch(source, pattern) do
				constructors[constructor] = true
			end
		end
	end
	local namespaces: { [string]: true } = { Host = true }
	for alias in string.gmatch(source, "local%s+([%w_]+)%s*=%s*[%w_.]+%.constructors%f[^%w_]") do
		namespaces[alias] = true
	end
	for owner, class in string.gmatch(source, "([%w_.]+)%.constructors%.([%a_][%w_]*)") do
		constructors[owner .. ".constructors." .. (requireString(class))] = true
	end
	for namespace in namespaces do
		local pattern = "%f[%w_]" .. escapePattern(namespace) .. "%.([%a_][%w_]*)"
		for class in string.gmatch(source, pattern) do
			constructors[namespace .. "." .. class] = true
		end
	end
	local cachedConstructors: { [string]: true } = {}
	for constructor in constructors do
		local pattern = "local%s+([%w_]+)%s*=%s*" .. escapePattern(constructor) .. "%f[^%w_]()"
		for alias, after in string.gmatch(source, pattern) do
			local offset = requireNumber(tonumber(after))
			local lineEnd = string.find(source, "\n", offset, true) or (#source + 1)
			local tail = string.sub(source, offset, lineEnd - 1)
			if string.match(tail, "^%s*;?%s*$") ~= nil then
				cachedConstructors[alias] = true
			end
		end
	end
	for alias in cachedConstructors do
		constructors[alias] = true
	end
	local directiveSymbols: { [string]: true } = {}
	for _, directive in DIRECTIVES do
		for alias in memberAliases(source, modules, directive) do
			directiveSymbols[alias] = true
		end
		for module in modules do
			directiveSymbols[module .. "." .. directive] = true
		end
	end
	for constructor in constructors do
		local forms = callForms(source, {}, { [constructor] = true }, "", "{")
		local labelled = "%f[%w_]" .. escapePattern(constructor) .. "%s*['\"][^'\"]*['\"]%s*{"
		local from = 1
		while true do
			local start, stop = string.find(source, labelled, from)
			if start == nil then
				break
			end
			local open = requireNumber(string.find(source, "{", requireNumber(start), true))
			table.insert(forms, { offset = requireNumber(start), open = open })
			from = (requireNumber(stop)) + 1
		end
		for _, form in forms do
			for _, entry in tableEntries(source, form.open) do
				local trimmed = string.gsub(entry.text, "^%s+", "")
				if string.match(trimmed, "^function%s*%(%s*[%w_]*%s*%)") ~= nil then
					add(found, seen, {
						code = "CMP022",
						confidence = "likely",
						offset = entry.offset,
						why = "a function in child position is a directive and receives a MountPoint, not an ordinary child callback",
						fix = "call the component and place its node here, or author an explicit directive that accepts a MountPoint",
						caveat = "this is valid if the function is intentionally a custom directive",
					})
				else
					local symbol = string.match(trimmed, "^([%w_.]+)%s*$")
					if symbol ~= nil and directiveSymbols[symbol] then
						add(found, seen, {
							code = "CMP023",
							confidence = "certain",
							offset = entry.offset,
							why = "a directive constructor was placed in the tree without being called",
							fix = ("call %s(...) so it returns a directive"):format(symbol),
							caveat = nil,
						})
					end
				end
			end
		end
	end

	for _, operation in { "mountFragment", "mount" } do
		for start in string.gmatch(source, "()[%w_]+%s*:%s*" .. operation .. "%s*%(") do
			add(found, seen, {
				code = "CMP026",
				confidence = "likely",
				offset = requireNumber(tonumber(start)),
				why = ("%s is a Compose runtime table function, not a colon method"):format(operation),
				fix = ("use dot syntax: runtime.%s(...)"):format(operation),
				caveat = "this is a false positive if the receiver is not a Compose runtime",
			})
		end
	end

	local mountDirectivePattern = "[%w_.]+%.mount%s*%(%s*function%s*%([^%)]*%)%s*return%s+([%w_.]+)"
	for start, symbol in string.gmatch(source, "()" .. mountDirectivePattern) do
		if directiveSymbols[symbol] then
			add(found, seen, {
				code = "CMP027",
				confidence = "likely",
				offset = requireNumber(tonumber(start)),
				why = "runtime.mount requires one node, but this builder returns a structural directive",
				fix = "use runtime.mountFragment for a top-level directive, or put the directive inside a node",
				caveat = "this is a false positive if mount is not Compose's runtime.mount",
			})
		end
	end

	local identityPattern = "([%w_]+)%s*=%s*function%s*%(use[^%)]*%)%s*return%s+use%s*%(%s*[%w_.]+%s*%)%s*end"
	local from = 1
	while true do
		local start, stop, field = string.find(source, identityPattern, from)
		if start == nil then
			break
		end

		if field ~= "from" then
			add(found, seen, {
				code = "CMP024",
				confidence = "likely",
				offset = requireNumber(start),
				why = "an identity reactive wrapper obscures a direct binding and misses its shared static sink",
				fix = "bind the readable directly: Property = value",
				caveat = "keep the body if it is about to gain a transformation or deliberate dynamic dependencies",
			})
		end
		from = (requireNumber(stop)) + 1
	end

	local runtimeNames: { [string]: true } = { runtime = true, Runtime = true }
	for alias in string.gmatch(source, "%f[%w_]local%s+([%w_]+)%s*=%s*[%w_.]*createRuntime%s*%(") do
		runtimeNames[alias] = true
	end
	for name in runtimeNames do
		if modules[name] ~= nil then
			continue
		end
		for _, control in { "watch", "batch", "settle", "pending" } do
			local pattern = "%f[%w_]" .. escapePattern(name) .. "%s*%." .. control .. "%s*%("
			local searchFrom = 1
			while true do
				local start, stop = string.find(source, pattern, searchFrom)
				if start == nil then
					break
				end
				local before = if (requireNumber(start)) > 1
					then string.sub(source, (requireNumber(start)) - 1, (requireNumber(start)) - 1)
					else ""

				if before ~= "." and before ~= ":" then
					add(found, seen, {
						code = "CMP028",
						confidence = "certain",
						offset = requireNumber(start),
						why = (
							"%s is a method on the runtime; the dot call binds the first argument as "
							.. "self, so a watch body passed this way is dropped without an error"
						):format(control),
						fix = ("use method syntax: %s:%s(...)"):format(name, control),
						caveat = nil,
					})
				end
				searchFrom = (requireNumber(stop)) + 1
			end
		end
	end

	local ranges = functionRanges(source)

	for _, opener in { "watch", "formula" } do
		local bodyPattern = "%f[%w_]" .. opener .. "%s*%(%s*function%f[^%w_]"
		local bodyFrom = 1
		while true do
			local start, stop = string.find(source, bodyPattern, bodyFrom)
			if start == nil then
				break
			end
			local functionAt = (requireNumber(stop)) - 7
			local bodyClose = blockEnd(source, functionAt)
			local peekFrom = functionAt
			while true do
				local peekAt = string.find(source, ":%s*peek%s*%(", peekFrom)
				if peekAt == nil or (requireNumber(peekAt)) > bodyClose then
					break
				end
				add(found, seen, {
					code = "CMP029",
					confidence = "likely",
					offset = requireNumber(peekAt),
					why = ":peek() inside a reactive body reads without depending, so this "
						.. opener
						.. " will not re-run when that value changes",
					fix = "read through the body's reader -- use(value) -- so the dependency is tracked",
					caveat = "an untracked read on purpose is legitimate: writing a cell this same watch "
						.. "sets, or a value deliberately sampled once per run",
				})
				peekFrom = (requireNumber(peekAt)) + 1
			end
			bodyFrom = (requireNumber(stop)) + 1
		end
	end

	local stateAliases: { [string]: { [string]: true } } = {}
	for _, state in { "cell", "formula" } do
		stateAliases[state] = memberAliases(source, modules, state)
		for _, call in callForms(source, modules, stateAliases[state], state, "(") do
			if innermostFunction(ranges, call.offset) == nil then
				add(found, seen, {
					code = "CMP030",
					confidence = "likely",
					offset = call.offset,
					why = ("a %s created at module scope is shared by every consumer of the module and has no owner to dispose it"):format(
						state
					),
					fix = ("create the %s inside a component or mount body so its owner's lifetime bounds it"):format(
						state
					) .. if state == "cell"
						then ", or state the intent with Compose.sharedCell for a deliberate singleton"
						else "",
					caveat = "a deliberate process-wide singleton is legitimate; module scope is then the point"
						.. if state == "cell" then ", and Compose.sharedCell says so in the constructor" else "",
				})
			end
		end
	end

	local cellNames: { string } = {}
	for alias in stateAliases.cell do
		table.insert(cellNames, alias)
	end
	for module in modules do
		table.insert(cellNames, module .. ".cell")
	end
	for _, name in cellNames do
		local declPattern = "()%f[%w_]local%s+([%w_]+)%s*=%s*" .. escapePattern(name) .. "%s*%("
		for declAt, variable in string.gmatch(source, declPattern) do
			local declOffset = requireNumber(tonumber(declAt))
			local declScope = innermostFunction(ranges, declOffset)
			local watchFrom = declOffset
			while true do
				local start, stop = string.find(source, "%f[%w_]watch%s*%(%s*function%f[^%w_]", watchFrom)
				if start == nil then
					break
				end
				if innermostFunction(ranges, requireNumber(start)) == declScope then
					local functionAt = (requireNumber(stop)) - 7
					local body = string.sub(source, functionAt, blockEnd(source, functionAt))
					if
						string.find(body, "%f[%w_]" .. escapePattern(requireString(variable)) .. "%s*:%s*set%s*%(")
						~= nil
					then
						add(found, seen, {
							code = "CMP031",
							confidence = "likely",
							offset = requireNumber(start),
							why = ("this watch exists to write %s from other reactive values -- an eager derivation that formula computes lazily, with equal values suppressed"):format(
								variable
							),
							fix = (
								"replace the cell and the watch with %s = formula(function(use) return ... end); "
								.. "a merge of discrete events into running state is %s = Compose.accumulator { from = ..., reduce = ... }"
							):format(variable, variable),
							caveat = "a watch that writes a cell is legitimate when the write bridges into imperative code rather than deriving a pure value; one that accumulates history belongs in Compose.accumulator",
						})
					end
				end
				watchFrom = (requireNumber(stop)) + 1
			end
		end
	end

	local generatorAt = string.find(contents, "generator: Author.bake.registryModule (authoring/bake.luau)", 1, true)
	if generatorAt ~= nil then
		local closeAt = string.find(contents, "]]", requireNumber(generatorAt), true)
		if closeAt ~= nil then
			local header = string.sub(contents, 1, (requireNumber(closeAt)) - 1)
			local bodyAt = string.find(contents, "\n\n", requireNumber(closeAt), true)
			if bodyAt ~= nil then
				local body = string.sub(contents, (requireNumber(bodyAt)) + 2)
				local expected = string.match(header, "body digest:%s*(%x+)")
				local actual = digestText(body)
				if expected == nil or string.lower(expected) ~= string.lower(actual) then
					add(found, seen, {
						code = "CMP033",
						confidence = "likely",
						offset = requireNumber(generatorAt),
						why = "the header's body digest no longer matches this file's body -- either the "
							.. "file was hand-edited after Author.bake.registryModule generated it, or it "
							.. "was never regenerated after the data or mapping it names changed",
						fix = "regenerate the module with Author.bake.registryModule and commit the result "
							.. "unedited, or make the change in the entry set or mapping and regenerate from "
							.. "there",
						caveat = "this cannot tell a hand edit apart from a body digest computed by a "
							.. "different bake.luau revision -- if the generator's own emission format "
							.. "changed, regenerating once makes the header true again with no further edit "
							.. "needed",
					})
				end
			end
		end
	end

	table.sort(found, function(left: Finding, right: Finding): boolean
		if left.offset ~= right.offset then
			return left.offset < right.offset
		end
		return left.code < right.code
	end)
	return found
end

return {
	mask = mask,
	boundLocalFunctionCalls = boundLocalFunctionCalls,
	scan = scan,
}
