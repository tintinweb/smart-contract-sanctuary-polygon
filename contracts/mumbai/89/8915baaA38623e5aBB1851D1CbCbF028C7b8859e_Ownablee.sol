// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Ownablee {
    
    event StudioAdded(address indexed _setter, address indexed _studio);
    event StudioRemoved(address indexed _setter, address indexed _studio);

    address public auditor;
    address private VOTE;                // vote contract address
    mapping(address => bool) private studioInfo;
    
    bool public isInitialized;           // check if contract initialized or not

    modifier onlyAuditor() {
        require(msg.sender == auditor, "caller is not the auditor");
        _;
    }

    modifier onlyVote() {
        require(msg.sender == VOTE, "caller is not the vote contract");
        _;
    }

    constructor() {
        auditor = msg.sender;
    }
    
    function setupVote(address _voteContract) external onlyAuditor {
        require(!isInitialized, "setupVote: Already initialized");
        require(_voteContract != address(0), "setupVote: Zero voteContract address");
        VOTE = _voteContract;    
                
        isInitialized = true;
    }    
    
    function transferAuditor(address _newAuditor) external onlyAuditor {
        require(_newAuditor != address(0), "Ownablee: Zero newAuditor address");
        auditor = _newAuditor;
    }

    function replaceAuditor(address _newAuditor) external onlyVote {
        require(_newAuditor != address(0), "Ownablee: Zero newAuditor address");
        auditor = _newAuditor;
    }

    function addStudio(address _studio) external onlyAuditor {
        require(!studioInfo[_studio], "addStudio: Already studio");
        studioInfo[_studio] = true;
        emit StudioAdded(msg.sender, _studio);
    }

    function removeStudio(address _studio) external onlyAuditor {
        require(studioInfo[_studio], "removeStudio: No studio");
        studioInfo[_studio] = false;
        emit StudioRemoved(msg.sender, _studio);
    }

    function isStudio(address _studio) external view returns (bool) {
        return studioInfo[_studio];
    }
}