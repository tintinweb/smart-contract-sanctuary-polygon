// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract HouseMagVoting {
address owner;
 struct User_Vote{
    string name;
  }
  mapping (bytes32 => uint256) public votesReceived;
 
  bytes32[] public candidateList;
  bytes32[] public UserList;
  mapping (bytes32 => User_Vote) public UserData;

  constructor(bytes32[] memory candidateNames) payable {
    candidateList = candidateNames;
    owner = msg.sender;
  }
  
  function totalVotesFor(bytes32 candidate) view public returns (uint256) {
    require(validCandidate(candidate), "Candidato nao encontrado");
    return votesReceived[candidate];
    
  }
  
  function voteForCandidate(bytes32[] memory candidates, bytes32[] memory  whatsapp, string[] memory name) public {
    for(uint i = 0; i < candidates.length; i++) {
          if(validUser(whatsapp[i], name[i])) {
            bytes32 candidate = candidates[i];

            if(!validCandidate(candidate)) {
                addCandidate(candidate);
            }
            
            votesReceived[candidate] += 1;            
         }
    }
  }
  
  function addCandidate(bytes32 candidate) public returns (bool) {
   require(!validCandidate(candidate), "Candidato ja incluido");   
   candidateList.push(candidate);
   return true;
  }

  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }

   function validUser(bytes32 whatsHash,string memory name)  public returns (bool) {
    for(uint i = 0; i < UserList.length; i++) {
      if (UserList[i] == whatsHash) {
        return false;
      }
    } 
     
    UserList.push(whatsHash);
    UserData[whatsHash] = User_Vote (name);

    return true;
  }
}