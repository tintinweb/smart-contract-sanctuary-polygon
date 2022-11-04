/**
 *Submitted for verification at polygonscan.com on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract T369CoinStaking {
    using SafeMath for uint256;
    
    ERC20 public t369 = ERC20(0xF7C981df54c53b93ED8851C72Ce243e73C82fFC7);  // T369 Coin
    ERC20 public dai = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);  // DAI Coin
    address staker;
    uint8 price = 10;
    uint256 minStake = 20e18;
    uint256 totalSold;
    event Stake(address buyer, uint256 amount);
    event Release(address staker, uint256 amount);
    event DistributeStake(address staker, uint256 amount);
   
    modifier onlyStaker(){
        require(msg.sender == staker,"You are not authorized staker.");
        _;
    }

    function getBalanceSheet() view public returns(uint256 daiBalance, uint256 t369Balance, uint256 t369sold){
        return (dai.balanceOf(address(this)),t369.balanceOf(address(this)),totalSold);
    }

    modifier security {
        uint size;
        address sandbox = msg.sender;
        assembly { size := extcodesize(sandbox) }
        require(size == 0, "Smart contract detected!");
        _;
    }

    constructor() public {
        staker = msg.sender;
    }

    function stake(uint256 _dai) public security{
        require(_dai>=minStake,"Invalid investment!");
        dai.transferFrom(msg.sender,address(this),_dai);
        t369.transfer(msg.sender,_dai.mul(price));
        totalSold+=_dai.mul(price);
        emit Stake(msg.sender,_dai);
    }

    function distributeStake(address _staker, uint256 _amount) external onlyStaker security{
        dai.transfer(_staker,_amount);
        emit DistributeStake(_staker,_amount);
    }

    function releaseToken(address _staker, uint256 _amount) external onlyStaker security{
        t369.transfer(_staker,_amount);
        totalSold+=_amount.mul(price);
        emit Release(_staker,_amount);
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}