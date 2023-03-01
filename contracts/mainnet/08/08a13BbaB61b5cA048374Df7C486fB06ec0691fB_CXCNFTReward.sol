/**
 *Submitted for verification at polygonscan.com on 2023-02-27
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/CXCNFTReward.sol


pragma solidity ^0.8.6;


interface CXCStaking {
    function getStakedTokenByID(address wallet, uint256 tokenID) external view returns (uint256);
    function getTotalStaked() external view returns (uint256);
}

contract CXCNFTReward {

    using SafeMath for uint256;
    address private immutable robotZero = 0x051bD3A5E4a94522B19AA42E8b3Ad10120838B14;
    address private immutable stakingContract = 0x7a050b710E56Fd78d680093896C553dDac63E543;

    uint256 private immutable startTime = 1675573200;
    uint256 private immutable timeStep = 1 days;
    uint256 public lastDistribute;

    uint256 public allTimeReward;

    mapping(uint256 => uint256) public dailyDeposit;
    mapping(uint256 => uint256) public dailyStakedNFT;
    mapping(uint256 => uint256) public dailyReward;
    mapping(address => uint256) public claimHistory;
    mapping(address => uint256) public claimedDays;
    mapping(address => mapping(uint256 => bool)) public claimedToday;
    mapping(address => bool) public rewardAccumulate;

    receive() external payable {
        uint256 today = getCurDay();
        dailyDeposit[today] += msg.value;
    }

    fallback() external payable {}

    constructor() {
        lastDistribute = startTime;
    }

    function distributeReward() external {
        if (block.timestamp >= lastDistribute.add(timeStep)) {
            uint256 today = getCurDay();
            dailyStakedNFT[today.sub(1)] = CXCStaking(stakingContract).getTotalStaked();
            dailyReward[today.sub(1)] = dailyDeposit[today.sub(1)].div(dailyStakedNFT[today.sub(1)]);
            allTimeReward += dailyReward[today.sub(1)];
            lastDistribute = startTime.add(today.mul(timeStep));
        }
    }

    function claimReward() external {
        require(claimedToday[msg.sender][getCurDay()] == false, "This wallet already claimed reward today.");
        require(getStakingData(msg.sender) > 0, "No staked NFT found for this wallet.");
        require(claimedDays[msg.sender] > 0, "Invalid claimed days. Activation required.");
        uint256 reward = getClaimableReward(msg.sender);
        require(getCurBalance() >= reward, "Contract insufficient balance for this claim.");
        (bool claimSuccess, ) = payable(msg.sender).call{value: reward}("");
        require(claimSuccess, "Claim reward failed.");
        claimHistory[msg.sender] += reward;
        claimedDays[msg.sender] = getCurDay().sub(1);
        claimedToday[msg.sender][getCurDay()] = true;
    }

    function activateRewardAccumulation() external {
        require(rewardAccumulate[msg.sender] == false && claimedDays[msg.sender] == 0, "Reward accumulation is active.");
        claimedDays[msg.sender] = getCurDay();
        rewardAccumulate[msg.sender] = true;
    }

    function getStakingData(address wallet) public view returns (uint256) {
        uint256 score;
        for (uint256 i = 1; i <= 101; i++) {
            score += CXCStaking(stakingContract).getStakedTokenByID(wallet, i);
        }
        return score;
    }

    function getClaimableReward(address wallet) public view returns (uint256) {
        uint256 claimable;
        if (rewardAccumulate[wallet] == false) {
            claimable = 0;
        } else {
            for (uint256 i = claimedDays[wallet]; i < getCurDay(); i++) {
                claimable += dailyReward[i];
            }
        }
        uint256 stakedNFT = getStakingData(wallet);
        if (claimedToday[wallet][getCurDay()] == true) {
            return 0;
        } else {
            return claimable.mul(stakedNFT);
        }
    }

    function getCurBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getClaimStatus(address wallet) public view returns (bool) {
        uint256 today = getCurDay();
        return claimedToday[wallet][today];
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

}