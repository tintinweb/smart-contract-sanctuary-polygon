/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface DAIGON {
	function stakeInfo(address addr) external view returns (uint112 totalReturn, uint112 activeStakes, uint112 totalClaimed, uint256 claimable, uint112 cps);
}

contract DGTestimonials {
	address public owner;
	DAIGON public daigon;

	struct Testimonial {
		address user;
		uint32 date_testified;
		string message;
	}

	Testimonial[] public testimonials;
	mapping(address => bool) public testified;
	mapping(uint256 => bool) public removed;
	uint256 public removeCount;

	constructor(address _daigon) {
		owner = msg.sender;
		daigon = DAIGON(_daigon);
	}

	function random(uint256 offset) public view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(offset, block.timestamp)));
	}

	function createTestimonial(string memory message) public {
		(,, uint112 totalClaimed,,) = daigon.stakeInfo(msg.sender);
		require(totalClaimed >= 20 ether, "You're not eligible to testify.");
		require(!testified[msg.sender], "You've already made a testimony.");
		testified[msg.sender] = true;
		testimonials.push(Testimonial(msg.sender, uint32(block.timestamp), message));
	}

	function removeTestimonial(uint256 index) public {
		require(msg.sender == owner);
		if(!removed[index]) {
			removeCount++;
			removed[index] = true;
		}
	}

	function getTestimonials(uint256 offset) external view returns (address[] memory, uint32[] memory, string[] memory) {
		uint256 length = testimonials.length;
		address[] memory user = new address[](10);
		uint32[] memory date_testified = new uint32[](10);
		string[] memory message = new string[](10);

		for(uint256 i = 0; i < 10; ++i) {
			if(offset + i < length) break;
			if(removed[offset + i]) continue;
			user[i] = testimonials[offset + i].user;
			date_testified[i] = testimonials[offset + i].date_testified;
			message[i] = testimonials[offset + i].message;
		}
		
		return (user, date_testified, message);
	}

	function testimonialsLength() external view returns (uint256) {
		return testimonials.length;
	}

	function random3Testimonials() external view returns (address[] memory, uint32[] memory, string[] memory) {
		uint256 length = testimonials.length;
		require(length - removeCount > 4, "insufficient data");

		address[] memory user = new address[](3);
		uint32[] memory date_testified = new uint32[](3);
		string[] memory message = new string[](3);

		uint256 n1;
		bool set;
		uint256 offset = 0;

		while(!set) {
			n1 = random(offset) % length;
			if(!removed[n1]) set = true;
			offset++;
		}

		uint256 n2;
		uint256 n3;

		while(!set) {
			n2 = random(offset) % length;
			if(n2 != n1 && !removed[n2]) set = true;
			offset++;
		}

		set = false;
		while(!set) {
			n3 = random(offset) % length;
			if(n3 != n1 && n3 != n2 && !removed[n3]) set = true;
			offset++;
		}

		user[0] = testimonials[n1].user;
		date_testified[0] = testimonials[n1].date_testified;
		message[0] = testimonials[n1].message;

		user[1] = testimonials[n2].user;
		date_testified[1] = testimonials[n2].date_testified;
		message[1] = testimonials[n2].message;

		user[2] = testimonials[n3].user;
		date_testified[2] = testimonials[n3].date_testified;
		message[2] = testimonials[n3].message;

		return (user, date_testified, message);
	}
}