/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {
    address payable public owner;

    modifier onlyOwner {
        require(owner == msg.sender, "Sorry, you are the owner");
        _;
    }

    constructor() payable {
        owner = payable(msg.sender); 
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function inject() external payable onlyOwner {
        
    }

    function send()  external {
        require(owner != msg.sender, "Sorry, you are the owner");
        require(getBalance() > 0, "Sorry, the balance is not enough");

        address payable to = payable (msg.sender);
        uint256 amount = 0.01 ether;

        to.transfer(amount);
    }

    function emergencyWithdraw() external onlyOwner {
        
        uint256 amount = getBalance();

        owner.transfer(amount);
    }

    function setOwner(address payable newOwner) external onlyOwner {
        owner = newOwner;
    }

    function destroy() external onlyOwner {
        selfdestruct(owner);
    }
}