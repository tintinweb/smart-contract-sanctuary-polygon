// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract MockBribe {
	event DepositBribe(
		bytes32 indexed proposal,
		address indexed token,
		uint256 amount,
		address indexed briber
	);

	function depositBribeERC20(
		bytes32 proposal,
    address token,
    uint256 amount
	) external {
		emit DepositBribe(
			proposal,
			token,
			amount,
			msg.sender
    );
	}
}