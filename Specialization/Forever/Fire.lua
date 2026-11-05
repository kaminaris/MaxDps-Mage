local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Fire = {}

function Mage:Fire()
    if MaxDps:SmartAoe() <= 1 then
        if ((MaxDps.Stacks("player", 22959, "HELPFUL") >= 5)) and not MaxDps.IsSpellOnCooldown(11129, true) then return 11129 end --  Combustion
        if (MaxDps.Power("mana") < 20 or MaxDps.Starved()) and not MaxDps.IsSpellOnCooldown(12051, true) then return 12051 end --  Evocation
        if (MaxDps.Stacks("player", 400625, "HELPFUL") == 3) and not MaxDps.IsSpellOnCooldown(11366, true) then return 11366 end --  Pyroblast
        if ((MaxDps.Stacks("player", 400625, "HELPFUL") >= 2) and not MaxDps.IsTrackedAuraActive(400625)) and not MaxDps.IsSpellOnCooldown(11366, true) then return 11366 end --  Pyroblast
        if (MaxDps.IsTrackedAuraActive(12536) or MaxDps.Power("mana") >= 10) and not MaxDps.IsSpellOnCooldown(2136, true) then return 2136 end --  Fire Blast
        if (MaxDps.Stacks("player", 22959, "HELPFUL") < 5 or not MaxDps.IsTrackedAuraActive(22959)) and not MaxDps.IsSpellOnCooldown(2948, true) then return 2948 end --  Scorch
        if ((MaxDps.Power("mana") >= 10)) and not MaxDps.IsSpellOnCooldown(133, true) then return 133 end --  Fireball
        if not MaxDps.IsSpellOnCooldown(2948, true) then return 2948 end --  Scorch
    end

    if MaxDps:SmartAoe() == 2 then
        if (MaxDps.Stacks("player", 22959, "HELPFUL") >= 5) and not MaxDps.IsSpellOnCooldown(11129, true) then return 11129 end -- Combustion
        if (MaxDps.Power("mana") < 20 or MaxDps.Starved()) and not MaxDps.IsSpellOnCooldown(12051, true) then return 12051 end -- Evocation
        if (MaxDps.Stacks("player", 400625, "HELPFUL") == 3) and not MaxDps.IsSpellOnCooldown(11366, true) then return 11366 end -- Pyroblast
        if (MaxDps.Stacks("player", 400625, "HELPFUL") >= 2 and not MaxDps.IsTrackedAuraActive(400625)) and not MaxDps.IsSpellOnCooldown(11366, true) then return 11366 end -- Pyroblast
        if (MaxDps.IsTrackedAuraActive(12536) or MaxDps.Power("mana") >= 10) and not MaxDps.IsSpellOnCooldown(2136, true) then return 2136 end -- Fire Blast
        if (MaxDps.Stacks("player", 22959, "HELPFUL") < 5 or not MaxDps.IsTrackedAuraActive(22959)) and not MaxDps.IsSpellOnCooldown(2948, true) then return 2948 end -- Scorch
        if (MaxDps.Power("mana") >= 10) and not MaxDps.IsSpellOnCooldown(133, true) then return 133 end -- Fireball
        if not MaxDps.IsSpellOnCooldown(2948, true) then return 2948 end -- Scorch
    end

    if MaxDps:SmartAoe() >= 3 then
        if ((MaxDps.Stacks("player", 22959, "HELPFUL") >= 5)) and not MaxDps.IsSpellOnCooldown(11129, true) then return 11129 end --  Combustion
        if (MaxDps.Power("mana") < 20 or MaxDps.Starved()) and not MaxDps.IsSpellOnCooldown(12051, true) then return 12051 end --  Evocation
        if (MaxDps.Stacks("player", 400625, "HELPFUL") == 3) and not MaxDps.IsSpellOnCooldown(11366, true) then return 11366 end --  Pyroblast
        if ((MaxDps.Stacks("player", 400625, "HELPFUL") >= 2) and not MaxDps.IsTrackedAuraActive(400625)) and not MaxDps.IsSpellOnCooldown(11366, true) then return 11366 end --  Pyroblast
        if (MaxDps.Near(10)) and not MaxDps.IsSpellOnCooldown(11113, true) then return 11113 end --  Blast Wave
        if (MaxDps.IsTrackedAuraActive(12536) or MaxDps.Power("mana") >= 10) and not MaxDps.IsSpellOnCooldown(2136, true) then return 2136 end --  Fire Blast
        if (MaxDps.Stacks("player", 22959, "HELPFUL") < 5 or not MaxDps.IsTrackedAuraActive(22959)) and not MaxDps.IsSpellOnCooldown(2948, true) then return 2948 end --  Scorch
        if not MaxDps.IsSpellOnCooldown(2120, true) then return 2120 end --  Flamestrike
        if ((MaxDps.Power("mana") >= 10)) and not MaxDps.IsSpellOnCooldown(133, true) then return 133 end --  Fireball
        if not MaxDps.IsSpellOnCooldown(2948, true) then return 2948 end --  Scorch
    end
end
