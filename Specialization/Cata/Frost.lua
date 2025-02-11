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



local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end




local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end




local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Counterspell, false)
end

function Frost:callaction()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBrilliance, 'ArcaneBrilliance')) and cooldown[classtable.ArcaneBrilliance].ready then
        if not setSpell then setSpell = classtable.ArcaneBrilliance end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoltenArmor, 'MoltenArmor')) and cooldown[classtable.MoltenArmor].ready then
        if not setSpell then setSpell = classtable.MoltenArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.WaterElemental, 'WaterElemental')) and cooldown[classtable.WaterElemental].ready then
        if not setSpell then setSpell = classtable.WaterElemental end
    end
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.ConjureManaGem, 'ConjureManaGem')) and (ManaGemCharges <3) and cooldown[classtable.ConjureManaGem].ready then
        if not setSpell then setSpell = classtable.ConjureManaGem end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (not UnitAffectingCombat('player')) and cooldown[classtable.VolcanicPotion].ready then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (MaxDps:Bloodlust(1) or buff[classtable.IcyVeinsBuff].up or ttd <= 40) and cooldown[classtable.VolcanicPotion].ready then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (ManaPerc <40 and ( buff[classtable.IcyVeinsBuff].up or MaxDps:Bloodlust(1) )) and cooldown[classtable.Evocation].ready then
        if not setSpell then setSpell = classtable.Evocation end
    end
    if (MaxDps:CheckSpellUsable(classtable.ManaGem, 'ManaGem')) and (ManaDeficit >12500) and cooldown[classtable.ManaGem].ready then
        if not setSpell then setSpell = classtable.ManaGem end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColdSnap, 'ColdSnap')) and (cooldown[classtable.DeepFreeze].remains >15 and cooldown[classtable.FrostfireOrb].remains >30 and cooldown[classtable.IcyVeins].remains >30) and cooldown[classtable.ColdSnap].ready then
        if not setSpell then setSpell = classtable.ColdSnap end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireOrb, 'FrostfireOrb')) and (ttd >= 12 and not debuff[classtable.FrostfireOrbDeBuff].up) and cooldown[classtable.FrostfireOrb].ready then
        if not setSpell then setSpell = classtable.FrostfireOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and (ttd >= 25) and cooldown[classtable.MirrorImage].ready then
        if not setSpell then setSpell = classtable.MirrorImage end
    end
    if (MaxDps:CheckSpellUsable(classtable.IcyVeins, 'IcyVeins')) and (not buff[classtable.IcyVeinsBuff].up and MaxDps:Bloodlust(1) and ( buff[classtable.Tier132pcBuff].count >7 or cooldown[classtable.ColdSnap].remains <22 )) and cooldown[classtable.IcyVeins].ready then
        if not setSpell then setSpell = classtable.IcyVeins end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeepFreeze, 'DeepFreeze')) and (buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.DeepFreeze].ready then
        if not setSpell then setSpell = classtable.DeepFreeze end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostfireBolt, 'FrostfireBolt')) and (buff[classtable.BrainFreezeBuff].up and buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.FrostfireBolt].ready then
        if not setSpell then setSpell = classtable.FrostfireBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].count >1) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and cooldown[classtable.Freeze].remains <gcd) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        if not setSpell then setSpell = classtable.Frostbolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
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
    ManaGemCharges = C_Item.GetItemCount(5500, true)
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.IcyVeinsBuff = 12472
    classtable.FingersofFrostBuff = 44544
    classtable.BrainFreezeBuff = 57761
    classtable.ArcaneBrilliance = 1459
    classtable.MoltenArmor = 30482
    classtable.WaterElemental = 1
    classtable.Counterspell = 2139
    classtable.ConjureManaGem = 759
    classtable.VolcanicPotion = 58091
    classtable.Evocation = 12051
    classtable.ManaGem = 3
    classtable.ColdSnap = 11958
    classtable.MirrorImage = 55342
    classtable.IcyVeins = 12472
    classtable.DeepFreeze = 44572
    classtable.FrostfireBolt = 44614
    classtable.IceLance = 30455
    classtable.Frostbolt = 116
    classtable.FireBlast = 2136
    classtable.FrostfireOrb = 84726

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
