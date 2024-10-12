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


local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


function Arcane:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneIntellect, 'ArcaneIntellect')) and (not buff[classtable.ArcaneIntellectBuff].up) and cooldown[classtable.ArcaneIntellect].ready then
        return classtable.ArcaneIntellect
    end
    aoe_target_count = 2
    if not talents[classtable.ArcingCleave] then
        aoe_target_count = 9
    end
    opener = ( cooldown[classtable.TouchoftheMagi].ready ) and ( cooldown[classtable.ArcaneSurge].ready or (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ArcaneSurge] and GetTime() - MaxDps.spellHistoryTime[classtable.ArcaneSurge].last_used or 0) <5 or cooldown[classtable.ArcaneSurge].remains >15 ) and ( cooldown[classtable.Evocation].ready or (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.Evocation] and GetTime() - MaxDps.spellHistoryTime[classtable.Evocation].last_used or 0) <5 or cooldown[classtable.Evocation].remains >15 )
    if talents[classtable.HighVoltage] then
        alt_rotation = 1
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready then
        MaxDps:GlowCooldown(classtable.MirrorImage, cooldown[classtable.MirrorImage].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (not talents[classtable.Evocation]) and cooldown[classtable.ArcaneBlast].ready then
    --    return classtable.ArcaneBlast
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (talents[classtable.Evocation]) and cooldown[classtable.Evocation].ready then
    --    return classtable.Evocation
    --end
end
function Arcane:cd_opener()
    if (MaxDps:CheckSpellUsable(classtable.TouchoftheMagi, 'TouchoftheMagi')) and (( (MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and ( buff[classtable.ArcaneSurgeBuff].up or cooldown[classtable.ArcaneSurge].remains >30 ) ) or ( (MaxDps.spellHistory[1] == classtable.ArcaneSurge) and ArcaneCharges <4 )) and cooldown[classtable.TouchoftheMagi].ready then
        return classtable.TouchoftheMagi
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.PresenceofMindBuff].up) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (talents[classtable.HighVoltage] and ArcaneCharges <4) and cooldown[classtable.ArcaneOrb].ready then
        return classtable.ArcaneOrb
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (cooldown[classtable.ArcaneSurge].remains <( gcd * 3 ) and cooldown[classtable.TouchoftheMagi].remains <( gcd * 5 )) and cooldown[classtable.Evocation].ready then
        return classtable.Evocation
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (opener and talents[classtable.NetherPrecision] and not buff[classtable.NetherPrecisionBuff].up) and cooldown[classtable.ArcaneMissiles].ready then
        return classtable.ArcaneMissiles
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneSurge, 'ArcaneSurge')) and (cooldown[classtable.TouchoftheMagi].remains <( 2 + ( gcd * ( ArcaneCharges == 4 and 1 or 0 ) ) )) and cooldown[classtable.ArcaneSurge].ready then
        return classtable.ArcaneSurge
    end
end
function Arcane:spellslinger_aoe()
    if (MaxDps:CheckSpellUsable(classtable.Supernova, 'Supernova')) and (buff[classtable.UnerringProficiencyBuff].count == 30) and cooldown[classtable.Supernova].ready then
        return classtable.Supernova
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( (MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and ( buff[classtable.ArcaneSurgeBuff].up or debuff[classtable.TouchoftheMagiDeBuff].up or cooldown[classtable.Evocation].remains <20 ) and talents[classtable.ShiftingShards] )) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <2) and cooldown[classtable.ArcaneOrb].ready then
        return classtable.ArcaneOrb
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (( debuff[classtable.MagisSparkArcaneBlastDeBuff].up )) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( talents[classtable.ArcaneTempo] and buff[classtable.ArcaneTempoBuff].remains <gcd ) or ( ( buff[classtable.IntuitionBuff].up and ( ArcaneCharges == 4 or not talents[classtable.HighVoltage] ) ) and buff[classtable.NetherPrecisionBuff].up ) or ( buff[classtable.NetherPrecisionBuff].up and (C_Spell and C_Spell.IsCurrentSpell(classtable.ArcaneBlast)) )) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ( ( talents[classtable.HighVoltage] and ArcaneCharges <4 ) or not buff[classtable.NetherPrecisionBuff].up )) and cooldown[classtable.ArcaneMissiles].ready then
        return classtable.ArcaneMissiles
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (ArcaneCharges == 3 or ArcaneCharges == 2) and cooldown[classtable.PresenceofMind].ready then
        return classtable.PresenceofMind
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( ArcaneCharges == 4 )) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and cooldown[classtable.ArcaneExplosion].ready then
        return classtable.ArcaneExplosion
    end
