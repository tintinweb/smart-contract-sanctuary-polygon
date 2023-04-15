/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SmartCourse {

    // enumeration
    enum CourseType {
        MASTER, // 0
        BSC, // 1
        NORMAL, // 2
        INTENSIVE // 3
    }

    // structs
    struct Metainformation {
        CourseType courseType;         
        string name;
        uint maximumsStudents;
    }

    // PROPERTIES
    // SmartCourse metainformation
    Metainformation public metainfo;

    // smart course actual information   
    uint public numberOfStudents;
    uint public numberOfTeachers;

    // CONSTRUCTOR
    constructor(uint _numberOfStudents, 
                uint _numberOfTeachers ) 
    {
        metainfo.courseType = CourseType.INTENSIVE;
        metainfo.name = "Blockchain programming";
        metainfo.maximumsStudents = 20;

        numberOfStudents = _numberOfStudents;
        numberOfTeachers = _numberOfTeachers;
    }

    // QUERY FUNCTIONS
    function nrAllParticipants() public view returns(uint) {
        return numberOfStudents + numberOfTeachers;
    }

    function getMetaInfo() public view 
        returns (CourseType,string memory,uint)
        {
            return (
                metainfo.courseType,
                metainfo.name,
                metainfo.maximumsStudents
            );
        }

    // TRASNSACTINAL FUNCTION
    function addStudents(uint nrStudents) public {
        numberOfStudents += nrStudents;
    } 

    function changeMetaInfo (
        CourseType _courseType,         
        string memory _name,
        uint _maximumsStudents        
    ) public {
        metainfo.courseType = _courseType;
        metainfo.name = _name;
        metainfo.maximumsStudents = _maximumsStudents;
    }



}