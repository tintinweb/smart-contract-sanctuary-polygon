/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// File: contracts/EtherWallet.sol


pragma solidity >=0.4.22 <0.9.0;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Not the Owner");
        //Method 1:
        payable(msg.sender).transfer(_amount);

        //Method2:
       // (bool sent, ) = msg.sender.call{value: _amount}("");
        //require(sent == true, "Failed to send Ether");
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "Only owner");
        owner = payable(newOwner);
    }

}