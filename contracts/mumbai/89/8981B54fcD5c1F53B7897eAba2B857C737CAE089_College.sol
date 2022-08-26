/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract College {

    struct StudentDetails {
        string name;
        uint class;
        uint feespaid;
    }

    mapping(uint => StudentDetails) private students;

    uint public totalStudents; // Default value 0

    function enroll(string memory name, uint class) external{
        
        students[totalStudents].name = name;
        students[totalStudents].class = class;
        students[totalStudents].feespaid = 0;

        totalStudents += 1;
    }

    function getStudentDetails(uint rollNumber) external view returns (StudentDetails memory){
        
       return students[rollNumber];
}
    function payFees(uint rollNumber)
    external payable
    {
        students[rollNumber].feespaid += msg.value;
    }

    //0.1 matic 
    //wei
    //1matic = 10**18 wei
    //1 matic-> 10 **18 wei

}