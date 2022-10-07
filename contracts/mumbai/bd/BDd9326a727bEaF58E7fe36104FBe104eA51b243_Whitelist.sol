// SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

contract Whitelist{

uint8 public peopleWhitelisted;
mapping (address=>bool)public whitelistedData;

uint8 public maxNoOfWhitelist;
constructor(uint8 _max){
maxNoOfWhitelist=_max;
}


function whitelisting() public {
 require(!whitelistedData[msg.sender], "Sender has already been whitelisted");
 require(peopleWhitelisted<=maxNoOfWhitelist,"More addresses cant be added, limit reached");
 whitelistedData[msg.sender]=true;
 peopleWhitelisted+=1;

}
}