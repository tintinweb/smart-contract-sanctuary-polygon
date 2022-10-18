/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPOLYCONTRACTRING {
    function getRingBous(address user) external view returns (uint256);
    function getRingQualifier(uint ring) external view returns (uint);
    function updateRingBous(address user) external returns (bool);
    function placeInRing(address user) external returns (bool);
}

interface IPOLYCONTRACTMAIN {
    function getTotalDirect(address user) external view returns (uint);
}

contract VaraGoldRing is IPOLYCONTRACTRING {
    
    address public contractOwner;

    //Ring Setting Start Here
    IPOLYCONTRACTMAIN public maincontract;

    uint public ringWidth = 4;

    uint public rewardRing1Slab = 15000000;
    uint public rewardRing2Slab = 45000000;
    uint public rewardRing3Slab = 100000000;
    uint public rewardRing4Slab = 300000000;
    uint public rewardRing5Slab = 600000000;
    uint public rewardRing6Slab = 2000000000;
    uint public rewardRing7Slab = 5000000000;
    uint public rewardRing8Slab = 15000000000;
    uint public rewardRing9Slab = 40000000000;
    uint public rewardRing10Slab = 200000000000;

    uint public noofDirectForRing5 = 5;
    uint public noofDirectForRing6 = 6;
    uint public noofDirectForRing7 = 7;
    uint public noofDirectForRing8 = 8;
    uint public noofDirectForRing9 = 9;
    uint public noofDirectForRing10 = 10;

    address[] public ring1QualifierList;
    address[] public ring2QualifierList;
    address[] public ring3QualifierList;
    address[] public ring4QualifierList;
    address[] public ring5QualifierList;
    address[] public ring6QualifierList;
    address[] public ring7QualifierList;
    address[] public ring8QualifierList;
    address[] public ring9QualifierList;
    address[] public ring10QualifierList;

    struct UserIncomeDetails {
        uint256 totalBonus;
        uint256 creditedWallet;
        uint256 usedWallet;
        uint256 availableWallet;
    }

    struct SystemRingTotalId {
        uint256 totalRingId;
        uint256 totalRing1Id;
        uint256 totalRing2Id;
        uint256 totalRing3Id;
        uint256 totalRing4Id;
        uint256 totalRing5Id;
        uint256 totalRing6Id;
        uint256 totalRing7Id;
        uint256 totalRing8Id;
        uint256 totalRing9Id;
        uint256 totalRing10Id;
    }

    struct SystemRingBonusDetails {
        uint256 totalRingBonus;
        uint256 totalRing1Bonus;
        uint256 totalRing2Bonus;
        uint256 totalRing3Bonus;
        uint256 totalRing4Bonus;
        uint256 totalRing5Bonus;
        uint256 totalRing6Bonus;
        uint256 totalRing7Bonus;
        uint256 totalRing8Bonus;
        uint256 totalRing9Bonus;
        uint256 totalRing10Bonus;
    }

    struct UserRingIncomeDetails {
        uint256 totalRing1Bonus;
        uint256 totalRing2Bonus;
        uint256 totalRing3Bonus;
        uint256 totalRing4Bonus;
        uint256 totalRing5Bonus;
        uint256 totalRing6Bonus;
        uint256 totalRing7Bonus;
        uint256 totalRing8Bonus;
        uint256 totalRing9Bonus;
        uint256 totalRing10Bonus;
    }

    mapping (address => UserIncomeDetails) public _UserIncomeDetails;
    mapping (address => UserRingIncomeDetails) public _UserRingIncomeDetails;
    mapping (uint => SystemRingBonusDetails) public _SystemRingBonusDetails;
    mapping (uint => SystemRingTotalId) public _SystemRingTotalId;

    event PlaceInRing(address indexed user);

    constructor() public {
      address _contractOwner=0x10D8AAb78b45d557DAbb153A21b57F62CF69d00C;
      contractOwner =_contractOwner;
      ring1QualifierList.push(contractOwner);
      _SystemRingTotalId[0].totalRingId += 1;
      _SystemRingTotalId[0].totalRing1Id += 1;
    }

    //Get Total Ring Bonus
    function getRingBous(address user) public view override returns (uint256) {
        return (_UserIncomeDetails[user].availableWallet);
    }

    //Get Total Ring Qualification
    function checkRingQualification(address user,uint ring) public view returns (bool) {
      uint noofdirect=maincontract.getTotalDirect(user);
      if(ring>=1 && ring<=4)
      {
          return true;
      }
      else if(ring>=5 && noofdirect>=ring){
          return true;
      }
      else{
          return false;
      }
    }

    //Get Total Ring Qualifier
    function getRingQualifier(uint ring) public view override returns (uint) {
        if(ring==1){ return(ring1QualifierList.length); }
        else if(ring==2){ return(ring2QualifierList.length); }
        else if(ring==3){ return(ring3QualifierList.length); }
        else if(ring==4){ return(ring4QualifierList.length); }
        else if(ring==5){ return(ring5QualifierList.length); }
        else if(ring==6){ return(ring6QualifierList.length); }
        else if(ring==7){ return(ring7QualifierList.length); }
        else if(ring==8){ return(ring8QualifierList.length); }
        else if(ring==9){ return(ring9QualifierList.length); }
        else if(ring==10){ return(ring10QualifierList.length); }
        else{ return(0); }
    }

    //Update Ring Bonus Settings
    function updateRingBonusSetting(uint _ringWidth,uint _rewardRing1,uint _rewardRing2,uint _rewardRing3,uint _rewardRing4,uint _rewardRing5,uint _rewardRing6,uint _rewardRing7,uint _rewardRing8,uint _rewardRing9,uint _rewardRing10) public {
      require(contractOwner==msg.sender, 'Admin what?');
      ringWidth = _ringWidth;
      rewardRing1Slab = _rewardRing1;
      rewardRing2Slab = _rewardRing2;
      rewardRing3Slab = _rewardRing3;
      rewardRing4Slab = _rewardRing4;
      rewardRing5Slab = _rewardRing5;
      rewardRing6Slab = _rewardRing6;
      rewardRing7Slab = _rewardRing7;
      rewardRing8Slab = _rewardRing8;
      rewardRing9Slab = _rewardRing9;
      rewardRing10Slab = _rewardRing10;
    }

    //Update No Of Direct Needed
    function updateRingQualifierDirect(uint _noofDirectForRing5,uint _noofDirectForRing6,uint _noofDirectForRing7,uint _noofDirectForRing8,uint _noofDirectForRing9,uint _noofDirectForRing10) public {
      require(contractOwner==msg.sender, 'Admin what?');
      noofDirectForRing5 = _noofDirectForRing5;
      noofDirectForRing6 = _noofDirectForRing6;
      noofDirectForRing7 = _noofDirectForRing7;
      noofDirectForRing8 = _noofDirectForRing8;
      noofDirectForRing9 = _noofDirectForRing9;
      noofDirectForRing10 = _noofDirectForRing10;
    }

    //Update Main Contract Here
    function updateMainContract(address _maincontract) public {
      require(contractOwner==msg.sender, 'Admin what?');
      maincontract=IPOLYCONTRACTMAIN(_maincontract);
    }

    //Update Ring Bonus
    function updateRingBous(address user) public override returns (bool) {
      _UserIncomeDetails[user].usedWallet += _UserIncomeDetails[user].availableWallet;
      _UserIncomeDetails[user].availableWallet -= _UserIncomeDetails[user].availableWallet; 
      return true;
    }

    //Place In Ring
    function placeInRing(address user) public override returns (bool) {
      _PlaceInRing1(user,1);
      emit PlaceInRing(user);
      return true;
    }

    //Place In Ring 1
    function _PlaceInRing1(address user,uint noofentry) private {
      for(uint I=1;I<=noofentry;I++){
      ring1QualifierList.push(user);
      _SystemRingTotalId[0].totalRingId += 1;
      _SystemRingTotalId[0].totalRing1Id += 1;
      uint Length=ring1QualifierList.length;
      Length -= 1;
      if((Length%ringWidth)==0) {
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring1QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing1Slab;
         _UserRingIncomeDetails[placementId].totalRing1Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing1Bonus += rewardRing;
         //Comment Distribution Start Here
         _PlaceInRing2(placementId);
        }
      }
    }

    //Place In Ring 2
    function _PlaceInRing2(address user) private {
      ring2QualifierList.push(user);
      _SystemRingTotalId[0].totalRing2Id += 1;
      uint Length=ring2QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring2QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing2Slab;
         _UserRingIncomeDetails[placementId].totalRing2Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing2Bonus += rewardRing;
         //Comment Distribution Start Here
         _PlaceInRing3(placementId);
      }
    }

    //Place In Ring 3
    function _PlaceInRing3(address user) private {
      ring3QualifierList.push(user);
      _SystemRingTotalId[0].totalRing3Id += 1;
      uint Length=ring3QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0) {
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring3QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing3Slab;
         _UserRingIncomeDetails[placementId].totalRing3Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing3Bonus += rewardRing;
         //Comment Distribution Start Here
         _PlaceInRing4(placementId);
      }
    }

    //Place In Ring 4
    function _PlaceInRing4(address user) private {
      ring4QualifierList.push(user);
      _SystemRingTotalId[0].totalRing4Id += 1;
      uint Length=ring4QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring4QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing4Slab;
         _UserRingIncomeDetails[placementId].totalRing4Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing4Bonus += rewardRing;
         //Comment Distribution Start Here
         uint noofdirect=maincontract.getTotalDirect(placementId);
         if(noofdirect>=noofDirectForRing5) {
            _PlaceInRing5(placementId);
         }
      }
    }

    //Place In Ring 5
    function _PlaceInRing5(address user) private {
      ring5QualifierList.push(user);
      _SystemRingTotalId[0].totalRing5Id += 1;
      uint Length=ring5QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring5QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing5Slab;
         _UserRingIncomeDetails[placementId].totalRing5Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing5Bonus += rewardRing;
         //Comment Distribution Start Here
         uint noofdirect=maincontract.getTotalDirect(placementId);
         if(noofdirect>=noofDirectForRing6){
          _PlaceInRing6(placementId);
         }
      }
    }

    //Place In Ring 6
    function _PlaceInRing6(address user) private {
      ring6QualifierList.push(user);
      _SystemRingTotalId[0].totalRing6Id += 1;
      uint Length=ring6QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring6QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing6Slab;
         _UserRingIncomeDetails[placementId].totalRing6Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing6Bonus += rewardRing;
         //Comment Distribution Start Here
         uint noofdirect=maincontract.getTotalDirect(placementId);
         if(noofdirect>=noofDirectForRing7){
            _PlaceInRing7(placementId);
         }
      }
    }

    //Place In Ring 7
    function _PlaceInRing7(address user) private {
      ring7QualifierList.push(user);
      _SystemRingTotalId[0].totalRing7Id += 1;
      uint Length=ring7QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring7QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing7Slab;
         _UserRingIncomeDetails[placementId].totalRing7Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing7Bonus += rewardRing;
         //Comment Distribution Start Here
         uint noofdirect=maincontract.getTotalDirect(placementId);
         if(noofdirect>=noofDirectForRing8){
          _PlaceInRing8(placementId);
         }
      }
    }

    //Place In Ring 8
    function _PlaceInRing8(address user) private {
      ring8QualifierList.push(user);
      _SystemRingTotalId[0].totalRing8Id += 1;
      uint Length=ring8QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring8QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing8Slab;
         _UserRingIncomeDetails[placementId].totalRing8Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing8Bonus += rewardRing;
         //Comment Distribution Start Here
         uint noofdirect=maincontract.getTotalDirect(placementId);
         if(noofdirect>=noofDirectForRing9){
            _PlaceInRing9(placementId);
         }
      }
    }

    //Place In Ring 9
    function _PlaceInRing9(address user) private {
      ring9QualifierList.push(user);
      _SystemRingTotalId[0].totalRing9Id += 1;
      uint Length=ring9QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring9QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing9Slab;
         _UserRingIncomeDetails[placementId].totalRing9Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing9Bonus += rewardRing;
         //Comment Distribution Start Here
         uint noofdirect=maincontract.getTotalDirect(placementId);
         if(noofdirect>=noofDirectForRing10){
            _PlaceInRing10(placementId);
         }
      }
    }

    //Place In Ring 10
    function _PlaceInRing10(address user) private {
      ring10QualifierList.push(user);
      _SystemRingTotalId[0].totalRing10Id += 1;
      uint Length=ring10QualifierList.length;
      Length -= 1;
      if(Length>0 && (Length%ringWidth)==0){
         uint Index=Length/ringWidth;
         Index -= 1;
         address placementId=ring10QualifierList[Index];
         //Comment Distribution Start Here
         uint256 rewardRing=rewardRing10Slab;
         _UserRingIncomeDetails[placementId].totalRing10Bonus += rewardRing;
         _UserIncomeDetails[placementId].totalBonus += rewardRing;
         _UserIncomeDetails[placementId].creditedWallet += rewardRing;
         _UserIncomeDetails[placementId].availableWallet += rewardRing;
         _SystemRingBonusDetails[0].totalRingBonus += rewardRing;
         _SystemRingBonusDetails[0].totalRing10Bonus += rewardRing;
         //Comment Distribution End Here
      }
    }
}