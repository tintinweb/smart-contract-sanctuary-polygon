/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IPOLYCONTRACTMAIN {
    function getUserId(address user) external view returns (uint);
    function getSponsorId(address user) external view returns (address);
}

interface IPOLYCONTRACTM6PROXYB {
    function _PlaceInM660Tree(address user,address referrer) external returns (bool);
    function _PlaceInM6120Tree(address user,address referrer) external returns (bool);
}

interface IPOLYCONTRACTM6 {
    function creditM6Income(address user,uint package,uint level) external returns (bool);
}

contract MetaOMaticM6PROXYB is  IPOLYCONTRACTM6PROXYB {

    address public contractOwner;

    //Main Contarct Start Here
    IPOLYCONTRACTMAIN public maincontract;
    IPOLYCONTRACTM6 public m6contract;

    struct M660Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
    }

    struct M6120Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
    }

    mapping (address => M660Details) public _M660Details;
    mapping (address => M6120Details) public _M6120Details;

    constructor() {
      contractOwner=0xEBc985f2964855650b8EA81f714cCb90a5843EE0;
      maincontract=IPOLYCONTRACTMAIN(0x12E7387A9160a6145498533Ef995CA937556a9d7);
      m6contract=IPOLYCONTRACTM6(0xf8Df5892D843f3b5cE785B20493cA92346021d40);
      uint TimeStamp=maincontract.getUserId(contractOwner);
      _M660Details[contractOwner].userId=TimeStamp;
      _M6120Details[contractOwner].userId=TimeStamp;
   }

    //Get Level Downline With No of Id & Investments
    function generate_report(uint package,address user,uint cycle) view public returns(uint currentrecycle,address parent,address left,address right,uint noofidinfirstlevel){
      if(package==2){
          return(_M660Details[user].currentrecycle,_M660Details[user].parent[cycle],_M660Details[user].left[cycle],_M660Details[user].right[cycle],_M660Details[user].noofidinfirstlevel[cycle]);
      }
      else if(package==3){
          return(_M6120Details[user].currentrecycle,_M6120Details[user].parent[cycle],_M6120Details[user].left[cycle],_M6120Details[user].right[cycle],_M6120Details[user].noofidinfirstlevel[cycle]);
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

    function _PlaceInM660Tree(address user,address referrer) public override returns(bool) {
       if(_M660Details[referrer].userId==0){
          referrer=contractOwner;
       }
       uint recycleno=_M660Details[referrer].currentrecycle;
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M660Details[referrer].currentrecycle+=1;
          recycleno=_M660Details[referrer].currentrecycle;
       }
       uint NoofIdInFirstLevel=_M660Details[referrer].noofidinfirstlevel[recycleno];
       uint IsUserGotPlaced=0;
       if(NoofIdInFirstLevel==2) {
         //Left Id Same Condition Check
         uint leftid1stlevelId=0;
         uint rightid1stlevelId=0;
         uint leftrecycleno=0;
         uint rightrecycleno=0;
         address leftid;
         address rightid;
         leftid=_M660Details[referrer].left[recycleno];
         leftrecycleno=_M660Details[leftid].currentrecycle;
         leftid1stlevelId=_M660Details[leftid].noofidinfirstlevel[leftrecycleno];
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM660Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,0,0);
            address parent=_M660Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,0,1);
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM660Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,0,0);
            address parent=maincontract.getSponsorId(leftid);
            m6contract.creditM6Income(parent,0,1);
         }
         else {
            rightid=_M660Details[referrer].right[recycleno];
            rightrecycleno=_M660Details[leftid].currentrecycle;
            rightid1stlevelId=_M660Details[rightid].noofidinfirstlevel[rightrecycleno];
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM660Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,0,0);
               address parent=maincontract.getSponsorId(rightid);
               m6contract.creditM6Income(parent,0,1);
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM660Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,0,0);
               address parent=_M660Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,0,1);  
            }
         }
         leftid1stlevelId=_M660Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M660Details[rightid].noofidinfirstlevel[leftrecycleno];
         uint noofid=leftid1stlevelId+rightid1stlevelId;
         if(noofid==4 && IsUserGotPlaced==1) {
             address referrersponsor=maincontract.getSponsorId(referrer);
             _M660Details[referrer].currentrecycle+=1;
             _PlaceInM660Tree(referrer,referrersponsor);
          }
          else if(noofid==4 && IsUserGotPlaced==0){
            _M660Details[referrer].currentrecycle+=1;
            _PlaceInM660Tree(user,referrer);
          }
       }
       //Below This All Is Okhey
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM660Left(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,0,0);
           address parent=_M660Details[referrer].parent[recycleno];
           m6contract.creditM6Income(parent,0,1);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM660Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,0,0);
           address parent=maincontract.getSponsorId(referrer);
           m6contract.creditM6Income(parent,0,1);
         }
       }
       return true;
    }

    function _PlaceInM660Left(address user,address placementid) private {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M660Details[user].currentrecycle;
        uint placementcurrentrecycle=_M660Details[placementid].currentrecycle;
        _M660Details[user].userId=userId;
        _M660Details[user].parent[usercurrentrecycle]=placementid;
        _M660Details[user].selfSide[usercurrentrecycle]=1;
        _M660Details[placementid].left[placementcurrentrecycle]=user;
        _M660Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM660Right(address user,address placementid) private {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M660Details[user].currentrecycle;
        uint placementcurrentrecycle=_M660Details[placementid].currentrecycle;
        _M660Details[user].userId=userId;
        _M660Details[user].parent[usercurrentrecycle]=placementid;
        _M660Details[user].selfSide[usercurrentrecycle]=2;
        _M660Details[placementid].right[placementcurrentrecycle]=user;
        _M660Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6120Tree(address user,address referrer) public override returns(bool) {
       if(_M6120Details[referrer].userId==0){
          referrer=contractOwner;
       }
       uint recycleno=_M6120Details[referrer].currentrecycle;
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M6120Details[referrer].currentrecycle+=1;
          recycleno=_M6120Details[referrer].currentrecycle;
       }
       uint NoofIdInFirstLevel=_M6120Details[referrer].noofidinfirstlevel[recycleno];
       uint IsUserGotPlaced=0;
       if(NoofIdInFirstLevel==2) {
         //Left Id Same Condition Check
         uint leftid1stlevelId=0;
         uint rightid1stlevelId=0;
         uint leftrecycleno=0;
         uint rightrecycleno=0;
         address leftid;
         address rightid;
         leftid=_M6120Details[referrer].left[recycleno];
         leftrecycleno=_M6120Details[leftid].currentrecycle;
         leftid1stlevelId=_M6120Details[leftid].noofidinfirstlevel[leftrecycleno];
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM6120Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,1,0);
            address parent=_M6120Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,1,1);
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM6120Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,1,0);
            address parent=maincontract.getSponsorId(leftid);
            m6contract.creditM6Income(parent,1,1);
         }
         else {
            rightid=_M6120Details[referrer].right[recycleno];
            rightrecycleno=_M6120Details[leftid].currentrecycle;
            rightid1stlevelId=_M6120Details[rightid].noofidinfirstlevel[rightrecycleno];
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6120Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,1,0);
               address parent=maincontract.getSponsorId(rightid);
               m6contract.creditM6Income(parent,1,1);
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6120Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,1,0);
               address parent=_M6120Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,1,1);  
            }
         }
         leftid1stlevelId=_M6120Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M6120Details[rightid].noofidinfirstlevel[leftrecycleno];
         uint noofid=leftid1stlevelId+rightid1stlevelId;
         if(noofid==4 && IsUserGotPlaced==1) {
             address referrersponsor=maincontract.getSponsorId(referrer);
             _M6120Details[referrer].currentrecycle+=1;
             _PlaceInM6120Tree(referrer,referrersponsor);
          }
          else if(noofid==4 && IsUserGotPlaced==0){
            _M6120Details[referrer].currentrecycle+=1;
            _PlaceInM6120Tree(user,referrer);
          }
       }
       //Below This All Is Okhey
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM6120Left(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,1,0);
           address parent=_M6120Details[referrer].parent[recycleno];
           m6contract.creditM6Income(parent,1,1);
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6120Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,1,0);
           address parent=maincontract.getSponsorId(referrer);
           m6contract.creditM6Income(parent,1,1);
         }
       }
       return true;
    }

   function _PlaceInM6120Left(address user,address placementid) internal {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M6120Details[user].currentrecycle;
        uint placementcurrentrecycle=_M6120Details[placementid].currentrecycle;
        _M6120Details[user].userId=userId;
        _M6120Details[user].parent[usercurrentrecycle]=placementid;
        _M6120Details[user].selfSide[usercurrentrecycle]=1;
        _M6120Details[placementid].left[placementcurrentrecycle]=user;
        _M6120Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
   }

   function _PlaceInM6120Right(address user,address placementid) internal {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M6120Details[user].currentrecycle;
        uint placementcurrentrecycle=_M6120Details[placementid].currentrecycle;
        _M6120Details[user].userId=userId;
        _M6120Details[user].parent[usercurrentrecycle]=placementid;
        _M6120Details[user].selfSide[usercurrentrecycle]=2;
        _M6120Details[placementid].right[placementcurrentrecycle]=user;
        _M6120Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
   }
}