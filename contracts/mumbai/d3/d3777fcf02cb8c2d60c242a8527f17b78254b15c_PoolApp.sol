/**
 *Submitted for verification at polygonscan.com on 2022-12-31
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.5.10; 

//*******************************************************************//
//------------------         nexa interface        -------------------//
//*******************************************************************//


interface nexaInt {

     function userInfos(address) external returns ( bool joined,address referral,uint32 id,uint32 activeDirect,uint32 teamCount,uint8 poolLimit,uint64 strongTeam,bool GR_Qualify,bool AR_Qualify,uint32 GR_index,uint32 AR_index,uint32 AR_VaildityIndex,uint32 globalPoolCount,uint64 poolTime);
     function userGains(address) external returns ( uint128 totalSponserGains,uint128 totalUnilevelGains,uint128 totalGapGenGains,uint128 totalGlobalRoyalityGains,uint128 totalActiveRoyalityGains,uint128 totalAutopool2xGains,uint128 poolSponsorGains,uint128 poolRoyaltyGains,uint128 total3xPoolGains,uint128 totalWithdrawn,uint128 withdrawLimit,uint128 creditFund,uint32 topup_Count);

     function lastIDCount() external returns (uint);
     function userAddressByID(uint)external returns (address);
     function POOL_2X_PAY() external returns (uint128);
     function POOL_3X_PAY() external returns (uint128);
     function defaultAddress() external returns (address);
     function POOL_UPLINE_BONUS() external returns(uint128);

     function sysInfos() external view returns(uint,uint,uint,uint,uint,uint,uint,uint);
     function initConnection() external;


    function wrapAutopool2xPayEv(uint ,uint ,uint , uint128 ,uint ) external;

    function wrapAutopool2xRebirth (uint , uint , uint ) external ;

    function wrapAutopool2xPosition(uint ,uint , uint , uint ) external ;

    function wrapAutopool3xPayEv(uint ,uint ,uint , uint128 ) external;

    function wrapAutopool3xRebirth (uint , uint , uint ) external;

    function wrapAutopool3xPosition (uint ,uint , uint ,uint ) external;

    function wrapPoolRoyaltyBonusEv(uint ,uint  ,uint  ,uint128 ) external;

    function wraPpoolCycles (uint , uint ) external ;

     
      
 }







