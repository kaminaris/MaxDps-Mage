local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Arcane = {}

function Mage:Arcane()
    if MaxDps:SmartAoe() <= 1 then
        if MaxDps.Power("mana") < 15 or MaxDps.Starved() then return 12051 end --  Evocation
        if (MaxDps.Stacks("player", 400573, "HELPFUL") >= 2) then return 2136 end --  Fire Blast
        if MaxDps.IsTrackedAuraActive(44404) then return 5143 end --  Arcane Missiles
        if MaxDps.Stacks("player", 400573, "HELPFUL") >= 3 or MaxDps.Power("mana") < 40 then return 116 end --  Frostbolt
        if not MaxDps.IsSpellOnCooldown(400574, true) then return 400574 end --  Arcane Blast
        if not MaxDps.IsSpellOnCooldown(116, true) then return 116 end --  Frostbolt
    end

    if MaxDps:SmartAoe() == 2 then
        if MaxDps.Power("mana") < 15 or MaxDps.Starved() then return 12051 end -- Evocation
        if MaxDps.Stacks("player", 400573, "HELPFUL") >= 2 then return 2136 end -- Fire Blast
        if MaxDps.IsTrackedAuraActive(44404) then return 5143 end -- Arcane Missiles
        if MaxDps.Stacks("player", 400573, "HELPFUL") >= 3 or MaxDps.Power("mana") < 40 then return 116 end -- Frostbolt
        if not MaxDps.IsSpellOnCooldown(400574, true) then return 400574 end -- Arcane Blast
        if not MaxDps.IsSpellOnCooldown(116, true) then return 116 end -- Frostbolt
    end

    if MaxDps:SmartAoe() >= 3 then
        if MaxDps.Power("mana") < 15 or MaxDps.Starved() then return 12051 end --  Evocation
        if MaxDps.Near(10) then return 1449 end --  Arcane Explosion
        if not MaxDps.IsSpellOnCooldown(10, true) then return 10 end --  Blizzard
        if (MaxDps.Stacks("player", 400573, "HELPFUL") >= 2) then return 2136 end --  Fire Blast
        if MaxDps.IsTrackedAuraActive(44404) then return 5143 end --  Arcane Missiles
        if MaxDps.Stacks("player", 400573, "HELPFUL") >= 3 or MaxDps.Power("mana") < 40 then return 116 end --  Frostbolt
        if not MaxDps.IsSpellOnCooldown(400574, true) then return 400574 end --  Arcane Blast
        if not MaxDps.IsSpellOnCooldown(116, true) then return 116 end --  Frostbolt
    end
end
