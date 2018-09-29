--- @type MaxDps
if not MaxDps then
	return ;
end

local Mage = MaxDps:NewModule('Mage', 'AceEvent-3.0');

-- Fire

local _Combustion = 190319;
local _Meteor = 153561;
local _Pyroclasm = 269651;
local _PhoenixFlames = 257541;
local _Flamestrike = 2120;
local _FlamePatch = 205037;
local _HotStreak = 48108;
local _LivingBomb = 44457;
local _DragonsBreath = 31661;
local _FireBlast = 108853;
local _HeatingUp = 48107;
local _Scorch = 2948;
local _SearingTouch = 269644;
local _Fireball = 133;
local _AlexstraszasFury = 235870;
local _Ignite = 12654;
local _Pyroblast = 11366;
local _BlastWave = 157981;
local _FrostNova = 122;
local _Kindling = 155148;
local _BlazingBarrier = 235313;
local _Firestarter = 205026;
local _Pyromaniac = 205020;

-- Frost

local _Frostbolt = 116;
local _FingersofFrost = 44544;
local _IceLance = 30455;
local _BrainFreeze = 190446;
local _GlacialSpike = 199786;
local _Flurry = 44614;
local _IcyVeins = 12472;
local _FrozenOrb = 84714;
local _RayofFrost = 205021;
local _Ebonbolt = 257537;
local _CometStorm = 153595;
local _IceNova = 157997;
local _Blizzard = 190356;
local _FreezingRain = 270233;
local _WintersReach = 273346;
local _Shatter = 12982;
local _Freeze = 231596;
local _ConeofCold = 120;
local _IceFloes = 108839;
local _LonelyWinter = 205024;
local _SummonWaterElemental = 31687;
local _Icicles = 205473;
local _SplittingIce = 56377;

local _SpellWhitelist = {
	[_Frostbolt] = 1,
	[_Ebonbolt] = 1,
	[_Flurry] = 1,
	[_IceLance] = 1,
	[_FrozenOrb] = 1,
	[_RayofFrost] = 1,
	[_GlacialSpike] = 1,
};

-- Arcane

local _Evocation = 12051;
local _ArcanePower = 12042;
local _Overpowered = 155147;
local _ArcaneOrb = 153626;
local _NetherTempest = 114923;
local _ArcaneBlast = 30451;
local _RuleofThrees = 264774;
local _PresenceofMind = 205025;
local _ArcaneBarrage = 44425;
local _ArcaneExplosion = 1449;
local _ArcaneMissiles = 5143;
local _Clearcasting = 263725;
local _Amplification = 236628;
local _ChargedUp = 205032;
local _Supernova = 157980;
local _DrainSoul = 198590;
local _Resonance = 205028;
local _Displacement = 195676;

-- Shared

local _MirrorImage = 55342;
local _RuneofPower = 116011;

_BaseArcaneBlastCost = 3200;


function Mage:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Mage [Arcane, Fire, Frost]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Mage.Arcane;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Mage.Fire;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Mage.Frost;
		self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	end

	return true;
end

function Mage:Disable()
	self:UnregisterAllEvents();
end

function Mage:UNIT_SPELLCAST_SUCCEEDED(event, unitID, spell, spellId)
	if unitID == 'player'and _SpellWhitelist[spellId] == 1 then
		Mage.lastSpell = spellId;
	end
end


