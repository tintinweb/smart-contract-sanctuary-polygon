/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

pragma solidity^0.8.7;

contract College {
    struct StudentDetails {
        string name;
        uint class;
        uint feesPaid;


    }

    mapping(uint =>StudentDetails) private _students;
    uint public totalStudents; //by default is 0
    function enroll(string memory name_, uint class_, uint feesPaid_) public {
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        _students[totalStudents].feesPaid = feesPaid_;
        totalStudents += 1;


    }

    function getStudetsByIndex(uint index) public view returns(StudentDetails memory){
        return _students[index];
    }
    
    function payFees(uint index_) public payable{
        _students[index_].feesPaid = _students[index_].feesPaid + msg.value;
    }
    
}