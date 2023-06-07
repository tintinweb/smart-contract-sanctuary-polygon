// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

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