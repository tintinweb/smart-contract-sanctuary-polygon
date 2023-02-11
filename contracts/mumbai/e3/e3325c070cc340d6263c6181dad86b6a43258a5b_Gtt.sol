/**
 *Submitted for verification at polygonscan.com on 2023-02-10
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

    function getTokens(address account) public view returns(uint balanceCT) {
        balanceCT = ctContract.balanceOf(account);
        //return balanceCT;
    }

    function getBalance(address account) public view returns(uint balance) {
        balance = address(account).balance;
    }


    receive() external payable{}
}