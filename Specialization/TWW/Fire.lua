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

local Fire = {}

local cast_remains_time = 0
local pooling_time = 0
local ff_combustion_flamestrike = 100
local ff_filler_flamestrike = 100
local sf_combustion_flamestrike = 100
local sf_filler_flamestrike = 100
local treacherous_transmitter_precombat_cast = 12
local combustion_on_use = false
local on_use_cutoff = 20
local combustion_precast_time = false


local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


local hot_streak_spells = {
    'Fireball',
    'PhoenixFlames',
    'Pyroblast',
    'Scorch',
}
local function hot_streak_spells_in_flight()
    local count = 0
    for i, Spell in ipairs( hot_streak_spells ) do
        if MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[C_Spell.GetSpellName(classtable[Spell])] then
            local spellTime = MaxDps.spellHistoryTime[C_Spell.GetSpellName(classtable[Spell])].last_used
            if GetTime() - spellTime > 0 then
                count = count +1
            end
        end
    end
    return count
end
local function GetCombustionStacks()
    local stacks = 0
    if buff[classtable.CombustionBuff].up then
        stacks = buff[classtable.CombustionBuff].applications
    end
    return stacks
end


function Fire:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneIntellect, 'ArcaneIntellect')) and not buff[classtable.ArcaneIntellect].up and cooldown[classtable.ArcaneIntellect].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ArcaneIntellect end
    end
    cast_remains_time = 0.2
    pooling_time = 15 * gcd
    if talents[classtable.FrostfireBolt] then
        ff_combustion_flamestrike = 100
    end
    if talents[classtable.FrostfireBolt] then
        ff_filler_flamestrike = 100
    end
    if talents[classtable.SpellfireSpheres] then
        sf_combustion_flamestrike = 100-(50 * (talents[classtable.MarkoftheFirelord] and talents[classtable.MarkoftheFirelord] or 0))-(44 * (talents[classtable.Quickflame] and talents[classtable.Quickflame] or 0))
    end
    if talents[classtable.SpellfireSpheres] then
        sf_filler_flamestrike = 100
    end
    if MaxDps:CheckEquipped('TreacherousTransmitter') then
        treacherous_transmitter_precombat_cast = 12
    end
    --if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and cooldown[classtable.treacherous_transmitter].ready and not UnitAffectingCombat('player') then
    --    MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    --end
    combustion_on_use = MaxDps:CheckEquipped('GladiatorsBadge') or MaxDps:CheckEquipped('TreacherousTransmitter') or MaxDps:CheckEquipped('MoonlitPrism') or MaxDps:CheckEquipped('IrideusFragment') or MaxDps:CheckEquipped('SpoilsofNeltharus') or MaxDps:CheckEquipped('TimebreachingTalon') or MaxDps:CheckEquipped('HornofValor')
    if combustion_on_use then
        on_use_cutoff = 20
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.MirrorImage, cooldown[classtable.MirrorImage].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt') and talents[classtable.FrostfireBolt]) and (talents[classtable.FrostfireBolt]) and cooldown[classtable.FrostfireBolt].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and (not talents[classtable.Firestarter]) and cooldown[classtable.Combustion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Combustion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and cooldown[classtable.Pyroblast].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
end
function Fire:cds()
    combustion_precast_time = (talents[classtable.FrostfireBolt] and talents[classtable.FrostfireBolt] or 0)*(( classtable and classtable.Fireball and GetSpellInfo(classtable.Fireball).castTime / 1000 or 0)*((not buff[classtable.ImprovedScorch].up and 0 or 1) or (( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime / 1000 or 0) <gcd and 1 or 0) )+( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime / 1000 or 0)*((( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime / 1000 or 0) >= gcd) and buff[classtable.ImprovedScorch].upMath or 0) and 1 or 0)+(talents[classtable.SpellfireSpheres] and talents[classtable.SpellfireSpheres] or 0)*(( classtable and classtable.Fireball and GetSpellInfo(classtable.Fireball).castTime / 1000 or 0)*((( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime / 1000 or 0) <gcd and 1 or 0) and buff[classtable.HotStreakBuff].upMath or not talents[classtable.Scorch])+( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime / 1000 or 0)*((( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime / 1000 or 0) >= gcd and 1 or 0) or not buff[classtable.HotStreakBuff].up))-cast_remains_time
    if (MaxDps:CheckSpellUsable(classtable.arazs_ritual_forge, 'arazs_ritual_forge')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.arazs_ritual_forge].ready then
        if not setSpell then setSpell = classtable.arazs_ritual_forge end
    end
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.gladiators_badge, 'gladiators_badge')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.gladiators_badge].ready then
        MaxDps:GlowCooldown(classtable.gladiators_badge, cooldown[classtable.gladiators_badge].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.signet_of_the_priory, 'signet_of_the_priory')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.signet_of_the_priory].ready then
        MaxDps:GlowCooldown(classtable.signet_of_the_priory, cooldown[classtable.signet_of_the_priory].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.sunblood_amethyst, 'sunblood_amethyst')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.sunblood_amethyst].ready then
        if not setSpell then setSpell = classtable.sunblood_amethyst end
    end
    if (MaxDps:CheckSpellUsable(classtable.lily_of_the_eternal_weave, 'lily_of_the_eternal_weave')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.lily_of_the_eternal_weave].ready then
        if not setSpell then setSpell = classtable.lily_of_the_eternal_weave end
    end
    if (MaxDps:CheckSpellUsable(classtable.funhouse_lens, 'funhouse_lens')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.funhouse_lens].ready then
        MaxDps:GlowCooldown(classtable.funhouse_lens, cooldown[classtable.funhouse_lens].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.mereldars_toll, 'mereldars_toll')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <15) and cooldown[classtable.mereldars_toll].ready then
        if not setSpell then setSpell = classtable.mereldars_toll end
    end
    if (MaxDps:CheckSpellUsable(classtable.flarendos_pilot_light, 'flarendos_pilot_light')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.flarendos_pilot_light].ready then
        MaxDps:GlowCooldown(classtable.flarendos_pilot_light, cooldown[classtable.flarendos_pilot_light].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.house_of_cards, 'house_of_cards')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.house_of_cards].ready then
        MaxDps:GlowCooldown(classtable.house_of_cards, cooldown[classtable.house_of_cards].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.soulletting_ruby, 'soulletting_ruby')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.soulletting_ruby].ready then
        if not setSpell then setSpell = classtable.soulletting_ruby end
    end
    if (MaxDps:CheckSpellUsable(classtable.quickwick_candlestick, 'quickwick_candlestick')) and (buff[classtable.CombustionBuff].remains >6 or MaxDps:boss() and ttd <20) and cooldown[classtable.quickwick_candlestick].ready then
        if not setSpell then setSpell = classtable.quickwick_candlestick end
    end
    --if (MaxDps:CheckSpellUsable(classtable.hyperthread_wristwraps, 'hyperthread_wristwraps')) and (hyperthread_wristwraps.fire_blast >= 2 and buff[classtable.CombustionBuff].up and cooldown[classtable.FireBlast].charges == 0) and cooldown[classtable.hyperthread_wristwraps].ready then
    --    MaxDps:GlowCooldown(classtable.hyperthread_wristwraps, cooldown[classtable.hyperthread_wristwraps].ready)
    --end
