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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/FractionalAmount.sol)

import "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {

    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    /// @notice Return the fractional amount as basis points (ie fractional amount at precision of 10k)
    function asBasisPoints(Data storage self) internal view returns (uint256) {
        return (self.numerator * BASIS_POINTS_DIVISOR) / self.denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev Overloaded version of the above, using calldata/pure to avoid a copy from storage in some scenarios
    function split(Data calldata self, uint256 inputAmount) internal pure returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/common/IMintableToken.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/common/IStaxTokenPrices.sol)

interface IStaxTokenPrices {
    function tokenPrice(address token) external view returns (int256 price);
    function tokenPrices(address[] memory tokens) external view returns (int256[] memory prices);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/gmx/IStaxGmxDepositor.sol)

import "../../../common/FractionalAmount.sol";

interface IStaxGmxDepositor {
    function rewardRates(bool forStakedGlpRewards) external view returns (uint256 wrappedNativeTokensPerSec, uint256 esGmxTokensPerSec);
    function harvestableRewards(bool forStakedGlpRewards) external view returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    );
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external returns (
        uint256 wrappedNativeClaimedFromGmx,
        uint256 wrappedNativeClaimedFromGlp,
        uint256 esGmxClaimedFromGmx,
        uint256 esGmxClaimedFromGlp,
        uint256 vestedGmxClaimed
    );
    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _maxAmount) external;
    function mintAndStakeGlp(
        uint256 fromAmount,
        address fromToken,
        uint256 minUsdg,
        uint256 minGlp,
        uint256 slippageBps
    ) external returns (uint256);
    function unstakeAndRedeemGlp(
        uint256 glpAmount, 
        address toToken, 
        uint256 minOut, 
        uint256 slippageBps,
        address receiver
    ) external returns (uint256);
    function transferStakedGlp(uint256 glpAmount, address receiver) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/gmx/IStaxGmxManager.sol)

import "../../staking/IStaxInvestmentManager.sol";
import "./IStaxGmxDepositor.sol";

interface IStaxGmxManager {
    function harvestableRewards(bool forStakedGlpRewards) external view returns (uint256[] memory amounts);
    function projectedRewardRates(bool forStakedGlpRewards) external view returns (uint256[] memory amounts);
    function harvestRewards() external;
    function rewardTokensList() external view returns (address[] memory tokens);
    function wrappedNativeToken() external view returns (address);
    function depositor() external view returns (IStaxGmxDepositor);
    function sellStxGmxQuote(uint256 _stxGmxAmount) external view returns (uint256 staxFeeBasisPoints, uint256 gmxAmountOut);
    function sellStxGmx(
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);
    function acceptedGlpTokens(address[] calldata extraTokens) external view returns (address[] memory);
    function buyStxGlpQuote(uint256 _amount, address _token) external view returns (uint256 stxGlpAmountOut, uint256[] memory investFeeBps, bytes memory otherQuoteParams);
    function sellStxGlpQuote(uint256 _stxGlpAmount, address _toToken) external view returns (uint256 toTokenAmount, uint256[] memory exitFeeBps, bytes memory otherQuoteParams);
    function sellStxGlp(
        uint256 _sellAmount,
        address _toToken,
        uint256 _minAmountOut,
        uint256 _slippageBps,
        address _recipient
    ) external returns (uint256 amountOut);
    function sellStxGlpToStakedGlp(
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/IStaxInvestment.sol)

import "../common/IMintableToken.sol";
import "../staking/IStaxStaking.sol";

/**
 * @title STAX Investment
 * @notice Users invest in the underlying protocol and receive an ERC20 receipt token in return.
 * This receipt token can be staked to earn protocol rewards, and surrendered to exit the investment.
 * STAX will apply the accepted investment token into the underlying protocol in the most optimal way.
 */
interface IStaxInvestment {
    /// @notice Emitted when a user makes a new investment
    event Invested(address indexed user, uint256 fromTokenAmount, address indexed fromToken, uint256 staxReceiptAmountOut, bool staked);

