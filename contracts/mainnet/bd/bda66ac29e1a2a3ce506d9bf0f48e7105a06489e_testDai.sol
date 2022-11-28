/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// import "hardhat/console.sol";
pragma solidity 0.5.10; 

contract owned
{
    address internal owner;
    address internal newOwner;


    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
 }


 interface ERC20In{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);

 }
 



contract testDai is owned {


//-------------------[PRICE CHART STORAGE]----------------

    
    uint128 constant SPONSER_PAY = 10e18;

    uint128 constant JOIN_PRICE=33e18; // join price / entry price
    uint128 constant POOL_PRICE=12e18;// pool price

    // pool
    uint128 constant POOL_2X_PAY = 10e18;
    uint128 constant POOL_3X_PAY = 4e18;
    uint128 constant POOL_UPLINE_BONUS=1e18;
  
    uint constant GAP_DIRECT =2;
    uint constant GR_DIRECT =3;
    uint constant GR_STRONG_LEG =2;
    uint constant GR_OTHER_LEG =3;

    uint constant TEAM_DEPTH =20;
    uint128 constant ROYALITY_BONUS = 1e18;
    uint128 constant ACTIVE_ROYALITY_BONUS = 2e18;

    uint constant ROYALTY_VALIDITY=300; // just for testing....
    uint constant AR_DIRECTS=4;
    uint constant AR_BONUS=2e18;
    
    // Royalty storage
    uint32 public royalty_Index;
    uint public nextRoyalty;
    //Daily Collection
    uint128  GR_collection;
    uint128  AR_collection;
    // Royalty Qualifire count
    uint32  GR_Qualifier_Count;
    uint32  AR_Qualifier_Count;


    uint32 public lastIDCount;
    bool USDT_INTERFACE_ENABLE; // for switching Token standard


// Replace below address with main token token
    address public tokenAddress;
    address  defaultAddress;
    struct sysInfo{

        uint8 withdrawFee; // withdraw fee that is dedcut when you will proccess for withdraw.
        uint64 pool2Deadline; // this pool deadline time frame
        uint8 pool2Entrylimit; // number of entry you can take in pool within deadline.
        uint8 maxCycle;// Pool 2X max cyclye distribution.
        uint8 maxDepth;// Pool 2X max cyclye distribution.
        uint8 AR_validity; // Active royalty validity.
        uint128 totalFee; // total fee
    }
    sysInfo public sysInfos ;
    
    
   struct userInfo {
        bool        joined;     // for checking user active/deactive status
        address     referral;   // user sponser / ref 
        uint32        id;             // user id
        uint64     activeDirect;    // active
        uint64     teamCount;      // team count
        uint8      poolLimit;     // eligible entry limit within pooltime.
        uint64     strongTeam;
        bool       GR_Qualify;
        bool       AR_Qualify;
        uint32     GR_index; //Global royaty index till paid.
        uint32     AR_index; // Active royaty index till paid.
        uint32     AR_VaildityIndex;// Validity of active royaltys index.
        uint32	   globalPoolCount;// who much pool you buy.
        uint64   poolTime;      //running pool time 

    }


    struct userIncome{
       
        uint128 totalSponserGains; // direct income.
        uint128 totalUnilevelGains; // unilevel income.
        uint128 totalGapGenGains;  // GapGen income.
        uint128 totalGlobalRoyalityGains; //Global Royality.
        uint128 totalActiveRoyalityGains; //Active Royality.
        uint128 totalAutopool2xGains; // autoPool2x.
        uint128 poolSponsorGains; // Pool Sponsor.
        uint128 poolRoyaltyGains; // Pool Royalty.
        uint128 total3xPoolGains;// 3xpool income.
        uint128 totalWithdrawn;// total fund he withdraw from system.
        uint128 withdrawLimit; // user eligible limit that he can withdraw.
        uint128 creditFund;    //transfer fund from other user.
        uint32 topup_Count;// who much Topup you have done 
        
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
    mapping (address=>userIncome) public  userGains;

    mapping (uint => address) public userAddressByID;
    mapping (address=>bool) public  alreadyPoolUser;

    mapping(uint64=>poolCycle) autopool2xCycle;

    // FINANCIAL EVENT
    event regUserEv(address user, address referral);
    event directIncomeEv(address _from,address _to,uint _amount);
    event unilevelEv(address _from , address _to, uint _amount);
    event investEv(address user, uint position);
    event reInvestEv(address user, uint position);
    event pool_3X_EV(address user, uint position);
    event pool_2X_EV(address user, uint position);
    event gapGenerationBonus_Ev(address _user,address ref ,uint amount);
    event withdrawEv(address user, uint _amount);
   
    // AUTOPOOL EVENTS
    event autopool2xPayEv (uint _index,uint _from,uint _toUser, uint _amount,uint cycle);
    event autopool2xRebirth (uint _index, uint _fromUser, uint _toUser);
    event autopool2xPosition (uint _index, uint _parentIndex, uint _mainIndex);
    event autopool3xPayEv (uint _index,uint _from,uint _toUser, uint _amount);
    event autopool3xRebirth (uint _index, uint _fromUser, uint _toUser);
    event autopool3xPosition (uint _index, uint _parentIndex);
    event poolSponsorBonusEv(uint _from,uint _to ,uint _amount);
    event poolRoyaltyBonusEv(uint _from,uint _to ,uint _amount);
    event poolCycles (uint mIndex, uint cycle);
  
   

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
   

    uint constant POOL2x_PAY_AMOUNT = 10e18;
    uint constant POOL3x_PAY_AMOUNT = 4e18;

    constructor(address _defaultAddress) public {    
    sysInfos.maxCycle=15;

    // default user 

    sysInfos.pool2Deadline =5;
    sysInfos.maxDepth=20;
    nextRoyalty=uint64(block.timestamp)+ROYALTY_VALIDITY;
    defaultAddress=_defaultAddress;

    _defaultUser(_defaultAddress);


    }

     //Pay registration 
    
     function payRegUser( address _referral) external returns(bool) 
    {
       regUser(_referral);
       userGains[msg.sender].creditFund=500e18;
       buyTopup();
        return true;
    }
    
    //free registration
    function regUser( address _referral ) public returns(bool) 
    {
        require(userInfos[defaultAddress].referral!=_referral,"Invalid referal");
        require(userInfos[msg.sender].referral==address(0),"You are alrady register");
        require(userInfos[_referral].joined==true,"Your referral is not activated");
        if (_referral==address(0)){
            _referral= defaultAddress;
        }
        lastIDCount++;
        userInfos[msg.sender].referral=_referral;
        userInfos[msg.sender].id=lastIDCount;
        userAddressByID[lastIDCount] = msg.sender;
        emit regUserEv(msg.sender, _referral);

      
        return true;
    }

    //Invest buy from your credit fund and wallet.
  
    function buyTopup() public returns(bool) {

        require(userInfos[msg.sender].referral!= address(0),"Invalid user or need to register first");
        // internal buy mode.
        _buyMode(msg.sender,JOIN_PRICE);

        // Comman function.
        if(userInfos[msg.sender].joined==true){
        userGains[msg.sender].withdrawLimit += JOIN_PRICE*4;
        }
        _activateUser();
       
        
        emit investEv(msg.sender,1);
        return true;

    }


    //Invest buy from your gains.

    function reTopup() external returns(bool) {

        require(userInfos[msg.sender].referral!= address(0),"Invalid user or need to register first");
        uint totalGains= totalGains_();
        require(totalGains>userGains[msg.sender].totalWithdrawn,"invalid Income");
        require(totalGains-userGains[msg.sender].totalWithdrawn>=JOIN_PRICE,"You don't have avilable balance");
    
         // Comman function.
        if(userInfos[msg.sender].joined==true){
		userGains[msg.sender].withdrawLimit += JOIN_PRICE*3;
        }
         _activateUser();

       
        userGains[msg.sender].totalWithdrawn += JOIN_PRICE;
        emit reInvestEv(msg.sender,1);

        return true;

    }

    function _activateUser() internal {
        address ref = userInfos[msg.sender].referral;

        if(userInfos[msg.sender].joined==true && userInfos[msg.sender].activeDirect>=GR_DIRECT){
        _royaltyQualify(msg.sender);
        }
        if (userInfos[msg.sender].joined==false){
            userInfo memory referr = userInfos[ref];
            
            if(referr.AR_VaildityIndex>0 && referr.AR_VaildityIndex>royalty_Index){
            referr.AR_VaildityIndex+=sysInfos.AR_validity;
            }
            else if(referr.AR_VaildityIndex>0 && referr.AR_VaildityIndex<royalty_Index){
            referr.AR_VaildityIndex=royalty_Index+sysInfos.AR_validity;
            }
          
             userInfos[msg.sender].poolTime = uint64(sysInfos.pool2Deadline+block.timestamp);
             userInfos[msg.sender].joined= true;
             userInfos[ref].activeDirect++;
           
             userGains[msg.sender].withdrawLimit += JOIN_PRICE*4;

            _updateTeamNum(ref) ;
            
           
            
        }
        
        userGains[msg.sender].topup_Count+=1;
        
        _royaltyCollection();
        _royaltyQualify(ref);
        _closingRoyality();

        // all position and distribution call should be fire from here
        _autoPool3xPosition(msg.sender);
        _distributeDirectBonus(ref);
        _distributeUnilevelIncome(msg.sender,ref);
        _distributeGapBonus(msg.sender,ref);
        //pool event
        emit pool_3X_EV (msg.sender,1); 

    }



    //Global pool 2X buy from your credit fund and wallet.
    function buyPool_2X( uint8 position) public returns(bool) {
       
        uint realPosition= _poolPosition(msg.sender, position);  // Pool limit and pool time setter.
          //_buyMode(msg.sender,realPosition*POOL_PRICE);
        for(uint i=1;i<=realPosition;i++){
            // all position and distribution call should be fire from here
            _autoPool2xPosition(msg.sender);
        }
    
        userInfos[msg.sender].globalPoolCount+=uint32(realPosition);
        _royaltyQualify(msg.sender);
        _closingRoyality();
        emit pool_2X_EV (msg.sender,realPosition);
        return true;
    }

  
    //Global pool 2X buy from your gains and limit.
    function rebuyPool_2X(uint8 position) public returns(bool) {
       
        uint128 realPosition= _poolPosition(msg.sender, position);  // Pool limit and pool time setter.
        uint totalGains= totalGains_();
        require(totalGains>userGains[msg.sender].totalWithdrawn,"Invalid income");
        uint128 poolAmount = realPosition*POOL_PRICE;
        require(totalGains-userGains[msg.sender].totalWithdrawn>=poolAmount && userGains[msg.sender].withdrawLimit>=poolAmount ,"Your avilable or Limit fund is low");
        userGains[msg.sender].withdrawLimit-=poolAmount;
        userGains[msg.sender].totalWithdrawn+=poolAmount;
        userInfos[msg.sender].globalPoolCount+=uint32(realPosition);
         for(uint i=1;i<=realPosition;i++){
            // all position and distribution call should be fire from here
            _autoPool2xPosition(msg.sender);
        } 
        _royaltyQualify(msg.sender);
        _closingRoyality();
        emit pool_2X_EV (msg.sender,realPosition);
       
        return true;


    }

    // fallback function

    function () payable external {
       
    }

    //  withdraw
   

    function autopool2xLastIndex() view public returns(uint){

        if (autoPool2xDataList.length>0){

            return autoPool2xDataList.length-1;
        }else{

            revert();
        }


    }

    function autopool3xLastIndex() view public returns(uint){

        if (autoPool3xDataList.length>0){

            return autoPool3xDataList.length-1;
        }else{

            revert();
        }


    }


    function totalGains_() public view returns (uint128){

        userIncome memory gains=userGains[msg.sender];
        uint128 total;
        total+=gains.totalSponserGains;
        total+=gains.totalUnilevelGains; 
        total+=gains.totalGapGenGains;  
        total+=gains.totalGlobalRoyalityGains; 
        total+=gains.totalActiveRoyalityGains;
        total+=gains.totalAutopool2xGains; 
        total+=gains.poolSponsorGains; 
        total+=gains.poolRoyaltyGains;
        total+=gains.total3xPoolGains;
        
        return(total);

    }
    
    function withdrawFund() external returns (bool) {

        uint128 totalGains= totalGains_();
        require(totalGains>userGains[msg.sender].totalWithdrawn,"invalid Income");
        require(userInfos[msg.sender].joined==true,"User is inactive or need to register first");
       
        uint128 balance=totalGains-userGains[msg.sender].totalWithdrawn;

        if(userGains[msg.sender].withdrawLimit<balance){
           balance= userGains[msg.sender].withdrawLimit;
        }
        userGains[msg.sender].withdrawLimit-=balance;
        userGains[msg.sender].totalWithdrawn+=balance;

        uint128 maintainfee=balance*sysInfos.withdrawFee/100;
        sysInfos.totalFee+=maintainfee;
    
      // _transfer(msg.sender,balance-maintainfee);
        _royaltyQualify(msg.sender);
        _closingRoyality();

       emit withdrawEv(msg.sender,balance);
       return true;

    }
     // tranfer from gains to gain user.
        event transferGainsToGains_Ev( address from, address to , uint amount);

        function transferGains(address _to, uint128 _amount) external returns(bool) { 

        uint totalGains= totalGains_();

        require(totalGains>userGains[msg.sender].totalWithdrawn,"invalid income");
        require(userInfos[msg.sender].joined==true,"Invalid user or need to register first");
        require(userInfos[_to].referral!= address(0),"Recipient user is not registered");
        require(totalGains-userGains[msg.sender].totalWithdrawn>=_amount && userGains[msg.sender].withdrawLimit >= _amount,"insuffcient limit or avilable fund");
       
        userGains[msg.sender].withdrawLimit-=_amount;
        userGains[msg.sender].totalWithdrawn+=_amount;
     
        userGains[_to].withdrawLimit+=_amount;

        emit transferGainsToGains_Ev (msg.sender,_to,_amount);       

        return true;

    }

     // tranfer from gains to credit.
        event transferGainsToCredit_Ev(address from, address to , uint  amount);

        function transferGainsToCredit(address _to, uint128 _amount) external returns(bool) { 

        uint128 totalGains = totalGains_();

        require(totalGains>userGains[msg.sender].totalWithdrawn,"invalid income");

        uint128 taxDeductable = uint128(_amount*sysInfos.withdrawFee/100);

        require(userInfos[msg.sender].joined==true,"Invalid user or need to register first");
        require(userInfos[_to].referral!= address(0),"Recipient user is not registered");
        require(totalGains-userGains[msg.sender].totalWithdrawn>=_amount+taxDeductable && userGains[msg.sender].withdrawLimit >= _amount+taxDeductable,"insuffcient limit or avilable fund");
       
        userGains[msg.sender].withdrawLimit-=(_amount+taxDeductable);
        userGains[msg.sender].totalWithdrawn+= (_amount+taxDeductable);
        userGains[_to].creditFund+=_amount;
        sysInfos.totalFee+=taxDeductable;

        emit transferGainsToCredit_Ev (msg.sender,_to,_amount+taxDeductable);       

        return true;

    }

    // Transfer from credit fund .
        event transferFromCredit_Ev(address from, address to , uint amount);

        function transferCredit(address _to, uint128 _amount) external  returns(bool) {
        require(userInfos[msg.sender].referral!=address(0) || msg.sender==defaultAddress," Inactive user or need to register first");
        require(userGains[msg.sender].creditFund >=_amount,"Your credit fund balance is low");

        userGains[msg.sender].creditFund-=_amount;
        userGains[_to].creditFund+=_amount;

        emit transferFromCredit_Ev (msg.sender,_to,_amount);       

        return true;

    }

    // Transfer from deposit credits fund .
        event depositCredit_Ev(address _user , uint amount);

        function depositFund(uint128 _amount) external  returns(bool) {

        require(userInfos[msg.sender].referral!=address(0)," Inactive user or need to register first");
        userGains[msg.sender].creditFund+=_amount;
       // _transfer(msg.sender,address(this),_amount);

        emit depositCredit_Ev (msg.sender,_amount);       

        return true;

    }
	



//-------------------------------ADMIN CALLER FUNCTION -----------------------------------

    //----------------------THIS IS JUST TEST FUNCTION WE CAN REPLACE THIS FUNCTION TO ANY -- MULTIsIGN CALL FUNCTION--------
    function withdrawFee() external returns(bool) {

        require(defaultAddress==msg.sender || userInfos[defaultAddress].referral==msg.sender,"You are not eligible for withdraw");
        //_transfer(msg.sender,sysInfos.totalFee);
        sysInfos.totalFee=0;
        return true;

    }

    function setPrams(uint8 withdrwalFee, uint64 setPoolTime, uint8 setPoolLimit,uint8 _maxCycle, uint8 _maxDepth, uint8 _AR_validity) external onlyOwner returns(bool){

        sysInfos.withdrawFee= withdrwalFee;
		sysInfos.pool2Deadline= setPoolTime;
        sysInfos.pool2Entrylimit= setPoolLimit;
        sysInfos.maxCycle= _maxCycle;
        sysInfos.maxDepth= _maxDepth;
        sysInfos.AR_validity=_AR_validity;
        return true;
    }

    function changetokenaddress(address newtokenaddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        tokenAddress = newtokenaddress;

        return("token address updated successfully");
    }


    function Switch_Interface () external onlyOwner  returns (string memory) {

        USDT_INTERFACE_ENABLE=!USDT_INTERFACE_ENABLE;
        
        if (USDT_INTERFACE_ENABLE==true){

            return "USDT INTERFACE ENABLED";

        }else{

            return "ERC20 INTERFACE ENABLED";
        }
    }





    //---------------------Internal/Optimized Function-----------------------------



function _updateTeamNum(address ref) private {

        for(uint i; i < TEAM_DEPTH; i++){

            address usr = ref;
            ref= userInfos[usr].referral;
            uint32 strongLeg;
            if(usr != address(0))userInfos[usr].teamCount++;
            strongLeg=uint32 (userInfos[usr].teamCount);
            if(ref == address(0)) break;
            if(userInfos[ref].strongTeam<strongLeg)userInfos[ref].strongTeam=strongLeg;

         } 
            

    }



    function getLevelDistRate(uint _level) internal pure returns(uint128){

        if(_level>0 && _level<6)
            return 1 ether;
        else if(_level>=6 && _level<11)
            return 0.5 ether;
        else if (_level>=11 && _level<21)
            return 0.25 ether;
        
    }



    function _defaultUser(address _user) internal {
        userInfo storage user= userInfos[_user]; 
        user.joined=true;
        // extend it 
         user.poolTime = uint64(sysInfos.pool2Deadline+block.timestamp);
         userGains[_user].withdrawLimit=1000000000*1e18;
         userGains[_user].creditFund=10000*1e18;
         user.GR_Qualify=true;
         user.AR_Qualify=true;
         user.AR_VaildityIndex=3650;

        lastIDCount++;

        userAddressByID[lastIDCount] = _user;
        user.id=lastIDCount;
        user.globalPoolCount+=5;

             GR_Qualifier_Count++;
             AR_Qualifier_Count++;


         for(uint i=1;i<=user.globalPoolCount;i++){
            // Global pool pre position
            _autoPool2xPosition(_user);
        }
         for(uint i=1;i<=3;i++){
            // infinity pool pre position
            _autoPool3xPosition(_user);
        }

         emit regUserEv(_user,address(0));
         

    }
    
    

    // internal calll

    function _buyMode(address _user, uint128 _amount)internal {
        

       if( userGains[_user].creditFund >=_amount){

            userGains[_user].creditFund-=_amount;
        }
         // Invest from DApp Wallet fund.
        else{

             _transfer(_user,address(this),_amount);
        }

    }

    function _poolPosition(address _user, uint8 position)internal returns(uint128){
        require(userInfos[_user].joined==true,"Inactive user or need to register first");
        require(position>0 && position<= sysInfos.pool2Entrylimit," invalid position entry");

      uint8 realPosition;
        //Pool time reset
        if (userInfos[_user].poolTime < block.timestamp){
            userInfos[_user].poolTime = uint64(sysInfos.pool2Deadline+block.timestamp);
            realPosition = position;  
            userInfos[_user].poolLimit = position;
            
        } 
        //user pool limit zero
        else if (userInfos[_user].poolLimit==0 ){ 
            realPosition = position;
            userInfos[_user].poolLimit = position;
        }
        else {
           
            realPosition=sysInfos.pool2Entrylimit-userInfos[_user].poolLimit;
            require(realPosition != 0,"your pool limit is exceed");
            userInfos[_user].poolLimit += realPosition;

        }
        return realPosition;

    }


    function _transfer(address _from, address _to,uint _amount) internal {

        require(_from!=address(0) && _to!=address(0) && _amount>0 ,"Invalid User or Amount");

        if(USDT_INTERFACE_ENABLE==true){

            tokenInterface(tokenAddress).transferFrom(_from, _to, _amount);
        }else{

            ERC20In(tokenAddress).transferFrom(_from, _to, _amount);
        }

    }


    function _transfer(address _to,uint _amount) internal {

        require(_to!=address(0) && _amount>0 ,"Invalid User or Amount");

        if(USDT_INTERFACE_ENABLE==true){

            tokenInterface(tokenAddress).transfer(_to, _amount);
        }else{

            ERC20In(tokenAddress).transfer(_to, _amount);
        }

    }


    //--------------------Internal Direct Bonus------------

    
    function _distributeDirectBonus(address _ref)  internal {
        userGains[_ref].totalSponserGains+=SPONSER_PAY;
        emit directIncomeEv(msg.sender,_ref,SPONSER_PAY);

    }

    //-------------------Internal 2x Position----------------------------



    function _autoPool2xPosition(address user) internal returns (bool)
    {

        // NEW POSITION
        mIndex2x++;
        autoPool2x memory mPool2x;
        mPool2x.userID = userInfos[user].id;
        uint32 idx = nextMemberParentFill;
        mPool2x.autoPoolParent = idx; 
        mPool2x.mIndex=mIndex2x;      
        autoPool2xDataList.push(mPool2x);

        emit autopool2xPosition(autoPool2xDataList.length-1,idx,mIndex2x);


        // upline bonus to buyer referral
        if(lastIDCount!=1){

            address ref = userInfos[user].referral;

            if(ref==address(0)){

                ref=defaultAddress;
            }
            userGains[ref].poolSponsorGains+=POOL_UPLINE_BONUS;
          

            emit poolSponsorBonusEv(userInfos[user].id,userInfos[ref].id,POOL_UPLINE_BONUS);

        }


      
        if(mIndex2x!=1){ // skip first autopool pay

            payNbirth(user,nextMemberParentFill);
            // syncIndex();
        }
        
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

               payUserPosition(recMindex, payUser ,recUserId, autopool2xCycle[recMindex].cycle);

            }

             autopool2xCycle[recMindex].action=true;

             syncIndex();  

        }

       

    }



    function syncIndex() internal {

        if (nextMemberDownlineFill==0){

            nextMemberDownlineFill=1;

        }else{

            nextMemberDownlineFill=0;
            // check if parent Cycle is over bypass index to new one
            bool cycle=fullCycleOver(nextMemberParentFill);

            if(cycle){

                while (cycle){

                    nextMemberParentFill++;
                    cycle=fullCycleOver(nextMemberParentFill);
                }

            }else{

                nextMemberParentFill++;
            }


        }
        
    }


    function fullCycleOver(uint index) internal view returns(bool){

        // get parent and then child
        uint64 recMindex = autoPool2xDataList[index].mIndex;

        if(autopool2xCycle[recMindex].cycle==sysInfos.maxCycle){

            return true;
        }
          return false;
    }


    function reBirthPosition(address _poolUser,uint32 _mIndex,uint _from, uint _to) internal {
    

            autoPool2x memory mPool2x;
            mPool2x.userID = userInfos[_poolUser].id;
            uint32 idx = nextMemberParentFill;
            mPool2x.autoPoolParent = idx; 
            mPool2x.mIndex=_mIndex;      
            autoPool2xDataList.push(mPool2x);
            emit autopool2xPosition(autoPool2xDataList.length-1,idx,_mIndex);
            // add pool in cycle 
            emit autopool2xRebirth(autoPool2xDataList.length-1,_from,_to); 

    }


    function payUserPosition(uint _mIndex, uint _from ,uint _to, uint cycle) internal {

        // address fromUser = userAddressByID[_from];
        address toUser= userAddressByID[_to];
        userGains[toUser].totalAutopool2xGains+=POOL_2X_PAY;
        
        emit  autopool2xPayEv (_mIndex,_from, _to, POOL_2X_PAY,cycle);

        address user = userAddressByID[_to];
        user= userInfos[user].referral;

        if (user==address(0)){

            user=defaultAddress;
        }

        userGains[user].poolRoyaltyGains+=POOL_UPLINE_BONUS;
       

        emit poolRoyaltyBonusEv(_from,_to,POOL_UPLINE_BONUS);

    }




    //------------------- Internal 3xPosition---------------------------------


    function _autoPool3xPosition(address _user) internal returns (bool)
    {

        // NEW POSITION
        uint32 tmp;

        if(alreadyPoolUser[_user] && _user !=defaultAddress){

        }else{

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
       

        emit autopool3xPosition(autoPool3xDataList.length-1,idx);

        
        if(tmp!=1){ // skip pay in first pool

            payNbirth3x(_user,nextMember3xParentFill);
             
        }
        

        return true;
    }


    function syncIndex3x() internal {

        if (nextMember3xDownlineFill==0){

            nextMember3xDownlineFill=1;

        }else if (nextMember3xDownlineFill==1){

            nextMember3xDownlineFill=2;
        }
        
        else{

            nextMember3xDownlineFill=0;


            uint recMindex = autoPool2xDataList[nextMember3xParentFill].mIndex;

            if(recMindex==0){

                while(recMindex==0){

                    nextMember3xParentFill++;
                    recMindex = autoPool2xDataList[nextMember3xParentFill].mIndex;
                }

            }else{

                 nextMember3xParentFill++;
            }


        }
        
    }


    function payNbirth3x(address _user, uint recParentIndx ) internal {


        // get all data of last parent
        uint32 recMindex = autoPool3xDataList[recParentIndx].mIndex;
        uint recUserId = autoPool3xDataList[recParentIndx].userID;
        address recUser = userAddressByID[recUserId];
        
        uint payUser   = userInfos[_user].id;
        bool is3xBirth =  autoPool3xControl[recMindex];

        if (is3xBirth){

            // rebirth position

            syncIndex3x();

            reBirth3xPosition(recUser,recMindex,payUser, recUserId);

            autoPool3xControl[recMindex]=false;
        

            payNbirth3x(_user,nextMember3xParentFill);

        }else{

            //pay 
            if (lastIDCount!=1){

                userGains[recUser].total3xPoolGains+=POOL_3X_PAY;
              
                emit  autopool3xPayEv (recMindex,payUser, recUserId, POOL_3X_PAY);

            }

             autoPool3xControl[recMindex]=true;
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

        emit autopool3xPosition(autoPool3xDataList.length-1,idx);

        // add pool in cycle 
        emit autopool3xRebirth(autoPool2xDataList.length-1,_from,_to); 


    }

    function getGapLevelDistRate(uint _level) internal pure returns(uint128){

        if(_level==1)
        return 2 ether;
        else if(_level>=2 && _level<6)
        return 1 ether;
            
    }

    //----------------- GapGen Bonus--------------------------------------------


  function _distributeGapBonus(address _user,address ref)  internal returns(bool){
        
       uint dist;
       for (uint i ; i <=sysInfos.maxDepth; i++){ 
            //variable data
            address usr = ref;
            userInfo memory user=userInfos[usr];
            ref = userInfos[usr].referral;
            uint directAct = user.activeDirect;
            uint strongLeg = user.strongTeam;
            uint otherLeg = user.teamCount-strongLeg;
            //if user is default
            if(usr == address(0)) usr = defaultAddress;
    
            
            if(directAct>=GAP_DIRECT && strongLeg>=GR_STRONG_LEG && otherLeg>=GR_OTHER_LEG || usr==defaultAddress){
                dist++;
                uint128 Amount = getGapLevelDistRate(dist);
                userGains[usr].totalGapGenGains+= Amount;
                emit unilevelEv(_user,usr,Amount);
            }
            if(directAct<GAP_DIRECT || strongLeg<GR_STRONG_LEG || otherLeg<GR_OTHER_LEG)
        
            if(dist==5) break; 

        }
    return true;
    }


    

    //------------------Unilevel Bonus-----------------------------------------
    
    function _distributeUnilevelIncome(address _user,address _referral) internal {
        
        for (uint i=1 ; i <= TEAM_DEPTH; i++)
        {
            address usr = _referral;
            uint activeDirect = userInfos[usr].activeDirect;
            _referral = userInfos[usr].referral;
            if(usr == address(0) || activeDirect<2) usr = defaultAddress;

            uint128 Amount = getLevelDistRate(i);
            if(activeDirect>=2 || usr==defaultAddress)userGains[usr].totalUnilevelGains += Amount;
             emit unilevelEv(_user,usr,Amount);
        }
   
    }


    //-----------------Global Royality Bonus-----------------------------------
  function _royaltyCollection() internal {

      GR_collection+=ROYALITY_BONUS;
      AR_collection+=ACTIVE_ROYALITY_BONUS;

  }
 
  function _closingRoyality() internal {

    if(nextRoyalty<=block.timestamp){
     
        uint lastIndex = royalty_Index;
        royalty memory lastIn=royaltys[lastIndex];

        //Update royalty data in index.
        royalty_Index++;
        royalty storage royal=royaltys[royalty_Index];
        
        royal.GR_Fund= GR_collection; 
        royal.GR_Users= GR_Qualifier_Count;
        royal.GR_total_Share=lastIn.GR_total_Share +(GR_collection/GR_Qualifier_Count);

        royal.AR_Fund= AR_collection;
        royal.AR_Users= AR_Qualifier_Count;
        royal.AR_total_Share=lastIn.AR_total_Share+(AR_collection/GR_Qualifier_Count);
        // Next royalty distribution time update.
        nextRoyalty+=ROYALTY_VALIDITY;
    
        GR_collection=0;
        AR_collection=0;
        
    }


  }
    
    function viewCurrentRoyalty()public view returns(uint GR_Collection, uint GR_Qualifier, uint AR_Collection, uint AR_Qualifier){
    return(GR_collection,GR_Qualifier_Count,AR_collection,AR_Qualifier_Count);

    }
    function viewRoyaltyPotential() public view returns (uint128 globalRoyalty,uint128 activeRoyalty){
       
       // Global royalty pay.
       userInfo memory user= userInfos[msg.sender];
       if(royalty_Index>user.GR_index && user.GR_Qualify==true){
         uint gpi =user.GR_index;
         globalRoyalty=royaltys[royalty_Index].GR_total_Share-royaltys[gpi].GR_total_Share;
         
       }
        // Active royalty pay.
       if( royalty_Index>user.AR_index && user.AR_VaildityIndex>=royalty_Index){
        uint api =user.AR_index;
        activeRoyalty=royaltys[royalty_Index].AR_total_Share-royaltys[api].AR_total_Share;
 
       }
       return (globalRoyalty,activeRoyalty);

    }


    function PayRoyalty() internal {
       (uint128 GR_Amount, uint128 AR_Amount)=viewRoyaltyPotential();
    
        if(GR_Amount>0){
         // Global royalty pay.
        userInfos[msg.sender].GR_index=royalty_Index;
        userGains[msg.sender].totalGlobalRoyalityGains+=GR_Amount;
       }
        if(AR_Amount>0){ 
        // Global royalty pay.
         userInfos[msg.sender].AR_index=royalty_Index;
         userGains[msg.sender].totalActiveRoyalityGains+AR_Amount;
         }
       
       
    }


// global royalty
  function _royaltyQualify(address _user) public{

      uint directCount = userInfos[_user].activeDirect;

      //active Royalty
      if(directCount>=AR_DIRECTS && userInfos[_user].GR_Qualify==false){
            //Qualified
            userInfos[_user].AR_index=royalty_Index;
            userInfos[_user].AR_VaildityIndex=uint32(royalty_Index+sysInfos.AR_validity);
            userInfos[_user].GR_Qualify=true;
            AR_Qualifier_Count++;
      }
      else if(userInfos[_user].AR_VaildityIndex<royalty_Index && userInfos[_user].GR_Qualify==true){
          //disqualified
          userInfos[_user].GR_Qualify=false;
          AR_Qualifier_Count--;

      }

      if (directCount>=GR_DIRECT && userInfos[_user].GR_Qualify==false){
    
        if ((userInfos[_user].teamCount-GR_STRONG_LEG)>=GR_OTHER_LEG && userInfos[_user].strongTeam>=GR_STRONG_LEG){
         	//Qualified
            userInfos[_user].GR_index=royalty_Index;
            userInfos[_user].GR_Qualify=true;
            GR_Qualifier_Count++;
        }

      }
       

  }

       

}