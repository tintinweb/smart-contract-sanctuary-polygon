// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract StudentManage {
    struct Student {
        uint256 id;
        string name;
        uint256 age;
    }

    Student[] public StudentList;

    function addList(string calldata _name, uint256 _age)
        public
        returns (uint256)
    {
        uint256 count = StudentList.length;
        uint256 index = count + 1;
        StudentList.push(Student(index, _name, _age));
        return StudentList.length;
    }

    function getList() public view returns (Student[] memory) {
        return StudentList;
    }
}