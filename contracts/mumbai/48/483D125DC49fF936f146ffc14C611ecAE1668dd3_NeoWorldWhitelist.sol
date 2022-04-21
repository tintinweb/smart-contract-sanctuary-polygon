// SPDX-License-Identifier: GPL-3.0

/// @title NeoWorld Whitelist

pragma solidity >=0.7.0 <0.9.0;

contract NeoWorldWhitelist {

    address public owner;
    address public deployer;

    mapping(address => bool) whitelistedAddresses;

    constructor() {
      owner = msg.sender;
      deployer = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner || msg.sender == deployer, "Ownable: caller is not the owner");
      
      _;
    }

    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address], "Whitelist: You need to be whitelisted");
      _;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
      whitelistedAddresses[_addressToWhitelist] = true;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    // function exampleFunction() public view isWhitelisted(msg.sender) returns(bool){
    //   return (true);
    // }
    

}