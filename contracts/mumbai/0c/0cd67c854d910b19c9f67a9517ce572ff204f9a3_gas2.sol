/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


contract gas2{

    uint[] array =[1,2,3,4,5,6];
    uint public abc;

    uint public a1;
    string a2;
    string a3;
    string a4;
    uint a5;


constructor(uint ID, string memory name, string memory OwnerName, string memory URI, uint userLimitNum)
    {
        
        uint q1=ID;
        a1=q1;
        string memory q2=name;
        a2=q2;
            
        string memory q3=OwnerName;
        a3=q3;

        string memory q4=URI;
        a4=q4;

        uint q5=userLimitNum;
        a5=q5;
    }


    function test() public{ //!!!more gas
        abc= array.length;

    }



    function test2()public{ //!!! less gas
        uint num = array.length;
        abc=num;
    }

}