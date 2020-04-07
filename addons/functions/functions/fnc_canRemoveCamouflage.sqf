#include "script_component.hpp"
/*
* Author: chris579
* Checks if camouflage can be removed from trench.
*
* Arguments:
* 0: Trench <OBJECT>
*
* Return Value:
* Can remove <BOOL>
*
* Example:
* [TrenchObj] call grad_trenches_functions_fnc_canPlaceCamouflage
*
* Public: No
*/

params ["_trench"];

if !(GVAR(allowCamouflage)) exitWith {false};
(count (_trench getVariable [QGVAR(camouflageObjects), []]) > 0)
