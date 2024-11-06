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

local Arcane = {}

local aoe_target_count
local opener
local steroid_trinket_equipped
local transmitter_double_on_use
local treacherous_transmitter_precombat_cast


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
    opener = ( cooldown[classtable.TouchoftheMagi].ready ) and ( cooldown[classtable.ArcaneSurge].ready or (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.ArcaneSurge] and GetTime() - MaxDps.spellHistoryTime[classtable.ArcaneSurge].last_used or 0) <5 or cooldown[classtable.ArcaneSurge].remains >15 ) and ( cooldown[classtable.Evocation].ready or (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.Evocation] and GetTime() - MaxDps.spellHistoryTime[classtable.Evocation].last_used or 0) <5 or cooldown[classtable.Evocation].remains >15 )
    transmitter_double_on_use = ( MaxDps:CheckEquipped('GladiatorsBadge') or MaxDps:CheckEquipped('SignetofthePriory') or MaxDps:CheckEquipped('HighSpeakersAccretion') or MaxDps:CheckEquipped('SpymastersWeb') or MaxDps:CheckEquipped('ImperfectAscendancySerum') or MaxDps:CheckEquipped('QuickwickCandlestick') ) and MaxDps:CheckEquipped('TreacherousTransmitter')
    treacherous_transmitter_precombat_cast = 11
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MirrorImage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (not talents[classtable.Evocation]) and cooldown[classtable.ArcaneBlast].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (talents[classtable.Evocation]) and cooldown[classtable.Evocation].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Evocation end
    end
end
function Arcane:cd_opener()
    if (MaxDps:CheckSpellUsable(classtable.TouchoftheMagi, 'TouchoftheMagi')) and (( buff[classtable.ArcaneSurgeBuff].up or cooldown[classtable.ArcaneSurge].remains >30 ) or ( ArcaneCharges <4 )) and cooldown[classtable.TouchoftheMagi].ready then
        if not setSpell then setSpell = classtable.TouchoftheMagi end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.PresenceofMindBuff].up) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (talents[classtable.HighVoltage]) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (cooldown[classtable.ArcaneSurge].remains <( gcd * 3 ) and cooldown[classtable.TouchoftheMagi].remains <( gcd * 5 )) and cooldown[classtable.Evocation].ready then
        if not setSpell then setSpell = classtable.Evocation end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and ((MaxDps.spellHistory[1] == classtable.Evocation) or (MaxDps.spellHistory[1] == classtable.ArcaneOrb)) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneSurge, 'ArcaneSurge')) and (cooldown[classtable.TouchoftheMagi].remains <( 2 + ( gcd * ( ArcaneCharges == 4 and 1 or 0 ) ) )) and cooldown[classtable.ArcaneSurge].ready then
        if not setSpell then setSpell = classtable.ArcaneSurge end
    end
end
function Arcane:spellslinger()
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( ( not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.TouchoftheMagi].remains >( 12 + 6 * gcd ) ) or ( (MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and talents[classtable.ShiftingShards] and ( buff[classtable.ArcaneSurgeBuff].up or debuff[classtable.TouchoftheMagiDeBuff].up or cooldown[classtable.Evocation].remains <20 ) ) ) and ttd >10) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.NetherPrecisionBuff].up and targets <aoe_target_count and not talents[classtable.UnerringProficiency]) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Supernova, 'Supernova')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.UnerringProficiencyBuff].count == 30) and cooldown[classtable.Supernova].ready then
        if not setSpell then setSpell = classtable.Supernova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (( ( buff[classtable.LeydrinkerBuff].up ) and not (MaxDps.spellHistory[1] == classtable.ArcaneBlast) and buff[classtable.NetherPrecisionBuff].up )) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( cooldown[classtable.TouchoftheMagi].ready ) or ( buff[classtable.ArcaneTempoBuff].up and buff[classtable.ArcaneTempoBuff].remains <gcd ) or ( ( buff[classtable.AethervisionBuff].count == 2 or buff[classtable.IntuitionBuff].up ) and ( buff[classtable.NetherPrecisionBuff].up or not buff[classtable.ClearcastingBuff].up ) ) or ( cooldown[classtable.ArcaneOrb].charges >0 and ArcaneCharges == 4 and buff[classtable.ClearcastingBuff].count == 0 and not buff[classtable.NetherPrecisionBuff].up and talents[classtable.OrbBarrage] )) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( ( ArcaneCharges == 4 and buff[classtable.NetherPrecisionBuff].up and targets >1 and ( cooldown[classtable.ArcaneOrb].remains <gcd or cooldown[classtable.ArcaneOrb].charges >0 ) ) or ( buff[classtable.AetherAttunementBuff].up and talents[classtable.HighVoltage] and buff[classtable.ClearcastingBuff].up and ArcaneCharges >1 and ( ( targetHP <35 and targets == 2 ) or targets >2 ) ) ) and talents[classtable.ArcingCleave]) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (( buff[classtable.ClearcastingBuff].up and not buff[classtable.NetherPrecisionBuff].up )) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <4) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (( talents[classtable.Reverberate] or ArcaneCharges <1 ) and targets >= 4) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
