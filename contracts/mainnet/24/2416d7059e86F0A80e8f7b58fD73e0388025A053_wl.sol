// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



/// @custom:security-contact [email protected]
contract wl 
{
   mapping (address => bool) public isWhitelisted;
   address[] wlAddresses;

   function getAllWhitelistedAddress() public view returns (address[] memory) {
       return wlAddresses;
   }

   function addWhitelist(address add) public { 
       wlAddresses.push(add);
       isWhitelisted[add] = true;
   }


}