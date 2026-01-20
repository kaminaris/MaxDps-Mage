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

local Frost = {}

local treacherous_transmitter_precombat_cast = 12


local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


function Frost:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneIntellect, 'ArcaneIntellect')) and (not buff[classtable.ArcaneIntellectBuff].up) and cooldown[classtable.ArcaneIntellect].ready then
        if not setSpell then setSpell = classtable.ArcaneIntellect end
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.MirrorImage, cooldown[classtable.MirrorImage].ready)
    end
    if MaxDps:CheckEquipped('TreacherousTransmitter') then
        treacherous_transmitter_precombat_cast = 12
    end
    if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and cooldown[classtable.treacherous_transmitter].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ingenious_mana_battery, 'ingenious_mana_battery')) and cooldown[classtable.ingenious_mana_battery].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.ingenious_mana_battery, cooldown[classtable.ingenious_mana_battery].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (targets >= 3) and cooldown[classtable.Blizzard].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and (targets <= 2) and cooldown[classtable.Frostbolt].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
end
function Frost:cds()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (timeInCombat <0.2 and targets <= 2 and talents[classtable.Splinterstorm]) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IcyVeins, 'IcyVeins')) and cooldown[classtable.IcyVeins].ready then
        MaxDps:GlowCooldown(classtable.IcyVeins, cooldown[classtable.IcyVeins].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and (ttd <32+20 * (MaxDps:CheckEquipped('SpymastersWeb')and 1 or 0) or MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.IcyVeins or (cooldown[classtable.IcyVeins].remains <12 or cooldown[classtable.IcyVeins].remains <22 and cooldown[classtable.ShiftingPower].remains <10)) and cooldown[classtable.treacherous_transmitter].ready then
        MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.spymasters_web, 'spymasters_web')) and (ttd <20 or buff[classtable.IcyVeinsBuff].remains <19 and (ttd <105 or buff[classtable.SpymastersReportBuff].count >= 32) and (buff[classtable.IcyVeinsBuff].remains >15 or MaxDps:CheckTrinketCooldown('TreacherousTransmitter') >50)) and cooldown[classtable.spymasters_web].ready then
        MaxDps:GlowCooldown(classtable.spymasters_web, cooldown[classtable.spymasters_web].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.arazs_ritual_forge, 'arazs_ritual_forge')) and cooldown[classtable.arazs_ritual_forge].ready then
        if not setSpell then setSpell = classtable.arazs_ritual_forge end
    end
    if (MaxDps:CheckSpellUsable(classtable.signet_of_the_priory, 'signet_of_the_priory')) and cooldown[classtable.signet_of_the_priory].ready then
        MaxDps:GlowCooldown(classtable.signet_of_the_priory, cooldown[classtable.signet_of_the_priory].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.sunblood_amethyst, 'sunblood_amethyst')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <20) and cooldown[classtable.sunblood_amethyst].ready then
        if not setSpell then setSpell = classtable.sunblood_amethyst end
    end
    if (MaxDps:CheckSpellUsable(classtable.lily_of_the_eternal_weave, 'lily_of_the_eternal_weave')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <20) and cooldown[classtable.lily_of_the_eternal_weave].ready then
        if not setSpell then setSpell = classtable.lily_of_the_eternal_weave end
    end
    if (MaxDps:CheckSpellUsable(classtable.funhouse_lens, 'funhouse_lens')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <20) and cooldown[classtable.funhouse_lens].ready then
        MaxDps:GlowCooldown(classtable.funhouse_lens, cooldown[classtable.funhouse_lens].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.mereldars_toll, 'mereldars_toll')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <15) and cooldown[classtable.mereldars_toll].ready then
        if not setSpell then setSpell = classtable.mereldars_toll end
    end
    if (MaxDps:CheckSpellUsable(classtable.house_of_cards, 'house_of_cards')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <20) and cooldown[classtable.house_of_cards].ready then
        MaxDps:GlowCooldown(classtable.house_of_cards, cooldown[classtable.house_of_cards].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.flarendos_pilot_light, 'flarendos_pilot_light')) and cooldown[classtable.flarendos_pilot_light].ready then
        MaxDps:GlowCooldown(classtable.flarendos_pilot_light, cooldown[classtable.flarendos_pilot_light].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.soulletting_ruby, 'soulletting_ruby')) and cooldown[classtable.soulletting_ruby].ready then
        if not setSpell then setSpell = classtable.soulletting_ruby end
    end
    if (MaxDps:CheckSpellUsable(classtable.quickwick_candlestick, 'quickwick_candlestick')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <20) and cooldown[classtable.quickwick_candlestick].ready then
        if not setSpell then setSpell = classtable.quickwick_candlestick end
    end
    if (MaxDps:CheckSpellUsable(classtable.imperfect_ascendancy_serum, 'imperfect_ascendancy_serum')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <20) and cooldown[classtable.imperfect_ascendancy_serum].ready then
        MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, cooldown[classtable.imperfect_ascendancy_serum].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.burst_of_knowledge, 'burst_of_knowledge')) and (buff[classtable.IcyVeinsBuff].remains >10 or MaxDps:boss() and ttd <20) and cooldown[classtable.burst_of_knowledge].ready then
        MaxDps:GlowCooldown(classtable.burst_of_knowledge, cooldown[classtable.burst_of_knowledge].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ratfang_toxin, 'ratfang_toxin')) and (timeInCombat >10) and cooldown[classtable.ratfang_toxin].ready then
        MaxDps:GlowCooldown(classtable.ratfang_toxin, cooldown[classtable.ratfang_toxin].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and (targets <= 2 or (MaxDps.spellHistory[1] == classtable.CometStorm) or ttd <20) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (timeInCombat <0.2 and targets <= 2) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and (timeInCombat <0.2 and targets >= 3) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
end
function Frost:ff_aoe()
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and (MaxDps.spellHistory[1] == classtable.CometStorm)) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.Freeze, 'Freeze')) and (freezable() and (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ConeofCold] and GetTime() - MaxDps.spellHistoryTime[classtable.ConeofCold].last_used or 0) >8 and ((MaxDps.spellHistory[1] == classtable.GlacialSpike) and debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up or (MaxDps.spellHistory[1] == classtable.CometStorm))) and cooldown[classtable.Freeze].ready then
        if not setSpell then setSpell = classtable.Freeze end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and (not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and freezable() and (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ConeofCold] and GetTime() - MaxDps.spellHistoryTime[classtable.ConeofCold].last_used or 0) >8 and ((MaxDps.spellHistory[1] == classtable.GlacialSpike) and debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up or (MaxDps.spellHistory[1] == classtable.CometStorm))) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up and (MaxDps.spellHistory[1] == classtable.GlacialSpike)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.ExcessFireBuff].count == 2 and cooldown[classtable.CometStorm].ready) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (talents[classtable.IceCaller] or talents[classtable.FreezingRain]) and cooldown[classtable.Blizzard].ready then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt') and talents[classtable.FrostfireBolt]) and (talents[classtable.DeathsChill] and buff[classtable.IcyVeinsBuff].up and (buff[classtable.DeathsChillBuff].count <9 or buff[classtable.DeathsChillBuff].count == 9 and not (MaxDps.spellHistory[1] == classtable.FrostfireBolt))) and cooldown[classtable.FrostfireBolt].ready then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (talents[classtable.DeathsChill] and buff[classtable.ExcessFireBuff].count == 2 and cooldown[classtable.CometStorm].ready) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and (cooldown[classtable.ConeofCold].remains >12 or cooldown[classtable.ConeofCold].ready) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and (talents[classtable.SplinteringRay] and debuff[classtable.WintersChillDeBuff].count == 2) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike') and talents[classtable.GlacialSpike]) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (buff[classtable.ExcessFrostBuff].up) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and ((not MaxDps:CheckEquipped('ArazsRitualForge') or not buff[classtable.IcyVeinsBuff].up) and cooldown[classtable.IcyVeins].remains >8 and (cooldown[classtable.CometStorm].remains >8 or not talents[classtable.CometStorm]) and cooldown[classtable.Blizzard].remains >6*gcd) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt') and talents[classtable.FrostfireBolt]) and (buff[classtable.FrostfireEmpowermentBuff].up and not buff[classtable.ExcessFireBuff].up) and cooldown[classtable.FrostfireBolt].ready then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt') and talents[classtable.FrostfireBolt]) and cooldown[classtable.FrostfireBolt].ready then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if GetUnitSpeed('player') > 0 then
    Frost:movement()
    end
