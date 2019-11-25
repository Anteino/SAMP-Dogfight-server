//----------------------------------------------------------
//
//  DOGFIGHT  1.0
//  A fighter pilot gamemode for SA-MP 0.3
//
//----------------------------------------------------------

#include <a_samp>
#include <core>
#include <float>
#include <YSI\y_commands>
#include "../include/progressbar.inc"
#include "../include/sscanf2.inc"

// #pragma tabsize 0

#define COLOR_WHITE 			0xFFFFFFFF

#define RUSTLER_ID				476
#define HYDRA_ID				520
#define VEHICLE_ID				RUSTLER_ID

#define SPAWN_LOCATION_X		1922.0
#define SPAWN_LOCATION_Y		-2430.0
#define SPAWN_LOCATION_Z		14.25
#define SPAWN_LOCATION_ANGLE	180.0

#define SPAWN_RANGE				50

#define STANDARD_WEATHER		1

// #define FIGHTZONE_MIN_X			-69.0
// #define FIGHTZONE_MAX_X			425.4
// #define FIGHTZONE_MIN_Y			1647.0
// #define FIGHTZONE_MAX_Y			2132.3

#define FIGHTZONE_MIN_X			(-69.0 - 1000)
#define FIGHTZONE_MAX_X			(425.4 + 350)
#define FIGHTZONE_MIN_Y			(1647.0 - 150)
#define FIGHTZONE_MAX_Y			(2132.3 + 600)

#define FIGHTZONE_MIDPOINT_X	(FIGHTZONE_MAX_X + FIGHTZONE_MIN_X) / 2
#define FIGHTZONE_MIDPOINT_Y	(FIGHTZONE_MAX_Y + FIGHTZONE_MIN_Y) / 2

#define FIGHTRANGE_X			(FIGHTZONE_MAX_X - FIGHTZONE_MIN_X)
#define FIGHTRANGE_Y			(FIGHTZONE_MAX_Y - FIGHTZONE_MIN_Y)

#define FIGHTZONE_MARGIN		200.0
#define FIGHTZONE_NO_GO_WIDTH	500.0

#define FIGHTZONE_MIN_Z			621.0		//	21.0 + extra height

#define IN_FIGHT_WARNING		1
#define IN_FREEROAM_WARNING		2

#define FREEROAM				0
#define IN_FIGHT				1
#define REENTERING				2

#define FIGHT_WAITING_LOCATION	346.3, 2483.8, 16.5
#define FIGHT_WAITING_ANGLE		165.5

#define FIGHT_COUNTER_START		5

#define FIGHT_MIN_HEALTH		750.0

#define MAX_LIVE_PICKUPS		10
#define PICKUP_BASE_IAT			60000		//	The amount of pickups that will be inserted per player per time unit is the inverse of this number,
											//	when the amount of players goes up this inter arrival time will be scaled to keep the amount of
											//	pickups per player per time unit constant on average
#define PICKUP_THREAD_DT		600
#define AMOUNT_PICKUP_LOC		20
#define PICKUP_RANGE			5.0

//	Pickup types
#define AMOUNT_PICKUP_TYPES		3

#define PICKUP_HEALTH			0
#define PICKUP_FUEL				1
#define PICKUP_VISION			2
//	End of pickup types

#define VISION_BLUR_DURATION	15000
#define VISION_WEATHER_TYPE		19

//	pickups array indexing
#define PICKUP_AMOUNT_FIELDS	4

#define TYPE					0
#define START_ID				1
#define END_ID					2
#define POS_ID					3
//	end of pickups array indexing

#define FUEL_UPDATE_INTERVAL	300
#define FUEL_RATE				0.000555	//	Amount of fuel burned per second, in %fuel/ms
// #define FUEL_RATE				0.01	//	Amount of fuel burned per second, in %fuel/ms

