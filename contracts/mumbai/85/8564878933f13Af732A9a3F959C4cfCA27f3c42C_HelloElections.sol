/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;



contract HelloElections {

    string elecName;

     function get()public pure returns (string memory){
        return 'Hello contracts' ;
    }

    function electionName(string memory _eName) public {
        elecName = _eName;
    }

    function getElectionName() external view returns(string memory elecName){
         return elecName;
    }

   
}