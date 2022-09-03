/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IPOLYCONTRACTMAIN {
    function getUserId(address user) external view returns (uint);
    function getSponsorId(address user) external view returns (address);
}

interface IPOLYCONTRACTM6PROXYC {
    function _PlaceInM6240Tree(address user,address referrer) external returns (bool);
    function _PlaceInM6480Tree(address user,address referrer) external returns (bool);
}

interface IPOLYCONTRACTM6 {
    function creditM6Income(address user,uint package,uint level) external returns (bool);
}

contract MetaOMaticM6PROXYC is  IPOLYCONTRACTM6PROXYC {

    address public contractOwner;

    //Main Contarct Start Here
    IPOLYCONTRACTMAIN public maincontract;
    IPOLYCONTRACTM6 public m6contract;

    struct M6240Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M6480Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    mapping (address => M6240Details) public _M6240Details;
    mapping (address => M6480Details) public _M6480Details;

    constructor() {
      contractOwner=0xEBc985f2964855650b8EA81f714cCb90a5843EE0;
      maincontract=IPOLYCONTRACTMAIN(0x92F44Ea7C922914a7f67d67C4010109495F9a464);
      m6contract=IPOLYCONTRACTM6(0x786dB7312E02DaA288922D5D11E93B93a800803A);
      uint TimeStamp=maincontract.getUserId(contractOwner);
      _M6240Details[contractOwner].userId=TimeStamp;
      _M6480Details[contractOwner].userId=TimeStamp;
   }

    //Get Level Downline With No of Id & Investments
    function generate_report(uint package,address user,uint cycle) view public returns(uint currentrecycle,address parent,address left,address right,uint noofidinfirstlevel){
      if(package==4){
          return(_M6240Details[user].currentrecycle,_M6240Details[user].parent[cycle],_M6240Details[user].left[cycle],_M6240Details[user].right[cycle],_M6240Details[user].noofidinfirstlevel[cycle]);
      }
      else if(package==5){
          return(_M6480Details[user].currentrecycle,_M6480Details[user].parent[cycle],_M6480Details[user].left[cycle],_M6480Details[user].right[cycle],_M6480Details[user].noofidinfirstlevel[cycle]);
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

    function _PlaceInM6240Tree(address user,address referrer) public override returns(bool) {
       if(_M6240Details[referrer].userId==0){
          referrer=contractOwner;
       }
       uint recycleno=_M6240Details[referrer].currentrecycle;
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M6240Details[referrer].currentrecycle+=1;
          recycleno=_M6240Details[referrer].currentrecycle;
       }
       uint NoofIdInFirstLevel=_M6240Details[referrer].noofidinfirstlevel[recycleno];
       uint IsUserGotPlaced=0;
       if(NoofIdInFirstLevel==2) {
         //Left Id Same Condition Check
         uint leftid1stlevelId=0;
         uint rightid1stlevelId=0;
         uint leftrecycleno=0;
         uint rightrecycleno=0;
         address leftid;
         address rightid;
         leftid=_M6240Details[referrer].left[recycleno];
         leftrecycleno=_M6240Details[leftid].currentrecycle;
         leftid1stlevelId=_M6240Details[leftid].noofidinfirstlevel[leftrecycleno];
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM6240Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,0,0);
            address parent=_M6240Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,0,1);
            _M6240Details[parent].noofidinsecondlevel[leftrecycleno]+=1;
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM6240Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,0,0);
            address parent=_M6240Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(leftid);
            m6contract.creditM6Income(sponsor,0,1);
            _M6240Details[parent].noofidinsecondlevel[leftrecycleno]+=1;
         }
         else {
            rightid=_M6240Details[referrer].right[recycleno];
            rightrecycleno=_M6240Details[leftid].currentrecycle;
            rightid1stlevelId=_M6240Details[rightid].noofidinfirstlevel[rightrecycleno];
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6240Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,0,0);
               address parent=_M6240Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(rightid);
               m6contract.creditM6Income(sponsor,0,1);
               _M6240Details[parent].noofidinsecondlevel[rightrecycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6240Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,0,0);
               address parent=_M6240Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,0,1); 
               _M6240Details[parent].noofidinsecondlevel[rightrecycleno]+=1; 
            }
         }
         leftid1stlevelId=_M6240Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M6240Details[rightid].noofidinfirstlevel[leftrecycleno];
         uint noofid=leftid1stlevelId+rightid1stlevelId;
         if(noofid==4 && IsUserGotPlaced==1) {
             address referrersponsor=maincontract.getSponsorId(referrer);
             _M6240Details[referrer].currentrecycle+=1;
             _PlaceInM6240Tree(referrer,referrersponsor);
          }
          else if(noofid==4 && IsUserGotPlaced==0){
            _M6240Details[referrer].currentrecycle+=1;
            _PlaceInM6240Tree(user,referrer);
          }
       }
       //Below This All Is Okhey
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM6240Left(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,0,0);
           address parent=_M6240Details[referrer].parent[recycleno];
           m6contract.creditM6Income(parent,0,1);
           _M6240Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(NoofIdInFirstLevel==1) {
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6240Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,0,0);
           address parent=_M6240Details[referrer].parent[recycleno];
           address sponsor=maincontract.getSponsorId(referrer);
           m6contract.creditM6Income(sponsor,0,1);
           _M6240Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
       }
       return true;
    }

    function _PlaceInM6240Left(address user,address placementid) private {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M6240Details[user].currentrecycle;
        uint placementcurrentrecycle=_M6240Details[placementid].currentrecycle;
        _M6240Details[user].userId=userId;
        _M6240Details[user].parent[usercurrentrecycle]=placementid;
        _M6240Details[user].selfSide[usercurrentrecycle]=1;
        _M6240Details[placementid].left[placementcurrentrecycle]=user;
        _M6240Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6240Right(address user,address placementid) private {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M6240Details[user].currentrecycle;
        uint placementcurrentrecycle=_M6240Details[placementid].currentrecycle;
        _M6240Details[user].userId=userId;
        _M6240Details[user].parent[usercurrentrecycle]=placementid;
        _M6240Details[user].selfSide[usercurrentrecycle]=2;
        _M6240Details[placementid].right[placementcurrentrecycle]=user;
        _M6240Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6480Tree(address user,address referrer) public override returns(bool) {
       if(_M6480Details[referrer].userId==0){
          referrer=contractOwner;
       }
       uint recycleno=_M6480Details[referrer].currentrecycle;
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M6480Details[referrer].currentrecycle+=1;
          recycleno=_M6480Details[referrer].currentrecycle;
       }
       uint NoofIdInFirstLevel=_M6480Details[referrer].noofidinfirstlevel[recycleno];
       uint IsUserGotPlaced=0;
       if(NoofIdInFirstLevel==2) {
         //Left Id Same Condition Check
         uint leftid1stlevelId=0;
         uint rightid1stlevelId=0;
         uint leftrecycleno=0;
         uint rightrecycleno=0;
         address leftid;
         address rightid;
         leftid=_M6480Details[referrer].left[recycleno];
         leftrecycleno=_M6480Details[leftid].currentrecycle;
         leftid1stlevelId=_M6480Details[leftid].noofidinfirstlevel[leftrecycleno];
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM6480Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,1,0);
            address parent=_M6480Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,1,1);
            _M6480Details[parent].noofidinsecondlevel[leftrecycleno]+=1;
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM6480Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,1,0);
            address parent=_M6480Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(leftid);
            m6contract.creditM6Income(sponsor,1,1);
            _M6480Details[parent].noofidinsecondlevel[leftrecycleno]+=1;
         }
         else {
            rightid=_M6480Details[referrer].right[recycleno];
            rightrecycleno=_M6480Details[leftid].currentrecycle;
            rightid1stlevelId=_M6480Details[rightid].noofidinfirstlevel[rightrecycleno];
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6480Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,1,0);
               address parent=_M6480Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(rightid);
               m6contract.creditM6Income(sponsor,1,1);
               _M6480Details[parent].noofidinsecondlevel[rightrecycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6480Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,1,0);
               address parent=_M6480Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,1,1);  
               _M6480Details[parent].noofidinsecondlevel[rightrecycleno]+=1;
            }
         }
         leftid1stlevelId=_M6480Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M6480Details[rightid].noofidinfirstlevel[leftrecycleno];
         uint noofid=leftid1stlevelId+rightid1stlevelId;
         if(noofid==4 && IsUserGotPlaced==1) {
             address referrersponsor=maincontract.getSponsorId(referrer);
             _M6480Details[referrer].currentrecycle+=1;
             _PlaceInM6480Tree(referrer,referrersponsor);
          }
          else if(noofid==4 && IsUserGotPlaced==0){
            _M6480Details[referrer].currentrecycle+=1;
            _PlaceInM6480Tree(user,referrer);
          }
       }
       //Below This All Is Okhey
       else if(NoofIdInFirstLevel<2) {
         if(NoofIdInFirstLevel==0){
           //If No Id Then Id Will Place In Left Only at 1st Level
           _PlaceInM6480Left(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,1,0);
           address parent=_M6480Details[referrer].parent[recycleno];
           m6contract.creditM6Income(parent,1,1);
           _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6480Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,1,0);
           address parent=_M6480Details[referrer].parent[recycleno];
           address sponsor=maincontract.getSponsorId(referrer);
           m6contract.creditM6Income(sponsor,1,1);
           _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
       }
       return true;
    }

    function _PlaceInM6480Left(address user,address placementid) internal {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M6480Details[user].currentrecycle;
        uint placementcurrentrecycle=_M6480Details[placementid].currentrecycle;
        _M6480Details[user].userId=userId;
        _M6480Details[user].parent[usercurrentrecycle]=placementid;
        _M6480Details[user].selfSide[usercurrentrecycle]=1;
        _M6480Details[placementid].left[placementcurrentrecycle]=user;
        _M6480Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6480Right(address user,address placementid) internal {
        uint userId=maincontract.getUserId(user);
        uint usercurrentrecycle=_M6480Details[user].currentrecycle;
        uint placementcurrentrecycle=_M6480Details[placementid].currentrecycle;
        _M6480Details[user].userId=userId;
        _M6480Details[user].parent[usercurrentrecycle]=placementid;
        _M6480Details[user].selfSide[usercurrentrecycle]=2;
        _M6480Details[placementid].right[placementcurrentrecycle]=user;
        _M6480Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }
}