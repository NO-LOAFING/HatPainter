AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Proxy Ent - TF2 Crit Glow"
ENT.Author			= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup			= RENDERGROUP_NONE




function ENT:SetupDataTables()

	self:NetworkVar("Bool", 0, "SparksRed")
	self:NetworkVar("Bool", 1, "SparksBlu")
	self:NetworkVar("Bool", 2, "SparksColorable")
	self:NetworkVar("Bool", 3, "SparksJarate")
	self:NetworkVar("Bool", 4, "SparksJarateColorable")

end




function ENT:Initialize()

	if SERVER then self:SetTransmitWithParent(true) end

	local ent = self:GetParent()
	if CLIENT then
		//Store color as a vector so the proxy func doesn't have to make a new one each frame
		local col = self:GetColor()
		self.Color = Vector(col.r, col.g, col.b)
		if IsValid(ent) then
			//Expose this value to the client so the matproxy can pick it up
			ent.ProxyentCritGlow = self
		end
	end

	self:SetNoDraw(true)
	self:SetModel("models/props_junk/watermelon01.mdl") //dummy model to prevent addons that look for the error model from affecting this entity
	self:DrawShadow(false) //make sure the ent's shadow doesn't render, just in case RENDERGROUP_NONE/SetNoDraw don't work and we have to rely on the blank draw function

	if SERVER then
		//fix for posable medigun beams addon - if the thing we've been attached to is a kritz poser, then find its kritz part and attach a copy of ourselves to it
		if IsValid(ent) and ent:GetClass() == "medigun_poser_blu_kritz" or "medigun_poser_red_kritz" then
			for _, ent2 in pairs (ent:GetChildren()) do
				if ent2:GetClass() == "medigun_kritz_part" then
					local pent = ents.Create("proxyent_tf2critglow")
					pent:SetParent(ent2)
					pent:SetColor(self:GetColor())
					ent2:DeleteOnRemove(pent)
					self:DeleteOnRemove(pent)
					pent:Spawn()
				end
			end
		end
	end

	PrecacheParticleSystem("critgun_weaponmodel_red")
	PrecacheParticleSystem("critgun_weaponmodel_blu")
	PrecacheParticleSystem("critgun_weaponmodel_colorable")
	PrecacheParticleSystem("peejar_drips")
	PrecacheParticleSystem("peejar_drips_colorable")

	if CLIENT then
		if IsValid(ent) then
			self.SparkParticleEffects = {}
			if self:GetSparksRed() then
				self.SparkParticleEffects.SparksRed = ent:CreateParticleEffect("critgun_weaponmodel_red", {
					{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW}
				})
			end
			if self:GetSparksBlu() then
				self.SparkParticleEffects.SparksBlu = ent:CreateParticleEffect("critgun_weaponmodel_blu", {
					{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW}
				})
			end
			if self:GetSparksColorable() then
				self.SparkParticleEffects.SparksColorable = ent:CreateParticleEffect("critgun_weaponmodel_colorable", {
					{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW},  //we overbrighten the color value (second controlpoint) by a large amount because
					{position = (Vector(65,65,65) + (self.Color * 3))}	//crit color values actually tend to be pretty low to avoid overpowering the texture
				})
			end
			if self:GetSparksJarate() then
				self.SparkParticleEffects.SparksJarate = ent:CreateParticleEffect("peejar_drips", {
					{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW}
				})
			end
			if self:GetSparksJarateColorable() then
				self.SparkParticleEffects.SparksJarateColorable = ent:CreateParticleEffect("peejar_drips_colorable", {
					{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW},  //we overbrighten the color value for jarate drips even more,
					{position = self.Color * 40}				//because jarate color values are so low they're in the single digits
				})
			end
		end
	end

	//This needs to be a CallOnRemove and not ENT:OnRemove because self:GetParent will return null
	self:CallOnRemove("RemoveProxyentCritGlow", function(self, ent)
		if IsValid(ent) then
			if CLIENT then
				for _, particle in pairs (self.SparkParticleEffects) do
					particle:StopEmission()
				end
			end
	
			if ent.ProxyentCritGlow == self then 
				ent.ProxyentCritGlow = nil
			end
		end
	end, ent)

end




//Entity still renders for some users despite having RENDERGROUP_NONE and self:SetNoDraw(true) (why?), so try to get around this by having a blank draw function
function ENT:Draw()
end




//prevent the entity from being duplicated
duplicator.RegisterEntityClass("proxyent_tf2critglow", function(ply, data) end, "Data")