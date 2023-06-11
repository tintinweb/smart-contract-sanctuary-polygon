// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
	address public owner;

	constructor() {
		owner = msg.sender;
	}

	struct User {
		string name;
		string email; // google, proton, microsoft
		Product[] productsBought;
	}

	struct Product {
		string alphaId;
		uint8 price;
	}

	mapping (uint8 => User) public users;
	uint8 public userAmount;

	function addUser(string memory _name, string memory _email) public returns (uint8) {
		require(msg.sender==owner,"testable by the owner address");
		User storage user = users[userAmount];
		user.name = _name;
		user.email = _email;
		userAmount++;
		return userAmount-1;
	}

	function addProduct(Product memory _bought,uint8 _id) public {
		User storage user = users[_id];
		user.productsBought.push(_bought);
	}

	function returnProductsBought(uint8 _id) public view returns (Product[] memory) {
		User storage user = users[_id];
		return user.productsBought;
	}
}