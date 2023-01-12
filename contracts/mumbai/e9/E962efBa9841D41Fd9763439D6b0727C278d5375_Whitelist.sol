/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.13;


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

// File: 11-01-23 Ido smart contract/MemoryLayout.sol

pragma solidity 0.8.15;


struct VirtualPool {
    // pool ID
    uint8 poolId;
    // start time
    uint64 startTime;
    // Numbers of participants
    uint32 participants;
    // is the pool is redeemable, meaning tokens are releasable
    bool canRedeem;
    // Is the pool is paused
    bool paused;
    // is the pool is closed
    bool closed;
    // the amount of the allocation in payment token, this amount is considered as a base amount.
    uint256 paymentTokenAllocation;
    // Numbers of tokens available
    uint256 totalProjectToken;
    // number of 'Payment Token' to raise.
    uint256 totalPaymentTokenToRaise;
    // number of 'Payment Token' raised.
    uint256 totalPaymentTokenRaised;
    // Numbers of tokens sold
    uint256 totalProjectTokenSold;
    // Numbers of tokens unsold
    uint256 totalProjectTokenUnsold;
}

struct VirtualPoolPrice {
    //define the token price in paymentToken
    uint256 projectTokenPrice;
    // define how many tokens you will receive for the project token price.
    uint256 projectTokenForPrice;
}

struct VirtualBuyer {
    // pool ID
    uint8 poolId;
    // is tokens has been redeem?
    bool redeemed;
    // current funded allocation
    uint256 allocation;
    uint256 tokensBought;
    uint256 tokensRedeemable;
}

contract MemoryLayout is Ownable {
    /**
     * @notice define the project token used for the fundraising
     */
    address public projectToken;

    /**
     * @notice define the token used to fund, usually a stablecoin.
     */
    address public paymentToken;

    /**
     * @notice In case of vesting, this ratio percentage is used to calculate the amount of tokens the user can redeem.
     */
    uint256 public vestingRatioPercentage;

    /**
     * @notice Addresse where funds are sent after withdraw
     */
    address public withdrawFundsAddress;

    /**
     * @notice Pools mapping
     */
    mapping(uint8 => VirtualPool) public pools;
    mapping(uint8 => VirtualPoolPrice) public poolPrices;

    /**
     * @notice Array containing all pool ids.
     */

    uint8[] public poolIds;

    /**
     * @notice Buyers (poolId > address > VirtualBuyer data)
     */
    mapping(uint256 => mapping(address => VirtualBuyer)) public buyers;
}
// File: 11-01-23 Ido smart contract/Vault.sol

pragma solidity 0.8.15;




contract Vault is MemoryLayout, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Emitted when the owner withdraw payment tokens from the pool
     */
    event WithdrawnPaymentToken(uint256 totalPaymentToken);

    /**
     * @dev Emitted when the owner withdraw project tokens from the pool
     */
    event WithdrawnProjectToken(uint256 totalProjectToken);

    /// @notice Get all of the project tokens inside of the contract
    function withdrawProjectTokens() external nonReentrant onlyOwner {
        require(projectToken != address(0), "Withdraw not allowed: No tokens");

        uint256 total = IERC20(projectToken).balanceOf(address(this));
        IERC20(projectToken).safeTransfer(owner(), total);

        emit WithdrawnProjectToken(total);
    }

    /// @notice Get all of the payment tokens inside of the contract
    function withdrawPaymentTokens() external nonReentrant onlyOwner {
        uint256 total = IERC20(paymentToken).balanceOf(address(this));

        IERC20(paymentToken).safeTransfer(withdrawFundsAddress, total);

        emit WithdrawnPaymentToken(total);
    }
}
// File: 11-01-23 Ido smart contract/Whitelist.sol

pragma solidity 0.8.15;


contract Whitelist is MemoryLayout {
    /**
     * Whitelist (poolId > address > number of tickets)
     */
    mapping(uint8 => mapping(address => uint8)) public whitelist;

    /// @notice Whitelist a bunch of address into a "Virtual Pool"
    /// @dev if the address is already whitelisted, we top-up numbers of tickets.
    /// @param _addrs Array of addresses
    /// @param _tickets Number of tickets associated (1 ticket = 1 paymentTokenAllocation for the given pool)
    /// @param _poolId Pool identifier
    function whitelistAddresses(
        address[] memory _addrs,
        uint8 _tickets,
        uint8 _poolId
    ) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_poolId][_addrs[i]] += _tickets;
        }
    }

    /// @notice Determine if the user can access a pool regarding if he owns "tickets"
    /// @param _user user address
    /// @param _poolId Unique pool identifier
    /// @return bool
    function canAccess(address _user, uint8 _poolId)
        public
        view
        returns (bool)
    {
        return whitelist[_poolId][_user] > 0;
    }
}
// File: 11-01-23 Ido smart contract/Pool.sol

