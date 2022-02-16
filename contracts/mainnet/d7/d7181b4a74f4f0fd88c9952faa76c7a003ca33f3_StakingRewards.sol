/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
    uint256 public tokenRewardRateH = 100000000;
    uint256 public tokenRewardRateL = 100000000;
    address owner = 0xCDeF3CC7cDBdC8695674973Ad015D9f2B01dD4C4;
    mapping(address => uint256) public rewardTime;
    mapping(address => uint256) public stakeAmount;

    IERC20 rewardsToken = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);  //usdt
    IERC20 lpToken = IERC20(0x4B1F1e2435A9C96f7330FAea190Ef6A7C8D70001);
    Staking lpStakeContract = Staking(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    Swapping tokenSwap = Swapping(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IERC20 sushiT = IERC20(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
    

    function stake(uint256 amount,uint256 _pid) public {
        require(amount > 0);
        require(rewardTime[msg.sender] == 0);
        require(stakeAmount[msg.sender] == 0);
        lpToken.transferFrom(msg.sender, address(this), amount);

        rewardTime[msg.sender] = block.timestamp;
        stakeAmount[msg.sender] = amount;

        lpToken.approve(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F, amount);
        lpStakeContract.deposit(_pid, amount, address(this));


    }

    function claimRewards(uint256 _pid,address[] calldata path) public {
        require(stakeAmount[msg.sender] > 0);
        lpStakeContract.harvest(_pid, address(this));
    //    uint256 amountToCashOut = lpStakeContract.pendingSushi(
    //         _pid,
    //         address(this)
    //     );
      //  sushiT.approve(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, amountToCashOut);
        // tokenSwap.swapExactTokensForTokens(
        //      amountToCashOut,
        //     0,
        //     path,
        //     address(this),  
        //     block.timestamp
        // );
     //   uint256 rewardAmount = 100;
       // uint256 rewardAmount = ((block.timestamp - rewardTime[msg.sender]) *tokenRewardRateH *stakeAmount[msg.sender]) / tokenRewardRateL;
      //  rewardTime[msg.sender] = block.timestamp;
      //  rewardsToken.transfer(msg.sender, rewardAmount);
    }

    function unstake(uint256 _pid,uint256 _amount) public {

         lpStakeContract.withdraw(_pid, _amount, address(this));
         lpToken.transfer(msg.sender, stakeAmount[msg.sender]);

    }

    function changeRate(uint256 new_rateH, uint256 new_rateL)
        public
        restricted
    {
        tokenRewardRateH = new_rateH;
        tokenRewardRateL = new_rateL;
    }
    function checkRewards(uint256 _pid) view public returns(uint256 amount){
        uint256 amountToCashOut = lpStakeContract.pendingSushi(
            _pid,
            address(this)
        );
        return amountToCashOut;
    }

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface Staking {
    function deposit(
        uint256 pid,
        uint256 _amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 _amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending);
}

interface Swapping {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}