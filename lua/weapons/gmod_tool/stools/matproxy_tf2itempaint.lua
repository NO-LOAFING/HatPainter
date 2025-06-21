TOOL.Category = "Render"
TOOL.Name = "Color - TF2 Paint"
TOOL.Command = nil
TOOL.ConfigName = "" 
 
TOOL.ClientConVar["r"] = "45"
TOOL.ClientConVar["g"] = "45"
TOOL.ClientConVar["b"] = "36"
TOOL.ClientConVar["override"] = "0"
TOOL.ClientConVar["whichlist"] = "original"

TOOL.Information = {
	{name = "left0", stage = 0, icon = "gui/lmb.png"},
	{name = "right0", stage = 0, icon = "gui/rmb.png"},
	{name = "reload0", stage = 0, icon = "gui/r.png"},
}

if CLIENT then
	language.Add("tool.matproxy_tf2itempaint.name", "Color - TF2 Paint")
	language.Add("tool.matproxy_tf2itempaint.desc", "Paint TF2 items with any color, as long as they're paintable")

	language.Add("tool.matproxy_tf2itempaint.left0", "Add paint color")
	language.Add("tool.matproxy_tf2itempaint.right0", "Copy paint color")
	language.Add("tool.matproxy_tf2itempaint.reload0", "Remove paint color")

	language.Add("Undone_matproxy_tf2itempaint", "Undone TF2 Item Paint")
end




