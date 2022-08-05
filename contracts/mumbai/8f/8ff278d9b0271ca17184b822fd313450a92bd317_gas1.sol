/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


contract gas1{

    uint[] array =[1,2,3,4,5,6];
    uint public abc;

    uint public a1;
    string a2;
    string a3;
    string a4;
    uint a5;


constructor(uint ID, string memory name, string memory OwnerName, string memory URI, uint userLimitNum)
    {
        a1=ID;
        a2=name;
        a3=OwnerName;
        a4=URI;
        a5=userLimitNum;
    }


    function test() public{ //!!!more gas
        abc= array.length;

    }



    function test2()public{ //!!! less gas
        uint num = array.length;
        abc=num;
    }

}