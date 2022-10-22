/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

// SPDX-License-Identifier: None
pragma solidity >=0.8.9;

contract Bundles {

enum Status{ ACTIVE, PAUSED, FINISHED } 

struct Bundle { 
   uint256 bundleId;
   uint256 price;
   Status status;
   address[] erc20Addresses;
   uint256[] erc20Amounts;
   address[] erc721Addresses;
   uint256[] erc721Ids;
   address[] erc1155Addresses;
   uint256[] erc1155Ids;
}

mapping (uint256 => Bundle) public bundles;
address public merchantAddress;
uint numBundles;

   constructor(address devAddress) {

      // Accepts a address argument `devAddress` and sets the value into the contract's `merchantAddress` storage variable).
      merchantAddress = devAddress;
   }
   
   modifier onlyOwner() { // Modifier
        require(
            msg.sender == merchantAddress,
            "Only owner of this bundles can call this."
        );
        _;
    }
	
	function createBundle(uint256 price, Status status, address[] memory erc20Addresses, uint256[] memory erc20Amounts) public onlyOwner returns (bool) {
		require(price < 0, "Price must be grater than 0");
		require(erc20Addresses.length > 0, "The bundle needs at least one asset");
		require(erc20Addresses.length == erc20Amounts.length, "Each address must have their amount.");
        
		// Begin transaction
		// Bundle creation
		Bundle storage newBundle = bundles[numBundles];
		newBundle.bundleId = numBundles;
		newBundle.status = status;
		newBundle.price = price;
		newBundle.erc20Addresses = erc20Addresses;
		newBundle.erc20Amounts = erc20Amounts;
		
		numBundles++;
		
		// TODO: Tokens transfer
		
		// End transaction
		
		return true;
    }
   
}