function TOOL:LeftClick(trace)

	local ent = trace.Entity
	if IsValid(ent) then
		if SERVER then
			local r = self:GetClientNumber("r", 0)
			local g = self:GetClientNumber("g", 0)
			local b = self:GetClientNumber("b", 0)
			//0,0,0 (and anything darker than 3,3,3) is used by the vmt to mean "no paint color", which means it'll get overwritten by the hat's
			//default color, so if the player is trying to paint something pure black, then redirect it to a color that actually works.
			if r < 3 and g < 3 and b < 3 then
				r = 3
				g = 3
				b = 3
			end

			GiveMatproxyTF2ItemPaint(self:GetOwner(), ent, {
				ColorR = r,
				ColorG = g,
				ColorB = b,
				Override = self:GetClientNumber("override", 0)
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

			if trace.Entity.EntityMods and trace.Entity.EntityMods.MatproxyTF2ItemPaint then
				self:GetOwner():ConCommand("matproxy_tf2itempaint_r " .. trace.Entity.EntityMods.MatproxyTF2ItemPaint.ColorR)
				self:GetOwner():ConCommand("matproxy_tf2itempaint_g " .. trace.Entity.EntityMods.MatproxyTF2ItemPaint.ColorG)
				self:GetOwner():ConCommand("matproxy_tf2itempaint_b " .. trace.Entity.EntityMods.MatproxyTF2ItemPaint.ColorB)
				self:GetOwner():ConCommand("matproxy_tf2itempaint_override " .. (trace.Entity.EntityMods.MatproxyTF2ItemPaint.Override or 0)) //nil on dupes from before 10/11/24
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

			local old = trace.Entity.ProxyentPaintColor
			if IsValid(old) then
				old:Remove()
				trace.Entity.ProxyentPaintColor = nil
				duplicator.ClearEntityModifier(trace.Entity, "MatproxyTF2ItemPaint")
			end
		end
		return true
	end

end




if SERVER then

	function GiveMatproxyTF2ItemPaint(ply, ent, Data)
		if !IsValid(ent) then return end
		if IsValid(ent.AttachedEntity) then
			ent = ent.AttachedEntity
		end

		local old = ent.ProxyentPaintColor
		if IsValid(old) and old:GetParent() == ent then //NOTE: Entities pasted using GenericDuplicatorFunction (i.e. anything without custom dupe functionality) will still have the original entity's Proxyent value saved into their table because GenericDuplicatorFunction uses table.Merge(). In most cases this won't matter because the saved Proxyent is NULL, but if the original entity still exists, then the value will point to THAT entity's Proxyent instead, which we don't want to delete by mistake.
			old:Remove()
		end

		local pent = ents.Create("proxyent_tf2itempaint")
		if IsValid(pent) then
			pent:SetPos(ent:GetPos())
			pent:SetParent(ent)
			pent:SetColor(Color(Data.ColorR, Data.ColorG, Data.ColorB))
			pent:SetPaintOverride(Data.Override or 0) //nil on dupes from before 10/11/24
			ent.ProxyentPaintColor = pent
			ent:DeleteOnRemove(pent)
			pent:Spawn()
		end
		duplicator.StoreEntityModifier(ent, "MatproxyTF2ItemPaint", Data)
	end

	duplicator.RegisterEntityModifier("MatproxyTF2ItemPaint", GiveMatproxyTF2ItemPaint)

end




local ConVarsDefault = TOOL:BuildConVarList()
ConVarsDefault["matproxy_tf2itempaint_whichlist"] = nil  //don't save the selected list in presets

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", {Description = "#tool.matproxy_tf2itempaint.desc"})

	//Presets
	panel:AddControl("ComboBox", {
		MenuButton = 1,
		Folder = "matproxy_tf2itempaint",
		//Options = {
		//	["#preset.default"] = ConVarsDefault
		//},
		CVars = table.GetKeys(ConVarsDefault)
	})

	panel:AddControl("ListBox", {
		Label = "Category",
		Height = 102,
		Options = {
			["1: Original Paints"] = {matproxy_tf2itempaint_whichlist = "original"},
			["2: The Bad-Paintening of December 2010"] = {matproxy_tf2itempaint_whichlist = "theonewithpinkandlime"},
			["3: \"Newer\" Paints"] = {matproxy_tf2itempaint_whichlist = "newpaints"},
			["4: Team Colors"] = {matproxy_tf2itempaint_whichlist = "teampaints"},
			["5: Halloween Spell Paints"] = {matproxy_tf2itempaint_whichlist = "spoopy"},
		},
	})

	panel.PaintList = panel:AddControl("ListBox", {
		Label = "Color",
		Height = 153,
		Options = {},
	})

	panel.PaintList.OldThink = panel.PaintList.Think
	panel.PaintList.Think = function(self, ...)
		local whichlist = GetConVar("matproxy_tf2itempaint_whichlist"):GetString()
		if whichlist != self.CurWhichlist then
			self.CurWhichlist = whichlist
			local data = {}

			//Original Paints
			if whichlist == "original" then
				data["A Deep Commitment to Purple"] = {
					matproxy_tf2itempaint_r = "125",
					matproxy_tf2itempaint_g = "64",
					matproxy_tf2itempaint_b = "113",
					matproxy_tf2itempaint_override = "0",
				}
				data["Aged Moustache Gray"] = {
					matproxy_tf2itempaint_r = "126",
					matproxy_tf2itempaint_g = "126",
					matproxy_tf2itempaint_b = "126",
					matproxy_tf2itempaint_override = "0",
				}
				data["Australium Gold"] = {
					matproxy_tf2itempaint_r = "231",
					matproxy_tf2itempaint_g = "181",
					matproxy_tf2itempaint_b = "59",
					matproxy_tf2itempaint_override = "0",
				}
				data["Color 216-190-216"] = {
					matproxy_tf2itempaint_r = "216",
					matproxy_tf2itempaint_g = "190",
					matproxy_tf2itempaint_b = "216",
					matproxy_tf2itempaint_override = "0",
				}
				data["Indubitably Green"] = {
					matproxy_tf2itempaint_r = "114",
					matproxy_tf2itempaint_g = "158",
					matproxy_tf2itempaint_b = "66",
					matproxy_tf2itempaint_override = "0",
				}
				data["Mann Co. Orange"] = {
					matproxy_tf2itempaint_r = "207",
					matproxy_tf2itempaint_g = "115",
					matproxy_tf2itempaint_b = "54",
					matproxy_tf2itempaint_override = "0",
				}
				data["Muskelmannbraun"] = {
					matproxy_tf2itempaint_r = "165",
					matproxy_tf2itempaint_g = "117",
					matproxy_tf2itempaint_b = "69",
					matproxy_tf2itempaint_override = "0",
				}
				data["Noble Hatter's Violet"] = {
					matproxy_tf2itempaint_r = "81",
					matproxy_tf2itempaint_g = "56",
					matproxy_tf2itempaint_b = "74",
					matproxy_tf2itempaint_override = "0",
				}
				data["Particularly Drab Tincture"] = {
					matproxy_tf2itempaint_r = "197",
					matproxy_tf2itempaint_g = "175",
					matproxy_tf2itempaint_b = "145",
					matproxy_tf2itempaint_override = "0",
				}
				data["Radigan Conagher Brown"] = {
					matproxy_tf2itempaint_r = "105",
					matproxy_tf2itempaint_g = "77",
					matproxy_tf2itempaint_b = "58",
					matproxy_tf2itempaint_override = "0",
				}
				data["Ye Olde Rustic Colour"] = {
					matproxy_tf2itempaint_r = "124",
					matproxy_tf2itempaint_g = "108",
					matproxy_tf2itempaint_b = "87",
					matproxy_tf2itempaint_override = "0",
				}
				data["Zepheniah's Greed"] = {
					matproxy_tf2itempaint_r = "66",
					matproxy_tf2itempaint_g = "79",
					matproxy_tf2itempaint_b = "59",
					matproxy_tf2itempaint_override = "0",
				}
				data["An Extraordinary Abundance of Tinge"] = {
					matproxy_tf2itempaint_r = "230",
					matproxy_tf2itempaint_g = "230",
					matproxy_tf2itempaint_b = "230",
					matproxy_tf2itempaint_override = "0",
				}
				data["A Distinctive Lack of Hue"] = {
					matproxy_tf2itempaint_r = "20",
					matproxy_tf2itempaint_g = "20",
					matproxy_tf2itempaint_b = "20",
					matproxy_tf2itempaint_override = "0",
				}
			//The Bad-Paintening of December 2010
			elseif whichlist == "theonewithpinkandlime" then
				data["A Color Similar to Slate"] = {
					matproxy_tf2itempaint_r = "47",
					matproxy_tf2itempaint_g = "79",
					matproxy_tf2itempaint_b = "79",
					matproxy_tf2itempaint_override = "0",
				}
				data["Dark Salmon Injustice"] = {
					matproxy_tf2itempaint_r = "233",
					matproxy_tf2itempaint_g = "150",
					matproxy_tf2itempaint_b = "122",
					matproxy_tf2itempaint_override = "0",
				}
				data["Drably Olive"] = {
					matproxy_tf2itempaint_r = "128",
					matproxy_tf2itempaint_g = "128",
					matproxy_tf2itempaint_b = "0",
					matproxy_tf2itempaint_override = "0",
				}
				data["The Color of a Gentlemann's Business Pants"] = {
					matproxy_tf2itempaint_r = "240",
					matproxy_tf2itempaint_g = "230",
					matproxy_tf2itempaint_b = "140",
					matproxy_tf2itempaint_override = "0",
				}
				data["The Bitter Taste of Defeat and Lime"] = {
					matproxy_tf2itempaint_r = "50",
					matproxy_tf2itempaint_g = "205",
					matproxy_tf2itempaint_b = "50",
					matproxy_tf2itempaint_override = "0",
				}
				data["Pink as Hell"] = {
					matproxy_tf2itempaint_r = "255",
					matproxy_tf2itempaint_g = "105",
					matproxy_tf2itempaint_b = "180",
					matproxy_tf2itempaint_override = "0",
				}
			//"Newer" Paints
			elseif whichlist == "newpaints" then
				data["A Mann's Mint"] = {
					matproxy_tf2itempaint_r = "188",
					matproxy_tf2itempaint_g = "221",
					matproxy_tf2itempaint_b = "179",
					matproxy_tf2itempaint_override = "0",
				}
				data["After Eight"] = {
					matproxy_tf2itempaint_r = "45",
					matproxy_tf2itempaint_g = "45",
					matproxy_tf2itempaint_b = "36",
					matproxy_tf2itempaint_override = "0",
				}
			//Team Colors
			elseif whichlist == "teampaints" then
				data["Team Spirit, RED"] = {
					matproxy_tf2itempaint_r = "184",
					matproxy_tf2itempaint_g = "56",
					matproxy_tf2itempaint_b = "59",
					matproxy_tf2itempaint_override = "0",
				}
				data["Team Spirit, BLU"] = {
					matproxy_tf2itempaint_r = "88",
					matproxy_tf2itempaint_g = "133",
					matproxy_tf2itempaint_b = "162",
					matproxy_tf2itempaint_override = "0",
				}
				data["The Value of Teamwork, RED"] = {
					matproxy_tf2itempaint_r = "128",
					matproxy_tf2itempaint_g = "48",
					matproxy_tf2itempaint_b = "32",
					matproxy_tf2itempaint_override = "0",
				}
				data["The Value of Teamwork, BLU"] = {
					matproxy_tf2itempaint_r = "37",
					matproxy_tf2itempaint_g = "109",
					matproxy_tf2itempaint_b = "141",
					matproxy_tf2itempaint_override = "0",
				}
				data["Waterlogged Lab Coat, RED"] = {
					matproxy_tf2itempaint_r = "168",
					matproxy_tf2itempaint_g = "154",
					matproxy_tf2itempaint_b = "140",
					matproxy_tf2itempaint_override = "0",
				}
				data["Waterlogged Lab Coat, BLU"] = {
					matproxy_tf2itempaint_r = "131",
					matproxy_tf2itempaint_g = "159",
					matproxy_tf2itempaint_b = "163",
					matproxy_tf2itempaint_override = "0",
				}
				data["An Air of Debonair, RED"] = {
					matproxy_tf2itempaint_r = "101",
					matproxy_tf2itempaint_g = "71",
					matproxy_tf2itempaint_b = "64",
					matproxy_tf2itempaint_override = "0",
				}
				data["An Air of Debonair, BLU"] = {
					matproxy_tf2itempaint_r = "40",
					matproxy_tf2itempaint_g = "57",
					matproxy_tf2itempaint_b = "77",
					matproxy_tf2itempaint_override = "0",
				}
				data["Balaclavas Are Forever, RED"] = {
					matproxy_tf2itempaint_r = "59",
					matproxy_tf2itempaint_g = "31",
					matproxy_tf2itempaint_b = "35",
					matproxy_tf2itempaint_override = "0",
				}
				data["Balaclavas Are Forever, BLU"] = {
					matproxy_tf2itempaint_r = "24",
					matproxy_tf2itempaint_g = "35",
					matproxy_tf2itempaint_b = "61",
					matproxy_tf2itempaint_override = "0",
				}
				data["Operator's Overalls, RED"] = {
					matproxy_tf2itempaint_r = "72",
					matproxy_tf2itempaint_g = "56",
					matproxy_tf2itempaint_b = "56",
					matproxy_tf2itempaint_override = "0",
				}
				data["Operator's Overalls, BLU"] = {
					matproxy_tf2itempaint_r = "56",
					matproxy_tf2itempaint_g = "66",
					matproxy_tf2itempaint_b = "72",
					matproxy_tf2itempaint_override = "0",
				}
				data["Cream Spirit, RED"] = {
					matproxy_tf2itempaint_r = "195",
					matproxy_tf2itempaint_g = "108",
					matproxy_tf2itempaint_b = "45",
					matproxy_tf2itempaint_override = "0",
				}
				data["Cream Spirit, BLU"] = {
					matproxy_tf2itempaint_r = "184",
					matproxy_tf2itempaint_g = "128",
					matproxy_tf2itempaint_b = "53",
					matproxy_tf2itempaint_override = "0",
				}
			//Halloween Spell Paints
			elseif whichlist == "spoopy" then
				//https://github.com/mastercomfig/tf2-patches/blob/main/src/game/shared/econ/econ_item_view.cpp#L1517
				//see override tables in proxyent_tf2itempaint
				data["Die Job"] = { matproxy_tf2itempaint_override = "1" } //&k_unWitchYellow[0],
				data["Chromatic Corruption"] = { matproxy_tf2itempaint_override = "2" } //&k_unDistinctiveLackOfSanity[0],
				data["Putrescent Pigmentation"] = { matproxy_tf2itempaint_override = "3" } //&k_unOverabundanceOfRottingFlesh[0],
				data["Spectral Spectrum, RED"] = { matproxy_tf2itempaint_override = "4" } //&k_unTheFlamesBelow[0], //red
				data["Spectral Spectrum, BLU"] = { matproxy_tf2itempaint_override = "6" } //&k_unBubbleBubble[0], //blu
				data["Sinister Staining"] = { matproxy_tf2itempaint_override = "5" } //&k_unThatQueesyFeeling[0],
				data["Afraid of Shadows (unused)"] = { matproxy_tf2itempaint_override = "7" } //&k_unAfraidOfShadowsDark[0],
			end

			//Replace the options currently in the panel with the ones in the data table
			panel.PaintList.Options = {}
			for name, command in pairs(data) do
				panel.PaintList.Options[name] = command
			end

			panel.PaintList:Clear()
			for k, v in pairs(panel.PaintList.Options) do
				local line = panel.PaintList:AddLine(k)
				line.data = v
				//If a line's color is currently selected, then highlight it (mostly for spells so players aren't confused as to why color picker is disabled)
				local selected = true
				for k2, v2 in pairs (v) do
					if GetConVar(k2):GetInt() != tonumber(v2) then selected = false end
				end
				if selected then line:SetSelected(true) end
			end
			panel.PaintList:SortByColumn(1, false)
		end
		//Disable color picker if a color override is selected, because it won't do anything until the player picks a non-override color to set it back to 0
		local override = GetConVar("matproxy_tf2itempaint_override"):GetInt()
		if override > 0 then
			panel.Col:SetEnabled(false)
		else
			panel.Col:SetEnabled(true)
		end
		if panel.PaintList.OldThink then
			return panel.PaintList.OldThink(self, ...)
		end
	end

	panel.Col = panel:AddControl("Color", {
		Label = "Color",
		Red = "matproxy_tf2itempaint_r",
		Green = "matproxy_tf2itempaint_g",
		Blue = "matproxy_tf2itempaint_b",
		ShowHSV = 1,
		ShowRGB = 1,
		Multiplier = 255,
	})

end