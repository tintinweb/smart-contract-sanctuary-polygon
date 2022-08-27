/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface DisasterInterface  {
     function setSeverity(string memory district, uint newSeverity) external;
    function getSeverityData(string memory district, uint day) external view returns (uint);
     function getDistricts() external pure returns (string memory);
     function getAccumulatedSeverity(string memory district) external view returns (uint);
}

contract A {
   function foo() external pure returns(string memory){
        DisasterInterface d = DisasterInterface(0xaD736Bb2D21e38e9978592904ea746Af489476e6);
        return d.getDistricts();
    } 

  
}