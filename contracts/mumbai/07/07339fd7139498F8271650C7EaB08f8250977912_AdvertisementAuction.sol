/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


contract AdvertisementAuction {

	struct Advertisement {
		string ImageLink;
		string Text;
	}

	Advertisement public advertisement;
	uint256 public latestPayment;

	constructor(string memory _imageLink, string memory _text) {
		advertisement.ImageLink = _imageLink;
		advertisement.Text = _text;
	}

	function advertise(string memory _imageLink, string memory _text) public payable {
		require(msg.value > latestPayment, "Not enough Ether to advertise");
		latestPayment = msg.value;

		advertisement.ImageLink = _imageLink;
		advertisement.Text = _text;
	}

}