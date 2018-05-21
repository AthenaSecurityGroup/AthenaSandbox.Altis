//	MERGE TO MASTER FUNCTION
//	Merges a multidimensional relational array with the master arrays for the related type. (sub function)
fn_mergeToMaster = {
	params ["_typeArray", "_amountArray"];
	_typeArray apply {
		private ["_persArrIndex", "_arrTarget"];
		switch true do {
			case ("Mine" in (_x call BIS_fnc_itemType) || "Magazine" in (_x call BIS_fnc_itemType)): {
				//	MAGAZINES
				_persArrIndex = [persist_masterMagArr, _x] call BIS_fnc_findNestedelement;
				_amountArrayIndex = [_typeArray, _x] call BIS_fnc_findNestedelement select 0;
				_itemAmount = _amountArray select _amountArrayIndex;
				[_persArrIndex, _itemAmount, persist_masterMagArr] call fn_processMerge;
			};
			case ("Item" in (_x call BIS_fnc_itemType)): {
				//	ITEMS
				_persArrIndex = [persist_masterItemArr, _x] call BIS_fnc_findNestedelement;
				_amountArrayIndex = [_typeArray, _x] call BIS_fnc_findNestedelement select 0;
				_itemAmount = _amountArray select _amountArrayIndex;
				[_persArrIndex, _itemAmount, persist_masterItemArr] call fn_processMerge;
			};
			case ("Weapon" in (_x call BIS_fnc_itemType)): {
				//	WEAPONS
				_persArrIndex = [persist_masterWeaponsArr, _x] call BIS_fnc_findNestedelement;
				_amountArrayIndex = [_typeArray, _x] call BIS_fnc_findNestedelement select 0;
				_itemAmount = _amountArray select _amountArrayIndex;
				[_persArrIndex, _itemAmount, persist_masterWeaponsArr] call fn_processMerge;
			};
			case ("Equipment" in (_x call BIS_fnc_itemType)): {
				//	CONTAINERS
				_persArrIndex = [persist_masterContainerArr, _x] call BIS_fnc_findNestedelement;
				_amountArrayIndex = [_typeArray, _x] call BIS_fnc_findNestedelement select 0;
				_itemAmount = _amountArray select _amountArrayIndex;
				[_persArrIndex, _itemAmount, persist_masterContainerArr] call fn_processMerge;
			};
			default {
				diag_log format ["%1 defaulted", _x];
			};
		};
	};
};

//	PROCESS MERGE INTO MASTER ARRAY
//	After mergeToMaster completes its initial processing, merges the items into the array.
fn_processMerge = {
	params ["_arrIndex", "_itemAmount", "_arrTarget"];
	if (_arrIndex isEqualTo []) then {
		//	IF EMPTY, PUSHBACK INTO ARRAY
		(_arrTarget select 0) pushBack _x;
		(_arrTarget select 1) pushBack _itemAmount;
	} else {
		//	IF NOT EMPTY, INCREMENT
		_arrIndex = _arrIndex select 1;
		(_arrTarget select 1) set [_arrIndex, (_arrTarget select 1 select _arrIndex) + _itemAmount];
	};			
};

//	PROCESS WEAPONS, ITEMS, AND MAGAZINES FUNCTION
//	Process the weapons, items, and magazines in a target container and pushes them to the master array.
fn_processWeaponsItemsMags = {
	params ["_targetContainer"];
	//	GET RELATIONAL ARRAYS FOR CORE ITEMS
	_magazineCargo = getMagazineCargo _targetContainer;
	_itemCargo = getItemCargo _targetContainer;
	_weaponCargo = getWeaponCargo _targetContainer;

	//	GET WEAPON ATTACHMENTS
	_weaponsItemsCargo = weaponsItemsCargo _targetContainer;
	_weaponsItemsCargo apply {_x deleteAt 0};
	{
		_x apply {
			private ["_existingIndex", "_itemName"];
			switch true do {
				//	ITEM
				case ((typeName _x == "STRING") && {(_x != "")}): {
					_existingIndex = [_itemCargo, _x] call BIS_fnc_findNestedElement;
					//	IF ITEM ALREADY EXISTS, INCREMENT RELATIONAL ARRAY BY 1. IF NOT, ADD AN ENTRY
					if (count _existingIndex != 0) then {
						_existingIndex = _existingIndex select 1;
						(_itemCargo select 1) set [_existingIndex, (_itemCargo select 1 select _existingIndex) + 1];
					} else {
						(_itemCargo select 0) pushBack _x;
						(_itemCargo select 1) pushBack 1;
					};
				};
				//	MAGAZINE
				case ((typeName _x == "ARRAY") && {!(_x isEqualTo [])}): {
					_existingIndex = [_magazineCargo, _x select 0] call BIS_fnc_findNestedElement;
					if (count _existingIndex != 0) then {
						_existingIndex = _existingIndex select 1;
						(_magazineCargo select 1) set [_existingIndex, (_magazineCargo select 1 select _existingIndex) + 1];
					} else {
						(_magazineCargo select 0) pushBack (_x select 0);
						(_magazineCargo select 1) pushBack 1;
					};
				};
				default {};
			};
		};
	} forEach _weaponsItemsCargo;
	
	{_x call fn_mergeToMaster} forEach [_magazineCargo, _itemCargo, _weaponCargo];
};

