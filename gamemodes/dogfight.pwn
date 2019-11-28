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

#define FIRING_VICINITY			200.0		//	If a player fires at another player while further away than this, bullets have no effect
#define FIRING_ERROR			10.0			//	By how many meters the projected firing vector may be off

//	Pickup types
#define AMOUNT_PICKUP_TYPES		7

#define PICKUP_HEALTH			0
#define PICKUP_FUEL				1
#define PICKUP_VISION			2
#define PICKUP_HEIGHT			3
#define PICKUP_SHIELD			4
#define PICKUP_RADAR			5
#define PICKUP_SPEED			6
//	End of pickup types

#define VISION_BLUR_DURATION	15000
#define HEIGHT_PICKUP_DURATION	15000
#define SHIELD_PICKUP_DURATION	15000
#define RADAR_JAM_DURATION		30000
#define SPEED_BOOST_DURATION	20000
#define VISION_WEATHER_TYPE		19

#define PICKUP_HEIGHT_Z_STEP	15.0
#define SPEED_BOOST_STEP		50.0

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

new PlayerColors[] = {
	0xFF8C13FF,0xC715FFFF,0x20B2AAFF,0xDC143CFF,0x6495EDFF,0xf0e68cFF,0x778899FF,0xFF1493FF,0xF4A460FF,0xEE82EEFF,
	0xFFD720FF,0x8b4513FF,0x4949A0FF,0x148b8bFF,0x14ff7fFF,0x556b2fFF,0x0FD9FAFF,0x10DC29FF,0x534081FF,0x0495CDFF,
	0xEF6CE8FF,0xBD34DAFF,0x247C1BFF,0x0C8E5DFF,0x635B03FF,0xCB7ED3FF,0x65ADEBFF,0x5C1ACCFF,0xF2F853FF,0x11F891FF,
	0x7B39AAFF,0x53EB10FF,0x54137DFF,0x275222FF,0xF09F5BFF,0x3D0A4FFF,0x22F767FF,0xD63034FF,0x9A6980FF,0xDFB935FF,
	0x3793FAFF,0x90239DFF,0xE9AB2FFF,0xAF2FF3FF,0x057F94FF,0xB98519FF,0x388EEAFF,0x028151FF,0xA55043FF,0x0DE018FF,
	0x93AB1CFF,0x95BAF0FF,0x369976FF,0x18F71FFF,0x4B8987FF,0x491B9EFF,0x829DC7FF,0xBCE635FF,0xCEA6DFFF,0x20D4ADFF,
	0x2D74FDFF,0x3C1C0DFF,0x12D6D4FF,0x48C000FF,0x2A51E2FF,0xE3AC12FF,0xFC42A8FF,0x2FC827FF,0x1A30BFFF,0xB740C2FF,
	0x42ACF5FF,0x2FD9DEFF,0xFAFB71FF,0x05D1CDFF,0xC471BDFF,0x94436EFF,0xC1F7ECFF,0xCE79EEFF,0xBD1EF2FF,0x93B7E4FF,
	0x3214AAFF,0x184D3BFF,0xAE4B99FF,0x7E49D7FF,0x4C436EFF,0xFA24CCFF,0xCE76BEFF,0xA04E0AFF,0x9F945CFF,0xDCDE3DFF,
	0x10C9C5FF,0x70524DFF,0x0BE472FF,0x8A2CD7FF,0x6152C2FF,0xCF72A9FF,0xE59338FF,0xEEDC2DFF,0xD8C762FF,0x3FE65CFF
};

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
	
new getIconId[AMOUNT_PICKUP_TYPES] = {63, 21, 23, 5, 22, 34, 27};
new getPickupId[AMOUNT_PICKUP_TYPES] = {11738, 1650, 1254, 19134, 1242, 1247, 1241};

new fightZoneId, marginZoneId, nogoZoneId;
new visionWeatherType = VISION_WEATHER_TYPE;

new playerFiring[MAX_PLAYERS];

new playerVehicle[MAX_PLAYERS];
new playerFighting[MAX_PLAYERS];
new playerShowWarning[MAX_PLAYERS];
new playerCounter[MAX_PLAYERS];
new Float:playerFuel[MAX_PLAYERS];
new playerFuelWarning[MAX_PLAYERS];

