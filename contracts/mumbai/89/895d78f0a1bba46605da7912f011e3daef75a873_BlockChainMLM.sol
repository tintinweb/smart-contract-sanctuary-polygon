pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
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
  function getUplines() external returns (address[] memory);
}

contract BlockChainMLM is Ownable{

  using SafeMath for uint256;

  string public username = "-";
  uint[] public rates = [10,9,8,7,6,5,4,3,2,1];
  address[] public uplines;
  uint256 public balance;
  uint public level = 0;

  function setUsername(string memory _username) public onlyOwner{
    username = _username;
  }

  function setRate(uint[] memory _rates) public onlyOwner{
    rates = _rates;
  }

  function getUplines() public view onlyOwner returns(address[] memory) {
    return uplines;
  }

  function reg(ERC20 token, uint256 amount) public {
    address[] memory lastUplines = token.getUplines();
    address[] memory newUplines;
        
    balance = balance.add(amount);
    level = newUplines.length + 1;

    newUplines[0] = msg.sender;
    token.transferFrom(msg.sender, address(this), amount);

    for (uint i = 1; i <= lastUplines.length; i++) {
      
      newUplines[i] = lastUplines[i];
      
      require(rates.length >= i, "Stopped level here");
      
      token.transfer(lastUplines[i], amount * rates[i-1] / 100);
    }
    uplines = newUplines;
  }
}