/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

// SPDX-License-Identifier: None
pragma solidity >=0.8.9;

contract Bundles {

enum Status{ ACTIVE, PAUSED, FINISHED } 

struct Bundle { 
   uint256 bundleId;
   uint256 price;
   Status status;
   mapping(address => uint256) erc20s;
   mapping(address => uint256) erc721s;
   mapping(address => uint256) erc1155s;
}

mapping (uint256 => Bundle) public bundles;
address merchantAddress;
uint numBundles;

constructor(address devAddress) {

      // Accepts a address argument `devAddress` and sets the value into the contract's `merchantAddress` storage variable).
      merchantAddress = devAddress;
	  
	  Bundle storage newBundle = bundles[numBundles++];
	  newBundle.bundleId = 1;
	  newBundle.price = 20;
	  newBundle.status = Status.ACTIVE;
   }
   
}