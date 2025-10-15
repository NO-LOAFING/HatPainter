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
		self.SparkParticleEffects = {} //This gets populated in the think func
	end

	//This needs to be a CallOnRemove and not ENT:OnRemove because self:GetParent will return null
	self:CallOnRemove("RemoveProxyentCritGlow", function(self, ent)
		if IsValid(ent) then
			if CLIENT then
				for _, particle in pairs (self.SparkParticleEffects) do
					if particle.IsValid and particle:IsValid() then
						particle:StopEmission()
					end
				end
			end
	
			if ent.ProxyentCritGlow == self then 
				ent.ProxyentCritGlow = nil
			end
		end
	end, ent)

end




if CLIENT then
	
	//Create spark/drip particles; do this every think to fix issues where fx fail to spawn or get removed by something (for example, back when we 
	//were doing this in initialize, newly connecting clients in MP would try to spawn the fx while loading into the server, but the fx would be 
	//invalid by the time they had fully loaded into the game. not sure if they were failing to spawn or getting removed after, but it doesn't matter.)

	local function DoSparkParticleEffect(self, ent, var, pname, ptab)

		if self["Get" .. var](self) and (!self.SparkParticleEffects[var] or !self.SparkParticleEffects[var].IsValid or !self.SparkParticleEffects[var]:IsValid()) then
			self.SparkParticleEffects[var] = ent:CreateParticleEffect(pname, ptab)
		end

	end

	function ENT:Think()

		local ent = self:GetParent()
		if IsValid(ent) then
			DoSparkParticleEffect(self, ent, "SparksRed", "critgun_weaponmodel_red", {
				{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW}
			})
			DoSparkParticleEffect(self, ent, "SparksBlu", "critgun_weaponmodel_blu", {
				{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW}
			})
			DoSparkParticleEffect(self, ent, "SparksColorable", "critgun_weaponmodel_colorable", {
				{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW},  //we overbrighten the color value (second controlpoint) by a large amount because
				{position = (Vector(65,65,65) + (self.Color * 3))}	//crit color values actually tend to be pretty low to avoid overpowering the texture
			})
			DoSparkParticleEffect(self, ent, "SparksJarate", "peejar_drips", {
				{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW}
			})
			DoSparkParticleEffect(self, ent, "SparksJarateColorable", "peejar_drips_colorable", {
				{entity = ent, attachtype = PATTACH_ABSORIGIN_FOLLOW},  //we overbrighten the color value for jarate drips even more,
				{position = self.Color * 40}				//because jarate color values are so low they're in the single digits
			})
		end

	end

end




//Entity still renders for some users despite having RENDERGROUP_NONE and self:SetNoDraw(true) (why?), so try to get around this by having a blank draw function
function ENT:Draw()
end




//prevent the entity from being duplicated
duplicator.RegisterEntityClass("proxyent_tf2critglow", function(ply, data) end, "Data")