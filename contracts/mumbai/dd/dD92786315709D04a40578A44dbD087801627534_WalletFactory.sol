// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error Wallet__isNotOwner();

contract Wallet {
    address payable public owner;

    constructor(address payable _owner) {
        owner = _owner;
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        if (msg.sender != owner) revert Wallet__isNotOwner();
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Wallet.sol";

error WalletFactory__AlreadyHaveMetadev3Wallet();

contract WalletFactory {
	mapping(address => address) public walletToMetadev3Wallet;

	event WalletCreated(address indexed owner, address indexed metadev3Wallet);

	function createWallet() external {
		if (walletToMetadev3Wallet[msg.sender] != address(0)) revert WalletFactory__AlreadyHaveMetadev3Wallet();
		Wallet newWallet = new Wallet(payable(msg.sender));
		walletToMetadev3Wallet[msg.sender]= address(newWallet);
		emit WalletCreated(msg.sender, address(newWallet));
	}
}