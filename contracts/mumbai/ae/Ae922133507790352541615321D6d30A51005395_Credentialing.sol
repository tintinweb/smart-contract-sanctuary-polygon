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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
/*

  /$$$$$$                            /$$                       /$$     /$$           /$$ /$$                    
 /$$__  $$                          | $$                      | $$    |__/          | $$|__/                    
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$$  /$$$$$$   /$$  /$$$$$$ | $$ /$$ /$$$$$$$   /$$$$$$ 
| $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$__  $$|_  $$_/  | $$ |____  $$| $$| $$| $$__  $$ /$$__  $$
| $$      | $$  \__/| $$$$$$$$| $$  | $$| $$$$$$$$| $$  \ $$  | $$    | $$  /$$$$$$$| $$| $$| $$  \ $$| $$  \ $$
| $$    $$| $$      | $$_____/| $$  | $$| $$_____/| $$  | $$  | $$ /$$| $$ /$$__  $$| $$| $$| $$  | $$| $$  | $$
|  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$|  $$$$$$$| $$  | $$  |  $$$$/| $$|  $$$$$$$| $$| $$| $$  | $$|  $$$$$$$
 \______/ |__/       \_______/ \_______/ \_______/|__/  |__/   \___/  |__/ \_______/|__/|__/|__/  |__/ \____  $$
                                                                                                       /$$  \ $$
                                                                                                      |  $$$$$$/
                                                                                                       \______/

*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import './Registration.sol';

contract Credentialing is Ownable {

    /*
    It saves bytecode to revert on custom errors instead of using require
    statements. We are just declaring these errors for reverting with upon various
    conditions later in this contract. Thanks, Chiru Labs!
    */
    error DriverAddressIsNotLinkedToCoupon();    
    error DataNotAvailable();
    error NotAnAdmin();
    error SameDataAlreadyStored();
    error AccessNotGranted();
    error AlreadyLinked();

    // type - Address
    address[] private adminAddresses;
    address private registrationConc;

    // type - uint
    uint private Status_Success = 200;

    // type - Event
    event DataCredentialized(bytes32 indexed _unlockKey, address indexed _driver, uint indexed _status);
    event DataCredentialEdited(address indexed _driver, uint indexed _NoOfTimesEdited, uint indexed _status);

    // type - Mapping
    mapping(address => mapping(string => bool)) private storeCredentails;
    mapping(address => bool) private admins;
    mapping(address => CredentializeData) private allInfo;
    mapping(address => mapping(string => bool)) private whetherIpfsAndAddressLinked;
    mapping(address => bytes32) private unlockKey;
    mapping(address => mapping(bytes32 => bool)) private accessKey;
    mapping(address => bool) private accessForRead;
    mapping(address => mapping(uint256 => bool)) private linkLicenseNumberBool;
    mapping(address => uint256[]) private storeLicense;

    // type - Modifier
    modifier onlyAdmin () {
    if (_msgSender() != owner() && !admins[_msgSender()]) {
      revert NotAnAdmin();
    }
        _;
    }

    // type - Struct
    struct CredentializeData{
        address driverAddress;
        string[] ipfsURL;
        uint count;
    }

    /**
     * @notice Used for verification
     * @param _registrationContract - Pass the registration contract address
     */
    constructor(address _registrationContract) {
        registrationConc = _registrationContract;
    }

    /**
     * @notice admin can call this function to register a driver
     * @dev modifier onlyAdmin is used here. only one of the registered admins can call this function
     * @param _ad add address of admins to the contract.
     */
    function addAdmin(address _ad) external onlyAdmin{
        admins[_ad] = true;
        adminAddresses.push(_ad);
    }

    /**
     * @notice enter the credentialing details for the driver
     * @dev only one of the registered admins can call this function
     * @param _driverAddress - Pass the driver wallet address.
     * @param _licenseNumber - Pass the driver license number.
     * @param _ipfsUrl - Pass the ipfs url respective to the driver.
     */
    function credentialize(address _driverAddress, uint _licenseNumber, string memory _ipfsUrl) external onlyAdmin{
        Registration regDriver = Registration(registrationConc);
        require(regDriver.isDriverRegistered(_driverAddress), "The address is not registered in the registration contract");
        bytes32 packedData = keccak256(abi.encodePacked(_driverAddress));
        if(storeCredentails[_driverAddress][_ipfsUrl]){
            revert SameDataAlreadyStored();
        }
        if(linkLicenseNumberBool[_driverAddress][_licenseNumber]){
            revert AlreadyLinked();
        }
        allInfo[_driverAddress].driverAddress = _driverAddress;
        allInfo[_driverAddress].ipfsURL.push(_ipfsUrl);
        allInfo[_driverAddress].count += 1;
        storeCredentails[_driverAddress][_ipfsUrl] = true;
        whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl] = true;
        unlockKey[_driverAddress] = packedData;
        accessKey[_driverAddress][packedData] = true;
        storeLicense[_driverAddress].push(_licenseNumber);
        linkLicenseNumberBool[_driverAddress][_licenseNumber] = true;
        emit DataCredentialized(packedData, _driverAddress, Status_Success);
    }

    /**
     * editCredential - Edit the credential for the users.
     * @param _driverAddress - Enter the driver wallet address.
     * @param _ipfsUrl - Enter the new IPFS url. 
     */
    function editCredential(address _driverAddress, uint _licenseNumber, string memory _ipfsUrl) external onlyAdmin{
        Registration regDriver = Registration(registrationConc);
        require(regDriver.isDriverRegistered(_driverAddress), "The address is not registered in the registration contract");
        if(linkLicenseNumberBool[_driverAddress][_licenseNumber]){
            allInfo[_driverAddress].ipfsURL.push(_ipfsUrl);
            allInfo[_driverAddress].count += 1;
            whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl] = true;
            emit DataCredentialEdited(_driverAddress, allInfo[_driverAddress].count, Status_Success);
        }else{
            revert("Initial credentialize is not done");
        }
    }

    /**
     * getReadAccess - The driver is expected give access to read the URLS.
     * @param _driverAddress - Enter the driver address.
     */
    function getReadAccess(address _driverAddress) public returns(bool status){
        Registration regDriver = Registration(registrationConc);
        require(regDriver.isDriverRegistered(_driverAddress), "The address is not registered in the registration contract");
        require(msg.sender == _driverAddress);
        if(accessKey[_driverAddress][unlockKey[_driverAddress]]){
            accessForRead[msg.sender] = true;
            status = true;
            return status;
        }else{
            status = false;
            return status;
        }
    }

    /**
     * viewAllIpfsURL - If permission is granted then the user can view the IPFS urls.
     * @param _driverAddress - Enter the driver address.
     */
    function viewAllIpfsURL(address _driverAddress) public view returns(string[] memory allUrls){
        if(accessForRead[_driverAddress]){
            return allInfo[_driverAddress].ipfsURL;
        }else{
            revert ("Access not provided by the driver yet");
        }
    }
    
    /**
     * @notice returns the detailed struct of credentials
     * @param _driverAddress pass the bytes32 value from the event.
     */
    function viewCredentialAddedTimes(address _driverAddress) external view 
    returns( uint totalNumberOfTimesEdited){
        return allInfo[_driverAddress].count;
    }

    /**
     * whetherAddressAndIpfsLinked - Checks wether the address and ipfs is linked.
     * @param _driverAddress - Enter the driver wallet address.
     * @param _ipfsUrl - Pass the ipfs url respective to the driver.
     */
    function whetherAddressAndIpfsLinked(address _driverAddress, string memory _ipfsUrl) public view 
    returns (bool linked){
        if(whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl]){
            return true;
        }else{
            return false;
        }
    }

    /**
     * @notice showLicenseKey
     * @param _driverAddress - Enter the driver address to get the license key.
     */
    function showLicenseKey(address _driverAddress) external view returns(uint[] memory allAssociatedLicenseKeys){
        return storeLicense[_driverAddress];
    }

}