new Float:PICKUP_LOCATIONS[AMOUNT_PICKUP_LOC][3] = {
		{99.9973,2240.9229,130.3171},
		{-78.0706,2265.0464,129.7907},
		{-272.8639,2236.2703,80.4099},
		{-426.1070,2503.1682,129.3047},
		{-97.6688,2634.4063,48.5383},
		{-663.9979,2571.9851,157.7660},
		{-811.6041,2357.8025,131.2855},
		{-1039.2329,2192.3694,65.6213},
		{-790.0214,2123.3677,48.7378},
		{-649.7656,2125.6650,47.7238},
		{-484.2232,2113.4070,138.4925},
		{-374.4309,2124.8665,137.6510},
		{-322.1332,1948.6766,137.4141},
		{-180.5462,1882.2250,120.7031},
		{-347.2214,1601.3956,169.9084},
		{-897.9266,1659.3677,8.5019},
		{-957.3370,1889.5605,161.8277},
		{-675.5039,2712.0642,86.3785},
		{270.8805,2727.3555,42.3206},
		{291.0545,2545.7107,19.7371}
	};
	
new getIconId[AMOUNT_PICKUP_TYPES] = {27, 21, 23};
new getPickupId[AMOUNT_PICKUP_TYPES] = {11738, 1650, 1254};

new fightZoneId, marginZoneId, nogoZoneId;

new playerVehicle[MAX_PLAYERS];
new playerFighting[MAX_PLAYERS];
new playerShowWarning[MAX_PLAYERS];
new playerCounter[MAX_PLAYERS];
new Float:playerFuel[MAX_PLAYERS];

new Bar:playerBar[MAX_PLAYERS];
new Bar:playerFuelBar[MAX_PLAYERS];

new playerTimer[MAX_PLAYERS];
new playerUnblurtimer[MAX_PLAYERS];

new Float:minHealth;

new activePlayers;

new vehicleType = RUSTLER_ID;

new pickups[MAX_LIVE_PICKUPS][PICKUP_AMOUNT_FIELDS];
new livePickups;
new pickupIAT;											//	Pickup inter arrival time
new lastPickupTime;

new pickupBaseIAT = PICKUP_BASE_IAT;

forward respawnPlayer(playerid);
forward initializeDogfight();
forward removePlayerFromFight(playerid);
forward isPlayerInSquare(playerid, Float:minx, Float:miny, Float:maxx, Float:maxy);
forward resetWarnings(playerid);
forward reenterFight(playerid);
forward countDownForPlayer(playerid);
forward createPickupSphere(pickupId, Float:x, Float:y, Float:z);
forward putPlayerInFight(playerid);
forward gameThread();
forward createRandomPickup();
forward blurVisionExcludingPlayer(playerid);
forward calcPickupIAT();
forward killFightingPlayer(playerid);

main()
{
	print("\n---------------------------------------");
	print("Running DOGFIGHT - By Anteino\n");
	print("---------------------------------------\n");
}

YCMD:rustler(playerid, params[], help)
{
	new Float:x = FIGHTZONE_MIDPOINT_X + 3 * FIGHTRANGE_X;
	new Float:y = FIGHTZONE_MIDPOINT_Y + 3 * FIGHTRANGE_Y;
	new Float:angle = atan2(y - FIGHTZONE_MIDPOINT_Y, x - FIGHTZONE_MIDPOINT_X) + 90.0;
	
	new vehicleId = CreateVehicle(VEHICLE_ID, x, y, FIGHTZONE_MIN_Z, angle, -1, -1, -1);
	PutPlayerInVehicle(playerid, vehicleId, 0);
	SetCameraBehindPlayer(playerid);
	
	return 1;
}

