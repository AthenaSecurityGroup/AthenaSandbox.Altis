//	SERVER PARAMS
setViewDistance 2000;												//	Max View distance.
{_x disableTIEquipment true;} forEach (allMissionObjects "All");	//	Disable thermals.
{_x disableNVGEquipment true;} forEach (allMissionObjects "All");	//	Disable NVGs.
enableEngineArtillery false;										//	Disable auto-calculated artillery.

//	DEDICATED SERVER, OR PLAYER-HOST
if (isServer) then {
	//	INIT PLAYER DISCONNECT EVENT HANDLER
	call ASG_fnc_initAPDH;
	
	//	ACDEP INITIALIZATIOn (SERVER)
	call ASG_fnc_initCampaignStart;
	
	//	ALOC QUEUE WATCHER
	call ASG_fnc_alocInit;

	//	INIT PLAYER DATABASE
	ASG_pDB = [
		["Diffusion9","76561197972564938",99,""],
		["DEL-J","76561198031485127",99,""],
		["jmlane","76561197967188494",99,""]
	];
};

//	INITIALIZE ABDEP
call ASG_fnc_initDeployment;

//	INITIALIZE DYNAMIC GROUPS
call ASG_fnc_initADYN;

//	INITIALIZE ARCS
call ASG_fnc_ARCSinit;
