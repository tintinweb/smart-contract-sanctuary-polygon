/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

contract MineMetaWorld {
    
    ERC20 public DAI = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); 
   
    address aggregator; 
    event Deposit(address depositor, uint256 dai, uint256 depositTime);
    event Distribution(address requestor, uint256 dai, uint256 distributionTime);
    
    modifier onlyAggregator(){
        require(msg.sender == aggregator,"You are not authorized!");
        _;
    }

    modifier security {
        uint size;
        address sandbox = msg.sender;
        assembly { size := extcodesize(sandbox) }
        require(size == 0, "Smart contract detected!");
        _;
    }

    function getBalanceSheet() public view returns(uint256 daiBalance){
        return DAI.balanceOf(address(this));
    } 

    constructor() public {
        aggregator = msg.sender;
    }

    function deposit(uint256 _dai) public security{
        require(_dai >= 25e18 && _dai <= 1000e18, "Minimum 25 DAI upto 1000 DAI!");
        DAI.transferFrom(msg.sender, address(this), _dai);
        emit Deposit(msg.sender, _dai, block.timestamp);
    }

    function distributeStake(address requestor,uint _amount) public onlyAggregator security{
        DAI.transfer(requestor,_amount);
        emit Distribution(requestor, _amount, block.timestamp);
    }
    
   
}