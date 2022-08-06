//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract GiftCenter {

    uint public count;

    receive() external payable {  
    }

    struct SendersData {
        address recipient;
        string message;
        uint amount;
        uint date;
    }

    struct ReceiversData {
        address sender;
        string message;
        uint amount;
        uint date;
        bool withdrawn;
    }

    mapping(address => SendersData[]) private senders;
    mapping(address => ReceiversData[]) private receivers;

    event Gifted(uint count, address from, address to, string message, uint amount, uint time);
    event withDrawal(address from, uint giftNumber, uint amount);

    //add a fallback function
    function sendGift(address _recipient, string memory _message) public payable {

        require(_recipient != msg.sender, "Can't gift yourself");
        require(msg.value > 0, "Add some gifting amount");
        
        senders[msg.sender].push(SendersData(_recipient, _message, msg.value, block.timestamp));
        receivers[_recipient].push(ReceiversData(msg.sender, _message, msg.value, block.timestamp, false));

        count += 1;
        emit Gifted(count, msg.sender, _recipient, _message, msg.value, block.timestamp);
    }
    
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getReceiversData(address _recipient) external view returns(ReceiversData[] memory){
        return receivers[_recipient];
    }

    function getSendersData(address _sender) external view returns(SendersData[] memory){
        return senders[_sender];
    }


    function totalSentAmount(address _sender) external view returns(uint){
        uint total = 0;
        for(uint i=0; i<senders[_sender].length; i++) {
            total += senders[_sender][i].amount;
        }
        return total;
    }

    function totalReceivedAmount(address _receiver) public returns(uint){
        uint total = 0;
        for(uint i=0; i<receivers[_receiver].length; i++) {
            if(!receivers[_receiver][i].withdrawn) {
                total += receivers[_receiver][i].amount;
                receivers[_receiver][i].withdrawn = true;
            }
        }
        return total;
    }


    function withdraw(address payable _receiver) external returns(string memory){
        _receiver.transfer(totalReceivedAmount(_receiver));
        return "Withdrawn successfully";
    }

    function resetCount() external{
        count = 0;
    }

}