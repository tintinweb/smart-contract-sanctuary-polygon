// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./IERC1363Receiver.sol";

/*
    @name Merchant
    @description A guy who can receive payments
    @date April 4th 2023
    @author William Doyle
 */
contract Merchant is IERC1363Receiver {
	uint256 public callCount = 0;

	function onTransferReceived(address spender, address sender, uint256 amount, bytes calldata data) external returns (bytes4) {
		callCount++;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
		return interfaceId == type(IERC1363Receiver).interfaceId;
	}
}