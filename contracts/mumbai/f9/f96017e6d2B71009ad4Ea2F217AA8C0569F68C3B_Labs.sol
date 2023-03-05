// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Labs {
    string public mentor;
    mapping(string => bool) public isPresent;

    mapping(string => address) public nameToAddress;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setMentor(string calldata newMentor) external {
        mentor = newMentor;
        emit UpdatedMentor(newMentor);
    }

    function setPresent(string calldata student, bool status) external {
        isPresent[student] = status;
        emit UpdatedPresent(student, status);
    }

    function setAddress(string calldata student, address studentAddress) external {
        nameToAddress[student] = studentAddress;
        emit SetStudentAddress(student, studentAddress);
    }

    event UpdatedMentor(string newMentor);
    event UpdatedPresent(string student, bool present);
    event SetStudentAddress(string student, address studentAddress);
}