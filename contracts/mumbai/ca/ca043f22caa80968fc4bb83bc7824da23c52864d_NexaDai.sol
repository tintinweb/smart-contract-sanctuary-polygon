/**
 *Submitted for verification at polygonscan.com on 2022-12-25
*/

pragma solidity 0.5.10; 


//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface ERC20In{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);

 }
  interface dataContract{

     function userInfos(address) external returns ( bool joined,address referral,uint32 id,uint32 activeDirect,uint32 teamCount,uint8 poolLimit,uint64 strongTeam,bool GR_Qualify,bool AR_Qualify,uint32 GR_index,uint32 AR_index,uint32 AR_VaildityIndex,uint32 globalPoolCount,uint64 poolTime);
     function userGains(address) external returns ( uint128 totalSponserGains,uint128 totalUnilevelGains,uint128 totalGapGenGains,uint128 totalGlobalRoyalityGains,uint128 totalActiveRoyalityGains,uint128 totalAutopool2xGains,uint128 poolSponsorGains,uint128 poolRoyaltyGains,uint128 total3xPoolGains,uint128 totalWithdrawn,uint128 withdrawLimit,uint128 creditFund,uint32 topup_Count);
     function autoPool2xDataList(uint) external returns ( uint32 userID,uint32 autoPoolParent,uint32 mIndex);
     function autoPool3xDataList(uint) external returns ( uint32 userID,uint32 autoPoolParent,uint32 mIndex);
     function autopool3xLastIndex() external returns (uint);
     function lastIDCount() external returns (uint);
     function userAddressByID(uint)external returns (address);
     
      
 }
 



