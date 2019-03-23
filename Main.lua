local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type MaxDps
if not MaxDps then return end

local Mage = MaxDps:NewModule('Mage', 'AceEvent-3.0');
addonTable.Mage = Mage;

local MaxDps = MaxDps;

Mage.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Mage:Enable()
	if MaxDps.Spec == 1 then
		MaxDps:Print(MaxDps.Colors.Info .. 'Mage - Arcane');
		MaxDps.NextSpell = Mage.Arcane;
	elseif MaxDps.Spec == 2 then
		MaxDps:Print(MaxDps.Colors.Info .. 'Mage - Fire');
		MaxDps.NextSpell = Mage.Fire;
	elseif MaxDps.Spec == 3 then
		MaxDps:Print(MaxDps.Colors.Info .. 'Mage - Frost');
		MaxDps.NextSpell = Mage.Frost;
		self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	end

	return true;
end

function Mage:Disable()
	self:UnregisterAllEvents();
end

