/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractName {
    struct Supply {
        mapping (uint256 => bool) supplies;
    }
    mapping (uint256 => Supply) supplyIDs;

    function addToken(uint256 _id, uint256 _supp) public{
      supplyIDs[_id].supplies[_supp] = true;
    }

    function getToken(uint256 _id, uint256 _supp) public view returns (bool){
      return supplyIDs[_id].supplies[_supp];
    }
}