 #include "script_component.hpp"
/*
 * Author: Garth 'L-H' de Wet, Ruthberg, edited by commy2 for better MP and eventual AI support and esteldunedain, Salbei
 * Removes trench.
 *
 * Arguments:
 * 0: Trench <OBJECT>
 * 1: Unit <OBJECT>
 * 2: SwitchingDigger <BOOLEAN> (optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * [TrenchObj, ACE_player] call grad_trenches_legacy_fnc_removeTrench
 *
 * Public: No
 */

params ["_trench", "_unit", ["_switchingDigger", false, [true]]];
TRACE_2("removeTrench",_trench,_unit,_switchingDigger);

private _actualProgress = _trench getVariable ["ace_trenches_progress", 0];
if (_actualProgress <= 0) exitWith {};

// Mark trench as being worked on
_trench setVariable ["ace_trenches_digging", true, true];
_trench setVariable [QGVAR(diggingType), "DOWN", true];
_unit setVariable [QGVAR(diggingTrench), true, true];

private _diggerCount = count (_trench getVariable [QGVAR(diggers), []]);

if (_diggerCount > 0 && {!_switchingDigger}) exitWith {
    [_trench, _unit] call EFUNC(common,addDigger);
};

private _removeTime = missionNamespace getVariable [getText (configOf _trench >> "ace_trenches_removalDuration"), 20];

if (_removeTime isEqualTo -1) then {
    _removeTime = missionNamespace getVariable [getText (configOf _trench >> "ace_trenches_diggingDuration"), 20];
};

_trench setVariable [QGVAR(diggers), [_unit], true];

// Create progress bar
private _fnc_onFinish = {
    (_this select 0) params ["_unit", "_trench"];

    [_trench, _unit] call EFUNC(common,deleteTrench);

    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;
};
private _fnc_onFailure = {
    (_this select 0) params ["_unit", "_trench"];

    _trench setVariable ["ace_trenches_digging", false, true];
    _trench setVariable [QGVAR(diggingType), nil, true];
    _unit setVariable [QGVAR(diggingTrench), false, true];
    [QEGVAR(common,handleDiggerToGVAR), [_trench, _unit, true]] call CBA_fnc_serverEvent;

    // Save progress global
    private _progress = _trench getVariable ["ace_trenches_progress", 0];
    _trench setVariable ["ace_trenches_progress", _progress, true];

    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;

    // Reset decay
    [QEGVAR(common,resetDecay), [_trench]] call CBA_fnc_serverEvent;
};
private _fnc_condition = {
    (_this select 0) params ["", "_trench"];

    if !(_trench getVariable ["ace_trenches_digging", false]) exitWith {false};
    if (count (_trench getVariable [QGVAR(diggers), []]) <= 0) exitWith {false};
    if (GVAR(stopBuildingAtFatigueMax) && {ace_advanced_fatigue_anReserve <= 0}) exitWith {false};

    true
};

[[_unit, _trench, false], _fnc_onFinish, _fnc_onFailure, localize "STR_ace_trenches_RemovingTrench", _fnc_condition] call EFUNC(common,progressBar);

[{
    params ["_args", "_handle"];
    _args params ["_trench", "_unit", "_removeTime"];

    private _actualProgress = _trench getVariable ["ace_trenches_progress", 0];
    private _diggerCount = count (_trench getVariable [QGVAR(diggers), []]);

    if (
        !(_trench getVariable ["ace_trenches_digging", false]) ||
        {_diggerCount <= 0}
    ) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        _trench setVariable ["ace_trenches_digging", false, true];
        [QEGVAR(common,handleDiggerToGVAR), [_trench, _unit, false, true]] call CBA_fnc_serverEvent;
    };

    if (_actualProgress <= 0) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    private _newProgress = _actualProgress - (_diggerCount / _removeTime);

    [_trench, _newProgress, 1.5] call EFUNC(common,setTrenchProgress); // not too fast so animation is still visible
    [QEGVAR(common,applyFatigue), [_trench, _unit], _unit] call CBA_fnc_targetEvent;

    // Show special effects
    if (GVAR(allowEffects)) then {
        [QEGVAR(common,digFX), [_trench]] call CBA_fnc_globalEvent;

        [_trench] call EFUNC(common,playSound);
    };
}, 1, [_trench, _unit, _removeTime]] call CBA_fnc_addPerFrameHandler;

// Play animation
[_unit] call EFUNC(common,loopanimation);
