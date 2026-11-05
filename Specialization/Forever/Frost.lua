local _, addonTable = ...
local Mage = addonTable.Mage
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Frost = {}

function Mage:Frost()
    if MaxDps:SmartAoe() <= 1 then
        if (MaxDps.Power("mana") < 20 or MaxDps.Starved()) and not MaxDps.IsSpellOnCooldown(12051, true) then return 12051 end --  Evocation
        if (MaxDps.IsTrackedAuraActive(400669)) and not MaxDps.IsSpellOnCooldown(1312002, true) then return 1312002 end --  Ice Lance
        if not MaxDps.IsSpellOnCooldown(116, true) then return 116 end --  Frostbolt
    end

    if MaxDps:SmartAoe() == 2 then
        if not MaxDps.IsSpellOnCooldown(120, true) then return 120 end -- Cone of Cold
        if (MaxDps.Power("mana") < 20 or MaxDps.Starved()) and not MaxDps.IsSpellOnCooldown(12051, true) then return 12051 end -- Evocation
        if (MaxDps.IsTrackedAuraActive(400669)) and not MaxDps.IsSpellOnCooldown(1312002, true) then return 1312002 end -- Ice Lance
        if not MaxDps.IsSpellOnCooldown(116, true) then return 116 end -- Frostbolt
    end

    if MaxDps:SmartAoe() >= 3 then
        if not MaxDps.IsSpellOnCooldown(120, true) then return 120 end --  Cone of Cold
        if (MaxDps.Power("mana") < 20 or MaxDps.Starved()) and not MaxDps.IsSpellOnCooldown(12051, true) then return 12051 end --  Evocation
        if not MaxDps.IsSpellOnCooldown(10, true) then return 10 end --  Blizzard
        if (MaxDps.IsTrackedAuraActive(400669)) and not MaxDps.IsSpellOnCooldown(1312002, true) then return 1312002 end --  Ice Lance
        if not MaxDps.IsSpellOnCooldown(116, true) then return 116 end --  Frostbolt
        if not MaxDps.IsSpellOnCooldown(122, true) then return 122 end --  Frost Nova
    end
end
