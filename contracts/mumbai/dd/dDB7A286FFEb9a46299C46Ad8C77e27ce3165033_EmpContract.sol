/**
 *Submitted for verification at polygonscan.com on 2022-09-12
*/

pragma solidity  ^0.8.7;
// SPDX-License-Identifier: MIT


contract EmpContract {
    uint public get = 0;
    mapping(uint => Details) public info;

    address public owner;

    

    struct Details {
        
        string _organisation_name;
        address payable  _employeeWalletadd;
        string _employeename;
        uint _employeephnumber;
        uint _worksnapid; 
        uint256 _tokenamount;
        

    }

   constructor() {
        owner = msg.sender;
        
      }
     

    function  addEmpdetails (
        uint  _worksnapid,
         uint _employeephnumber,
        string memory _employeename,
        string memory _organisation_name,
         address payable  _employeeWalletadd,
         uint256 _tokenamount

    )public payable {
        info[get] = Details( _organisation_name, _employeeWalletadd, _employeename, _employeephnumber,_worksnapid,_tokenamount);


    }
         

     function transfertoken( ) public  payable  {
        
           

        (bool success, ) = info[get]._employeeWalletadd.call{ value : info[get]._tokenamount}("owner");
        
        require(success , "call failed");
  }
}