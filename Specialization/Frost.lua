local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit

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


local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    if spellstring == 'KillShot' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then print('no cost found for ',spellstring) return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


function Frost:precombat()
    if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
        return classtable.Flask
    end
    if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
        return classtable.Food
    end
    if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
        return classtable.Augmentation
    end
    if (MaxDps:FindSpell(classtable.ArcaneIntellect) and CheckSpellCosts(classtable.ArcaneIntellect, 'ArcaneIntellect')) and cooldown[classtable.ArcaneIntellect].ready then
        return classtable.ArcaneIntellect
    end
    if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
        return classtable.SnapshotStats
    end
    if (MaxDps:FindSpell(classtable.Blizzard) and CheckSpellCosts(classtable.Blizzard, 'Blizzard')) and (targets >= 2 and talents[classtable.IceCaller] or targets >= 3) and cooldown[classtable.Blizzard].ready then
        return classtable.Blizzard
    end
    if (MaxDps:FindSpell(classtable.Frostbolt) and CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and (targets <= 2) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
end
function Frost:aoe()
    if (MaxDps:FindSpell(classtable.ConeofCold) and CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and ( (MaxDps.spellHistory[1] == classtable.CometStorm) or (MaxDps.spellHistory[1] == classtable.FrozenOrb) and not talents[classtable.CometStorm] )) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (MaxDps:FindSpell(classtable.FrozenOrb) and CheckSpellCosts(classtable.FrozenOrb, 'FrozenOrb')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or not freezable) and cooldown[classtable.FrozenOrb].ready then
        return classtable.FrozenOrb
    end
    if (MaxDps:FindSpell(classtable.Blizzard) and CheckSpellCosts(classtable.Blizzard, 'Blizzard')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or not freezable) and cooldown[classtable.Blizzard].ready then
        return classtable.Blizzard
    end
    if (MaxDps:FindSpell(classtable.CometStorm) and CheckSpellCosts(classtable.CometStorm, 'CometStorm')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) and ( not talents[classtable.ColdestSnap] or cooldown[classtable.ConeofCold].ready and cooldown[classtable.FrozenOrb].remains >25 or cooldown[classtable.ConeofCold].remains >20 )) and cooldown[classtable.CometStorm].ready then
        return classtable.CometStorm
    end
    if (MaxDps:FindSpell(classtable.Freeze) and CheckSpellCosts(classtable.Freeze, 'Freeze')) and (freezable and not debuff[classtable.FrozenDeBuff].up and ( not talents[classtable.GlacialSpike] and not talents[classtable.Snowstorm] or (MaxDps.spellHistory[1] == classtable.GlacialSpike) or cooldown[classtable.ConeofCold].ready and buff[classtable.SnowstormBuff].count == buff[classtable.SnowstormBuff].maxStacks )) and cooldown[classtable.Freeze].ready then
        return classtable.Freeze
    end
    if (MaxDps:FindSpell(classtable.IceNova) and CheckSpellCosts(classtable.IceNova, 'IceNova')) and (freezable and not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and ( (MaxDps.spellHistory[1] == classtable.GlacialSpike) or cooldown[classtable.ConeofCold].ready and buff[classtable.SnowstormBuff].count == buff[classtable.SnowstormBuff].maxStacks and gcd <1 )) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (MaxDps:FindSpell(classtable.FrostNova) and CheckSpellCosts(classtable.FrostNova, 'FrostNova')) and (freezable and not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and ( (MaxDps.spellHistory[1] == classtable.GlacialSpike) and not (debuff[classtable.WintersChillDeBuff].up) or cooldown[classtable.ConeofCold].ready and buff[classtable.SnowstormBuff].count == buff[classtable.SnowstormBuff].maxStacks and gcd <1 )) and cooldown[classtable.FrostNova].ready then
        return classtable.FrostNova
    end
    if (MaxDps:FindSpell(classtable.ConeofCold) and CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and (buff[classtable.SnowstormBuff].count == buff[classtable.SnowstormBuff].maxStacks) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (MaxDps:FindSpell(classtable.ShiftingPower) and CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (MaxDps:FindSpell(classtable.GlacialSpike) and CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and cooldown[classtable.Blizzard].remains >gcd) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (MaxDps:FindSpell(classtable.Flurry) and CheckSpellCosts(classtable.Flurry, 'Flurry')) and (not freezable and cooldown[classtable.Flurry].ready and not debuff[classtable.WintersChillDeBuff].duration and ( (MaxDps.spellHistory[1] == classtable.GlacialSpike) or cooldown[classtable.Flurry].charges >1.8 )) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (MaxDps:FindSpell(classtable.Flurry) and CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and not debuff[classtable.WintersChillDeBuff].duration and ( buff[classtable.BrainFreezeBuff].up or not buff[classtable.FingersofFrostBuff].up )) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (MaxDps:FindSpell(classtable.IceLance) and CheckSpellCosts(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up or debuff[classtable.FrozenDeBuff].remains >1 or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (MaxDps:FindSpell(classtable.IceNova) and CheckSpellCosts(classtable.IceNova, 'IceNova')) and (targets >= 4 and ( not talents[classtable.Snowstorm] and not talents[classtable.GlacialSpike] or not freezable )) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (MaxDps:FindSpell(classtable.DragonsBreath) and CheckSpellCosts(classtable.DragonsBreath, 'DragonsBreath')) and (targets >= 7) and cooldown[classtable.DragonsBreath].ready then
        return classtable.DragonsBreath
    end
    if (MaxDps:FindSpell(classtable.ArcaneExplosion) and CheckSpellCosts(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (ManaPerc >30 and targets >= 7) and cooldown[classtable.ArcaneExplosion].ready then
        return classtable.ArcaneExplosion
    end
    if (MaxDps:FindSpell(classtable.Frostbolt) and CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end
end
function Frost:cds()
    --if (MaxDps:FindSpell(classtable.TimeWarp) and CheckSpellCosts(classtable.TimeWarp, 'TimeWarp')) and (buff[classtable.ExhaustionBuff].up and talents[classtable.TemporalWarp] and MaxDps:Bloodlust() and ( MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.IcyVeins or ( buff[classtable.IcyVeinsBuff].up and ttd <= 110 or buff[classtable.IcyVeinsBuff].up and ttd >= 280 ) or ttd <40 )) and cooldown[classtable.TimeWarp].ready then
    --    return classtable.TimeWarp
    --end
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.IcyVeins or ttd <60) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
    if (MaxDps:FindSpell(classtable.Flurry) and CheckSpellCosts(classtable.Flurry, 'Flurry')) and (timeInCombat == 0 and targets <= 2) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (MaxDps:FindSpell(classtable.IcyVeins) and CheckSpellCosts(classtable.IcyVeins, 'IcyVeins')) and cooldown[classtable.IcyVeins].ready then
        return classtable.IcyVeins
    end
end
function Frost:cleave()
    if (MaxDps:FindSpell(classtable.CometStorm) and CheckSpellCosts(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold)) and cooldown[classtable.CometStorm].ready then
        return classtable.CometStorm
    end
    if (MaxDps:FindSpell(classtable.Flurry) and CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and ( ( (MaxDps.spellHistory[1] == classtable.Frostbolt) and buff[classtable.IciclesBuff].count >= 3 ) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) or ( buff[classtable.IciclesBuff].count >= 3 and buff[classtable.IciclesBuff].count <5 and cooldown[classtable.Flurry].charges == 2 ) )) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (MaxDps:FindSpell(classtable.IceLance) and CheckSpellCosts(classtable.IceLance, 'IceLance')) and (talents[classtable.GlacialSpike] and not debuff[classtable.WintersChillDeBuff].up and buff[classtable.IciclesBuff].count == 4 and buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (MaxDps:FindSpell(classtable.RayofFrost) and CheckSpellCosts(classtable.RayofFrost, 'RayofFrost')) and ((debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        return classtable.RayofFrost
    end
    if (MaxDps:FindSpell(classtable.GlacialSpike) and CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and ( cooldown[classtable.Flurry].ready or (debuff[classtable.WintersChillDeBuff].up) )) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (MaxDps:FindSpell(classtable.FrozenOrb) and CheckSpellCosts(classtable.FrozenOrb, 'FrozenOrb')) and (buff[classtable.FingersofFrostBuff].count <2 and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains )) and cooldown[classtable.FrozenOrb].ready then
        return classtable.FrozenOrb
    end
    if (MaxDps:FindSpell(classtable.ConeofCold) and CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and cooldown[classtable.CometStorm].remains >10 and cooldown[classtable.FrozenOrb].remains >10 and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and targets >= 3) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (MaxDps:FindSpell(classtable.Blizzard) and CheckSpellCosts(classtable.Blizzard, 'Blizzard')) and (targets >= 2 and talents[classtable.IceCaller] and talents[classtable.FreezingRain] and ( not talents[classtable.SplinteringCold] and not talents[classtable.RayofFrost] or buff[classtable.FreezingRainBuff].up or targets >= 3 )) and cooldown[classtable.Blizzard].ready then
        return classtable.Blizzard
    end
    if (MaxDps:FindSpell(classtable.ShiftingPower) and CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and (cooldown[classtable.FrozenOrb].remains >10 and ( not talents[classtable.CometStorm] or cooldown[classtable.CometStorm].remains >10 ) and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains >10 ) or cooldown[classtable.IcyVeins].remains <20) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (MaxDps:FindSpell(classtable.GlacialSpike) and CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (MaxDps:FindSpell(classtable.IceLance) and CheckSpellCosts(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (MaxDps:FindSpell(classtable.IceNova) and CheckSpellCosts(classtable.IceNova, 'IceNova')) and (targets >= 4) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (MaxDps:FindSpell(classtable.Frostbolt) and CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end
end
function Frost:movement()
    if (MaxDps:FindSpell(classtable.AnyBlink) and CheckSpellCosts(classtable.AnyBlink, 'AnyBlink')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.AnyBlink].ready then
        return classtable.AnyBlink
    end
    if (MaxDps:FindSpell(classtable.IceFloes) and CheckSpellCosts(classtable.IceFloes, 'IceFloes')) and (not buff[classtable.IceFloesBuff].up) and cooldown[classtable.IceFloes].ready then
        return classtable.IceFloes
    end
    if (MaxDps:FindSpell(classtable.IceNova) and CheckSpellCosts(classtable.IceNova, 'IceNova')) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (MaxDps:FindSpell(classtable.ArcaneExplosion) and CheckSpellCosts(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (ManaPerc >30 and targets >= 2) and cooldown[classtable.ArcaneExplosion].ready then
        return classtable.ArcaneExplosion
    end
    if (MaxDps:FindSpell(classtable.FireBlast) and CheckSpellCosts(classtable.FireBlast, 'FireBlast')) and cooldown[classtable.FireBlast].ready then
        return classtable.FireBlast
    end
    if (MaxDps:FindSpell(classtable.IceLance) and CheckSpellCosts(classtable.IceLance, 'IceLance')) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
end
function Frost:st()
    if (MaxDps:FindSpell(classtable.CometStorm) and CheckSpellCosts(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold)) and cooldown[classtable.CometStorm].ready then
        return classtable.CometStorm
    end
    if (MaxDps:FindSpell(classtable.Flurry) and CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and not debuff[classtable.WintersChillDeBuff].up and ( ( (MaxDps.spellHistory[1] == classtable.Frostbolt) and buff[classtable.IciclesBuff].count >= 3 or (MaxDps.spellHistory[1] == classtable.Frostbolt) and buff[classtable.BrainFreezeBuff].up ) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) or talents[classtable.GlacialSpike] and buff[classtable.IciclesBuff].count == 4 and not buff[classtable.FingersofFrostBuff].up )) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (MaxDps:FindSpell(classtable.IceLance) and CheckSpellCosts(classtable.IceLance, 'IceLance')) and (talents[classtable.GlacialSpike] and not debuff[classtable.WintersChillDeBuff].up and buff[classtable.IciclesBuff].count == 4 and buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (MaxDps:FindSpell(classtable.RayofFrost) and CheckSpellCosts(classtable.RayofFrost, 'RayofFrost')) and ((debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        return classtable.RayofFrost
    end
    if (MaxDps:FindSpell(classtable.GlacialSpike) and CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and ( cooldown[classtable.Flurry].ready or (debuff[classtable.WintersChillDeBuff].up) )) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (MaxDps:FindSpell(classtable.FrozenOrb) and CheckSpellCosts(classtable.FrozenOrb, 'FrozenOrb')) and (buff[classtable.FingersofFrostBuff].count <2 and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains )) and cooldown[classtable.FrozenOrb].ready then
        return classtable.FrozenOrb
    end
    if (MaxDps:FindSpell(classtable.ConeofCold) and CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and cooldown[classtable.CometStorm].remains >10 and cooldown[classtable.FrozenOrb].remains >10 and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and targets >= 3) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (MaxDps:FindSpell(classtable.Blizzard) and CheckSpellCosts(classtable.Blizzard, 'Blizzard')) and (targets >= 2 and talents[classtable.IceCaller] and talents[classtable.FreezingRain] and ( not talents[classtable.SplinteringCold] and not talents[classtable.RayofFrost] or buff[classtable.FreezingRainBuff].up or targets >= 3 )) and cooldown[classtable.Blizzard].ready then
        return classtable.Blizzard
    end
    if (MaxDps:FindSpell(classtable.ShiftingPower) and CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and (cooldown[classtable.FrozenOrb].remains >10 and ( not talents[classtable.CometStorm] or cooldown[classtable.CometStorm].remains >10 ) and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains >10 ) or cooldown[classtable.IcyVeins].remains <20) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (MaxDps:FindSpell(classtable.GlacialSpike) and CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (MaxDps:FindSpell(classtable.IceLance) and CheckSpellCosts(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (MaxDps:FindSpell(classtable.IceNova) and CheckSpellCosts(classtable.IceNova, 'IceNova')) and (targets >= 4) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (MaxDps:FindSpell(classtable.Frostbolt) and CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    ArcaneCharges = UnitPower('player', ArcaneChargesPT)
    ManaPerc = (Mana / ManaMax) * 100
    classtable.FrozenDeBuff = 122
    classtable.SnowstormBuff = 381706
    classtable.IciclesBuff = 205473
    classtable.WintersChillDeBuff = 228358
    classtable.BrainFreezeBuff = 190446
    classtable.FingersofFrostBuff = 44544
    classtable.ExhaustionBuff = 0
    classtable.IcyVeinsBuff = 12472
    classtable.FreezingRainBuff = 270232
    classtable.IceFloesBuff = 108839

    --if (MaxDps:FindSpell(classtable.Counterspell) and CheckSpellCosts(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
    --    return classtable.Counterspell
    --end
    local cdsCheck = Frost:cds()
    if cdsCheck then
        return cdsCheck
    end
    if (targets >= 7 and not (MaxDps.tier and MaxDps.tier[30].count >= 2) or targets >= 3 and talents[classtable.IceCaller]) then
        local aoeCheck = Frost:aoe()
        if aoeCheck then
            return Frost:aoe()
        end
    end
    if (targets == 2) then
        local cleaveCheck = Frost:cleave()
        if cleaveCheck then
            return Frost:cleave()
        end
    end
    local stCheck = Frost:st()
    if stCheck then
        return stCheck
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end

end
