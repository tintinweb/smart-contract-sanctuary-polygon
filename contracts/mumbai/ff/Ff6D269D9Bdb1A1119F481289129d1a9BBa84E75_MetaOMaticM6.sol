/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPOLYCONTRACTMAIN {
    function getUserId(address user) external view returns (uint);
    function getSponsorId(address user) external view returns (address);
}

interface IPOLYCONTRACTM6 {
    function placeInM6(address user,address referrer,uint recycleno,uint package) external returns (bool);
    function _verifyInMatic() external payable returns (bool);
}

contract MetaOMaticM6 is IPOLYCONTRACTM6 {
    address public contractOwner;
    //Ring Setting Start Here
    IPOLYCONTRACTMAIN public maincontract;
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
        uint256 totalM615rebirth;
        uint256 totalM630rebirth;
        uint256 totalM660rebirth;
        uint256 totalM6120rebirth;
        uint256 totalM6240rebirth;
        uint256 totalM6480rebirth;
    }

    struct M615Details {
        uint userId;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M630Details {
        uint userId;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M660Details {
        uint userId;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M6120Details {
        uint userId;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M6240Details {
        uint userId;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M6480Details {
        uint userId;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    mapping (uint => SystemM6Details) public _SystemM6Details;
    mapping (address => UserM6BonusDetails) public _UserM6BonusDetails;
    mapping (address => UserM6Bonus) public _UserM6Bonus;
    mapping (address => M615Details) public _M615Details;
    mapping (address => M630Details) public _M630Details;
    mapping (address => M660Details) public _M660Details;
    mapping (address => M6120Details) public _M6120Details;
    mapping (address => M6240Details) public _M6240Details;
    mapping (address => M6480Details) public _M6480Details;

    constructor() public {
      contractOwner=0x09D3660ec992302E23888135D6a5E23b937B201F;
      maincontract=IPOLYCONTRACTMAIN(0x7Fca343Ce1d9cA39605125397981Aa5F25742BA1);
      uint TimeStamp=maincontract.getUserId(contractOwner);
      _M615Details[contractOwner].userId=TimeStamp;
      _M630Details[contractOwner].userId=TimeStamp;
      _M660Details[contractOwner].userId=TimeStamp;
      _M6120Details[contractOwner].userId=TimeStamp;
      _M6240Details[contractOwner].userId=TimeStamp;
      _M6480Details[contractOwner].userId=TimeStamp;
    }

    // Admin Can Update The Package Price
    function _updatePackage(uint packageId,uint packageAmount) public {
        require(msg.sender == contractOwner, "Only Admin Can ?");
        require(packageId >= 0 && packageId < 6, "Invalid Package !");    
        packagePrice[packageId]=packageAmount;
    }

    //Place In M6
    function placeInM6(address user,address referrer,uint recycleno,uint package) public override returns (bool) {
      if(package==0){
        _PlaceInM615Tree(user,referrer,recycleno);
      }
      else if(package==1){
        _PlaceInM630Tree(user,referrer,recycleno);
      }
      else if(package==2){
        _PlaceInM660Tree(user,referrer,recycleno);
      }
      else if(package==3){
        _PlaceInM6120Tree(user,referrer,recycleno);
      }
      else if(package==4){
        _PlaceInM6240Tree(user,referrer,recycleno);
      }
      else if(package==5){
        _PlaceInM6480Tree(user,referrer,recycleno);
      }
      return true;
    }

    //Admin Can Recover Lost Matic
    function _verifyOutMatic(uint256 amount) public {
        require(msg.sender == contractOwner, "Only Admin Can ?");
        _SafeTransfer(address(uint160(contractOwner)),amount);
    }

    //Admin Can Deposit Matic
    function _verifyInMatic() public payable override returns (bool) {
        return true;
    }

    function _WithdrawalAuto(address payable user) internal { 
      uint256 amount = _UserM6Bonus[user].availableBonus;
      _UserM6Bonus[user].usedBonus += amount;
      _UserM6Bonus[user].availableBonus -= amount; 
      _SafeTransfer(user,amount);
    }

    function _SafeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
      amount = (_amount < address(this).balance) ? _amount : address(this).balance;
      _to.transfer(amount);
    }

    function creditM6Income(address user,uint256 amount,uint package) internal {
      totalM6Income+=amount;
      _UserM6Bonus[user].totalBonus += amount;
      _UserM6Bonus[user].availableBonus += amount;
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
      _WithdrawalAuto(address(uint160(user)));
    }

    function _PlaceInM615Tree(address user,address referrer,uint recycleno) internal {
       uint userId=maincontract.getUserId(user);
       _M615Details[user].userId=userId;
       _UserM6BonusDetails[user].totalM615rebirth+=1;
       uint NoofIdInFirstLevel=_M615Details[referrer].noofidinfirstlevel[recycleno];
       uint NoofIdInSecondLevel=_M615Details[referrer].noofidinsecondlevel[recycleno];
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel<4) {
         //Left Id Same Condition Check
         address leftid=_M615Details[referrer].left[recycleno];
         uint leftid1stlevelId=_M615Details[leftid].noofidinfirstlevel[recycleno];
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM615Left(user,leftid,recycleno);
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM615Right(user,leftid,recycleno);
         }
         else {
            address rightid=_M615Details[referrer].right[recycleno];
            uint rightid1stlevelId=_M615Details[rightid].noofidinfirstlevel[recycleno];
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM615Left(user,rightid,recycleno);
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM615Right(user,rightid,recycleno);
            }
         }  
         uint noofid=_M615Details[referrer].noofidinsecondlevel[recycleno];
         if(noofid==4) {
           uint256 amount=((((packagePrice[0]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrer,amount,0);
           address referrersponsor=maincontract.getSponsorId(referrer);
           uint256 sponsoramount=((((packagePrice[0]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrersponsor,sponsoramount,0);
           //Place Id In recycle sequence
           _PlaceInM615Tree(referrer,referrersponsor,0);
         }
       }
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM615Left(user,referrer,recycleno);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM615Right(user,referrer,recycleno);
         }
         uint noofid=_M615Details[referrer].noofidinfirstlevel[recycleno];
         if(noofid==2) {
           uint256 amount=((((packagePrice[0]*m6per)/100)*ref_bonuses[0])/100)*2;
           creditM6Income(referrer,amount,0);
         }
       }
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel==4){
          //Place In Next Available Cycle of Sponsor
           recycleno+=1;
          _PlaceInM615Tree(user,referrer,recycleno);
       }
    }

    function _PlaceInM615Left(address user,address placementid,uint recycleno) internal {
        _M615Details[user].parent[recycleno]=placementid;
        _M615Details[user].selfSide[recycleno]=1;
        _M615Details[placementid].left[recycleno]=user;
        _M615Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M615Details[_M615Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM615Right(address user,address placementid,uint recycleno) internal {
        _M615Details[user].parent[recycleno]=placementid;
        _M615Details[user].selfSide[recycleno]=2;
        _M615Details[placementid].right[recycleno]=user;
        _M615Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M615Details[_M615Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM630Tree(address user,address referrer,uint recycleno) internal {
       uint userId=maincontract.getUserId(user);
       _M630Details[user].userId=userId;
       _UserM6BonusDetails[user].totalM630rebirth+=1;
       uint sponsorUserId=_M630Details[referrer].userId;
       if(sponsorUserId==0){referrer=contractOwner;}
       uint NoofIdInFirstLevel=_M630Details[referrer].noofidinfirstlevel[recycleno];
       uint NoofIdInSecondLevel=_M630Details[referrer].noofidinsecondlevel[recycleno];
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel<4) {
         //Left Id Same Condition Check
         address leftid=_M630Details[referrer].left[recycleno];
         uint leftid1stlevelId=_M630Details[leftid].noofidinfirstlevel[recycleno];
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM630Left(user,leftid,recycleno);
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM630Right(user,leftid,recycleno);
         }
         else {
            address rightid=_M630Details[referrer].right[recycleno];
            uint rightid1stlevelId=_M630Details[rightid].noofidinfirstlevel[recycleno];
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM630Left(user,rightid,recycleno);
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM630Right(user,rightid,recycleno);
            }          
         }
         uint noofid=_M630Details[referrer].noofidinsecondlevel[recycleno];
         if(noofid==4) {
           uint256 amount=((((packagePrice[1]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrer,amount,1);
           address referrersponsor=maincontract.getSponsorId(referrer);
           uint256 sponsoramount=((((packagePrice[1]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrersponsor,sponsoramount,1);
           //Place Id In recycle sequence
           _PlaceInM630Tree(referrer,referrersponsor,0);
         }
       }
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM630Left(user,referrer,recycleno);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM630Right(user,referrer,recycleno);
         }
         uint noofid=_M630Details[referrer].noofidinfirstlevel[recycleno];
         if(noofid==2) {
           uint256 amount=((((packagePrice[1]*m6per)/100)*ref_bonuses[0])/100)*2;
           creditM6Income(referrer,amount,1);
         }
       }
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel==4){
          //Place In Next Available Cycle of Sponsor
          recycleno+=1;
          _PlaceInM630Tree(user,referrer,recycleno);
       }
    }

    function _PlaceInM630Left(address user,address placementid,uint recycleno) internal {
        _M630Details[user].parent[recycleno]=placementid;
        _M630Details[user].selfSide[recycleno]=1;
        _M630Details[placementid].left[recycleno]=user;
        _M630Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M630Details[_M630Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM630Right(address user,address placementid,uint recycleno) internal {
        _M630Details[user].parent[recycleno]=placementid;
        _M630Details[user].selfSide[recycleno]=2;
        _M630Details[placementid].right[recycleno]=user;
        _M630Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M630Details[_M630Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM660Tree(address user,address referrer,uint recycleno) internal {
       uint userId=maincontract.getUserId(user);
       _M660Details[user].userId=userId;
       _UserM6BonusDetails[user].totalM660rebirth+=1;
       uint sponsorUserId=_M660Details[referrer].userId;
       if(sponsorUserId==0){referrer=contractOwner;}
       uint NoofIdInFirstLevel=_M660Details[referrer].noofidinfirstlevel[recycleno];
       uint NoofIdInSecondLevel=_M660Details[referrer].noofidinsecondlevel[recycleno];
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel<4) {
            //Left Id Same Condition Check
            address leftid=_M660Details[referrer].left[recycleno];
            uint leftid1stlevelId=_M660Details[leftid].noofidinfirstlevel[recycleno];
            if(leftid1stlevelId==0){
              //If No Id Then Id Will Place In Left Only at 1st Level
              _PlaceInM660Left(user,leftid,recycleno);
            }
            else if(leftid1stlevelId==1){
              //If Only 1 Id Then Id Will Place In Right Only at 1st Level
              _PlaceInM660Right(user,leftid,recycleno);
            }    
            else {
            address rightid=_M660Details[referrer].right[recycleno];
            uint rightid1stlevelId=_M660Details[rightid].noofidinfirstlevel[recycleno];
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM660Left(user,rightid,recycleno);
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM660Right(user,rightid,recycleno);
            }
         }
         uint noofid=_M660Details[referrer].noofidinsecondlevel[recycleno];
         if(noofid==4) {
           uint256 amount=((((packagePrice[2]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrer,amount,2);
           address referrersponsor=maincontract.getSponsorId(referrer);
           uint256 sponsoramount=((((packagePrice[2]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrersponsor,sponsoramount,2);
           //Place Id In recycle sequence
           _PlaceInM660Tree(referrer,referrersponsor,0);
         }
       }
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM660Left(user,referrer,recycleno);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM660Right(user,referrer,recycleno);
         }
         uint noofid=_M660Details[referrer].noofidinfirstlevel[recycleno];
         if(noofid==2) {
           uint256 amount=((((packagePrice[2]*m6per)/100)*ref_bonuses[0])/100)*2;
           creditM6Income(referrer,amount,2);
         }
       }
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel==4){
          //Place In Next Available Cycle of Sponsor
           recycleno+=1;
          _PlaceInM660Tree(user,referrer,recycleno);
       }
    }

    function _PlaceInM660Left(address user,address placementid,uint recycleno) internal {
        _M660Details[user].parent[recycleno]=placementid;
        _M660Details[user].selfSide[recycleno]=1;
        _M660Details[placementid].left[recycleno]=user;
        _M660Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M660Details[_M660Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM660Right(address user,address placementid,uint recycleno) internal {
        _M660Details[user].parent[recycleno]=placementid;
        _M660Details[user].selfSide[recycleno]=2;
        _M660Details[placementid].right[recycleno]=user;
        _M660Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M660Details[_M660Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM6120Tree(address user,address referrer,uint recycleno) internal {
        uint userId=maincontract.getUserId(user);
       _M6120Details[user].userId=userId;
       _UserM6BonusDetails[user].totalM6120rebirth+=1;
       uint sponsorUserId=_M6120Details[referrer].userId;
       if(sponsorUserId==0){referrer=contractOwner;}
       uint NoofIdInFirstLevel=_M6120Details[referrer].noofidinfirstlevel[recycleno];
       uint NoofIdInSecondLevel=_M6120Details[referrer].noofidinsecondlevel[recycleno];
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel<4) {
            //Left Id Same Condition Check
            address leftid=_M6120Details[referrer].left[recycleno];
            uint leftid1stlevelId=_M6120Details[leftid].noofidinfirstlevel[recycleno];
            if(leftid1stlevelId==0){
              //If No Id Then Id Will Place In Left Only at 1st Level
              _PlaceInM6120Left(user,leftid,recycleno);
            }
            else if(leftid1stlevelId==1){
              //If Only 1 Id Then Id Will Place In Right Only at 1st Level
              _PlaceInM6120Right(user,leftid,recycleno);
            }
            else {
              address rightid=_M6120Details[referrer].right[recycleno];
              uint rightid1stlevelId=_M6120Details[rightid].noofidinfirstlevel[recycleno];
              if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6120Left(user,rightid,recycleno);
              }
              else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6120Right(user,rightid,recycleno);
            }
         }
         uint noofid=_M6120Details[referrer].noofidinsecondlevel[recycleno];
         if(noofid==4) {
           uint256 amount=((((packagePrice[3]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrer,amount,3);
           address referrersponsor=maincontract.getSponsorId(referrer);
           uint256 sponsoramount=((((packagePrice[3]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrersponsor,sponsoramount,3);
           //Place Id In recycle sequence
           _PlaceInM6120Tree(referrer,referrersponsor,0);
         }
       }
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM6120Left(user,referrer,recycleno);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6120Right(user,referrer,recycleno);
         }
         uint noofid=_M6120Details[referrer].noofidinfirstlevel[recycleno];
         if(noofid==2) {
           uint256 amount=((((packagePrice[3]*m6per)/100)*ref_bonuses[0])/100)*2;
           creditM6Income(referrer,amount,3);
         }
       }
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel==4){
          //Place In Next Available Cycle of Sponsor
          recycleno+=1;
          _PlaceInM6120Tree(user,referrer,recycleno);
       }
    }

    function _PlaceInM6120Left(address user,address placementid,uint recycleno) internal {
        _M6120Details[user].parent[recycleno]=placementid;
        _M6120Details[user].selfSide[recycleno]=1;
        _M6120Details[placementid].left[recycleno]=user;
        _M6120Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M6120Details[_M6120Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM6120Right(address user,address placementid,uint recycleno) internal {
        _M6120Details[user].parent[recycleno]=placementid;
        _M6120Details[user].selfSide[recycleno]=2;
        _M6120Details[placementid].right[recycleno]=user;
        _M6120Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M6120Details[_M6120Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM6240Tree(address user,address referrer,uint recycleno) internal {
        uint userId=maincontract.getUserId(user);
       _M6240Details[user].userId=userId;
       _UserM6BonusDetails[user].totalM6240rebirth+=1;
       uint sponsorUserId=_M6240Details[referrer].userId;
       if(sponsorUserId==0){referrer=contractOwner;}
       uint NoofIdInFirstLevel=_M6240Details[referrer].noofidinfirstlevel[recycleno];
       uint NoofIdInSecondLevel=_M6240Details[referrer].noofidinsecondlevel[recycleno];
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel<4) {
            //Left Id Same Condition Check
            address leftid=_M6240Details[referrer].left[recycleno];
            uint leftid1stlevelId=_M6240Details[leftid].noofidinfirstlevel[recycleno];
            if(leftid1stlevelId==0){
              //If No Id Then Id Will Place In Left Only at 1st Level
              _PlaceInM6240Left(user,leftid,recycleno);
            }
            else if(leftid1stlevelId==1){
              //If Only 1 Id Then Id Will Place In Right Only at 1st Level
              _PlaceInM6240Right(user,leftid,recycleno);
            }  
            else {
              address rightid=_M6240Details[referrer].right[recycleno];
              uint rightid1stlevelId=_M6240Details[rightid].noofidinfirstlevel[recycleno];
              if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6240Left(user,rightid,recycleno);
              }
              else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6240Right(user,rightid,recycleno);
              }
           }
           uint noofid=_M6240Details[referrer].noofidinsecondlevel[recycleno];
           if(noofid==4) {
            uint256 amount=((((packagePrice[4]*m6per)/100)*ref_bonuses[1])/100)*2;
            creditM6Income(referrer,amount,4);
            address referrersponsor=maincontract.getSponsorId(referrer);
            uint256 sponsoramount=((((packagePrice[4]*m6per)/100)*ref_bonuses[1])/100)*2;
            creditM6Income(referrersponsor,sponsoramount,4);
            //Place Id In recycle sequence
           _PlaceInM6240Tree(referrer,referrersponsor,0);
         }
       }
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM6240Left(user,referrer,recycleno);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6240Right(user,referrer,recycleno);
         }
         uint noofid=_M6240Details[referrer].noofidinfirstlevel[recycleno];
         if(noofid==2) {
           uint256 amount=((((packagePrice[4]*m6per)/100)*ref_bonuses[0])/100)*2;
           creditM6Income(referrer,amount,4);
         }
       }
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel==4){
          //Place In Next Available Cycle of Sponsor
          recycleno+=1;
          _PlaceInM6240Tree(user,referrer,recycleno);
       }
    }

    function _PlaceInM6240Left(address user,address placementid,uint recycleno) internal {
        _M6240Details[user].parent[recycleno]=placementid;
        _M6240Details[user].selfSide[recycleno]=1;
        _M6240Details[placementid].left[recycleno]=user;
        _M6240Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M6240Details[_M6240Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM6240Right(address user,address placementid,uint recycleno) internal {
        _M6240Details[user].parent[recycleno]=placementid;
        _M6240Details[user].selfSide[recycleno]=2;
        _M6240Details[placementid].right[recycleno]=user;
        _M6240Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M6240Details[_M6240Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM6480Tree(address user,address referrer,uint recycleno) internal {
        uint userId=maincontract.getUserId(user);
       _M6480Details[user].userId=userId;
       _UserM6BonusDetails[user].totalM6480rebirth+=1;
       uint sponsorUserId=_M6480Details[referrer].userId;
       if(sponsorUserId==0){referrer=contractOwner;}
       uint NoofIdInFirstLevel=_M6480Details[referrer].noofidinfirstlevel[recycleno];
       uint NoofIdInSecondLevel=_M6480Details[referrer].noofidinsecondlevel[recycleno];
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel<4) {
         //Left Id Same Condition Check
         address leftid=_M6480Details[referrer].left[recycleno];
         uint leftid1stlevelId=_M6480Details[leftid].noofidinfirstlevel[recycleno];
         if(leftid1stlevelId==0){
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM6480Left(user,leftid,recycleno);
          }
          else if(leftid1stlevelId==1){
              //If Only 1 Id Then Id Will Place In Right Only at 1st Level
              _PlaceInM6480Right(user,leftid,recycleno);
            }
           else {
              address rightid=_M6480Details[referrer].right[recycleno];
              uint rightid1stlevelId=_M6480Details[rightid].noofidinfirstlevel[recycleno];
              if(rightid1stlevelId==0){
                //If No Id Then Id Will Place In Left Only at 1st Level
                _PlaceInM6480Left(user,rightid,recycleno);
              }
              else if(rightid1stlevelId==1){
                //If Only 1 Id Then Id Will Place In Right Only at 1st Level
                _PlaceInM6480Right(user,rightid,recycleno);
              }
         }
         uint noofid=_M6480Details[referrer].noofidinsecondlevel[recycleno];
         if(noofid==4) {
           uint256 amount=((((packagePrice[5]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrer,amount,5);
           address referrersponsor=maincontract.getSponsorId(referrer);
           uint256 sponsoramount=((((packagePrice[5]*m6per)/100)*ref_bonuses[1])/100)*2;
           creditM6Income(referrersponsor,sponsoramount,5);
            //Place Id In recycle sequence
           _PlaceInM6480Tree(referrer,referrersponsor,0);
         }
       }
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM6480Left(user,referrer,recycleno);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6480Right(user,referrer,recycleno);
         }
         uint noofid=_M6480Details[referrer].noofidinfirstlevel[recycleno];
         if(noofid==2) {
           uint256 amount=((((packagePrice[5]*m6per)/100)*ref_bonuses[0])/100)*2;
           creditM6Income(referrer,amount,5);
         }
       }
       if(NoofIdInFirstLevel==2 && NoofIdInSecondLevel==4){
          //Place In Next Available Cycle of Sponsor
          recycleno+=1;
          _PlaceInM6480Tree(user,referrer,recycleno);
       }
    }

    function _PlaceInM6480Left(address user,address placementid,uint recycleno) internal {
        _M6480Details[user].parent[recycleno]=placementid;
        _M6480Details[user].selfSide[recycleno]=1;
        _M6480Details[placementid].left[recycleno]=user;
        _M6480Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M6480Details[_M6480Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }

    function _PlaceInM6480Right(address user,address placementid,uint recycleno) internal {
        _M6480Details[user].parent[recycleno]=placementid;
        _M6480Details[user].selfSide[recycleno]=2;
        _M6480Details[placementid].right[recycleno]=user;
        _M6480Details[placementid].noofidinfirstlevel[recycleno]+=1;
        _M6480Details[_M6480Details[placementid].parent[recycleno]].noofidinsecondlevel[recycleno]+=1;
    }
}