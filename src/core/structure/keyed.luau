--!strict
--!native

local StructureTypes = require "../types"
local Owners = require "../ownership/owner"
local Block = require("../runtime/children").block
local Children = require "../runtime/children"
local Diagnostics = require "../diagnostics"
local Host = require "../host"
local Support = require "./support"
local Types = require "../reactive/types"
local longestIncreasingSubsequence = require "./lis"
local cellModule = require "../reactive/cell"

export type Render<V, K> = StructureTypes.KeyedRender<V, K>

export type Source<V> = StructureTypes.KeyedSource<V>

export type Options<V, K = V> = StructureTypes.KeyedOptions<V, K>

local UNREAD_INDEX = cellModule.cell(0)
local KNOWN_FIELDS: { [string]: true } = { from = true, key = true, render = true }

local function array<T>(count: number): { T }
	local create: (number, T?) -> { T } = table.create
	return create(count)
end

local function keyedWithKeys<V, K>(
	from: Source<V>,
	render: Render<V, K>,
	collectKeys: (list: { V }, wanted: number, keys: { K }) -> ()
): Children.Directive
	local source: Types.Body<{ V }> = Support.sourceOf(from, "keyed", "from")
	local arity, variadic = debug.info(render, "a")
	local readsIndex = variadic or arity >= 2

	return function(mountPoint: Children.MountPoint)
		local owner = Support.ownerFor "keyed"
		Support.mountPointOf(mountPoint, "keyed")
		local ordersChildren = mountPoint.ordersChildren
		local entries: { [K]: number } = {}
		local owners: { Owners.Owner } = {}
		local nodes: { Host.Node } = {}
		local values: { Types.Value<V> } = {}
		local indices: { Types.Value<number> } = {}
		local rowKeys: { K } = {}
		local items: { V } = {}
		local positions: { number } = {}
		local marks: { number } = {}
		local free: { number } = {}
		local retired: { [number]: true } = {}
		local nextEntry = 0
		local order: { number } = {}
		local matched: { [number]: number? } = {}

		local keys: { K } = {}
		local stale: { number } = {}
		local retainedPositions: { number } = {}
		local retainedTargets: { number } = {}
		local base, count, epoch = 0, 0, 0

		Owners.own(owner, function()
			for _, entry in entries do
				Block.releaseNode(mountPoint, nodes[entry])
			end
			table.clear(entries)
			table.clear(owners)
			table.clear(nodes)
			table.clear(values)
			table.clear(indices)
			table.clear(rowKeys)
			table.clear(items)
			table.clear(positions)
			table.clear(marks)
			table.clear(free)
			table.clear(retired)
			table.clear(order)
			table.clear(matched)
			table.clear(keys)
		end)

		local function normalize()
			if base == 0 then
				return
			end
			table.move(order, base + 1, base + count, 1)
			for index = count + 1, base + count do
				order[index] = nil
			end
			for index = 1, count do
				positions[order[index]] = index
			end
			base = 0
		end

		local function reindex(from: number, to: number)
			for index = from, to do
				positions[order[index]] = index
			end
		end

		local function compact()
			for _, entry in entries do
				local at = positions[entry]
				if at <= base or at > base + count or order[at] ~= entry then
					return
				end
			end
			for index = 1, count do
				local at = base + index
				local entry = order[at]
				if entry == nil or positions[entry] ~= at or entries[rowKeys[entry]] ~= entry then
					return
				end
			end
			local keptOwners = array<<Owners.Owner>>(count)
			local keptNodes = array<<Host.Node>>(count)
			local keptValues = array<<Types.Value<V>>>(count)
			local keptIndices = array<<Types.Value<number>>>(count)
			local keptKeys = array<<K>>(count)
			local keptItems = array<<V>>(count)
			local keptPositions = array<<number>>(count)
			local keptMarks = array<<number>>(count)
			for index = 1, count do
				local at = base + index
				local entry = order[at]
				keptOwners[index] = owners[entry]
				keptNodes[index] = nodes[entry]
				keptValues[index] = values[entry]
				keptIndices[index] = indices[entry]
				keptKeys[index] = rowKeys[entry]
				keptItems[index] = items[entry]
				keptPositions[index] = at
				keptMarks[index] = marks[entry]
				entries[rowKeys[entry]] = index
				order[at] = index
			end
			owners, nodes, values, indices = keptOwners, keptNodes, keptValues, keptIndices
			rowKeys, items, positions, marks = keptKeys, keptItems, keptPositions, keptMarks
			free, retired, nextEntry = {}, {}, count
			table.clear(matched)
		end

		local function setIndex(entry: number, index: number)
			local cell = indices[entry]
			local cached = cell.cache
			if cached == nil or cached.value ~= index then
				cell:set(index)
			end
		end

		local function mountRow(index: number, itemKey: K, at: number, item: V): number
			local value = cellModule.cell(item)
			local position = if readsIndex then cellModule.cell(index) else UNREAD_INDEX
			local node, rowOwner = Block.mountRow(mountPoint, owner, render, value, position, itemKey, "keyed row", at)
			local entry = table.remove(free) or nextEntry + 1
			nextEntry = math.max(nextEntry, entry)
			owners[entry] = rowOwner
			nodes[entry] = node
			values[entry] = value
			indices[entry] = position
			rowKeys[entry] = itemKey
			items[entry] = item
			positions[entry] = 0
			marks[entry] = 0
			entries[itemKey] = entry
			return entry
		end

		local function duplicate(index: number, earlier: number): never
			return Diagnostics.raise("structure/duplicate-key", "two items in a keyed collection share a key", {
				index = index,
				detail = ("the same key is also used at index %d"):format(earlier),
				contract = "keys identify rows across updates, so they must be unique within one update",
				fix = "pass a keyOf that returns a stable unique id, e.g. function(item) return item.id end",
			})
		end

		local function raiseFailures(failures: { string }?)
			if failures ~= nil then
				if #failures == 1 then
					error(failures[1], 0)
				end
				error(
					("Compose: %d keyed row factories failed:\n  %s"):format(#failures, table.concat(failures, "\n  ")),
					0
				)
			end
		end

		local function release(entry: number)
			Block.releaseNode(mountPoint, nodes[entry])
			Owners.dispose(owners[entry])
			entries[rowKeys[entry]] = nil
			positions[entry] = 0
			retired[entry] = true
		end

		local function trimHead(list: { V }, wanted: number, found: number): boolean
			if count == 0 or wanted == 0 then
				return false
			end
			local head = entries[keys[1]]
			if head == nil then
				return false
			end
			local first = positions[head]
			local drop = first - base - 1
			local kept = count - drop
			if drop <= 0 or kept > wanted or found ~= kept then
				return false
			end
			for index = 2, kept do
				if rowKeys[order[first + index - 1]] ~= keys[index] then
					return false
				end
			end
			for at = base + 1, base + drop do
				release(order[at])
				order[at] = nil
			end
			base += drop
			count = kept
			for index = 1, kept do
				local entry = order[base + index]
				local item = list[index]
				if items[entry] ~= item then
					items[entry] = item
					values[entry]:set(item)
				end
				if readsIndex then
					setIndex(entry, index)
				end
			end
			local failures: { string }? = nil
			for index = kept + 1, wanted do
				local itemKey = keys[index]
				local ok, made = pcall(mountRow, index, itemKey, count + 1, list[index])
				if ok then
					count += 1
					local at = base + count
					order[at] = made
					positions[made] = at
				else
					local collected: { string } = failures or {}
					failures = collected
					table.insert(collected, tostring(made))
				end
			end
			if base > count then
				normalize()
			end
			raiseFailures(failures)
			return true
		end

		local depth, passes = 0, 0
		local function reconcile(use: Types.Use)
			passes += 1
			local pass = passes
			local list = source(use)
			local wanted = #list
			collectKeys(list, wanted, keys)
			for index = #keys, wanted + 1, -1 do
				keys[index] = nil
			end

			local mark = epoch + 1
			epoch = mark + wanted
			table.clear(matched)
			local changed = 0
			local previousCount = count
			local rows, wantedKeys, offset = order, keys, base
			local prefix, staleCount = 0, 0
			local shared = math.min(previousCount, wanted)
			while prefix < shared do
				local entry = rows[offset + prefix + 1]
				if not rawequal(rowKeys[entry], wantedKeys[prefix + 1]) then
					break
				end
				prefix += 1
				marks[entry] = mark + prefix
				local cached = if readsIndex then indices[entry].cache else nil
				if items[entry] ~= list[prefix] or (readsIndex and (cached == nil or cached.value ~= prefix)) then
					staleCount += 1
					stale[staleCount] = prefix
				end
			end
			local found = prefix
			local fresh: { [K]: number }? = nil
			local byKey, picked = entries, matched
			for index = prefix + 1, wanted do
				local item = list[index]
				local itemKey = wantedKeys[index]
				local entry = byKey[itemKey]
				if entry ~= nil then
					local cached = if readsIndex then indices[entry].cache else nil
					local at = positions[entry] - offset
					if marks[entry] >= mark then
						duplicate(index, marks[entry] - mark)
					end
					marks[entry] = mark + index
					found += 1
					if ordersChildren then
						picked[index] = entry
					elseif
						at ~= index
						or items[entry] ~= item
						or (readsIndex and (cached == nil or cached.value ~= index))
					then
						changed += 1
						picked[changed] = entry
					end
				else
					local added = fresh or {}
					fresh = added
					local earlier = added[itemKey]
					if earlier ~= nil then
						duplicate(index, earlier)
					end
					added[itemKey] = index
				end
			end
			for at = 1, staleCount do
				local index = stale[at]
				local entry = order[base + index]
				local item = list[index]
				if items[entry] ~= item then
					items[entry] = item
					values[entry]:set(item)
				end
				if readsIndex then
					setIndex(entry, index)
				end
			end
			if not ordersChildren and fresh == nil and wanted == previousCount then
				for at = 1, changed do
					local entry = assert(matched[at])
					local index = marks[entry] - mark
					local item = list[index]
					if items[entry] ~= item then
						items[entry] = item
						values[entry]:set(item)
					end
					if readsIndex then
						setIndex(entry, index)
					end
					order[base + index] = entry
					positions[entry] = base + index
				end
				return
			end
			if trimHead(list, wanted, found) then
				return
			end
			normalize()

			local oldEnd, newEnd = previousCount, wanted
			while oldEnd > prefix and newEnd > prefix and rawequal(rowKeys[rows[oldEnd]], wantedKeys[newEnd]) do
				oldEnd -= 1
				newEnd -= 1
			end
			local shift = newEnd - oldEnd

			for index = newEnd + 1, wanted do
				local entry = order[index - shift]
				local item = list[index]
				if items[entry] ~= item then
					items[entry] = item
					values[entry]:set(item)
				end
				if readsIndex then
					setIndex(entry, index)
				end
			end
			if prefix == wanted and previousCount == wanted then
				return
			end

			local removedAny = false
			if found < previousCount then
				for index = prefix + 1, oldEnd do
					local existing = order[index]
					if marks[existing] < mark then
						release(existing)
						removedAny = true
					end
				end
			end
			if not ordersChildren then
				local live = prefix
				local failures: { string }? = nil
				for index = prefix + 1, wanted do
					local entry = entries[keys[index]]
					if entry == nil then
						local ok, made = pcall(mountRow, index, keys[index], live + 1, list[index])
						if passes ~= pass then
							return
						end
						if not ok then
							local collected: { string } = failures or {}
							failures = collected
							table.insert(collected, tostring(made))
							continue
						end
						entry = made
					elseif index <= newEnd then
						local item = list[index]
						if items[entry] ~= item then
							items[entry] = item
							values[entry]:set(item)
						end
						if readsIndex then
							setIndex(entry, index)
						end
					end
					live += 1
					local mounted = assert(entry)
					if positions[mounted] ~= live then
						order[live] = mounted
						positions[mounted] = live
					end
				end
				for index = #order, live + 1, -1 do
					order[index] = nil
				end
				count = live
				raiseFailures(failures)
				return
			end
			if removedAny then
				local live = prefix
				local was = #order
				for index = prefix + 1, was do
					local existing = order[index]
					if positions[existing] ~= 0 then
						live += 1
						order[live] = existing
						positions[existing] = live
					end
				end
				for index = was, live + 1, -1 do
					order[index] = nil
				end
			end

			local retained = 0
			local previousPosition = 0
			local ordered = true
			for index = prefix + 1, newEnd do
				local entry = matched[index]
				if entry ~= nil then
					local item = list[index]
					if items[entry] ~= item then
						items[entry] = item
						values[entry]:set(item)
					end
					if readsIndex then
						setIndex(entry, index)
					end
					local at = positions[entry]
					retained += 1
					if at < previousPosition then
						ordered = false
					end
					previousPosition = at
					retainedPositions[retained] = at
					retainedTargets[retained] = index
				end
			end

			local middle = newEnd - prefix
			if ordered and retained == middle and not removedAny and previousCount == wanted then
				return
			end
			if not ordered and retained == middle and previousCount == wanted then
				local first, last = order[prefix + 1], order[newEnd]
				local index = prefix + 2
				if matched[prefix + 1] == last and matched[newEnd] == first then
					while index < newEnd and matched[index] == order[index] do
						index += 1
					end
					if index >= newEnd then
						order[prefix + 1], order[newEnd] = last, first
						positions[last], positions[first] = prefix + 1, newEnd
						mountPoint.moveTo(nodes[last], prefix + 1)
						if middle > 2 then
							mountPoint.moveTo(nodes[first], newEnd)
						end
						return
					end
				end
			end

			local stays: { number }? = nil
			if not ordered then
				stays = longestIncreasingSubsequence(retainedPositions, retained)
			end

			local failures: { string }? = nil
			if stays == nil then
				local live = prefix
				for index = prefix + 1, newEnd do
					local entry = matched[index]
					live += 1

					if entry == nil then
						local ok, made = pcall(mountRow, index, keys[index], live, list[index])
						if passes ~= pass then
							return
						end
						if not ok then
							local collected: { string } = failures or {}
							failures = collected
							table.insert(collected, tostring(made))
							live -= 1
							continue
						end
						table.insert(order, live, made)
						reindex(live, #order)
					elseif retained < middle and order[live] ~= entry then
						local from = positions[entry]
						table.remove(order, from)
						table.insert(order, live, entry)
						reindex(math.min(from, live), math.max(from, live))
					else
						order[live] = entry
						positions[entry] = live
					end
				end
				for index = #order, live + wanted - newEnd + 1, -1 do
					order[index] = nil
				end
			else
				local following = matched[newEnd + 1]
				local anchor: number? = if newEnd < wanted then following else nil
				local staying = 1
				for index = newEnd, prefix + 1, -1 do
					local entry = matched[index]

					local anchorLive = if anchor ~= nil then positions[anchor] else #order + 1

					if entry == nil then
						local ok, made = pcall(mountRow, index, keys[index], anchorLive, list[index])
						if passes ~= pass then
							return
						end
						if not ok then
							local collected: { string } = failures or {}
							failures = collected
							table.insert(collected, tostring(made))
							continue
						end
						table.insert(order, anchorLive, made)
						reindex(anchorLive, #order)
						entry = made
					elseif index ~= retainedTargets[stays[staying]] then
						local from = positions[entry]
						table.remove(order, from)
						local destination = if from < anchorLive then anchorLive - 1 else anchorLive
						table.insert(order, destination, entry)
						reindex(math.min(from, destination), math.max(from, destination))
						mountPoint.moveTo(nodes[entry], destination)
					else
						staying += 1
					end
					anchor = entry
				end
			end
			count = #order
			raiseFailures(failures)
		end
		Owners.watch(owner, function(use)
			depth += 1
			local outerKeys, outerMatched = keys, matched
			if depth > 1 then
				keys, matched = {}, {}
			end
			local ok, failure: unknown = pcall(reconcile, use)
			keys, matched = outerKeys, outerMatched
			depth -= 1
			if depth == 0 and ok then
				if count == 0 and next(entries) == nil and next(order) == nil then
					owners, nodes, values, indices = {}, {}, {}, {}
					rowKeys, items, positions, marks = {}, {}, {}, {}
					free, retired, nextEntry = {}, {}, 0
				else
					if next(retired) ~= nil then
						table.clear(matched)
						for entry in retired do
							matched[entry] = entry
						end
						for _, entry in order do
							matched[entry] = nil
						end
						for _, entry in entries do
							matched[entry] = nil
						end
						for entry in matched do
							owners[entry] = nil
							nodes[entry] = nil
							values[entry] = nil
							indices[entry] = nil
							rowKeys[entry] = nil
							items[entry] = nil
							positions[entry] = nil
							marks[entry] = nil
							table.insert(free, entry)
							retired[entry] = nil
						end
						table.clear(matched)
					end
					if nextEntry > count * 2 and next(retired) == nil then
						compact()
					end
				end
			end
			if not ok then
				error(failure, 0)
			end
		end)
	end
end

local function keyed<V, K>(options: Options<V, K>): Children.Directive
	local settings = Support.optionsOf(options, "keyed", "from = ..., key = ..., render = ...")
	Support.noUnknownFields(settings, "keyed", KNOWN_FIELDS)
	local render = Support.builderOf(settings.render, "keyed", "render")
	if settings.key == nil then
		return keyedWithKeys(settings.from, render, function(list: { V }, wanted: number, keys: { V })
			table.move(list, 1, wanted, 1, keys)
		end)
	end
	local key = Support.builderOf(settings.key, "keyed", "key")
	return keyedWithKeys(settings.from, render, function(list: { V }, wanted: number, keys: { K })
		for index = 1, wanted do
			keys[index] = key(list[index], index)
		end
	end)
end

return keyed
