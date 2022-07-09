// SPDX-License-Identifier: MIT
pragma solidity >=0.6.3 <0.9.0;

import "./RDAO.sol";

library Votings {
  function getVotings(uint[] storage votingsList, mapping(uint256 => RDAO.Voting) storage votings) public view returns (uint256[] memory) {
    uint numVotings;
    for (uint32 i = 0; i < votingsList.length; i++) {
      if (votings[votingsList[i]].status == RDAO.VotingStatus.ACTIVE) {
        numVotings++;
      }
    }

    uint256[] memory retVotingArr = new uint256[](numVotings);
    uint256 j = 0;

    for (uint32 i = 0; i < votingsList.length; i++) {
      if (votings[votingsList[i]].status == RDAO.VotingStatus.ACTIVE) {
        retVotingArr[j] = votingsList[i];
        j++;
      }
    }
    return retVotingArr;
  }

  function getRolesOfMember(mapping(address => RDAO.Member) storage members,
    mapping(uint256 => RDAO.Role) storage roles,
    uint[] storage roleIdList, address memberAddress) public view returns (uint[] memory) {
    require(members[memberAddress].proposalCounter > 0, "INVALID_ADDR");

    uint32 count = 0;
    for (uint32 i = 0; i < roleIdList.length; i++) {
      if (roles[roleIdList[i]].rank > 0 && members[memberAddress].roles[roleIdList[i]]) {
        count++;
      }
    }

    uint[] memory roleList = new uint[](count);
    uint32 j = 0;
    for (uint32 i = 0; i < roleIdList.length; i++) {
      if (roles[roleIdList[i]].rank > 0 && members[memberAddress].roles[roleIdList[i]]) {
        roleList[j] = roleIdList[i];
        j++;
      }
    }

    return roleList;
  }

  function isEligibleForProposal(mapping(uint256 => RDAO.Voting) storage votings,
    mapping(uint256 => RDAO.Role) storage roles,
    mapping(address => RDAO.Member) storage members,
    uint[] storage roleIdList, uint256 votingId, address member) public view returns (bool) {
    if (votings[votingId].minimumPermissions == 0) {
      return true;
    }

    for (uint32 i = 0; i < roleIdList.length; i++) {
      if (members[member].roles[roleIdList[i]] &&
      roles[roleIdList[i]].rank > votings[votingId].minimumRank &&
        (roles[roleIdList[i]].permissions & votings[votingId].minimumPermissions) == votings[votingId].minimumPermissions) {
        return true;
      }
    }
    return false;
  }

  function getEligibleVoters(mapping(uint256 => RDAO.Voting) storage votings,
    mapping(uint256 => RDAO.Role) storage roles, mapping(address => RDAO.Member) storage members,
    uint[] storage roleIdList, address[] storage memberList, uint256 votingId) public view returns (uint voters) {
    for (uint32 i = 0; i < memberList.length; i++) {
      if (memberList[i] != address(0) && isEligibleForProposal(votings, roles, members, roleIdList, votingId, memberList[i])) {
        voters++;
      }
    }
    return voters;
  }

  function getMemberCount(address[] storage memberList) public view returns (uint count) {
    for (uint32 i = 0; i < memberList.length; i++) {
      if (memberList[i] != address(0)) {
        count++;
      }
    }
    return count;
  }

  function checkPayout(mapping(address => RDAO.Member) storage members, address receiver, uint amount, uint timestamp) public view {
    require(members[receiver].proposalCounter > 0, "INVALID_RECEIVER");
    require(members[receiver].canPayOut == msg.sender, "SENDER_NOT_PAYER");
    require(timestamp > members[receiver].lastPayout, "TIMESTAMP_TOO_LOW");
    require(timestamp < block.timestamp, "TIMESTAMP_TOO_HIGH");
    require(amount <= (timestamp - members[receiver].lastPayout) * members[receiver].maxPayout, "PAYOUT_TOO_HIGH");
  }

  function checkVote(mapping(uint256 => RDAO.Voting) storage votings, uint256 votingId, RDAO.VoteType voteType) public view {
    require(voteType != RDAO.VoteType.NOT_VOTED, "INVALID_TYPE");
    require(votings[votingId].status == RDAO.VotingStatus.ACTIVE, "NOT_ACTIVE");
    require(votings[votingId].votes[msg.sender] == RDAO.VoteType.NOT_VOTED, "ALREADY_VOTED");
  }

  function initialize(mapping(RDAO.ActionType => address) storage parameterProviders, address[9] memory dependencies) public {
    parameterProviders[RDAO.ActionType.ADD_MEMBER] = dependencies[1];
    parameterProviders[RDAO.ActionType.REMOVE_MEMBER] = dependencies[2];
    parameterProviders[RDAO.ActionType.ADD_ROLE] = dependencies[3];
    parameterProviders[RDAO.ActionType.REMOVE_ROLE] = dependencies[4];
    parameterProviders[RDAO.ActionType.CREATE_ROLE] = dependencies[5];
    parameterProviders[RDAO.ActionType.TRANSACT] = dependencies[6];
    parameterProviders[RDAO.ActionType.CHANGE_PAYOUT] = dependencies[7];
    parameterProviders[RDAO.ActionType.CHANGE_ROLE] = dependencies[8];
  }
}