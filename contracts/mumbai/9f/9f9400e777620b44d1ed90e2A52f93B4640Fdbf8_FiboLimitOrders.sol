//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../signatures/signatureTypes.sol";

library FiboLimitOrders {
    using SafeMathUpgradeable for uint256;

    struct LimitOrder {
        /// @notice the address of the account placing this order
        address trader;
        /// @notice the address of the asset being traded
        /// in the context of the fibo product this will typically be a property token
        address assetToken;
        /// @notice the address of the token denominating the "price" of the primary asset
        /// in the context of the fibo product with will typically be a stablecoin
        address denominationToken;
        /// @notice true if `trader` wants to transfer out `denominationToken` and receive `assetToken`
        /// and false, if they want to transfer out `assetToken` and receive `denominationToken`
        bool isBuy;
        /// @notice the number of tokens of `assetToken` that `trader` is willing to trade
        uint256 quantity;
        /// @notice the number of tokens of `denominationToken` that `trader` wants to trade in exchange
        /// for each token of `assetToken`
        uint256 price;
        /// @notice unix timestamp after which this order can no longer be executed
        /// if set to 0, the order never expires
        uint256 expiration;
        /// @notice must be taken from the ats contract at the time that the order is created
        /// this order can only execute as long as the contract's `blockNonce` value hasn't changed
        uint256 blockNonce;
        uint256 batchId;
        /// @notice can have any value and is meaningless as long as it's different from other orders
        /// this allows a user to submit multiple orders with otherwise identical details
        uint256 salt;
    }

    struct SignedLimitOrder {
        LimitOrder order;
        Signature signature;
    }

    uint256 private constant PRICE_DENOMINATOR = 1e18;

    /// @notice computes whether or not two limit orders should trade with each other, and if so, at what price
    /// this function only compares the orders based on their inherent information, and should not be considered an exhaustive check of order validity
    /// for example, this function does *not* verify an order's signature, or check that it hasnb't been cancelled
    /// @param takerOrder a newly placed order trading against resting orders
    /// @param makerOrder a resting order expected to match with `takerOrder`
    /// @param shareCount the number of shares to trade if these orders match with each other
    /// @dev this may not necessarily be the same as taking the minimum of the two orders' quantities,
    /// because they may have already had some number of shares executed against them, meaning that their
    /// remaining number of shares is lower
    /// @return crosses true if the orders match with each other, false otherwise
    /// @return crossingTotalPrice the total price (measured in `denominationToken`) that should be be paid for this transaction
    function getCrossingTotalPrice(LimitOrder calldata takerOrder, LimitOrder calldata makerOrder, uint256 shareCount)
        public
        pure
        returns (bool crosses, uint256 crossingTotalPrice)
    {
        // orders must have same tokens
        if (
            takerOrder.assetToken != makerOrder.assetToken ||
            takerOrder.denominationToken != makerOrder.denominationToken
        ) {
            return (false, 0);
        }

        // orders must have opposite sides
        if ((takerOrder.isBuy && makerOrder.isBuy) || (!takerOrder.isBuy && !makerOrder.isBuy)) {
            return (false, 0);
        }

        if (takerOrder.isBuy) {
            if (takerOrder.price < makerOrder.price) {
                return (false, 0);
            }
        } else {
            if (takerOrder.price > makerOrder.price) {
                return (false, 0);
            }
        }

        bool valid;
        uint256 takerTotal;
        uint256 makerTotal;
        uint256 midPriceTotal;

        (valid, takerTotal) = takerOrder.price.tryMul(shareCount);
        require(valid, "taker price overflow");

        (valid, makerTotal) = makerOrder.price.tryMul(shareCount);
        require(valid, "maker price overflow");

        (valid, midPriceTotal) = takerTotal.tryAdd(makerTotal);
        require(valid, "total price overflow");

        return (true, midPriceTotal.div(2));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum SignatureType {
    SignatureEOA,
    SignatureContract
}

struct EOASignature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct Signature {
    SignatureType sigType;
    bytes signatureData;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}