end
function Fire:ff_combustion()
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and (not buff[classtable.CombustionBuff].up and (IsCurrentSpell(classtable.Fireball)) and ((select(9,UnitCastingInfo('player')) == classtable.Fireball and select(5,UnitCastingInfo('player')) or 0) <cast_remains_time) or (MaxDps.spellHistory[1] == classtable.Meteor) and ((cooldown[classtable.Meteor].duration >0 and cooldown[classtable.Meteor].duration /100) <cast_remains_time) or (IsCurrentSpell(classtable.Pyroblast)) and ((select(9,UnitCastingInfo('player')) == classtable.Pyroblast and select(5,UnitCastingInfo('player')) or 0) <cast_remains_time) or (IsCurrentSpell(classtable.Scorch)) and ((select(9,UnitCastingInfo('player')) == classtable.Scorch and select(5,UnitCastingInfo('player')) or 0) <cast_remains_time)) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and not (IsCurrentSpell(classtable.Scorch)) and not (IsCurrentSpell(classtable.Fireball)) and not (IsCurrentSpell(classtable.Pyroblast)) and not buff[classtable.HotStreakBuff].up and gcd and gcd <gcd and (hot_streak_spells_in_flight() + buff[classtable.HeatingUpBuff].upMath)<2 and not buff[classtable.FuryoftheSunKingBuff].up) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Pyroblast)) and (select(9,UnitCastingInfo('player')) == classtable.Pyroblast and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Fireball)) and (select(9,UnitCastingInfo('player')) == classtable.Fireball and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and not buff[classtable.HeatingUpBuff].up and not buff[classtable.HotStreakBuff].up and (IsCurrentSpell(classtable.Scorch)) and (select(9,UnitCastingInfo('player')) == classtable.Scorch and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.FuryoftheSunKingBuff].up and targets >= ff_combustion_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.FuryoftheSunKingBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Meteor, 'Meteor')) and (not buff[classtable.CombustionBuff].up or buff[classtable.CombustionBuff].remains >2) and cooldown[classtable.Meteor].ready then
        if not setSpell then setSpell = classtable.Meteor end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (not buff[classtable.CombustionBuff].up and not (MaxDps.spellHistory[1] == classtable.Scorch) and ( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime /1000 or 0) >= gcd and (buff[classtable.HeatShimmerBuff].up and talents[classtable.ImprovedScorch] or buff[classtable.ImprovedScorch].up)) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (not buff[classtable.CombustionBuff].up) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.HotStreakBuff].up and targets >= ff_combustion_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up and targets >= ff_combustion_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HotStreakBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and (buff[classtable.ExcessFrostBuff].up and (not (MaxDps.spellHistory[1] == classtable.Pyroblast) or not buff[classtable.HeatingUpBuff].up)) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
