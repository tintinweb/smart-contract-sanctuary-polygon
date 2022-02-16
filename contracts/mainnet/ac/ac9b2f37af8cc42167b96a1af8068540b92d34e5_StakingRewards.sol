/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
    IERC20 lpToken = IERC20(0x4B1F1e2435A9C96f7330FAea190Ef6A7C8D70001);
    IERC20 sushiT = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    Staking lpStakeContract =
        Staking(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    Swapping tokenSwap = Swapping(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    function deposit(uint256 _pid, uint256 _amount) public {
        lpToken.approve(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F, _amount);
        lpStakeContract.deposit(_pid, _amount, address(this));
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        lpStakeContract.withdraw(_pid, _amount, address(this));
    }

    function harvest(uint256 _pid) public {
        lpStakeContract.harvest(_pid, address(this));
      
    
    }
    function swap(uint256 amountToCashOut) public{

        sushiT.approve(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, amountToCashOut);
        tokenSwap.swapExactTokensForTokens(
             amountToCashOut,
            0,
            [
                0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
                0xc2132D05D31c914a87C6611C10748AEb04B58e8F
            ],
            address(this),  
            100000000000000000000000000000000
        );
    }

 function getData(uint256 _pid) view public returns(uint256 amountToCashOut){
       uint256 amountToCashOuts = lpStakeContract.pendingSushi(
            _pid,
            address(this)
        );
        return amountToCashOuts;
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
        address[2] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}