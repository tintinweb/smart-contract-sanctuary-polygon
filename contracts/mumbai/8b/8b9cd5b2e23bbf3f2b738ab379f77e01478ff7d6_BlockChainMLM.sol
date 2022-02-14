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
  function getUplines() external view returns (address[] memory);
}

contract BlockChainMLM is Ownable{

  using SafeMath for uint256;

  uint[] public rates = [10,9,8,7,6,5,4,3,2,1];
  address[] public uplines;
  uint256 public balance;
  uint public level = 0;

  function getUplines() public view returns(address[] memory) {
    return uplines;
  }

  function reg(ERC20 token, uint256 amount) public {
    address[] memory lastUplines = token.getUplines();
    address[] memory newUplines;
        
    balance = balance.add(amount);
    level = lastUplines.length + 1;

    newUplines[0] = msg.sender;
    newUplines[1] = address(token);
    token.transferFrom(msg.sender, address(this), amount);

    token.transfer(address(token), amount * rates[0] / 100);

    require(lastUplines.length > 0, "Stopped level here");
    for (uint i = 2; i <= lastUplines.length; i++) {
      
      newUplines[i] = lastUplines[i];
      
      require(rates.length >= i, "Stopped level here");
      
      token.transfer(lastUplines[i], amount * rates[i-1] / 100);
    }
    uplines = newUplines;
  }
}