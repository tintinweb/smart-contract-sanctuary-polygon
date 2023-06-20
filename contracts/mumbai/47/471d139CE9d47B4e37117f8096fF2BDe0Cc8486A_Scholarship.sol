// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Scholarship {

    uint256 public registerCount = 0;

    struct Student {
        uint256 id;
        address payable stu_address;
        address donor;
        string name;
        string cgpa;
        uint256 received;
        uint256 totalAmount;
        bool got;
    }

    struct Sponsor {
        uint256 id;
        address[] students;
    }

    mapping(address => Student) public registeredStudents;
    mapping(address => Sponsor) public sponsors;
    mapping(uint256 => address) public studentList;

    address public owner;

    mapping(address => bool) public isStudent;
    mapping(address => bool) public isSponsor;
    mapping(address => bool) public isVendor;
    mapping(address => uint256) public scholarships;

    event ScholarshipAwarded(address indexed student, address indexed sponsor, uint256 amount);
    event PaymentMade(address indexed student, address indexed vendor, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    modifier onlyStudent() {
        require(isStudent[msg.sender], "Only students can perform this action");
        _;
    }

    modifier onlySponsor() {
        require(isSponsor[msg.sender], "Only sponsors can perform this action");
        _;
    }

    modifier onlyVendor() {
        require(isVendor[msg.sender], "Only vendors can perform this action");
        _;
    }

    function addStudent(address payable _student, string memory name, string memory cgpa, uint256 totalAmount) public onlyOwner returns (uint256) {
        require(!isStudent[_student], "This student is already registered");
        isStudent[_student] = true;
        registerCount += 1;
        Student memory reg = Student(registerCount, _student, address(0), name, cgpa, 0, totalAmount, false);
        registeredStudents[_student] = reg;
        studentList[registerCount] = _student;
        return 0;
    }

    function getRegisteredCount() public view returns (uint256) {
        return registerCount;
    }

    function getStudentFromId(uint256 id) public view returns (Student memory) {
        address temp = studentList[id];
        return registeredStudents[temp];
    }

    function addSponsor(address _sponsor) public onlyOwner {
        isSponsor[_sponsor] = true;
    }

    function addVendor(address _vendor) public onlyOwner {
        isVendor[_vendor] = true;
    }

    function sponsorStudent(address _student) public payable onlySponsor {
        require(isStudent[_student], "Recipient must be a registered student");
        require(msg.value > 0, "Sponsorship amount must be greater than zero");

        scholarships[_student] += msg.value;
        registeredStudents[_student].donor = msg.sender;
        registeredStudents[_student].received += msg.value;
        registeredStudents[_student].got = true;

        emit ScholarshipAwarded(_student, msg.sender, msg.value);
    }

    function payVendor(address payable _vendor, uint256 _amount) public payable {
        // require(isVendor[_vendor], "Recipient must be a registered vendor");
        require(_amount > 0, "Payment amount must be greater than zero");
        // require(scholarships[msg.sender] >= _amount, "Insufficient scholarship amount");
        (bool success,)=_vendor.call{value: _amount}("");
        require(success,"Call failed");

        emit PaymentMade(msg.sender, _vendor, _amount);
    }
}