//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract GiftCenter {

    uint public count;

    receive() external payable {  
    }

    event Gifted(uint count, address from, address to, string message, uint amount, uint time);
    event withDrawal(address from, uint giftNumber, uint amount);

    //add a fallback function
    function sendGift(address _recipient, string memory _message) public payable {

        require(_recipient != msg.sender, "Can't gift yourself");
        require(msg.value > 0, "Add some gifting amount");
        
        count += 1;
        emit Gifted(count, msg.sender, _recipient, _message, msg.value, block.timestamp);
    }
    
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function withdraw(uint amt) external{
        payable(msg.sender).transfer(amt);
    }

    function resetCount() external{
        count = 0;
    }

}