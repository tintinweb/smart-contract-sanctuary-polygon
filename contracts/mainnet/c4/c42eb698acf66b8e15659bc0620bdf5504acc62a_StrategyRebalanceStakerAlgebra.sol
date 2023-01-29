// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./safe-math.sol";
import "./context.sol";

// File: contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
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

// File: contracts/utils/Address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
    assembly {
      size := extcodesize(account)
    }
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
    (bool success, ) = recipient.call{value: amount}("");
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
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
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
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// File: contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
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
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
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
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
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
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
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
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
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
  ) internal virtual {}
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
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
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
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
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
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
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
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
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
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
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
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
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IAlgebraCalculator {
  function getSqrtRatioAtTick(int24 _tick) external view returns (uint160);

  function getLiquidityForAmount0(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0
  ) external pure returns (uint128);

  function getLiquidityForAmount1(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount1
  ) external pure returns (uint128);

  function getAmountsForLiquidity(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) external pure returns (uint256 amount0, uint256 amount1);

  function getLiquidityForAmounts(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0,
    uint256 amount1
  ) external pure returns (uint128);

  function liquidityForAmounts(
    uint160 sqrtRatioX96,
    uint256 amount0,
    uint256 amount1,
    int24 _tickLower,
    int24 _tickUpper
  ) external view returns (uint128);

  function amountsForLiquidity(
    uint160 sqrtRatioX96,
    uint128 liquidity,
    int24 _tickLower,
    int24 _tickUpper
  ) external view returns (uint256, uint256);

  function determineTicksCalc(
    int56[] memory _cumulativeTicks,
    int24 _tickSpacing,
    int24 _tickRangeMultiplier,
    uint24 _twapTime
  ) external view returns (int24, int24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IAlgebraPoolImmutables.sol";
import "./pool/IAlgebraPoolState.sol";
import "./pool/IAlgebraPoolDerivedState.sol";
import "./pool/IAlgebraPoolActions.sol";
import "./pool/IAlgebraPoolPermissionedActions.sol";
import "./pool/IAlgebraPoolEvents.sol";

/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces.
 * Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPool is
  IAlgebraPoolImmutables,
  IAlgebraPoolState,
  IAlgebraPoolDerivedState,
  IAlgebraPoolActions,
  IAlgebraPoolPermissionedActions,
  IAlgebraPoolEvents
{
  // used only for combining interfaces
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./INonfungiblePositionManager.sol";

interface IAlgebraPositionsNFT {
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);
  event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
  event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function WETH9() external view returns (address);

  function approve(address to, uint256 tokenId) external;

  function balanceOf(address owner) external view returns (uint256);

  function baseURI() external pure returns (string memory);

  function burn(uint256 tokenId) external payable;

  function collect(INonfungiblePositionManager.CollectParams memory params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  function createAndInitializePoolIfNecessary(
    address token0,
    address token1,
    uint24 fee,
    uint160 sqrtPriceX96
  ) external payable returns (address pool);

  function decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams memory params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  function factory() external view returns (address);

  function getApproved(uint256 tokenId) external view returns (address);

  function increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams memory params)
    external
    payable
    returns (
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function mint(INonfungiblePositionManager.MintParams memory params)
    external
    payable
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );

  function multicall(bytes[] memory data) external payable returns (bytes[] memory results);

  function name() external view returns (string memory);

  function ownerOf(uint256 tokenId) external view returns (address);

  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  function refundETH() external payable;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) external;

  function selfPermit(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function selfPermitAllowed(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function selfPermitAllowedIfNecessary(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function selfPermitIfNecessary(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function setApprovalForAll(address operator, bool approved) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function sweepToken(
    address token,
    uint256 amountMinimum,
    address recipient
  ) external payable;

  function symbol() external view returns (string memory);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function uniswapV3MintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes memory data
  ) external;

  function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

  receive() external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import "../../lib/algebra/AdaptiveFee.sol";

interface IDataStorageOperator {
  event FeeConfiguration(AdaptiveFee.Configuration feeConfig);

  /**
   * @notice Returns data belonging to a certain timepoint
   * @param index The index of timepoint in the array
   * @dev There is more convenient function to fetch a timepoint: observe(). Which requires not an index but seconds
   * @return initialized Whether the timepoint has been initialized and the values are safe to use,
   * blockTimestamp The timestamp of the observation,
   * tickCumulative The tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
   * secondsPerLiquidityCumulative The seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
   * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp,
   * averageTick Time-weighted average tick,
   * volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
  /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
  /// @param tick Initial tick
  function initialize(uint32 time, int24 tick) external;

  /// @dev Reverts if an timepoint at or before the desired timepoint timestamp does not exist.
  /// 0 may be passed as `secondsAgo' to return the current cumulative values.
  /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
  /// at exactly the timestamp between the two timepoints.
  /// @param time The current block timestamp
  /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulative The cumulative tick since the pool was first initialized, as of `secondsAgo`
  /// @return secondsPerLiquidityCumulative The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
  /// @return volatilityCumulative The cumulative volatility value since the pool was first initialized, as of `secondsAgo`
  /// @return volumePerAvgLiquidity The cumulative volume per liquidity value since the pool was first initialized, as of `secondsAgo`
  function getSingleTimepoint(
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint112 volatilityCumulative,
      uint256 volumePerAvgLiquidity
    );

  /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest timepoint
  /// @param time The current block.timestamp
  /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulatives The cumulative tick since the pool was first initialized, as of each `secondsAgo`
  /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
  /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
  /// @return volumePerAvgLiquiditys The cumulative volume per liquidity values since the pool was first initialized, as of each `secondsAgo`
  function getTimepoints(
    uint32 time,
    uint32[] memory secondsAgos,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /// @notice Returns average volatility in the range from time-WINDOW to time
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return TWVolatilityAverage The average volatility in the recent range
  /// @return TWVolumePerLiqAverage The average volume per liquidity in the recent range
  function getAverages(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

  /// @notice Writes an dataStorage timepoint to the array
  /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @param liquidity The total in-range liquidity at the time of the new timepoint
  /// @param volumePerLiquidity The gmean(volumes)/liquidity at the time of the new timepoint
  /// @return indexUpdated The new index of the most recently written element in the dataStorage array
  function write(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint128 volumePerLiquidity
  ) external returns (uint16 indexUpdated);

  /// @notice Changes fee configuration for the pool
  function changeFeeConfiguration(AdaptiveFee.Configuration calldata feeConfig) external;

  /// @notice Calculates gmean(volume/liquidity) for block
  /// @param liquidity The current in-range pool liquidity
  /// @param amount0 Total amount of swapped token0
  /// @param amount1 Total amount of swapped token1
  /// @return volumePerLiquidity gmean(volume/liquidity) capped by 100000 << 64
  function calculateVolumePerLiquidity(
    uint128 liquidity,
    int256 amount0,
    int256 amount1
  ) external pure returns (uint128 volumePerLiquidity);

  /// @return windowLength Length of window used to calculate averages
  function window() external view returns (uint32 windowLength);

  /// @notice Calculates fee based on combination of sigmoids
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return fee The fee in hundredths of a bip, i.e. 1e-6
  function getFee(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint16 fee);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./INonfungiblePositionManager.sol";

interface IFarmingCenter {
  struct IncentiveKey {
    address rewardToken;
    address bonusRewardToken;
    address pool;
    uint256 startTime;
    uint256 endTime;
  }

  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event DepositTransferred(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function WNativeToken() external view returns (address);

  function approve(address to, uint256 tokenId) external;

  function balanceOf(address owner) external view returns (uint256);

  function baseURI() external view returns (string memory);

  function claimReward(
    address rewardToken,
    address to,
    uint256 amountRequestedIncentive,
    uint256 amountRequestedEternal
  ) external returns (uint256 reward);

  function collect(INonfungiblePositionManager.CollectParams memory params)
    external
    returns (uint256 amount0, uint256 amount1);

  function collectRewards(IncentiveKey memory key, uint256 tokenId)
    external
    returns (uint256 reward, uint256 bonusReward);

  function connectVirtualPool(address pool, address newVirtualPool) external;

  function cross(int24 nextTick, bool zeroToOne) external;

  function deposits(uint256)
    external
    view
    returns (
      uint256 L2TokenId,
      uint32 numberOfFarms,
      bool inLimitFarming,
      address owner
    );

  function enterFarming(
    IncentiveKey memory key,
    uint256 tokenId,
    uint256 tokensLocked,
    bool isLimit
  ) external;

  function eternalFarming() external view returns (address);

  function exitFarming(
    IncentiveKey memory key,
    uint256 tokenId,
    bool isLimit
  ) external;

  function farmingCenterVault() external view returns (address);

  function getApproved(uint256 tokenId) external view returns (address);

  function increaseCumulative(uint32 blockTimestamp) external returns (uint8 status);

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function l2Nfts(uint256)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      uint256 tokenId
    );

  function limitFarming() external view returns (address);

  function multicall(bytes[] memory data) external payable returns (bytes[] memory results);

  function name() external view returns (string memory);

  function nonfungiblePositionManager() external view returns (address);

  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes memory
  ) external returns (bytes4);

  function ownerOf(uint256 tokenId) external view returns (address);

  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function refundNativeToken() external payable;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) external;

  function setApprovalForAll(address operator, bool approved) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function sweepToken(
    address token,
    uint256 amountMinimum,
    address recipient
  ) external payable;

  function symbol() external view returns (string memory);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function unwrapWNativeToken(uint256 amountMinimum, address recipient) external payable;

  function virtualPoolAddresses(address pool) external view returns (address limitVP, address eternalVP);

  function withdrawToken(
    uint256 tokenId,
    address to,
    bytes memory data
  ) external;

  receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INonfungiblePositionManager {
  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct MintParams {
    address token0;
    address token1;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ISwapRouter {
  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 limitSqrtPrice;
  }

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 limitSqrtPrice;
  }

  function WNativeToken() external view returns (address);

  function algebraSwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes memory _data
  ) external;

  function exactInput(ExactOutputParams memory params) external payable returns (uint256 amountOut);

  function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);

  function exactInputSingleSupportingFeeOnTransferTokens(ExactInputSingleParams memory params)
    external
    returns (uint256 amountOut);

  function exactOutput(ExactOutputParams memory params) external payable returns (uint256 amountIn);

  function exactOutputSingle(ExactOutputSingleParams memory params) external payable returns (uint256 amountIn);

  function factory() external view returns (address);

  function multicall(bytes[] memory data) external payable returns (bytes[] memory results);

  function poolDeployer() external view returns (address);

  function refundNativeToken() external payable;

  function selfPermit(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function selfPermitAllowed(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function selfPermitAllowedIfNecessary(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function selfPermitIfNecessary(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  function sweepToken(
    address token,
    uint256 amountMinimum,
    address recipient
  ) external payable;

  function sweepTokenWithFee(
    address token,
    uint256 amountMinimum,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) external payable;

  function unwrapWNativeToken(uint256 amountMinimum, address recipient) external payable;

  function unwrapWNativeTokenWithFee(
    uint256 amountMinimum,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) external payable;

  receive() external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
  /**
   * @notice Sets the initial price for the pool
   * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
   * @param price the initial sqrt price of the pool as a Q64.96
   */
  function initialize(uint160 price) external;

  /**
   * @notice Adds liquidity for the given recipient/bottomTick/topTick position
   * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
   * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
   * on bottomTick, topTick, the amount of liquidity, and the current price.
   * @param sender The address which will receive potential surplus of paid tokens
   * @param recipient The address for which the liquidity will be created
   * @param bottomTick The lower tick of the position in which to add liquidity
   * @param topTick The upper tick of the position in which to add liquidity
   * @param amount The desired amount of liquidity to mint
   * @param data Any data that should be passed through to the callback
   * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return liquidityActual The actual minted amount of liquidity
   */
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  )
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint128 liquidityActual
    );

  /**
   * @notice Collects tokens owed to a position
   * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
   * Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
   * amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
   * actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
   * @param recipient The address which should receive the fees collected
   * @param bottomTick The lower tick of the position for which to collect fees
   * @param topTick The upper tick of the position for which to collect fees
   * @param amount0Requested How much token0 should be withdrawn from the fees owed
   * @param amount1Requested How much token1 should be withdrawn from the fees owed
   * @return amount0 The amount of fees collected in token0
   * @return amount1 The amount of fees collected in token1
   */
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /**
   * @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
   * @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
   * @dev Fees must be collected separately via a call to #collect
   * @param bottomTick The lower tick of the position for which to burn liquidity
   * @param topTick The upper tick of the position for which to burn liquidity
   * @param amount How much liquidity to burn
   * @return amount0 The amount of token0 sent to the recipient
   * @return amount1 The amount of token1 sent to the recipient
   */
  function burn(
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0
   * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
   * @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
   * @param sender The address called this function (Comes from the Router)
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
   * @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
   * @dev All excess tokens paid in the callback are distributed to liquidity providers as an additional fee. So this method can be used
   * to donate underlying tokens to currently in-range liquidity providers by calling with 0 amount{0,1} and sending
   * the donation amount(s) from the callback
   * @param recipient The address which will receive the token0 and token1 amounts
   * @param amount0 The amount of token0 to send
   * @param amount1 The amount of token1 to send
   * @param data Any data to be passed through to the callback
   */
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolDerivedState {
  /**
   * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
   * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
   * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
   * you must call it with secondsAgos = [3600, 0].
   * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
   * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
   * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
   * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
   * @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos`
   * from the current block timestamp
   * @return volatilityCumulatives Cumulative standard deviation as of each `secondsAgos`
   * @return volumePerAvgLiquiditys Cumulative swap volume per liquidity as of each `secondsAgos`
   */
  function getTimepoints(uint32[] calldata secondsAgos)
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /**
   * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
   * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
   * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
   * snapshot is taken and the second snapshot is taken.
   * @param bottomTick The lower tick of the range
   * @param topTick The upper tick of the range
   * @return innerTickCumulative The snapshot of the tick accumulator for the range
   * @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
   * @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
   */
  function getInnerCumulatives(int24 bottomTick, int24 topTick)
    external
    view
    returns (
      int56 innerTickCumulative,
      uint160 innerSecondsSpentPerLiquidity,
      uint32 innerSecondsSpent
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
  /**
   * @notice Emitted exactly once by a pool when #initialize is first called on the pool
   * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
   * @param price The initial sqrt price of the pool, as a Q64.96
   * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
   */
  event Initialize(uint160 price, int24 tick);

  /**
   * @notice Emitted when liquidity is minted for a given position
   * @param sender The address that minted the liquidity
   * @param owner The owner of the position and recipient of any minted liquidity
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity minted to the position range
   * @param amount0 How much token0 was required for the minted liquidity
   * @param amount1 How much token1 was required for the minted liquidity
   */
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed bottomTick,
    int24 indexed topTick,
    uint128 liquidityAmount,
    uint256 amount0,
    uint256 amount1
  );

  /**
   * @notice Emitted when fees are collected by the owner of a position
   * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
   * @param owner The owner of the position for which fees are collected
   * @param recipient The address that received fees
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param amount0 The amount of token0 fees collected
   * @param amount1 The amount of token1 fees collected
   */
  event Collect(address indexed owner, address recipient, int24 indexed bottomTick, int24 indexed topTick, uint128 amount0, uint128 amount1);

  /**
   * @notice Emitted when a position's liquidity is removed
   * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
   * @param owner The owner of the position for which liquidity is removed
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity to remove
   * @param amount0 The amount of token0 withdrawn
   * @param amount1 The amount of token1 withdrawn
   */
  event Burn(address indexed owner, int24 indexed bottomTick, int24 indexed topTick, uint128 liquidityAmount, uint256 amount0, uint256 amount1);

  /**
   * @notice Emitted by the pool for any swaps between token0 and token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the output of the swap
   * @param amount0 The delta of the token0 balance of the pool
   * @param amount1 The delta of the token1 balance of the pool
   * @param price The sqrt(price) of the pool after the swap, as a Q64.96
   * @param liquidity The liquidity of the pool after the swap
   * @param tick The log base 1.0001 of price of the pool after the swap
   */
  event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 price, uint128 liquidity, int24 tick);

  /**
   * @notice Emitted by the pool for any flashes of token0/token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the tokens from flash
   * @param amount0 The amount of token0 that was flashed
   * @param amount1 The amount of token1 that was flashed
   * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
   * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
   */
  event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

  /**
   * @notice Emitted when the community fee is changed by the pool
   * @param communityFee0New The updated value of the token0 community fee percent
   * @param communityFee1New The updated value of the token1 community fee percent
   */
  event CommunityFee(uint8 communityFee0New, uint8 communityFee1New);

  /**
   * @notice Emitted when new activeIncentive is set
   * @param virtualPoolAddress The address of a virtual pool associated with the current active incentive
   */
  event Incentive(address indexed virtualPoolAddress);

  /**
   * @notice Emitted when the fee changes
   * @param fee The value of the token fee
   */
  event Fee(uint16 fee);

  /**
   * @notice Emitted when the LiquidityCooldown changes
   * @param liquidityCooldown The value of locktime for added liquidity
   */
  event LiquidityCooldown(uint32 liquidityCooldown);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../IDataStorageOperator.sol";

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /**
   * @notice The contract that stores all the timepoints and can perform actions with them
   * @return The operator address
   */
  function dataStorageOperator() external view returns (address);

  /**
   * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
   * @return The contract address
   */
  function factory() external view returns (address);

  /**
   * @notice The first of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token0() external view returns (address);

  /**
   * @notice The second of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token1() external view returns (address);

  /**
   * @notice The pool tick spacing
   * @dev Ticks can only be used at multiples of this value
   * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
   * This value is an int24 to avoid casting even though it is always positive.
   * @return The tick spacing
   */
  function tickSpacing() external view returns (int24);

  /**
   * @notice The maximum amount of position liquidity that can use any tick in the range
   * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
   * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
   * @return The max amount of liquidity per tick
   */
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or tokenomics
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolPermissionedActions {
  /**
   * @notice Set the community's % share of the fees. Cannot exceed 25% (250)
   * @param communityFee0 new community fee percent for token0 of the pool in thousandths (1e-3)
   * @param communityFee1 new community fee percent for token1 of the pool in thousandths (1e-3)
   */
  function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

  /**
   * @notice Sets an active incentive
   * @param virtualPoolAddress The address of a virtual pool associated with the incentive
   */
  function setIncentive(address virtualPoolAddress) external;

  /**
   * @notice Sets new lock time for added liquidity
   * @param newLiquidityCooldown The time in seconds
   */
  function setLiquidityCooldown(uint32 newLiquidityCooldown) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
  /**
   * @notice The globalState structure in the pool stores many values but requires only one slot
   * and is exposed as a single method to save gas when accessed externally.
   * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
   * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
   * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
   * boundary;
   * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
   * Returns timepointIndex The index of the last written timepoint;
   * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
   * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
   * Returns unlocked Whether the pool is currently locked to reentrancy;
   */
  function globalState()
    external
    view
    returns (
      uint160 price,
      int24 tick,
      uint16 fee,
      uint16 timepointIndex,
      uint8 communityFeeToken0,
      uint8 communityFeeToken1,
      bool unlocked
    );

  /**
   * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth0Token() external view returns (uint256);

  /**
   * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth1Token() external view returns (uint256);

  /**
   * @notice The currently in range liquidity available to the pool
   * @dev This value has no relationship to the total liquidity across all ticks.
   * Returned value cannot exceed type(uint128).max
   */
  function liquidity() external view returns (uint128);

  /**
   * @notice Look up information about a specific tick in the pool
   * @dev This is a public structure, so the `return` natspec tags are omitted.
   * @param tick The tick to look up
   * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
   * tick upper;
   * Returns liquidityDelta how much liquidity changes when the pool price crosses the tick;
   * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
   * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
   * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
   * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
   * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
   * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
   * otherwise equal to false. Outside values can only be used if the tick is initialized.
   * In addition, these values are only relative and must be used only in comparison to previous snapshots for
   * a specific position.
   */
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int56 outerTickCumulative,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool initialized
    );

  /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
  function tickTable(int16 wordPosition) external view returns (uint256);

  /**
   * @notice Returns the information about a position by the position's key
   * @dev This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
   * @return liquidityAmount The amount of liquidity in the position;
   * Returns lastLiquidityAddTimestamp Timestamp of last adding of liquidity;
   * Returns innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke;
   * Returns innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke;
   * Returns fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke;
   * Returns fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
   */
  function positions(bytes32 key)
    external
    view
    returns (
      uint128 liquidityAmount,
      uint32 lastLiquidityAddTimestamp,
      uint256 innerFeeGrowth0Token,
      uint256 innerFeeGrowth1Token,
      uint128 fees0,
      uint128 fees1
    );

  /**
   * @notice Returns data about a specific timepoint index
   * @param index The element of the timepoints array to fetch
   * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
   * ago, rather than at a specific index in the array.
   * This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @return initialized whether the timepoint has been initialized and the values are safe to use;
   * Returns blockTimestamp The timestamp of the timepoint;
   * Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp;
   * Returns secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp;
   * Returns volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp;
   * Returns averageTick Time-weighted average tick;
   * Returns volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp;
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /**
   * @notice Returns the information about active incentive
   * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
   * @return virtualPool The address of a virtual pool associated with the current active incentive
   */
  function activeIncentive() external view returns (address virtualPool);

  /**
   * @notice Returns the lock time for added liquidity
   */
  function liquidityCooldown() external view returns (uint32 cooldownInSeconds);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Constants.sol";

/// @title AdaptiveFee
/// @notice Calculates fee based on combination of sigmoids
library AdaptiveFee {
  // alpha1 + alpha2 + baseFee must be <= type(uint16).max
  struct Configuration {
    uint16 alpha1; // max value of the first sigmoid
    uint16 alpha2; // max value of the second sigmoid
    uint32 beta1; // shift along the x-axis for the first sigmoid
    uint32 beta2; // shift along the x-axis for the second sigmoid
    uint16 gamma1; // horizontal stretch factor for the first sigmoid
    uint16 gamma2; // horizontal stretch factor for the second sigmoid
    uint32 volumeBeta; // shift along the x-axis for the outer volume-sigmoid
    uint16 volumeGamma; // horizontal stretch factor the outer volume-sigmoid
    uint16 baseFee; // minimum possible fee
  }

  /// @notice Calculates fee based on formula:
  /// baseFee + sigmoidVolume(sigmoid1(volatility, volumePerLiquidity) + sigmoid2(volatility, volumePerLiquidity))
  /// maximum value capped by baseFee + alpha1 + alpha2
  function getFee(
    uint88 volatility,
    uint256 volumePerLiquidity,
    Configuration memory config
  ) internal pure returns (uint16 fee) {
    uint256 sumOfSigmoids = sigmoid(volatility, config.gamma1, config.alpha1, config.beta1) +
      sigmoid(volatility, config.gamma2, config.alpha2, config.beta2);

    if (sumOfSigmoids > type(uint16).max) {
      // should be impossible, just in case
      sumOfSigmoids = type(uint16).max;
    }

    return
      uint16(
        config.baseFee + sigmoid(volumePerLiquidity, config.volumeGamma, uint16(sumOfSigmoids), config.volumeBeta)
      ); // safe since alpha1 + alpha2 + baseFee _must_ be <= type(uint16).max
  }

  /// @notice calculates α / (1 + e^( (β-x) / γ))
  /// that is a sigmoid with a maximum value of α, x-shifted by β, and stretched by γ
  /// @dev returns uint256 for fuzzy testing. Guaranteed that the result is not greater than alpha
  function sigmoid(
    uint256 x,
    uint16 g,
    uint16 alpha,
    uint256 beta
  ) internal pure returns (uint256 res) {
    if (x > beta) {
      x = x - beta;
      if (x >= 6 * uint256(g)) return alpha; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = exp(x, g, g8); // < 155 bits
      res = (alpha * ex) / (g8 + ex); // in worst case: (16 + 155 bits) / 155 bits
      // so res <= alpha
    } else {
      x = beta - x;
      if (x >= 6 * uint256(g)) return 0; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = g8 + exp(x, g, g8); // < 156 bits
      res = (alpha * g8) / ex; // in worst case: (16 + 128 bits) / 156 bits
      // g8 <= ex, so res <= alpha
    }
  }

  /// @notice calculates e^(x/g) * g^8 in a series, since (around zero):
  /// e^x = 1 + x + x^2/2 + ... + x^n/n! + ...
  /// e^(x/g) = 1 + x/g + x^2/(2*g^2) + ... + x^(n)/(g^n * n!) + ...
  function exp(
    uint256 x,
    uint16 g,
    uint256 gHighestDegree
  ) internal pure returns (uint256 res) {
    // calculating:
    // g**8 + x * g**7 + (x**2 * g**6) / 2 + (x**3 * g**5) / 6 + (x**4 * g**4) / 24 + (x**5 * g**3) / 120 + (x**6 * g^2) / 720 + x**7 * g / 5040 + x**8 / 40320

    // x**8 < 152 bits (19*8) and g**8 < 128 bits (8*16)
    // so each summand < 152 bits and res < 155 bits
    uint256 xLowestDegree = x;
    res = gHighestDegree; // g**8

    gHighestDegree /= g; // g**7
    res += xLowestDegree * gHighestDegree;

    gHighestDegree /= g; // g**6
    xLowestDegree *= x; // x**2
    res += (xLowestDegree * gHighestDegree) / 2;

    gHighestDegree /= g; // g**5
    xLowestDegree *= x; // x**3
    res += (xLowestDegree * gHighestDegree) / 6;

    gHighestDegree /= g; // g**4
    xLowestDegree *= x; // x**4
    res += (xLowestDegree * gHighestDegree) / 24;

    gHighestDegree /= g; // g**3
    xLowestDegree *= x; // x**5
    res += (xLowestDegree * gHighestDegree) / 120;

    gHighestDegree /= g; // g**2
    xLowestDegree *= x; // x**6
    res += (xLowestDegree * gHighestDegree) / 720;

    xLowestDegree *= x; // x**7
    res += (xLowestDegree * g) / 5040 + (xLowestDegree * x) / (40320);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

library Constants {
  uint8 internal constant RESOLUTION = 96;
  uint256 internal constant Q96 = 0x1000000000000000000000000;
  uint256 internal constant Q128 = 0x100000000000000000000000000000000;
  // fee value in hundredths of a bip, i.e. 1e-6
  uint16 internal constant BASE_FEE = 100;
  int24 internal constant TICK_SPACING = 60;

  // max(uint128) / ( (MAX_TICK - MIN_TICK) / TICK_SPACING )
  uint128 internal constant MAX_LIQUIDITY_PER_TICK = 11505743598341114571880798222544994;

  uint32 internal constant MAX_LIQUIDITY_COOLDOWN = 1 days;
  uint8 internal constant MAX_COMMUNITY_FEE = 250;
  uint256 internal constant COMMUNITY_FEE_DENOMINATOR = 1000;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IAlgebraEternalFarming {
  struct IncentiveParams {
    uint256 reward;
    uint256 bonusReward;
    uint128 rewardRate;
    uint128 bonusRewardRate;
    uint24 minimalPositionWidth;
    address multiplierToken;
  }

  event EternalFarmingCreated(
    address indexed rewardToken,
    address indexed bonusRewardToken,
    address indexed pool,
    address virtualPool,
    uint256 startTime,
    uint256 endTime,
    uint256 reward,
    uint256 bonusReward,
    IAlgebraFarming.Tiers tiers,
    address multiplierToken,
    uint24 minimalAllowedPositionWidth
  );
  event FarmEnded(
    uint256 indexed tokenId,
    bytes32 indexed incentiveId,
    address indexed rewardAddress,
    address bonusRewardToken,
    address owner,
    uint256 reward,
    uint256 bonusReward
  );
  event FarmEntered(uint256 indexed tokenId, bytes32 indexed incentiveId, uint128 liquidity, uint256 tokensLocked);
  event FarmingCenter(address indexed farmingCenter);
  event IncentiveAttached(
    address indexed rewardToken,
    address indexed bonusRewardToken,
    address indexed pool,
    address virtualPool,
    uint256 startTime,
    uint256 endTime
  );
  event IncentiveDetached(
    address indexed rewardToken,
    address indexed bonusRewardToken,
    address indexed pool,
    address virtualPool,
    uint256 startTime,
    uint256 endTime
  );
  event IncentiveMaker(address indexed incentiveMaker);
  event RewardClaimed(address indexed to, uint256 reward, address indexed rewardAddress, address indexed owner);
  event RewardsAdded(uint256 rewardAmount, uint256 bonusRewardAmount, bytes32 incentiveId);
  event RewardsCollected(uint256 tokenId, bytes32 incentiveId, uint256 rewardAmount, uint256 bonusRewardAmount);
  event RewardsRatesChanged(uint128 rewardRate, uint128 bonusRewardRate, bytes32 incentiveId);

  function addRewards(
    IIncentiveKey.IncentiveKey memory key,
    uint256 rewardAmount,
    uint256 bonusRewardAmount
  ) external;

  function attachIncentive(IIncentiveKey.IncentiveKey memory key) external;

  function claimReward(
    address rewardToken,
    address to,
    uint256 amountRequested
  ) external returns (uint256 reward);

  function claimRewardFrom(
    address rewardToken,
    address from,
    address to,
    uint256 amountRequested
  ) external returns (uint256 reward);

  function collectRewards(
    IIncentiveKey.IncentiveKey memory key,
    uint256 tokenId,
    address _owner
  ) external returns (uint256 reward, uint256 bonusReward);

  function createEternalFarming(
    IIncentiveKey.IncentiveKey memory key,
    IncentiveParams memory params,
    IAlgebraFarming.Tiers memory tiers
  ) external returns (address virtualPool);

  function deployer() external view returns (address);

  function detachIncentive(IIncentiveKey.IncentiveKey memory key) external;

  function enterFarming(
    IIncentiveKey.IncentiveKey memory key,
    uint256 tokenId,
    uint256 tokensLocked
  ) external;

  function exitFarming(
    IIncentiveKey.IncentiveKey memory key,
    uint256 tokenId,
    address _owner
  ) external;

  function farmingCenter() external view returns (address);

  function farms(uint256, bytes32)
    external
    view
    returns (
      uint128 liquidity,
      int24 tickLower,
      int24 tickUpper,
      uint256 innerRewardGrowth0,
      uint256 innerRewardGrowth1
    );

  function getRewardInfo(IIncentiveKey.IncentiveKey memory key, uint256 tokenId)
    external
    view
    returns (uint256 reward, uint256 bonusReward);

  function incentives(bytes32)
    external
    view
    returns (
      uint256 totalReward,
      uint256 bonusReward,
      address virtualPoolAddress,
      uint24 minimalPositionWidth,
      uint224 totalLiquidity,
      address multiplierToken,
      IAlgebraFarming.Tiers memory tiers
    );

  function nonfungiblePositionManager() external view returns (address);

  function rewards(address, address) external view returns (uint256);

  function setFarmingCenterAddress(address _farmingCenter) external;

  function setIncentiveMaker(address _incentiveMaker) external;

  function setRates(
    IIncentiveKey.IncentiveKey memory key,
    uint128 rewardRate,
    uint128 bonusRewardRate
  ) external;
}

interface IAlgebraFarming {
  struct Tiers {
    uint256 tokenAmountForTier1;
    uint256 tokenAmountForTier2;
    uint256 tokenAmountForTier3;
    uint32 tier1Multiplier;
    uint32 tier2Multiplier;
    uint32 tier3Multiplier;
  }
}

interface IIncentiveKey {
  struct IncentiveKey {
    address rewardToken;
    address bonusRewardToken;
    address pool;
    uint256 startTime;
    uint256 endTime;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IControllerV7 {
  enum Governance {
    devfund,
    treasury,
    strategist,
    governance,
    timelock
  }

  enum Strategy {
    vault,
    revoke,
    approve,
    removeVault,
    removeStrategy,
    setStrategy
  }

  enum Withdraw {
    withdrawAll,
    inCaseTokensGetStuck,
    inCaseStrategyTokenGetStuck,
    withdraw,
    withdrawReward
  }

  function converters(address, address) external view returns (address);

  function earn(
    address _pool,
    uint256 _token0Amount,
    uint256 _token1Amount
  ) external;

  function getLowerTick(address _pool) external view returns (int24);

  function getUpperTick(address _pool) external view returns (int24);

  function governance(uint8) external view returns (address);

  function liquidityOf(address _pool) external view returns (uint256);

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external pure returns (bytes4);

  function strategies(address) external view returns (address);

  function treasury() external view returns (address);

  function vaults(address) external view returns (address);

  function withdraw(address _pool, uint256 _amount) external returns (uint256 a0, uint256 a1);

  function withdrawFunction(
    uint8 name,
    address _pool,
    uint256 _amount,
    address _token
  ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDragonsLair {
  function enter(uint256 amount) external;

  function leave(uint256 amount) external;

  function dQUICKForQUICK(uint256 amount) external view returns (uint256);

  function QUICKForDQUICK(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../../../lib/erc20.sol";
import "../interfaces/algebra/IAlgebraPositionsNFT.sol";
import "./interfaces/IAlgebraEternalFarming.sol";
import "../interfaces/algebra/IFarmingCenter.sol";
import "../interfaces/algebra/ISwapRouter.sol";
import "./interfaces/IControllerV7.sol";
import "../interfaces/algebra/IAlgebraPool.sol";
import "../../../interfaces/IUniswapRouterETH.sol";
import "./interfaces/IDragonsLair.sol";
import "../interfaces/algebra/IAlgebraCalculator.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract StrategyRebalanceStakerAlgebra is Initializable, OwnableUpgradeable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  // Cache struct for calculations
  struct Info {
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0;
    uint256 amount1;
    uint128 liquidity;
  }

  // Perfomance fees - start with 20%
  uint256 public performanceTreasuryFee;
  uint256 public performanceTreasuryMax;
  uint256 public constant MAX_PERFORMANCE_TREASURY_FEE = 2000;
  uint256 public lastHarvest;

  // User accounts
  address public governance;
  address public controller;
  address public strategist;
  address public timelock;

  address payable public algebraFarmingCenter;
  address public algebraEternalFarming;
  // Dex
  address payable public ALGEBRA_ROUTER;

  // Tokens
  IAlgebraPool public pool;

  IERC20 public token0;
  IERC20 public token1;
  uint256 public tokenId;

  int24 public tick_lower;
  int24 public tick_upper;
  int24 private tickSpacing;
  int24 public tickRangeMultiplier;
  uint24 private twapTime;

  IAlgebraPositionsNFT public constant nftManager =
    IAlgebraPositionsNFT(payable(0x8eF88E4c7CfbbaC1C163f7eddd4B578792201de6));
  IAlgebraCalculator private algebraCalculator;

  mapping(address => bool) public harvesters;

  IFarmingCenter.IncentiveKey public key;
  address[] public outputToAssetRewardToken;
  address[] public outputToAssetBonusRewardToken;
  uint256 public startTime;
  uint256 public endTime;
  uint256 private tokensLocked;
  bool private isLimit;
  address public rewardToken;
  address public bonusRewardToken;
  address private quickToken;
  address private wNative;
  address public uniRouter;

  int24 public innerTickRangeMultiplier;
  int24 public inner_tick_lower;
  int24 public inner_tick_upper;

  event InitialDeposited(uint256 tokenId);
  event Harvested(uint256 tokenId);
  event Deposited(uint256 tokenId, uint256 token0Balance, uint256 token1Balance);
  event Withdrawn(uint256 tokenId, uint256 _liquidity);
  event Rebalanced(uint256 tokenId, int24 _tickLower, int24 _tickUpper);

  function initialize(
    address _pool,
    int24 _tickRangeMultiplier,
    address _governance,
    address _strategist,
    address _controller,
    address _timelock,
    address _iAlgebraCalculator
  ) public initializer {
    __Ownable_init_unchained();
    governance = _governance;
    strategist = _strategist;
    controller = _controller;
    timelock = _timelock;

    algebraCalculator = IAlgebraCalculator(_iAlgebraCalculator);
    quickToken = 0xB5C064F955D8e7F38fE0460C556a72987494eE17;
    wNative = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    uniRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    algebraFarmingCenter = payable(0x7F281A8cdF66eF5e9db8434Ec6D97acc1bc01E78);
    algebraEternalFarming = 0x8a26436e41d0b5fc4C6Ed36C1976fafBe173444E;
    ALGEBRA_ROUTER = payable(0xf5b509bB0909a69B1c207E495f687a596C168E12);
    performanceTreasuryFee = 2000;
    performanceTreasuryMax = 10000;
    startTime = 1665190155;
    endTime = 4104559500;
    twapTime = 60;

    pool = IAlgebraPool(_pool);

    token0 = IERC20(pool.token0());
    token1 = IERC20(pool.token1());

    tickSpacing = pool.tickSpacing();
    tickRangeMultiplier = _tickRangeMultiplier;

    token0.safeApprove(address(nftManager), type(uint128).max);
    token1.safeApprove(address(nftManager), type(uint128).max);
    nftManager.setApprovalForAll(algebraFarmingCenter, true);
    nftManager.setApprovalForAll(address(nftManager), true);
    tokensLocked = 0;
    isLimit = false;
    harvesters[msg.sender] = true;
  }

  // **** Modifiers **** //

  modifier onlyBenevolent() {
    require(harvesters[msg.sender] || msg.sender == governance || msg.sender == strategist);
    _;
  }

  // **** Views **** //

  /**
   * @notice  Total liquidity
   * @return  uint256  returns amount of liquidity
   */
  function liquidityOfThis() public view returns (uint256) {
    (uint160 sqrtRatioX96, , , , , , ) = pool.globalState();
    uint256 liquidity = uint256(
      algebraCalculator.liquidityForAmounts(
        sqrtRatioX96,
        token0.balanceOf(address(this)),
        token1.balanceOf(address(this)),
        tick_lower,
        tick_upper
      )
    );
    return liquidity;
  }

  /**
   * @notice  The liquidity of our Uni position
   * @return  uint256  returns total liquidity
   */
  function liquidityOfPool() public view returns (uint256) {
    (, , , , , , uint128 liquidity, , , , ) = nftManager.positions(tokenId);

    //    uint256 ya = 100;
    return liquidity;
  }

  /**
   * @notice  Total liquidity
   * @return  uint256  returns total liquidity
   */
  function liquidityOf() public view returns (uint256) {
    return liquidityOfThis() + (liquidityOfPool());
  }

  /**
   * @notice  Check if Uni staking is active
   * @return  stakingActive  If the block timestamp is within staking period, then true, else false
   */
  function isStakingActive() public view returns (bool stakingActive) {
    return (block.timestamp >= key.startTime && block.timestamp < key.endTime) ? true : false;
  }

  /**
   * @notice  amount of liquid
   * @return  uint256  token0 value
   * @return  uint256  token1 value
   */
  function amountsForLiquid() public view returns (uint256, uint256) {
    (uint160 sqrtRatioX96, , , , , , ) = pool.globalState();
    (uint256 a1, uint256 a2) = algebraCalculator.amountsForLiquidity(sqrtRatioX96, 1e18, tick_lower, tick_upper);
    return (a1, a2);
  }

  /**
   * @notice  Determine the optimal tick for our pool
   * @return  _lowerTick  lower tick
   * @return  _upperTick  upper tick
   * @return  _innerLowerTick  inner lower tick
   * @return  _innerUpperTick  inner upper tick
   */
  function determineTicks()
    public
    view
    returns (
      int24 _lowerTick,
      int24 _upperTick,
      int24 _innerLowerTick,
      int24 _innerUpperTick
    )
  {
    uint32[] memory _observeTime = new uint32[](2);
    _observeTime[0] = twapTime;
    _observeTime[1] = 0;
    (int56[] memory _cumulativeTicks, , , ) = pool.getTimepoints(_observeTime);

    (_innerLowerTick, _innerUpperTick) = algebraCalculator.determineTicksCalc(
      _cumulativeTicks,
      tickSpacing,
      innerTickRangeMultiplier,
      twapTime
    );

    (_lowerTick, _upperTick) = algebraCalculator.determineTicksCalc(
      _cumulativeTicks,
      tickSpacing,
      tickRangeMultiplier,
      twapTime
    );
  }

  /**
   * @notice Calculates whether the current tick is within the specified range
   * @dev The range is determined by calling the `tick_lower` and `tick_upper` functions
   * @return true if the current tick is within the range, false otherwise
   */
  function inRangeCalc() public view returns (bool) {
    (, int24 currentTick, , , , , ) = pool.globalState();

    return currentTick > inner_tick_lower && currentTick < inner_tick_upper;
  }

  /**
   * @notice  Calculates balances of assets
   * @dev     Calcuates how much token0 / token1 exists in the contract
   * @return  _a0Expect  amount in token0 that is to be expected
   * @return  _a1Expect  amount in token1 that is to be expected
   */
  function getLiquidity() public view returns (uint256 _a0Expect, uint256 _a1Expect) {
    uint256 _liquidity = liquidityOfPool();
    (uint160 _sqrtRatioX96, , , , , , ) = pool.globalState();
    (_a0Expect, _a1Expect) = algebraCalculator.amountsForLiquidity(
      _sqrtRatioX96,
      uint128(_liquidity),
      tick_lower,
      tick_upper
    );
    _a0Expect += (IERC20(address(token0)).balanceOf(address(this)));
    _a1Expect += (IERC20(address(token1)).balanceOf(address(this)));
  }

  // **** Setters **** //

  /**
   * @notice  Adjusts harvesters for autocompounding, governance & strategists are whitelisted by default
   * @param   _harvesters  array of addresses to be whitelisted
   * @param   _values     boolean to allow or disallow harvesters
   */
  function adjustHarvesters(address[] calldata _harvesters, bool[] calldata _values) external {
    require(msg.sender == governance || msg.sender == strategist || harvesters[msg.sender], "not authorized");

    for (uint256 i = 0; i < _harvesters.length; i++) {
      harvesters[_harvesters[i]] = _values[i];
    }
  }

  /**
   * @notice  Performance fee of the protocol to be taken, the timelock only can update
   * @param   _performanceTreasuryFee  Amount of treasury fee
   */
  function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee) external {
    require(msg.sender == timelock, "!timelock");
    require(_performanceTreasuryFee < MAX_PERFORMANCE_TREASURY_FEE, "fee limit");
    performanceTreasuryFee = _performanceTreasuryFee;
  }

  /**
   * @notice  Update the new strategy, only by governance
   * @param   _strategist  new address
   */
  function setStrategist(address _strategist) external {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  /**
   * @notice  Update the new governance, only by governance
   * @param   _governance  new address
   */
  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  /**
   * @notice  Update the new governance, only by governance
   * @param   _timelock  new address
   */
  function setTimelock(address _timelock) external {
    require(msg.sender == timelock, "!timelock");
    timelock = _timelock;
  }

  /**
   * @notice  Update to the new timelock, only by timelock
   * @param   _controller  new address
   */
  function setController(address _controller) external {
    require(msg.sender == timelock, "!timelock");
    controller = _controller;
  }

  /**
   * @notice  Twap time, changeable only by governance
   * @param   _twapTime  new value
   */
  function setTwapTime(uint24 _twapTime) public {
    require(msg.sender == governance, "!governance");
    twapTime = _twapTime;
  }

  /**
   * @notice  Tick range multiplier for the rebalance
   * @param   _tickRangeMultiplier  the multiplier value
   * @param   _innerTickRangeMultiplier  the multiplier value for inner road
   */
  function setTickRangeMultiplier(int24 _tickRangeMultiplier, int24 _innerTickRangeMultiplier) public {
    require(msg.sender == governance, "!governance");
    tickRangeMultiplier = _tickRangeMultiplier;
    innerTickRangeMultiplier = _innerTickRangeMultiplier;
  }

  // **** State mutations **** //

  /**
   * @notice  withdraw the token and re-deposit with new total liquidity
   */
  function deposit() public {
    _harvestStaker();

    uint256 _token0 = token0.balanceOf(address(this));
    uint256 _token1 = token1.balanceOf(address(this));

    if (_token0 > 0 && _token1 > 0) {
      nftManager.increaseLiquidity(
        INonfungiblePositionManager.IncreaseLiquidityParams({
          tokenId: tokenId,
          amount0Desired: _token0,
          amount1Desired: _token1,
          amount0Min: 0,
          amount1Min: 0,
          deadline: block.timestamp + 300
        })
      );
    }
    redeposit();

    emit Deposited(tokenId, _token0, _token1);
  }

  /**
   * @notice  Controller only function for creating additional rewards from dust
   * @param   _asset  withdraw assets from the protocol
   * @return  balance  asset amount that has been withdrawn
   */
  function withdraw(IERC20 _asset) external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  /**
   * @notice  Override base withdraw function to redeposit
   * @param   _liquidity  amount of assets to be withdrawn
   * @return  a0  token0 amount
   * @return  a1  token1 amount
   */
  function withdraw(uint256 _liquidity) external returns (uint256 a0, uint256 a1) {
    require(msg.sender == controller, "!controller");
    (a0, a1) = _withdrawSome(_liquidity);

    address _vault = IControllerV7(controller).vaults(address(pool));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    token0.safeTransfer(_vault, a0);
    token1.safeTransfer(_vault, a1);

    redeposit();

    emit Withdrawn(tokenId, _liquidity);
  }

  /**
   * @notice  Withdraw all funds, normally used when migrating strategies
   * @return  a0  amount of token0
   * @return  a1  amount of token1
   */
  function withdrawAll() external returns (uint256 a0, uint256 a1) {
    require(msg.sender == controller, "!controller");
    _withdrawAll();
    address _vault = IControllerV7(controller).vaults(address(pool));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    a0 = token0.balanceOf(address(this));
    a1 = token1.balanceOf(address(this));
    token0.safeTransfer(_vault, a0);
    token1.safeTransfer(_vault, a1);
  }

  function _rebalanceAsset(uint256 _initToken0, uint256 _initToken1) internal {
    (, , , , , , uint128 _liquidity, , , , ) = nftManager.positions(tokenId);
    (uint256 _liqAmt0, uint256 _liqAmt1) = nftManager.decreaseLiquidity(
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: uint128(_liquidity),
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp + 300
      })
    );

    nftManager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );

    nftManager.sweepToken(address(token0), 0, address(this));
    nftManager.sweepToken(address(token1), 0, address(this));
    nftManager.burn(tokenId);
    tokenId = 0;

    _distributePerformanceFees(
      token0.balanceOf(address(this)) - (_liqAmt0 + _initToken0),
      token1.balanceOf(address(this)) - (_liqAmt1 + _initToken1)
    );
  }

  function _harvestStaker() internal {
    if (nftManager.ownerOf(tokenId) != address(this) && isStakingActive()) {
      (uint256 reward, uint256 bonusReward) = IFarmingCenter(algebraFarmingCenter).collectRewards(key, tokenId);
      if (reward > 0) {
        reward = IFarmingCenter(algebraFarmingCenter).claimReward(rewardToken, address(this), 0, type(uint256).max);
      }
      if (bonusReward > 0) {
        IFarmingCenter(algebraFarmingCenter).claimReward(bonusRewardToken, address(this), 0, type(uint256).max);
      }

      _exitStaker();

      IFarmingCenter(algebraFarmingCenter).withdrawToken(tokenId, address(this), new bytes(0));
    }
  }

  function withdrawToken() public onlyBenevolent {
    IFarmingCenter(algebraFarmingCenter).withdrawToken(tokenId, address(this), new bytes(0));
  }

  /**
   * @notice  Rebalancing, re-set the position and taking performance fee for the user
   */
  function harvest() public onlyBenevolent {
    uint256 _initToken0 = token0.balanceOf(address(this));
    uint256 _initToken1 = token1.balanceOf(address(this));

    _harvestStaker();

    _swapAssets();

    _rebalanceAsset(_initToken0, _initToken1);

    _balanceProportion(tick_lower, tick_upper);
    //Need to do this again after the swap to cover any slippage.
    uint256 _amount0Desired = token0.balanceOf(address(this));
    uint256 _amount1Desired = token1.balanceOf(address(this));

    (uint256 _tokenId, , , ) = nftManager.mint(
      INonfungiblePositionManager.MintParams({
        token0: address(token0),
        token1: address(token1),
        tickLower: tick_lower,
        tickUpper: tick_upper,
        amount0Desired: _amount0Desired,
        amount1Desired: _amount1Desired,
        amount0Min: (_amount0Desired * 90) / 100,
        amount1Min: (_amount1Desired * 90) / 100,
        recipient: address(this),
        deadline: block.timestamp + 300
      })
    );

    //Record updated information.
    tokenId = _tokenId;

    lastHarvest = block.timestamp;

    _enterStaker();

    emit Harvested(tokenId);
  }

  /**
   * @notice  This assumes rewardToken == (token0 || token1)
   * @return  _tokenId  new token id
   */
  function rebalance() external onlyBenevolent returns (uint256 _tokenId) {
    uint256 _initToken0 = token0.balanceOf(address(this));
    uint256 _initToken1 = token1.balanceOf(address(this));
    if (tokenId != 0) {
      _harvestStaker();
      _rebalanceAsset(_initToken0, _initToken1);
    }
    (int24 _tickLower, int24 _tickUpper, int24 _innerTickLower, int24 _innerTickUpper) = determineTicks();
    _balanceProportion(_tickLower, _tickUpper);
    //Need to do this again after the swap to cover any slippage.
    uint256 _amount0Desired = token0.balanceOf(address(this));
    uint256 _amount1Desired = token1.balanceOf(address(this));

    (_tokenId, , , ) = nftManager.mint(
      INonfungiblePositionManager.MintParams({
        token0: address(token0),
        token1: address(token1),
        tickLower: _tickLower,
        tickUpper: _tickUpper,
        amount0Desired: _amount0Desired,
        amount1Desired: _amount1Desired,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp + 300
      })
    );

    //Record updated information.
    tokenId = _tokenId;
    tick_lower = _tickLower;
    tick_upper = _tickUpper;
    inner_tick_lower = _innerTickLower;
    inner_tick_upper = _innerTickUpper;

    nftManager.approve(address(nftManager), tokenId);

    if (isStakingActive()) {
      nftManager.safeTransferFrom(address(this), algebraFarmingCenter, tokenId);
      IFarmingCenter(algebraFarmingCenter).enterFarming(key, tokenId, 0, isLimit);
    }

    if (tokenId == 0) {
      emit InitialDeposited(_tokenId);
    }

    emit Rebalanced(tokenId, _tickLower, _tickUpper);
  }

  // **** Internal functions ****

  /**
   * @notice  Deposit + stake in Uni v3 staker
   */
  function redeposit() internal {
    _enterStaker();
  }

  /**
   * @notice  Withdraw all assets of pool
   * @return  a0  amount of token0
   * @return  a1  amount of token1
   */
  function _withdrawAll() internal returns (uint256 a0, uint256 a1) {
    (a0, a1) = _withdrawSome(liquidityOfPool());
  }

  /**
   * @notice  Withdraw some assets from the protocol
   * @param   _liquidity  amount to be withdrawn
   * @return  uint256  return amount 0
   * @return  uint256  return amount 1
   */
  function _withdrawSome(uint256 _liquidity) internal returns (uint256, uint256) {
    if (_liquidity == 0) return (0, 0);
    _exitStaker();

    (uint160 sqrtRatioX96, , , , , , ) = pool.globalState();
    (uint256 _a0Expect, uint256 _a1Expect) = algebraCalculator.amountsForLiquidity(
      sqrtRatioX96,
      uint128(_liquidity),
      tick_lower,
      tick_upper
    );

    IFarmingCenter(algebraFarmingCenter).withdrawToken(tokenId, address(this), new bytes(0));
    nftManager.approve(address(nftManager), tokenId);
    (uint256 amount0, uint256 amount1) = nftManager.decreaseLiquidity(
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: uint128(_liquidity),
        amount0Min: _a0Expect,
        amount1Min: _a1Expect,
        deadline: block.timestamp + 300
      })
    );

    //Only collect decreasedLiquidity, not trading fees.
    nftManager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: uint128(amount0),
        amount1Max: uint128(amount1)
      })
    );

    return (amount0, amount1);
  }

  /// @dev Get imbalanced token
  /// @param amount0Desired The desired amount of token0
  /// @param amount1Desired The desired amount of token1
  /// @param amount0 Amounts of token0 that can be stored in base range
  /// @param amount1 Amounts of token1 that can be stored in base range
  /// @return zeroGreaterOne true if token0 is imbalanced. False if token1 is imbalanced
  function _amountsDirection(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0,
    uint256 amount1
  ) internal pure returns (bool zeroGreaterOne) {
    zeroGreaterOne = (amount0Desired - amount0) * amount1Desired > (amount1Desired - amount1) * amount0Desired
      ? true
      : false;
  }

  /**
   * @notice  Send the performance fee to the treasury
   * @param   _amount0  amount 0 to be sent towards the treasury
   * @param   _amount1  amount 1 to be sent towards the treasury
   */
  function _distributePerformanceFees(uint256 _amount0, uint256 _amount1) internal {
    if (_amount0 > 0) {
      IERC20(token0).safeTransfer(
        IControllerV7(controller).treasury(),
        (_amount0 * (performanceTreasuryFee)) / (performanceTreasuryMax)
      );
    }
    if (_amount1 > 0) {
      IERC20(token1).safeTransfer(
        IControllerV7(controller).treasury(),
        (_amount1 * (performanceTreasuryFee)) / (performanceTreasuryMax)
      );
    }
  }

  function _exitStaker() internal {
    if (nftManager.ownerOf(tokenId) != address(this) && isStakingActive()) {
      IFarmingCenter(algebraFarmingCenter).exitFarming(key, tokenId, isLimit);
    }
  }

  function _enterStaker() internal {
    if (nftManager.ownerOf(tokenId) == address(this) && isStakingActive()) {
      nftManager.safeTransferFrom(address(this), algebraFarmingCenter, tokenId);
      IFarmingCenter(algebraFarmingCenter).enterFarming(key, tokenId, 0, isLimit);
    }
  }

  function _swapAssets() internal {
    swapRewardToken();
    // swapBonusRewardToken();
  }

  function swapRewardToken() internal virtual {
    uint256 lairBal = IERC20(rewardToken).balanceOf(address(this));
    if (lairBal == 0) return;
    IDragonsLair(rewardToken).leave(lairBal);
    uint256 outputBal = IERC20(quickToken).balanceOf(address(this));

    if (outputBal == 0) return;
    IERC20(quickToken).safeApprove(uniRouter, outputBal);
    IUniswapRouterETH(uniRouter).swapExactTokensForTokens(
      outputBal,
      0,
      outputToAssetRewardToken,
      address(this),
      block.timestamp
    );
  }

  /**
   * @notice Update the array of addresses representing the path to the asset reward token.
   * @param _newPath An array of addresses representing the new path to the asset reward token.
   * @dev The `outputToAssetRewardToken` state variable is updated with the new path.
   */
  function updateOutputToAssetRewardToken(address[] memory _newPath) external {
    require(msg.sender == timelock, "!timelock");
    outputToAssetRewardToken = _newPath;
  }

  /**
   * @notice Update the address of the bonus reward token.
   * @param _bonusRewardToken The new address of the bonus reward token.
   * @dev The `bonusRewardToken` state variable is updated with the new address.
   */
  function updateBonusRewardToken(address _bonusRewardToken) external {
    require(msg.sender == timelock, "!timelock");
    bonusRewardToken = _bonusRewardToken;
  }

  /**
   * @notice Update the address of the reward token.
   * @param _rewardToken The new address of the reward token.
   * @dev The `rewardToken` state variable is updated with the new address.
   */
  function updateRewardToken(address _rewardToken) external {
    require(msg.sender == timelock, "!timelock");
    rewardToken = _rewardToken;
  }

  // function swapBonusRewardToken() internal virtual {}

  // /**
  //  * @notice Swap a token using the 1inch exchange.
  //  * @param _oneInchRouter The address of the 1inch router contract.
  //  * @param _token The address of the token contract.
  //  * @param data The data payload to pass to the 1inch router contract.
  //  * @dev The `approve` function of the token contract is called with the `_oneInchRouter`
  //  * address as the spender and the maximum possible value of `uint256` as the amount.
  //  * @dev The `call` function of the 1inch router contract is called with the `data` payload. If
  //  * the call is unsuccessful, an error message is thrown.
  //  * @dev The `approve` function of the token contract is called with the `_oneInchRouter` address
  //  * as the spender and 0 as the amount.
  //  */
  // function swapTokenVia1inch(
  //   address _oneInchRouter,
  //   IERC20 _token,
  //   bytes calldata data
  // ) external onlyBenevolent {
  //   _token.approve(_oneInchRouter, type(uint256).max);
  //   require((token0) != _token && (token1) != _token, "token can not be traded");
  //   (bool success, ) = _oneInchRouter.call(data);
  //   require(success, "1inch swap unsucessful");
  //   _token.approve(_oneInchRouter, 0);
  //   harvest();
  // }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function amountDetection()
    public
    view
    returns (
      uint256 _amount0,
      uint256 _amount1,
      uint256 _amount0Desired,
      uint256 _amount1Desired
    )
  {
    Info memory _cache;

    _amount0Desired = token0.balanceOf(address(this));
    _amount1Desired = token1.balanceOf(address(this));
    (uint160 sqrtRatioX96, , , , , , ) = pool.globalState();

    //Get Max Liquidity for Amounts we own.
    uint128 _liquidity = algebraCalculator.liquidityForAmounts(
      sqrtRatioX96,
      _cache.amount0Desired,
      _cache.amount1Desired,
      tick_lower,
      tick_upper
    );

    //Get correct amounts of each token for the liquidity we have.
    (_amount0, _amount1) = algebraCalculator.amountsForLiquidity(
      sqrtRatioX96,
      _cache.liquidity,
      tick_lower,
      tick_upper
    );

    //Determine Trade Direction
    bool _zeroForOne;
    if (_cache.amount1Desired == 0) {
      _zeroForOne = true;
    } else {
      _zeroForOne = _amountsDirection(_cache.amount0Desired, _cache.amount1Desired, _cache.amount0, _cache.amount1);
    }
  }

  /**
   * @notice Rebalance assets for liquidity and swap if necessary
   * @param   _tickLower  lower tick
   * @param   _tickUpper  upper tick
   */
  function _balanceProportion(int24 _tickLower, int24 _tickUpper) internal {
    Info memory _cache;

    _cache.amount0Desired = token0.balanceOf(address(this));
    _cache.amount1Desired = token1.balanceOf(address(this));
    (uint160 sqrtRatioX96, , , , , , ) = pool.globalState();

    //Get Max Liquidity for Amounts we own.
    _cache.liquidity = algebraCalculator.liquidityForAmounts(
      sqrtRatioX96,
      _cache.amount0Desired,
      _cache.amount1Desired,
      _tickLower,
      _tickUpper
    );

    //Get correct amounts of each token for the liquidity we have.
    (_cache.amount0, _cache.amount1) = algebraCalculator.amountsForLiquidity(
      sqrtRatioX96,
      _cache.liquidity,
      _tickLower,
      _tickUpper
    );

    //Determine Trade Direction
    bool _zeroForOne;
    if (_cache.amount1Desired == 0) {
      _zeroForOne = true;
    } else {
      _zeroForOne = _amountsDirection(_cache.amount0Desired, _cache.amount1Desired, _cache.amount0, _cache.amount1);
    }

    //Determine Amount to swap
    uint256 _amountSpecified = _zeroForOne
      ? ((_cache.amount0Desired - _cache.amount0) / 2)
      : ((_cache.amount1Desired - _cache.amount1) / 2);

    if (_amountSpecified > 0) {
      //Determine Token to swap
      address _inputToken = _zeroForOne ? address(token0) : address(token1);

      IERC20(_inputToken).safeApprove(ALGEBRA_ROUTER, 0);
      IERC20(_inputToken).safeApprove(ALGEBRA_ROUTER, _amountSpecified);

      //Swap the token imbalanced
      ISwapRouter(ALGEBRA_ROUTER).exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
          tokenIn: _inputToken,
          tokenOut: _zeroForOne ? address(token1) : address(token0),
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _amountSpecified,
          amountOutMinimum: 0,
          limitSqrtPrice: 0
        })
      );
    }
  }

  function updateRewardTokenPath(
    address[] memory _outputToAssetRewardToken,
    address[] memory _outputToAssetBonusRewardToken
  ) external {
    require(msg.sender == governance, "!governance");
    outputToAssetRewardToken = _outputToAssetRewardToken;
    outputToAssetBonusRewardToken = _outputToAssetBonusRewardToken;
    rewardToken = _outputToAssetRewardToken[0];
    bonusRewardToken = _outputToAssetBonusRewardToken[0];

    key = IFarmingCenter.IncentiveKey({
      rewardToken: (rewardToken),
      bonusRewardToken: (bonusRewardToken),
      pool: address(pool),
      startTime: startTime,
      endTime: endTime
    });
  }
}