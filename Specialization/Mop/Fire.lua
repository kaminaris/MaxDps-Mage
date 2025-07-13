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

local ArcaneCharges
local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaGemCharges

local Fire = {}



local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


function Fire:precombat()
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBrilliance, 'ArcaneBrilliance')) and (not buff[classtable.ArcaneBrillianceBuff].up) and cooldown[classtable.ArcaneBrilliance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ArcaneBrilliance end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoltenArmor, 'MoltenArmor')) and (not buff[classtable.MoltenArmorBuff].up) and cooldown[classtable.MoltenArmor].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MoltenArmor end
    end
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Counterspell, false)
    MaxDps:GlowCooldown(classtable.MirrorImage, false)
end

function Fire:callaction()
    if (MaxDps:CheckSpellUsable(classtable.ConjureManaGem, 'ConjureManaGem')) and (ManaGemCharges <=1) and cooldown[classtable.ConjureManaGem].ready then
        if not setSpell then setSpell = classtable.ConjureManaGem end
    end
    --if (MaxDps:CheckSpellUsable(classtable.TimeWarp, 'TimeWarp')) and (targethealthPerc <25 or timeInCombat >5) and cooldown[classtable.TimeWarp].ready then
    --    if not setSpell then setSpell = classtable.TimeWarp end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and (ttd <12) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and ((MaxDps.tier and MaxDps.tier[14].count >= 4) and debuff[classtable.IgniteDeBuff].up and debuff[classtable.PyroblastDeBuff].up) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Combustion, 'Combustion')) and (not (MaxDps.tier and MaxDps.tier[14].count >= 4) and debuff[classtable.IgniteDeBuff].value >= 12000 and debuff[classtable.PyroblastDeBuff].up) and cooldown[classtable.Combustion].ready then
        if not setSpell then setSpell = classtable.Combustion end
    end
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (MaxDps:Bloodlust(1) or ttd <= 40) and cooldown[classtable.VolcanicPotion].ready then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.ManaGem, 'ManaGem')) and (ManaPerc <84 and not buff[classtable.AlterTimeBuff].up) and cooldown[classtable.ManaGem].ready then
        if not setSpell then setSpell = classtable.ManaGem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (ManaPerc <10 and ttd >= 30) and cooldown[classtable.Evocation].ready then
        if not setSpell then setSpell = classtable.Evocation end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyroblast, 'Pyroblast')) and (buff[classtable.PyroblastBuff].up) and cooldown[classtable.Pyroblast].ready then
        if not setSpell then setSpell = classtable.Pyroblast end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernoBlast, 'InfernoBlast')) and (buff[classtable.HeatingUpBuff].up and not buff[classtable.PyroblastBuff].up) and cooldown[classtable.InfernoBlast].ready then
        if not setSpell then setSpell = classtable.InfernoBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready then
        MaxDps:GlowCooldown(classtable.MirrorImage, cooldown[classtable.MirrorImage].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and (not buff[classtable.AlterTimeBuff].up) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.NetherTempest, 'NetherTempest')) and talents[classtable.NetherTempest] and (targets >= 5 and not debuff[classtable.NetherTempestDeBuff].up) and cooldown[classtable.NetherTempest].ready then
        if not setSpell then setSpell = classtable.NetherTempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingBomb, 'LivingBomb')) and talents[classtable.LivingBomb] and (targets <= 4 and not debuff[classtable.LivingBombDeBuff].up) and cooldown[classtable.LivingBomb].ready then
        if not setSpell then setSpell = classtable.LivingBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fireball, 'Fireball')) and cooldown[classtable.Fireball].ready then
        if not setSpell then setSpell = classtable.Fireball end
    end
    if (MaxDps:CheckSpellUsable(classtable.InfernoBlast, 'InfernoBlast')) and cooldown[classtable.InfernoBlast].ready then
        if not setSpell then setSpell = classtable.InfernoBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
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
    ManaGemCharges = C_Item.GetItemCount(36799, true, true)

    classtable.ManaGem = 5405
    classtable.InfernoBlast = 108853

    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
    end

    classtable.ArcaneBrillianceBuff = 1459
    classtable.MoltenArmorBuff = 30482
    classtable.AlterTimeBuff = 110909
    classtable.PyroblastBuff = 48108
    classtable.HeatingUpBuff = 48107
    classtable.IgniteDeBuff = 413841
    classtable.PyroblastDeBuff = 11366
    classtable.NetherTempestDeBuff = 114923
    classtable.LivingBombDeBuff = 44457

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Fire:precombat()

    Fire:callaction()
    if setSpell then return setSpell end
end