pragma solidity 0.8.15;



contract Pool is MemoryLayout, Whitelist {
    using SafeERC20 for IERC20;

    /**
     * @dev Emitted when a pool is added.
     */
    event PoolInitialized(uint8 poolId);

    /**
     * @dev Emitted when the pool is paused
     */
    event PoolPaused(uint8 poolId);

    /**
     * @dev Emitted when the pause is lifted
     */
    event PoolUnpaused(uint8 poolId);

    /**
     * @dev Emitted when the pool is closed
     */
    event PoolClosed(uint256 unsold, uint256 sold, uint8 poolId);

    /**
     * @dev Emitted when tokens within the pool are releasable
     */
    event PoolRedeemAllowed(uint256 poolId);

    /**
     * @dev Emitted when the owner collects the remaing unsold tokens
     */
    event WithdrawnPoolUnsoldProjectToken(uint256 unsold, uint8 poolId);

    /// @notice Modifier When Sale Not Paused
    /// @param _poolId Unique Identifier of the pool
    modifier whenPoolNotPaused(uint8 _poolId) {
        require(!pools[_poolId].paused, "Pool paused");
        _;
    }

    /// @notice Modifier When Sale Paused
    /// @param _poolId Unique Identifier of the pool
    modifier whenPoolPaused(uint8 _poolId) {
        require(pools[_poolId].paused, "Pool not paused");
        _;
    }

    /// @notice Modifier When Pool is Closed
    /// @param _poolId Unique Identifier of the pool
    modifier whenPoolIsClosed(uint8 _poolId) {
        require(pools[_poolId].closed, "Pool has to be closed");
        _;
    }

    /// @notice Initialze a Pool
    /// @param _poolId Unique Identifier of the pool
    /// @param _startTime Start time of the pool (unix seconds)
    /// @param _paymentTokenAllocation  the base amount of the allocation in payment token
    /// @param _totalProjectToken  The total project token in the pool
    /// @param _projectTokenPrice  The project token price
    /// @param _projectTokenForPrice  The number of tokens expected for token price.
    
    function initializePool(
        uint8 _poolId,
        uint64 _startTime,
        uint256 _paymentTokenAllocation,
        uint256 _totalProjectToken,
        uint256 _projectTokenPrice,
        uint256 _projectTokenForPrice
    ) external onlyOwner {
        require(pools[_poolId].startTime == 0, "Pool already initialized");
        uint256 totalTokensVested = (_totalProjectToken * _projectTokenPrice) /
            _projectTokenForPrice;
        uint256 totalPaymentTokenToRaise = (totalTokensVested * 100) /
            vestingRatioPercentage;

        // Add pool.
        pools[_poolId] = VirtualPool({
            poolId: _poolId,
            startTime: _startTime,
            participants: 0,
            canRedeem: false,
            paused: false,
            closed: false,
            paymentTokenAllocation: _paymentTokenAllocation,
            totalProjectToken: _totalProjectToken,
            totalPaymentTokenToRaise: totalPaymentTokenToRaise,
            totalPaymentTokenRaised: 0,
            totalProjectTokenSold: 0,
            totalProjectTokenUnsold: _totalProjectToken
        });

        // to avoid stack to deep error, i created another struct to store prices related to the pool
        poolPrices[_poolId] = VirtualPoolPrice({
            projectTokenPrice: _projectTokenPrice,
            projectTokenForPrice: _projectTokenForPrice
        });

        poolIds.push(_poolId);
        emit PoolInitialized(_poolId);
    }

    /// @notice Pause a pool
    /// @param _poolId Unique Identifier of the pool
    function pausePool(uint8 _poolId)
        external
        onlyOwner
        whenPoolNotPaused(_poolId)
    {
        pools[_poolId].paused = true;

        emit PoolPaused(_poolId);
    }

    /// @notice Unause a pool
    /// @param _poolId Unique Identifier of the pool
    function unPausePool(uint8 _poolId)
        external
        onlyOwner
        whenPoolPaused(_poolId)
    {
        pools[_poolId].paused = false;

        emit PoolUnpaused(_poolId);
    }

    /// @notice Close pool. This action is irreversible
    /// @dev We set the numbers of tokens in the pool equals to the number of tokens sold.
    /// @param _poolId Unique Identifier of the pool
    function closePool(uint8 _poolId) external onlyOwner {
        pools[_poolId].closed = true;
        // the total tokens in the pool is now equals to the total tokens sold.
        pools[_poolId].totalProjectToken = pools[_poolId].totalProjectTokenSold;

        emit PoolClosed(
            pools[_poolId].totalProjectTokenUnsold,
            pools[_poolId].totalProjectTokenSold,
            _poolId
        );
    }

    /// @notice Allow redeem
    /// @dev only if pool is closed and we have project token address
    /// @param _poolId Unique Identifier of the pool
    function allowPoolRedeem(uint8 _poolId)
        external
        onlyOwner
        whenPoolIsClosed(_poolId)
    {
        require(projectToken != address(0), "No Project Token address");

        pools[_poolId].canRedeem = true;

        emit PoolRedeemAllowed(_poolId);
    }
}
// File: 11-01-23 Ido smart contract/BuyerAccess.sol

