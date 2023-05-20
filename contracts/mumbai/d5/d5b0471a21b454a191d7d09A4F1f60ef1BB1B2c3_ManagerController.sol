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
    function getAllValues() external returns (string memory values);
    function updateVariables(VariablesInt[] memory changedVariablesInt, VariablesDec[] memory changedVariablesDec, VariablesString[] memory changedVariablesString, VariablesBool[] memory changedVariablesBool, address _treasuryAddress) external;
    function getValueInt(string memory variableName) external view returns(uint256);
    function getValueDec(string memory variableName) external view returns(uint256);
    function treasuryAddress() external view returns(address treasuryAddress);
    function getValueString(string memory variableName) external returns(string memory);
    function getValueBool(string memory variableName) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../YousovAccessControl.sol';
import '../interface/IYousovStructs.sol';
import './interface/IManagerController.sol';
import '../lib/ManagerHelper.sol';
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";


contract ManagerController is YousovRoles, IManagerController,ERC2771Context  {


    VariablesInt[] variablesInt;
    string[] variableNamesInt;
    uint[] valuesInt;


    VariablesDec[] variablesDec;
    string[] variableNamesDec;
    uint[] valuesDec;


    VariablesString[] variablesString;
    string[] variableNamesString;
    string[] valuesString;

    VariablesBool[] variablesBool;
    string[] variableNamesBool;
    bool[] valuesBool;


    address public treasuryAddress;

    address yousovAccessControl;

    constructor(address _youSovAccessControl, address _treasuryAddress, address _forwarder) ERC2771Context(_forwarder) {
        treasuryAddress=_treasuryAddress;
        yousovAccessControl = _youSovAccessControl;
        variableNamesInt = [
            "minimumRecoveryPriceUsd",
            "minimumRecoveryPriceEzr",
            "zeroEZRBalancePriceFactor",//TODO v2
            "numberOfTestsAgentsMo",//TODO v2
            "maximumNumberOfAgents",
            "maxLottery",//TODO v2
            "attempt2Price",//TODO v2
            "attempt3Price",//TODO v2
            "attempt4Price",//TODO v2
            "attempt5Price",//TODO v2
            "minimumAgentsAppear",
            "timeLimitFaucet", // TODO when manage timers
            "bundleOfferExpiration",
            "emptyWalletRecovery" //TODO v2
        ];
        valuesInt = [
            50,
            10**18,
            2,
            12,
            40000,
            1000000,
            75,
            100,
            200,
            500,
            500,
            86400,
            5184000,
            2
        ];

        for (uint256 i = 0; i < variableNamesInt.length; i++) {
            variablesInt.push(VariablesInt(variableNamesInt[i], valuesInt[i]));
        }

         variableNamesDec = [
            "testRecoveryRewardRatio",//TODO v2
            "totalAgentsRatio",//TODO v2
            "seniorAgentsRatio",//TODO v2
            "stakingRewardPerYear",//TODO v2
            "seniorAgentRate",//TODO v2
            "juniorAgentRate",//TODO v2
            "standardsRate",//TODO v2
            "deniedRate",//TODO v2
            "agentPayrollWalletFromJunior",//TODO v2
            "agentPayrollWalletFromDenied",//TODO v2
            "agentPayrollWalletFromRecovery",
            "bonusShare",//TODO v2
            "seniorAgentsBonusShare",//TODO v2
            "senioAgentsLotteryOdds",//TODO v2
            "juniorAgentsLotteryOdds",//TODO v2
            "standards",//TODO v2
            "burn",
            "amountFaucet"
            ];
         valuesDec = [
            2500,
            30000,
            150000,
            6000,
            1200000,
            900000,
            750000,
            0,
            800000,
            500000,
            50,
            800000,
            700000,
            600000,
            150000,
            200000,
            30,
            5 * 10**16
            ];

         for (uint256 i = 0; i < variableNamesDec.length; i++) {
            variablesDec.push(VariablesDec(variableNamesDec[i], valuesDec[i]));
        }

        variableNamesString = [
            "agentType",
            "urlFaucet"
        ];

        valuesString = [
            "human",//TODO v2
            "http://yousov.com/faucet" //TODO v2
        ];

         for (uint256 i = 0; i < variableNamesString.length; i++) {
            variablesString.push(VariablesString(variableNamesString[i], valuesString[i]));
        }

        variableNamesBool = [
            "stakingRewardsPanic",//TODO v2
            "agentRewardsPanic",//TODO v2
            "recoveriesPanic"
        ];

        valuesBool = [
            false,
            false,
            false
        ];

        for (uint256 i = 0; i < variableNamesBool.length; i++) {
            variablesBool.push(VariablesBool(variableNamesBool[i], valuesBool[i]));
        }

    }

    function updateVariables(VariablesInt[] memory changedVariablesInt, VariablesDec[] memory changedVariablesDec, VariablesString[] memory changedVariablesString, VariablesBool[] memory changedVariablesBool, address _treasuryAddress) external override {
      require(
            isTrustedForwarder(msg.sender)&&
            YousovAccessControl(yousovAccessControl).hasRole(
                MANAGER_ROLE,
                _msgSender()
            ),
            "You dont have the rights to change variables"
        );
        treasuryAddress = _treasuryAddress;
        for (uint i = 0; i < changedVariablesInt.length; i++) {
            for (uint j = 0; j < variablesInt.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesInt[i].variableNameInt)
                    ) == keccak256(abi.encodePacked(variablesInt[j].variableNameInt))
                ) {
                    variablesInt[j].valueInt = changedVariablesInt[i].valueInt;
                }
            }
        }
        for (uint i = 0; i < changedVariablesDec.length; i++) {
            for (uint j = 0; j < variablesDec.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesDec[i].variableNameDec)
                    ) == keccak256(abi.encodePacked(variablesDec[j].variableNameDec))
                ) {
                    variablesDec[j].valueDec = changedVariablesDec[i].valueDec;
                }
            }
        }
        for (uint i = 0; i < changedVariablesString.length; i++) {
            for (uint j = 0; j < variablesString.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesString[i].variableNameString)
                    ) == keccak256(abi.encodePacked(variablesString[j].variableNameString))
                ) {
                    variablesString[j].valueString = changedVariablesString[i].valueString;
                }
            }
        }
        for (uint i = 0; i < changedVariablesBool.length; i++) {
            for (uint j = 0; j < variablesBool.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesBool[i].variableNameBool)
                    ) == keccak256(abi.encodePacked(variablesBool[j].variableNameBool))
                ) {
                    variablesBool[j].valueBool = changedVariablesBool[i].valueBool;
                }
            }
        }
    }



    function getValueString(
        string memory variableName
    ) external view override returns (string memory) {
        string memory vr = "";
        for (uint i = 0; i < variablesString.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesString[i].variableNameString)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesString[i].valueString;
            }
        }
        return vr;
    }

    function getValueBool(
        string memory variableName
    ) external view override returns (bool) {
        bool vr = false;
        for (uint i = 0; i < variablesBool.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesBool[i].variableNameBool)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesBool[i].valueBool;
            }
        }
        return vr;
    }

    function getValueInt(
        string memory variableName
    ) external view override returns (uint256) {
        uint vr;
        for (uint i = 0; i < variablesInt.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesInt[i].variableNameInt)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesInt[i].valueInt;
            }
        }
        return vr;
    }

    function getValueDec(
        string memory variableName
    ) external view override returns (uint256) {
        uint vr;
        for (uint i = 0; i < variablesDec.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesDec[i].variableNameDec)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesDec[i].valueDec;
            }
        }
        return vr;
    }

    function getAllValues() external view override returns (string memory) {
        string memory resultInt;
        for (uint i = 0; i < variablesInt.length; i++) {
            VariablesInt memory v = variablesInt[i];
            resultInt = string(
                abi.encodePacked(
                    resultInt,
                    "{'name': '",
                    v.variableNameInt,
                    "', 'value': '",
                    ManagerHelper.uint2str(v.valueInt),
                    "'}, "
                )
            );
        }
        string memory resultDec;
        for (uint i = 0; i < variablesDec.length; i++) {
            VariablesDec memory v = variablesDec[i];
            resultDec = string(
                abi.encodePacked(
                    resultDec,
                    "{'name': '",
                    v.variableNameDec,
                    "', 'value': '",
                    ManagerHelper.uint2str(v.valueDec),
                    "'}, "
                )
            );
        } 
        string memory resultString;
        for (uint i = 0; i < variablesString.length; i++) {
            VariablesString memory v = variablesString[i];
            resultString = string(
                abi.encodePacked(
                    resultString,
                    "{'name': '",
                    v.variableNameString,
                    "', 'value': '",
                    v.valueString,
                    "'}, "
                )
            );
        }
        string memory resultBool;
        for (uint i = 0; i < variablesBool.length; i++) {
            VariablesBool memory v = variablesBool[i];
            resultBool = string(
                abi.encodePacked(
                    resultBool,
                    "{'name': '",
                    v.variableNameBool,
                    "', 'value': '",
                    ManagerHelper.boolToString(v.valueBool),
                    "'}, "
                )
            );
        }
        string memory result;
        result = string(
            abi.encodePacked(
                resultInt,
                resultDec,
                resultString,
                resultBool
            )
        );
        return result;
     }

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
        SENIOR,
        JUNIOR,
        STANDARD,
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
        ANSWERED,
        NOT_ANSWERED
        
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
        uint256 birthDateTimeStamp;
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

pragma solidity 0.8.17;

library ManagerHelper {

    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }

function boolToString(bool _bool) internal pure returns (string memory) {
    return _bool ? "true" : "false";
}

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