    /// @notice Emitted when a user exists a position in an investment
    event Exited(address indexed user, uint256 staxReceiptAmountIn, address indexed toToken, uint256 toTokenAmountOut, address indexed recipient);

    /// @notice Errors for unsupported functions - for example if native chain ETH/AVAX/etc isn't a vaild investment
    error Unsupported();

    /// @notice The STAX ERC20 receipt token, received upon investment.
    function staxReceiptToken() external view returns (IMintableToken);

    /// @notice The contract used to stake the staxReceiptToken
    function staxStaking() external view returns (IStaxStaking);

    /**
     * @notice The set of accepted tokens which can be used to invest.
     * If the native chain ETH/AVAX is accepted, 0x0 will also be included in this list.
     */
    function acceptedTokens() external view returns (address[] memory);

    /**
     * @notice Get a quote to buy the STAX ERC20 receipt token using one of the approved tokens. 
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param fromTokenAmount How much of `fromToken` to invest with
     * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedTokens`
     * @return staxReceiptAmountOut The number of receipt tokens to expect, inclusive of any fees.
     * @return investFeeBps Any fees expected when investing with the given token, either from STAX or from the underlying investment.
     * @return otherQuoteParams Other quote params for this investment, required to be passed through when executing the quote.
     */
    function investWithTokenQuote(
        uint256 fromTokenAmount, address fromToken
    ) external view returns (uint256 staxReceiptAmountOut, uint256[] memory investFeeBps, bytes memory otherQuoteParams);

    /** 
      * @notice User buys STAX ERC20 receipt tokens with an amount of one of the approved ERC20 tokens. 
      * @param fromTokenAmount How much of `fromToken` to invest with
      * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedTokens`
      * @param stake If true, immediately stake the resulting STAX receipt token
      * @param expectedStaxReceiptAmount The quoted amount of STAX receipt tokens to expect - do not apply slippage to this.
      * @param otherQuoteParams Other quote params required by the investment
      * @param slippageBps Acceptable slippage, applied to both the `expectedStaxReceiptAmount` and `otherQuoteParams`
      * @return staxReceiptAmountOut The actual number of receipt tokens received, inclusive of any fees.
      */
    function investWithToken(
        uint256 fromTokenAmount, address fromToken, bool stake, uint256 expectedStaxReceiptAmount, bytes calldata otherQuoteParams, uint256 slippageBps
    ) external returns (uint256 staxReceiptAmountOut);

    /** 
      * @notice User buys STAX ERC20 receipt tokens with an amount of native chain token (ETH/AVAX)
      * @param stake If true, immediately stake the resulting STAX receipt token
      * @param expectedStaxReceiptAmount The quoted amount of STAX receipt tokens to expect - do not apply slippage to this.
      * @param otherQuoteParams Other quote params required by the investment
      * @param slippageBps Acceptable slippage, applied to both the `expectedStaxReceiptAmount` and `otherQuoteParams`
      * @return staxReceiptAmountOut The number of receipt tokens to expect, inclusive of any fees.
      */
    function investWithNative(
        bool stake, uint256 expectedStaxReceiptAmount, bytes calldata otherQuoteParams, uint256 slippageBps
    ) external payable returns (uint256 staxReceiptAmountOut);

    /**
     * @notice Get a quote to sell STAX ERC20 receipt tokens to receive one of the accepted tokens.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param staxReceiptAmount The amount of STAX ERC20 receipt tokens to sell
     * @param toToken The token to receive when selling
     * @return toTokenAmountOut The number of `toToken` tokens to expect, inclusive of any fees.
     * @return exitFeeBps Any fees expected when exiting the investment to the nominated token, either from STAX or from the underlying investment.
     * @return otherQuoteParams Other quote params for this investment, required to be passed through when executing the quote.
     */
    function exitToTokenQuote(
        uint256 staxReceiptAmount, address toToken
    ) external view returns (uint256 toTokenAmountOut, uint256[] memory exitFeeBps, bytes memory otherQuoteParams);

