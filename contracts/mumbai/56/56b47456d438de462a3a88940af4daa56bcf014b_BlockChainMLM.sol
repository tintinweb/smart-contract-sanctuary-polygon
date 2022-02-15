pragma solidity ^0.5.0;

import "./SafeMath.sol";
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
  using SafeMath for uint256;
	
  string public name = "BlockchanMLM";
  string public symbol = "BMLM";

  uint[] public rates = [10,9,8,7,6,5,4,3,2,1];

  struct Member{
    ERC20 token;
    address uplineAddress;
    uint256 bal;
  }

  mapping (address => Member) private _members;

  function setRate(uint[] memory _rates) public onlyOwner{
    rates = _rates;
  }

  function reg(ERC20 token, address uplineAddress, uint256 amount) public {

    token.transferFrom(msg.sender, address(this), amount);

    _members[msg.sender] = Member(token, uplineAddress, _members[msg.sender].bal.add(amount));

    // _payout(token, uplineAddress, amount, 0);
  }

  function _payout(ERC20 token, address uplineAddress, uint256 amount, uint levelCounter) internal{
    
    require(rates.length > levelCounter);
    require(uplineAddress != address(0));

    token.transfer(uplineAddress, amount.mul(rates[levelCounter] / 100));
    
    _payout(token, _members[uplineAddress].uplineAddress, amount, levelCounter+1);
  }

  function getMember(address to) public view returns (ERC20, address, uint256) {
    return (_members[to].token, _members[to].uplineAddress, _members[to].bal);
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

  function withdrawAllTo(address payable _to) public onlyOwner returns(bool){
    _to.transfer(getBalance());
     return true;
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }
}