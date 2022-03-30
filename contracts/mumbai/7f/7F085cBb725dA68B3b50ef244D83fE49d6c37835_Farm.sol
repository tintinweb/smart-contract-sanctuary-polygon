// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Farm{
    bool public initCalled;
    
    
    struct UserInfo {
        uint256 amount;     // LP tokens provided.
        uint256 rewardDebt; // Reward debt.
    }

    struct FarmInfo {
        IERC20 lpToken;
        IERC20 rewardToken;
        uint startBlock;
        uint blockReward;
        uint bonusEndBlock;
        uint bonus;
        uint endBlock;
        uint lastRewardBlock;  // Last block number that reward distribution occurs.
        uint accRewardPerShare; // rewards per share, times 1e12
        uint farmableSupply; // total amount of tokens farmable
        uint numFarmers; // total amount of farmers
    }

    FarmInfo public farmInfo;
    mapping (address => UserInfo) public userInfo;

    uint256 public totalStakedAmount; 
    

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor() {}

    /**
     * @dev initialize farming contract, should be called only once
     * @param rewardToken token to be rewarded to the user (GFI)
     * @param amount amount of tokens to be farmed in total
     * @param depositToken ERC20 compatible (lp) token used for farming
     * @param blockReward token rewards per blockReward
     * @param start blocknumber to start farming
     * @param end blocknumber to stop farming
     * @param bonusEnd blocknumber to stop the bonus period
     * @param bonus bonus amount
     */
    function init(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) public {
        require(!initCalled, 'Gravity Finance: Init already called');
        require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "Farm does not have enough reward tokens to back initialization");
        IERC20 rewardT = IERC20(rewardToken);
        IERC20 lpT = IERC20(depositToken);
        farmInfo.rewardToken = rewardT;
        
        farmInfo.startBlock = start;
        farmInfo.blockReward = blockReward;
        farmInfo.bonusEndBlock = bonusEnd;
        farmInfo.bonus = bonus;
        
        uint256 lastRewardBlock = block.number > start ? block.number : start;
        farmInfo.lpToken = lpT;
        farmInfo.lastRewardBlock = lastRewardBlock;
        farmInfo.accRewardPerShare = 0;
        
        farmInfo.endBlock = end;
        farmInfo.farmableSupply = amount;
        initCalled = true;
    }

    /**
     * @dev Gets the reward multiplier over the given _from_block until _to block
     * @param _from_block the start of the period to measure rewards for
     * @param _to the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(uint256 _from_block, uint256 _to) public view returns (uint256) {
        uint256 _from = _from_block >= farmInfo.startBlock ? _from_block : farmInfo.startBlock;
        uint256 to = farmInfo.endBlock > _to ? _to : farmInfo.endBlock;
        if (to <= farmInfo.bonusEndBlock) {
            return (to - _from)* farmInfo.bonus;
        } else if (_from >= farmInfo.bonusEndBlock) {
            return to - _from;
        } else {
            return (farmInfo.bonusEndBlock -_from)*farmInfo.bonus + (to - farmInfo.bonusEndBlock);
        }
    }

    /**
     * @dev get pending reward token for address
     * @param _user the user for whom unclaimed tokens will be shown
     * @return total amount of withdrawable reward tokens
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = farmInfo.accRewardPerShare;
        uint256 lpSupply = totalStakedAmount;
        if (block.number > farmInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(farmInfo.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * farmInfo.blockReward;
            accRewardPerShare = accRewardPerShare + (tokenReward * 1e12)/lpSupply;
        }
        return (user.amount * accRewardPerShare)/1e12 - user.rewardDebt;
    }

    /**
     * @dev updates pool information to be up to date to the current block
     */
    function updatePool() public {
        if (block.number <= farmInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalStakedAmount;
        if (lpSupply == 0) {
            farmInfo.lastRewardBlock = block.number < farmInfo.endBlock ? block.number : farmInfo.endBlock;
            return;
        }
        uint256 multiplier = getMultiplier(farmInfo.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier * farmInfo.blockReward;
        farmInfo.accRewardPerShare = farmInfo.accRewardPerShare + (tokenReward * 1e12)/lpSupply;
        farmInfo.lastRewardBlock = block.number < farmInfo.endBlock ? block.number : farmInfo.endBlock;
    }

    /**
     * @dev deposit LP token function for msg.sender
     * @param _amount the total deposit amount
     */
    function deposit(uint256 _amount) public {
        require(farmInfo.startBlock <= block.number, 'Gravity Finance: Farming has not started!');
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) { //first pay out pending rewards if already farming
            uint256 pending = (user.amount * farmInfo.accRewardPerShare)/1e12 - user.rewardDebt;
            safeRewardTransfer(msg.sender, pending);
        }
        if (user.amount == 0 && _amount > 0) { //not farming already -> add farmer to total amount
            farmInfo.numFarmers += 1;
        }
        farmInfo.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        totalStakedAmount = totalStakedAmount + _amount; 
        user.amount += _amount;
        user.rewardDebt = (user.amount * farmInfo.accRewardPerShare)/1e12; //already rewarded tokens
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev withdraw LP token function for msg.sender
     * @param _amount the total withdrawable amount
     */
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Withdrawal request amount exceeds user farming amount");
        updatePool();
        if (user.amount == _amount && _amount > 0) { //withdraw everything -> less farmers
            farmInfo.numFarmers -= 1;
        }
        uint256 pending = (user.amount * farmInfo.accRewardPerShare)/1e12 - user.rewardDebt;
        safeRewardTransfer(msg.sender, pending);
        user.amount -= _amount;
        user.rewardDebt = (user.amount * farmInfo.accRewardPerShare)/1e12;
        totalStakedAmount = totalStakedAmount - _amount; 
        farmInfo.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev function to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
     */
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        totalStakedAmount = totalStakedAmount - _amount; 
        if (_amount > 0) {
            farmInfo.numFarmers -= 1;
        }
        farmInfo.lpToken.transfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    /**
     * @dev Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
     * @param _to the user address to transfer tokens to
     * @param _amount the total amount of tokens to transfer
     */
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = farmInfo.rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            farmInfo.rewardToken.transfer(_to, rewardBal);
        } else {
            farmInfo.rewardToken.transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}