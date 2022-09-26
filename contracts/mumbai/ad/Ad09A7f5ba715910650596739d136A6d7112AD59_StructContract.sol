/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: PUCRS

pragma solidity >= 0.7.3;

contract StructContract {
    struct Instructor {
        uint age;
        string first_name;
        string last_name;
    }
    
    Instructor[] public instructor_enrolled;

    mapping(address => Instructor) instructors;

    function getInstructorInfos(address _instructor_address)  public view returns (uint, string memory, string memory) {
        return (
            instructors[_instructor_address].age,
            instructors[_instructor_address].first_name,
            instructors[_instructor_address].last_name
        );
    }
    
    function addInstructor(uint _age, string memory _first_name, string memory _last_name) public {
        Instructor memory new_instructor = Instructor(_age, _first_name, _last_name);
        instructor_enrolled.push(new_instructor);
    }

}