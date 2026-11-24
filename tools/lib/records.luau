--!strict

local function read(value: unknown): { [unknown]: unknown }?
	if type(value) ~= "table" then
		return nil
	end
	local fields: { [unknown]: unknown } = {}
	for key, entry in value do
		fields[key] = entry
	end
	return fields
end

return { read = read }
