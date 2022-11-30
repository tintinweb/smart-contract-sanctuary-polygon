/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract MetaMatic{
    using SafeMath for uint256;

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
    
    function getContractInfo() view public returns(uint256 contractBalance){
        return contractBalance = address(this).balance;
    }

    constructor() public {
        aggregator = msg.sender;
    }

    function deposit() public payable security {
        require(msg.value>=15e18,"Invalid Investment");
        emit Deposit(msg.sender,msg.value);
    }
    
    function WagesDistribution(address payable _wager, uint256 _amount) external payable security onlyAggregator{
        _wager.transfer(_amount);
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