YCMD:joinfight(playerid, params[], help)
{
	if(playerFighting[playerid] != FREEROAM)
	{
		SendClientMessage(playerid, 0xFF0000FF, "You're already in the fight!");
	}
	else
	{
		SendClientMessage(playerid, 0xFF00FFFF, "===============================================================");
		SendClientMessage(playerid, 0xFF00FFFF, "===============================================================");
		SendClientMessage(playerid, COLOR_WHITE, "{00FF00}Welcome to the fight!");
		SendClientMessage(playerid, COLOR_WHITE, "On your minimap you will find your enemies and the available power-ups");
		SendClientMessage(playerid, COLOR_WHITE, "The {00FFFF}blue {FFFFFF}bar displays your vehicles {FF0000}health {FFFFFF}and the {00FF00}green {FFFFFF}bar displays your {00FF00}fuel");
		SendClientMessage(playerid, COLOR_WHITE, "The power ups shown on the minimap represent:");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Heart {FFFFFF}is to {FFFF00}refuel");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Wrench {FFFFFF}is to {FFFF00}repair vehicle");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Skull {FFFFFF}is to {FFFF00}blur your oponents vision");
		SendClientMessage(playerid, 0xFF00FFFF, "===============================================================");
		
		playerFuel[playerid] = 100.0;
		
		playerBar[playerid] = CreateProgressBar(548.5, 36.0, _, _, 0x70000FFFF, 100.0);
		playerFuelBar[playerid] = CreateProgressBar(548.5, 45.0, _, _, 0x700FF00FF, 100.0);
		
		ShowProgressBarForPlayer(playerid, playerBar[playerid]);
		ShowProgressBarForPlayer(playerid, playerFuelBar[playerid]);
		
		putPlayerInFight(playerid);
		
		for(new i = 0; i < livePickups; i++)
		{
			new posid = pickups[i][POS_ID];
			new type = pickups[i][TYPE];
			new iconId = getIconId[type];
			new Float:x = PICKUP_LOCATIONS[posid][0],
				Float:y = PICKUP_LOCATIONS[posid][1],
				Float:z = PICKUP_LOCATIONS[posid][2];
			SetPlayerMapIcon(playerid, i, x, y, z, iconId, -1, 1);
		}
		
		activePlayers++;
		calcPickupIAT();
	}
    return 1;
}

YCMD:leavefight(playerid, params[], help)
{
	if(playerFighting[playerid] == FREEROAM)
	{
		SendClientMessage(playerid, 0xFF0000FF, "You're not in the fight!");
	}
	else
	{
		removePlayerFromFight(playerid);
	}
	return 1;
}

YCMD:setminhealth(playerid, params[], help)
{
	sscanf(params, "f", minHealth);
	new msg[128];
	format(msg, sizeof(msg), "The minimum health is now %f.", minHealth);
	SendClientMessageToAll(0x00FF00FF, msg);
	return 1;
}

YCMD:setiat(playerid, params[], help)
{
	sscanf(params, "d", pickupBaseIAT);
	pickupBaseIAT = pickupBaseIAT * 1000;
	new msg[128];
	format(msg, sizeof(msg), "The pickup base interarrival time is now %d seconds.", pickupBaseIAT / 1000);
	SendClientMessageToAll(0x00FF00FF, msg);
	calcPickupIAT();
	return 1;
}

YCMD:jetpack(playerid, params[], help)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	CreatePickup(370, 4, x, y, z);
	return 1;
}

YCMD:gotopickup(playerid, params[], help)
{
	new pickupid;
	sscanf(params, "d", pickupid);
	new Float:x = PICKUP_LOCATIONS[pickupid][0],
		Float:y = PICKUP_LOCATIONS[pickupid][1],
		Float:z = PICKUP_LOCATIONS[pickupid][2];
	SetPlayerPos(playerid, x, y, z);
	return 1;
}

YCMD:setweather(playerid, params[], help)
{
	new weather;
	sscanf(params, "d", weather);
	SetPlayerWeather(playerid, weather);
	return 1;
}

