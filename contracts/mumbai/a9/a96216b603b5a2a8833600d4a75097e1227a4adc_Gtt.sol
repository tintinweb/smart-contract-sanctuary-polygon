/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


abstract contract InterfaceCT{
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address to, uint256 amount) external virtual returns (bool);
}


contract Gtt{
    InterfaceCT CT = InterfaceCT(addressCT);
    address addressCT = 0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5;

    uint amountMatic = 0.3 * 10**18;
    uint amountCT = 10000 * 10**18;
    uint minMatic = 0.02 * 10**18;
    uint minCT = 10000 * 10**18;

    function getTokens(address payable account) public returns(uint balance, uint balanceCT) {
        balance = address(account).balance;
       // balance = balance / 10**18;

        balanceCT = CT.balanceOf(account);
       // balanceCT = balanceCT / 10**18;

        if(balance < minMatic && balanceCT < minCT){
            account.transfer(amountMatic);
            CT.transfer(account, amountCT);
        }
    }


    receive() external payable{}
}