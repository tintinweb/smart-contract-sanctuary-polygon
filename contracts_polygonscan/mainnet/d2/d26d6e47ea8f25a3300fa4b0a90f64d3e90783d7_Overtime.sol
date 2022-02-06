/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Overtime {

	address manager;
	uint public currStart;
	uint public totalTime;

	constructor() {
		manager = msg.sender;
	}	

	modifier onlyManager {
		require(msg.sender == manager, "only manager can execute");
		_;
	}

	event OverTime1(uint startTime, uint endTime, uint timeGap);
	function startStopwatch() external onlyManager {
		currStart = block.timestamp;
	}

	function resetStopwatch() external onlyManager {
		currStart = 0;
	}
	function resetTotal() external onlyManager {
		totalTime = 0;
	}

	function endStopWatch() external onlyManager {
		require(currStart != 0, "Stopwatch not started");
		uint endTime = block.timestamp;
		uint secondsPassed = endTime - currStart;
		emit OverTime1(currStart, endTime, secondsPassed);
		totalTime += secondsPassed;
		currStart = 0;
	}

	function getTimeInHours() external view returns(uint) {
		return totalTime / 3600;
	}

	function changeManager(address _newManager) external onlyManager {
		manager = _newManager;
	}
}