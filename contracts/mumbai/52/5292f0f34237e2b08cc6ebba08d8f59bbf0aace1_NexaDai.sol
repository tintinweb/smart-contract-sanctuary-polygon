/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
pragma solidity 0.5.10; 



//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface ERC20In{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);

 }
  interface dataContract{

     function userInfos(address) external returns ( bool joined,address referral,uint32 id,uint32 activeDirect,uint32 teamCount,uint32 poolLimit,uint64 strongTeam,bool GR_Qualify,bool AR_Qualify,uint32 GR_index,uint32 AR_index,uint32 AR_VaildityIndex,uint32 globalPoolCount,uint64 poolTime);
     function userGains(address) external returns ( uint128 totalSponserGains,uint128 totalUnilevelGains,uint128 totalGapGenGains,uint128 totalGlobalRoyalityGains,uint128 totalActiveRoyalityGains,uint128 totalAutopool2xGains,uint128 poolSponsorGains,uint128 poolRoyaltyGains,uint128 total3xPoolGains,uint128 totalWithdrawn,uint128 withdrawLimit,uint128 creditFund,uint128 transferGains,uint32 topup_Count);
     function totalGains_(address) external returns(uint);
     function royalty_Index()external returns (uint);
     function royaltys(uint)external returns(uint128 GR_Fund, uint32 GR_Users,uint128 GR_total_Share,uint128 AR_Fund, uint32 AR_Users,uint128 AR_total_Share);
     function autoPool2xDataList(uint) external returns ( uint32 userID,uint32 autoPoolParent,uint32 mIndex);
     function autoPool3xDataList(uint) external returns ( uint32 userID,uint32 autoPoolParent,uint32 mIndex);
     function autopool3xLastIndex() external returns (uint);
     function lastIDCount() external returns (uint);
     function userAddressByID(uint)external returns (address);
     
      
 }





