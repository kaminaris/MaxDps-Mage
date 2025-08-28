local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaRegen
local ManaRegenCombined
local ManaTimeToMax
local ArcaneCharges

local Arcane = {}

local aoe_target_count = 2
local aoe_list = 0
local steroid_trinket_equipped = false
local neural_on_mini = false
local nonsteroid_trinket_equipped = false
local treacherous_transmitter_precombat_cast = 11
local opener = 0
local touch_condition = false


local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


function Arcane:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneIntellect, 'ArcaneIntellect')) and (not buff[classtable.ArcaneIntellectBuff].up) and cooldown[classtable.ArcaneIntellect].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ArcaneIntellect end
    end
    aoe_target_count = 2

    if not talents[classtable.ArcingCleave] then
        aoe_target_count = 9
    end
    aoe_list = 0
    steroid_trinket_equipped = MaxDps:CheckEquipped('GladiatorsBadge') or MaxDps:CheckEquipped('SignetofthePriory') or MaxDps:CheckEquipped('HighSpeakersAccretion') or MaxDps:CheckEquipped('SpymastersWeb') or MaxDps:CheckEquipped('TreacherousTransmitter') or MaxDps:CheckEquipped('ImperfectAscendancySerum') or MaxDps:CheckEquipped('QuickwickCandlestick') or MaxDps:CheckEquipped('SoullettingRuby') or MaxDps:CheckEquipped('FunhouseLens') or MaxDps:CheckEquipped('HouseofCards') or MaxDps:CheckEquipped('FlarendosPilotLight') or MaxDps:CheckEquipped('SignetofthePriory') or MaxDps:CheckEquipped('NeuralSynapseEnhancer')
    neural_on_mini = MaxDps:CheckEquipped('GladiatorsBadge') or MaxDps:CheckEquipped('SignetofthePriory') or MaxDps:CheckEquipped('HighSpeakersAccretion') or MaxDps:CheckEquipped('SpymastersWeb') or MaxDps:CheckEquipped('TreacherousTransmitter') or MaxDps:CheckEquipped('ImperfectAscendancySerum') or MaxDps:CheckEquipped('QuickwickCandlestick') or MaxDps:CheckEquipped('SoullettingRuby') or MaxDps:CheckEquipped('FunhouseLens') or MaxDps:CheckEquipped('HouseofCards') or MaxDps:CheckEquipped('FlarendosPilotLight') or MaxDps:CheckEquipped('SignetofthePriory')
    nonsteroid_trinket_equipped = MaxDps:CheckEquipped('Blastmaster3000') or MaxDps:CheckEquipped('RatfangToxin') or MaxDps:CheckEquipped('IngeniousManaBattery') or MaxDps:CheckEquipped('GeargrindersSpareKeys') or MaxDps:CheckEquipped('RingingRitualMud') or MaxDps:CheckEquipped('GooBlinGrenade') or MaxDps:CheckEquipped('NoggenfoggerUltimateDeluxe') or MaxDps:CheckEquipped('GarbagemancersLastResort') or MaxDps:CheckEquipped('MadQueensMandate') or MaxDps:CheckEquipped('FearbreakersEcho') or MaxDps:CheckEquipped('MereldarsToll') or MaxDps:CheckEquipped('GooblinGrenade')
    if (MaxDps:CheckSpellUsable(classtable.ingenious_mana_battery, 'ingenious_mana_battery')) and cooldown[classtable.ingenious_mana_battery].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.ingenious_mana_battery, cooldown[classtable.ingenious_mana_battery].ready)
    end
    treacherous_transmitter_precombat_cast = 11
    if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and cooldown[classtable.treacherous_transmitter].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.MirrorImage, cooldown[classtable.MirrorImage].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.imperfect_ascendancy_serum, 'imperfect_ascendancy_serum')) and cooldown[classtable.imperfect_ascendancy_serum].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, cooldown[classtable.imperfect_ascendancy_serum].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (not talents[classtable.Evocation]) and cooldown[classtable.ArcaneBlast].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation') and talents[classtable.Evocation]) and (talents[classtable.Evocation]) and cooldown[classtable.Evocation].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Evocation end
    end
