/**
 *Submitted for verification at polygonscan.com on 2022-03-23
*/

// SPDX-License-Identifier: MIT
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

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract StakingContract is ReEntrancyGuard{

    address public _link = 0x8A953CfE442c5E8855cc6c61b1293FA648BAE472;  // address of staked coin
    IERC20 token = IERC20(_link);
    //declaring owner state variable
    address public owner;

    address payable public devwalletAddress = payable(0xCea3d4c5282878c228687Fb1f07a456Fb5CAD1b7); // Dev Address
    

    //declaring APY for custom staking ( default 0.5%)
    uint256 public customAPY = 500;

    //dev fee % ( default 7%)
    uint256 public devFee = 70;

    //referral fee % ( default 5%)
    uint256 public refFee = 50;

    //declaring total staked
    uint256 public customTotalStaked;

    //users staking balance
    mapping(address => uint256) public customStakingBalance;
    mapping(address => uint256) public stakedTime;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public totalClaimedRewards;

    //Referral Mapping
    mapping(address => address) public referredBy;
    mapping(address => uint256) public totalRefferalClaimed;
    mapping(address => bool) public hasUsedrefferal;
    

    //mapping list of users who ever staked
    mapping(address => bool) public customHasStaked;

    //mapping list of users who are staking at the moment
    mapping(address => bool) public customIsStakingAtm;

    //array of all stakers
    address[] public stakers;
    address[] public customStakers;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor() public {
        owner = msg.sender;
    }

    function setDevAddress(address payable devAddress) external {
        require(msg.sender == owner , "Caller must be Owner!");
        devwalletAddress = devAddress;
    }

    function setDevFeePercent(uint256 Fee) external {
        require(msg.sender == owner , "Caller must be Owner!");
        devFee = Fee;
    }

    function setRefFeePercent(uint256 Fee) external {
        require(msg.sender == owner , "Caller must be Owner!");
        refFee = Fee;
    }

    function getRefferal(address account) external {
        require(referredBy[msg.sender] == address(0), "Referral Code Already Used!");
        require(account != msg.sender, "Cannot Refer Own Address!");
        referredBy[msg.sender] = account;
        hasUsedrefferal[msg.sender] = true;
    }

    /*
    function contractSTakingbalance() public view returns (uint256)
    {
        uint256 balance = token.balanceOf(address(this)) / 1000000000000000000;
        return balance;
    }*/

    // different APY Pool
    function customStaking(uint256 _amount) external noReentrant {
        require(_amount > 0, "amount cannot be 0");
        uint256 feeAmount = _amount * devFee / 1000;
        customTotalStaked = customTotalStaked + _amount;
        customStakingBalance[msg.sender] =
            customStakingBalance[msg.sender] +
            _amount;

        if (!customHasStaked[msg.sender]) {
            customStakers.push(msg.sender);
        }
        stakedTime[msg.sender] = block.timestamp;
        lastRewardTime[msg.sender] = block.timestamp;
        customHasStaked[msg.sender] = true;
        customIsStakingAtm[msg.sender] = true;
        token.transferFrom(msg.sender, address(this), _amount  );
        token.transfer(devwalletAddress, feeAmount  );
        if(referredBy[msg.sender] != address(0) && hasUsedrefferal[msg.sender] == true)
        {
            uint256 reffeeAmount = _amount * refFee / 1000;
            totalRefferalClaimed[referredBy[msg.sender]] = totalRefferalClaimed[referredBy[msg.sender]] + reffeeAmount;
            token.transfer(referredBy[msg.sender], reffeeAmount  );
        }
    }

    /*
    function customUnstake() external noReentrant {
        uint256 balance = customStakingBalance[msg.sender];
        require(balance > 0, "amount has to be more than 0");
        require(token.balanceOf(address(this)) >= balance, "Contract Out of Gas!");
        token.transfer(msg.sender,balance);
        customTotalStaked = customTotalStaked - balance;
        customStakingBalance[msg.sender] = 0;
        customIsStakingAtm[msg.sender] = false;
        customHasStaked[msg.sender] = false;
        stakedTime[msg.sender] = 0;
        lastRewardTime[msg.sender] = 0;
        totalClaimedRewards[msg.sender] = 0;
    }*/

    //change APY value for custom staking
    function changeAPY(uint256 _value) external {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        customAPY = _value;
    }

        //claim reward
    function claimRewards() noReentrant external {
            address recipient = msg.sender;
            require(customIsStakingAtm[recipient] == true, "No Tokens Staked by Caller!");
            uint256 numdays = (block.timestamp - lastRewardTime[recipient]) / 86400;
            require(numdays > 0 , "Reward Already Claimed in Last 24 Hours!");
            uint256 maxpossibleReward = customStakingBalance[recipient] * customAPY * 75 / 100000;
            require(totalClaimedRewards[recipient] < maxpossibleReward , "Max Reward Already Claimed!");
            if(numdays >= 75)
            {
                numdays = 75;
            }
            uint256 balance = customStakingBalance[recipient] * customAPY * numdays;
            balance = balance / 100000;

            if (balance > 0) {
                token.transfer(recipient, balance);
                //customTotalStaked = customTotalStaked - balance;
                lastRewardTime[recipient] = block.timestamp;
                totalClaimedRewards[recipient] = totalClaimedRewards[recipient] + balance;
            }
        
    }

    function unclaimedrewards(address account) public view returns (uint256)
    {
        uint256 numdays = (block.timestamp - lastRewardTime[account]) ;
        uint256 balance = customStakingBalance[account] * customAPY * numdays;
        
        balance = balance / 100000 / 86400;
        
        return balance;
    }

    function nextClaim(address account) public view returns (uint256)
    {
        uint256 nextclaimTime = lastRewardTime[account] + 86400;
        return nextclaimTime;
    }

    function recoverBalance() noReentrant external {
        require(msg.sender == owner, "Only Owner may call!");
        token.transfer(owner,token.balanceOf(address(this)));
        customTotalStaked = 0;
    }

}