local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end

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


local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
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




local function freezable()
   if (cooldown[classtable.IceNova].ready or cooldown[classtable.Freeze].ready or cooldown[classtable.FrostNova].ready) and not ( UnitName('target') == UnitName('boss1') or UnitName('target') == UnitName('boss2') or UnitName('target') == UnitName('boss3') or UnitName('target') == UnitName('boss4') or UnitName('target') == UnitName('boss5') or UnitName('target') == UnitName('boss6') or UnitName('target') == UnitName('boss7') or UnitName('target') == UnitName('boss8') ) then
      return true
    else
      return false
   end
end


local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Frost:precombat()
    --if (CheckSpellCosts(classtable.ArcaneIntellect, 'ArcaneIntellect')) and cooldown[classtable.ArcaneIntellect].ready then
    --    return classtable.ArcaneIntellect
    --end
    --if (CheckSpellCosts(classtable.MirrorImage, 'MirrorImage')) and cooldown[classtable.MirrorImage].ready then
    --    return classtable.MirrorImage
    --end
    --if (CheckSpellCosts(classtable.Blizzard, 'Blizzard')) and (targets >= 2 and talents[classtable.IceCaller] and not talents[classtable.FracturedFrost] or targets >= 3) and cooldown[classtable.Blizzard].ready then
    --    return classtable.Blizzard
    --end
    --if (CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and (targets <= 2) and cooldown[classtable.Frostbolt].ready then
    --    return classtable.Frostbolt
    --end
end
function Frost:aoe()
    if (CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and ( (MaxDps.spellHistory[1] == classtable.CometStorm) or (MaxDps.spellHistory[1] == classtable.FrozenOrb) and not talents[classtable.CometStorm] )) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (CheckSpellCosts(classtable.FrozenOrb, 'FrozenOrb')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or not freezable) and cooldown[classtable.FrozenOrb].ready then
        return classtable.FrozenOrb
    end
    if (CheckSpellCosts(classtable.Blizzard, 'Blizzard')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or not freezable) and cooldown[classtable.Blizzard].ready then
        return classtable.Blizzard
    end
    if (CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and (buff[classtable.IcyVeinsBuff].up and ( buff[classtable.DeathsChillBuff].count <9 or buff[classtable.DeathsChillBuff].count == 9 and not (classtable and classtable.Frostbolt and GetSpellCooldown(classtable.Frostbolt).duration >=5 ) ) and buff[classtable.IcyVeinsBuff].remains >8 and talents[classtable.DeathsChill]) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
    if (CheckSpellCosts(classtable.CometStorm, 'CometStorm')) and (not (MaxDps.spellHistory[1] == classtable.GlacialSpike) and ( not talents[classtable.ColdestSnap] or cooldown[classtable.ConeofCold].ready and cooldown[classtable.FrozenOrb].remains >25 or cooldown[classtable.ConeofCold].remains >20 )) and cooldown[classtable.CometStorm].ready then
        return classtable.CometStorm
    end
    if (CheckSpellCosts(classtable.Freeze, 'Freeze')) and (freezable and not debuff[classtable.FrozenDeBuff].up and ( not talents[classtable.GlacialSpike] or (MaxDps.spellHistory[1] == classtable.GlacialSpike) )) and cooldown[classtable.Freeze].ready then
        return classtable.Freeze
    end
    if (CheckSpellCosts(classtable.IceNova, 'IceNova')) and (freezable and not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and ( (MaxDps.spellHistory[1] == classtable.GlacialSpike) )) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (CheckSpellCosts(classtable.FrostNova, 'FrostNova')) and (freezable and not MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[1] ~= classtable.Freeze and ( (MaxDps.spellHistory[1] == classtable.GlacialSpike) and not (debuff[classtable.WintersChillDeBuff].up and 1 or 0) )) and cooldown[classtable.FrostNova].ready then
        return classtable.FrostNova
    end
    if (CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and (cooldown[classtable.CometStorm].remains >10) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and not debuff[classtable.WintersChillDeBuff].duration and buff[classtable.IciclesBuff].count == 4 and talents[classtable.GlacialSpike] and not freezable) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and cooldown[classtable.Blizzard].remains >gcd) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (CheckSpellCosts(classtable.Flurry, 'Flurry')) and (( freezable or not talents[classtable.GlacialSpike] ) and cooldown[classtable.Flurry].ready and not debuff[classtable.WintersChillDeBuff].duration and ( buff[classtable.BrainFreezeBuff].up or not buff[classtable.FingersofFrostBuff].up )) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up or debuff[classtable.FrozenDeBuff].remains >1 or (debuff[classtable.WintersChillDeBuff].up and 1 or 0)) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (CheckSpellCosts(classtable.IceNova, 'IceNova')) and (targets >= 4 and ( not talents[classtable.GlacialSpike] or not freezable )) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) >= 8 and not talents[classtable.ColdestSnap] and targets >= 7) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (CheckSpellCosts(classtable.DragonsBreath, 'DragonsBreath')) and (targets >= 7) and cooldown[classtable.DragonsBreath].ready then
        return classtable.DragonsBreath
    end
    if (CheckSpellCosts(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (ManaPerc >30 and targets >= 7) and cooldown[classtable.ArcaneExplosion].ready then
        return classtable.ArcaneExplosion
    end
    if (CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end
end
function Frost:cds()
    if (CheckSpellCosts(classtable.Flurry, 'Flurry')) and (timeInCombat <0.1 and targets <= 2) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (CheckSpellCosts(classtable.IcyVeins, 'IcyVeins')) and cooldown[classtable.IcyVeins].ready then
        return classtable.IcyVeins
    end
end
function Frost:cleave()
    if (CheckSpellCosts(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold)) and cooldown[classtable.CometStorm].ready then
        return classtable.CometStorm
    end
    if (CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and ( ( ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.FrostfireBolt) ) and buff[classtable.IciclesBuff].count >= 3 ) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) or ( buff[classtable.IciclesBuff].count >= 3 and buff[classtable.IciclesBuff].count <5 and cooldown[classtable.Flurry].charges == 2 ) )) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and (talents[classtable.GlacialSpike] and not debuff[classtable.WintersChillDeBuff].up and buff[classtable.IciclesBuff].count == 4 and buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (CheckSpellCosts(classtable.RayofFrost, 'RayofFrost')) and ((debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        return classtable.RayofFrost
    end
    if (CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and ( cooldown[classtable.Flurry].ready or (debuff[classtable.WintersChillDeBuff].up ) )) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (CheckSpellCosts(classtable.FrozenOrb, 'FrozenOrb')) and (buff[classtable.FingersofFrostBuff].count <2 and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].ready==false )) and cooldown[classtable.FrozenOrb].ready then
        return classtable.FrozenOrb
    end
    if (CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and cooldown[classtable.CometStorm].remains >10 and cooldown[classtable.FrozenOrb].remains >10 and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and targets >= 3) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and (cooldown[classtable.FrozenOrb].remains >10 and ( not talents[classtable.CometStorm] or cooldown[classtable.CometStorm].remains >10 ) and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains >10 ) or cooldown[classtable.IcyVeins].remains <20) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (CheckSpellCosts(classtable.IceNova, 'IceNova')) and (targets >= 4) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end
