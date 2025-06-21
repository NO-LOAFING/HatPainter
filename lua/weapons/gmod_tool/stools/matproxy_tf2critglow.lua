TOOL.Category = "Render"
TOOL.Name = "Color - TF2 Crit Glow / Jarate"
TOOL.Command = nil
TOOL.ConfigName = "" 
 
TOOL.ClientConVar["r"] = "80"
TOOL.ClientConVar["g"] = "8"
TOOL.ClientConVar["b"] = "5"
TOOL.ClientConVar["sparksr"] = "1"
TOOL.ClientConVar["sparksb"] = "0"
TOOL.ClientConVar["sparksc"] = "0"
TOOL.ClientConVar["sparksj"] = "0"
TOOL.ClientConVar["sparksjc"] = "0"

TOOL.Information = {
	{name = "left0", stage = 0, icon = "gui/lmb.png"},
	{name = "right0", stage = 0, icon = "gui/rmb.png"},
	{name = "reload0", stage = 0, icon = "gui/r.png"},
}

if CLIENT then
	language.Add("tool.matproxy_tf2critglow.name", "Color - TF2 Crit Glow / Jarate")
	language.Add("tool.matproxy_tf2critglow.desc", "Add a critboost or jarate effect to TF2 items and characters")

	language.Add("tool.matproxy_tf2critglow.left0", "Add crit glow / jarate")
	language.Add("tool.matproxy_tf2critglow.right0", "Copy crit glow / jarate")
	language.Add("tool.matproxy_tf2critglow.reload0", "Remove crit glow / jarate")

	language.Add("Undone_matproxy_tf2critglow", "Undone TF2 Crit Glow / Jarate")
end




function TOOL:LeftClick(trace)

	local ent = trace.Entity
	if IsValid(ent) then
		if SERVER then
			GiveMatproxyTF2CritGlow(self:GetOwner(), ent, {
				ColorR = self:GetClientNumber("r", 1),
				ColorG = self:GetClientNumber("g", 1),
				ColorB = self:GetClientNumber("b", 1),
				RedSparks = self:GetClientNumber("sparksr", 0),
				BluSparks = self:GetClientNumber("sparksb", 0),
				ColorableSparks = self:GetClientNumber("sparksc", 0),
				JarateSparks = self:GetClientNumber("sparksj", 0),
				JarateColorableSparks = self:GetClientNumber("sparksjc", 0),
			})
		end
		return true
	end

end




function TOOL:RightClick(trace)

	if IsValid(trace.Entity) then
		if SERVER then
			if IsValid(trace.Entity.AttachedEntity) then
				trace.Entity = trace.Entity.AttachedEntity
			end

			if trace.Entity.EntityMods and trace.Entity.EntityMods.MatproxyTF2CritGlow then
				self:GetOwner():ConCommand("matproxy_tf2critglow_r " .. trace.Entity.EntityMods.MatproxyTF2CritGlow.ColorR)
				self:GetOwner():ConCommand("matproxy_tf2critglow_g " .. trace.Entity.EntityMods.MatproxyTF2CritGlow.ColorG)
				self:GetOwner():ConCommand("matproxy_tf2critglow_b " .. trace.Entity.EntityMods.MatproxyTF2CritGlow.ColorB)
				self:GetOwner():ConCommand("matproxy_tf2critglow_sparksr " .. trace.Entity.EntityMods.MatproxyTF2CritGlow.RedSparks)
				self:GetOwner():ConCommand("matproxy_tf2critglow_sparksb " .. trace.Entity.EntityMods.MatproxyTF2CritGlow.BluSparks)
				self:GetOwner():ConCommand("matproxy_tf2critglow_sparksc " .. (trace.Entity.EntityMods.MatproxyTF2CritGlow.ColorableSparks or 0))        //nil on old dupes
				self:GetOwner():ConCommand("matproxy_tf2critglow_sparksj " .. (trace.Entity.EntityMods.MatproxyTF2CritGlow.JarateSparks or 0))           //^
				self:GetOwner():ConCommand("matproxy_tf2critglow_sparksjc " .. (trace.Entity.EntityMods.MatproxyTF2CritGlow.JarateColorableSparks or 0)) //^
			end
		end
		return true
	end