new Bar:playerBar[MAX_PLAYERS];
new Bar:playerFuelBar[MAX_PLAYERS];

new playerTimer[MAX_PLAYERS];
new playerUnblurtimer[MAX_PLAYERS];
new playerUnjamtimer[MAX_PLAYERS];
new playerHeightPickupTimer[MAX_PLAYERS];
new playerShieldPickupTimer[MAX_PLAYERS];
new playerSpeedBoostTimer[MAX_PLAYERS];

new Float:playerHealth[MAX_PLAYERS];		//	Used to save the health when the shield pickup is activated
new Float:oldVehicleHealth[MAX_PLAYERS];

new Float:minHealth;

new activePlayers;

new vehicleType = RUSTLER_ID;

new pickups[MAX_LIVE_PICKUPS][PICKUP_AMOUNT_FIELDS];
new livePickups;
new pickupIAT;											//	Pickup inter arrival time
new lastPickupTime;

new pickupBaseIAT = PICKUP_BASE_IAT;

forward putPlayerInFight(playerid);
forward removePlayerFromFight(playerid);
forward calcPickupIAT();

forward setDogfightMapIcons(playerid);
forward removeDogfightMapIcons(playerid);

forward respawnPlayer(playerid);
forward initializeDogfight();
forward isPlayerInSquare(playerid, Float:minx, Float:miny, Float:maxx, Float:maxy);
forward resetWarnings(playerid);
forward reenterFight(playerid);
forward countDownForPlayer(playerid);
forward createPickupSphere(pickupId, Float:x, Float:y, Float:z);
forward gameThread();
forward createRandomPickup();

forward blurVisionExcludingPlayer(playerid);
forward jamRadarExcludingPlayer(playerid);
forward activatePlayerShield(playerid);
forward activateHeightPickup(playerid);
forward activateSpeedBoost(playerid);
forward refuelPlayerVehicle(playerid);
forward repairPlayerVehicle(playerid);

forward onVehicleHealthUpdate(playerid, Float:amount);

main()
{
	print("\n---------------------------------------");
	print("Running DOGFIGHT - By Anteino\n");
	print("---------------------------------------\n");
}

/******************************************************
*******************************************************
***                                                 ***
***        Handling of native SA-MP callbacks       ***
***                                                 ***
*******************************************************
*******************************************************/

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

