/**
 *Submitted for verification at polygonscan.com on 2023-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract MetaMaticRider{
    using SafeMath for uint256;
    ERC20 public DAI = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    event Deposit(address depositor, uint256 amount);
    event Distribution(address receiver, uint256 amount);

    address aggregator;
   
    modifier onlyAggregator(){
        require(msg.sender == aggregator,"You are not authorized aggregator.");
        _;
    }

    modifier security {
        uint size;
        address sandbox = msg.sender;
        assembly { size := extcodesize(sandbox) }
        require(size == 0, "Smart contract detected!");
        _;
    }
    
    function getContractInfo(address coin) view public returns(uint256){
        return ERC20(coin).balanceOf(address(this));
    }

    constructor() {
        aggregator = msg.sender;
    }

    function deposit(uint256 _amount) public security {
        require(_amount>=1e18,"Invalid Investment");
        DAI.transferFrom(msg.sender,address(this),_amount);
        emit Deposit(msg.sender,_amount);
    }
    
    function WagesDistribution(address _wager, address coin, uint256 _amount) external security onlyAggregator{
        ERC20(coin).transfer(_wager,_amount);
        emit Distribution(_wager,_amount);
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