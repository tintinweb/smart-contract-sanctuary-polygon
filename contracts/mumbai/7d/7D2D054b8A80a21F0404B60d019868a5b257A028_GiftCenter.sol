//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract GiftCenter {

    struct SendGift {
        string message;
        uint amount;
        address recipient;
        uint time;
    }

    struct ReceiveGift {
        string message;
        uint amount;
        address sender;
        bool withdrawn;
        uint time;
    }
    
    
    mapping(address => SendGift[]) GiftSenders;

    mapping(address => ReceiveGift[]) GiftReceivers;

    receive() external payable {  
    }

    event Gifted(address from, address to, string message, uint amount, uint time);
    event withDrawal(address from, uint giftNumber, uint amount);

    //add a fallback function
    function sendGift(address _recipient, string memory _message) public payable {

        require(_recipient != msg.sender, "Can't gift yourself");
        require(msg.value <= (msg.sender).balance, "Not sufficient balance");
        require(msg.value >= 0, "Add some amount");
        
        // payable(address(this)).transfer(msg.value);

        GiftSenders[msg.sender].push(SendGift({message: _message, amount: msg.value, recipient: _recipient, time: block.timestamp}));

        GiftReceivers[_recipient].push(ReceiveGift({message: _message, amount: msg.value, sender: msg.sender, withdrawn: false, time: block.timestamp}));

        emit Gifted(msg.sender, _recipient, _message, msg.value, block.timestamp);
    }
    
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function showReceivedGifts(address _recipient) external view returns(ReceiveGift[] memory){
        return GiftReceivers[_recipient];
    }

    function withdrawGiftNumber(uint index) external {

        require(index < GiftReceivers[msg.sender].length, "No gifts at that index");
        require(!GiftReceivers[msg.sender][index].withdrawn, "Already withdrawn");

        payable(msg.sender).transfer(GiftReceivers[msg.sender][index].amount);

        emit withDrawal(msg.sender, index, GiftReceivers[msg.sender][index].amount);

        GiftReceivers[msg.sender][index].withdrawn = true;
    }

    function showSentGifts(address _from) external view returns(SendGift[] memory){
        return GiftSenders[_from];
    }

}