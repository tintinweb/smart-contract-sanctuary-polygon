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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.6;

interface IDateTime {
    function isLeapYear(uint16 year) external pure returns (bool);

    function leapYearsBefore(uint256 year) external pure returns (uint256);

    function getDaysInMonth(uint8 month, uint16 year)
        external
        pure
        returns (uint8);

    function getYear(uint256 timestamp) external pure returns (uint16);

    function getMonth(uint256 timestamp) external pure returns (uint8);

    function getDay(uint256 timestamp) external pure returns (uint8);

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) external pure returns (uint256 timestamp);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.6;

interface IXGHub {
    function getAuthorizationStatus(address _address)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.6;

interface IXGWallet {
    enum Currency {
        NULL,
        XDAI,
        XGT
    }

    function payWithToken(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bool _withFreeze
    ) external returns (bool);

    function getUserTokenBalance(address _token, address _user) external view returns (uint256);

    function pause() external;

    function unpause() external;

    function setFeeWallet(address _feeWallet) external;

    function setSubscriptionsContract(address _subscriptions) external;

    function setPurchasesContract(address _purchases) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "contracts/interfaces/IXGWallet.sol";
import "contracts/interfaces/IXGHub.sol";
import "contracts/interfaces/IDateTime.sol";

contract XGSubscriptions is OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    IXGWallet public wallet;
    IXGHub public hub;
    IDateTime public dateTimeLib;
    address public feeWallet;

    enum Status {
        NULL,
        ACTIVE,
        PAUSED,
        UNSUBSCRIBED,
        END
    }

    struct Subscription {
        address user;
        address merchant;
        bytes32 productId;
        bytes32 parentProductId;
        Status status;
        bool unlimited;
        uint256 billingDay;
        uint256 nextBillingDay;
        uint256 billingCycle;
        uint256 cycles;
        uint256 price;
        uint256 successPaymentsAmount;
        uint256 lastPaymentDate;
    }

    mapping(bytes32 => Subscription) public subscriptions;
    mapping(bytes32 => bool) public productPaused;

    event SubscriptionCreated(
        address user,
        address merchant,
        bytes32 subscriptionId,
        uint256 processID,
        bytes32 productId
    );

    event SubscriptionPaid(
        address user,
        address merchant,
        bytes32 subscriptionID,
        uint256 rebillID,
        address tokenAddress,
        uint256 tokenPayment,
        uint256 tokenPrice
    );

    event RecurringBillingPaymentPaid(
        address user,
        address merchant,
        bytes32 subscriptionID,
        uint256 rebillID,
        address tokenAddress,
        uint256 tokenPayment,
        uint256 tokenPrice
    );

    event SingleBillingPaymentPaid(
        address user,
        address merchant,
        bytes32 purchaseId,
        uint256 processId,
        address tokenAddress,
        uint256 tokenPayment,
        uint256 tokenPrice
    );

    event PauseSubscriptionByCustomer(
        address user,
        bytes32 subscriptionID,
        uint256 processID,
        address tokenAddress,
        uint256 tokenPrice
    );

    event ActivateSubscription(
        address user,
        bytes32 subscriptionID,
        uint256 processID
    );

    event CancelSubscription(
        address user,
        bytes32 subscriptionID,
        uint256 processID
    );

    event PauseProductByMerchant(bytes32 productID, uint256 processID);
    event UnpauseProductByMerchant(bytes32 productID, uint256 processID);

    event PauseSubscriptionByMerchant(
        bytes32 subscriptionID,
        uint256 processID
    );
    event UnpauseSubscriptionByMerchant(
        bytes32 subscriptionID,
        uint256 processID
    );

    function initialize(
        address _hub,
        address _dateTimeLib
    ) external initializer {
        hub = IXGHub(_hub);
        dateTimeLib = IDateTime(_dateTimeLib);

        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        transferOwnership(OwnableUpgradeable(address(hub)).owner());
    }

    function setXGHub(address _hub) external onlyOwner {
        hub = IXGHub(_hub);
    }

    function setFeeWallet(address _feeWallet) external onlyHub {
        feeWallet = _feeWallet;
    }

    function setWallet(address _wallet) external onlyHub {
        wallet = IXGWallet(_wallet);
    }

    function pause() external onlyHub whenNotPaused {
        _pause();
    }

    function unpause() external onlyHub whenPaused {
        _unpause();
    }