//	PROCESS SUB CONTAINERS
//	Process the containers and contents and push them into the master array.
fn_processSubContainers = {
	params ["_targetContainer"];
	_backpackCargo = getBackpackCargo _targetContainer;
	_backpackCargo call fn_mergeToMaster;

	_everyContainer = everyContainer _targetContainer;
	_everyContainer params ["_containerType","_containerObj"];
	if !(_everyContainer isEqualTo []) then {
		[_containerType, _containerObj] apply {(_x select 1) call fn_processWeaponsItemsMags};
	};
};

//	LOAD CARGO INTO A SPECIFIC CONTAINER
fn_loadCargo = {
	params ["_targetContainer","_masterArray"];
	_masterArray params ["_typeArray","_amountArray"];
	_typeArray apply {
		switch true do {
			case ("Mine" in (_x call BIS_fnc_itemType) || "Magazine" in (_x call BIS_fnc_itemType)): {
				//	MAGAZINE
				_targetContainer addMagazineCargoGlobal [_x, _amountArray select ([_typeArray, _x] call BIS_fnc_findNestedElement select 0)];	//	, getNumber (configfile >> "CfgMagazines" >> _x >> "count")
			};
			case ("Item" in (_x call BIS_fnc_itemType)): {
				//	ITEM 
				_targetContainer addItemCargoGlobal [_x, _amountArray select ([_typeArray, _x] call BIS_fnc_findNestedElement select 0)];
			};
			case ("Weapon" in (_x call BIS_fnc_itemType)): {
				//	WEAPON
				_targetContainer addWeaponCargoGlobal [_x call BIS_fnc_baseWeapon, _amountArray select ([_typeArray, _x] call BIS_fnc_findNestedElement select 0)];
			};
			case ("Equipment" in (_x call BIS_fnc_itemType)): {
				_itemTypeArr = [];
				//	GLASSES
				_itemTypeArr pushback ("G_Balaclava_blk" in ([configfile >> "CfgGlasses" >> _x , true] call BIS_fnc_returnParents));	//	"G_Balaclava_blk"
				//	HEADGEAR
				_itemTypeArr pushback ("ItemCore" in ([configfile >> "CfgWeapons" >> _x , true] call BIS_fnc_returnParents));			//	"ItemCore"
				//	VEST
				_itemTypeArr pushback ("ItemCore" in ([configfile >> "CfgWeapons" >> _x , true] call BIS_fnc_returnParents));			//	"ItemCore"
				//	UNIFORM
				_itemTypeArr pushback ("Uniform_Base" in ([configfile >> "CfgWeapons" >> _x , true] call BIS_fnc_returnParents));		//	"Uniform_Base"
				//	BACKPACK
				_itemTypeArr pushback ("Bag_Base" in ([configfile >> "cfgVehicles" >> _x , true] call BIS_fnc_returnParents));			//	"Bag_Base"
				
				switch true do {
					case (_itemTypeArr select 0);
					case (_itemTypeArr select 1);
					case (_itemTypeArr select 2);
					case (_itemTypeArr select 3): {
						//	ADD	HEAD\VEST\UNIFORM
						_targetContainer addItemCargoGlobal [_x, _amountArray select ([_typeArray, _x] call BIS_fnc_findNestedElement select 0)];
					};
					case (_itemTypeArr select 4): {
						//	ADD BACKPACK
						_targetContainer addBackpackCargoGlobal  [_x, _amountArray select ([_typeArray, _x] call BIS_fnc_findNestedElement select 0)];
					};
					default {};
				};
			};
			default {};
		};
	};
};

