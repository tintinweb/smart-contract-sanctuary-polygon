// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/interfaces/IERC721.sol";

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
  }

  address birthCertificateContract;
  function setBirthCertificateAddress(address _address) public { // changed to public for testing purpose
    birthCertificateContract = _address;
  }

  mapping (string => Proposal) public proposals;

  // get tokenId from nft contract
  function getTokenId() public view returns(uint256) {
    return IBirthCertificate(birthCertificateContract).getTokenIdbyAddress(msg.sender);
  }

  // get voterEligibity
  function getEligibityandLocation(uint256 _tokenId) public view returns(uint256 voterEligibity, string memory location) { // changed to public for testing purpose
    (,,location,,voterEligibity) = IBirthCertificate(birthCertificateContract).getCertificatebyTokenId(_tokenId);
    return (voterEligibity, location);
  }

  //@dev create  a new voting proposal
  function createProposal(string memory _title, string memory _body,string memory _location, uint256 _deadline) public {
    //require msg.sender is approved address
    require(!proposals[_title].created, "This proposal already exists"); // make sure a proposal with this title DOES NOT exist
    proposals[_title] = Proposal(_title, _body, _location, _deadline, 0, 0, 0, true); // create a propsal with vote counts set to zero
  }
  // this will need to be altered to get the mapping of the voter to access status, location, age rather than what currently written
  function vote(string memory _title, string memory _vote) public{
    uint256 tokenId = getTokenId();
    require(tokenId > 0, "You must have a valid birth certificate");
    (uint256 voterEligibity, string memory location) = getEligibityandLocation(tokenId);
    require(voterEligibity > 0, "Must be elgible to vote"); // Need a function in nft to return either a boolean or 1/0 for voter status 
    require(keccak256(abi.encodePacked(location)) == keccak256(abi.encodePacked(proposals[_title].location))); //will need to be changed to work with the contract
    require(proposals[_title].created, "This proposal does not exist"); // make sure a proposal with this title DOES exist
    require(
      keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Yay")) ||
      keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Nay")) ||
      keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Absatin")),
      "Please vote with Yay, Nay, or Abstain"
    );
    //require voting is still open

    if(keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Yay"))){
      proposals[_title].Yay ++;
      }else if(keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Nay"))){
      proposals[_title].Nay ++;
      }else if (keccak256(abi.encodePacked(_vote)) == keccak256(abi.encodePacked("Abstain"))){
      proposals[_title].Abstain ++;
      }
  } 


}