    /** 
      * @notice Sell STAX ERC20 receipt tokens to receive one of the accepted tokens. 
      * @param staxReceiptAmount The amount of STAX ERC20 receipt tokens to sell
      * @param toToken The token to receive when selling
      * @param expectedToTokenAmount The quoted amount of `toToken` to expect, inclusive of any fees - do not apply slippage to this.
      * @param otherQuoteParams Other quote params required by the investment, required to be passed through when executing the quote.
      * @param slippageBps Acceptable slippage, which is applied to both the `expectedToTokenAmount` and `otherQuoteParams`
      * @param recipient The receiving address of the `toToken`
      * @return toTokenAmountOut The number of `toToken` tokens received upon selling the STAX receipt token.
      */
    function exitToToken(
        uint256 staxReceiptAmount, address toToken, uint256 expectedToTokenAmount, bytes memory otherQuoteParams, uint256 slippageBps, address recipient
    ) external returns (uint256 toTokenAmountOut);

    /** 
      * @notice Sell stax ERC20 receipt tokens to native ETH/AVAX.
      * @param staxReceiptAmount The amount of STAX ERC20 receipt tokens to sell
      * @param expectedNativeAmount The quoted amount of native chain token to expect, inclusive of any fees - do not apply slippage to this.
      * @param otherQuoteParams Other quote params required by the investment - do not apply slippage to this.
      * @param slippageBps Acceptable slippage, applied to both the `expectedNativeAmount` and `otherQuoteParams`
      * @param recipient The receiving address of the native chain token.
      * @return nativeAmountOut The number of native chain ETH/AVAX/etc tokens received upon selling the STAX receipt token.
      */
    function exitToNative(
        uint256 staxReceiptAmount, uint256 expectedNativeAmount, bytes memory otherQuoteParams, uint256 slippageBps, address payable recipient
    ) external returns (uint256 nativeAmountOut);

    /**
     * @notice STAX can recover tokens accidentally transferred to this contract.
     */
    function recoverToken(address _token, address _to, uint256 _amount) external;

    /** 
     * @notice Protocol can pause the investment.
     */
    function pause() external;

    /** 
     * @notice Protocol can unpause the investment.
     */
    function unpause() external;

    /**
     * @notice Annual Percentage Rate (APR) in basis points for this investment,
     * based on the projected reward rates when staking
     * @dev APR == [the total USD value of rewawrds for one per year] / [divided by USD value of the staked stax receipt tokens]
     */
    function apr() external returns (uint256 aprBps);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxInvestmentManager.sol)

interface IStaxInvestmentManager {
    function rewardTokensList() external view returns (address[] memory tokens);
    function harvestRewards() external returns (uint256[] memory amounts);
    function harvestableRewards() external view returns (uint256[] memory amounts);
    function projectedRewardRates() external view returns (uint256[] memory amounts);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxRewardsDistributor.sol)

interface IStaxRewardsDistributor {
    function allRewardTokens() external view returns (address[] memory);
    function harvestRewards(bool _transferOutstandingDistributions) external;
    function pendingRewards() external view returns (uint256[] memory pendingAmounts);
    function distribute(bool forceHarvest) external returns (
        uint256[] memory distributedAmounts, 
        bool rewardsHarvested
    );
    function projectedRewardRates() external view returns (uint256[] memory amounts);
    function latestActualRewardRates() external view returns (uint256[] memory amounts);
    function setStaking(address _staking) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxStaking.sol)

import "./IStaxRewardsDistributor.sol";

interface IStaxStaking {
    /// @notice Stake an amount of `stakingToken` on behalf of another address.
    /// @param _for Who to stake `stakingToken` on behalf of
    /// @param _amount The amount of `stakingToken` to stake
    function stakeFor(address _for, uint256 _amount) external;

    /// @notice Pull the latest distributions and update global and user state
    /// @param _account 0x0 for just the global state, user address for global+user state
    /// @param _forceHarvest Force a harvest of rewards from upstream investment.
    /// @dev Used internally whenever users stake/unstake/claim, and can also be
    /// used by a keeper to distribute and harvest on a schedule.
    function updateRewards(address _account, bool _forceHarvest) external returns (bool rewardsHarvested);

