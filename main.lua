-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

-- Spells
-- Talents
local _PrismaticCrystal = 152087;
local _NetherTempest = 114923;
local _RuneOfPower = 116011;
local _Supernova = 157980;
local _ArcaneOrb = 153626;
local _LivingBomb = 44457;
local _BlastWave = 157981;
-- Arcane
local _ArcaneBlast = 30451;
local _ArcaneBarrage = 44425;
local _ArcaneMissiles = 5143;
local _ArcanePower = 12042;
local _Evocation = 12051;
local _PresenceOfMind = 12043;
-- Fire
local _Combustion = 11129;
local _Pyroblast = 11366;
local _InfernoBlast = 108853;
local _Fireball = 133;
local _DragonBreath = 31661;
-- Frost
local _FrozenOrb = 84714;
local _Frostbolt = 116;
local _IceLance = 30455;
local _FrostfireBolt = 44614;
local _IceNova = 157997;
local _SummonWaterElemental = 157750;
local _Freeze = 33395;
local _WaterJet = 135029;


-- Auras
local _RuneOfPowerAura = 116014;
local _ArcaneMissilesAura = 79683;
local _HeatingAura = 48107;
local _PyroblastAura = 48108;
local _FingersOfFrost = 44544;
local _BrainFreeze = 57761;
local _MarkofDoom = 184073;

-- Talents
local _isRuneOfPower = false;
local _isMirrorImage = false;
local _isPrismaticCrystal = false;
local _isArcaneOrb = false;
local _isNetherTempest = false;
local _isSupernova = false;
local _isLivingBomb = false;
local _isBlastWave = false;
local _isIceNova = false;

local _Burn = false;
local _evoFlag = false;

_CombustionValue = 8000;
_BaseArcaneBlastCost = 3200;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Mage_CheckTalents = function()
	-- Tier 6 talents
	_isRuneOfPower = TD_TalentEnabled('Rune of Power');
	_isMirrorImage = TD_TalentEnabled('Mirror Image');

	-- Tier 7 talents
	_isPrismaticCrystal = TD_TalentEnabled('Prismatic Crystal');
	_isArcaneOrb = TD_TalentEnabled('Arcane Orb');

	_isNetherTempest = TD_TalentEnabled('Nether Tempest');
	_isSupernova = TD_TalentEnabled('Supernova');
	_isLivingBomb = TD_TalentEnabled('Living Bomb');
	_isBlastWave = TD_TalentEnabled('Blast Wave');
	_isIceNova = TD_TalentEnabled('Ice Nova');

	_BaseArcaneBlastCost = 3200;
	-- other checking functions
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Mage_EnableAddon(mode)
	mode = mode or 1;
	_TD['DPS_Description'] = 'TD Mage DPS supports: Arcane';
	_TD['DPS_OnEnable'] = TDDps_Mage_CheckTalents;
	if mode == 1 then
		_TD['DPS_NextSpell'] = TDDps_Mage_Arcane;
	end;
	if mode == 2 then
		_TD['DPS_NextSpell'] = TDDps_Mage_Fire;
	end;
	if mode == 3 then
		_TD['DPS_NextSpell'] = TDDps_Mage_Frost;
	end;
	TDDps_EnableAddon();
end

----------------------------------------------
-- Main rotation: Arcane
----------------------------------------------
TDDps_Mage_Arcane = function()
	local timeShift, currentSpell = TD_EndCast();

	local arcaneStacks = TDDps_Mage_ArcaneCharge();
	local mana = TD_Mana(0, timeShift);
	local evo = TD_SpellAvailable(_Evocation, timeShift);
	local ap, apCd = TD_SpellAvailable(_ArcanePower, timeShift);
	local ao = TD_SpellAvailable(_ArcaneOrb, timeShift);
	local pom = TD_SpellAvailable(_PresenceOfMind, timeShift);
	local prism = TD_SpellAvailable(_PrismaticCrystal, timeShift);
	local nt = TD_TargetAura(_NetherTempest, timeShift + 3.6);
	local mod = TD_TargetAura(_MarkofDoom, timeShift);
	local sn, snCharges, snMax = TD_SpellCharges(_Supernova);
	local am, amCharges = TD_Aura(_ArcaneMissilesAura, timeShift);
	local apAura = TD_Aura(_ArcanePower, timeShift);
	local rop = TDDps_Mage_RuneOfPower();

	if amCharges > 0 and currentSpell == 'Arcane Charges' then
		amCharges = amCharges - 1;
	end

	local abMulti = arcaneStacks;
	if currentSpell == 'Arcane Blast' then
		local abCost = _BaseArcaneBlastCost * abMulti;
		if apAura then
			abCost = abCost * 0.9;
		end
		abCost = abCost / UnitPowerMax('player', 0);

		mana = mana - abCost;
	end

	TDButton_GlowCooldown(_ArcanePower, ap);
	TDButton_GlowCooldown(_PresenceOfMind, pom);
	TDButton_GlowCooldown(_PrismaticCrystal, prism);

	if apCd >= 89 and not _Burn then
		print('Burn faza');
		_Burn = true;
	end

	if _isRuneOfPower and not rop and currentSpell ~= 'Rune of Power' then
		return _RuneOfPower;
	end

	-- Conserve rotation
	if (_Burn and mana < 0.5) or (_evoFlag and mana < 0.9) then
		_evoFlag = true;
		return _Evocation;
	end

	if _evoFlag and mana > 0.9 then
		_evoFlag = false;
		_Burn = false;
	end

	if mod and (amCharges > 1 or (amCharges > 0 and currentSpell ~= 'Arcane Missiles')) then
		return _ArcaneMissiles;
	end

	if _isNetherTempest and arcaneStacks == 4 and not nt then
		return _NetherTempest;
	end

	if _isSupernova and snCharges == snMax then
		return _Supernova;
	end

	if _isArcaneOrb and ao and arcaneStacks < 2 then
		return _ArcaneOrb;
	end

	if _Burn and amCharges >= 1 and mana > 0.7 and currentSpell ~= 'Arcane Missiles' then
		return _ArcaneMissiles;
	end

	if mana > 0.93 and currentSpell ~= 'Arcane Blast' then
		return _ArcaneBlast;
	end

	if arcaneStacks == 4 and (amCharges > 1 or (amCharges > 0 and currentSpell ~= 'Arcane Missiles')) then
		return _ArcaneMissiles;
	end

	if not _Burn and (arcaneStacks == 4 or (mana < 0.9 and arcaneStacks >= 1)) then
		return _ArcaneBarrage;
	end

	return _ArcaneBlast;