    function subscribeUser(
        address user,
        address merchant,
        bytes32 subscriptionId,
        bytes32 productId,
        uint256 processID,
        uint256 billingDay,
        uint256 billingCycle,
        uint256 cycles,
        address tokenAddress,
        uint256[] calldata priceInfo, // price, basePayment, tokenPayment, tokenPrice
        bool unlimited,
        bytes32 parentProductId
    ) public onlyAuthorized whenNotPaused {
        require(
            !productPaused[productId] &&
                !productPaused[subscriptions[subscriptionId].parentProductId],
            "Product paused by merchant"
        );
        require(
            subscriptions[subscriptionId].status != Status.ACTIVE,
            "User already has an active subscription with this ID"
        );
        require(billingDay <= 28, "Invalid billing day");

        subscriptions[subscriptionId] = Subscription(
            user,
            merchant,
            productId,
            parentProductId,
            Status.ACTIVE,
            unlimited,
            billingDay,
            0,
            billingCycle,
            cycles,
            priceInfo[0],
            0,
            0
        );
        emit SubscriptionCreated(
            user,
            merchant,
            subscriptionId,
            processID,
            productId
        );
        processSubscriptionPayment(
            subscriptionId,
            0,
            tokenAddress,
            priceInfo[2],
            priceInfo[3]
        );
    }

    function processSubscriptionPayment(
        bytes32 subscriptionId,
        uint256 rebillID,
        address tokenAddress,
        uint256 tokenPayment,
        uint256 tokenPrice
    ) public onlyAuthorized whenNotPaused {
        uint256 tokenPaymentValue = (tokenPayment.mul(tokenPrice)).div(
            10 ** 18
        );
        require(
            (subscriptions[subscriptionId].successPaymentsAmount <
                subscriptions[subscriptionId].cycles) ||
                subscriptions[subscriptionId].unlimited,
            "Subscription is over"
        );
        require(
            (tokenPaymentValue <= subscriptions[subscriptionId].price),
            "Payment cant be more than started payment amount"
        );
        require(
            !productPaused[subscriptions[subscriptionId].productId],
            "Product paused by merchant"
        );
        require(
            subscriptions[subscriptionId].status != Status.UNSUBSCRIBED &&
                subscriptions[subscriptionId].status != Status.PAUSED,
            "Subscription must not be unsubscribed or paused"
        );

        require(
            block.timestamp >= subscriptions[subscriptionId].nextBillingDay,
            "Subscription can't be rebilled before the next billing date"
        );
        if (subscriptions[subscriptionId].billingDay != 0) {
            uint8 month = dateTimeLib.getMonth(block.timestamp);
            uint16 year = dateTimeLib.getYear(block.timestamp);
            if (month == 12) {
                month = 1;
                year++;
            } else {
                month++;
            }
            subscriptions[subscriptionId].nextBillingDay = dateTimeLib
                .toTimestamp(
                    year,
                    month,
                    uint8(subscriptions[subscriptionId].billingDay),
                    0,
                    0,
                    0
                );
        } else {
            if (subscriptions[subscriptionId].nextBillingDay == 0) {
                subscriptions[subscriptionId].nextBillingDay = block.timestamp;
            }
            subscriptions[subscriptionId].nextBillingDay = subscriptions[
                subscriptionId
            ].nextBillingDay.add(subscriptions[subscriptionId].billingCycle);
        }

        bool success = wallet.payWithToken(
            tokenAddress,
            subscriptions[subscriptionId].user,
            subscriptions[subscriptionId].merchant,
            tokenPayment,
            true
        );

        require(success, "Payment failed");

        subscriptions[subscriptionId].status = Status.ACTIVE;
        subscriptions[subscriptionId].lastPaymentDate = block.timestamp;
        subscriptions[subscriptionId].successPaymentsAmount = subscriptions[
            subscriptionId
        ].successPaymentsAmount.add(1);

        if (
            subscriptions[subscriptionId].successPaymentsAmount ==
            subscriptions[subscriptionId].cycles &&
            !subscriptions[subscriptionId].unlimited
        ) {
            subscriptions[subscriptionId].status = Status.END;
        }

        emit SubscriptionPaid(
            subscriptions[subscriptionId].user,
            subscriptions[subscriptionId].merchant,
            subscriptionId,
            rebillID,
            tokenAddress,
            tokenPayment,
            tokenPrice
        );
    }

