Matproxy_TF2CritGlow_UseModelGlowColor = {}

matproxy.Add(
{
	name = "ModelGlowColor",

	init = function(self, mat, values)

		self.ResultTo = values.resultvar

	end,

	bind = function(self, mat, ent)

		//don't use yellowlevel if the material has the modelglowcolor proxy
		//there's no way for the yellowlevel proxy to check if this proxy is here on the same material, and we can't set custom values on the material object either, so instead
		//store the name of the material in a table to tell yellowlevel to ignore it. this isn't perfect - if the vmt gets edited later on to not use this proxy, it won't know.
		Matproxy_TF2CritGlow_UseModelGlowColor[mat:GetName()] = true

		if IsValid(ent) and IsValid(ent.ProxyentCritGlow) and ent.ProxyentCritGlow.Color then
			mat:SetVector(self.ResultTo, ent.ProxyentCritGlow.Color)
		else
			mat:SetVector(self.ResultTo, Vector(1,1,1))
		end

	end
})





//use the yellowlevel (jarate) proxy as a fallback if the material doesn't have the modelglowcolor proxy.
//in tf2 these proxies can have separate color values that stack, but in gmod we only have a single color value that we're applying through either proxy, whichever the material happens to 
//have. we don't want them to stack here because that would apply the same color twice.
matproxy.Add(
{
	name = "YellowLevel",

	init = function(self, mat, values)

		self.ResultTo = values.resultvar

	end,

	bind = function(self, mat, ent)

		if IsValid(ent) and !Matproxy_TF2CritGlow_UseModelGlowColor[mat:GetName()] and ent.ProxyentCritGlow and ent.ProxyentCritGlow.Color then
			mat:SetVector(self.ResultTo, ent.ProxyentCritGlow.Color)
		else
			mat:SetVector(self.ResultTo, Vector(1,1,1))
		end

	end
})