// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

error Wallet__isNotOwner();
error Wallet__InvalidTokenAddress();

contract Wallet {
	address payable public owner;

	constructor(address payable _owner) {
		owner = _owner;
	}

	receive() external payable {}

	modifier isOwner() {
		if (msg.sender != owner) revert Wallet__isNotOwner();
		_;
	}
	modifier isValidERC20(address _token) {
		if (_token == address(0)) revert Wallet__InvalidTokenAddress();
		_;
	}

	function withdraw(uint _amount) external isOwner {
		payable(msg.sender).transfer(_amount);
	}

	function withdrawERC20(address _token, uint _amount) external isOwner isValidERC20(_token) {
		IERC20 token = IERC20(_token);
		token.transfer(msg.sender, _amount);
	}

	function getETHBalance() external view returns (uint) {
		return address(this).balance;
		// will give the balance in eth
	}

	function getERC20Balance(address _token) external view isValidERC20(_token) returns (uint) {
		IERC20 token = IERC20(_token);
		return token.balanceOf(address(this));
	}
}