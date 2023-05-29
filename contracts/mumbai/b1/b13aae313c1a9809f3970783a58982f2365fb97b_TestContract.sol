/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



contract TestContract{

    // people public person=people("kuncant");
    struct people{
        uint no;
        string name;
    }
    uint  public  favouriteNo=10;
    people public person2=people({no:10,name:"abhi"});

    function stor(string memory _val) public pure returns (string memory){
        _val="baniya";
        return _val;
    }
    function update(people memory _peple,uint val) internal pure{
        _peple.no=val;
    }
    function getUpdate()public  returns (uint){
        update(person2,1000);
       return person2.no;
    }
}