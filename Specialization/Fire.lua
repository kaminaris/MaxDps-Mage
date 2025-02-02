local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

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

local Fire = {}

local firestarter_combustion
local hot_streak_flamestrike
local hard_cast_flamestrike
local combustion_flamestrike
local skb_flamestrike
local arcane_explosion
local arcane_explosion_mana
local combustion_shifting_power
local combustion_cast_remains
local overpool_fire_blasts
local skb_duration
local treacherous_transmitter_precombat_cast
local combustion_on_use
local on_use_cutoff
local shifting_power_before_combustion
local item_cutoff_active
local one
local phoenix_pooling
local ta_combust
local fire_blast_pooling =  false --TODO


local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end

local function castTime()
    local spell, _, _, _, endTime = UnitCastingInfo("player")
    if endTime and endTime > 0 then
        return endTime/1000 - GetTime()
    end
    return math.huge
end

function Fire:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneIntellect, 'ArcaneIntellect')) and not buff[classtable.ArcaneIntellect].up and cooldown[classtable.ArcaneIntellect].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ArcaneIntellect end
    end
    if firestarter_combustion == nil or firestarter_combustion <0 then
        firestarter_combustion = talents[classtable.SunKingsBlessing] or 0
    end
    if hot_streak_flamestrike == nil or hot_streak_flamestrike == 0 then
        hot_streak_flamestrike = 4 * ( talents[classtable.Quickflame] or talents[classtable.FlamePatch] or 1 ) + 999 * ( not talents[classtable.FlamePatch] and not talents[classtable.Quickflame] and 1 or 0)
    end
    if hard_cast_flamestrike == nil or hard_cast_flamestrike == 0 then
        hard_cast_flamestrike = 999
    end
    if combustion_flamestrike == nil or combustion_flamestrike == 0 then
        combustion_flamestrike = 4 * ( talents[classtable.Quickflame] or talents[classtable.FlamePatch] or 1) + 999 * ( not talents[classtable.FlamePatch] and not talents[classtable.Quickflame] and 2 or 1 )
    end
    if skb_flamestrike == nil or skb_flamestrike == 0 then
        skb_flamestrike = 3 * ( talents[classtable.Quickflame] or talents[classtable.FlamePatch] or 1) + 999 * ( not talents[classtable.FlamePatch] and not talents[classtable.Quickflame] and 2 or 1)
    end
    if arcane_explosion == nil or arcane_explosion == 0 then
        arcane_explosion = 999
    end
    arcane_explosion_mana = 40
    if combustion_shifting_power == 0 then
        combustion_shifting_power = 999
    end
    combustion_cast_remains = 0.3
    overpool_fire_blasts = 0
    skb_duration = 6
    treacherous_transmitter_precombat_cast = 12
    combustion_on_use = MaxDps:CheckEquipped('GladiatorsBadge') or MaxDps:CheckEquipped('TreacherousTransmitter') or MaxDps:CheckEquipped('MoonlitPrism') or MaxDps:CheckEquipped('IrideusFragment') or MaxDps:CheckEquipped('SpoilsofNeltharus') or MaxDps:CheckEquipped('TimebreachingTalon') or MaxDps:CheckEquipped('HornofValor')
    if combustion_on_use then
        on_use_cutoff = 20
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MirrorImage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (targets >= hot_streak_flamestrike) and cooldown[classtable.Flamestrike].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and cooldown[classtable.Pyroblast].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
end
function Fire:active_talents()
    if (MaxDps:CheckSpellUsable(classtable.Meteor, 'Meteor')) and (buff[classtable.CombustionBuff].up or ( buff[classtable.SunKingsBlessingBuff].maxStacks - buff[classtable.SunKingsBlessingBuff].count >4 or cooldown[classtable.combustion].duration <= 0 or buff[classtable.CombustionBuff].remains >1 or not talents[classtable.SunKingsBlessing] and ( cooldown[classtable.Meteor].duration <cooldown[classtable.combustion].duration and ttd <cooldown[classtable.combustion].duration ) )) and cooldown[classtable.Meteor].ready then
        if not setSpell then setSpell = classtable.Meteor end
    end
    if (MaxDps:CheckSpellUsable(classtable.DragonsBreath, 'DragonsBreath')) and (talents[classtable.AlexstraszasFury] and ( not buff[classtable.CombustionBuff].up and not buff[classtable.HotStreakBuff].up ) and ( buff[classtable.FeeltheBurnBuff].up or timeInCombat >15 ) and ( not buff[classtable.ImprovedScorch].up )) and cooldown[classtable.DragonsBreath].ready then
        if not setSpell then setSpell = classtable.DragonsBreath end
    end
