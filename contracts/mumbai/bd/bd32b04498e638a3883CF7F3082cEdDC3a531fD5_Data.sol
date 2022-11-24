/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7;

contract Data{

	struct Employee{

		uint empid;
		string name;
		string department;
		uint sallery;
	}

	address claim;

	constructor(address _claim) {
        claim = _claim;
    }

	modifier OnlyClaimer() {
        require(msg.sender == claim);
        _;
    }

    mapping (uint => Employee) public Employee_data;
	Employee [] emps;

    uint count = 1;

	function addEmployee(uint empid, string memory name, string memory department, uint sallery) public  {
        Employee_data[count] = Employee(empid,name,department,sallery);
        Employee memory e =Employee(empid,name,department,sallery);
		emps.push(e);
        count++;
	}

	function SearchData(uint empid, uint _sallery) public view OnlyClaimer returns( bool ){
			bool t;
			uint i;
			for(i=0;i<emps.length;i++)
			{
				Employee memory e = emps[i];

				if(e.empid==empid)
				{
					if(e.sallery == _sallery){
						t = true;
					}
				}
			}
			return t;
		}
		
}