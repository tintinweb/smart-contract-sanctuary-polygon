/// @title Convert Currency & Time on-chain
/// @author Stephen Taylor
/// @notice This plugin unlocks TheCoin from being tied to the stock
/// market.  It allows converting currencies online and implements
/// a delayable non-revokable allowance to permit Brokers to complete
/// payments outside of trading hours, letting the trades settle at the
/// time specified.

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import '@thecointech/contract-oracle/contracts/OracleClient.sol';
import '@thecointech/contract-plugins/contracts/BasePlugin.sol';
import '@thecointech/contract-plugins/contracts/permissions.sol';
import '@thecointech/contract-plugins/contracts/IPluggable.sol';

struct PendingTransactions {
  // The currency code of the value (eg 124 for $CAD)
  // uint8 currency;
  // For now, just assume CAD
  // We could (?) provide a new Converter per-currency?
  // The total value owed to all users (in currency)
  uint total;
  // to => timestamp => value
  mapping(address => mapping(uint => uint)) transfers;
}


contract UberConverter is BasePlugin, OracleClient, OwnableUpgradeable, PermissionUser {

  // We list "to" first, as that is the value most likely to be repeated
  // From => { To => Timestamp => Value }
  mapping(address => PendingTransactions) pending;

  // Link back to core contract.
  IPluggable internal theCoin;

  // The currency code this client supports.
  uint16 constant CurrencyCode = 124;

  function initialize(address baseContract, address oracle) public initializer {
    __Ownable_init();

    setFeed(oracle);
    theCoin = IPluggable(baseContract);
  }

  // ------------------------------------------------------------------------
  // TESTING FUNCTIONS - REMOVE PRIOR TO PROD PUBLISH
  // ------------------------------------------------------------------------
  function seedPending(address from, address to, uint amount, uint msTransferAt, uint msSignedAt) public onlyOwner{
    // This can only run on testing blockchains.
    require(block.chainid == 0x13881 || block.chainid == 31337, "testing only");
    pending[from].transfers[to][msTransferAt] = pending[from].transfers[to][msTransferAt] + amount;
    pending[from].total = pending[from].total + amount;
    emit ValueChanged(from, msSignedAt, "pending[user].total", int(pending[from].total));
  }

  // ------------------------------------------------------------------------
  // IPlugin Implementation
  // ------------------------------------------------------------------------
  // We modify transfers
  function getPermissions() override external pure returns(uint) {
    return PERMISSION_AUTO_ACCESS & PERMISSION_WITHDRAWAL;
  }

  function userDetached(address exClient, address /*initiator*/) override external onlyBaseContract {
    // Total == 0 means no transfers remaining
    require(pending[exClient].total == 0, "Cannot remove plugin while a transaction is pending");
    delete pending[exClient];
  }

  // We automatically modify the balance to adjust for market fluctuations.
  function balanceOf(address user, int currentBalance) external view override returns(int)
  {
    PendingTransactions storage userPending = pending[user];
    if (userPending.total != 0) {
      // How much does our owed amount turn into?
      uint owed = toCoin(userPending.total, msNow());
      return currentBalance - int(owed);
    }
    return currentBalance;
  }

  //
  // What do we want to do about this particular transaction?
  function modifyTransfer(address from, address to, uint amount, uint16 currency, uint msTransferAt, uint msSignedAt)
    external override onlyBaseContract
    returns (uint finalAmount, uint16 finalCurrency)
  {
    (finalAmount, finalCurrency) = (amount, currency);
    // We only care about CAD  transactions
    if (currency == CurrencyCode) {

      // If this is scheduled to happen in the future?
      if (msTransferAt > msNow()) {
        pending[from].transfers[to][msTransferAt] = pending[from].transfers[to][msTransferAt] + amount;
        pending[from].total = pending[from].total + amount;
        finalAmount = 0;
        emit ValueChanged(from, msSignedAt, "pending[user].total", int(pending[from].total));
      }
      // Happening now, so convert to Coin
      else {
        finalAmount = toCoin(amount, msTransferAt);
        finalCurrency = 0;
      }
    }
    return (finalAmount, finalCurrency);
  }

  // This function can be safely made public as it can only
  // process transactions that have already been registered
  function processPending(address from, address to, uint msTime) public
  {
    require(msTime <= msNow(), "Cannot process future transactions");

    PendingTransactions storage user = pending[from];
    uint fiat = user.transfers[to][msTime];
    if (fiat > 0) {
      uint coin = uint(toCoin(fiat, msTime));
      theCoin.pl_transferFrom(from, to, coin, msTime);
      delete user.transfers[to][msTime];
      user.total = user.total - fiat;
      emit ValueChanged(from, msTime, "pending[user].total", int(user.total));
    }
  }

  // ------------------------------------------------------------------------
  // Pending transactions prevent withdrawals
  // ------------------------------------------------------------------------
  function preWithdraw(address user, uint balance, uint coin, uint msTime) public virtual override returns(uint) {
    uint userPending = pending[user].total;
    if (userPending != 0) {
      // How much does our owed amount turn into?
      uint owed = toCoin(userPending, msTime);
      require((owed + coin) <= balance, "Cannot withdraw, exceeds balance");
      return balance - owed;
    }
    return balance;
  }

  // ------------------------------------------------------------------------
  // Modifiers
  // ------------------------------------------------------------------------
  modifier onlyBaseContract()
  {
    require(msg.sender == address(theCoin), "Only callable from the base contract");
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

/// @title Oracle client library
/// @author Stephen Taylor
/// @notice Simple library intended to add fiat conversion to plugins
/// @dev Makes it easier to convert from TC to fiat on-chain

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;
import './AggregatorV3Interface.sol';

contract OracleClient {

  // SPX->CAD price feed.  Updated irregularily.
  // Only valuable for use with TheCoin
  AggregatorV3Interface internal priceFeed;

  function setFeed(address oracle) internal {
    priceFeed = AggregatorV3Interface(oracle);
  }

  // Convert to fiat with 2 decimal places (ie, floor to cent)
  function toFiat(int coin, uint millis) public view returns(int) {
    uint price = getPrice(millis);
    // coin is 6 decimal places, price is 8 decimal places
    // 1 coin at exchange of 4 would be 1*10e6 * 4*10e8
    // to be 4*10e14 / 10e12 to be 400 cents.
    return (coin * int(price) / 1e12);
  }

  function toFiat(uint coin, uint millis) public view returns(uint) {
    uint price = getPrice(millis);
    // coin is 6 decimal places, price is 8 decimal places
    // 1 coin at exchange of 4 would be 1*10e6 * 4*10e8
    // to be 4*10e14 / 10e12 to be 400 cents.
    return (coin * price / 1e12);
  }

  // convert to coin.  Fiat should be denominated in cents
  function toCoin(uint fiat, uint millis) public view returns(uint) {
    uint price = getPrice(millis);
    return fiat * 1e12 / price;
  }
  function toCoin(int fiat, uint millis) public view returns(int) {
    uint price = getPrice(millis);
    return fiat * 1e12 / int(price);
  }

  /**
    * Returns the latest price
    */
  function getPrice(uint millis) public view returns(uint) {
    uint price = priceFeed.getRoundFromTimestamp(millis);
    return price;
  }
}

/**
 * De-duplicate implementation of supportsInterface
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IPlugin.sol";

abstract contract BasePlugin is IPlugin {

  bytes4 public constant IID_PLUGIN = type(IPlugin).interfaceId;
  bytes4 public constant IID_ERC165 = type(IPlugin).interfaceId;

  event ValueChanged(address indexed user, uint msTime, string path, int change);

  // suppport ERC165
  function supportsInterface(bytes4 interfaceID) override external pure returns (bool)
  {
    return (
      interfaceID == IID_ERC165 || interfaceID == IID_PLUGIN
    );
  }

  function msNow() public view returns(uint) { return block.timestamp * 1000; }

  // Default empty implementations allow clients to ignore fns they dont use
  function userAttached(address user, uint, address) virtual external override {}
  function userDetached(address user, address) virtual external override {}
  function preDeposit(address, uint, uint, uint) virtual external override {}
  function preWithdraw(address, uint balance, uint, uint) virtual external override returns(uint)
  { return balance; }
  function balanceOf(address, int currentBalance) virtual external view override returns(int)
  { return currentBalance; }
  function modifyTransfer(address, address, uint amount, uint16 currency, uint, uint) virtual external override returns (uint, uint16)
  { return (amount, currency); }
}

/**
 * List bit-wise user permissions
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract PermissionUser {
  // A contract may modify the users reported balance.  This does
  // not modify the actual amount, but may be useful for contracts
  // that (for example) encourage saving by hiding the users profit.
  // If a plugin increases the user balance, it is the responsibility
  // of the plugin to ensure that transactions over the real balance
  // succeed by transferring to the user in the pre-transfer hook
  uint constant PERMISSION_BALANCE = 1 << 0;

  // A plugin may take actions during a deposit.
  // Use case: reserving a portion of the deposit for saving, unlocking rewards etc
  uint constant PERMISSION_DEPOSIT = 1 << 1;

  // A plugin may take actions during a withdrawal.  This has similar
  // Use case: similar to deposit permission (is it redundant?)
  uint constant PERMISSION_WITHDRAWAL = 1 << 2;

  // A plugin may be used to automatically approve/decline transactions.
  // Use case: set spending limits, external lock on accounts, etc.
  // Permissions can only be applied to withdrawals, there is no
  // system in place to prevent deposits.
  uint constant PERMISSION_APPROVAL = 1 << 3;

  // An auto-access plugin may make un-attended transfers on the users
  // account once per calendar year.  This plugin will have full access
  // to the users account.
  // Use case: Inheritance/fail-over accounts (setup a backup account that can pull
  // your funds in case of lost access to account)
  uint constant PERMISSION_AUTO_ACCESS = 1 << 4;
}




// PACKED DATA
// Proposal: Bits 16 - 32 are used to define which day of the year (UTC-only) the
// plugin is allowed to interact with the users account.
// Use case: Time-Limiting may reduce the risk of an auto-access plugin doing a rug-pull.
// For example, a popular inheritance plugin is upgradeable and is modified
// to transfer to the owner instead of designated account.  If the user
// has only granted permission on 1 day of the year, we mitigate potential
// damages to 1/365 of worst case.

// Propsal: bits 32 - 64 represent maximum transfer value for plugin in TC * 1000.
// If set to 0, maximum transfer is unlimited.  Max limit ~$250
// Use case: Limit on plugins decreases risk.

/**
 * A plugin interface that can be added to a users account
 * Plugins are contracts that can modify user transactions
 * on the fly.
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IPlugin.sol";

// TODO: Pack this tightly
struct PluginAndPermissions {
  // Plugin address (20bytes)
  IPlugin plugin;

  // The permissions the user has granted to
  // the plugin.  These permissions persist
  // even if the plugin changes to request
  // other permissions.
  uint96 permissions;
}


struct AssignRequest {
  address user;
  uint chainId;
  address plugin;
  uint timeMs;
  uint96 permissions;
  uint msSignedAt;
  bytes signature;
}

struct RemoveRequest {
  address user;
  uint chainId;
  uint index;
  uint msSignedAt;
  bytes signature;
}


/// @title Interface to allow plugins to interop with base contract
/// @author TheCoin
/// @dev Plugin-specific versions allow plugins to do stuff ordinary users can't do.
interface IPluggable is IERC20Upgradeable {

  event PluginAttached(address add, address plugin);
  event PluginDetached(address det, address plugin);

  // Assign new plugin to user.  Currently un-guarded.
  // Signature is of [user, plugin, permissions, lastTxTimestamp]
  function pl_assignPlugin(AssignRequest calldata request) external;

  // Remove plugin from user.  As above
  // Signature is of [user, plugin, lastTxTimestamp]
  function pl_removePlugin(RemoveRequest calldata request) external;

  // Users balance as reported by plugins
  function pl_balanceOf(address user) external view returns(int);

  // A special-purpose plugin transfer fn, in case we need to restrict it later(?)
  function pl_transferTo(address user, uint amount, uint timeMillis) external;

  // Allow a plugin to transfer money out of a users account.
  // Somehow, this needs to be locked to only allow a plugin that
  // is currently being queried to access the account of the user
  // who is currently engaging to function.  This could be achieved
  // either by saving local state, or by (better) passing an argument
  // through the stack that uniquely indentifies this request.
  function pl_transferFrom(address user, address to, uint amount, uint256 timeMillis) external;

  function getUsersPlugins(address user) external view returns(PluginAndPermissions[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// src: https://raw.githubusercontent.com/smartcontractkit/chainlink/master/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
// Interface matching chainlink oracles
// Ideally, we'll retire ours and support chainlinks version when it comes around.

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Custom TC function.  Only the Oracle can convert from
  // timestamp to roundId, so we might as well encapsulate it here.
  function getRoundFromTimestamp(uint millis)
    external
    view
    returns (uint answer);
}

/**
 * A plugin interface that can be added to a users account
 * Plugins are contracts that can modify user transactions
 * on the fly.
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPlugin is IERC165 {

  // An interface has a list of permissions that it must request

  // Get the permissions requested by this plugin over users account.
  // A user must sign these permissions and store with their account on TC.
  function getPermissions() external view returns(uint);

  // Hook called whenever a user adds a plugin to their account.
  function userAttached(address add, uint timeMs, address initiator) external;

  // Hook called whenever a user removes a plugin from their account
  function userDetached(address remove, address initiator) external;

  // A plugin may modify the users reported balance.
  // Requires PERMISSION_BALANCE
  function balanceOf(address user, int currentBalance) external view returns(int);

  // A plugin may take actions in response to user transfer.  Eg - it may
  // automatically top up the account, restrict the transfer, or perform
  // some other kind of action.
  // requires PERMISSION_DEPOSIT/PERMISSION_WITHDRAWAL/PERMISSION_APPROVAL
  function preDeposit(address user, uint balance, uint coin, uint msTime) external;
  function preWithdraw(address user, uint balance, uint coin, uint msTime) external returns(uint);

  function modifyTransfer(address from, address to, uint amount, uint16 currency, uint msTransferAt, uint msSignedAt) external returns (uint, uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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