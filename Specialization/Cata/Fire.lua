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

local Fire = {}



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

function Fire:callaction()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBrilliance, 'ArcaneBrilliance')) and not buff[classtable.ArcaneBrilliance].up and cooldown[classtable.ArcaneBrilliance].ready then
        if not setSpell then setSpell = classtable.ArcaneBrilliance end
    end
    --if (MaxDps:CheckSpellUsable(classtable.MoltenArmor, 'MoltenArmor')) and (not buff[classtable.MageArmorBuff].up and not buff[classtable.MoltenArmorBuff].up) and cooldown[classtable.MoltenArmor].ready then
    --    if not setSpell then setSpell = classtable.MoltenArmor end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.MoltenArmor, 'MoltenArmor')) and (ManaPerc >45 and buff[classtable.MageArmorBuff].up) and cooldown[classtable.MoltenArmor].ready then
    --    if not setSpell then setSpell = classtable.MoltenArmor end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.ConjureManaGem, 'ConjureManaGem')) and (mana_gem_charges <3) and cooldown[classtable.ConjureManaGem].ready then
    --    if not setSpell then setSpell = classtable.ConjureManaGem end
    --end
    if (MaxDps:CheckSpellUsable(classtable.ManaGem, 'ManaGem')) and (ManaDeficit >12500) and cooldown[classtable.ManaGem].ready then
        if not setSpell then setSpell = classtable.ManaGem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and cooldown[classtable.Scorch].ready then
        if not setSpell then setSpell = classtable.Scorch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and (debuff[classtable.LivingBombDeBuff].up and debuff[classtable.IgniteDeBuff].up and debuff[classtable.PyroblastDeBuff].up and debuff[classtable.IgniteDeBuff].tick_dmg >10000) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and (ttd >= 25) and cooldown[classtable.MirrorImage].ready then
        if not setSpell then setSpell = classtable.MirrorImage end
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingBomb, 'LivingBomb')) and (not debuff[classtable.LivingBombDeBuff].up) and cooldown[classtable.LivingBomb].ready then
        if not setSpell then setSpell = classtable.LivingBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.PyroblastHs, 'PyroblastHs')) and (buff[classtable.HotStreakBuff].up) and cooldown[classtable.PyroblastHs].ready then
        if not setSpell then setSpell = classtable.PyroblastHs end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameOrb, 'FlameOrb')) and (ttd >= 12) and cooldown[classtable.FlameOrb].ready then
        if not setSpell then setSpell = classtable.FlameOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.MageArmor, 'MageArmor')) and (ManaPerc <5 and not buff[classtable.MageArmorBuff].up) and cooldown[classtable.MageArmor].ready then
        if not setSpell then setSpell = classtable.MageArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.Scorch, 'Scorch')) and cooldown[classtable.Scorch].ready then
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.MageArmorBuff = 0
    classtable.MoltenArmorBuff = 0
    classtable.bloodlust = 0
    classtable.LivingBombDeBuff = 0
    classtable.IgniteDeBuff = 0
    classtable.PyroblastDeBuff = 0
    classtable.HotStreakBuff = 0
    setSpell = nil
    ClearCDs()

    Fire:callaction()
    if setSpell then return setSpell end
end
