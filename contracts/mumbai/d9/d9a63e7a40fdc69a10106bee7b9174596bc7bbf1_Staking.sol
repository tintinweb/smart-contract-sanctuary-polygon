/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT
contract Staking {

	struct record0 { uint256 staker; uint256 stakeTime; string monkey; }
	struct record1 { uint256 staker; uint256 stakeTime; string monkey; record0 ha; record0[] b; }

	function test() public pure returns (record0[2] memory){
		record0 memory a = record0 (1, 2, "a");
		record0 memory b = record0 (1, 2, "b");
		return [a, b];
	}

	function test1() public pure returns (record0[] memory){
		record0 memory a = record0 (1, 2, "c");
		record0 memory b = record0 (2, 3, "d");
		record0 memory c = record0 (3, 4, "e");
		record0[] memory aList;
		aList[0] = a;
		aList[1] = b;
		aList[3] = c;
		return aList;
	}

	function test2() public pure returns (record1[] memory){
		record0 memory a = record0 (1, 2, "a");
		record0 memory b = record0 (1, 2, "b");
		record0[] memory b1;
		b1[0] = b;
		record1 memory c = record1 (1, 2, "b", a, b1);
		record1[] memory bList;
		bList[0] = c;
		bList[1] = c;
		return bList;
	}



}