--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local Test = require "../tests/harness"

type ManifestEntry = Test.ManifestEntry

local ROOT = "tests"
local MANIFEST_PATH = "tests/manifest.luau"

local HEADER = [[--!strict

local Verify = require "../.lute/dependencies/verify/src/core"

local manifest: Verify.Manifest = {
	schemaVersion = 1,
	entries = {]]

local function quotedList(values: { string }): string
	if #values == 0 then
		return "{}"
	end
	local pieces: { string } = {}
	for _, value in values do
		table.insert(pieces, ("%q"):format(value))
	end
	return "{ " .. table.concat(pieces, ", ") .. " }"
end

local function render(entries: { ManifestEntry }): string
	local out: { string } = { HEADER }
	for _, entry in entries do
		table.insert(out, "\t\t{")
		table.insert(out, ("\t\t\tid = %q,"):format(entry.id))
		table.insert(out, ("\t\t\tsource = %q,"):format(entry.source))
		table.insert(out, ("\t\t\tgroup = %q,"):format(entry.group or entry.id))
		table.insert(out, ("\t\t\ttags = %s,"):format(quotedList(entry.tags or {})))
		table.insert(out, ("\t\t\trequires = %s,"):format(quotedList(entry.requires or {})))
		table.insert(out, "\t\t},")
	end
	table.insert(out, "\t},")
	table.insert(out, "}")
	table.insert(out, "")
	table.insert(out, "return manifest")
	table.insert(out, "")
	return table.concat(out, "\n")
end

local function describe(entry: ManifestEntry): string
	return ("%s | %s | %s | %s | %s"):format(
		entry.id,
		entry.source,
		entry.group or entry.id,
		table.concat(entry.tags or {}, ","),
		table.concat(entry.requires or {}, ",")
	)
end

local function main(): number
	local write = false
	for index = 2, #process.args do
		local argument = process.args[index]
		if argument == "--write" then
			write = true
		else
			error(("check-test-manifest: unrecognised argument %q"):format(tostring(argument)), 0)
		end
	end

	local generated = Test.generate(ROOT)

	if write then
		fs.writeStringToFile(MANIFEST_PATH, render(generated.entries))
		process.run { "stylua", MANIFEST_PATH }
		print(("check-test-manifest: wrote %s (%d entries)"):format(MANIFEST_PATH, #generated.entries))
		return 0
	end

	if not fs.exists(MANIFEST_PATH) then
		print(("check-test-manifest: %s is missing; run with --write"):format(MANIFEST_PATH))
		return 1
	end

	local committed = (require "../tests/manifest" :: any) :: Test.Manifest

	Test.sources(committed)

	local onDisk: { [string]: string } = {}
	local order: { string } = {}
	for _, entry in generated.entries do
		onDisk[entry.source] = describe(entry)
		table.insert(order, entry.source)
	end

	local findings: { string } = {}
	local named: { [string]: boolean } = {}
	for index, entry in committed.entries do
		named[entry.source] = true
		local expected = onDisk[entry.source]
		if expected == nil then
			table.insert(findings, ("manifest names %s, which is not on disk"):format(entry.source))
			continue
		end
		local actual = describe(entry)
		if actual ~= expected then
			table.insert(
				findings,
				("%s\n      manifest: %s\n      disk:     %s"):format(entry.source, actual, expected)
			)
		end
		if order[index] ~= entry.source then
			table.insert(
				findings,
				("%s is entry %d in the manifest and %s is entry %d on disk; order is part of a reproducible run"):format(
					entry.source,
					index,
					tostring(order[index]),
					index
				)
			)
		end
	end
	for _, source in order do
		if not named[source] then
			table.insert(findings, ("%s is on disk and not in the manifest"):format(source))
		end
	end

	if #findings > 0 then
		print(("check-test-manifest: %d finding(s); regenerate with --write"):format(#findings))
		for _, finding in findings do
			print("  " .. finding)
		end
		return 1
	end

	print(
		("check-test-manifest: %s is the run authority and matches disk (%d entries)"):format(
			MANIFEST_PATH,
			#committed.entries
		)
	)
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