pragma solidity 0.8.15;



contract BuyerAccess is MemoryLayout, Whitelist {
    /// @notice Check if the user can buy from a given pool
    /// @param _poolId Unique Identifier of the pool
    modifier isAllowedToBuy(uint8 _poolId) {
        require(canBuy(msg.sender, _poolId), "You're not allowed to buy");
        _;
    }

    /// @notice Check if the user can redeem from a given pool
    /// @param _poolId Unique Identifier of the pool
    modifier isAllowedToRedeem(uint8 _poolId) {
        require(canRedeem(msg.sender, _poolId), "You're not allowed to redeem");
        _;
    }

    /// @notice Returns if the pool is open
    /// @param _poolId Unique Identifier of the pool
    /// @return bool
    function _isPoolOpen(uint8 _poolId) private view returns (bool) {
        if (pools[_poolId].closed) return false;

        return block.timestamp >= pools[_poolId].startTime;
    }

    /// @notice Get the maximum allocation the user can spend for a given pool.
    /// @param _user user address
    /// @param _poolId Unique pool identifier
    /// @return uint256 allocation
    function getMaximumPaymentTokenAllocation(address _user, uint8 _poolId)
        public
        view
        returns (uint256)
    {
        uint256 paymentTokenAllocation = pools[_poolId].paymentTokenAllocation;

        return whitelist[_poolId][_user] * paymentTokenAllocation;
    }

    /// @notice Determine if the user can buy from a given pool.
    /// @param _user Sender address
    /// @param _poolId Unique pool identifier
    /// @return bool
    function canBuy(address _user, uint8 _poolId) public view returns (bool) {
        // if the user is not on the whitelist
        if (!canAccess(_user, _poolId)) return false;

        // if sale is not open
        if (!_isPoolOpen(_poolId)) return false;

        // if the contract is paused.
        if (pools[_poolId].paused) return false;

        // if you did bought tokens
        if (
            buyers[_poolId][_user].allocation >=
            getMaximumPaymentTokenAllocation(_user, _poolId)
        ) return false;

        // if we can redeem, you cannot buy anymore
        if (pools[_poolId].canRedeem) return false;

        return true;
    }

    /// @notice Determine if the user can redeem from a given pool.
    /// @param _user Sender address
    /// @param _poolId Unique pool identifier
    /// @return bool
    function canRedeem(address _user, uint8 _poolId)
        public
        view
        returns (bool)
    {
        if (!canAccess(_user, _poolId)) return false;
        // if the contract is paused.
        if (pools[_poolId].paused) return false;

        // if we cannot redeem
        if (!pools[_poolId].canRedeem) return false;

        // if you did not buy tokens
        if (buyers[_poolId][_user].tokensBought == 0) return false;

        // if you have redeemed already
        if (buyers[_poolId][_user].redeemed) return false;

        return true;
    }
}
// File: 11-01-23 Ido smart contract/Buyer.sol

pragma solidity 0.8.15;





struct BuyerProfile {
    // pool ID
    uint8 poolId;
    // is tokens has been redeem?
    bool redeemed;
    bool canAccess;
    bool canBuy;
    bool canRedeem;
    // max allocation for the pool
    uint256 maxAllocation;
    // current funded allocation
    uint256 allocation;
    uint256 tokensBought;
    uint256 tokensRedeemable;
}

