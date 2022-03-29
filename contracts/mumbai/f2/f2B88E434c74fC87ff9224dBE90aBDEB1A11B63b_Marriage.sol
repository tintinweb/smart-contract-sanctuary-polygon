/**
 *Submitted for verification at polygonscan.com on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Marriage {
    string husband = "TheBeast";
    string wife = "MissMax";

    uint private _startTime;
    uint private _endTime;

    mapping(string=>string) public _vowsByBothParties;
    
    constructor(string memory _husband, string memory _wife) {
        _vowsByBothParties[husband] = _husband;
        _vowsByBothParties[wife] = _wife;

        _startTime = block.timestamp;
        _endTime = block.timestamp + 60*60;
    }

    function hasTheMarriageContractEnded() external view returns(string memory) {
        if(block.timestamp >= _endTime) {
            return "Yes";
        }
        return "No";
    }

    function marriageContractStartTime() external pure returns(string memory) {
        return "1st of April 2022 18:00 (GST)";
    }

     function marriageContractEndTime() external pure returns(string memory) {
        return "2nd of April 2022 18:00 (GST)";
    }

    function wifeVow() external view returns(string memory) {
        return _vowsByBothParties[wife];
    }
    
    function husbandVow() external view returns(string memory) {
        return _vowsByBothParties[husband];
    }
}