/**
 *Submitted for verification at polygonscan.com on 2022-07-23
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Exchange
 * 1st Item : Coin GuildFiToken
 * 1st Address : 0x7EFD8beC4A6E928747Fc9bB4c1DEF138F1C4Cfa4
 * 2nd Item : Native Token
*/

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Exchange {

	address owner;
	event Exchanged (address indexed tgt);

	constructor() {
		owner = msg.sender;
	}

	//This function allows the owner to specify an address that will take over ownership rights instead. Please double check the address provided as once the function is executed, only the new owner will be able to change the address back.
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

/**
 * Function exchange1To2
 * Minimum Exchange Amount : 10000000000000000
 * Exchange Rate : 1
 * The function takes in 1 variable, zero or a positive integer v0. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that v0 is greater than or equals to 10000000000000000
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as v0
 * transfers v0 of the native currency to the address that called this function
 * emits event Exchanged with inputs the address that called this function
*/
	function exchange1To2(uint256 v0) public {
		require((v0 >= 10000000000000000), "Too little exchanged");
		ERC20(0x7EFD8beC4A6E928747Fc9bB4c1DEF138F1C4Cfa4).transferFrom(msg.sender, address(this), v0);
		payable(msg.sender).transfer(v0);
		emit Exchanged(msg.sender);
	}

/**
 * Function withdrawToken1
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
*/
	function withdrawToken1(uint256 _amt) public onlyOwner {
		ERC20(0x7EFD8beC4A6E928747Fc9bB4c1DEF138F1C4Cfa4).transfer(msg.sender, _amt);
	}

/**
 * Function withdrawToken2
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * transfers _amt of the native currency to the address that called this function
*/
	function withdrawToken2(uint256 _amt) public onlyOwner {
		payable(msg.sender).transfer(_amt);
	}

	function sendMeNativeCurrency() external payable {
	}
}