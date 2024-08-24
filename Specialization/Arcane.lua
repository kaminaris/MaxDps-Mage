local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local ArcaneCharges
local Mana
local ManaMax
local ManaDeficit
local ManaPerc

local Arcane = {}

local aoe_target_count
local opener
local alt_rotation
local steroid_trinket_equipped

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Arcane:precombat()
    --if (CheckSpellCosts(classtable.ArcaneIntellect, 'ArcaneIntellect')) and cooldown[classtable.ArcaneIntellect].ready then
    --    return classtable.ArcaneIntellect
    --end
    aoe_target_count = 2
    if not talents[classtable.ArcingCleave] then
        aoe_target_count = 9
    end
    --opener = true
    if talents[classtable.HighVoltage] then
        alt_rotation = true
    else
        alt_rotation = false
    end
    --if (CheckSpellCosts(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready then
    --    return classtable.MirrorImage
    --end
    --if (CheckSpellCosts(classtable.ArcaneBlast, 'ArcaneBlast')) and (not talents[classtable.Evocation]) and cooldown[classtable.ArcaneBlast].ready then
    --    return classtable.ArcaneBlast
    --end
    --if (CheckSpellCosts(classtable.Evocation, 'Evocation')) and (talents[classtable.Evocation]) and cooldown[classtable.Evocation].ready then
    --    return classtable.Evocation
    --end
end
function Arcane:cd_opener()
    if (CheckSpellCosts(classtable.TouchoftheMagi, 'TouchoftheMagi')) and ((MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and ( (cooldown[classtable.ArcaneBarrage].duration >0 and cooldown[classtable.ArcaneBarrage].duration /100 or 0) <= 0.5 or gcd <= 0.5 )) and cooldown[classtable.TouchoftheMagi].ready then
        return classtable.TouchoftheMagi
    end
    if (CheckSpellCosts(classtable.Supernova, 'Supernova')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.UnerringProficiencyBuff].count == 30) and cooldown[classtable.Supernova].ready then
        return classtable.Supernova
    end
    if (CheckSpellCosts(classtable.PresenceofMind, 'PresenceofMind')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.NetherPrecisionBuff].up and targets <aoe_target_count and not talents[classtable.UnerringProficiency]) and cooldown[classtable.PresenceofMind].ready then
        return classtable.PresenceofMind
    end
    if (CheckSpellCosts(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.PresenceofMindBuff].up) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (CheckSpellCosts(classtable.ArcaneOrb, 'ArcaneOrb')) and (opener) and cooldown[classtable.ArcaneOrb].ready then
        return classtable.ArcaneOrb
    end
    if (CheckSpellCosts(classtable.Evocation, 'Evocation')) and (cooldown[classtable.ArcaneSurge].remains <gcd * 2) and cooldown[classtable.Evocation].ready then
        return classtable.Evocation
    end
    if (CheckSpellCosts(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (opener) and cooldown[classtable.ArcaneMissiles].ready then
        return classtable.ArcaneMissiles
    end
    if (CheckSpellCosts(classtable.ArcaneSurge, 'ArcaneSurge')) and cooldown[classtable.ArcaneSurge].ready then
        return classtable.ArcaneSurge
    end
    if (CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and (( ( not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.Evocation].remains >15 and cooldown[classtable.TouchoftheMagi].remains >15 ) and ( cooldown[classtable.ArcaneOrb].ready==false and cooldown[classtable.ArcaneOrb].charges == 0 ) and ttd >10 ) or ( (MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and ( buff[classtable.ArcaneSurgeBuff].up or debuff[classtable.TouchoftheMagiDeBuff].up or cooldown[classtable.Evocation].remains <20 ) and talents[classtable.ShiftingShards] )) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (CheckSpellCosts(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <2 and ( cooldown[classtable.TouchoftheMagi].remains >18 or not (targets >= aoe_target_count) )) and cooldown[classtable.ArcaneOrb].ready then
        return classtable.ArcaneOrb
    end
end
function Arcane:rotation_aoe()
    if (CheckSpellCosts(classtable.ArcaneBlast, 'ArcaneBlast')) and (targets >= aoe_target_count and debuff[classtable.TouchoftheMagiDeBuff].up and talents[classtable.MagisSpark]) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (CheckSpellCosts(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( talents[classtable.ArcaneTempo] and buff[classtable.ArcaneTempoBuff].remains <gcd ) or ( ( buff[classtable.IntuitionBuff].up and ( ArcaneCharges == 4 or not alt_rotation ) ) and buff[classtable.NetherPrecisionBuff].up ) or ( buff[classtable.NetherPrecisionBuff].up )) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (CheckSpellCosts(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ( ( alt_rotation and ArcaneCharges <4 ) or buff[classtable.AetherAttunementBuff].up or talents[classtable.ArcaneHarmony] ) and ( ( alt_rotation and ArcaneCharges <4 ) or not buff[classtable.NetherPrecisionBuff].up )) and cooldown[classtable.ArcaneMissiles].ready then
        return classtable.ArcaneMissiles
    end
    if (CheckSpellCosts(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ArcaneCharges == 4) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (CheckSpellCosts(classtable.ArcaneExplosion, 'ArcaneExplosion')) and cooldown[classtable.ArcaneExplosion].ready then
        return classtable.ArcaneExplosion
    end
end
function Arcane:rotation_default()
    if (CheckSpellCosts(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ( not buff[classtable.NetherPrecisionBuff].up or ( buff[classtable.ClearcastingBuff].count == 3 and not talents[classtable.SplinteringSorcery] ) or ( alt_rotation and buff[classtable.NetherPrecisionBuff].count == 1 and ArcaneCharges <4 ) )) and cooldown[classtable.ArcaneMissiles].ready then
        return classtable.ArcaneMissiles
    end
    if (CheckSpellCosts(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( ArcaneCharges == 4 and ( ( buff[classtable.NetherPrecisionBuff].count == 1 and ( ( buff[classtable.ClearcastingBuff].up or cooldown[classtable.ArcaneOrb].charges >0 ) ) and buff[classtable.ArcaneHarmonyBuff].count >12 ) or ( cooldown[classtable.TouchoftheMagi].ready and ( buff[classtable.NetherPrecisionBuff].up or not talents[classtable.MagisSpark] ) ) ) ) or ( talents[classtable.ArcaneTempo] and buff[classtable.ArcaneTempoBuff].remains <( gcd * 2 ) ) or buff[classtable.IntuitionBuff].up) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (CheckSpellCosts(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.NetherPrecisionBuff].count == 2 or ( buff[classtable.NetherPrecisionBuff].count == 1 and not (MaxDps.spellHistory[1] == classtable.ArcaneBlast) )) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (CheckSpellCosts(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (not buff[classtable.ArcaneSurgeBuff].up and ( ManaPerc <70 and cooldown[classtable.ArcaneSurge].remains >45 and cooldown[classtable.TouchoftheMagi].remains >6 ) or ( ManaDeficit >( ManaMax - MaxGetSpellCost(classtable.ArcaneBlast, 'MANA') ) ) or cooldown[classtable.TouchoftheMagi].ready or ( cooldown[classtable.ShiftingPower].ready and cooldown[classtable.ArcaneOrb].ready )) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (CheckSpellCosts(classtable.ArcaneBlast, 'ArcaneBlast')) and (not talents[classtable.SplinteringSorcery] or ( ArcaneCharges >2 and not buff[classtable.NetherPrecisionBuff].up )) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (CheckSpellCosts(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
end

function Arcane:callaction()
    if (CheckSpellCosts(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if debuff[classtable.TouchoftheMagiDeBuff].up and opener then
        opener = false
    end
    if (CheckSpellCosts(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ttd <2) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    local cd_openerCheck = Arcane:cd_opener()
    if cd_openerCheck then
        return cd_openerCheck
    end
    if (targets >= ( aoe_target_count + (talents[classtable.Impetus] and talents[classtable.Impetus] or 0) + (talents[classtable.SplinteringSorcery] and talents[classtable.SplinteringSorcery] or 0) )) then
        local rotation_aoeCheck = Arcane:rotation_aoe()
        if rotation_aoeCheck then
            return Arcane:rotation_aoe()
        end
    end
    local rotation_defaultCheck = Arcane:rotation_default()
    if rotation_defaultCheck then
        return rotation_defaultCheck
    end
    if (CheckSpellCosts(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
end
function Mage:Arcane()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    ArcaneCharges = UnitPower('player', ArcaneChargesPT)
    ManaPerc = (Mana / ManaMax) * 100
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.TouchoftheMagiDeBuff = 210824
    classtable.UnerringProficiencyBuff = 0
    classtable.NetherPrecisionBuff = 383783
    classtable.PresenceofMindBuff = 205025
    classtable.ArcaneSurgeBuff = 365362
    classtable.SiphonStormBuff = 384267
    classtable.ArcaneChargeBuff = 0
    classtable.ArcaneTempoBuff = 383997
    classtable.IntuitionBuff = 0
    classtable.ClearcastingBuff = 263725
    classtable.AetherAttunementBuff = 453601
    classtable.ArcaneHarmonyBuff = 384455
	if timeInCombat <= 4 then
		opener = true
	else
		opener = false
	end

    local precombatCheck = Arcane:precombat()
    if precombatCheck then
        return Arcane:precombat()
    end

    local callactionCheck = Arcane:callaction()
    if callactionCheck then
        return Arcane:callaction()
    end
end
