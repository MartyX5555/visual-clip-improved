/*
Visual Clip Tool
	by TGiFallen
	Credits to Ralle105 of facepunch
*/

TOOL.Category		= "Construction"
TOOL.Name			= "#Visual Clip"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["distance"] = "1"
TOOL.ClientConVar["p"] = "0"
TOOL.ClientConVar["y"] = "0"
TOOL.ClientConVar["inside"] = "0"


if CLIENT then

	TOOL.Information = {

		{ name = "left", icon = "gui/lmb.png"},
		{ name = "right", icon = "gui/rmb.png" },
		{ name = "reload", icon = "gui/r.png" },

	}

	language.Add( "tool.visual.name", "Visual Clip Tool" )
	language.Add( "tool.visual.desc", "Visually Clip entities" )
	language.Add( "tool.visual.left", "Clip an entity" )
	language.Add( "tool.visual.right", "Copy a Clip from the current entity. Click again to copy other clip of it" )
	language.Add( "tool.visual.reload", "Remove the latest clip" )

end


function TOOL:LeftClick( trace )

	if CLIENT then return true end
	
	local ply = self:GetOwner()
	local ent = trace.Entity

	if not ent:IsValid() or ent:IsWorld() or ent:IsPlayer() or ent == NULL then return end

	ent.ClipData = ent.ClipData or {}

	local pitch = ply:GetInfoNum("visual_p",0)
	local yaw   = ply:GetInfoNum("visual_y",0)
	local dist  = ply:GetInfoNum("visual_distance",1)
	local ins   = ply:GetInfoNum("visual_inside",1)

	if #ent.ClipData > 0 then

		for i=1, #ent.ClipData do

			local CAng = ent.ClipData[i]["n"]

			local Cpitch = CAng.p
			local Cyaw = CAng.y		

			if Cpitch == pitch and Cyaw == yaw then return true end

		end
	end

	local ind = table.insert(ent.ClipData , {
		n = Angle(pitch,yaw,0),
		d = dist,
		inside = tobool( ins or false ),
		new = true
	})

	SendPropClip( ent , nil , ind )
	duplicator.StoreEntityModifier( ent , "clips", ent.ClipData )
	if !table.HasValue( Clipped , ent ) then
		Clipped[ #Clipped + 1 ] =  ent
	end
	return true
end

--TODO: make a way to edit every clip
function TOOL:RightClick( trace )

	if CLIENT then return true end

	local ply = self:GetOwner()
	local ent = trace.Entity 

	if not ent:IsValid() or ent:IsWorld() or ent:IsPlayer() or ent == NULL then return end

	ent.ClipData = ent.ClipData or {}

	local dist = 0
	local pitch = 0
	local yaw = 0
	local ins = 0

	if ent.ClipData and #ent.ClipData > 0 then

		self.lastEnt = self.lastEnt or ent
		self.ClipInd = self.ClipInd or #ent.ClipData

		if #ent.ClipData > 1 then self.ClipInd = self.ClipInd - 1 end

		if ent ~= self.lastEnt or self.ClipInd <= 0 or self.ClipInd > #ent.ClipData then self.ClipInd = #ent.ClipData end

		self.lastEnt = ent

		local Ind = self.ClipInd
		local ClipAng = ent.ClipData[Ind]["n"]

		dist = ent.ClipData[Ind]["d"]
		pitch = ClipAng.p
		yaw = ClipAng.y
		ins = ent.ClipData[Ind]["inside"] and 1 or 0

	end

	ply:ConCommand( "visual_distance "..dist )
	ply:ConCommand( "visual_p " ..pitch )
	ply:ConCommand( "visual_y " ..yaw )
	ply:ConCommand( "visual_inside " ..ins )

	return true
end

function TOOL:Reload( trace )

	if CLIENT then return true end
	local ent = trace.Entity
	if not ent:IsValid() then return end

	ent.ClipData = ent.ClipData or {}
	local count = #ent.ClipData
	ent.ClipData[ count ] = nil

	if count == 1 then
		ent.ClipData = {}
		for k , v in pairs(Clipped) do
			if v == ent then
				Clipped[ k ] = nil
			end
		end
	end

	duplicator.ClearEntityModifier( ent, "clips" )

	umsg.Start("visual_clip_reset")
		umsg.Entity(ent)
	umsg.End()
	return true
end

if CLIENT then
	function TOOL.BuildCPanel( panel )

		panel:SetName( "#tool.visual.name" )
		panel:Help( "#tool.visual.desc" )
		panel:NumSlider( "Distance" , "visual_distance" , -100 , 100, 4 )
		panel:NumSlider( "Pitch" , "visual_p" , -180 , 180, 4 )
		panel:NumSlider( "Yaw" , "visual_y" , -180 , 180, 4 )
		panel:Button( "Reset" , "visual_reset" , 1)
		panel:CheckBox( "Render inside of prop", "visual_inside" )
		panel:ControlHelp( "Clicking this will render the inside of the prop" )
		panel:NumSlider( "Max clips per prop" , "max_clips_per_prop" , 0 , 25 , 0 )
		panel:Button( "Refresh clips" , "cliptool_request_clips" , 1)

	end
end
