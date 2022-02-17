pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract LottoX is Ownable{
  using SafeMath for uint256;
  
  string public name = "Lotto X";
  string public symbol = "LTX";
  bool public gameOn = true;
  uint256 public totalBonus;
  uint256 public totalPool;
  uint256 public totalWin;
  uint256 private _oddid;
  uint256 private _charge = 20;
  uint256 public _lastBetID;

  uint[] public rates = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];

  mapping (address => uint256) _bonuses;

  mapping (address => uint256) _balances;

  mapping (address => uint256) private _winnerBalances;

  mapping (address => uint256) private _totalWinAmounts;

  string[] public oddLabels = ["-", "Gold", "Wood", "Water", "Fire", "Earth"];

  struct Member{
    address uplineAddress;
    uint256 directs;
    uint256 totalDownlines;
    uint256 directSales;
    uint256 groupSales;
    uint256 level;
  }

  struct OddBet{
    uint256 bet1;
    uint256 bet2;
    uint256 bet3;
    uint256 bet4;
    uint256 bet5;
  }

  struct OddAddress{
    address addr1;
    address addr2;
    address addr3;
    address addr4;
    address addr5;
  }

  mapping (address => Member) private _members;
  mapping (uint256 => OddBet) private _oddBets;
  mapping (uint256 => OddAddress) private _oddAddresses;

  function setRate(uint[] memory _rates) public onlyOwner{
    rates = _rates;
  }

  function setCharge(uint256 charge) public onlyOwner{
    _charge = charge;
  }

  function setResult(ERC20 token, uint256 id) public onlyOwner{
    gameOn = false;
    _oddid = id;
    _loopBet(token, id, 0);
  }

  function _loopBet(ERC20 token, uint256 id, uint256 counter) internal{
    if(counter <= _lastBetID){
      uint256 betAmt;
      uint256 betWin;
      address winnerAddr;

      if(id == 1){
        betAmt = _oddBets[counter].bet1;
        winnerAddr = _oddAddresses[counter].addr1;
      }
      else if(id == 2){
        betAmt = _oddBets[counter].bet2;
        winnerAddr = _oddAddresses[counter].addr2;
      }
      else if(id == 3){
        betAmt = _oddBets[counter].bet3;
        winnerAddr = _oddAddresses[counter].addr3;
      }
      else if(id == 4){
        betAmt = _oddBets[counter].bet4;
        winnerAddr = _oddAddresses[counter].addr4;
      }
      else if(id == 5){
        betAmt = _oddBets[counter].bet5;
        winnerAddr = _oddAddresses[counter].addr5;
      }
      
      betWin = betAmt.div(totalPool).mul(betAmt);
    
      if(totalPool > 0 && totalPool >= betWin){
        totalPool = totalPool.sub(betWin);
      }
      
      _winnerBalances[winnerAddr] = _winnerBalances[winnerAddr].add(betWin);
      _totalWinAmounts[winnerAddr] = _totalWinAmounts[winnerAddr].add(betWin);
      totalWin = totalWin.add(totalPool);
    
      _winnerPayout(token, _members[winnerAddr].uplineAddress, betWin, 0);
      delete _oddBets[counter];
      delete _oddAddresses[counter];
      _loopBet(token, id, counter+1);
    }
  }

  function startGame() public onlyOwner{
    gameOn = true;
    totalPool = 0;
    _oddid = 0;
    _lastBetID = 0;
  }

  function setMember(address to, address uplineAddress, uint256 id, uint256 totalDownlines) public onlyOwner{
    require(id > 0, "Invalid item!");
    if(uplineAddress == address(0)){
        uplineAddress = address(this);
    }
    _members[to] = Member(uplineAddress, 0, totalDownlines, 0, 0, 0);
  }

  function _bet(uint256 id, uint256 amount, address to) internal{
    if(id == 1){
      _oddBets[_lastBetID] = OddBet(amount, 0, 0, 0, 0);
      _oddAddresses[_lastBetID] = OddAddress(to, address(0), address(0), address(0), address(0));
    }
    else if(id == 2){
      _oddBets[_lastBetID] = OddBet(0, amount, 0, 0, 0);
      _oddAddresses[_lastBetID] = OddAddress(address(0), to, address(0), address(0), address(0));
    }
    else if(id == 3){
      _oddBets[_lastBetID] = OddBet(0, 0, amount, 0, 0);
      _oddAddresses[_lastBetID] = OddAddress(address(0), address(0), to, address(0), address(0));
    }
    else if(id == 4){
      _oddBets[_lastBetID] = OddBet(0, 0, 0, amount, 0);
      _oddAddresses[_lastBetID] = OddAddress(address(0), address(0), address(0), to, address(0));
    }
    else if(id == 5){
      _oddBets[_lastBetID] = OddBet(0, 0, 0, 0, amount);
      _oddAddresses[_lastBetID] = OddAddress(address(0), address(0), address(0), address(0), to);
    }
    _lastBetID++;
  }

  function reg(ERC20 token, address uplineAddress, uint256 id, uint256 amount) public {
    require(gameOn, "Game was Ended");
    require(id > 0, "Invalid item!");
    require(uplineAddress != msg.sender, "Upline same your address!");
    require(_members[msg.sender].totalDownlines == 0, "Address exits!");

    token.transferFrom(msg.sender, address(this), amount);

    if(uplineAddress == address(0)){
        uplineAddress = address(this);
    }

    _members[msg.sender] = Member(
        uplineAddress,
        _members[msg.sender].directs.add(0), 
        _members[msg.sender].totalDownlines.add(1), 
        _members[msg.sender].directSales.add(amount),
        _members[msg.sender].groupSales.add(amount),
        _members[uplineAddress].level.add(1)
    );

    _bet(id, amount, msg.sender);
    
    _members[uplineAddress].directs = _members[uplineAddress].directs.add(1);

    totalPool                       = totalPool.add(amount);
    uint256 _chargeAmt              = amount.mul(_charge).div(100);
    if(totalPool > 0 && totalPool >= _chargeAmt){
      totalPool                   = totalPool.sub(_chargeAmt);
    }
    _payout(token, uplineAddress, amount, 0);
    _updateDownlines(uplineAddress, amount, 0);
  }

  function _updateDownlines(address uplineAddress, uint256 amount, uint levelCounter) internal{

    if(rates.length > levelCounter && uplineAddress != address(0)){
      _members[uplineAddress].totalDownlines = _members[uplineAddress].totalDownlines.add(1);
      _members[uplineAddress].groupSales = _members[uplineAddress].groupSales.add(amount);
      _updateDownlines(_members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }
  
  function _updateGroupSales(address uplineAddress, uint256 amount, uint levelCounter) internal{

    if(rates.length > levelCounter && uplineAddress != address(0)){
      _members[uplineAddress].groupSales = _members[uplineAddress].groupSales.add(amount);
      _updateGroupSales(_members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }

  function buy(ERC20 token, uint256 id, uint256 amount) public{
    require(gameOn, "Game was Ended");
    require(id > 0, "Invalid item!");
    address _uplineAddress = _members[msg.sender].uplineAddress;
    require(_uplineAddress != address(0), "Your address not yet register!");
    
    _members[msg.sender].groupSales = _members[msg.sender].groupSales.add(amount);

    _bet(id, amount, msg.sender);
    
    _balances[msg.sender]                   = _balances[msg.sender].add(amount);

    totalPool                               = totalPool.add(amount);
    uint256 _chargeAmt                      = amount.mul(_charge).div(100);
	
    if(totalPool > 0 && totalPool >= _chargeAmt){
      totalPool                           = totalPool.sub(_chargeAmt);
    }

    _members[_uplineAddress].directSales    = _members[_uplineAddress].directSales.add(amount);

    token.transferFrom(msg.sender, address(this), amount);
    _payout(token, _uplineAddress, amount, 0);
    _updateGroupSales(_uplineAddress, amount, 0);
  }

  function payout(ERC20 token, address to, uint256 amount) public onlyOwner{
    require(_members[to].totalDownlines > 0, "Address no exists");
    _payout(token, to, amount, 0);
  }

  function _payout(ERC20 token, address uplineAddress, uint256 amount, uint levelCounter) internal{
    if(rates.length > levelCounter && _members[uplineAddress].totalDownlines > 0 && uplineAddress != address(0)){
      uint256 _bonus = amount.mul(rates[levelCounter]).div(100);

      token.transfer(uplineAddress, _bonus);
      
      _bonuses[uplineAddress]         = _bonuses[uplineAddress].add(_bonus);

      totalBonus                      = totalBonus.add(amount);
    
      _payout(token, _members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }

  function _winnerPayout(ERC20 token, address uplineAddress, uint256 amount, uint levelCounter) internal{
    if(rates.length > levelCounter && _members[uplineAddress].totalDownlines > 0 && uplineAddress != address(0)){
      uint256 _bonus = amount.mul(rates[levelCounter]).div(100);
      
      _bonuses[uplineAddress]         = _bonuses[uplineAddress].add(_bonus);
      
      totalBonus                      = totalBonus.add(amount);
      
      _winnerPayout(token, _members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }

  function checkBonus(address _to) public onlyOwner view returns (uint256) {
    return _bonuses[_to];
  }

  function checkBalance(address _to) public onlyOwner view returns (uint256) {
    return _balances[_to];
  }

  function checkTotalWin(address _to) public onlyOwner view returns (uint256) {
    return _totalWinAmounts[_to];
  }

  function checkMyWonBalance() public view returns (uint256) {
    return _winnerBalances[msg.sender];
  }

  function getResult() public view returns (string memory){
    return oddLabels[_oddid];
  }

  function getMember(address to) public view returns (address, uint256, uint256, uint256, uint256){
    return (
      _members[to].uplineAddress, 
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

  function withdrawMyToken(ERC20 token) public returns(bool){
    uint256 winAmt = _winnerBalances[msg.sender];
    token.transfer(msg.sender, winAmt);
    if(_winnerBalances[msg.sender] > 0 && _winnerBalances[msg.sender] >= winAmt){
      _winnerBalances[msg.sender] = _winnerBalances[msg.sender].sub(winAmt);
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