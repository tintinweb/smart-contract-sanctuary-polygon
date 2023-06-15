/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract Faucet
 {

    address public owner;
   
    uint256 public amountToSend = 0.01 ether;
    

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }


    function inject() external payable onlyOwner{
    } 


    function sendEther() external payable {

        require(msg.value >= 0.001 ether, "No tienes suficiente ETH pobre que eres pobre");
    }

   
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(getBalance());
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Esta adress no esta autorizada");
        _; 
    }


    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Esta adress no esta autorizada");
        owner = newOwner;
    }


    function setAmount(uint256 newAmount) external onlyOwner {
        amountToSend = newAmount;
    }


}