pragma solidity ^0.8.11;

contract EtherWallet {
    address payable public owner;
    constructor() {
        owner = payable(msg.sender);
    }
    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "Error! 403 unauthorized");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {}
    function send(address payable to, uint amount) public {
        require(msg.sender == owner, "You are not allowed");
        require(address(this).balance >= amount, "Not enough funds");
        to.transfer(amount);
    }
}