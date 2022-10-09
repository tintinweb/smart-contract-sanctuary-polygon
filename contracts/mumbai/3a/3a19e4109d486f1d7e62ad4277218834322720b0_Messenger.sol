/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// File: contracts/Messaging.sol


pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Messenger {
    IERC20 public token;
    address private owner;

    uint price;
    uint fee;

    struct Message {
        string message;
        address sender;
        uint date;
        uint time;
        string attachment;
    }

    struct sentMessage {
        string message;
        address recipient;
        uint date;
        uint time;
        string attachment;
    }

    constructor() public {
        token = IERC20(0x69fF763980cFE56c9153565066F518D65b0B70f4);
        owner = msg.sender;
    }

    mapping (address => Message[]) messages;
    mapping (address => sentMessage[]) sentmessages;

    function GetUserTokenBalance() public view returns(uint256){ 
       return token.balanceOf(msg.sender);
    }

     function GetContractTokenBalance() public onlyOwner view returns(uint256){
       return token.balanceOf(address(this));
    }

     function Approvetokens(uint256 _tokenamount) public returns(bool){
       token.approve(address(this), _tokenamount);
       return true;
    }

    function GetAllowance() public view returns(uint256){
       return token.allowance(msg.sender, address(this));
    }

    function AcceptPayment(uint256 _tokenamount) public returns(bool) {
       require(_tokenamount > GetAllowance(), "Please approve tokens before transferring");
       token.transfer(address(this), _tokenamount);
       return true;
    }

    function sendMessage(address _to, string memory _message, uint _date, string memory _attachment) public payable {
        require(msg.value >= price, "Not Paid");
        require(AcceptPayment(fee));
        messages[_to].push(Message({sender: msg.sender, message: _message, date: _date, time: block.timestamp, attachment: _attachment }));
        sentmessages[msg.sender].push(sentMessage({recipient: _to, message: _message, date: _date, time: block.timestamp, attachment: _attachment }));
    }

    function getMessage(uint _index) public view returns (address, string memory, uint, uint, string memory) {
        Message memory message = messages[msg.sender][_index];
        return (message.sender, message.message, message.date, message.time, message.attachment);
    }

    function getSentMessage(uint _index) public view returns (address, string memory, uint, uint, string memory) {
        sentMessage memory message = sentmessages[msg.sender][_index];
        return (message.recipient, message.message, message.date, message.time, message.attachment);
    }

    function getMsgLength() public view returns(uint) {
        return messages[msg.sender].length;
    }

    function getSentMsgLength() public view returns(uint) {
        return sentmessages[msg.sender].length;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed.");
    }

    function setPrices(uint _price, uint _fee) public onlyOwner {
        price = _price;
        fee = _fee;
    }
    
}