YCMD:setvehicle(playerid, params[], help)
{
	new id;
	sscanf(params, "d", id);
	vehicleType = id;
	new msg[128];
	format(msg, sizeof(msg), "The vehicle model id is now %d.", vehicleType);
	SendClientMessageToAll(0x00FF00FF, msg);	
	return 1;
}

YCMD:blur(playerid, params[], help)
{
	blurVisionExcludingPlayer(playerid);
	return 1;
}

public calcPickupIAT()
{
	pickupIAT = pickupBaseIAT / activePlayers;
}

public removePlayerFromFight(playerid)
{
	playerFighting[playerid] = FREEROAM;
	DestroyVehicle(playerVehicle[playerid]);
	playerVehicle[playerid] = -1;
	respawnPlayer(playerid);
	SendClientMessage(playerid, 0xFF8000FF, "You left the fight!");
	HideProgressBarForPlayer(playerid, playerBar[playerid]);
	HideProgressBarForPlayer(playerid, playerFuelBar[playerid]);
	activePlayers--;
	if(activePlayers == 0)
	{
		pickupIAT = 9999999;
	}
	else
	{
		pickupIAT = pickupBaseIAT / activePlayers;
	}
	
	new msg[64];
	format(msg, sizeof(msg), "pickupIAT = %d", pickupIAT);
	SendClientMessageToAll(COLOR_WHITE, msg);
	
	return 1;
}

public OnPlayerConnect(playerid)
{
	GameTextForPlayer(playerid,"~w~DOGFIGHT",3000,4);
  	SendClientMessage(playerid, COLOR_WHITE, "Welcome to {88AA88}D{FFFFFF}OGFIGHT. Use /joinfight and /leavefight to fight.");
	GangZoneShowForPlayer(playerid, nogoZoneId, 0xFF000080);
	GangZoneShowForPlayer(playerid, marginZoneId, 0xFF660080);
	GangZoneShowForPlayer(playerid, fightZoneId, 0x00FF0080);
 	return 1;
}

public isPlayerInSquare(playerid, Float:minx, Float:miny, Float:maxx, Float:maxy)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	
	if( ( (x >= minx) && (x <= maxx) ) && ( (y >= miny) && (y <= maxy) ) )
	{
		return 1;
	}
	return 0;
}

public OnPlayerDisconnect(playerid, reason)
{
	removePlayerFromFight(playerid);
	return 1;
}

//----------------------------------------------------------


public respawnPlayer(playerid)
{
	new Float:x = float(random(SPAWN_RANGE) - SPAWN_RANGE / 2), Float:y = float(random(SPAWN_RANGE) - SPAWN_RANGE / 2);
	
	if(IsPlayerInAnyVehicle(playerid))
	{
		new vehicleId = GetPlayerVehicleID(playerid);
		DestroyVehicle(vehicleId);
	}
	
	SetPlayerPos(playerid, SPAWN_LOCATION_X + x, SPAWN_LOCATION_Y + y, SPAWN_LOCATION_Z);
	SetPlayerFacingAngle(playerid, SPAWN_LOCATION_ANGLE);
	SetCameraBehindPlayer(playerid);
	SetPlayerWeather(playerid, STANDARD_WEATHER);
}

public OnPlayerSpawn(playerid)
{
	if(IsPlayerNPC(playerid)) return 1;
	
	ResetPlayerWeapons(playerid);
	
	if(playerFighting[playerid] == REENTERING)
	{
		SetPlayerPos(playerid, FIGHT_WAITING_LOCATION);
		SetPlayerFacingAngle(playerid, FIGHT_WAITING_ANGLE);
		SetCameraBehindPlayer(playerid);
		TogglePlayerControllable(playerid, 0);
		SetTimerEx("reenterFight", 1000 * FIGHT_COUNTER_START, false, "d", playerid);
		
		playerCounter[playerid] = FIGHT_COUNTER_START;
		new msg[32];
		format(msg, sizeof(msg), "~w~%d..", playerCounter[playerid]);
		GameTextForPlayer(playerid, msg, 1000, 3);
		SetTimerEx("countDownForPlayer", 1000, false, "d", playerid);
	}
	else
	{
		respawnPlayer(playerid);
	}
	
	TogglePlayerClock(playerid, 0);

	return 1;
}

