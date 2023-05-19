/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MaticSender{

    address owner;
    
    
    function setOwner(address newOwner) public {
        owner = newOwner;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function inject() external payable {
    }

    function withdrawal() external {
        payable(msg.sender).transfer(0.001 ether);

    }

    function withdrawalHalf() external {
        uint256 balance = getBalance() / 2;
        payable(msg.sender).transfer(balance);
    }

    function withdrawalBalanceOwner() external {
      uint256 balance = getBalance();
        payable(owner).transfer(balance);

    }
}