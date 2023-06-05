/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MaticSender {

    address payable owner;

    function setOwner(address payable newOwner) external {
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance; 
    }

    function inject() external payable {}

    //0.001 Matic
    function send0001() external {
        payable(msg.sender).transfer(0.001 ether);
    }
    function sendHalfBalance() external {
        uint256 halfBalance = getBalance()/2;
        payable(msg.sender).transfer(halfBalance/2);
    }

    function sendAllBalanceToOwner() external {
        uint256 balance = getBalance();
        owner.transfer(balance);
    }

    //Qué function selector tiene la función “getBalance” ? = 0x12065fe0
    //Cuál es el input data de la transacción “setOwner” con el input“0x72c77e070405503Db4D266A12cb09cDd3c89b0AC” ?
    //0x13af403500000000000000000000000072c77e070405503db4d266a12cb09cdd3c89b0ac
}