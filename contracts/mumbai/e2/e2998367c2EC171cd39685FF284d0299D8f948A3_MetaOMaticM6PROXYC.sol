/**
 *Submitted for verification at polygonscan.com on 2022-10-07
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
    function creditM6Income(address user,uint package,uint level,uint IsFreshId) external returns (bool);
}

contract MetaOMaticM6PROXYC is  IPOLYCONTRACTM6PROXYC {

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
      contractOwner=0x4697b20B0dc6619C2625050B82F7eFce88536dFA;
      maincontract=IPOLYCONTRACTMAIN(0x87487525C07F0e2d728ea03c1d87b3E7b358bFD5);
      m6contract=IPOLYCONTRACTM6(0x8658504c0B36a53ddd1FF17a04b4bCF6dD167944);
      uint TimeStamp=maincontract.getUserId(contractOwner);
      _M6240Details[contractOwner].userId=TimeStamp;
      _M6480Details[contractOwner].userId=TimeStamp;
   }

    //Get Level Downline With No of Id & Investments
    function generate_report(uint package,address user,uint cycle) view public returns(uint currentrecycle,address parent,address left,address right,uint noofidinfirstlevel,uint noofidinsecondlevel){
      if(package==4){
          return(_M6240Details[user].currentrecycle,_M6240Details[user].parent[cycle],_M6240Details[user].left[cycle],_M6240Details[user].right[cycle],_M6240Details[user].noofidinfirstlevel[cycle],_M6240Details[user].noofidinsecondlevel[cycle]);
      }
      else if(package==5){
          return(_M6480Details[user].currentrecycle,_M6480Details[user].parent[cycle],_M6480Details[user].left[cycle],_M6480Details[user].right[cycle],_M6480Details[user].noofidinfirstlevel[cycle],_M6480Details[user].noofidinsecondlevel[cycle]);
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
       IsFreshId=0;
       if(_M6240Details[user].userId==0){
           IsFreshId=1;
       }
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M6240Details[referrer].currentrecycle+=1;
       }
       else{
         if(_M6240Details[referrer].userId==0){
          referrer=contractOwner;
         }
       }

       recycleno=_M6240Details[referrer].currentrecycle;
       NoofIdInFirstLevel=_M6240Details[referrer].noofidinfirstlevel[recycleno];
       IsUserGotPlaced=0;

       if(NoofIdInFirstLevel==2) {

         leftid=_M6240Details[referrer].left[recycleno];
         leftrecycleno=_M6240Details[leftid].currentrecycle;
         leftid1stlevelId=_M6240Details[leftid].noofidinfirstlevel[leftrecycleno];

         rightid=_M6240Details[referrer].right[recycleno];
         rightrecycleno=_M6240Details[rightid].currentrecycle;
         rightid1stlevelId=_M6240Details[rightid].noofidinfirstlevel[rightrecycleno];

         //Left Id Same Condition Check
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM6240Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,4,0,IsFreshId);
             address parent=_M6240Details[leftid].parent[leftrecycleno];
             m6contract.creditM6Income(parent,4,1,IsFreshId);
            _M6240Details[parent].noofidinsecondlevel[recycleno]+=1;
         }

         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM6240Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,4,0,IsFreshId);
            address parent=_M6240Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(parent);
            m6contract.creditM6Income(sponsor,4,1,IsFreshId);
            _M6240Details[parent].noofidinsecondlevel[recycleno]+=1;
         }

         else {
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6240Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,4,0,IsFreshId);
               address parent=_M6240Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(parent);
               m6contract.creditM6Income(sponsor,4,1,IsFreshId);
               _M6240Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6240Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,4,0,IsFreshId);
               address parent=_M6240Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,4,1,IsFreshId); 
               _M6240Details[parent].noofidinsecondlevel[recycleno]+=1; 
            }
         }

         leftid1stlevelId=_M6240Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M6240Details[rightid].noofidinfirstlevel[rightrecycleno];

         noofid=leftid1stlevelId+rightid1stlevelId;

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
           m6contract.creditM6Income(referrer,4,0,IsFreshId);
           address parent=_M6240Details[referrer].parent[recycleno];
           uint referralside=_M6240Details[referrer].selfSide[recycleno];
           if(referralside==1)
           {
              m6contract.creditM6Income(parent,4,1,IsFreshId);
           }
           else {
              address sponsor=maincontract.getSponsorId(parent);
              m6contract.creditM6Income(sponsor,4,1,IsFreshId);
           }
           _M6240Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(NoofIdInFirstLevel==1) {
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6240Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,4,0,IsFreshId);
           address parent=_M6240Details[referrer].parent[recycleno];
           uint referralside=_M6240Details[referrer].selfSide[recycleno];        
           address sponsor=maincontract.getSponsorId(parent);
           if(referralside==2)
           {
              m6contract.creditM6Income(parent,4,1,IsFreshId);
           }
           else {
              m6contract.creditM6Income(sponsor,4,1,IsFreshId);
           }
           _M6240Details[parent].noofidinsecondlevel[recycleno]+=1;
           firstlevelcount=_M6240Details[parent].noofidinfirstlevel[recycleno];
           secondlevelcount=_M6240Details[parent].noofidinsecondlevel[recycleno];
           noofid=firstlevelcount+secondlevelcount;
           if(noofid==6) {            
             _M6240Details[parent].currentrecycle+=1;
             _PlaceInM6240Tree(parent,sponsor);
           }  
         }
       }
       return true;
    }

    function _PlaceInM6240Left(address user,address placementid) private {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M6240Details[user].currentrecycle;
         placementcurrentrecycle=_M6240Details[placementid].currentrecycle;
        _M6240Details[user].userId=userId;
        _M6240Details[user].parent[usercurrentrecycle]=placementid;
        _M6240Details[user].selfSide[usercurrentrecycle]=1;
        _M6240Details[placementid].left[placementcurrentrecycle]=user;
        _M6240Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6240Right(address user,address placementid) private {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M6240Details[user].currentrecycle;
         placementcurrentrecycle=_M6240Details[placementid].currentrecycle;
        _M6240Details[user].userId=userId;
        _M6240Details[user].parent[usercurrentrecycle]=placementid;
        _M6240Details[user].selfSide[usercurrentrecycle]=2;
        _M6240Details[placementid].right[placementcurrentrecycle]=user;
        _M6240Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6480Tree(address user,address referrer) public override returns(bool) {
       IsFreshId=0;
       if(_M6480Details[user].userId==0){
           IsFreshId=1;
       }
       if(referrer==address(0) || referrer==0x0000000000000000000000000000000000000000) {  
          _M6480Details[referrer].currentrecycle+=1;
       }
       else{
         if(_M6480Details[referrer].userId==0){
           referrer=contractOwner;
         }
       }
       recycleno=_M6480Details[referrer].currentrecycle;
       NoofIdInFirstLevel=_M6480Details[referrer].noofidinfirstlevel[recycleno];
       IsUserGotPlaced=0;
       if(NoofIdInFirstLevel==2) {
         leftid=_M6480Details[referrer].left[recycleno];
         leftrecycleno=_M6480Details[leftid].currentrecycle;
         leftid1stlevelId=_M6480Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid=_M6480Details[referrer].right[recycleno];
         rightrecycleno=_M6480Details[rightid].currentrecycle;
         rightid1stlevelId=_M6480Details[rightid].noofidinfirstlevel[rightrecycleno];
         //Left Id Same Condition Check
         if(leftid1stlevelId==0) {
            //If No Id Then Id Will Place In Left Only at 1st Level
            _PlaceInM6480Left(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
             m6contract.creditM6Income(leftid,5,0,IsFreshId);
            address parent=_M6480Details[leftid].parent[leftrecycleno];
            m6contract.creditM6Income(parent,5,1,IsFreshId);
            _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(leftid1stlevelId==1) {
            //If Only 1 Id Then Id Will Place In Right Only at 1st Level
            _PlaceInM6480Right(user,leftid);
            IsUserGotPlaced=1;
            //Benificary,Package,Level
            m6contract.creditM6Income(leftid,5,0,IsFreshId);
            address parent=_M6480Details[leftid].parent[leftrecycleno];
            address sponsor=maincontract.getSponsorId(parent);
            m6contract.creditM6Income(sponsor,5,1,IsFreshId);
            _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else {
            if(rightid1stlevelId==0){
               //If No Id Then Id Will Place In Left Only at 1st Level
               _PlaceInM6480Left(user,rightid);
               IsUserGotPlaced=1;
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,5,0,IsFreshId);
               address parent=_M6480Details[rightid].parent[rightrecycleno];
               address sponsor=maincontract.getSponsorId(parent);
               m6contract.creditM6Income(sponsor,5,1,IsFreshId);
               _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
            else if(rightid1stlevelId==1){
               //If Only 1 Id Then Id Will Place In Right Only at 1st Level
               _PlaceInM6480Right(user,rightid);
               IsUserGotPlaced=1;   
               //Benificary,Package,Level
               m6contract.creditM6Income(rightid,5,0,IsFreshId);
               address parent=_M6480Details[rightid].parent[rightrecycleno];
               m6contract.creditM6Income(parent,5,1,IsFreshId);  
               _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
            }
         }
         leftid1stlevelId=_M6480Details[leftid].noofidinfirstlevel[leftrecycleno];
         rightid1stlevelId=_M6480Details[rightid].noofidinfirstlevel[rightrecycleno];
         noofid=leftid1stlevelId+rightid1stlevelId;
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
           m6contract.creditM6Income(referrer,5,0,IsFreshId);
           address parent=_M6480Details[referrer].parent[recycleno];
           uint referralside=_M6480Details[referrer].selfSide[recycleno];
           if(referralside==1)
           {
              m6contract.creditM6Income(parent,5,1,IsFreshId);
           }
           else {
              address sponsor=maincontract.getSponsorId(parent);
              m6contract.creditM6Income(sponsor,5,1,IsFreshId);
           }
           _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
         }
         else if(NoofIdInFirstLevel==1){
           //If Only 1 Id Then Id Will Place In Right Only at 1st Level
           _PlaceInM6480Right(user,referrer);
           IsUserGotPlaced=1;
           //Benificary,Package,Level
           m6contract.creditM6Income(referrer,5,0,IsFreshId);
           address parent=_M6480Details[referrer].parent[recycleno];
           uint referralside=_M6480Details[referrer].selfSide[recycleno];    
           address sponsor=maincontract.getSponsorId(parent);
           if(referralside==2)
           {
              m6contract.creditM6Income(parent,5,1,IsFreshId);
           }
           else {
              m6contract.creditM6Income(sponsor,5,1,IsFreshId);
           }
           _M6480Details[parent].noofidinsecondlevel[recycleno]+=1;
           firstlevelcount=_M6480Details[parent].noofidinfirstlevel[recycleno];
           secondlevelcount=_M6480Details[parent].noofidinsecondlevel[recycleno];
           noofid=firstlevelcount+secondlevelcount;
           if(noofid==6) {            
             _M6480Details[parent].currentrecycle+=1;
             _PlaceInM6480Tree(parent,sponsor);
           }    
         }
       }
       return true;
    }

    function _PlaceInM6480Left(address user,address placementid) internal {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M6480Details[user].currentrecycle;
         placementcurrentrecycle=_M6480Details[placementid].currentrecycle;
        _M6480Details[user].userId=userId;
        _M6480Details[user].parent[usercurrentrecycle]=placementid;
        _M6480Details[user].selfSide[usercurrentrecycle]=1;
        _M6480Details[placementid].left[placementcurrentrecycle]=user;
        _M6480Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }

    function _PlaceInM6480Right(address user,address placementid) internal {
         userId=maincontract.getUserId(user);
         usercurrentrecycle=_M6480Details[user].currentrecycle;
         placementcurrentrecycle=_M6480Details[placementid].currentrecycle;
        _M6480Details[user].userId=userId;
        _M6480Details[user].parent[usercurrentrecycle]=placementid;
        _M6480Details[user].selfSide[usercurrentrecycle]=2;
        _M6480Details[placementid].right[placementcurrentrecycle]=user;
        _M6480Details[placementid].noofidinfirstlevel[placementcurrentrecycle]+=1;
    }
}