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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IOparcade.sol";

/**
 * @title GameRegistry
 * @notice This contract stores all info related to the game and tournament
 * @author David Lee
 */
contract GameRegistry is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event GameAdded(
    address indexed by,
    uint256 indexed gid,
    string gameName,
    address indexed gameCreator,
    uint256 baseGameCreatorFee
  );
  event GameRemoved(
    address indexed by,
    uint256 indexed gid,
    string gameName,
    address indexed gameCreator,
    uint256 baseGameCreatorFee
  );
  event GameCreatorUpdated(
    address indexed by,
    uint256 indexed gid,
    address indexed oldGameCreator,
    address newGameCreator
  );
  event BaseGameCreatorFeeUpdated(
    address indexed by,
    uint256 indexed gid,
    uint256 indexed oldBaseGameCreatorFee,
    uint256 newBaseGameCreatorFee
  );
  event TournamentCreated(
    address indexed by,
    uint256 indexed gid,
    uint256 indexed tid,
    uint256 appliedGameCreatorFee,
    uint256 tournamentCreatorFee
  );
  event DepositAmountUpdated(
    address indexed by,
    uint256 indexed gid,
    uint256 indexed tid,
    address token,
    uint256 oldAmount,
    uint256 newAmount
  );
  event DistributableTokenAddressUpdated(
    address indexed by,
    uint256 indexed gid,
    address indexed token,
    bool oldStatus,
    bool newStatus
  );
  event PlatformFeeUpdated(
    address indexed by,
    address indexed oldFeeRecipient,
    uint256 oldPlatformFee,
    address indexed newFeeRecipient,
    uint256 newPlatformFee
  );
  event TournamentCreationFeeUpdated(
    address indexed by,
    address indexed oldTournamentCreationFeeToken,
    uint256 oldTournamentCreationFeeAmount,
    address indexed newTournamentCreationFeeToken,
    uint256 newTournamentCreationFeeAmount
  );

  /// @dev Game name array
  string[] public games;

  /// @dev Game ID -> Game creator
  mapping(uint256 => address) public gameCreators;

  /// @dev Game ID -> Base game creator fee
  mapping(uint256 => uint256) public baseGameCreatorFees;

  /// @dev Game ID -> Tournament ID -> Game creator fee applied to the tournament
  mapping(uint256 => mapping(uint256 => uint256)) public appliedGameCreatorFees;

  /// @dev Game ID -> Tournament creator list
  mapping(uint256 => address[]) public tournamentCreators;

  /// @dev Game ID -> Tournament ID -> Tournament creator fee
  mapping(uint256 => mapping(uint256 => uint256)) public tournamentCreatorFees;

  /// @dev Game ID -> Deposit token list
  mapping(uint256 => address[]) public depositTokenList;

  /// @dev Game ID -> Tournament ID -> Token address -> Deposit amount
  mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public depositTokenAmount;

  /// @dev Game ID -> Distributable token list
  mapping(uint256 => address[]) public distributableTokenList;

  /// @dev Game ID -> Token address -> Bool
  mapping(uint256 => mapping(address => bool)) public distributable;

  /// @dev Game ID -> Bool
  mapping(uint256 => bool) public isDeprecatedGame;

  /// @dev AddressRegistry
  IAddressRegistry public addressRegistry;

  /// @dev Platform fee recipient
  address public feeRecipient;

  /// @dev Platform fee
  uint256 public platformFee;

  /// @dev Tournament creation fee token address
  address public tournamentCreationFeeToken;

  /// @dev Tournament creation fee token amount
  uint256 public tournamentCreationFeeAmount;

  modifier onlyValidGID(uint256 _gid) {
    require(_gid < games.length && isDeprecatedGame[_gid] == false, "Invalid game index");
    _;
  }

  modifier onlyValidTID(uint256 _gid, uint256 _tid) {
    require(_tid < tournamentCreators[_gid].length, "Invalid tournament index");
    _;
  }

  function initialize(
    address _addressRegistry,
    address _feeRecipient,
    uint256 _platformFee,
    address _tournamentCreationFeeToken,
    uint256 _tournamentCreationFeeAmount
  ) public initializer {
    __Ownable_init();

    require(_feeRecipient != address(0) || _platformFee == 0, "Fee recipient not set");
    require(_platformFee <= 1000, "Platform fee exceeded");

    // initialize AddressRegistery
    addressRegistry = IAddressRegistry(_addressRegistry);

    // initialize fee and recipient
    feeRecipient = _feeRecipient;
    platformFee = _platformFee;
    tournamentCreationFeeToken = _tournamentCreationFeeToken;
    tournamentCreationFeeAmount = _tournamentCreationFeeAmount;
  }

  /**
   * @notice Add the new game
   * @param _gameName Game name to add
   * @param _gameCreator Game creator address
   * @param _baseGameCreatorFee Base game creator fee
   */
  function addGame(
    string calldata _gameName,
    address _gameCreator,
    uint256 _baseGameCreatorFee
  ) external onlyOwner returns (uint256 gid) {
    require(bytes(_gameName).length != 0, "Empty game name");
    require(_gameCreator != address(0), "Zero game creator address");
    require(platformFee + _baseGameCreatorFee < 1000, "Exceeded base game creator fee");

    // add the game
    games.push(_gameName);

    // set the gid
    gid = games.length - 1;

    // set the game creator address and fee
    gameCreators[gid] = _gameCreator;
    baseGameCreatorFees[gid] = _baseGameCreatorFee;

    emit GameAdded(msg.sender, gid, _gameName, _gameCreator, _baseGameCreatorFee);
  }

  /**
   * @notice Remove the exising game
   * @dev Game is not removed from the games array, just set it deprecated
   * @param _gid Game ID
   */
  function removeGame(uint256 _gid) external onlyOwner onlyValidGID(_gid) {
    // remove game
    isDeprecatedGame[_gid] = true;

    emit GameRemoved(msg.sender, _gid, games[_gid], gameCreators[_gid], baseGameCreatorFees[_gid]);
  }

  /**
   * @notice Update the game creator
   * @param _gid Game ID
   * @param _gameCreator Game creator address
   */
  function updateGameCreator(uint256 _gid, address _gameCreator) external onlyValidGID(_gid) {
    require(msg.sender == gameCreators[_gid], "Only game creator");
    require(_gameCreator != address(0), "Zero game creator address");

    emit GameCreatorUpdated(msg.sender, _gid, gameCreators[_gid], _gameCreator);

    // update the game creator address
    gameCreators[_gid] = _gameCreator;
  }

  /**
   * @notice Update the base game creator fee
   * @dev Tournament creator fee is the royality that will be transferred to the tournament creator address
   * @dev Tournament creator can propose the game creator fee when creating the tournament
   * @dev but it can't be less than the base game creator fee
   * @param _gid Game ID
   * @param _baseGameCreatorFee Base game creator fee
   */
  function updateBaseGameCreatorFee(uint256 _gid, uint256 _baseGameCreatorFee) external onlyOwner onlyValidGID(_gid) {
    require(platformFee + _baseGameCreatorFee < 1000, "Exceeded game creator fee");

    emit BaseGameCreatorFeeUpdated(msg.sender, _gid, baseGameCreatorFees[_gid], _baseGameCreatorFee);

    // update the game creator fee
    baseGameCreatorFees[_gid] = _baseGameCreatorFee;
  }

  /**
   * @notice Create the tournament
   * @dev Only owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev The prize pool for the tournament that the owner created is initialized on Oparcade contract
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @return tid Tournament ID created
   */
  function createTournamentByDAO(
    uint256 _gid,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee
  ) external onlyOwner onlyValidGID(_gid) returns (uint256 tid) {
    tid = _createTournament(_gid, _proposedGameCreatorFee, _tournamentCreatorFee);
  }

  /**
   * @notice Create the tournament
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @return tid Tournament ID created
   */
  function _createTournament(
    uint256 _gid,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee
  ) internal returns (uint256 tid) {
    // use baseCreatorFee if _proposedGameCreatorFee is zero
    uint256 appliedGameCreatorFee;
    if (_proposedGameCreatorFee == 0) {
      appliedGameCreatorFee = baseGameCreatorFees[_gid];
    } else {
      appliedGameCreatorFee = _proposedGameCreatorFee;
    }

    // check fees
    require(baseGameCreatorFees[_gid] <= appliedGameCreatorFee, "Low game creator fee proposed");
    require(platformFee + appliedGameCreatorFee + _tournamentCreatorFee < 1000, "Exceeded fees");

    // get the new tournament ID
    tid = tournamentCreators[_gid].length;

    // add the tournament creator address and fee
    tournamentCreators[_gid].push(msg.sender);
    appliedGameCreatorFees[_gid][tid] = appliedGameCreatorFee;
    tournamentCreatorFees[_gid][tid] = _tournamentCreatorFee;

    emit TournamentCreated(msg.sender, _gid, tid, appliedGameCreatorFee, _tournamentCreatorFee);
  }

  /**
   * @notice Create the tournament
   * @dev Anyone can create the tournament and initialize the prize pool with tokens and NFTs
   * @dev Tournament creator should set all params necessary for the tournament in 1 tx and
   * @dev the params set is immutable
   * @dev Tournament creator should pay fees to create the tournament
   * @dev and the fee token address and fee token amount are set by the owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev NFT type to initialize the prize pool should be either 721 or 1155
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _proposedGameCreatorFee Tournament creator fee
   * @param _depositTokenAddress Deposit token address for playing the tournament
   * @param _depositTokenAmount Deposit token amount for playing the tournament
   * @param _tokenToAddPrizePool Token address to initialize the prize pool
   * @param _amountToAddPrizePool Token amount to initialize the prize pool
   * @param _nftAddressToAddPrizePool NFT address to initialize the prize pool
   * @param _nftTypeToAddPrizePool NFT type to initialize the prize pool
   * @param _tokenIdsToAddPrizePool NFT token Id list to initialize the prize pool
   * @param _amountsToAddPrizePool NFT token amount list to initialize the prize pool
   * @return tid Tournament ID created
   */
  function createTournamentByUser(
    uint256 _gid,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee,
    address _depositTokenAddress,
    uint256 _depositTokenAmount,
    address _tokenToAddPrizePool,
    uint256 _amountToAddPrizePool,
    address _nftAddressToAddPrizePool,
    uint256 _nftTypeToAddPrizePool,
    uint256[] memory _tokenIdsToAddPrizePool,
    uint256[] memory _amountsToAddPrizePool
  ) external onlyValidGID(_gid) returns (uint256 tid) {
    // pay the tournament creation fee
    IERC20Upgradeable(tournamentCreationFeeToken).safeTransferFrom(
      msg.sender,
      feeRecipient,
      tournamentCreationFeeAmount
    );

    // create new tournament
    tid = _createTournament(_gid, _proposedGameCreatorFee, _tournamentCreatorFee);

    // set the deposit token amount
    _updateDepositTokenAmount(_gid, tid, _depositTokenAddress, _depositTokenAmount);

    // set the distributable token
    if (distributable[_gid][_depositTokenAddress] == false && _depositTokenAmount > 0) {
      _updateDistributableTokenAddress(_gid, _depositTokenAddress, true);
    }
    if (distributable[_gid][_tokenToAddPrizePool] == false && _amountToAddPrizePool > 0) {
      _updateDistributableTokenAddress(_gid, _tokenToAddPrizePool, true);
    }
    if (distributable[_gid][_nftAddressToAddPrizePool] == false && _amountsToAddPrizePool.length > 0) {
      _updateDistributableTokenAddress(_gid, _nftAddressToAddPrizePool, true);
    }

    // initialize the prize pool with tokens
    if (_amountToAddPrizePool > 0) {
      IOparcade(addressRegistry.oparcade()).depositPrize(
        msg.sender,
        _gid,
        tid,
        _tokenToAddPrizePool,
        _amountToAddPrizePool
      );
    }

    // initialize the prize pool with NFTs
    if (_nftTypeToAddPrizePool == 721 || _nftTypeToAddPrizePool == 1155) {
      IOparcade(addressRegistry.oparcade()).depositNFTPrize(
        msg.sender,
        _gid,
        tid,
        _nftAddressToAddPrizePool,
        _nftTypeToAddPrizePool,
        _tokenIdsToAddPrizePool,
        _amountsToAddPrizePool
      );
    }
  }

  /**
   * @notice Update deposit token amount
   * @dev Only owner
   * @dev Only tokens with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to allow/disallow the deposit
   * @param _amount Token amount
   */
  function updateDepositTokenAmount(
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) external onlyOwner onlyValidGID(_gid) onlyValidTID(_gid, _tid) {
    _updateDepositTokenAmount(_gid, _tid, _token, _amount);
  }

  /**
   * @notice Update deposit token amount
   * @dev Only tokens with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to allow/disallow the deposit
   * @param _amount Token amount
   */
  function _updateDepositTokenAmount(
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) internal {
    emit DepositAmountUpdated(msg.sender, _gid, _tid, _token, depositTokenAmount[_gid][_tid][_token], _amount);

    // update deposit token list
    if (_amount > 0) {
      if (depositTokenAmount[_gid][_tid][_token] == 0) {
        // add the token into the list only if it's added newly
        depositTokenList[_gid].push(_token);
      }
    } else {
      for (uint256 i; i < depositTokenList[_gid].length; i++) {
        if (_token == depositTokenList[_gid][i]) {
          // remove the token from the list
          depositTokenList[_gid][i] = depositTokenList[_gid][depositTokenList[_gid].length - 1];
          depositTokenList[_gid].pop();
          break;
        }
      }
    }

    // update deposit token amount
    depositTokenAmount[_gid][_tid][_token] = _amount;
  }

  /**
   * @notice Update distributable token address
   * @dev Only owner
   * @param _gid Game ID
   * @param _token Token address to allow/disallow the deposit
   * @param _isDistributable true: distributable false: not distributable
   */
  function updateDistributableTokenAddress(
    uint256 _gid,
    address _token,
    bool _isDistributable
  ) external onlyOwner onlyValidGID(_gid) {
    _updateDistributableTokenAddress(_gid, _token, _isDistributable);
  }

  /**
   * @notice Update distributable token address
   * @dev Only owner
   * @param _gid Game ID
   * @param _token Token address to allow/disallow the deposit
   * @param _isDistributable true: distributable false: not distributable
   */
  function _updateDistributableTokenAddress(
    uint256 _gid,
    address _token,
    bool _isDistributable
  ) internal {
    emit DistributableTokenAddressUpdated(msg.sender, _gid, _token, distributable[_gid][_token], _isDistributable);

    // update distributable token list
    if (_isDistributable) {
      if (!distributable[_gid][_token]) {
        // add token to the list only if it's added newly
        distributableTokenList[_gid].push(_token);
      }
    } else {
      for (uint256 i; i < distributableTokenList[_gid].length; i++) {
        if (_token == distributableTokenList[_gid][i]) {
          distributableTokenList[_gid][i] = distributableTokenList[_gid][distributableTokenList[_gid].length - 1];
          distributableTokenList[_gid].pop();
          break;
        }
      }
    }

    // update distributable token amount
    distributable[_gid][_token] = _isDistributable;
  }

  /**
   * @notice Returns the deposit token list of the game
   * @param _gid Game ID
   * @return (address[]) Deposit token list of the game
   */
  function getDepositTokenList(uint256 _gid) external view returns (address[] memory) {
    return depositTokenList[_gid];
  }

  /**
   * @notice Returns the distributable token list of the game
   * @param _gid Game ID
   * @param (address[]) Distributable token list of the game
   */
  function getDistributableTokenList(uint256 _gid) external view returns (address[] memory) {
    return distributableTokenList[_gid];
  }

  /**
   * @notice Returns the number of games added in games array
   * @return (uint256) Game count created
   */
  function gameCount() external view returns (uint256) {
    return games.length;
  }

  /**
   * @notice Returns the number of the tournaments of the specific game
   * @param _gid Game ID
   * @return (uint256) Number of the tournament
   */
  function getTournamentCount(uint256 _gid) external view onlyValidGID(_gid) returns (uint256) {
    return tournamentCreators[_gid].length;
  }

  /**
   * @notice Returns the tournament creator address of the specific game/tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (address) Tournament creator address
   */
  function getTournamentCreator(uint256 _gid, uint256 _tid)
    external
    view
    onlyValidGID(_gid)
    onlyValidTID(_gid, _tid)
    returns (address)
  {
    return tournamentCreators[_gid][_tid];
  }

  /**
   * @notice Update the platform fee
   * @dev Only owner
   * @dev Allow zero recipient address only of fee is also zero
   * @param _feeRecipient Platform fee recipient address
   * @param _platformFee platform fee
   */
  function updatePlatformFee(address _feeRecipient, uint256 _platformFee) external onlyOwner {
    require(_feeRecipient != address(0) || _platformFee == 0, "Fee recipient not set");
    require(_platformFee <= 1000, "Platform fee exceeded");

    emit PlatformFeeUpdated(msg.sender, feeRecipient, platformFee, _feeRecipient, _platformFee);

    feeRecipient = _feeRecipient;
    platformFee = _platformFee;
  }

  /**
   * @notice Update the tournament creation fee
   * @dev Only owner
   * @dev Tournament creator should pay this fee when creating the tournament
   * @param _tournamentCreationFeeToken Fee token address
   * @param _tournamentCreationFeeAmount Fee token amount
   */
  function updateTournamentCreationFee(address _tournamentCreationFeeToken, uint256 _tournamentCreationFeeAmount)
    external
    onlyOwner
  {
    require(_tournamentCreationFeeToken != address(0), "Zero tournament creation fee token");
    require(_tournamentCreationFeeAmount > 0, "Zero tournament creation fee");

    emit TournamentCreationFeeUpdated(
      msg.sender,
      tournamentCreationFeeToken,
      tournamentCreationFeeAmount,
      _tournamentCreationFeeToken,
      _tournamentCreationFeeAmount
    );

    tournamentCreationFeeToken = _tournamentCreationFeeToken;
    tournamentCreationFeeAmount = _tournamentCreationFeeAmount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AddressRegistry Contract Interface
 * @notice Define the interface used to get addresses in Oparcade
 * @author David Lee
 */
interface IAddressRegistry {
  /**
   * @notice Provide the Oparcade contract address
   * @dev Can be zero in case of the Oparcade contract is not registered
   * @return address Oparcade contract address
   */
  function oparcade() external view returns (address);

  /**
   * @notice Provide the GameRegistry contract address
   * @dev Can be zero in case of the GameRegistry contract is not registered
   * @return address GameRegistry contract address
   */
  function gameRegistry() external view returns (address);

  /**
   * @notice Provide the maintainer address
   * @dev Can be zero in case of the maintainer address is not registered
   * @return address Maintainer contract address
   */
  function maintainer() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Oparcade Contract Interface
 * @notice Define the interface used to get the token deposit and withdrawal info
 * @author David Lee
 */
interface IOparcade {
  function depositPrize(
    address _depositor,
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) external;

  function depositNFTPrize(
    address _from,
    uint256 _gid,
    uint256 _tid,
    address _nftAddress,
    uint256 _nftType,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) external;
}