// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: StateMachine.sol

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

// File: Strings.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: Monotonic.sol

// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

/**
@notice Provides monotonic increasing and decreasing values, similar to
OpenZeppelin's Counter but (a) limited in direction, and (b) allowing for steps
> 1.
 */
library Monotonic {
    using SafeMath for uint256;

    /**
    @notice Holds a value that can only increase.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and add().
     */
    struct Increaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Increaser.
    function current(Increaser storage incr) internal view returns (uint256) {
        return incr.value;
    }

    /// @notice Adds x to the Increaser's value.
    function add(Increaser storage incr, uint256 x) internal {
        incr.value += x;
    }

    /**
    @notice Holds a value that can only decrease.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and subtract().
     */
    struct Decreaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Decreaser.
    function current(Decreaser storage decr) internal view returns (uint256) {
        return decr.value;
    }

    /// @notice Subtracts x from the Decreaser's value.
    function subtract(Decreaser storage decr, uint256 x) internal {
        decr.value -= x;
    }

    struct Counter{
        uint256 value;
    }

    function current(Counter storage _counter) internal view returns (uint256) {
        return _counter.value;
    }

    function add(Counter storage _augend, uint256 _addend) internal returns (uint256) {
        _augend.value += _addend;
        return _augend.value;
    }

    function subtract(Counter storage _minuend, uint256 _subtrahend) internal returns (uint256) {
        _minuend.value -= _subtrahend;
        return _minuend.value;
    }

    function increment(Counter storage _counter) internal returns (uint256) {
        return add(_counter, 1);
    }

    function decrement(Counter storage _counter) internal returns (uint256) {
        return subtract(_counter, 1);
    }

    function reset(Counter storage _counter) internal {
        _counter.value = 0;
    }
}

// File: DropManagement.sol

struct Drop {
    string dropName;
    uint32 dropStartTime;
    uint32 dropSize;
    string baseURI;
}