end
function Frost:ff_cleave()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and ((MaxDps.spellHistory[1] == classtable.GlacialSpike) or (MaxDps.spellHistory[1] == classtable.FrostfireBolt) or (MaxDps.spellHistory[1] == classtable.CometStorm)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike') and talents[classtable.GlacialSpike]) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (not buff[classtable.IcyVeinsBuff].up and buff[classtable.FreezingRainBuff].up) and cooldown[classtable.Blizzard].ready then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and ((not MaxDps:CheckEquipped('ArazsRitualForge') or not buff[classtable.IcyVeinsBuff].up) and cooldown[classtable.IcyVeins].remains >8 and (cooldown[classtable.CometStorm].remains >8 or not talents[classtable.CometStorm])) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (not talents[classtable.DeathsChill] and debuff[classtable.WintersChillDeBuff].count == 2) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt') and talents[classtable.FrostfireBolt]) and cooldown[classtable.FrostfireBolt].ready then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if GetUnitSpeed('player') > 0 then
    Frost:movement()
    end
end
function Frost:ff_st()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up and (MaxDps.spellHistory[1] == classtable.GlacialSpike)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up and (buff[classtable.IciclesBuff].count >= 3 or not talents[classtable.GlacialSpike])) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and (debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and (debuff[classtable.WintersChillDeBuff].count == 2) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike') and talents[classtable.GlacialSpike]) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and ((not MaxDps:CheckEquipped('ArazsRitualForge') or not buff[classtable.IcyVeinsBuff].up) and cooldown[classtable.IcyVeins].remains >8 and (cooldown[classtable.CometStorm].remains >8 or not talents[classtable.CometStorm])) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt') and talents[classtable.FrostfireBolt]) and cooldown[classtable.FrostfireBolt].ready then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if GetUnitSpeed('player') > 0 then
    Frost:movement()
    end
