--!strict

local Lute = require "../.lute/dependencies/verify/src/lute"

local function measure<T>(spec: Lute.MemorySpec<T>, plantedBytes: number?, released: boolean?): Lute.MemoryResult
	local bytes = plantedBytes or 0
	assert(bytes >= 0 and bytes <= 16 * 1024 * 1024 and bytes % 1 == 0)
	local retained: buffer? = nil
	local setups = 0
	local rehearsals = spec.rehearsals or 0
	local result = Lute.memory.measure({
		setup = function(): T
			setups += 1
			if bytes > 0 and setups > rehearsals then
				retained = buffer.create(bytes)
			end
			return spec.setup()
		end,
		run = spec.run,
		afterRun = spec.afterRun,
		teardown = function(sample: T)
			if released then
				retained = nil
			end
			spec.teardown(sample)
		end,
		warmup = spec.warmup,
		iterations = spec.iterations,
		rehearsals = rehearsals,
	}, { cycles = 8, maxAllocations = 2500000, deadlineSeconds = 10 })
	if retained ~= nil then
		assert(buffer.len(retained) == bytes)
	end
	return result
end

return measure
