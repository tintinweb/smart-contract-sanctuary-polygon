/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ClaimReward {

    address owner;

    mapping(address => uint256) whitelistedAddresses;

    constructor() {
      owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "Ownable: caller is not the owner");
      _;
    }

    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address] > 0, "Whitelist: You need to be whitelisted");
      _;
    }

    function addUsers(address[] calldata _addressToWhitelist, uint256[] calldata _value) external onlyOwner {
      for (uint256 i = 0; i < _addressToWhitelist.length; i++) {
          if (whitelistedAddresses[_addressToWhitelist[i]] > 0){
            whitelistedAddresses[_addressToWhitelist[i]] = whitelistedAddresses[_addressToWhitelist[i]] + _value[i];
          }
          else{
            whitelistedAddresses[_addressToWhitelist[i]] = _value[i];
          }
      }
      for (uint256 i = 0; i < _addressToWhitelist.length; i++) {
          if (whitelistedAddresses[_addressToWhitelist[i]] == 0){
            delete whitelistedAddresses[_addressToWhitelist[i]];
          }
      } 
    }


    function getClaimValue(address _whitelistedAddress) public view returns(uint256) {
      uint256 claimValue = whitelistedAddresses[_whitelistedAddress];
      return claimValue;
    }

    function claim() public payable isWhitelisted(msg.sender){
        uint256 amount = whitelistedAddresses[msg.sender];
        payable(msg.sender).transfer(amount);
    }
}