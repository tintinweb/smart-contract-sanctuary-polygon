// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFireBotTokenV4 {
	function approve(address spender, uint256 amount) external returns (bool);
	function burnFrom(address account, uint256 amount) external;
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TestBurnV4 {

	IFireBotTokenV4 public FBX = IFireBotTokenV4(0xD125443F38A69d776177c2B9c041f462936F8218);
	
	function this_approve(address spender, uint256 amount) public {
		FBX.approve(spender, amount);
	}
	
	function this_burnFrom(address account, uint256 amount) public {
		FBX.burnFrom(account, amount);
	}
	
	function this_approve_and_burnFrom(address account, uint256 amount) public {
		FBX.approve(address(this), amount);
		FBX.burnFrom(account, amount);
	}
	
	function this_transferFrom(address sender, address recipient, uint256 amount) public {
		FBX.transferFrom(sender, recipient, amount);
	}
}