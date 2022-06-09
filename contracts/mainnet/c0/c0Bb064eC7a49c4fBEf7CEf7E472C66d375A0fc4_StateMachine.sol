/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: StateMachine.sol

library StateMachine {
    struct State {
        string name;
        bytes data;
        mapping(string => bool) transitions;
    }

    struct States {
        string initialState;
        mapping(string => State) states;
    }

    function initialize(
        States storage _stateMachine,
        string memory _startStateName,
        bytes memory _data
    ) external {
        require(bytes(_startStateName).length > 0);
        require(bytes(_stateMachine.initialState).length == 0);
        State storage startState = _stateMachine.states[_startStateName];
        require(!_isValid(startState));
        _stateMachine.initialState = _startStateName;
        startState.name = _startStateName;
        startState.data = _data;
    }

    function initialStateName(States storage _stateMachine)
        external
        view
        returns (string memory)
    {
        return _stateMachine.initialState;
    }

    function addStateTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState,
        bytes memory _data
    ) external {
        require(bytes(_toState).length > 0, "Missing to state");
        State storage fromState = _stateMachine.states[_fromState];
        require(_isValid(fromState), "Invalid from state");
        require(!fromState.transitions[_toState], "Transition already exists");

        State storage toState = _stateMachine.states[_toState];
        toState.name = _toState;
        toState.data = _data;
        fromState.transitions[_toState] = true;
    }

    function setStateData(
        States storage _stateMachine,
        string memory _stateName,
        bytes memory _data
    ) external {
        State storage state = _stateMachine.states[_stateName];
        require(_isValid(state));
        state.data = _data;
    }

    function getStateData(
        States storage _stateMachine,
        string memory _stateName
    ) external view returns (bytes memory) {
        State storage state = _stateMachine.states[_stateName];
        require(_isValid(state));
        return state.data;
    }

    function isValidTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState
    ) external view returns (bool) {
        return _stateMachine.states[_fromState].transitions[_toState];
    }

    function _isValid(State storage _state) private view returns (bool) {
        return bytes(_state.name).length > 0;
    }
}