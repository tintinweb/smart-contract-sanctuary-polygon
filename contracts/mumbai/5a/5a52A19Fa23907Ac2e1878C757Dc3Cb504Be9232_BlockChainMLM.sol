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
}

contract BlockChainMLM is Ownable{

  using SafeMath for uint256;

  uint[] public rates = [10,9,8,7,6,5,4,3,2,1];

  struct Member{
    ERC20 token;
    address uplineAddress;
    address regAddress;
    uint256 balance;
    uint level;
  }

  Member[] public members;

  function reg(ERC20 token, address uplineAddress, uint256 amount) public {
   
    // token.transferFrom(msg.sender, address(this), amount);
    
    members.push(Member(token, uplineAddress, msg.sender, amount, members.length));
  }

  function get(uint index) public view returns (ERC20, address, address, uint256, uint) {
     Member storage mem = members[index];

    return (mem.token, mem.uplineAddress, mem.regAddress, mem.balance, mem.level);
  }
}