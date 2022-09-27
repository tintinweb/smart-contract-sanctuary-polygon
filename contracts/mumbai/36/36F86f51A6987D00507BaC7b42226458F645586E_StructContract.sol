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

    function getContracts() public view returns (Instructor[] memory) {
        Instructor[] memory id = new Instructor[](instructorCount);
        for (uint i = 0; i<instructorCount; i++){
            Instructor storage instructor = instructors[i];
            id[i] = instructor;     
        }
        return id;
    }
    //function getMember() public view returns (uint[] memory, string[] memory,uint[] memory)
    /*function getEmptyStations() public view returns (string memory, string memory, uint memory, string memory) {
        string[]  memory first_name = new string[](instructorCount);
        string[]  memory last_name = new string[](instructorCount);
        uint[]    memory age = new uint[](instructorCount);
        string[]  memory contract_address = new string[](instructorCount);
        for (uint i = 0; i < instructorCount; i++) {
            Instructor storage instructor = instructors[i];
            first_name[i] = instructor.first_name;
            last_name[i] = instructor.last_name;
            age[i] = instructor.age;
            contract_address[i] = instructor.hash_value;
        }
      return (first_name, last_name, age, contract_address);
    }*/

}