end
function Fire:combustion_cooldowns()
end
function Fire:combustion_phase()
    if (buff[classtable.CombustionBuff].remains >skb_duration or MaxDps:boss() and ttd <20) then
        Fire:combustion_cooldowns()
    end
    Fire:active_talents()
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (not buff[classtable.CombustionBuff].up and buff[classtable.FuryoftheSunKingBuff].up and buff[classtable.FuryoftheSunKingBuff].remains >( classtable and classtable.Flamestrike and GetSpellInfo(classtable.Flamestrike).castTime /1000 ) and buff[classtable.FuryoftheSunKingBuff].remains == 0 and cooldown[classtable.Combustion].remains <( classtable and classtable.Flamestrike and GetSpellInfo(classtable.Flamestrike).castTime /1000 ) and targets >= skb_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (not buff[classtable.CombustionBuff].up and buff[classtable.FuryoftheSunKingBuff].up and buff[classtable.FuryoftheSunKingBuff].remains >( classtable and classtable.Pyroblast and GetSpellInfo(classtable.Pyroblast).castTime /1000 ) and ( buff[classtable.FuryoftheSunKingBuff].remains == 0 or buff[classtable.FlameAccelerantBuff].up )) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (not buff[classtable.CombustionBuff].up and cooldown[classtable.Combustion].remains <( classtable and classtable.Fireball and GetSpellInfo(classtable.Fireball).castTime /1000 ) and targets <2 and not buff[classtable.ImprovedScorch].up and not ( talents[classtable.SunKingsBlessing] and talents[classtable.FlameAccelerant] )) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (not buff[classtable.CombustionBuff].up and cooldown[classtable.Combustion].remains <( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime /1000 )) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (not buff[classtable.CombustionBuff].up and buff[classtable.FrostfireEmpowermentBuff].up) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and (not buff[classtable.CombustionBuff].up and cooldown[classtable.combustion].duration <= 0 and ( (C_Spell and C_Spell.IsCurrentSpell(classtable.Scorch)) and (gcd) <combustion_cast_remains or (C_Spell and C_Spell.IsCurrentSpell(classtable.Fireball)) and castTime() <combustion_cast_remains or (C_Spell and C_Spell.IsCurrentSpell(classtable.Pyroblast)) and castTime() <combustion_cast_remains or (C_Spell and C_Spell.IsCurrentSpell(classtable.Flamestrike)) and castTime() <combustion_cast_remains or (classtable and classtable.Meteor and GetSpellCooldown(classtable.Meteor).duration >=5 ) and (cooldown[classtable.Meteor].duration >0 and cooldown[classtable.Meteor].duration /100) <combustion_cast_remains )) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    ta_combust = cooldown[classtable.Combustion].remains <10 and buff[classtable.CombustionBuff].up
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and (talents[classtable.SpellfireSpheres] and talents[classtable.PhoenixReborn] and buff[classtable.HeatingUpBuff].up and not buff[classtable.HotStreakBuff].up and buff[classtable.FlamesFuryBuff].up) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (( not ta_combust or talents[classtable.SunKingsBlessing] ) and not fire_blast_pooling and ( not buff[classtable.ImprovedScorch].up or (C_Spell and C_Spell.IsCurrentSpell(classtable.Scorch)) or debuff[classtable.ImprovedScorchDeBuff].remains >4 * gcd ) and ( not buff[classtable.FuryoftheSunKingBuff].up or (C_Spell and C_Spell.IsCurrentSpell(classtable.Pyroblast)) ) and buff[classtable.CombustionBuff].up and not buff[classtable.HotStreakBuff].up and 1 + buff[classtable.HeatingUpBuff].count * ( gcd >0 and 1 or 0) <2) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (ta_combust and not fire_blast_pooling and cooldown[classtable.FireBlast].charges >2.5 and ( not buff[classtable.ImprovedScorch].up or (C_Spell and C_Spell.IsCurrentSpell(classtable.Scorch)) or debuff[classtable.ImprovedScorchDeBuff].remains >4 * gcd ) and ( not buff[classtable.FuryoftheSunKingBuff].up or (C_Spell and C_Spell.IsCurrentSpell(classtable.Pyroblast)) ) and buff[classtable.CombustionBuff].up and not buff[classtable.HotStreakBuff].up and 1 + buff[classtable.HeatingUpBuff].count * ( gcd >0 and 1 or 0) <2) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (( buff[classtable.HotStreakBuff].up and targets >= combustion_flamestrike ) or ( buff[classtable.HyperthermiaBuff].up and targets >= combustion_flamestrike - (talents[classtable.Hyperthermia] and talents[classtable.Hyperthermia] or 0) )) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HyperthermiaBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.HotStreakBuff].up and buff[classtable.CombustionBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and ((MaxDps.spellHistory[1] == classtable.Scorch) and buff[classtable.HeatingUpBuff].up and targets <combustion_flamestrike and buff[classtable.CombustionBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (buff[classtable.FuryoftheSunKingBuff].up and buff[classtable.FuryoftheSunKingBuff].remains >( classtable and classtable.Flamestrike and GetSpellInfo(classtable.Flamestrike).castTime /1000 ) and targets >= skb_flamestrike and buff[classtable.FuryoftheSunKingBuff].remains == 0) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.FuryoftheSunKingBuff].up and buff[classtable.FuryoftheSunKingBuff].remains >( classtable and classtable.Pyroblast and GetSpellInfo(classtable.Pyroblast).castTime /1000 ) and buff[classtable.FuryoftheSunKingBuff].remains == 0) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (buff[classtable.FrostfireEmpowermentBuff].up and not buff[classtable.HotStreakBuff].up and not buff[classtable.ExcessFrostBuff].up) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and (talents[classtable.PhoenixReborn] and buff[classtable.HeatingUpBuff].up and buff[classtable.FlamesFuryBuff].up) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (buff[classtable.ImprovedScorch].up and ( debuff[classtable.ImprovedScorchDeBuff].remains <4 * gcd ) and targets <combustion_flamestrike) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (buff[classtable.HeatShimmerBuff].up and ( talents[classtable.Scald] or talents[classtable.ImprovedScorch] ) and targets <combustion_flamestrike) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and (( not talents[classtable.CalloftheSunKing] and 1 <buff[classtable.CombustionBuff].remains or ( talents[classtable.CalloftheSunKing] and buff[classtable.CombustionBuff].remains <4 or buff[classtable.SunKingsBlessingBuff].count <8 ) ) and buff[classtable.HeatingUpBuff].count + 1 <2) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (buff[classtable.FrostfireEmpowermentBuff].up and not buff[classtable.HotStreakBuff].up) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (buff[classtable.CombustionBuff].remains >( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime /1000 ) and ( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime /1000 ) >= gcd) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
end
function Fire:combustion_timing()
    local combustion_ready_time = cooldown[classtable.Combustion].remains
    one = cooldown[classtable.Combustion].remains
    one = ( classtable and classtable.Fireball and GetSpellInfo(classtable.Fireball).castTime / 1000 ) * ( targets <combustion_flamestrike and 1 or 0) + ( classtable and classtable.Flamestrike and GetSpellInfo(classtable.Flamestrike).castTime / 1000 ) * ( targets >= combustion_flamestrike and 1 or 0) - combustion_cast_remains
    one = combustion_ready_time
    if talents[classtable.Firestarter] and not firestarter_combustion then
        one = (targethealthPerc >=90 and math.huge or 0) --firestarter.remains
    end
    if talents[classtable.SunKingsBlessing] and (talents[classtable.Firestarter] and targethealthPerc >= 90) and not buff[classtable.FuryoftheSunKingBuff].up then
        one = ( buff[classtable.SunKingsBlessingBuff].maxStacks - buff[classtable.SunKingsBlessingBuff].count ) * ( 3 * gcd )
    end
    if MaxDps:CheckEquipped('GladiatorsBadge') and cooldown[classtable.GladiatorsBadge].remains - 20 <cooldown[classtable.combustion].duration then
        one = cooldown[classtable.GladiatorsBadge].remains
    end
    one = buff[classtable.CombustionBuff].remains
    if (targets >1) and 1 >= 3 and (targets>1 and MaxDps:MaxAddDuration() or 0) >15 then
        one = math.huge
    end
    if combustion_ready_time + cooldown[classtable.Combustion].duration * ( 1 - ( 0.4 + 0.2 * (talents[classtable.Firestarter] and talents[classtable.Firestarter] or 0) ) * (talents[classtable.Kindling] and talents[classtable.Kindling] or 0) ) <= cooldown[classtable.combustion].duration or cooldown[classtable.combustion].duration >ttd - 20 then
        one = combustion_ready_time
    end
end
function Fire:firestarter_fire_blasts()
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not fire_blast_pooling and not buff[classtable.HotStreakBuff].up and ( gcd >gcd or (C_Spell and C_Spell.IsCurrentSpell(classtable.Pyroblast)) ) and buff[classtable.HeatingUpBuff].up and ( cooldown[classtable.ShiftingPower].ready or cooldown[classtable.FireBlast].charges >1 or buff[classtable.FeeltheBurnBuff].remains <2 * gcd )) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not fire_blast_pooling and buff[classtable.HeatingUpBuff].count + 1 and ( talents[classtable.FeeltheBurn] and buff[classtable.FeeltheBurnBuff].remains <gcd or cooldown[classtable.ShiftingPower].ready ) and timeInCombat >0) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
end
function Fire:standard_rotation()
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (targets >= hot_streak_flamestrike and ( buff[classtable.HotStreakBuff].up or buff[classtable.HyperthermiaBuff].up )) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (buff[classtable.HotStreakBuff].up and not buff[classtable.FrostfireEmpowermentBuff].up and not buff[classtable.HyperthermiaBuff].up and not cooldown[classtable.ShiftingPower].ready and cooldown[classtable.PhoenixFlames].charges <1 and not (targethealthPerc <=30) and not (MaxDps.spellHistory[1] == classtable.Fireball)) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (( buff[classtable.HyperthermiaBuff].up or buff[classtable.HotStreakBuff].up and ( buff[classtable.HotStreakBuff].remains <2 ) or buff[classtable.HotStreakBuff].up and ( 1 or (talents[classtable.Firestarter] and targethealthPerc >= 90) or talents[classtable.CalloftheSunKing] and cooldown[classtable.PhoenixFlames].charges ) or buff[classtable.HotStreakBuff].up and (targethealthPerc <=30) )) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (targets >= skb_flamestrike and buff[classtable.FuryoftheSunKingBuff].up and buff[classtable.FuryoftheSunKingBuff].remains == 0) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (buff[classtable.ImprovedScorch].up and debuff[classtable.ImprovedScorchDeBuff].remains <( classtable and classtable.Pyroblast and GetSpellInfo(classtable.Pyroblast).castTime / 1000 ) + 5 * gcd and buff[classtable.FuryoftheSunKingBuff].up and not (classtable and classtable.Scorch and GetSpellCooldown(classtable.Scorch).duration >=5 )) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.FuryoftheSunKingBuff].up and buff[classtable.FuryoftheSunKingBuff].remains == 0) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not (talents[classtable.Firestarter] and targethealthPerc >= 90) and ( not fire_blast_pooling or talents[classtable.SpontaneousCombustion] ) and not buff[classtable.FuryoftheSunKingBuff].up and ( ( ( (C_Spell and C_Spell.IsCurrentSpell(classtable.Fireball)) and ( castTime() <0.5 or not talents[classtable.Hyperthermia] ) or (C_Spell and C_Spell.IsCurrentSpell(classtable.Pyroblast)) and ( castTime() <0.5 ) ) and buff[classtable.HeatingUpBuff].up ) or ( (targethealthPerc <=30) and ( not buff[classtable.ImprovedScorch].up or debuff[classtable.ImprovedScorchDeBuff].count == debuff[classtable.ImprovedScorchDeBuff].maxStacks or cooldown[classtable.FireBlast].fullRecharge <3 ) and ( buff[classtable.HeatingUpBuff].up and not (C_Spell and C_Spell.IsCurrentSpell(classtable.Scorch)) or not buff[classtable.HotStreakBuff].up and not buff[classtable.HeatingUpBuff].up and (C_Spell and C_Spell.IsCurrentSpell(classtable.Scorch)) and not 1 ) ) )) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not (talents[classtable.Firestarter] and targethealthPerc >= 90) and ( not fire_blast_pooling or talents[classtable.SpontaneousCombustion] ) and not buff[classtable.FuryoftheSunKingBuff].up and ( buff[classtable.HeatingUpBuff].up and 1 <1 and ( (MaxDps.spellHistory[1] == classtable.PhoenixFlames) or (MaxDps.spellHistory[1] == classtable.Scorch) ) ) or ( ( ( MaxDps:Bloodlust() and cooldown[classtable.FireBlast].charges >1.5 ) or cooldown[classtable.FireBlast].charges >2.5 or buff[classtable.FeeltheBurnBuff].remains <0.5 or cooldown[classtable.FireBlast].fullRecharge * 1 - ( 0.5 * cooldown[classtable.ShiftingPower].ready ) <buff[classtable.HyperthermiaBuff].duration ) and buff[classtable.HeatingUpBuff].up )) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (buff[classtable.ImprovedScorch].up and debuff[classtable.ImprovedScorchDeBuff].remains <gcd) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and (buff[classtable.FrostfireEmpowermentBuff].up and not buff[classtable.HotStreakBuff].up and not buff[classtable.ExcessFrostBuff].up) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (buff[classtable.HeatShimmerBuff].up and ( talents[classtable.Scald] or talents[classtable.ImprovedScorch] ) and targets <combustion_flamestrike) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and (not buff[classtable.HotStreakBuff].up and ( ( not (MaxDps.spellHistory[1] == classtable.Fireball) or ( not buff[classtable.HeatingUpBuff].up and not buff[classtable.HotStreakBuff].up ) ) ) or ( 1 <2 and buff[classtable.FlamesFuryBuff].up )) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    Fire:active_talents()
    if (MaxDps:CheckSpellUsable(classtable.DragonsBreath, 'DragonsBreath')) and (targets >1 and talents[classtable.AlexstraszasFury]) and cooldown[classtable.DragonsBreath].ready then
        if not setSpell then setSpell = classtable.DragonsBreath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (( (targethealthPerc <=30) or buff[classtable.HeatShimmerBuff].up )) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (targets >= arcane_explosion and ManaPerc >= arcane_explosion_mana) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (targets >= hard_cast_flamestrike) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Counterspell, false)
