// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

interface IBirthCertificate {
  function getCertificatebyTokenId(uint _tokenId) external view returns (
    string memory name,
    string memory locationofBirth,
    string memory location,
    uint256 dateofBirth,
    uint256 voterEligibity
  );

  function getTokenIdbyAddress(address _address) external view returns (uint256 tokenId);

}

contract Voting {
  struct Proposal{
    string title;
    string body;
    string location;
    uint256 deadline;
    uint256 Yay;
    uint256 Nay;
    uint256 Abstain;
    bool created;
    // voters - a mapping of tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
    mapping(uint256 => bool) voters;
  }

  // variable to store birthCertificateContract address
  address birthCertificateContract;

  // function to set the address of the birthCertificateContract
  function setBirthCertificateAddress(address _address) public { 
    birthCertificateContract = _address;
  }

  // id to proposal mapping
  mapping(uint256 => Proposal) public proposals;
  
  // number of proposal that have been created. counting from 1.
  uint256 public numProposals = 1;

  // get tokenId from nft contract
  function getTokenId() public view returns(uint256) {
    return IBirthCertificate(birthCertificateContract).getTokenIdbyAddress(msg.sender);
  }

  // get voterEligibity
  function getEligibityandLocation(uint256 _tokenId) public view returns(uint256 voterEligibity, string memory location) { 
    (,,location,,voterEligibity) = IBirthCertificate(birthCertificateContract).getCertificatebyTokenId(_tokenId);
    return (voterEligibity, location);
  }

  //@dev create  a new voting proposal that takes title, body and location in string but the deadline should be formatted in unix time format
  function createProposal(string memory _title, string memory _body,string memory _location, uint256 _deadline) public {
    uint256 tokenId = getTokenId();
    require(tokenId > 0, "You must have a valid birth certificate");
    // require(!proposals[_title].created, "This proposal already exists"); // make sure a proposal with this title DOES NOT exist <<< commented out, need more time to have solution

    // create a propsal with vote counts set to zero. This is a work around because struct with mapping throw an error if assigned the normal way
    Proposal storage newProposal = proposals[numProposals];
    newProposal.title = _title;
    newProposal.body = _body;
    newProposal.location = _location;
    newProposal.deadline = _deadline;
    newProposal.Yay = 0;
    newProposal.Nay = 0;
    newProposal.Abstain = 0;
    newProposal.created = true;
    numProposals++;
    // console.log(_deadline);
  }

  // function for voting the contract proposed, should need numProposal and the vote in string "Yay", "Nay", or "Abstain"
  function vote(uint _numProposals, string memory _vote) public{
    uint256 tokenId = getTokenId();
    require(tokenId > 0, "You must have a valid birth certificate");
    (uint256 voterEligibity, string memory location) = getEligibityandLocation(tokenId);
    require(voterEligibity > 0, "Must be elgible to vote");
    require(proposals[_numProposals].voters[tokenId] == false, "You already voted");
    require(keccak256(abi.encodePacked(location)) == keccak256(abi.encodePacked(proposals[_numProposals].location)), "Must have same location with the proposal location"); 
    require(proposals[_numProposals].created, "This proposal does not exist"); // make sure a proposal with this title DOES exist

    // check wheter the proposal already expired, if so cant vote
    require(block.timestamp < proposals[_numProposals].deadline, "This proposal already expired");

    if(keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Yay"))){
      proposals[_numProposals].Yay ++;
      } else if(keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Nay"))){
      proposals[_numProposals].Nay ++;
      } else if (keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Abstain"))){
      proposals[_numProposals].Abstain ++;
      } else revert();
    proposals[_numProposals].voters[tokenId] = true; // mark tokenId already vote on _title proposal so it cannot vote again
  } 


}