public OnPlayerConnect(playerid)
{
	GameTextForPlayer(playerid,"~w~DOGFIGHT",3000,4);
  	SendClientMessage(playerid, COLOR_WHITE, "Welcome to {88AA88}D{FFFFFF}OGFIGHT. Use {FF0000}/joinfight {FFFFFF}and {FF0000}/leavefight {FFFFFF}to fight.");
	GangZoneShowForPlayer(playerid, nogoZoneId, 0xFF000080);
	GangZoneShowForPlayer(playerid, marginZoneId, 0xFF660080);
	GangZoneShowForPlayer(playerid, fightZoneId, 0x00FF0080);
	SetPlayerColor(playerid, PlayerColors[playerid % sizeof PlayerColors]);
 	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	removePlayerFromFight(playerid);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid)) return 1;
	
	SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 26, 36, 28, 150, 0, 0);
	SpawnPlayer(playerid);
    
	return 0;
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
	
	TogglePlayerClock(playerid, 0);

	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(!IsPlayerConnected(playerid)) return 0;
	if(IsPlayerNPC(playerid)) return 1;
	
	if(playerFighting[playerid] == FREEROAM)
	{
		removeDogfightMapIcons(playerid);
	}
	else if(playerFighting[playerid] == IN_FIGHT)
	{
		if(IsPlayerInAnyVehicle(playerid) == 0)
		{
			removePlayerFromFight(playerid);
		}
		
		setDogfightMapIcons(playerid);
		
		if(GetTickCount() - playerUnblurtimer[playerid] >= 0)
		{
			SetPlayerWeather(playerid, STANDARD_WEATHER);
		}
		
		if(GetTickCount() - playerUnjamtimer[playerid] >= 0)
		{
			new color;
			for(new i = 0; i < MAX_PLAYERS; i++)
			{
				if( (playerFighting[i] == 1) && (i != playerid) )
				{
					color = GetPlayerColor(i);
					SetPlayerMarkerForPlayer(i, playerid, color);
				}
			}
		}
		
		new Float:health;
		if(GetTickCount() - playerShieldPickupTimer[playerid] >= 0)
		{
			GetVehicleHealth(playerVehicle[playerid], health);
		}
		else
		{
			health = playerHealth[playerid];
			SetVehicleHealth(playerVehicle[playerid], playerHealth[playerid]);
		}
		
		if(health != oldVehicleHealth[playerid])
		{
			onVehicleHealthUpdate(playerid, oldVehicleHealth[playerid] - health);
			oldVehicleHealth[playerid] = health;
		}
		
		if(health < minHealth)
		{
			SetVehicleHealth(playerVehicle[playerid], 0.0);
			SetPlayerHealth(playerid, 0.0);
			new Float:x, Float:y, Float:z;
			GetVehiclePos(playerVehicle[playerid], x, y, z);
			CreateExplosionForPlayer(playerid, x, y, z, 0, 100.0);
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
				playerFuel[playerid] = 0.0;
				new engine, lights, alarm, doors, bonnet, boot, objective;
				GetVehicleParamsEx(playerVehicle[playerid], engine, lights, alarm, doors, bonnet, boot, objective);
				SetVehicleParamsEx(playerVehicle[playerid], 0, lights, alarm, doors, bonnet, boot, objective);
			}
			else if( (playerFuel[playerid] <= 10.0) && (playerFuelWarning[playerid] == 1) )
			{
				playerFuelWarning[playerid] = 2;
				GameTextForPlayer(playerid, "~w~EXTREMELY LOW FUEL: ~r~10%", 3000, 3);
			}
			else if( (playerFuel[playerid] <= 25.0) && (playerFuelWarning[playerid] == 0) )
			{
				playerFuelWarning[playerid] = 1;
				GameTextForPlayer(playerid, "~w~LOW FUEL: ~r~25%", 3000, 3);
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
					case PICKUP_HEALTH: repairPlayerVehicle(playerid);
					case PICKUP_FUEL: refuelPlayerVehicle(playerid);
					case PICKUP_VISION: blurVisionExcludingPlayer(playerid);
					case PICKUP_HEIGHT: activateHeightPickup(playerid);
					case PICKUP_SHIELD: activatePlayerShield(playerid);
					case PICKUP_RADAR: jamRadarExcludingPlayer(playerid);
					case PICKUP_SPEED: activateSpeedBoost(playerid);
				}
				for(new j = pickups[i][START_ID]; j <= pickups[i][END_ID]; j++)
				{
					DestroyPickup(j);
					
				}
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

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(playerFighting[playerid] == IN_FIGHT)
	{
		if( (newkeys & KEY_CROUCH) && !(oldkeys & KEY_CROUCH) && (GetTickCount() < playerHeightPickupTimer[playerid]) )
		{
			new Float:x, Float:y, Float:z, Float:vx, Float:vy, Float:vz;
			GetVehiclePos(playerVehicle[playerid], x, y, z);
			GetVehicleVelocity(playerVehicle[playerid], vx, vy, vz);
			SetVehiclePos(playerVehicle[playerid], x, y, z + PICKUP_HEIGHT_Z_STEP);
			SetVehicleVelocity(playerVehicle[playerid], vx, vy, vz);
			SetCameraBehindPlayer(playerid);
		}
		if( (newkeys & KEY_CROUCH) && !(oldkeys & KEY_CROUCH)  && (GetTickCount() < playerSpeedBoostTimer[playerid]) )
		{
			new Float:x, Float:y, Float:z, Float:vx, Float:vy, Float:vz;
			GetVehiclePos(playerVehicle[playerid], x, y, z);
			GetVehicleVelocity(playerVehicle[playerid], vx, vy, vz);
			SetVehiclePos(playerVehicle[playerid], x + SPEED_BOOST_STEP * vx, y + SPEED_BOOST_STEP * vy, z + SPEED_BOOST_STEP * vz);
			SetVehicleVelocity(playerVehicle[playerid], vx, vy, vz);
			SetCameraBehindPlayer(playerid);
		}
		if( (newkeys & KEY_ACTION) && (playerFighting[playerid] == IN_FIGHT) )
		{
			playerFiring[playerid] = 1;
		}
		else if( (oldkeys & KEY_ACTION) && (playerFighting[playerid] == IN_FIGHT) )
		{
			playerFiring[playerid] = 0;
		}
	}
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(playerFighting[playerid] == IN_FIGHT)
	{
		playerFighting[playerid] = REENTERING;
		DestroyVehicle(playerVehicle[playerid]);
	}
   	return 1;
}