library DropManagement {
    using Strings for string;
    using StateMachine for StateMachine.States;
    using Monotonic for Monotonic.Counter;

    event DropAnnounced(Drop drop);
    event DropEnded(Drop drop);
    event URI(string value, uint256 indexed id);
    event StateChange(
        uint256 indexed tokenId,
        string fromState,
        string toState
    );

    struct ManagedDrop {
        Drop drop;
        Monotonic.Counter mintCount;
        bool active;
        StateMachine.States stateMachine;
        mapping(uint256 => string) stateForToken;
    }

    struct DropManager {
        uint256 maxSupply;
        Monotonic.Counter mintCount;
        bool requireCategory;
        string baseURI;
        string[] allDropNames;
        Monotonic.Counter tokensReserved;
        mapping(uint256 => string) customURIs;
        mapping(string => ManagedDrop) dropByName;
        mapping(uint256 => string) dropNameByTokenId;
    }

    modifier validDropName(DropManager storage mgr, string memory dropName) {
        if (bytes(dropName).length > 0 || mgr.requireCategory) {
            require(
                _isRealDrop(mgr.dropByName[dropName].drop),
                "invalid category"
            );
        }
        _;
    }

    modifier realDrop(DropManager storage mgr, string memory dropName) {
        require(_isRealDrop(mgr.dropByName[dropName].drop), "invalid category");
        _;
    }

    modifier validBaseURI(string memory baseURI) {
        require(bytes(baseURI).length > 0, "empty base uri");
        _;
    }

    function initMaxSupply(DropManager storage mgr, uint256 _maxSupply)
        external
    {
        mgr.maxSupply = _maxSupply;
    }

    function setRequireCategory(DropManager storage mgr, bool _required)
        external
    {
        mgr.requireCategory = _required;
    }

    function getMaxSupply(DropManager storage mgr)
        external
        view
        returns (uint256)
    {
        return mgr.maxSupply;
    }

    function totalAvailable(DropManager storage mgr)
        public
        view
        returns (uint256)
    {
        return
            mgr.maxSupply -
            mgr.mintCount.current() -
            mgr.tokensReserved.current();
    }

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     * @param dropName The name of the drop
     *
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be the
     *    remaining supply for the entire collection minus the number reserved by active drops.
     */
    function amountRemainingInDrop(
        DropManager storage mgr,
        string memory dropName
    ) external view returns (uint256) {
        if (bytes(dropName).length == 0) {
            return totalAvailable(mgr);
        }

        ManagedDrop storage currentDrop = mgr.dropByName[dropName];
        if (!currentDrop.active) {
            return 0;
        }

        return _remaining(currentDrop);
    }

    /**
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be 0.
     *
     * @param _dropName The name of the drop
     */
    function dropMintCount(DropManager storage mgr, string memory _dropName)
        external
        view
        returns (uint256)
    {
        return mgr.dropByName[_dropName].mintCount.current();
    }

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount(DropManager storage mgr)
        external
        view
        returns (uint256)
    {
        return mgr.allDropNames.length;
    }

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(DropManager storage mgr, string memory _dropName)
        external
        view
        returns (Drop memory)
    {
        return mgr.dropByName[_dropName].drop;
    }

    /**
     * @dev Return the name of a drop at `_index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(DropManager storage mgr, uint256 _index)
        external
        view
        returns (string memory)
    {
        return mgr.allDropNames[_index];
    }

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * nor been stopped manually.
     * @dev Returns true if the `_dropName` refers to an active drop.
     */
    function isDropActive(DropManager storage mgr, string memory _dropName)
        external
        view
        returns (bool)
    {
        return mgr.dropByName[_dropName].active;
    }

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be he concatenation of the `baseURI` and the `tokenId`.
     */
    function getBaseURI(DropManager storage mgr)
        external
        view
        returns (string memory)
    {
        return mgr.baseURI;
    }

    /**
     * @notice This sets the baseURI for any tokens minted outside of a drop.
     */
    function setBaseURI(DropManager storage mgr, string memory baseURI)
        external
    {
        mgr.baseURI = baseURI;
    }

    /**
     * @dev Change the base URI for the named drop.

     * Requirements:
     *
     * - `_dropName` MUST refer to a valid drop.
     * - `_baseURI` MUST be different from the current `baseURI` for the named drop.
     * - `_dropName` MAY refer to an active or inactive drop.
     */
    function setBaseURI(
        DropManager storage mgr,
        string memory _dropName,
        string memory _baseURI
    ) external realDrop(mgr, _dropName) validBaseURI(_baseURI) {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        require(
            keccak256(bytes(_baseURI)) !=
                keccak256(bytes(currentDrop.drop.baseURI)),
            "base uri unchanged"
        );
        currentDrop.drop.baseURI = _baseURI;
        currentDrop.stateMachine.setStateData(
            currentDrop.stateMachine.initialStateName(),
            abi.encode(_baseURI)
        );
    }

    /**
     * @dev get the base URI for the named drop.
     * @dev if `_dropName` is the empty string, returns the baseURI for any 
     *     tokens minted outside of a drop.
     */
    function getBaseURI(DropManager storage mgr, string memory _dropName)
        external
        view
        realDrop(mgr, _dropName)
        returns (string memory)
    {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        return
            _getBaseURIForState(
                currentDrop,
                currentDrop.stateMachine.initialStateName()
            );
    }

    /**
     * @dev Change the base URI for the named state in the named drop.
     *
     * Requirements:
     *
     * - `_dropName` MUST refer to a valid drop.
     * - `_fromState` MUST refer to a valid state for `_dropName`
     * - `_dropName` MAY refer to an active or inactive drop
     */
    function setBaseURIForState(
        DropManager storage mgr,
        string memory _dropName,
        string memory _stateName,
        string memory _baseURI
    ) external realDrop(mgr, _dropName) validBaseURI(_baseURI) {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        bytes memory encodedBaseURI = abi.encode(_baseURI);
        require(
            keccak256(encodedBaseURI) !=
                keccak256(currentDrop.stateMachine.getStateData(_stateName)),
            "base uri unchanged"
        );

        currentDrop.stateMachine.setStateData(_stateName, abi.encode(_baseURI));
    }

    /**
     * @dev return the base URI for the named state in the named drop.
     * @param _dropName The name of the drop
     * @param _stateName The state to be updated.
     *
     * Requirements:
     *
     * - `_dropName` MUST refer to a valid drop.
     * - `_stateName` MUST refer to a valid state for `_dropName`
     * - `_dropName` MAY refer to an active or inactive drop
     */
    function getBaseURIForState(
        DropManager storage mgr,
        string memory _dropName,
        string memory _stateName
    ) external view realDrop(mgr, _dropName) returns (string memory) {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        return _getBaseURIForState(currentDrop, _stateName);
    }

    /**
     * @dev Override the baseURI + tokenId scheme for determining the token
     * URI with the specified custom URI.
     *
     * @param tokenId The token to use the custom URI
     * @param newURI The custom URI
     *
     * Requirements:
     *
     * - `tokenId` MAY refer to an invalid token id. Setting the custom URI
     *      before minting is allowed.
     * - `newURI` MAY be an empty string, to clear a previously set customURI
     *      and use the default scheme.
     */
    function setCustomURI(
        DropManager storage mgr,
        uint256 tokenId,
        string memory newURI
    ) external {
        mgr.customURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `_tokenId` token.
     *
     * @param tokenId the tokenId
     */
    function getTokenURI(DropManager storage mgr, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(mgr.customURIs[tokenId]);
        if (customUriBytes.length > 0) {
            return mgr.customURIs[tokenId];
        }

        string memory base = _getBaseURI(mgr, tokenId);
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }

        return base;
    }

    /**
     * @notice Starts a new drop.
     * @param _dropName The name of the new drop
     * @param _dropStartTime The unix timestamp of when the drop is active
     * @param _dropSize The number of NFTs in this drop
     * @param _startStateName The initial state for the drop's state machine.
     * @param _baseURI The base URI for the tokens in this drop
     *
     * Requirements:
     *
     * - There MUST be sufficient unreserved tokens for the drop size.
     * - The drop size MUST NOT be empty.
     * - The drop name MUST NOT be empty.
     * - The drop name MUST be unique.
     */
    function startNewDrop(
        DropManager storage mgr,
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _startStateName,
        string memory _baseURI
    ) external validBaseURI(_baseURI) {
        require(_dropSize > 0, "invalid drop");
        require(_dropSize <= totalAvailable(mgr), "drop too large");
        require(bytes(_dropName).length > 0, "invalid category");
        ManagedDrop storage newDrop = mgr.dropByName[_dropName];
        require(!_isRealDrop(newDrop.drop), "drop exists");

        newDrop.drop = Drop(_dropName, _dropStartTime, _dropSize, _baseURI);
        _activateDrop(mgr, newDrop, _startStateName);

        mgr.tokensReserved.add(_dropSize);
        emit DropAnnounced(newDrop.drop);
    }

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param _dropName The name of the drop to deactivate
     *
     * Requirements:
     *
     * - There MUST be an active drop with the `_dropName`.
     */
    function deactivateDrop(DropManager storage mgr, string memory _dropName)
        external
    {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        require(currentDrop.active, "invalid drop");

        currentDrop.active = false;
        mgr.tokensReserved.subtract(_remaining(currentDrop));
        emit DropEnded(currentDrop.drop);
    }

    /**
     * @dev Call this function when minting a token within a drop.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     */
    function onMint(
        DropManager storage mgr,
        string memory _dropName,
        uint256 _tokenId,
        string memory _customURI
    ) external validDropName(mgr, _dropName) {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        if (_isRealDrop(currentDrop.drop)) {
            _preMintCheck(currentDrop, 1);

            mgr.dropNameByTokenId[_tokenId] = _dropName;
            currentDrop.stateForToken[_tokenId] = currentDrop
                .stateMachine
                .initialStateName();
            mgr.tokensReserved.decrement();
        } else {
            require(totalAvailable(mgr) >= 1, "sold out");
        }

        mgr.mintCount.increment();

        bytes memory customUriBytes = bytes(_customURI);
        if (customUriBytes.length > 0) {
            mgr.customURIs[_tokenId] = _customURI;
        }
    }

    /**
     * @dev Call this function when minting a batch of tokens within a drop.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     */
    function onBatchMint(
        DropManager storage mgr,
        string memory _dropName,
        uint256[] memory _tokenIds
    ) external validDropName(mgr, _dropName) {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        if (_isRealDrop(currentDrop.drop)) {
            _preMintCheck(currentDrop, _tokenIds.length);

            for (uint256 i = 0; i < _tokenIds.length; i++) {
                mgr.dropNameByTokenId[_tokenIds[i]] = _dropName;
                currentDrop.stateForToken[_tokenIds[i]] = currentDrop
                    .stateMachine
                    .initialStateName();
            }

            mgr.tokensReserved.subtract(_tokenIds.length);
        } else {
            require(totalAvailable(mgr) >= _tokenIds.length, "sold out");
        }

        mgr.mintCount.add(_tokenIds.length);
    }

    /**
     * @dev Call this function when burning a token within a drop.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     */
    function onBurn(DropManager storage mgr, uint256 tokenId) external {
        ManagedDrop storage currentDrop = mgr.dropByName[
            mgr.dropNameByTokenId[tokenId]
        ];
        if (_isRealDrop(currentDrop.drop)) {
            currentDrop.mintCount.decrement();
            mgr.tokensReserved.increment();
            delete mgr.dropNameByTokenId[tokenId];
            delete currentDrop.stateForToken[tokenId];
        }

        delete mgr.customURIs[tokenId];
        mgr.mintCount.decrement();
    }

    /**
     * @notice Sets up a state transition
     *
     * Requirements:
     * - `_dropName` MUST refer to a valid drop
     * - `_fromState` MUST refer to a valid state for `_dropName`
     * - `_toState` MUST NOT be empty
     * - `_baseURI` MUST NOT be empty
     * - A transition named `_toState` MUST NOT already be defined for `_fromState`
     *    in the drop named `_dropName`
     */
    function addStateTransition(
        DropManager storage mgr,
        string memory _dropName,
        string memory _fromState,
        string memory _toState,
        string memory _baseURI
    ) external realDrop(mgr, _dropName) validBaseURI(_baseURI) {
        ManagedDrop storage drop = mgr.dropByName[_dropName];

        drop.stateMachine.addStateTransition(
            _fromState,
            _toState,
            abi.encode(_baseURI)
        );
    }

    /**
     * @notice Removes a state transition. Does not remove any states.
     *
     * Requirements:
     * - `_dropName` MUST refer to a valid drop.
     * - `_fromState` and `toState` MUST describe an existing transition.
     */
    function deleteStateTransition(
        DropManager storage mgr,
        string memory _dropName,
        string memory _fromState,
        string memory _toState
    ) external realDrop(mgr, _dropName) {
        ManagedDrop storage drop = mgr.dropByName[_dropName];

        drop.stateMachine.deleteStateTransition(_fromState, _toState);
    }

    /**
     * @dev Move the token to a new state. Reverts if the
     * state transition is invalid.
     */
    function changeState(
        DropManager storage _mgr,
        uint256 _tokenId,
        string memory _stateName
    ) external {
        _setState(_mgr, _tokenId, _stateName, true);
    }

    /**
     * @dev Arbitrarily set the token state. Does not revert if the
     * transition is invalid. Will revert if the new state doesn't
     * exist.
     */
    function setState(
        DropManager storage _mgr,
        uint256 _tokenId,
        string memory _stateName
    ) external {
        _setState(_mgr, _tokenId, _stateName, false);
    }

    /**
     * @dev Returns the token's current state
     * @dev Returns empty string if the token is not managed by a state machine.
     */
    function getState(DropManager storage _mgr, uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        ManagedDrop storage currentDrop = _mgr.dropByName[
            _mgr.dropNameByTokenId[_tokenId]
        ];

        if (!_isRealDrop(currentDrop.drop)) {
            return "";
        }

        return currentDrop.stateForToken[_tokenId];
    }

    function _setState(
        DropManager storage _mgr,
        uint256 _tokenId,
        string memory _stateName,
        bool requireValidTransition
    ) internal {
        ManagedDrop storage currentDrop = _mgr.dropByName[
            _mgr.dropNameByTokenId[_tokenId]
        ];
        require(_isRealDrop(currentDrop.drop), "no state");
        require(
            currentDrop.stateMachine.isValidState(_stateName),
            "invalid state"
        );
        string memory currentStateName = currentDrop.stateForToken[_tokenId];

        if (requireValidTransition) {
            require(
                currentDrop.stateMachine.isValidTransition(
                    currentStateName,
                    _stateName
                ),
                "No such transition"
            );
        }

        currentDrop.stateForToken[_tokenId] = _stateName;
        emit StateChange(_tokenId, currentStateName, _stateName);
    }

    function _getBaseURI(DropManager storage _mgr, uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        ManagedDrop storage currentDrop = _mgr.dropByName[
            _mgr.dropNameByTokenId[_tokenId]
        ];
        if (!_isRealDrop(currentDrop.drop)) {
            return _mgr.baseURI;
        }

        string memory stateName = currentDrop.stateForToken[_tokenId];
        if (bytes(stateName).length == 0) {
            return _mgr.baseURI;
        }

        return _getBaseURIForState(currentDrop, stateName);
    }

    function _getBaseURIForState(
        ManagedDrop storage currentDrop,
        string memory stateName
    ) internal view returns (string memory) {
        return
            abi.decode(
                currentDrop.stateMachine.getStateData(stateName),
                (string)
            );
    }

    function _remaining(ManagedDrop storage drop)
        private
        view
        returns (uint32)
    {
        return drop.drop.dropSize - uint32(drop.mintCount.current());
    }

    function _activateDrop(
        DropManager storage mgr,
        ManagedDrop storage drop,
        string memory _startStateName
    ) private {
        mgr.allDropNames.push(drop.drop.dropName);
        drop.active = true;
        drop.stateMachine.initialize(
            _startStateName,
            abi.encode(drop.drop.baseURI)
        );
    }

    function _preMintCheck(ManagedDrop storage currentDrop, uint256 _quantity)
        private
    {
        require(currentDrop.active, "no drop");
        require(block.timestamp >= currentDrop.drop.dropStartTime, "early");
        uint32 remaining = _remaining(currentDrop);
        require(remaining >= _quantity, "sold out");

        currentDrop.mintCount.add(_quantity);
        if (remaining == _quantity) {
            currentDrop.active = false;
            emit DropEnded(currentDrop.drop);
        }
    }

    function _isRealDrop(Drop storage testDrop) private view returns (bool) {
        return testDrop.dropSize != 0;
    }
}