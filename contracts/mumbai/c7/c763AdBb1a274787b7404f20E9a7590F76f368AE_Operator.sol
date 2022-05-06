// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { IFismoOperate } from "./interfaces/IFismoOperate.sol";
import { FismoConstants } from "./domain/FismoConstants.sol";
import { FismoTypes } from "./domain/FismoTypes.sol";

/**
 * @title Operator
 *
 * This is a basic, cloneable, Fismo operator contract.
 * Anyone can invoke actions.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract Operator is FismoConstants {

    /// Emitted when a user clones the Operator contract
    event OperatorCloned(
        address indexed clonedBy,
        address indexed clone,
        address indexed fismo
    );

    /// The Fismo instance to invoke actions upon
    IFismoOperate private fismo;

    /// Is this the original Operator instance or a clone?
    bool private isOperator;

    /**
     * @notice Constructor
     *
     * Note:
     * - Only executed in an actual contract deployment
     * - Clones have their init() method called to do same
     *
     * @param _fismo - address of the Fismo instance
     */
    constructor(address _fismo) payable {
        initialize(_fismo, true);
    }

    /**
     * @notice Initialize a cloned Operator instance.
     *
     * Reverts if:
     * - Current Fismo address is not the zero address
     *
     * Note:
     * - Must be external to be called from the Operator factory.
     * - Sets `isOperator` to false, so that `cloneOperator` will revert.
     *
     * @param  _fismo - address of the Fismo instance
     */
    function init(address _fismo)
    external
    {
        require(address(fismo) == address(0), ALREADY_INITIALIZED);
        initialize(_fismo, false);
    }

    /**
     * @notice Initialize Operator contract
     *
     * @param  _fismo - address of the Fismo instance
     * @param  _isOperator - are we initializing the a just-deployed instance?
     */
    function initialize(address _fismo, bool _isOperator) internal {
        fismo = IFismoOperate(_fismo);
        isOperator = _isOperator;
    }

    /**
     * Invoke a Fismo action
     *
     * Note:
     * - In this basic implementation anyone can invoke actions
     *
     * @param _machineId - the id of the target machine
     * @param _actionId - the id of the action to invoke
     *
     * @return response - the response message. see {FismoTypes.ActionResponse}
     */
    function invokeAction(bytes4 _machineId, bytes4 _actionId)
    external
    returns(FismoTypes.ActionResponse memory response) {
        response = fismo.invokeAction(msg.sender, _machineId, _actionId);
    }

    /**
     * @notice Deploys and returns the address of an Operator clone.
     *
     * Emits:
     * - OperatorCloned
     *
     * @param _fismo - the address of the Fismo instance to operate
     * @return instance - the address of the Operator clone instance
     */
    function cloneOperator(address _fismo)
    external
    returns (address instance)
    {
        // Make sure this isn't a clone
        require(isOperator, MULTIPLICITY);

        // Clone the contract
        instance = clone();

        // Initialize the clone
        Operator(instance).init(_fismo);

        // Notify watchers of state change
        emit OperatorCloned(msg.sender, instance, _fismo);
    }

    /**
     * @dev Deploys and returns the address of an Operator clone
     *
     * Note:
     * - This function uses the create opcode, which should never revert.
     *
     * @return instance - the address of the Fismo clone
     */
    function clone()
    internal
    returns (address instance) {

        // Clone this contract
        address implementation = address(this);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoTypes } from "../domain/FismoTypes.sol";

/**
 * @title FismoOperate
 *
 * @notice Operate Fismo state machines
 * The ERC-165 identifier for this interface is 0xcad6b576
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IFismoOperate {

    /// Emitted when a user transitions from one State to another.
    event UserTransitioned(
        address indexed user,
        bytes4 indexed machineId,
        bytes4 indexed newStateId,
        FismoTypes.ActionResponse response
    );

    /**
     * Invoke an action on a configured Machine.
     *
     * Reverts if
     * - Caller is not the machine's operator (contract or EOA)
     * - Machine does not exist
     * - Action is not valid for the user's current State in the given Machine
     * - Any invoked Guard logic reverts
     *
     * @param _user - the address of the user
     * @param _machineId - the id of the target machine
     * @param _actionId - the id of the action to invoke
     *
     * @return response - the response from the action. See {FismoTypes.ActionResponse}
     */
    function invokeAction(
        address _user,
        bytes4 _machineId,
        bytes4 _actionId
    )
    external
    returns(
        FismoTypes.ActionResponse memory response
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title FismoConstants
 *
 * @notice Constants used by the Fismo protocol
 */
contract FismoConstants {

    // Revert Reasons
    string internal constant MULTIPLICITY = "Can't clone a clone";

    string internal constant ALREADY_INITIALIZED = "Already initialized";

    string internal constant ONLY_OWNER = "Only owner may call";
    string internal constant ONLY_OPERATOR = "Only operator may call";

    string internal constant MACHINE_EXISTS = "Machine already exists";
    string internal constant STATE_EXISTS = "State already exists";

    string internal constant NO_SUCH_GUARD = "No such guard";
    string internal constant NO_SUCH_MACHINE = "No such machine";
    string internal constant NO_SUCH_STATE = "No such state";
    string internal constant NO_SUCH_ACTION = "No such action";

    string internal constant INVALID_ADDRESS = "Invalid address";
    string internal constant INVALID_OPERATOR_ADDR = "Invalid operator address";
    string internal constant INVALID_MACHINE_ID = "Invalid machine id";
    string internal constant INVALID_STATE_ID = "Invalid state id";
    string internal constant INVALID_ACTION_ID = "Invalid action id";
    string internal constant INVALID_TARGET_ID = "Invalid target state id";

    string internal constant CODELESS_INITIALIZER = "Initializer address not a contract";
    string internal constant INITIALIZER_REVERTED = "Initializer function reverted, no reason given";
    string internal constant CODELESS_GUARD = "Guard address not a contract";
    string internal constant GUARD_REVERTED = "Guard function reverted, no reason given";

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title FismoTypes
 *
 * @notice Enums and structs used by Fismo
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoTypes {

    enum Guard {
        Enter,
        Exit,
        Filter
    }

    struct Machine {
        address operator;         // address of approved operator (can be contract or EOA)
        bytes4 id;                // keccak256 hash of machine name
        bytes4 initialStateId;    // keccak256 hash of initial state
        string name;              // name of machine
        string uri;               // off-chain URI of metadata describing the machine
        State[] states;           // all of the valid states for this machine
    }

    struct State {
        bytes4 id;                // keccak256 hash of state name
        string name;              // name of state. begin with letter, no spaces, a-z, A-Z, 0-9, and _
        bool exitGuarded;         // is there an exit guard?
        bool enterGuarded;        // is there an enter guard?
        address guardLogic;       // address of guard logic contract
        Transition[] transitions; // all of the valid transitions from this state
    }

    struct Position {
        bytes4 machineId;         // keccak256 hash of machine name
        bytes4 stateId;           // keccak256 hash of state name
    }

    struct Transition {
        bytes4 actionId;          // keccak256 hash of action name
        bytes4 targetStateId;     // keccak256 hash of target state name
        string action;            // Action name. no spaces, only a-z, A-Z, 0-9, and _
        string targetStateName;   // Target State name. begin with letter, no spaces, a-z, A-Z, 0-9, and _
    }

    struct ActionResponse {
        string machineName;        // name of machine
        string action;             // name of action that triggered the transition
        string priorStateName;     // name of prior state
        string nextStateName;      // name of new state
        string exitMessage;        // response from the prior state's exit guard
        string enterMessage;       // response from the new state's enter guard
    }

}