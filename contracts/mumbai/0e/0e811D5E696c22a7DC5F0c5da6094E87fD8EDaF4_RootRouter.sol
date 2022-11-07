// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


// TODO: Add possibility of hold
contract RootRouter is Ownable {
    using SafeMath for uint256;



    // ----- CUSTOM TYPES ------------------------------------------------------

    enum CustomerNumberMode { Number, Pool }

    struct Router {
        uint128 chainId;
        string adr;
        uint128 poolCodeLength;
    }

    struct CustomerNumber {
        bool isBlocked;
        address owner;
        uint256 subscriptionEndTime;
        CustomerNumberMode mode;
        Router router;
    }

    struct NumberStatus {
        bool isBlocked;
        bool isFree;
        bool isHolded;
        bool isAvailableForBuy;
        uint256 subscriptionEndTime;
        uint256 holdingEndTime;
    }



    // ----- SETTINGS ----------------------------------------------------------

    uint256 constant public POOL_CODE_LENGTH = 3;
    uint256 constant public POOL_SIZE = 1000;
    uint256 constant public MIN_NUMBER = 100;
    uint256 constant public MAX_NUMBER = 999;

    uint256 public buyPrice = 10 ether;
    uint256 public subscriptionPrice = 7 ether;
    uint256 public modeChangePrice = 5 ether;
    uint256 public subscriptionDuration = 315532800; // 10 years
    uint256 public numberFreezeDuration = 7776000; // 3 months
    // TODO: Refactory TTL globaly
    uint256 public ttl = 864000; // 10 days

    string public sipDomain = "sip.quic.pro";



    // ----- DATA --------------------------------------------------------------

    CustomerNumber[POOL_SIZE] public pool;



    // ----- CONSTRUCTOR -------------------------------------------------------

    constructor() {
        for (uint256 number; number < MIN_NUMBER; number = number.add(1)) {
            pool[number].isBlocked = true;
        }
    }



    // ----- PUBLIC UTILS ------------------------------------------------------

    function isValidNumber(uint256 number) internal pure returns(bool) {
        return ((number >= MIN_NUMBER) && (number <= MAX_NUMBER));
    }

    function checkPayment(uint256 received, uint256 expected) internal view returns(bool) {
        return ((received >= expected) || (msg.sender == owner()));
    }

    function isAddressNumberOwner(uint256 number, address addressNumberOwner) public view returns(bool) {
        if (!isValidNumber(number)) {
            return false;
        }

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        return ((addressNumberOwner == owner()) || ((customerNumber.owner == addressNumberOwner) && (block.timestamp < customerNumber.subscriptionEndTime)));
    }

    function isFree(uint256 number) public view returns(bool) {
        return isFree(getCustomerNumber(number));
    }

    function isBlocked(uint256 number) public view returns(bool) {
        return isBlocked(getCustomerNumber(number));
    }

    function isHolded(uint256 number) public view returns(bool) {
        return isHolded(getCustomerNumber(number));
    }

    function isAvailableForBuy(uint256 number) public view returns(bool) {
        CustomerNumber storage customerNumber = getCustomerNumber(number);
        return isAvailableForBuy(customerNumber);
    }

    function getMode(uint256 number) public view returns(CustomerNumberMode) {
        CustomerNumber storage customerNumber = getCustomerNumber(number);
        return customerNumber.mode;
    }

    function getNumberStatus(uint256 number) public view returns(NumberStatus memory) {
        CustomerNumber storage customerNumber = getCustomerNumber(number);
        return NumberStatus(
            isBlocked(customerNumber),
            isFree(customerNumber),
            isHolded(customerNumber),
            isAvailableForBuy(customerNumber),
            customerNumber.subscriptionEndTime,
            customerNumber.subscriptionEndTime.add(numberFreezeDuration)
        );
    }

    function getBlockedNumber() public view returns(bool[POOL_SIZE] memory) {
        bool[1000] memory blockedNumbers;
        for (uint256 number; number < POOL_SIZE; number = number.add(1)) {
            blockedNumbers[number] = isBlocked(number);
        }
        return blockedNumbers;
    }

    function getFreeNumber() public view returns(bool[POOL_SIZE] memory) {
        bool[1000] memory freeNumbers;
        for (uint256 number; number < POOL_SIZE; number = number.add(1)) {
            freeNumbers[number] = isFree(number);
        }
        return freeNumbers;
    }

     function getHoldedNumber() public view returns(bool[POOL_SIZE] memory) {
        bool[1000] memory holdedNumbers;
        for (uint256 number; number < POOL_SIZE; number = number.add(1)) {
            holdedNumbers[number] = isHolded(number);
        }
        return holdedNumbers;
    }



    // ----- INTERNAL UTILS ----------------------------------------------------

    function getCustomerNumber(uint256 number) internal view returns(CustomerNumber storage) {
        return pool[number];
    }

    function isFree(CustomerNumber storage customerNumber) internal view returns(bool) {
        return ((customerNumber.owner != address(0)) && (block.timestamp > customerNumber.subscriptionEndTime));
    }

    function isBlocked(CustomerNumber storage customerNumber) internal view returns(bool) {
        return customerNumber.isBlocked;
    }

    function isHolded(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (
            (block.timestamp > customerNumber.subscriptionEndTime) &&
            (block.timestamp.sub(customerNumber.subscriptionEndTime) < numberFreezeDuration)
        );
    }

    function isAvailableForBuy(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (!isFree(customerNumber) && !isBlocked(customerNumber) && !isHolded(customerNumber));
    }

    function isNumberMode(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (customerNumber.mode == CustomerNumberMode.Number);
    }

    function isPoolMode(CustomerNumber storage customerNumber) internal view returns(bool) {
        return (customerNumber.mode == CustomerNumberMode.Pool);
    }

    function clearCustomerNumber(uint256 number) internal {
        CustomerNumber storage customerNumber = getCustomerNumber(number);
        customerNumber.owner = address(0);
        customerNumber.subscriptionEndTime = block.timestamp;
        customerNumber.isBlocked = false;
        customerNumber.mode = CustomerNumberMode.Number;
        customerNumber.router = Router(0, Strings.toHexString(address(0)), 0);
    }



    // ----- SMART CONTRACT MANAGEMENT ------------------------------------------

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBuyPrice(uint256 newBuyPrice) external onlyOwner {
        buyPrice = newBuyPrice;
    }

    function setSubscriptionPricePrice(uint256 newSubscriptionPrice) external onlyOwner {
        subscriptionPrice = newSubscriptionPrice;
    }

    function setNumberFreezeDuration(uint256 newNumberFreezeDuration) external onlyOwner {
        numberFreezeDuration = newNumberFreezeDuration;
    }

    function setModeChangePrice(uint256 newModeChangePrice) external onlyOwner {
        modeChangePrice = newModeChangePrice;
    }

    function setSubscriptionDuration(uint256 newSubscriptionDuration) external onlyOwner {
        subscriptionDuration = newSubscriptionDuration;
    }

    function setTtl(uint256 newTtl) external onlyOwner {
        ttl = newTtl;
    }

    function setSipDomain(string memory newSipDomain) external onlyOwner {
        sipDomain = newSipDomain;
    }

    function takeAwayOwnership(uint256 number) external onlyOwner {
        require(isValidNumber(number), "Invalid number!");

        clearCustomerNumber(number);
    }

    function setBlockedStatus(uint256 number, bool blockedStatus) external onlyOwner {
        require(isValidNumber(number), "Invalid number!");

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        customerNumber.isBlocked = blockedStatus;
    }

    function setExpirationTime(uint256 number, uint256 newExpirationTime) external onlyOwner {
        require(isValidNumber(number), "Invalid number!");

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        customerNumber.subscriptionEndTime = block.timestamp.add(newExpirationTime);
    }



    // ----- CUSTOMER NUMBER MANAGEMENT -----------------------------------------

    // TODO: Refactory to ERC721 (like ENS Name)
    function buy(uint256 number) external payable {
        require(isValidNumber(number), "Invalid number!");
        require(checkPayment(msg.value, buyPrice), "Insufficient funds!");
        require(isFree(number), "The customerNumber already has an owner!");

        clearCustomerNumber(number);

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        customerNumber.owner = msg.sender;
        customerNumber.subscriptionEndTime = block.timestamp.add(subscriptionDuration);
    }

    function renewSubscription(uint256 number) external payable returns(string[1] memory) {
        if (!isAddressNumberOwner(number, msg.sender) || !checkPayment(msg.value, subscriptionPrice)) {
            return ["400"];
        }

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        customerNumber.subscriptionEndTime = customerNumber.subscriptionEndTime.add(subscriptionDuration);

        return ["200"];
    }

    function changeCustomerNumberMode(uint256 number) external payable returns(string[1] memory) {
        if (!isAddressNumberOwner(number, msg.sender) || !checkPayment(msg.value, modeChangePrice)) {
            return ["400"];
        }

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        if (isNumberMode(customerNumber)) {
            customerNumber.mode = CustomerNumberMode.Pool;
        } else {
            customerNumber.mode = CustomerNumberMode.Number;
            customerNumber.router = Router(0, Strings.toHexString(address(0)), 0);
        }

        return ["200"];
    }

    function setCustomerNumberRouter(uint256 number, uint128 chainId, string memory adr, uint128 poolCodeLength) external returns(string[1] memory) {
        if (!isAddressNumberOwner(number, msg.sender)) {
            return ["400"];
        }

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        require(isPoolMode(customerNumber), "The CustomerNumber is not a pool!");

        customerNumber.router.chainId = chainId;
        customerNumber.router.adr = adr;
        customerNumber.router.poolCodeLength = poolCodeLength;

        return ["200"];
    }

    function transferOwnershipOfCustomerNumber(uint256 number, address newOwner) external returns(string[1] memory) {
        if (!isAddressNumberOwner(number, msg.sender)) {
            return ["400"];
        }

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        customerNumber.owner = newOwner;

        return ["200"];
    }



    // ----- ROUTING ------------------------------------------------------------

    function getNextNode(uint256 number) public view returns(string[] memory) {
        if (!isValidNumber(number) || isFree(number)) {
            string[] memory result = new string[](1);
            result[0] = "400";
            return result;
        }

        CustomerNumber storage customerNumber = getCustomerNumber(number);
        if (isNumberMode(customerNumber)) {
            string[] memory result = new string[](5);
            result[0] = "200";
            result[1] = customerNumber.isBlocked ? "1" : "0";
            result[2] = "0";
            result[3] = Strings.toHexString(customerNumber.owner);
            result[4] = sipDomain;

            return result;
        } else {
            string[] memory result = new string[](6);
            result[0] = "200";
            result[1] = customerNumber.isBlocked ? "1" : "0";
            result[2] = Strings.toString(customerNumber.router.poolCodeLength);
            result[3] = Strings.toString(customerNumber.router.chainId);
            result[4] = customerNumber.router.adr;
            result[5] = Strings.toString(ttl);

            return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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