public countDownForPlayer(playerid)
{
	playerCounter[playerid]--;
	
	if(playerCounter[playerid] == 0)
	{
		GameTextForPlayer(playerid, "~w~Go!", 1000, 3);
	}
	else
	{
		new msg[32];
		format(msg, sizeof(msg), "~w~%d..", playerCounter[playerid]);
		GameTextForPlayer(playerid, msg, 1000, 3);
		SetTimerEx("countDownForPlayer", 1000, false, "d", playerid);
	}
}

//----------------------------------------------------------

public OnPlayerDeath(playerid, killerid, reason)
{
	if(playerFighting[playerid] == IN_FIGHT)
	{
		playerFighting[playerid] = REENTERING;
		DestroyVehicle(playerVehicle[playerid]);
	}
   	return 1;
}

public reenterFight(playerid)
{
	putPlayerInFight(playerid);
	TogglePlayerControllable(playerid, 1);
}

public putPlayerInFight(playerid)
{
	new Float:x = FIGHTZONE_MIDPOINT_X + FIGHTRANGE_X * (0.5 - float(random(1000)) / 1000.0);
	new Float:y = FIGHTZONE_MIDPOINT_Y + FIGHTRANGE_Y * (0.5 - float(random(1000)) / 1000.0);
	new Float:angle = atan2(y - FIGHTZONE_MIDPOINT_Y, x - FIGHTZONE_MIDPOINT_X) + 90.0;
	
	playerFighting[playerid] = IN_FIGHT;
	playerVehicle[playerid] = CreateVehicle(vehicleType, x, y, FIGHTZONE_MIN_Z, angle, -1, -1, -1);
	playerTimer[playerid] = GetTickCount();
	playerFuel[playerid] = 100.0;
	PutPlayerInVehicle(playerid, playerVehicle[playerid], 0);
	SetCameraBehindPlayer(playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid)) return 1;
	
	SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 26, 36, 28, 150, 0, 0);
	SpawnPlayer(playerid);
    
	return 0;
}

//----------------------------------------------------------

public OnGameModeInit()
{
	SetGameModeText("Dogfight");
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
	ShowNameTags(1);
	SetNameTagDrawDistance(40.0);
	EnableStuntBonusForAll(0);
	DisableInteriorEnterExits();
	SetWeather(2);
	SetWorldTime(11);

	initializeDogfight();

	return 1;
}

public initializeDogfight()
{
	for(new i = 0; i < MAX_PLAYERS; i = i + 1)
	{
		playerFighting[i] = 0;
		playerVehicle[i] = -1;
		playerShowWarning[i] = 0;
		playerCounter[i] = 0;
		playerTimer[i] = GetTickCount();
		playerUnblurtimer[i] = playerTimer[i];
	}
	
	nogoZoneId = GangZoneCreate(	FIGHTZONE_MIN_X - FIGHTZONE_MARGIN - FIGHTZONE_NO_GO_WIDTH,
									FIGHTZONE_MIN_Y - FIGHTZONE_MARGIN - FIGHTZONE_NO_GO_WIDTH,
									FIGHTZONE_MAX_X + FIGHTZONE_MARGIN + FIGHTZONE_NO_GO_WIDTH, 
									FIGHTZONE_MAX_Y + FIGHTZONE_MARGIN + FIGHTZONE_NO_GO_WIDTH);
	marginZoneId = GangZoneCreate(FIGHTZONE_MIN_X - FIGHTZONE_MARGIN, FIGHTZONE_MIN_Y - FIGHTZONE_MARGIN, FIGHTZONE_MAX_X + FIGHTZONE_MARGIN, FIGHTZONE_MAX_Y + FIGHTZONE_MARGIN);
	fightZoneId = GangZoneCreate(FIGHTZONE_MIN_X, FIGHTZONE_MIN_Y, FIGHTZONE_MAX_X, FIGHTZONE_MAX_Y);
	minHealth = FIGHT_MIN_HEALTH;
	
	activePlayers = 0;
	pickupIAT = pickupBaseIAT;
	lastPickupTime = GetTickCount();
	livePickups = 0;
	
	SetTimerEx("gameThread", PICKUP_THREAD_DT, true, "");
}

