// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LunchMoney{
    address private receiver;
    uint256 private lunchMoneyAmount;

    function setReceiverAddress(address _receiver) public {
        require(_receiver != address(0x0), "address cannot be the zero address");
        receiver = _receiver;
    }

    function setLunchMoneyAmount(uint256 _amount) public {
        require(_amount > 0, "can't be zero");
        lunchMoneyAmount = _amount;
    }

    function transferLunchMoney() public { 
        (bool sent, ) =  receiver.call{value: lunchMoneyAmount}("");
        require(sent, "Failed to send Ether");
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

    // receive function is used to receive Ether when msg.data is empty
    receive() external payable {}

    // Fallback function is used to receive Ether when msg.data is NOT empty
    fallback() external payable {}
}