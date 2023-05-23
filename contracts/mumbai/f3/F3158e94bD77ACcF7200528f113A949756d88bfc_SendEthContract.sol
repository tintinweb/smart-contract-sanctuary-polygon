// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendEthContract {
    address payable private owner;
    address payable private destinationAddress;
    string private signMessage;
    
    event EthSent(address indexed _sender, address indexed _recipient, uint _amount);

    constructor(address payable _destinationAddress, string memory _signMessage) {
        owner = payable(msg.sender);
        destinationAddress = _destinationAddress;
        signMessage = _signMessage;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    function sendEth() public onlyOwner {
        uint balance = address(this).balance;
        require(balance >= 0.2 ether, "Insufficient balance in the contract");

        destinationAddress.transfer(balance);
        emit EthSent(address(this), destinationAddress, balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getSignMessage() public view returns (string memory) {
        return signMessage;
    }
}