contract PoolApp{



    // FOR TEMPLATING USE ONLY 


    struct userInfo {
        bool        joined;     // for checking user active/deactive status
        address     referral;   // user sponser / ref 
        uint32        id;        // user id
        uint32     activeDirect;    // active
        uint32     teamCount;      // team count
        uint8      poolLimit;     // eligible entry limit within pooltime.
        uint64     strongTeam;
        bool       GR_Qualify;
        bool       AR_Qualify;
        uint32     GR_index; //Global royaty index till paid.
        uint32     AR_index; // Active royaty index till paid.
        uint32     AR_VaildityIndex;// Validity of active royaltys index.
        uint32	   globalPoolCount;// who much pool you buy.
        uint64     poolTime;      //running pool time 

    }

    struct userIncome{
       
        uint128 totalSponserGains; // direct income.
        uint128 totalUnilevelGains; // unilevel income.
        uint128 totalGapGenGains;  // GapGen income.
        uint128 totalGlobalRoyalityGains; //Global Royality.
        uint128 totalActiveRoyalityGains; //Active Royality.
        uint128 totalAutopool2xGains; // autoPool2x.
        uint128 poolRoyaltyGains; // Pool Royalty.
        uint128 total3xPoolGains;// 3xpool income.
         uint128 withdrawLimit; // user eligible limit that he can withdraw.
        uint128 creditFund;    //transfer fund from other user.
        uint32  topup_Count;// who much Topup you have done 
        
    }




    struct autoPool2x
    {
        uint32 userID;
        uint32 autoPoolParent;
        uint32 mIndex;
    }
    
    struct autoPool3x
    { 
        uint32 userID;
        uint32 autoPoolParent;
        uint32 mIndex;
    }



    struct poolCycle{

        uint16 cycle;
        bool action;
    }


    mapping (address=>bool) public  alreadyPoolUser;

    mapping(uint64=>poolCycle)public autopool2xCycle;



        // AUTOPOOL CYCLES 

    autoPool2x[] public autoPool2xDataList;
    autoPool3x[] public autoPool3xDataList;
    mapping(uint=>bool) autoPool3xControl;
    uint32 public mIndex2x;
    uint32 public mIndex3x;
    // uint parentIndx;
    uint32 nextMemberParentFill;
    uint32 nextMemberDownlineFill;

    // uint parent3xIndx;
    uint32 nextMember3xParentFill;
    uint32 nextMember3xDownlineFill;



    address nexaContract;

    nexaInt nexaApp;





    // internal calls


    //-------------------Internal 2x Position----------------------------


    function _autoPool2xPosition(address user, bool stand) external returns (bool)
    {

        require(nexaContract==msg.sender,"Invalid caller");

        userInfo memory usrInfo;

        (,,usrInfo.id,,,,,,,,,,,) = nexaApp.userInfos(user);

        // NEW POSITION
        uint32 tmp;

        if(stand==true){
            mIndex2x++;
            tmp =mIndex2x;
        }
        
        autoPool2x memory mPool2x;
        mPool2x.userID = usrInfo.id;
        uint32 idx = nextMemberParentFill;
        mPool2x.autoPoolParent = idx; 
        mPool2x.mIndex=tmp;      
        autoPool2xDataList.push(mPool2x);

         nexaApp.wrapAutopool2xPosition(autoPool2xDataList.length-1,mPool2x.userID,idx,mIndex2x);
        if(mIndex2x!=1)payNbirth(user,nextMemberParentFill);
       
        
        return true;
    }


    function payNbirth(address user,uint recParentIndx) internal returns(uint) {


        // get all data of last parent
        uint32 recMindex = autoPool2xDataList[recParentIndx].mIndex;
        uint recUserId = autoPool2xDataList[recParentIndx].userID;
        address recUser = nexaApp.userAddressByID(recUserId);

        (,,uint userID,,,,,,,,,,,) = nexaApp.userInfos(user);
        
        uint payUser   = userID;

        // autopool2xCycle[recMindex].cycle;
        

        bool is2xBirth =  autopool2xCycle[recMindex].action;

        if (is2xBirth){

            // rebirth position

            syncIndex();

            reBirthPosition(recUser,recMindex,payUser, recUserId);

            autopool2xCycle[recMindex].action=false;

            payNbirth(user,nextMemberParentFill);

        }else{

            //pay 
            if (nexaApp.lastIDCount()!=1){

               //payuser
               autopool2xCycle[recMindex].cycle++;

               payUserPosition(recMindex, payUser,recUserId, autopool2xCycle[recMindex].cycle);

            }

             autopool2xCycle[recMindex].action=true;

             syncIndex();  

        }

       

    }



    function syncIndex() internal {

        

        if (nextMemberDownlineFill==0){
            
            bool cycle=fullCycleOver(nextMemberParentFill);

            uint recMindex = autoPool2xDataList[nextMemberParentFill].mIndex;
            uint defID = autoPool2xDataList[nextMemberParentFill].userID;
           
            if(cycle || recMindex==0 && defID!=1){

                while (cycle || recMindex==0 && defID!=1){

                    nextMemberParentFill++;
                    cycle=fullCycleOver(nextMemberParentFill);
                }
                nextMemberDownlineFill=0;

            }
            else nextMemberDownlineFill=1;
            


        }
           
        else{
             nextMemberDownlineFill=0;
             nextMemberParentFill++;
            // check if parent Cycle is over bypass index to new one
            bool cycle=fullCycleOver(nextMemberParentFill);
            uint recMindex = autoPool2xDataList[nextMemberParentFill].mIndex;
            uint defID = autoPool2xDataList[nextMemberParentFill].userID;
            
            if(cycle || recMindex==0 && defID==1){

                while (cycle || recMindex==0 && defID==1){

                    nextMemberParentFill++;
                    cycle=fullCycleOver(nextMemberParentFill);
                }

            }
        }   
    }


    function fullCycleOver(uint index) internal view returns(bool){

        // get parent and then child
        uint64 recMindex = autoPool2xDataList[index].mIndex;
        uint64 userId = autoPool2xDataList[index].userID;

        (,,,uint maxCycle,,,,) = nexaApp.sysInfos();

        if(autopool2xCycle[recMindex].cycle==maxCycle && userId!=1 ) return true;

        return false;
    }


    function reBirthPosition(address _poolUser,uint32 _mIndex,uint _from, uint _to) internal {
    
            autoPool2x memory mPool2x;

            userInfo memory usrInfo;

            (,,usrInfo.id,,,,,,,,,,,) = nexaApp.userInfos(_poolUser);

            mPool2x.userID = usrInfo.id;
            uint32 idx = nextMemberParentFill;
            mPool2x.autoPoolParent = idx; 
            mPool2x.mIndex=_mIndex;      
            autoPool2xDataList.push(mPool2x);
            nexaApp.wrapAutopool2xPosition(autoPool2xDataList.length-1,mPool2x.userID,idx,_mIndex);
            // add pool in cycle 
            nexaApp.wrapAutopool2xRebirth(autoPool2xDataList.length-1,_from,_to); 

    }


    function payUserPosition(uint _mIndex, uint _from, uint _recId ,uint cycle) internal {

       
        address recUser= nexaApp.userAddressByID(_recId);

        userInfo memory usrInfo;
       

        (,address ref,,,,,,,,,,,,)=nexaApp.userInfos(recUser);


        (,,usrInfo.id,,,,,,,,,,,) = nexaApp.userInfos(ref);
    
       
        nexaApp.wrapAutopool2xPayEv (_mIndex,_from, _recId, nexaApp.POOL_2X_PAY(),cycle);
        
        if (ref==address(0))ref=nexaApp.defaultAddress();
        
        nexaApp.wrapPoolRoyaltyBonusEv(_from,_recId,usrInfo.id,nexaApp.POOL_UPLINE_BONUS());



    }




    //------------------- external 3xPosition---------------------------------


    function _autoPool3xPosition(address _user) external returns (bool)
    {

         require(nexaContract==msg.sender,"Invalid caller");

        // NEW POSITION
        uint32 tmp;


        userInfo memory usrInfo;
       

        (,,usrInfo.id,,,,,,,,,,,) = nexaApp.userInfos(_user);



        if(!alreadyPoolUser[_user] || _user == nexaApp.defaultAddress()){
            mIndex3x++;
            tmp =mIndex3x;
        }

        autoPool3x memory mPool3x;
        mPool3x.userID = usrInfo.id;
        uint32 idx = nextMember3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=tmp;      
        autoPool3xDataList.push(mPool3x);
        alreadyPoolUser[_user]=true;
       
        nexaApp.wrapAutopool3xPosition(autoPool3xDataList.length-1,mPool3x.userID,idx,tmp);
        if(tmp!=1) payNbirth3x(_user,nextMember3xParentFill);

        return true;
    }


    function syncIndex3x() internal {

        if (nextMember3xDownlineFill==0) nextMember3xDownlineFill=1;
        else if (nextMember3xDownlineFill==1) nextMember3xDownlineFill=2;
        // new member fill
        else{

            nextMember3xDownlineFill=0;
            nextMember3xParentFill++;

            uint recMindex = autoPool3xDataList[nextMember3xParentFill].mIndex;

            if(recMindex==0){

                while(recMindex==0){

                    nextMember3xParentFill++;
                    recMindex = autoPool3xDataList[nextMember3xParentFill].mIndex;
                }

            }


        }
        
    }


    function payNbirth3x(address _user, uint recParentIndx ) internal {


        // get all data of last parent
        address recUser = nexaApp.userAddressByID(autoPool3xDataList[recParentIndx].userID);

        userInfo memory usrInfo;
       

        (,,usrInfo.id,,,,,,,,,,,) = nexaApp.userInfos(_user);

      
        
        uint payUser   = usrInfo.id;
        bool is3xBirth =  autoPool3xControl[autoPool3xDataList[recParentIndx].mIndex];

        if (is3xBirth){

            // rebirth position
            syncIndex3x();
            reBirth3xPosition(recUser,autoPool3xDataList[recParentIndx].mIndex,payUser, autoPool3xDataList[recParentIndx].userID);
            autoPool3xControl[autoPool3xDataList[recParentIndx].mIndex]=false;
            payNbirth3x(_user,nextMember3xParentFill);

        }else{

            //pay 
            if (nexaApp.lastIDCount()!=1){

                nexaApp.wrapAutopool3xPayEv (autoPool3xDataList[recParentIndx].mIndex,payUser, autoPool3xDataList[recParentIndx].userID, nexaApp.POOL_3X_PAY());
            }

             autoPool3xControl[autoPool3xDataList[recParentIndx].mIndex]=true;
             syncIndex3x();  

        }


    }


    function reBirth3xPosition(address _poolUser,uint32 _mIndex,uint _from, uint _to) internal {

        userInfo memory usrInfo;
       

        (,,usrInfo.id,,,,,,,,,,,) = nexaApp.userInfos(_poolUser);

      
        // NEW POSITION
        autoPool3x memory mPool3x;

        mPool3x.userID = usrInfo.id;
        uint32 idx = nextMember3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=_mIndex;      
        autoPool3xDataList.push(mPool3x);

        nexaApp.wrapAutopool3xPosition(autoPool3xDataList.length-1,mPool3x.userID,idx,_mIndex);

        // add pool in cycle 
        nexaApp.wrapAutopool3xRebirth(autoPool2xDataList.length-1,_from,_to); 


    }



    function autoPool2xDataListLength() external view returns(uint){

         return autoPool2xDataList.length;
    }
    
    function autoPool3xDataListLength() external view returns(uint){

        return autoPool3xDataList.length;
    }



    // initilize/established contract connection 

    function eStablishedConnection(address _contract) external {

        require(nexaContract==address(0),"you already established connection");
        require(_contract!=address(0),"invalid address");
        nexaContract= _contract;

        nexaApp = nexaInt(nexaContract); // initObject

        nexaApp.initConnection(); // iniit nexa 


        
    }



}