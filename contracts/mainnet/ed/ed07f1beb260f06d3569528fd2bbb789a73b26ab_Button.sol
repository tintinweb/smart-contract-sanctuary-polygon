/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Button {
    address public leader;
    uint256 public leadership_start_timestamp;
    uint256 public countdown_milliseconds;
    
    uint256 constant LEADERSHIP_PAYMENT_AMOUNT = 500000000000000000; // half Matic
    uint256 constant COUNTDOWN_DROP_FACTOR = 10800000000; // 3 hours in milliseconds
    uint256 constant MINIMAL_COUNT_DOWN_MILLISECONDS = 300000; // 5 minutes in milliseconds
    uint256 constant INITIAL_BALANCE = 1000000000000000000; // 1 Matic
    
    constructor() {
        leader = 0xC6036B8c3F911f936b661a075CFAA4B802b75cc3;
        leadership_start_timestamp = 999999999999999;
        countdown_milliseconds = 86400000; // 24 hours in milliseconds
    }
    
    function _drop_countdown() internal {
        uint256 balance_weight_tenthtez = (address(this).balance - INITIAL_BALANCE) / 5000000000000000; // Matic becomes half of a Matic
        
        uint256 countdown_drop_milliseconds = (COUNTDOWN_DROP_FACTOR + balance_weight_tenthtez) / balance_weight_tenthtez;
        
        if (countdown_milliseconds > MINIMAL_COUNT_DOWN_MILLISECONDS + countdown_drop_milliseconds) {
            countdown_milliseconds -= countdown_drop_milliseconds;
        } else {
            countdown_milliseconds = MINIMAL_COUNT_DOWN_MILLISECONDS;
        }
    }

    function becomeLeader() public payable {
        require(msg.value == LEADERSHIP_PAYMENT_AMOUNT, "Invalid payment amount");
        require(leadership_start_timestamp + countdown_milliseconds / 1000 > block.timestamp, "Countdown time expired");

        leader = msg.sender;
        leadership_start_timestamp = block.timestamp;
        
        _drop_countdown();
    }

    function withdraw() public {
        require(msg.sender == leader, "Only the current leader can withdraw");
        require(leadership_start_timestamp + countdown_milliseconds / 1000 < block.timestamp, "Countdown time not expired");

        payable(msg.sender).transfer(address(this).balance);
    }

    function getLeader() public view returns (address) {
        return leader;
    }

    function getLeadershipStartTimestamp() public view returns (uint256) {
        return leadership_start_timestamp;
    }
    
    function getCountdownMilliseconds() public view returns (uint256) {
        return countdown_milliseconds;
    }
}