function Mage:Arcane(timeShift, currentSpell, gcd, talents)
	-- Ressource
	local arcaneCharge = UnitPower('player', Enum.PowerType.ArcaneCharges);
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local maxMana = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = mana / maxMana;

	if currentSpell == _ArcaneBlast then
		arcaneCharge = arcaneCharge + 1;
	end

	local ap, apCd = MaxDps:Aura(_ArcanePower, timeShift);
	local rop = MaxDps:Aura(_RuneofPower);
	local _, ropCharges, ropCd = MaxDps:SpellCharges(_RuneofPower, timeShift);

	-- image
	MaxDps:GlowCooldown(_MirrorImage, talents[_MirrorImage] and MaxDps:SpellAvailable(_MirrorImage, timeShift));

	local burnCond = MaxDps:SpellAvailable(_ArcanePower, timeShift) and arcaneCharge >= 4 and
		(ropCharges >= 1 or not talents[_RuneofPower]) and
		((talents[_Overpowered] and manaPct > 0.3) or manaPct > 0.5);

	MaxDps:GlowCooldown(_ArcanePower, burnCond);

	-- burn
	if MaxDps:SpellAvailable(_Evocation, timeShift) then

		if manaPct < 0.05 then
			return _Evocation;
		end

		if talents[_ChargedUp] and MaxDps:SpellAvailable(_ChargedUp, timeShift) and arcaneCharge <= 1 then
			return _ChargedUp;
		end

		if talents[_ArcaneOrb] and MaxDps:SpellAvailable(_ArcaneOrb, timeShift) and arcaneCharge < 4 then
			return _ArcaneOrb;
		end

		if talents[_NetherTempest] and not ap and not rop and not MaxDps:TargetAura(_NetherTempest, timeShift + 3)
			and arcaneCharge >= 4 then
			return _NetherTempest;
		end

		if talents[_RuleofThrees] and talents[_Overpowered] and MaxDps:Aura(_RuleofThrees, timeShift) and
			currentSpell ~= _ArcaneBlast then
			return _ArcaneBlast;
		end

		if talents[_RuneofPower] and ropCharges > 1.6 then
			return _RuneofPower;
		end

		local pom, pomCd = MaxDps:SpellAvailable(_PresenceofMind, timeShift);
		if pom and apCd < 2 and not MaxDps:Aura(_PresenceofMind, timeShift) then
			return _PresenceofMind;
		end

		local cc = MaxDps:Aura(_Clearcasting, timeShift);
		local am = MaxDps:SpellAvailable(_ArcaneMissiles, timeShift);

		if talents[_Amplification] and cc and am and currentSpell ~= _ArcaneMissiles then
			return _ArcaneMissiles;
		end

		if am and cc and not ap and manaPct < 0.95 and currentSpell ~= _ArcaneMissiles  then
			return _ArcaneMissiles;
		end

		return _ArcaneBlast;
	end


	if talents[_ChargedUp] and MaxDps:SpellAvailable(_ChargedUp, timeShift) and arcaneCharge == 0 then
		return _ChargedUp;
	end

	if talents[_NetherTempest] and not MaxDps:TargetAura(_NetherTempest, timeShift + 3) and arcaneCharge >= 4 then
		return _NetherTempest;
	end

	if talents[_ArcaneOrb] and MaxDps:SpellAvailable(_ArcaneOrb, timeShift) and arcaneCharge < 4 then
		return _ArcaneOrb;
	end

	if talents[_RuneofPower] and ropCharges > 1.8 and currentSpell ~= _RuneofPower then
		return _RuneofPower;
	end

	if talents[_RuleofThrees] and MaxDps:Aura(_RuleofThrees, timeShift) then
		return _ArcaneBlast;
	end

	if MaxDps:Aura(_Clearcasting, timeShift) and MaxDps:SpellAvailable(_ArcaneMissiles, timeShift) and
		currentSpell ~= _ArcaneMissiles
	then
		return _ArcaneMissiles;
	end

	if manaPct < 0.6 and arcaneCharge >= 4 then
		return _ArcaneBarrage;
	end

	if talents[_Supernova] and MaxDps:SpellAvailable(_Supernova, timeShift) then
		return _Supernova;
	end

	return _ArcaneBlast;
end

function Mage:Fire(timeShift, currentSpell, gcd, talents)

	MaxDps:GlowCooldown(_Combustion, MaxDps:SpellAvailable(_Combustion, timeShift));

	if talents[_MirrorImage] then
		MaxDps:GlowCooldown(_MirrorImage, MaxDps:SpellAvailable(_MirrorImage, timeShift));
	end

	local combu, combuCD = MaxDps:Aura(_Combustion, timeShift);
	--local rop = MaxDps:Aura(_RuneofPower);

	local _, ropCharges, ropCd = MaxDps:SpellCharges(_RuneofPower, timeShift);
	local fb, fbCharges = MaxDps:SpellCharges(_FireBlast, timeShift);
	local pf, pfCharges = MaxDps:SpellCharges(_PhoenixFlames, timeShift);


	if talents[_RuneofPower] and MaxDps:SpellAvailable(_RuneofPower, timeShift) and combu
		and currentSpell ~= _RuneofPower then
		return  _RuneofPower;
	end

	--Cast Meteor, if talented. Only cast it together with Rune of Power of Power, if talented.
	if talents[_Meteor] and MaxDps:SpellAvailable(_Meteor, timeShift) then
		return _Meteor;
	end

	-- Use Rune of Power if it has 2 charges or will have 2 charges within 2 seconds, or you have a Pyroclasm proc,
	-- and Combustion will not be available before a second Rune of Power charge becomes available.
	if talents[_RuneofPower] then
		if (ropCharges >= 1.8 or MaxDps:Aura(_Pyroclasm, timeShift)) and currentSpell ~= _RuneofPower then
			return _RuneofPower;
		end
	end

	--Cast Phoenix Flames if it has 3 charges or will have 3 charges soon, if talented.
	if talents[_PhoenixFlames] and pfCharges >= 2.5 then
		return _PhoenixFlames;
	end

	--Cast Pyroblast when you have a Hot Streak Streak proc.
	if MaxDps:Aura(_HotStreak, timeShift) then
		return _Pyroblast;
	end

	--Cast Dragon's Breath's Breath if Combustion is active and you have no Fire Blast Blast available.
	if combu and fbCharges < 0.8 and MaxDps:SpellAvailable(_DragonsBreath, timeShift) then
		return _DragonsBreath;
	end

	--Cast Fire Blast when you have Heating Up.
	if fbCharges >= 1 and MaxDps:Aura(_HeatingUp, timeShift) then
		return _FireBlast;
	end

	--Cast Scorch if you have Searing Touch talented and the target is below 30% Health, to generate Heating Up	and Hot Streak Streaks.
	local ph = MaxDps:TargetPercentHealth();
	if talents[_SearingTouch] and ph < 0.3 then
		return _Scorch;
	end

	--Cast Fireball to generate Heating Up.
	--Cast Scorch if you have to move and have no instant casts to burn.
	local moving = GetUnitSpeed('player');
	if moving > 0 then
		return _Scorch;
	end

	return _Fireball;
