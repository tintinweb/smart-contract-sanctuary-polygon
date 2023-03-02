// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity 0.8.7;

/// @title Admin related functionalities
/// @dev This contract is abstract. It is inherited in SxTRelay and SxTValidator to set and handle admin only functions

abstract contract Admin {
    /// @dev Address of admin set by inheriting contracts
    address internal admin;

    /// @notice Modifier for checking if Admin address has called the function
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    /**
     * @notice Get the address of Admin wallet
     * @return adminAddress Address of Admin wallet set in the contract
     */
    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    /**
     * @notice Set the address of Admin wallet
     * @param  adminAddress Address of Admin wallet to be set in the contract
     */
    function setAdmin(address adminAddress) public onlyAdmin {
        admin = adminAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Initializer for inheriting contracts
/// @dev This contract is abstract. It is inherited in SxTRelay for initializing Validator contract for now. But will be used more in future

abstract contract Initializer {

    /// @dev stores if the inheriting contract has been initialized or not
    bool private _isInitialized;

    /// @notice Modifier for checking if the inheriting contract has been already initialized or not before initializing.
    modifier initializer() {
        require(!_isInitialized, "Initializer: already initialized");
        _;
        _isInitialized = true;
    }
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISxTPaymentLedger {

    struct Currency {
        address contractAddress;
        bool isActive;
        uint128 fees;
    }

    struct Payment {
        string currency;
        uint128 amount;
    }

    /**
     * Event emitted when new payment record is added in contract
     * @param  requestId ID for request for which payment record is to be added
     * @param  currencySymbol Symbol of currency
     * @param  paymentReceived Payment amount received for this request
     */    
    event PaymentRecordAdded(        
        bytes32 requestId,
        string currencySymbol,
        uint128 paymentReceived
    );

    /**
     * Event emitted when new treasury wallet is updated in contract
     * @param treasuryWallet Address of new treasury wallet
     */    
    event SxTTreasuryRegistered(address indexed treasuryWallet);

    /**
     * event emitted when fees of a token is set in contract
     * @param  currencySymbol Symbol of currency
     * @param  tokenAddress Token address to set the fees
     * @param  tokenFees Fees for the token
     */     
    event TokenDetailsUpdated(
        string currencySymbol,
        address tokenAddress,
        bool isActive,
        uint128 tokenFees
    );

    /**
     * Set treasury address
     * @param treasuryWallet address of treasury wallet
     */
    function setTreasury(address treasuryWallet) external;

    /**
     * @notice Function to get fees of a token address
     * @param  currencySymbol Symbol to identify currency
     */
    function getTokenDetails(
        string calldata currencySymbol
    ) external returns ( Currency memory );

    /**
     * @notice Function to get fees native currency
     */
    function getNativeCurrencyDetails() external returns ( Currency memory );

    /**
     * @notice Function to add Fees of a token address
     * @param  currencySymbol Symbol to identify currency
     */
    function hasTokenFees(
        string memory currencySymbol
    ) external returns (bool);

    /**
     * @notice Function to accept fees for request in ERC20 Token
     * @param  currencySymbol Symbol to identify currency
     * @param  requestId ID for request to pay fees
     */
    function acceptERC20Payment(
        bytes32 requestId, 
        string memory currencySymbol
    ) external;

    /**
     * @notice Function to accept fees for request in native currency
     * @param  requestId ID for request to pay fees
     */
    function acceptNativePayment(
        bytes32 requestId
    ) external payable;

    /**
     * @notice Function to get payment record of a prepaid request
     * @param  requestId ID for request to fetch payment record
     */
    function getPaymentRecord(
        bytes32 requestId
    ) external returns (Payment memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISxTRelay {
    /**
     * @notice Event emitted when a new query request is registered in SxTValidator Contract
     * @param requestId ID generated for new request
     * @param requester Address of UserClient contract
     * @param paramHash Hash of request parameters
     * @param sqlTextData SQL query in bytes format
     * @param resourceIdData Resource ID in bytes format 
     * @param biscuitIdData Biscuit ID for authorization in bytes format 
     * @param isPrepaid Specify if the request registered is prepaid or postpaid
     */
    event SxTRequestQueryV1(
        bytes32 indexed requestId,
        address requester,
        bytes paramHash,
        bytes sqlTextData, 
        bytes resourceIdData,
        bytes biscuitIdData,
        bool isPrepaid
    );

    /**
     * @notice Event emitted when a new view request is registered in SxTValidator Contract
     * @param requestId ID generated for new request
     * @param requester Address of UserClient contract
     * @param paramHash Hash of request parameters
     * @param viewNameData View name in bytes format
     * @param biscuitIdData Biscuit ID for authorization in bytes format 
     * @param isPrepaid Specify if the request registered is prepaid or postpaid
     */
    event SxTRequestViewV1(
        bytes32 indexed requestId,
        address requester,
        bytes paramHash,
        bytes viewNameData, 
        bytes biscuitIdData,
        bool isPrepaid
    );
    
    /**
     * @notice Event emitted when new SxTValidator Contract is updated in SxTRelay contract
     * @param validator Address of validator contract set in the contract
     */
    event SxTValidatorRegistered(address indexed validator);

    /**
     * @notice Event emitted when new SxTPaymentLedger Contract is updated in SxTRelay contract
     * @param payment Address of payment contract set in the contract
     */
    event SxTPaymentLedgerRegistered(address indexed payment);

    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
     * @param sqlText SQL Query for executing
     * @param resourceId ID for selecting cluster on Gateway
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQuery(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external returns (bytes32);

    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
     * @param sqlText SQL Query for executing
     * @param resourceId ID for selecting cluster on Gateway
     * @param paymentCurrency Address of Fungible Token to pay request fees 
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQueryERC20(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string calldata paymentCurrency
    ) external returns (bytes32);
    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
     * @param sqlText SQL Query for executing
     * @param resourceId ID for selecting cluster on Gateway
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQueryNative(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable returns (bytes32);

    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
     * @dev  SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
     * @param viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external returns (bytes32);

    /**
    * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
    * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
    * @param  viewName View name for fetching response data
    * @param  callbackFunctionSignature Callback function signature from UserClient contract
    * @param paymentCurrency Address of Fungible Token to pay request fees
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @notice paymentToken should be equal to ZERO Address for postpaid request
    */
    function executeViewERC20(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string calldata paymentCurrency
    ) external returns (bytes32);
    
    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
     * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
     * @param viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeViewNative(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISxTValidator {

    // Structure for storing request data
    struct SXTRequest {
        bytes32 requestId;
        uint128 createdAt;
        uint128 expiredAt;
        bytes4 callbackFunctionSignature;
        address callbackAddress;
    }

    // Structure for storing signer data
    struct Signer {
        bool active;
        // Index of oracle in signersList/transmittersList
        uint8 index;
    }

    // Structure for storing config arguments of SxTValidator Contract
    struct ValidatorConfigArgs {
        address[] signers;
        uint8 f;
        bytes onchainConfig;
        uint64 offchainConfigVersion;
        bytes offchainConfig;
    }
    /**
     * Function for registering a new request in SxTValidator
     * @param callbackAddress Address of user smart contract which sent the request
     * @param callbackFunctionSignature Signature of the callback function from user contract, which SxTValidator should call for returning response
     */    
    function registerSXTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    ) external returns (SXTRequest memory, bytes memory);

    /**
     * Event emitted when new SxTRelay Contract is updated in contract
     * @param sxtRelay Address of new SxTRelay contract
     */    
    event SxTRelayRegistered(address indexed sxtRelay);

    /**
     * Event emitted when new request expiry duration is updated in contract
     * @param expireTime Duration of seconds in which a request should expire
     */
    event SXTRequestExpireTimeRegistered(uint256 expireTime);
    
    /**
     * Event emitted when Maximum number of possible oracles is updated in contract
     * @param count New maximum number of oracles to allow
     */
    event SXTMaximumOracleCountRegistered(uint64 count);

    /**
     * Event emitted when the response is received by SxTValidator contract, for a request
     * @param requestId Request ID for which response received
     * @param data Response received in encoded format
     */
    event SXTResponseRegistered(bytes32 indexed requestId, bytes data);

    /**
     * Event emitted when config arguments are updated in the contract
     * @param prevConfigBlockNumber block number which previous config was set
     * @param configCount Number of times the contract config is updated till now
     * @param signers Array of list of valid signers for a response
     * @param onchainConfig Encoded version of config args stored onchain
     * @param offchainConfigVersion Version of latest config
     * @param offchainConfig Encoded version of config args stored offchain
     */
    event SXTConfigRegistered(
        uint32 prevConfigBlockNumber,
        uint64 configCount,
        address[] signers,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );
}

/**
________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
\ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
\|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
|\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
\|_________|         
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./abstract/Admin.sol";
import "./abstract/Initializer.sol";

import "./interfaces/ISxTRelay.sol";
import "./interfaces/ISxTPaymentLedger.sol";
import "./interfaces/ISxTValidator.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/// @title SxTRelay handles request from SxTClient
/// @dev This contract will be deployed by SxT team, used to emit event which will be listened by Oracle node

contract SxTRelay is Admin, Initializer, Pausable, ISxTRelay {
    using Strings for string;

    // Address to represent Native Currency in the contract
    string constant private NATIVE_CURRENCY_SYMBOL = "ETH";

    // Zero Address
    address constant ZERO_ADDRESS = address(0);

    /// @dev Instance of sxtValidator to interact with
    ISxTValidator public sxtValidator;

    /// @dev Instance of sxtPaymentLedger to interact with
    ISxTPaymentLedger public sxtPaymentLedger;

    /// @notice constructor sets the admin address of contract
    constructor() {
        admin = msg.sender;
    }

    /**
    * @notice Initialize the validator and payment contract addresses in SxTRelay contract 
    * @param  validator Address of validator contract to be set in the contract
    * @param  payment Address of payment contract to be set in the contract
    */
    function initialize(address validator, address payment)
        external
        initializer
        onlyAdmin
    {
        setSxTValidator(validator);
        setSxTPaymentLedger(payment);
    }

    /**
    * @notice Set the address of validator contract 
    * @param  validator Address of validator contract to be set in the contract
    */
    function setSxTValidator(address validator) public onlyAdmin {
        sxtValidator = ISxTValidator(validator);
        emit SxTValidatorRegistered(validator);
    }

    /**
    * @notice Set the address of payment contract 
    * @param  payment Address of payment contract to be set in the contract
    */
    function setSxTPaymentLedger(address payment) public onlyAdmin {
        sxtPaymentLedger = ISxTPaymentLedger(payment);
        emit SxTPaymentLedgerRegistered(payment);
    }
    
    /**
    * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
    * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
    * @param sqlText SQL Query for executing
    * @param resourceId ID for selecting cluster on Gateway
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @param  callbackFunctionSignature Callback function signature from UserClient contract
    * @notice paymentCurrency should be equal to address of valid ERC20 token acceptable by SxT
    */
    function executeQuery(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external override whenNotPaused returns (bytes32) {
        (bytes32 requestId, bytes memory paramHash, bytes memory sqlTextData, bytes memory resourceIdData, bytes memory biscuitIdData) = _registerQueryRequest(
            resourceId,
            sqlText,
            biscuitId,
            callbackFunctionSignature
        );
        emit SxTRequestQueryV1(requestId, msg.sender, paramHash, sqlTextData, resourceIdData, biscuitIdData, false);
        return requestId;

    }

    /**
    * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
    * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
    * @param sqlText SQL Query for executing
    * @param resourceId ID for selecting cluster on Gateway
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @param callbackFunctionSignature Callback function signature from UserClient contract
    * @param paymentCurrency Address of Fungible Token to pay request fees 
    * @notice paymentCurrency should be equal to address of valid ERC20 token acceptable by SxT
    */
    function executeQueryERC20(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string calldata paymentCurrency
    ) external override whenNotPaused returns (bytes32) {
        (bytes32 requestId, bytes memory paramHash, bytes memory sqlTextData, bytes memory resourceIdData, bytes memory biscuitIdData) = _registerQueryRequest(
            resourceId,
            sqlText,
            biscuitId,
            callbackFunctionSignature
        );
        sxtPaymentLedger.acceptERC20Payment(requestId, paymentCurrency);
        emit SxTRequestQueryV1(requestId, msg.sender, paramHash, sqlTextData, resourceIdData, biscuitIdData, true);
        return requestId;

    }

    /**
    * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
    * @notice Payable function. Need to send native currency as value
    * @notice To be used in case of Native currency prepaid request
    * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
    * @param sqlText SQL Query for executing
    * @param resourceId ID for selecting cluster on Gateway
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @param  callbackFunctionSignature Callback function signature from UserClient contract
    */
    function executeQueryNative(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable override whenNotPaused returns (bytes32) {
        (bytes32 requestId, bytes memory paramHash, bytes memory sqlTextData, bytes memory resourceIdData, bytes memory biscuitIdData) = _registerQueryRequest(
            resourceId,
            sqlText,
            biscuitId,
            callbackFunctionSignature
        );
        sxtPaymentLedger.acceptNativePayment{value: msg.value}(requestId);
        emit SxTRequestQueryV1(requestId, msg.sender, paramHash, sqlTextData, resourceIdData, biscuitIdData, true);
        return requestId;
    }

    /**
    * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
    * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
    * @param  viewName View name for fetching response data
    * @param  callbackFunctionSignature Callback function signature from UserClient contract
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @notice paymentCurrency should be equal to address of valid ERC20 token acceptable by SxT
    */
    function executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external override whenNotPaused returns (bytes32) {
        (bytes32 requestId, bytes memory paramHash, bytes memory viewNameData, bytes memory biscuitIdData) = _registerViewRequest(
            viewName,
            biscuitId,
            callbackFunctionSignature
        );
        emit SxTRequestViewV1(requestId, msg.sender, paramHash, viewNameData, biscuitIdData, false);
        return requestId;
    }

    /**
    * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
    * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
    * @param viewName View name for fetching response data
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @param callbackFunctionSignature Callback function signature from UserClient contract
    * @param paymentCurrency Address of Fungible Token to pay request fees 
    * @notice paymentCurrency should be equal to address of valid ERC20 token acceptable by SxT
    */
    function executeViewERC20(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string calldata paymentCurrency
    ) external override whenNotPaused returns (bytes32) {
        (bytes32 requestId, bytes memory paramHash, bytes memory viewNameData, bytes memory biscuitIdData) = _registerViewRequest(
            viewName,
            biscuitId,
            callbackFunctionSignature
        );
        sxtPaymentLedger.acceptERC20Payment(requestId, paymentCurrency);
        emit SxTRequestViewV1(requestId, msg.sender, paramHash, viewNameData, biscuitIdData, true);
        return requestId;
    }

    /**
    * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
    * @notice Payable function. Need to send native currency as value
    * @notice To be used in case of Native currency prepaid request
    * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
    * @param viewName View name for fetching response data
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @param callbackFunctionSignature Callback function signature from UserClient contract
    */
    function executeViewNative(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable override whenNotPaused returns (bytes32) {
        (bytes32 requestId, bytes memory paramHash, bytes memory viewNameData, bytes memory biscuitIdData) = _registerViewRequest(
            viewName,
            biscuitId,
            callbackFunctionSignature
        );
        sxtPaymentLedger.acceptNativePayment{value: msg.value}(requestId);
        emit SxTRequestViewV1(requestId, msg.sender, paramHash, viewNameData, biscuitIdData, true);
        return requestId;
    }

    /**
    * @notice Function to register Query request in SxTValidator
    * @notice Internal function. Cannot be called by user directly
    * @param resourceId ID for selecting cluster on Gateway
    * @param sqlText SQL Query for executing
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @param callbackFunctionSignature Callback function signature from UserClient contract
    */
    function _registerQueryRequest( 
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32, bytes memory, bytes memory, bytes memory, bytes memory ){
        (
            ISxTValidator.SXTRequest memory request,
            bytes memory paramHash
        ) = sxtValidator.registerSXTRequest(
                msg.sender,
                callbackFunctionSignature
            );

        bytes memory sqlTextData = bytes(sqlText);
        bytes memory resourceIdData = bytes(resourceId);
        bytes memory biscuitIdData = bytes(biscuitId);

        return (request.requestId, paramHash, sqlTextData, resourceIdData, biscuitIdData);
    }

    /**
    * @notice Function to register View request in SxTValidator
    * @notice Internal function. Cannot be called by user directly
    * @param viewName View name for fetching response data
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @param callbackFunctionSignature Callback function signature from UserClient contract
    */
    function _registerViewRequest( 
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32, bytes memory, bytes memory, bytes memory ){
        (
            ISxTValidator.SXTRequest memory request,
            bytes memory paramHash
        ) = sxtValidator.registerSXTRequest(
                msg.sender,
                callbackFunctionSignature
            );
        bytes memory viewNameData = bytes(viewName);
        bytes memory biscuitIdData = bytes(biscuitId);
        return (request.requestId, paramHash, viewNameData, biscuitIdData);
    }

    /**
    * @notice Function to pause the contract
    */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
    * @notice Function to unpause the contract
    */
    function unpause() external onlyAdmin {
        _unpause();
    }

}