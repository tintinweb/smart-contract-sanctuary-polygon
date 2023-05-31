/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

interface IERC20Ext is IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUpgradeSource {
  function finalizeUpgrade() external;
  function shouldUpgrade() external view returns (bool, address);
}

interface IVault is IERC20 {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function doHardWork() external;
    function getReward() external;
    function initializeVault(
        address,
        address,
        uint256,
        bool,
        uint256
    ) external;
    function setStrategy(address) external;
    function addRewardDistribution(address) external;
    function addRewardToken(address, uint256) external;
    function strategy() external view returns (address);
    function getPricePerFullShare() external view returns (uint256);
}

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()
    function pendingYield() external view returns (uint256[] memory);

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.

library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

library JsonWriter {

    using JsonWriter for string;

    struct Json {
        int256 depthBitTracker;
        string value;
    }

    bytes1 constant BACKSLASH = bytes1(uint8(92));
    bytes1 constant BACKSPACE = bytes1(uint8(8));
    bytes1 constant CARRIAGE_RETURN = bytes1(uint8(13));
    bytes1 constant DOUBLE_QUOTE = bytes1(uint8(34));
    bytes1 constant FORM_FEED = bytes1(uint8(12));
    bytes1 constant FRONTSLASH = bytes1(uint8(47));
    bytes1 constant HORIZONTAL_TAB = bytes1(uint8(9));
    bytes1 constant NEWLINE = bytes1(uint8(10));

    string constant TRUE = "true";
    string constant FALSE = "false";
    bytes1 constant OPEN_BRACE = "{";
    bytes1 constant CLOSED_BRACE = "}";
    bytes1 constant OPEN_BRACKET = "[";
    bytes1 constant CLOSED_BRACKET = "]";
    bytes1 constant LIST_SEPARATOR = ",";

    int256 constant MAX_INT256 = type(int256).max;

    /**
     * @dev Writes the beginning of a JSON array.
     */
    function writeStartArray(Json memory json) 
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON array with a property name as the key.
     */
    function writeStartArray(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON object.
     */
    function writeStartObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACE);
    }

    /**
     * @dev Writes the beginning of a JSON object with a property name as the key.
     */
    function writeStartObject(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACE);
    }

    /**
     * @dev Writes the end of a JSON array.
     */
    function writeEndArray(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACKET);
    }

    /**
     * @dev Writes the end of a JSON object.
     */
    function writeEndObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACE);
    }

    /**
     * @dev Writes the property name and address value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeAddressProperty(
        Json memory json,
        string memory propertyName,
        address value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', addressToString(value), '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', addressToString(value), '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the address value (as a JSON string) as an element of a JSON array.
     */
    function writeAddressValue(Json memory json, address value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', addressToString(value), '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', addressToString(value), '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and boolean value (as a JSON literal "true" or "false") as part of a name/value pair of a JSON object.
     */
    function writeBooleanProperty(
        Json memory json,
        string memory propertyName,
        bool value
    ) internal pure returns (Json memory) {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', strValue));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', strValue));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the boolean value (as a JSON literal "true" or "false") as an element of a JSON array.
     */
    function writeBooleanValue(Json memory json, bool value)
        internal
        pure
        returns (Json memory)
    {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, strValue));
        } else {
            json.value = string(abi.encodePacked(json.value, strValue));
        }
        
        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and int value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeIntProperty(
        Json memory json,
        string memory propertyName,
        int256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', intToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', intToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the int value (as a JSON number) as an element of a JSON array.
     */
    function writeIntValue(Json memory json, int256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, intToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, intToString(value)));
        }
        
        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and value of null as part of a name/value pair of a JSON object.
     */
    function writeNullProperty(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": null'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": null'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the value of null as an element of a JSON array.
     */
    function writeNullValue(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, "null"));
        } else {
            json.value = string(abi.encodePacked(json.value, "null"));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the string text value (as a JSON string) as an element of a JSON array.
     */
    function writeStringProperty(
        Json memory json,
        string memory propertyName,
        string memory value
    ) internal pure returns (Json memory) {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', jsonEscapedString, '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', jsonEscapedString, '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and string text value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeStringValue(Json memory json, string memory value)
        internal
        pure
        returns (Json memory)
    {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', jsonEscapedString, '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', jsonEscapedString, '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and uint value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeUintProperty(
        Json memory json,
        string memory propertyName,
        uint256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', uintToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', uintToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the uint value (as a JSON number) as an element of a JSON array.
     */
    function writeUintValue(Json memory json, uint256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, uintToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, uintToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter.
     */
    function writeStart(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, token));
        } else {
            json.value = string(abi.encodePacked(json.value, token));
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter with a property name as the key.
     */
    function writeStart(
        Json memory json,
        string memory propertyName,
        bytes1 token
    ) private pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', token));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', token));
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the end of a JSON array or object based on the token parameter.
     */
    function writeEnd(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        json.value = string(abi.encodePacked(json.value, token));
        json.depthBitTracker = setListSeparatorFlag(json);
        
        if (getCurrentDepth(json) != 0) {
            json.depthBitTracker--;
        }

        return json;
    }

    /**
     * @dev Escapes any characters that required by JSON to be escaped.
     */
    function escapeJsonString(string memory value)
        private
        pure
        returns (string memory str)
    {
        bytes memory b = bytes(value);
        bool foundEscapeChars;

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == DOUBLE_QUOTE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FRONTSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == HORIZONTAL_TAB) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FORM_FEED) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == NEWLINE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == CARRIAGE_RETURN) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == BACKSPACE) {
                foundEscapeChars = true;
                break;
            }
        }

        if (!foundEscapeChars) {
            return value;
        }

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                str = string(abi.encodePacked(str, "\\\\"));
            } else if (b[i] == DOUBLE_QUOTE) {
                str = string(abi.encodePacked(str, '\\"'));
            } else if (b[i] == FRONTSLASH) {
                str = string(abi.encodePacked(str, "\\/"));
            } else if (b[i] == HORIZONTAL_TAB) {
                str = string(abi.encodePacked(str, "\\t"));
            } else if (b[i] == FORM_FEED) {
                str = string(abi.encodePacked(str, "\\f"));
            } else if (b[i] == NEWLINE) {
                str = string(abi.encodePacked(str, "\\n"));
            } else if (b[i] == CARRIAGE_RETURN) {
                str = string(abi.encodePacked(str, "\\r"));
            } else if (b[i] == BACKSPACE) {
                str = string(abi.encodePacked(str, "\\b"));
            } else {
                str = string(abi.encodePacked(str, b[i]));
            }
        }

        return str;
    }

    /**
     * @dev Tracks the recursive depth of the nested objects / arrays within the JSON text
     * written so far. This provides the depth of the current token.
     */
    function getCurrentDepth(Json memory json) private pure returns (int256) {
        return json.depthBitTracker & MAX_INT256;
    }

    /**
     * @dev The highest order bit of json.depthBitTracker is used to discern whether we are writing the first item in a list or not.
     * if (json.depthBitTracker >> 255) == 1, add a list separator before writing the item
     * else, no list separator is needed since we are writing the first item.
     */
    function setListSeparatorFlag(Json memory json)
        private
        pure
        returns (int256)
    {
        return json.depthBitTracker | (int256(1) << 255);
    }

        /**
     * @dev Converts an address to a string.
     */
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes16 alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(str);
    }

    /**
     * @dev Converts an int to a string.
     */
    function intToString(int256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }

        if (i == type(int256).min) {
            // hard-coded since int256 min value can't be converted to unsigned
            return "-57896044618658097711785492504343953926634992332820282019728792003956564819968"; 
        }

        bool negative = i < 0;
        uint256 len;
        uint256 j;
        if(!negative) {
            j = uint256(i);
        } else {
            j = uint256(-i);
            ++len; // make room for '-' sign
        }
        
        uint256 l = j;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (l != 0) {
            bstr[--k] = bytes1((48 + uint8(l - (l / 10) * 10)));
            l /= 10;
        }

        if (negative) {
            bstr[0] = "-"; // prepend '-'
        }

        return string(bstr);
    }

    /**
     * @dev Converts a uint to a string.
     */
    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1((48 + uint8(_i - (_i / 10) * 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}

// COPIED AND MODIFIED FROM: @openzeppelin/upgrades.

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    impl = StorageSlot.getAddressSlot(slot).value;
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    StorageSlot.getAddressSlot(slot).value = newImplementation;
  }
}

