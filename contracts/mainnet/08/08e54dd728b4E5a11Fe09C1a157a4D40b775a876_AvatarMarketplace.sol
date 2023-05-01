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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Collateral is IERC20{
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IAvatar {
    function createAvatar(
        uint16 multiplier,
        string memory tokenURI,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external returns (uint256);

    function createAvatar(
        address owner,
        uint16 multiplier,
        string memory tokenURI
    ) external returns (uint256);

    function getMultiplier(uint256 avatarId) external view returns (uint16);

    function isAssigned(uint256 avatarId) external view returns (bool, uint256);

    function applyMultiplier(
        uint256 oilWellId,
        uint256 avatarId,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IContractType {
    function getTypeContract() external pure returns (bytes32);
    function getTypeNameContract() external pure returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface ISimpleStaking{
    function distribute() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../ERC721/interfaces/IAvatar.sol";
import "../ERC721/interfaces/IContractType.sol";
import "./PresaleTax.sol";

contract AvatarMarketplace is ReentrancyGuard, PresaleTax {
    using ECDSALib for bytes;
    using Counters for Counters.Counter;

    IAvatar private avatarToken;
    Counters.Counter private _itemsSold;
    bool private turnOff = false;

    constructor(
        address _collateral,
        IECDSASignature2 _signature,
        IUAC _uac
    ) PresaleTax(_collateral, _signature, _uac) {}

    struct AvatarType {
        uint256 typeId;
        uint16 multiplier;
        uint256 price;
        string tokenURI; //IPFS Token Metadata
    }

    event AvatarSold(
        address indexed owner,
        uint256 indexed avatarId,
        uint16 multiplier,
        uint256 price
    );

    event ChangeAvatarToken(address prevAddress, address newAddress);

    event StatusChanged(string message, bool status);

    mapping(uint256 => AvatarType) private avatarTypes;

    function buyAvatar(uint256 typeId) external nonReentrant {
        _buyAvatar(typeId);
    }

    function createType(
        AvatarType memory aType,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        Signature.verifyMessage(
            abi
                .encodePacked(aType.price, aType.multiplier, aType.typeId, msg.sender)
                .hash(),
            nonce,
            timestamp,
            signatures
        );
        _createType(
            aType.typeId,
            aType.multiplier,
            aType.price,
            aType.tokenURI
        );
    }

    function removeType(
        uint256 typeId,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        Signature.verifyMessage(
            abi.encodePacked(typeId).hash(),
            nonce,
            timestamp,
            signatures
        );
        _removeType(typeId);
    }

    //SETTERS:-------------------------------------------//
    function switchStatus(
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        Signature.verifyMessage(
            abi.encodePacked(msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        turnOff = !turnOff;
        if (turnOff)
            emit StatusChanged(
                "All operations by this means have been suspended",
                turnOff
            );
        if (!turnOff)
            emit StatusChanged(
                "All operations by this means have been resumed",
                turnOff
            );
    }

    function setAvatarTokenAddress(
        IAvatar _avatarToken,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        Signature.verifyMessage(
            abi.encodePacked(address(_avatarToken), msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        require(
            IContractType(address(_avatarToken)).getTypeContract() ==
                keccak256(abi.encodePacked("multiplier"))
        );
        emit ChangeAvatarToken(address(avatarToken), address(_avatarToken));
        avatarToken = _avatarToken;
    }

    //---------------------------------------------------//

    //GETTERS:-------------------------------------------//
    function getSoldAmount() external view returns (uint256) {
        return _itemsSold.current();
    }

    //---------------------------------------------------//

    function _buyAvatar(uint256 typeId) private status {
        AvatarType memory aType = avatarTypes[typeId];
        require(aType.typeId != 0, "The token id is incorrect.");
        require(aType.price > 0, "The token id or price is incorrect.");

        _collateralTransferFrom(msg.sender, address(this), aType.price);
        _distributionPreSales(aType.price);

        uint256 avatarId = avatarToken.createAvatar(
            msg.sender,
            aType.multiplier,
            aType.tokenURI
        );

        _itemsSold.increment();

        emit AvatarSold(msg.sender, avatarId, aType.multiplier, aType.price);
    }

    function _createType(
        uint256 typeId,
        uint16 multiplier,
        uint256 price,
        string memory tokenURI
    ) private {
        avatarTypes[typeId] = AvatarType(typeId, multiplier, price, tokenURI);
    }

    function _removeType(uint256 typeId) private {
        avatarTypes[typeId] = AvatarType(0, 0, 0, "");
    }

    modifier status() {
        require(
            turnOff == false,
            "The operations of this marketplace are stopped"
        );
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../util/CriticalTracer.sol";
import "../ERC20/interfaces/IERC20Collateral.sol";
import "../Security2/Interfaces/IECDSASignature2.sol";
import "../Security2/Security2Base.sol";
import "./DecimalUtils.sol";

abstract contract CollateralWrapper is
    Security2Base,
    DecimalUtils,
    CriticalTracer
{
    using ECDSALib for bytes;
    using SafeERC20 for IERC20;
    IERC20 private collateral;

    event CollateralAddressChanged(address newCollateralAddress);
    event NewPriceOfTheBar(uint256 newPrice, uint256 prev);

    constructor(
        address _collateral,
        IECDSASignature2 _signature,
        IUAC _uac
    ) Security2Base(_signature, _uac) DecimalUtils(_signature, _uac) {
        collateral = IERC20(_collateral);
        _setDecimalTo(_collateral, 1); //1 USDT
    }

    function getCollateralAddress() external view returns (address) {
        return address(collateral);
    }

    function setCollateralAddress(
        address tokenAddress,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external onlyOwner {
        Signature.verifyMessage(
            abi.encodePacked(tokenAddress).hash(),
            nonce,
            timestamp,
            signatures
        );
        require(tokenAddress != address(0), _ctMsg("address cannot be zero"));
        collateral = IERC20Collateral(tokenAddress);
        emit CollateralAddressChanged(tokenAddress);
    }

    function _collateralTransfer(
        address to,
        uint256 amount
    ) internal validateBalance(amount) {
        require(to != address(0), _ctMsg("address cannot be zero"));
        require(amount > 0, _ctMsg("amount cannot be zero"));
        require(
            amount <= _collateralBalanceOf(address(this)),
            _ctMsg("not enough collateral")
        );
        uac.verifyGameStatus(3);
        collateral.safeTransfer(to, amount);
    }

    function _collateralTransferFrom(
        address from,
        address to,
        uint256 amount
    ) internal validateBalanceFrom(amount) {
        require(to != address(0), _ctMsg("address cannot be zero"));
        require(from != address(0), _ctMsg("the from address cannot be zero"));
        require(amount > 0, _ctMsg("amount cannot be zero"));
        uac.verifyGameStatus(3);
        collateral.safeTransferFrom(from, to, amount);
    }

    function _collateralBalanceOf(
        address account
    ) internal view returns (uint256) {
        return collateral.balanceOf(account);
    }

    function extractCollateral(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        Signature.verifyMessage(
            abi.encodePacked(to, amount, msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        _collateralTransfer(to, amount);
    }

    function decimals() external view returns (uint8) {
        return getDecimals(1);  //1 USDT
    }

    function raise(uint256 amount) internal view returns (uint256) {
        return amount * 10 ** getDecimals(1); //1 USDT
    }

    modifier validateBalance(uint256 price) {
        require(
            collateral.balanceOf(address(this)) >= price,
            _ctMsg("there is not enough collateral to transfer")
        );
        _;
    }

    modifier validateBalanceFrom(uint256 price) {
        require(
            collateral.balanceOf(msg.sender) >= price,
            _ctMsg("you dont have enough collateral")
        );
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "../ERC20/interfaces/IERC20Collateral.sol";
import "../Security2/Security2Base.sol";

contract DecimalUtils {
    using ECDSALib for bytes;
    mapping(uint => uint8) private decimalsByToken;
    IECDSASignature2 private signature;
    IUAC private uac;

    constructor(IECDSASignature2 _signature, IUAC _uac) {
        signature = _signature;
        uac = _uac;
        decimalsByToken[1] = 6; //USDT
        decimalsByToken[2] = 6; //BAR
        decimalsByToken[3] = 6; //WOS
        decimalsByToken[4] = 6; //CRU
    }

    function setDecimalTo(
        address token,
        uint key,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        signature.verifyMessage(
            abi.encodePacked(token, key, msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        _setDecimalTo(token, key);
    }

    function _setDecimalTo(address token, uint key) internal {
        uac.verifyGameStatus(5);
        IERC20Collateral erc20Token = IERC20Collateral(token);
        uint8 decimals = erc20Token.decimals();
        decimalsByToken[key] = decimals;
    }

    function getDecimals(uint key) internal view returns (uint8) {
        uint8 tDecimals = decimalsByToken[key];
        return tDecimals > 0 ? tDecimals : 6;
    }

    function raise(uint256 amount, uint key) internal view returns (uint256) {
        return amount * 10 ** getDecimals(key);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./CollateralWrapper.sol";
import "./../ISimpleStaking.sol";

abstract contract PresaleTax is CollateralWrapper {
    uint256 tax = 5;

    //Wallets of presales
    address private PreSalesOP;
    address private PreSalesMk;

    constructor(
        address _collateral,
        IECDSASignature2 _signature,
        IUAC _uac
    ) CollateralWrapper(_collateral, _signature, _uac) {
        PreSalesOP = 0x788B366fbb3C57dA08749c0253C175B51f04C6c5;
        PreSalesMk = 0x65d03f96B46701790Ba5E169423d4bE042016B01;
    }

    function _distributionPreSales(uint256 price) internal {
        uint256 amountDistribute = price / 2;
        _ctSign("TXPS_T_STEP_1");
        _collateralTransfer(PreSalesOP, amountDistribute);
        _ctSign("TXPS_T_STEP_2");
        _collateralTransfer(PreSalesMk, amountDistribute);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IECDSASignature2 {
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external;
    function signatureStatus(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external view returns(uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IUAC {
    function verifyUser(address user) external view;

    function verifyGameStatus(uint _panicLevel) external view;

    function verifyAll(address user, uint _panicLevel) external view;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

library ECDSALib {
    function hash(bytes memory encodePackedMsg) internal pure returns (bytes32) {
        return keccak256(encodePackedMsg);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./Interfaces/IECDSASignature2.sol";
import "./Interfaces/IUAC.sol";
import "./libs/ECDSALib.sol";

abstract contract Security2Base {
    IECDSASignature2 internal Signature;
    IUAC internal uac;

    constructor(IECDSASignature2 _signature, IUAC _uac) {
        Signature = _signature;
        uac = _uac;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract CriticalTracer is Ownable {
    string private trace;
    bool private enabled = false;

    function _ctMsg(string memory message) internal view returns (string memory) {
        if (!enabled) return message;
        return string.concat(message, "; ", trace);
    }

    function _ctSign(string memory sign) internal {
        trace = sign;
    }

    function setTracerStatus(bool enable) onlyOwner public {
        enabled = enable;
    }

    function getTracerStatus() public view returns (bool) {
        return enabled;
    }
}