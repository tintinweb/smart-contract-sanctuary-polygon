// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import "hardhat/console.sol";

library ShipFactoryLibrary {
    using SafeMath for uint256;
    using SafeMath for uint8;

    function getRandomShipPartIdForMint(
        uint256[] memory expandedValues, 
        uint256 amount, 
        bool isRewardMint, 
        uint256 rewardTokenIdStart, 
        uint256 standardTokenIdStart) 
        public 
        pure 
        returns (uint256[] memory shipPartIds) 
    {
        
        shipPartIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            
            if (isRewardMint) {

                shipPartIds[i] = 
                    getRandomRewardShipPartIdForMint(
                    expandedValues[i], 
                    expandedValues[i + amount], 
                    rewardTokenIdStart);
            }
            else {
                
                shipPartIds[i] = getStandardShipPartIdForMint(
                    expandedValues[i + amount], 
                    standardTokenIdStart);
            }
        }
    }
    
    function getRandomRewardShipPartIdForMint(uint256 shipRandomValue, uint256 shipPartRandomValue, uint256 rewardTokenIdStart) 
        public
        pure 
        returns (uint256 shipPartId) 
    {  
        uint256 shipRandom = shipRandomValue.mod(100).add(1); // percentage
        uint256 shipPartRandom = shipPartRandomValue.mod(5); // one of five ship parts

        if (shipRandom <= 2) { // 2%
            shipPartId = shipPartRandom + rewardTokenIdStart + 10;
        }
        else if (shipRandom <= 10) { // 10%
            shipPartId = shipPartRandom + rewardTokenIdStart + 5;
        }
        else { // 88%
            shipPartId = shipPartRandom + rewardTokenIdStart;
        }

        return shipPartId;
    }

    function getStandardShipPartIdForMint(uint256 shipPartRandomValue, uint256 standardTokenIdStart) 
        public
        pure 
        returns (uint256 shipPartId) 
    {  
        uint256 shipPartRandom = shipPartRandomValue.mod(5); // one of five ship parts

        shipPartId = shipPartRandom + standardTokenIdStart;

        return shipPartId;
    }

    function getNewShipCanClaimRewardArray(uint256 shipTypeId, uint256 mintedSupply, uint256 _maxShipPartSupply) 
        public 
        pure 
        returns (bool[] memory) 
    {
        bool[] memory canClaimReward = new bool[](5);

        if (shipTypeId > 2 )
        {
            return canClaimReward;
        }
    
        if (mintedSupply <= _maxShipPartSupply.div(5))
        {
            canClaimReward[0] = true;
        } 
        if (canClaimReward[0] == true || mintedSupply <= _maxShipPartSupply.div(5).mul(2))
        {
            canClaimReward[1] = true;
        }
        if (canClaimReward[1] == true || mintedSupply <= _maxShipPartSupply.div(5).mul(3))
        {
           canClaimReward[2] = true;
        }
        if (canClaimReward[2] == true || mintedSupply <= _maxShipPartSupply.div(5).mul(4))
        {
            canClaimReward[3] = true;
        }
        if (canClaimReward[3] == true || mintedSupply >= _maxShipPartSupply)
        {
            canClaimReward[4] = true;
        }  

        return canClaimReward;   
    }

    function isRequiredNumberofPartsMintedForReward(uint8 rewardIndex, uint256 mintedSupply, uint256 _maxShipPartSupply) 
        public 
        pure 
        returns (bool) 
    {
        // has the required number of parts been minted
        if (rewardIndex == 0 && mintedSupply > _maxShipPartSupply.div(5)) // 20%
        {
            return true;
        }
        
        if (rewardIndex == 1 && mintedSupply > _maxShipPartSupply.div(5).mul(2)) // 40%
        {
            return true;
        }
        
        if (rewardIndex == 2 && mintedSupply > _maxShipPartSupply.div(5).mul(3)) // 60%
        {
            return true;
        }
        
        if (rewardIndex == 3 && mintedSupply > _maxShipPartSupply.div(5).mul(4)) // 80%
        {
            return true;
        }
        
        if (rewardIndex == 4 && mintedSupply >= _maxShipPartSupply) // 100%
        {
            return true;
        }

        return false;
    }

    function getIndexForRewardShipSupply(uint256 mintedSupply, uint256 _maxShipPartSupply) 
        public 
        pure
        returns (uint8) 
    {
        if (mintedSupply <= _maxShipPartSupply.div(5))
        {
            return 0;
        } 
        
        if (mintedSupply <= _maxShipPartSupply.div(5).mul(2))
        {
            return 1;
        }
        
        if (mintedSupply <= _maxShipPartSupply.div(5).mul(3))
        {
           return 2;
        }

        if (mintedSupply <= _maxShipPartSupply.div(5).mul(4))
        {
            return 3;
        }
        
        return 4;
    }

    function getStakingBonus(uint256 durationStaked) private pure returns (uint256) {
        uint256 bonus = durationStaked.div(1 days).div(2);
        
        if (bonus > 50) {
            bonus = 50;
        }

        return bonus;
    }

    function getPayoutAmount(
        uint256 shipTypeId, 
        uint256 mintedCopperShips, 
        uint256 mintedSilverShips, 
        uint256 mintedGoldShips, 
        uint256 rewardBalance, 
        uint256 claimResult,
        uint256 maxShipPartSupply,
        uint8 rewardIndex,
        bool isRequiredPartsMinted) 
        public 
        pure
        returns (uint256 payout)
    {
        payout = 0;

        if (!isRequiredPartsMinted) // if claiming before the required number of parts have been minted
        {
            mintedCopperShips += getShipPartSupplyForRewardIndex(rewardIndex, maxShipPartSupply).div(5);
            mintedSilverShips += getShipPartSupplyForRewardIndex(rewardIndex, maxShipPartSupply).div(5);
            mintedGoldShips += getShipPartSupplyForRewardIndex(rewardIndex, maxShipPartSupply).div(5);
        }

        if (shipTypeId == 0)
        {
            if (mintedCopperShips > 0) {
                // 51% chance of earning reward
                if (claimResult <= 510)// + getStakingBonus(durationStaked))
                {
                    // 72% of rewardBalance allocated
                    payout = rewardBalance.mul(72).div(100).div(mintedCopperShips);
                }  
            } 
        } 
        else if (shipTypeId == 1)
        {
            if (mintedSilverShips > 0) {
                // 75% chance of earning reward
                if (claimResult <= 750)// + getStakingBonus(durationStaked))
                {
                    payout = rewardBalance.mul(15).div(100).div(mintedSilverShips);
                } 
            }
        }
        else if (shipTypeId == 2)
        {
            if (mintedGoldShips > 0) {
                // 99% chance of earning reward
                if (claimResult <= 990)
                {
                    payout = rewardBalance.mul(15).div(100).div(mintedSilverShips);
                } 
            }
        }
    }

    function getShipPartSupplyForRewardIndex(uint8 rewardIndex, uint256 maxShipPartSupply) internal pure returns(uint256) {
        if (rewardIndex == 0) {
            return maxShipPartSupply / 5;
        }
        if (rewardIndex == 1) {
            return maxShipPartSupply / 5 * 2;
        }
        if (rewardIndex == 2) {
            return maxShipPartSupply / 5 * 3;
        }
        if (rewardIndex == 3) {
            return maxShipPartSupply / 5 * 4;
        }
        return maxShipPartSupply;
    }

    function getStartIndexForShipTypeId(uint256 shipTypeId, uint256 rewardTokenIdStart, uint256 standardTokenIdStart) public pure returns(uint256 startIndex) {
        if (shipTypeId == 0) {
            startIndex = rewardTokenIdStart;
        } else if (shipTypeId == 1) {
            startIndex = rewardTokenIdStart + 5;
        }
        else if (shipTypeId == 2) {
            startIndex = rewardTokenIdStart + 10;
        }
        else if (shipTypeId == 3) {
            startIndex = standardTokenIdStart;
        }
    }

    function getRewardAllocationAmounts(
        uint256[5] storage rewardBalances,
        uint256 mintedSupply,
        uint256 _maxShipPartSupply,
        uint256 value
    ) 
        public
        view
        returns (
            uint256[5] memory rewardAllocations
        )
    {
        uint8 index = getIndexForRewardShipSupply(mintedSupply, _maxShipPartSupply);

        // calculate max reward balance for each reward
        uint256[] memory maxRewardBalances = new uint256[](5); 

        maxRewardBalances[0] = _maxShipPartSupply.mul(8).div(100).mul(value).div(5);
        maxRewardBalances[1] = _maxShipPartSupply.mul(14).div(100).mul(value).div(5);
        maxRewardBalances[2] = _maxShipPartSupply.mul(21).div(100).mul(value).div(5);
        maxRewardBalances[3] = _maxShipPartSupply.mul(26).div(100).mul(value).div(5);
        maxRewardBalances[4] = _maxShipPartSupply.mul(31).div(100).mul(value).div(5);

        if (rewardBalances[index] + value < maxRewardBalances[index])
        {
            rewardAllocations[index] += value;
        }
        else
        {
            uint256 rem = (rewardBalances[index] + value) - maxRewardBalances[index];
            rewardAllocations[index] += value - rem; 

            if (index < 4)
            {
                rewardAllocations[index + 1] += rem;
            }
        }

        return rewardAllocations;      
    }

    function getShipTypeName(uint256 shipTypeId) public pure returns(string memory name) {
        if (shipTypeId == 0) {
            return "Copper";
        } else if (shipTypeId == 1) {
            return "Silver";
        }
        else if (shipTypeId == 2) {
            return "Gold";
        }
        
        return "Standard";
    }
}