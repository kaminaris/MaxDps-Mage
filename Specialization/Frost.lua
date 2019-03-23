local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local Mage = addonTable.Mage;
local MaxDps = MaxDps;
local UnitExists = UnitExists;

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

local _MirrorImage = 55342;
local _RuneOfPower = 116011

local _SpellWhitelist = {
	[_Frostbolt]    = 1,
	[_Ebonbolt]     = 1,
	[_Flurry]       = 1,
	[_IceLance]     = 1,
	[_FrozenOrb]    = 1,
	[_RayofFrost]   = 1,
	[_GlacialSpike] = 1,
};

function Mage:UNIT_SPELLCAST_SUCCEEDED(event, unitID, spell, spellId)
	if unitID == 'player' and _SpellWhitelist[spellId] == 1 then
		Mage.lastSpell = spellId;
	end
end

function Mage:Frost()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local currentSpell = fd.currentSpell;

	local rop = buff[_RuneOfPower].up;
	local iciCharges = buff[_Icicles].count;

	if currentSpell == _Frostbolt then
		iciCharges = iciCharges + 1;
	end

	local frozenOrb = MaxDps:FindSpell(198149) and 198149 or _FrozenOrb;

	MaxDps:GlowCooldown(_MirrorImage, talents[_MirrorImage] and cooldown[_MirrorImage].ready);
	MaxDps:GlowCooldown(_IcyVeins, cooldown[_IcyVeins].ready);

	if not talents[_LonelyWinter] and not UnitExists('pet')
		and cooldown[_SummonWaterElemental].ready
		and currentSpell ~= _SummonWaterElemental
	then
		return _SummonWaterElemental;
	end

	--Ice Lance after every Flurry cast. @TODO
	if Mage.lastSpell == _Flurry or currentSpell == _Flurry then
		return _IceLance;
	end

	if buff[_BrainFreeze].up and
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

	if cooldown[frozenOrb].ready then
		return frozenOrb;
	end

	if buff[_FingersofFrost].up then
		return _IceLance;
	end

	if talents[_RayofFrost] and cooldown[_RayofFrost].ready and currentSpell ~= _RayofFrost then
		return _RayofFrost;
	end

	if talents[_CometStorm] and cooldown[_CometStorm].ready then
		return _CometStorm;
	end

	if talents[_Ebonbolt] then
		if not talents[_GlacialSpike] and cooldown[_Ebonbolt].ready and currentSpell ~= _Ebonbolt then
			return _Ebonbolt;
		end

		if talents[_GlacialSpike] and cooldown[_Ebonbolt].ready and iciCharges >= 5
			and not buff[_BrainFreeze].up and currentSpell ~= _Ebonbolt
		then
			return _Ebonbolt;
		end
	end

	local targets = MaxDps:TargetsInRange(_IceLance);
	if talents[_GlacialSpike] and cooldown[_GlacialSpike].ready and iciCharges >= 5 and
		currentSpell ~= _GlacialSpike and (
		(talents[_SplittingIce] and targets >= 2) or buff[_BrainFreeze].up or currentSpell == _Ebonbolt
	) then
		return _GlacialSpike;
	end

	return _Frostbolt;
end