/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {
    address payable owner;
    address payable record;
    bool permission = true;
    bool running = true;
    uint256 amount = 0.01 ether;
    uint256 contador;
   
    constructor() payable {
        if (msg.value != 0.5 ether) {
            revert("Error. Incorrect value");
        }
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
       if (msg.sender != owner) {
            revert("Error. You are not the owner");
        } 
        _;
    }

    modifier go {
        if (!running) {
            revert("Error. The SC is paused");
        }
        _;          
    }
   
    function inject() external payable go onlyOwner {}

    function paused() external go onlyOwner {
        running = false;
    }

    function resume() external onlyOwner {
        running = true;
    }

    function setAmount(uint256 _newAmount) external go onlyOwner {
        amount = _newAmount;
    }

    function send() external go {
       
        if (msg.sender == owner) {
            revert("Error. You are the owner");
        }

        if (getBalance() == 0 ether) {
            revert("Error. Not enough balance");
        }

        if (msg.sender != record) {
            permission = true;          
        }

        if(permission) {
            contador ++;

            if (contador % 5 == 0) {
                (bool succes,) = payable(msg.sender).call {value : amount += 0.005 ether}("");
                
                if (!succes) {
                revert("Error. The transaction has failed");
                }
                amount -= 0.005 ether;
                record = payable(msg.sender);
                permission = false;

            } else {
                (bool succes,) = payable(msg.sender).call {value : amount}("");
                
                if (!succes) {
                revert("Error. The transaction has failed");
                }
                record = payable(msg.sender);
                permission = false;
            }
            
        } else {
            revert("Error. You cannot withdraw 2 times in a row");
        }          
    }

    function emergencyWithdraw() external go onlyOwner {

        (bool succes,) = owner.call{value: getBalance()}("");

        if (succes == false) {
            revert("Error. The transaction has failed");
        }
    }
    
    function setOwner(address payable _newOwner) external go onlyOwner {
        owner = _newOwner;
    }

    function destroy() external go onlyOwner {
        selfdestruct(owner);
    }

    function getBalance() public view  go returns (uint256) {
        return address(this).balance;
    }
}