/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

pragma solidity >=0.8.9;

contract Bundles {

enum Status{ ACTIVE, PAUSED, FINISHED } 

struct Bundle { 
   uint256 bundleId;
   mapping(address => uint256) erc20s;
   mapping(address => uint256) erc721s;
   mapping(address => uint256) erc1155s;
   uint256 price;
   Status status;
}

mapping (uint256 => Bundle) public bundles;
address merchantAddress;

constructor(address devAddress) {

      // Accepts a address argument `devAddress` and sets the value into the contract's `merchantAddress` storage variable).
      merchantAddress = devAddress;
   }
   
}