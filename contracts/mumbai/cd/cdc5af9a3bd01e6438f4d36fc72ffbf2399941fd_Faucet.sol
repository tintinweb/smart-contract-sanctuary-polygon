/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {

    address payable internal owner;
    address internal lastUser;
    uint256 internal sendAmount;
    uint8 internal winner;
    bool internal paused;

    constructor() payable {
        if (msg.value != 0.5 ether) {
            revert("Error. You need 0.5 eteher to deploy the SC.");
        }

        owner = payable(msg.sender);
        sendAmount = 0.01 ether;
        paused = false;
        lastUser = address(0);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("Error. You are not the owner. Sorry :D");
        }
        _;
    }

    modifier enoughBalance(uint256 _amount) {
        if (getBalance() < _amount) {
            revert("Error. Not enough balance");
        }
        _;
    }

    modifier notPaused() {
        if (paused) {
            revert("Error. Sorry I'm paused :(");
        }
        _;
    }

    function inject() external payable onlyOwner notPaused {}

    function send() external enoughBalance(sendAmount) notPaused {
        uint256 totalValue = sendAmount;
        winner++;
        if (msg.sender == owner) {
            revert("Error. You are the owner.");
        }
        if (lastUser == msg.sender) {
            revert("Error. Sorry you are the last user. I can't send you money again!");
        }
        lastUser = msg.sender;
        if (winner % 5 == 0) {
            totalValue = totalValue + 0.005 ether;
            if (getBalance() < totalValue) {
                revert("Error. Not enough balance. You were the winner :(.");
            }
            winner = 0;
        }
        
        (bool success, ) = payable(msg.sender).call{value: totalValue}("");
        if (!success) {
            revert("Error. Something went wrong");
        }
    }

    function emergencyWithdraw() external onlyOwner enoughBalance(1 wei) notPaused {
        (bool success, ) = owner.call{value: getBalance()}("");
        if (!success) {
            revert("Error. Something went wrong");
        }
    }

    function setOwner(address payable _newOwner) external onlyOwner notPaused {
        owner = _newOwner;
    }

    function destroy() external onlyOwner notPaused {
        selfdestruct(owner);
    }

    function setAmount(uint256 _newAmount) external onlyOwner notPaused {
        sendAmount = _newAmount;
    }

    function pause() external notPaused onlyOwner {
        paused = true;
    }

    function resume() external onlyOwner {
        if (!paused) {
            revert("Error. We are not paused!");
        }
        paused = false;
    }

    function getBalance() public view notPaused returns (uint256) {
        return address(this).balance;
    }
}