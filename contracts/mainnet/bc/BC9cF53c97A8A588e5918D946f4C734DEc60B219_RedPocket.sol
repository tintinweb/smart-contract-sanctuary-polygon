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

pragma solidity 0.8.11;

struct RedPocketDetail {
    address creator;
    uint256 value;
    uint256 remainingBalance;
    uint256 split;
    bool isWhitelisted;
    address[] whitelist;
    address[] claimants;
}

interface IRedPocket {

    event redPocketCreated(address indexed creater, bytes32 indexed ID, uint256 value);

    event redPocketClaimed(address indexed claimant, bytes32 indexed ID, uint256 value);

    event redPocketDestroyed(bytes32 indexed ID);

    event redPocketEmptied(bytes32 indexed ID);

    // Creation & delete

    function createRedPocket(uint256 splitNumber) external payable;

    function createWhitelistedRedPocket(uint256 splitNumber, address[] calldata whitelist) external payable;

    function destroyRedPocket(bytes32 id) external;

    // Claim

    function claim(bytes32 id) external;

    // read

    function getRedPocketDetails(bytes32[] memory ids) external view returns(RedPocketDetail[] memory);
}

pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IRedPocket.sol";

contract RedPocket is IRedPocket {

    using SafeMath for uint256;

    mapping(bytes32 => RedPocketDetail) redPockets;
    mapping(bytes32 => mapping(address => bool)) whitelists;
    mapping(bytes32 => mapping(address => bool)) claimedUsers;

    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    function createRedPocket(uint256 splitNumber) public payable {

        createRedPocketInternal(splitNumber, false, new address[](0));
    }

    function createWhitelistedRedPocket(uint256 splitNumber, address[] calldata whitelist) public payable {
        createRedPocketInternal(splitNumber, true, whitelist);
    }

    function destroyRedPocket(bytes32 id) public {
        require(msg.sender == redPockets[id].creator, "Unauthorized");
        payable(redPockets[id].creator).transfer(redPockets[id].remainingBalance);
        redPockets[id].creator = ZERO_ADDRESS;
        emit redPocketDestroyed(id);
    }

    function claim(bytes32 id) public {
        require(redPockets[id].creator != ZERO_ADDRESS, "Red Pocket does not exist");
        require(! claimedUsers[id][msg.sender], "One address can only claim once per red pocket");

        RedPocketDetail storage detail = redPockets[id];
        uint256 numberOfClaims = detail.claimants.length;
        require(numberOfClaims < detail.split, "This red pocket has been fully claimed");
        
        if (detail.isWhitelisted) {
            require(whitelists[id][msg.sender], "Unauthorized");
        }

        uint256 valueClaimed = 0;
        if (detail.claimants.length == detail.split - 1) {
            valueClaimed = detail.remainingBalance;
            emit redPocketEmptied(id);
        } else {
            valueClaimed = detail.value.div(detail.split);
        }

        detail.claimants.push(msg.sender);
        claimedUsers[id][msg.sender] = true;
        payable(msg.sender).transfer(valueClaimed);
        detail.remainingBalance -= valueClaimed;

        emit redPocketClaimed(msg.sender, id, valueClaimed);
    }

    function getRedPocketDetails(bytes32[] memory ids) public view returns (RedPocketDetail[] memory) {
        RedPocketDetail[] memory details = new RedPocketDetail[](ids.length);
        for (uint i = 0; i < ids.length; i ++) {
            details[i] = redPockets[ids[i]];
        }
        return details;
    }

    // Internals

    function createRedPocketInternal(uint256 splitNumber, bool isWhitelisted, address[] memory whitelist) internal {
        require(splitNumber > 0, "Red pockets must have non-zero splits");
        uint256 value = msg.value;
        require(value > 0, "Cannot create empty red pocket");

        bytes32 id = keccak256(abi.encodePacked(msg.sender, value, splitNumber, block.timestamp));
        require(redPockets[id].creator == ZERO_ADDRESS);

        redPockets[id].creator = msg.sender;
        redPockets[id].value = value;
        redPockets[id].remainingBalance = value;
        redPockets[id].split = splitNumber;
        redPockets[id].isWhitelisted = isWhitelisted;
        if (isWhitelisted) {
            redPockets[id].whitelist = new address[](whitelist.length);
            for (uint i = 0; i < whitelist.length; i ++) {
                redPockets[id].whitelist[i] = whitelist[i];
                whitelists[id][whitelist[i]] = true;
            } 
        }

        emit redPocketCreated(msg.sender, id, value);
    }


}