end




function TOOL:Reload(trace)

	if IsValid(trace.Entity) then
		if SERVER then
			if IsValid(trace.Entity.AttachedEntity) then
				trace.Entity = trace.Entity.AttachedEntity
			end

			local old = trace.Entity.ProxyentCritGlow
			if IsValid(old) then
				old:Remove()
				trace.Entity.ProxyentCritGlow = nil
				duplicator.ClearEntityModifier(trace.Entity, "MatproxyTF2CritGlow")
			end
		end
		return true
	end

end




if SERVER then

	function GiveMatproxyTF2CritGlow(ply, ent, Data)
		if !IsValid(ent) then return end
		if IsValid(ent.AttachedEntity) then
			ent = ent.AttachedEntity
		end

		local old = ent.ProxyentCritGlow
		if IsValid(old) and old:GetParent() == ent then //NOTE: Entities pasted using GenericDuplicatorFunction (i.e. anything without custom dupe functionality) will still have the original entity's Proxyent value saved into their table because GenericDuplicatorFunction uses table.Merge(). In most cases this won't matter because the saved Proxyent is NULL, but if the original entity still exists, then the value will point to THAT entity's Proxyent instead, which we don't want to delete by mistake.
			old:Remove()
		end

		local pent = ents.Create("proxyent_tf2critglow")
		if IsValid(pent) then
			pent:SetPos(ent:GetPos())
			pent:SetParent(ent)
			pent:SetColor(Color(Data.ColorR, Data.ColorG, Data.ColorB))
			pent:SetSparksRed(tobool(Data.RedSparks))
			pent:SetSparksBlu(tobool(Data.BluSparks))
			pent:SetSparksColorable(tobool(Data.ColorableSparks))             //This will be nil on older dupes, but I don't think that should matter here
			pent:SetSparksJarate(tobool(Data.JarateSparks))                   //^
			pent:SetSparksJarateColorable(tobool(Data.JarateColorableSparks)) //^
			ent.ProxyentCritGlow = pent
			ent:DeleteOnRemove(pent)
			pent:Spawn()
		end
		duplicator.StoreEntityModifier(ent, "MatproxyTF2CritGlow", Data)
	end

	duplicator.RegisterEntityModifier("MatproxyTF2CritGlow", GiveMatproxyTF2CritGlow)

end