/******************************************************
*******************************************************
***                                                 ***
***        Handling of custom SA-MP callbacks       ***
***                                                 ***
*******************************************************
*******************************************************/

public onVehicleHealthUpdate(playerid, Float:amount)
{
	new candidates[MAX_PLAYERS];
	new Float:dist[MAX_PLAYERS];
	new Float:xp, Float:yp, Float:zp, Float:xi, Float:yi, Float:zi;
	new Float:pitch, Float:roll, Float:yaw;
	
	GetPlayerPos(playerid, xp, yp, zp);
	
	//	First check if other players are in the vicinity of the player taking damage on their vehicle
	for(new i  = 0; i < MAX_PLAYERS; i++)
	{
		if( (playerid != i) && (playerFighting[i] == IN_FIGHT) && (playerFiring[i] == 1) )
		{
			GetPlayerPos(i, xi, yi, zi);
			dist[i] = floatpower(floatpower(xi - xp, 2.0) + floatpower(yi - yp, 2.0) + floatpower(zi - zp, 2.0), 1.0 / 2.0);
			if(dist[i] <= FIRING_VICINITY)
			{
				candidates[i] = 1;
			}
			else
			{
				candidates[i] = 0;
			}
		}
	}
	
	new Float:xyDist, Float:error;
	
	//	Now we check for the heading, but we can skip the candidates that were not even in the vicinity of the player taking damage
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(candidates[i] == 1)
		{
			GetVehicleRotation(playerVehicle[i], pitch, roll, yaw);
			#pragma unused roll
			GetPlayerPos(i, xi, yi, zi);
			
			// new Float:dist_ = floatpower(floatpower(xi - xp, 2.0) + floatpower(yi - yp, 2.0) + floatpower(zi - zp, 2.0), 1.0 / 2.0);
			
			xyDist = floatabs(dist[i] * floatcos(pitch, degrees));
			xi -= xyDist * floatsin(yaw, degrees);
			yi += xyDist * floatcos(yaw, degrees);
			zi += dist[i] * floatsin(pitch, degrees);
			
			error = floatpower(floatpower(xi - xp, 2.0) + floatpower(yi - yp, 2.0) + floatpower(zi - zp, 2.0), 1.0 / 2.0);
			// if(error > maxError)
			// {
				// maxError = error;
			// }
			
			if(error > FIRING_ERROR)
			{
				candidates[i] = 0;
			}
			
			// new msg[256];
			// format(msg, sizeof(msg), "Player %d, is firing at position (%f, %f, %f) at player %d, whose actual position is (%f, %f, %f).", i, xi, yi, zi, playerid, xp, yp, zp);
			// SendClientMessageToAll(COLOR_WHITE, msg);
			// format(msg, sizeof(msg), "Error: %f, max error: %f, dist: %f.", error, maxError, dist_);
			// SendClientMessageToAll(COLOR_WHITE, msg);
			// format(msg, sizeof(msg), "Yaw: %f, pitch: %f.", yaw, pitch);
			// SendClientMessageToAll(COLOR_WHITE, msg);
		}
	}
	
	//	With some smart filtering some more "non-candidates" may be filter out further.
	//	Now we assign points to all the candidates that are left
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(candidates[i] == 1)
		{
			//	Either leave this piece of code intact or add your own score handling algorithm here.
			SetPlayerScore(i, GetPlayerScore(i) + floatround(amount));
		}
	}
}

