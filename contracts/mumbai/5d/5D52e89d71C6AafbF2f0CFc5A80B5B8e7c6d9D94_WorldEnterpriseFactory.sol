// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

contract Authorizable {
    mapping(address => bool) private _authorized;

    modifier onlyAuthorized() {
        require(
            _authorized[msg.sender],
            "Authorizable: authorization error"
        );
        _;
    }

    function addAuthorized(address _toAdd) internal {
        require(
            _toAdd != address(0),
            "Authorizable: new owner is the zero address"
        );
        _authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) internal {
        require(
            _toRemove != address(0),
            "Authorizable: new owner is the zero address"
        );
        _authorized[_toRemove] = false;
    }

    function replaceAuthorized(address _fromAdmin, address _toReplace) internal {
        require(
            _toReplace != address(0),
            "Authorizable: new owner is the zero address"
        );
        _authorized[_fromAdmin] = false;
        _authorized[_toReplace] = true;
    }

    function authorized(address _user) public view returns (bool) {
        return _authorized[_user];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

library Enterprise {
    uint256 constant MAX_LENGTH = 100;

    enum CompanyType {
        LLC,
        CC,
        SC,
        NP,
        OT
    }

    struct Info {
        string logoImg;
        string enterpriseName;
        string description;
        bool isRG;
        CompanyType companyType;
        address admin;
        string ipfs;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
/**
____    __    ____  ______   .______      __       _______      _______ .__   __. .___________._______ .______     .______   .______      __       _______. _______ 
\   \  /  \  /   / /  __  \  |   _  \    |  |     |       \    |   ____||  \ |  | |           |   ____||   _  \    |   _  \  |   _  \    |  |     /       ||   ____|
 \   \/    \/   / |  |  |  | |  |_)  |   |  |     |  .--.  |   |  |__   |   \|  | `---|  |----|  |__   |  |_)  |   |  |_)  | |  |_)  |   |  |    |   (----`|  |__   
  \            /  |  |  |  | |      /    |  |     |  |  |  |   |   __|  |  . `  |     |  |    |   __|  |      /    |   ___/  |      /    |  |     \   \    |   __|  
   \    /\    /   |  `--'  | |  |\  \----|  `----.|  '--'  |   |  |____ |  |\   |     |  |    |  |____ |  |\  \----|  |      |  |\  \----|  | .----)   |   |  |____ 
    \__/  \__/     \______/  | _| `._____|_______||_______/    |_______||__| \__|     |__|    |_______|| _| `._____| _|      | _| `._____|__| |_______/    |_______|
 **/

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libs/Enterprise.sol";
import "./libs/Authorizable.sol";

contract WorldEnterprise is IERC20, Authorizable, Initializable {
    using Counters for Counters.Counter;

    enum ProposalStatus {
        NONE,
        ACTIVE,
        CANCELLED,
        FAILED,
        PASSED
    }

    enum OrderStatus {
        NONE,
        ACTIVE,
        CANCELLED,
        CLOSED
    }

    enum OrderType {
        BUY,
        SELL
    }

    enum ProposalType {
        ADD,
        REMOVE,
        REPLACE,
        MINT,
        NEW_SHAREHOLDER
    }

    struct Proposal {
        uint256 id;
        address owner;
        address admin;
        address candidate;
        uint256 amount;
        string commentUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 yes;
        uint256 no;
        ProposalStatus status;
        ProposalType pType;
    }

    struct Order {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 price;
        OrderType orderType;
        OrderStatus status;
    }

    Counters.Counter public proposalIndex;
    Counters.Counter public orderIndex;

    uint8 public decimals;

    // proposal delay time
    uint256 public proposalDelayTime;
    // treasury ether amount
    uint256 public treasuryAmount;

    Enterprise.Info public info;

    /**
     * proposal list
     * @dev mapping(proposal id => Proposal)
     **/
    mapping(uint256 => Proposal) public proposals;

    /**
     * proposal indices of proposer
     * @dev mapping(proposer address => indices)
     * */
    mapping(address => uint256[]) public proposalIndices;

    /**
     * vote info list
     * @dev mapping(proposal id => poroposer => status)
     * */
    mapping(uint256 => mapping(address => bool)) public votes;

    /**
     * order list
     * @dev mapping(order id => Order)
     **/
    mapping(uint256 => Order) public orders;

    /**
     * order indices by owner
     * @dev mapping(owner => indices)
     * */
    mapping(address => uint256[]) public orderIndices;

    /**
     *  `join world enterprise proposal id` => price
     * @dev join world enterprise prosal id is not line
     **/
    mapping(uint256 => uint256) public joinPriceList;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _tokenHolders;

    string private _name;
    string private _symbol;

    event JoinWorldEnterprise(
        uint256 proposalIndex,
        address indexed proposer,
        uint256 amount,
        uint256 price,
        string commentUrl,
        uint256 startTime,
        uint256 endTime
    );
    event ProposeNewShareHolder(
        uint256 proposalIndex,
        address indexed proposer,
        address indexed user,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    );
    event RequestAdminRole(
        uint256 proposalIndex,
        address indexed proposer,
        bool isAdd,
        uint256 startTime,
        uint256 endTime
    );
    event ProposeAdminRequest(
        uint256 proposalIndex,
        address indexed proposer,
        address indexed admin,
        address indexed candidate,
        ProposalType pType,
        uint256 startTime,
        uint256 endTime
    );
    event CancelProposal(uint256 proposalIndex);
    event VoteYes(address indexed account, uint256 proposalIndex);
    event VoteNo(address indexed account, uint256 proposalIndex);
    event ExecutePassed(
        uint256 proposalIndex,
        address indexed proposer,
        uint256 amount
    );
    event ExecuteAdminAddPassed(uint256 proposalIndex, address indexed admin);
    event ExecuteAdminRemovePassed(
        uint256 proposalIndex,
        address indexed admin
    );
    event ExecuteAdminReplacePassed(
        uint256 proposalIndex,
        address indexed admin,
        address indexed candidate
    );
    event ExecuteProposeNewShareHolder(
        uint256 proposalIndex,
        address indexed admin,
        address indexed user,
        uint256 amount
    );
    event ExecuteFailed(uint256 proposalIndex);
    event CreateBuyOrder(
        uint256 orderIndex,
        address indexed owner,
        uint256 amount,
        uint256 price
    );
    event CreateSellOrder(
        uint256 orderIndex,
        address indexed owner,
        uint256 amount,
        uint256 price
    );
    event CloseOrder(uint256 orderId);
    event CancelOrder(uint256 orderId);
    event Withdraw(address indexed owner, address indexed to, uint256 amount);
    event WithdrawToken(
        address indexed token,
        address indexed owner,
        address indexed to,
        uint256 amount
    );
    event UpdateInfo(address indexed owner, Enterprise.Info info);
    event EditProposal(
        uint256 proposalIndex,
        address indexed admin,
        address indexed candidate,
        uint256 amount,
        string commentUrl
    );
    event ReceiveEther(address indexed from, uint256 amount);

    modifier checkInfo(Enterprise.Info memory info_) {
        require(
            bytes(info_.enterpriseName).length < Enterprise.MAX_LENGTH,
            "WE: Error max length"
        );
        require(
            bytes(info_.ipfs).length < Enterprise.MAX_LENGTH,
            "WE: IPFS error"
        );
        _;
    }

    constructor() {}

    function initialize(
        address[] calldata admins,
        address[] calldata users,
        uint256[] calldata shares,
        string calldata name_,
        string calldata symbol_,
        Enterprise.Info calldata info_
    ) external checkInfo(info_) initializer {
        require(admins.length > 0, "WE: Admins length zero");
        require(users.length > 0, "WE: Users length zero");
        require(users.length == shares.length, "WE: Shares length error");

        _name = name_;
        _symbol = symbol_;
        info = info_;

        decimals = 18;
        proposalDelayTime = 60 * 60 * 24 * 7 * 2; // 2 weeks

        for (uint256 i; i < admins.length; i++) {
            addAuthorized(admins[i]);
        }

        for (uint256 i; i < users.length; i++) {
            _mint(users[i], shares[i]);
        }

        emit UpdateInfo(msg.sender, info);
    }

    function voteThreshold() public view returns (uint256) {
        if (_tokenHolders > 5) {
            return 5;
        }
        return _tokenHolders;
    }

    /**
     * Update information of Enterprise
     */
    function updateInfo(
        Enterprise.Info memory info_
    ) external checkInfo(info_) onlyAuthorized {
        info = info_;
        emit UpdateInfo(msg.sender, info);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "WE: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @param amount propose amount
     * @dev create a propose to join world enterprise
     *
     **/
    function joinWorldEnterprise(
        uint256 amount,
        uint256 price,
        string memory commentUrl
    ) external payable {
        require(amount > 0, "WE: Zero amount");
        if (price > 0) {
            require(price == msg.value, "WE: Insufficiant fund");
        }

        uint256 _proposalIndex = proposalIndex.current();
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + proposalDelayTime;

        if (price > 0) {
            joinPriceList[_proposalIndex] = price;
            treasuryAmount += price;
        }

        Proposal memory _proposal = Proposal({
            id: _proposalIndex,
            owner: msg.sender,
            admin: address(0),
            candidate: address(0),
            amount: amount,
            commentUrl: commentUrl,
            startTime: _startTime,
            endTime: _endTime,
            yes: 0,
            no: 0,
            status: ProposalStatus.ACTIVE,
            pType: ProposalType.MINT
        });

        proposals[_proposalIndex] = _proposal;
        proposalIndices[msg.sender].push(_proposalIndex);

        proposalIndex.increment();

        emit JoinWorldEnterprise(
            _proposalIndex,
            msg.sender,
            amount,
            price,
            commentUrl,
            _startTime,
            _endTime
        );
    }

    function proposeNewShareHolder(address user, uint256 amount) external {
        require(user != address(0), "WE: invalid user");
        require(amount != 0, "WE: invalid amount");
        require(balanceOf(msg.sender) > 0, "WE: Not share holder");

        uint256 _proposalIndex = proposalIndex.current();
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + proposalDelayTime;

        Proposal memory _proposal = Proposal({
            id: _proposalIndex,
            owner: msg.sender,
            admin: address(0),
            candidate: user,
            amount: amount,
            commentUrl: "",
            startTime: _startTime,
            endTime: _endTime,
            yes: 0,
            no: 0,
            status: ProposalStatus.ACTIVE,
            pType: ProposalType.NEW_SHAREHOLDER
        });

        proposals[_proposalIndex] = _proposal;
        proposalIndices[msg.sender].push(_proposalIndex);

        proposalIndex.increment();

        emit ProposeNewShareHolder(
            _proposalIndex,
            msg.sender,
            user,
            amount,
            _startTime,
            _endTime
        );
    }

    /**
     * @dev create a propose to be admin
     *
     **/
    function handleAdminRequest(bool isAdd) external {
        require(balanceOf(msg.sender) > 0, "WE: Not shareholder");
        require(authorized(msg.sender) != isAdd, "WE: invalid request");

        uint256 _proposalIndex = proposalIndex.current();
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + proposalDelayTime;
        ProposalType _type = ProposalType.ADD;
        if (!isAdd) {
            _type = ProposalType.REMOVE;
        }
        Proposal memory _proposal = Proposal({
            id: _proposalIndex,
            owner: msg.sender,
            admin: msg.sender,
            candidate: address(0),
            amount: 0,
            commentUrl: "",
            startTime: _startTime,
            endTime: _endTime,
            yes: 0,
            no: 0,
            status: ProposalStatus.ACTIVE,
            pType: _type
        });

        proposals[_proposalIndex] = _proposal;
        proposalIndices[msg.sender].push(_proposalIndex);

        proposalIndex.increment();

        emit RequestAdminRole(
            _proposalIndex,
            msg.sender,
            isAdd,
            _startTime,
            _endTime
        );
    }

    /**
     * @param _proposalIndex proposal index
     * @param _status vote status
     * @dev vote proposal
     **/
    function vote(uint256 _proposalIndex, bool _status) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(_proposal.status == ProposalStatus.ACTIVE, "WE: Not active");
        require(block.timestamp < _proposal.endTime, "WE: Time error");
        require(balanceOf(msg.sender) > 0, "WE: Not shareholder");
        require(!votes[_proposalIndex][msg.sender], "WE: Already voted");

        if (_proposal.pType != ProposalType.MINT) {
            require(_proposal.owner != msg.sender, "Invalid vote");
        }

        if (_status) {
            _proposal.yes++;
        } else {
            _proposal.no++;
        }

        votes[_proposalIndex][msg.sender] = true;
        if (_status) {
            emit VoteYes(msg.sender, _proposalIndex);
        } else {
            emit VoteNo(msg.sender, _proposalIndex);
        }
    }

    /**
     * @param _proposalIndex proposal index
     * @dev execute proposal
     **/
    function execute(uint256 _proposalIndex) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(_proposal.status == ProposalStatus.ACTIVE, "WE: Not active");

        if (
            !(_proposal.yes * 2 <= _tokenHolders ||
                _proposal.no * 2 <= _tokenHolders)
        ) {
            require(
                block.timestamp >= _proposal.endTime,
                "WE: You can execute after the end time"
            );
        }

        uint256 _voteThreshold = voteThreshold();

        if (_proposal.no < _proposal.yes && _voteThreshold <= _proposal.yes) {
            _proposal.status = ProposalStatus.PASSED;

            if (_proposal.pType == ProposalType.MINT) {
                if (joinPriceList[_proposalIndex] > 0) {
                    treasuryAmount -= joinPriceList[_proposalIndex];
                }

                _mint(_proposal.owner, _proposal.amount);
                emit ExecutePassed(
                    _proposalIndex,
                    _proposal.owner,
                    _proposal.amount
                );
            } else if (_proposal.pType == ProposalType.ADD) {
                addAuthorized(_proposal.admin);
                emit ExecuteAdminAddPassed(_proposalIndex, _proposal.admin);
            } else if (_proposal.pType == ProposalType.REMOVE) {
                removeAuthorized(_proposal.admin);
                emit ExecuteAdminRemovePassed(_proposalIndex, _proposal.admin);
            } else if (_proposal.pType == ProposalType.REPLACE) {
                replaceAuthorized(_proposal.admin, _proposal.candidate);
                emit ExecuteAdminReplacePassed(
                    _proposalIndex,
                    _proposal.admin,
                    _proposal.candidate
                );
            } else if (_proposal.pType == ProposalType.NEW_SHAREHOLDER) {
                _mint(_proposal.candidate, _proposal.amount);
                emit ExecuteProposeNewShareHolder(
                    _proposalIndex,
                    _proposal.admin,
                    _proposal.candidate,
                    _proposal.amount
                );
            }
        } else {
            _proposal.status = ProposalStatus.FAILED;

            if (
                _proposal.pType == ProposalType.MINT &&
                joinPriceList[_proposalIndex] > 0
            ) {
                treasuryAmount -= joinPriceList[_proposalIndex];

                (bool success, ) = (_proposal.owner).call{
                    value: joinPriceList[_proposalIndex]
                }("");
                require(success, "WE: send price error");
            }

            emit ExecuteFailed(_proposalIndex);
        }
    }

    /**
     * @param amount token amount
     * @param price price (unit is gwei)
     * @dev create buy order
     **/
    function createBuyOrder(uint256 amount, uint256 price) external payable {
        require(amount > 0, "WE: Amount should be greater than the zero");
        require(price > 0, "WE: Price is zero");
        require(
            msg.value >= (amount * price) / 10 ** 9,
            "WE: Insufficent deposit"
        );

        treasuryAmount += (amount * price) / 10 ** 9;

        uint256 _orderIndex = orderIndex.current();
        Order memory _order = Order({
            id: _orderIndex,
            owner: msg.sender,
            amount: amount,
            price: price,
            orderType: OrderType.BUY,
            status: OrderStatus.ACTIVE
        });

        orders[_orderIndex] = _order;

        orderIndices[msg.sender].push(_orderIndex);

        orderIndex.increment();

        emit CreateBuyOrder(_orderIndex, msg.sender, amount, price);
    }

    /**
     * @param amount token amount
     * @param price price
     * @dev create buy order
     **/
    function createSellOrder(uint256 amount, uint256 price) external {
        require(amount > 0, "WE: Zero amount");
        require(price > 0, "WE: Zero price");
        require(balanceOf(msg.sender) >= amount, "WE: Insufficient balanace");
        require(
            allowance(msg.sender, address(this)) >= amount,
            "WE: Insufficient allowance"
        );

        _spendAllowance(msg.sender, address(this), amount);
        _transfer(msg.sender, address(this), amount);

        uint256 _orderIndex = orderIndex.current();
        Order memory _order = Order({
            id: _orderIndex,
            owner: msg.sender,
            amount: amount,
            price: price,
            orderType: OrderType.SELL,
            status: OrderStatus.ACTIVE
        });

        orders[_orderIndex] = _order;

        orderIndices[msg.sender].push(_orderIndex);

        orderIndex.increment();

        emit CreateSellOrder(_orderIndex, msg.sender, amount, price);
    }

    /**
     * @param orderId order id
     * @dev close order
     **/
    function closeOrder(uint256 orderId) external payable {
        Order storage _order = orders[orderId];
        require(_order.status == OrderStatus.ACTIVE, "WE: Order not active");

        if (_order.orderType == OrderType.BUY) {
            require(
                balanceOf(msg.sender) >= _order.amount,
                "WE: Insufficient amount"
            );
            require(
                allowance(msg.sender, address(this)) >= _order.amount,
                "WE: Insufficient allowance"
            );

            _spendAllowance(msg.sender, address(this), _order.amount);
            _transfer(msg.sender, _order.owner, _order.amount);

            (bool success, ) = (msg.sender).call{
                value: (_order.price * _order.amount) / 10 ** 9
            }("");
            require(success, "WE: Withdraw token error");

            treasuryAmount -= (_order.price * _order.amount) / 10 ** 9;
        } else if (_order.orderType == OrderType.SELL) {
            require(
                msg.value >= (_order.price * _order.amount) / 10 ** 9,
                "WE: Insufficient ETH"
            );
            require(
                balanceOf(address(this)) >= _order.amount,
                "WE: Insufficient amount"
            );

            treasuryAmount += (_order.price * _order.amount) / 10 ** 9;

            _transfer(address(this), msg.sender, _order.amount);

            (bool success, ) = (_order.owner).call{
                value: (_order.price * _order.amount) / 10 ** 9
            }("");
            require(success, "WE: Withdraw token error");

            treasuryAmount -= (_order.price * _order.amount) / 10 ** 9;
        }

        _order.status = OrderStatus.CLOSED;

        emit CloseOrder(orderId);
    }

    /**
     * @param orderId order id
     * @dev cancel order
     **/
    function cancelOrder(uint256 orderId) external {
        Order storage _order = orders[orderId];

        require(_order.owner == msg.sender, "WE: Owner error");
        require(_order.status == OrderStatus.ACTIVE, "WE: Order Inactive");

        if (_order.orderType == OrderType.BUY) {
            (bool success, ) = (_order.owner).call{
                value: (_order.price * _order.amount) / 10 ** 9
            }("");
            require(success, "WE: Withdraw token error");
            treasuryAmount -= (_order.price * _order.amount) / 10 ** 9;
        } else if (_order.orderType == OrderType.SELL) {
            require(
                balanceOf(address(this)) >= _order.amount,
                "WE: Insufficient amount"
            );
            require(
                transfer(_order.owner, _order.amount),
                "WE: Withdraw failed"
            );
        }

        _order.status = OrderStatus.CANCELLED;

        emit CancelOrder(orderId);
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "WE: Zero address");
        require(to != address(0), "WE: Zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "WE: Invalid balance");

        uint256 _prevToBalance = _balances[to];

        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        if (_balances[from] == 0 && _tokenHolders != 0) {
            _tokenHolders--;
        }

        if (_prevToBalance == 0 && _balances[to] != 0) {
            _tokenHolders++;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "WE: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        if (_balances[account] == 0) {
            _tokenHolders++;
        }
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "WE: Zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "WE: Invalid balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "WE: Zero address");
        require(spender != address(0), "WE: Zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "WE: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdmin(
        address payable to,
        uint256 value
    ) external onlyAuthorized {
        require(
            address(this).balance > treasuryAmount,
            "WE: insufficient balacne"
        );
        require(
            value <= address(this).balance - treasuryAmount,
            "WE: Invalid amount"
        );
        to.transfer(value);
        emit Withdraw(msg.sender, to, value);
    }

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdminERC20(
        address token,
        address payable to,
        uint256 value
    ) external onlyAuthorized {
        require(
            value <= IERC20(token).balanceOf(address(this)),
            "WE: Invalid amount"
        );
        IERC20(token).transfer(to, value);

        emit WithdrawToken(token, msg.sender, to, value);
    }

    /**
     * @notice shareholders can create a proposal to manage admin rights
     * @dev create a proposal for admin management
     * @param _type proposal type - ADD, REMOVE, REPLACE
     * @param _admin address for admin rights change
     * @param _candidate candidate - only valid for replace request
     **/
    function proposeForAdminRequest(
        ProposalType _type,
        address _admin,
        address _candidate
    ) external {
        require(balanceOf(msg.sender) > 0, "WE: Not shareholder");

        require(_type != ProposalType.MINT, "WE: proposal type issue");

        if (_type == ProposalType.REMOVE || _type == ProposalType.REPLACE) {
            require(authorized(_admin), "WE: invalid REMOVE or ADD request");
        } else {
            require(!authorized(_admin), "WE: Invalid ADD request");
        }

        uint256 _proposalIndex = proposalIndex.current();
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + proposalDelayTime;

        Proposal memory _proposal = Proposal({
            id: _proposalIndex,
            owner: msg.sender,
            admin: _admin,
            candidate: _candidate,
            amount: 0,
            commentUrl: "",
            startTime: _startTime,
            endTime: _endTime,
            yes: 0,
            no: 0,
            status: ProposalStatus.ACTIVE,
            pType: _type
        });

        proposals[_proposalIndex] = _proposal;
        proposalIndices[msg.sender].push(_proposalIndex);

        proposalIndex.increment();

        emit ProposeAdminRequest(
            _proposalIndex,
            msg.sender,
            _admin,
            _candidate,
            _type,
            _startTime,
            _endTime
        );
    }

    function cancelProposal(uint256 _proposalIndex) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(
            _proposal.status == ProposalStatus.ACTIVE,
            "WE: Proposal not active"
        );
        require(_proposal.owner == msg.sender, "WE: Not proposal owner");
        require(_proposal.yes == 0 && _proposal.no == 0, "WE: Can not cancel");

        _proposal.status = ProposalStatus.CANCELLED;

        emit CancelProposal(_proposalIndex);
    }

    function editProposal(
        uint256 _proposalIndex,
        address _admin,
        address _candidate,
        uint256 _amount,
        string calldata _commentUrl
    ) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(
            _proposal.status == ProposalStatus.ACTIVE,
            "WE: Proposal not active"
        );
        require(_proposal.owner == msg.sender, "WE: Not proposal owner");
        require(
            _proposal.status == ProposalStatus.ACTIVE,
            "WE: proposal is not active"
        );
        require(_proposal.yes == 0 && _proposal.no == 0, "WE: Can not edit");

        _proposal.admin = _admin;
        _proposal.candidate = _candidate;
        _proposal.amount = _amount;
        _proposal.commentUrl = _commentUrl;

        emit EditProposal(
            _proposalIndex,
            _admin,
            _candidate,
            _amount,
            _commentUrl
        );
    }

    receive() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/**
____    __    ____  ______   .______      __       _______      _______ .__   __. .___________._______ .______     .______   .______      __       _______. _______ 
\   \  /  \  /   / /  __  \  |   _  \    |  |     |       \    |   ____||  \ |  | |           |   ____||   _  \    |   _  \  |   _  \    |  |     /       ||   ____|
 \   \/    \/   / |  |  |  | |  |_)  |   |  |     |  .--.  |   |  |__   |   \|  | `---|  |----|  |__   |  |_)  |   |  |_)  | |  |_)  |   |  |    |   (----`|  |__   
  \            /  |  |  |  | |      /    |  |     |  |  |  |   |   __|  |  . `  |     |  |    |   __|  |      /    |   ___/  |      /    |  |     \   \    |   __|  
   \    /\    /   |  `--'  | |  |\  \----|  `----.|  '--'  |   |  |____ |  |\   |     |  |    |  |____ |  |\  \----|  |      |  |\  \----|  | .----)   |   |  |____ 
    \__/  \__/     \______/  | _| `._____|_______||_______/    |_______||__| \__|     |__|    |_______|| _| `._____| _|      | _| `._____|__| |_______/    |_______|
 **/
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WorldEnterprise.sol";

contract WorldEnterpriseFactory is Ownable {
    using Counters for Counters.Counter;

    // enterprise index
    Counters.Counter public index;

    /**
     * world enterprise list
     * @dev mapping(world enterprise index => WorldEnterprise)
     **/
    mapping(uint256 => address) public worldEnterprises;
    /**
     * @dev is world enterprise
     **/
    mapping(address => bool) public isWorldEnterprise;

    event CreateWorldEnterprise(
        uint256 index,
        address[] admins,
        address[] users,
        uint256[] shares,
        string name,
        string symbol,
        address indexed enterprise,
        Enterprise.Info info
    );
    /**
     *  Emitted when Withdraw
     */
    event Withdraw(address indexed owner, address indexed to, uint256 amount);
    /**
     *  Emitted when WithdrawERC20
     */
    event WithdrawToken(
        address indexed token,
        address indexed owner,
        address indexed to,
        uint256 amount
    );

    /**
     * @param users shareholders user array
     * @param shares amount array of shareholders
     * @param tokenName ERC20 token name
     * @param symbol ERC20 token symbol
     *
     * @dev create a new world enterprise
     **/
    function createWorldEnterprise(
        address[] memory admins,
        address[] calldata users,
        uint256[] calldata shares,
        string calldata tokenName,
        string calldata symbol,
        Enterprise.Info calldata info
    ) external {
        bytes memory bytecode = type(WorldEnterprise).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(admins, block.number, index.current() + 1)
        );

        address payable weAddress;

        assembly {
            weAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        WorldEnterprise(weAddress).initialize(
            admins,
            users,
            shares,
            tokenName,
            symbol,
            info
        );

        worldEnterprises[index.current()] = weAddress;
        isWorldEnterprise[weAddress] = true;

        index.increment();

        emit CreateWorldEnterprise(
            index.current() - 1,
            admins,
            users,
            shares,
            tokenName,
            symbol,
            weAddress,
            info
        );
    }

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdmin(
        address payable to,
        uint256 value
    ) external onlyOwner {
        require(to != address(0), "WEF: Zero address");
        require(value <= address(this).balance, "WEF: Invalid amount");
        to.transfer(value);
        emit Withdraw(owner(), to, value);
    }

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdminERC20(
        address token,
        address payable to,
        uint256 value
    ) external onlyOwner {
        require(to != address(0), "WEF: Zero address");
        require(
            value <= IERC20(token).balanceOf(address(this)),
            "WEF: Invalid amount"
        );
        IERC20(token).transfer(to, value);

        emit WithdrawToken(token, owner(), to, value);
    }

    receive() external payable {}
}