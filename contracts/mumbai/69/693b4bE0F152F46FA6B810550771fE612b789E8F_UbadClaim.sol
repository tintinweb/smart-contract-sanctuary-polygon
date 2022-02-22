// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

import "./IERC20.sol";
import './SafeMath.sol';

contract UbadClaim {

	using SafeMath for uint;

	// This map for store had cliamed the addresses and claimed amount.
	mapping(address => uint256) public claimed;

	address constant public UbadAddress = 0xa49Df7c22FFB8105102BD98a6c3c1c45Bb4a5274;

	uint public totalRewardsBalance; 

	constructor(uint _totalRewards) {
		totalRewardsBalance = _totalRewards * 10e18;	
	}

	function claim() payable public {
		require(claimed[msg.sender] == 0, "The address had claimed rewards");
		// this is function to generate a random number
		// uint256 rewards  = random(10*10e18);			
		// claimed[msg.sender] = rewards;
		// totalRewardsBalance = totalRewardsBalance.sub(rewards);
		IERC20(UbadAddress).transfer(msg.sender, 1*10e18);
		// return rewards;
	}

	// To generate a random number less than num
	function random(uint num) private view returns (uint) {
  		return uint(uint256(keccak256(abi.encode(block.timestamp , block.difficulty)))%num);
	}
}