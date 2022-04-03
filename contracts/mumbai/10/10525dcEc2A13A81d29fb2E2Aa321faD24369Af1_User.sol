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

    // Employer-Employees mapping
    mapping(address => address[]) private employer_Employees;

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

    // Courses employer creates
    mapping(address => Course[]) private employerCourses;

    // Courses employee subscribed to
    mapping(address => Course[]) private employeeCourses;

    // Status of courses employee had subscribed to
    mapping(address => mapping(uint8 => EmployeeCourseStatus)) private employeeCourseStatus;

    /**
     * Course details
     */
    struct Course {
        uint8 id; 
        string name; 
        string desc;
        address owner; 
        string url;
        uint8 bounty;
    }

    // TODO Add course, delete course functions
    // TODO Check for change in course status, emit an event on course completion that initiates streaming from employer to employee
    // TODO Function to get all the learning courses added by employer
    // TODO Employee address => List of courses enrolled and completed

    enum Access {
        Locked, // Locked by employer. Can't be unlocked by employee. No access to widrawal of funds.
        Unlocked // Unlocked by employer. Can't be unlocked by employee. No access to widrawal of funds.
    }

    /**
    * Employee course status
    */
    enum EmployeeCourseStatus {
        NOT_STARTED,
        IN_PROGRESS,
        COMPLETED
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
     * @notice - Creates course
     *
     * @param _name - name of the course
     * @param _desc - description of the course
     * @param _url - url of the course
     * @param _bounty - bounty for the course
     */
    function createCourse(string memory _name, string memory _desc, 
        string memory _url, uint8 _bounty) public {
        require(
            (bytes(_name).length != 0 && bytes(_url).length != 0 && _bounty != 0), 
        "Error: Mandatory information course name/url/bounty missing"
        );

        require(
            isEmployer[msg.sender],
            "Access Restricted: Courses can be created only by an employer"
        );

        Course memory course = Course({
            id: uint8(employerCourses[msg.sender].length + 1),
            name: _name,
            desc: _desc,
            owner: msg.sender,
            url: _url,
            bounty: _bounty
        });
        employerCourses[msg.sender].push(course);
        subscribeCourse(course);
    }

    /**
     * @notice - Fetch course list based on user type
     *
     * @return courseList - list of courses  
     */
    function fetchCourses() view public returns (Course[] memory courseList) {
        Course[] memory courses;
        if (isEmployer[msg.sender]) { //Employer
            return employerCourses[msg.sender];
        } else if (isEmployee[msg.sender]) { //Employee
            return fetchIncompleteCourses();
        } else {
            return courses;
        }
    }


    /**
     * @notice - Fetch incompleted course list
     *
     * @return courseList - list of courses  
     */
    function fetchIncompleteCourses() view public returns (Course[] memory) {
        Course[] memory coursesList = employeeCourses[msg.sender];
        Course[] memory incompletedList = new Course[](coursesList.length);
        uint8 counter = 0;
        for (uint8 i = 0; i < coursesList.length; i++) {
            if(employeeCourseStatus[msg.sender][coursesList[i].id] != EmployeeCourseStatus.COMPLETED) {
                incompletedList[counter] = coursesList[i];
                counter = counter + 1;
            }
        }
        return incompletedList;
    }


    /**
     * @notice - Subscribe course
     *
     * @param _course - course
     */
    function subscribeCourse(Course memory _course) private {
        address[] memory employees = employer_Employees[msg.sender];

        // All newly added courses are subscribed to all employers by default
        for (uint8 i = 0; i < employees.length; i++) {
            employeeCourses[employees[i]].push(_course);
            employeeCourseStatus[employees[i]][_course.id] = EmployeeCourseStatus.NOT_STARTED;
        }
    }


    /**
     * @notice - Complete course
     *
     * @param _courseId - course ID
     * @return courseUrl - course URL
     */
    function completeCourse(uint8 _courseId) public returns (string memory courseUrl) {
        require(isEmployee[msg.sender], "Only an employee can make this request");

        Course[] memory allCourses = employeeCourses[msg.sender];
        for (uint8 i = 0; i < allCourses.length; i++) {
            if (allCourses[i].id == _courseId && employeeCourseStatus[msg.sender][allCourses[i].id] == EmployeeCourseStatus.NOT_STARTED) {
                employeeCourseStatus[msg.sender][allCourses[i].id] = EmployeeCourseStatus.COMPLETED;
                return allCourses[i].url;
            }
        }
        return "";
    }

    /**
     * @notice - Get course status
     *
     * @param _courseId - course ID
     * @return courseStatus - course status
     */
    function getCourseStatus(uint8 _courseId) public view returns (string memory courseStatus) {
        Course[] memory allCourses = employeeCourses[msg.sender];
        string memory status;
        for (uint8 i = 0; i < allCourses.length; i++) {
            if (allCourses[i].id == _courseId) {
                EmployeeCourseStatus cStatus = employeeCourseStatus[msg.sender][allCourses[i].id];
                    if (cStatus == EmployeeCourseStatus.NOT_STARTED) {
                        status = "NOT_STARTED";
                    } else if (cStatus == EmployeeCourseStatus.IN_PROGRESS) {
                        status = "IN_PROGRESS";
                    } else if (cStatus == EmployeeCourseStatus.COMPLETED) {
                        status = "COMPLETED";
                    }
            }
        }
        return status;
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

        // Update employer-employees mapping
        if (!isEmployeeAlreadyExist(_employeeAddress)) {
            employer_Employees[msg.sender].push(_employeeAddress);
        } 
    }

    /**
     * @notice - Check if employee address already exist for the employer
     *
     * @param _employeeAddress - address of the employee
     * @return - flag indicating if employee already present 
     */
    function isEmployeeAlreadyExist(address _employeeAddress) private view returns(bool) {
        address[] memory employees = employer_Employees[msg.sender];

        if (employees.length == 0) { return false; }
        for (uint8 i = 0; i < employees.length; i++) {
            if (employees[i] == _employeeAddress) { return true; }
        }
        return false;
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