end
function Frost:movement()
    --if (CheckSpellCosts(classtable.AnyBlink, 'AnyBlink')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.AnyBlink].ready then
    --    return classtable.AnyBlink
    --end
    --if (CheckSpellCosts(classtable.IceFloes, 'IceFloes')) and (not buff[classtable.IceFloesBuff].up) and cooldown[classtable.IceFloes].ready then
    --    return classtable.IceFloes
    --end
    --if (CheckSpellCosts(classtable.IceNova, 'IceNova')) and cooldown[classtable.IceNova].ready then
    --    return classtable.IceNova
    --end
    --if (CheckSpellCosts(classtable.ArcaneExplosion, 'ArcaneExplosion')) and (ManaPerc >30 and targets >= 2) and cooldown[classtable.ArcaneExplosion].ready then
    --    return classtable.ArcaneExplosion
    --end
    --if (CheckSpellCosts(classtable.FireBlast, 'FireBlast')) and cooldown[classtable.FireBlast].ready then
    --    return classtable.FireBlast
    --end
    --if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and cooldown[classtable.IceLance].ready then
    --    return classtable.IceLance
    --end
end
function Frost:ss_st()
    if (CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and not debuff[classtable.WintersChillDeBuff].up and ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) )) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and (buff[classtable.IcyVeinsBuff].up and debuff[classtable.WintersChillDeBuff].count == 2) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (CheckSpellCosts(classtable.RayofFrost, 'RayofFrost')) and (not buff[classtable.IcyVeinsBuff].up and not buff[classtable.FreezingWindsBuff].up and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        return classtable.RayofFrost
    end
    if (CheckSpellCosts(classtable.FrozenOrb, 'FrozenOrb')) and cooldown[classtable.FrozenOrb].ready then
        return classtable.FrozenOrb
    end
    if (CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and ((debuff[classtable.WintersChillDeBuff].up and 1 or 0) or buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (CheckSpellCosts(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold) or (classtable and classtable.Splinterstorm and GetSpellCooldown(classtable.Splinterstorm).duration >=5 )) and cooldown[classtable.CometStorm].ready then
        return classtable.CometStorm
    end
    if (CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and buff[classtable.IcyVeinsBuff].up) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
end
function Frost:st()
    if (CheckSpellCosts(classtable.CometStorm, 'CometStorm')) and ((MaxDps.spellHistory[1] == classtable.Flurry) or (MaxDps.spellHistory[1] == classtable.ConeofCold)) and cooldown[classtable.CometStorm].ready then
        return classtable.CometStorm
    end
    if (CheckSpellCosts(classtable.Flurry, 'Flurry')) and (cooldown[classtable.Flurry].ready and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and not debuff[classtable.WintersChillDeBuff].up and ( ( ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.FrostfireBolt) ) and buff[classtable.IciclesBuff].count >= 3 or ( (MaxDps.spellHistory[1] == classtable.Frostbolt) or (MaxDps.spellHistory[1] == classtable.FrostfireBolt) ) and buff[classtable.BrainFreezeBuff].up ) or (MaxDps.spellHistory[1] == classtable.GlacialSpike) or talents[classtable.GlacialSpike] and buff[classtable.IciclesBuff].count == 4 and not buff[classtable.FingersofFrostBuff].up ) or buff[classtable.ExcessFrostBuff].up and buff[classtable.FrostfireEmpowermentBuff].up) and cooldown[classtable.Flurry].ready then
        return classtable.Flurry
    end
    if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and (talents[classtable.GlacialSpike] and not debuff[classtable.WintersChillDeBuff].up and buff[classtable.IciclesBuff].count == 4 and buff[classtable.FingersofFrostBuff].up) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (CheckSpellCosts(classtable.RayofFrost, 'RayofFrost')) and ((debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 1) and cooldown[classtable.RayofFrost].ready then
        return classtable.RayofFrost
    end
    if (CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5 and ( cooldown[classtable.Flurry].ready or (debuff[classtable.WintersChillDeBuff].up) )) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (CheckSpellCosts(classtable.FrozenOrb, 'FrozenOrb')) and (buff[classtable.FingersofFrostBuff].count <2 and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].ready==false )) and cooldown[classtable.FrozenOrb].ready then
        return classtable.FrozenOrb
    end
    if (CheckSpellCosts(classtable.ConeofCold, 'ConeofCold')) and (talents[classtable.ColdestSnap] and cooldown[classtable.CometStorm].remains >10 and cooldown[classtable.FrozenOrb].remains >10 and (debuff[classtable.WintersChillDeBuff].up and 1 or 0) == 0 and targets >= 3) and cooldown[classtable.ConeofCold].ready then
        return classtable.ConeofCold
    end
    if (CheckSpellCosts(classtable.Blizzard, 'Blizzard')) and (targets >= 2 and talents[classtable.IceCaller] and talents[classtable.FreezingRain] and ( not talents[classtable.SplinteringCold] and not talents[classtable.RayofFrost] or buff[classtable.FreezingRainBuff].up or targets >= 3 )) and cooldown[classtable.Blizzard].ready then
        return classtable.Blizzard
    end
    if (CheckSpellCosts(classtable.ShiftingPower, 'ShiftingPower')) and (( not buff[classtable.IcyVeinsBuff].up or not talents[classtable.DeathsChill] ) and cooldown[classtable.FrozenOrb].remains >10 and ( not talents[classtable.CometStorm] or cooldown[classtable.CometStorm].remains >10 ) and ( not talents[classtable.RayofFrost] or cooldown[classtable.RayofFrost].remains >10 ) or cooldown[classtable.IcyVeins].remains <20) and cooldown[classtable.ShiftingPower].ready then
        return classtable.ShiftingPower
    end
    if (CheckSpellCosts(classtable.GlacialSpike, 'GlacialSpike')) and (buff[classtable.IciclesBuff].count == 5) and cooldown[classtable.GlacialSpike].ready then
        return classtable.GlacialSpike
    end
    if (CheckSpellCosts(classtable.IceLance, 'IceLance')) and (buff[classtable.FingersofFrostBuff].up and not (MaxDps.spellHistory[1] == classtable.GlacialSpike) or (debuff[classtable.WintersChillDeBuff].up)) and cooldown[classtable.IceLance].ready then
        return classtable.IceLance
    end
    if (CheckSpellCosts(classtable.IceNova, 'IceNova')) and (targets >= 4) and cooldown[classtable.IceNova].ready then
        return classtable.IceNova
    end
    if (CheckSpellCosts(classtable.Frostbolt, 'Frostbolt')) and cooldown[classtable.Frostbolt].ready then
        return classtable.Frostbolt
    end
    local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    if movementCheck then
        return movementCheck
    end
