// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {TablelandPolicy} from "../TablelandPolicy.sol";

/**
 * @dev Interface of a TablelandTables compliant contract.
 */
interface ITablelandTables {
    /**
     * The caller is not authorized.
     */
    error Unauthorized();

    /**
     * RunSQL was called with a query length greater than maximum allowed.
     */
    error MaxQuerySizeExceeded(uint256 querySize, uint256 maxQuerySize);

    /**
     * @dev Emitted when `owner` creates a new table.
     *
     * owner - the to-be owner of the table
     * tableId - the table id of the new table
     * statement - the SQL statement used to create the table
     */
    event CreateTable(address owner, uint256 tableId, string statement);

    /**
     * @dev Emitted when a table is transferred from `from` to `to`.
     *
     * Not emmitted when a table is created.
     * Also emitted after a table has been burned.
     *
     * from - the address that transfered the table
     * to - the address that received the table
     * tableId - the table id that was transferred
     */
    event TransferTable(address from, address to, uint256 tableId);

    /**
     * @dev Emitted when `caller` runs a SQL statement.
     *
     * caller - the address that is running the SQL statement
     * isOwner - whether or not the caller is the table owner
     * tableId - the id of the target table
     * statement - the SQL statement to run
     * policy - an object describing how `caller` can interact with the table (see {TablelandPolicy})
     */
    event RunSQL(
        address caller,
        bool isOwner,
        uint256 tableId,
        string statement,
        TablelandPolicy policy
    );

    /**
     * @dev Emitted when a table's controller is set.
     *
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     */
    event SetController(uint256 tableId, address controller);

    /**
     * @dev Struct containing parameters needed to run a mutating sql statement
     *
     * tableId - the id of the target table
     * statement - the SQL statement to run
     *           - the statement type can be any of INSERT, UPDATE, DELETE, GRANT, REVOKE
     *
     */
    struct Statement {
        uint256 tableId;
        string statement;
    }

    /**
     * @dev Creates a new table owned by `owner` using `statement` and returns its `tableId`.
     *
     * owner - the to-be owner of the new table
     * statement - the SQL statement used to create the table
     *           - the statement type must be CREATE
     *
     * Requirements:
     *
     * - contract must be unpaused
     */
    function create(
        address owner,
        string memory statement
    ) external payable returns (uint256);

    /**
     * @dev Creates multiple new tables owned by `owner` using `statements` and returns array of `tableId`s.
     *
     * owner - the to-be owner of the new table
     * statements - the SQL statements used to create the tables
     *            - each statement type must be CREATE
     *
     * Requirements:
     *
     * - contract must be unpaused
     */
    function create(
        address owner,
        string[] calldata statements
    ) external payable returns (uint256[] memory);

    /**
     * @dev Runs a mutating SQL statement for `caller` using `statement`.
     *
     * caller - the address that is running the SQL statement
     * tableId - the id of the target table
     * statement - the SQL statement to run
     *           - the statement type can be any of INSERT, UPDATE, DELETE, GRANT, REVOKE
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller`
     * - `tableId` must exist and be the table being mutated
     * - `caller` must be authorized by the table controller
     * - `statement` must be less than or equal to 35000 bytes
     */
    function mutate(
        address caller,
        uint256 tableId,
        string calldata statement
    ) external payable;

    /**
     * @dev Runs an array of mutating SQL statements for `caller`
     *
     * caller - the address that is running the SQL statement
     * statements - an array of structs containing the id of the target table and coresponding statement
     *            - the statement type can be any of INSERT, UPDATE, DELETE, GRANT, REVOKE
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller`
     * - `tableId` must be the table being muated in each struct's statement
     * - `caller` must be authorized by the table controller if the statement is mutating
     * - each struct inside `statements` must have a `tableId` that corresponds to table being mutated
     * - each struct inside `statements` must have a `statement` that is less than or equal to 35000 bytes after normalization
     */
    function mutate(
        address caller,
        ITablelandTables.Statement[] calldata statements
    ) external payable;

