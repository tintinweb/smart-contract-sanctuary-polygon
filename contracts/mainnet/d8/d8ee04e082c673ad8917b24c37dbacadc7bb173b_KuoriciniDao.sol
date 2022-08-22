/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KuoriciniDao {

  struct DaoGroup {
    string name;
    address[] members;
    uint[] tokenIds;
    uint[] candidateIds;
    uint voteThreshold;
    uint voteDuration;
    string invitationLink;
  }
  
    /* CandType
    0 : new address
    1 : new token
    2 : change existing token
    3 : new quorum
    4 : new vote duration
    */

  struct Candidate {
    uint id;
    uint candType;
    string name;
    uint roundSupply;
    uint roundDuration;
    address candidateAddress;
    uint votes;
    address[] voters;
    uint timestamp;
  }

  struct GToken {
    string name;
    uint roundSupply;
    uint roundDuration;
    uint timestamp;
  }

  struct UToken {
    uint tokenId;
    uint gTokenBalance;
    uint xBalance;
    uint last_sent;
  }

  mapping (address => string) names;
  mapping (address => UToken[]) userTokens;
  mapping (string => uint) invitationLinks;
  DaoGroup[] daoGroups;
  GToken[] allTokens;

  // TODO : these two at least, have to become mappings, BUT REFACTOR QUITE
  Candidate[] allCandidates;

  constructor() {
  }

  function createGroup(string calldata _name) public returns(bool) {
    address[] memory addr = new address[](1);
    addr[0] = msg.sender;
    uint[] memory defaultTokens;
    uint[] memory defaultCandidates;
    uint threshold = 5;
    uint voteduration = 1209600; // 14 days
    string memory invLink = generateInvitationLink(_name);
    DaoGroup memory new_group = DaoGroup({ 
      name: _name, 
      members: addr, 
      tokenIds: defaultTokens, 
      candidateIds: defaultCandidates, 
      voteThreshold: threshold,
      voteDuration: voteduration,
      invitationLink: invLink
    });
    daoGroups.push(new_group);
    // check invitation link doesn't exist already
    if ( daoGroups.length-1 != 0 ) {
      require ( invitationLinks[invLink] == 0 );
    }
    invitationLinks[invLink]=daoGroups.length-1;
    return true;
  }

  function getGroup(uint _gid) public view returns(DaoGroup memory) {
    return daoGroups[_gid];
  }
  
  function checkInvitationLink(string calldata link) public view returns (uint) {    
    uint groupInv =  invitationLinks[link];
    if (isAddressInGroup(groupInv, msg.sender)) {
      return 0;      
    }
    uint l = daoGroups[groupInv].candidateIds.length;
    uint[] memory candidateIds = new uint[](l+1);
    for (uint i = 0; i < l; i++) {
      candidateIds[i] = daoGroups[groupInv].candidateIds[i];
      if ( allCandidates[candidateIds[i]].candidateAddress == msg.sender ){
        return 0;
      }
    }    
    return groupInv;
  }

  function generateInvitationLink(string memory name) private view returns (string memory) {
      uint invLength = 15;
      string memory newString = new string(invLength);
      bytes memory finalString = bytes(newString);
      bytes memory originString = "abcdefghijklmnopqrstuvxyz1234567890";
      for (uint i=0; i< invLength-1; i++) {
          uint r = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, string(finalString), name))) % originString.length;
          finalString[i] = originString[r];
      }
      return string(finalString);
  }    

  
/*
*   Tokens
*
*/

  function getToken(uint _tokenid) public view returns(GToken memory) {
    return allTokens[_tokenid];
  }

  function createGToken(uint tokid, string memory _name, uint _supply, uint _duration, bool present, uint _groupId) private returns(bool){
    require(isAddressInGroup(_groupId, msg.sender), "member cannot vote!" );

    if (present) {
      require(isTokenInGroup(tokid, _groupId), "token not allowed");
      allTokens[tokid].name = _name;
      allTokens[tokid].roundSupply = _supply;
      allTokens[tokid].roundDuration = _duration;
    } 
    else {
      allTokens.push(GToken({
        name: _name,
        roundSupply: _supply,
        roundDuration: _duration,
        timestamp: block.timestamp
      }));
      uint l = allTokens.length;
      daoGroups[_groupId].tokenIds.push(l-1);
    }
    return true;
  }