end

function Mage:Frost(timeShift, currentSpell, gcd, talents)
	local rop = MaxDps:Aura(_RuneofPower);
	local ici, iciCharges = MaxDps:Aura(_Icicles, timeShift);

	if currentSpell == _Frostbolt then
		iciCharges = iciCharges + 1;
	end

	local frozenOrb = MaxDps:FindSpell(198149) and 198149 or _FrozenOrb;

	MaxDps:GlowCooldown(_MirrorImage, talents[_MirrorImage] and MaxDps:SpellAvailable(_MirrorImage, timeShift));
	MaxDps:GlowCooldown(_IcyVeins, MaxDps:SpellAvailable(_IcyVeins, timeShift));

	if not talents[_LonelyWinter] and not UnitExists('pet')
		and MaxDps:SpellAvailable(_SummonWaterElemental, timeShift)
		and currentSpell ~= _SummonWaterElemental
	then
		return _SummonWaterElemental;
	end

	--Ice Lance after every Flurry cast. @TODO
	if Mage.lastSpell == _Flurry or currentSpell == _Flurry then
		return _IceLance;
	end

	if MaxDps:Aura(_BrainFreeze, timeShift) and
		(
			talents[_GlacialSpike] and (
				(iciCharges >= 5 and currentSpell == _GlacialSpike) or
				(iciCharges <= 3 and currentSpell == _Frostbolt)
			)
				or
			not talents[_GlacialSpike] and (
				currentSpell == _Ebonbolt or
				currentSpell == _Frostbolt
			)
		)
	then
		return _Flurry;
	end

	if MaxDps:SpellAvailable(frozenOrb, timeShift) then
		return frozenOrb;
	end

	if MaxDps:Aura(_FingersofFrost, timeShift) then
		return _IceLance;
	end

	if talents[_RayofFrost] and MaxDps:SpellAvailable(_RayofFrost, timeShift) and currentSpell ~= _RayofFrost then
		return _RayofFrost;
	end

	if talents[_CometStorm] and MaxDps:SpellAvailable(_CometStorm, timeShift) then
		return _CometStorm;
	end

	if talents[_Ebonbolt] then
		if not talents[_GlacialSpike] and MaxDps:SpellAvailable(_Ebonbolt, timeShift) and currentSpell ~= _Ebonbolt then
			return _Ebonbolt;
		end

		if talents[_GlacialSpike] and MaxDps:SpellAvailable(_Ebonbolt, timeShift) and iciCharges >= 5
			and not MaxDps:Aura(_BrainFreeze, timeShift) and currentSpell ~= _Ebonbolt
		then
			return _Ebonbolt;
		end
	end

	local targets = MaxDps:TargetsInRange(_IceLance);
	if talents[_GlacialSpike] and MaxDps:SpellAvailable(_GlacialSpike, timeShift) and iciCharges >= 5 and
		currentSpell ~= _GlacialSpike and (
		(talents[_SplittingIce] and targets >= 2) or MaxDps:Aura(_BrainFreeze, timeShift) or currentSpell == _Ebonbolt
	) then
		return _GlacialSpike;
	end

	return _Frostbolt;
end

function Mage:ArcaneCharge()
	local _, _, _, charges = UnitAura('player', 'Arcane Charge', nil, 'PLAYER|HARMFUL');
	if charges == nil then
		charges = 0;
	end
	return charges;
end

function Mage:Ignite()
	return select(15, UnitAura('target', 'Ignite', nil, 'HARMFUL'));
end