    /**
     * @dev Sets the controller for a table. Controller can be an EOA or contract address.
     *
     * When a table is created, it's controller is set to the zero address, which means that the
     * contract will not enforce write access control. In this situation, validators will not accept
     * transactions from non-owners unless explicitly granted access with "GRANT" SQL statements.
     *
     * When a controller address is set for a table, validators assume write access control is
     * handled at the contract level, and will accept all transactions.
     *
     * You can unset a controller address for a table by setting it back to the zero address.
     * This will cause validators to revert back to honoring owner and GRANT/REVOKE based write access control.
     *
     * caller - the address that is setting the controller
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function setController(
        address caller,
        uint256 tableId,
        address controller
    ) external;

    /**
     * @dev Returns the controller for a table.
     *
     * tableId - the id of the target table
     */
    function getController(uint256 tableId) external returns (address);

    /**
     * @dev Locks the controller for a table _forever_. Controller can be an EOA or contract address.
     *
     * Although not very useful, it is possible to lock a table controller that is set to the zero address.
     *
     * caller - the address that is locking the controller
     * tableId - the id of the target table
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function lockController(address caller, uint256 tableId) external;

    /**
     * @dev Sets the contract base URI.
     *
     * baseURI - the new base URI
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev Pauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be unpaused
     */
    function pause() external;

