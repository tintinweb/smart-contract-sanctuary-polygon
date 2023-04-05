/**
 *Submitted for verification at polygonscan.com on 2023-04-03
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract CourseContract {

    bool public courseStatus;
    bool public paymentStatus;
    uint public payment;
    uint public studentStake;
    uint public sponsorshipTotal;
    uint public paymentTimestamp;
    uint internal div = 15;
    address public peaceAntzCouncil = 0x6bE3d955Cb6cF9A52Bc3c92F453309931012D386;

    event GrantRole(bytes32 role, address account);
    event RevokeRole(bytes32 role, address account);
    event DropOut(address indexed account);
    event CourseStatus(bool courseStatus);
    event PaymentStatus(bool paymentStatus);
    event StudentEnrolled(address account);
    event Sponsored(uint indexed sponsorDeposit, address account);
    event CourseCompleted(address indexed account);
    event ClaimPayment(uint paymentTimestamp);

    mapping(bytes32 => mapping(address => bool)) public roles;

    mapping (address => uint) public studentDeposit;
    mapping (address => uint) public sponsorDeposit;
    mapping (address => bool) public courseCompleted;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant TEACHER = keccak256(abi.encodePacked("TEACHER"));
    bytes32 private constant STUDENT = keccak256(abi.encodePacked("STUDENT"));
    bytes32 private constant SPONSOR = keccak256(abi.encodePacked("SPONSOR"));

    modifier onlyRole(bytes32 _role){
        require(roles[_role][msg.sender], "not authorized");
        _;
    }

    constructor() payable{
        _grantRole(ADMIN, 0x6bE3d955Cb6cF9A52Bc3c92F453309931012D386);
        _grantRole(TEACHER, msg.sender);
    }

    function _grantRole(bytes32 _role, address _account) internal{
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account) external onlyRole(ADMIN){
        _grantRole(_role,_account);
    }

    function revokeRole(bytes32 _role, address _account) external onlyRole(ADMIN){
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function updateCourseStatus() external onlyRole(TEACHER){
        require(!courseStatus);
        require(paymentStatus);
        require(payment == sponsorshipTotal);
        courseStatus = true;
        paymentStatus = false;
        emit CourseStatus(true);
        emit PaymentStatus(false);
    }

    function setAmount(uint _payment) external onlyRole(TEACHER){
        require(!paymentStatus);
        require(!courseStatus);
        payment = _payment;
        studentStake = _payment / div;
        paymentStatus = true;
        emit PaymentStatus(true);
    }

    function passStudent(address _account) external onlyRole(TEACHER){
        require(roles[STUDENT][_account]);
        require(courseStatus);
        courseCompleted[_account] = true;
        paymentStatus = true;

        (bool success, ) = _account.call{value: studentStake}("");
        require(success);

        emit PaymentStatus(true);
        emit CourseCompleted(_account);
    }

    function bootStudent(address _account) external onlyRole(TEACHER){
        require(roles[STUDENT][_account]);
      
        roles[STUDENT][_account] = false;

        (bool success, ) = peaceAntzCouncil.call{value: studentStake}("");
        require(success);

        emit DropOut(_account);
    }

    function claimPayment() external onlyRole(TEACHER){
        require(courseStatus, "You have to start and complete the course to collect sponsor payment.");
        require(paymentStatus, "Please pass a student to complete the course.");

        (bool success, ) = msg.sender.call{value: payment}("");
        require(success);

        emit ClaimPayment(block.timestamp);
    }

    function enroll() external payable {
        require(!roles[TEACHER][msg.sender], "Teachers cannot enroll in their own course!");
        require(!courseStatus, "Course has already started :(");
        require(!roles[STUDENT][msg.sender], "You are enrolled already!");
        require(msg.value == studentStake, "Please Stake the Correct Amount");
        require(paymentStatus, "Enrollment Closed");

        roles[STUDENT][msg.sender] = true;
        studentDeposit[msg.sender] = studentStake;

        emit StudentEnrolled(msg.sender);
    }

    function withdraw() external payable {
        require(roles[STUDENT][msg.sender], "You are not enrolled!");
        require(address(this).balance > 0, "No balance available");
        require(courseStatus == false, "You have to dropout because the course has started.");
        require(msg.value == 0, "Leave value empty.");

        studentDeposit[msg.sender] = 0;
        roles[STUDENT][msg.sender] = false;

        (bool success, ) = msg.sender.call{value: studentStake}("");
        require(success);

        emit RevokeRole(STUDENT, msg.sender);
    }

    function dropOut() external payable onlyRole(STUDENT){
        require(courseStatus, "Course has not started yet, feel free to simply withdraw :)");
        require(!courseCompleted[msg.sender], "You have completed the course already!");

        (bool success, ) = peaceAntzCouncil.call{value: studentStake}("");
        require(success);

        roles[STUDENT][msg.sender] = false;
        emit DropOut(msg.sender);
    }

    function sponsor() external payable {
        require(!courseStatus, "Course has already begun.");
        require(payment > sponsorshipTotal, "This course is fully sponsored :)");
        require(msg.value > 0, "Please input amount you wish to sponsor");
        require(msg.value <= (payment - sponsorshipTotal), "Please input the Sponsorship amount needed or less");

        roles[SPONSOR][msg.sender] = true;
        uint currentDeposit = sponsorDeposit[msg.sender] + msg.value;
        sponsorshipTotal += msg.value;

        sponsorDeposit[msg.sender] = currentDeposit;
        emit Sponsored(currentDeposit, msg.sender);
    }

    function unsponsor(address payable _to, uint _amount) external payable onlyRole(SPONSOR){
        require(!courseStatus, "Course has already begun.");
        require(_amount > 0, "Please input an amount to unsponsor");
        require(_amount <= sponsorDeposit[_to], "That is more than you have sponsored");
        require(_to == msg.sender, "You are not the owner of this address.");

        (bool success, ) = _to.call{value: _amount}("");
        require(success);

        uint currentDeposit = sponsorDeposit[_to] - _amount;
        sponsorshipTotal -= _amount;
        sponsorDeposit[_to] = currentDeposit;

        if (sponsorDeposit[_to] == 0) {
            roles[SPONSOR][_to] = false;
            emit RevokeRole(SPONSOR, _to);
}
emit Sponsored(currentDeposit, _to);
}
}