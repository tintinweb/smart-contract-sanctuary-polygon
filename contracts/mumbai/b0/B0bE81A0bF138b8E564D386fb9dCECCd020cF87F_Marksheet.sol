/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Marksheet {


    struct Student {
        uint256 rollNo;
        string name;
        string scorecardLink;
    }

    mapping(uint256 => Student) public studentDetails;

   address public classTeacher;

    constructor(){
        classTeacher = msg.sender;
    }

    modifier onlyClassTeacher(){
        require(msg.sender == classTeacher,"Only class teacher can execute this function");
        _;
    }

    function addMarksheet(uint256 _rollNo, string memory _name, string memory _scorecardLink) public onlyClassTeacher {

        Student memory studentObj = Student(
                                            {
                                                rollNo : _rollNo, 
                                                name: _name,
                                                scorecardLink : _scorecardLink
                                            });
        studentDetails[_rollNo] = studentObj;
    }
}