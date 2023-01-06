/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract EtuDeneme {
  // NFT sahiplenme işlemleri
  address public owner;
  mapping(uint => address) public tokenOwner;
  mapping(uint => bool) public tokensMinted;

  constructor() public {
    owner = msg.sender;
  }

  function mint(uint _tokenId) public {
    require(msg.sender == owner);
    require(!tokensMinted[_tokenId]);
    tokenOwner[_tokenId] = msg.sender;
    tokensMinted[_tokenId] = true;
  }

  function transfer(uint _tokenId, address _to) public {
    require(tokenOwner[_tokenId] == msg.sender);
    require(whitelist[_to]);
    tokenOwner[_tokenId] = _to;
  }

  // Whitelist adreslerinin yönetimi
  mapping(address => bool) public whitelist;

  function addToWhitelist(address[] memory _newWhitelist) public {
    require(msg.sender == owner);
    for (uint i = 0; i < _newWhitelist.length; i++) {
      whitelist[_newWhitelist[i]] = true;
    }
  }

  function removeFromWhitelist(address[] memory _removedWhitelist) public {
    require(msg.sender == owner);
    for (uint i = 0; i < _removedWhitelist.length; i++) {
      whitelist[_removedWhitelist[i]] = false;
    }
  }

  // Öğrencilerin bilgileri
  struct StudentInfo {
    string name;
    uint gpa;
  }

  mapping(uint => StudentInfo) public studentInfo;

  function updateStudentInfo(uint _tokenId, string memory _name, uint _gpa) public {
    require(msg.sender == owner);
    studentInfo[_tokenId].name = _name;
    studentInfo[_tokenId].gpa = _gpa;
  }

  function updateStudentInfo(uint[] memory _tokenIds, string[] memory _names, uint[] memory _gpas) public {
    require(msg.sender == owner);
    require(_tokenIds.length == _names.length && _tokenIds.length == _gpas.length);
    for (uint i = 0; i < _tokenIds.length; i++) {
      studentInfo[_tokenIds[i]].name = _names[i];
      studentInfo[_tokenIds[i]].gpa = _gpas[i];
    }
  }
}