/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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


// File contracts/DocumentsManager/Interface/IDocumentsManager.sol


pragma solidity ^0.8.17;

/**
 * @title IDocumentsManager
 * @author Polytrade
 */
interface IDocumentsManager {
    /**
     * @notice Emits when staking strategy is switched
     * @dev Emits when {setIdManager} is called by the owner
     * @param oldManager is the address of the new id manager
     * @param newManager is the address of the old id manager
     */
    event IdManagerChanged(address oldManager, address newManager);

    /**
     * @notice Emits when a document is added
     * @dev Emits when {addDoc} is called by an organization
     * @param polytradeId is the Id assigned to an organization
     * @param docId is the Id assigned to the document
     * @param docURI is the URI of the document added
     */
    event DocAdded(bytes32 indexed polytradeId, uint256 docId, string docURI);

    /**
     * @notice Emits when a document is removed
     * @dev Emits when {removeDoc} is called by an organization
     * @param polytradeId is the Id assigned to an organization
     * @param docId is the Id assigned to the document
     */
    event DocRemoved(bytes32 indexed polytradeId, uint256 docId);

    /**
     * @notice Sets the base URI for computing docURI
     * @dev If set, the resulting URI for each document will be the
     * concatenation of the {baseURI} and the docId.
     * @param uri is the base URI for any document
     */
    function setBaseURI(string memory uri) external;

    /**
     * @notice Sets the address of the IdManager contract
     * @param newManager is the address of the new IdManager contract
     */
    function setIdManager(address newManager) external;

    /**
     * @notice Adds a document for an organization
     * @dev Creates a unique URI for each document based on the {baseURI}
     * @param polytradeId is the Id assigned to an organization
     * Emits {DocAdded} event
     */
    function addDoc(bytes32 polytradeId) external;

    /**
     * @notice Removes a document for an organization
     * @param polytradeId is the Id assigned to an organization
     * @param docId is the Id of the document to be removed
     * Emits {DocRemoved} event
     */
    function removeDoc(bytes32 polytradeId, uint256 docId) external;

    /**
     * @notice returns the base URI for the document URIs
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice returns the number of documents added by an organization
     * @param polytradeId is the Id assigned to an organization
     */
    function getDocsCount(bytes32 polytradeId) external view returns (uint256);
}


// File contracts/IdManager/Interface/IIdManager.sol


pragma solidity ^0.8.17;

/**
 * @title IIdManager
 * @author Polytrade
 */
interface IIdManager {
    struct Organization {
        bytes32 polytradeId;
        address admin;
        address[] wallets;
        bool verified;
    }

    /**
     * @notice Emits when a polytrade Id is created for an organization
     * @param polytradeId is the Id assigned to an organization
     * @param orgAdminWallet is the organization's admin wallet's address
     */
    event IdCreated(bytes32 indexed polytradeId, address orgAdminWallet);

    /**
     * @notice Emits when an organization is verified
     * @param polytradeId is the Id assigned to an organization
     * @param verified is the verification status of the organization
     */
    event OrgVerified(bytes32 indexed polytradeId, bool verified);

    /**
     * @notice Emits when a wallet is added to an organization
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address
     */
    event WalletAdded(bytes32 indexed polytradeId, address wallet);

    /**
     * @notice Emits when a wallet is removed from an organization
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address
     */
    event WalletRemoved(bytes32 indexed polytradeId, address wallet);

    /**
     * @notice Emits when an organization transfers assigns a new admin
     * @param polytradeId is the Id assigned to an organization
     * @param oldAdmin is the wallet address of the old organization admin
     * @param newAdmin is the wallet address of the new organization admin
     */
    event OrgAdminTransferred(
        bytes32 indexed polytradeId,
        address oldAdmin,
        address newAdmin
    );

    /**
     * @notice Creates a polytrade Id for an organization
     * @dev Maps the polytrade Id generated from the system to an organization's admin wallet
     * @param polytradeId is the Id assigned to an organization
     * @param orgAdminWallet is the organization's admin wallet address
     * @param validKyc boolean value of organization's kyc status
     * Emits {IdCreated} event
     */
    function createId(
        bytes32 polytradeId,
        address orgAdminWallet,
        bool validKyc
    ) external;