public gameThread()
{
	if(GetTickCount() - lastPickupTime >= pickupIAT)
	{
		lastPickupTime += pickupIAT;
		if( (activePlayers > 0) && (livePickups < MAX_LIVE_PICKUPS) )
		{
			createRandomPickup();
		}
	}
}

public createRandomPickup()
{
	SendClientMessageToAll(COLOR_WHITE, "Pickup created.");
	
	new type, liveFuelPickups = 0;
	
	for(new i = 0; i < livePickups; i++)
	{
		liveFuelPickups += pickups[i][TYPE] == PICKUP_FUEL ? 1 : 0;
	}
	
	if( (activePlayers >= 2) && (liveFuelPickups < 2) )
	{
		type = PICKUP_FUEL;
	}
	else
	{
		type = random(AMOUNT_PICKUP_TYPES);
	}
	// new iconId = getIconId[type];
	new pickupId = getPickupId[type];
	
	new posid;
	new loop = 1;
	while(loop != 0)
	{
		loop = 0;
		posid = random(AMOUNT_PICKUP_LOC);
		for(new i = 0; i < livePickups; i++)
		{
			if(posid == pickups[i][POS_ID])
			{
				loop = 1;
			}
		}
	}
	
	new	Float:x = PICKUP_LOCATIONS[posid][0],
		Float:y = PICKUP_LOCATIONS[posid][1],
		Float:z = PICKUP_LOCATIONS[posid][2];
	
	pickups[livePickups][TYPE] = type;
	pickups[livePickups][POS_ID] = posid;
	
	createPickupSphere(pickupId, x, y, z);
	
	// for(new i = 0; i < MAX_PLAYERS; i++)
	// {
		// if(playerFighting[i] == 1)
		// {
			// SetPlayerMapIcon(i, livePickups, x, y, z, iconId, -1, 1);
		// }
	// }
	
	livePickups++;
}

public createPickupSphere(pickupId, Float:x, Float:y, Float:z)
{
	new Float:R = 5.0;
	new Float:dAngle = 30.0;
	new Float:dH = 4.0 * R / 12.0;
	
	pickups[livePickups][START_ID] = CreatePickup(pickupId, 1, x, y, z + R, -1);
	CreatePickup(pickupId, 1, x, y, z - R, -1);
	
	for(new Float:h = -R + dH; h <= R - dH; h += dH)
	{
		new Float:r = floatsqroot(R * R - h * h);
		new Float:Z = h;
		for(new Float:angle2 = 0.0; angle2 < 360.0; angle2 += dAngle)
		{
			new Float:X = r * floatcos(angle2, degrees);
			new Float:Y = -r * floatsin(angle2, degrees);
			pickups[livePickups][END_ID] = CreatePickup(pickupId, 1, x + X, y + Y, z + Z, -1);
		}
	}
}

//----------------------------------------------------------

