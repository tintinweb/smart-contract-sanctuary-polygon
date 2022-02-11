/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract PaymentSplitter {
	function splitPayment(address payable[] memory _recipients, uint[] memory _shares) external payable {
		require(_recipients.length > 0, "the number of recipients must be greater than 0");
		require(_shares.length > 0, "the number of shares must be greater than 0");
		require(_recipients.length == _shares.length, "the number of recipients & shares must be equal");

		uint sum = 0;

		for (uint256 i = 0; i < _shares.length; i++) {
			sum = sum + _shares[i];
		}

		require(sum == 100, "sum of shares is not equal to 100 percent");

		for (uint256 i = 0; i < _recipients.length; i++) {
			_recipients[i].transfer(msg.value * _shares[i] / 100);
		}
	}
}