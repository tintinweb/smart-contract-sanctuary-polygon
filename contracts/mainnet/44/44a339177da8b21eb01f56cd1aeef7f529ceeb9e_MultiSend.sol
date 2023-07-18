pragma solidity ^0.4.23;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract MultiSend {
	using SafeERC20 for IERC20;

  mapping(address => bool) public admins;
	
	event AdminSet(address indexed newAdmin);
	event AdminRemoved(address indexed oldAdmin);
	event Transfer(address indexed from, address indexed to, address indexed tokenAddress, uint tokens);

	constructor() public {
		admins[msg.sender] = true;
		emit AdminSet(msg.sender);
	}

	modifier onlyAdmin() {
		require(admins[msg.sender], "Must be an admin");
		_;
	}

	function setAdmin(address admin) external onlyAdmin returns(bool success){
		admins[admin] = true;
		emit AdminSet(admin);
		return admins[admin];
	}

	function removeAdmin(address admin) external onlyAdmin returns(bool success){
		admins[admin] = false;
		emit AdminRemoved(admin);
		return !admins[admin];
	}

	// withdraw tokens stuck in the contract
	function withdraw(address returnee, address tokenAddress, uint256 amount)external onlyAdmin returns(bool success){
		IERC20 token = IERC20(tokenAddress);
		uint256 balance = token.balanceOf(address(this));
		require(balance > 0, "There are no tokens to withdraw");
		require(balance >= amount, "Attempting to withdraw more tokens than available");
		require(token.safeTransfer(returnee, amount) == true, "Failed to transfer tokens");
		emit Transfer(address(this), returnee, tokenAddress, amount);
		return true;
	}

	function sendEth(address[] memory recipients, uint256[] memory amounts) public payable returns (bool) {
		// input validation
		require(recipients.length == amounts.length, "Recipients array must have same length as amounts");

		// count values for refunding sender
		uint256 sentTotal = 0;

		// loop through recipients and send amount
		for (uint i = 0; i < recipients.length; i++) {
			sentTotal = sentTotal + amounts[i];
			require(sentTotal <= msg.value, "Ran out of funds. 'value' should be at least sum of amounts");
			require(recipients[i].send(amounts[i]), "Failed to send");
			emit Transfer(msg.sender, recipients[i], address(0), amounts[i]);
		}
		// send back remaining value to sender
		uint256 remainingValue = msg.value - sentTotal;
		if (remainingValue > 0) {
			require(msg.sender.send(remainingValue), "Failed to send remaining back to self");
			emit Transfer(address(this), msg.sender, address(0), remainingValue);
		}
		return true;
	}

	function sendErc20(address tokenAddress, address[] memory recipients, uint256[] memory amounts) public returns (bool) {
		// input validation
		require(recipients.length == amounts.length, "Recipients array must have same length as amounts");

		// use the erc20 abi
		IERC20 token = IERC20(tokenAddress);

		// check if contract is allowed to send total amount
		uint256 total = 0;
		for (uint i = 0; i < recipients.length; i++) {
			total += amounts[i];
		}
		require(token.allowance(msg.sender, address(this)) >= total, "Insufficient token allowance");

		// loop through recipients and send amount
		for (i = 0; i < recipients.length; i++) {
			require(token.safeTransferFrom(msg.sender, recipients[i], amounts[i]) == true, "Failed to transfer");
			emit Transfer(msg.sender, recipients[i], tokenAddress, amounts[i]);
		}
		return true;
	}

}