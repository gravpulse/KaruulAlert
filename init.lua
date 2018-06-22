local addonInfo, private = ...

local kAlert =
{
	context = UI.CreateContext("kAlert"),
	version = addonInfo.toc.Version,
	revision = tonumber(string.match("$Revision: 106 $", "Revision: (%d+)")),
	versionStable = addonInfo.toc.xVersionStable,
	screenObjects =
	{
		object = nil,
		objectCount = 0,
		max = 40,
		buffUnits = {},
		resourceList = {},
		buffList = {}
	},
	systemScanner =
	{
		activeScanning = false,
		nextScan = math.floor(Inspect.Time.Frame())
	},
	changeHandler =
	{
		buffChanged = false,
		abilityChanged = false,
		resourceChanged = false,
		castingChanged = false
	},
	messaging = {},
	sharedAlerts = {},
	cache =
	{
		resources = {},
		abilities = {},
		buffs = {},
		buffsPending = {},
		unitState = {},
		unitName = {}
	}
}

local kUtils = {}
private.kAlert = kAlert
private.kUtils = kUtils

kAlert.units = {"player", "player.target", "focus", "player.pet", "player.target.target"}
kAlert.rolesMax = 6
kAlert.unitIds = {}
kAlert.unitSpecs = {}
kAlert.unitAvailability = {}
kAlert.unitRelation = {friendly = 1, hostile = 2}
kAlert.combat = false
kAlert.useTargetOfTarget = Inspect.Setting.Detail("combatCastTot").value

kAlert.debug = false
kAlert.profiling = false


