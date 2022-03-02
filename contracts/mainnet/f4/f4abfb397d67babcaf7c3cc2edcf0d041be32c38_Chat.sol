/**
 *Submitted for verification at polygonscan.com on 2022-03-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract Chat {
    uint public counter;
    address owner;

    modifier onlyOwner{
        require(msg.sender == owner);
        _; // Close Modifier
    }

    struct Message 
    { 
        address to;
        string mess;
        uint value;
        uint blocktime;
    }

    mapping(address => Message[]) public chatHistory;
    mapping(address => uint) public chatCounter;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    function addMessage(address _to, string memory _message) public payable{
        counter +=1;
        chatCounter[msg.sender]+=1;
        chatHistory[msg.sender].push(Message(_to,_message, msg.value,block.timestamp));
        payable(_to).transfer(msg.value);
    }


    // Transfer money in the contract.

    function garbage() public onlyOwner payable{
        payable(owner).transfer(address(this).balance);
    }
}