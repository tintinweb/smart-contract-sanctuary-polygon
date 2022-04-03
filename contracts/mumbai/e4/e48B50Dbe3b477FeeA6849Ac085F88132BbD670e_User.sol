// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract User {
    // Employee address => employerAddress
    // Used when creating a new employee
    mapping(address => address) private employee_Employer;

    // Employee address => Employee Struct
    // Used when creating a new Employee
    mapping(address => Employee) private employee_AccountDetails;

    // Organization employerAddress => Organization
    // Used when creating an Organization
    mapping(address => Organization) private employer_Organization;

    // Employer address => employeeId => employeeAddress
    // Used when creating a new Employer
    // mapping(address => mapping(uint8 => address)) private member_Organization;
    mapping(address => mapping(uint8 => Employee)) private member_Organization;

    // Employer address => bool
    mapping(address => bool) private isEmployer;

    // Employee address => bool
    mapping(address => bool) private isEmployee;

    // User address => username
    mapping(address => string) private users;

    // TODO Course struct to be created to hold course details
    // TODO Add course, delete course functions
    // TODO Check for change in course status, emit an event on course completion that initiates streaming from employer to employee
    // TODO Function to get all the learning courses added by employer
    // TODO Employee address => List of courses enrolled and completed

    enum Access {
        Locked, // Locked by employer. Can't be unlocked by employee. No access to widrawal of funds.
        Unlocked // Unlocked by employer. Can't be unlocked by employee. No access to widrawal of funds.
    }

    struct Employee {
        address _address; // the address of the employee
        string username; // an identifier for the employee
        Access access; // locked(0) or unlocked(1)
    }

    struct Organization {
        address payable owner; // the owner of the Organization
        // mapping(address => Employee) employee; // the employees of the organization
        uint8 numOfEmployees; // The number of employees in the organization
    }

    /** 
     * @notice - This function is used to retrieve the username based on wallet address
     * @param _address - The address of the user.
     */
    function getUserName(address _address) external view returns(string memory username){
        return users[_address];
    }
    
    /** 
     * @notice - This function is used to determine the type of user
     * 1 = employer. 2 = employee. 3 = unenrolled
     * @param user - The address of the user.
     */
    function getUserType(address user) external view returns(uint256){
        if(isEmployer[user]){
            return 1;
        }else if (isEmployee[user]){
            return 2;
        }else{
            return 3;
        }
    }

    /**
     * @notice - This function is used to determine if the user is an employee of an organization.
     */
    function fetchEmployees() public view returns (Employee[] memory) {
        require(isEmployer[msg.sender], "Only an Employer can make this request");

        //determine how many employees the employer has
        uint8 numOfEmployees = employer_Organization[msg.sender].numOfEmployees;
        Employee[] memory employees = new Employee[](numOfEmployees);
        for (uint8 index = 0; index < numOfEmployees; index++) {
            employees[index] = member_Organization[msg.sender][index + 1];
        }
        return employees;
    }

    /**
     * @notice - This function is used to create a new employer/owner
     */
    function createEmployer(string memory username) public {
        require(
            !isEmployer[msg.sender],
            "You are already registered as an Employer"
        );

        // create a new organization
        Organization memory organization = Organization({
            owner: payable(msg.sender),
            numOfEmployees: 0
        });
        employer_Organization[msg.sender] = organization;
        isEmployer[msg.sender] = true;
        users[msg.sender]=username;
    }

    /**
     * @notice - This function is used to add a employee to the organization owned by an employer.
     * @param _employeeAddress - The address of the employee.
     * @param _employeeName - The username of the employee.
     */
    function addEmployee(address _employeeAddress, string memory _employeeName) public {
        require(isEmployer[msg.sender], "Only an employer can make this request");
        require(!isEmployee[_employeeAddress], "Employee is already registered to an organization");
        // Fetch the employee
        Employee memory employee = Employee({
            _address: _employeeAddress,
            username: _employeeName,
            access: Access.Locked
        });

        // get next id number for the employee
        uint8 employeeId = employer_Organization[msg.sender].numOfEmployees + 1;

        // update employee count
        employer_Organization[msg.sender].numOfEmployees = employeeId;

        // update mappings
        isEmployee[_employeeAddress] = true;
        employee_Employer[_employeeAddress] = msg.sender;
        employee_AccountDetails[_employeeAddress] = employee;
        member_Organization[msg.sender][employeeId] = employee;
        users[_employeeAddress]=_employeeName;
    }

    /**
     * @notice - This function is used to change the access of an employee.
     * @param _employeeAddress - The address of the employee.
     */
    function changeAccess(address _employeeAddress) public {
        require(isEmployer[msg.sender], "Only an employer can make this request");

        // current status
        Access currentAccess = employee_AccountDetails[_employeeAddress].access;

        // change the access of the employee
        if (currentAccess == Access.Locked) {
            employee_AccountDetails[_employeeAddress].access = Access.Unlocked;
        } else {
            employee_AccountDetails[_employeeAddress].access = Access.Locked;
        }
    }
}