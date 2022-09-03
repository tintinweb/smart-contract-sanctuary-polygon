/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IPOLYCONTRACTM6 {
    function _verifyInMatic() external payable returns (bool);
    function placeInM6(address user,address referrer,uint package) external returns (bool);
    function creditM6Income(address user,uint package,uint level,uint IsFreshId) external returns (bool);
}

interface IPOLYCONTRACTM6PROXYA {
    function _PlaceInM615Tree(address user,address referrer) external returns (bool);
    function _PlaceInM630Tree(address user,address referrer) external returns (bool);
}

interface IPOLYCONTRACTM6PROXYB {
    function _PlaceInM660Tree(address user,address referrer) external returns (bool);
    function _PlaceInM6120Tree(address user,address referrer) external returns (bool);
}

interface IPOLYCONTRACTM6PROXYC {
    function _PlaceInM6240Tree(address user,address referrer) external returns (bool);
    function _PlaceInM6480Tree(address user,address referrer) external returns (bool);
}

contract MetaOMaticM6 is IPOLYCONTRACTM6 {

    address public contractOwner;
    uint256 public totalM6Income;
    uint[2] public ref_bonuses = [10,50]; 
    uint public m6per=50;

    uint256[6] public packagePrice = [1 ether,2 ether,3 ether,4 ether,5 ether,6 ether];

    struct SystemM6Details {
        uint256 totalM615Bonus;
        uint256 totalM630Bonus;
        uint256 totalM660Bonus;
        uint256 totalM6120Bonus;
        uint256 totalM6240Bonus;
        uint256 totalM6480Bonus;
    }

    struct UserM6Bonus {
      uint256 totalBonus;
      uint256 usedBonus;
      uint256 availableBonus;
    }

    struct UserM6BonusDetails {
        uint256 totalM615Bonus;
        uint256 totalM630Bonus;
        uint256 totalM660Bonus;
        uint256 totalM6120Bonus;
        uint256 totalM6240Bonus;
        uint256 totalM6480Bonus;
    }

    mapping (uint => SystemM6Details) public _SystemM6Details;
    mapping (address => UserM6Bonus) public _UserM6Bonus;
    mapping (address => UserM6BonusDetails) public _UserM6BonusDetails;

    IPOLYCONTRACTM6PROXYA internal m6proxya;
    IPOLYCONTRACTM6PROXYB internal m6proxyb;
    IPOLYCONTRACTM6PROXYC internal m6proxyc;

    constructor() {
      contractOwner=0xEBc985f2964855650b8EA81f714cCb90a5843EE0;
    }

    //Update M6 Proxy A Contract
    function update_M6ProxyA(address M6ProxyA) public {
      require(contractOwner==msg.sender, 'Admin what?');
      m6proxya=IPOLYCONTRACTM6PROXYA(M6ProxyA);
    }

    //Update M6 Proxy B Contract
    function update_M6ProxyB(address M6ProxyB) public {
      require(contractOwner==msg.sender, 'Admin what?');
      m6proxyb=IPOLYCONTRACTM6PROXYB(M6ProxyB);
    }

    //Update M6 Proxy C Contract
    function update_M6ProxyC(address M6ProxyC) public {
      require(contractOwner==msg.sender, 'Admin what?');
      m6proxyc=IPOLYCONTRACTM6PROXYC(M6ProxyC);
    }

    //Admin Can Update The Package Price
    function _updatePackage(uint packageId,uint packageAmount) public {
        require(msg.sender == contractOwner, "Only Admin Can ?");
        require(packageId >= 0 && packageId < 6, "Invalid Package !");    
        packagePrice[packageId]=packageAmount;
    }

    //Admin Can Recover Lost Matic
    function _verifyOutMatic(uint256 amount) public {
        require(msg.sender == contractOwner, "Only Admin Can ?");
        _SafeTransfer(payable(contractOwner),amount);
    }

    //Admin Can Deposit Matic
    function _verifyInMatic() public payable override returns (bool) {
        return true;
    }

    function _WithdrawalAuto(address payable user) internal { 
      uint256 amount = _UserM6Bonus[user].availableBonus;
      _UserM6Bonus[user].usedBonus += amount;
      _UserM6Bonus[user].availableBonus -= amount; 
      if(user!=address(0) && user!=0x0000000000000000000000000000000000000000) {
        _SafeTransfer(user,amount);
      }
    }

    function _SafeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
      amount = (_amount < address(this).balance) ? _amount : address(this).balance;
      if(_to!=address(0) && _to!=0x0000000000000000000000000000000000000000) {
        _to.transfer(amount);
      }
    }

    //Place In M6
    function placeInM6(address user,address referrer,uint package) public override returns (bool) {
      if(package==0){
        m6proxya._PlaceInM615Tree(user,referrer);
      }
      else if(package==1){
        m6proxya._PlaceInM630Tree(user,referrer);
      }
      else if(package==2){
        m6proxyb._PlaceInM660Tree(user,referrer);
      }
      else if(package==3){
        m6proxyb._PlaceInM6120Tree(user,referrer);
      }
      else if(package==4){
        m6proxyc._PlaceInM6240Tree(user,referrer);
      }
      else if(package==5){
        m6proxyc._PlaceInM6480Tree(user,referrer);
      }
      return true;
    }

    function creditM6Income(address user,uint package,uint level,uint IsFreshId) public override returns (bool) {
      if(IsFreshId==1){
        uint packageamount=packagePrice[package];
        uint LevelIncomeDistributionWorth=((packageamount*m6per)/100);
        uint amount=((LevelIncomeDistributionWorth*ref_bonuses[level])/100);
        if(package==0){
          _UserM6BonusDetails[user].totalM615Bonus += amount;
          _SystemM6Details[0].totalM615Bonus += amount;
        }
        else if(package==1){
          _UserM6BonusDetails[user].totalM630Bonus += amount;
          _SystemM6Details[0].totalM630Bonus += amount;
        }
        else if(package==2){
          _UserM6BonusDetails[user].totalM660Bonus += amount;
          _SystemM6Details[0].totalM660Bonus += amount;
        }
        else if(package==3){
          _UserM6BonusDetails[user].totalM6120Bonus += amount;
          _SystemM6Details[0].totalM6120Bonus += amount;
        }
        else if(package==4){
          _UserM6BonusDetails[user].totalM6240Bonus += amount;
          _SystemM6Details[0].totalM6240Bonus += amount;
        }
        else if(package==5){
          _UserM6BonusDetails[user].totalM6480Bonus += amount;
          _SystemM6Details[0].totalM6480Bonus += amount;
        }
        totalM6Income+=amount;
        _UserM6Bonus[user].totalBonus += amount;
        _UserM6Bonus[user].availableBonus += amount;
        _WithdrawalAuto(payable(user));
      }
      return true;
    }

}