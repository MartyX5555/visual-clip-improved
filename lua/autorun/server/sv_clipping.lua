AddCSLuaFile("autorun/client/clipping.lua")
AddCSLuaFile("autorun/client/preview.lua")
util.AddNetworkString( "VisualClip_newclip" )
util.AddNetworkString( "VisualClip_clip_data" )
util.AddNetworkString( "VisualClip_clip_data_PA" )
Clipped = {}

duplicator.RegisterEntityModifier( "clips", function( ply , Entity , data)
	if not Entity:IsValid() then return end
	Entity.ClipData = data
	
	if not table.HasValue( Clipped , Entity ) then
		Clipped[ #Clipped + 1 ] =  Entity
	end
	
	timer.Simple(1, function()
		for _,v in pairs( player.GetAll() ) do
			if not Entity:IsValid() then return end

			SendPropClip( Entity, v )
		end
	end)
	duplicator.StoreEntityModifier( Entity, "clips", Entity.ClipData )
end)


local function RemoveFromTable( ent )
	for i , e in pairs(Clipped) do
		if ent == e then
			table.remove( Clipped , i )
		end
	end
end

function SendPropClip( Entity , ply , ind )
	
	Entity:CallOnRemove( "RemoveFromClippedTable" , RemoveFromTable )
	
	local Data = Entity.ClipData
	if IsValid( ply ) then
		for k , v in pairs(Data) do
			net.Start("VisualClip_newclip")
				net.WriteEntity(Entity)
				net.WriteFloat(v.n.p)
				net.WriteFloat(v.n.y)
				net.WriteFloat(v.n.r)
				net.WriteFloat(v.d)
				net.WriteBit(v.inside)
				net.WriteBit(v.new or false )
			net.Send( ply )
		end
		return
	end
	if ind then 
		Data = Data[ ind ]
		net.Start("VisualClip_newclip")
			net.WriteEntity(Entity)
			net.WriteFloat(Data.n.p)
			net.WriteFloat(Data.n.y)
			net.WriteFloat(Data.n.r)
			net.WriteFloat(Data.d)
			net.WriteBit(Data.inside)
			net.WriteBit(Data.new or false )
		net.Broadcast()
	else
		for k , Data in pairs(Data) do
			net.Start("VisualClip_newclip")
				net.WriteEntity(Entity)
				net.WriteFloat(Data.n.p)
				net.WriteFloat(Data.n.y)
				net.WriteFloat(Data.n.r)
				net.WriteFloat(Data.d)
				net.WriteBit(Data.inside)
				net.WriteBit(Data.new or false )
			net.Broadcast()
		end
	end
end

local function SlowSendClips( inc  , ply)	
	local ent = Clipped[inc]
	if IsValid(ent) then 
		SendPropClip( ent , ply )
	end
	inc = inc + 1
	if inc > table.Count(Clipped) then
		return
	end
	timer.Simple( 0 , function() SlowSendClips( inc , ply ) end)
end

local function OnRequestClips( ply , command , args )
	if !ply or !IsValid( ply ) then return end
	
	timer.Simple( 0 , function() SlowSendClips( 1 , ply ) end)
end
concommand.Add( "cliptool_request_clips" , OnRequestClips )

hook.Add("PlayerInitialSpawn", "VisualClip.NewPlayer", function( ply )
	timer.Simple( 5 , function() ply:ConCommand("cliptool_request_clips") end)
end)