//	GET ACTIVE BASES
//	Should only run on the server.
fn_saveBaseData = {
	{
		_x params ["_menuStr", "_rankAccess", "_compName", "_markerDetails", "_deployPos", "_cargoData", "_vehData"];
		//	SKIP ENTRIES WITH NO MARKER DETAILS (SMALLER BASES, NO CARGO)
		if !(isNil {_markerDetails}) then {
			//	CONSTRUCT THE MARKER NAME
			_markerName = format ["%1_M", _compName];
			if !((getMarkerPos _markerName) isEqualTo [0,0,0]) then {
				//	MARKER IS ACTIVE, START GATHERING PERSISTENCE
				//	GET POSITION
				_baseDeployPos = getMarkerPos _markerName;
				_x set [4, _baseDeployPos];
				//	GET CARGO
				_x call fn_saveBaseCargo;
				//	GET NEAR VEHICLES
				_baseDeployPos call fn_saveBaseVehicles;
			};
		};
	} forEach baseData;
	//	SAVE TO SERVER PROFILE NAMESPACE
	// profileNamespace setVariable ["baseData", baseData];
};

fn_saveBaseCargo = {
	_x params ["_menuStr", "_rankAccess", "_compName", "_markerDetails", "_deployPos", "_cargoData", "_vehData"];
	private _baseDataMaster = [];
	{
		//	FOR EACH COMP OBJECT, CHECK IF IT IS A VALID CONTAINER:
		_objParents = [configFile >> "cfgVehicles" >> typeOf _x, true] call BIS_fnc_returnParents;
		if ("ReammoBox_F" in _objParents) then {
			//	IF IT IS A VALID CONTAINER, GET ITS CONTENTS, CREATE SUB-ARRAY
			//	DEFINE MASTER ARRAYS
			persist_masterMagArr = [[],[]];
			persist_masterItemArr = [[],[]];
			persist_masterWeaponsArr = [[],[]];
			persist_masterContainerArr = [[],[]];
			persist_containerMaster = [];
			//	GET ALL CONTAINER CONTENTS
			_x call fn_processWeaponsItemsMags;
			_x call fn_processSubContainers;
			//	FORM MASTER CONTAINER ARRAY
			persist_containerMaster = [persist_masterMagArr,persist_masterItemArr,persist_masterWeaponsArr,persist_masterContainerArr];
			//	ADD EACH CONTAINER ARRAY TO THE PRIMARY DATA ARRAY FOR THE COMPOSITION
			_baseDataMaster pushBack persist_containerMaster;
		};
	} forEach ((missionNamespace getVariable _compName) call LAR_fnc_getCompObjects);
	//	PUSH THE PRIMARY DATA ARRAY INTO BASEDATA
	_baseDataIndex = [baseData, _compName] call BIS_fnc_findNestedElement select 0;
	(baseData select _baseDataIndex) set [5, _baseDataMaster];
};

fn_saveBaseVehicles = {};

fn_loadBaseData = {
	{
		_x params ["_menuStr", "_rankAccess", "_compName", "_markerDetails", "_deployPos", "_cargoData", "_vehData"];
		//	IF DEPLOYPOS HAS DATA, THE BASE WAS ACTIVE, AND NEEDS TO BE RELOADED.
		if !(isNil {_deployPos} || {_deployPos isEqualTo []}) then {
			//	RE-DEPLOY THE BASE AT THE POSITION FROM MEMORY.
			//	LOAD CARGO INTO CARGO CONTAINERS.
			private _containerCounter = 0;
			{
				_objParents = [configFile >> "cfgVehicles" >> typeOf _x, true] call BIS_fnc_returnParents;
				if ("ReammoBox_F" in _objParents) then {
					_currentContainer = _x;
					//	CLEAR FOR INSERTION.
					clearWeaponCargoGlobal _x;
					clearMagazineCargoGlobal _x;
					clearItemCargoGlobal _x;
					clearBackpackCargoGlobal _x;
					uiSleep 0.05;
					//	ADD TO CONTAINER FROM CARGO DATA ARRAY
					{
						[_currentContainer, _x] call fn_loadCargo;
					} forEach (_cargoData select _containerCounter);
					//	+1 FOR CARGO DATA INDEXING
					_containerCounter = _containerCounter + 1;
				};
			} forEach ((missionNamespace getVariable _compName) call LAR_fnc_getCompObjects);
			//	RELOAD VEHICLES IN THE VICINITY.
		};
	//	TO DO: CHANGE missionNamespace TO profileNamespace
	} forEach (missionNamespace getVariable "baseData");
};

//	DEBUG SCRIPT

//	SAVE PERSISTENCE DATA
call fn_saveBaseData;
//	CLEAR THE CARGO, FOR DEBUGGING
//	DELETE NEARBY VEHICLES
uiSleep 2;
//	UNDEPLOY THE BASE
//	LOAD PERSISTENCE DATA
call fn_loadBaseData;
