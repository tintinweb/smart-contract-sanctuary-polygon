// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ISupportReciever {
    function onSubscribed(
        address user,
        address token,
        uint256 currentAmount
    ) external payable;

    function onRenewed(address user) external payable;

    function onUnsubscribed(address user) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @title Implements efficient safe methods for ERC20 interface.
 * @notice Compared to the standard ERC20, this implementation offers several enhancements:
 * 1. more gas-efficient, providing significant savings in transaction costs.
 * 2. support for different permit implementations
 * 3. forceApprove functionality
 * 4. support for WETH deposit and withdraw
 */
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();
    error Permit2TransferAmountTooHigh();

    /**
     * @notice Fetches the balance of a specific ERC20 token held by an account.
     * Consumes less gas then regular `ERC20.balanceOf`.
     * @param token The IERC20 token contract for which the balance will be fetched.
     * @param account The address of the account whose token balance will be fetched.
     * @return tokenBalance The balance of the specified ERC20 token held by the account.
     */
    function safeBalanceOf(
        IERC20 token,
        address account
    ) internal view returns (uint256 tokenBalance) {
        bytes4 selector = IERC20.balanceOf.selector;
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            mstore(0x00, selector)
            mstore(0x04, account)
            let success := staticcall(gas(), token, 0x00, 0x24, 0x00, 0x20)
            tokenBalance := mload(0)

            if or(iszero(success), lt(returndatasize(), 0x20)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /**
     * @notice Attempts to safely transfer tokens from one address to another using the ERC20 standard.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /**
     * @notice Attempts to safely transfer tokens to another address.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param value The amount of tokens to transfer.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /**
     * @notice Attempts to approve a spender to spend a certain amount of tokens.
     * @dev If `approve(from, to, amount)` fails, it tries to set the allowance to zero, and retries the `approve` call.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /**
     * @notice Safely increases the allowance of a spender.
     * @dev Increases with safe math check. Checks if the increased allowance will overflow, if yes, then it reverts the transaction.
     * Then uses `forceApprove` to increase the allowance.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance)
            revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /**
     * @notice Safely decreases the allowance of a spender.
     * @dev Decreases with safe math check. Checks if the decreased allowance will underflow, if yes, then it reverts the transaction.
     * Then uses `forceApprove` to increase the allowance.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    /**
     * @dev Executes a low level call to a token contract, making it resistant to reversion and erroneous boolean returns.
     * @param token The IERC20 token contract on which the call will be made.
     * @param selector The function signature that is to be called on the token contract.
     * @param to The address to which the token amount will be transferred.
     * @param amount The token amount to be transferred.
     * @return success A boolean indicating if the call was successful. Returns 'true' on success and 'false' on failure.
     * In case of success but no returned data, validates that the contract code exists.
     * In case of returned data, ensures that it's a boolean `true`.
     */
    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

contract NextDate {
    uint256 constant DENOMINATOR = 10_000;

    /**
     * @dev parse timestamp & get service params for calculations
     */
    function getDaysFromTimestamp(
        uint256 timestamp
    )
        internal
        pure
        returns (uint256 yearStartDay, uint256 dayOfYear, uint256 yearsFrom1972)
    {
        // get number of days from 01.01.1970
        uint256 daysFrom0 = timestamp / 86_400;

        // get number of full years from `01.01.1970 + 730 days = 01.01.1972` (first leap year from 1970)
        // 1461 days = number of days in one leap cycle 365 + 365 + 365 + 366
        yearsFrom1972 =
            ((((daysFrom0 - 730) * DENOMINATOR) / 1461) * 4) /
            DENOMINATOR;

        // subtract 1 year from yearsFrom1972 (so 0 year = 01.01.1973) and add 1096 days (= 366 + 365 + 365 days), so 0 years is 01.01.1970 and we can get 0 day of the current year
        yearStartDay = ((((yearsFrom1972 - 1) * 1461) / 4) + 1096);

        dayOfYear = daysFrom0 - yearStartDay + 1;
    }

    /**
     * @dev get timestamp for the first day of the next month
     */
    function getStartOfNextMonth(
        uint256 timestamp
    ) public pure returns (uint256) {
        (
            uint256 yearStartDay,
            uint256 dayOfYear,
            uint256 yearsFrom1972
        ) = getDaysFromTimestamp(timestamp);

        uint16[13] memory monthsSums = yearsFrom1972 % 4 == 0
            ? [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]
            : [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];

        uint8 low = 0;
        uint8 high = 12;
        while (true) {
            uint8 mid = (low + high) / 2;

            if (high - low == 1)
                return (yearStartDay + uint256(monthsSums[high])) * 86_400;

            if (dayOfYear > monthsSums[mid]) low = mid;
            else high = mid;
        }

        return 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./NextDate.sol";
import "./erc20/SafeERC20.sol";

import "./addons/ISupportReciever.sol";

/**
 * @title SupportClub
 * @dev This contract allows to sign up for monthly payments in ERC20 tokens to any address. User can subscribe in any token from `paymentTokens` array, in any amount, but not less than the minimum value `minAmount * 10**minAmountDecimals`. On the first day of each month, the sums donated to recipient (=club owner) via subscriptions become eligible for collection and renewal by {renewClubsSubscriptions} & {renewClubsSubscriptionsWRefund} methods.
 */
contract SupportClub is Ownable, NextDate {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    /**
     * @dev `amount` & `amountDecimals` are used to reduce Subscription struct storage size,
     * total subscription amount = `amount * (10**amountDecimals)`
     */
    struct Subscription {
        uint128 idx;
        uint32 amount;
        uint8 amountDecimals;
        uint16 tokenIndex;
        uint8 lastRenewRound;
        uint8 subscriptionRound;
    }
    struct RenewRound {
        uint32 startsAt;
        uint8 id;
    }
    struct PaymentToken {
        address address_;
        uint16 minAmount;
        uint8 minAmountDecimals;
    }

    /**
    * @dev
     `refundForbidden` – a clubOwner can disable the renewal of club subscriptions with {renewClubsSubscriptionsWRefund} method
     `isSupportReciever` – whether the clubOwner is a SupportReciever-compatible contract
     */
    struct ClubData {
        uint128 nextSubscriptionIdx;
        uint96 id;
        bool refundForbidden;
        bool isSupportReciever;
    }

    /**
     * @dev clubOwner => (user => Subscription)
     */
    mapping(address => mapping(address => Subscription)) public subscriptionTo;
    /**
     * @dev clubOwner => (subscriberIndex => user)
     */
    mapping(address => mapping(uint128 => address)) public subscriberOf;
    /**
     * @dev user: clubId[]
     */
    mapping(address => uint128[]) public userSubscriptions;

    PaymentToken[10_000] public paymentTokens;
    uint256 public totalPaymentTokens;
    RenewRound public renewRound;
    address[] public clubOwners;
    mapping(address => ClubData) public clubs;

    uint256 constant MAX_REFUND_FEE = 1500; // 15%
    /**
     * @dev if `true` {subscribe} method will store extra data about subsciption for easy data querying;
     * `true` for all chains except Ethereum mainnet since its high gas cost for using extra storage
     */
    bool public immutable storeExtraData;

    error SubscriptionNotExpired();
    error InvalidParams();
    error Forbidden();
    error NotSubscribed();
    event Subscribed(address indexed clubOwner, address indexed user);
    event SubscriptionsRenewed(
        address indexed clubOwner,
        uint256 indexed subscriptionsCount
    );
    event SubscriptionBurned(address indexed clubOwner, address indexed user);
    event SetIsSupportReciever(address clubOwner);
    event SetRefundForbidden(bool refundForbidden);

    constructor(bool _storeExtraData) {
        storeExtraData = _storeExtraData;
        getActualRound();
        clubOwners.push(address(0));
    }

    function totalClubs() external view returns (uint256) {
        return clubOwners.length - 1;
    }

    function userSubscriptionsCount(
        address user
    ) external view returns (uint256) {
        return userSubscriptions[user].length;
    }

    function subscriptionsCount(
        address clubOwner
    ) external view returns (uint128) {
        uint128 nextId = clubs[clubOwner].nextSubscriptionIdx;

        if (nextId == 0) return 0;
        return nextId - 1;
    }

    function subscribe(
        address clubOwner,
        uint16 tokenIndex,
        uint32 amount,
        uint8 amountDecimals,
        uint256 currentAmount
    ) external payable {
        if (
            subscriptionTo[clubOwner][msg.sender].amount != 0 ||
            msg.sender == clubOwner
        ) revert Forbidden();

        RenewRound memory _renewRound = getActualRound();

        if (clubs[clubOwner].nextSubscriptionIdx == 0) _initClub(clubOwner);

        uint128 subIdx;
        if (storeExtraData) {
            subIdx = clubs[clubOwner].nextSubscriptionIdx++;

            subscriberOf[clubOwner][subIdx] = msg.sender;
            userSubscriptions[msg.sender].push(clubs[clubOwner].id);
        }
        subscriptionTo[clubOwner][msg.sender] = Subscription({
            idx: subIdx,
            amount: amount,
            amountDecimals: amountDecimals,
            tokenIndex: tokenIndex,
            lastRenewRound: 0,
            subscriptionRound: _renewRound.id
        });

        PaymentToken memory paymentToken = paymentTokens[tokenIndex];

        uint256 totalAmount = amount * (10 ** amountDecimals);
        uint256 minAmount = paymentToken.minAmount *
            (10 ** paymentToken.minAmountDecimals);

        if (
            totalAmount < minAmount ||
            currentAmount < minAmount ||
            currentAmount > totalAmount
        ) revert InvalidParams();

        IERC20(paymentToken.address_).safeTransferFrom(
            msg.sender,
            clubOwner,
            currentAmount
        );

        if (clubs[clubOwner].isSupportReciever) {
            ISupportReciever(clubOwner).onSubscribed{value: msg.value}(
                msg.sender,
                paymentToken.address_,
                currentAmount
            );
        }
        emit Subscribed(clubOwner, msg.sender);
    }

    function initClub(address clubOwner) external {
        require(
            clubs[clubOwner].nextSubscriptionIdx == 0,
            "Already initialized"
        );
        _initClub(clubOwner);
    }

    function setIsSupportReciever(address clubOwner) external {
        if (clubOwner.code.length > 0) {
            clubs[clubOwner].isSupportReciever = clubOwner
                .supportsERC165InterfaceUnchecked(
                    type(ISupportReciever).interfaceId
                );

            emit SetIsSupportReciever(clubOwner);
        }
    }

    function setRefundForbidden(bool refundForbidden) external {
        clubs[msg.sender].refundForbidden = refundForbidden;

        emit SetRefundForbidden(refundForbidden);
    }

    function addPaymentTokens(
        PaymentToken[] calldata erc20Tokens
    ) external payable onlyOwner {
        for (uint256 i = totalPaymentTokens; i < erc20Tokens.length; ++i) {
            PaymentToken calldata erc20Token = erc20Tokens[i];

            paymentTokens[i] = (
                PaymentToken({
                    address_: erc20Token.address_,
                    minAmount: erc20Token.minAmount,
                    minAmountDecimals: erc20Token.minAmountDecimals
                })
            );
        }
        totalPaymentTokens += erc20Tokens.length;
    }

    function setMinAmounts(
        uint256[] calldata indexes,
        PaymentToken[] calldata erc20Tokens
    ) external payable onlyOwner {
        uint256 totalPaymentTokens_ = totalPaymentTokens;
        for (uint256 i; i < erc20Tokens.length; ++i) {
            uint256 index = indexes[i];
            require(index < totalPaymentTokens_, "Invalid index");
            PaymentToken calldata erc20Token = erc20Tokens[i];

            paymentTokens[index].minAmount = erc20Token.minAmount;
            paymentTokens[index].minAmountDecimals = erc20Token
                .minAmountDecimals;
        }
    }

    function getActualRound() public returns (RenewRound memory) {
        RenewRound memory renewRound_ = renewRound;
        if (renewRound_.startsAt < block.timestamp) {
            uint32 nextRoundStartsAt = uint32(
                getStartOfNextMonth(block.timestamp)
            ); // create new round

            renewRound_.id += renewRound_.startsAt != 0
                ? uint8((nextRoundStartsAt - renewRound_.startsAt) / 28 days)
                : 1;
            renewRound_.startsAt = nextRoundStartsAt;

            renewRound = renewRound_;
            return renewRound_;
        }
        return renewRound_;
    }

    function burnSubscription(
        address user,
        address clubOwner,
        uint256 userSubscriptionIndex
    ) external {
        if (msg.sender != user && msg.sender != owner()) revert Forbidden();

        Subscription memory subscription = subscriptionTo[clubOwner][user];
        if (subscription.amount == 0) revert NotSubscribed();

        if (storeExtraData) {
            if (
                userSubscriptions[user][userSubscriptionIndex] !=
                clubs[clubOwner].id
            ) revert InvalidParams();

            uint128 subscriberIdx = subscription.idx;

            uint128 lastSubIdx = clubs[clubOwner].nextSubscriptionIdx - 1;
            if (subscriberIdx != lastSubIdx) {
                address lastSubscriptionUser = subscriberOf[clubOwner][
                    lastSubIdx
                ];

                subscriptionTo[clubOwner][lastSubscriptionUser]
                    .idx = subscriberIdx;

                subscriberOf[clubOwner][subscriberIdx] = lastSubscriptionUser;
            }

            delete subscriberOf[clubOwner][lastSubIdx];

            uint256 lastUserSubscriptionIndex = userSubscriptions[user].length -
                1;
            if (userSubscriptionIndex != lastUserSubscriptionIndex) {
                userSubscriptions[user][
                    userSubscriptionIndex
                ] = userSubscriptions[user][lastUserSubscriptionIndex];
            }
            userSubscriptions[user].pop();

            clubs[clubOwner].nextSubscriptionIdx--;
        }
        delete subscriptionTo[clubOwner][user];

        if (clubs[clubOwner].isSupportReciever) {
            /**
             * @dev ignore {SupportReciever.onUnsubscribed} method failing
             */
            clubOwner.call(
                abi.encodeWithSelector(
                    ISupportReciever.onUnsubscribed.selector,
                    user
                )
            );
        }
        emit SubscriptionBurned(clubOwner, user);
    }

    function renewClubsSubscriptions(
        address[] calldata _clubOwners,
        address[][] calldata _subscribers
    ) external {
        if (_clubOwners.length != _subscribers.length) revert Forbidden();
        uint8 renewRoundId = getActualRound().id;

        for (uint i = 0; i < _clubOwners.length; i++) {
            address clubOwner = _clubOwners[i];
            address[] calldata clubSubscribers = _subscribers[i];

            bool isSupportReciever = clubs[clubOwner].isSupportReciever;
            for (uint256 index; index < clubSubscribers.length; ++index) {
                _renewSubscription(
                    clubOwner,
                    clubSubscribers[index],
                    renewRoundId
                );
                if (isSupportReciever)
                    ISupportReciever(clubOwner).onRenewed(
                        clubSubscribers[index]
                    );
            }
            emit SubscriptionsRenewed(clubOwner, clubSubscribers.length);
        }
    }

    function renewClubsSubscriptionsWRefund(
        address[] calldata _clubOwners,
        address[][] calldata _subscribers,
        uint8 tokenIndex,
        uint256 refundFeePerSub,
        address refundRecipient
    ) external onlyOwner {
        if (_clubOwners.length != _subscribers.length) revert Forbidden();
        uint8 renewRoundId = getActualRound().id;

        uint256 totalRefundAmount;

        address tokenAddress = paymentTokens[tokenIndex].address_;
        for (uint i = 0; i < _clubOwners.length; i++) {
            address clubOwner = _clubOwners[i];
            if (clubs[clubOwner].refundForbidden) revert Forbidden();

            bool isSupportReciever = clubs[clubOwner].isSupportReciever;
            address[] calldata clubSubscribers = _subscribers[i];

            uint256 amountForClub;
            for (uint256 index; index < clubSubscribers.length; ++index) {
                Subscription memory subscription = subscriptionTo[clubOwner][
                    clubSubscribers[index]
                ];
                if (subscription.tokenIndex != tokenIndex)
                    revert InvalidParams();

                amountForClub += _renewSubscriptionWRefund(
                    subscription,
                    clubOwner,
                    clubSubscribers[index],
                    tokenAddress,
                    renewRoundId
                );

                if (isSupportReciever)
                    ISupportReciever(clubOwner).onRenewed(
                        clubSubscribers[index]
                    );
            }

            uint256 refundFromClub = clubSubscribers.length * refundFeePerSub;
            if (refundFromClub > (amountForClub * MAX_REFUND_FEE) / DENOMINATOR)
                revert Forbidden(); // max 15% fee
            IERC20(tokenAddress).safeTransfer(
                clubOwner,
                amountForClub - refundFromClub
            );

            totalRefundAmount += refundFromClub;
        }

        IERC20(tokenAddress).safeTransfer(refundRecipient, totalRefundAmount);
    }

    function _renewSubscription(
        address clubOwner,
        address subscriber,
        uint8 renewRoundId
    ) internal {
        Subscription memory subscription = subscriptionTo[clubOwner][
            subscriber
        ];
        if (subscription.amount == 0) revert InvalidParams();

        uint8 lastRenewRound = subscription.lastRenewRound;
        if (lastRenewRound == 0)
            lastRenewRound = subscription.subscriptionRound;
        if (lastRenewRound == renewRoundId) revert SubscriptionNotExpired();

        subscriptionTo[clubOwner][subscriber].lastRenewRound = renewRoundId;

        uint16 tokenIndex = subscription.tokenIndex;

        IERC20(paymentTokens[tokenIndex].address_).safeTransferFrom(
            subscriber,
            clubOwner,
            (subscription.amount * (renewRoundId - lastRenewRound)) *
                (10 ** subscription.amountDecimals) // (amount * non-renewed periods) * decimals
        );
    }

    function _renewSubscriptionWRefund(
        Subscription memory subscription,
        address clubOwner,
        address subscriber,
        address token,
        uint8 renewRoundId
    ) internal returns (uint256) {
        if (subscription.amount == 0) revert InvalidParams();

        uint8 lastRenewRound = subscription.lastRenewRound;
        if (lastRenewRound == 0)
            lastRenewRound = subscription.subscriptionRound;
        if (lastRenewRound == renewRoundId) revert SubscriptionNotExpired();

        subscriptionTo[clubOwner][subscriber].lastRenewRound = renewRoundId;

        uint256 fullAmount = (subscription.amount *
            (renewRoundId - lastRenewRound)) *
            (10 ** subscription.amountDecimals); // (amount * non-renewed periods) * decimals
        IERC20(token).safeTransferFrom(subscriber, address(this), fullAmount);

        return fullAmount;
    }

    function _initClub(address clubOwner) internal {
        ++clubs[clubOwner].nextSubscriptionIdx;
        if (clubOwner.code.length > 0) {
            clubs[clubOwner].isSupportReciever = clubOwner
                .supportsERC165InterfaceUnchecked(
                    type(ISupportReciever).interfaceId
                );
        }
        if (storeExtraData) {
            clubs[clubOwner].id = uint96(clubOwners.length);
            clubOwners.push(clubOwner);
        }
    }
}