matproxy.Add(
{
	name = "ItemTintColor",

	init = function(self, mat, values)

		self.ResultTo = values.resultvar

	end,

	bind = function(self, mat, ent)

		if !IsValid(ent) then return end

		if IsValid(ent.ProxyentPaintColor) and ent.ProxyentPaintColor.Color then
			mat:SetVector(self.ResultTo, ent.ProxyentPaintColor.Color)
		else
			mat:SetVector(self.ResultTo, Vector(0,0,0))
		end

	end
})