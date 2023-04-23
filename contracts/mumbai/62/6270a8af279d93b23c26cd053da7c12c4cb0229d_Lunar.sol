/**
 *Submitted for verification at polygonscan.com on 2023-04-23
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
    event SetPhaseCutoffs(uint256[8] _phaseCutoffs);

    uint256 public synodicMonth;
    uint256 public referenceNewMoon;
    address public owner;
    uint256[8] public phaseCutoffs;

    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);

        synodicMonth = 2551442.77777766 gwei; // seconds in a synodic month
        emit SetSynodicMonth(synodicMonth);

        referenceNewMoon = 947163600; // January 6th 2000
        emit SetReferenceNewMoon(referenceNewMoon);

        phaseCutoffs = [
            0.02 gwei,
            0.24 gwei,
            0.26 gwei,
            0.49 gwei,
            0.51 gwei,
            0.74 gwei,
            0.76 gwei,
            0.98 gwei
        ];
        emit SetPhaseCutoffs(phaseCutoffs);
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
        require(
            _synodicMonth > 2551440 gwei,
            "Synodic month must be greater than 2551440 seconds."
        ); // needs to be a reasonable value
        require(
            _synodicMonth < 2551444 gwei,
            "Synodic month must be less than 2551444 seconds."
        );
        synodicMonth = _synodicMonth;
    }

    function setPhaseCutoffs(uint256[8] memory _phaseCutoffs) public onlyOwner {
        require(_phaseCutoffs[0] < 1 gwei, "Phase cutoffs must be less than 1.");
        
        // ensure each element is greater than the last
        for (uint256 i = 1; i < _phaseCutoffs.length; i++) {
            require(_phaseCutoffs[i] > _phaseCutoffs[i - 1], "Phase cutoffs must be in ascending order.");
            require(_phaseCutoffs[i] < 1 gwei, "Phase cutoffs must be less than 1.");
        }
        phaseCutoffs = _phaseCutoffs;
        emit SetPhaseCutoffs(_phaseCutoffs);
    }

    function phaseToRange(uint256 phase) internal view returns (string memory) {
        if (phase < phaseCutoffs[0]) return "New Moon";
        if (phase < phaseCutoffs[1]) return "Waxing Crescent";
        if (phase < phaseCutoffs[2]) return "First Quarter";
        if (phase < phaseCutoffs[3]) return "Waxing Gibbous";
        if (phase < phaseCutoffs[4]) return "Full Moon";
        if (phase < phaseCutoffs[5]) return "Waning Gibbous";
        if (phase < phaseCutoffs[6]) return "Last Quarter";
        if (phase < phaseCutoffs[7]) return "Waning Crescent";
        return "New Moon";
    }

    function _currentFrac(uint256 timestamp) internal view returns (uint256) {
        return
            ((((timestamp - referenceNewMoon) * 1 gwei) % synodicMonth) *
                1 gwei) / synodicMonth;
    }

    function currentFrac() public view returns (uint256) {
        return _currentFrac(block.timestamp);
    }

    function phaseAtMoment(
        uint256 timestamp
    ) public view returns (string memory) {
        require(
            timestamp > referenceNewMoon,
            "Timestamp must be after reference new moon."
        );
        return phaseToRange(_currentFrac(timestamp));
    }

    function currentPhase() public view returns (string memory) {
        return phaseToRange(currentFrac());
    }
}