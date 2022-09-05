// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Yield{
  address payable public holderOne;
  address payable public holderTwo;

  constructor(address _holderOne, address _holderTwo){
    holderOne = payable(_holderOne);
    holderTwo = payable(_holderTwo);
  }

  receive() external payable {}

  modifier onlyHolder {
    require(msg.sender == holderOne || msg.sender == holderTwo, "Yield: not an owner");
    _;
  }

  function withdraw() external onlyHolder {
      uint eachBalance = address(this).balance / 2;
      payable(holderOne).transfer(eachBalance);
      payable(holderTwo).transfer(eachBalance);
  }

  function getBalance() external view returns (uint) {
      return address(this).balance;
  }

  function changeHolder(address newAddress) external onlyHolder{
    if(msg.sender == holderOne){
      holderOne = payable(newAddress);
    }
    if(msg.sender == holderTwo){
      holderTwo = payable(newAddress);
    }
  }
}