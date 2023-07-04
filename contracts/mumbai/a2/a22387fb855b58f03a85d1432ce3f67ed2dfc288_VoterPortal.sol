/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract VoterPortal {

    address private owner;
    event ElectionResultLog(string indexed electionId, string indexed adminId, string[] winner, uint256 timestamp);
    event OwnerLog(address indexed owner, uint256 timestamp);

    struct ElectionResult {
        string electionId;
        string adminId;
        string[] winner;
    }

    constructor() {
        owner = msg.sender;
    }

    mapping(string => ElectionResult) private electionResultMap;

    function setElectionResult(string memory _electionId, string memory _adminId, string[] memory _winner) public {
        require(msg.sender == owner, "Insufficient Access");
        require(bytes(electionResultMap[_electionId].electionId).length == 0, "Election Id already exists");
        electionResultMap[_electionId] = ElectionResult(_electionId, _adminId, _winner);
        emit ElectionResultLog(_electionId, _adminId, _winner, block.timestamp);
    }

    function getElectionResult(string memory _electionId) public view returns (ElectionResult memory){
        return electionResultMap[_electionId];
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner, "Insufficient Access");
        owner = _owner;
        emit OwnerLog(_owner, block.timestamp);
    }

    function getOwner() public view returns (address){
        return owner;
    }

}