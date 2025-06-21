AddCSLuaFile()

//Old entity class used by removed "Bone Merger Compatibility Mode" option. This feature only existed to get around a bug with the old Bone Merger tool that's been fixed for years now, 
//and it caused a lot more problems than it solved. This code only still exists so as to not break old saves and dupes.

ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Effect (replacement)"
ENT.Author			= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false




function ENT:SpawnFunction(pl, tr)
	if CLIENT then return end
	if !tr.Hit then return end
	local posSpawn = tr.HitPos
	local angSpawn = tr.HitNormal:Angle()
	angSpawn.p = angSpawn.p +90
	
	local ent = ents.Create("prop_replacementeffect")
	ent:SetPos(posSpawn)
	ent:SetAngles(angSpawn)
	ent:SetModel("models/gman_high.mdl")
	ent:Spawn()
	ent:Activate()
	return ent
end



function ENT:Initialize()

//	local maxs = self:OBBMaxs()
//	local mins = self:OBBMins()
//	self:SetCollisionBounds(mins,maxs)
//
//	//self.Entity:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )  
//	self:PhysicsInit(SOLID_OBB)
//	self:SetSolid(SOLID_OBB)
//	self:SetMoveType(MOVETYPE_NONE)

	//if SERVER then
	self.Entity:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_NONE)
	//end

end




duplicator.RegisterEntityClass("prop_replacementeffect", function(ply, data)
	local dupedent = ents.Create("prop_replacementeffect")
	if (!dupedent:IsValid()) then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(dupedent, data)
	duplicator.DoGenericPhysics(dupedent, data)

	dupedent:Spawn()
	dupedent:Activate()

	return dupedent
end, "Data")