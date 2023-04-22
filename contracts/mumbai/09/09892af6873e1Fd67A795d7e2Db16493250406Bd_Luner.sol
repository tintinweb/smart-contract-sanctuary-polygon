/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Luner {
	uint256 lunerSeconds = 2551442.77777766 gwei;
    address public author = 0xd90f7Fb941829CFE7Fc50eD235d1Efac05c58190;
    string public doubleCheckAt = "https://www.moongiant.com/phase/today/";

	function phaseToRange(uint256 phase) internal pure returns (string memory) {
		if (phase < 0.02 gwei) return "New Moon";
		if (phase < 0.24 gwei) return "Waxing Crescent";
		if (phase < 0.26 gwei) return "First Quarter";
		if (phase < 0.49 gwei) return "Waxing Gibbous";
		if (phase < 0.51 gwei) return "Full Moon";
		if (phase < 0.74 gwei) return "Waning Gibbous";
		if (phase < 0.76 gwei) return "Last Quarter";
		if (phase < 0.98 gwei) return "Waning Crescent";
		return "New Moon";
	}

	function secondsSinceNewMoon() public view returns (uint256) {
		return block.timestamp - 947163600;
	}

	function secondsInCurrentCycle() public view returns (uint256) {
		return (secondsSinceNewMoon() * 1 gwei) % lunerSeconds;
	}

	function currentFrac() public view returns (uint256) {
		return (secondsInCurrentCycle() * 1 gwei) / lunerSeconds;
	}

    function currentPhase() public view returns (string memory) {
        return phaseToRange(currentFrac());
    }
}