end
function Fire:ff_filler()
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Fireball)) and (select(9,UnitCastingInfo('player')) == classtable.Fireball and select(5,UnitCastingInfo('player')) or 0) <0.5 and ((cooldown[classtable.Combustion].remains >pooling_time) or talents[classtable.SunKingsBlessing])) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Pyroblast)) and (select(9,UnitCastingInfo('player')) == classtable.Pyroblast and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not buff[classtable.HotStreakBuff].up and not buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Scorch)) and (select(9,UnitCastingInfo('player')) == classtable.Scorch and select(5,UnitCastingInfo('player')) or 0) <0.5 and ((cooldown[classtable.Combustion].remains >pooling_time) or talents[classtable.SunKingsBlessing])) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not buff[classtable.HotStreakBuff].up and (IsCurrentSpell(classtable.ShiftingPower)) and ((cooldown[classtable.Combustion].remains >pooling_time) or talents[classtable.SunKingsBlessing])) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not buff[classtable.HotStreakBuff].up and (hot_streak_spells_in_flight() + buff[classtable.HeatingUpBuff].upMath<2) and buff[classtable.HyperthermiaBuff].up and gcd <gcd and ((cooldown[classtable.Combustion].remains >pooling_time) or talents[classtable.SunKingsBlessing])) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Meteor, 'Meteor')) and (((cooldown[classtable.Combustion].remains >pooling_time) or talents[classtable.SunKingsBlessing])) and cooldown[classtable.Meteor].ready then
        if not setSpell then setSpell = classtable.Meteor end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and ((buff[classtable.ImprovedScorch].up or buff[classtable.HeatShimmerBuff].up and talents[classtable.ImprovedScorch]) and debuff[classtable.ImprovedScorchDeBuff].remains <3*gcd and not (MaxDps.spellHistory[1] == classtable.Scorch)) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.FuryoftheSunKingBuff].up and targets >= ff_filler_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.HyperthermiaBuff].up and targets >= ff_filler_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up and targets >= ff_filler_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.HotStreakBuff].up and targets >= ff_filler_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.FuryoftheSunKingBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HyperthermiaBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HotStreakBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (cooldown[classtable.Combustion].remains >10) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (talents[classtable.SunKingsBlessing] and buff[classtable.FrostfireEmpowermentBuff].up) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and ((buff[classtable.ExcessFrostBuff].up or talents[classtable.SunKingsBlessing]) and not ((MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.FrostfireBolt] and GetTime() - MaxDps.spellHistoryTime[classtable.FrostfireBolt].last_used or 0) <0.5)) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (talents[classtable.SunKingsBlessing] and ((targethealthPerc <=30) or buff[classtable.HeatShimmerBuff].up)) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
