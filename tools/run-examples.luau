--!strict

local process = require "@lute/process"

local Examples = require "../examples"

local function main(): number
	local failures = 0

	for _, example in Examples.all do
		local ok, result: any = pcall(example.run)
		if not ok then
			failures += 1
			print(("  FAIL  %-12s raised: %s"):format(example.name, tostring(result)))
		elseif result ~= example.expected then
			failures += 1
			print(("  FAIL  %-12s returned %q, expected %q"):format(example.name, tostring(result), example.expected))
		else
			print(("  ok    %-12s %s"):format(example.name, example.what))
			print(("        -> %s"):format(result))
		end
	end

	print(("\n%d example(s), %d failed"):format(#Examples.all, failures))
	return if failures == 0 then 0 else 1
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
