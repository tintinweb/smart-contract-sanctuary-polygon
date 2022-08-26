/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.7;
// contract MyCalculator{
//     string public creator="Niraj";
//     address public owner;
//     constructor(){
//         owner=msg.sender;
//     }

//     modifier onlyOwner(){
//         require(owner==msg.sender);
//     }

//     function sum(int x,int y) public pure returns(int ){
//         return x+y;
//     } 

//     function sub(int x,int y) public pure returns(int){
//         return x-y;
//     }

//     function personalDivision(int x, int y) public view onlyOwner returns(int ){
//         return x/y;
//     }

// }

contract College{

    struct StudDetails{
        string name;
        uint class;
        uint feesp;
    }

    mapping(uint=>StudDetails) private students;

    uint totStud=0;
    function enroll(string memory name,uint class )external {
        students[totStud].name=name;
        students[totStud].class=class;
        students[totStud].feesp=0;
        totStud+=1;
    } 

    function getStudent(uint rollnumber) external view returns(StudDetails memory){
        return students[rollnumber];
    }

    function payfees(uint rollnumber) external payable{
        students[rollnumber].feesp+=msg.value;
    }

}