contract Buyer is MemoryLayout, BuyerAccess, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /**
     * @dev Emitted when a user bought tokens.
     */
    event Bought(
        address indexed user,
        uint8 poolId,
        uint256 allocation,
        uint256 tokensBought,
        uint256 tokensRedeemable
    );

    /**
     * @dev Emitted when a user redeem his tokens
     */
    event Redeemed(
        address indexed user,
        uint8 poolId,
        uint256 tokensRedeemable
    );

    /// @notice is the user allow to transfer paymentToken?
    /// @dev In order to do an ERC20 Transfer, the contract has to get the allowance.
    /// @param _allocation Allocation
    modifier isAllowedToTransferPaymentToken(uint256 _allocation) {
        require(_allocation > 0, "Incorrect Allocation");
        require(_isSufficientBalance(_allocation), "Insufficient balance");
        require(
            IERC20(paymentToken).allowance(msg.sender, address(this)) >=
                _allocation,
            "You must approve transfer"
        );
        _;
    }

    /// @notice Check if the user can still purchase tokens with allocation
    /// @param _poolId Unique pool identifier
    /// @param _allocation Allocation
    function _isAllocationAllow(uint8 _poolId, uint256 _allocation)
        private
        view
        returns (bool)
    {
        uint256 buyerAllocation = buyers[_poolId][msg.sender].allocation +
            _allocation;
        uint256 maxAllocation = getMaximumPaymentTokenAllocation(
            msg.sender,
            _poolId
        );

        return buyerAllocation <= maxAllocation;
    }

    /// @notice Check if the user has enough paymentToken balance
    /// @param _allocation Allocation
    function _isSufficientBalance(uint256 _allocation)
        private
        view
        returns (bool)
    {
        uint256 balance = IERC20(paymentToken).balanceOf(msg.sender);
        return balance >= _allocation;
    }

    /// @notice Check if there is tokens available with the amount of tokens the user is purchasing
    /// @param _poolId Unique pool identifier
    /// @param _tokensBought Tokens the user bought
    function _isTokensAvailable(uint8 _poolId, uint256 _tokensBought)
        private
        view
        returns (bool)
    {
        uint256 totalProjectTokenSold = pools[_poolId].totalProjectTokenSold +
            _tokensBought;

        return totalProjectTokenSold <= pools[_poolId].totalProjectToken;
    }

    /// @notice Before buy (before paymentToken transfer)
    /// @param _poolId Unique pool identifier
    /// @param _allocation Allocation for pool
    /// @param _tokensBought Number of tokens bought (100%)
    /// @param _tokensRedeemable Number of tokens for initial release (according to vesting)
    function _beforeBuy(
        uint8 _poolId,
        uint256 _allocation,
        uint256 _tokensBought,
        uint256 _tokensRedeemable
    ) private {
        // add +1 to participants if he buy for the first time
        if (buyers[_poolId][msg.sender].allocation == 0) {
            pools[_poolId].participants += 1;
        }

        buyers[_poolId][msg.sender].poolId = _poolId;
        buyers[_poolId][msg.sender].allocation =
            buyers[_poolId][msg.sender].allocation +
            _allocation;
        buyers[_poolId][msg.sender].tokensBought =
            buyers[_poolId][msg.sender].tokensBought +
            _tokensBought;
        buyers[_poolId][msg.sender].tokensRedeemable =
            buyers[_poolId][msg.sender].tokensRedeemable +
            _tokensRedeemable;

        // increase total raise
        pools[_poolId].totalPaymentTokenRaised =
            pools[_poolId].totalPaymentTokenRaised +
            _allocation;

        // increase total tokens sold
        pools[_poolId].totalProjectTokenSold =
            pools[_poolId].totalProjectTokenSold +
            _tokensBought;

        // reduce total tokens unsold
        pools[_poolId].totalProjectTokenUnsold =
            pools[_poolId].totalProjectToken -
            pools[_poolId].totalProjectTokenSold;
    }

    /// @notice Buy tokens for a given pool
    /// @param _allocation allocation amount in projectToken
    /// @param _poolId Unique pool identifier
    function buy(uint256 _allocation, uint8 _poolId)
        external
        nonReentrant
        isAllowedToBuy(_poolId)
        isAllowedToTransferPaymentToken(_allocation)
    {
        require(
            _isAllocationAllow(_poolId, _allocation),
            "Max allocation excedeed"
        );

        uint256 tokensBought = (_allocation *
            poolPrices[_poolId].projectTokenForPrice) /
            poolPrices[_poolId].projectTokenPrice;
        uint256 tokensRedeemable = (tokensBought * vestingRatioPercentage) /
            100;

        require(_isTokensAvailable(_poolId, tokensBought), "Pool soldout");

        _beforeBuy(_poolId, _allocation, tokensBought, tokensRedeemable);

        // transfer
        IERC20(paymentToken).safeTransferFrom(
            msg.sender,
            address(this),
            _allocation
        );

        emit Bought(
            msg.sender,
            _poolId,
            _allocation,
            tokensBought,
            tokensRedeemable
        );
    }

    /// @notice Redeem tokens for a given pool
    /// @param _poolId Unique pool identifier
    function redeem(uint8 _poolId)
        external
        nonReentrant
        isAllowedToRedeem(_poolId)
    {
        uint256 tokensRedeemable = buyers[_poolId][msg.sender].tokensRedeemable;
        //reset
        buyers[_poolId][msg.sender].redeemed = true;
        buyers[_poolId][msg.sender].tokensRedeemable = 0;

        // check balance
        uint256 balance = IERC20(projectToken).balanceOf(address(this));
        require(balance >= tokensRedeemable, "Insufficient tokens");

        // transfer
        IERC20(projectToken).safeTransfer(msg.sender, tokensRedeemable);

        emit Redeemed(msg.sender, _poolId, tokensRedeemable);
    }

    /// @notice Get the buyer profile. This will return all fundings made for a given buyer.
    /// @dev this function is used for an external purpose.
    /// The frontend can request the contract only once and get an array of informations for all pools available.
    /// @param _user Buyer's address
    function getBuyerProfile(address _user)
        external
        view
        returns (BuyerProfile[] memory)
    {
        uint256 nbrOfPools = poolIds.length;
        BuyerProfile[] memory buyerProfile = new BuyerProfile[](nbrOfPools);

        for (uint8 i = 0; i < nbrOfPools; i++) {
            uint256 maxAllocation = getMaximumPaymentTokenAllocation(
                _user,
                poolIds[i]
            );

            buyerProfile[i] = BuyerProfile({
                poolId: poolIds[i],
                redeemed: buyers[poolIds[i]][_user].redeemed,
                canAccess: canAccess(_user, poolIds[i]),
                canBuy: canBuy(_user, poolIds[i]),
                canRedeem: canRedeem(_user, poolIds[i]),
                maxAllocation: maxAllocation,
                allocation: buyers[poolIds[i]][_user].allocation,
                tokensBought: buyers[poolIds[i]][_user].tokensBought,
                tokensRedeemable: buyers[poolIds[i]][_user].tokensRedeemable
            });
        }

        return buyerProfile;
    }
}
// File: 11-01-23 Ido smart contract/Contract.sol

