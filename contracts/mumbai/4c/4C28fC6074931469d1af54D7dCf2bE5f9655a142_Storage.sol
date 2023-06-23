//SPDX-License-Identifier:MIT
pragma solidity 0.8.15;

contract Storage {
  /* State variables */
  mapping(address => string[]) private files;
  mapping(address => mapping(address => bool)) private accessAllowance;

  /* Store Function  */
  function addFile(string memory _url) external {
    require(bytes(_url).length > 0, "invalid url");
    files[msg.sender].push(_url);
  }

  function getFiles(address _user) external view returns (string[] memory) {
    require(msg.sender == _user || accessAllowance[msg.sender][_user]);
    return files[msg.sender];
  }

  function grantAccess(address _user) external onlyOwner {
    require(_user != address(0), "Invalid viewer address");
    accessAllowance[msg.sender][_user] = true;
  }

  modifier onlyOwner() {
    require(
      files[msg.sender].length > 0,
      "Only file owner can perform this action"
    );
    _;
  }

  function revokeAccess(address viewer) external onlyOwner {
    require(viewer != address(0), "Invalid viewer address");
    accessAllowance[msg.sender][viewer] = false;
  }
}