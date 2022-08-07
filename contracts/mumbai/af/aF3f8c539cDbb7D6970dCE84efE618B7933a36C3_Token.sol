pragma solidity >=0.4.22 <0.9.0;

contract Token {

  mapping (address => uint256) public balanceOf;

  constructor (uint256 initialSupply) public {
    balanceOf[msg.sender] = initialSupply;
  }

  function transfer(address _from, 
  address _to, 
  uint256 _value) public returns (bool success) {

    require(balanceOf[_from] >= _value); // Check if the sender balanceOf _from

    require(balanceOf[_to] + _value >= balanceOf[_to]); // Check balanceOf _to 

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;

    return true;

  }
  
}