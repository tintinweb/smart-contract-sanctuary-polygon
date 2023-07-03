/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: MesV2.sol


pragma solidity ^0.8.7;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MustasheChat {
    using SafeMath for uint256;

    uint256 public constant messageExpiration = 24 hours;
    uint256 public constant maxChatMessages = 100;

    struct User {
        string name;
        bool isRegistered;
        uint256 lastTransactionTimestamp;
    }

    struct Message {
        string sender;
        string text;
        uint256 timestamp;
    }

    mapping(address => User) public users;
    mapping(string => bool) private registeredNames;
    Message[] public publicChatMessages;
    address private contractOwner;
    address private tokenAddress;
    uint256 public nameChangePrice;

    event UserRegistered(address indexed userAddress, string name);
    event PublicMessageSent(string indexed sender, string text);
    event NameChanged(address indexed userAddress, string newName);
    event PriceUpdated(uint256 newPrice);

    constructor(address _tokenAddress, uint256 _nameChangePrice) {
        contractOwner = msg.sender;
        tokenAddress = _tokenAddress;
        nameChangePrice = _nameChangePrice;
       
        users[msg.sender].lastTransactionTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
        _;
    }

    function registerUser(string memory _name) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!users[msg.sender].isRegistered, "User already registered");
        require(!registeredNames[_name], "Name is already registered");

        users[msg.sender].name = _name;
        users[msg.sender].isRegistered = true;
        registeredNames[_name] = true;

        emit UserRegistered(msg.sender, _name);
    }

    function sendPublicMessage(string memory _text) external {
        require(bytes(_text).length > 0, "Message text cannot be empty");
        require(users[msg.sender].isRegistered, "User is not registered");

        Message memory message = Message(users[msg.sender].name, _text, block.timestamp);
        publicChatMessages.push(message);

        users[msg.sender].lastTransactionTimestamp = block.timestamp;

        emit PublicMessageSent(users[msg.sender].name, _text);

        if (publicChatMessages.length > maxChatMessages) {
            
            uint256 deleteCount = publicChatMessages.length - maxChatMessages;

            for (uint256 i = 0; i < deleteCount; i++) {
                delete publicChatMessages[i];
            }

            for (uint256 i = deleteCount; i < publicChatMessages.length; i++) {
                publicChatMessages[i - deleteCount] = publicChatMessages[i];
            }

            publicChatMessages.pop();
        }
    }

    function getPublicChatMessages() external view returns (Message[] memory) {
        return publicChatMessages;
    }

    function updateName(string memory _newName) external {
        require(bytes(_newName).length > 0, "Name cannot be empty");
        require(users[msg.sender].isRegistered, "User is not registered");
        require(!registeredNames[_newName], "Name is already registered");

        IERC20 token = IERC20(tokenAddress);

        uint256 price = getNameChangePrice();
        require(token.balanceOf(msg.sender) >= price, "Insufficient tokens");

        uint256 tokensToSend = price.mul(10**18);

        require(token.transferFrom(msg.sender, address(this), tokensToSend), "Token transfer failed");

        registeredNames[users[msg.sender].name] = false;
        registeredNames[_newName] = true;
        users[msg.sender].name = _newName;

        emit NameChanged(msg.sender, _newName);
    }

    function cleanupMessages() external onlyOwner {
        delete publicChatMessages;
    }

    function updatePrice(uint256 _newPrice) external onlyOwner {
        nameChangePrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    function withdrawTokens(address recipient) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(recipient, balance), "Failed to transfer tokens");
    }

    function getNameChangePrice() public view returns (uint256) {
        return nameChangePrice;
    }
}