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

local Frost = {}



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
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready then
        MaxDps:GlowCooldown(classtable.MirrorImage, cooldown[classtable.MirrorImage].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (targets >= 2 and talents[classtable.IceCaller] and not talents[classtable.FracturedFrost] or targets >= 3) and cooldown[classtable.Blizzard].ready then
    --    return classtable.Blizzard
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and (targets <= 2) and cooldown[classtable.Frostbolt].ready then
    --    return classtable.Frostbolt
    --end
end
function Frost:aoe()
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and ( (MaxDps.spellHistory[1] == classtable.CometStorm) or (MaxDps.spellHistory[1] == classtable.FrozenOrb) and not talents[classtable.CometStorm] )) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and (( not (MaxDps.spellHistory[1] == classtable.ConeofCold) or not talents[classtable.IsothermicCore] ) and ( not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or not freezable() )) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or not freezable()) and cooldown[classtable.Blizzard].ready then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and (buff[classtable.IcyVeinsBuff].up and ( buff[classtable.DeathsChillBuff].count <9 or buff[classtable.DeathsChillBuff].count == 9 and not (classtable and classtable.Frostbolt and GetSpellCooldown(classtable.Frostbolt).duration >=5 ) ) and buff[classtable.IcyVeinsBuff].remains >8 and talents[classtable.DeathsChill]) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) and ( not talents[classtable.ColdestSnap] or cooldown[classtable.ConeofCold].ready and cooldown[classtable.FrozenOrb].remains >25 or ( cooldown[classtable.ConeofCold].remains >10 and talents[classtable.FrostfireBolt] or cooldown[classtable.ConeofCold].remains >20 and not talents[classtable.FrostfireBolt] ) )) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Freeze, 'Freeze')) and (freezable() and not debuff[classtable.FrozenDeBuff].up and ( not talents[classtable.GlacialSpike] or (MaxDps.spellHistory[1] == classtable.GlacialSpike) )) and cooldown[classtable.Freeze].ready then
        if not setSpell then setSpell = classtable.Freeze end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and (freezable() and not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and ( (MaxDps.spellHistory[1] == classtable.GlacialSpike) )) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostNova, 'FrostNova')) and (freezable() and not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and ( (MaxDps.spellHistory[1] == classtable.GlacialSpike) and not (debuff[classtable.WintersChillDeBuff].up) )) and cooldown[classtable.FrostNova].ready then
        if not setSpell then setSpell = classtable.FrostNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (cooldown[classtable.CometStorm].remains >10) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and (buff[classtable.FrostfireEmpowermentBuff].up and not buff[classtable.ExcessFrostBuff].up and not buff[classtable.ExcessFireBuff].up) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and not (debuff[classtable.WintersChillDeBuff].up) and ( buff[classtable.BrainFreezeBuff].up and not talents[classtable.ExcessFrost] or buff[classtable.ExcessFrostBuff].up )) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up or debuff[classtable.FrozenDeBuff].remains >1 or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and not (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and (targets >= 4 and ( not talents[classtable.GlacialSpike] or not freezable() ) and not talents[classtable.FrostfireBolt]) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (((LibRangeCheck and LibRangeCheck:GetRange('target', true) or math.huge) <=10 or false) and not talents[classtable.ColdestSnap] and targets >= 7) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
        Frost:movement()
    end
end
function Frost:cds()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (timeInCombat <0.1 and targets <= 2) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IcyVeins, 'IcyVeins')) and cooldown[classtable.IcyVeins].ready then
		MaxDps:GlowCooldown(classtable.IcyVeins, cooldown[classtable.IcyVeins].ready)
    end
end
function Frost:ss_cleave()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and not debuff[classtable.WintersChillDeBuff].up and ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) )) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.IcyVeinsBuff].up and debuff[classtable.WintersChillDeBuff].count == 2) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and (not buff[classtable.IcyVeinsBuff].up and not buff[classtable.FreezingWindsBuff].up and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and ((debuff[classtable.WintersChillDeBuff].up) or buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold) or debuff[classtable.EmbeddedFrostSplinterDeBuff].maxStacks / count * 100 == 100) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].up == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and buff[classtable.IcyVeinsBuff].up) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
        Frost:movement()
    end
end
function Frost:cleave()
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold)) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and ( ( ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.FrostfireBolt) ) and buff[classtable.IciclesBuff].count >= 3 ) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) or ( buff[classtable.IciclesBuff].count >= 3 and buff[classtable.IciclesBuff].count <5 and cooldown[classtable.Flurry].charges == 2 ) )) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (talents[classtable.GlacialSpike] and not debuff[classtable.WintersChillDeBuff].up and buff[classtable.IciclesBuff].count == 4 and buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and ((debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and ( cooldown[classtable.Flurry].ready or (debuff[classtable.WintersChillDeBuff].up) )) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and (buff[classtable.FingersofFrostBuff].count <2 and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].ready==false )) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and cooldown[classtable.CometStorm].remains >10 and cooldown[classtable.FrozenOrb].remains >10 and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and targets >= 3) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (cooldown[classtable.FrozenOrb].remains >10 and ( not talents[classtable.CometStorm] or cooldown[classtable.CometStorm].remains >10 ) and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains >10 ) or cooldown[classtable.IcyVeins].remains <20) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and (targets >= 4) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
        Frost:movement()
    end