end
function Frost:ff_st_boltspam()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up and (MaxDps.spellHistory[1] == classtable.GlacialSpike)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and ((MaxDps.spellHistory[1] == classtable.FrostfireBolt) and buff[classtable.IciclesBuff].count >= 3) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and (debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike') and talents[classtable.GlacialSpike]) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (not buff[classtable.IcyVeinsBuff].up and cooldown[classtable.CometStorm].remains >8 and cooldown[classtable.IcyVeins].remains >8) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (debuff[classtable.WintersChillDeBuff].count == 2) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and not buff[classtable.IciclesBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt') and talents[classtable.FrostfireBolt]) and cooldown[classtable.FrostfireBolt].ready then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if GetUnitSpeed('player') > 0 then
    Frost:movement()
    end
end
function Frost:movement()
    if (MaxDps:CheckSpellUsable(classtable.IceFloes, 'IceFloes')) and (not buff[classtable.IceFloesBuff].up) and cooldown[classtable.IceFloes].ready then
        if not setSpell then setSpell = classtable.IceFloes end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blink, 'Blink')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >40) and cooldown[classtable.Blink].ready then
        if not setSpell then setSpell = classtable.Blink end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and (talents[classtable.Splinterstorm]) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
end
function Frost:ss_aoe()
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and ((MaxDps.spellHistory[1] == classtable.FrozenOrb) or cooldown[classtable.FrozenOrb].remains >30)) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and ((freezable() or talents[classtable.UnerringProficiency]) and targets >= 5 and (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ConeofCold] and GetTime() - MaxDps.spellHistoryTime[classtable.ConeofCold].last_used or 0) <8 and (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ConeofCold] and GetTime() - MaxDps.spellHistoryTime[classtable.ConeofCold].last_used or 0) >7) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Freeze, 'Freeze')) and (freezable() and ((MaxDps.spellHistory[1] == classtable.GlacialSpike) or not talents[classtable.GlacialSpike] and (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ConeofCold] and GetTime() - MaxDps.spellHistoryTime[classtable.ConeofCold].last_used or 0) >8)) and cooldown[classtable.Freeze].ready then
        if not setSpell then setSpell = classtable.Freeze end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up and (MaxDps.spellHistory[1] == classtable.GlacialSpike)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (debuff[classtable.WintersChillDeBuff].count == 0 and not debuff[classtable.WintersChillDeBuff].up and (MaxDps.spellHistory[1] == classtable.Frostbolt)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (buff[classtable.ColdFrontReadyBuff].up) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (talents[classtable.IceCaller] or talents[classtable.FreezingRain]) and cooldown[classtable.Blizzard].ready then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and (talents[classtable.GlacialAssault] or not buff[classtable.IcyVeinsBuff].up) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and (talents[classtable.SplinteringRay] and not buff[classtable.IcyVeinsBuff].up and debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (talents[classtable.ShiftingShards]) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].count == 2 and talents[classtable.GlacialSpike]) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike') and talents[classtable.GlacialSpike]) and (buff[classtable.IciclesBuff].count == 5 and (cooldown[classtable.Flurry].ready or debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and (talents[classtable.DeathsChill] and buff[classtable.IcyVeinsBuff].up and (buff[classtable.DeathsChillBuff].count <6 or buff[classtable.DeathsChillBuff].count == 6 and not (MaxDps.spellHistory[1] == classtable.Frostbolt))) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (not buff[classtable.IcyVeinsBuff].up and cooldown[classtable.IcyVeins].remains >8) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
    Frost:movement()
    end
