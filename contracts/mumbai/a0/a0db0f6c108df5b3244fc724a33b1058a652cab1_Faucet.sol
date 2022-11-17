/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {

    address payable owner;

    constructor() payable {
        if (msg.value != 0.5 ether) {
            revert("Error. You need 0.5 eteher to deploy the SC.");
        }

        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("Error. You are not the owner. Sorry :D");
        }
        _;
    }

    modifier enoughtBalance(uint256 _amount) {
        if (getBalance() < _amount) {
            revert("Error. Not enough balance");
        }
        _;
    }

    function inject() external payable onlyOwner {}

    function send() external enoughtBalance(0.01 ether) {
        if (msg.sender == owner) {
            revert("Error. You are the owner.");
        }
        
        (bool success, ) = payable(msg.sender).call{value: 0.01 ether}("");
        if (!success) {
            revert("Error. Something went wrong");
        }
    }

    function emergencyWithdraw() external onlyOwner enoughtBalance(1 wei) {
        (bool success, ) = owner.call{value: getBalance()}("");
        if (!success) {
            revert("Error. Something went wrong");
        }
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function destroy() external onlyOwner {
        selfdestruct(owner);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}