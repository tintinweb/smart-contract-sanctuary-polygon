/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {
   address payable public owner;
   address payable public lastTxOwner;

   uint256 public sendCounter = 1;
   uint256 public amount = 0.01 ether;

   bool public resumed;

   modifier onlyOwner {
        require(owner == msg.sender, "Sorry, only the owner can do that");
        _;
   }
   
   modifier contractStatus {
       require(resumed == true, "The smart contract is currently paused, please, resume it before using it again");
       _;
   }

   constructor() {
        owner = payable(msg.sender);
        resumed = true;
   }

   function inject() external payable onlyOwner contractStatus {
   }

   function pause() external {
       resumed = false;
   }

   function resume() external {
       resumed = true;
   }

   function destroy() external onlyOwner contractStatus {
        selfdestruct(owner);
   }

   function setAmount(uint256 newAmount) external onlyOwner contractStatus {
       amount = newAmount;
   }

   function send() external contractStatus {
        require(owner != msg.sender, "Sorry, the owner can't receive money");
        require(getBalance() > 0, "Sorry, there's not enough money on the smart contract, try later please");
        require(lastTxOwner != msg.sender, "Sorry, you have to wait for someone else to retire from the faucet before using it again");

        address payable to = payable(msg.sender);
        lastTxOwner = payable(msg.sender);

        if (sendCounter % 5 == 0) {
            amount = amount + 0.015 ether;
            to.transfer(amount);
        } else {
            to.transfer(amount);
        }
        sendCounter++;
   }

    function emergencyWithdraw() external onlyOwner contractStatus {
        uint256 liquidity = getBalance();

        owner.transfer(liquidity);
   }

    function setOwner(address payable newOwner) external onlyOwner contractStatus {
        owner = newOwner;
   }

    function getBalance() public view contractStatus returns (uint256) {
        return address(this).balance;
   }
}