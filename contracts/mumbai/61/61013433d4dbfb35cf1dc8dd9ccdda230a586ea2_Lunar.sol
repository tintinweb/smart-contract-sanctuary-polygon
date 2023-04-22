/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// solc version 0.8.2+commit.661d1103.Linux.g++
// algorithm:  https://en.wikipedia.org/wiki/Lunar_phase#Calculating_phase
// reference:  https://www.moongiant.com/phase/today/
// author:     WilliamDoyle.eth

contract Lunar {
    event TransferOwnership(address indexed _from, address indexed _to);
    event SetReferenceNewMoon(uint256 _newMoon);
    event SetSynodicMonth(uint256 _synodicMonth);

    uint256 public synodicMonth;
    uint256 public referenceNewMoon;
    address public owner;

    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);

        synodicMonth = 2551442.77777766 gwei; // seconds in a synodic month
        emit SetSynodicMonth(synodicMonth);

        referenceNewMoon = 947163600; // January 6th 2000
        emit SetReferenceNewMoon(referenceNewMoon);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
        emit TransferOwnership(msg.sender, _owner);
    }

    function setReferenceNewMoon(uint256 _newMoon) public onlyOwner {
        require(_newMoon < block.timestamp, "New moon must be in the past.");
        referenceNewMoon = _newMoon;
        emit SetReferenceNewMoon(_newMoon);
    }

    function setSynodicMonth(uint256 _synodicMonth) public onlyOwner {
        require(_synodicMonth > 2551440 gwei, "Synodic month must be greater than 2551440 seconds."); // needs to be a reasonable value
        require(_synodicMonth < 2551444 gwei, "Synodic month must be less than 2551444 seconds.");
        synodicMonth = _synodicMonth;
    }

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

    function _currentFrac(uint256 timestamp) internal view returns (uint256) {
        return ((((timestamp - referenceNewMoon) * 1 gwei) % synodicMonth) * 1 gwei) / synodicMonth;
    }

    function currentFrac() public view returns (uint256) {
        return _currentFrac(block.timestamp);
    }

    function phaseAtMoment(uint256 timestamp) public view returns (string memory) {
        require(timestamp > referenceNewMoon, "Timestamp must be after reference new moon.");
        return phaseToRange(_currentFrac(timestamp));
    }

    function currentPhase() public view returns (string memory) {
        return phaseToRange(currentFrac());
    }
}