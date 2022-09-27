/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: PUCRS

pragma solidity >= 0.7.3;

contract StructContract {
    struct Instructor {
        uint id;
        uint age;
        string first_name;
        string last_name;
        string hash_value;
    }

    event instructorEvent(uint indexed _instructorId);

    uint instructorCount;

    constructor() {
        instructorCount = 0;
    }
    
    Instructor[] instructor_enrolled;

    //mapping(address => Instructor) instructors;
    mapping(uint => Instructor) instructors;

    /*function getInstructorInfos(address _instructor_address)  public view 
    returns (uint, string memory, string memory) {   
        return (
            instructors[_instructor_address].age,
            instructors[_instructor_address].first_name,
            instructors[_instructor_address].last_name
        );
    }*/
    
    function get(uint _instructorId) public view returns(Instructor memory) {
        return instructors[_instructorId];
    }

    function addInstructor(uint _age, string memory _first_name, string memory _last_name, string memory _hash_value) public {
        instructors[instructorCount] = Instructor(instructorCount,_age, _first_name,_last_name, _hash_value);
        instructorCount++;
    }

    function addInstructorOld(uint _age, string memory _first_name, string memory _last_name, string memory _hash_value) private {
        Instructor memory new_instructor = Instructor(instructorCount,_age, _first_name, _last_name, _hash_value);
        instructor_enrolled.push(new_instructor);
        instructorCount++;
    }

    function getNumInstructors() public view returns (uint) {
        return instructorCount;
    }

    

}