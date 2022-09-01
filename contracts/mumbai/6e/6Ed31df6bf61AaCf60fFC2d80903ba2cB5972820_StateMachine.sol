// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @notice An implementation of a Finite State Machine.
 * @dev A State has a name, some arbitrary data, and a set of
 *   valid transitions.
 * @dev A State Machine has an initial state and a set of states.
 */
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

    /**
     * @dev You must call this before using the state machine.
     * @dev creates the initial state.
     * @param _startStateName The name of the initial state.
     * @param _data The data for the initial state.
     *
     * Requirements:
     * - The state machine MUST NOT already have an initial state.
     * - `_startStateName` MUST NOT be empty.
     * - `_startStateName` MUST NOT be the same as an existing state.
     */
    function initialize(
        States storage _stateMachine,
        string memory _startStateName,
        bytes memory _data
    ) external {
        require(bytes(_startStateName).length > 0, "invalid state name");
        require(
            bytes(_stateMachine.initialState).length == 0,
            "already initialized"
        );
        State storage startState = _stateMachine.states[_startStateName];
        require(!_isValid(startState), "duplicate state");
        _stateMachine.initialState = _startStateName;
        startState.name = _startStateName;
        startState.data = _data;
    }

    /**
     * @dev Returns the name of the iniital state.
     */
    function initialStateName(States storage _stateMachine)
        external
        view
        returns (string memory)
    {
        return _stateMachine.initialState;
    }

    /**
     * @dev Creates a new state transition, creating
     *   the "to" state if necessary.
     * @param _fromState the "from" side of the transition
     * @param _toState the "to" side of the transition
     * @param _data the data for the "to" state
     *
     * Requirements:
     * - `_fromState` MUST be the name of a valid state.
     * - There MUST NOT aleady be a transition from `_fromState`
     *   and `_toState`.
     * - `_toState` MUST NOT be empty
     * - `_toState` MAY be the name of an existing state. In
     *   this case, `_data` is ignored.
     * - `_toState` MAY be the name of a non-existing state. In
     *   this case, a new state is created with `_data`.
     */
    function addStateTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState,
        bytes memory _data
    ) external {
        require(bytes(_toState).length > 0, "Missing to state");
        State storage fromState = _stateMachine.states[_fromState];
        require(_isValid(fromState), "invalid from state");
        require(!fromState.transitions[_toState], "duplicate transition");

        State storage toState = _stateMachine.states[_toState];
        if (!_isValid(toState)) {
            toState.name = _toState;
            toState.data = _data;
        }
        fromState.transitions[_toState] = true;
    }

    /**
     * @dev Removes a transtion. Does not remove any states.
     * @param _fromState the "from" side of the transition
     * @param _toState the "to" side of the transition
     *
     * Requirements:
     * - `_fromState` and `toState` MUST describe an existing transition.
     */
    function deleteStateTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState
    ) external {
        require(
            _stateMachine.states[_fromState].transitions[_toState],
            "invalid transition"
        );
        _stateMachine.states[_fromState].transitions[_toState] = false;
    }

    /**
     * @dev Update the data for a state.
     * @param _stateName The state to be updated.
     * @param _data The new data
     *
     * Requirements:
     * - `_stateName` MUST be the name of a valid state.
     */
    function setStateData(
        States storage _stateMachine,
        string memory _stateName,
        bytes memory _data
    ) external {
        State storage state = _stateMachine.states[_stateName];
        require(_isValid(state), "invalid state");
        state.data = _data;
    }

    /**
     * @dev Returns the data for a state.
     * @param _stateName The state to be queried.
     *
     * Requirements:
     * - `_stateName` MUST be the name of a valid state.
     */
    function getStateData(
        States storage _stateMachine,
        string memory _stateName
    ) external view returns (bytes memory) {
        State storage state = _stateMachine.states[_stateName];
        require(_isValid(state), "invalid state");
        return state.data;
    }

    /**
     * @dev Returns true if the parameters describe a valid
     *   state transition.
     * @param _fromState the "from" side of the transition
     * @param _toState the "to" side of the transition
     */
    function isValidTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState
    ) external view returns (bool) {
        return _stateMachine.states[_fromState].transitions[_toState];
    }

    /**
     * @dev Returns true if the state exists.
     * @param _stateName The state to be queried.
     */
    function isValidState(
        States storage _stateMachine,
        string memory _stateName
    ) external view returns (bool) {
        return _isValid(_stateMachine.states[_stateName]);
    }

    function _isValid(State storage _state) private view returns (bool) {
        return bytes(_state.name).length > 0;
    }
}