// temporary struct to make the output of a token more verbose

  struct EToken {
    uint tokenId;
    uint gTokenBalance;
    uint xBalance;
    uint blocktimestamp;
    uint newtime;
    uint residualtime;
  }

  function getUserTokens(uint gid) public view returns(EToken[] memory) {
    require(isAddressInGroup(gid, msg.sender), "user not authorized"); 
    uint l = daoGroups[gid].tokenIds.length;
    uint m = userTokens[msg.sender].length;
    UToken[] memory utokens = new UToken[](l);
    EToken[] memory etokens = new EToken[](l);

    for ( uint w = 0; w < l; w++ ) { // all the tokens of this group 
      uint tokid = daoGroups[gid].tokenIds[w];
      utokens[w] = UToken ({ tokenId: tokid, gTokenBalance: 0, xBalance: allTokens[tokid].roundSupply, last_sent: 0});
      uint newtime = allTokens[tokid].timestamp + allTokens[tokid].roundDuration;

      for ( uint j = 0; j < m; j++ ) { // all the tokens of this user
        if (userTokens[msg.sender][j].tokenId == tokid) {
          utokens[w].gTokenBalance = userTokens[msg.sender][j].gTokenBalance;
          utokens[w].last_sent = userTokens[msg.sender][j].last_sent;
          if ( ( block.timestamp < newtime )  && ( utokens[w].last_sent > allTokens[tokid].timestamp ) ) {
            utokens[w].xBalance = userTokens[msg.sender][j].xBalance;
          }
        }
      }
      etokens[w].tokenId = utokens[w].tokenId;
      etokens[w].gTokenBalance = utokens[w].gTokenBalance;
      etokens[w].xBalance = utokens[w].xBalance;
      etokens[w].blocktimestamp = block.timestamp;

      // expiration time calculation
      while (newtime < block.timestamp) {
        newtime += allTokens[tokid].roundDuration;
      }
      etokens[w].newtime = newtime;

      // residual time calculation
      while ( ( newtime - block.timestamp ) > allTokens[tokid].roundDuration ) {
        newtime -= allTokens[tokid].roundDuration;
      }
      etokens[w].residualtime = newtime - block.timestamp;
    }
    return etokens;
  }

  function transferToken(uint _tokenId, address receiver, uint value) public returns(bool) {
    UToken memory _tokSender;
    bool matchFoundSender = false;
    uint s;
    uint r;
    for (s = 0; s < userTokens[msg.sender].length ; s++) {
      if (userTokens[msg.sender][s].tokenId == _tokenId) {
        _tokSender = userTokens[msg.sender][s];
        matchFoundSender = true;
        break;
      }
    }
    if (matchFoundSender == false){
      _tokSender = UToken({ tokenId: _tokenId, gTokenBalance: 0, xBalance: allTokens[_tokenId].roundSupply, last_sent: 0});
    }

    uint newtimestamp = allTokens[_tokenId].timestamp + allTokens[_tokenId].roundDuration;
    if (block.timestamp > newtimestamp ) {
      _tokSender.xBalance = allTokens[_tokenId].roundSupply;

      while ( block.timestamp > (newtimestamp + allTokens[_tokenId].roundDuration)) {
        newtimestamp += allTokens[_tokenId].roundDuration;
      }
      
      allTokens[_tokenId].timestamp=newtimestamp;
    }
    
    require(_tokSender.xBalance >= value, "non hai abbastanza token");
    UToken memory _tokReceiver;
    bool matchFoundReceiver = false;
    for ( r = 0; r < userTokens[receiver].length ; r++) {
      if (userTokens[receiver][r].tokenId == _tokenId) {
        _tokReceiver = userTokens[receiver][r];
        matchFoundReceiver = true;
        break;
      }
    }
    if ( matchFoundReceiver == false){
      _tokReceiver= UToken({ tokenId: _tokenId, gTokenBalance: 0, xBalance: allTokens[_tokenId].roundSupply, last_sent: 0});
    }
    _tokSender.xBalance -= value;
    _tokSender.last_sent = block.timestamp;
    _tokReceiver.gTokenBalance += value;
    if (matchFoundSender == true) {
      userTokens[msg.sender][s] = _tokSender;
    }
    else {
      userTokens[msg.sender].push( UToken({ tokenId: _tokenId, gTokenBalance: 0, xBalance: _tokSender.xBalance, last_sent: _tokSender.last_sent}));
    }
    if (matchFoundReceiver == true) {
      userTokens[receiver][r] = _tokReceiver;
    }
    else {
      userTokens[receiver].push( UToken({ tokenId: _tokenId, gTokenBalance: _tokReceiver.gTokenBalance, xBalance: allTokens[_tokenId].roundSupply, last_sent: 0}));
    }
    return true;
  }

  function isTokenInGroup(uint tokid, uint gid) private view returns(bool) {
    for ( uint i = 0; i < daoGroups[gid].tokenIds.length; i++){
      if ( daoGroups[gid].tokenIds[i] == tokid ){
        return true;
      }
    }
    return false;
  }

  
 // obsolete, to be removed. replaced by getToken. Remove it from one call from js  
  function getGroupNamefromId(uint _id) public view returns(string memory) {
    return daoGroups[_id].name;
  }

 // obsolete, to be removed. replaced by getToken. Remove it from one call from js  
  function getGroupAddressfromId(uint _id) public view returns(address[] memory) {
    return daoGroups[_id].members;
  }