    function pauseProductAsMerchant(
        bytes32 productId,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {
        productPaused[productId] = true;
        emit PauseProductByMerchant(productId, processID);
    }

    function unpauseProductAsMerchant(
        bytes32 productId,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {
        productPaused[productId] = false;
        emit UnpauseProductByMerchant(productId, processID);
    }

    function unsubscribeAsMerchant(
        bytes32[] calldata subscriptionIds,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {
        for (uint256 i = 0; i < subscriptionIds.length; i++) {
            cancelSubscription(subscriptionIds[i], processID);
        }
    }

    function resubscribeAsMerchant(
        bytes32[] calldata subscriptionIds,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {
        for (uint256 i = 0; i < subscriptionIds.length; i++) {
            activateSubscription(subscriptionIds[i], processID);
        }
    }

    function pauseSubscriptionsAsMerchant(
        bytes32[] calldata subscriptionIds,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {
        for (uint256 i = 0; i < subscriptionIds.length; i++) {
            bytes32 subscription = subscriptionIds[i];
            require(
                subscriptions[subscription].status != Status.PAUSED &&
                    subscriptions[subscription].status != Status.UNSUBSCRIBED,
                "Subscription is already paused"
            );

            subscriptions[subscription].status = Status.PAUSED;
            emit PauseSubscriptionByMerchant(subscription, processID);

        }
    }

    function unpauseSubscriptionsAsMerchant(
        bytes32[] calldata subscriptionIds,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {
        for (uint256 i = 0; i < subscriptionIds.length; i++) {
            bytes32 subscription = subscriptionIds[i];
            require(
                subscriptions[subscription].status == Status.PAUSED &&
                    subscriptions[subscription].status != Status.UNSUBSCRIBED,
                "Subscription is not paused"
            );

            subscriptions[subscription].status = Status.ACTIVE;

            // Is this intended to emit product ID?
            emit UnpauseSubscriptionByMerchant(
                subscription,
                processID
            );
        }
    }

    function cancelSubscription(
        bytes32 subscriptionId,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {
        if (
            subscriptions[subscriptionId].status == Status.ACTIVE ||
            subscriptions[subscriptionId].status == Status.PAUSED
        ) {
            subscriptions[subscriptionId].status = Status.UNSUBSCRIBED;

            emit CancelSubscription(
                subscriptions[subscriptionId].user,
                subscriptionId,
                processID
            );
        }
    }

    function pauseSubscription(
        bytes32 subscriptionId,
        uint256 processID,
        address tokenAddress,
        uint256 tokenPrice
    ) public onlyAuthorized whenNotPaused {
        require(
            subscriptions[subscriptionId].status != Status.PAUSED &&
                subscriptions[subscriptionId].status != Status.UNSUBSCRIBED,
            "Subscription is already paused"
        );

        subscriptions[subscriptionId].status = Status.PAUSED;

        uint256 totalValue = subscriptions[subscriptionId].price.mul(125).div(
            1000
        );
        uint256 merchantValue = subscriptions[subscriptionId]
            .price
            .mul(100)
            .div(1000);

        uint256 totalTokens = (totalValue.mul(10 ** 18)).div(tokenPrice);
        uint256 merchantAmount = (merchantValue.mul(10 ** 18)).div(tokenPrice);
        bool successMerchant = wallet.payWithToken(
            tokenAddress,
            subscriptions[subscriptionId].user,
            subscriptions[subscriptionId].merchant,
            merchantAmount,
            true
        );
        require(successMerchant, "Pause payment to merchant failed.");
        bool successFee = wallet.payWithToken(
            tokenAddress,
            subscriptions[subscriptionId].user,
            feeWallet,
            totalTokens.sub(merchantAmount),
            false
        );
        require(successFee, "Pause payment to fee wallet failed.");
        emit PauseSubscriptionByCustomer(
            subscriptions[subscriptionId].user,
            subscriptionId,
            processID,
            tokenAddress,
            tokenPrice
        );
    }

    function activateSubscription(
        bytes32 subscriptionId,
        uint256 processID
    ) public onlyAuthorized whenNotPaused {

        // require was previously: subscriptions[subscriptionId].status != Status.UNSUBSCRIBED
        // should be intended to only revert if status is not UNSUBSCRIBED

        require(
            subscriptions[subscriptionId].status == Status.UNSUBSCRIBED,
            "Subscription must be unsubscribed"
        );
        subscriptions[subscriptionId].status = Status.ACTIVE;
        emit ActivateSubscription(
            subscriptions[subscriptionId].user,
            subscriptionId,
            processID
        );
    }

    function getSubscriptionStatus(
        bytes32 subscriptionId
    ) external view returns (uint256) {
        return uint256(subscriptions[subscriptionId].status);
    }

    modifier onlyAuthorized() {
        require(
            hub.getAuthorizationStatus(msg.sender) || msg.sender == owner(),
            "Not authorized"
        );
        _;
    }

    modifier onlyHub() {
        require(msg.sender == address(hub), "Not authorized");
        _;
    }
}