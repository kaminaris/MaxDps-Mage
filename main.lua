-- Fire
local _RuneofPower = 116011;
local _Combustion = 190319;
local _PhoenixsFlames = 194466;
local _FlameOn = 205029;
local _Flamestrike = 2120;
local _HotStreak = 195283;
local _HotStreakAura = 48108;
local _Pyroblast = 11366;
local _Meteor = 153561;
local _LivingBomb = 44457;
local _FireBlast = 108853;
local _DragonsBreath = 31661;
local _HeatingUp = 48107;
local _Fireball = 133;
local _Scorch = 2948;
local _IceFloes = 108839;
local _Ignite = 12654;
local _MirrorImage = 55342;
local _BlastWave = 157981;
local _Cinderstorm = 198929;
local _FrostNova = 122;
local _Blink = 1953;
local _IceBlock = 45438;
local _Kindling = 155148;
local _IceBarrier = 11426;
local _Shimmer = 212653;
local _Pyromaniac = 205020;

-- Talents
local _isFlameOn = false;
local _isBlastWave = false;
local _isMeteor = false;
local _isCinderstorm = false;
local _isMirrorImage = false;
local _isRuneofPower = false;

-- Legendary items
local _isKoralon = false;
local _isDarckli = false;

_BaseArcaneBlastCost = 3200;

MaxDps.Mage = {};
function MaxDps.Mage.CheckTalents()
	MaxDps:CheckTalents();
	_isFlameOn = MaxDps:HasTalent(_FlameOn);
	_isBlastWave = MaxDps:HasTalent(_BlastWave);
	_isMeteor = MaxDps:HasTalent(_Meteor);
	_isCinderstorm = MaxDps:HasTalent(_Cinderstorm);
	_isMirrorImage = MaxDps:HasTalent(_MirrorImage);
	_isRuneofPower = MaxDps:HasTalent(_RuneofPower);
	_isKoralon = IsEquippedItem(132454);
	_isDarckli = IsEquippedItem(132863);
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Mage [Fire]';
	MaxDps.ModuleOnEnable = MaxDps.Mage.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Mage.Arcane;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Mage.Fire;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Mage.Frost;
	end;
end

function MaxDps.Mage.Arcane()
	local timeShift, currentSpell = MaxDps:EndCast();

	return nil;
end

function MaxDps.Mage.Fire()
	local timeShift, currentSpell = MaxDps:EndCast();

	MaxDps:GlowCooldown(_Combustion, MaxDps:SpellAvailable(_Combustion, timeShift));
	MaxDps:GlowCooldown(_RuneofPower, _isRuneofPower and MaxDps:SpellAvailable(_RuneofPower, timeShift));
	MaxDps:GlowCooldown(_MirrorImage, _isMirrorImage and MaxDps:SpellAvailable(_MirrorImage, timeShift));

	local combu, combuCD = MaxDps:Aura(_Combustion, timeShift);
	local rop = MaxDps:PersistentAura(_RuneofPower);

	local pf, pfCharges = MaxDps:SpellCharges(_PhoenixsFlames, timeShift);
	local fb, fbCharges = MaxDps:SpellCharges(_FireBlast, timeShift);

	local ph = MaxDps:TargetPercentHealth();

	if pfCharges >= 2 then
		return _PhoenixsFlames;
	end

	if MaxDps:Aura(_HotStreakAura, timeShift) then
		return _Pyroblast;
	end

	if _isFlameOn and fbCharges == 0 and MaxDps:SpellAvailable(_FlameOn, timeShift) then
		return _FlameOn;
	end

	--actions.active_talents+=/blast_wave,if=(buff.combustion.down)|(buff.combustion.up&action.fire_blast
	--.charges<1&action.phoenixs_flames.charges<1)
	if _isBlastWave and MaxDps:SpellAvailable(_BlastWave, timeShift) and
		((not combu) or
		(combu and fbCharges < 1 and pfCharges < 1))
	then
		return _BlastWave;
	end

	--actions.active_talents+=/meteor,if=cooldown.combustion.remains>30|(cooldown.combustion.remains>target
	--.time_to_die)|buff.rune_of_power.up
	if _isMeteor and MaxDps:SpellAvailable(_Meteor, timeShift) and ((combuCD > 30) or rop) then
		return _Meteor
	end

	--actions.active_talents+=/cinderstorm,if=cooldown.combustion.remains<cast_time&(buff.rune_of_power.up|!talent
	--.rune_on_power.enabled)|cooldown.combustion.remains>10*spell_haste&!buff.combustion.up
	if _isCinderstorm and MaxDps:SpellAvailable(_Cinderstorm, timeShift) and
		not MaxDps:SameSpell(currentSpell, _Cinderstorm) and
		not combu and not rop then
		return _Cinderstorm;
	end

	--actions.active_talents+=/dragons_breath,if=equipped.132863
	if _isDarckli and MaxDps:SpellAvailable(_DragonsBreath, timeShift) then
		return _DragonsBreath;
	end

	--actions.active_talents+=/living_bomb,if=active_enemies>1&buff.combustion.down
	--NIY

	if fbCharges > 0 and MaxDps:Aura(_HeatingUp, timeShift) then
		return _FireBlast;
	end

	local moving = GetUnitSpeed('player');
	if (_isKoralon and ph < 0.25) or moving > 0 then
		return _Scorch;
	end

	return _Fireball;
end

function MaxDps.Mage.Frost()
	local timeShift, currentSpell = MaxDps:EndCast();
	local _, currentPetSpell = MaxDps:EndCast('pet');

	return nil;
end

function MaxDps.Mage.ArcaneCharge()
	local _, _, _, charges = UnitAura('player', 'Arcane Charge', nil, 'PLAYER|HARMFUL');
	if charges == nil then
		charges = 0;
	end
	return charges;
end

function MaxDps.Mage.RuneOfPower()
	local n = UnitAura('player', 'Rune of Power')
	return n == 'Rune of Power';
end

function MaxDps.Mage.Ignite()
	return select(15, UnitAura('target', 'Ignite', nil, 'HARMFUL'));
end