contract NexaDai{


//-------------------[PRICE CHART STORAGE]----------------

    
    uint128 constant JOIN_PRICE=45e18; // join price / entry price
    uint128 constant POOL_PRICE=12e18;// pool price

    uint128 constant SPONSER_PAY = 10e18;

    // pool
    uint128 constant POOL_2X_PAY = 10e18;
    uint128 constant POOL_3X_PAY = 4e18;
    uint128 constant POOL_UPLINE_BONUS=1e18;
  
    uint constant GAP_DIRECT =2;
    uint constant GR_DIRECT =3;
    uint constant GR_STRONG_LEG =2;
    uint constant GR_OTHER_LEG =2;
    uint constant AR_DIRECTS=4;
   

    uint32 constant TEAM_DEPTH =20;
    uint128 constant ROYALITY_BONUS = 1e18;
    uint128 constant ACTIVE_ROYALITY_BONUS = 2e18;
   
    //Daily Collection
    uint128  royalty_collection;

     // Royalty storage
    uint64 public nextRoyalty;
    uint32 public royalty_Index;
   
    // Royalty Qualifire count
    uint32  GR_Qualifier_Count;
    uint32  AR_Qualifier_Count;

    uint32 public lastIDCount;

    address poolFinder;
    bool dataFetchDone;
   


// Replace below address with main token token
    address public tokenAddress;
    address  constant defaultAddress=0x2B2FE21A85B033c3E64DF5861c08f5C3504c0c30;// this is 1 number ID.
    address constant oldContract= 0xe4dd72fF19F0B2aeE716900E7D30926f06183C76;// old contract for data fetching.
   

    struct sysInfo{

        uint32 withdrawFee; // withdraw fee that is dedcut when you will proccess for withdraw.
        uint64 pool2Deadline; // this pool deadline time frame
        uint32 pool2Entrylimit; // number of entry you can take in pool within deadline.
        uint32 maxCycle;// Pool 2X max cyclye distribution.
        uint32 AR_validity; // Active royalty validity.
        uint64 royaltyValidity;// Royalty closing time.
        uint128 totalFee; // total fee of system.
        uint128 storeageGP; // global pool auto genrated fund.
        uint32 helpPoolCount;//global pool help from systems.
        bool poolSpan;// pool cycle aftre activation.
    }
    sysInfo public sysInfos ;
    
    
   struct userInfo {
        bool            joined;     // for checking user active/deactive status.
        address         referral;   // user sponser / ref. 
        uint32          id;        // user id.
        uint32          activeDirect; // total active direct users.
        uint32          teamCount;   // total team count of user.
        uint32          poolLimit;  // eligible entry limit within pooltime.
        uint64          strongTeam; // Power leg of user.
        bool            GR_Qualify; // Global royalty qualify done or not.
        bool            AR_Qualify; // Active royalty qualify done or not.
        uint32          GR_index; //Global royaty index till paid.
        uint32          AR_index; // Active royaty index till paid.
        
        uint32          AR_VaildityIndex;// Validity of active royaltys index.
        uint32          globalPoolCount;// How much pool you buy.
        uint64          poolTime;      //running pool time   
        
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
        uint32 AR_Users; 
        
        uint128 GR_total_Share;
        uint128 AR_Fund;
     
        uint128 AR_total_Share; 
    }

    struct poolCycle{

        uint16 cycle;
        bool action;
    }



    //------------------------------autopool storage ------------------------


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


    // Mapping data
    mapping (uint => royalty) public royaltys;
    mapping (address => userInfo) public userInfos;
    mapping (address=> userIncome) public userGains;
  
    mapping (uint => address) public userAddressByID;


    // FINANCIAL EVENT
    event regUserEv(address user, address referral,uint id);
    event directIncomeEv(address _from,address _to,uint _amount);
    event investEv(address user);
    event reInvestEv(address user);
    event pool_3X_EV(address user);
    event pool_2X_EV(address user);
    event unilevelEv(address _from , address _to,uint level,uint _amount);
    event gapGenerationBonus_Ev(address from,address to ,uint level,uint amount);
    
   

    event poolSponsorBonusEv(uint _fromId,uint _toId ,uint _amount);


    //ROYALTY EVENT
    event royaltyPay_Ev(address user,uint GR_amount,uint AR_amount);
    event activeRoyaltyQualify(address user,uint currentIndex, uint validityIndex,bool status);

    //LOST INCOME EVENT
    event lostIncome_Ev(address user,uint types, uint amount);

    // AUTOPOOL EVENTS 

    event autopool2xPayEv (uint _index,uint _from,uint _toUser, uint _amount,uint cycle);
    event autopool2xRebirth (uint _index, uint _fromUser, uint _toUser);
    event autopool2xPosition (uint _index,uint usrID, uint _parentIndex, uint _mainIndex);
    event autopool3xPayEv (uint _index,uint _from,uint _toUser, uint _amount);
    event autopool3xRebirth (uint _index, uint _fromUser, uint _toUser);
    event autopool3xPosition (uint _index,uint usrID, uint _parentIndex,uint _mainIndex);
    event poolRoyaltyBonusEv(uint _payId,uint _fromId ,uint _toId ,uint _amount);
    event poolCycles (uint mIndex, uint cycle);
  

    constructor() public {   

    sysInfos.maxCycle=15;

    // default user 
    sysInfos.pool2Deadline =1200;
    sysInfos.pool2Entrylimit=2;
    sysInfos.royaltyValidity=300;
    nextRoyalty=uint64(now)+sysInfos.royaltyValidity;

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
     require(_referral!=address(0),"EC-1");
     require(userInfos[msgSender].referral==address(0),"EC-2");
     require(userInfos[_referral].joined==true,"EC-3");
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
        require(userInfos[msgSender].referral!= address(0) || msgSender==defaultAddress,"EC-3");
        userGains[msgSender].withdrawLimit += JOIN_PRICE*3;
        // internal buy mode.
        if(tokenAddress!=address(0))_buyMode(msgSender,JOIN_PRICE);
       
        _activateUser(msgSender);
       

        ERC20In(tokenAddress).transfer(defaultAddress, (JOIN_PRICE*sysInfos.withdrawFee/100)); //System fee.
       
        emit investEv(msgSender);
        return true;
    }




    //Invest buy from your gains.
   
    function _activateUser(address msgSender) internal {

        

        address ref = userInfos[msgSender].referral;
    
       
        _royaltyQualify(msgSender);
        bool userJoin = userInfos[msgSender].joined;

        if (userJoin==false){
            
             userInfos[msgSender].poolTime = uint64(sysInfos.pool2Deadline+now);
             userInfos[msgSender].joined= true;
             userInfos[ref].activeDirect++;
            

            //AR VaildityIndex ++
            if(userInfos[ref].AR_Qualify==true && userInfos[ref].AR_VaildityIndex>=royalty_Index){
                userInfos[ref].AR_VaildityIndex+=sysInfos.AR_validity;
                emit activeRoyaltyQualify(ref,userInfos[ref].AR_index,userInfos[ref].AR_VaildityIndex,userInfos[ref].AR_Qualify);

            }
            else{
                 //AR Qualify update
                if(userInfos[ref].AR_index<userInfos[ref].AR_VaildityIndex && userInfos[ref].AR_VaildityIndex<royalty_Index)PayRoyalty(ref);


                if(userInfos[ref].AR_VaildityIndex!=0 && userInfos[ref].AR_Qualify==false && userInfos[ref].AR_VaildityIndex<royalty_Index){
                     userInfos[ref].AR_index=royalty_Index;
                     userInfos[ref].AR_VaildityIndex=uint32(royalty_Index+sysInfos.AR_validity);
                     userInfos[ref].AR_Qualify=true;
                     AR_Qualifier_Count++;
                     emit activeRoyaltyQualify(ref,royalty_Index,userInfos[ref].AR_VaildityIndex,userInfos[ref].AR_Qualify);    
                }   
            
            }
            
        
            _updateTeamNum(ref) ;
            _autoPool2xPosition(msgSender,true);

             userInfos[msgSender].globalPoolCount++;
            
                           
        }
        else{
            _autoPool2xPosition(msgSender,sysInfos.poolSpan);
            if(!sysInfos.poolSpan)userInfos[msgSender].globalPoolCount++;
        } 

        userGains[msgSender].topup_Count++;
     
        
        uint128 payAmount=(_payCulculate(ref,1,(SPONSER_PAY+POOL_UPLINE_BONUS)));

        if(payAmount>0){
        userGains[ref].totalSponserGains+=payAmount;
        emit directIncomeEv(msgSender,ref,SPONSER_PAY);
        emit poolSponsorBonusEv(userInfos[msgSender].id,userInfos[ref].id,POOL_UPLINE_BONUS);
        _transferTo(ref,payAmount); // zero balance call pool_&_Sponsor
        } 

        _royaltyCollection();
        _closingRoyality();
        _royaltyQualify(ref);
        // all position and distribution call should be fire from here
        _autoPool3xPosition(msgSender,userJoin);
        _distributeUnilevelIncome(msgSender,ref);
        _distributeGapBonus(msgSender,ref);
        //pool event
        emit pool_2X_EV (msgSender);
        emit pool_3X_EV (msgSender);


    }



    //Global pool 2X buy from your credit fund and wallet.
    function buyPool_2X() external  returns(bool) {
        _poolPosition();
        address msgSender=msg.sender;
        address ref =userInfos[msgSender].referral;

        if(tokenAddress!=address(0))_buyMode(msgSender,POOL_PRICE);
        sysInfos.totalFee+=uint128(POOL_PRICE*sysInfos.withdrawFee/100);

        _autoPool2xPosition(msgSender,true);
        userInfos[msgSender].globalPoolCount++;
        
        _closingRoyality();
        PayRoyalty(msgSender);

        uint128 payAmount=_payCulculate(ref,7,POOL_UPLINE_BONUS);

        if(payAmount>0){
            userGains[ref].totalSponserGains+=payAmount;
            emit poolSponsorBonusEv(userInfos[msgSender].id,userInfos[ref].id,POOL_UPLINE_BONUS);
            _transferTo(ref,payAmount); // zero balance call pool_Sponsor
        }
        emit pool_2X_EV (msgSender);
       
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

     
        uint128 total;
        
        total=(userGains[_user].totalSponserGains + userGains[_user].totalUnilevelGains +userGains[_user].totalGapGenGains+ userGains[_user].totalGlobalRoyalityGains+userGains[_user].totalActiveRoyalityGains+userGains[_user].totalAutopool2xGains+userGains[_user].poolRoyaltyGains+userGains[_user].total3xPoolGains);

        return(total);

    }
    

    // Transfer from credit fund .
    event transferFromCredit_Ev(address from, address to , uint amount);

    function transferCredit(address _to, uint128 _amount) external  returns(bool) {
        address msgSender=msg.sender;
        require(userInfos[msgSender].referral != address(0) || msgSender==defaultAddress,"EC-3");
        require(userGains[msgSender].creditFund >=_amount,"EC-10");

        userGains[msgSender].creditFund-=_amount;
        userGains[_to].creditFund+=_amount;
        
        emit transferFromCredit_Ev (msgSender,_to,_amount);       
        return true;

    }

      // Deposit credits fund .
        event depositCredit_Ev(address _user , uint amount);

        function depositFund(uint128 _amount) external  returns(bool) {

            address msgSender=msg.sender;

        require(userInfos[msgSender].referral!=address(0),"EC3");
        userGains[msgSender].creditFund+=_amount;
         _buyMode(msgSender,_amount);

        emit depositCredit_Ev (msgSender,_amount);       

        return true;

    }



//-------------------------------ADMIN CALLER FUNCTION -----------------------------------

    //----------------------THIS IS JUST TEST FUNCTION WE CAN REPLACE THIS FUNCTION TO ANY -- MULTIsIGN CALL FUNCTION--------


    function setPrams(uint32 withdrwalFee, uint64 setPoolTime, uint16 setPoolLimit,uint16 _maxCycle,uint64 _royaltyClosingTime, uint32 _AR_validity, bool _poolSpan)  external  returns(bool){
        require(msg.sender==defaultAddress,"EC-4");
        sysInfos.withdrawFee= withdrwalFee;
        sysInfos.pool2Deadline= setPoolTime;
        sysInfos.pool2Entrylimit= setPoolLimit;
        sysInfos.maxCycle= _maxCycle;
        sysInfos.royaltyValidity=_royaltyClosingTime;
        sysInfos.AR_validity=_AR_validity;
        sysInfos.poolSpan=_poolSpan;
        return true;
    }
    function updateTokenAddress(address newTokenAddress) external returns (bool) {
        
        tokenAddress=newTokenAddress;
        dataFetchDone=true;

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
        _autoPool3xPosition(_user,false);
       
         emit regUserEv(_user,address(0),lastIDCount);
         

    }

    function _buyMode(address _user, uint128 _amount)internal { 

       if(userGains[_user].creditFund >=_amount) userGains[_user].creditFund-=_amount;
       else ERC20In(tokenAddress).transferFrom(_user, address(this), _amount); 

    }

    function _poolPosition()internal{

        // userInfo memory usr=userInfos[msg.sender];
        address msgSender = msg.sender;
        uint current = now;
     
        require(userInfos[msgSender].joined==true,"EC-5");
        //Pool time reset
        if (userInfos[msgSender].poolTime < current){
            userInfos[msgSender].poolTime = uint64(sysInfos.pool2Deadline+current);
            userInfos[msgSender].poolLimit=1;  
        
        }else{
            
            userInfos[msgSender].poolLimit = userInfos[msgSender].poolLimit==0?1:userInfos[msgSender].poolLimit<sysInfos.pool2Entrylimit?userInfos[msgSender].poolLimit+1:0;
            require(userInfos[msgSender].poolLimit!=0,"EC-6");
                
        }

         //userInfos[msg.sender]=usr;
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
            ref = userInfos[usr].referral;
            //if user is default
            if(usr == address(0)) usr = defaultAddress;
            if(userInfos[usr].activeDirect>=GAP_DIRECT && (userInfos[usr].strongTeam)>=GR_STRONG_LEG && (userInfos[usr].teamCount-userInfos[usr].strongTeam)>=GR_OTHER_LEG || usr==defaultAddress){
                dist++;
                uint128 Amount = getGapLevelDistRate(dist);
                uint128 payAmount=_payCulculate(usr,3,Amount);
               if(payAmount>0){
                    userGains[usr].totalGapGenGains+= payAmount;
                    emit gapGenerationBonus_Ev(_user,usr,dist,Amount);
                   _transferTo(usr,payAmount); // zero balance call gap_bonus
               
               }
                
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
            uint128 payAmount=_payCulculate(usr,2,Amount);

               if(payAmount>0){
                    userGains[usr].totalUnilevelGains+= payAmount;
                     emit unilevelEv(_user,usr,i,Amount);
                   _transferTo(usr,payAmount); // zero balance call gap_bonus
               
               }

            
        }
   
    }

    //-----------------Global Royality Bonus-----------------------------------
    function _royaltyCollection() internal {
        royalty_collection+=ROYALITY_BONUS;
    }
    function closeRoyality() public {
        _closingRoyality();
    }
 
    function _closingRoyality() internal {
        royalty memory royal=royaltys[royalty_Index];
        uint32 tmpGrQ = GR_Qualifier_Count;
        uint32 tmpArQ = AR_Qualifier_Count;
        uint current = now;
        if(nextRoyalty<=current || defaultAddress==msg.sender ){
            //global royalty data
            royal.GR_Fund= royalty_collection; 
            royal.GR_Users= tmpGrQ;
            royal.GR_total_Share=royal.GR_total_Share +(royal.GR_Fund/tmpGrQ);
            //Active royalty data
            royal.AR_Fund= (2*royal.GR_Fund);
            royal.AR_Users= tmpArQ;
            royal.AR_total_Share=royal.AR_total_Share+(royal.AR_Fund/tmpArQ);
            // Next royalty distribution time update.
            nextRoyalty= uint64(current + sysInfos.royaltyValidity);
            //Reset collection
            delete royalty_collection;
            //Update royalty data in index.
            royalty_Index++;
            royaltys[royalty_Index]=royal;
        }
    }
    
    function viewCurrentRoyalty()public view returns(uint GR_Collection, uint GR_Qualifier, uint AR_Collection, uint AR_Qualifier){
        uint tmpRoyalColl = royalty_collection;
        return(tmpRoyalColl,GR_Qualifier_Count,(2*tmpRoyalColl),AR_Qualifier_Count);
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

    function claimRoyalty() external returns (bool){
        PayRoyalty(msg.sender);
        return true;
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

              uint128 payAmount=_payCulculate(msgSender,5,(GR_fund+AR_fund));

               if(payAmount>0){
                    userGains[msgSender].totalUnilevelGains+= payAmount;
                    emit royaltyPay_Ev(msgSender,GR_fund,AR_fund);
                   _transferTo(msgSender,payAmount); // zero balance call gap_bonus
               
               }
        
            }
       
         _royaltyQualify(msgSender);
       
    }


    // global royalty
    function _royaltyQualify(address _user) internal{
  

        //active Royalty
        if(userInfos[_user].activeDirect==AR_DIRECTS && userInfos[_user].AR_Qualify==false){
            //Qualified
            userInfos[_user].AR_index=royalty_Index;
            userInfos[_user].AR_VaildityIndex=uint32(royalty_Index+sysInfos.AR_validity);
            userInfos[_user].AR_Qualify=true;
            AR_Qualifier_Count++;
           
            emit activeRoyaltyQualify(_user,royalty_Index,userInfos[_user].AR_VaildityIndex,userInfos[_user].AR_Qualify);
            
        }
        else if(userInfos[_user].AR_VaildityIndex<royalty_Index && userInfos[_user].AR_Qualify==true){
            //disqualified
            userInfos[_user].AR_Qualify=false;
            AR_Qualifier_Count--;
          
             emit activeRoyaltyQualify(_user,userInfos[_user].AR_index,userInfos[_user].AR_VaildityIndex,userInfos[_user].AR_Qualify);
        }
        //Global Royalty
        if (userInfos[_user].activeDirect>=GR_DIRECT && userInfos[_user].strongTeam>=GR_STRONG_LEG && (userInfos[_user].teamCount-userInfos[_user].strongTeam)>=GR_OTHER_LEG && userInfos[_user].GR_Qualify==false){
        //Qualified
            userInfos[_user].GR_index=royalty_Index;
            userInfos[_user].GR_Qualify=true;
            GR_Qualifier_Count++; 
          
        }

    } 

    function _transferTo(address user,uint128 amot)internal {
        if(!dataFetchDone)return;
          
          if(tokenAddress!=address(0)) ERC20In(tokenAddress).transfer(user,(amot-(amot*sysInfos.withdrawFee/100))); // zero balance call    
         // else console.log(user,(amot-(amot*sysInfos.withdrawFee/100))); 

    }

    function _payCulculate (address to_usr,uint16 typ,uint128 amot)internal  returns (uint128){
       
       if(!dataFetchDone)return(amot);
        
        uint128 total=totalGains_(to_usr);
        uint128 expPay =(userGains[to_usr].withdrawLimit+JOIN_PRICE);
       
        if (total<expPay && (expPay-total)>0 ){
            expPay=(expPay-total);// remaining balance.
            if (amot<=expPay)expPay=amot;
            // lost income if big from remaining balance.
            if((amot-expPay)!=0 && amot>(amot-expPay)){
                sysInfos.storeageGP+=(amot-expPay);
                emit lostIncome_Ev(to_usr,typ,(amot-expPay));
            }
        }
        // lost income if remaining is exust.
         else{
            sysInfos.storeageGP+=amot;
            emit lostIncome_Ev(to_usr,typ,amot);
            expPay=0;
        }   
        return(expPay);

    }



 

    function helpPool() external {
        
        if(sysInfos.storeageGP>=POOL_PRICE) {
            _autoPool2xPosition(defaultAddress,false);
            sysInfos.helpPoolCount++;
            
        }

    }

   

    //--------------------------------AUTOPOOL ----------------------------------


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
        uint32 recUserId = autoPool2xDataList[recParentIndx].userID;
 
        
        uint payUser   = userInfos[user].id;

        bool is2xBirth =  autopool2xCycle[recMindex].action;

        if (is2xBirth){

            // rebirth position

            syncIndex();

            reBirthPosition(recMindex,payUser, recUserId);

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

        
        if (nextMemberDownlineFill==0){

            uint32 nextParent= nextMemberParentFill;
            
            bool cycle=fullCycleOver(nextParent);

            uint recMindex = autoPool2xDataList[nextParent].mIndex;
            uint defID = autoPool2xDataList[nextParent].userID;
           
            if(cycle || recMindex==0 && defID!=1){

                while (cycle || recMindex==0 && defID!=1){

                    nextMemberParentFill++;
                    nextParent =nextMemberParentFill;
                    cycle=fullCycleOver(nextParent);
                    recMindex = autoPool2xDataList[nextParent].mIndex;
                    defID = autoPool2xDataList[nextParent].userID;
                }
                delete nextMemberDownlineFill;

            }
            else nextMemberDownlineFill=1;
            

        }
           
        else{
             delete nextMemberDownlineFill;
             nextMemberParentFill++;
            // check if parent Cycle is over bypass index to new one
            uint32 nextParent= nextMemberParentFill;
            bool cycle=fullCycleOver(nextParent);
            uint recMindex = autoPool2xDataList[nextParent].mIndex;
            
            if(cycle || recMindex==0){

                while (cycle || recMindex==0){

                    nextMemberParentFill++;
                    nextParent= nextMemberParentFill;
                    cycle=fullCycleOver(nextParent);
                    recMindex = autoPool2xDataList[nextParent].mIndex;
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


    function reBirthPosition(uint32 _mIndex,uint _from, uint32 _to) internal {
    
            autoPool2x memory mPool2x;

            mPool2x.userID = _to;
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
       
        uint128 payAmount=_payCulculate(recUser,6,POOL_2X_PAY);

        if(payAmount>0){
            userGains[recUser].totalAutopool2xGains+=payAmount;
            emit  autopool2xPayEv (_mIndex,_from, _recId, POOL_2X_PAY,cycle);
            _transferTo(recUser,payAmount); // zero balance call gap_bonus
        
        } 
    
        if (ref==address(0))ref=defaultAddress;

        payAmount=_payCulculate(ref,8,POOL_UPLINE_BONUS);
        
        if(payAmount>0){

            userGains[ref].poolRoyaltyGains+=payAmount;
            emit poolRoyaltyBonusEv( _from, _recId , userInfos[recUser].id , POOL_UPLINE_BONUS);
            _transferTo(ref,payAmount); // zero balance call gap_bonus
        
        } 
    


    }


    //------------------- AUTO POOL 3xPosition---------------------------------


    function _autoPool3xPosition(address _user ,bool _joined) internal returns (bool)
    {

        // NEW POSITION
        uint32 tmp;

        if(!_joined || _user == defaultAddress){
            mIndex3x++;
            tmp =mIndex3x;
        }

        autoPool3x memory mPool3x;
        mPool3x.userID = userInfos[_user].id;
        uint32 idx = nextMember3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=tmp;      
        autoPool3xDataList.push(mPool3x);
        
       
        emit autopool3xPosition(autoPool3xDataList.length-1,mPool3x.userID,idx,tmp);

        if(tmp!=1) payNbirth3x(_user,nextMember3xParentFill);

        return true;
    }


    function syncIndex3x() internal {

        if (nextMember3xDownlineFill==0) nextMember3xDownlineFill=1;
        else if (nextMember3xDownlineFill==1) nextMember3xDownlineFill=2;
        // new member fill
        else{

            delete nextMember3xDownlineFill;
            nextMember3xParentFill++;
            uint32 nextParent= nextMember3xParentFill;
            uint recMindex = autoPool3xDataList[nextParent].mIndex;

            if(recMindex==0){

                while(recMindex==0){

                    nextMember3xParentFill++;
                    nextParent= nextMember3xParentFill;
                    recMindex = autoPool3xDataList[nextParent].mIndex;
                }

            }


        }
        
    }


    function payNbirth3x(address _user, uint recParentIndx ) internal {


        // get all data of last parent
        // address recUser = userAddressByID[autoPool3xDataList[recParentIndx].userID];

        
        uint payUser   = userInfos[_user].id;
        uint32 mIndex = autoPool3xDataList[recParentIndx].mIndex;
        bool is3xBirth =  autoPool3xControl[mIndex];

        if (is3xBirth){

            // rebirth position
            syncIndex3x();
            reBirth3xPosition(mIndex,payUser, autoPool3xDataList[recParentIndx].userID);
            autoPool3xControl[mIndex]=false;
            payNbirth3x(_user,nextMember3xParentFill);

        }else{

            //pay 
            if (lastIDCount!=1){

               uint128 payAmount=_payCulculate(_user,9,POOL_3X_PAY);
                if(payAmount>0){
                    userGains[_user].total3xPoolGains+=payAmount;
                    emit  autopool3xPayEv (mIndex,payUser, autoPool3xDataList[recParentIndx].userID, POOL_3X_PAY);
                    _transferTo(_user,payAmount); // zero balance call gap_bonus
                
                } 
               
            }

             autoPool3xControl[mIndex]=true;
             syncIndex3x();  

        }


    }


    function reBirth3xPosition(uint32 _mIndex,uint _from, uint32 _to) internal {


        // NEW POSITION
        autoPool3x memory mPool3x;

        mPool3x.userID = _to;
        uint32 idx = nextMember3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=_mIndex;      
        autoPool3xDataList.push(mPool3x);


        emit autopool3xPosition(autoPool3xDataList.length-1,mPool3x.userID,idx,_mIndex);

        // add pool in cycle 
        emit autopool3xRebirth(autoPool2xDataList.length-1,_from,_to); 

    }


     //------------------oldcontract data fetcher function--------------------------------------//
    uint32 public updateCounter=1;
    
    function fetchUser(uint _dataWriteLimit) external  returns (bool){

        require(msg.sender==defaultAddress,"EC-4");
        require (!dataFetchDone,"EC-8");

        for (uint i ; i< _dataWriteLimit;i++){
            
            (uint32 Id, address user)=_oldUserFetch();
            
            (,address referral,uint32 id,,,,,,,,,,,)=dataContract(oldContract).userInfos(user); // here we can optimize code
            //free register
            if(Id==id ){
            _regUser( user,referral);
            } 
        }  
        return true;
    
    }



     // fetch all user gains Limit

    function fetchGainData(uint _dataWriteLimit) external {
    require (!dataFetchDone,"EC-8");
    require(msg.sender==defaultAddress,"EC-4");
        for (uint i ; i< _dataWriteLimit;i++){

            (,address user)=_oldUserFetch();
            PayRoyalty(user);
            (,,,,,,,,,,uint128 withdrawLimit,,uint128 creditFund,)=dataContract(oldContract).userGains(user);
            //write the storage.
            uint tot=dataContract(oldContract).totalGains_(user);
            userGains[user].withdrawLimit=uint128(withdrawLimit+tot);
            userGains[user].creditFund= creditFund;
            
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

    function fetchPools(uint _dataWriteLimit) external  {
        require(msg.sender==defaultAddress,"EC-4");
        require (!dataFetchDone,"EC-8");
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
                    //_autoPool2xPosition(_nowAddress,true);
                    userInfos[_nowAddress].globalPoolCount++;
                }
                
                uint nowRoy=royalty_Index;
                nowRoy++;
                uint oldRoy= dataContract(oldContract).royalty_Index();
                
                (,,,uint128 AR_Fund,uint32 AR_Users,)=dataContract(oldContract).royaltys(nowRoy);

                if(royalty_Index < oldRoy && AR_Fund==royaltys[nowRoy].AR_Fund && AR_Users==royaltys[nowRoy].AR_Users){
                    _closingRoyality();

                }
               
            }   


    }

    function resetCounter(uint32 _counter)external {
        require(msg.sender==defaultAddress,"EC-4");
     updateCounter=_counter;

    }




}