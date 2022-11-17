/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
// File: salary.sol


pragma solidity ^0.8.7;

contract Salary_of_individual{
    
    
    uint256 Emp_id;

    struct Employe{
        uint256 Emp_id;
        string Emp_name;
        string Emp_des;
        uint256 salary;
        
    }

    mapping ( uint256 => Employe) public EmployeData;

    function addEmploye(uint256 _Emp_id, string memory _Emp_name, string memory _Emp_des,uint256 _salary) public {
        
        EmployeData[_Emp_id] = Employe(_Emp_id, _Emp_name, _Emp_des, _salary);
    
    }

    

    function getEmploye(uint256 Emp_Id) public view returns(uint256,string memory, string memory,uint256 ){
        
        return (EmployeData[Emp_Id].Emp_id,EmployeData[Emp_id].Emp_name,EmployeData[Emp_id].Emp_des,EmployeData[Emp_id].salary);

    }

    function fetchEmploye(uint256 _Emp_id)public view returns(bool salary){
        if(EmployeData[_Emp_id].salary>1000){
            return true;
        }
    }
}