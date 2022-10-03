/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract StudentRecords {
    //stores student count
    uint256 public count;

    //gender enums
    enum Gender { MALE, FEMALE, OTHERS}

    //enums representing student class level
    enum Level { PRIMARY, SECONDARY, UNIVERSITY }

    struct Student {
       uint256 id;
       string firstName;
       string lastName;
       Gender gender;
       uint256 age;
       Level level;
    }
    //maps students id to student struct
    mapping (uint256 => Student) private Students;

    // contract events
    event StudentCreated(string _firstName, string _lastName, uint256 _id);

    //function to get student info
    function addStudentData(
        string memory _firstName, 
        string memory _lastName, 
        Gender _gender, 
        uint256 _age, 
        Level _level
    ) public {
        uint256 _id = count + 1;
        Student  memory newStudent = Student(_id,_firstName,_lastName,_gender,_age,_level );
        Students[_id] = newStudent;
        ++count;
        emit  StudentCreated( _firstName,  _lastName, _id);
    }

    function getStudentData(uint256 _id) public view returns (Student memory){
        Student memory student = Students[_id];
        return student;
    }

    function getAllStudents() public view returns (Student[] memory){
        Student[] memory AllStudents = new Student[](count);
        for(uint256 i=0; i< count; ++i){
            Student storage student = Students[i+1];
            AllStudents[i] = student;
        }
        return AllStudents;
    }

    //function to check if student with an id is a registered student
    function isStudent(uint256 _id) public view returns (bool){
       Student[] memory AllStudents = getAllStudents(); 
       for(uint256 i=0; i< count; ++i){
            if(AllStudents[i].id == _id){
                return true;
            }
        }
        return false;
    }

    

}