    /**
     * @notice Adds a wallet address to an organization
     * @dev It gives a wallet the permission to be able to perform
     * transactions using the organization's polytrade id
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be added
     * Emits {WalletAdded} event
     */
    function addWallet(bytes32 polytradeId, address wallet) external;

    /**
     * @notice Removes a wallet address from an organization
     * @dev Removing it revokes its use of the organization's polytrade Id
     * from making transactions
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet to be removed
     * Emits {WalletRemoved} event
     */
    function removeWallet(bytes32 polytradeId, address wallet) external;

    /**
     * @notice Assigns a new wallet address for an organization's admin
     * @param polytradeId is the Id assigned to an organization
     * @param newAdmin is the wallet address to transfer ownership to
     * Emits {OrgAdminTransferred} event
     */
    function transferAdmin(bytes32 polytradeId, address newAdmin) external;

    /**
     * @dev returns the verification status of an organization
     * @param polytradeId is the Id assigned to an organization
     * @return boolean value representing the verification status
     */
    function isVerified(bytes32 polytradeId) external view returns (bool);

    /**
     * @dev returns the organization details from the organization struct
     * @param polytradeId is the Id assigned to an organization
     * @return struct returns organization struct details
     */
    function getOrgDetails(
        bytes32 polytradeId
    ) external view returns (Organization memory);

    /**
     * @dev returns whether a wallet belongs to an organization's admin
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be checked
     * @return bool true or false
     */
    function isAdminWallet(
        bytes32 polytradeId,
        address wallet
    ) external view returns (bool);

    /**
     * @dev returns whether a wallet belongs to an organization or not
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be checked
     * @return bool true or false
     */
    function isOrgWallet(
        bytes32 polytradeId,
        address wallet
    ) external view returns (bool);
}


// File contracts/DocumentsManager/DocumentsManager.sol


pragma solidity ^0.8.17;




contract DocumentsManager is IDocumentsManager, Ownable {
    string private _baseURI;
    IIdManager private _idManager;

    mapping(bytes32 => uint256[]) private _orgToDocs;

    modifier isDocIdValid(uint256 docId) {
        require(docId != 0, "Invalid Doc ID");
        _;
    }

    modifier isWalletAuthorized(bytes32 polytradeId) {
        bool isAdminWallet = _idManager.isAdminWallet(polytradeId, msg.sender);
        bool isOrgWallet = _idManager.isOrgWallet(polytradeId, msg.sender);

        require(isAdminWallet || isOrgWallet, "Un-authorized wallet");
        _;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        require(bytes(uri).length != 0, "Invalid BaseURI");
        _baseURI = uri;
    }

    function setIdManager(address newManager) external onlyOwner {
        address oldManager = address(_idManager);
        _idManager = IIdManager(newManager);

        emit IdManagerChanged(oldManager, newManager);
    }

    function addDoc(
        bytes32 polytradeId
    ) external isWalletAuthorized(polytradeId) {
        uint256 docId = _orgToDocs[polytradeId].length + 1;

        _orgToDocs[polytradeId].push(docId);

        string memory docURI = _docURI(docId);

        emit DocAdded(polytradeId, docId, docURI);
    }

    function removeDoc(
        bytes32 polytradeId,
        uint256 docId
    ) external isDocIdValid(docId) isWalletAuthorized(polytradeId) {
        uint256 docsCount = _orgToDocs[polytradeId].length;
        _orgToDocs[polytradeId][docId - 1] = _orgToDocs[polytradeId][
            docsCount - 1
        ];
        _orgToDocs[polytradeId].pop();

        emit DocRemoved(polytradeId, docId);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function getDocsCount(bytes32 polytradeId) external view returns (uint256) {
        require(polytradeId != 0, "Invalid Id");
        return _orgToDocs[polytradeId].length;
    }

    function _docURI(uint256 docId) internal view returns (string memory) {
        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, Strings.toString(docId)))
                : "";
    }
}