/*  
*   Tokens Candidates
*
*/


  // propose token change
  function changeToken(uint val, string memory name, uint supply, uint duration, uint gid, uint candtype) public returns(bool) {

    if ( candtype == 0 ) {
      require(!isAddressInGroup(gid, msg.sender), "member already present!");
      require( invitationLinks[name] == gid, "link not authorized" ); 
      require( gid != 0, "group not authorized" );
    } else {
      require(isAddressInGroup(gid, msg.sender), "member not allowed!");
    }

    // if token is marked as present make sure it really exists and belongs to the right group
    if ( candtype == 2 ) {
      require(isTokenInGroup(val, gid), "token not allowed");
    }
    if (candtype == 3) {
      require(val <= 10, "invalid quorum");
    }

    uint l = daoGroups[gid].candidateIds.length;
    uint[] memory candidateIds = new uint[](l+1);
    
    for (uint i = 0; i < l; i++) {
      candidateIds[i] = daoGroups[gid].candidateIds[i];
      if ( ( candtype == 0 ) &&  ( allCandidates[candidateIds[i]].candidateAddress == msg.sender ) ) {
        require ( !candidateValid(allCandidates[candidateIds[i]].timestamp, gid), "candidate already added" ); 
      }
    }

    // generate a new candidate
    address[] memory vot = new address[](0);
    allCandidates.push(Candidate({
      id: val,
      candType: candtype,
      name: name,
      roundSupply: supply,
      roundDuration: duration,
      candidateAddress: msg.sender,
      votes: 0,
      voters: vot,
      timestamp: block.timestamp
    }));

    // update candidate list in the group
    candidateIds[l] = allCandidates.length-1;
    daoGroups[gid].candidateIds = candidateIds;

    return true;

  }