local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", {Description = "#tool.matproxy_tf2critglow.desc"})

	//Presets
	panel:AddControl("ComboBox", {
		MenuButton = 1,
		Folder = "matproxy_tf2critglow",
		Options = {
			//["#preset.default"] = ConVarsDefault,
			//Include some presets by default:
			["Custom critboost, white"] = {
				matproxy_tf2critglow_r = "55",
				matproxy_tf2critglow_g = "55",
				matproxy_tf2critglow_b = "67",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "1",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Custom critboost, yellow"] = {
				matproxy_tf2critglow_r = "50",
				matproxy_tf2critglow_g = "50",
				matproxy_tf2critglow_b = "5",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "1",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Custom critboost, green"] = {
				matproxy_tf2critglow_r = "12",
				matproxy_tf2critglow_g = "56",
				matproxy_tf2critglow_b = "12",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "1",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Custom liquid, green"] = {
				matproxy_tf2critglow_r = "2",
				matproxy_tf2critglow_g = "7",
				matproxy_tf2critglow_b = "2",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "1",
			},
			["Custom liquid, pink"] = {
				matproxy_tf2critglow_r = "7",
				matproxy_tf2critglow_g = "2",
				matproxy_tf2critglow_b = "7",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "1",
			},
			["Custom liquid, black"] = {
				matproxy_tf2critglow_r = "0",
				matproxy_tf2critglow_g = "0",
				matproxy_tf2critglow_b = "0",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "1",
			},
			["Custom liquid, radioactive"] = {
				matproxy_tf2critglow_r = "1",
				matproxy_tf2critglow_g = "255",
				matproxy_tf2critglow_b = "1",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "1",
			},
			["Dripping yellow madness"] = {
				matproxy_tf2critglow_r = "255",
				matproxy_tf2critglow_g = "255",
				matproxy_tf2critglow_b = "0",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "1",
			},
		},
		CVars = table.GetKeys(ConVarsDefault)
	})

	//Color values confirmed from TF2 source code:
	//https://github.com/mastercomfig/tf2-patches/blob/main/src/game/client/tf/c_tf_player.cpp#L2301-L2334 (weapon glows)
	//https://github.com/mastercomfig/tf2-patches/blob/main/src/game/client/tf/c_tf_player.cpp#L2228 (jarate)
	local colorpanel = panel:AddControl("ListBox", {
		Label = "Color", 
		Height = 136, 
		Options = {
			["Critboost, RED"] = {
				matproxy_tf2critglow_r = "80",
				matproxy_tf2critglow_g = "8",
				matproxy_tf2critglow_b = "5",
				matproxy_tf2critglow_sparksr = "1",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Critboost, BLU"] = {
				matproxy_tf2critglow_r = "5",
				matproxy_tf2critglow_g = "20",
				matproxy_tf2critglow_b = "80",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "1",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Mini-crits, RED"] = {
				matproxy_tf2critglow_r = "226",
				matproxy_tf2critglow_g = "150",
				matproxy_tf2critglow_b = "62",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Mini-crits, BLU"] = {
				matproxy_tf2critglow_r = "29",
				matproxy_tf2critglow_g = "202",
				matproxy_tf2critglow_b = "135",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Hype mode"] = {
				matproxy_tf2critglow_r = "50",
				matproxy_tf2critglow_g = "2",
				matproxy_tf2critglow_b = "48",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "0",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Jarated, RED"] = {
				matproxy_tf2critglow_r = "6",
				matproxy_tf2critglow_g = "9",
				matproxy_tf2critglow_b = "2",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "1",
				matproxy_tf2critglow_sparksjc = "0",
			},
			["Jarated, BLU"] = {
				matproxy_tf2critglow_r = "7",
				matproxy_tf2critglow_g = "5",
				matproxy_tf2critglow_b = "1",
				matproxy_tf2critglow_sparksr = "0",
				matproxy_tf2critglow_sparksb = "0",
				matproxy_tf2critglow_sparksc = "0",
				matproxy_tf2critglow_sparksj = "1",
				matproxy_tf2critglow_sparksjc = "0",
			},
		},
	})
	colorpanel:ClearSelection()  //the default highlighting method is bad and starts off by highlighting ALL of the lines that have ANY matching convars - meaning, if we have any of 
				     //these selected, all of them will be highlighted by default since they all have sparksc = "0". not having anything selected by default isn't as bad.

	panel:AddControl("Color", {
		Label = "Color",
		Red = "matproxy_tf2critglow_r",
		Green = "matproxy_tf2critglow_g",
		Blue = "matproxy_tf2critglow_b",
		ShowHSV = 1,
		ShowRGB = 1,
		Multiplier = 255
	})

	panel:AddControl("CheckBox", {Label = "RED Sparks", Command = "matproxy_tf2critglow_sparksr"})
	panel:AddControl("CheckBox", {Label = "BLU Sparks", Command = "matproxy_tf2critglow_sparksb"})
	panel:AddControl("CheckBox", {Label = "Colorable Sparks", Command = "matproxy_tf2critglow_sparksc"})
	panel:AddControl("CheckBox", {Label = "Jarate Drips", Command = "matproxy_tf2critglow_sparksj"})
	panel:AddControl("CheckBox", {Label = "Colorable Drips", Command = "matproxy_tf2critglow_sparksjc"})

end