end
function Frost:ss_cleave()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and ((MaxDps.spellHistory[1] == classtable.GlacialSpike)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (not debuff[classtable.WintersChillDeBuff].up and debuff[classtable.WintersChillDeBuff].count == 0 and (MaxDps.spellHistory[1] == classtable.Frostbolt)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (not debuff[classtable.WintersChillDeBuff].up and debuff[classtable.WintersChillDeBuff].count == 0 and talents[classtable.ShiftingShards] and buff[classtable.ColdFrontReadyBuff].up) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up == 2 and talents[classtable.GlacialSpike]) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and (not buff[classtable.IcyVeinsBuff].up and debuff[classtable.WintersChillDeBuff].up and talents[classtable.ShiftingShards]) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (not MaxDps:CheckEquipped('ArazsRitualForge') and cooldown[classtable.Flurry].charges <2 and cooldown[classtable.IcyVeins].remains >8 or talents[classtable.ShiftingShards]) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike') and talents[classtable.GlacialSpike]) and (buff[classtable.IciclesBuff].count == 5 and (cooldown[classtable.Flurry].ready or debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (buff[classtable.FreezingRainBuff].up and talents[classtable.IceCaller]) and cooldown[classtable.Blizzard].ready then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and (talents[classtable.DeathsChill] and buff[classtable.IcyVeinsBuff].up and (buff[classtable.DeathsChillBuff].count <8 or buff[classtable.DeathsChillBuff].count == 8 and not (MaxDps.spellHistory[1] == classtable.Frostbolt))) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (MaxDps:CheckEquipped('ArazsRitualForge') and not buff[classtable.IcyVeinsBuff].up and cooldown[classtable.Flurry].charges <2 and cooldown[classtable.IcyVeins].remains >8) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
    Frost:movement()
    end
end
function Frost:ss_st()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (not debuff[classtable.WintersChillDeBuff].up and debuff[classtable.WintersChillDeBuff].count == 0 and (MaxDps.spellHistory[1] == classtable.GlacialSpike)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (not debuff[classtable.WintersChillDeBuff].up and debuff[classtable.WintersChillDeBuff].count == 0 and (buff[classtable.IciclesBuff].count <5 or not talents[classtable.GlacialSpike]) and (MaxDps.spellHistory[1] == classtable.Frostbolt)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm') and talents[classtable.CometStorm]) and (not buff[classtable.IcyVeinsBuff].up and debuff[classtable.WintersChillDeBuff].up and talents[classtable.ShiftingShards]) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and (not buff[classtable.IcyVeinsBuff].up and debuff[classtable.WintersChillDeBuff].count == 1) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (not MaxDps:CheckEquipped('ArazsRitualForge') and cooldown[classtable.Flurry].charges <2 and cooldown[classtable.IcyVeins].remains >8 or talents[classtable.ShiftingShards]) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike') and talents[classtable.GlacialSpike]) and (buff[classtable.IciclesBuff].count == 5 and (cooldown[classtable.Flurry].ready or debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (not buff[classtable.IcyVeinsBuff].up and buff[classtable.FreezingRainBuff].up and talents[classtable.IceCaller]) and cooldown[classtable.Blizzard].ready then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (debuff[classtable.WintersChillDeBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (MaxDps:CheckEquipped('ArazsRitualForge') and not buff[classtable.IcyVeinsBuff].up and cooldown[classtable.Flurry].charges <2 and cooldown[classtable.IcyVeins].remains >8) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
    Frost:movement()
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.MirrorImage, false)
    MaxDps:GlowCooldown(classtable.treacherous_transmitter, false)
    MaxDps:GlowCooldown(classtable.ingenious_mana_battery, false)
    MaxDps:GlowCooldown(classtable.Counterspell, false)
    MaxDps:GlowCooldown(classtable.IcyVeins, false)
    MaxDps:GlowCooldown(classtable.spymasters_web, false)
    MaxDps:GlowCooldown(classtable.signet_of_the_priory, false)
    MaxDps:GlowCooldown(classtable.funhouse_lens, false)
    MaxDps:GlowCooldown(classtable.house_of_cards, false)
    MaxDps:GlowCooldown(classtable.flarendos_pilot_light, false)
    MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, false)
    MaxDps:GlowCooldown(classtable.burst_of_knowledge, false)
    MaxDps:GlowCooldown(classtable.ratfang_toxin, false)
    MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, false)
end

function Frost:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Frost:cds()
    if (talents[classtable.FrostfireBolt] and targets >= 3) then
        Frost:ff_aoe()
    end
    if (not talents[classtable.FrostfireBolt] and targets >= 3) then
        Frost:ss_aoe()
    end
    if (talents[classtable.FrostfireBolt] and targets == 2) then
        Frost:ff_cleave()
    end
    if (not talents[classtable.FrostfireBolt] and targets == 2) then
        Frost:ss_cleave()
    end
    if (talents[classtable.FrostfireBolt] and (talents[classtable.GlacialSpike] and talents[classtable.SlickIce] and talents[classtable.ColdFront] and talents[classtable.DeathsChill] and talents[classtable.DeepShatter])) then
        Frost:ff_st_boltspam()
    end
    if (talents[classtable.FrostfireBolt]) then
        Frost:ff_st()
    end
    if (not talents[classtable.FrostfireBolt]) then
        Frost:ss_st()
    end
end
function Mage:Frost()
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
    classtable.IcyVeinsBuff = 12472
    classtable.CrypticInstructionsBuff = 449946
    classtable.RealigningNexusConvergenceDivergenceBuff = 449947
    classtable.ErrantManaforgeEmissionBuff = 449952
    classtable.SpymastersReportBuff = 451199
    classtable.PowerInfusionBuff = 10060
    classtable.BlessingofSummerBuff = 0
    classtable.ExcessFireBuff = 438624
    classtable.DeathsChillBuff = 454371
    classtable.IciclesBuff = 205473
    classtable.ExcessFrostBuff = 438611
    classtable.FrostfireEmpowermentBuff = 431177
    classtable.FingersofFrostBuff = 44544
    classtable.FreezingRainBuff = 270232
    classtable.IceFloesBuff = 108839
    classtable.ColdFrontReadyBuff = 382114
    classtable.WintersChillDeBuff = 228358
    classtable.Freeze = 33395

    local function debugg()
        talents[classtable.FrostfireBolt] = 1
        talents[classtable.GlacialSpike] = 1
        talents[classtable.SlickIce] = 1
        talents[classtable.ColdFront] = 1
        talents[classtable.DeathsChill] = 1
        talents[classtable.DeepShatter] = 1
        talents[classtable.Splinterstorm] = 1
        talents[classtable.ColdestSnap] = 1
        talents[classtable.IceCaller] = 1
        talents[classtable.FreezingRain] = 1
        talents[classtable.SplinteringRay] = 1
        talents[classtable.CometStorm] = 1
        talents[classtable.UnerringProficiency] = 1
        talents[classtable.GlacialAssault] = 1
        talents[classtable.ShiftingShards] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Frost:precombat()

    Frost:callaction()
    if setSpell then return setSpell end
end