end
function Arcane:spellslinger()
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( ( not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.Evocation].remains >15 and cooldown[classtable.TouchoftheMagi].remains >10 ) and ( cooldown[classtable.ArcaneOrb].ready==false and cooldown[classtable.ArcaneOrb].charges == 0 ) and ttd >10 ) or ( (MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and ( buff[classtable.ArcaneSurgeBuff].up or debuff[classtable.TouchoftheMagiDeBuff].up or cooldown[classtable.Evocation].remains <20 ) )) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.NetherPrecisionBuff].up and targets <aoe_target_count and not talents[classtable.UnerringProficiency]) and cooldown[classtable.PresenceofMind].ready then
        return classtable.PresenceofMind
    end
    if (MaxDps:CheckSpellUsable(classtable.Supernova, 'Supernova')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.UnerringProficiencyBuff].count == 30) and cooldown[classtable.Supernova].ready then
        return classtable.Supernova
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( buff[classtable.NetherPrecisionBuff].count == 2 ) or ( cooldown[classtable.TouchoftheMagi].ready ) or ( talents[classtable.ArcaneTempo] and buff[classtable.ArcaneTempoBuff].remains <gcd )) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (( buff[classtable.ClearcastingBuff].up and not buff[classtable.NetherPrecisionBuff].up ) or buff[classtable.ClearcastingBuff].count == 3) and cooldown[classtable.ArcaneMissiles].ready then
        return classtable.ArcaneMissiles
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <2) and cooldown[classtable.ArcaneOrb].ready then
        return classtable.ArcaneOrb
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
end
function Arcane:sunfury()
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( ( not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.Evocation].remains >15 and cooldown[classtable.TouchoftheMagi].remains >10 ) and ttd >10 ) and ( not buff[classtable.ArcaneSoulBuff].up )) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.NetherPrecisionBuff].up and targets <4) and cooldown[classtable.PresenceofMind].ready then
        return classtable.PresenceofMind
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( ( ArcaneCharges == 4 and ( buff[classtable.NetherPrecisionBuff].count == 2 ) and targets >= ( 5 - ( 2 * ( talents[classtable.ArcaneBombardment] and targetHP <35 and 1 or 0 ) ) ) and talents[classtable.ArcingCleave] and ( ( talents[classtable.HighVoltage] and buff[classtable.ClearcastingBuff].up ) or ( cooldown[classtable.ArcaneOrb].remains <gcd or cooldown[classtable.ArcaneOrb].charges >0 ) ) ) ) or ( buff[classtable.AetherAttunementBuff].up and talents[classtable.HighVoltage] and buff[classtable.ClearcastingBuff].up and ArcaneCharges >1 and targets >1 )) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <2 and not buff[classtable.ArcaneSoulBuff].up and ( not talents[classtable.HighVoltage] or buff[classtable.ClearcastingBuff].up == 0 )) and cooldown[classtable.ArcaneOrb].ready then
        return classtable.ArcaneOrb
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( ( buff[classtable.GloriousIncandescenceBuff].up or buff[classtable.IntuitionBuff].up ) and ( buff[classtable.NetherPrecisionBuff].count == 2 or ( not buff[classtable.NetherPrecisionBuff].up and buff[classtable.ClearcastingBuff].up == 0 ) ) ) or ( buff[classtable.ArcaneSoulBuff].up and ( ( buff[classtable.ClearcastingBuff].count <3 ) or buff[classtable.ArcaneSoulBuff].remains <gcd ) ) or ( ArcaneCharges == 4 and ( cooldown[classtable.TouchoftheMagi].ready or ( buff[classtable.BurdenofPowerBuff].up and buff[classtable.NetherPrecisionBuff].up ) ) )) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ( ( not buff[classtable.NetherPrecisionBuff].up or ( buff[classtable.ClearcastingBuff].up == 3 ) or ( talents[classtable.HighVoltage] and ArcaneCharges <3 ) ) )) and cooldown[classtable.ArcaneMissiles].ready then
        return classtable.ArcaneMissiles
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (( ArcaneCharges == 3 or ArcaneCharges == 2 ) and targets >= 3) and cooldown[classtable.PresenceofMind].ready then
        return classtable.PresenceofMind
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (( talents[classtable.Reverberate] or ArcaneCharges <1 ) and targets >= 4) and cooldown[classtable.ArcaneExplosion].ready then
        return classtable.ArcaneExplosion
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        return classtable.ArcaneBlast
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
end

function Arcane:callaction()
    MaxDps:GlowCooldown(classtable.Counterspell,MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell') and ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    --if (MaxDps:CheckSpellUsable(classtable.Spellsteal, 'Spellsteal')) and cooldown[classtable.Spellsteal].ready then
    --    return classtable.Spellsteal
    --end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (MaxDps:boss() and ttd <2) and cooldown[classtable.ArcaneBarrage].ready then
        return classtable.ArcaneBarrage
    end
    if (opener) then
        local cd_openerCheck = Arcane:cd_opener()
        if cd_openerCheck then
            return Arcane:cd_opener()
        end
    end
    if (targets >= ( aoe_target_count + (talents[classtable.Impetus] and talents[classtable.Impetus] or 0) ) and not talents[classtable.SpellfireSpheres]) then
        local spellslinger_aoeCheck = Arcane:spellslinger_aoe()
        if spellslinger_aoeCheck then
            return Arcane:spellslinger_aoe()
        end
    end
    if (talents[classtable.SpellfireSpheres]) then
        local sunfuryCheck = Arcane:sunfury()
        if sunfuryCheck then
            return Arcane:sunfury()
        end
    end
    if (not talents[classtable.SpellfireSpheres]) then
        local spellslingerCheck = Arcane:spellslinger()
        if spellslingerCheck then
            return Arcane:spellslinger()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
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
    classtable.ArcaneSurgeBuff = 365362
    classtable.ArcaneChargeBuff = 0
    classtable.PresenceofMindBuff = 205025
    classtable.NetherPrecisionBuff = 383783
    classtable.UnerringProficiencyBuff = 444981
    classtable.TouchoftheMagiDeBuff = 210824
    classtable.MagisSparkArcaneBlastDeBuff = 0
    classtable.ArcaneTempoBuff = 383997
    classtable.IntuitionBuff = 0
    classtable.ClearcastingBuff = 263725
    classtable.SiphonStormBuff = 384267
    classtable.ArcaneSoulBuff = 451038
    classtable.AetherAttunementBuff = 453601
    classtable.GloriousIncandescenceBuff = 451073
    classtable.BurdenofPowerBuff = 451049
	classtable.ArcaneIntellectBuff = 1459

    local precombatCheck = Arcane:precombat()
    if precombatCheck then
        return Arcane:precombat()
    end

    local callactionCheck = Arcane:callaction()
    if callactionCheck then
        return Arcane:callaction()
    end
end
