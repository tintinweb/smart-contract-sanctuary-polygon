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
    uint256 directs;
    uint256 totalDownlines;
    uint256 directSales;
    uint256 groupSales;
  }

  mapping (address => Member) private _members;

  function setRate(uint[] memory _rates) public onlyOwner{
    rates = _rates;
  }

  function setMember(ERC20 token, address to, address uplineAdress, uint256 amount) public onlyOwner{
      _members[to] = Member(token, uplineAdress, amount, 0, 0, 0, 0);
  }

  function reg(ERC20 token, address uplineAddress, uint256 amount) public {
    require(uplineAddress != msg.sender, "Upline same your address!");
    require(_members[msg.sender].totalDownlines == 0, "Reg exits!");

    token.transferFrom(msg.sender, address(this), amount);

    _members[msg.sender] = Member(
        token, 
        uplineAddress,
        _members[msg.sender].bal.add(amount), 
        _members[msg.sender].directs.add(0), 
        _members[msg.sender].totalDownlines.add(1), 
        _members[msg.sender].directSales.add(amount),
        _members[msg.sender].groupSales.add(amount)
    );
    _payout(token, uplineAddress, amount, 0);
    // _updateDownlines(uplineAddress, amount, 0);
  }

  function _updateDownlines(address uplineAddress, uint256 amount, uint levelCounter) internal{
    
    require(uplineAddress != address(0));
    require(rates.length > levelCounter);

    _members[uplineAddress].totalDownlines.add(1);
    _members[uplineAddress].groupSales.add(amount);
    
    _updateDownlines(_members[uplineAddress].uplineAddress, amount, levelCounter+1);
  }

  function reTopup(ERC20 token, uint256 amount) public{
    require(_members[msg.sender].uplineAddress != address(0), "This address not yet register!");

    _members[msg.sender].bal = _members[msg.sender].bal.add(amount);
    token.transferFrom(msg.sender, address(this), amount);
    _payout(token, _members[msg.sender].uplineAddress, amount, 0);
  }

  function payout(ERC20 token, address uplineAddress, uint256 amount) public onlyOwner{
    require(_members[uplineAddress].uplineAddress != address(0), "No such this upline!");
    _payout(token, uplineAddress, amount, 0);
  }
  
  function _payout(ERC20 token, address uplineAddress, uint256 amount, uint levelCounter) internal{
    require(rates.length > levelCounter);
    if(uplineAddress != address(0)){
      if(_members[uplineAddress].totalDownlines > 0){
        token.transfer(uplineAddress, amount.mul(rates[levelCounter]).div(100));
        _payout(token, _members[uplineAddress].uplineAddress, amount, levelCounter+1);
      }
      else{
        _payout(token, _members[uplineAddress].uplineAddress, amount, levelCounter);
      }
    }
  }

  function getMember(address to) public view returns (ERC20, address, uint256, uint256, uint256, uint256, uint256) {
    return (
      _members[to].token, 
      _members[to].uplineAddress, 
      _members[to].bal,
      _members[to].directs, 
      _members[to].totalDownlines, 
      _members[to].directSales,
      _members[to].groupSales
    );
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