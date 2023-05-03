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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IManagers.sol";
import {TokenReward, ICrowdfunding} from "../interfaces/ICrowdfunding.sol";

/** TEST INFO
 * Ön koşul olarak;
* Main Vault, BotPrevention, Managers, CrowdfundingVault ve Crowdfunding contractları deploy edilmiştir. 
* Main Vault contract adresi managers contractına güvenilir olarak eklendikten sonra managers contractının sahipliği Main Vault contractına devredilmiştir.

 */
contract Crowdfunding is ERC165Storage, Ownable {
    struct Investor {
        uint256 totalAmount;
        uint256 vestingCount;
        uint256 currentVestingIndex;
        uint256 blacklistDate;
    }

    IManagers private managers;
    IERC20 public soulsToken;

    uint256 public totalCap;
    uint256 public totalRewardAmount;
    uint256 public totalClaimedAmount;

    address[] public investorList;
    address private crowdfundingVault;

    string public crowdfundingType;

    mapping(address => TokenReward[]) public tokenRewards;
    mapping(address => Investor) public investors;

    // Custom Errors
    error ReleaseDateIsBeforeAdvanceReleaseDate();
    error AdvanceReleaseDateIsInThePast();
    error TotalRewardExceedsTotalCap();
    error TotalCapCannotBeZero();
    error AddressIsBlacklisted();
    error InvestorAlreadyAdded();
    error RewardIsDeactivated();
    error RewardOwnerNotFound();
    error InvalidVestingIndex();
    error TokenTransferError();
    error AlreadyBlacklisted();
    error AlreadyDeactive();
    error AlreadyClaimed();
    error NotBlacklisted();
    error AlreadyActive();
    error OnlyManagers();
    error EarlyRequest();
    error ZeroAddress();
    error InvalidData();

    //Events
    event AddRewards(
        address manager,
        address[] rewardOwners,
        uint256[] advanceAmountPerAddress,
        uint256[] totalOfVestings,
        uint256 vestingCount,
        uint256 advanceReleaseDate,
        uint256 vestingStartDate,
        address tokenHolder,
        bool isApproved
    );
    event DeactivateVesting(
        address manager,
        address rewardOwner,
        uint8[] vestingIndexes,
        address tokenReceiver,
        string description,
        bool isApproved
    );
    event ActivateVesting(
        address manager,
        address rewardOwner,
        uint8[] vestingIndexes,
        address tokenReceiver,
        string description,
        bool isApproved
    );
    event AddToBlacklist(
        address manager,
        address rewardOwner,
        address tokenReceiver,
        string description,
        bool isApproved
    );
    event RemoveFromBlacklist(
        address manager,
        address rewardOwner,
        address tokenReceiver,
        string description,
        bool isApproved
    );

    event Claim(address rewardOwner, uint256 vestingIndex, uint256 amount);

    constructor(
        string memory _CrowdfundingType,
        uint256 _totalCap,
        address _soulsTokenAddress,
        address _managersAddress
    ) {
        if (_totalCap == 0) {
            revert TotalCapCannotBeZero();
        }
        if (_soulsTokenAddress == address(0) || _managersAddress == address(0)) {
            revert ZeroAddress();
        }
        crowdfundingType = _CrowdfundingType;
        soulsToken = IERC20(_soulsTokenAddress);
        managers = IManagers(_managersAddress);
        totalCap = _totalCap;
        _registerInterface(type(ICrowdfunding).interfaceId);
    }

    //Modifiers
    modifier ifNotBlacklisted(uint256 _time) {
        if (isInBlacklist(msg.sender, _time)) {
            revert AddressIsBlacklisted();
        }
        _;
    }

    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert OnlyManagers();
        }
        _;
    }

    //Write functions

    //Managers function
    function addRewards(
        address[] memory _rewardOwners,
        uint256[] memory _advanceAmountPerAddress,
        uint256[] memory _totalOfVestings, //excluding advance amount
        uint256 _vestingCount, // excluding advance payment
        uint256 _advanceReleaseDate,
        uint256 _vestingStartDate,
        address _crowdfundingVault
    ) external onlyManager {
        if (
            _rewardOwners.length != _advanceAmountPerAddress.length || _rewardOwners.length != _totalOfVestings.length
        ) {
            revert InvalidData();
        }

        if (_advanceReleaseDate < block.timestamp) {
            revert AdvanceReleaseDateIsInThePast();
        }
        if (_vestingCount > 0 && _vestingStartDate <= _advanceReleaseDate) {
            revert ReleaseDateIsBeforeAdvanceReleaseDate();
        }

        uint256 _totalAmount = 0;
        for (uint256 r = 0; r < _rewardOwners.length; r++) {
            address _rewardOwner = _rewardOwners[r];
            if (investors[_rewardOwner].totalAmount > 0) {
                revert InvestorAlreadyAdded();
            }
            if (isInBlacklist(_rewardOwner, block.timestamp)) {
                revert AddressIsBlacklisted();
            }
            uint256 _investorTotalAmount = _advanceAmountPerAddress[r] + _totalOfVestings[r];
            _totalAmount += _investorTotalAmount;
        }

        if (totalRewardAmount + _totalAmount > totalCap) {
            revert TotalRewardExceedsTotalCap();
        }

        string memory _title = "Add New Rewards";
        bytes memory _encodedValues = abi.encode(
            _rewardOwners,
            _advanceAmountPerAddress,
            _totalOfVestings,
            _vestingCount,
            _advanceReleaseDate,
            _vestingStartDate,
            _crowdfundingVault
        );

        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            _addRewards(
                _rewardOwners,
                _advanceAmountPerAddress,
                _totalOfVestings,
                _vestingCount,
                _advanceReleaseDate,
                _vestingStartDate,
                _crowdfundingVault
            );

            managers.deleteTopic(_title);
            if (crowdfundingVault == address(0)) {
                crowdfundingVault = _crowdfundingVault;
            }
        }
        emit AddRewards(
            msg.sender,
            _rewardOwners,
            _advanceAmountPerAddress,
            _totalOfVestings,
            _vestingCount,
            _advanceReleaseDate,
            _vestingStartDate,
            _crowdfundingVault,
            _isApproved
        );
    }

    function _addRewards(
        address[] memory _rewardOwners,
        uint256[] memory _advanceAmountPerAddress,
        uint256[] memory _totalOfVestings, //excluding advance amount
        uint256 _vestingCount, // excluding advance payment
        uint256 _advanceReleaseDate,
        uint256 _vestingStartDate,
        address _crowdfundingVault
    ) private {
        uint256 _totalAmount = 0;
        for (uint256 r = 0; r < _rewardOwners.length; r++) {
            address _rewardOwner = _rewardOwners[r];
            uint256 _advanceAmount = _advanceAmountPerAddress[r];
            uint256 _investorTotalAmount = _advanceAmount;

            if (_advanceAmount > 0) {
                tokenRewards[_rewardOwner].push(
                    TokenReward({
                        amount: _advanceAmount,
                        releaseDate: _advanceReleaseDate,
                        isClaimed: false,
                        isActive: true
                    })
                );
            }

            for (uint256 i = 0; i < _vestingCount; i++) {
                uint256 _vestingAmount;
                if (i == _vestingCount - 1) {
                    _vestingAmount = (_advanceAmount + _totalOfVestings[r]) - _investorTotalAmount;
                } else {
                    _vestingAmount = _totalOfVestings[r] / _vestingCount;
                }
                tokenRewards[_rewardOwner].push(
                    TokenReward({
                        amount: _vestingAmount,
                        releaseDate: _vestingStartDate + (30 days * i),
                        isClaimed: false,
                        isActive: true
                    })
                );
                _investorTotalAmount += _vestingAmount;
            }
            _totalAmount += _investorTotalAmount;

            investors[_rewardOwner] = Investor({
                totalAmount: _investorTotalAmount,
                vestingCount: _advanceAmount > 0 ? (_vestingCount + 1) : _vestingCount,
                currentVestingIndex: 0,
                blacklistDate: 0
            });
            investorList.push(_rewardOwner);
        }

        totalRewardAmount += _totalAmount;
        require(soulsToken.transferFrom(_crowdfundingVault, address(this), _totalAmount));
    }

    //Managers Function
    function deactivateInvestorVesting(
        address _rewardOwner,
        uint8[] calldata _vestingIndexes,
        string calldata _description
    ) external onlyManager {
        if (_rewardOwner == address(0)) revert ZeroAddress();
        if (tokenRewards[_rewardOwner].length == 0) revert RewardOwnerNotFound();

        string memory _vestingsToDeactivate;
        for (uint256 i = 0; i < _vestingIndexes.length; i++) {
            if (_vestingIndexes[i] >= investors[_rewardOwner].vestingCount) revert InvalidVestingIndex();
            if (tokenRewards[_rewardOwner][_vestingIndexes[i]].isClaimed) revert AlreadyClaimed();
            if (!tokenRewards[_rewardOwner][_vestingIndexes[i]].isActive) revert AlreadyDeactive();

            _vestingsToDeactivate = string.concat(_vestingsToDeactivate, Strings.toString(_vestingIndexes[i]));
            if (i < _vestingIndexes.length - 1) {
                _vestingsToDeactivate = string.concat(_vestingsToDeactivate, ", ");
            }
        }

        string memory _title = string.concat(
            "Deactivate Investor (",
            Strings.toHexString(_rewardOwner),
            ") Vesting (",
            _vestingsToDeactivate,
            ")"
        );
        bytes memory _encodedValues = abi.encode(_rewardOwner, _vestingIndexes, _description);

        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            uint256 _totalAmountToDeactivate;
            for (uint256 i = 0; i < _vestingIndexes.length; i++) {
                tokenRewards[_rewardOwner][_vestingIndexes[i]].isActive = false;
                _totalAmountToDeactivate += tokenRewards[_rewardOwner][_vestingIndexes[i]].amount;
            }
            if (!soulsToken.transfer(crowdfundingVault, _totalAmountToDeactivate)) {
                revert TokenTransferError();
            }
            totalRewardAmount -= _totalAmountToDeactivate;

            managers.deleteTopic(_title);
        }
        emit DeactivateVesting(msg.sender, _rewardOwner, _vestingIndexes, crowdfundingVault, _description, _isApproved);
    }

    //Managers Function
    function activateInvestorVesting(
        address _rewardOwner,
        uint8[] calldata _vestingIndexes,
        string calldata _description
    ) external onlyManager {
        if (_rewardOwner == address(0)) {
            revert ZeroAddress();
        }
        if (tokenRewards[_rewardOwner].length == 0) {
            revert RewardOwnerNotFound();
        }

        string memory _vestingsToActivate;
        for (uint256 i = 0; i < _vestingIndexes.length; i++) {
            if (_vestingIndexes[i] >= investors[_rewardOwner].vestingCount) {
                revert InvalidVestingIndex();
            }
            if (tokenRewards[_rewardOwner][_vestingIndexes[i]].isActive) {
                revert AlreadyActive();
            }
            _vestingsToActivate = string.concat(_vestingsToActivate, Strings.toString(_vestingIndexes[i]));
            if (i < _vestingIndexes.length - 1) {
                _vestingsToActivate = string.concat(_vestingsToActivate, ", ");
            }
        }

        string memory _title = string.concat(
            "Activate Investor (",
            Strings.toHexString(_rewardOwner),
            ") Vesting (",
            _vestingsToActivate,
            ")"
        );

        bytes memory _encodedValues = abi.encode(_rewardOwner, _vestingIndexes, _description);

        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            uint256 _totalAmountToActivate;
            for (uint256 i = 0; i < _vestingIndexes.length; i++) {
                tokenRewards[_rewardOwner][_vestingIndexes[i]].isActive = true;
                _totalAmountToActivate += tokenRewards[_rewardOwner][_vestingIndexes[i]].amount;
            }
            if (!soulsToken.transferFrom(crowdfundingVault, address(this), _totalAmountToActivate))
                revert TokenTransferError();
            totalRewardAmount += _totalAmountToActivate;

            managers.deleteTopic(_title);
        }
        emit ActivateVesting(msg.sender, _rewardOwner, _vestingIndexes, crowdfundingVault, _description, _isApproved);
    }

    //Managers Function
    function addToBlacklist(address _rewardOwner, string calldata _description) external onlyManager {
        if (_rewardOwner == address(0)) revert ZeroAddress();
        if (tokenRewards[_rewardOwner].length == 0) revert RewardOwnerNotFound();
        if (isInBlacklist(_rewardOwner, block.timestamp)) revert AlreadyBlacklisted();

        string memory _title = string.concat("Add To Blacklist (", Strings.toHexString(_rewardOwner), ")");

        bytes memory _encodedValues = abi.encode(_rewardOwner, _description);

        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            uint256 _remainingAmount = 0;
            for (uint256 i = 0; i < tokenRewards[_rewardOwner].length; i++) {
                if (tokenRewards[_rewardOwner][i].releaseDate > block.timestamp) {
                    _remainingAmount += tokenRewards[_rewardOwner][i].amount;
                    totalRewardAmount -= tokenRewards[_rewardOwner][i].amount;
                }
            }
            if (!soulsToken.transfer(crowdfundingVault, _remainingAmount)) {
                revert TokenTransferError();
            }
            investors[_rewardOwner].blacklistDate = block.timestamp;
            managers.deleteTopic(_title);
        }
        emit AddToBlacklist(msg.sender, _rewardOwner, crowdfundingVault, _description, _isApproved);
    }

    //Managers Function
    function removeFromBlacklist(address _rewardOwner, string calldata _description) external onlyManager {
        if (_rewardOwner == address(0)) revert ZeroAddress();
        if (!isInBlacklist(_rewardOwner, block.timestamp)) revert NotBlacklisted();

        string memory _title = string.concat("Remove From Blacklist (", Strings.toHexString(_rewardOwner), ")");
        bytes memory _encodedValues = abi.encode(_rewardOwner, _description);
        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            uint256 _requiredAmount;
            for (uint256 i = 0; i < tokenRewards[_rewardOwner].length; i++) {
                if (tokenRewards[_rewardOwner][i].releaseDate > investors[_rewardOwner].blacklistDate) {
                    _requiredAmount += tokenRewards[_rewardOwner][i].amount;
                    totalRewardAmount += tokenRewards[_rewardOwner][i].amount;
                }
            }
            if (!soulsToken.transferFrom(crowdfundingVault, address(this), _requiredAmount)) {
                revert TokenTransferError();
            }
            investors[_rewardOwner].blacklistDate = 0;
            managers.deleteTopic(_title);
        }
        emit RemoveFromBlacklist(msg.sender, _rewardOwner, crowdfundingVault, _description, _isApproved);
    }

    function claimTokens(
        uint8 _vestingIndex
    ) public ifNotBlacklisted(tokenRewards[msg.sender][_vestingIndex].releaseDate) {
        require(_vestingIndex == investors[msg.sender].currentVestingIndex);
        if (tokenRewards[msg.sender][_vestingIndex].releaseDate > block.timestamp) {
            revert EarlyRequest();
        }

        if (tokenRewards[msg.sender][_vestingIndex].isClaimed) {
            revert AlreadyClaimed();
        }
        if (!tokenRewards[msg.sender][_vestingIndex].isActive) {
            revert RewardIsDeactivated();
        }
        tokenRewards[msg.sender][_vestingIndex].isClaimed = true;
        investors[msg.sender].currentVestingIndex++;
        totalClaimedAmount += tokenRewards[msg.sender][_vestingIndex].amount;
        if (!soulsToken.transfer(msg.sender, tokenRewards[msg.sender][_vestingIndex].amount)) {
            revert TokenTransferError();
        }
        emit Claim(msg.sender, _vestingIndex, tokenRewards[msg.sender][_vestingIndex].amount);
    }

    //Read Functions
    function getAllVestingInfoForAccount(address _rewardOwner) public view returns (TokenReward[] memory) {
        return tokenRewards[_rewardOwner];
    }

    function getVestingInfoForAccount(
        address _rewardOwner,
        uint8 _vestingIndex
    ) public view returns (TokenReward memory) {
        return tokenRewards[_rewardOwner][_vestingIndex];
    }

    function getInvestorList() public view returns (address[] memory) {
        return investorList;
    }

    function isInBlacklist(address _address, uint256 _time) public view returns (bool) {
        return investors[_address].blacklistDate != 0 && investors[_address].blacklistDate < _time;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct TokenReward {
    uint256 amount;
    uint256 releaseDate;
    bool isClaimed;
    bool isActive;
}

interface ICrowdfunding {
    function addRewards(
        address[] memory _rewardOwners,
        uint256[] memory _advancePayments,
        uint256[] memory _amountsPerVesting,
        uint8[] memory _numberOfVestings,
        uint256 _releaseDate,
        address _tokenHolder
    ) external;

    function claimTokens(uint8 _vestingIndex) external;

    function deactivateInvestorVesting(
        address _rewardOwner,
        uint8 _vestingIndex,
        address _tokenReceiver
    ) external;

    function activateInvestorVesting(
        address _rewardOwner,
        uint8 _vestingIndex,
        address _tokenSource
    ) external;

    function addToBlacklist(address _rewardOwner, address _tokenReceiver) external;

    function removeFromBlacklist(address _rewardOwner, address _tokenSource) external;

    function fetchRewardsInfo(uint8 _vestingIndex) external view returns (TokenReward memory);

    function fetchRewardsInfoForAccount(address _rewardOwner, uint8 _vestingIndex)
        external
        view
        returns (TokenReward memory);

    function isInBlacklist(address _address, uint256 _time) external view returns (bool);

    function getTotalBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function addAddressToTrustedSources(address _address, string memory _name) external;
}