/// @title Beluga Proxy
/// @author Chainvisions
/// @notice Proxy for Beluga's contracts.

contract BelugaProxy is BaseUpgradeabilityProxy {

    constructor(address _impl) {
        _setImplementation(_impl);
    }

    /**
    * The main logic. If the timer has elapsed and there is a schedule upgrade,
    * the governance can upgrade the contract
    */
    function upgrade() external {
        (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
        require(should, "Beluga Proxy: Upgrade not scheduled");
        _upgradeTo(newImplementation);

        // The finalization needs to be executed on itself to update the storage of this proxy
        // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature("finalizeUpgrade()")
        );

        require(success, "Beluga Proxy: Issue when finalizing the upgrade");
    }

    function implementation() external view returns (address) {
        return _implementation();
    }
}

library CoreStorage {
    enum StrategyType {
        Autocompound,
        Maximizer
    }

    struct RegistryData {
        StrategyType strategyType;
        address vaultAddress;
        address underlyingAddress;
    }

    struct Layout {
        address governance;
        address pendingGovernance;
        uint256 profitSharingNumerator;
        uint256 rebateNumerator;
        address reserveToken;
        address latestVaultImplementation;
        address nextImplementation;

        RegistryData[] registeredVaults;
        mapping(address => bool) whitelist;
        mapping(address => bool) feeExemptAddresses;
        mapping(address => bool) greyList;
        mapping(address => bool) keepers;
        mapping(address => uint256) lastHarvestTimestamp;
        mapping(address => bool) transferFeeTokens;
        mapping(address => mapping(address => address[])) tokenConversionRoute;
    
        mapping(address => mapping(address => address)) tokenConversionRouter;
        mapping(address => mapping(address => address[])) tokenConversionRouters;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('beluga.contracts.storage.Core');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/// @title Beluga Core Protocol
/// @author Chainvisions
/// @notice Core protocol contract for access control and harvests.

contract Core is Initializable, IUpgradeSource {
    using CoreStorage for CoreStorage.Layout;
    using JsonWriter for JsonWriter.Json;
    using SafeTransferLib for IERC20;

    // Structure for a vault deployment
    struct Deployment {
        address vault;
        address strategy;
        address strategyImpl;
    }

    /// @notice Numerator for percentage calculations.
    uint256 public constant NUMERATOR = 10000;

    /// @notice Literally just a true boolean.
    bool public constant yes = true;

    /// @notice Literally just a false boolean.
    bool public constant no = false;

    /// @notice Emitted on a successful doHardWork.
    /// @param vault Vault that the harvest was performed on.
    /// @param strategy Strategy of the vault.
    /// @param oldSharePrice Old price per full share of the vault.
    /// @param newSharePrice New price per full share of the vault.
    /// @param timestamp Timestamp of the vault harvest.
    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    /// @notice Emitted on a failed doHardWork on `batchDoHardWork()` calls.
    /// @param vault Vault that the harvest failed on.
    event FailedHarvest(address indexed vault);

    /// @notice Emitted on a successful rebalance on a vault.
    /// @param vault Vault that the rebalance was performed on.
    event VaultRebalance(address indexed vault);

    /// @notice Emitted on a failed rebalance on `batchRebalance()` calls.
    /// @param vault Vault that the rebalance failed on.
    event FailedRebalance(address indexed vault);

    /// @notice Emitted when governance is transferred to a new address.
    /// @param prevGovernance Previous governance address.
    /// @param newGovernance New governance address.
    event GovernanceTransferred(address prevGovernance, address newGovernance);

    /// @notice Emitted on vault deployment.
    /// @param vault Vault deployed.
    /// @param strategy Strategy deployed.
    /// @param vaultType Type of vault deployed.
    event VaultDeployment(address vault, address strategy, string vaultType);

    /// @notice Emitted when an upgrade is scheduled on the contract.
    /// @param newImplementation New implementation of the contract.
    event UpgradeScheduled(address newImplementation);

    /// @notice Used for limiting certain functions to governance only.
    modifier onlyGovernance {
        require(msg.sender == CoreStorage.layout().governance);
        _;
    }

    /// @notice Initializes the Core contract.
    /// @param _governance Address of Beluga governance.
    /// @param _reserveToken Reserve token that fees are converted to.
    /// @param _latestVaultImplementation Latest implementation of the vault contract.
    function initialize(
        address _governance,
        address _reserveToken,
        address _latestVaultImplementation
    ) external initializer {
        CoreStorage.layout().governance = _governance;
        CoreStorage.layout().profitSharingNumerator = 400;
        CoreStorage.layout().rebateNumerator = 1000;
        CoreStorage.layout().reserveToken = _reserveToken;
        CoreStorage.layout().latestVaultImplementation = _latestVaultImplementation;
    }

    /// @notice Deploys and configures a new vault contract.
    /// @param _underlying The underlying token that the vault accepts.
    /// @param _exitFee The exit fee charged by the vault on early withdrawal.
    /// @param _bytecode The bytecode of the vault's strategy contract implementation.
    /// @param _deployAsMaximizer Whether or not to deploy the vault as a maximizer.
    /// @return The deployed contracts that are part of the vault.
    function deployVault(
        address _underlying,
        uint256 _exitFee,
        bytes memory _bytecode,
        bool _deployAsMaximizer
    ) public returns (Deployment memory) {
        require(CoreStorage.layout().keepers[msg.sender]);
        // Create a variable for the deployment metadata to return.
        Deployment memory deploymentData;

        // Deploy and initialize a new vault proxy.
        BelugaProxy proxy = new BelugaProxy(CoreStorage.layout().latestVaultImplementation);
        deploymentData.vault = address(proxy);
        IVault vaultProxy = IVault(address(proxy));
        vaultProxy.initializeVault(address(this), _underlying, 9999, yes, _exitFee);

        // Deploy a new strategy contract.
        address strategyImpl = _create(_bytecode);
        BelugaProxy strategyProxy = new BelugaProxy(strategyImpl);
        (bool initStatus, ) = address(strategyProxy).call(abi.encodeWithSignature("initializeStrategy(address,address)", address(this), address(proxy)));
        require(initStatus, "VaultDeployer: Strategy initialization failed");
        deploymentData.strategy = address(strategyProxy);
        deploymentData.strategyImpl = strategyImpl;

        vaultProxy.setStrategy(address(strategyProxy));

        // Handle vault configuration.
        if(_deployAsMaximizer) {
            // Set the strategy as reward distribution on the vault.
            vaultProxy.addRewardDistribution(address(strategyProxy));

            // Fetch the reward token to add to the vault.
            (,bytes memory encodedReward) = address(strategyProxy).staticcall(abi.encodeWithSignature("targetVault()"));
            address vaultReward = abi.decode(encodedReward, (address));

            // Add the reward token to the vault with a reward duration of 1 hour.
            vaultProxy.addRewardToken(vaultReward, 900);
            CoreStorage.layout().whitelist[address(strategyProxy)] = yes;
            CoreStorage.layout().feeExemptAddresses[address(strategyProxy)] = yes;
        }

        CoreStorage.layout().registeredVaults.push(
            CoreStorage.RegistryData(
                _deployAsMaximizer == false ? CoreStorage.StrategyType.Autocompound : CoreStorage.StrategyType.Maximizer,
                address(proxy), 
                _underlying
            )
        );
        emit VaultDeployment(
            address(proxy),
            address(strategyProxy),
            _deployAsMaximizer == false ? "autocompounding" : "maximizer"
        );
        return deploymentData;
    }

    /// @notice Collects `_token` that is in the Controller.
    /// @param _token Token to salvage from the contract.
    /// @param _amount Amount of `_token` to salvage.
    function salvage(
        address _token,
        uint256 _amount
    ) external onlyGovernance {
        IERC20(_token).safeTransfer(CoreStorage.layout().governance, _amount);
    }

    /// @notice Salvages tokens from the specified strategy.
    /// @param _strategy Address of the strategy to salvage from.
    /// @param _token Token to salvage from `_strategy`.
    /// @param _amount Amount of `_token` to salvage from `_strategy`.
    function salvageStrategy(
        address _strategy,
        address _token,
        uint256 _amount
    ) external onlyGovernance {
        IStrategy(_strategy).salvage(CoreStorage.layout().governance, _token, _amount);
    }

    /// @notice Salvages multiple tokens from the Controller.
    /// @param _tokens Tokens to salvage.
    function salvageMultipleTokens(
        address[] calldata _tokens
    ) external onlyGovernance {
        address _governance = CoreStorage.layout().governance;
        for(uint256 i; i < _tokens.length;) {
            IERC20 token = IERC20(_tokens[i]);
            token.safeTransfer(_governance, token.balanceOf(address(this)));
            unchecked { ++i; }
        }
    }

    /// @notice Converts `_tokenFrom` into Beluga's target tokens.
    /// @param _tokenFrom Token to convert from.
    /// @param _fee Performance fees to convert into the target tokens.
    function notifyFee(address _tokenFrom, uint256 _fee) external {
        CoreStorage.layout().lastHarvestTimestamp[msg.sender] = block.timestamp;
        IERC20 reserve = IERC20(CoreStorage.layout().reserveToken);
        // If the token is the reserve token, send it to the multisig.
        if(_tokenFrom == address(reserve)) {
            IERC20(_tokenFrom).safeTransferFrom(msg.sender, CoreStorage.layout().governance, _fee);
            return;
        }
        // Else, the token needs to be converted to wrapped(native).
        address[] memory targetRouteToReward = CoreStorage.layout().tokenConversionRoute[_tokenFrom][address(reserve)]; // Save to memory to save gas.
        if(targetRouteToReward.length > 1) {
            // Perform conversion if a route to wrapped(native) from `_tokenFrom` is specified.
            IERC20(_tokenFrom).safeTransferFrom(msg.sender, address(this), _fee);
            uint256 feeAfter = IERC20(_tokenFrom).balanceOf(address(this)); // In-case the token has transfer fees.
            IUniswapV2Router02 targetRouter = IUniswapV2Router02(CoreStorage.layout().tokenConversionRouter[_tokenFrom][address(reserve)]);
            if(address(targetRouter) != address(0)) {
                // We can safely perform a regular swap.
                uint256 endAmount = _performSwap(targetRouter, IERC20(_tokenFrom), feeAfter, targetRouteToReward);

                // Calculate and distribute split.
                uint256 rebateAmount = (endAmount * CoreStorage.layout().rebateNumerator) / NUMERATOR;
                uint256 remainingAmount = (endAmount - rebateAmount);
                reserve.safeTransfer(tx.origin, rebateAmount);
                reserve.safeTransfer(CoreStorage.layout().governance, remainingAmount);
            } else {
                // Else, we need to perform a cross-dex liquidation.
                address[] memory targetRouters = CoreStorage.layout().tokenConversionRouters[_tokenFrom][address(reserve)];
                uint256 endAmount = _performMultidexSwap(targetRouters, _tokenFrom, feeAfter, targetRouteToReward);

                // Calculate and distribute split.
                uint256 rebateAmount = (endAmount * CoreStorage.layout().rebateNumerator) / NUMERATOR;
                uint256 remainingAmount = (endAmount - rebateAmount);
                reserve.safeTransfer(tx.origin, rebateAmount);
                reserve.safeTransfer(CoreStorage.layout().governance, remainingAmount);
            }
        } else {
            // Else, leave the funds in the Controller.
            return;
        }
    }

    /// @notice Schedules a new upgrade on the core protocol contract.
    /// @param _newImplementation New implementation of the core contract.
    function scheduleUpgrade(
        address _newImplementation
    ) external onlyGovernance {
        CoreStorage.layout().nextImplementation = _newImplementation;
        emit UpgradeScheduled(_newImplementation);
    }

    /// @notice Changes the current vault implementation.
    /// @param _newImplementation New implementation of the vault.
    function setVaultImplementation(
        address _newImplementation
    ) external onlyGovernance {
        CoreStorage.layout().latestVaultImplementation = _newImplementation;
    }

    /// @notice Simulates a harvest on a vault. Meant to be called statically.
    /// @param _vault Vault to simulate a harvest on.
    /// @return bounty Bounty for harvesting the vault.
    /// @return gasUsed Gas used to harvest.
    function simulateHarvest(
        address _vault
    ) external returns (uint256 bounty, uint256 gasUsed) {
        uint256 initialReserve = IERC20(CoreStorage.layout().reserveToken).balanceOf(tx.origin);
        uint256 initialGas = gasleft();
        doHardWork(_vault);
        gasUsed = initialGas - gasleft();
        bounty = IERC20(CoreStorage.layout().reserveToken).balanceOf(tx.origin) - initialReserve;
    }

    /// @notice Fetches the last harvest on a specific vault.
    /// @return Timestamp of the vault's most recent harvest.
    function fetchLastHarvestForVault(address _vault) external view returns (uint256) {
        return CoreStorage.layout().lastHarvestTimestamp[IVault(_vault).strategy()];
    }

    /// @notice Lists all registered vaults.
    /// @return All vaults registered on the protocol in JSON format.
    function registry() external view returns (string[] memory) {
        CoreStorage.RegistryData[] memory registeredVaults = CoreStorage.layout().registeredVaults;
        string[] memory vaults = new string[](registeredVaults.length);
        for(uint256 i; i < vaults.length;) {
            CoreStorage.RegistryData memory vault = registeredVaults[i];
            JsonWriter.Json memory writer;
            string memory tokenSymbol;
            bool isRegularToken;
            {
                try IUniswapV2Pair(vault.underlyingAddress).token0() {
                    isRegularToken = no;
                } catch {
                    isRegularToken = yes;
                }
            }

            // Construct token symbol.
            if(isRegularToken) {
                string memory symbol = IERC20Ext(vault.underlyingAddress).symbol();
                tokenSymbol = vault.strategyType == CoreStorage.StrategyType.Autocompound ? string.concat("b", symbol) : string.concat(symbol, " Maximizer");
            } else {
                string memory symbol = string.concat(
                    string.concat(
                        IERC20Ext(IUniswapV2Pair(vault.underlyingAddress).token0()).symbol(), 
                        string.concat(
                            "-", IERC20Ext(IUniswapV2Pair(vault.underlyingAddress).token1()).symbol()
                        )
                    ),
                    " LP"
                );
                tokenSymbol = vault.strategyType == CoreStorage.StrategyType.Autocompound ? string.concat("b", symbol) : string.concat(symbol, " Maximizer");
            }

            writer.writeStartObject();
            writer.writeStringProperty("name", tokenSymbol);
            writer.writeAddressProperty("address", vault.vaultAddress);
            writer.writeAddressProperty("underlyingAddress", vault.underlyingAddress);
            writer.writeStringProperty("strategyType", vault.strategyType == CoreStorage.StrategyType.Autocompound ? "autocompound" : "maximizer");
            writer.writeEndObject();

            vaults[i] = writer.value;
            unchecked { ++i; }
        }

        return vaults;
    }

    /// @notice Finalizes an upgrade by zero'ing the pending implementation.
    function finalizeUpgrade() external override {
        CoreStorage.layout().nextImplementation = address(0);
    }

    /// @notice Fetches the storage value of the profitsharing numerator.
    /// @return Numerator for vault performance fees.
    function profitSharingNumerator() external view returns (uint256) {
        return CoreStorage.layout().profitSharingNumerator;
    }

    /// @notice Fetches the pure value of the profitsharing denominator.
    /// @return Denominator for vault performance fees.
    function profitSharingDenominator() external pure returns (uint256) {
        return NUMERATOR;
    }

    /// @notice Provides backwards compatability with existing contracts.
    /// @return The address of the core protocol.
    function governance() external view returns (address) {
        return address(this);
    }

    /// @notice Provides backwards compatability with existing contracts.
    /// @return The address of the core protocol.
    function controller() external view returns (address) {
        return address(this);
    }

    /// @notice Fetches whether or not a contract is whitelisted.
    /// @param _contract Contract to check whitelisting for.
    /// @return Whether or not the contract is whitelisted.
    function whitelist(address _contract) external view returns (bool) {
        return CoreStorage.layout().whitelist[_contract];
    }

    /// @notice Fetches whether or not a contract is exempt from penalties.
    /// @param _contract Contract to check exemption for.
    /// @return Whether or not the contract is exempt.
    function feeExemptAddresses(address _contract) external view returns (bool) {
        return CoreStorage.layout().feeExemptAddresses[_contract];
    }

    /// @notice Fetches whether or not a contract is whitelisted (old method).
    /// @param _contract Contract to check whitelisting for.
    /// @return Whether or not the contract is whitelisted.
    function greyList(address _contract) external view returns (bool) {
        return CoreStorage.layout().greyList[_contract];
    }

    /// @notice Fetches the governance address from storage.
    /// @return Protocol governance address.
    function protocolGovernance() external view returns (address) {
        return CoreStorage.layout().governance;
    }

    /// @notice Fetches the next implementation from storage.
    /// @return Next implementation of the core protocol contract.
    function nextImplementation() external view returns (address) {
        return CoreStorage.layout().nextImplementation;
    }

    /// @notice List of tokens that are marked as transfer fee for special handling.
    /// @param _token Token to check.
    /// @return Whether or not the token is marked as a transfer fee token.
    function transferFeeTokens(address _token) external view returns (bool) {
        return CoreStorage.layout().transferFeeTokens[_token];
    }

    function tokenConversionRoute(
        address _tokenIn,
        address _tokenOut
    ) external view returns (address[] memory) {
        return CoreStorage.layout().tokenConversionRoute[_tokenIn][_tokenOut];
    }

    /// @notice Router used for a specific swap route.
    /// @param _tokenIn Token input of the route.
    /// @param _tokenOut Token output of the route.
    /// @return Router used for the route.
    function tokenConversionRouter(
        address _tokenIn, 
        address _tokenOut
    ) external view returns (address) {
        return CoreStorage.layout().tokenConversionRouter[_tokenIn][_tokenOut];
    }

    /// @notice Routers used for a specific swap route.
    /// @param _tokenIn Token input of the route.
    /// @param _tokenOut Token output of the route.
    /// @return Routers used for the route.
    function tokenConversionRouters(
        address _tokenIn, 
        address _tokenOut
    ) external view returns (address[] memory) {
        return CoreStorage.layout().tokenConversionRouters[_tokenIn][_tokenOut];
    }

    /// @notice Determines whether or not the contract can be upgraded.
    /// @return Whether or not the contract can be upgraded / New implementation.
    function shouldUpgrade() external view override returns (bool,address) {
        return (yes, CoreStorage.layout().nextImplementation); // TODO: Implement
    }

    /// @notice Performs doHardWork on a desired vault.
    /// @param _vault Address of the vault to doHardWork on.
    function doHardWork(address _vault) public {
        uint256 prevSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        uint256 sharePriceAfter = IVault(_vault).getPricePerFullShare();
        emit SharePriceChangeLog(
            _vault,
            IVault(_vault).strategy(),
            prevSharePrice,
            sharePriceAfter,
            block.timestamp
        );
    }

    /// @notice Performs doHardWork on vaults in batches.
    /// @param _vaults Array of vaults to doHardWork on.
    function batchDoHardWork(address[] memory _vaults) public {
        for(uint256 i; i < _vaults.length;) {
            uint256 prevSharePrice = IVault(_vaults[i]).getPricePerFullShare();
            // We use the try/catch pattern to allow us to spot an issue in one of our vaults
            // while still being able to harvest the rest.
            try IVault(_vaults[i]).doHardWork() {
                uint256 sharePriceAfter = IVault(_vaults[i]).getPricePerFullShare();
                emit SharePriceChangeLog(
                    _vaults[i],
                    IVault(_vaults[i]).strategy(),
                    prevSharePrice,
                    sharePriceAfter,
                    block.timestamp
                );
            } catch {
                // Log failure.
                emit FailedHarvest(_vaults[i]);
            }
            unchecked { ++i; }
        }
    }

    /// @notice Silently performs a doHardWork (does not emit any events).
    function silentDoHardWork(address _vault) public {
        IVault(_vault).doHardWork();
    }

    /// @notice Adds a contract to the whitelist.
    /// @param _whitelistedAddress Address of the contract to whitelist.
    function addToWhitelist(address _whitelistedAddress) public onlyGovernance {
        CoreStorage.layout().whitelist[_whitelistedAddress] = yes;
    }

    /// @notice Removes a contract from the whitelist.
    /// @param _whitelistedAddress Address of the contract to remove.
    function removeFromWhitelist(address _whitelistedAddress) public onlyGovernance {
        CoreStorage.layout().whitelist[_whitelistedAddress] = no;
    }

    /// @notice Exempts an address from deposit maturity and exit fees.
    /// @param _feeExemptedAddress Address to exempt from fees.
    function addFeeExemptAddress(address _feeExemptedAddress) public onlyGovernance {
        CoreStorage.layout().feeExemptAddresses[_feeExemptedAddress] = yes;
    }

    /// @notice Removes an address from fee exemption
    /// @param _feeExemptedAddress Address to remove from fee exemption.
    function removeFeeExemptAddress(address _feeExemptedAddress) public onlyGovernance {
        CoreStorage.layout().feeExemptAddresses[_feeExemptedAddress] = no;
    }

    /// @notice Adds a list of addresses to the whitelist.
    /// @param _toWhitelist Addresses to whitelist.
    function batchWhitelist(address[] memory _toWhitelist) public onlyGovernance {
        for(uint256 i; i < _toWhitelist.length;) {
            CoreStorage.layout().whitelist[_toWhitelist[i]] = yes;
            unchecked { ++i; }
        }
    }

    /// @notice Exempts a list of addresses from Beluga exit penalties.
    /// @param _toExempt Addresses to exempt.
    function batchExempt(address[] memory _toExempt) public onlyGovernance {
        for(uint256 i; i < _toExempt.length;) {
            CoreStorage.layout().feeExemptAddresses[_toExempt[i]] = yes;
            unchecked { ++i; }
        }
    }

    /// @notice Adds an address to the legacy whitelist mechanism.
    /// @param _greyListedAddress Address to whitelist.
    function addToGreyList(address _greyListedAddress) public onlyGovernance {
        CoreStorage.layout().greyList[_greyListedAddress] = yes;
    }

    /// @notice Removes an address from the legacy whitelist mechanism.
    /// @param _greyListedAddress Address to remove from whitelist.
    function removeFromGreyList(address _greyListedAddress) public onlyGovernance {
        CoreStorage.layout().greyList[_greyListedAddress] = no;
    }

    /// @notice Sets the numerator for protocol performance fees.
    /// @param _profitSharingNumerator New numerator for fees.
    function setProfitSharingNumerator(uint256 _profitSharingNumerator) public onlyGovernance {
        CoreStorage.layout().profitSharingNumerator  = _profitSharingNumerator;
    }

    /// @notice Sets the percentage of fees that are to be used for gas rebates.
    /// @param _rebateNumerator Percentage to use for buybacks.
    function setRebateNumerator(uint256 _rebateNumerator) public onlyGovernance {
        require(_rebateNumerator <= NUMERATOR, "FeeRewardForwarder: New numerator is higher than the denominator");
        CoreStorage.layout().rebateNumerator = _rebateNumerator;
    }

    /// @notice Sets the address of the reserve token.
    /// @param _reserveToken Reserve token for the protocol to collect.
    function setReserveToken(address _reserveToken) public onlyGovernance {
        CoreStorage.layout().reserveToken = _reserveToken;
    }

    /// @notice Adds a token to the list of transfer fee tokens.
    /// @param _transferFeeToken Token to add to the list.
    function addTransferFeeToken(address _transferFeeToken) public onlyGovernance {
        CoreStorage.layout().transferFeeTokens[_transferFeeToken] = yes;
    }

    /// @notice Removes a token from the transfer fee tokens list.
    /// @param _transferFeeToken Address of the transfer fee token.
    function removeTransferFeeToken(address _transferFeeToken) public onlyGovernance {
        CoreStorage.layout().transferFeeTokens[_transferFeeToken] = no;
    }

    /// @notice Adds a keeper to the contract.
    /// @param _keeper Keeper to add to the contract.
    function addKeeper(address _keeper) public onlyGovernance {
        CoreStorage.layout().keepers[_keeper] = yes;
    }

    /// @notice Removes a keeper from the contract.
    /// @param _keeper Keeper to remove from the contract.
    function removeKeeper(address _keeper) public onlyGovernance {
        CoreStorage.layout().keepers[_keeper] = no;
    }

    /// @notice Sets the route for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _route Route used for conversion.
    function setTokenConversionRoute(
        address _tokenFrom,
        address _tokenTo,
        address[] memory _route
    ) public onlyGovernance {
        CoreStorage.layout().tokenConversionRoute[_tokenFrom][_tokenTo] = _route;
    }

    /// @notice Sets the router for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _router Target router for the swap.
    function setTokenConversionRouter(
        address _tokenFrom,
        address _tokenTo,
        address _router
    ) public onlyGovernance {
        CoreStorage.layout().tokenConversionRouter[_tokenFrom][_tokenTo] = _router;
    }

    /// @notice Sets the routers used for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _routers Target routers for the swap.
    function setTokenConversionRouters(
        address _tokenFrom,
        address _tokenTo,
        address[] memory _routers
    ) public onlyGovernance {
        CoreStorage.layout().tokenConversionRouters[_tokenFrom][_tokenTo] = _routers;
    }

    /// @notice Sets the pending governance address.
    /// @param _governance New governance address.
    function setGovernance(address _governance) public onlyGovernance {
        CoreStorage.layout().pendingGovernance = _governance;
    }

    /// @notice Transfers governance from the current to the pending.
    function acceptGovernance() public onlyGovernance {
        address prevGovernance = CoreStorage.layout().governance;
        address newGovernance = CoreStorage.layout().pendingGovernance;
        require(msg.sender == newGovernance);
        CoreStorage.layout().governance = newGovernance;
        CoreStorage.layout().pendingGovernance = address(0);
        emit GovernanceTransferred(prevGovernance, newGovernance);
    }

    function _performSwap(
        IUniswapV2Router02 _router,
        IERC20 _tokenFrom,
        uint256 _amount,
        address[] memory _route
    ) internal returns (uint256 endAmount) {
        _tokenFrom.safeApprove(address(_router), 0);
        _tokenFrom.safeApprove(address(_router), _amount);
        if(!CoreStorage.layout().transferFeeTokens[address(_tokenFrom)]) {
            uint256[] memory amounts = _router.swapExactTokensForTokens(_amount, 0, _route, address(this), (block.timestamp + 600));
            endAmount = amounts[amounts.length - 1];
        } else {
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 0, _route, address(this), (block.timestamp + 600));
            endAmount = IERC20(_route[_route.length - 1]).balanceOf(address(this));
        }
    }

    function _performMultidexSwap(
        address[] memory _routers,
        address _tokenFrom,
        uint256 _amount,
        address[] memory _route
    ) internal returns (uint256 endAmount) {
        for(uint256 i; i < _routers.length;) {
            // Create swap route.
            address swapRouter = _routers[i];
            address[] memory conversionRoute = new address[](2);
            conversionRoute[0] = _route[i];
            conversionRoute[1] = _route[i+1];

            // Fetch balances.
            address routeStart = conversionRoute[0];
            uint256 routeStartBalance;
            if(routeStart == _tokenFrom) {
                routeStartBalance = _amount;
            } else {
                routeStartBalance = IERC20(routeStart).balanceOf(address(this));
            }
            
            // Perform swap.
            if(conversionRoute[1] != _route[_route.length - 1]) {
                _performSwap(IUniswapV2Router02(swapRouter), IERC20(routeStart), routeStartBalance, conversionRoute);
            } else {
                endAmount = _performSwap(IUniswapV2Router02(swapRouter), IERC20(routeStart), routeStartBalance, conversionRoute);
            }

            unchecked { ++i; }
        }
    }

    function _create(bytes memory _bytecode) internal returns (address deployed) {
        assembly {
            deployed := create(0, add(_bytecode, 0x20), mload(_bytecode))
        }
    }
}