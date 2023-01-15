/*
@author Aayush Gupta, Github: https://github.com/AAYUSH-GUPTA-coder, Twitter: https://twitter.com/Aayush_gupta_ji

Smart contract to send Lunch money to your Kid and automate the `transferLunchMoney` function with Galeto network
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error ONLYOWNER_CAN_CALL_THIS_FUNCTION();
error ADDRESS_CANT_BE_ZERO();
error AMOUNT_CANT_BE_ZERO();
error TIME_NOT_PASSED();
error FAILED_TO_SEND_ETHER();

contract LunchMoney{
    address private receiver;
    uint256 private lunchMoneyAmount;
    address private owner;
    uint private threshold;
    uint private lastCall;

    event Transfer(address receiver, uint lastCallTimestamp);

    constructor() {
        owner = msg.sender;
        lastCall = block.timestamp;
    }

    modifier onlyOwner() {
        if(msg.sender != owner){
            revert ONLYOWNER_CAN_CALL_THIS_FUNCTION();
        }
        _;
    }

    function setReceiverAddress(address _receiver) public onlyOwner {
        if(_receiver == address(0x0)){
            revert ADDRESS_CANT_BE_ZERO();
        }
        receiver = _receiver;
    }

    function setLunchMoneyAmount(uint256 _amount) public onlyOwner {
        if(_amount == 0){
            revert AMOUNT_CANT_BE_ZERO();
        }
        lunchMoneyAmount = _amount;
    }

    // production
    // function setThreshold(uint8 _hours) public onlyOwner {
    //     threshold = _hours * 60 * 60;
    // }

    // testing 
    function setThreshold(uint256 _min) public onlyOwner {
        threshold = _min * 60 ;
    }

    function transferLunchMoney() public { 
        if(block.timestamp < lastCall + threshold){
            revert TIME_NOT_PASSED();
        }
        (bool sent, ) =  receiver.call{value: lunchMoneyAmount}("");
        if(!sent){
            revert FAILED_TO_SEND_ETHER();
        }
        lastCall = block.timestamp;
        emit Transfer(receiver, lastCall);
    }

    function withdraw() public onlyOwner {
        (bool sent, ) =  owner.call{value: address(this).balance}("");
        if(!sent){
            revert FAILED_TO_SEND_ETHER();
        }
    }

    function getThreshold() public view returns(uint){
        return threshold;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getReceiver() public view returns(address){
        return receiver;
    }

    function getLunchAmount() public view returns(uint){
        return lunchMoneyAmount;
    }

    function getLastCall() public view returns(uint){
        return lastCall;
    }

    function getOwner() public view returns(address){
        return owner;
    }

    function getTimeRemaining() public view returns(uint){
        return lastCall + threshold - block.timestamp;
    }

    // receive function is used to receive Ether when msg.data is empty
    receive() external payable {}

    // Fallback function is used to receive Ether when msg.data is NOT empty
    fallback() external payable {}
}