end
function Arcane:cd_opener()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.PresenceofMindBuff].up) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (talents[classtable.HighVoltage] and opener) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (buff[classtable.ArcaneTempoBuff].up and cooldown[classtable.Evocation].ready and buff[classtable.ArcaneTempoBuff].remains <gcd*5) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation') and talents[classtable.Evocation]) and (cooldown[classtable.ArcaneSurge].remains<(gcd * 3) and cooldown[classtable.TouchoftheMagi].remains<(gcd * 5)) and cooldown[classtable.Evocation].ready then
        if not setSpell then setSpell = classtable.Evocation end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and ((((MaxDps.spellHistory[1] == classtable.Evocation) or (MaxDps.spellHistory[1] == classtable.ArcaneSurge)) or opener) and not buff[classtable.NetherPrecisionBuff].up) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneSurge, 'ArcaneSurge')) and (cooldown[classtable.TouchoftheMagi].remains<(2+(gcd*((ArcaneCharges == 4) and 1 or 0)))) and cooldown[classtable.ArcaneSurge].ready then
        if not setSpell then setSpell = classtable.ArcaneSurge end
    end
end
function Arcane:spellslinger()
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and ((((((cooldown[classtable.ArcaneOrb].charges == 0) and cooldown[classtable.ArcaneOrb].remains >16) or cooldown[classtable.TouchoftheMagi].remains <20) and not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and (not buff[classtable.IntuitionBuff].up or (buff[classtable.IntuitionBuff].up and buff[classtable.IntuitionBuff].remains >( classtable and classtable.ShiftingPower and GetSpellInfo(classtable.ShiftingPower).castTime /1000 or 0))) and cooldown[classtable.TouchoftheMagi].remains>(12 + 6*gcd)) or ((MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and talents[classtable.ShiftingShards] and (not buff[classtable.IntuitionBuff].up or (buff[classtable.IntuitionBuff].up and buff[classtable.IntuitionBuff].remains >( classtable and classtable.ShiftingPower and GetSpellInfo(classtable.ShiftingPower).castTime /1000 or 0))) and (buff[classtable.ArcaneSurgeBuff].up or debuff[classtable.TouchoftheMagiDeBuff].up or cooldown[classtable.Evocation].remains <20))) and ttd >10 and (buff[classtable.ArcaneTempoBuff].remains >gcd*2.5 or not buff[classtable.ArcaneTempoBuff].up)) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.NetherPrecisionBuff].up and targets <aoe_target_count and not talents[classtable.UnerringProficiency]) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Supernova, 'Supernova')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.UnerringProficiencyBuff].count == 30) and cooldown[classtable.Supernova].ready then
        if not setSpell then setSpell = classtable.Supernova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <4) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((buff[classtable.ArcaneTempoBuff].up and buff[classtable.ArcaneTempoBuff].remains <gcd)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.AetherAttunementBuff].up and cooldown[classtable.TouchoftheMagi].remains <gcd*3 and buff[classtable.ClearcastingBuff].up and (MaxDps.tier and MaxDps.tier[33].count) >3) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((cooldown[classtable.TouchoftheMagi].ready or cooldown[classtable.TouchoftheMagi].remains< max((1 + 0.05),(gcd+1))) and (cooldown[classtable.ArcaneSurge].remains >30 and cooldown[classtable.ArcaneSurge].remains <75)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ArcaneCharges == 4 and buff[classtable.ArcaneHarmonyBuff].count >= 20 and (MaxDps.tier and MaxDps.tier[34].count >= 4)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and ((buff[classtable.ClearcastingBuff].up and not buff[classtable.NetherPrecisionBuff].up and ((cooldown[classtable.TouchoftheMagi].remains >gcd*7 and cooldown[classtable.ArcaneSurge].remains >gcd*7) or buff[classtable.ClearcastingBuff].count >1 or not talents[classtable.MagisSpark] or (cooldown[classtable.TouchoftheMagi].remains <gcd*4 and not buff[classtable.AetherAttunementBuff].up) or (MaxDps.tier and MaxDps.tier[33].count >= 4))) or (ttd <5 and buff[classtable.ClearcastingBuff].up)) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (talents[classtable.HighVoltage] and (buff[classtable.ClearcastingBuff].count >1 or (buff[classtable.ClearcastingBuff].up and buff[classtable.AetherAttunementBuff].up)) and ArcaneCharges <3) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (buff[classtable.IntuitionBuff].up) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (debuff[classtable.MagisSparkArcaneBlastDeBuff].up or buff[classtable.LeydrinkerBuff].up) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.NetherPrecisionBuff].up and buff[classtable.ArcaneHarmonyBuff].count <= 16 and ArcaneCharges == 4 and targets == 1) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ManaPerc <10 and not buff[classtable.ArcaneSurgeBuff].up and (cooldown[classtable.ArcaneOrb].remains <gcd)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (targets == 1 and (cooldown[classtable.TouchoftheMagi].remains <6 or not talents[classtable.ChargedOrb] or buff[classtable.ArcaneSurgeBuff].up or cooldown[classtable.ArcaneOrb].charges >1.5)) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (targets >= 2 and ArcaneCharges == 4 and cooldown[classtable.ArcaneOrb].remains <gcd and (buff[classtable.ArcaneHarmonyBuff].count<=(8+(10 * not (MaxDps.tier and MaxDps.tier[34].count >= 4)))) and ((((MaxDps.spellHistory[1] == classtable.ArcaneBarrage) or (MaxDps.spellHistory[1] == classtable.ArcaneOrb)) and buff[classtable.NetherPrecisionBuff].count == 1) or buff[classtable.NetherPrecisionBuff].count == 2 or not buff[classtable.NetherPrecisionBuff].up)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (targets >2 and (ArcaneCharges == 4 and not (MaxDps.tier and MaxDps.tier[34].count >= 4))) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (targets >1 and buff[classtable.ArcaneHarmonyBuff].count <20 and (buff[classtable.ArcaneSurgeBuff].up or buff[classtable.NetherPrecisionBuff].up or targets >= 7) and (MaxDps.tier and MaxDps.tier[34].count >= 4)) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (talents[classtable.HighVoltage] and targets >= 2 and ArcaneCharges == 4 and buff[classtable.AetherAttunementBuff].up and buff[classtable.ClearcastingBuff].up) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (targets >1 and (targets <3 or buff[classtable.ArcaneSurgeBuff].up or (buff[classtable.NetherPrecisionBuff].up)) and (MaxDps.tier and MaxDps.tier[34].count >= 4)) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (targets >1 and ArcaneCharges == 4 and cooldown[classtable.ArcaneOrb].remains <gcd) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (talents[classtable.HighVoltage] and ArcaneCharges == 4 and buff[classtable.ClearcastingBuff].up and buff[classtable.NetherPrecisionBuff].count == 1) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((targets == 1 and (talents[classtable.OrbBarrage] or (targethealthPerc <35 and talents[classtable.ArcaneBombardment])) and (cooldown[classtable.ArcaneOrb].remains <gcd) and ArcaneCharges == 4 and (cooldown[classtable.TouchoftheMagi].remains >gcd*6 or not talents[classtable.MagisSpark]) and (not buff[classtable.NetherPrecisionBuff].up or (buff[classtable.NetherPrecisionBuff].count == 1 and buff[classtable.ClearcastingBuff].count == 0))) and not (MaxDps.tier and MaxDps.tier[34].count >= 4)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (targets >1 and ((ArcaneCharges <1 and not talents[classtable.HighVoltage]) or (ArcaneCharges <3 and (not buff[classtable.ClearcastingBuff].up or talents[classtable.Reverberate])))) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (targets == 1 and ArcaneCharges <2 and not buff[classtable.ClearcastingBuff].up) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((((targethealthPerc <35 and (debuff[classtable.TouchoftheMagiDeBuff].remains<(gcd * 1.25)) and (debuff[classtable.TouchoftheMagiDeBuff].remains >1)) or ((buff[classtable.ArcaneSurgeBuff].remains <gcd) and buff[classtable.ArcaneSurgeBuff].up)) and ArcaneCharges == 4) and not (MaxDps.tier and MaxDps.tier[34].count >= 4)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
end
function Arcane:sunfury()
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (((not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.Evocation].remains >15 and cooldown[classtable.TouchoftheMagi].remains >10) and ttd >10) and not buff[classtable.ArcaneSoulBuff].up and (not buff[classtable.IntuitionBuff].up or (buff[classtable.IntuitionBuff].up and buff[classtable.IntuitionBuff].remains >( classtable and classtable.ShiftingPower and GetSpellInfo(classtable.ShiftingPower).castTime /1000 or 0)))) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.NetherPrecisionBuff].up and targets <4) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (not buff[classtable.NetherPrecisionBuff].up and buff[classtable.ClearcastingBuff].up and buff[classtable.ArcaneSoulBuff].up and buff[classtable.ArcaneSoulBuff].remains >gcd*(4 - buff[classtable.ClearcastingBuff].count)) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (buff[classtable.ArcaneSoulBuff].up) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((buff[classtable.ArcaneTempoBuff].up and buff[classtable.ArcaneTempoBuff].remains <gcd) or (buff[classtable.IntuitionBuff].up and buff[classtable.IntuitionBuff].remains <gcd)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((talents[classtable.OrbBarrage] and targets >1 and buff[classtable.ArcaneHarmonyBuff].count >= 18 and ((targets >3 and (talents[classtable.Resonance] or talents[classtable.HighVoltage])) or not buff[classtable.NetherPrecisionBuff].up or buff[classtable.NetherPrecisionBuff].count == 1 or (buff[classtable.NetherPrecisionBuff].count == 2 and buff[classtable.ClearcastingBuff].count == 3)))) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and (MaxDps.tier and MaxDps.tier[33].count >= 4) and buff[classtable.AetherAttunementBuff].up and cooldown[classtable.TouchoftheMagi].remains <gcd*(3-(1.5*(targets >3 and (not talents[classtable.TimeLoop] or talents[classtable.Resonance]))))) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (((debuff[classtable.MagisSparkArcaneBlastDeBuff].up and ((debuff[classtable.MagisSparkArcaneBlastDeBuff].remains<(( classtable and classtable.ArcaneBlast and GetSpellInfo(classtable.ArcaneBlast).castTime /1000 or 0) + gcd)) or targets == 1 or talents[classtable.Leydrinker])) or buff[classtable.LeydrinkerBuff].up) and ArcaneCharges == 4 and (buff[classtable.NetherPrecisionBuff].up or not buff[classtable.ClearcastingBuff].up)) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ArcaneCharges == 4 and (cooldown[classtable.TouchoftheMagi].ready or cooldown[classtable.TouchoftheMagi].remains < max((1 + 0.05),(gcd+1)) )) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((talents[classtable.HighVoltage] and targets >1 and ArcaneCharges == 4 and buff[classtable.ClearcastingBuff].up and buff[classtable.NetherPrecisionBuff].count == 1)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((targets >1 and talents[classtable.HighVoltage] and ArcaneCharges == 4 and buff[classtable.ClearcastingBuff].up and buff[classtable.AetherAttunementBuff].up and not buff[classtable.GloriousIncandescenceBuff].up and not buff[classtable.IntuitionBuff].up)) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((targets >2 and talents[classtable.OrbBarrage] and talents[classtable.HighVoltage] and not debuff[classtable.MagisSparkArcaneBlastDeBuff].up and ArcaneCharges == 4 and targethealthPerc <35 and talents[classtable.ArcaneBombardment] and (buff[classtable.NetherPrecisionBuff].up or (not buff[classtable.NetherPrecisionBuff].up and buff[classtable.ClearcastingBuff].count == 0)))) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (((targets >2 or (targets >1 and targethealthPerc <35 and talents[classtable.ArcaneBombardment])) and cooldown[classtable.ArcaneOrb].remains <gcd and ArcaneCharges == 4 and cooldown[classtable.TouchoftheMagi].remains >gcd*6 and (not debuff[classtable.MagisSparkArcaneBlastDeBuff].up or not talents[classtable.MagisSpark]) and buff[classtable.NetherPrecisionBuff].up and (talents[classtable.HighVoltage] or buff[classtable.NetherPrecisionBuff].count == 2 or (buff[classtable.NetherPrecisionBuff].count == 1 and not buff[classtable.ClearcastingBuff].up)))) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ((talents[classtable.HighVoltage] and ArcaneCharges <4) or not buff[classtable.NetherPrecisionBuff].up)) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and ((ArcaneCharges == 4 and targets >1 and targets <5 and buff[classtable.BurdenofPowerBuff].up and ((talents[classtable.HighVoltage] and buff[classtable.ClearcastingBuff].up) or buff[classtable.GloriousIncandescenceBuff].up or buff[classtable.IntuitionBuff].up or (cooldown[classtable.ArcaneOrb].remains <gcd or cooldown[classtable.ArcaneOrb].charges >0))) and (not talents[classtable.ConsortiumsBauble] or talents[classtable.HighVoltage])) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <3) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (buff[classtable.GloriousIncandescenceBuff].up or buff[classtable.IntuitionBuff].up) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and ((ArcaneCharges == 3 or ArcaneCharges == 2) and targets >= 3) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (ArcaneCharges <2 and targets >1) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.ingenious_mana_battery, false)
    MaxDps:GlowCooldown(classtable.treacherous_transmitter, false)
    MaxDps:GlowCooldown(classtable.MirrorImage, false)
    MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, false)
    MaxDps:GlowCooldown(classtable.Counterspell, false)
    MaxDps:GlowCooldown(classtable.spymasters_web, false)
    MaxDps:GlowCooldown(classtable.high_speakers_accretion, false)
    MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, false)
