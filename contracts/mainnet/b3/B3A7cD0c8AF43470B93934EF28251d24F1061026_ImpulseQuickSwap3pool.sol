/**
 *Submitted for verification at polygonscan.com on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// File: Address.sol

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: IERC165Upgradeable.sol

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// File: IERC20.sol

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

// File: IStakingRewards.sol

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// File: IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// File: IdQuick.sol

interface IdQuick {
    function enter(uint256 _quickAmount) external;
    function leave(uint256 _dQuickAmount) external;
}

// File: Initializable.sol

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// File: StringsUpgradeable.sol

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// File: ContextUpgradeable.sol

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: ERC165Upgradeable.sol

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// File: ReentrancyGuardUpgradeable.sol

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// File: SafeERC20.sol

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// File: AccessControlUpgradeable.sol

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// File: ImpulseQuickSwap3pool.sol

contract ImpulseQuickSwap3pool is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    uint256 internal constant DUST = 1e12;
    uint256 internal constant SIX_DECIMAL_DUST = 1e3;

    ///@notice Total number of staked lp tokens.
    uint256 public wantTotal;
    ///@notice Total number of staked lp tokens (amount for each).
    uint256[] public wantTotalForEach;
    ///@notice Total number of staked lp tokens without reward.
    uint256 internal totalSupplyShares;
    ///@notice Slippage tolerance precentage.
    uint256 public slippagePercent;
    ///@notice Array of underlyings for which LP tokens will be bought.
    IERC20[] public underlyings;
    ///@notice Array of want(LP) tokens.
    IERC20[] public wantTokens;
    ///@notice Array of pools for lp tokens stake.
    address[] public pools;
    ///@notice Reward token of QuickSwap pools.
    IERC20 public rewardToken;
    ///@notice Quick token, which is collected during earn.
    IERC20 public quickToken;
    /// @notice Swap router address.
    address public router;

    // fromToken => toToken => path
    mapping(address => mapping(address => address[])) public swapUnderlyingRoutes;

    // fromToken => toToken => path
    mapping(address => mapping(address => address[])) public swapRewardRoutes;

    event Deposit(uint256[] amounts, uint256 shares, uint256 wantTotal, uint256 sharesTotal);
    event Withdraw(uint256 amount, uint256 shares, uint256 wantTotal, uint256 sharesTotal);
    event Earning(uint256[] earned, uint256 wantTotal, uint256 sharesTotal);
    event AdminWithdraw(address token, uint256 amount);

    function initialize(
        address[] memory _underlyings,
        address[] memory _wantTokens,
        address[] memory _pools,
        address _rewardToken,
        address _router
    ) public virtual initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ReentrancyGuard_init();

        underlyings = new IERC20[](_underlyings.length);
        for (uint256 i = 0; i < _underlyings.length; i++) {
            underlyings[i] = IERC20(_underlyings[i]);
        }
        wantTokens = new IERC20[](_wantTokens.length);
        for (uint256 i = 0; i < _wantTokens.length; i++) {
            wantTokens[i] = IERC20(_wantTokens[i]);
        }
        pools = new address[](_pools.length);
        for (uint256 i = 0; i < _pools.length; i++) {
            pools[i] = address(_pools[i]);
        }

        rewardToken = IERC20(_rewardToken);
        quickToken = IERC20(address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13));
        router = _router;
        wantTotalForEach = new uint256[](wantTokens.length);
        slippagePercent = 5e16; // 5% initially
    }

    /**
     * ADMIN INTERFACE
     */

    /// @notice Admin method for withdraw stuck tokens, except want.
    function adminWithdraw(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < wantTokens.length; i++) {
            require(_token != address(wantTokens[i]), "Wrong token");
        }
        for (uint256 i = 0; i < underlyings.length; i++) {
            require(_token != address(underlyings[i]), "Wrong token");
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).transfer(_msgSender(), balance);
        }
        emit AdminWithdraw(_token, balance);
    }

    /// @notice Sets router address.
    /// @dev Can only be called by admin.
    /// @param _router Address of swap router.
    function setRouter(address _router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        router = _router;
    }

    function setSlippage(uint256 _newSlippagePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        slippagePercent = _newSlippagePercent;
    }

    /// @notice Add route for swapping reward tokens.
    /// @param _path Full path for swap.
    function setRewardRoutes(address[] memory _path) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_path.length >= 2, "wrong path");
        address from = _path[0];
        address to = _path[_path.length - 1];
        swapRewardRoutes[from][to] = _path;
    }

    /// @notice Add route for swapping usd to underlying.
    /// @param _path Full path for swap.
    function setUnderlyingRoutes(address[] memory _path) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_path.length >= 2, "wrong path");
        address from = _path[0];
        address to = _path[_path.length - 1];
        swapUnderlyingRoutes[from][to] = _path;
    }

    /**
     * USER INTERFACE (FOR STAKING CONTRACT)
     */

    /// @notice Deposit want (lp) tokens through underlyings.
    /// @param _amounts Amounts in underlying to stake.
    function depositInUnderlying(uint256[] calldata _amounts) external nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256) {
        require(_amounts.length == underlyings.length, "deposit: wrong amounts");
        for (uint256 i = 0; i < underlyings.length; i++) {
            if (_amounts[i] != 0) {
                IERC20(underlyings[i]).safeTransferFrom(_msgSender(), address(this), _amounts[i]);
            }
        }

        uint256 shares = _deposit(_swapAllUnderlyingsToWant(_rebalanceAmounts(_amounts)));

        // The rest of the tokens after first deposit are deposited again
        // Because after rebalancing and adding liquidity some underlyings
        // still stay on contract
        uint256[] memory amountsRemainder = new uint256[](underlyings.length);
        bool isEnough;
        for (uint256 i = 0; i < underlyings.length; i++) {
            amountsRemainder[i] = underlyings[i].balanceOf(address(this));
            // Ensure, that enough tokens amounts (not dusting values)
            // left after the first deposit
            if (!isEnough) {
                if (i < 2 && amountsRemainder[i] > SIX_DECIMAL_DUST) isEnough = true;
                else if (amountsRemainder[i] > DUST) isEnough = true;
            }
        }

        if (isEnough) shares += _deposit(_swapAllUnderlyingsToWant(_rebalanceAmounts(amountsRemainder)));

        return shares;
    }

    /// @notice Withdraw lp tokens in one of underlyings.
    /// @param _wantAmount Amount of lp token to withdraw.
    /// @param _underlying Token to withdraw in.
    function withdrawInOneUnderlying(uint256 _wantAmount, address _underlying)
        external
        nonReentrant
        onlyRole(STRATEGIST_ROLE)
        returns (uint256)
    {
        require(_wantAmount <= wantTotal && _wantAmount > 0, "Withdraw: wrong value");
        require(_validateToken(_underlying), "Wrong underlying provided!");

        uint256 shares = (_wantAmount * totalSupplyShares) / wantTotal;
        uint256[] memory withdrawAmount = new uint256[](wantTokens.length);

        for (uint256 i; i < wantTokens.length; i++) {
            withdrawAmount[i] = (shares * wantTotalForEach[i]) / totalSupplyShares;
        }

        // Withdraw tokens from staking contracts
        _withdraw(withdrawAmount, address(this));

        for (uint256 i; i < wantTokens.length; i++) {
            wantTotalForEach[i] -= withdrawAmount[i];
        }
        wantTotal -= _wantAmount;
        totalSupplyShares -= shares;

        //Swap all getted want tokens to one underlying
        _swapAllWantToOneUnderlying(_underlying, _msgSender());

        emit Withdraw(0, shares, wantTotal, totalSupplyShares);
        return shares;
    }

    ///@dev Total want tokens managed by strategy.
    function wantLockedTotal() external view returns (uint256) {
        return wantTotal;
    }

    ///@dev Total want tokens managed by strategy.
    function wantLockedTotalForEach() external view returns (uint256[] memory) {
        return wantTotalForEach;
    }

    ///@dev Sum of all users shares to wantLockedTotal.
    function sharesTotal() external view returns (uint256) {
        return totalSupplyShares;
    }

    ///@dev List underlyings managed by strategy.
    function listUnderlying() external view returns (address[] memory) {
        address[] memory result = new address[](underlyings.length);
        for (uint256 u = 0; u < underlyings.length; u++) {
            result[u] = address(underlyings[u]);
        }
        return result;
    }

    /// @notice Calculate current price in usd for want (LP tokens of pair).
    /// @param _wantAmounts Shares amounts.
    /// @return wantPrices Price of shares in usd (with 18 decimals).
    function wantPriceInUsd(uint256[] memory _wantAmounts) external view returns (uint256) {
        uint256[] memory wantPrices = new uint256[](wantTokens.length);
        uint256 wantPrice;

        //Here we get the prices for one lp token
        //USDT-MAI price
        wantPrices[0] =
            ((underlyings[1].balanceOf(address(wantTokens[0]))) + underlyings[3].balanceOf(address(wantTokens[0]))) /
            wantTokens[0].totalSupply();

        //USDC-DAI price
        wantPrices[1] =
            ((underlyings[0].balanceOf(address(wantTokens[1]))) + underlyings[2].balanceOf(address(wantTokens[1]))) /
            wantTokens[1].totalSupply();

        //USDC-USDT price
        wantPrices[2] =
            ((underlyings[0].balanceOf(address(wantTokens[2]))) + underlyings[1].balanceOf(address(wantTokens[2]))) /
            wantTokens[2].totalSupply();

        // And here for requested lp tokens amounts
        for (uint256 i = 0; i < wantPrices.length; i++) {
            wantPrices[i] *= _wantAmounts[i];
            wantPrice += wantPrices[i];
        }
        return wantPrice;
    }

    ///@dev Unsupported in this strategy.
    ///@dev Is unnecessary due because will return prices in dollars (due to the features of underlying tokens and want tokens).
    ///@dev But it is here for compatibility with other strategies (contracts).
    ///@dev Return empty array.
    function wantPriceInUnderlying(uint256 _wantAmt) external view returns (uint256[] memory wantPricesInUnderlying) {
        wantPricesInUnderlying = new uint256[](underlyings.length);
        return wantPricesInUnderlying;
    }

    /**
     * BACKEND SERVICE INTERFACE
     */

    ///@notice Main want token compound function.
    function earn() external nonReentrant onlyRole(BACKEND_ROLE) {
        //Get rewards from staking contracts
        _getRewards();
        uint256 rewardBalance;

        //Continue compound only if reward balances are bigger than dust
        bool enough = false;
        rewardBalance = rewardToken.balanceOf(address(this));
        if (rewardBalance > DUST) {
            enough = true;
        }

        if (!enough) {
            return;
        }

        // Exchange DQuick into Quick
        IdQuick(address(rewardToken)).leave(rewardBalance);
        rewardBalance = quickToken.balanceOf((address(this)));

        //Swap Quick rewards to one token (now usdc)
        _swapRewardsToUnderlyings(rewardBalance);

        uint256[] memory underlyingsBalances = new uint256[](underlyings.length);
        for (uint256 i = 0; i < underlyings.length; i++) {
            underlyingsBalances[i] = underlyings[i].balanceOf(address(this));
        }
        uint256[] memory wantEarned = new uint256[](wantTokens.length);
        uint256[] memory rebalanceUnderlyingBalances = new uint256[](underlyings.length);

        //We get rebalanced amounts from amounts received after rewards swap
        rebalanceUnderlyingBalances = _rebalanceAmounts(underlyingsBalances);

        //Swap rebalanced underlyings to want tokens
        wantEarned = _swapAllUnderlyingsToWant(rebalanceUnderlyingBalances);

        //Deposit want tokens
        _depositLpToken(wantEarned);

        for (uint256 i = 0; i < wantTokens.length; i++) {
            wantTotal += wantEarned[i];
            wantTotalForEach[i] += wantEarned[i];
        }
        emit Earning(wantEarned, wantTotal, totalSupplyShares);
    }

    /// @notice Deposit want tokens to staking contract and calculate shares.
    /// @param _wantAmounts Amounts in want (lp tokens) to stake.
    /// @return Amount of shares.
    function _deposit(uint256[] memory _wantAmounts) internal returns (uint256) {
        uint256 shares = 0;
        uint256 wantToAdd = 0;
        _depositLpToken(_wantAmounts);
        for (uint256 i = 0; i < wantTokens.length; i++) {
            if (totalSupplyShares == 0) {
                shares += _wantAmounts[i];
            } else {
                shares += (_wantAmounts[i] * totalSupplyShares) / wantTotal;
            }
            wantToAdd += _wantAmounts[i];
            wantTotalForEach[i] += _wantAmounts[i];
        }
        wantTotal += wantToAdd;
        totalSupplyShares += shares;

        emit Deposit(_wantAmounts, shares, wantTotal, totalSupplyShares);
        return shares;
    }

    /// @notice Withdraw lp tokens from staking contract.
    /// @dev Has additional checks before withdraw.
    function _withdraw(uint256[] memory _wantAmounts, address _receiver) internal {
        for (uint256 i = 0; i < wantTokens.length; i++) {
            require(_wantAmounts[i] <= wantTotalForEach[i] && _wantAmounts[i] > 0, "Withdraw: wrong value");
        }
        require(_receiver != address(0), "Withdraw: receiver is zero address");

        _withdrawLpToken(_wantAmounts);
    }

    /// @notice Deposit want tokens to staking contract.
    /// @param _wantAmounts Amounts of want tokens.
    function _depositLpToken(uint256[] memory _wantAmounts) internal {
        for (uint256 i = 0; i < wantTokens.length; i++) {
            IERC20(wantTokens[i]).approve(pools[i], 0);
            IERC20(wantTokens[i]).approve(pools[i], _wantAmounts[i]);
            IStakingRewards(pools[i]).stake(_wantAmounts[i]);
        }
    }

    /// @notice Withdraw want tokens from staking contract.
    /// @param _wantAmt Amounts of want tokens.
    function _withdrawLpToken(uint256[] memory _wantAmt) internal {
        for (uint256 i = 0; i < wantTokens.length; i++) {
            IStakingRewards(pools[i]).withdraw(_wantAmt[i]);
        }
    }

    /// @notice Get rewards from staking contracts.
    function _getRewards() internal {
        for (uint256 i = 0; i < pools.length; i++) {
            IStakingRewards(pools[i]).getReward();
        }
    }

    ///@notice Check token presence in underlyings.
    function _validateToken(address _underlying) internal view returns (bool) {
        for (uint256 i = 0; i < underlyings.length; i++) {
            if (_underlying == address(underlyings[i])) {
                return true;
            }
        }
        return false;
    }

    /**
     * REBALANCE HELPERS
     */
    /**
     * Formula for calculating amounts needed for a balanced deposit in three pools.
     * On the example where the USDC token is USD token.
     * USDC - C, USDT - T, DAI - D, MAI - M, a - amount, x - target amount.
     * DC, TC, MC - token to USDC (usd token) rate.
     * totalC = Ca + Ta*TC + Da*DC + Ma*MC
     * x = totalC/(2 + 2TC + DC + MC)
     * 2 for USDC and USDT since they participate in pools 2 times.
     */

    /// @notice Rebalance underlyings amounts to get equal parts.
    /// @param _amounts Amounts in underlyings to rebalance.
    /// @return rebalanceAmounts Rebalanced by function amounts.
    function _rebalanceAmounts(uint256[] memory _amounts) internal returns (uint256[] memory rebalanceAmounts) {
        uint256 biggestAmount;
        uint256 index;

        //Give a copy of amounts to 18 decimals
        uint256[] memory amounts = new uint256[](_amounts.length);
        for (uint256 i = 0; i < _amounts.length; i++) {
            amounts[i] = _amounts[i];
            if (i < 2) {
                amounts[i] *= 10**12;
            }
        }

        //Get biggest amount from user _amounts
        for (uint256 i = 0; i < underlyings.length; i++) {
            if (amounts[i] > biggestAmount) {
                biggestAmount = amounts[i];
                index = i;
            }
        }

        //Set usd token according to largest underlying amount for more optimized swap.
        address usdToken = address(underlyings[index]);

        (uint256[] memory excessAmounts, uint256[] memory missingAmounts) = _getExcessAndMissingAmounts(usdToken, _amounts, index);

        //All excess amounts swap to usd token.
        _swapUnderlyingsToUSDToken(excessAmounts, usdToken);
        //Missing amounts buy for usd token.
        _swapUSDTokenToUnderlyings(missingAmounts, usdToken);

        rebalanceAmounts = new uint256[](underlyings.length);
        for (uint256 i = 0; i < underlyings.length; i++) {
            rebalanceAmounts[i] = underlyings[i].balanceOf(address(this));
        }
    }

    ///@notice Get by how much to multiply the amount of tokens to get amount in wei.
    ///@dev For usdc and usdt tokens it's 10**12.
    ///@dev For mai and dai tokens it's 10**18.
    function _getTokenDecimalsMultiplier(uint256 _underlyingIndex) internal pure returns (uint256) {
        if (_underlyingIndex == 0 || _underlyingIndex == 1) {
            return 10**12;
        } else {
            return 1;
        }
    }

    ///@notice Get token decimals.
    ///@dev For usdc and usdt tokens it's 10**6.
    ///@dev For mai and dai tokens it's 10**18.
    function _getTokenDecimals(uint256 _underlyingIndex) internal pure returns (uint256) {
        if (_underlyingIndex == 0 || _underlyingIndex == 1) {
            return 1 * 10**6;
        } else {
            return 1 ether;
        }
    }

    ///@dev For usdt and usdc pool multiplier is 2 because they participate in pools 2 times.
    function _getTokenPoolMultiplier(uint256 _underlyingIndex) internal pure returns (uint256) {
        if (_underlyingIndex == 0 || _underlyingIndex == 1) {
            return 2;
        } else {
            return 1;
        }
    }

    ///@notice Calculate total amount of underlyings.
    ///@return underlyingsTotal Amount of underlyings calculated in usd token.
    function _calculateUnderlyingsTotal(
        uint256[] memory _amounts,
        address _usdToken,
        uint256 _usdIndex
    ) internal view returns (uint256 underlyingsTotal) {
        for (uint256 i = 0; i < _amounts.length; i++) {
            if (i == _usdIndex) {
                underlyingsTotal += _amounts[i] * _getTokenDecimalsMultiplier(_usdIndex);
            } else {
                underlyingsTotal += _getTokenPriceInUsd(i, _amounts[i], _usdToken);
            }
        }
    }

    ///@dev In a simple case, we would divide the underlyingsTotal amount by 6, since we have 6 amounts to buy LP tokens,
    ///@dev but due to the difference in prices, we get the rate of 1 token to one usd token, sum up,
    ///@dev and get a proportionally calculated divider.
    ///@return rebalanceDivider Proportionally calculated divider.
    function _calculateRebalanceDivider(address _usdToken, uint256 _usdIndex) internal view returns (uint256 rebalanceDivider) {
        for (uint256 i = 0; i < underlyings.length; i++) {
            if (_usdIndex == i) {
                rebalanceDivider += 1 ether * _getTokenPoolMultiplier(i);
            } else {
                rebalanceDivider += _getTokenPriceInUsd(i, _getTokenDecimals(i) * _getTokenPoolMultiplier(i), _usdToken);
            }
        }
    }

    ///@notice Get excess and missing amounts of underlyings for swap.
    ///@dev We don't calculate these amounts for usd token, its amount is rebalanced after calculations.
    function _getExcessAndMissingAmounts(
        address _usdToken,
        uint256[] memory _amounts,
        uint256 usdIndex
    ) internal view returns (uint256[] memory excessAmounts, uint256[] memory missingAmounts) {
        excessAmounts = new uint256[](underlyings.length);
        missingAmounts = new uint256[](underlyings.length);

        uint256 underlyingsTotal = _calculateUnderlyingsTotal(_amounts, _usdToken, usdIndex);
        uint256 tokensRebalanceAmount = (underlyingsTotal * (1 ether)) / _calculateRebalanceDivider(_usdToken, usdIndex);

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (i == usdIndex) continue;

            uint256 tokenDecimalsMultiplier = _getTokenDecimalsMultiplier(i);
            uint256 targetAmount = (tokensRebalanceAmount * _getTokenPoolMultiplier(i)) / tokenDecimalsMultiplier;
            if (targetAmount <= _amounts[i]) {
                excessAmounts[i] = _amounts[i] - targetAmount;
            } else {
                missingAmounts[i] = targetAmount - _amounts[i];
            }
        }
    }

    ///@notice Get token to usd token swap rate.
    function _getTokenPriceInUsd(
        uint256 _tokenIndex,
        uint256 _tokenAmount,
        address _usdToken
    ) internal view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }
        address[] memory path = swapUnderlyingRoutes[address(underlyings[_tokenIndex])][_usdToken];
        uint256 priceTokenInUSD = IUniswapV2Router01(router).getAmountsOut(_tokenAmount, path)[path.length - 1];

        if (_usdToken == address(underlyings[0]) || _usdToken == address(underlyings[1])) {
            priceTokenInUSD *= 10**12; // Since USDC and USDT has 6 decimals
        }
        return priceTokenInUSD;
    }

    /**
     * SWAP HELPERS
     */

    /// @notice Swap all want tokens to one underlying.
    function _swapAllWantToOneUnderlying(address _underlying, address _receiver) internal {
        uint256[] memory wantBalances = new uint256[](wantTokens.length);
        for (uint256 i = 0; i < wantTokens.length; i++) {
            wantBalances[i] += wantTokens[i].balanceOf(address(this));
            wantTokens[i].safeApprove(router, wantBalances[i]);
        }

        //Remove liquidity for USDT-MAI want token (get usdt and mai)
        IUniswapV2Router01(router).removeLiquidity(
            address(underlyings[1]),
            address(underlyings[3]),
            wantBalances[0],
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        //Remove liquidity for USDC-DAI want token (get usdc and dai)
        IUniswapV2Router01(router).removeLiquidity(
            address(underlyings[0]),
            address(underlyings[2]),
            wantBalances[1],
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        //Remove liquidity for USDC-USDT want token (get usdc and usdt)
        IUniswapV2Router01(router).removeLiquidity(
            address(underlyings[0]),
            address(underlyings[1]),
            wantBalances[2],
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        uint256[] memory underlyingsBalances = new uint256[](underlyings.length);
        for (uint256 i = 0; i < underlyings.length; i++) {
            underlyings[i].safeApprove(router, 0);
            underlyingsBalances[i] = underlyings[i].balanceOf(address(this));
            underlyings[i].safeApprove(router, underlyingsBalances[i]);
        }

        //Swap getted underlyings to one underlying defined by user
        for (uint256 i = 0; i < underlyings.length; i++) {
            if (address(underlyings[i]) == _underlying) continue;

            // Calculate slippage tolerance. We can tolerate 2% slippage top. All underlyings are stables with rate approximately 1:1.
            uint256 slippageTolerance = underlyingsBalances[i] - (underlyingsBalances[i] * slippagePercent / 1e18);
            if ((i < 2) && (_underlying == address(underlyings[2]) || _underlying == address(underlyings[3]))) // Add 12 decimals if source has 6 and destination has 18
                slippageTolerance *= 10**12;
            else if ((i >= 2) && (_underlying == address(underlyings[0]) || _underlying == address(underlyings[1]))) // Sub 12 decimals if source has 18 and destination has 6
                slippageTolerance /= 10**12;

            _swapTokens(swapUnderlyingRoutes[address(underlyings[i])][_underlying], underlyingsBalances[i], slippageTolerance);
        }

        //Transfer underlying to user
        IERC20(_underlying).safeTransfer(_receiver, IERC20(_underlying).balanceOf(address(this)));
    }

    function _swapTokens(address[] memory path, uint256 _amount, uint256 slippageTolerance) internal { 
        IUniswapV2Router01(router).swapExactTokensForTokens(_amount, slippageTolerance, path, address(this), block.timestamp + 1);
    }

    function _swapTokensForExact(address[] memory path, uint256 _amount, uint256 slippageTolerance) internal {
        IUniswapV2Router01(router).swapTokensForExactTokens(_amount, slippageTolerance, path, address(this), block.timestamp + 1);
    }

    /// @notice Swap reward tokens to underlyings.
    /// @param _rewardAmount Quick reward amount.
    function _swapRewardsToUnderlyings(uint256 _rewardAmount) internal {
            if (_rewardAmount > DUST) {
                quickToken.safeApprove(router, 0);
                quickToken.safeApprove(router, _rewardAmount);
                _swapTokens(swapRewardRoutes[address(quickToken)][address(underlyings[0])], _rewardAmount, 0);
            }
    }

    /// @notice Swap excess amounts of underlying tokens to one usd token.
    function _swapUnderlyingsToUSDToken(uint256[] memory _excessAmounts, address usdToken) internal {
        for (uint256 i = 0; i < _excessAmounts.length; i++) {
            underlyings[i].safeApprove(router, 0);
            underlyings[i].safeApprove(router, _excessAmounts[i]);
        }
        for (uint256 u = 0; u < underlyings.length; u++) {
            if (_excessAmounts[u] == 0 || address(underlyings[u]) == usdToken) continue;

            // Calculate slippage tolerance. We can tolerate 2% slippage top. All underlyings are stables with rate approximately 1:1.
            uint256 slippageTolerance = _excessAmounts[u] - (_excessAmounts[u] * slippagePercent / 1e18);
            if ((u < 2) && (usdToken == address(underlyings[2]) || usdToken == address(underlyings[3]))) // Add 12 decimals if source has 6 and destination has 18
                slippageTolerance *= 10**12;
            else if ((u >= 2) && (usdToken == address(underlyings[0]) || usdToken == address(underlyings[1]))) // Sub 12 decimals if source has 18 and destination has 6
                slippageTolerance /= 10**12;

            _swapTokens(swapUnderlyingRoutes[address(underlyings[u])][usdToken], _excessAmounts[u], slippageTolerance);
        }
    }

    /// @notice Buy missing amounts of underlying tokens for one usd token.
    function _swapUSDTokenToUnderlyings(uint256[] memory _missingAmounts, address usdToken) internal {
        IERC20(usdToken).safeApprove(router, 0);
        IERC20(usdToken).safeApprove(router, (IERC20(usdToken).balanceOf(address(this))));
        for (uint256 u = 0; u < underlyings.length; u++) {
            if (_missingAmounts[u] == 0 || address(underlyings[u]) == usdToken) continue;

            // Calculate slippage tolerance. We can tolerate 2% slippage top. All underlyings are stables with rate approximately 1:1.
            uint256 slippageTolerance = _missingAmounts[u] + (_missingAmounts[u] * slippagePercent / 1e18);
            if ((usdToken == address(underlyings[0]) || usdToken == address(underlyings[1])) && (u >= 2)) // Sub 12 decimals if source has 6 and destination has 18
                slippageTolerance /= 10**12;
            else if ((usdToken == address(underlyings[2]) || usdToken == address(underlyings[3])) && (u < 2)) // Add 12 decimals if source has 18 and destination has 6
                slippageTolerance *= 10**12;

            _swapTokensForExact(swapUnderlyingRoutes[usdToken][address(underlyings[u])], _missingAmounts[u], slippageTolerance);
        }
    }

    /// @notice Swap all underlying tokens to want tokens.
    /// @return Want received amounts.
    function _swapAllUnderlyingsToWant(uint256[] memory _amounts) internal returns (uint256[] memory) {
        for (uint256 i = 0; i < underlyings.length; i++) {
            IERC20(underlyings[i]).safeApprove(router, 0);
            IERC20(underlyings[i]).safeApprove(router, _amounts[i]);
        }

        // These amounts of tokens is calculated for LP purchase in two pools
        uint256 usdcPart = _amounts[0] / 2; // so we divide it by two here
        uint256 usdtPart = _amounts[1] / 2;

        //Get USDC-USDT LP token
        IUniswapV2Router01(router).addLiquidity(
            address(underlyings[0]),
            address(underlyings[1]),
            usdcPart,
            usdtPart,
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        //Get USDC-DAI LP token
        IUniswapV2Router01(router).addLiquidity(
            address(underlyings[0]),
            address(underlyings[2]),
            usdcPart,
            _amounts[2],
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        //Get USDT-MAI LP token
        IUniswapV2Router01(router).addLiquidity(
            address(underlyings[1]),
            address(underlyings[3]),
            usdtPart,
            _amounts[3],
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        uint256[] memory wantBalances = new uint256[](wantTokens.length);
        for (uint256 i = 0; i < wantTokens.length; i++) {
            wantBalances[i] = wantTokens[i].balanceOf(address(this));
        }

        return wantBalances;
    }
}