/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {

    IERC20 lpToken = IERC20(0x4B1F1e2435A9C96f7330FAea190Ef6A7C8D70001);
    Staking lpStakeContract=Staking(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);


 
    function deposit(uint256 _pid,uint256 _amount) public {
       lpToken.approve(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F, _amount);
       lpStakeContract.deposit(_pid, _amount,address(this));
    }
    function withdraw(uint256 _pid,uint256 _amount) public {
        lpStakeContract.withdraw(_pid, _amount,address(this));
    }

      function harvest(uint256 _pid) public {
        lpStakeContract.harvest(_pid,address(this));
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
   function  deposit(uint256 pid, uint256 _amount, address to) external;
   function withdraw(uint256 pid, uint256 _amount,address to) external;
   function harvest(uint256 pid, address to) external;
}