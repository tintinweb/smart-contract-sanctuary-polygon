/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentyFour{

    struct Student{
        string name;
        uint256[3] marks;
    }

    Student[10] student;
    uint32 i = 1;

    function set(string memory _name, uint256 maths, uint256 science, uint256 english) public {
        student[i] = Student(_name, [maths,science,english]);
        i++;
    }

    function get(uint32 _i) public view returns(string memory, uint256[3] memory){
        return (student[_i].name, student[_i].marks); // returns marks of maths, science, english respectively
    }
}