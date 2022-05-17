/**
 *Submitted for verification at polygonscan.com on 2022-05-17
*/

pragma solidity ^0.6.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MasterChef {
  /// @notice Store data about amount of locked reward tokens
  struct pendingRewards {
    uint256 startBlock;
    uint256 endBlock;
    uint256 amount;
    uint256 alreadyClaimed;
  }
  /// @notice An array of pendingRewards structs, storing data about user rewards
  mapping(address => pendingRewards[]) public pending;

  /**
   * @notice Get the number of pendingRewards not claimed yet
   * @param user Address of the user
   * @return Length of pending array
   */
  function pendingLength(address user) external view returns (uint256) {
    return pending[user].length;
  }
}

contract Read {
  using SafeMath for uint;

  MasterChef public target;
  address public admin;
  uint256 public lockupPeriodBlocks = 1296000;

  constructor() public {
    target = MasterChef(0xEF79881DF640B42bda6A84aC9435611Ec6Bb51A4);
    admin = msg.sender;
  }

  function set(uint256 _new, address _admin) external {
    require(msg.sender == admin, "!admin");
    lockupPeriodBlocks = _new;
    admin = _admin;
  }

  /**
   * @notice Get the sum of all pending unlocked tokens
   * @return Number of unlocked tokens that can be claimed without penalty
   */
  function unlockedTokens(address _user) external view returns (uint256) {
    uint256 length = target.pendingLength(_user);

    uint256 sumUnlocked;

    for (uint256 i = 0; i < length; i++){
      (uint256 startBlock, uint256 endBlock, uint256 amount, uint256 alreadyClaimed) = target.pending(_user, i);

      //already fully unlocked
      if (block.number.sub(lockupPeriodBlocks) >= endBlock){
        sumUnlocked += amount - alreadyClaimed;
      } else {
        if (block.number - startBlock < lockupPeriodBlocks){
          //nothing yet unlocked
        } else {
          //not yet fully unlocked
          uint256 duration = endBlock.sub(startBlock) > 0 ? endBlock.sub(startBlock) : 1;
          uint256 amountPerBlock = amount / duration;
          uint256 unlocked = (block.number - startBlock) * amountPerBlock;
          sumUnlocked += unlocked - alreadyClaimed;
        }
      }
    }

    return sumUnlocked;
  }

  /**
   * @notice Get the sum of all pending locked tokens
   * @return Number of locked tokens that will require paying 50% penalty if claimed
   */
  function lockedTokens(address _user) external view returns (uint256) {
    uint256 length = target.pendingLength(_user);

    uint256 sumLocked = 0;

    for (uint256 i = 0; i < length; i++){
      (uint256 startBlock, uint256 endBlock, uint256 amount, uint256 alreadyClaimed) = target.pending(_user, i);

      if (block.number.sub(lockupPeriodBlocks) >= endBlock){
        //already fully unlocked
      } else {
        if (block.number - startBlock < lockupPeriodBlocks){
          //nothing yet unlocked
          sumLocked += amount;
        } else {
          uint256 duration = endBlock.sub(startBlock) > 0 ? endBlock.sub(startBlock) : 1;
          uint256 amountPerBlock = amount / duration;
          uint256 unlocked = (block.number - startBlock) * amountPerBlock;
          sumLocked += amount - unlocked;
        }
      }
    }

    return sumLocked;
  }
}