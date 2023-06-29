/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract VotingSystem {

struct Campaign {
uint256 id;
string name;
uint256 endTime;
uint256 totalVotes;
string description;
}

struct Candidate {
address id;
uint256 noOfVotes;
}

struct Voter {
uint256 id;
address candidateAddress;
bool isVoted;
}

mapping(uint256 => Campaign) campaigns;
mapping(uint256 => Candidate[]) candidateInfo;
mapping(uint256 => mapping(address => Candidate)) campaignCandidate;
mapping(uint256 => mapping(address => Voter)) campaignVoter;
Campaign[] _camp;

event CampaignCreated(uint256 campaignId, string nameOfCampaign, string desc, uint256 time);
event CandidateAdded(uint256 campaignId, address canAddress);
event Voted(uint256 campaignId, address canAddress, address voterAddress);

function createCampaign(uint256 id, string memory name, string memory description, uint256 endTime) public {
require(endTime > block.timestamp);
campaigns[id] = Campaign(id, name, endTime, 0, description);
_camp.push(campaigns[id]);
emit CampaignCreated(id, name, description, endTime);
}

function addCandidate(uint256 campaignid, address candidate) public {
require(campaigns[campaignid].endTime > block.timestamp);
campaignCandidate[campaignid][candidate] = Candidate(candidate, 0);
candidateInfo[campaignid].push(Candidate(candidate, 0));
emit CandidateAdded(campaignid, candidate);
}

function liveCampaigns() public view returns(Campaign[] memory) {
Campaign[] memory liveCampaignArr = new Campaign[](_camp.length);

for(uint256 i = 0; i<_camp.length ; i++) {
if(_camp[i].endTime > block.timestamp) {
liveCampaignArr[i] = _camp[i];
}
}
return liveCampaignArr;
}

function endedCampaigns() public view returns(Campaign[] memory) {
Campaign[] memory endedCampaignArr = new Campaign[](_camp.length);

for(uint256 i = 0; i<_camp.length ; i++) {
if(_camp[i].endTime > block.timestamp) {
endedCampaignArr[i] = _camp[i];
}
}
return endedCampaignArr;
}

function getCampaignData(uint256 id) public view returns(Campaign memory) {
return campaigns[id];
}

function checkIfUserHasVoted(uint256 campaignId, address userId) public view returns(bool) {
return campaignVoter[campaignId][userId].isVoted;
}

function getCandidates(uint256 id) public view returns(Candidate[] memory) {
return candidateInfo[id];
}

function vote(uint256 id, address candidate) public {
require(campaigns[id].endTime > block.timestamp);
require(campaignVoter[id][msg.sender].isVoted == false, "Already Voted");
campaignVoter[id][msg.sender].isVoted = true;
campaignCandidate[id][candidate].noOfVotes++;
campaigns[id].totalVotes++;
emit Voted(id, candidate, msg.sender);
}

function getVoteCount(uint256 id, address candidate) public view returns (uint256) {
return campaignCandidate[id][candidate].noOfVotes;
}

}