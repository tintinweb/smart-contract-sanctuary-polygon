// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;



import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract RootRouter is Ownable {
    using SafeMath for uint256;



    // ----- CUSTOM TYPES ----------------------------------------------------------------------------------------------

    enum CustomerNumberMode { Number, Pool }

    struct Router {
        uint128 chainId; // ────────┐
        uint128 poolCodeLength; // ─┘
        uint256 ttl;
        string adr;
    }

    struct CustomerNumber {
        bool isBlocked; // ─┐
        address owner; // ──┘
        uint256 subscriptionEndTime;
        CustomerNumberMode mode;
        string sipDomain;
        Router router;
    }

    struct NumberStatus {
        bool isBlocked; // ─────────┐
        bool isAvailable; //        │
        bool isHolded; //           │
        bool isAvailableForBuy; // ─┘
        uint256 subscriptionEndTime;
        uint256 holdingEndTime;
    }



    // ----- SETTINGS --------------------------------------------------------------------------------------------------

    uint256 constant public POOL_CODE_LENGTH = 3;
    uint256 constant public POOL_SIZE = 1000;

    uint256 public buyPrice = 10 ether;
    uint256 public subscriptionPrice = 7 ether;
    uint256 public modeChangePrice = 5 ether;
    uint256 public subscriptionDuration = 315532800; // 10 years
    uint256 public numberFreezeDuration = 7776000; // 3 months
    uint256 public defaultTtl = 864000; // 10 days

    string public defaultSipDomain = "sip.quic.pro";



    // ----- DATA ------------------------------------------------------------------------------------------------------

    CustomerNumber[POOL_SIZE] public pool;



    // ----- CONSTRUCTOR -----------------------------------------------------------------------------------------------

    constructor() {
        for (uint256 number; number < 100; number = number.add(1)) {
            pool[number].isBlocked = true;
        }
    }



    // ----- PUBLIC UTILS ----------------------------------------------------------------------------------------------

    function isValidNumber(uint256 number) public pure returns(bool) {
        return (number < POOL_SIZE);
    }

    function isNumberOwner(uint256 number, address adr) public view returns(bool) {
        require(isValidNumber(number), "Invalid number!");
        return isNumberOwner(pool[number], adr);
    }

    function isAvailable(uint256 number) public view returns(bool) {
        require(isValidNumber(number), "Invalid number!");
        return isAvailable(pool[number]);
    }

    function isBlocked(uint256 number) public view returns(bool) {
        require(isValidNumber(number), "Invalid number!");
        return isBlocked(pool[number]);
    }

    function isHolded(uint256 number) public view returns(bool) {
        require(isValidNumber(number), "Invalid number!");
        return isHolded(pool[number]);
    }

    function isAvailableForBuy(uint256 number) public view returns(bool) {
        require(isValidNumber(number), "Invalid number!");
        return isAvailableForBuy(pool[number]);
    }

    function isNumberMode(uint256 number) internal view returns(bool) {
        require(isValidNumber(number), "Invalid number!");
        return isNumberMode(pool[number]);
    }

    function isPoolMode(uint256 number) internal view returns(bool) {
        require(isValidNumber(number), "Invalid number!");
        return isPoolMode(pool[number]);
    }

    function getMode(uint256 number) public view returns(CustomerNumberMode) {
        require(isValidNumber(number), "Invalid number!");
        return pool[number].mode;
    }

    function getNumberStatus(uint256 number) public view returns(NumberStatus memory) {
        require(isValidNumber(number), "Invalid number!");

        CustomerNumber storage customerNumber = pool[number];
        return NumberStatus(
            isBlocked(customerNumber),
            isAvailable(customerNumber),
            isHolded(customerNumber),
            isAvailableForBuy(customerNumber),
            customerNumber.subscriptionEndTime,
            customerNumber.subscriptionEndTime.add(numberFreezeDuration)
        );
    }

    function getBlockedNumbers() public view returns(bool[POOL_SIZE] memory) {
        bool[POOL_SIZE] memory blockedNumbers;
        for (uint256 number; number < POOL_SIZE; number = number.add(1)) {
            blockedNumbers[number] = isBlocked(number);
        }
        return blockedNumbers;
    }

    function getAvailableNumbers() public view returns(bool[POOL_SIZE] memory) {
        bool[POOL_SIZE] memory availableNumbers;
        for (uint256 number; number < POOL_SIZE; number = number.add(1)) {
            availableNumbers[number] = isAvailable(number);
        }
        return availableNumbers;
    }

    function getHoldedNumbers() public view returns(bool[POOL_SIZE] memory) {
        bool[POOL_SIZE] memory holdedNumbers;
        for (uint256 number; number < POOL_SIZE; number = number.add(1)) {
            holdedNumbers[number] = isHolded(number);
        }
        return holdedNumbers;
    }

    function getAvailableForBuyNumbers() public view returns(bool[POOL_SIZE] memory) {
        bool[POOL_SIZE] memory availableForBuyNumbers;
        for (uint256 number; number < POOL_SIZE; number = number.add(1)) {
            availableForBuyNumbers[number] = isAvailableForBuy(number);
        }
        return availableForBuyNumbers;
    }



    // ----- INTERNAL UTILS --------------------------------------------------------------------------------------------

    function checkPayment(uint256 expected, uint256 received) internal view returns(bool) {
        return ((received >= expected) || (msg.sender == owner()));
    }

    function isNumberOwner(CustomerNumber storage customerNumber, address adr) internal view returns(bool) {
        return (
            (adr == owner()) ||
            (
                (customerNumber.owner == adr) &&
                (block.timestamp < customerNumber.subscriptionEndTime.add(numberFreezeDuration))
            )
        );
    }

    function isAvailable(CustomerNumber storage customerNumber) internal view returns(bool) {
        return ((customerNumber.owner == address(0)) && (block.timestamp > customerNumber.subscriptionEndTime));
    }

    function isBlocked(CustomerNumber storage customerNumber) internal view returns(bool) {
        return customerNumber.isBlocked;
    }

    function isHolded(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (
        (block.timestamp > customerNumber.subscriptionEndTime) &&
        (block.timestamp < customerNumber.subscriptionEndTime.add(numberFreezeDuration))
        );
    }

    function isAvailableForBuy(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (isAvailable(customerNumber) && !isBlocked(customerNumber) && !isHolded(customerNumber));
    }

    function isNumberMode(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (customerNumber.mode == CustomerNumberMode.Number);
    }

    function isPoolMode(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (customerNumber.mode == CustomerNumberMode.Pool);
    }

    function isEmptyString(string memory str) internal pure returns(bool) {
        return (bytes(str).length == 0);
    }

    function clearCustomerNumber(uint256 number) internal {
        delete pool[number];
    }



    // ----- SMART CONTRACT MANAGEMENT ---------------------------------------------------------------------------------

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBuyPrice(uint256 newBuyPrice) external onlyOwner {
        buyPrice = newBuyPrice;
    }

    function setSubscriptionPrice(uint256 newSubscriptionPrice) external onlyOwner {
        subscriptionPrice = newSubscriptionPrice;
    }

    function setModeChangePrice(uint256 newModeChangePrice) external onlyOwner {
        modeChangePrice = newModeChangePrice;
    }

    function setSubscriptionDuration(uint256 newSubscriptionDuration) external onlyOwner {
        subscriptionDuration = newSubscriptionDuration;
    }

    function setNumberFreezeDuration(uint256 newNumberFreezeDuration) external onlyOwner {
        numberFreezeDuration = newNumberFreezeDuration;
    }

    function setDefaultTtl(uint256 newDefaultTtl) external onlyOwner {
        defaultTtl = newDefaultTtl;
    }

    function setDefaultSipDomain(string memory newDefaultSipDomain) external onlyOwner {
        defaultSipDomain = newDefaultSipDomain;
    }

    function takeAwayOwnership(uint256 number) external onlyOwner {
        require(isValidNumber(number), "Invalid number!");

        clearCustomerNumber(number);
    }

    function setBlockedStatus(uint256 number, bool newBlockedStatus) external onlyOwner {
        require(isValidNumber(number), "Invalid number!");

        CustomerNumber storage customerNumber = pool[number];
        customerNumber.isBlocked = newBlockedStatus;
    }

    function setExpirationTime(uint256 number, uint256 newExpirationTime) external onlyOwner {
        require(isValidNumber(number), "Invalid number!");

        CustomerNumber storage customerNumber = pool[number];
        customerNumber.subscriptionEndTime = block.timestamp.add(newExpirationTime);
    }



    // ----- CUSTOMER NUMBER MANAGEMENT --------------------------------------------------------------------------------

    // TODO: Refactory to ERC721 (like ENS Name)
    function buy(uint256 number) external payable {
        require(isValidNumber(number), "Invalid number!");
        require(checkPayment(buyPrice, msg.value), "Insufficient funds!");

        CustomerNumber storage customerNumber = pool[number];
        require(isAvailableForBuy(customerNumber), "The number is not available for buy!");

        clearCustomerNumber(number);

        customerNumber.owner = msg.sender;
        customerNumber.subscriptionEndTime = block.timestamp.add(subscriptionDuration);
    }

    function renewSubscription(uint256 number) external payable returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];
        if (!checkPayment(subscriptionPrice, msg.value)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];

        customerNumber.subscriptionEndTime = customerNumber.subscriptionEndTime.add(subscriptionDuration);

        return ["200"];
    }

    function transferOwnershipOfCustomerNumber(uint256 number, address newOwner) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];

        customerNumber.owner = newOwner;

        return ["200"];
    }

    function renounceOwnershipOfCustomerNumber(uint256 number) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];

        clearCustomerNumber(number);

        return ["200"];
    }

    function changeCustomerNumberMode(uint256 number) external payable returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];
        if (!checkPayment(modeChangePrice, msg.value)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];

        if (isNumberMode(customerNumber)) {
            customerNumber.mode = CustomerNumberMode.Pool;
            delete customerNumber.sipDomain;
        } else {
            customerNumber.mode = CustomerNumberMode.Number;
            delete customerNumber.router;
        }

        return ["200"];
    }

    function setCustomerNumberSipDomain(uint256 number, string memory newSipDomain) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];
        if (!isNumberMode(customerNumber)) return ["400"];

        customerNumber.sipDomain = newSipDomain;

        return ["200"];
    }

    function clearCustomerNumberSipDomain(uint256 number) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];
        if (!isNumberMode(customerNumber)) return ["400"];

        delete customerNumber.sipDomain;

        return ["200"];
    }

    function setCustomerNumberRouter(uint256 number, Router memory newRouter) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];
        if (!isPoolMode(customerNumber)) return ["400"];

        customerNumber.router = newRouter;

        return ["200"];
    }

    function clearCustomerNumberRouter(uint256 number) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];
        if (!isPoolMode(customerNumber)) return ["400"];

        delete customerNumber.router;

        return ["200"];
    }

    function setCustomerNumberRouterTtl(uint256 number, uint256 newTtl) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];
        if (!isPoolMode(customerNumber)) return ["400"];

        customerNumber.router.ttl = newTtl;

        return ["200"];
    }

    function clearCustomerNumberRouterTtl(uint256 number) external returns(string[1] memory) {
        if (!isValidNumber(number)) return ["400"];

        CustomerNumber storage customerNumber = pool[number];
        if (!isNumberOwner(customerNumber, msg.sender)) return ["400"];
        if (isHolded(customerNumber)) return ["400"];
        if (!isPoolMode(customerNumber)) return ["400"];

        delete customerNumber.router.ttl;

        return ["200"];
    }



    // ----- ROUTING ---------------------------------------------------------------------------------------------------

    function getNextNode(uint256 number) public view returns(string[5] memory) {
        if (!isValidNumber(number)) return ["400", "", "", "", ""];

        CustomerNumber storage customerNumber = pool[number];
        if (isBlocked(customerNumber)) return ["400", "", "", "", ""];
        if (isAvailable(customerNumber)) return ["400", "", "", "", ""];
        if (isHolded(customerNumber)) return ["400", "", "", "", ""];

        if (isNumberMode(customerNumber)) {
            return [
                "200",
                "0",
                Strings.toHexString(customerNumber.owner),
                (isEmptyString(customerNumber.sipDomain) ? defaultSipDomain : customerNumber.sipDomain),
                ""
            ];
        } else {
            return [
                "200",
                Strings.toString(customerNumber.router.poolCodeLength),
                Strings.toString(customerNumber.router.chainId),
                customerNumber.router.adr,
                Strings.toString(customerNumber.router.ttl == 0 ? defaultTtl : customerNumber.router.ttl)
            ];
        }
    }
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
library SafeMath {
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