/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract MarksheetSolution{
    constructor(){}
    // string marksheetURL;
    struct studentData {
        
        // bytes32 bidId;
        // address payable bidder;
        string marksheetURL;
        string studentName;
        // string studentID;
        // string class;
        // uint256 bidPrice;
        
       
    }
    struct studentDatanew {
        
        // bytes32 bidId;
        // address payable bidder;
        string marksheetURLi;
        string studentNamei;
        // string studentID;
        // string class;
        // uint256 bidPrice;
        
       
    }
    

    mapping(uint256 => mapping(uint256 => studentData)) public studentDataByStudentID; 

        mapping(uint256 => mapping(uint256 => studentDatanew)) public studentDataByStudentIDnew;  
 

    // mapping(uint256 => Bid) public urlbyStudentID;

    function uploadMarksheet (string memory  _url, uint256 _studentID, uint256 _classID) public {
        studentDataByStudentID[_classID][_studentID].marksheetURL = _url;
    }
    function getMarksheet(uint256 _studentID, uint256 _classID, string memory _url) payable public  
    {
        studentDataByStudentIDnew[_classID][_studentID].marksheetURLi = _url;
        
        // return studentDataByStudentID[_classID][_studentID].marksheetURL;
    }
}