    /**
     * @dev Unpauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be paused
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

/**
 * @dev Object defining how a table can be accessed.
 */
struct TablelandPolicy {
    // Whether or not the table should allow SQL INSERT statements.
    bool allowInsert;
    // Whether or not the table should allow SQL UPDATE statements.
    bool allowUpdate;
    // Whether or not the table should allow SQL DELETE statements.
    bool allowDelete;
    // A conditional clause used with SQL UPDATE and DELETE statements.
    // For example, a value of "foo > 0" will concatenate all SQL UPDATE
    // and/or DELETE statements with "WHERE foo > 0".
    // This can be useful for limiting how a table can be modified.
    // Use {Policies-joinClauses} to include more than one condition.
    string whereClause;
    // A conditional clause used with SQL INSERT statements.
    // For example, a value of "foo > 0" will concatenate all SQL INSERT
    // statements with a check on the incoming data, i.e., "CHECK (foo > 0)".
    // This can be useful for limiting how table data ban be added.
    // Use {Policies-joinClauses} to include more than one condition.
    string withCheck;
    // A list of SQL column names that can be updated.
    string[] updatableColumns;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Library of helpers for generating SQL statements from common parameters.
 */
library SQLHelpers {
    /**
     * @dev Generates a properly formatted table name from a prefix and table id.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toNameFromId(
        string memory prefix,
        uint256 tableId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    "_",
                    Strings.toString(tableId)
                )
            );
    }

    /**
     * @dev Generates a CREATE statement based on a desired schema and table prefix.
     *
     * schema - a comma seperated string indicating the desired prefix. Example: "int id, text name"
     * prefix - the user generated table prefix as a string
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toCreateFromSchema(
        string memory schema,
        string memory prefix
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "CREATE TABLE ",
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    "(",
                    schema,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - a string encoded ordered list of values that will be inserted wrapped in parentheses. Example: "'jerry', 24". Values order must match column order.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toInsert(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string memory values
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        return
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    name,
                    "(",
                    columns,
                    ")VALUES(",
                    values,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - an array where each item is a string encoded ordered list of values.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toBatchInsert(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string[] memory values
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        string memory insert = string(
            abi.encodePacked("INSERT INTO ", name, "(", columns, ")VALUES")
        );
        for (uint256 i = 0; i < values.length; i++) {
            if (i == 0) {
                insert = string(abi.encodePacked(insert, "(", values[i], ")"));
            } else {
                insert = string(abi.encodePacked(insert, ",(", values[i], ")"));
            }
        }
        return insert;
    }

    /**
     * @dev Generates an Update statement based on table prefix, tableId, setters, and filters.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     * setters - a string encoded set of updates. Example: "name='tom', age=26"
     * filters - a string encoded list of filters or "" for no filters. Example: "id<2 and name!='jerry'"
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toUpdate(
        string memory prefix,
        uint256 tableId,
        string memory setters,
        string memory filters
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        string memory filter = "";
        if (bytes(filters).length > 0) {
            filter = string(abi.encodePacked(" WHERE ", filters));
        }
        return
            string(abi.encodePacked("UPDATE ", name, " SET ", setters, filter));
    }

    /**
     * @dev Generates a Delete statement based on table prefix, tableId, and filters.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * filters - a string encoded list of filters. Example: "id<2 and name!='jerry'".
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toDelete(
        string memory prefix,
        uint256 tableId,
        string memory filters
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        return
            string(abi.encodePacked("DELETE FROM ", name, " WHERE ", filters));
    }

    /**
     * @dev Add single quotes around a string value
     *
     * input - any input value.
     *
     */
    function quote(string memory input) internal pure returns (string memory) {
        return string(abi.encodePacked("'", input, "'"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {ITablelandTables} from "../interfaces/ITablelandTables.sol";

/**
 * @dev Helper library for getting an instance of ITablelandTables for the currently executing EVM chain.
 */
library TablelandDeployments {
    /**
     * Current chain does not have a TablelandTables deployment.
     */
    error ChainNotSupported(uint256 chainid);

    // TablelandTables address on Ethereum.
    address internal constant MAINNET =
        0x012969f7e3439a9B04025b5a049EB9BAD82A8C12;
    // TablelandTables address on Ethereum.
    address internal constant HOMESTEAD = MAINNET;
    // TablelandTables address on Optimism.
    address internal constant OPTIMISM =
        0xfad44BF5B843dE943a09D4f3E84949A11d3aa3e6;
    // TablelandTables address on Arbitrum One.
    address internal constant ARBITRUM =
        0x9aBd75E8640871A5a20d3B4eE6330a04c962aFfd;
    // TablelandTables address on Arbitrum Nova.
    address internal constant ARBITRUM_NOVA =
        0x1A22854c5b1642760a827f20137a67930AE108d2;
    // TablelandTables address on Polygon.
    address internal constant MATIC =
        0x5c4e6A9e5C1e1BF445A062006faF19EA6c49aFeA;
    // TablelandTables address on Filecoin.
    address internal constant FILECOIN =
        0x59EF8Bf2d6c102B4c42AEf9189e1a9F0ABfD652d;

    // TablelandTables address on Ethereum Sepolia.
    address internal constant SEPOLIA =
        0xc50C62498448ACc8dBdE43DA77f8D5D2E2c7597D;
    // TablelandTables address on Optimism Goerli.
    address internal constant OPTIMISM_GOERLI =
        0xC72E8a7Be04f2469f8C2dB3F1BdF69A7D516aBbA;
    // TablelandTables address on Arbitrum Goerli.
    address internal constant ARBITRUM_GOERLI =
        0x033f69e8d119205089Ab15D340F5b797732f646b;
    // TablelandTables address on Polygon Mumbai.
    address internal constant MATICMUM =
        0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68;
    // TablelandTables address on Filecoin Hyperspace.
    address internal constant FILECOIN_HYPERSPACE =
        0x0B9737ab4B3e5303CB67dB031b509697e31c02d3;

    // TablelandTables address on for use with https://github.com/tablelandnetwork/local-tableland.
    address internal constant LOCAL_TABLELAND =
        0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    /**
     * @dev Returns an interface to Tableland for the currently executing EVM chain.
     *
     * The selection order is meant to reduce gas on more expensive chains.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function get() internal view returns (ITablelandTables) {
        if (block.chainid == 1) {
            return ITablelandTables(MAINNET);
        } else if (block.chainid == 10) {
            return ITablelandTables(OPTIMISM);
        } else if (block.chainid == 42161) {
            return ITablelandTables(ARBITRUM);
        } else if (block.chainid == 42170) {
            return ITablelandTables(ARBITRUM_NOVA);
        } else if (block.chainid == 137) {
            return ITablelandTables(MATIC);
        } else if (block.chainid == 314) {
            return ITablelandTables(FILECOIN);
        } else if (block.chainid == 11155111) {
            return ITablelandTables(SEPOLIA);
        } else if (block.chainid == 420) {
            return ITablelandTables(OPTIMISM_GOERLI);
        } else if (block.chainid == 421613) {
            return ITablelandTables(ARBITRUM_GOERLI);
        } else if (block.chainid == 80001) {
            return ITablelandTables(MATICMUM);
        } else if (block.chainid == 3141) {
            return ITablelandTables(FILECOIN_HYPERSPACE);
        } else if (block.chainid == 31337) {
            return ITablelandTables(LOCAL_TABLELAND);
        } else {
            revert ChainNotSupported(block.chainid);
        }
    }
}

pragma solidity ^0.8.13;

interface IMultisig {

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event multisigAccountCreated(bytes indexed data);
    event Deposit(address indexed sender, uint amount, uint balance);


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IMultisig.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
// import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract Multisig is  IMultisig {

    ITablelandTables private tablelandContract;

    string[] private createStatements;
    string[] public tables;
    uint256[] private tableIDs;

    string private constant PROPOSAL_TABLE_PREFIX = "transaction_proposal";
    // string private constant COMPUTATION_SCHEMA = "wasmCID text, inputCID text, startCMD text, CMD text, JobId text, creator text, bacalhauJobID text, result text";
    string private constant PROPOSAL_SCHEMA =
        "proposalID text, name text, description text, proposer text, executed text";

    string private constant CONFIRMATIONS_TABLE_PREFIX = "confirmation";
    // string private constant COMPUTATION_SCHEMA = "wasmCID text, inputCID text, startCMD text, CMD text, JobId text, creator text, bacalhauJobID text, result text";
    string private constant CONFIRMATIONS_TABLE_SCHEMA =
        "proposalID text, confirmationAddress text";


    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;
    // /**
    //  * @notice Executes once when a contract is created to initialize state variables
    //  *
    //  * @param _entrypoint - 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
    //  * @param _factory - The factory contract address to issue token Gated accounts
    //  *
    //  */
    // constructor(IEntryPoint _entrypoint, address _factory) Account(_entrypoint, _factory) {
    //     _disableInitializers();
    // }

    constructor(bytes memory _data){
        (owners, numConfirmationsRequired) = abi.decode(_data, (address[], uint256));

        require(owners.length > 0, "owners required");
        require(
            numConfirmationsRequired > 0 && numConfirmationsRequired <= owners.length,
            "invalid number of required confirmations"
        );
        for (uint i = 0; i < owners.length; i++) {
            require(owners[i] != address(0), "invalid owner");
            require(!isOwner[owners[i]], "owner not unique");
            isOwner[owners[i]] = true;
        }
        // require(owner() == _admin, "Account: not token owner.");
        tablelandContract = TablelandDeployments.get();

        createStatements.push(
            SQLHelpers.toCreateFromSchema(PROPOSAL_SCHEMA, PROPOSAL_TABLE_PREFIX)
        );

        createStatements.push(SQLHelpers.toCreateFromSchema(CONFIRMATIONS_TABLE_SCHEMA, CONFIRMATIONS_TABLE_PREFIX));
   
        tableIDs = tablelandContract.create(address(this), createStatements);

        tables.push(SQLHelpers.toNameFromId(PROPOSAL_TABLE_PREFIX, tableIDs[0]));
        tables.push(SQLHelpers.toNameFromId(CONFIRMATIONS_TABLE_PREFIX, tableIDs[1]));

         emit multisigAccountCreated(_data);
    }
    


    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data,
        string memory proposalName,
        string memory proposalDescription
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        insertProposal(txIndex, proposalName, proposalDescription);
    }

    function confirmTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        insertConfirmation(_txIndex);
    }

    function execute(
        uint _txIndex
    ) external virtual onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        
        _call(transaction.to, transaction.value, transaction.data);
        transaction.executed = true;
        updateExecutionStatus(_txIndex);
    }

    // function executeBatchTransaction(uint[] memory _txIndexes) public txsExists(_txIndexes) txtsNotExecuted(_txIndexes){
    //     for(uint i = 0; i < _txIndexes.length; i++){
    //         Transaction storage transaction = transactions[_txIndexes[i]];

    //         require(
    //             transaction.numConfirmations >= numConfirmationsRequired,
    //             "cannot execute tx"
    //         );

    //         transaction.executed = true;

    //         _call(transaction.to, transaction.value, transaction.data);

    //         emit ExecuteTransaction(msg.sender, _txIndexes[i]);
    //     }
    // }

    // function revokeConfirmation(
    //     uint _txIndex
    // ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
    //     Transaction storage transaction = transactions[_txIndex];

    //     require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

    //     transaction.numConfirmations -= 1;
    //     isConfirmed[_txIndex][msg.sender] = false;
    //     deleteConfirmation(_txIndex);
    // }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }


    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }


    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }


    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }



