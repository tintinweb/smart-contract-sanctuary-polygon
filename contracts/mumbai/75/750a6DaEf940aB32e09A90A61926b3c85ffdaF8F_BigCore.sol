/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

pragma solidity ^0.8.0;

contract Ownable {
  address private owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can perform this action.");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "The new owner address cannot be 0x0.");
    owner = newOwner;
  }
}

contract BigCore is Ownable {
  string public name = "Big Core";
  string public symbol = "Bcore";
  uint8 public decimals = 4;
  uint256 public totalSupply;
  uint256 public tradeFee = 1; // 1%
  uint256 public transferBurnFee = 1; // 0.01%

  mapping(address => uint256) public balances;

  constructor(uint256 _totalSupply) public {
    name = "Big Core";
    symbol = "Bcore";
    decimals = 4;
    totalSupply = _totalSupply;
  }

  function transfer(address _to, uint256 _value) public {
    require(_to != address(0), "The recipient address cannot be 0x0.");
    require(balances[msg.sender] >= _value, "Insufficient balance.");
    require(balances[_to] + _value >= balances[_to], "Overflow in adding the tokens.");

    uint256 tradeAmount = _value * tradeFee / 100;
    uint256 transferAmount = _value * transferBurnFee / 10000;
    balances[msg.sender] -= _value + tradeAmount + transferAmount;
    balances[_to] += _value;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function mint(address _to, uint256 _value) public onlyOwner {
    require(_to != address(0), "The recipient address cannot be 0x0.");
    require(balances[_to] + _value >= balances[_to], "Overflow in adding the tokens.");
    balances[_to] += _value;
    totalSupply += _value;
  }
}