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

local Arcane = {}



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

function Arcane:callaction()
    if (MaxDps:CheckSpellUsable(classtable.FocusMagic, 'FocusMagic')) and cooldown[classtable.FocusMagic].ready then
        if not setSpell then setSpell = classtable.FocusMagic end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBrilliance, 'ArcaneBrilliance')) and cooldown[classtable.ArcaneBrilliance].ready then
        if not setSpell then setSpell = classtable.ArcaneBrilliance end
    end
    if (MaxDps:CheckSpellUsable(classtable.MageArmor, 'MageArmor')) and cooldown[classtable.MageArmor].ready then
        if not setSpell then setSpell = classtable.MageArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.ConjureManaGem, 'ConjureManaGem')) and (ManaGemCharges <3) and cooldown[classtable.ConjureManaGem].ready then
        if not setSpell then setSpell = classtable.ConjureManaGem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evocation, 'Evocation')) and (( ( ManaMax >ManaMax and ManaPerc <= 40 ) or ( ManaMax == ManaMax and ManaPerc <= 35 ) ) and ttd >10) and cooldown[classtable.Evocation].ready then
        if not setSpell then setSpell = classtable.Evocation end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameOrb, 'FlameOrb')) and (ttd >= 10) and cooldown[classtable.FlameOrb].ready then
        if not setSpell then setSpell = classtable.FlameOrb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ManaGem, 'ManaGem')) and (buff[classtable.ArcaneBlastBuff].count == 4 and buff[classtable.Tier132pcBuff].count >= 7 and ( cooldown[classtable.ArcanePower].remains <= 0 or ttd <= 50 )) and cooldown[classtable.ManaGem].ready then
        if not setSpell then setSpell = classtable.ManaGem end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePower, 'ArcanePower')) and (( buff[classtable.ImprovedManaGemBuff].up and buff[classtable.Tier132pcBuff].count >= 9 ) or ( buff[classtable.Tier132pcBuff].count >= 10 and cooldown[classtable.ManaGem].remains >30 and cooldown[classtable.Evocation].remains >10 ) or ttd <= 50) and cooldown[classtable.ArcanePower].ready then
        if not setSpell then setSpell = classtable.ArcanePower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MirrorImage, 'MirrorImage')) and (buff[classtable.ArcanePowerBuff].up or ( cooldown[classtable.ArcanePower].remains >20 and ttd >15 )) and cooldown[classtable.MirrorImage].ready then
        if not setSpell then setSpell = classtable.MirrorImage end
    end
    if (MaxDps:CheckSpellUsable(classtable.PresenceofMind, 'PresenceofMind')) and cooldown[classtable.PresenceofMind].ready then
        if not setSpell then setSpell = classtable.PresenceofMind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConjureManaGem, 'ConjureManaGem')) and (buff[classtable.PresenceofMindBuff].up and ttd >cooldown[classtable.ManaGem].remains and ManaGemCharges == 0) and cooldown[classtable.ConjureManaGem].ready then
        if not setSpell then setSpell = classtable.ConjureManaGem end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.PresenceofMindBuff].up) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (ttd <20 or ( ( cooldown[classtable.Evocation].remains <= 20 or buff[classtable.ImprovedManaGemBuff].up or cooldown[classtable.ManaGem].remains <5 ) and ManaPerc >= 22 ) or ( buff[classtable.ArcanePowerBuff].up and ManaPerc >88 )) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and (buff[classtable.ArcaneBlastBuff].remains <0.8 and buff[classtable.ArcaneBlastBuff].count == 4) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (ManaPerc <92 and buff[classtable.ArcaneMissilesBuff].up and buff[classtable.MageArmorBuff].remains <= 2) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneMissiles, 'ArcaneMissiles')) and (ManaPerc <93 and buff[classtable.ArcaneMissilesBuff].up and buff[classtable.MageArmorBuff].remains >2) and cooldown[classtable.ArcaneMissiles].ready then
        if not setSpell then setSpell = classtable.ArcaneMissiles end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ManaPerc <87 and buff[classtable.ArcaneBlastBuff].count == 2) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ManaPerc <90 and buff[classtable.ArcaneBlastBuff].count == 3) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and (ManaPerc <92 and buff[classtable.ArcaneBlastBuff].count == 4) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBlast, 'ArcaneBlast')) and cooldown[classtable.ArcaneBlast].ready then
        if not setSpell then setSpell = classtable.ArcaneBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneBarrage, 'ArcaneBarrage')) and cooldown[classtable.ArcaneBarrage].ready then
        if not setSpell then setSpell = classtable.ArcaneBarrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBlast, 'FireBlast')) and cooldown[classtable.FireBlast].ready then
        if not setSpell then setSpell = classtable.FireBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceLance, 'IceLance')) and cooldown[classtable.IceLance].ready then
        if not setSpell then setSpell = classtable.IceLance end
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
    classtable.ManaGem = 36799
    ManaGemCharges = C_Item.GetItemCount(classtable.ManaGem,false, true) or 0
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ImprovedManaGemBuff = 83098
    classtable.ArcaneBlastBuff = 38881
    classtable.Tier132pcBuff = 0
    classtable.ArcanePowerBuff = 12042
    classtable.PresenceofMindBuff = 205025
    classtable.ArcaneMissilesBuff = 0

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