        /*
     * @dev Inserts a new record into the attribute table.
     * @param {uint256} tokenid - Token ID.
     * @param {string} trait_type - Trait type.
     * @param {string} value - Value.
     * @param {address} proposer - Value.
     */

    function insertProposal(
        uint256 proposalID,
        string memory name,
        string memory description
    ) internal {
        mutate(
            tableIDs[0],
            SQLHelpers.toInsert(
                PROPOSAL_TABLE_PREFIX,
                tableIDs[0],
                "proposalID, name, description, proposer, executed",
                string.concat(
                    SQLHelpers.quote((Strings.toString(proposalID))),
                    ",",
                    SQLHelpers.quote(name),
                    ",",
                    SQLHelpers.quote(description),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    SQLHelpers.quote("false")
                    
                )
            )
        );
    }


        /*
     * @dev Inserts a new record into the attribute table.
     * @param {uint256} proposalID - Token ID.
     */

    function insertConfirmation(
        uint256 proposalID
    ) internal {
        mutate(
            tableIDs[1],
            SQLHelpers.toInsert(
                CONFIRMATIONS_TABLE_PREFIX,
                tableIDs[1],
                "proposalID, confirmationAddress",
                string.concat(
                    SQLHelpers.quote((Strings.toString(proposalID))),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(msg.sender))
                )
            )
        );
    }

    function updateExecutionStatus(uint256 proposalID) internal {
        string memory set = string.concat("executed='", "true", "'");
        string memory filter = string.concat("proposalID=", SQLHelpers.quote(Strings.toString(proposalID)));
        mutate(tableIDs[0], SQLHelpers.toUpdate(PROPOSAL_TABLE_PREFIX, tableIDs[0], set, filter));
    }

    function mutate(uint256 tableId, string memory statement) internal {
        tablelandContract.mutate(address(this), tableId, statement);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Multisig} from "./Multisig.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
