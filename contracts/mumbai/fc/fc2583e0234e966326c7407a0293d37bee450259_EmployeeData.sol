/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract EmployeeData {
    struct Employee {
        uint256 id;
        string firstName;
        string lastName;
        string email;
        string salary;
        string employeeStatus;
        uint256 createdAt;
        uint256 updatedAt;
    }

    enum Status {
        Active,
        Inactive
    }

    address private immutable SENDER_ADDRESS;
    uint256 private immutable CREATED_AT;

    Employee[] employees;

    event Log(string message);

    constructor() {
        SENDER_ADDRESS = msg.sender;
        CREATED_AT = block.timestamp;
    }

    modifier onlyOwner() {
        require(SENDER_ADDRESS == msg.sender, "Only Owner!");
        _;
    }

    function createEmployee(
        string memory _firstName,
        string calldata _lastName,
        string calldata _email,
        string calldata _salary,
        Status _employeeStatus
    ) public onlyOwner {
        uint256 lengthArray = employees.length;
        uint256 _createdAt = block.timestamp;
        string memory status;

        require(bytes(_firstName).length > 0, "First name cannot be empty");
        require(bytes(_lastName).length > 0, "Last name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        require(bytes(_salary).length > 0, "Salary cannot be empty");

        if (Status.Active == _employeeStatus) {
            status = "Active";
        } else if (Status.Inactive == _employeeStatus) {
            status = "Inactive";
        } else {
            revert("Invalid Employee Status");
        }

        employees.push(
            Employee({
                id: lengthArray + 1,
                firstName: _firstName,
                lastName: _lastName,
                email: _email,
                salary: _salary,
                employeeStatus: status,
                createdAt: _createdAt,
                updatedAt: _createdAt
            })
        );

        emit Log("Created New Employee");
    }

    function readEmployee() public view onlyOwner returns (Employee[] memory) {
        return employees;
    }

    function updateEmployee(
        uint256 id,
        string memory _firstName,
        string calldata _lastName,
        string calldata _email,
        string calldata _salary,
        Status _employeeStatus
    ) public onlyOwner {
        string memory status;
        uint256 updatedAt = block.timestamp;

        require(id > 0 && id <= employees.length, "Invalid employee ID");
        require(bytes(_firstName).length > 0, "First name cannot be empty");
        require(bytes(_lastName).length > 0, "Last name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        require(bytes(_salary).length > 0, "Salary cannot be empty");

        if (Status.Active == _employeeStatus) {
            status = "Active";
        } else if (Status.Inactive == _employeeStatus) {
            status = "Inactive";
        } else {
            revert("Invalid Employee Status");
        }

        employees[id - 1].firstName = _firstName;
        employees[id - 1].lastName = _lastName;
        employees[id - 1].email = _email;
        employees[id - 1].salary = _salary;
        employees[id - 1].employeeStatus = status;
        employees[id - 1].updatedAt = updatedAt;

        emit Log("Updated Employee");
    }

    function deleteEmployee(uint256 id) public onlyOwner {
        require(id > 0 && id <= employees.length, "Invalid employee ID");

        delete employees[id - 1];
        emit Log("Deleted Employee");
    }

    function getEmployeeLength() public view returns (uint256) {
        return employees.length;
    }
}