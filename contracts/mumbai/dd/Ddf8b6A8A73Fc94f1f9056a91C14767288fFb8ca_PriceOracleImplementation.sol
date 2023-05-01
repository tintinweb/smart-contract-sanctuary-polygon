/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

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

interface PriceOracle {
    /**
     * @dev Returns the price to register.
     * @param condition keccak256 multiple conditions, like payment token address, duration, length, etc.
     * @return The price of this registration.
     */
    function getPrice(bytes32 tld, bytes32 condition) external view returns(uint);

    /**
     * @dev Returns the payment token addresses according to a specific tld.
     * @param tld keccak256 tld.
     * @return The payment token addresses.
     */
    function getSupportedPayment(bytes32 tld) external view returns(address[] memory);

    /**
     * @dev Returns the permanent ownership status of subnode belonged to a tld.
     * @param tld keccak256 tld.
     * @return The permanent ownership status of subnode belonged to a tld
     */
    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool);

    function receivingAddress(bytes32 tld) external view returns(address);
}

contract PriceOracleImplementation {
    using StringUtils for string;
    using SafeMath for uint;
    
    address public registryController;
    mapping(address=>bool) public whitelist;
    bool whitelistEnabled;

    struct TldOwner {
        address owner;
        address receivingAddress;
        bool permanent;
        address[] supportedPayment;
    }
    mapping(bytes32=>TldOwner) public tldToOwner;
    mapping(address=>bytes32) public ownerToTld;

    // A map of conditions that correspond to prices.
    mapping(bytes32=>mapping(bytes32=>uint)) public prices;


    event SetPrice(bytes32 indexed condition, uint indexed price);
    event SetPermanentOwnership(bytes32 indexed tld, bool indexed enable);
    event SetSupportedPayment(bytes32 indexed tld, address[] tokens);

    modifier onlyController {
        require(registryController == msg.sender);
        _;
    }

    constructor(address _registryController) public {
        registryController = _registryController;
        whitelistEnabled = true;
    }

    function updateWhitelist(address member, bool enabled) onlyController public {
        whitelist[member] = enabled;
    }

    function setWhitelistEnabled(bool enabled) onlyController public {
        whitelistEnabled = enabled;
    }

    function setTld(string memory tld, address receiveWallet, bytes32[] memory condition, uint[] memory price, address[] memory payment, bool permanent) public {
        require(tld.strlen() == 3);
        if(whitelistEnabled && !whitelist[msg.sender]) {
            revert('Not authorized');
        }
        bytes32 tldHash = keccak256(bytes(tld));
        if(tldToOwner[tldHash].owner != address(0)) {
            require(tldToOwner[tldHash].owner == msg.sender, 'Not tld owner');
        }
        tldToOwner[tldHash] = TldOwner({owner : msg.sender, receivingAddress : receiveWallet, permanent : permanent, supportedPayment: payment});
        ownerToTld[msg.sender] = tldHash;
        require(condition.length == price.length);
        for(uint i = 0; i < condition.length; i++) {
            prices[tldHash][condition[i]] = price[i];
        }
    }
    
    function setReceiveAddress(address receiveWallet) public {
        require(ownerToTld[msg.sender] != bytes32(0));
        tldToOwner[ownerToTld[msg.sender]].receivingAddress = receiveWallet;
    }

    function getPrice(bytes32 tld, bytes32 condition) external view returns(uint) {
        return prices[tld][condition].div(100);
    }
    
    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool) {
        return tldToOwner[tld].permanent;
    }

    function getSupportedPayment(bytes32 tld) public view returns (address[] memory){
        return tldToOwner[tld].supportedPayment;
    }
    
    function receivingAddress(bytes32 tld) external view returns(address) {
        return tldToOwner[tld].receivingAddress;
    }
}