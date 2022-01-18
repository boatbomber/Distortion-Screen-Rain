--[=[
	Simple object pool to avoid constantly creating new objects
--]=]

local DISTANT_CF = CFrame.new(0, 0, 1_000_000)

local ObjectPool = {}

function ObjectPool.new(Object: Instance, InitialAmount: number?)
	local Pool = {
		Object = Object:Clone(),
		Available = {},
	}

	for i = 1, InitialAmount or 1 do
		Pool.Available[i] = Pool.Object:Clone()
	end

	function Pool:Get()
		local i = #Pool.Available
		local obj = Pool.Available[i]
		if obj then
			table.remove(Pool.Available, i)
			return obj
		else
			return Pool.Object:Clone()
		end
	end

	function Pool:Return(obj: BasePart)
		obj.CFrame = DISTANT_CF
		table.insert(Pool.Available, obj)
	end

	return Pool
end

return ObjectPool
