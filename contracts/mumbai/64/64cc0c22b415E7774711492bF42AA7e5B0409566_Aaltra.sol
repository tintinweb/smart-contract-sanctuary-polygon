/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Aaltra {
  address payable public artistAddress;
  string public artistName;
  uint public investmentTotal = 1 ether;
  uint public investmentLeft = investmentTotal;
  bool public investmentComplete = false;

  struct Investor {
    address payable investorAddress;
    string investorName;
    uint investmentAmount;
  }

  address payable[] public arrInvestors;
  mapping(address => Investor) public investors;

  event Investment(address investorAddress, string investorName, uint investmentAmount);
  event RoyaltiesPaid(uint amount);

  constructor(string memory _artistName) {
    artistName = _artistName;
    artistAddress = payable(msg.sender);
  }

  // function getInvestors() public {
  //   return;
  // }

  function invest(string memory _investorName) public payable {
    require(!investmentComplete, "Investment is less than what is left");
    require(msg.value >= 0.1 ether, "Min. investment is 0.1 ether");
    require(msg.value <= investmentLeft, "Investment is less than what is left");

    Investor memory investor = Investor({
      investorAddress: payable(msg.sender),
      investorName: _investorName,
      investmentAmount: msg.value
    });

    investmentLeft -= msg.value;
    investmentComplete = investmentLeft == 0;

    investors[msg.sender] = investor;
    arrInvestors.push(payable(msg.sender));

    emit Investment(msg.sender, _investorName, msg.value);
  }

  function payRoyalties() public payable {
    require(investmentComplete, "Investment needs to be complete");
    uint artistShare = msg.value * 50/100;
    uint investmentShare = msg.value * 50/100;

    artistAddress.transfer(artistShare);

    for(uint i = 0; i < arrInvestors.length; i++) {
      Investor memory investor = investors[arrInvestors[i]];
      uint investorShare = (investor.investmentAmount / investmentTotal) * investmentShare;

      payable(arrInvestors[i]).transfer(investorShare);
    }

    emit RoyaltiesPaid(msg.value);
  }
}