end
function Arcane:spellslinger_aoe()
    if (MaxDps:CheckSpellUsable(classtable.Supernova, 'Supernova')) and (buff[classtable.UnerringProficiencyBuff].count == 30) and cooldown[classtable.Supernova].ready then
        if not setSpell then setSpell = classtable.Supernova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( ( not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.Evocation].remains >15 and cooldown[classtable.TouchoftheMagi].remains >10 ) and ( cooldown[classtable.ArcaneOrb].ready==false and cooldown[classtable.ArcaneOrb].charges == 0 ) and ttd >10 ) or ( (MaxDps.spellHistory[1] == classtable.ArcaneBarrage) and ( buff[classtable.ArcaneSurgeBuff].up or debuff[classtable.TouchoftheMagiDeBuff].up or cooldown[classtable.Evocation].remains <20 ) and talents[classtable.ShiftingShards] )) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <3) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (( ( buff[classtable.LeydrinkerBuff].up ) and not (MaxDps.spellHistory[1] == classtable.ArcaneBlast) )) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (buff[classtable.AetherAttunementBuff].up and talents[classtable.HighVoltage] and buff[classtable.ClearcastingBuff].up and ArcaneCharges >1) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ( ( talents[classtable.HighVoltage] and ArcaneCharges <4 ) or not buff[classtable.NetherPrecisionBuff].up )) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (ArcaneCharges == 3 or ArcaneCharges == 2) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ArcaneCharges == 4) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (( talents[classtable.Reverberate] or ArcaneCharges <1 )) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
