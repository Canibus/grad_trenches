#include "script_component.hpp"
/*
 * Author: Garth 'L-H' de Wet, Ruthberg, edited by commy2 for better MP and eventual AI support, esteldunedain, Salbei
 * Continue process of digging trench.
 *
 * Arguments:
 * 0: Trench <OBJECT>
 * 1: Unit <OBJECT>
 * 2: SwitchingDigger <BOOLEAN>
 *
 * Return Value:
 * None
 *
 * Example:
 * [TrenchObj, ACE_player] call ace_trenches_fnc_continueDiggingTrench
 *
 * Public: No
 */

params ["_trench", "_unit", ["_switchingDigger", false, [true]]];
TRACE_2("continueDiggingTrench", _trench, _unit, _switchingDigger);

private _actualProgress = _trench getVariable ["ace_trenches_progress", 0];
if (_actualProgress >= 1) exitWith {};

// Mark trench as being worked on
_trench setVariable ["ace_trenches_digging", true, true];
_trench setVariable [QGVAR(diggingType), "UP", true];
_unit setVariable [QGVAR(diggingTrench), true];

private _diggerCount = count (_trench getVariable [QGVAR(diggers), []]);

if (_diggerCount > 0 && {!(_switchingDigger)}) exitWith {
    [_trench, _unit] call FUNC(addDigger);
};

private _digTime = missionNamespace getVariable [getText (configFile >> "CfgVehicles" >> (typeOf _trench) >>"ace_trenches_diggingDuration"), 20];
private _placeData = _trench getVariable ["ace_trenches_placeData", [[], []]];
_placeData params ["", "_vecDirAndUp"];

if (isNil "_vecDirAndUp") then {
    _vecDirAndUp = [vectorDir _trench, vectorUp _trench];
};

_trench setVariable [QGVAR(diggers), [_unit]];


// Create progress bar
private _fnc_onFinish = {
    (_this select 0) params ["_unit", "_trench"];
    _trench setVariable ["ace_trenches_digging", false, true];
    _trench setVariable [QGVAR(diggingType), nil, true];
    _unit setVariable [QGVAR(diggingTrench), false];
    [QGVAR(addDigger), [_trench, _unit, false, true]] call CBA_fnc_serverEvent;
    [QGVAR(handleDiggingServer), [_trench, _unit, false, true]] call CBA_fnc_serverEvent;

    // Save progress global
    _trench setVariable ["ace_trenches_progress", 1, true];

    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;
};
private _fnc_onFailure = {
    (_this select 0) params ["_unit", "_trench"];
    _trench setVariable ["ace_trenches_digging", false, true];
    _trench setVariable [QGVAR(diggingType), nil, true];
    _unit setVariable [QGVAR(diggingTrench), false];
    [QGVAR(addDigger), [_trench, _unit, true]] call CBA_fnc_serverEvent;

    // Save progress global
    private _progress = _trench getVariable ["ace_trenches_progress", 0];
    _trench setVariable ["ace_trenches_progress", _progress, true];
    [QGVAR(handleDiggingServer), [_trench, _unit, false, true]] call CBA_fnc_serverEvent;

    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;
};
private _fnc_condition = {
    (_this select 0) params ["", "_trench"];

    if !(_trench getVariable ["ace_trenches_digging", false]) exitWith {false};
    if (count (_trench getVariable [QGVAR(diggers),[]]) <= 0) exitWith {false};
    if (GVAR(stopBuildingAtFatigueMax) && (ace_advanced_fatigue_anReserve <= 0)) exitWith {false};
    true
};

[[_unit, _trench], _fnc_onFinish, _fnc_onFailure, localize "STR_ace_trenches_DiggingTrench", _fnc_condition] call FUNC(progressBar);
[QGVAR(handleDiggingServer), [_trench, _unit, true, true]] call CBA_fnc_serverEvent;

if (_actualProgress == 0) then {
    //Remove grass
    {
        private _trenchGrassCutter = createVehicle ["Land_ClutterCutter_medium_F", [0, 0, 0], [], 0, "NONE"];
        private _cutterPos = AGLToASL (_trench modelToWorld _x);
        _cutterPos set [2, getTerrainHeightASL _cutterPos];
        _trenchGrassCutter setPosASL _cutterPos;
        deleteVehicle _trenchGrassCutter;
    } foreach getArray (configFile >> "CfgVehicles" >> (typeOf _trench) >> "ace_trenches_grassCuttingPoints");
};

[{
    params ["_args", "_handle"];
    _args params ["_trench", "_unit", "_digTime", "_vecDirAndUp"];
    private _actualProgress = _trench getVariable ["ace_trenches_progress", 0];
    private _diggerCount = count (_trench getVariable [QGVAR(diggers),[]]);

    //systemChat format ["Dig: %1, Count: %2, Progress: %3", _trench getVariable ["ace_trenches_digging", false], _diggerCount , _actualProgress];

    if (
        !(_trench getVariable ["ace_trenches_digging", false]) ||
        {_diggerCount <= 0}
    ) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        _trench setVariable ["ace_trenches_digging", false, true];
        [QGVAR(addDigger), [_trench, _unit, true]] call CBA_fnc_serverEvent;
    };

    if (_actualProgress >= 1) exitWith {
        systemChat str(getPosWorld _trench);
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    private _pos = (getPosWorld _trench);
    private _posDiff = (_trench getVariable [QGVAR(diggingSteps), 0]) * _diggerCount;

    systemChat format ["Diff: %1, Steps: %2", (_trench getVariable [QGVAR(diggingSteps), 0]) * _diggerCount, _trench getVariable [QGVAR(diggingSteps), 0]];
 
    _pos set [2,((_pos select 2) + _posDiff)];

    systemChat format ["%1", _pos];

    _trench setPosWorld _pos;
    _trench setVectorDirAndUp _vecDirAndUp;

    //Fatigue impact
    ace_advanced_fatigue_anReserve = (ace_advanced_fatigue_anReserve - ((_digTime /12) * GVAR(buildFatigueFactor))) max 0;
    ace_advanced_fatigue_anFatigue = (ace_advanced_fatigue_anFatigue + (((_digTime/12) * GVAR(buildFatigueFactor))/1200)) min 1;

    if (GVAR(stopBuildingAtFatigueMax) && (ace_advanced_fatigue_anReserve <= 0)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        _trench setVariable ["ace_trenches_digging", false, true];
        [QGVAR(addDigger), [_trench, _unit, true]] call CBA_fnc_serverEvent;
        _unit setVariable [QGVAR(diggingTrench), false];
    };
},0.1,[_trench, _unit, _digTime, _vecDirAndUp]] call CBA_fnc_addPerFrameHandler;

// Play animation
[_unit] call FUNC(loopanimation);