contract NexaDai {


//-------------------[PRICE CHART STORAGE]----------------

    
    uint128 constant JOIN_PRICE=45e18; // join price / entry price
    uint128 constant POOL_PRICE=12e18;// pool price

    uint128 constant SPONSER_PAY = 10e18;

    // pool
    uint128 constant POOL_2X_PAY = 10e18;
    uint128 constant POOL_3X_PAY = 4e18;
    uint128 constant POOL_UPLINE_BONUS=1e18;
  
    uint constant GAP_DIRECT =4;
    uint constant GR_DIRECT =6;
    uint constant GR_STRONG_LEG =30;
    uint constant GR_OTHER_LEG =70;
    uint constant AR_DIRECTS=10;
   

    uint constant TEAM_DEPTH =20;
    uint128 constant ROYALITY_BONUS = 1e18;
    uint128 constant ACTIVE_ROYALITY_BONUS = 2e18;
   
    //Daily Collection
    uint128  GR_collection;
    uint128  AR_collection;

     // Royalty storage
    uint64 public nextRoyalty;
    uint32 public royalty_Index;
   
    // Royalty Qualifire count
    uint32  GR_Qualifier_Count;
    uint32  AR_Qualifier_Count;


    uint32 public lastIDCount;
   


// Replace below address with main token token
    address public tokenAddress;
    address  constant defaultAddress=0x2B2FE21A85B033c3E64DF5861c08f5C3504c0c30;// this is 1 number ID.
    address constant oldContract= 0xe4dd72fF19F0B2aeE716900E7D30926f06183C76;// old contract for data fetching.
    address  fetchAuther;
    struct sysInfo{

        uint8 withdrawFee; // withdraw fee that is dedcut when you will proccess for withdraw.
        uint64 pool2Deadline; // this pool deadline time frame
        uint8 pool2Entrylimit; // number of entry you can take in pool within deadline.
        uint8 maxCycle;// Pool 2X max cyclye distribution.
        uint8 AR_validity; // Active royalty validity.
        uint64 royaltyValidity;// Royalty closing time
        uint128 totalFee; // total fee
        uint128 storeageGP; // global pool auto genrated fund.
    }
    sysInfo public sysInfos ;
    
    
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

    struct royalty
    {   uint128 GR_Fund;
        uint32 GR_Users;
        uint128 GR_total_Share;
        uint128 AR_Fund;
        uint32 AR_Users; 
        uint128 AR_total_Share; 
    }

    struct poolCycle{

        uint16 cycle;
        bool action;
    }

    // Mapping data
    mapping (uint => royalty) public royaltys;
    mapping (address => userInfo) public userInfos;
    mapping (address=> userIncome) public userGains;
  
    mapping (uint => address) public userAddressByID;
    mapping (address=>bool) public  alreadyPoolUser;

    mapping(uint64=>poolCycle)public autopool2xCycle;

    // FINANCIAL EVENT
    event regUserEv(address user, address referral,uint id);
    event directIncomeEv(address _from,address _to,uint _amount);
    event investEv(address user, uint position);
    event reInvestEv(address user, uint position);
    event pool_3X_EV(address user, uint position);
    event pool_2X_EV(address user, uint position);
    event unilevelEv(address _from , address _to,uint level,uint _amount);
    event gapGenerationBonus_Ev(address from,address to ,uint level,uint amount);
    event withdrawEv(address user, uint _amount);
   
    // AUTOPOOL EVENTS
    event autopool2xPayEv (uint _index,uint _from,uint _toUser, uint _amount,uint cycle);
    event autopool2xRebirth (uint _index, uint _fromUser, uint _toUser);
    event autopool2xPosition (uint _index,uint usrID, uint _parentIndex, uint _mainIndex);
    event autopool3xPayEv (uint _index,uint _from,uint _toUser, uint _amount);
    event autopool3xRebirth (uint _index, uint _fromUser, uint _toUser);
    event autopool3xPosition (uint _index,uint usrID, uint _parentIndex,uint _mainIndex);
    event poolSponsorBonusEv(uint _fromId,uint _toId ,uint _amount);
    event poolRoyaltyBonusEv(uint _payId,uint _fromId ,uint _toId ,uint _amount);
    event poolCycles (uint mIndex, uint cycle);
    //ROYALTY EVENT
    event royaltyPay_Ev(address user,uint GR_amount,uint AR_amount);
    event activeRoyaltyQualify(address user,uint currentIndex, uint validityIndex,bool status);
  
    // AUTOPOOL CYCLES 

    autoPool2x[] public autoPool2xDataList;
    autoPool3x[] public autoPool3xDataList;
    mapping(uint=>bool) autoPool3xControl;
    uint32 mIndex2x;
    uint32 mIndex3x;
    // uint parentIndx;
    uint32 nextMemberParentFill;
    uint32 nextMemberDownlineFill;

    // uint parent3xIndx;
    uint32 nextMember3xParentFill;
    uint32 nextMember3xDownlineFill;
   

    constructor(address _authAddress) public {    
    sysInfos.maxCycle=15;

    // default user 

    sysInfos.pool2Deadline =3600;
    sysInfos.pool2Entrylimit=2;
    sysInfos.royaltyValidity=86400;
    nextRoyalty=uint64(now)+sysInfos.royaltyValidity;
    fetchAuther=_authAddress;
    _defaultUser(defaultAddress);

    }

     //Pay registration 
    
    function payRegUser( address _referral) external returns(bool) 
    {
       regUser(_referral);
       buyTopup();
        return true;
    }
    
    //free registration
    function regUser( address _referral ) public returns(bool){

     address msgSender=msg.sender;
     require(_referral!=address(0),"Invalid referal");
     require(userInfos[msgSender].referral==address(0),"You are alrady register");
     require(userInfos[_referral].joined==true,"Your referral is not activated");
     _regUser( msgSender, _referral );
     return true;

    } 

    function _regUser( address user, address _referral ) internal 
    {
	   
        lastIDCount++;
        userInfos[user].referral=_referral;
        userInfos[user].id=lastIDCount;
        userAddressByID[lastIDCount] = user;
        emit regUserEv(user, _referral,lastIDCount);
        
    }

    //Invest buy from your credit fund and wallet.
  
    function buyTopup() public returns (bool) {

	    address msgSender=msg.sender;
        require(userInfos[msgSender].referral!= address(0) || msgSender== defaultAddress,"Invalid user or need to register first");
        userGains[msgSender].withdrawLimit += JOIN_PRICE*3;
        _activateUser(msgSender);
         // internal buy mode.
        _buyMode(msgSender,JOIN_PRICE);
        emit investEv(msgSender,1);
        return true;
    }


    //Invest buy from your gains.
   
    function _activateUser(address msgSender) internal {

        userInfo memory usr=userInfos[msgSender];
        address ref = usr.referral;
    
       
        _royaltyQualify(msgSender);

        if (usr.joined==false){
            
             usr.poolTime = uint64(sysInfos.pool2Deadline+now);
             usr.joined= true;
             userInfos[ref].activeDirect++;
             userInfo memory referr = userInfos[ref];

            //AR VaildityIndex ++
            if(referr.AR_Qualify==true && referr.AR_VaildityIndex>=royalty_Index){
                referr.AR_VaildityIndex+=sysInfos.AR_validity;
                emit activeRoyaltyQualify(ref,referr.AR_index,referr.AR_VaildityIndex,referr.AR_Qualify);

            }
            else{
                 //AR Qualify update
                if(referr.AR_index<referr.AR_VaildityIndex && referr.AR_VaildityIndex<royalty_Index)PayRoyalty(ref);
                referr = userInfos[ref];
                // Again AR Qualify
                if(referr.AR_VaildityIndex!=0 && referr.AR_Qualify==false && referr.AR_VaildityIndex<royalty_Index){
                     referr.AR_index=royalty_Index;
                     referr.AR_VaildityIndex=uint32(royalty_Index+sysInfos.AR_validity);
                     referr.AR_Qualify=true;
                     AR_Qualifier_Count++;
                     emit activeRoyaltyQualify(ref,royalty_Index,referr.AR_VaildityIndex,referr.AR_Qualify);    
                }   
            
            }
            
            userInfos[ref]=referr;
            userInfos[msgSender]=usr;
            _updateTeamNum(ref) ;
            _autoPool2xPosition(msgSender,true);
            
                           
        }
        else _autoPool2xPosition(msgSender,false);

        userGains[msgSender].topup_Count++;
        userInfos[msgSender].globalPoolCount++;
        uint128 total=(SPONSER_PAY+POOL_UPLINE_BONUS);
        
        userGains[ref].totalSponserGains+=total;
        transferTo(ref,total); // zero balance call
       
        

        _royaltyCollection();
        _closingRoyality();
        _royaltyQualify(ref);
        // all position and distribution call should be fire from here
       
        _autoPool3xPosition(msgSender);
        _distributeUnilevelIncome(msgSender,ref);
        _distributeGapBonus(msgSender,ref);
        //pool event
        emit pool_2X_EV (msgSender,1);
        emit pool_3X_EV (msgSender,1); 
        emit directIncomeEv(msgSender,ref,SPONSER_PAY);
        emit poolSponsorBonusEv(userInfos[msgSender].id,userInfos[ref].id,POOL_UPLINE_BONUS);


    }



    //Global pool 2X buy from your credit fund and wallet.
    function buyPool_2X() external  returns(bool) {
        _poolPosition();
	    address msgSender=msg.sender;
        address ref =userInfos[msgSender].referral;

        _autoPool2xPosition(msgSender,true);
        userInfos[msgSender].globalPoolCount++;
        _buyMode(msgSender,POOL_PRICE);
        _closingRoyality();
        PayRoyalty(msgSender);

         userGains[ref].totalSponserGains+=POOL_UPLINE_BONUS;
         transferTo(ref,POOL_UPLINE_BONUS); // zero balance call
       
        emit pool_2X_EV (msgSender,1);
        emit poolSponsorBonusEv(userInfos[msgSender].id,userInfos[ref].id,POOL_UPLINE_BONUS);
        return true;
    }

    
    // fallback function

    function () payable external {
       
    }

    //  withdraw
   

    function autopool2xLastIndex() view public returns(uint){

        if (autoPool2xDataList.length>0) return autoPool2xDataList.length-1;
        revert();
    }

    function autopool3xLastIndex() view public returns(uint){

        if (autoPool3xDataList.length>0) return autoPool3xDataList.length-1;
        revert();
    }


    function totalGains_(address _user) public view returns (uint128){

        userIncome memory gains=userGains[_user];
        uint128 total;
        total+=gains.totalSponserGains;
        total+=gains.totalUnilevelGains; 
        total+=gains.totalGapGenGains;  
        total+=gains.totalGlobalRoyalityGains; 
        total+=gains.totalActiveRoyalityGains;
        total+=gains.totalAutopool2xGains; 
        total+=gains.poolRoyaltyGains;
        total+=gains.total3xPoolGains;
        return(total);

    }
    

    // Transfer from credit fund .
    event transferFromCredit_Ev(address from, address to , uint amount);

    function transferCredit(address _to, uint128 _amount) external  returns(bool) {
	    address msgSender=msg.sender;
        require(userInfos[msgSender].referral != address(0) || msgSender==defaultAddress," Inactive user or need to register first");
        require(userGains[msgSender].creditFund >=_amount,"Your credit fund balance is low");

        userGains[msgSender].creditFund-=_amount;
        userGains[_to].creditFund+=_amount;
        
        emit transferFromCredit_Ev (msgSender,_to,_amount);       
        return true;

    }


//-------------------------------ADMIN CALLER FUNCTION -----------------------------------

    //----------------------THIS IS JUST TEST FUNCTION WE CAN REPLACE THIS FUNCTION TO ANY -- MULTIsIGN CALL FUNCTION--------
    function withdrawFee() onlyDefault external returns(bool) {
        _transfer(msg.sender,sysInfos.totalFee);
        sysInfos.totalFee=0;
        return true;

    }

    function setPrams(address newTokenAddress, uint8 withdrwalFee, uint64 setPoolTime, uint8 setPoolLimit,uint8 _maxCycle,uint64 _royaltyClosingTime, uint8 _AR_validity) onlyDefault external  returns(bool){
        tokenAddress=newTokenAddress;
        sysInfos.withdrawFee= withdrwalFee;
		sysInfos.pool2Deadline= setPoolTime;
        sysInfos.pool2Entrylimit= setPoolLimit;
        sysInfos.maxCycle= _maxCycle;
        sysInfos.royaltyValidity=_royaltyClosingTime;
        sysInfos.AR_validity=_AR_validity;
        return true;
    }


    //---------------------Internal/Optimized Function-----------------------------

   function _updateTeamNum(address ref) internal  {

        for(uint i; i < TEAM_DEPTH; i++){

            address usr = ref;
            ref = userInfos[usr].referral;
            if(usr != address(0))userInfos[usr].teamCount++;
            if(ref == address(0)) break;
            else if((userInfos[usr].teamCount+1)>userInfos[ref].strongTeam)userInfos[ref].strongTeam=(userInfos[usr].teamCount+1);
         } 
         
    }


    // internal calll

    function _defaultUser(address _user) internal {
        userInfo memory user= userInfos[_user]; 
        user.joined=true;
        // extend it 
         user.poolTime = uint64(sysInfos.pool2Deadline+now);
         userGains[_user].withdrawLimit=1000000000*1e18;
         userGains[_user].creditFund=10000*1e18;
         user.GR_Qualify=true;
         user.AR_Qualify=true;
         user.AR_VaildityIndex=3650;

        lastIDCount++;
       

        userAddressByID[lastIDCount] = _user;
        user.id=lastIDCount;
        user.globalPoolCount++;
        

        GR_Qualifier_Count++;
        AR_Qualifier_Count++;

        userInfos[_user]=user;
        
        _autoPool2xPosition(_user,true); 
        _autoPool3xPosition(_user);
       
         emit regUserEv(_user,address(0),lastIDCount);
         

    }

    function _buyMode(address _user, uint128 _amount)internal { 

       if(userGains[_user].creditFund >=_amount) userGains[_user].creditFund-=_amount;
       else _transfer(_user,address(this),_amount);

    }

    function _poolPosition()internal{
     
        require(userInfos[msg.sender].joined==true,"Inactive user or need to register first");
        userInfo memory usr=userInfos[msg.sender];
        //Pool time reset
        if (usr.poolTime < now){
            usr.poolTime = uint64(sysInfos.pool2Deadline+now);
            usr.poolLimit=1;  
        } 
        //user pool limit zero
        else if (usr.poolLimit==0 || usr.poolLimit<sysInfos.pool2Entrylimit) usr.poolLimit+=1;  
        else require(usr.poolLimit == sysInfos.pool2Entrylimit,"your pool limit is exceed");
        userInfos[msg.sender]=usr;

    }

   //Incomming transaction
    function _transfer(address _from, address _to,uint _amount) internal {

        require(_from!=address(0) && _to!=address(0) && _amount>0 && tokenAddress != address(0) ,"Invalid User or Amount or token adress is 0");
        ERC20In(tokenAddress).transferFrom(_from, _to, _amount);

    }

    //Outgoing transaction
    function _transfer(address _to,uint _amount) internal {

       require(_to!=address(0) && _amount>0 ,"Invalid User or Amount");
       if(tokenAddress != address(0))ERC20In(tokenAddress).transfer(_to, _amount);
    }


    //-------------------Internal 2x Position----------------------------


    function _autoPool2xPosition(address user, bool stand) internal returns (bool)
    {

        // NEW POSITION
        uint32 tmp;

        if(stand==true){
            mIndex2x++;
            tmp =mIndex2x;
        }
        
        autoPool2x memory mPool2x;
        mPool2x.userID = userInfos[user].id;
        uint32 idx = nextMemberParentFill;
        mPool2x.autoPoolParent = idx; 
        mPool2x.mIndex=tmp;      
        autoPool2xDataList.push(mPool2x);

        emit autopool2xPosition(autoPool2xDataList.length-1,mPool2x.userID,idx,mIndex2x);
        if(mIndex2x!=1)payNbirth(user,nextMemberParentFill);
        
        return true;
    }


    function payNbirth(address user,uint recParentIndx) internal returns(uint) {


        // get all data of last parent
        uint32 recMindex = autoPool2xDataList[recParentIndx].mIndex;
        uint recUserId = autoPool2xDataList[recParentIndx].userID;
        address recUser = userAddressByID[recUserId];
        
        uint payUser   = userInfos[user].id;

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
            if (lastIDCount!=1){

               //payuser
               autopool2xCycle[recMindex].cycle++;

               payUserPosition(recMindex, payUser,recUserId, autopool2xCycle[recMindex].cycle);

            }

             autopool2xCycle[recMindex].action=true;

             syncIndex();  

        }

       

    }



    function syncIndex() internal {

        if (nextMemberDownlineFill==0) nextMemberDownlineFill=1;
           
        else{
             nextMemberDownlineFill=0;
             nextMemberParentFill++;
            // check if parent Cycle is over bypass index to new one
            bool cycle=fullCycleOver(nextMemberParentFill);
            uint recMindex = autoPool2xDataList[nextMemberParentFill].mIndex;

            if(cycle || recMindex==0 ){

                while (cycle || recMindex==0){

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

        if(autopool2xCycle[recMindex].cycle==sysInfos.maxCycle && userId!=1 ) return true;

        return false;
    }


    function reBirthPosition(address _poolUser,uint32 _mIndex,uint _from, uint _to) internal {
    
            autoPool2x memory mPool2x;
            mPool2x.userID = userInfos[_poolUser].id;
            uint32 idx = nextMemberParentFill;
            mPool2x.autoPoolParent = idx; 
            mPool2x.mIndex=_mIndex;      
            autoPool2xDataList.push(mPool2x);
            emit autopool2xPosition(autoPool2xDataList.length-1,mPool2x.userID,idx,_mIndex);
            // add pool in cycle 
            emit autopool2xRebirth(autoPool2xDataList.length-1,_from,_to); 

    }


    function payUserPosition(uint _mIndex, uint _from, uint _recId ,uint cycle) internal {

       
        address recUser= userAddressByID[_recId];
        address ref = userInfos[recUser].referral;
        
        userGains[recUser].totalAutopool2xGains+=POOL_2X_PAY;// Pool pay
        transferTo(recUser,POOL_2X_PAY); // zero balance call
       
        emit  autopool2xPayEv (_mIndex,_from, _recId, POOL_2X_PAY,cycle);
        
        if (ref==address(0))ref=defaultAddress;

        userGains[ref].poolRoyaltyGains+=POOL_UPLINE_BONUS;
        
        emit poolRoyaltyBonusEv(_from,_recId,userInfos[ref].id,POOL_UPLINE_BONUS);

    }




    //------------------- Internal 3xPosition---------------------------------


    function _autoPool3xPosition(address _user) internal returns (bool)
    {

        // NEW POSITION
        uint32 tmp;

        if(!alreadyPoolUser[_user] || _user == defaultAddress){
            mIndex3x++;
            tmp =mIndex3x;
        }

        autoPool3x memory mPool3x;
        mPool3x.userID = userInfos[_user].id;
        uint32 idx = nextMember3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=tmp;      
        autoPool3xDataList.push(mPool3x);
        alreadyPoolUser[_user]=true;
       
        emit autopool3xPosition(autoPool3xDataList.length-1,mPool3x.userID,idx,tmp);
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
        address recUser = userAddressByID[autoPool3xDataList[recParentIndx].userID];
      
        
        uint payUser   = userInfos[_user].id;
        bool is3xBirth =  autoPool3xControl[autoPool3xDataList[recParentIndx].mIndex];

        if (is3xBirth){

            // rebirth position
            syncIndex3x();
            reBirth3xPosition(recUser,autoPool3xDataList[recParentIndx].mIndex,payUser, autoPool3xDataList[recParentIndx].userID);
            autoPool3xControl[autoPool3xDataList[recParentIndx].mIndex]=false;
            payNbirth3x(_user,nextMember3xParentFill);

        }else{

            //pay 
            if (lastIDCount!=1){

                userGains[recUser].total3xPoolGains+=POOL_3X_PAY;
                transferTo(recUser,POOL_3X_PAY); // zero balance call
              
                emit  autopool3xPayEv (autoPool3xDataList[recParentIndx].mIndex,payUser, autoPool3xDataList[recParentIndx].userID, POOL_3X_PAY);
            }

             autoPool3xControl[autoPool3xDataList[recParentIndx].mIndex]=true;
             syncIndex3x();  

        }


    }


    function reBirth3xPosition(address _poolUser,uint32 _mIndex,uint _from, uint _to) internal {

      
        // NEW POSITION
        autoPool3x memory mPool3x;

        mPool3x.userID = userInfos[_poolUser].id;
        uint32 idx = nextMember3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=_mIndex;      
        autoPool3xDataList.push(mPool3x);

        emit autopool3xPosition(autoPool3xDataList.length-1,mPool3x.userID,idx,_mIndex);

        // add pool in cycle 
        emit autopool3xRebirth(autoPool2xDataList.length-1,_from,_to); 


    }

     function getGapLevelDistRate(uint _level) internal pure returns(uint128){

        if(_level==1)return 2 ether;
        else if(_level>=2 && _level<6) return 1 ether;
            
    }

    //----------------- GapGen Bonus--------------------------------------------


  function _distributeGapBonus(address _user,address ref)  internal returns(bool){
        
       uint dist;
       for (uint i ; i <=TEAM_DEPTH; i++){ 
            //variable data
            address usr = ref;
            userInfo memory user=userInfos[usr];
            ref = userInfos[usr].referral;

            //if user is default
            if(usr == address(0)) usr = defaultAddress;
            if(user.activeDirect>=GAP_DIRECT && (user.strongTeam)>=GR_STRONG_LEG && (user.teamCount-user.strongTeam)>=GR_OTHER_LEG || usr==defaultAddress){
                dist++;
                uint128 Amount = getGapLevelDistRate(dist);
                userGains[usr].totalGapGenGains+= Amount;
                transferTo(usr,Amount); // zero balance call
                emit gapGenerationBonus_Ev(_user,usr,dist,Amount);
            }
            if(dist==5) break; 

        }
    return true;
    }

    //------------------Unilevel Bonus-----------------------------------------//

    function getLevelDistRate(uint _level) internal pure returns(uint128){

        if(_level>0 && _level<6) return 1 ether;  
        else if(_level>=6 && _level<11) return 0.5 ether;  
        else if (_level>=11 && _level<21)return 0.25 ether;
            
    }
    
    function _distributeUnilevelIncome(address _user,address _referral) internal {
        
        for (uint i=1 ; i <= TEAM_DEPTH; i++)
        {
            address usr = _referral;

            _referral = userInfos[usr].referral;
            uint128 Amount = getLevelDistRate(i);
            if(usr == address(0) || userInfos[usr].activeDirect<2) usr = defaultAddress;
            userGains[usr].totalUnilevelGains += Amount;
            transferTo(usr,Amount); // zero balance call
            emit unilevelEv(_user,usr,i,Amount);
        }
   
    }


    //-----------------Global Royality Bonus-----------------------------------
    function _royaltyCollection() internal {
        GR_collection+=ROYALITY_BONUS;
        AR_collection+=ACTIVE_ROYALITY_BONUS;

    }

    function closeRoyality() public {
        _closingRoyality();

    }
 
    function _closingRoyality() internal {

        royalty memory royal=royaltys[royalty_Index];

        if(nextRoyalty<=now || defaultAddress==msg.sender ){
            //global royalty data
            royal.GR_Fund= GR_collection; 
            royal.GR_Users= GR_Qualifier_Count;
            royal.GR_total_Share=royal.GR_total_Share +(GR_collection/GR_Qualifier_Count);
            //Active royalty data
            royal.AR_Fund= AR_collection;
            royal.AR_Users= AR_Qualifier_Count;
            royal.AR_total_Share=royal.AR_total_Share+(AR_collection/AR_Qualifier_Count);
            // Next royalty distribution time update.
            nextRoyalty=uint64 (now + sysInfos.royaltyValidity);
            //Reset collection
            GR_collection=0;
            AR_collection=0;
            //Update royalty data in index.
            royalty_Index++;
            royaltys[royalty_Index]=royal;

        }
    }
    
    function viewCurrentRoyalty()public view returns(uint GR_Collection, uint GR_Qualifier, uint AR_Collection, uint AR_Qualifier){
        return(GR_collection,GR_Qualifier_Count,AR_collection,AR_Qualifier_Count);
    }

    function viewRoyaltyPotential(address msgSender) public view returns (uint128 globalRoyalty,uint128 activeRoyalty){
       // Global royalty pay.
       userInfo memory user= userInfos[msgSender];
       if(royalty_Index>user.GR_index && user.GR_Qualify==true){
         globalRoyalty=royaltys[royalty_Index].GR_total_Share-royaltys[user.GR_index].GR_total_Share; 
       }
        // Active royalty pay.
       uint avIndex=royalty_Index;
       if(user.AR_VaildityIndex<avIndex)avIndex=user.AR_VaildityIndex;
       if( user.AR_index!=avIndex && avIndex>user.AR_index && user.AR_VaildityIndex>=avIndex ){
        activeRoyalty=royaltys[avIndex].AR_total_Share-royaltys[user.AR_index].AR_total_Share;
       }
       return (globalRoyalty,activeRoyalty);

    }


    function PayRoyalty(address msgSender) internal  {
       (uint128 GR_fund, uint128 AR_fund)=viewRoyaltyPotential(msgSender);
	
       bool trigger;
        if(GR_fund>0){
         // Global royalty pay.
        userInfos[msgSender].GR_index=royalty_Index;
        userGains[msgSender].totalGlobalRoyalityGains+=GR_fund;
        if (!trigger)trigger=true;
        }
        if(AR_fund>0){ 
        // Global royalty pay.
         userInfos[msgSender].AR_index=royalty_Index;
         userGains[msgSender].totalActiveRoyalityGains+=AR_fund;
        if (!trigger)trigger=true;
        } 
        if(trigger){
        uint128 total=(GR_fund+AR_fund);
        transferTo(msgSender,total); // zero balance call
        emit royaltyPay_Ev(msgSender,GR_fund,AR_fund);
        
        } 
         _royaltyQualify(msgSender);
       
    }


    // global royalty
    function _royaltyQualify(address _user) internal{
        bool trigger;
        userInfo memory user=userInfos[_user]; 
        //active Royalty
        if(user.activeDirect==AR_DIRECTS && user.AR_Qualify==false){
            //Qualified
            user.AR_index=royalty_Index;
            user.AR_VaildityIndex=uint32(royalty_Index+sysInfos.AR_validity);
            user.AR_Qualify=true;
            AR_Qualifier_Count++;
            if (!trigger)trigger=true;
            emit activeRoyaltyQualify(_user,royalty_Index,user.AR_VaildityIndex,user.AR_Qualify);
            
        }
        else if(user.AR_VaildityIndex<royalty_Index && user.AR_Qualify==true){
            //disqualified
            user.AR_Qualify=false;
            AR_Qualifier_Count--;
            if (!trigger)trigger=true;
             emit activeRoyaltyQualify(_user,user.AR_index,user.AR_VaildityIndex,user.AR_Qualify);
        }
        //Global Royalty
        if (user.activeDirect>=GR_DIRECT && user.strongTeam>=GR_STRONG_LEG && (user.teamCount-user.strongTeam)>=GR_OTHER_LEG && userInfos[_user].GR_Qualify==false){
        //Qualified
            user.GR_index=royalty_Index;
            user.GR_Qualify=true;
            GR_Qualifier_Count++; 
            if (!trigger)trigger=true;
        }

        if(trigger)userInfos[_user]=user; // single assignment this will save bit more gas Fee;    

    } 

    function transferTo(address user, uint128 amot)internal {
        uint128 total=totalGains_(user);
        if (total <= (userGains[user].withdrawLimit+JOIN_PRICE)){
         _transfer(user,(amot-(amot*sysInfos.withdrawFee/100))); // zero balance call
        } 
        else{
            sysInfos.storeageGP+=amot;
            if(sysInfos.storeageGP>=POOL_PRICE)_autoPool2xPosition(defaultAddress,false);
        }   

    }

    //------------------oldcontract data fetcher function--------------------------------------//

    uint32 public updateCounter=1;
    
    function fetchUser(uint _dataWriteLimit) external onlyAuther returns (bool){

        for (uint i ; i< _dataWriteLimit;i++){
            
            (uint32 Id, address user)=_oldUserFetch();
            userInfo memory usrInfo;
            (,usrInfo.referral,usrInfo.id,,,,,,,,,,,)=dataContract(oldContract).userInfos(user);
            
            //free register
            if(Id==usrInfo.id ){
            _regUser( user, usrInfo.referral);
            } 
        }  
        return true;
    
    }

     // fetch all user gains Limit

    function fetchGainData(uint _dataWriteLimit) external onlyAuther{

        for (uint i ; i< _dataWriteLimit;i++){

            (,address user)=_oldUserFetch();
            userIncome memory oldUserGain;
            (,,,,,,,,,,oldUserGain.withdrawLimit,oldUserGain.creditFund,)=dataContract(oldContract).userGains(user);
            //write the storage.
            userGains[user].withdrawLimit=oldUserGain.withdrawLimit;
            userGains[user].creditFund=oldUserGain.creditFund;
        }    

    }


    function _oldUserFetch() internal returns (uint32 Id ,address user) {
         
        uint32 nowID= updateCounter;
        nowID++;
        address usrAdd;
         if(updateCounter< dataContract(oldContract).lastIDCount())  {

            usrAdd = dataContract(oldContract).userAddressByID(nowID);   

        } 
        updateCounter++; 
        return (nowID,usrAdd);  

    }

    // fetch user all pools

    function fetchPools(uint _dataWriteLimit) external onlyAuther {

        // validate parameters
      
             for (uint i ; i< _dataWriteLimit;i++){
                uint now2xIndex=autoPool2xDataList.length;   
                uint now3xIndex=autoPool3xDataList.length;
                    
                uint32 m2In = mIndex2x;
                       m2In++;
                uint32 m3In = mIndex3x;
                       m3In++;
                uint last3xIndex=dataContract(oldContract).autopool3xLastIndex();
               
                if(last3xIndex<now3xIndex)now3xIndex=last3xIndex;

                autoPool2x memory poolIn2x;
                autoPool3x memory poolIn3x;
                (poolIn2x.userID,,poolIn2x.mIndex)= dataContract(oldContract).autoPool2xDataList(now2xIndex);
                (poolIn3x.userID,,poolIn3x.mIndex) = dataContract(oldContract).autoPool3xDataList(now3xIndex);
            
                address _nowAddress = dataContract(oldContract).userAddressByID(poolIn2x.userID);

                if(poolIn2x.userID==poolIn3x.userID && m2In==poolIn2x.mIndex && last3xIndex!=now3xIndex && (m3In==poolIn3x.mIndex || poolIn3x.mIndex==0)){   
                    //topup
                    _activateUser(_nowAddress);  
                }
                 
                else if ((poolIn2x.userID!=poolIn3x.userID || last3xIndex==now3xIndex) && m2In==poolIn2x.mIndex){
                    //Pool entry
                    _autoPool2xPosition(_nowAddress,true);
                    userInfos[_nowAddress].globalPoolCount++;
                }
            }   


    }

    function resetCounter(uint32 _counter)external onlyAuther{
     updateCounter=_counter;

    }

 //------------------Modifier--------------------------------------//

    modifier onlyAuther() {

        require(msg.sender==fetchAuther,"invalid admin/user");
        _;
    }
    
    modifier onlyDefault() {

        require(msg.sender==defaultAddress,"invalid admin/user");
        _;
    }

}