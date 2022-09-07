/**
 *Submitted for verification at polygonscan.com on 2022-09-06
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
    function creditM6Income(address user,uint package,uint level,uint IsFreshId) external returns (bool);
}

contract MetaOMaticM6PROXYSMCB is  IPOLYCONTRACTM6PROXYB {

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

    struct M660Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    struct M6120Details {
        uint userId;
        uint currentrecycle;
        mapping(uint => uint) selfSide;
        mapping(uint => address) parent;
        mapping(uint => address) left;
        mapping(uint => address) right;
        mapping(uint => uint) noofidinfirstlevel;
        mapping(uint => uint) noofidinsecondlevel;
    }

    mapping (address => M660Details) public _M660Details;
    mapping (address => M6120Details) public _M6120Details;

    constructor() {
      contractOwner=0xEBc985f2964855650b8EA81f714cCb90a5843EE0;
      maincontract=IPOLYCONTRACTMAIN(0x89aBCEE8a430B14AC7eB5E54E8A8143d9680BF1b);
      m6contract=IPOLYCONTRACTM6(0xb3976F59e9288EFfc576766D8cbec341B8140a87);
      uint TimeStamp=maincontract.getUserId(contractOwner);
      _M660Details[contractOwner].userId=TimeStamp;
      _M6120Details[contractOwner].userId=TimeStamp;
   }

    //Get Level Downline With No of Id & Investments
    function generate_report(uint package,address user,uint cycle) view public returns(uint currentrecycle,address parent,address left,address right,uint noofidinfirstlevel,uint noofidinsecondlevel){
      if(package==2){
          return(_M660Details[user].currentrecycle,_M660Details[user].parent[cycle],_M660Details[user].left[cycle],_M660Details[user].right[cycle],_M660Details[user].noofidinfirstlevel[cycle],_M660Details[user].noofidinsecondlevel[cycle]);
      }
      else if(package==3){
          return(_M6120Details[user].currentrecycle,_M6120Details[user].parent[cycle],_M6120Details[user].left[cycle],_M6120Details[user].right[cycle],_M6120Details[user].noofidinfirstlevel[cycle],_M6120Details[user].noofidinsecondlevel[cycle]);
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
       IsFreshId=0;
       if(_M660Details[user].userId==0){
           IsFreshId=1;
       }
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M660Details[referrer].currentrecycle+=1;
       }
       else{
         if(_M660Details[referrer].userId==0){
           referrer=contractOwner;
         }
       }    

       recycleno=_M660Details[referrer].currentrecycle;
       NoofIdInFirstLevel=_M660Details[referrer].noofidinfirstlevel[recycleno];
       IsUserGotPlaced=0;

       if(NoofIdInFirstLevel==2) {

         leftid=_M660Details[referrer].left[recycleno];
         leftrecycleno=_M660Details[leftid].currentrecycle;
         leftid1stlevelId=_M660Details[leftid].noofidinfirstlevel[leftrecycleno];

         rightid=_M660Details[referrer].right[recycleno];
         rightrecycleno=_M660Details[rightid].currentrecycle;
         rightid1stlevelId=_M660Details[rightid].noofidinfirstlevel[rightrecycleno];

         //Left Id Same Condition Check
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM660Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,2,0,IsFreshId);
             address parent=_M660Details[leftid].parent[leftrecycleno];
             m6contract.creditM6Income(parent,2,1,IsFreshId);
            _M660Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM660Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,2,0,IsFreshId);
            address parent=_M660Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(parent);
            m6contract.creditM6Income(sponsor,2,1,IsFreshId);
            _M660Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else {
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM660Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,2,0,IsFreshId);
               address parent=_M660Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(parent);
               m6contract.creditM6Income(sponsor,2,1,IsFreshId);
               _M660Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM660Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,2,0,IsFreshId);
               address parent=_M660Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,2,1,IsFreshId); 
               _M660Details[parent].noofidinsecondlevel[recycleno]+=1; 
            }
         }
         leftid1stlevelId=_M660Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M660Details[rightid].noofidinfirstlevel[rightrecycleno];
         noofid=leftid1stlevelId+rightid1stlevelId;
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
           m6contract.creditM6Income(referrer,2,0,IsFreshId);
           address parent=_M660Details[referrer].parent[recycleno];
           uint referralside=_M660Details[referrer].selfSide[recycleno];
           if(referralside==1)
           {
              m6contract.creditM6Income(parent,2,1,IsFreshId);
           }
           else {
              address sponsor=maincontract.getSponsorId(parent);
              m6contract.creditM6Income(sponsor,2,1,IsFreshId);
           }
           _M660Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM660Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,2,0,IsFreshId);
           address parent=_M660Details[referrer].parent[recycleno];
           uint referralside=_M660Details[referrer].selfSide[recycleno];    
           address sponsor=maincontract.getSponsorId(parent);
           if(referralside==2)
           {
              m6contract.creditM6Income(parent,2,1,IsFreshId);
           }
           else {
              m6contract.creditM6Income(sponsor,2,1,IsFreshId);
           }
           _M660Details[parent].noofidinsecondlevel[recycleno]+=1;
           firstlevelcount=_M660Details[parent].noofidinfirstlevel[recycleno];
           secondlevelcount=_M660Details[parent].noofidinsecondlevel[recycleno];
           noofid=firstlevelcount+secondlevelcount;
           if(noofid==6) {         
             _M660Details[parent].currentrecycle+=1;
             _PlaceInM660Tree(parent,sponsor);
           }
         }
       }
       return true;
    }

    function _PlaceInM660Left(address user,address placementid) private {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M660Details[user].currentrecycle;
         placementcurrentrecycle=_M660Details[placementid].currentrecycle;
        _M660Details[user].userId=userId;
        _M660Details[user].parent[usercurrentrecycle]=placementid;
        _M660Details[user].selfSide[usercurrentrecycle]=1;
        _M660Details[placementid].left[placementcurrentrecycle]=user;
        _M660Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM660Right(address user,address placementid) private {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M660Details[user].currentrecycle;
         placementcurrentrecycle=_M660Details[placementid].currentrecycle;
        _M660Details[user].userId=userId;
        _M660Details[user].parent[usercurrentrecycle]=placementid;
        _M660Details[user].selfSide[usercurrentrecycle]=2;
        _M660Details[placementid].right[placementcurrentrecycle]=user;
        _M660Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6120Tree(address user,address referrer) public override returns(bool) {
       IsFreshId=0;
       if(_M6120Details[user].userId==0){
           IsFreshId=1;
       }
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M6120Details[referrer].currentrecycle+=1;
       }
       else {
         if(_M6120Details[referrer].userId==0){
            referrer=contractOwner;
         }
       }
       recycleno=_M6120Details[referrer].currentrecycle;
       NoofIdInFirstLevel=_M6120Details[referrer].noofidinfirstlevel[recycleno];
       IsUserGotPlaced=0;
       if(NoofIdInFirstLevel==2) {
         leftid=_M6120Details[referrer].left[recycleno];
         leftrecycleno=_M6120Details[leftid].currentrecycle;
         leftid1stlevelId=_M6120Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid=_M6120Details[referrer].right[recycleno];
         rightrecycleno=_M6120Details[rightid].currentrecycle;
         rightid1stlevelId=_M6120Details[rightid].noofidinfirstlevel[rightrecycleno];
         //Left Id Same Condition Check
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM6120Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,3,0,IsFreshId);
            address parent=_M6120Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,3,1,IsFreshId);
            _M6120Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM6120Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,3,0,IsFreshId);
            address parent=_M6120Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(parent);
            m6contract.creditM6Income(sponsor,3,1,IsFreshId);
            _M6120Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else {
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6120Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,3,0,IsFreshId);
               address parent=_M6120Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(parent);
               m6contract.creditM6Income(sponsor,3,1,IsFreshId);
               _M6120Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6120Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,3,0,IsFreshId);
               address parent=_M6120Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,3,1,IsFreshId);
               _M6120Details[parent].noofidinsecondlevel[recycleno]+=1; 
            }
         }
         leftid1stlevelId=_M6120Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M6120Details[rightid].noofidinfirstlevel[rightrecycleno];
         noofid=leftid1stlevelId+rightid1stlevelId;
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
           m6contract.creditM6Income(referrer,3,0,IsFreshId);
           address parent=_M6120Details[referrer].parent[recycleno];
           uint referralside=_M6120Details[referrer].selfSide[recycleno];
           if(referralside==1)
           {
              m6contract.creditM6Income(parent,3,1,IsFreshId);
           }
           else {
              address sponsor=maincontract.getSponsorId(parent);
              m6contract.creditM6Income(sponsor,3,1,IsFreshId);
           }
           _M6120Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(NoofIdInFirstLevel==1){
           _PlaceInM6120Right(user,referrer);
           IsUserGotPlaced=1;
           m6contract.creditM6Income(referrer,3,0,IsFreshId);
           address parent=_M6120Details[referrer].parent[recycleno];
           uint referralside=_M6120Details[referrer].selfSide[recycleno];
           address sponsor=maincontract.getSponsorId(parent);
           if(referralside==2)
           {
              m6contract.creditM6Income(parent,3,1,IsFreshId);
           }
           else {
              m6contract.creditM6Income(sponsor,3,1,IsFreshId);
           }
           _M6120Details[parent].noofidinsecondlevel[recycleno]+=1;  
           firstlevelcount=_M6120Details[parent].noofidinfirstlevel[recycleno];
           secondlevelcount=_M6120Details[parent].noofidinsecondlevel[recycleno];
           noofid=firstlevelcount+secondlevelcount;
           if(noofid==6) {            
             _M6120Details[parent].currentrecycle+=1;
             _PlaceInM6120Tree(parent,sponsor);
           }              
         }
       }
       return true;
    }

   function _PlaceInM6120Left(address user,address placementid) internal {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M6120Details[user].currentrecycle;
         placementcurrentrecycle=_M6120Details[placementid].currentrecycle;
        _M6120Details[user].userId=userId;
        _M6120Details[user].parent[usercurrentrecycle]=placementid;
        _M6120Details[user].selfSide[usercurrentrecycle]=1;
        _M6120Details[placementid].left[placementcurrentrecycle]=user;
        _M6120Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
   }

   function _PlaceInM6120Right(address user,address placementid) internal {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M6120Details[user].currentrecycle;
         placementcurrentrecycle=_M6120Details[placementid].currentrecycle;
        _M6120Details[user].userId=userId;
        _M6120Details[user].parent[usercurrentrecycle]=placementid;
        _M6120Details[user].selfSide[usercurrentrecycle]=2;
        _M6120Details[placementid].right[placementcurrentrecycle]=user;
        _M6120Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
   }
}