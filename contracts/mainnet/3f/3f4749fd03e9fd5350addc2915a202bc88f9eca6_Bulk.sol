/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


contract bot {
	constructor(address contractAddress, address to) payable{
        (bool success, ) = contractAddress.call{value: msg.value}(abi.encodeWithSelector(0x6a627842, to));
        require(success, "Batch transaction failed");
		selfdestruct(payable(tx.origin));
   }
}

contract Bulk {
	address private immutable owner;

	modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

	constructor() {
		owner = msg.sender;
	}

	function BulkMint(address contractAddress, uint256 times) external payable{
        uint price;
        if (msg.value > 0){
            price = msg.value / times;
        }
		address to = msg.sender;
		for(uint i=0; i< times; i++) {
			new bot{value: price}(contractAddress, to);
		}
	}
}