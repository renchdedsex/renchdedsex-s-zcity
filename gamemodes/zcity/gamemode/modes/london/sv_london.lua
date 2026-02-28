MODE.name = "london"
MODE.PrintName = "London"

MODE.OverideSpawnPos = true
MODE.LootSpawn = false
MODE.ForBigMaps = false
MODE.Chance = 0.001

local londonWeapons = {
    "weapon_stiletto",
    "weapon_navaja",
    "weapon_bowie",
    "weapon_pocketknife",
    "weapon_hg_crowbar",
    "weapon_bat"
}

local londonConsumables = {
    "weapon_bigconsumable",
    "weapon_fentanyl",
    "weapon_ducttape",
    "weapon_tourniquet",
    "weapon_bandage_sh",
    "weapon_hg_smokenade_tpik",
    "weapon_painkillers"
}

local londonArmorChance = 20

local lawWeapons = {
    "weapon_hg_tonfa",
    "weapon_taser",
    "weapon_walkie_talkie",
    "weapon_handcuffs",
    "weapon_handcuffs_key"
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end

util.AddNetworkString("london_start")
util.AddNetworkString("london_roundend")

function MODE:Intermission()
    game.CleanUpMap()


    self.londonPoints = {}
    table.CopyFromTo(zb.GetMapPoints("RIOT_TDM_LAW"), self.londonPoints)

    self.LawPoints = {}
    table.CopyFromTo(zb.GetMapPoints("RIOT_TDM_RIOTERS"), self.LawPoints)

	local ctpos
	local tpos
	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local pos
		if ply:Team() == 1 then
			if !ctpos then
				ctpos = #self.LawPoints > 0 and self.LawPoints[1].pos or zb:GetRandomSpawn()
				pos = ctpos
			else
				pos = hg.tpPlayer(ctpos, ply, i, 0)
			end
		end

		if ply:Team() == 0 then
			if !tpos then
				tpos = #self.londonPoints > 0 and self.londonPoints[1].pos or zb:GetRandomSpawn()
				pos = tpos
			else
				pos = hg.tpPlayer(tpos, ply, i, 0)
			end
		end

		ply:SetupTeam(ply:Team())

		if pos then
			ply:SetPos(pos)
		end
	end

    net.Start("london_start")
    net.Broadcast()
end


function MODE:CheckAlivePlayers()
    local swatPlayers = {}
    local banditPlayers = {}

    for _, ply in ipairs(team.GetPlayers(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(swatPlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(banditPlayers, ply)
        end
    end

    return {swatPlayers, banditPlayers}
end


function MODE:EndRound()
    timer.Simple(2,function()
        net.Start("london_roundend")
        net.Broadcast()
    end)
end


function MODE:ShouldRoundEnd()
    local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
    return endround
end

function MODE:RoundStart()
end


function MODE:GiveEquipment()
    local players = player.GetAll()
    table.Shuffle(players)

    local numPlayers = #players
    local numLawEnforcers = math.max(math.floor(numPlayers / 2) + 1)
    local numlondoners = numPlayers - numLawEnforcers

    local pipebomberCount = 0  
    local hasMp80 = false

    for i = 1, numlondoners do
        local ply = players[i]
        if ply:Team() == TEAM_SPECTATOR then continue end
    
        ply:SetupTeam(0)

        ply:SetPlayerClass("black")
    
        zb.GiveRole(ply, "Black gang member", Color(10, 10, 10))
    
        ply:Give("weapon_hands_sh")

        if pipebomberCount < 1 then
            ply:Give("weapon_hg_glassshard_taped")
            pipebomberCount = pipebomberCount + 1
        elseif not hasMp80 then
            ply:Give("weapon_travmat")
            hasMp80 = true
        end

		ply:SetNetVar("CurPluv", "pluvmajima")

        ply:Give(londonConsumables[math.random(#londonConsumables)])
    
        if math.random(100) <= londonArmorChance then
            hg.AddArmor(ply, "ent_armor_helmet2")
        end
    
        local londonWeapon = londonWeapons[math.random(#londonWeapons)]
        local wep = ply:Give(londonWeapon)

        if IsValid(wep) then
            ply:SelectWeapon(wep:GetClass())
        end
    end
    

    for i = numlondoners + 1, numPlayers do
        local ply = players[i]
        if ply:Team() == TEAM_SPECTATOR then continue end

        ply:SetupTeam(1)
        ply:SetPlayerClass("white")

        zb.GiveRole(ply, "White gang member", Color(210, 210, 210))
        ply:Give("weapon_hands_sh")

        ply:SetNetVar("CurPluv", "pluvberet")

        ply:Give(londonConsumables[math.random(#londonConsumables)])

        if math.random(100) <= londonArmorChance then
            hg.AddArmor(ply, "ent_armor_helmet2")
        end

        if i == numlondoners + 1 then
            ply:Give("weapon_osapb")
        end

        local londonWeapon = londonWeapons[math.random(#londonWeapons)]
        local wep = ply:Give(londonWeapon)

        if IsValid(wep) then
            ply:SelectWeapon(wep:GetClass())
        end
    end
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:RoundThink()
end


function MODE:CanLaunch()
    local activePlayers = 0

    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            activePlayers = activePlayers + 1
        end
    end
    
    if activePlayers < 5 then
        return false
    end

    return true
    --[[local pointsRioters = zb.GetMapPoints("RIOT_TDM_RIOTERS")
    local pointsLaw = zb.GetMapPoints("RIOT_TDM_LAW")
    return (#pointsRioters > 0) and (#pointsLaw > 0)--]]
end

return MODE
