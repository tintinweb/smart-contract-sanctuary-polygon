// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract LearnAndEarn{
    uint256 public totalCourses;

    struct Courses{
        uint256 courseId;
        uint256 pricePerShare;
        uint256 totalShares;
    }

    struct Students{
        address studentAddress;
        uint256 courseId;
        uint256 shares;
        bool isForSale;
        uint256 pricePerShare;
    }

    mapping(uint256 => Courses) public courses;
    mapping(address => Students) public students;

    event CourseBought( uint256 _courseId, uint256 _shares, uint256 _totalPrice);
    event CourseBoughtFromPool(address _seller, address _buyer, uint256 _courseId, uint256 _shares, uint256 _totalPrice);
    event ShareForSale(address _seller, uint256 _courseId, uint256 _shares, uint256 _pricePerShare);
    event ShareNotForSale(address _seller, uint256 _courseId, uint256 _shares, uint256 _pricePerShare);

    constructor(){
        totalCourses = 0;
    }

    function createCourse(uint256 _pricePerShare, uint256 _totalShares) public{
        totalCourses++;
        courses[totalCourses] = Courses(totalCourses, _pricePerShare, _totalShares);
    }

    // buy course
    function buyCourse(uint256 _courseId, uint256 _shares) public payable{
        require(courses[_courseId].totalShares >= _shares, "Not enough shares available");
        require(msg.value >= _shares * courses[_courseId].pricePerShare, "Not enough fund sent");

        payable(address(this)).transfer(_shares * courses[_courseId].pricePerShare);

        courses[_courseId].totalShares -= _shares;
        students[msg.sender] = Students(msg.sender, _courseId, _shares, false, courses[_courseId].pricePerShare);
        emit CourseBought(_courseId, _shares, _shares * courses[_courseId].pricePerShare);
    }

    // set isForSale to true and set pricePerShare maximum of 10% more than original pricePerShare
    function sellCourse(uint256 _courseId, uint256 _pricePerShare) public{
        require(students[msg.sender].courseId == _courseId, "You are not enrolled in this course");
        require(students[msg.sender].isForSale == false, "You have already put this course for sale");
        require(_pricePerShare <= students[msg.sender].pricePerShare * 110 / 100, "Price per share cannot be more than 10% of original price per share");

        students[msg.sender].isForSale = true;
        students[msg.sender].pricePerShare = _pricePerShare;

        emit ShareForSale(msg.sender, _courseId, students[msg.sender].shares, _pricePerShare);
    }

    // set isForSale to false
    function cancelSellCourse(uint256 _courseId) public{
        require(students[msg.sender].courseId == _courseId, "You are not enrolled in this course");
        require(students[msg.sender].isForSale == true, "You have not put this course for sale");

        students[msg.sender].isForSale = false;

        emit ShareNotForSale(msg.sender, _courseId, students[msg.sender].shares, students[msg.sender].pricePerShare);
    }

    // buy course from another student
    function buyCourseFromStudent(address _studentAddress, uint256 _courseId, uint256 _shares) public payable {
        require(students[_studentAddress].courseId == _courseId, "Student is not enrolled in this course");
        require(students[_studentAddress].isForSale == true, "Student has not put this course for sale");
        require(students[_studentAddress].shares >= _shares, "Not enough shares available");
        require(msg.value >= _shares * students[_studentAddress].pricePerShare, "Not enough funds sent");

        uint256 totalPrice = _shares * students[_studentAddress].pricePerShare;

        // Transfer funds from the buyer to the seller
        payable(_studentAddress).transfer(totalPrice);

        // Update the shares and ownership for the buyer and seller
        students[_studentAddress].shares -= _shares;
        students[msg.sender].courseId = _courseId;
        students[msg.sender].shares += _shares;
        students[msg.sender].isForSale = false;

        emit CourseBoughtFromPool(_studentAddress, msg.sender, _courseId, _shares, totalPrice);
    }

    // get balance of contract
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    // get an array which shows students with priceOfShare and isForSale
    // function getStudentsForSale() public view returns (address[] memory, uint256[] memory, bool[] memory) {
    //     uint256 numStudentsForSale = 0;

    //     // Determine the number of students with courses for sale
    //     for (uint256 i = 0; i < totalStudents; i++) {
    //         if (students[i].isForSale) {
    //             numStudentsForSale++;
    //         }
    //     }

    //     // Initialize arrays to hold the student data
    //     address[] memory addresses = new address[](numStudentsForSale);
    //     uint256[] memory pricesOfShare = new uint256[](numStudentsForSale);
    //     bool[] memory isForSale = new bool[](numStudentsForSale);

    //     // Populate the arrays with the relevant student data
    //     uint256 index = 0;
    //     for (uint256 i = 0; i < totalStudents; i++) {
    //         if (students[i].isForSale) {
    //             addresses[index] = students[i].studentAddress;
    //             pricesOfShare[index] = students[i].priceOfShare;
    //             isForSale[index] = students[i].isForSale;
    //             index++;
    //         }
    //     }

    //     return (addresses, pricesOfShare, isForSale);
    // }
    
    // get share price and totalShares of all courses
    function getCourses() public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory pricesOfShare = new uint256[](totalCourses);
        uint256[] memory totalShares = new uint256[](totalCourses);

        for (uint256 i = 0; i < totalCourses; i++) {
            pricesOfShare[i] = courses[i].pricePerShare;
            totalShares[i] = courses[i].totalShares;
        }

        return (pricesOfShare, totalShares);
    }
}