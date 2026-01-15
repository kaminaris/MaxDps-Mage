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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local ArcaneCharges
local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaGemCharges

local Frost = {}

local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.IcyVeins, false)
    MaxDps:GlowCooldown(classtable.SummonWaterElemental, false)
    MaxDps:GlowCooldown(classtable.ColdSnap, false)
    MaxDps:GlowCooldown(classtable.FrostNova, false)
end

function Frost:Single()
    if (MaxDps:CheckSpellUsable(classtable.IcyVeins, 'IcyVeins')) and cooldown[classtable.IcyVeins].ready then
        --if not setSpell then setSpell = classtable.IcyVeins end
        MaxDps:GlowCooldown(classtable.IcyVeins, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonWaterElemental, 'SummonWaterElemental')) and cooldown[classtable.SummonWaterElemental].ready then
        --if not setSpell then setSpell = classtable.SummonWaterElemental end
        MaxDps:GlowCooldown(classtable.SummonWaterElemental, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ColdSnap, 'ColdSnap')) and cooldown[classtable.ColdSnap].ready then
        --if not setSpell then setSpell = classtable.IcyVeins end
        MaxDps:GlowCooldown(classtable.ColdSnap, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostNova, 'FrostNova')) and freezable() and cooldown[classtable.FrostNova].ready then
        --if not setSpell then setSpell = classtable.FrostNova end
        MaxDps:GlowCooldown(classtable.FrostNova, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (MaxDps:FindADAuraData(classtable.Frozen).up) and freezable() and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
end

function Frost:AoE()
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (MaxDps:FindADAuraData(classtable.Flamestrike).up or MaxDps:FindADAuraData(classtable.Flamestrike).refreshable) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (( LibRangeCheck and LibRangeCheck:GetRange ( 'target', true ) or 0 ) <10) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'Arcane Explosion')) and (( LibRangeCheck and LibRangeCheck:GetRange ( 'target', true ) or 0 ) <10) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
end

function Frost:callaction()
    if targets > 1 then
        Frost:AoE()
    end
    if targets <= 1 then
        Frost:Single()
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

    classtable.Frostbolt = 10181
    classtable.Flamestrike = 10216
    classtable.ConeofCold = 10161
    classtable.ArcaneExplosion = 10202
    classtable.Freeze = 33395
    classtable.FrostNova = 27088
    classtable.SummonWaterElemental = 10205
    classtable.IceLance = 30455
    classtable.IceNova = 157997
    classtable.Frozen = 33390
    classtable.IcyVeins = 12472
    classtable.ColdSnap = 11958

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Frost:callaction()
    if setSpell then return setSpell end
end
