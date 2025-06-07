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

local Arcane = {}

local function ClearCDs()
end

function Arcane:Single()
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (ManaPerc <= 35) and cooldown[classtable.Evocation].ready then
        if not setSpell then setSpell = classtable.Evocation end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePower, 'Arcane Power')) and cooldown[classtable.ArcanePower].ready then
        if not setSpell then setSpell = classtable.ArcanePower end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'Presence of Mind')) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'Fire Blast')) and (talents[classtable.ImprovedArcaneMissiles]) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'Arcane Missiles')) and (talents[classtable.ImprovedArcaneMissiles]) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and (not talents[classtable.ImprovedArcaneMissiles]) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
end

function Arcane:AoE()
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (ManaPerc <= 35) and cooldown[classtable.Evocation].ready then
        if not setSpell then setSpell = classtable.Evocation end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePower, 'Arcane Power'))  and cooldown[classtable.ArcanePower].ready then
        if not setSpell then setSpell = classtable.ArcanePower end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'Presence of Mind')) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Flamestrike, 'Flamestrike')) and (MaxDps:FindADAuraData(classtable.Flamestrike).up or MaxDps:FindADAuraData(classtable.Flamestrike).refreshable) and cooldown[classtable.Flamestrike].ready then
        if not setSpell then setSpell = classtable.Flamestrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConeofCold, 'ConeofCold')) and (not talents[classtable.ImprovedArcaneMissiles] and ( LibRangeCheck and LibRangeCheck:GetRange ( 'target', true ) or 0 ) <10) and cooldown[classtable.ConeofCold].ready then
        if not setSpell then setSpell = classtable.ConeofCold end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneExplosion, 'Arcane Explosion')) and (( LibRangeCheck and LibRangeCheck:GetRange ( 'target', true ) or 0 ) <10) and cooldown[classtable.ArcaneExplosion].ready then
        if not setSpell then setSpell = classtable.ArcaneExplosion end
    end
end

function Arcane:callaction()
    if targets > 1 then
        Arcane:AoE()
    end
    if targets <= 1 then
        Arcane:Single()
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

    classtable.ArcanePower = 12042
    classtable.PresenceofMind = 12043
    classtable.Frostbolt = 10181
    classtable.ArcaneExplosion = 10202
    classtable.Blizzard = 10187
    classtable.ImprovedArcaneMissiles = 16770
    classtable.ConeofCold = 10161
    classtable.Flamestrike = 10216
    classtable.Evocation = 12051

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Arcane:callaction()
    if setSpell then return setSpell end
end