end

function Fire:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.PhoenixFlames, 'PhoenixFlames')) and (timeInCombat <0.5) and cooldown[classtable.PhoenixFlames].ready then
        if not setSpell then setSpell = classtable.PhoenixFlames end
    end
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and (not buff[classtable.CombustionBuff].up) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    Fire:combustion_timing()
    shifting_power_before_combustion = (cooldown[classtable.combustion].duration >cooldown[classtable.ShiftingPower].remains and 1 or 0)
    --item_cutoff_active = ( cooldown[classtable.combustion].duration <on_use_cutoff or buff[classtable.CombustionBuff].remains >skb_duration and not cooldown[classtable.ItemCd1141].ready==false ) and ( ( trinket.1.has_cooldown and MaxDps:CheckTrinketCooldown('1') <on_use_cutoff ) + ( trinket.2.has_cooldown and MaxDps:CheckTrinketCooldown('2') <on_use_cutoff ) >1 )
    one = not buff[classtable.CombustionBuff].up and cooldown[classtable.FireBlast].charges + ( cooldown[classtable.combustion].duration + 12 * shifting_power_before_combustion ) % cooldown[classtable.FireBlast].duration - 1 <cooldown[classtable.FireBlast].maxCharges + overpool_fire_blasts % cooldown[classtable.FireBlast].duration - ( buff[classtable.CombustionBuff].duration % cooldown[classtable.FireBlast].duration ) % 1 and cooldown[classtable.combustion].duration <ttd
    local combustion_precast_time = ( classtable and classtable.Fireball and GetSpellInfo(classtable.Fireball).castTime / 1000 ) *(targets<combustion_flamestrike and 1 or 0)+( classtable and classtable.Flamestrike and GetSpellInfo(classtable.Flamestrike).castTime / 1000 )*(targets>=combustion_flamestrike and 1 or 0)-combustion_cast_remains
    if (cooldown[classtable.combustion].duration <= 0 or buff[classtable.CombustionBuff].up or cooldown[classtable.combustion].duration <combustion_precast_time and cooldown[classtable.Combustion].remains <combustion_precast_time) then
        Fire:combustion_phase()
    end
    if not fire_blast_pooling and talents[classtable.SunKingsBlessing] then
        one = (targethealthPerc <=30) and cooldown[classtable.FireBlast].fullRecharge >3 * gcd
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (not buff[classtable.CombustionBuff].up and ( not buff[classtable.ImprovedScorch].up or debuff[classtable.ImprovedScorchDeBuff].remains >( classtable and classtable.ShiftingPower and GetSpellInfo(classtable.ShiftingPower).castTime /1000 ) + ( classtable and classtable.Scorch and GetSpellInfo(classtable.Scorch).castTime / 1000 ) and not buff[classtable.FuryoftheSunKingBuff].up ) and not buff[classtable.HotStreakBuff].up and not buff[classtable.HyperthermiaBuff].up and ( cooldown[classtable.PhoenixFlames].charges <= 1 or cooldown[classtable.Combustion].remains <20 )) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if not talents[classtable.SunKingsBlessing] then
        phoenix_pooling = ( cooldown[classtable.combustion].duration + buff[classtable.CombustionBuff].duration - 5 <cooldown[classtable.PhoenixFlames].fullRecharge + cooldown[classtable.PhoenixFlames].duration - 12 * shifting_power_before_combustion and cooldown[classtable.combustion].duration <ttd or talents[classtable.SunKingsBlessing] ) and not talents[classtable.AlexstraszasFury]
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and (not fire_blast_pooling and cooldown[classtable.combustion].duration >0 and targets >= hard_cast_flamestrike and not (talents[classtable.Firestarter] and targethealthPerc >= 90) and not buff[classtable.HotStreakBuff].up and ( buff[classtable.HeatingUpBuff].up or cooldown[classtable.FireBlast].charges >= 2 )) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (not buff[classtable.CombustionBuff].up and (talents[classtable.Firestarter] and targethealthPerc >= 90) and cooldown[classtable.combustion].duration >0) then
        Fire:firestarter_fire_blasts()
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and ((C_Spell and C_Spell.IsCurrentSpell(classtable.ShiftingPower)) and ( cooldown[classtable.FireBlast].fullRecharge <3.5 or talents[classtable.SunKingsBlessing] and buff[classtable.HeatingUpBuff].up )) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (cooldown[classtable.combustion].duration >0 and not buff[classtable.CombustionBuff].up) then
        Fire:standard_rotation()
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and (not (targethealthPerc <=30)) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and (not buff[classtable.CombustionBuff].up) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
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
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    ArcaneCharges = UnitPower('player', ArcaneChargesPT)
    ManaPerc = (Mana / ManaMax) * 100
    classtable.Fireball = talents[classtable.FrostfireBolt] and classtable.FrostfireBolt or 133
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.CombustionBuff = 190319
    classtable.SunKingsBlessingBuff = 0
    classtable.HotStreakBuff = 48108
    classtable.FeeltheBurnBuff = 0
    classtable.FuryoftheSunKingBuff = 0
    classtable.FlameAccelerantBuff = 0
    classtable.FrostfireEmpowermentBuff = 0
    classtable.HeatingUpBuff = 48107
    classtable.FlamesFuryBuff = 0
    classtable.ImprovedScorchDeBuff = 383608
    classtable.HyperthermiaBuff = 383874
    classtable.ExcessFrostBuff = 0
    classtable.HeatShimmerBuff = 0
    classtable.bloodlust = 0
    setSpell = nil
    ClearCDs()

    Fire:precombat()

    Fire:callaction()
    if setSpell then return setSpell end
end
