/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Crowdfunding {
  event Create(string title, address creator, uint contributed, uint startTime, uint endTime, bool claimed, uint campaignIndex);
  event Contribute(address contributor, uint amount, uint campaignIndex);
  event Claim(uint amount, uint campaignIndex);

  struct Campaign {
    string title;
    address creator;
    uint contributed;
    uint startTime;
    uint endTime;
    bool claimed;
  }

  address public tokenAddress;
  Campaign[] public campaigns;


  constructor(address _tokenAddress) {
    tokenAddress = _tokenAddress;
  }

  function create(string memory title, uint daysDuration) public {
    require(daysDuration >= 30, 'duration too short');
    require(daysDuration <= 365, 'duration too long');
    campaigns.push(Campaign(title, msg.sender, 0, block.timestamp, (block.timestamp + daysDuration*86400), false));
    emit Create(title, msg.sender, 0, block.timestamp, (block.timestamp + daysDuration*86400), false, campaigns.length-1);
  }

  function contribute(uint amount, uint campaignIndex) public {
    require(block.timestamp < campaigns[campaignIndex].endTime);
    require(campaignIndex >= 0, 'campaign index cannot be less than zero');
    require(campaignIndex < campaigns.length, 'campaign index must be less than array length');
    if (!token(tokenAddress).transferFrom(msg.sender, address(this), amount)) revert();
    campaigns[campaignIndex].contributed += amount;
    emit Contribute(msg.sender, amount, campaignIndex);
  }

  function claim(uint campaignIndex) public {
    require(block.timestamp >= campaigns[campaignIndex].endTime, 'campaign cannot be claimed before end date');
    require(campaignIndex >= 0, 'campaign index cannot be less than zero');
    require(campaignIndex < campaigns.length, 'campaign index must be less than array length');
    require(campaigns[campaignIndex].claimed == false, 'campaign has already been claimed');
    require(msg.sender == campaigns[campaignIndex].creator, 'only owner can claim campaign funds');
    require(campaigns[campaignIndex].contributed > 0, 'campaign must have contributions');
    if (!token(tokenAddress).transfer(msg.sender, campaigns[campaignIndex].contributed)) revert();
    campaigns[campaignIndex].claimed = true;
    emit Claim(campaigns[campaignIndex].contributed, campaignIndex);
  }
}

abstract contract token {
  function transfer(address _to, uint256 _amount) public virtual returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) public virtual returns (bool success);
}