end
function Fire:sf_combustion()
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and ((IsCurrentSpell(classtable.Fireball)) and ((select(9,UnitCastingInfo('player')) == classtable.Fireball and select(5,UnitCastingInfo('player')) or 0) <cast_remains_time) or (IsCurrentSpell(classtable.Scorch)) and ((select(9,UnitCastingInfo('player')) == classtable.Scorch and select(5,UnitCastingInfo('player')) or 0) <cast_remains_time)) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and not (IsCurrentSpell(classtable.Scorch)) and not (IsCurrentSpell(classtable.Fireball)) and not (IsCurrentSpell(classtable.Pyroblast)) and not buff[classtable.HotStreakBuff].up and gcd and gcd <gcd and (not talents[classtable.GloriousIncandescence] or buff[classtable.GloriousIncandescenceBuff].up or cooldown[classtable.FireBlast].charges >1.7 or buff[classtable.CombustionBuff].remains<(gcd * cooldown[classtable.FireBlast].charges)) and (hot_streak_spells_in_flight() + buff[classtable.HeatingUpBuff].upMath)<2) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Pyroblast)) and (select(9,UnitCastingInfo('player')) == classtable.Pyroblast and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Fireball)) and (select(9,UnitCastingInfo('player')) == classtable.Fireball and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.CombustionBuff].up and not buff[classtable.HeatingUpBuff].up and not buff[classtable.HotStreakBuff].up and (IsCurrentSpell(classtable.Scorch)) and (select(9,UnitCastingInfo('player')) == classtable.Scorch and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (not buff[classtable.CombustionBuff].up and (( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime /1000 or 0) >= gcd or not buff[classtable.HotStreakBuff].up)) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (not buff[classtable.CombustionBuff].up) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.HotStreakBuff].up and targets >= sf_combustion_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up and targets >= sf_combustion_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HotStreakBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and ((buff[classtable.ImprovedScorch].up or buff[classtable.HeatShimmerBuff].up) and debuff[classtable.ImprovedScorchDeBuff].remains <4*gcd) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
end
function Fire:sf_filler()
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Fireball)) and (select(9,UnitCastingInfo('player')) == classtable.Fireball and select(5,UnitCastingInfo('player')) or 0) <0.5) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not buff[classtable.HotStreakBuff].up and not buff[classtable.HeatingUpBuff].up and (IsCurrentSpell(classtable.Scorch)) and (select(9,UnitCastingInfo('player')) == classtable.Scorch and select(5,UnitCastingInfo('player')) or 0) <0.5 and cooldown[classtable.Combustion].remains >pooling_time) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not buff[classtable.HotStreakBuff].up and (IsCurrentSpell(classtable.ShiftingPower)) and cooldown[classtable.Combustion].remains >pooling_time) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not buff[classtable.HotStreakBuff].up and (hot_streak_spells_in_flight() + buff[classtable.HeatingUpBuff].upMath<2) and (buff[classtable.HyperthermiaBuff].up or buff[classtable.HyperthermiaBuff].up and buff[classtable.LesserTimeWarpBuff].up) and gcd <gcd and (not talents[classtable.GloriousIncandescence] or buff[classtable.GloriousIncandescenceBuff].up or cooldown[classtable.FireBlast].charges >1.7 or buff[classtable.HyperthermiaBuff].remains<(gcd * cooldown[classtable.FireBlast].charges)) and cooldown[classtable.Combustion].remains >pooling_time) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (targets >= 2 and not buff[classtable.HotStreakBuff].up and (hot_streak_spells_in_flight() + buff[classtable.HeatingUpBuff].upMath<2) and buff[classtable.GloriousIncandescenceBuff].up and cooldown[classtable.Combustion].remains >pooling_time) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and ((buff[classtable.HyperthermiaBuff].up or buff[classtable.HyperthermiaBuff].up and buff[classtable.LesserTimeWarpBuff].up) and targets >= sf_filler_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.HotStreakBuff].up and targets >= sf_filler_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up and targets >= sf_filler_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HyperthermiaBuff].up or buff[classtable.HyperthermiaBuff].up and buff[classtable.LesserTimeWarpBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HotStreakBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (buff[classtable.HeatShimmerBuff].up) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Meteor, 'Meteor')) and (targets >= 2) and cooldown[classtable.Meteor].ready then
        if not setSpell then setSpell = classtable.Meteor end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and (buff[classtable.HeatingUpBuff].up or cooldown[classtable.FireBlast].ready or cooldown[classtable.PhoenixFlames].charges >1.5 or buff[classtable.BornofFlameBuff].up) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and ((targethealthPerc <=30)) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.treacherous_transmitter, false)
    MaxDps:GlowCooldown(classtable.MirrorImage, false)
    MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, false)
    MaxDps:GlowCooldown(classtable.gladiators_badge, false)
    MaxDps:GlowCooldown(classtable.signet_of_the_priory, false)
    MaxDps:GlowCooldown(classtable.funhouse_lens, false)
    MaxDps:GlowCooldown(classtable.flarendos_pilot_light, false)
    MaxDps:GlowCooldown(classtable.house_of_cards, false)
    MaxDps:GlowCooldown(classtable.hyperthread_wristwraps, false)
