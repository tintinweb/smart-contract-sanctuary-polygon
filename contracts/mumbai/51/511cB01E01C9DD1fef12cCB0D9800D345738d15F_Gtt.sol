/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


abstract contract InterfaceCT{
    function balanceOf(address account) external view virtual returns (uint256);
}

contract Gtt{
   // address Matic = 0x0000000000000000000000000000000000001010;
    address addressCT = 0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5;

    InterfaceCT ctContract = InterfaceCT(addressCT);

    function getTokens() public view returns(uint balanceCT) {
        balanceCT = ctContract.balanceOf(msg.sender);
        //return balanceCT;
    }

    function getBalance() public view returns(uint balance) {
        balance = address(msg.sender).balance;
    }


    receive() external payable{}
}