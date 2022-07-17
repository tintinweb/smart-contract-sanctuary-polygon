//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract GiftCenter {

    struct SendGift {
        string message;
        uint amount;
        address recipient;
    }

    struct ReceiveGift {
        string message;
        uint amount;
        address sender;
        bool withdrawn;
    }
    
    
    mapping(address => SendGift[]) GiftSenders;

    mapping(address => ReceiveGift[]) GiftReceivers;

    receive() external payable {  
    }

    event Gifted(address from, address to, string message, uint amount);
    event withDrawal(address from, uint giftNumber, uint amount);

    //add a fallback function
    function sendGift(address _recipient, string memory _message) public payable {

        require(_recipient != msg.sender, "Can't gift yourself");
        require(msg.value <= (msg.sender).balance, "Not sufficient balance");
        require(msg.value >= 5 ether, "Amount should be greater than 5 ETH");
        

        GiftSenders[msg.sender].push(SendGift({message: _message, amount: msg.value, recipient: _recipient}));

        GiftReceivers[_recipient].push(ReceiveGift({message: _message, amount: msg.value, sender: msg.sender, withdrawn: false}));

        emit Gifted(msg.sender, _recipient, _message, msg.value);
    }
    
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function giftReceiverData(address _recipient) external view returns(ReceiveGift[] memory){
        return GiftReceivers[_recipient];
    }

    function showReceivedGifts() external view returns(ReceiveGift[] memory, uint){
        return (GiftReceivers[msg.sender], GiftReceivers[msg.sender].length);
    }


    function withdrawGiftNumber(uint index) external {

        require(index < GiftReceivers[msg.sender].length, "No gifts at that index");
        require(!GiftReceivers[msg.sender][index].withdrawn, "Already withdrawn");

        payable(msg.sender).transfer(GiftReceivers[msg.sender][index].amount);

        emit withDrawal(msg.sender, index, GiftReceivers[msg.sender][index].amount);

        GiftReceivers[msg.sender][index].withdrawn = true;
    }

    function giftSenderData(address _from) external view returns(SendGift[] memory){
        return GiftSenders[_from];
    }

    function showSentGifts() external view returns(SendGift[] memory){
        return GiftSenders[msg.sender];
    }

}