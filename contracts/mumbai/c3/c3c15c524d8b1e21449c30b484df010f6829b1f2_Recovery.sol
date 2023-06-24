// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
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
pragma solidity 0.8.17 ;

import "../../interface/IYousovStructs.sol";

interface IManagerController is IYousovStructs{
    event UpdatingManagerVars();
    function getAllValues() external returns (string memory values);
    function updateVariables(VariablesInt[] memory changedVariablesInt, VariablesDec[] memory changedVariablesDec, VariablesString[] memory changedVariablesString, VariablesBool[] memory changedVariablesBool, address _treasuryAddress) external;
    function getValueInt(string memory variableName) external view returns(uint256);
    function getValueDec(string memory variableName) external view returns(uint256);
    function treasuryAddress() external view returns(address treasuryAddress);
    function getValueString(string memory variableName) external returns(string memory);
    function getValueBool(string memory variableName) external returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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

pragma solidity ^0.8.17;

import "../../interface/IYousovStructs.sol";

interface IEZR is IYousovStructs {
  event GASTOPAY(uint256);
  function mint(address to, uint256 amount) external ;
  function userTransactionsList(address yousovuser) view external returns(Transaction[] memory _userTransactions) ;
  function setRecoveryFactory(address _recoveryFactory) external;
  function transferFromExternalContracts(address from, address to, uint256 amount) external;
  function burnFromFromRecoveryFactory(address from, uint256 amount) external;
  function claimFreeEZR() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IYousovStructs {

    enum AccountType {
        REGULAR,
        PSEUDO
    }
    enum Gender {
        MALE,
        FEMALE,
        OTHER
    }
    enum UserStatus {
        OPT_IN,
        OPT_OUT
    }
    enum UserRole {
        JUNIOR,
        STANDARD,
        SENIOR,
        DENIED
    }
    enum RecoveryStatus {
        CREATED,
        READY_TO_START,
        IN_PROGRESS,
        WAITING_AGENTS_ANSWERS,
        OVER,
        CANCELED
    }
    enum RecoveryRole {
        QUESTION_AGENT,
        ANSWER_AGENT
    }
    enum AnswerStatus{
        NOT_ANSWERED,
        ANSWERED
    }

    enum SecretStatus{
        LOCK,
        UNLOCK
    }

    struct SecretVault {
        string secret;
        SecretStatus secretStatus;
    }
    struct ExtraUserArgs {
        address forwarder;
        address userFactoryExtra;
        address agregator;
    }
    struct AnswerAgentsDetails{
        string initialAnswer;
        string actualAnswer;
        string challengeID;
        bool answer;
        AnswerStatus answerStatus;
    }
    struct RecoveryStats {
        bool isAllAnswersAgentsAnswered;
        uint256 totoalValidAnswers;
        
    }
    struct PII {
        string firstName;
        string middelName;
        string lastName;
        string cityOfBirth;
        string countryOfBirth;
        string countryOfCitizenship;
        string uid;
        int256 birthDateTimeStamp;
        Gender gender;
    }
    struct Wallet {
        address publicAddr;
        string walletPassword;
        string privateKey;
    }
    struct Challenge {
        string question;
        string answer;
        string id;
    }

    enum TransactionType {
        TRANSACTION_IN,
        TRANSACTION_OUT
    }
    struct Transaction {
        TransactionType transactionType;
        uint256 transactionDate;
        uint256 amount;
        address from;
        address to;
    }

    struct VariablesInt {
        string variableNameInt;
        uint valueInt;
    }

    struct VariablesDec{
        string variableNameDec;
        uint valueDec;
    }

    struct VariablesString{
        string variableNameString;
        string valueString;
    }

    struct VariablesBool{
        string variableNameBool;
        bool valueBool;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

import "../../interface/IYousovStructs.sol";
interface IRecovery is IYousovStructs{
    event AgentAddedToRecovery(address recoveryAddress,address user);
    event RecoveryReadyToStart(address userRecovery);
    event AgentAssignedAnswerForRecovery(address[] agents, address recovery);
    event SendAnswersToAnswerAgents(address[] agents, address recovery);
    event VaultAccessAccepted(address recoveryAddress);
    event VaultAccessDenied(address recoveryAddress);
    event RecoveryIsOver(address recovery);
    function user() view external returns (address user);
    function contenderAgentsList() view external returns (address[] memory);
    function recoveryAgents() view external returns (address[] memory);
    function addContenderAgent(address contenderAgent) external;
    function addNewAgentToRecovery() external;
    function getRecoveryStatus() external view returns (RecoveryStatus currentRecoveryStatus) ;
    function clearContenderAgents() external;
    function isUserIsAnActifAgent(address userAgent) external returns (bool);
    function startTheRecovery() external;
    function sendRecoveryAnswerToAnswerAgent(Challenge[] memory _challenges) external;
    function agentCheckUserAnswer(address answerAgent,bool userAnswer) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "../../interface/IYousovStructs.sol";

interface IRecoveryBroadcast is IYousovStructs{
    event LegalAgentsToNotify(address recovery,address[] legalSelectableAgents);
    event LegalAgentsToNotifyToReplaceEjectedAgents(address recovery,address[] legalSelectableAgents);
   function setRecoveryFactoryAddress (address _recoveryFactory)  external;
   function getLegalSelectableAgents(
        address initialSender,
        address _currentRecovery
    ) external;
    function getLegalSelectableAgentsToReplaceEjectedAgent(
        address _currentRecovery
    ) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "../../interface/IYousovStructs.sol";

interface IRecoveryFactory is IYousovStructs{
    event RecoveryCreated(address currentAddress, address recoveryAddress);
    // event LegalAgentsToNotify(address recovery,address[] legalSelectableAgents);
    function userFactory() external view returns (address);
    function addActiveAgent(address newActiveAgent, address linkedRecovery) external;
    function deleteActiveAgent(address _agentAddress) external;
    function yousovRecoveries() external view returns (address[] memory);
    function yousovActiveAgentsInRecoveries() external view returns (address[] memory);
    function temporaryWalletMappings(address ) view external returns (address);
    function temporaryRecoverytemporaryWallet(address) view external returns (address);
    function recoveryExist(address _recovery) external view returns (bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IRecovery.sol";
import "./interface/IRecoveryFactory.sol";
import "../Users/interface/IUser.sol";
import "../Users/interface/IUserFactory.sol";
import "../YousovAccessControl.sol";
import "../YousovRoles.sol";
import "../EZR/interface/IEZR.sol";
import "../EZR/interface/IERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "../controller/interface/IManagerController.sol";
import "./interface/IRecoveryBroadcast.sol";


contract Recovery is IRecovery, YousovRoles, ERC2771Context {
    address public user;
    address[] public agentList;
    address public recoveryFactory;
    address public yousovAccessControl;
    address[] public contenderAgents;
    address public managerController;
    address public ezr;
    address public recoveryBroadcast;
    RecoveryStatus public recoveryStatus = RecoveryStatus.CREATED;
    mapping(address => AnswerAgentsDetails) public answerAgentsDetails;
    address[] public ejectedAgents;
    address[] public answeredAgents;
    event Event1(address ejectedAgentToReplace, uint256 ejectedAgentsLength);
    event Event2(uint256 ejectedAgentsLength);
    event EventAnswerAgentsDetails1(AnswerAgentsDetails);
    // event EventAnswerAgentsDetails2(AnswerAgentsDetails);
    constructor(
        address _user,
        address _recoveryFactory,
        address _yousovAccessControl,
        address _forwarder,
        address _managerController,
        address _ezr,
        address _recoveryBroadcast
    ) ERC2771Context(_forwarder) {
        recoveryFactory = _recoveryFactory;
        user = _user;
        yousovAccessControl = _yousovAccessControl;
        managerController = _managerController;
        ezr = _ezr;
        recoveryBroadcast = _recoveryBroadcast;
    }

    modifier recoveryPanicOff() {
        require(
            !IManagerController(managerController).getValueBool(
                "recoveriesPanic"
            ),
            "Yousov : Recoveries are stopped for emergency security"
        );
        _;
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    // function cancelCurrentRecovery() public recoveryPanicOff {
    //     require(
    //         isTrustedForwarder(msg.sender),
    //         "YOUSOV : Operation not authorized, not the trustedForwarder"
    //     );
    //     require(
    //         _msgSender() == user && recoveryStatus != RecoveryStatus.CANCELED,
    //         "YOUSOV : Operation not authorized"
    //     );
    //     recoveryStatus = RecoveryStatus.CANCELED;
    // }

    function clearContenderAgents() external override recoveryPanicOff {
        require(
            msg.sender == recoveryBroadcast,
            "YOUSOV : Operation not authorized"
        );
        if (contenderAgents.length > 0) {
            delete contenderAgents;
        }
    }

    function addContenderAgent(
        address contenderAgent
    ) external override recoveryPanicOff {
        require(
            msg.sender == recoveryBroadcast,
            "YOUSOV : Operation not authorized"
        );
        contenderAgents.push(contenderAgent);
    }

    function contenderAgentsList()
        external
        view
        override
        returns (address[] memory)
    {
        return contenderAgents;
    }

    function recoveryAgents()
        external
        view
        override
        returns (address[] memory)
    {
        return agentList;
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function addNewAgentToRecovery() external override recoveryPanicOff {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        require(
            YousovAccessControl(yousovAccessControl).hasRole(
                YOUSOV_USER_ROLE,
                _msgSender()
            ),
            "YOUSOV : Recovery user is not a yousov user"
        );

        require(
            agentList.length <
                IUser(
                    IUserFactory(
                        IRecoveryFactory(recoveryFactory).userFactory()
                    ).userContract(user)
                ).userChallenges().length,
            "YOUSOV : Recovery selection is over"
        );
        require(
            !this.isUserIsAnActifAgent(_msgSender()),
            "User is already an actif agent"
        );
        agentList.push(_msgSender());
        IRecoveryFactory(recoveryFactory).addActiveAgent(
            _msgSender(),
            address(this)
        );
        if (
            agentList.length ==
            IUser(
                IUserFactory(IRecoveryFactory(recoveryFactory).userFactory())
                    .userContract(user)
            ).userChallenges().length
        ) {
            recoveryStatus = RecoveryStatus.READY_TO_START;
            emit RecoveryReadyToStart(address(this));
        } else {
            emit AgentAddedToRecovery(address(this), _msgSender());
        }
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function deleteAgentFromRecovery(
        address _agentAddress
    ) public recoveryPanicOff {
        // require(
        //     isTrustedForwarder(msg.sender),
        //     "YOUSOV : Operation not authorized, not the trustedForwarder"
        // );

        // require(
        //     _agentAddress == _msgSender(),
        //     "YOUSOV : Operation not authorized"
        // ); // to avoid checking the for loop if identity theft

        // require(
        //     YousovAccessControl(yousovAccessControl).hasRole(
        //         YOUSOV_USER_ROLE,
        //         _msgSender()
        //     ),
        //     "YOUSOV : Recovery user is not a yousov user"
        // );

        bool _agentExists = false;
        for (uint i = 0; i < agentList.length; ++i) {
            if (agentList[i] == _agentAddress) {
                agentList[i] = agentList[agentList.length - 1];
                _agentExists = true;
                break;
            }
        }
        if (_agentExists) {
            agentList.pop();
        }
        IRecoveryFactory(recoveryFactory).deleteActiveAgent(_agentAddress);
    }

    function getRecoveryStatus()
        external
        view
        override
        returns (RecoveryStatus currentRecoveryStatus)
    {
        return recoveryStatus;
    }

    function isUserIsAnActifAgent(
        address userAgent
    ) external view override returns (bool) {
        for (uint i = 0; i < agentList.length; ++i) {
            if (agentList[i] == userAgent) {
                return true;
            }
        }
        return false;
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function startTheRecovery() external override recoveryPanicOff {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );

        require(
            recoveryStatus == RecoveryStatus.READY_TO_START &&
                (_msgSender() == user ||
                    IRecoveryFactory(recoveryFactory).temporaryWalletMappings(
                        _msgSender()
                    ) ==
                    user) &&
                (agentList.length ==
                    IUser(
                        IUserFactory(
                            IRecoveryFactory(recoveryFactory).userFactory()
                        ).userContract(user)
                    ).userChallenges().length),
            "YOUSOV : Operation not authorized"
        );
        string[] memory userChallengesShuffled = IUser(
            IUserFactory(IRecoveryFactory(recoveryFactory).userFactory())
                .userContract(user)
        ).shuffleChallenges();
        for (uint256 i = 0; i < agentList.length; ++i) {
            Challenge memory affectedChallenge = IUser(
                IUserFactory(IRecoveryFactory(recoveryFactory).userFactory())
                    .userContract(user)
            ).userChallengesDetails(userChallengesShuffled[i]);
            answerAgentsDetails[agentList[i]] = AnswerAgentsDetails(
                affectedChallenge.answer,
                "",
                affectedChallenge.id,
                false,
                AnswerStatus.NOT_ANSWERED
            );
        }
        recoveryStatus = RecoveryStatus.IN_PROGRESS;
        emit AgentAssignedAnswerForRecovery(agentList, address(this));
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function sendRecoveryAnswerToAnswerAgent(
        Challenge[] memory _challenges
    ) external override recoveryPanicOff {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );

        require(
            (_msgSender() == user ||
                IRecoveryFactory(recoveryFactory).temporaryWalletMappings(
                    _msgSender()
                ) ==
                user) && recoveryStatus == RecoveryStatus.IN_PROGRESS,
            "YOUSOV : Not authorized operation"
        );
        for (uint i = 0; i < agentList.length; ++i) {
            address answerAgent = agentList[i];
            for (uint j = 0; j < _challenges.length; ++j) {
                if (
                    keccak256(
                        abi.encodePacked(
                            answerAgentsDetails[answerAgent].challengeID
                        )
                    ) == keccak256(abi.encodePacked(_challenges[j].id))
                ) {
                    AnswerAgentsDetails memory lastStat = answerAgentsDetails[
                        answerAgent
                    ];
                    answerAgentsDetails[answerAgent] = AnswerAgentsDetails(
                        lastStat.initialAnswer,
                        _challenges[j].answer,
                        lastStat.challengeID,
                        false,
                        AnswerStatus.NOT_ANSWERED
                    );
                    break;
                }
            }
        }
        recoveryStatus = RecoveryStatus.WAITING_AGENTS_ANSWERS;
        emit SendAnswersToAnswerAgents(agentList, address(this));
    }

    function _isAllAnswersAgentsHaveAnswered()
        private
        view
        returns (RecoveryStats memory)
    {
        uint256 totalValidAnswers = 0;
        if (answeredAgents.length < IUser(
                        IUserFactory(
                            IRecoveryFactory(recoveryFactory).userFactory()
                        ).userContract(user)
                    ).userChallenges().length) {
            return RecoveryStats(false, totalValidAnswers);
        }
        for (uint i = 0; i < answeredAgents.length; ++i) {
          
            if (answerAgentsDetails[answeredAgents[i]].answer) {
                totalValidAnswers = totalValidAnswers + 1;
            }
        }
        return RecoveryStats(true, totalValidAnswers);
    }

    function _deleteRecoveryFactoryCurrentRecoveryActiveAgents() private {
        for (uint i = 0; i < agentList.length; ++i) {
            IRecoveryFactory(recoveryFactory).deleteActiveAgent(agentList[i]);
        }
        delete agentList;
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function agentCheckUserAnswer(
        address answerAgent,
        bool userAnswer
    ) external override recoveryPanicOff {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        require(
            _msgSender() == answerAgent &&
                recoveryStatus == RecoveryStatus.WAITING_AGENTS_ANSWERS &&
                answerAgentsDetails[answerAgent].answerStatus ==
                AnswerStatus.NOT_ANSWERED,
            "YOUSOV : Not authorized operation"
        );
        answerAgentsDetails[answerAgent] = AnswerAgentsDetails(
            answerAgentsDetails[answerAgent].initialAnswer,
            answerAgentsDetails[answerAgent].actualAnswer,
            answerAgentsDetails[answerAgent].challengeID,
            userAnswer,
            AnswerStatus.ANSWERED
        );
        // add agent to temporary answered agents 
        answeredAgents.push(answerAgent);
        deleteAgentFromRecovery(answerAgent);
        // check if all answers agents have answered than
        RecoveryStats
            memory actualRecoveryStats = _isAllAnswersAgentsHaveAnswered();
        if (actualRecoveryStats.isAllAnswersAgentsAnswered) {
            if (
                actualRecoveryStats.totoalValidAnswers >=
                IUser(
                    IUserFactory(
                        IRecoveryFactory(recoveryFactory).userFactory()
                    ).userContract(user)
                ).threashold()
            ) {
                // Give access to the vault
                IUser(
                    IUserFactory(
                        IRecoveryFactory(recoveryFactory).userFactory()
                    ).userContract(user)
                ).unlockSecretVault();
                // get temporary user if its a temporary recovery
                address _tempWalletAddress = IRecoveryFactory(recoveryFactory)
                    .temporaryRecoverytemporaryWallet(address(this));

                if (_tempWalletAddress != address(0)) {
                    // transfer all finds to user
                    IEZR(ezr).transferFromExternalContracts(
                        _tempWalletAddress,
                        user,
                        IERC20(ezr).balanceOf(_tempWalletAddress)
                    );
                }
                recoveryStatus = RecoveryStatus.OVER;
                emit VaultAccessAccepted(address(this));
            } else {
                recoveryStatus = RecoveryStatus.OVER;
                //  don't give access to the vault
                emit VaultAccessDenied(address(this));
            }
        
            emit RecoveryIsOver(address(this));
        }
    }

    function ejectUserAgentFromRecoveryAndNotifyOtherAgents(
        address agentToEject
    ) public {
        require(
            // isTrustedForwarder(msg.sender) && 
            this.isUserIsAnActifAgent(agentToEject) ,
            // && agentToEject == _msgSender(),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );

        // delete from recovery and recovery factory view
        deleteAgentFromRecovery(agentToEject);
        // set pending
        ejectedAgents.push(agentToEject);
        //  notify agents
        IRecoveryBroadcast(recoveryBroadcast)
            .getLegalSelectableAgentsToReplaceEjectedAgent(
                address(this)
            );
    }

    function replaceEjectedAgentWithCurrent(address agentToReplace) public {
        require(
            // isTrustedForwarder(msg.sender) &&
                // agentToReplace == _msgSender() &&
                recoveryStatus == RecoveryStatus.WAITING_AGENTS_ANSWERS,
            "YOUSOV : Operation not authorized"
        );
        address ejectedAgentToReplace = ejectedAgents[ejectedAgents.length - 1];
        emit Event1(ejectedAgentToReplace, ejectedAgents.length);
        ejectedAgents.pop();
        emit Event2(ejectedAgents.length);
        emit EventAnswerAgentsDetails1(answerAgentsDetails[
            ejectedAgentToReplace
        ]);
        agentList.push(agentToReplace);
        IRecoveryFactory(recoveryFactory).addActiveAgent(
            agentToReplace,
            address(this)
        );
        AnswerAgentsDetails memory ejectedAnswerDetails = answerAgentsDetails[
            ejectedAgentToReplace
        ];
        // emit EventAnswerAgentsDetails2(ejectedAnswerDetails);
        delete answerAgentsDetails[ejectedAgentToReplace];
        answerAgentsDetails[agentToReplace] = ejectedAnswerDetails;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
pragma experimental ABIEncoderV2;
import "../../interface/IYousovStructs.sol";
interface IUser is IYousovStructs {
    function pseudonym() view external returns (string memory pseudonym);
    function creationDate() view external returns (uint256 creationDate);
    function threashold() view external returns (uint256 threashold);
    function userChallenges() view external returns(string[] memory _userChallenges);
    function setSecret(string memory newSecret) external;
    function setWallet(string memory walletPassword) external;
    function getWalletDetails() external view  returns (Wallet memory);
    function getAccountType() external view  returns (AccountType);
    function getPII() external view returns (PII memory);
    function getSecret() external view returns (string memory);
    function switchUserStatus(UserStatus newStatus) external;
    function lockSecretVault() external;
    function updateUserAccountTypeFromPiiToPseudo(string memory pseudo) external;
    function updateUserAccountTypeFromPseudoToPii(PII memory newPII) external;
    function setChallenges(Challenge[] memory newChallenges , uint256 newThreashold ) external;
    function checkWalletPassword(string memory walletPassword) view external  returns (Wallet memory wallet);
    function userChallengesDetails(string memory challengID) external view returns (Challenge memory challengDetail);
    function unlockSecretVault() external;
    function isSecretUnlocked() external returns(bool);
    function shuffleChallenges() external returns (string[] memory);
    event SecretUpdated();
    event PseudonymUpdated();
    event PIIUpdated();
    event ChallengesUpdated();
    event WalletUpdated();
    event AccountTypeUpdated();
    event ThreasholdUpdated();
    event StatusUpdated();
    event UpdateUserIdentityFromPIIToPseudo();
    event UpdateUserIdentityFromPseudoToPII();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "../../interface/IYousovStructs.sol";
interface IUserFactory is IYousovStructs {
    function yousovUserList() external view returns (address[] memory );
    function userContract(address) external view returns (address);
    function newUser(PII memory pii , Wallet memory wallet, Challenge[] memory challenges, string memory pseudonym , AccountType accountType, uint256 threashold, string memory secret) external;
    function deleteUserContractUser(address userAddr, uint256 index) external;
    // function checkUnicity(AccountType userAccountTpe , PII memory userPII , string memory userPseudo) external view returns(bool exists, address userContractAddr);
    event UserCreated();
    event UserDeleted(address userDeletedAddress);
   
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./YousovRoles.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
 
 contract YousovAccessControl is Context, IAccessControl, ERC165, YousovRoles {
    address userFactory;
    
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    constructor (address _defaultAdmin, address _ezrMinter, address _ezrPauser) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(PAUSER_ROLE, _defaultAdmin);
        _setupRole(MANAGER_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _ezrMinter);
        _setupRole(PAUSER_ROLE, _ezrPauser);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function checkRole(bytes32 role, address sender) public view {
        _checkRoleAccount(role, sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRoleAccount(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE , msg.sender) || hasRole(DEFAULT_ADMIN_ROLE,tx.origin) || msg.sender == userFactory );
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE , msg.sender) || hasRole(DEFAULT_ADMIN_ROLE,tx.origin) || msg.sender == userFactory);
        _revokeRole(role, account);
    }
    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == tx.origin, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }


    function setAgentPayrolWalletAddressAsMinter(address _apwAddress) public {
        require(msg.sender == _apwAddress, "Yousov: Incorrect Address");
        _setupRole(MINTER_ROLE, _apwAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _apwAddress);
    }
    function setUserFactory(address newUserFactoryAddress)  public{
        require(msg.sender == newUserFactoryAddress, "Yousov: Incorrect Address");
        userFactory = newUserFactoryAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract YousovRoles {
    bytes32 public constant YOUSOV_USER_ROLE = keccak256("YOUSOV_USER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant TEMPORARY_YOUSOV_USER_ROLE = keccak256("TEMPORARY_YOUSOV_USER_ROLE");
    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CAN_TRANSFER_ROLE = keccak256("CAN_TRANSFER_ROLE");
}