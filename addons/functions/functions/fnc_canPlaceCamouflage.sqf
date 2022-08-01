#include "script_component.hpp"
/*
* Author: chris579
* Checks if camouflage can be applied to a trench.
*
* Arguments:
* 0: Trench <OBJECT>
* 1: Unit <OBJECT>
*
* Return Value:
* Can place <BOOL>
*
* Example:
* [TrenchObj] call grad_trenches_functions_fnc_canPlaceCamouflage
*
* Public: No
*/

params ["_trench", "_unit"];

private _statusNumber = _trench getVariable [QGVAR(trenchCamouflageStatus), 0];
private _statusString = "CamouflagePositions" + str (_statusNumber + 1);

if !(GVAR(allowCamouflage)) exitWith {false};
if (GVAR(camouflageRequireEntrenchmentTool) && {!("ACE_EntrenchingTool" in items _unit)}) exitWith {false};

private _config = configOf _trench >> _statusString;

(isClass _config) &&
{count (getArray (configFile >> "CfgWorldsTextures" >> worldName >> "camouflageObjects")) > 0} &&
{count (configProperties [_config]) > 0} &&
{_trench getVariable ["ace_trenches_progress", 0] == 100}