public OnPlayerUpdate(playerid)
{
	if(!IsPlayerConnected(playerid)) return 0;
	if(IsPlayerNPC(playerid)) return 1;
	
	if(playerFighting[playerid] == FREEROAM)
	{
		for(new i = 0; i < AMOUNT_PICKUP_LOC; i++)
		{
			RemovePlayerMapIcon(playerid, i);
		}
	}
	else if(playerFighting[playerid] == IN_FIGHT)
	{
		if(IsPlayerInAnyVehicle(playerid) == 0)
		{
			removePlayerFromFight(playerid);
		}
		
		for(new i = 0; i < livePickups; i++)
		{
			new posid = pickups[i][POS_ID];
			new type = pickups[i][TYPE];
			new iconId = getIconId[type];
			new Float:x = PICKUP_LOCATIONS[posid][0],
				Float:y = PICKUP_LOCATIONS[posid][1],
				Float:z = PICKUP_LOCATIONS[posid][2];
			SetPlayerMapIcon(playerid, i, x, y, z, iconId, -1, 1);
		}
		
		for(new i = livePickups; i < AMOUNT_PICKUP_LOC; i++)
		{
			RemovePlayerMapIcon(playerid, i);
		}
		
		if(GetTickCount() - playerUnblurtimer[playerid] >= 0)
		{
			SetPlayerWeather(playerid, STANDARD_WEATHER);
		}
		
		new Float:health;
		GetVehicleHealth(playerVehicle[playerid], health);
		
		if(health < minHealth)
		{
			SetVehicleHealth(playerVehicle[playerid], 0.0);
			new Float:x, Float:y, Float:z;
			GetVehiclePos(playerVehicle[playerid], x, y, z);
			CreateExplosionForPlayer(playerid, x, y, z, 0, 100.0);
			SetTimerEx("killFightingPlayer", 3000, false, "d", playerid);
		}
		
		SetProgressBarValue(playerBar[playerid], 100.0 * (health - minHealth) / (1000.0 - minHealth));
		ShowProgressBarForPlayer(playerid, playerBar[playerid]);
		
		new tmp = GetTickCount() - playerTimer[playerid];
		if(tmp > FUEL_UPDATE_INTERVAL)
		{
			playerTimer[playerid] += tmp;
			playerFuel[playerid] -= float(tmp) * FUEL_RATE;
			if(playerFuel[playerid] <= 0.0)
			{
				new Float:x, Float:y, Float:z;
				GetVehiclePos(playerVehicle[playerid], x, y, z);
				CreateExplosionForPlayer(playerid, x, y, z, 0, 100.0);
				SetVehicleHealth(playerVehicle[playerid], 0.0);
				playerFuel[playerid] = 0.0;
				new engine, lights, alarm, doors, bonnet, boot, objective;
				GetVehicleParamsEx(playerVehicle[playerid], engine, lights, alarm, doors, bonnet, boot, objective);
				SetVehicleParamsEx(playerVehicle[playerid], 0, lights, alarm, doors, bonnet, boot, objective);
			}
			SetProgressBarValue(playerFuelBar[playerid], playerFuel[playerid]);
			ShowProgressBarForPlayer(playerid, playerFuelBar[playerid]);
		}
		
		for(new i = 0; i < livePickups; i++)
		{
			new posid = pickups[i][POS_ID];
			new Float:xp = PICKUP_LOCATIONS[posid][0],
				Float:yp = PICKUP_LOCATIONS[posid][1],
				Float:zp = PICKUP_LOCATIONS[posid][2];
			new Float:x, Float:y, Float:z;
			GetPlayerPos(playerid, x, y, z);
			if( floatpower(floatpower(xp - x, 2.0) + floatpower(yp - y, 2.0) + floatpower(zp - z, 2.0), 1.0 / 3.0) < PICKUP_RANGE )
			{
				switch(pickups[i][TYPE])
				{
					case PICKUP_HEALTH: RepairVehicle(playerVehicle[playerid]);
					case PICKUP_FUEL: playerFuel[playerid] = 100.0;
					case PICKUP_VISION: blurVisionExcludingPlayer(playerid);
				}
				for(new j = pickups[i][START_ID]; j <= pickups[i][END_ID]; j++)
				{
					DestroyPickup(j);
				}
				// for(new j = 0; j < MAX_PLAYERS; j++)
				// {
					// RemovePlayerMapIcon(j, i);
				// }
				for(new j = i; j < livePickups - 1; j++)
				{
					for(new k = 0; k < PICKUP_AMOUNT_FIELDS; k++)
					{
						pickups[j][k] = pickups[j + 1][k];
					}
				}
				livePickups--;
			}
		}
	}
	
 	//	Player is in middle (green) square, everything ok
	if(isPlayerInSquare(playerid, FIGHTZONE_MIN_X, FIGHTZONE_MIN_Y, FIGHTZONE_MAX_X, FIGHTZONE_MAX_Y) == 1)
	{
		
	}
	//	Player is in orange band around the green square, danger zone, send warning when in fight, kick when not in fight
	else if(isPlayerInSquare(playerid, FIGHTZONE_MIN_X - FIGHTZONE_MARGIN, FIGHTZONE_MIN_Y - FIGHTZONE_MARGIN, FIGHTZONE_MAX_X + FIGHTZONE_MARGIN, FIGHTZONE_MAX_Y + FIGHTZONE_MARGIN) == 1)
	{
		if(playerFighting[playerid] == IN_FIGHT)
		{
			if(playerShowWarning[playerid] != IN_FIGHT_WARNING)
			{
				playerShowWarning[playerid] = IN_FIGHT_WARNING;
				GameTextForPlayer(playerid, "~r~Return to fighting zone.", 100, 3);
				SetTimerEx("resetWarnings", 100, false, "d", playerid);
			}
		}
		else if(playerFighting[playerid] == FREEROAM)
		{
			respawnPlayer(playerid);
			SendClientMessage(playerid, 0xFF0000FF, "You've been warned!");
		}
	}
	//	The player is far outside the fighting area (red), warning if not in fight or kick from fight when currently in fight
	else
	{
		if(playerFighting[playerid] == FREEROAM)
		{
			if(isPlayerInSquare(playerid,	FIGHTZONE_MIN_X - FIGHTZONE_MARGIN - FIGHTZONE_NO_GO_WIDTH,
											FIGHTZONE_MIN_Y - FIGHTZONE_MARGIN - FIGHTZONE_NO_GO_WIDTH,
											FIGHTZONE_MAX_X + FIGHTZONE_MARGIN + FIGHTZONE_NO_GO_WIDTH, 
											FIGHTZONE_MAX_Y + FIGHTZONE_MARGIN + FIGHTZONE_NO_GO_WIDTH) == 1 )
			{
				if(playerShowWarning[playerid] != IN_FREEROAM_WARNING)
				{
					playerShowWarning[playerid] = IN_FREEROAM_WARNING;
					GameTextForPlayer(playerid, "~r~Leave immediately or /joinfight", 100, 3);
					SetTimerEx("resetWarnings", 100, false, "d", playerid);
				}
			}
		}
		else if(playerFighting[playerid] == IN_FIGHT)
		{
			SendClientMessage(playerid, 0xFF0000FF, "You've been warned !");
			removePlayerFromFight(playerid);
		}
	}

	return 1;
}

public killFightingPlayer(playerid)
{
	if(playerFighting[playerid] == IN_FIGHT)
	{
		SetPlayerHealth(playerid, 0.0);
	}
}

public blurVisionExcludingPlayer(playerid)
{
	new msg[64];
	new time = GetTickCount() + VISION_BLUR_DURATION;
	
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if( (playerFighting[i] == 1) && (i != playerid) )
		{
			SetPlayerWeather(i, VISION_WEATHER_TYPE);
			format(msg, sizeof(msg), "~r~Your vision has been blurred for %d seconds.", VISION_BLUR_DURATION / 1000);
			playerUnblurtimer[i] = time;
			GameTextForPlayer(i, msg, 1000, 3);
		}
	}
	
}

public resetWarnings(playerid)
{
	playerShowWarning[playerid] = 0;
}

//----------------------------------------------------------
