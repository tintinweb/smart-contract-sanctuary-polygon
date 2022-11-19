/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Faucet{

    uint8 nonce = 0;
    uint256 amountToSent = 0.01 ether;

    bool public isPaused = false;

    address payable owner;
    address lastUser;

    constructor() payable {
        owner = payable(msg.sender);
        if (msg.value != 0.5 ether) {
            revert("Error, SC needs 0.5 ether to be deployed!");
        }
    }

    modifier onlyOwner{
        if (msg.sender != owner) {
            revert("Error, you're not the owner!");
        }
        _;
    }

    modifier pauseFaucet{
        if (isPaused == true) {
            revert("Error, the faucet is paused!");
        }
        _;
    }

    function getBalance() public view pauseFaucet returns (uint256) {
        return address(this).balance;
    }

    function inject() external payable onlyOwner pauseFaucet {}

    function send() external pauseFaucet {

        uint256 amountTotal = amountToSent + 0.005 ether;
        
        if (msg.sender == owner) {
            revert("Error, owner can't use it!");
        }
        if (getBalance() < amountToSent) {
            revert("Error, not enough funds!");
        }
        if (msg.sender == lastUser) {
            revert("Error, you can't use it two times in a row!");
        }


        if (nonce == 4) {
            if (getBalance() < amountTotal) {
                revert("Error, not enough funds!");
            } else {
                (bool success, ) = msg.sender.call{value: amountTotal}("");
                 if (success == false) {
                    revert("Error, some problem occured!");
                } else {
                    lastUser = msg.sender;
                    nonce = 0;
                }
            }   
        } else {
            (bool success, ) = msg.sender.call{value: amountToSent}("");
            if (success == false) {
                revert("Error, some problem occured!");
            } else {
                lastUser = msg.sender;
                nonce++;
            }
        }
    }

    function emergencyWithdraw() external onlyOwner pauseFaucet {
        (bool success, ) = owner.call{value: getBalance()}("");
        if (success == false) {
            revert("Error, some problem occured!");
        }
    }

    function setOwner(address payable _newOwner) external onlyOwner pauseFaucet {
        owner = _newOwner;
    } 

    function setAmount(uint256 _newAmountToSent) external onlyOwner pauseFaucet {
        amountToSent = _newAmountToSent;
    }

    function pause() external onlyOwner {
        isPaused = true;
    }

    function resume() external onlyOwner {
        isPaused = false;
    }

    function destroy() external onlyOwner pauseFaucet {
        selfdestruct(owner);
    }
}