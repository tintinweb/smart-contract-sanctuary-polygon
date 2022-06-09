/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: IUriManager.sol

/**
 * @notice A URI Manager keeps track of which token has which URI.
 */
interface IUriManager is IERC165  {
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `_tokenId` token.
     * 
     * @param _tokenId the tokenId
     */
    function getTokenURI(uint256 _tokenId) external view returns (string memory);
    
    /**
     * @dev Override the baseURI + tokenId scheme for determining the token 
     * URI with the specified custom URI.
     *
     * @param _tokenId The token to use the custom URI
     * @param _newUri The custom URI
     */
    function setCustomURI(uint256 _tokenId, string memory _newUri) external;

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be he concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() external view returns (string memory);

    /**
     * @param _baseURI the new base URI.
     */
    function setBaseURI(string memory _baseURI) external;
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

// File: ITokenManager.sol

/**
 * @dev Adds some functions from `IERC721Enumerable` and some callback hooks 
 * for when tokens are minted.
 */
interface ITokenManager is IUriManager {
    /**
     * @notice returns the total number of tokens that may be minted.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice returns the current number of tokens that have been minted.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice returns the current number of tokens available to be minted.
     * @dev This should be maxSupply() - totalSupply()
     */
    function totalAvailable() external view returns (uint256);

    /**
     * @dev Returns the number of tokens in ``_owner``'s account.
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @dev Returns a token ID owned by `_owner` at a given `_index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``_owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 _index) external view returns (uint256);
    
    /**
     * @notice Returns a list of all the token ids owned by an address.
     */
    function userWallet(address _user) external view returns (uint256[] memory);

    /**
     * @dev Hook that is called before normal minting.
     * 
     * @param _category Type, group, option name etc.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     */
    function beforeMint(
        string memory _category,
        address _toAddress,
        uint256 _tokenId
    ) external;

    /**
     * @dev Hook that is called before batch minting.
     * 
     * @param _category Type, group, option name etc.
     * @param _toAddresses The accounts to receive the newly minted tokens.
     * @param _tokenIds The ids of the new tokens.
     */
    function beforeBatchMint(
        string memory _category,
        address[] memory _toAddresses,
        uint256[] memory _tokenIds
    ) external;

    /**
     * @dev Hook that is called before custom minting.
     * 
     * @param _category Type, group, option name etc.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     * @param _customURI the custom URI.
     */
    function beforeMintCustom(
        string memory _category,
        address _toAddress,
        uint256 _tokenId,
        string memory _customURI
    ) external;

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     */
    function beforeTokenTransfer(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) external;

    /**
     * @dev Cause the transaction to revert if `_toAddress` is a contract that does 
     * not implement {onERC721Received}.
     * @dev See the warnings on {Address.isContract} for reasons why this function
     * might fail to identify an unsafe address.
     *
     * @param _fromAddress address representing the previous owner of the given token ID
     * @param _toAddress target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function checkOnERC721Received(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId,
        bytes memory _data) external returns (bool);
}

// File: ITokenDropManager.sol

struct Drop {
    string dropName;
    uint32 dropStartTime;
    uint32 dropSize;
    string baseURI;
}

/**
 * @dev A Token Drop Manager allows you to partition an NFT collection into
 * pools of various sizes and release dates, each with its own baseURI.
 */
interface ITokenDropManager is ITokenManager {
    event DropAnnounced(Drop drop);
    event DropEnded(Drop drop);
    
    /**
     * @dev Returns the number of tokens minted so far in a drop.
     *
     * @param _dropName The name of the drop
     */
    function dropMintCount(string memory _dropName)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     *
     * @param _dropName The name of the drop
     */
    function amountRemainingInDrop(string memory _dropName)
        external
        view
        returns (uint256);

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * or been stopped manually.
     * @dev Returns true if the `_dropName` refers to an active drop.
     */
    function isDropActive(string memory _dropName) external view returns (bool);

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount() external view returns (uint256);

    /**
     * @dev Return the name of a drop at `_index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(uint256 _index)
        external
        view
        returns (string memory);

    /**
     * @dev Return the drop at `_index`. Use along with {dropCount()} to iterate through
     * all the drops.
     */
    function dropForIndex(uint256 _index) external view returns (Drop memory);

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(string memory _dropName)
        external
        view
        returns (Drop memory);

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(string memory _dropName, string memory _baseURI)
        external;