stock GetVehicleRotation(vehicleid,&Float:rx,&Float:ry,&Float:rz){
	new Float:qw,Float:qx,Float:qy,Float:qz;
	GetVehicleRotationQuat(vehicleid,qw,qx,qy,qz);
	rx = asin(2*qy*qz-2*qx*qw);
	ry = -atan2(qx*qz+qy*qw,0.5-qx*qx-qy*qy);
	rz = -atan2(qx*qy+qz*qw,0.5-qx*qx-qz*qz);
}

/******************************************************
*******************************************************
***                                                 ***
***                 Admin commands                  ***
***                                                 ***
*******************************************************
*******************************************************/

YCMD:setminhealth(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		sscanf(params, "f", minHealth);
		new msg[128];
		format(msg, sizeof(msg), "The minimum health is now %f.", minHealth);
		SendClientMessage(playerid, 0x00FF00FF, msg);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:setiat(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		sscanf(params, "d", pickupBaseIAT);
		pickupBaseIAT = pickupBaseIAT * 1000;
		new msg[128];
		format(msg, sizeof(msg), "The pickup base interarrival time is now %d seconds.", pickupBaseIAT / 1000);
		SendClientMessage(playerid, 0x00FF00FF, msg);
		calcPickupIAT();
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:jetpack(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		new Float:x, Float:y, Float:z;
		GetPlayerPos(playerid, x, y, z);
		CreatePickup(370, 4, x, y, z);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:gotopickup(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		new pickupid;
		sscanf(params, "d", pickupid);
		new Float:x = PICKUP_LOCATIONS[pickupid][0],
			Float:y = PICKUP_LOCATIONS[pickupid][1],
			Float:z = PICKUP_LOCATIONS[pickupid][2];
		SetPlayerPos(playerid, x, y, z);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:setweather(playerid, params[], help)		//	Sets the weather that occurs on a vision blur pickup
{
	if(IsPlayerAdmin(playerid))
	{
		sscanf(params, "d", visionWeatherType);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:setvehicle(playerid, params[], help)		//	Sets the vehicle type, when a player dies or enters the match they will respawn in this vehicle type
{
	if(IsPlayerAdmin(playerid))
	{
		new id;
		sscanf(params, "d", id);
		vehicleType = id;
		new msg[128];
		format(msg, sizeof(msg), "The vehicle model id is now %d.", vehicleType);
		SendClientMessage(playerid, 0x00FF00FF, msg);	
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:blur(playerid, params[], help)		//	Mimics a vision blur pickup. Implemented for testing purposes.
{
	if(IsPlayerAdmin(playerid))
	{
		new i = -1;
		sscanf(params, "d", i);
		if(i == -1)
		{
			i = playerid;
		}
		blurVisionExcludingPlayer(i);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:jam(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		new i = -1;
		sscanf(params, "d", i);
		if(i == -1)
		{
			i = playerid;
		}
		jamRadarExcludingPlayer(i);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:boost(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		new i = -1;
		sscanf(params, "d", i);
		if(i == -1)
		{
			i = playerid;
		}
		activateSpeedBoost(i);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:refuel(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		new i = -1;
		sscanf(params, "d", i);
		if(i == -1)
		{
			i = playerid;
		}
		refuelPlayerVehicle(i);
		return 1;
	}
	else
	{
		return 0;
	}
}

YCMD:repair(playerid, params[], help)
{
	if(IsPlayerAdmin(playerid))
	{
		new i = -1;
		sscanf(params, "d", i);
		if(i == -1)
		{
			i = playerid;
		}
		repairPlayerVehicle(i);
		return 1;
	}
	else
	{
		return 0;
	}
}

/******************************************************
*******************************************************
***                                                 ***
***                  User commands                  ***
***                                                 ***
*******************************************************
*******************************************************/

YCMD:joinfight(playerid, params[], help)
{
	if(playerFighting[playerid] != FREEROAM)
	{
		SendClientMessage(playerid, 0xFF0000FF, "You're already in the fight!");
	}
	else
	{
		SendClientMessage(playerid, 0xFF00FFFF, "==================== {00FF00}Welcome to the fight!{FF00FF} ====================");
		SendClientMessage(playerid, COLOR_WHITE, "The {00FFFF}blue {FFFFFF}bar displays your vehicles {FF0000}health {FFFFFF}and the {00FF00}green {FFFFFF}bar displays your {00FF00}fuel.");
		SendClientMessage(playerid, COLOR_WHITE, "The power ups shown on the minimap represent:");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Heart {FFFFFF}is to {FFFF00}refuel.");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Spraycan {FFFFFF}is to {FFFF00}repair vehicle.");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Skull {FFFFFF}is to {FFFF00}blur your oponents vision.");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Airplane {FFFFFF}is to {FFFF00}activate height pickup.");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Red cross {FFFFFF}is to {FFFF00}activate a shield.");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}R {FFFFFF}is to {FFFF00}jam your oponents radar.");
		SendClientMessage(playerid, COLOR_WHITE, "{00FFFF}Wrench {FFFFFF}is to {FFFF00}enable speed boost.");
		
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
		
		new posidVehicle;
		sscanf(params, "d", posidVehicle);
		
		if(posidVehicle == 1)
		{
			SetVehiclePos(playerVehicle[playerid], -8.7120, 1956.7133, 18.3474);
			SetVehicleZAngle(playerVehicle[playerid], 180);
		}
		else if(posidVehicle == 2)
		{
			SetVehiclePos(playerVehicle[playerid], -8.7120, 1940.7133, 18.3474);
			SetVehicleZAngle(playerVehicle[playerid], 0);
		}
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

/******************************************************
*******************************************************
***                                                 ***
***               Functional routines               ***
***                                                 ***
*******************************************************
*******************************************************/


public putPlayerInFight(playerid)
{
	new Float:x = FIGHTZONE_MIDPOINT_X + FIGHTRANGE_X * (0.5 - float(random(1000)) / 1000.0);
	new Float:y = FIGHTZONE_MIDPOINT_Y + FIGHTRANGE_Y * (0.5 - float(random(1000)) / 1000.0);
	new Float:angle = atan2(y - FIGHTZONE_MIDPOINT_Y, x - FIGHTZONE_MIDPOINT_X) + 90.0;
	
	playerFighting[playerid] = IN_FIGHT;
	playerVehicle[playerid] = CreateVehicle(vehicleType, x, y, FIGHTZONE_MIN_Z, angle, -1, -1, -1);
	playerTimer[playerid] = GetTickCount();
	playerFuel[playerid] = 100.0;
	oldVehicleHealth[playerid] = 1000.0;
	playerFuelWarning[playerid] = 0;
	PutPlayerInVehicle(playerid, playerVehicle[playerid], 0);
	SetCameraBehindPlayer(playerid);
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
	calcPickupIAT();
	return 1;
}

public calcPickupIAT()
{
	if(activePlayers == 0)
	{
		pickupIAT = pickupBaseIAT;
	}
	else
	{
		pickupIAT = pickupBaseIAT / activePlayers;
	}
}

public setDogfightMapIcons(playerid)
{
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
}

public removeDogfightMapIcons(playerid)
{
	for(new i = 0; i < AMOUNT_PICKUP_LOC; i++)
	{
		RemovePlayerMapIcon(playerid, i);
	}
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

public countDownForPlayer(playerid)
{
	playerCounter[playerid]--;
	
	if(playerCounter[playerid] <= 0)
	{
		GameTextForPlayer(playerid, "~w~Go!", 1000, 3);
	}
	else if(playerFighting[playerid] != FREEROAM)
	{
		new msg[32];
		format(msg, sizeof(msg), "~w~%d..", playerCounter[playerid]);
		GameTextForPlayer(playerid, msg, 1000, 3);
		SetTimerEx("countDownForPlayer", 1000, false, "d", playerid);
	}
}

public reenterFight(playerid)
{
	if(playerFighting[playerid] != FREEROAM)
	{
		putPlayerInFight(playerid);
	}
	TogglePlayerControllable(playerid, 1);
}

public initializeDogfight()
{
	for(new i = 0; i < MAX_PLAYERS; i = i + 1)
	{
		playerFighting[i] = 0;
		playerVehicle[i] = -1;
		playerShowWarning[i] = 0;
		playerCounter[i] = 0;
		playerFiring[i] = 0;
		playerTimer[i] = GetTickCount();
		playerUnblurtimer[i] = playerTimer[i];
		playerUnjamtimer[i] = playerTimer[i];
		playerHeightPickupTimer[i] = playerTimer[i];
		playerShieldPickupTimer[i] = playerTimer[i];
		playerSpeedBoostTimer[i] = playerTimer[i];
		playerFuelWarning[i] = 0;
		oldVehicleHealth[i] = 1000.0;
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

public activateHeightPickup(playerid)
{
	playerHeightPickupTimer[playerid] = GetTickCount() + HEIGHT_PICKUP_DURATION;
	new msg[128];
	format(msg, sizeof(msg), "~r~Height pickup activated, deactivation in %d seconds.\nPress horn (h) to gain height.", HEIGHT_PICKUP_DURATION / 1000);
	GameTextForPlayer(playerid, msg, 3000, 3);
}

public activatePlayerShield(playerid)
{
	GetVehicleHealth(playerVehicle[playerid], playerHealth[playerid]);
	new msg[128];
	format(msg, sizeof(msg), "~r~Shield activated, deactivation in %d seconds.", SHIELD_PICKUP_DURATION / 1000);
	GameTextForPlayer(playerid, msg, 3000, 3);
	playerShieldPickupTimer[playerid] = GetTickCount() + SHIELD_PICKUP_DURATION;
}

public activateSpeedBoost(playerid)
{
	new msg[128];
	format(msg, sizeof(msg), "~r~Speedboost activated, deactivation in %d seconds. Press horn (h) to accelerate.", SPEED_BOOST_DURATION / 1000);
	GameTextForPlayer(playerid, msg, 3000, 3);
	playerSpeedBoostTimer[playerid] = GetTickCount() + SPEED_BOOST_DURATION;
}

public blurVisionExcludingPlayer(playerid)
{
	new msg[64];
	new time = GetTickCount() + VISION_BLUR_DURATION;
	
	format(msg, sizeof(msg), "~r~You blurred your opponents vision for %d seconds.", VISION_BLUR_DURATION / 1000);
	GameTextForPlayer(playerid, msg, 3000, 3);
	
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if( (playerFighting[i] == 1) && (i != playerid) )
		{
			SetPlayerWeather(i, visionWeatherType);
			format(msg, sizeof(msg), "~r~Your vision has been blurred for %d seconds.", VISION_BLUR_DURATION / 1000);
			playerUnblurtimer[i] = time;
			GameTextForPlayer(i, msg, 3000, 3);
		}
	}
}

public refuelPlayerVehicle(playerid)
{
	new msg[64];
	format(msg, sizeof(msg), "~r~Your vehicle is refuelled to ~g~100%%.", VISION_BLUR_DURATION / 1000);
	GameTextForPlayer(playerid, msg, 3000, 3);
	playerFuel[playerid] = 100.0;
	playerFuelWarning[playerid] = 0;
}

public repairPlayerVehicle(playerid)
{
	new msg[64];
	format(msg, sizeof(msg), "~r~Your vehicle is repaired to ~g~100%%.", VISION_BLUR_DURATION / 1000);
	GameTextForPlayer(playerid, msg, 3000, 3);
	RepairVehicle(playerVehicle[playerid]);
}

public jamRadarExcludingPlayer(playerid)
{
	new msg[64];
	
	format(msg, sizeof(msg), "~r~You jammed your opponents radar for %d seconds.", RADAR_JAM_DURATION / 1000);
	GameTextForPlayer(playerid, msg, 3000, 3);
	
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if( (playerFighting[i] == 1) && (i != playerid) )
		{
			SetPlayerMarkerForPlayer(i, playerid, 0x0);
		}
	}
	playerUnjamtimer[playerid] = GetTickCount() + RADAR_JAM_DURATION;
}

public resetWarnings(playerid)
{
	playerShowWarning[playerid] = 0;
}