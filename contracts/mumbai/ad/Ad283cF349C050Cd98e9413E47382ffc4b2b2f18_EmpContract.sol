/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

pragma solidity  ^0.8.7;
// SPDX-License-Identifier: MIT


contract EmpContract {
    uint256 public peopleCount = 0;
    mapping(uint => Details) public info;

    address public owner;

    

    struct Details {
        
        string _organisation_name;
        address _employeeWalletadd;
        string _employeename;
        uint _employeephnumber;
        uint _worksnapid;

    }

   constructor() {
        owner = msg.sender;
      }

    function  addEmpdetails (
        uint  _worksnapid,
         uint _employeephnumber,
        string memory _employeename,
        string memory _organisation_name,
         address  _employeeWalletadd
   
    )public  {
        info[peopleCount] = Details( _organisation_name, _employeeWalletadd, _employeename, _employeephnumber,_worksnapid);
    }
         
    
}