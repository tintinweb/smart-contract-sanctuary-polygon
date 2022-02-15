/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public{
   owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
  _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool ok);
  function transferFrom(address from, address to, uint256 value) external returns (bool ok);
}

contract BlockChainMLM is Ownable{
	
  string public name = "BlockchanMLM";
  string public symbol = "BMLM";

  uint[] public rates = [10,9,8,7,6,5,4,3,2,1];

  struct Member{
    ERC20 token;
    address uplineAddress;
    address regAddress;
    uint256 balance;
    uint level;
    address[] uplineAddresses;
  }

  mapping (address => Member) public members;

  function setRate(uint[] memory _rates) public onlyOwner{
    rates = _rates;
  }

  function reg(ERC20 token, address uplineAddress, uint256 amount, uint level, address[] memory uplineAddresses) public {
   
    require(level > 0);
    uint totalUplines = uplineAddresses.length;
    uint maxRateLength = rates.length;

    require(maxRateLength == totalUplines);

    address[] memory newUplinesAddresses;
    for(uint i = 0; i < totalUplines; i++){
      require(uplineAddresses[i] != address(0), "Invalid address");
      newUplinesAddresses[i] = uplineAddresses[i];
    }
    
    uint totalPayoutRates = 0;
    for(uint i = 0; i < rates.length; i++){
      totalPayoutRates += rates[i];
    }

    token.transferFrom(msg.sender, address(this), amount);

    uint getLength = maxRateLength;
    if(totalUplines < maxRateLength){
      getLength = totalUplines;
    }

    for(uint i = 0; i < getLength; i++){
      token.transfer(uplineAddresses[maxRateLength-i], amount * rates[i] / 100);
    }

    if(totalUplines > 0){
      newUplinesAddresses[totalUplines] = msg.sender;
    }
    else{
      newUplinesAddresses[0] = msg.sender;
    }
    members[msg.sender] = Member(token, uplineAddress, msg.sender, amount, level+1, newUplinesAddresses);
  }

  function getMember(address to) public view returns (address, ERC20, address, uint256, uint, address[] memory) {
    return (members[to].uplineAddress, members[to].token, members[to].regAddress, members[to].balance, members[to].level, members[to].uplineAddresses);
  }

  function withdrawToken(ERC20 token, address _to, uint256 _amount) public onlyOwner returns(bool){
    token.transfer(_to, _amount);
    return true;
  }

  function withdrawTokenToAll(ERC20 token, address[] memory _to, uint256[] memory _value) public onlyOwner returns(bool){
    require(_to.length == _value.length);
    for (uint8 i = 0; i < _to.length; i++) {
      token.transfer(_to[i], _value[i]);
    }
    return true;
  }

  function() external payable {
  }

  function withdrawAllTo(address payable _to) public onlyOwner returns(bool success){
    _to.transfer(getBalance());
     return true;
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }
}