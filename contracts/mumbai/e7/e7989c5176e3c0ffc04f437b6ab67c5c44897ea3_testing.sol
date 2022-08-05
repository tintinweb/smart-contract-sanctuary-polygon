/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


contract testing{

    uint[] array =[1,2,3,4,5,6];
    uint public abc;

    function test() public{
        abc= array.length;

    }



    function test2()public{
        uint num = array.length;
        abc=num;
    }

}