    /// @notice The upstream rewards distributor.
    function distributor() external view returns (IStaxRewardsDistributor);

    /// @notice The set of reward tokens currently issuing rewards.
    /// @dev This doesn't include any past reward tokens which are no longer issuing rewards.
    function currentRewardTokens() external view returns (address[] memory);

    /// @notice The projected reward rates per second 'as of now', driven from the upstream reward distributor,
    /// to 1e18 precision. These may fluctuate block-to-block as external events happen
    /// (eg they change emissions, STAX's dilution of upstream rewards change, etc)
    /// @dev The reward rate represents STAX's total rewards per second across all of it's stakers.
    function projectedRewardRates() external view returns (uint256[] memory);

    /// @notice The total amount of staked tokens
    function totalSupply() external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/gmx/StaxGmxLocker.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../StaxInvestment.sol";
import "../../interfaces/common/IMintableToken.sol";
import "../../interfaces/investments/gmx/IStaxGmxManager.sol";
import "../../interfaces/staking/IStaxStaking.sol";
import "../../common/CommonEventsAndErrors.sol";

/// @title STAX GMX Investment
/// @notice Users purchase stxGMX with pre-purchased GMX
/// Upon investment, users receive the same as amount of stxGMX as deposited GMX
/// Staked stxGMX will earn boosted ETH/AVAX & stxGMX rewards.
contract StaxGmxInvestment is StaxInvestment {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;

    /// @notice The GMX token used for purchases.
    IERC20 public immutable gmxToken;

    /// @notice The STAX contract managing the holdings of GMX and derived esGMX/mult point rewards
    IStaxGmxManager public staxGmxManager;

    /// @notice The STAX contract holding the staked GMX/GLP/multiplier points/esGMX
    IStaxGmxDepositor public depositor;

    /// @notice If true, STAX will stake the GMX immediately on user deposits.
    ///         If false, STAX automation applies the GMX on aggregate on a schedule.
    bool public applyGmxOnPurchase;

    event ApplyGmxOnPurchaseSet(bool value);
    event StaxGmxManagerSet(address staxGmxManager);
    
    constructor(
        address _stxGmxToken,
        address _staxGmxManager,
        address _gmxToken,
        bool _applyGmxOnPurchase,
        address _staxStaking,
        address _staxTokenPrices
    ) StaxInvestment(_stxGmxToken, _staxStaking, _staxTokenPrices) {
        staxGmxManager = IStaxGmxManager(_staxGmxManager);
        depositor = staxGmxManager.depositor();
        gmxToken = IERC20(_gmxToken);
        applyGmxOnPurchase = _applyGmxOnPurchase;
    }

    /// @notice Set the Stax GMX Manager contract used to apply GMX to earn rewards.
    function setStaxGmxManager(address _staxGmxManager) external onlyOwner {
        if (_staxGmxManager == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        staxGmxManager = IStaxGmxManager(_staxGmxManager);
        depositor = staxGmxManager.depositor();
        emit StaxGmxManagerSet(_staxGmxManager);
    }

    /// @notice Whether STAX will stake the GMX within the same user transaction as their buy, 
    /// or later on aggregate/scheduled.
    function setApplyGmxOnPurchase(bool _value) external onlyOwner {
        applyGmxOnPurchase = _value;
        emit ApplyGmxOnPurchaseSet(_value);
    }

    /**
     * @notice Only GMX can be used to buy stxGMX
     */
    function acceptedTokens() external override view returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = address(gmxToken);
    }

    /**
     * @notice Get a quote to buy the stxGMX using GMX.
     * @param fromTokenAmount How much of GMX to invest with
     * @param fromToken This must be the address of the GMX token
     * @return staxReceiptAmountOut The number of stxGMX to expect.
     */
    function investWithTokenQuote(
        uint256 fromTokenAmount, address fromToken
    ) external override view returns (uint256 staxReceiptAmountOut, uint256[] memory /*investFeeBps*/, bytes memory /*otherQuoteParams*/) {
        if (fromToken != address(gmxToken)) revert CommonEventsAndErrors.InvalidToken(fromToken);

        // stxGMX is minted 1:1, no fees or other quote params
        return (fromTokenAmount, new uint256[](0), new bytes(0));
    }

    /** 
      * @notice User buys stxGMX with an amount GMX.
      * @param fromTokenAmount How much of GMX to invest with
      * @param fromToken This must be the address of the GMX token
      * @param stake If true, immediately stake the resulting stxGMX
      * @return staxReceiptAmountOut The actual number of stxGMX tokens received.
      */
    function investWithToken(
        uint256 fromTokenAmount, address fromToken, bool stake, uint256 /*expectedStaxReceiptAmount*/, bytes calldata /*otherQuoteParams*/, uint256 /*slippageBps*/
    ) external override whenNotPaused returns (uint256 staxReceiptAmountOut) {
        if (fromToken != address(gmxToken)) revert CommonEventsAndErrors.InvalidToken(fromToken);
        if (fromTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // If apply immediately, transfer the GMX straight to the depositor and stake the GMX at GMX.io
        // Otherwise transfer to the staxGmxManager which will manage staking the GMX on aggregate in a separate transaction
        if (applyGmxOnPurchase) {
            gmxToken.safeTransferFrom(msg.sender, address(depositor), fromTokenAmount);
            depositor.stakeGmx(fromTokenAmount);
        } else {
            gmxToken.safeTransferFrom(msg.sender, address(staxGmxManager), fromTokenAmount);
        }

        // Mint and optionally stake the stxGMX for the user
        staxReceiptAmountOut = fromTokenAmount;
        mintStaxReceiptToken(msg.sender, staxReceiptAmountOut, stake);
        emit Invested(msg.sender, fromTokenAmount, fromToken, staxReceiptAmountOut, stake);
    }

    /** 
      * @notice Unsupported - cannot invest in stxGMX using native chain ETH/AVAX
      */
    function investWithNative(
        bool /*stake*/, uint256 /*expectedStaxReceiptAmount*/, bytes calldata /*otherQuoteParams*/, uint256 /*slippageBps*/
    ) external payable override returns (uint256) {
        revert Unsupported();
    }

    /**
     * @notice Get a quote to sell stxGMX to GMX.
     * @param staxReceiptAmount The amount of stxGMX to sell
     * @param toToken This must be the address of the GMX token
     * @return toTokenAmountOut The number of GMX tokens to expect.
     * @return exitFeeBps [STAX's exit fee]
     */
    function exitToTokenQuote(
        uint256 staxReceiptAmount, address toToken
    ) external override view returns (uint256 toTokenAmountOut, uint256[] memory exitFeeBps, bytes memory /*otherQuoteParams*/) {
        if (toToken != address(gmxToken)) revert CommonEventsAndErrors.InvalidToken(toToken);
        exitFeeBps = new uint256[](1);
        (exitFeeBps[0], toTokenAmountOut) = staxGmxManager.sellStxGmxQuote(staxReceiptAmount);
        return (toTokenAmountOut, exitFeeBps, new bytes(0));
    }

    /** 
      * @notice Sell stxGMX to receive GMX. 
      * @param staxReceiptAmount The amount of stxGMX to sell
      * @param toToken This must be the address of the GMX token
      * @param recipient The receiving address of the `toToken`
      * @return toTokenAmountOut The number of `toToken` tokens received upon selling the stxGLP
      */
    function exitToToken(
        uint256 staxReceiptAmount, address toToken, uint256 /*expectedToTokenAmount*/, bytes memory /*otherQuoteParams*/, uint256 /*slippageBps*/, address recipient
    ) external override whenNotPaused returns (uint256 toTokenAmountOut) {
        if (toToken != address(gmxToken)) revert CommonEventsAndErrors.InvalidToken(toToken);
        staxReceiptToken.safeTransferFrom(msg.sender, address(staxGmxManager), staxReceiptAmount);
        toTokenAmountOut = staxGmxManager.sellStxGmx(staxReceiptAmount, recipient);

        emit Exited(msg.sender, staxReceiptAmount, toToken, toTokenAmountOut, recipient);
    }

    /** 
      * @notice Unsupported - cannot exit stxGMX to native chain ETH/AVAX
      */
    function exitToNative(
        uint256 /*stxGmxAmount*/, uint256 /*expectedNativeAmount*/, bytes memory /*otherQuoteParams*/,  uint256 /*slippageBps*/, address payable /*recipient*/
    ) external pure override returns (uint256 /*nativeAmount*/) {
        revert Unsupported();
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/StaxInvestment.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/common/IMintableToken.sol";
import "../interfaces/common/IStaxTokenPrices.sol";
import "../interfaces/investments/IStaxInvestment.sol";
import "../interfaces/staking/IStaxStaking.sol";
import "../common/CommonEventsAndErrors.sol";

/**
 * @title STAX Investment
 * @notice Users invest in the underlying protocol and receive an ERC20 receipt token in return.
 * This receipt token can be staked to earn protocol rewards, and surrendered to exit the investment.
 * STAX will apply the accepted investment token into the underlying protocol in the most optimal way.
 */
abstract contract StaxInvestment is IStaxInvestment, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;

    /// @notice The STAX ERC20 receipt token, received upon investment.
    IMintableToken public immutable override staxReceiptToken;

    /// @notice The STAX staking contract
    IStaxStaking public immutable override staxStaking;

    IStaxTokenPrices public staxTokenPrices;

    constructor(
        address _staxReceiptToken,
        address _staxStaking,
        address _staxTokenPrices
    ) {
        staxReceiptToken = IMintableToken(_staxReceiptToken);
        staxStaking = IStaxStaking(_staxStaking);
        staxTokenPrices = IStaxTokenPrices(_staxTokenPrices);
    }

    /** 
     * @notice Protocol can pause the investment.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /** 
     * @notice Protocol can unpause the investment.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /// @notice The GLP Locker can mint stxGLP for users, and optionally immediately stake it on their behalf
    function mintStaxReceiptToken(address onBehalfOf, uint256 amountToMint, bool stake) internal {
        if (stake) {
            staxReceiptToken.mint(address(this), amountToMint);
            staxReceiptToken.safeIncreaseAllowance(address(staxStaking), amountToMint);
            staxStaking.stakeFor(onBehalfOf, amountToMint);
        } else {
            staxReceiptToken.mint(onBehalfOf, amountToMint);
        }
    }

    /**
     * @notice Annual Percentage Rate (APR) in basis points for this investment,
     * based on the projected reward rates when staking
     * @dev APR == [the total USD value of rewawrds for one per year] / [divided by USD value of the staked stax receipt tokens]
     */
    function apr() external view returns (uint256 aprBps) {
        address[] memory stakingRewardTokens = staxStaking.currentRewardTokens();
        uint256[] memory projectedRewardRates = staxStaking.projectedRewardRates();  // 1e18 precision
        int256[] memory rewardTokenPricesUsd = staxTokenPrices.tokenPrices(stakingRewardTokens); // 1e30 precision

        // Accumulate the USD value of rewards for the year, based on the current projected reward rates per second.
        int256 projectedRewardsUsdPerSec;
        for (uint256 i; i < projectedRewardRates.length; ++i) {
            projectedRewardsUsdPerSec += int256(projectedRewardRates[i]) * rewardTokenPricesUsd[i];
        }
        int256 projectedRewardsUsdPerYear = projectedRewardsUsdPerSec * 365 days; // 1e48 precision

        // Calculate the USD value of staked stax receipt tokens
        int256 staxStakedTokens = int256(staxStaking.totalSupply()); // 1e18 precision
        int256 staxStakedTokenPriceUsd = staxTokenPrices.tokenPrice(address(staxReceiptToken)); // 1e30 precision
        int256 staxStakedSupplyUsd = staxStakedTokens * staxStakedTokenPriceUsd; // 1e48 precision

        aprBps = (staxStakedSupplyUsd == 0) ? 0 : uint256(10_000 * projectedRewardsUsdPerYear / staxStakedSupplyUsd);
    }

}