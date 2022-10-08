/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IPOLYCONTRACTMAIN {
    function getUserId(address user) external view returns (uint);
    function getSponsorId(address user) external view returns (address);
}

interface IPOLYCONTRACTM6PROXYA {
    function _PlaceInM615Tree(address user,address referrer) external returns (bool);
    function _PlaceInM630Tree(address user,address referrer) external returns (bool);
}

interface IPOLYCONTRACTM6 {
    function creditM6Income(address user,uint package,uint level,uint IsFreshId) external returns (bool);
}

contract MetaOMaticM6PROXYA is  IPOLYCONTRACTM6PROXYA {

    address public contractOwner;

    uint recycleno;
    uint NoofIdInFirstLevel;
    uint IsUserGotPlaced;
	 uint leftid1stlevelId;
    uint rightid1stlevelId;
    uint leftrecycleno;
    uint rightrecycleno;
    address leftid;
    address rightid;
	 uint userId;
    uint usercurrentrecycle;
    uint placementcurrentrecycle;
    uint IsFreshId;
    uint firstlevelcount;
    uint secondlevelcount;
    uint noofid;


    //Main Contarct Start Here
    IPOLYCONTRACTMAIN public maincontract;
    IPOLYCONTRACTM6 public m6contract;

    struct M615Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M630Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    mapping (address => M615Details) public _M615Details;
    mapping (address => M630Details) public _M630Details;

    constructor() {
      contractOwner=0x4697b20B0dc6619C2625050B82F7eFce88536dFA;
      maincontract=IPOLYCONTRACTMAIN(0x87487525C07F0e2d728ea03c1d87b3E7b358bFD5);
      m6contract=IPOLYCONTRACTM6(0x8658504c0B36a53ddd1FF17a04b4bCF6dD167944);
      uint TimeStamp=maincontract.getUserId(contractOwner);
      _M615Details[contractOwner].userId=TimeStamp;
      _M630Details[contractOwner].userId=TimeStamp;
   }

   //Get Level Downline With No of Id & Investments
    function generate_report(uint package,address user,uint cycle) view public returns(uint currentrecycle,address parent,address left,address right,uint noofidinfirstlevel,uint noofidinsecondlevel){
      if(package==0){
          return(_M615Details[user].currentrecycle,_M615Details[user].parent[cycle],_M615Details[user].left[cycle],_M615Details[user].right[cycle],_M615Details[user].noofidinfirstlevel[cycle],_M615Details[user].noofidinsecondlevel[cycle]);
      }
      else if(package==1){
          return(_M630Details[user].currentrecycle,_M630Details[user].parent[cycle],_M630Details[user].left[cycle],_M630Details[user].right[cycle],_M630Details[user].noofidinfirstlevel[cycle],_M630Details[user].noofidinsecondlevel[cycle]);
      }
    }
 
    //Admin Can Recover Lost Matic
    function _verifyOutMatic(uint256 amount) public {
        require(msg.sender == contractOwner, "Only Admin Can ?");
        _SafeTransfer(payable(contractOwner),amount);
    }

   function _SafeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
      amount = (_amount < address(this).balance) ? _amount : address(this).balance;
      if(_to!=address(0) && _to!=0x0000000000000000000000000000000000000000) {
        _to.transfer(amount);
      }
   }

   function _PlaceInM615Tree(address user,address referrer) public override returns(bool) {
       IsFreshId=0;
       if(_M615Details[user].userId==0){
           IsFreshId=1;
       }
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M615Details[referrer].currentrecycle+=1;
       }
       else {
         if(_M615Details[referrer].userId==0){
            referrer=contractOwner;
         }
       }

       recycleno=_M615Details[referrer].currentrecycle;
       NoofIdInFirstLevel=_M615Details[referrer].noofidinfirstlevel[recycleno];
       IsUserGotPlaced=0;

       if(NoofIdInFirstLevel==2) {

         leftid=_M615Details[referrer].left[recycleno];
         leftrecycleno=_M615Details[leftid].currentrecycle;
         leftid1stlevelId=_M615Details[leftid].noofidinfirstlevel[leftrecycleno];

         rightid=_M615Details[referrer].right[recycleno];
         rightrecycleno=_M615Details[rightid].currentrecycle;
         rightid1stlevelId=_M615Details[rightid].noofidinfirstlevel[rightrecycleno];

         //Left Id Same Condition Check
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM615Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,0,0,IsFreshId);
            address parent=_M615Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,0,1,IsFreshId);
            _M615Details[parent].noofidinsecondlevel[recycleno]+=1;
         }

         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM615Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,0,0,IsFreshId);
            address parent=_M615Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(parent);
            m6contract.creditM6Income(sponsor,0,1,IsFreshId);
            _M615Details[parent].noofidinsecondlevel[recycleno]+=1;
         }

         else {
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM615Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,0,0,IsFreshId);
               address parent=_M615Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(parent);
               m6contract.creditM6Income(sponsor,0,1,IsFreshId);
               _M615Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM615Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,0,0,IsFreshId);
               address parent=_M615Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,0,1,IsFreshId); 
               _M615Details[parent].noofidinsecondlevel[recycleno]+=1; 
            }
         }

         leftid1stlevelId=_M615Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M615Details[rightid].noofidinfirstlevel[rightrecycleno];

         noofid=leftid1stlevelId+rightid1stlevelId;

         if(noofid==4 && IsUserGotPlaced==1) {
             address referrersponsor=maincontract.getSponsorId(referrer);
             _M615Details[referrer].currentrecycle+=1;
             _PlaceInM615Tree(referrer,referrersponsor);
          }

          else if(noofid==4 && IsUserGotPlaced==0){
            _M615Details[referrer].currentrecycle+=1;
            _PlaceInM615Tree(user,referrer);
          }

       }
       //Below This All Is Okhey
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM615Left(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,0,0,IsFreshId);
           address parent=_M615Details[referrer].parent[recycleno];
           uint referralside=_M615Details[referrer].selfSide[recycleno];
           if(referralside==1)
           {
              m6contract.creditM6Income(parent,0,1,IsFreshId);
           }
           else {
              address sponsor=maincontract.getSponsorId(parent);
              m6contract.creditM6Income(sponsor,0,1,IsFreshId);
           }
           _M615Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(NoofIdInFirstLevel==1) {
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM615Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,0,0,IsFreshId);
           address parent=_M615Details[referrer].parent[recycleno];
           uint referralside=_M615Details[referrer].selfSide[recycleno];  
           address sponsor=maincontract.getSponsorId(parent);
           if(referralside==2)
           {
              m6contract.creditM6Income(parent,0,1,IsFreshId);
           }
           else {
              m6contract.creditM6Income(sponsor,0,1,IsFreshId);
           }
           _M615Details[parent].noofidinsecondlevel[recycleno]+=1;
           firstlevelcount=_M615Details[parent].noofidinfirstlevel[recycleno];
           secondlevelcount=_M615Details[parent].noofidinsecondlevel[recycleno];
           noofid=firstlevelcount+secondlevelcount;
           if(noofid==6) {            
             _M615Details[parent].currentrecycle+=1;
             _PlaceInM615Tree(parent,sponsor);
           }
         }
       }
       return true;
   }

    function _PlaceInM615Left(address user,address placementid) private {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M615Details[user].currentrecycle;
         placementcurrentrecycle=_M615Details[placementid].currentrecycle;
        _M615Details[user].userId=userId;
        _M615Details[user].parent[usercurrentrecycle]=placementid;
        _M615Details[user].selfSide[usercurrentrecycle]=1;
        _M615Details[placementid].left[placementcurrentrecycle]=user;
        _M615Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM615Right(address user,address placementid) private {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M615Details[user].currentrecycle;
         placementcurrentrecycle=_M615Details[placementid].currentrecycle;
        _M615Details[user].userId=userId;
        _M615Details[user].parent[usercurrentrecycle]=placementid;
        _M615Details[user].selfSide[usercurrentrecycle]=2;
        _M615Details[placementid].right[placementcurrentrecycle]=user;
        _M615Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM630Tree(address user,address referrer) public override returns(bool) {
       IsFreshId=0;
       if(_M630Details[user].userId==0){
           IsFreshId=1;
       }
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M630Details[referrer].currentrecycle+=1;
       }
       else{
         if(_M630Details[referrer].userId==0){
           referrer=contractOwner;
         }
       }
       recycleno=_M630Details[referrer].currentrecycle;
       NoofIdInFirstLevel=_M630Details[referrer].noofidinfirstlevel[recycleno];
       IsUserGotPlaced=0;
       if(NoofIdInFirstLevel==2) {
         leftid=_M630Details[referrer].left[recycleno];
         leftrecycleno=_M630Details[leftid].currentrecycle;
         leftid1stlevelId=_M630Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid=_M630Details[referrer].right[recycleno];
         rightrecycleno=_M630Details[rightid].currentrecycle;
         rightid1stlevelId=_M630Details[rightid].noofidinfirstlevel[rightrecycleno];
         //Left Id Same Condition Check
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM630Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,1,0,IsFreshId);
            address parent=_M630Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,1,1,IsFreshId);
            _M630Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM630Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,1,0,IsFreshId);
            address parent=_M630Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(parent);
            m6contract.creditM6Income(sponsor,1,1,IsFreshId);     
            _M630Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else {
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM630Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,1,0,IsFreshId);
               address parent=_M630Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(parent);
               m6contract.creditM6Income(sponsor,1,1,IsFreshId);
               _M630Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM630Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,1,0,IsFreshId);
               address parent=_M630Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,1,1,IsFreshId);  
               _M630Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
         }
         leftid1stlevelId=_M630Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M630Details[rightid].noofidinfirstlevel[rightrecycleno];
         noofid=leftid1stlevelId+rightid1stlevelId;
         if(noofid==4 && IsUserGotPlaced==1) {
             address referrersponsor=maincontract.getSponsorId(referrer);            
             _M630Details[referrer].currentrecycle+=1;
             _PlaceInM630Tree(referrer,referrersponsor);
          }
          else if(noofid==4 && IsUserGotPlaced==0){
            _M630Details[referrer].currentrecycle+=1;
            _PlaceInM630Tree(user,referrer);
          }
       }
       //Below This All Is Okhey
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0) {
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM630Left(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,1,0,IsFreshId);
           address parent=_M630Details[referrer].parent[recycleno];
           uint referralside=_M630Details[referrer].selfSide[recycleno];
           if(referralside==1)
           {
              m6contract.creditM6Income(parent,1,1,IsFreshId);
           }
           else {
              address sponsor=maincontract.getSponsorId(parent);
              m6contract.creditM6Income(sponsor,1,1,IsFreshId);
           }
           _M630Details[parent].noofidinsecondlevel[recycleno]+=1;   
         }
         else if(NoofIdInFirstLevel==1) {
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM630Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,1,0,IsFreshId);
           address parent=_M630Details[referrer].parent[recycleno];
           uint referralside=_M630Details[referrer].selfSide[recycleno];       
           address sponsor=maincontract.getSponsorId(parent);
           if(referralside==2)
           {
              m6contract.creditM6Income(parent,1,1,IsFreshId);
           }
           else {
              m6contract.creditM6Income(sponsor,1,1,IsFreshId);
           }
           _M630Details[parent].noofidinsecondlevel[recycleno]+=1;
           firstlevelcount=_M630Details[parent].noofidinfirstlevel[recycleno];
           secondlevelcount=_M630Details[parent].noofidinsecondlevel[recycleno];
           noofid=firstlevelcount+secondlevelcount;
           if(noofid==6) {           
             _M630Details[parent].currentrecycle+=1;
             _PlaceInM630Tree(parent,sponsor);
           }
         }
       }
      return true;
   }

   function _PlaceInM630Left(address user,address placementid) internal {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M630Details[user].currentrecycle;
         placementcurrentrecycle=_M630Details[placementid].currentrecycle;
        _M630Details[user].userId=userId;
        _M630Details[user].parent[usercurrentrecycle]=placementid;
        _M630Details[user].selfSide[usercurrentrecycle]=1;
        _M630Details[placementid].left[placementcurrentrecycle]=user;
        _M630Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
   }

   function _PlaceInM630Right(address user,address placementid) internal {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M630Details[user].currentrecycle;
         placementcurrentrecycle=_M630Details[placementid].currentrecycle;
        _M630Details[user].userId=userId;
        _M630Details[user].parent[usercurrentrecycle]=placementid;
        _M630Details[user].selfSide[usercurrentrecycle]=2;
        _M630Details[placementid].right[placementcurrentrecycle]=user;
        _M630Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
   }
}