contract multisigFactory  {
    ITablelandTables private tablelandContract;

    string private createStatement;
    string public table;
    uint256 private tableID;
    address[] owners;
    uint256 numConfirmationsRequired;
    uint public _salt;


    string private constant MULTISIG_TABLE_PREFIX = "multisig";
    // string private constant COMPUTATION_SCHEMA = "wasmCID text, inputCID text, startCMD text, CMD text, JobId text, creator text, bacalhauJobID text, result text";
    string private constant MULTISIG_SCHEMA =
        "multisigAddress text, ownerAddress text, numberOfConfirmations text, proposalTable text, confirmationTable text";
    constructor(){
        tablelandContract = TablelandDeployments.get();
        tableID = tablelandContract.create(address(this), SQLHelpers.toCreateFromSchema(MULTISIG_SCHEMA, MULTISIG_TABLE_PREFIX));
        table = SQLHelpers.toNameFromId(MULTISIG_TABLE_PREFIX, tableID);

    }

    function createWallet(
        bytes calldata _data
    ) external {
        (owners, numConfirmationsRequired) = abi.decode(_data, (address[], uint256));
        
        _salt = _salt + 1;
        Multisig multisigWallet = (new Multisig){salt:bytes32(_salt)}(_data);

        string memory _proposalTable = multisigWallet.tables(0);
        string memory _confirmationTable = multisigWallet.tables(1);
        addMultisig(address(multisigWallet), owners, numConfirmationsRequired, _proposalTable, _confirmationTable);
    }



    function addMultisig(
        address multisigAddress,
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        string memory proposalTable,
        string memory confirmationTable
    ) internal {

        for(uint256 i = 0; i < _owners.length; i++){
            mutate(
            tableID,
            SQLHelpers.toInsert(
                MULTISIG_TABLE_PREFIX,
                tableID,
                "multisigAddress, ownerAddress, numberOfConfirmations, proposalTable, confirmationTable",
                string.concat(
                    SQLHelpers.quote(Strings.toHexString(multisigAddress)),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(_owners[i])),
                    ",",
                    SQLHelpers.quote(Strings.toString(_numConfirmationsRequired)),
                    ",",
                    SQLHelpers.quote(proposalTable),
                    ",",
                    SQLHelpers.quote(confirmationTable)
                )
            )
        );

        }
    }
        function mutate(uint256 tableId, string memory statement) internal {
        tablelandContract.mutate(address(this), tableId, statement);
    }

    // function getAddress() public view returns (address) {
    //     return
    //         Create2.computeAddress(
    //             bytes32(salt),
    //             keccak256(type(Multisig).creationCode)
    //         );
    // }
}