/*
 * New PROPOSALS API
 * Commented for now (run out of gas cannot compile)
 *

function proposeQuorum(uint val, uint gid) public returns(bool) {
  require(val <= 10, "invalid quorum");
  changeToken(val, "", 0, 0, gid, 3);
  return true; 
}

struct quorumProposal {
  uint proposalId;
  address proposer;
  uint votes;
  bool voted;
  uint timestamp;
  uint quorum;
}

function getQuorumProposals(uint gid) public view returns (quorumProposal[] memory) {
  require(isAddressInGroup(gid, msg.sender), "member not allowed!" );
  uint l = daoGroups[gid].candidateIds.length;
  quorumProposal[] memory proposals = new quorumProposal[](l);
  quorumProposal memory proposal;
  Candidate memory candidate;
  uint counter = 0;
  for (uint i = 0; i < l; i++) {
    uint c = daoGroups[gid].candidateIds[i];
    candidate = allCandidates[c];
    if (candidate.candType == 3) {
      proposal.proposalId = allCandidates[c].id;
      proposal.proposer = allCandidates[c].candidateAddress;
      proposal.votes = allCandidates[c].votes;
      proposal.voted = false;
      for (uint q=0; q < allCandidates[c].voters.length ; q++ ) {
        if ( allCandidates[c].voters[q] == msg.sender) {
          proposal.voted = true;
        }
      }
      proposal.timestamp = allCandidates[c].timestamp;
      proposal.quorum = allCandidates[c].id;
      proposals[counter] = proposal;
      counter++;
    }
  }
  return proposals;
}
*/

// hide voters expose voted
struct ECandidate {
  uint id;
  uint candType;
  string name;
  uint roundSupply;
  uint roundDuration;
  address candidateAddress;
  uint votes;
  bool voted;
  uint timestamp;
}

  // get candidate tokens of a group
  function getGroupCandidates(uint gid) public view returns(ECandidate[] memory) {
    require(isAddressInGroup(gid, msg.sender), "member not allowed!" );
    uint l = daoGroups[gid].candidateIds.length;
    ECandidate[] memory candidates = new ECandidate[](l);
    for (uint i = 0; i < l; i++) {
      uint c = daoGroups[gid].candidateIds[i];
      candidates[i].id = allCandidates[c].id;
      candidates[i].candType = allCandidates[c].candType;
      candidates[i].name = allCandidates[c].name;
      candidates[i].roundSupply = allCandidates[c].roundSupply;
      candidates[i].roundDuration = allCandidates[c].roundDuration;
      candidates[i].candidateAddress = allCandidates[c].candidateAddress;
      candidates[i].votes = allCandidates[c].votes;
      candidates[i].voted = false;
      for (uint q=0; q < allCandidates[c].voters.length ; q++ ) {
        if ( allCandidates[c].voters[q] == msg.sender) {
          candidates[i].voted = true;
        }
      }
      if ( candidateValid(allCandidates[c].timestamp, gid) ) {
        candidates[i].timestamp = allCandidates[c].timestamp;
      } else {
        candidates[i].timestamp = 0;
      }
    }
    return candidates;
  }

  function candidateValid(uint candidateTimestamp, uint gid) private view returns(bool) {
    return ( ( candidateTimestamp + daoGroups[gid].voteDuration) > block.timestamp );
  }

  // vote candidate token and eventually promote the change if quorum is passed
  function voteCandidate(uint gid, uint candTokId, uint vote) public returns(bool) {
    require(isAddressInGroup(gid, msg.sender), "member cannot vote!" );

    // find candidate
    Candidate memory candidate;
    // check it exists in the group
    uint l = daoGroups[gid].candidateIds.length;
    bool candidateFound = false; 
    for (uint i = 0; i < l; i++) {
      if (daoGroups[gid].candidateIds[i] == candTokId) {
        candidate = allCandidates[candTokId];
        candidateFound = true;
        break;
      }
    }
    require(candidateFound, "candidate token doesn't exists");
    require(candidateValid(candidate.timestamp, gid), "candidate invalid");

    // add voter (this would be the same if we merge)
    uint m = candidate.voters.length;
    address[] memory v = new address[](m+1);
    for (uint i = 0; i < m; i++) {
      require(candidate.voters[i] != msg.sender, "address already voted!");
      v[i]=candidate.voters[i];
    }
    v[m]=msg.sender;
    candidate.voters=v;

    // assign vote   
    if (vote > 0) {
      candidate.votes += 1;
    }
    
    // write on chain
    allCandidates[candTokId] = candidate;

    // check if candidate win
    uint quorum = getQuorum(gid);
    if ( candidate.votes > quorum ) {
      if ( candidate.candType == 0 ) {
        addAddresstoGroup(gid, candidate.candidateAddress);
      }       
      if ( ( candidate.candType == 1 ) || ( candidate.candType == 2 ) ) {
        createGToken(candidate.id, candidate.name, candidate.roundSupply, candidate.roundDuration, (candidate.candType == 2), gid);
      }
      if ( candidate.candType == 3 ) {
        daoGroups[gid].voteThreshold = candidate.id;  
      } 
      if ( candidate.candType == 4 ) {
        daoGroups[gid].voteDuration = candidate.id;  
      } 

      // remove element from candidates array
      uint[] memory newCandidateIds = new uint[](l-1);
      uint index;
      uint k;
      for (k = 0; k < l; k++) {
        if ( daoGroups[gid].candidateIds[k] == candTokId ) {
          index = k;
          break;
        }
      }
      for (k = 0; k < l; k++) {
        if ( k < index) {
          newCandidateIds[k] = daoGroups[gid].candidateIds[k];
        }
        if ( k > index) {
          newCandidateIds[k-1] = daoGroups[gid].candidateIds[k];
        }
      }
      
      daoGroups[gid].candidateIds = newCandidateIds;

    }

    return true;
  }

  function getQuorum(uint gid) private view returns(uint) {
    require(isAddressInGroup(gid, msg.sender));
    return daoGroups[gid].members.length * daoGroups[gid].voteThreshold / 10 ;
  }

