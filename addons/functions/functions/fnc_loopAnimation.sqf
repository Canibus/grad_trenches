#include "script_component.hpp"
params ["_unit"];

[_unit, "AinvPknlMstpSnonWnonDnon_medic4"] call ace_common_fnc_doAnimation;

[
	_unit, 
	"AnimDone", 
	{
		params ["_unit", "_anim"];

		if (
			!(_unit getVariable [QGVAR(diggingTrench), false])
		) exitWith {
			_unit removeEventHandler ["AnimDone", _thisID];
		};

		if (_anim == "AinvPknlMstpSnonWnonDnon_medic4") then {
			[_unit, _anim] call ace_common_fnc_doAnimation;
		};
	}
] call CBA_fnc_addBISEventHandler;