end
function Frost:movement()
    if (MaxDps:CheckSpellUsable(classtable.Blink, 'Blink')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.Blink].ready then
        if not setSpell then setSpell = classtable.Blink end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceFloes, 'IceFloes')) and (not buff[classtable.IceFloesBuff].up) and cooldown[classtable.IceFloes].ready then
        if not setSpell then setSpell = classtable.IceFloes end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or math.huge) <=10 and not talents[classtable.ColdestSnap] and targets >= 2) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (ManaPerc >30 and targets >= 2) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
end
function Frost:ss_st()
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and not debuff[classtable.WintersChillDeBuff].up and ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) )) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.IcyVeinsBuff].up and ( debuff[classtable.WintersChillDeBuff].count == 2 or debuff[classtable.WintersChillDeBuff].count == 1 and debuff[classtable.EmbeddedFrostSplinterDeBuff].maxStacks / count * 100 == 100 )) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and (not buff[classtable.IcyVeinsBuff].up and not buff[classtable.FreezingWindsBuff].up and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and ((debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold) or debuff[classtable.EmbeddedFrostSplinterDeBuff].maxStacks / count * 100 == 100) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (buff[classtable.IcyVeinsBuff].up and debuff[classtable.EmbeddedFrostSplinterDeBuff].maxStacks / count * 100 <100) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
        Frost:movement()
    end
end
function Frost:st()
    if (MaxDps:CheckSpellUsable(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold)) and cooldown[classtable.CometStorm].ready then
        if not setSpell then setSpell = classtable.CometStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and not debuff[classtable.WintersChillDeBuff].up and ( ( ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.FrostfireBolt) ) and buff[classtable.IciclesBuff].count >= 3 or ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.FrostfireBolt) ) and buff[classtable.BrainFreezeBuff].up ) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) or talents[classtable.GlacialSpike] and buff[classtable.IciclesBuff].count == 4 and not buff[classtable.FingersofFrostBuff].up ) or buff[classtable.ExcessFrostBuff].up and buff[classtable.FrostfireEmpowermentBuff].up) and cooldown[classtable.Flurry].ready then
        if not setSpell then setSpell = classtable.Flurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (talents[classtable.GlacialSpike] and not debuff[classtable.WintersChillDeBuff].up and buff[classtable.IciclesBuff].count == 4 and buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.RayofFrost, 'RayofFrost')) and ((debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        if not setSpell then setSpell = classtable.RayofFrost end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and ( cooldown[classtable.Flurry].ready or (debuff[classtable.WintersChillDeBuff].up) )) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrozenOrb, 'FrozenOrb')) and (buff[classtable.FingersofFrostBuff].count <2 and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].ready==false )) and cooldown[classtable.FrozenOrb].ready then
        if not setSpell then setSpell = classtable.FrozenOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and cooldown[classtable.CometStorm].remains >10 and cooldown[classtable.FrozenOrb].remains >10 and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and targets >= 3) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.Blizzard, 'Blizzard')) and (targets >= 2 and talents[classtable.IceCaller] and talents[classtable.FreezingRain] and ( not talents[classtable.SplinteringCold] and not talents[classtable.RayofFrost] or buff[classtable.FreezingRainBuff].up or targets >= 3 )) and cooldown[classtable.Blizzard].ready then
        if not setSpell then setSpell = classtable.Blizzard end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShiftingPower, 'ShiftingPower')) and (( not buff[classtable.IcyVeinsBuff].up or not talents[classtable.DeathsChill] ) and cooldown[classtable.FrozenOrb].remains >10 and ( not talents[classtable.CometStorm] or cooldown[classtable.CometStorm].remains >10 ) and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains >10 ) or cooldown[classtable.IcyVeins].remains <20) and cooldown[classtable.ShiftingPower].ready then
        if not setSpell then setSpell = classtable.ShiftingPower end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        if not setSpell then setSpell = classtable.GlacialSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceNova, 'IceNova')) and (targets >= 4) and cooldown[classtable.IceNova].ready then
        if not setSpell then setSpell = classtable.IceNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if GetUnitSpeed('player') > 0 then
        Frost:movement()
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Counterspell, false)
    MaxDps:GlowCooldown(classtable.MirrorImage, false)
end

function Frost:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Frost:cds()
    if (targets >= 7 and not (MaxDps.tier and MaxDps.tier[30].count >= 2) or targets >= 4 and talents[classtable.IceCaller]) then
        Frost:aoe()
    end
    if (targets >= 2 and targets <= 3 and talents[classtable.Splinterstorm]) then
        Frost:ss_cleave()
    end
    if (targets >= 2 and targets <= 3) then
        Frost:cleave()
    end
    if (talents[classtable.Splinterstorm]) then
        Frost:ss_st()
    end
    Frost:st()
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
    classtable.Freeze = 33395
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.IcyVeinsBuff = 12472
    classtable.DeathsChillBuff = 454371
    classtable.FrozenDeBuff = 122
    classtable.WintersChillDeBuff = 228358
    classtable.FrostfireEmpowermentBuff = 431177
    classtable.ExcessFrostBuff = 438611
    classtable.ExcessFireBuff = 438624
    classtable.BrainFreezeBuff = 190446
    classtable.FingersofFrostBuff = 44544
    classtable.FreezingWindsBuff = 382106
    classtable.EmbeddedFrostSplinterDeBuff = 0
    classtable.IciclesBuff = 205473
    classtable.IceFloesBuff = 108839
    classtable.FreezingRainBuff = 270232
    classtable.ArcaneIntellectBuff = 1459
    classtable.ConeofCold = 120
    classtable.ColdestSnap = 417493
    setSpell = nil
    ClearCDs()

    Frost:precombat()

    Frost:callaction()
    if setSpell then return setSpell end
end