end
function Arcane:sunfury()
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( ( not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.Evocation].remains >15 and cooldown[classtable.TouchoftheMagi].remains >10 ) and ttd >10 ) and not buff[classtable.ArcaneSoulBuff].up) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (debuff[classtable.TouchoftheMagiDeBuff].remains <= gcd and buff[classtable.NetherPrecisionBuff].up and targets <4) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( ArcaneCharges == 4 and not buff[classtable.BurdenofPowerBuff].up and buff[classtable.NetherPrecisionBuff].up and targets >2 and ( ( talents[classtable.ArcaneBombardment] and targetHP <35 ) or targets >4 ) and talents[classtable.ArcingCleave] and ( ( talents[classtable.HighVoltage] and buff[classtable.ClearcastingBuff].up ) or ( cooldown[classtable.ArcaneOrb].remains <gcd or cooldown[classtable.ArcaneOrb].charges >0 ) ) ) or ( buff[classtable.AetherAttunementBuff].up and talents[classtable.HighVoltage] and buff[classtable.ClearcastingBuff].up and ArcaneCharges >1 and targets >2 and ( targetHP <35 or not talents[classtable.ArcaneBombardment] or targets >4 ) ) or ( targets >2 and ( buff[classtable.AethervisionBuff].count == 2 or buff[classtable.GloriousIncandescenceBuff].up or buff[classtable.IntuitionBuff].up ) and ( buff[classtable.NetherPrecisionBuff].up or ( targetHP <35 and talents[classtable.ArcaneBombardment] and not buff[classtable.ClearcastingBuff].up ) ) )) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <2 and not buff[classtable.ArcaneSoulBuff].up and ( not talents[classtable.HighVoltage] or not buff[classtable.ClearcastingBuff].up )) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (not buff[classtable.NetherPrecisionBuff].up and buff[classtable.ClearcastingBuff].up and ( buff[classtable.ArcaneSoulBuff].up and buff[classtable.ArcaneSoulBuff].remains >gcd * ( 4 - buff[classtable.ClearcastingBuff].count ) )) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( buff[classtable.IntuitionBuff].up or buff[classtable.AethervisionBuff].count == 2 or buff[classtable.GloriousIncandescenceBuff].up ) and ( ( targetHP <35 and talents[classtable.ArcaneBombardment] ) or ( ManaPerc <70 and talents[classtable.Enlightened] and not buff[classtable.ArcaneSurgeBuff].up and targets <3 ) or buff[classtable.GloriousIncandescenceBuff].up ) and ( buff[classtable.NetherPrecisionBuff].up or not buff[classtable.ClearcastingBuff].up ) and cooldown[classtable.TouchoftheMagi].remains >6 or ( buff[classtable.ArcaneSoulBuff].up and ( ( buff[classtable.ClearcastingBuff].count <3 ) or buff[classtable.ArcaneSoulBuff].remains <gcd ) ) or ( ArcaneCharges == 4 and cooldown[classtable.TouchoftheMagi].ready )) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ( ( not buff[classtable.NetherPrecisionBuff].up or buff[classtable.ClearcastingBuff].count == 3 or ( talents[classtable.HighVoltage] and ArcaneCharges <3 ) ) )) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (( ArcaneCharges == 3 or ArcaneCharges == 2 ) and targets >= 3) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (( talents[classtable.Reverberate] or ArcaneCharges <1 ) and targets >= 4) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
end
function Arcane:sunfury_aoe()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( buff[classtable.ArcaneSoulBuff].up and ( ( buff[classtable.ClearcastingBuff].count <3 ) or buff[classtable.ArcaneSoulBuff].remains <gcd ) )) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ArcaneSoulBuff].up) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( not buff[classtable.ArcaneSurgeBuff].up and not buff[classtable.SiphonStormBuff].up and not debuff[classtable.TouchoftheMagiDeBuff].up and cooldown[classtable.Evocation].remains >15 and cooldown[classtable.TouchoftheMagi].remains >15 ) and ( cooldown[classtable.ArcaneOrb].ready==false and cooldown[classtable.ArcaneOrb].charges == 0 ) and ttd >10) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneOrb, 'ArcaneOrb')) and (ArcaneCharges <2 and ( not talents[classtable.HighVoltage] or not buff[classtable.ClearcastingBuff].up )) and cooldown[classtable.ArcaneOrb].ready then
        if not setSpell then setSpell = classtable.ArcaneOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (( ( buff[classtable.BurdenofPowerBuff].up or buff[classtable.LeydrinkerBuff].up ) and not (MaxDps.spellHistory[1] == classtable.ArcaneBlast) )) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (( ArcaneCharges == 4 or buff[classtable.GloriousIncandescenceBuff].up or buff[classtable.AethervisionBuff].count == 2 or buff[classtable.IntuitionBuff].up ) and ( buff[classtable.NetherPrecisionBuff].up or not buff[classtable.ClearcastingBuff].up )) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (buff[classtable.ClearcastingBuff].up and ( buff[classtable.AetherAttunementBuff].up or talents[classtable.ArcaneHarmony] )) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (ArcaneCharges == 3 or ArcaneCharges == 2) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (talents[classtable.Reverberate] or ArcaneCharges <1) and cooldown[classtable.ArcaneExplosion].ready then
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
    MaxDps:GlowCooldown(classtable.Counterspell, false)
end

function Arcane:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.Spellsteal, 'Spellsteal')) and cooldown[classtable.Spellsteal].ready then
    --    if not setSpell then setSpell = classtable.Spellsteal end
    --end
    if debuff[classtable.TouchoftheMagiDeBuff].up and opener then
        opener = false
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ttd <2) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (opener) then
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
    classtable.ArcaneIntellectBuff = 1459
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ArcaneSurgeBuff = 365362
    classtable.PresenceofMindBuff = 205025
    classtable.SiphonStormBuff = 384267
    classtable.TouchoftheMagiDeBuff = 210824
    classtable.NetherPrecisionBuff = 383783
    classtable.UnerringProficiencyBuff = 444981
    classtable.MagisSparkArcaneBlastDeBuff = 0
    classtable.LeydrinkerBuff = 0
    classtable.ArcaneTempoBuff = 383997
    classtable.AethervisionBuff = 467634
    classtable.IntuitionBuff = 0
    classtable.ClearcastingBuff = 263725
    classtable.AetherAttunementBuff = 453601
    classtable.ArcaneSoulBuff = 451038
    classtable.BurdenofPowerBuff = 451049
    classtable.GloriousIncandescenceBuff = 451073
    setSpell = nil
    ClearCDs()

    Arcane:precombat()

    Arcane:callaction()
    if setSpell then return setSpell end
end