    /**
     * @notice Starts a new drop.
     * @param _dropName The name of the new drop
     * @param _dropStartTime The unix timestamp of when the drop is active
     * @param _dropSize The number of NFTs in this drop
     * @param _baseURI The base URI for the tokens in this drop
     */
    function startNewDrop(
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _baseURI
    ) external;

    /**
     * @notice Starts a new drop within a parent drop.
     * @param _parentDropName The name of the parent drop
     * @param _dropName The name of the new drop
     * @param _dropSize The number of NFTs in this drop
     * @param _baseURI The base URI for the tokens in this drop
     */
    function startSubDrop(
        string memory _parentDropName,
        string memory _dropName,
        uint32 _dropSize,
        string memory _baseURI
    ) external;

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param _dropName The name of the drop to deactivate
     */
    function deactivateDrop(string memory _dropName) external;
}

// File: DropManagement.sol

library DropManagement {
    using Strings for string;
    using StateMachine for StateMachine.States;
    using Monotonic for Monotonic.Counter;

    struct ManagedDrop {
        Drop drop;
        Monotonic.Counter mintCount;
        bool active;
        StateMachine.States stateMachine;
        mapping(uint256 => string) stateForToken;
    }

    struct DropManager {
        string[] allDropNames;
        mapping(string => ManagedDrop) dropByName;
        mapping(uint256 => string) dropNameByTokenId;
    }

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     * @dev Returns 0 if `_dropName` does not refer to an active drop.
     *
     * @param _dropName The name of the drop
     */
    function amountRemainingInDrop(
        DropManager storage mgr,
        string memory _dropName
    ) external view returns (uint32) {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        if (!currentDrop.active) {
            return 0;
        }

        return _remaining(currentDrop);
    }

    /**
     * @dev Returns the number of tokens minted so far in a drop.
     * @dev Returns 0 if `_dropName` does not refer to an active drop.
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
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(
        DropManager storage mgr,
        string memory _dropName,
        string memory _baseURI
    ) external {
        require(bytes(_baseURI).length > 0);
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        require(_isRealDrop(currentDrop.drop));
        require(
            keccak256(bytes(_baseURI)) !=
                keccak256(bytes(currentDrop.drop.baseURI))
        );
        currentDrop.drop.baseURI = _baseURI;
        currentDrop.stateMachine.setStateData(
            currentDrop.stateMachine.initialStateName(),
            abi.encode(_baseURI)
        );
    }

    /**
     * @dev Change the base URI for the named state in the named drop.
     */
    function setBaseURIForState(
        DropManager storage mgr,
        string memory _dropName,
        string memory _stateName,
        string memory _baseURI
    ) external {
        require(bytes(_baseURI).length > 0);
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        require(_isRealDrop(currentDrop.drop));
        require(
            keccak256(bytes(_baseURI)) !=
                keccak256(bytes(currentDrop.drop.baseURI))
        );

        currentDrop.stateMachine.setStateData(_stateName, abi.encode(_baseURI));
    }

    /**
     * @notice Starts a new drop.
     * @param _dropName The name of the new drop
     * @param _dropStartTime The unix timestamp of when the drop is active
     * @param _dropSize The number of NFTs in this drop
     * @param _startStateName The initial state for the drop's state machine.
     * @param _baseURI The base URI for the tokens in this drop
     */
    function startNewDrop(
        DropManager storage mgr,
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _startStateName,
        string memory _baseURI
    ) external returns (Drop memory) {
        require(_dropSize > 0);
        require(bytes(_dropName).length > 0);
        require(bytes(_baseURI).length > 0);
        ManagedDrop storage newDrop = mgr.dropByName[_dropName];
        require(!_isRealDrop(newDrop.drop));

        newDrop.drop = Drop(_dropName, _dropStartTime, _dropSize, _baseURI);
        _activateDrop(mgr, newDrop, _startStateName);

        return newDrop.drop;
    }

    /**
     * @notice Starts a new drop within a parent drop.
     * @param _parentDropName The name of the parent drop
     * @param _dropName The name of the new drop
     * @param _dropSize The number of NFTs in this drop
     * @param _baseURI The base URI for the tokens in this drop
     */
    function startSubDrop(
        DropManager storage mgr,
        string memory _parentDropName,
        string memory _dropName,
        uint32 _dropSize,
        string memory _baseURI
    ) external returns (Drop memory, Drop memory) {
        require(_dropSize > 0);
        require(bytes(_dropName).length > 0);
        ManagedDrop storage subDrop = mgr.dropByName[_dropName];
        require(!_isRealDrop(subDrop.drop));

        ManagedDrop storage parentDrop = mgr.dropByName[_parentDropName];
        require(parentDrop.active);
        uint32 remainingInParent = _remaining(parentDrop);
        require(remainingInParent >= _dropSize);

        if (bytes(_baseURI).length == 0) {
            _baseURI = parentDrop.drop.baseURI;
        }

        subDrop.drop = Drop(
            _dropName,
            parentDrop.drop.dropStartTime,
            _dropSize,
            _baseURI
        );

        _activateDrop(mgr, subDrop, parentDrop.stateMachine.initialStateName());
        parentDrop.drop.dropSize -= _dropSize;
        if (remainingInParent == _dropSize) {
            parentDrop.active = false;
        }

        return (parentDrop.drop, subDrop.drop);
    }

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param _dropName The name of the drop to deactivate
     */
    function deactivateDrop(DropManager storage mgr, string memory _dropName)
        external
        returns (Drop memory, uint32)
    {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        require(currentDrop.active);

        currentDrop.active = false;
        return (currentDrop.drop, _remaining(currentDrop));
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `_tokenId` token.
     * 
     * @param _tokenId the tokenId
     */
    function getTokenURI(DropManager storage _mgr, uint256 _tokenId)
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

        string memory stateName = currentDrop.stateForToken[_tokenId];
        if (bytes(stateName).length == 0) {
            return "";
        }

        string memory base = abi.decode(
            currentDrop.stateMachine.getStateData(stateName),
            (string)
        );
        return string(abi.encodePacked(base, Strings.toString(_tokenId)));
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
        uint256 _tokenId
    ) external {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        _preMintCheck(currentDrop, 1);

        mgr.dropNameByTokenId[_tokenId] = _dropName;
        currentDrop.stateForToken[_tokenId] = currentDrop
            .stateMachine
            .initialStateName();
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
    ) external {
        ManagedDrop storage currentDrop = mgr.dropByName[_dropName];
        _preMintCheck(currentDrop, _tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            mgr.dropNameByTokenId[_tokenIds[i]] = _dropName;
            currentDrop.stateForToken[_tokenIds[i]] = currentDrop
                .stateMachine
                .initialStateName();
        }
    }

    /**
     * @dev Call this function when burning a token within a drop.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     */
    function postBurnUpdate(DropManager storage _mgr, uint256 _tokenId)
        external
    {
        ManagedDrop storage currentDrop = _mgr.dropByName[
            _mgr.dropNameByTokenId[_tokenId]
        ];
        if (_isRealDrop(currentDrop.drop)) {
            currentDrop.mintCount.decrement();
            delete _mgr.dropNameByTokenId[_tokenId];
            delete currentDrop.stateForToken[_tokenId];
        }
    }

    /**
     * @notice Sets up a state transition
     *
     * Requirements:
     * - `_dropName` MUST refer to a valid drop
     * - `_fromState` MUST refer to a valid state for `_dropName`
     * - `_toState` MUST not be empty
     * - `_baseURI` MUST not be empty
     * - A transition named `_toState` MUST NOT already be defined for `_fromState`
     *    in the drop named `_dropName`
     */
    function addStateTransition(
        DropManager storage mgr,
        string memory _dropName,
        string memory _fromState,
        string memory _toState,
        string memory _baseURI
    ) external {
        require(bytes(_dropName).length > 0, "Missing drop name");
        ManagedDrop storage drop = mgr.dropByName[_dropName];
        require(_isRealDrop(drop.drop), "No drop");
        require(bytes(_baseURI).length > 0, "Missing Base URI");

        drop.stateMachine.addStateTransition(
            _fromState,
            _toState,
            abi.encode(_baseURI)
        );
    }

    /**
     * @dev Move the token to a new state.
     */
    function changeState(
        DropManager storage _mgr,
        uint256 _tokenId,
        string memory _stateName
    ) external returns (string memory) {
        ManagedDrop storage currentDrop = _mgr.dropByName[
            _mgr.dropNameByTokenId[_tokenId]
        ];
        require(_isRealDrop(currentDrop.drop));
        string memory currentStateName = currentDrop.stateForToken[_tokenId];
        require(
            currentDrop.stateMachine.isValidTransition(
                currentStateName,
                _stateName
            )
        );
        currentDrop.stateForToken[_tokenId] = _stateName;
        return currentStateName;
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
        }
    }

    function _isRealDrop(Drop storage testDrop) private view returns (bool) {
        return testDrop.dropSize != 0;
    }
}