/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface token {
    function transfer(address receiver, uint256 value) external returns (bool);
    function balanceOf(address holder) external view returns (uint256 balance);
}

// Usage
// 1. create a Vault contract
// 2. transfer tokens to the Vault contract
// 3. call allocateToken()
// 4. Investor can claim() after the duration

contract Vault {

    using SafeMath for uint256;

    address public owner;
    address public tokenHolder;
    token public tokenContract;

    address internal investor;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public durationInDays;
    mapping(address => uint256) public freezeEndsAt;

    bool internal claimed;

    address public tokenAddress = 0x202655af326dE310491Cb54f120E02eE0da92b55;

    constructor(address _investor, uint256 _durationInDays, uint256 _amountTokenNoDecimals) {
        require(_durationInDays > 0);
        require(_amountTokenNoDecimals > 0);
        owner           = msg.sender;
        tokenHolder     = address(this);
        tokenContract   = token(tokenAddress);
        claimed         = false;
        investor        = _investor;
        balance[investor]           = _amountTokenNoDecimals.mul(1 ether);
        durationInDays[investor]    = _durationInDays;
        freezeEndsAt[investor]      = 0;
    }

    function allocateToken(uint256 _amountTokenNoDecimals) public {	
        require(msg.sender == owner);
        require(freezeEndsAt[investor] == 0);
        require(balance[investor] == _amountTokenNoDecimals.mul(1 ether));
        require(balance[investor] == tokenContract.balanceOf(tokenHolder));
        freezeEndsAt[investor] = durationInDays[investor].mul(1 days).add(block.timestamp);
    }

    function withdrawToken() public {
        require(msg.sender == owner);
        require(freezeEndsAt[investor] == 0);
        uint256 amount = tokenContract.balanceOf(tokenHolder);
        require(amount > 0);
        tokenContract.transfer(owner, amount);
    }

    function distribute() public {
        require(msg.sender == owner);
        require(claimed == false);
        require(freezeEndsAt[investor] != 0);
        freezeEndsAt[investor] = block.timestamp - 1;
    }

    function claim() public {
        require(msg.sender == investor);
        require(claimed == false);
        require(freezeEndsAt[investor] != 0);
        require(block.timestamp >= freezeEndsAt[investor]);
        tokenContract.transfer(investor, balance[investor]);
        claimed = true;
    }

    // Loading: Investor data is being loaded and contract not yet locked
    // Holding: Holding tokens for the investor
    // Distributing: Freeze time is over, the investor can claim their tokens
    // Distributed: The investor has already claimed
    function getState(address _investor) public view returns(string memory) {
        if(freezeEndsAt[_investor] == 0) {
            return "Loading";
        } else if(claimed == true) {
            return "Distributed";
        } else if(block.timestamp < freezeEndsAt[_investor]) {
            return "Holding";
        } else {
            return "Distributing";
        }
    }

    function getLeftTime(address _investor) public view returns(uint256) {
        require(freezeEndsAt[_investor] != 0);
        require(block.timestamp < freezeEndsAt[_investor]);
        uint256 _left = freezeEndsAt[_investor] - block.timestamp;
        return _left;
    }

    // return format = ddd0hh0mm00ss
    function getLeftTime_ddd0hh0mm0ss(address _investor) public view returns(uint256) {
        require(freezeEndsAt[_investor] != 0);
        require(block.timestamp < freezeEndsAt[_investor]);
        uint256 _left = freezeEndsAt[_investor] - block.timestamp;
        uint256 _days = _left.div(1 days);
        uint256 _leftHours = _left - _days.mul(1 days);
        uint256 _hours = _leftHours.div(1 hours);
        uint256 _leftMinutes = _leftHours - _hours.mul(1 hours);
        uint256 _minutes = _leftMinutes.div(1 minutes);
        uint256 _seconds = _leftMinutes - _minutes.mul(1 minutes);
        uint256 _time = _days.mul(1000000000) + _hours.mul(1000000) + _minutes.mul(1000) + _seconds;
        return _time;
    }
}