end

function Frost:callaction()
    if (CheckSpellCosts(classtable.Counterspell, 'Counterspell')) and cooldown[classtable.Counterspell].ready then
        MaxDps:GlowCooldown(classtable.Counterspell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    local cdsCheck = Frost:cds()
    if cdsCheck then
        return cdsCheck
    end
    if (targets >= 7 and not (MaxDps.tier and MaxDps.tier[30].count >= 2) or targets >= 4 and talents[classtable.IceCaller]) then
        local aoeCheck = Frost:aoe()
        if aoeCheck then
            return Frost:aoe()
        end
    end
    if (targets >= 2 and targets <= 3) then
        local cleaveCheck = Frost:cleave()
        if cleaveCheck then
            return Frost:cleave()
        end
    end
    if (talents[classtable.Splinterstorm]) then
        local ss_stCheck = Frost:ss_st()
        if ss_stCheck then
            return Frost:ss_st()
        end
    end
    local stCheck = Frost:st()
    if stCheck then
        return stCheck
    end
    --local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    --if movementCheck then
    --    return movementCheck
    --end
    --local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    --if movementCheck then
    --    return movementCheck
    --end
    --local movementCheck = Frost:movement() and GetUnitSpeed('player') > 0
    --if movementCheck then
    --    return movementCheck
    --end
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
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    ArcaneCharges = UnitPower('player', ArcaneChargesPT)
    ManaPerc = (Mana / ManaMax) * 100
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.IcyVeinsBuff = 12472
    classtable.DeathsChillBuff = 0
    classtable.FrozenDeBuff = 122
    classtable.WintersChillDeBuff = 228358
    classtable.IciclesBuff = 205473
    classtable.BrainFreezeBuff = 190446
    classtable.FingersofFrostBuff = 44544
    classtable.IceFloesBuff = 108839
    classtable.FreezingWindsBuff = 0
    classtable.ExcessFrostBuff = 0
    classtable.FrostfireEmpowermentBuff = 0
    classtable.FreezingRainBuff = 270232

    local precombatCheck = Frost:precombat()
    if precombatCheck then
        return Frost:precombat()
    end

    local callactionCheck = Frost:callaction()
    if callactionCheck then
        return Frost:callaction()
    end
end
