--!strict

export type Expectation = {
	toBe: (self: Expectation, expected: unknown) -> (),
	toEqual: (self: Expectation, expected: unknown) -> (),
	toBeNil: (self: Expectation) -> (),
	toBeOk: (self: Expectation) -> (),
	toBeTruthy: (self: Expectation) -> (),
	toBeFalsy: (self: Expectation) -> (),
	toBeCloseTo: (self: Expectation, expected: number, tolerance: number?) -> (),
	toBeLessThan: (self: Expectation, expected: number) -> (),
	toBeGreaterThan: (self: Expectation, expected: number) -> (),
	toBeLessThanOrEqual: (self: Expectation, expected: number) -> (),
	toBeGreaterThanOrEqual: (self: Expectation, expected: number) -> (),
	toContain: (self: Expectation, expected: unknown) -> (),
	toHaveLength: (self: Expectation, expected: number) -> (),
	toThrow: (self: Expectation, pattern: string?) -> (),
	never: Expectation,
}

local MAX_RENDER_DEPTH = 4

local render: (value: unknown, depth: number, seen: { [any]: true }) -> string

local function renderKey(key: unknown): string
	if type(key) == "string" and string.match(key, "^[%a_][%w_]*$") ~= nil then
		return key
	end
	return "[" .. render(key, MAX_RENDER_DEPTH, {}) .. "]"
end

function render(value: unknown, depth: number, seen: { [any]: true }): string
	local kind = type(value)
	if kind == "string" then
		return string.format("%q", value :: string)
	elseif kind ~= "table" then
		return tostring(value)
	end

	local subject = value :: { [any]: any }
	if seen[subject] then
		return "<cycle>"
	end
	if depth <= 0 then
		return "<table>"
	end
	seen[subject] = true

	local pieces: { string } = {}
	local count = #subject
	for index = 1, count do
		table.insert(pieces, render(subject[index], depth - 1, seen))
	end

	local namedKeys: { any } = {}
	for key in subject do
		if not (type(key) == "number" and key % 1 == 0 and key >= 1 and key <= count) then
			table.insert(namedKeys, key)
		end
	end
	table.sort(namedKeys, function(left, right)
		return tostring(left) < tostring(right)
	end)
	for _, key in namedKeys do
		table.insert(pieces, renderKey(key) .. " = " .. render(subject[key], depth - 1, seen))
	end

	seen[subject] = nil
	return "{ " .. table.concat(pieces, ", ") .. " }"
end

local function describeValue(value: unknown): string
	return render(value, MAX_RENDER_DEPTH, {})
end

local function deepEquals(left: unknown, right: unknown): boolean
	if left == right then
		return true
	end
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
	end

	local leftTable = left :: { [any]: any }
	local rightTable = right :: { [any]: any }
	for key, leftValue in leftTable do
		if not deepEquals(leftValue, rightTable[key]) then
			return false
		end
	end
	for key in rightTable do
		if leftTable[key] == nil then
			return false
		end
	end
	return true
end

local function fail(negated: boolean, verb: string, actual: unknown, detail: string?): never
	local prefix = if negated then "expected NOT " else "expected "
	local message = prefix .. verb
	if detail ~= nil then
		message ..= " " .. detail
	end
	message ..= "\n     actual: " .. describeValue(actual)
	return error(message, 0) :: never
end

local function makeExpectation(actual: unknown, negated: boolean): Expectation
	local expectation = {} :: any

	local function assertThat(holds: boolean, verb: string, detail: string?)
		if holds == negated then
			fail(negated, verb, actual, detail)
		end
	end

	local function misuse(message: string): never
		return error(message, 3) :: never
	end

	local function asNumber(): number
		if type(actual) ~= "number" then
			return misuse("expected a number for a numeric comparison, got " .. describeValue(actual))
		end
		return actual :: number
	end

	function expectation:toBe(expected: unknown)
		assertThat(actual == expected, "to be", describeValue(expected))
	end

	function expectation:toEqual(expected: unknown)
		assertThat(deepEquals(actual, expected), "to deeply equal", describeValue(expected))
	end

	function expectation:toBeNil()
		assertThat(actual == nil, "to be nil")
	end

	function expectation:toBeOk()
		assertThat(actual ~= nil, "to be non-nil")
	end

	function expectation:toBeTruthy()
		assertThat(not not actual, "to be truthy")
	end

	function expectation:toBeFalsy()
		assertThat(not actual, "to be falsy")
	end

	function expectation:toBeCloseTo(expected: number, tolerance: number?)
		local epsilon = if tolerance ~= nil then tolerance else 1e-9
		assertThat(
			math.abs(asNumber() - expected) <= epsilon,
			"to be within " .. tostring(epsilon) .. " of",
			tostring(expected)
		)
	end

	function expectation:toBeLessThan(expected: number)
		assertThat(asNumber() < expected, "to be less than", tostring(expected))
	end

	function expectation:toBeGreaterThan(expected: number)
		assertThat(asNumber() > expected, "to be greater than", tostring(expected))
	end

	function expectation:toBeLessThanOrEqual(expected: number)
		assertThat(asNumber() <= expected, "to be at most", tostring(expected))
	end

	function expectation:toBeGreaterThanOrEqual(expected: number)
		assertThat(asNumber() >= expected, "to be at least", tostring(expected))
	end

	function expectation:toContain(expected: unknown)
		if type(actual) == "string" then
			local found = type(expected) == "string"
				and string.find(actual :: string, expected :: string, 1, true) ~= nil
			assertThat(found, "to contain substring", describeValue(expected))
			return
		end
		if type(actual) ~= "table" then
			misuse("expected a string or table for toContain, got " .. describeValue(actual))
		end
		local found = false
		for _, candidate in actual :: { [any]: any } do
			if deepEquals(candidate, expected) then
				found = true
				break
			end
		end
		assertThat(found, "to contain", describeValue(expected))
	end

	function expectation:toHaveLength(expected: number)
		if type(actual) == "string" then
			assertThat(#(actual :: string) == expected, "to have length", tostring(expected))
			return
		end
		if type(actual) ~= "table" then
			misuse("expected a string or table for toHaveLength, got " .. describeValue(actual))
		end
		local length = #(actual :: { any })
		assertThat(length == expected, "to have length", tostring(expected) .. " (was " .. tostring(length) .. ")")
	end

	function expectation:toThrow(pattern: string?)
		if type(actual) ~= "function" then
			misuse("expected a function for toThrow, got " .. describeValue(actual))
		end
		local ok, err: any = pcall(actual :: () -> ())
		if negated then
			if not ok then
				error("expected NOT to throw, but it threw: " .. tostring(err), 0)
			end
			return
		end
		if ok then
			error("expected to throw, but it returned normally", 0)
		end
		if pattern ~= nil then
			local text = tostring(err)
			if string.find(text, pattern, 1, true) == nil and string.find(text, pattern) == nil then
				error(("expected the thrown error to match %q\n     actual: %s"):format(pattern, text), 0)
			end
		end
	end

	if not negated then
		expectation.never = makeExpectation(actual, true)
	end

	return (expectation :: any) :: Expectation
end

local function expect(actual: unknown): Expectation
	return makeExpectation(actual, false)
end

return {
	expect = expect,
	deepEquals = deepEquals,
	describeValue = describeValue,
}
