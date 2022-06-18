/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract MaticReceiver {
  address payable owner;
  uint256 balance;
  mapping(address =>  uint) public users;
  address[] public accounts;

  constructor() payable {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(
      msg.sender == owner,
      "Only owner can call this function."
    );
    _;
  }

  receive() payable external {

  }

  function addUsers(address[] memory _addresses) public onlyOwner {
        uint i = 0;
        while (i < _addresses.length) {         
            users[_addresses[i]] = 1;
            accounts.push(_addresses[i]);
            i++;
        } 
  }

  function getUsers() public view returns (address[] memory ) {
    return accounts;
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function Withdraw(uint256 weiAmount) payable public{
      require(address(this).balance >= weiAmount, "insufficient BNB balance");
      require(users[msg.sender] > 0, "invalid user");
      payable(msg.sender).transfer(weiAmount);
  }

  function greeting() public pure returns (string memory) {
    return "Hello, I am an Balance receiver!";
  }

  function withdrawWholeFunds() public onlyOwner {
      payable(owner).transfer(address(this).balance);
  }

  function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = payable(newOwner);
    }

}