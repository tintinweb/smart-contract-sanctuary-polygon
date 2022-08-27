/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

// Author: YiChong Li 
// Date: 2022 / 08 / 25

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/IERC20.sol



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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: contracts/AttackStake.sol


pragma solidity ^0.8.0;



contract AttackStaking {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    
  
    mapping(address => uint) public rewards;
    

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => uint) private _lastUpdateTimes;
    bool private _enableLock;
    address private _ownerAddr;

    event RewardUpdated(address account, uint rewards, uint lastUpdateTime);
    event Stake(address account, uint amount, uint amountSoFar);
    event Withdraw(address account, uint amount, uint amountRemaining);
    event ClaimReward(address account, uint amount);
    
   

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        _ownerAddr = msg.sender;
        _enableLock = false;
    }

   
    function enableLock() public {
        require(msg.sender == _ownerAddr, "You can enable Lock features.");
        _enableLock = false;
    }
    
    function enableUnLock() public {
        require(msg.sender == _ownerAddr, "You can enable Lock features.");
        _enableLock = true;
        
        
    }

    function earned(address account) public view returns (uint) {
        
        if (_totalSupply == 0) {
            return 0;
        }
        if (_enableLock == false){
            return 0;
        }
        else{ 
            uint256 reward = (_balances[account] *  (block.timestamp - _lastUpdateTimes[account])) / (365 * 24 hours * 5); 
            return reward;
        }
    }
    

    modifier updateReward(address account) {
        
        
        rewards[account] += earned(account);
        _lastUpdateTimes[account] = block.timestamp;
        emit RewardUpdated(account, rewards[account], _lastUpdateTimes[account]);
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount, _balances[msg.sender]);
    }

    function restake() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        _totalSupply += reward;
        _balances[msg.sender] += reward;
        rewards[msg.sender] = 0;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        bool sent = stakingToken.transfer(msg.sender, _amount);
        
        require(sent, "Stakingtoken transfer failed");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;

        emit Withdraw(msg.sender, _amount, _balances[msg.sender]);
    }

    function claimReward() external updateReward(msg.sender) {
        
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);

        emit ClaimReward(msg.sender, reward);
    }
    function getStackingAmount(address account) public view returns(uint){
        return _balances[account];   
    }

    function getDailyProfit(uint _amount) public view returns(uint){
        return (_balances[msg.sender] + _amount) / (365 * 5); 
    }

    function getEarnedAmount(address account) public view returns(uint){
        uint reward = (_balances[account] *  (block.timestamp - _lastUpdateTimes[account])) / (365 * 24 hours * 5); 
        reward += rewards[account];  
        return reward;
    }


}