end

function Fire:callaction()
    classtable.CounterSpell = classtable.Counterspell
    --if (MaxDps:CheckSpellUsable(classtable.CounterSpell, 'CounterSpell')) and cooldown[classtable.CounterSpell].ready then
    --    if not setSpell then setSpell = classtable.CounterSpell end
    --end
    if (not (buff[classtable.HotStreakBuff].up and (MaxDps.spellHistory[1] == classtable.Scorch))) then
        Fire:cds()
    end
    if (talents[classtable.FrostfireBolt] and not buff[classtable.HyperthermiaBuff].up and (cooldown[classtable.Combustion].remains <= combustion_precast_time or buff[classtable.CombustionBuff].up)) then
        Fire:ff_combustion()
    end
    if (not buff[classtable.HyperthermiaBuff].up and not (buff[classtable.HyperthermiaBuff].up and buff[classtable.LesserTimeWarpBuff].up) and (cooldown[classtable.Combustion].remains <= combustion_precast_time or buff[classtable.CombustionBuff].up)) then
        Fire:sf_combustion()
    end
    if (talents[classtable.FrostfireBolt]) then
        Fire:ff_filler()
    end
    Fire:sf_filler()
end
function Mage:Fire()
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
    classtable.Fireball = talents[classtable.FrostfireBolt] and classtable.FrostfireBolt or 133
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.HotStreakBuff = 48108
    classtable.HyperthermiaBuff = 383874
    classtable.CombustionBuff = 190319
    classtable.LesserTimeWarpBuff = 1236231
    classtable.PowerInfusionBuff = 10060
    classtable.BlessingofSummerBuff = 388007
    classtable.HeatingUpBuff = 48107
    classtable.FuryoftheSunKingBuff = 333315
    classtable.HeatShimmerBuff = 458964
    classtable.ExcessFrostBuff = 438611
    classtable.FrostfireEmpowermentBuff = 431177
    classtable.GloriousIncandescenceBuff = 451073
    classtable.BornofFlameBuff = 1219307
    classtable.ImprovedScorchDeBuff = 383608

    local function debugg()
        talents[classtable.FrostfireBolt] = 1
        talents[classtable.SpellfireSpheres] = 1
        talents[classtable.Firestarter] = 1
        talents[classtable.ImprovedScorch] = 1
        talents[classtable.SunKingsBlessing] = 1
        talents[classtable.GloriousIncandescence] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Fire:precombat()

    Fire:callaction()
    if setSpell then return setSpell end
end
