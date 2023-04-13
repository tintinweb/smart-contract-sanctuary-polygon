/**
 *Submitted for verification at polygonscan.com on 2023-04-12
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT


interface ERC20{
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

contract PresaleMGPS {

	address owner;
	uint256 public minExchange1To2amt = uint256(1000000000000000000);
	uint256 public exchange1To2rate = uint256(310000000000000000);
	event Exchanged (address indexed tgt);

	constructor() {
		owner = msg.sender;
	}

	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function changeValueOf_minExchange1To2amt (uint256 _minExchange1To2amt) external onlyOwner {
		 minExchange1To2amt = _minExchange1To2amt;
	}

	function changeValueOf_exchange1To2rate (uint256 _exchange1To2rate) external onlyOwner {
		 exchange1To2rate = _exchange1To2rate;
	}

	function exchange1To2() public payable {
		require((msg.value >= minExchange1To2amt), "Too little exchanged");
		require((ERC20(0xEA22d7E2010ed681e91D405992Ac69B168cb8028).balanceOf(address(this)) >= ((msg.value * exchange1To2rate) / uint256(1000000000000000000))), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0xEA22d7E2010ed681e91D405992Ac69B168cb8028).transfer(msg.sender, ((msg.value * exchange1To2rate) / uint256(1000000000000000000)));
		emit Exchanged(msg.sender);
	}
	function withdrawToken1(uint256 _amt) public onlyOwner {
		require((address(this).balance >= _amt), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		payable(msg.sender).transfer(_amt);
	}
	function withdrawToken2(uint256 _amt) public onlyOwner {
		require((ERC20(0xEA22d7E2010ed681e91D405992Ac69B168cb8028).balanceOf(address(this)) >= _amt), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0xEA22d7E2010ed681e91D405992Ac69B168cb8028).transfer(msg.sender, _amt);
	}

	function sendMeNativeCurrency() external payable {
	}
}