end

function Arcane:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.Spellsteal, 'Spellsteal')) and cooldown[classtable.Spellsteal].ready then
    --    if not setSpell then setSpell = classtable.Spellsteal end
    --end
    if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and (buff[classtable.SpymastersReportBuff].count <40) and cooldown[classtable.treacherous_transmitter].ready then
        MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.spymasters_web, 'spymasters_web')) and ((((MaxDps.spellHistory[1] == classtable.ArcaneSurge) or (MaxDps.spellHistory[1] == classtable.Evocation)) and (ttd <80 or targethealthPerc <35 or not talents[classtable.ArcaneBombardment] or (buff[classtable.SpymastersReportBuff].count == 40 and ttd >240)) or MaxDps:boss() and ttd <20)) and cooldown[classtable.spymasters_web].ready then
        MaxDps:GlowCooldown(classtable.spymasters_web, cooldown[classtable.spymasters_web].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.high_speakers_accretion, 'high_speakers_accretion')) and (((MaxDps.spellHistory[1] == classtable.ArcaneSurge) or (MaxDps.spellHistory[1] == classtable.Evocation) or (buff[classtable.SiphonStormBuff].up and opener) or cooldown[classtable.Evocation].remains <4 or MaxDps:boss() and ttd <20) and not spymasters_double_on_use) and cooldown[classtable.high_speakers_accretion].ready then
        MaxDps:GlowCooldown(classtable.high_speakers_accretion, cooldown[classtable.high_speakers_accretion].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.imperfect_ascendancy_serum, 'imperfect_ascendancy_serum')) and ((cooldown[classtable.Evocation].ready or cooldown[classtable.ArcaneSurge].ready or MaxDps:boss() and ttd <21) and not spymasters_double_on_use) and cooldown[classtable.imperfect_ascendancy_serum].ready then
        MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, cooldown[classtable.imperfect_ascendancy_serum].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and ((debuff[classtable.TouchoftheMagiDeBuff].remains >8 and buff[classtable.ArcaneSurgeBuff].up) or (debuff[classtable.TouchoftheMagiDeBuff].remains >8 and neural_on_mini)) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if debuff[classtable.TouchoftheMagiDeBuff].up and opener then
        opener = 0
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ttd <2) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    touch_condition = ttd >15 and ((cooldown[classtable.ArcaneBarrage].duration >0 and cooldown[classtable.ArcaneBarrage].duration /100 or 0) <= 0.5 or gcd <= 0.5) and (buff[classtable.ArcaneSurgeBuff].up or cooldown[classtable.ArcaneSurge].remains >30) or ((MaxDps.spellHistory[1] == classtable.ArcaneSurge) and (ArcaneCharges <4 or not buff[classtable.NetherPrecisionBuff].up)) or (cooldown[classtable.ArcaneSurge].remains >30 and cooldown[classtable.TouchoftheMagi].ready and ArcaneCharges <4 and not (MaxDps.spellHistory[1] == classtable.ArcaneBarrage))
    if (MaxDps:CheckSpellUsable(classtable.TouchoftheMagi, 'TouchoftheMagi')) and (touch_condition) and cooldown[classtable.TouchoftheMagi].ready then
        if not setSpell then setSpell = classtable.TouchoftheMagi end
    end
    if (cooldown[classtable.TouchoftheMagi].remains <2*gcd or cooldown[classtable.Evocation].remains <2*gcd or cooldown[classtable.ArcaneSurge].remains <2*gcd) then
        Arcane:cd_opener()
    end
    if (talents[classtable.SpellfireSpheres]) then
        Arcane:sunfury()
    end
    if (not talents[classtable.SpellfireSpheres]) then
        Arcane:spellslinger()
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    ManaPerc = (Mana / ManaMax) * 100
    ManaRegen = GetPowerRegenForPowerType(ManaPT)
    ManaTimeToMax = ManaDeficit / ManaRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    ArcaneCharges = UnitPower('player', ArcaneChargesPT)
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ArcaneIntellectBuff = 1459
    classtable.SiphonStormBuff = 384267
    classtable.SpymastersWebBuff = 444959
    classtable.ArcaneSurgeBuff = 365362
    classtable.SpymastersReportBuff = 451199
    classtable.CrypticInstructionsBuff = 449946
    classtable.RealigningNexusConvergenceDivergenceBuff = 449947
    classtable.ErrantManaforgeEmissionBuff = 449952
    classtable.ArcaneChargeBuff = 0
    classtable.NetherPrecisionBuff = 383783
    classtable.PresenceofMindBuff = 205025
    classtable.ArcaneTempoBuff = 383997
    classtable.AetherAttunementBuff = 453601
    classtable.IntuitionBuff = 455681
    classtable.UnerringProficiencyBuff = 444981
    classtable.ClearcastingBuff = 135700
    classtable.ArcaneHarmonyBuff = 384455
    classtable.LeydrinkerBuff = 453758
    classtable.ArcaneSoulBuff = 451038
    classtable.GloriousIncandescenceBuff = 451073
    classtable.BurdenofPowerBuff = 451049
    classtable.TouchoftheMagiDeBuff = 210824
    classtable.MagisSparkArcaneBlastDeBuff = "MagisSparkArcaneBlastDeBuff"
    classtable.MagisSparkArcaneBarrageDeBuff = "MagisSparkArcaneBarrageDeBuff"
    classtable.MagisSparkArcaneMissilesDeBuff = "MagisSparkArcaneMissilesDeBuff"

    local function debugg()
        talents[classtable.ArcingCleave] = 1
        talents[classtable.Evocation] = 1
        talents[classtable.ArcaneBombardment] = 1
        talents[classtable.SpellfireSpheres] = 1
        talents[classtable.HighVoltage] = 1
        talents[classtable.ShiftingShards] = 1
        talents[classtable.UnerringProficiency] = 1
        talents[classtable.MagisSpark] = 1
        talents[classtable.ChargedOrb] = 1
        talents[classtable.OrbBarrage] = 1
        talents[classtable.Reverberate] = 1
        talents[classtable.Resonance] = 1
        talents[classtable.TimeLoop] = 1
        talents[classtable.Leydrinker] = 1
        talents[classtable.ConsortiumsBauble] = 1
    end

    if talents[classtable.MagisSpark] and debuff[classtable.TouchoftheMagiDeBuff].up then
        if (MaxDps.spellHistoryTime["ArcaneBarrage"] and MaxDps.spellHistoryTime["ArcaneBarrage"].lastCast or math.huge) <
        (debuff[classtable.TouchoftheMagiDeBuff].up and MaxDps.spellHistoryTime["TouchoftheMagi"] and MaxDps.spellHistoryTime["TouchoftheMagi"].lastCast or math.huge) 
        then debuff[classtable.MagisSparkArcaneBarrageDeBuff] = {up = true, remains = debuff[classtable.TouchoftheMagiDeBuff].remains}
        else debuff[classtable.MagisSparkArcaneBarrageDeBuff] = {up = false, remains = 0}
        end
        if (MaxDps.spellHistoryTime["ArcaneBlast"] and MaxDps.spellHistoryTime["ArcaneBlast"].lastCast or math.huge) <
        (debuff[classtable.TouchoftheMagiDeBuff].up and MaxDps.spellHistoryTime["TouchoftheMagi"] and MaxDps.spellHistoryTime["TouchoftheMagi"].lastCast or math.huge)
        then debuff[classtable.MagisSparkArcaneBlastDeBuff] = {up = true, remains = debuff[classtable.TouchoftheMagiDeBuff].remains}
        else debuff[classtable.MagisSparkArcaneBlastDeBuff] = {up = false, remains = 0}
        end
        if (MaxDps.spellHistoryTime["ArcaneMissiles"] and MaxDps.spellHistoryTime["ArcaneMissiles"].lastCast or math.huge) <
        (debuff[classtable.TouchoftheMagiDeBuff].up and MaxDps.spellHistoryTime["TouchoftheMagi"] and MaxDps.spellHistoryTime["TouchoftheMagi"].lastCast or math.huge)
        then debuff[classtable.MagisSparkArcaneMissilesDeBuff] = {up = true, remains = debuff[classtable.TouchoftheMagiDeBuff].remains}
        else debuff[classtable.MagisSparkArcaneMissilesDeBuff] = {up = false, remains = 0}
        end
    else
        debuff[classtable.MagisSparkArcaneBlastDeBuff] = {up = false, remains = 0}
        debuff[classtable.MagisSparkArcaneBarrageDeBuff] = {up = false, remains = 0}
        debuff[classtable.MagisSparkArcaneMissilesDeBuff] = {up = false, remains = 0}
    end

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Arcane:precombat()

    Arcane:callaction()
    if setSpell then return setSpell end
end