pragma solidity 0.8.15;





contract Contract is MemoryLayout, Pool, Buyer, Vault {
    /// @notice Initialize fundraising contract
    /// @dev projectToken address can be zero because we can raise funds without any tokens for redemption.
    /// @param _paymentToken ERC20 token address used for funding, usually a stable token.
    /// @param _projectToken ERC20 address used for tokens that you are funding for
    /// @param _vestingRatioPercentage  In case of vesting, this ratio percentage is used to calculate the amount of tokens the user can redeem.
    /// @param _withdrawFundsAddress withdraw address to receive funds after fundraising
    
    constructor(
        address _paymentToken,
        address _projectToken,
        address _withdrawFundsAddress,
        uint256 _vestingRatioPercentage
    ) {
        require(_paymentToken != address(0), "Can not use 0x0");
        require(_withdrawFundsAddress != address(0), "Can not use 0x0");

        paymentToken = _paymentToken;
        projectToken = _projectToken;
        vestingRatioPercentage = _vestingRatioPercentage;
        withdrawFundsAddress = _withdrawFundsAddress;
    }

    /// @notice Get all pools
    /// @return VirtualPool[] Array of Pools
    function getPools() public view returns (VirtualPool[] memory) {
        uint256 numberOfPools = poolIds.length;
        VirtualPool[] memory pools = new VirtualPool[](numberOfPools);

        for (uint8 i = 0; i < numberOfPools; i++) {
            pools[i] = pools[poolIds[i]];
        }

        return pools;
    }

    fallback() external {
        revert("Transaction reverted");
    }
}