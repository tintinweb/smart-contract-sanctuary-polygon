/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Luner {
    event DaysSince(uint256 daysSince);
    event MoonPhase(uint256 moonPhase);
    event MoonPhaseRange(string moonPhaseRange);
    
    function phaseToRange(uint256 phase) internal pure returns (string memory) {
        if (phase < 0.02 gwei)
            return "New Moon";
        if (phase < 0.24 gwei)
            return "Waxing Crescent";
        if (phase < 0.26 gwei)
            return "First Quarter";
        if (phase < 0.49 gwei)
            return "Waxing Gibbous";
        if (phase < 0.51 gwei)
            return "Full Moon";
        if (phase < 0.74 gwei)
            return "Waning Gibbous";
        if (phase < 0.76 gwei)
            return "Last Quarter";
        if (phase < 0.98 gwei)
            return "Waning Crescent";
        return "New Moon";
    }

    function moonPhase() public returns (uint256){
        uint256 timestamp = block.timestamp;
        uint256 lastNewMoon =  947163600 gwei; // january 6th 2000 -- gwei adds 9 zeros we will use as for decimals
        uint256 daysSince = ((timestamp * 1 gwei) - lastNewMoon) / 86400 gwei; // 86400 seconds in a day
        emit DaysSince(daysSince);

        uint256 phase = (daysSince - 2451550.1 gwei) / 29.530588853 gwei; 

        emit MoonPhase(phase);

        string memory moonPhaseRange = phaseToRange(phase);
        emit MoonPhaseRange(moonPhaseRange);

        return 0;

    }
}

// williamdoyle.eth