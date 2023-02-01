/**
 *Submitted for verification at polygonscan.com on 2023-01-31
*/

// File: contracts/ICrystals.sol


// @todo: What license should go there

pragma solidity ^0.8.7;

interface ICrystals {
    function create(address addressFor, 
                    uint crystalLevel, 
                    uint crystalCount) external;

    function create(address addressFor, 
                    uint crystalLevel, 
                    uint crystalCount,
                    bytes32 requestId) external;                    

    function consume(address addressFor, 
                     uint crystalLevel, 
                     uint crystalCount, 
                     uint targetId) external;

}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

pragma solidity ^0.8.0;


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

// File: contracts/PlayToEarn.sol


pragma solidity ^0.8.7;






interface StakingPoints {
    function pointsOf(address user) external view returns (uint);
}

interface Lootbox2 {
    function mint(address player, uint quality, uint count) external;
}

interface Halos {
    function balanceOf(address account, uint id) external view returns (uint);
}

contract PlayToEarn is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint public constant MONDAY = 1654473600;
    uint public DURATION  = 1 days;

    address public TRY_CONTRACT;
    address public LOOTBOX_CONTRACT;
    address public HALO_CONTRACT;
    address public CRYSTAL_CONTRACT;

    mapping (uint => uint[2]) lootboxChance;
    mapping (uint => uint[3]) crystalChance;

    uint MAX_CRYSTALS = 1000;
    uint MAX_NORMAL_LOOTBOXES = 3;
    uint MAX_ENHANCED_LOOTBOXES = 1;

    constructor() {

        TRY_CONTRACT = 0xEFeE2de82343BE622Dcb4E545f75a3b9f50c272D;
        LOOTBOX_CONTRACT = 0x514419A2b1d5321cB109870ABD2ef3290C791905;
        HALO_CONTRACT = 0x850eb069f65aa4C5F4a5453E0f121fd74Ab93B88;
        CRYSTAL_CONTRACT = 0x55AD818f4541d3dCdfFC7CD41504d0D4B6E8931c;
        
        if (block.chainid==80001) {
            TRY_CONTRACT = 0x70FF9b4E261CbeD4EDC4F1a61b408eF9B0416a7d;
            LOOTBOX_CONTRACT = 0xEe12EabEBB6795c3b32E9996bA6a86Afb33E9025;
            HALO_CONTRACT = 0x4179bf4870B86c72b4128e7d8088fd809e2F0bf0;
            CRYSTAL_CONTRACT = 0x414C174407c1144E893E0888a2f6B16200C6Ce87;
        }

        lootboxChance[0] = [0, 0];
        crystalChance[0] = [100 *10**5, 0, 0];

        lootboxChance[1] = [0.5 *10**5, 0.01 *10**5];
        crystalChance[1] = [80 *10**5, 15 *10**5, 5 * 10**5];

        lootboxChance[2] = [1 *10**5,  0.02 *10**5];
        crystalChance[2] = [75 *10**5, 12.5 *10**5, 12.5 *10**5];

        lootboxChance[3] = [2 *10**5, 0.025 *10**5];
        crystalChance[3] = [72.5 *10**5, 12.5 *10**5, 15 *10**5];

        lootboxChance[4] = [4 *10**5, 0.04 *10**5];
        crystalChance[4] = [70 *10**5, 10 *10**5, 20 *10**5];

        lootboxChance[5] = [4.5 *10**5, 0.05 *10**5];
        crystalChance[5] = [67.5 *10**5, 10 *10**5, 22.5 *10**5];

        lootboxChance[6] = [6 *10**5, 0.1 *10**5];
        crystalChance[6] = [60 *10**5, 5 *10**5, 35 *10**5];

        crystalsPerWin[1] = 10;
        crystalsPerWin[2] = 10;
        crystalsPerWin[3] = 10;
        crystalsPerWin[4] = 10;
        crystalsPerWin[5] = 10;
        crystalsPerWin[6] = 10;
        crystalsPerWin[7] = 10;
        crystalsPerWin[8] = 10;
        crystalsPerWin[9] = 10;
        crystalsPerWin[10] = 10;
        crystalsPerWin[11] = 11;
        crystalsPerWin[12] = 12;
        crystalsPerWin[13] = 13;
        crystalsPerWin[14] = 14;
        crystalsPerWin[15] = 15;
        crystalsPerWin[16] = 16;
        crystalsPerWin[17] = 17;
        crystalsPerWin[18] = 18;
        crystalsPerWin[19] = 19;
        crystalsPerWin[20] = 20;

    }

    // Lootbox2(LOOTBOX_CONTRACT).mint(msg.sender, lootboxType*10+1, count);

    mapping (address=>uint) public lastUpdateTimestamps;
    
    mapping (uint=>uint) public crystalsPerWin;
    function setCrystalsPerWin(uint winNumber, uint crystalcCount) public onlyOwner {
        crystalsPerWin[winNumber] = crystalcCount;
    }

    struct PlayerDay {
        uint winCount;
        uint crystalMultiplier;
        uint dropTier;
        uint dropMultiplier;
        uint winsClaimed;
        uint[2] lootboxDrops;
        uint crystalDrops;
    }

    mapping (address => mapping(uint => PlayerDay)) public playerDays;
    mapping (address => mapping(uint => uint)) public playerLootboxTickets;


    event playerDayUpdate (
        address player,
        uint date,
        uint winCount,
        uint crystalMultiplier,
        uint dropTier,
        uint dropMultiplier
    );

    //address updaterAddress = 0x060D545Eb39b81E3B531C16430A64D34FA0B7b3e;
    address updaterAddress = 0x684474961CE4474277E2B86B84E029194Fc9bb9e;
    
    function allowUpdate(address value) public onlyOwner {
        updaterAddress = value;
    }

    function disallowUpdate() public onlyOwner {
        updaterAddress = address(0);
    }

    function updatePlayer(address player, 
                          uint lastUpdateTimestamp, 
                          uint winCount, 
                          uint crystalMultiplier, 
                          uint dropTier,
                          uint dropMultiplier) public {

        require(msg.sender==updaterAddress || msg.sender==owner(), 'Update denied');
        require(lastUpdateTimestamps[player]!=lastUpdateTimestamp, 'Duplicate update');
        lastUpdateTimestamps[player] = lastUpdateTimestamp;
        uint date = timestampToDate(lastUpdateTimestamp);
        PlayerDay storage day = playerDays[player][date];

        require(day.winCount<winCount, 'Win count does not increase');

        require(day.winCount!=winCount || 
                day.crystalMultiplier!=crystalMultiplier || 
                day.dropTier!=dropTier || 
                day.dropMultiplier!=dropMultiplier, 'Nothing changed');
        

        day.winCount = winCount;
        day.crystalMultiplier = crystalMultiplier;
        day.dropTier = dropTier;
        day.dropMultiplier = dropMultiplier;

        emit playerDayUpdate (
            player,
            date,
            winCount,
            crystalMultiplier,
            dropTier,
            dropMultiplier
        );
    }

    function updatePlayerMulti(address[] memory player, 
                          uint[] memory lastUpdateTimestamp, 
                          uint[] memory winCount, 
                          uint[] memory crystalMultiplier, 
                          uint[] memory dropTier,
                          uint[] memory dropMultiplier) public {
        uint count = player.length;
        for (uint i=0; i<count; i++) {
            updatePlayer(player[i], lastUpdateTimestamp[i], winCount[i], crystalMultiplier[i], dropTier[i], dropMultiplier[i]);
        } 
    }

    function timestampToDate(uint timestamp) public view returns(uint) {
        return MONDAY+((timestamp - MONDAY)/DURATION)*DURATION;
    }

    // @todo we need multiplication for droMultiplier
    function randomLootboxRarity(uint dropTier, uint dropMultiplier) internal returns (int) {
        uint randomSeed = random_keccak(); 
        uint randomNumber = randomSeed % (100*10**5) + 1;
        uint randomCompare;
        int outcome = -1;
        for (uint i=0; i<2; i++) {
            if (dropMultiplier>0) {
                randomCompare += (lootboxChance[dropTier][i] * dropMultiplier) / (10 ** 5);
            } else {
                randomCompare += lootboxChance[dropTier][i];
            }

            // randomCompare += lootboxChance[dropTier][i];
            // if (dropMultiplier>0) {
            //     randomCompare *= dropMultiplier;
            // }

            if (randomNumber<=randomCompare) {
                outcome = int(i);
                break;
            }
        }
        return outcome;
    }

    function randomCrystalRarity(uint dropTier, uint dropMultiplier) internal returns (int) {
        uint randomSeed = random_keccak(); 
        uint randomNumber = randomSeed % (100*10**5) + 1;
        uint randomCompare;
        int outcome = -1;
        uint difference;
        for (uint i=0; i<3; i++) {
            randomCompare += crystalChance[dropTier][i];
            if (dropMultiplier>0) {
                if (i==0) {
                    // differenece = (5*1.59) - 5 = 2.95
                    difference =  ((crystalChance[dropTier][2] * dropMultiplier) / 10**5) - crystalChance[dropTier][2];
                    // 80 - 2.95 = 77.05
                    randomCompare -= difference;
                }
                if (i==2) { 
                    randomCompare += difference;
                }
            }
            if (randomNumber<=randomCompare) {
                outcome = int(i);
                break;
            }
        }
        return outcome;
    }

    event prizeDrop (
        address player,
        uint date,
        uint[2] lootboxes,
        uint[3] crystals,
        uint numberOfWins
    );

    function getHaloLevel() public view returns(uint) {
        if (block.chainid==1) {
            return 4;
        } 
        if (Halos(HALO_CONTRACT).balanceOf(msg.sender, 4)>0) {
            return 4;
        } else if (Halos(HALO_CONTRACT).balanceOf(msg.sender, 3)>0) {
            return 3;
        } else if (Halos(HALO_CONTRACT).balanceOf(msg.sender, 2)>0) {
            return 2;
        } else if (Halos(HALO_CONTRACT).balanceOf(msg.sender, 1)>0) {
            return 1;
        }    
        return 0;
    }

    function getClaimableWins(uint date) public view returns (uint) {
        return getClaimableWins(date, msg.sender);
    }

    function getClaimableWins(uint date, address player) public view returns (uint) {
        uint totalWins = playerDays[player][date].winCount;
        if (totalWins>20) 
        {
            totalWins = 20;
        }
        return totalWins - playerDays[player][date].winsClaimed;
    }

    function dropPrizes(uint date, uint numberOfWins) public nonReentrant {
        // require (tx.origin==msg.sender, "This is to protect from miners");
        require(block.timestamp-date<=7 days, 'Cant claim more then 7 days');
        PlayerDay storage day = playerDays[msg.sender][date];
        require(day.winsClaimed + numberOfWins<=20, 'Only first 20 wins are claimable per day');
        require(day.winCount - day.winsClaimed>=numberOfWins, 'Not enough wins to claim');
        uint[2] memory lootboxDrops = [uint(0), 0];
        uint[3] memory crystalDrops = [uint(0), 0, 0];
        uint haloLevel = getHaloLevel();
        uint crystalCount;
        uint crystalFinal;

        for (uint i=0; i<numberOfWins; i++) {
            day.winsClaimed++;

            crystalCount = 0;
            crystalFinal = 0;

            if (day.dropTier>0 && 
                (day.lootboxDrops[0]<MAX_NORMAL_LOOTBOXES || day.lootboxDrops[1]<MAX_ENHANCED_LOOTBOXES)
            ) {
                int lootboxRaritySource = randomLootboxRarity(day.dropTier, day.dropMultiplier);
                if (lootboxRaritySource>=0) {
                    uint lootboxRarity = uint(lootboxRaritySource);
                    if (
                        (lootboxRarity==0 && day.lootboxDrops[lootboxRarity]<MAX_NORMAL_LOOTBOXES)
                        || 
                        (lootboxRarity==1 && day.lootboxDrops[lootboxRarity]<MAX_ENHANCED_LOOTBOXES)
                    ) {
                        day.lootboxDrops[lootboxRarity]++;
                        playerLootboxTickets[msg.sender][lootboxRarity]++;
                        lootboxDrops[lootboxRarity]++;
                    }
                }
            }

            if (day.crystalDrops<MAX_CRYSTALS) {
                
                if (day.winsClaimed>=18) {
                    if (haloLevel>=4) {
                        crystalCount = crystalsPerWin[day.winsClaimed];                        
                    }
                } else if (day.winsClaimed>=16) {
                    if (haloLevel>=3) {
                        crystalCount = crystalsPerWin[day.winsClaimed];
                    }
                } else if (day.winsClaimed>=13) {
                    if (haloLevel>=2) {
                        crystalCount = crystalsPerWin[day.winsClaimed];
                    }
                } else if (day.winsClaimed>=11) {
                    if (haloLevel>=1) {
                        crystalCount = crystalsPerWin[day.winsClaimed];
                    }
                } else if (day.winsClaimed>0 && day.winsClaimed<=10) {
                    crystalCount = crystalsPerWin[day.winsClaimed];
                }

                if (crystalCount>0) {
                    crystalFinal = (crystalCount * day.crystalMultiplier)/(10**5);
                }

                if (crystalCount>0 && day.crystalDrops+crystalFinal<=MAX_CRYSTALS) {                    
                    day.crystalDrops += crystalFinal;
                    int crystalRaritySource = randomCrystalRarity(day.dropTier, day.dropMultiplier);
                    if (crystalRaritySource>=0) {
                        uint crystalRarity = uint(crystalRaritySource);
                        crystalDrops[crystalRarity] += crystalFinal;
                    }    
                }
            }

        }

        emit prizeDrop (
            msg.sender,
            date,
            lootboxDrops,
            crystalDrops,
            numberOfWins
        );

        for (uint i=0; i<3; i++) {
            if (crystalDrops[i]>0) {
                mintCrystals(i+1, crystalDrops[i]);
            }
        }

    }

    function mintCrystals(uint rarity, uint count) internal {
        if (block.chainid!=1) {
            ICrystals(CRYSTAL_CONTRACT).create(msg.sender, rarity, count);
        }
    }

    uint public nonce = 1988;
    function random_keccak () internal returns (uint256)
    {
        nonce++;
        if (block.chainid==1) {
            return uint256(keccak256(abi.encodePacked(nonce)));
        }
        return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, nonce, blockhash(block.number - 1))));
    }


    event LootboxClaimed (
        address player,
        uint lootboxType,
        uint count
    );

    // LootboxType 0: Normal, 1: Enhanced, 
    // itemType 1: Fanatic, 2: Weapon
    function claimLootbox(uint lootboxType, uint itemType, uint count) public nonReentrant {
        require(playerLootboxTickets[msg.sender][lootboxType]>=count, 'Not enough won tickets');
        playerLootboxTickets[msg.sender][lootboxType] -= count;
        require(itemType==1 || itemType==2, 'Invalid type');
        Lootbox2(LOOTBOX_CONTRACT).mint(msg.sender, itemType*10+1+lootboxType, count);
        emit LootboxClaimed(msg.sender, lootboxType, count);        
    }

    mapping (address=>bool) public blockedPlayers;

    function blockPlayer(address value) public onlyOwner {
        blockedPlayers[value] = true;
    }

    function unblockPlayer(address value) public onlyOwner {
        blockedPlayers[value] = false;
    }


}