//SPDX-License-Identifier: MIT
/*
 _______                       __              __                          __      __                       ______                        __                                     __     
|       \                     |  \            |  \                        |  \    |  \                     /      \                      |  \                                   |  \    
| $$$$$$$\  ______    ______   \$$  _______  _| $$_     ______   ______  _| $$_    \$$  ______   _______  |  $$$$$$\  ______   _______  _| $$_     ______   ______    _______  _| $$_   
| $$__| $$ /      \  /      \ |  \ /       \|   $$ \   /      \ |      \|   $$ \  |  \ /      \ |       \ | $$   \$$ /      \ |       \|   $$ \   /      \ |      \  /       \|   $$ \  
| $$    $$|  $$$$$$\|  $$$$$$\| $$|  $$$$$$$ \$$$$$$  |  $$$$$$\ \$$$$$$\\$$$$$$  | $$|  $$$$$$\| $$$$$$$\| $$      |  $$$$$$\| $$$$$$$\\$$$$$$  |  $$$$$$\ \$$$$$$\|  $$$$$$$ \$$$$$$  
| $$$$$$$\| $$    $$| $$  | $$| $$ \$$    \   | $$ __ | $$   \$$/      $$ | $$ __ | $$| $$  | $$| $$  | $$| $$   __ | $$  | $$| $$  | $$ | $$ __ | $$   \$$/      $$| $$        | $$ __ 
| $$  | $$| $$$$$$$$| $$__| $$| $$ _\$$$$$$\  | $$|  \| $$     |  $$$$$$$ | $$|  \| $$| $$__/ $$| $$  | $$| $$__/  \| $$__/ $$| $$  | $$ | $$|  \| $$     |  $$$$$$$| $$_____   | $$|  \
| $$  | $$ \$$     \ \$$    $$| $$|       $$   \$$  $$| $$      \$$    $$  \$$  $$| $$ \$$    $$| $$  | $$ \$$    $$ \$$    $$| $$  | $$  \$$  $$| $$      \$$    $$ \$$     \   \$$  $$
 \$$   \$$  \$$$$$$$ _\$$$$$$$ \$$ \$$$$$$$     \$$$$  \$$       \$$$$$$$   \$$$$  \$$  \$$$$$$  \$$   \$$  \$$$$$$   \$$$$$$  \$$   \$$   \$$$$  \$$       \$$$$$$$  \$$$$$$$    \$$$$ 
                    |  \__| $$                                                                                                                                                          
                     \$$    $$                                                                                                                                                          
                      \$$$$$$                                                                                                                                                           
*/

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Registration is Ownable {

    // type - Address
    address[] private admins;
    address[] private users;

    // type - Uint
    uint constant private Status_Success = 200;

    // type - Event
    event DriverRegistered(address indexed _driverAddress, uint indexed _success);
    event AdminAdded(address indexed _address, uint indexed _success);
    
    // type - Mapping
    mapping(address => bool) private isAdmin;
    mapping(address => bool) private isRegisteredDriver;

    // type - Modifier
    modifier onlyAdmin(){
        require(isAdmin[msg.sender], "only an Admin can call this function!!");
        _;
    }

    constructor(){
        admins.push(msg.sender); // contract deployer is added as first admin
        isAdmin[msg.sender]=true; 
    }

    /**
     * @notice admin can call this function to register another wallet address as an extra admin
     * @dev modifier onlyAdmin is used here. only one of the registered admins can call this function
     * @param _newlyAddedAdmin address of the driver who is to be registered
     */
    function addAdmin(address _newlyAddedAdmin) external onlyAdmin {
        require(!isAdmin[_newlyAddedAdmin], "This address is already an Admin!!");
        admins.push(_newlyAddedAdmin);
        isAdmin[_newlyAddedAdmin] = true;
        emit AdminAdded(_newlyAddedAdmin, Status_Success);
    }
    
    /**
     * @notice admin can call this function to register a driver
     * @dev modifier onlyAdmin is used here. only one of the registered admins can call this function
     * @param _newDriver address of the driver who is to be registered
     */
    function registerDriver(address _newDriver) external onlyAdmin {
        require(!isRegisteredDriver[_newDriver],"This driver is already registered");
        users.push(_newDriver);
        isRegisteredDriver[_newDriver] = true;
        emit DriverRegistered(_newDriver, Status_Success);
    }

    /**
     * @notice checks if the input driver address is registered or not
     * @param _driverAddress address of the driver which is to be checked if registered or not
     * @return driverRegistrationStatus bool true if driver registered. false if not.
     */
    function isDriverRegistered(address _driverAddress) external view returns(bool driverRegistrationStatus) {
        return isRegisteredDriver[_driverAddress];
    }

    /**
     * @notice returns the address of all Drivers
     * @dev returns an address[]
     * @return allDrivers address array that contains address of all Drivers
     */
    function getAllDrivers() external view returns(address[] memory allDrivers){
        return users;
    }

    /**
     * @notice returns the address of all admins
     * @dev returns an address[]
     * @return allAdmins address array that contains address of all Admins
     */
    function getAllAdmins() external view returns(address[] memory allAdmins) {
        return admins;
    }

    /**
     *  @notice returns the total no of registered drivers
     *  @dev returns a uint256 value
     *  @return driversCount number of registered drivers
     */
    function getNoOfDrivers() external view returns (uint driversCount){
        return users.length;
    }
}