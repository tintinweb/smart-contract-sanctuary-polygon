pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract LottoX is Ownable{
  using SafeMath for uint256;
  
  string public name = "Lotto X";
  string public symbol = "LTX";
  address private _token = 0x2D279333fcd1E818E240a7b26BBCeC364A3C7B8C;
  uint256 private _tokenDecimal = 18;
  uint256 private _oddid;
  uint256 private _charge = 20;
  uint[] private _rates = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];

  bool public gameOn = true;
  uint256 private _totalPool;
  uint256 private _totalDeposit;
  uint256 private _totalBonus;
  uint256 private _totalWin;
  uint256 public _lastBetID;
  uint256 public _startBetID;

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

  struct Winner{
    uint256 wonResult;
    uint256 sponsorBonus;
    uint256 wonBonus;
  }

  mapping (address => Member) private _members;
  mapping (uint256 => OddBet) private _oddBets;
  mapping (uint256 => OddAddress) private _oddAddresses;

  mapping (address => uint256) _winnerRecords;
  mapping (uint256 => uint256) _totalOddBets;
  mapping (address => uint256) _winnerBonuses;
  mapping (address => uint256) _sponsorBonuses;

  function setRate(uint[] memory rates) public onlyOwner{
    _rates = rates;
  }

  function setCharge(uint256 charge) public onlyOwner{
    _charge = charge;
  }

  function setToken(address token, uint256 decimal) public onlyOwner{
    _token = token;
    _tokenDecimal = decimal;
  }

  function setResult(uint256 oddID) public onlyOwner{
    gameOn = false;
    _oddid = oddID;

    uint256 betWin;
    uint256 totaPayout;

    uint256 totalOddBet = _totalOddBets[oddID];

    if(totalOddBet > 0){

      for(uint i=_startBetID; i<_lastBetID; i++){
        
        (uint256 betAmt, address winnerAddr)  = getOddRecord(i, oddID);
        
        betWin = betAmt.mul(_totalPool).div(totalOddBet);
        _winnerRecords[winnerAddr] = _winnerRecords[winnerAddr].add(betWin);

        totaPayout += betWin;
        _totalWin = _totalWin.add(betWin);
        _winnerPayout(_members[winnerAddr].uplineAddress, betWin, 0);
      }

      if(totaPayout > 0 && _totalPool >= totaPayout){
        _totalPool = _totalPool.sub(totaPayout);
      }
      _totalOddBets[oddID] = _totalOddBets[oddID].sub(totalOddBet);
    }
  }

  function startGame() public onlyOwner{
    gameOn = true;
    _totalPool = 0;
    _totalDeposit = 0;
    _oddid = 0;
    _startBetID = _lastBetID;
  }

  function endGame() public onlyOwner{
    gameOn = false;
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

  function reg(address uplineAddress, uint256 id, uint256 amount) public {
    require(gameOn, "Game was Ended");
    require(id > 0, "Invalid item!");
    require(uplineAddress != msg.sender, "Upline same your address!");
    require(_members[msg.sender].totalDownlines == 0, "Address exits!");

    ERC20(_token).transferFrom(msg.sender, address(this), amount);

    if(uplineAddress == address(0)){
        uplineAddress = address(this);
    }

    _members[msg.sender] = Member(
        uplineAddress,
        _members[msg.sender].directs.add(0), 
        _members[msg.sender].totalDownlines.add(1), 
        _members[msg.sender].directSales.add(0),
        _members[msg.sender].groupSales.add(amount),
        _members[uplineAddress].level.add(1)
    );
    
    _totalDeposit                   = _totalDeposit.add(amount);

    _bet(id, amount, msg.sender);
    
    _members[uplineAddress].directs     = _members[uplineAddress].directs.add(1);
    _members[uplineAddress].directSales = _members[uplineAddress].directSales.add(amount);

    _totalOddBets[id]               = _totalOddBets[id].add(amount);
    _totalPool                      = _totalPool.add(amount);
    uint256 _chargeAmt              = amount.mul(_charge).div(100);
    if(_totalPool > 0 && _totalPool >= _chargeAmt){
      _totalPool                    = _totalPool.sub(_chargeAmt);
    }
    _payout(uplineAddress, amount, 0);
    _updateDownlines(uplineAddress, amount, 0);
  }

  function _updateDownlines(address uplineAddress, uint256 amount, uint levelCounter) internal{

    if(_rates.length > levelCounter && uplineAddress != address(0)){
      _members[uplineAddress].totalDownlines = _members[uplineAddress].totalDownlines.add(1);
      _members[uplineAddress].groupSales = _members[uplineAddress].groupSales.add(amount);
      _updateDownlines(_members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }
  
  function _updateGroupSales(address uplineAddress, uint256 amount, uint levelCounter) internal{

    if(_rates.length > levelCounter && uplineAddress != address(0)){
      _members[uplineAddress].groupSales = _members[uplineAddress].groupSales.add(amount);
      _updateGroupSales(_members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }

  function buy(uint256 id, uint256 amount) public{
    require(gameOn, "Game was Ended!");
    require(id > 0, "Invalid item!");
    address _uplineAddress = _members[msg.sender].uplineAddress;
    require(_uplineAddress != address(0), "Your address not yet register!");

    _bet(id, amount, msg.sender);
    _totalDeposit                           = _totalDeposit.add(amount);

    _totalOddBets[id]                       = _totalOddBets[id].add(amount);
    _totalPool                              = _totalPool.add(amount);
    uint256 _chargeAmt                      = amount.mul(_charge).div(100);
	
    if(_totalPool > 0 && _totalPool >= _chargeAmt){
      _totalPool                            = _totalPool.sub(_chargeAmt);
    }

    _members[_uplineAddress].directSales    = _members[_uplineAddress].directSales.add(amount);
    _members[msg.sender].groupSales = _members[msg.sender].groupSales.add(amount);

    ERC20(_token).transferFrom(msg.sender, address(this), amount);
    _payout(_uplineAddress, amount, 0);
    _updateGroupSales(_uplineAddress, amount, 0);
  }

  function _payout(address uplineAddress, uint256 amount, uint levelCounter) internal{
    if(amount > 0 && _rates.length > levelCounter && _members[uplineAddress].totalDownlines > 0 && uplineAddress != address(0) && uplineAddress != address(this)){
      uint256 _bonus                        = amount.mul(_rates[levelCounter]).div(100);
      // ERC20(_token).transfer(uplineAddress, _bonus);
      _sponsorBonuses[uplineAddress]        = _sponsorBonuses[uplineAddress].add(_bonus);
      _totalBonus                           = _totalBonus.add(_bonus);
      _payout(_members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }

  function _winnerPayout(address uplineAddress, uint256 amount, uint levelCounter) internal{
    if(amount > 0 && _rates.length > levelCounter && _members[uplineAddress].totalDownlines > 0 && uplineAddress != address(0) && uplineAddress != address(this)){
      uint256 _bonus                    = amount.mul(_rates[levelCounter]).div(100);
      _winnerBonuses[uplineAddress]     = _winnerBonuses[uplineAddress].add(_bonus);
      _totalBonus                       = _totalBonus.add(_bonus);
      _winnerPayout(_members[uplineAddress].uplineAddress, amount, levelCounter+1);
    }
  }

  function result() public view returns (string memory){
    return oddLabels[_oddid];
  }

  function gameStatus() public view returns (bool){
    return gameOn;
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

  function chenMyTotalWonAmount(address to) public view returns (uint256){
    return _winnerRecords[to] / (10 ** _tokenDecimal);
  }

  function chenMyTotalSponsorBonus(address to) public view returns (uint256){
    return _sponsorBonuses[to] / (10 ** _tokenDecimal);
  }

  function chenMyTotalWinnerBonus(address to) public view returns (uint256){
    return _winnerBonuses[to] / (10 ** _tokenDecimal);
  }

  function checkTotalPool() public view returns (uint256){
    return _totalPool / (10 ** _tokenDecimal);
  }

  function checkTotalDeposit() public view returns (uint256){
    return _totalDeposit / (10 ** _tokenDecimal);
  }

  function checkTotalWin() public view returns (uint256){
    return _totalWin / (10 ** _tokenDecimal);
  }

  function checkTotalBonus() public view returns (uint256){
    return _totalBonus / (10 ** _tokenDecimal);
  }

  function getOddRecord(uint256 _id, uint256 _odd) public view returns (uint256, address){
    
    uint256 oddBet;
    address oddAddr;
    if(_odd == 1){
      oddBet = _oddBets[_id].bet1;
      oddAddr = _oddAddresses[_id].addr1;
    }
    else if(_odd == 2){
      oddBet = _oddBets[_id].bet2;
      oddAddr = _oddAddresses[_id].addr2;
    }
    else if(_odd == 3){
      oddBet = _oddBets[_id].bet3;
      oddAddr = _oddAddresses[_id].addr3;
    }
    else if(_odd == 4){
      oddBet = _oddBets[_id].bet4;
      oddAddr = _oddAddresses[_id].addr4;
    }
    else if(_odd == 5){
      oddBet = _oddBets[_id].bet5;
      oddAddr = _oddAddresses[_id].addr5;
    }
    return (oddBet, oddAddr);
  }

  function withdrawToken(ERC20 token, address _to, uint256 _amount) public onlyOwner returns(bool){
    token.transfer(_to, _amount);
    return true;
  }
  
  function withdrawAllIncome() public returns(bool){
    uint256 winAmt    = _winnerRecords[msg.sender];
    uint256 winBonus  = _winnerBonuses[msg.sender];
    uint256 spBonus   = _sponsorBonuses[msg.sender];
    uint256 allAmt    = winAmt + winBonus + spBonus;
    require(allAmt > 0, "Insuffient amount");
    
    if(winAmt > 0){
      ERC20(_token).transfer(msg.sender, winAmt);
      _winnerRecords[msg.sender]  = _winnerRecords[msg.sender].sub(winAmt);
    }

    if(winBonus > 0){
      ERC20(_token).transfer(msg.sender, winBonus);
      _winnerBonuses[msg.sender] = _winnerBonuses[msg.sender].sub(winBonus);
    }

    if(spBonus > 0){
      ERC20(_token).transfer(msg.sender, spBonus);
      _sponsorBonuses[msg.sender] = _sponsorBonuses[msg.sender].sub(spBonus);
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