end

----------------------------------------------
-- Main rotation: Fire
----------------------------------------------
TDDps_Mage_Fire = function()
	local timeShift, currentSpell = TD_EndCast();

	local rop = TDDps_Mage_RuneOfPower();
	local ignite = TDDps_Mage_Ignite();
	local pyro = TD_Aura(_PyroblastAura, timeShift);
	local heating = TD_Aura(_HeatingAura, timeShift);
	local combustion = TD_SpellAvailable(_Combustion, timeShift);
	local inferno = TD_SpellAvailable(_InfernoBlast, timeShift);
	local blast = TD_SpellAvailable(_BlastWave, timeShift);
	local dragon = TD_SpellAvailable(_DragonBreath, timeShift);
	local livingBomb = TD_TargetAura(_LivingBomb, timeShift + 3.6);

	TDButton_GlowCooldown(_DragonBreath, dragon);

	if _isRuneOfPower and not rop and currentSpell ~= 'Rune of Power' then
		return _RuneOfPower;
	end

	if ignite and ignite >= _CombustionValue and combustion then
		return _Combustion;
	end

	if pyro and heating then
		return _Pyroblast;
	end

	if _isLivingBomb and not livingBomb then
		return _LivingBomb;
	end

	if heating and inferno then
		return _InfernoBlast;
	end

	if _isBlastWave and blast then
		return _BlastWave;
	end

	return _Fireball;
end

----------------------------------------------
-- Main rotation: Frost
----------------------------------------------
TDDps_Mage_Frost = function()
	local timeShift, currentSpell = TD_EndCast();
	local _, currentPetSpell = TD_EndCast('pet');

	local orb, orbCD = TD_SpellAvailable(_FrozenOrb, timeShift);
	local orbActive = orbCD > 50;

	local elementalCD = TD_SpellAvailable(_SummonWaterElemental, timeShift);
	local freeze = TD_SpellAvailable(_Freeze, timeShift);
	local jet = TD_SpellAvailable(_WaterJet, timeShift);
	local _, novaCharges = TD_SpellCharges(_IceNova, timeShift);
	local targetPH = TD_TargetPercentHealth();
	local elemental = UnitExists('pet');
	local fingers = TD_Aura(_FingersOfFrost, timeShift);
	local brain = TD_Aura(_BrainFreeze, timeShift);

	TDButton_GlowCooldown(_FrozenOrb, orb);
	TDButton_GlowCooldown(_Freeze, elemental and freeze and not orbActive);

	if not elemental and elementalCD and currentSpell ~= 'Summon Water Elemental' then
		return _SummonWaterElemental;
	end

	if _isIceNova and (novaCharges > 1 or (targetPH < 0.1 and novaCharges >= 1)) then
		return _IceNova;
	end

	if fingers then
		return _IceLance;
	end

	if brain then
		return _FrostfireBolt;
	end

	if not orbActive and jet and not fingers and currentPetSpell ~= 'Water Jet' then
		return _WaterJet;
	end

	if _isIceNova and novaCharges >= 1 then
		return _IceNova;
	end

	return _Frostbolt;
end

----------------------------------------------
-- Arcane Charges
----------------------------------------------
function TDDps_Mage_ArcaneCharge()
	local _, _, _, charges = UnitAura('player', 'Arcane Charge', nil, 'PLAYER|HARMFUL');
	if charges == nil then
		charges = 0;
	end
	return charges;
end

function TDDps_Mage_RuneOfPower()
	local n = UnitAura('player', 'Rune of Power')
	return n == 'Rune of Power';
end

function TDDps_Mage_Ignite()
	return select(15, UnitAura('target', 'Ignite', nil, 'HARMFUL'));
end