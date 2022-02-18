// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFireBotTokenV3 {
	function _burn(address account, uint256 amount) external;
}

contract TestBurnV3 {

	IFireBotTokenV3 public FBX = IFireBotTokenV3(0xD125443F38A69d776177c2B9c041f462936F8218);
	
    function burn_fbx(uint256 amount) public {
		FBX._burn(msg.sender, amount);
	}	
}