--!strict

local Types = require "../../src/core/reactive/types"

local function cellAsReadable<T>(value: Types.Cell<T>): Types.Readable<T>
	return value
end

return {
	cellAsReadable = cellAsReadable,
}