/*
*
*   Group Members
*/

  function addAddresstoGroup(uint gid, address addr) private returns(bool) {
    require(!isAddressInGroup(gid, addr), "member already present!" );
    uint l = daoGroups[gid].members.length;
    address[] memory members = new address[](l+1);
    for (uint i = 0; i < l; i++) {
      members[i] = daoGroups[gid].members[i];
    }
    members[l] = addr;
    daoGroups[gid].members = members;
    return true;
  }

  function removeMeFromGroup(uint gid) public returns(bool) {
    require(isAddressInGroup(gid, msg.sender), "member not in group!" );

    uint l = daoGroups[gid].members.length;
    address[] memory members = new address[](l-1);
    uint index;
    uint k;
    for (k = 0; k < l; k++) {
      if ( daoGroups[gid].members[k] != msg.sender ) {
        index = k;
        break;
      }
    }
    for (k = 0; k < l; k++) {
      if ( k < index) {
        members[k] = daoGroups[gid].members[k];
      }
      if ( k > index) {
        members[k-1] = daoGroups[gid].members[k];
      }
    }
    daoGroups[gid].members = members;
    return true;
  }



  function isAddressInGroup(uint gid, address addr) private view returns(bool) {
    bool exists = false;
    for (uint i = 0; i < daoGroups[gid].members.length; i++) {
      if( daoGroups[gid].members[i] == addr ) {
        exists=true;
        break;
      }
    }
    return exists;
  }

  function myGroups() public view returns(uint[] memory) {
    uint lg = daoGroups.length;
    uint[] memory mygroups;
    for (uint i = 0; i < lg; i++) {
      uint lm = daoGroups[i].members.length;
      for (uint q = 0; q < lm; q++) {
        if(daoGroups[i].members[q] == msg.sender) {
          uint gl = mygroups.length;
          uint[] memory groups = new uint[](gl+1);
          for (uint w = 0; w < gl; w++) {
            groups[w] = mygroups[w];
          }
          groups[gl] = i;
          mygroups = groups;
        }
      }
    }
    return mygroups;
  }

  function groupNameByInvitation(uint gid, string calldata invitation) public view returns(string memory){
    require( invitationLinks[invitation] == gid, "user not authorized" ); 
    return daoGroups[gid].name;
  }
  
  // names are public
  function nameOf(address owner) public view returns(string memory) {
    return names[owner];
  }

  function nameSet(string calldata name) public returns(bool) {
    names[msg.sender]=name;
    return true;
  }

}