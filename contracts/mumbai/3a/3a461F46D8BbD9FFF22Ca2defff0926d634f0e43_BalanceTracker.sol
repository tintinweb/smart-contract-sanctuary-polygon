// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../interfaces/IBalanceTracker.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/EventWrapper.sol";
import "../interfaces/events/EventReceiver.sol";
import "../interfaces/events/DelegationEnabled.sol";
import "../interfaces/events/DelegationDisabled.sol";

contract BalanceTracker is EventReceiver, IBalanceTracker, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant EVENT_TYPE_DEPOSIT = bytes32("Deposit");
    bytes32 public constant EVENT_TYPE_TRANSFER = bytes32("Transfer");
    bytes32 public constant EVENT_TYPE_SLASH = bytes32("Slash");
    bytes32 public constant EVENT_TYPE_WITHDRAW = bytes32("Withdraw");
    bytes32 public constant EVENT_TYPE_WITHDRAWALREQUEST = bytes32("Withdrawal Request");
    bytes32 public constant EVENT_TYPE_DELEGATION_ENABLED = bytes32("DelegationEnabled");
    bytes32 public constant EVENT_TYPE_DELEGATION_DISABLED = bytes32("DelegationDisabled");

    // user account address -> token address -> balance
    mapping(address => mapping(address => TokenBalance)) public accountTokenBalances;
    // token address -> total tracked balance
    mapping(address => uint256) public totalTokenBalances;

    // account -> delegatedTo
    mapping(address => address) public delegatedTo;

    EnumerableSet.AddressSet private supportedTokenAddresses;

    // account -> token -> delegatedBalance
    mapping(address => mapping(address => uint256)) public delegatedBalance;

    //solhint-disable-next-line no-empty-blocks, func-visibility
    function initialize(address eventProxy) public initializer {
        __Ownable_init_unchained();
        EventReceiver.init(eventProxy);
    }

    function getBalance(address account, address[] calldata tokens)
        external
        view
        override
        returns (TokenBalance[] memory userBalances)
    {
        userBalances = new TokenBalance[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            // Return 0 if account has delegated
            if (delegatedTo[account] != address(0)) {
                userBalances[i] = TokenBalance({token: tokens[i], amount: 0});
            } else {
                userBalances[i] = accountTokenBalances[account][tokens[i]];
            }
        }

        return userBalances;
    }

    function getActualBalance(address account, address[] calldata tokens)
        external
        view
        override
        returns (TokenBalance[] memory userBalances)
    {
        userBalances = new TokenBalance[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            userBalances[i] = accountTokenBalances[account][tokens[i]];
        }

        return userBalances;
    }

    function setBalance(SetTokenBalance[] calldata balances) external override onlyOwner {
        for (uint256 i = 0; i < balances.length; i++) {
            SetTokenBalance calldata balance = balances[i];
            updateBalance({
                account: balance.account,
                token: balance.token,
                amount: balance.amount,
                stateSync: false
            });
        }
    }

    function updateBalance(
        address account,
        address token,
        uint256 amount,
        bool stateSync
    ) private {
        require(token != address(0), "INVALID_TOKEN_ADDRESS");
        require(account != address(0), "INVALID_ACCOUNT_ADDRESS");

        TokenBalance memory userTokenBalance = accountTokenBalances[account][token];

        // stateSync updates balances on an ongoing basis, whereas setBalance is only
        // allowed to update balances that have not been set before
        if (stateSync || userTokenBalance.token == address(0)) {
            // Set the account's balance equal to the amount (which is the true balance of pool tokens)
            accountTokenBalances[account][token] = TokenBalance({token: token, amount: amount});

            if (delegatedTo[account] != address(0)) {
                //Delegated balance, back out individual and apply new balance
                uint256 delegatedAmt = accountTokenBalances[delegatedTo[account]][token].amount;
                delegatedAmt = delegatedAmt.sub(userTokenBalance.amount).add(amount);
                accountTokenBalances[delegatedTo[account]][token] = TokenBalance({
                    token: token,
                    amount: delegatedAmt
                });
                delegatedBalance[delegatedTo[account]][token] = delegatedBalance[
                    delegatedTo[account]
                ][token].sub(userTokenBalance.amount).add(amount);
            }

            // Add the balance delegated to the account (since the amount in the event does not include delegated balance)
            accountTokenBalances[account][token].amount = accountTokenBalances[account][token]
                .amount
                .add(delegatedBalance[account][token]);

            //Update the total based on the individual amounts
            _updateTotalTokenBalance(
                token,
                userTokenBalance.amount,
                accountTokenBalances[account][token].amount
            );

            emit BalanceUpdate(account, token, amount, stateSync, true);
        } else {
            // setBalance may trigger this event if it tries to update the balance
            // of an already set user-token key
            emit BalanceUpdate(account, token, amount, false, false);
        }
    }

    /// @dev Moves delegations from the old delegation (delegatedTo[from]) to the new one (to)
    /// @dev It does not update the delegation mapping
    function _delegate(
        address token,
        address from,
        address to
    ) private {
        require(from != address(0), "INVALID_FROM");
        require(token != address(0), "INVALID_TOKEN");
        require(from != to, "NO_SELF");
        require(delegatedTo[to] == address(0), "ALREADY_DELEGATOR");

        // This line only protects when paired with the DelegateFunction contract
        // Should we send events from another source we need to be aware
        require(delegatedBalance[from][token] == 0, "ALREADY_DELEGATEE");

        TokenBalance memory balanceToTransfer = accountTokenBalances[from][token];

        //See if we need to back it out of an existing delegation
        if (delegatedTo[from] != address(0)) {
            TokenBalance memory oldDelegateBal = accountTokenBalances[delegatedTo[from]][token];
            oldDelegateBal.amount = oldDelegateBal.amount.sub(balanceToTransfer.amount);
            accountTokenBalances[delegatedTo[from]][token] = oldDelegateBal;
            delegatedBalance[delegatedTo[from]][token] = delegatedBalance[delegatedTo[from]][token]
                .sub(balanceToTransfer.amount);
        }

        if (to != address(0)) {
            //Apply the existing balance to the new account
            TokenBalance memory newDelegateBal = accountTokenBalances[to][token];
            newDelegateBal.amount = newDelegateBal.amount.add(balanceToTransfer.amount);
            newDelegateBal.token = token;
            accountTokenBalances[to][token] = newDelegateBal;
            delegatedBalance[to][token] = delegatedBalance[to][token].add(balanceToTransfer.amount);
        }

        emit BalanceDelegated(token, from, to);
    }

    function _delegateAll(
        address from,
        address to,
        bytes32 functionId
    ) private {
        // so far, only vote delegtion impacts BalanceTracker
        if (functionId == "voting") {
            uint256 length = supportedTokenAddresses.length();
            for (uint256 i = 0; i < length; i++) {
                address token = supportedTokenAddresses.at(i);
                _delegate(token, from, to);
            }
            delegatedTo[from] = to;
        }
    }

    function getSupportedTokens()
        external
        view
        override
        returns (address[] memory supportedTokensArray)
    {
        uint256 supportedTokensLength = supportedTokenAddresses.length();
        supportedTokensArray = new address[](supportedTokensLength);

        for (uint256 i = 0; i < supportedTokensLength; i++) {
            supportedTokensArray[i] = supportedTokenAddresses.at(i);
        }
        return supportedTokensArray;
    }

    function addSupportedTokens(address[] calldata tokensToSupport) external override onlyOwner {
        require(tokensToSupport.length > 0, "NO_TOKENS");

        for (uint256 i = 0; i < tokensToSupport.length; i++) {
            require(tokensToSupport[i] != address(0), "ZERO_ADDRESS");

            require(supportedTokenAddresses.add(tokensToSupport[i]), "ADD_FAIL");
        }
        emit SupportedTokensAdded(tokensToSupport);
    }

    function removeSupportedTokens(address[] calldata tokensToSupport) external override onlyOwner {
        require(tokensToSupport.length > 0, "NO_TOKENS");

        for (uint256 i = 0; i < tokensToSupport.length; i++) {
            require(tokensToSupport[i] != address(0), "ZERO_ADDRESS");

            require(supportedTokenAddresses.remove(tokensToSupport[i]), "REMOVE_FAIL");
        }
        emit SupportedTokensRemoved(tokensToSupport);
    }

    function _updateTotalTokenBalance(
        address token,
        uint256 oldAmount,
        uint256 newBalance
    ) private {
        uint256 currentTotalBalance = totalTokenBalances[token];
        uint256 updatedTotalBalance = currentTotalBalance.sub(oldAmount).add(newBalance);
        totalTokenBalances[token] = updatedTotalBalance;
    }

    function _onBalanceChange(bytes calldata data) private {
        BalanceUpdateEvent memory balanceUpdate = abi.decode(data, (BalanceUpdateEvent));

        updateBalance({
            account: balanceUpdate.account,
            token: balanceUpdate.token,
            amount: balanceUpdate.amount,
            stateSync: true
        });
    }

    function _onDelegationEnabled(bytes calldata data) private {
        DelegationEnabled memory delegation = abi.decode(data, (DelegationEnabled));
        _delegateAll(delegation.from, delegation.to, delegation.functionId);
    }

    function _onDelegationDisabled(bytes calldata data) private {
        DelegationDisabled memory delegation = abi.decode(data, (DelegationDisabled));
        _delegateAll(delegation.from, address(0), delegation.functionId);
    }

    function _onEventReceive(
        address,
        bytes32 eventType,
        bytes calldata data
    ) internal virtual override {
        if (
            eventType == EVENT_TYPE_DEPOSIT ||
            eventType == EVENT_TYPE_TRANSFER ||
            eventType == EVENT_TYPE_WITHDRAW ||
            eventType == EVENT_TYPE_SLASH ||
            eventType == EVENT_TYPE_WITHDRAWALREQUEST
        ) {
            _onBalanceChange(data);
        } else if (eventType == EVENT_TYPE_DELEGATION_ENABLED) {
            _onDelegationEnabled(data);
        } else if (eventType == EVENT_TYPE_DELEGATION_DISABLED) {
            _onDelegationDisabled(data);
        } else {
            revert("INVALID_EVENT_TYPE");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./events/IEventReceiver.sol";
import "./structs/TokenBalance.sol";

/**
 *   @title Accounts for every balance the user has in the Pools
 *   and the Staking contracts. It is used to support the Vote Tracker
 *   in determining voting power
 */
interface IBalanceTracker is IEventReceiver {
    struct SetTokenBalance {
        address account;
        address token;
        uint256 amount;
    }

    /// @param account User address
    /// @param token Token address
    /// @param amount User balance set for the user-token key
    /// @param stateSynced True if the event is from the L1 to L2 state sync. False if backfill
    /// @param applied False if the update was not actually recorded. Only applies to backfill updates that are skipped
    event BalanceUpdate(
        address account,
        address token,
        uint256 amount,
        bool stateSynced,
        bool applied
    );

    /// @param tokens Tokens addresses that have been added
    event SupportedTokensAdded(address[] tokens);

    /// @param tokens Tokens addresses that have been removed
    event SupportedTokensRemoved(address[] tokens);

    /// @param from delegator
    /// @param to delegatee
    /// @param token token delegated
    event BalanceDelegated(address token, address from, address to);

    /// @notice get all tokens currently supported by the contract
    /// @return supportedTokensArray an array of supported token addresses
    function getSupportedTokens() external view returns (address[] memory supportedTokensArray);

    /// @notice adds tokens to support
    /// @param tokensToSupport an array of supported token addresses
    function addSupportedTokens(address[] calldata tokensToSupport) external;

    /// @notice removes tokens to support
    /// @param tokensToRemove an array of token addresses to remove from supported token
    function removeSupportedTokens(address[] calldata tokensToRemove) external;

    /// @notice Retrieve the current balances for the supplied account and tokens. Returned balance WILL respect delegation
    function getBalance(address account, address[] calldata tokens)
        external
        view
        returns (TokenBalance[] memory userBalances);

    /// @notice Retrieve the current balances for the supplied account and tokens. Returned balance WONT respect delegation
    function getActualBalance(address account, address[] calldata tokens)
        external
        view
        returns (TokenBalance[] memory userBalances);

    /// @notice Allows backfilling of current balance
    /// @dev onlyOwner. Only allows unset balances to be updated
    function setBalance(SetTokenBalance[] calldata balances) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Simple structure for events sent to Governance layer
struct EventWrapper {
    bytes32 eventType;
    bytes data;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IEventReceiver.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/// @title Base contract for receiving events through our Event Proxy
abstract contract EventReceiver is Initializable, IEventReceiver {
    address public eventProxy;

    event ProxyAddressSet(address proxyAddress);

    function init(address eventProxyAddress) public initializer {
        require(eventProxyAddress != address(0), "INVALID_ROOT_PROXY");

        _setEventProxyAddress(eventProxyAddress);
    }

    /// @notice Receive an encoded event from a contract on a different chain
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) external override {
        require(msg.sender == eventProxy, "EVENT_PROXY_ONLY");

        _onEventReceive(sender, eventType, data);
    }

    /// @notice Implemented by child contracts to process events
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function _onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) internal virtual;

    /// @notice Configures the contract that can send events to this contract
    /// @param eventProxyAddress New sender address
    function _setEventProxyAddress(address eventProxyAddress) private {
        eventProxy = eventProxyAddress;

        emit ProxyAddressSet(eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has enabled delegation for voting or rewards
struct DelegationEnabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has disabled their delegation for voting or rewards
struct DelegationDisabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IEventReceiver {
    /// @notice Receive an encoded event from a contract on a different chain
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/// @notice Simple mapping of token to amount
struct TokenBalance {
    address token;
    uint256 amount;
}