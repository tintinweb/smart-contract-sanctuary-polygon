/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

//import "hardhat/console.sol";
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

    
    uint constant SPONSER_PAY = 10e18;

    uint constant JOIN_PRICE=45e18; // join price / entry price
    uint constant POOL_PRICE=12e18;// pool price

    // pool
    uint constant POOL_2X_PAY = 10e18;
    uint constant POOL_3X_PAY = 4e18;
    uint constant POOL_UPLINE_BONUS=1e18;
  
    uint constant GAP_DIRECT =3;
    uint constant GR_DIRECT =4;
    uint constant GR_STRONG_LEG =3;
    uint constant GR_OTHER_LEG =7;

    uint constant TEAM_DEPTH =20;
    uint constant ROYALITY_BONUS = 1e18;
    uint constant ACTIVE_ROYALITY_BONUS = 2e18;

    uint constant ROYALTY_VALIDITY=600; // just for testing....
    uint constant AR_DIRECTS=10;
    uint constant AR_BONUS=2e18;
    
    // Royalty storage
    uint64 public royalty_Index;
    uint public nextRoyalty;
    //Daily Collection
    uint public GR_collection;
    uint public AR_collection;
    // Royalty Qualifire count
    uint public GR_Qualifier_Count;
    uint public AR_Qualifier_Count;


    uint64 public lastIDCount;
    bool USDT_INTERFACE_ENABLE; // for switching Token standard


// Replace below address with main token token
    address public tokenAddress;
    address  defaultAddress;
    struct sysInfo{

        uint withdrawFee; // withdraw fee that is dedcut when you will proccess for withdraw.
        uint pool2Deadline; // this pool deadline time frame
        uint8 pool2Entrylimit; // number of entry you can take in pool within deadline.
        uint8 maxCycle;// Pool 2X max cyclye distribution.
        uint8 maxDepth;// Pool 2X max cyclye distribution.
        uint totalFee; // total fee
    }
    sysInfo public sysInfos ;
    
    
   struct userInfo {
        bool        joined;     // for checking user active/deactive status
        address     referral;   // user sponser / ref 
        uint64        id;             // user id
        uint64     activeDirect;    // active
        uint64     teamCount;      // team count
        address[]  referralList;   // active referral list 
        uint64     GR_index; //Global royaty index till paid.
        uint64     AR_index; // Active royaty index till paid.
        uint64     AR_VaildityIndex;// Validity of active royaltys index.
        uint64	   globalPoolCount;// who much pool you buy.
		uint64	   topup_Count;// who much Topup you have done 
        uint256     creditFund;    //transfer fund from other user.
        uint256     poolTime;      //running pool time 
        uint8       poolLimit;     // eligible entry limit within pooltime.
    }


    struct userIncome{
       
        uint totalSponserGains; // direct income.
        uint totalUnilevelGains; // unilevel income.
        uint totalGapGenGains;  // GapGen income.
        uint totalGlobalRoyalityGains; //Global Royality.
        uint totalActiveRoyalityGains; //Active Royality.
        uint totalAutopool2xGains; // autoPool2x.
        uint poolSponsorGains; // Pool Sponsor.
        uint poolRoyaltyGains; // Pool Royalty.
        uint total3xPoolGains;// 3xpool income.
        uint totalGains; // Total Gain.
        uint   totalWithdrawn;// total fund he withdraw from system.
        uint   withdrawLimit; // user eligible limit that he can withdraw.
        
    }


    struct autoPool2x
    {
        uint userID;
        uint autoPoolParent;
        uint mIndex;
    }
    
    struct autoPool2xPayNbirth{
        uint target;
        uint achieved;
        uint indexPay;
        uint indexRebirth;
        uint cycle;
        uint maxCycle;
        bool isFullBirth;
    }

    struct autoPool3x
    {   uint mIndex;
        uint userID;
        uint autoPoolParent;
    }

    struct royalty
    {   uint GR_Fund;
        uint GR_Users;
        uint GR_total_Share;
        uint AR_Fund;
        uint AR_Users; 
        uint AR_total_Share; 
    }

    // Mapping data
    mapping (uint => royalty) public royaltys;
    mapping (address => userInfo) public userInfos;
    mapping (address=>userIncome) public  userGains;

    mapping(address => mapping(uint256 => address[])) public usersTeam;
    mapping (uint => address) public userAddressByID;
    mapping (address=>bool) public  alreadyPoolUser;

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
    event autopool2xPayEv (uint _index,uint _from,uint _toUser, uint _amount);
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

    mapping(uint => autoPool2xPayNbirth) public autoPoolCycles;  // it wll contain each index cycle stats
    uint mIndex2x;
    uint mIndex3x;
    // uint parentIndx;
    uint nextMemberParentFill;
    uint nextMemberDownlineFill;

    // uint parent3xIndx;
    uint nextMember3xParentFill;
    uint nextMember3xDownlineFill;
    bool is3xBirth= true; // for test purposes

    uint constant POOL2x_PAY_AMOUNT = 10e18;
    uint constant POOL3x_PAY_AMOUNT = 4e18;

    constructor(address _defaultAddress) public {
        
    sysInfos.maxCycle=7;

    // default user 

    sysInfos.pool2Deadline =600; 
    nextRoyalty=now+ROYALTY_VALIDITY;
    defaultAddress=_defaultAddress;

    _defaultUser(_defaultAddress);


    }

     //Pay registration 

     function payRegUser( address _referral) external returns(bool) 
    {
       regUser(_referral);
       buyTopup(1);
        return true;
    }
    
    //free registration
    function regUser( address _referral ) public returns(bool) 
    {
        require(userInfos[defaultAddress].referral!=_referral,"Invalid referal");
        require(userInfos[msg.sender].joined==false,"You are blocked");
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
  
    function buyTopup(uint64 position) public returns(bool) {

        require(userInfos[msg.sender].referral!= address(0),"Invalid user or need to register first");
        uint totalAmount = position*JOIN_PRICE;
        address ref = userInfos[msg.sender].referral;
        // internal buy mode.
       // _buyMode(msg.sender,totalAmount);

    

        // Comman function.
         if (userInfos[msg.sender].joined==false){
            
            if(userInfos[ref].AR_VaildityIndex>0 && userInfos[ref].AR_VaildityIndex<royalty_Index){
            userInfos[ref].AR_VaildityIndex+=uint64(ROYALTY_VALIDITY*30);
            }
            else if(userInfos[ref].AR_VaildityIndex>0 && userInfos[ref].AR_VaildityIndex<royalty_Index){
            userInfos[ref].AR_VaildityIndex+= uint64(now+(ROYALTY_VALIDITY*30));
            }
          
             userInfos[msg.sender].poolTime = sysInfos.pool2Deadline+now;
             userInfos[msg.sender].joined= true;
             userInfos[ref].activeDirect++;
             userInfos[ref].referralList.push(msg.sender);
             _royaltyQualify(ref);
           
            
        }
        userGains[msg.sender].withdrawLimit += totalAmount*3;
        userInfos[msg.sender].globalPoolCount+=position;
        userInfos[msg.sender].topup_Count+=position;

        _royaltyCollection(position);
    
     
        _closingRoyality();
   
        
        emit investEv(msg.sender,position);
        emit pool_2X_EV (msg.sender,position);
        emit pool_3X_EV (msg.sender,position);


        // _buy2xPosition
        // _buy3xPosition

        for(uint i=1;i<=position;i++){

            // all position and distribution call should be fire from here
            _autoPool2xPosition(msg.sender);
            _autoPool3xPosition(msg.sender);
            // distribution cycle
            _distributeDirectBonus(msg.sender);
            _distributeUnilevelIncome(msg.sender);
            _distributeGapBonus(msg.sender);

        }

     

        return true;

    }


    //Invest buy from your gains.

    function reTopup(uint64 position) external returns(bool) {

        require(userInfos[msg.sender].referral!= address(0),"Invalid user or need to register first");
        uint totalAmount =  position*JOIN_PRICE;
        require(userGains[msg.sender].totalGains-userGains[msg.sender].totalWithdrawn>=totalAmount,"You don't have avilable balance");
        
		userGains[msg.sender].withdrawLimit += totalAmount*2;
        userGains[msg.sender].totalWithdrawn += totalAmount;
        userInfos[msg.sender].globalPoolCount+=position;
        userInfos[msg.sender].topup_Count+=position;
        _royaltyCollection(position);
        _closingRoyality();

        for(uint i=1;i<=position;i++){
            // all position and distribution call should be fire from here
            _autoPool2xPosition(msg.sender);
            _autoPool3xPosition(msg.sender);
            // distribution cycle
            _distributeDirectBonus(msg.sender);
            _distributeUnilevelIncome(msg.sender);
            _distributeGapBonus(msg.sender);

        }
        emit reInvestEv(msg.sender,position);
        emit pool_2X_EV (msg.sender,position);
        emit pool_3X_EV (msg.sender,position);

        return true;

    }



    //Global pool 2X buy from your credit fund and wallet.
    function buyPool_2X( uint8 position) public returns(bool) {
       
        uint realPosition= _poolPosition(msg.sender, position);  // Pool limit and pool time setter.
       // _buyMode(msg.sender,realPosition*POOL_PRICE);
        for(uint i=1;i<=realPosition;i++){
            // all position and distribution call should be fire from here
            _autoPool2xPosition(msg.sender);
        }
        userInfos[msg.sender].globalPoolCount+=uint64(realPosition);
        emit pool_2X_EV (msg.sender,realPosition);
        return true;
    }

  
    //Global pool 2X buy from your gains and limit.
    function rebuyPool_2X(uint8 position) public returns(bool) {
       
        uint realPosition= _poolPosition(msg.sender, position);  // Pool limit and pool time setter.
        
        uint poolAmount = realPosition*POOL_PRICE;
        require(userGains[msg.sender].totalGains-userGains[msg.sender].totalWithdrawn>=poolAmount && userGains[msg.sender].withdrawLimit>=poolAmount ,"Your avilable or Limit fund is low");
        userGains[msg.sender].withdrawLimit-=poolAmount;
        userGains[msg.sender].totalWithdrawn+=poolAmount;
        userInfos[msg.sender].globalPoolCount+=uint64(realPosition);
         for(uint i=1;i<=realPosition;i++){
            // all position and distribution call should be fire from here
            _autoPool2xPosition(msg.sender);
        } 
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
    
    function withdrawFund() external returns (bool) {

        require(userInfos[msg.sender].joined==true,"User is inactive or need to register first");
        uint balance=userGains[msg.sender].totalGains-userGains[msg.sender].totalWithdrawn;

        if(userGains[msg.sender].withdrawLimit<balance){
           balance= userGains[msg.sender].withdrawLimit;
        }
        userGains[msg.sender].withdrawLimit-=balance;
        userGains[msg.sender].totalWithdrawn+=balance;

        uint maintainfee=balance*sysInfos.withdrawFee/100;
        sysInfos.totalFee+=maintainfee;
    
      // _transfer(msg.sender,balance-maintainfee);

       emit withdrawEv(msg.sender,balance);
       return true;

    }
     // tranfer from gains to gain user.
        event transferGainsToGains_Ev( address from, address to , uint amount);

        function transferGains(address _to, uint _amount) external returns(bool) { 
        require(userInfos[msg.sender].joined==true,"Invalid user or need to register first");
        require(userInfos[_to].referral!= address(0),"Recipient user is not registered");
        require(userGains[msg.sender].totalGains-userGains[msg.sender].totalWithdrawn>=_amount && userGains[msg.sender].withdrawLimit >= _amount,"insuffcient limit or avilable fund");
       
        userGains[msg.sender].withdrawLimit-=_amount;
        userGains[msg.sender].totalWithdrawn+=_amount;
        userGains[_to].totalGains+=_amount;

        emit transferGainsToGains_Ev (msg.sender,_to,_amount);       

        return true;

    }

     // tranfer from gains to credit.
        event transferGainsToCredit_Ev(address from, address to , uint amount);

        function transferGainsToCredit(address _to, uint _amount) external returns(bool) { 

        uint taxDeductable = _amount*sysInfos.withdrawFee/100;

        require(userInfos[msg.sender].joined==true,"Invalid user or need to register first");
        require(userInfos[_to].referral!= address(0),"Recipient user is not registered");
        require(userGains[msg.sender].totalGains-userGains[msg.sender].totalWithdrawn>=_amount+taxDeductable && userGains[msg.sender].withdrawLimit >= _amount+taxDeductable,"insuffcient limit or avilable fund");
       
        userGains[msg.sender].withdrawLimit-=_amount+taxDeductable;
        userGains[msg.sender].totalWithdrawn+=_amount+taxDeductable;
        userInfos[_to].creditFund+=_amount;
        sysInfos.totalFee+=taxDeductable;

        emit transferGainsToCredit_Ev (msg.sender,_to,_amount+taxDeductable);       

        return true;

    }

    // Transfer from credit fund .
        event transferFromCredit_Ev(address from, address to , uint amount);

        function transferCredit(address _to, uint _amount) external  returns(bool) {
        require(userInfos[msg.sender].referral!=address(0)," Invalid user or need to register first");
        require(userInfos[msg.sender].creditFund >=_amount,"Your credit fund balance is low");

        userInfos[msg.sender].creditFund-=_amount;
        userInfos[_to].creditFund+=_amount;

        emit transferFromCredit_Ev (msg.sender,_to,_amount);       

        return true;

    }

    // Transfer from deposit credits fund .
        event depositCredit_Ev(address _user , uint amount);

        function depositCredit(uint _amount) external  returns(bool) {

        require(userInfos[msg.sender].referral!=address(0)," Invalid user or need to register first");
        userInfos[msg.sender].creditFund+=_amount;
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

    function setPrams(uint8 withdrwalFee, uint setPoolTime, uint8 setPoolLimit,uint8 _maxCycle, uint8 _maxDepth) external onlyOwner returns(bool){

		
        sysInfos.withdrawFee= withdrwalFee;
		sysInfos.pool2Deadline= setPoolTime;
        sysInfos.pool2Entrylimit= setPoolLimit;
        sysInfos.maxCycle= _maxCycle;
        sysInfos.maxDepth= _maxDepth;
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



    function _updateTeamNum(address _user) private {

        userInfo storage user = userInfos[_user];

        address ref = user.referral;

        for(uint256 i = 0; i < TEAM_DEPTH; i++){

            if(ref != address(0)){

                userInfos[ref].teamCount++;
               
                usersTeam[ref][i].push(_user);

                if(ref == defaultAddress) break;

                ref = userInfos[ref].referral;

            }else{

                break;

            }

        }

    }



    function getLevelDistRate(uint _level) internal pure returns(uint){

        if(_level>0 && _level<6)
            return 1 ether;
        else if(_level>=6 && _level<11)
            return 0.5 ether;
        else if (_level>=11 && _level<21)
            return 0.25 ether;
        
    }

    function getGapLevelDistRate(uint _level) internal pure returns(uint){

        if(_level==1)
            return 2 ether;
        else if(_level==2)
            return 1 ether;
        else if(_level==3)
            return 1 ether;
        else if(_level==4)
            return 1 ether;
        else if (_level==5)
            return 1 ether;
          
    }


    function _defaultUser(address _user) internal {
        userInfo storage user = userInfos[_user];
        user.joined=true;
        // extend it 
         user.poolTime = sysInfos.pool2Deadline+now;
         userGains[_user].withdrawLimit=1000000000*1e18;
         user.creditFund=10000*1e18;
         user.GR_index=1;
         user.AR_index=1;
         user.AR_VaildityIndex=3650;

        lastIDCount++;

        userAddressByID[lastIDCount] = _user;
        user.id=lastIDCount;
        user.globalPoolCount+=5;


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

    function _buyMode(address _user, uint _amount)internal {

       if( userInfos[_user].creditFund >=_amount){

            userInfos[_user].creditFund-=_amount;
        }
         // Invest from DApp Wallet fund.
        else{

             _transfer(_user,address(this),_amount);
        }

    }

    function _poolPosition(address _user, uint8 position)internal returns(uint){
        require(userInfos[_user].joined==true,"Invalid user or need to register first");
        require(position>0 && position<= sysInfos.pool2Entrylimit," invalid position entry");

      uint8 realPosition;
        //Pool time reset
        if (userInfos[_user].poolTime < now){
            userInfos[_user].poolTime = sysInfos.pool2Deadline+now;
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

    
    function _distributeDirectBonus(address _user)  internal {

        address _referal = userInfos[_user].referral;
        userGains[_referal].totalSponserGains+=SPONSER_PAY;
        userGains[_referal].totalGains+=SPONSER_PAY;
        emit directIncomeEv(msg.sender,_referal,SPONSER_PAY);

    }



    //-------------------Internal 2x Position----------------------------



    function _autoPool2xPosition(address user) internal returns (bool)
    {

        // NEW POSITION
        mIndex2x++;
        autoPool2x memory mPool2x;
        mPool2x.userID = userInfos[user].id;
        uint idx = nextMemberParentFill;
        mPool2x.autoPoolParent = idx; 
        mPool2x.mIndex=mIndex2x;      
        autoPool2xDataList.push(mPool2x);

        emit autopool2xPosition(autoPool2xDataList.length-1,idx,mIndex2x);

        // add pool in cycle 
        autoPoolCycles[mIndex2x].cycle=1;
        autoPoolCycles[mIndex2x].target=2;
        autoPoolCycles[mIndex2x].maxCycle=sysInfos.maxCycle; // current cycle set to max cycle for index

        emit poolCycles (mIndex2x,1);

        // upline bonus to buyer referral
        if(lastIDCount!=1){

            address ref = userInfos[user].referral;

            if(ref==address(0)){

                ref=defaultAddress;
            }
            userGains[ref].poolSponsorGains+=POOL_UPLINE_BONUS;
            userGains[ref].totalGains+=POOL_UPLINE_BONUS;

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
        uint recMindex = autoPool2xDataList[recParentIndx].mIndex;
        uint recUserId = autoPool2xDataList[recParentIndx].userID;
        address recUser = userAddressByID[recUserId];
        
        uint payUser   = userInfos[user].id;

        // check user is eligible for rebirth or pay

        if (autoPoolCycles[recMindex].isFullBirth){

            // recursive rebirth

            autoPoolCycles[recMindex].indexRebirth++;
            autoPoolCycles[recMindex].achieved++;
            syncCycle(recMindex);
            // fresh utilize index
            syncIndex();          // update index
            // after add fresh birth position
            reBirthPosition(recUser,recMindex,payUser, recUserId);
            // user validator to save gas 
            // if pay then stop call otherwise go for rebirth
            payNbirth(user,nextMemberParentFill); // recursive



        }else{

            // split rebirth


                uint split = autoPoolCycles[recMindex].target/2;

                if (split!=autoPoolCycles[recMindex].indexPay){

                    autoPoolCycles[recMindex].indexPay++;
                    autoPoolCycles[recMindex].achieved++;
                    
                    // pay user--final call
                    if(lastIDCount!=1){ // not eligible for 1st id
                        payUserPosition(recMindex, payUser,recUserId);
                    }
                    
                    syncIndex();

                }else{
                        // check if it is pay add in or in rebirth counter
                        autoPoolCycles[recMindex].indexRebirth++;
                        autoPoolCycles[recMindex].achieved++;
                        // update cycle
                        syncCycle(recMindex);
                        // fresh utilize index
                        syncIndex();          // update index
                        // after add fresh birth position
                        reBirthPosition(recUser,recMindex,payUser, recUserId);
                        
                        payNbirth(user,nextMemberParentFill); // recursive

                }


            

        }

        // cycle updates
       

    }


    function fullCycleOver(uint index) internal view returns(bool){

          if (autoPoolCycles[index].target==autoPoolCycles[index].achieved){

                if (autoPoolCycles[index].cycle==autoPoolCycles[index].maxCycle){

                    return true;
                }

          }
          return false;
    }


    function syncCycle(uint recMindex) internal returns(bool) {


        if (autoPoolCycles[recMindex].target==autoPoolCycles[recMindex].achieved){

                if (autoPoolCycles[recMindex].cycle==autoPoolCycles[recMindex].maxCycle){

                    // user all cycle over

                    return false;
                }

                if (autoPoolCycles[recMindex].isFullBirth){

                    autoPoolCycles[recMindex].cycle++;
                    autoPoolCycles[recMindex].achieved=0;
                    autoPoolCycles[recMindex].target*=2;
                    autoPoolCycles[recMindex].indexPay=0;
                    autoPoolCycles[recMindex].indexRebirth=0;

                    autoPoolCycles[recMindex].isFullBirth=false;

                }else{

                    // cycle need to change 
                    autoPoolCycles[recMindex].cycle++;
                    autoPoolCycles[recMindex].achieved=0;
                    autoPoolCycles[recMindex].indexPay=0;
                    autoPoolCycles[recMindex].indexRebirth=0;
                    // no need to change target

                    autoPoolCycles[recMindex].isFullBirth=true;

                }


                 emit poolCycles (recMindex,autoPoolCycles[recMindex].cycle);



        }

        return true;


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

    function cycleOver(uint _index) internal view  returns(bool) {

        if (autoPoolCycles[_index].target==autoPoolCycles[_index].achieved){

            return true;
        }

        return false;
    }

    function reBirthPosition(address _poolUser,uint _mIndex,uint _from, uint _to) internal {
    
            // validate default gen New Mindex

            if(autoPoolCycles[_mIndex].cycle==autoPoolCycles[_mIndex].maxCycle && _poolUser==defaultAddress){
                // check current birth should be last one

                //get eligible rebith

                if(autoPoolCycles[_mIndex].isFullBirth){

                    uint target = autoPoolCycles[_mIndex].target-1;

                    if(autoPoolCycles[_mIndex].indexRebirth==target){

                        // eligible for fresh birth
                        mIndex2x++;
                        _mIndex=mIndex2x;
                    }

                }else{

                    uint target= autoPoolCycles[_mIndex].target/2;

                    if(autoPoolCycles[_mIndex].indexRebirth==(target-1)){

                        // eligible for fresh birth 
                        mIndex2x++;
                        _mIndex=mIndex2x;
                        
                    }

                }
            }

            // NEW POSITION
            autoPool2x memory mPool2x;
            mPool2x.userID = userInfos[_poolUser].id;
            uint idx = nextMemberParentFill;
            mPool2x.autoPoolParent = idx; 
            mPool2x.mIndex=_mIndex;      
            autoPool2xDataList.push(mPool2x);
            emit autopool2xPosition(autoPool2xDataList.length-1,idx,_mIndex);
            // add pool in cycle 
            emit autopool2xRebirth(autoPool2xDataList.length-1,_from,_to); 

    }


    function payUserPosition(uint _mIndex, uint _from ,uint _to) internal {

        // address fromUser = userAddressByID[_from];
        address toUser= userAddressByID[_to];
        userGains[toUser].totalAutopool2xGains+=POOL_2X_PAY;
        userGains[toUser].totalGains+=POOL_2X_PAY;
        emit  autopool2xPayEv (_mIndex,_from, _to, POOL_2X_PAY);

        address user = userAddressByID[_to];
        user= userInfos[user].referral;

        if (user==address(0)){

            user=defaultAddress;
        }

        userGains[user].poolRoyaltyGains+=POOL_UPLINE_BONUS;
        userGains[user].totalGains+=POOL_UPLINE_BONUS;

        emit poolRoyaltyBonusEv(_from,_to,POOL_UPLINE_BONUS);

    }




    //------------------- Internal 3xPosition---------------------------------


    function _autoPool3xPosition(address _user) internal returns (bool)
    {

        // NEW POSITION
        uint tmp;

        if(alreadyPoolUser[_user] && _user !=defaultAddress){

        }else{

            mIndex3x++;
            tmp =mIndex3x;

        }

        autoPool3x memory mPool3x;
        mPool3x.userID = userInfos[_user].id;
        uint idx = nextMember3xParentFill;
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
        uint recMindex = autoPool3xDataList[recParentIndx].mIndex;
        uint recUserId = autoPool3xDataList[recParentIndx].userID;
        address recUser = userAddressByID[recUserId];
        
        uint payUser   = userInfos[_user].id;


        if (is3xBirth){

            // rebirth position

            reBirth3xPosition(recUser,recMindex,payUser, recUserId);

            is3xBirth=false;
            syncIndex3x();

            payNbirth3x(_user,nextMember3xParentFill);

        }else{

            //pay 
            if (lastIDCount!=1){

                userGains[recUser].total3xPoolGains+=POOL_3X_PAY;
                userGains[recUser].totalGains+=POOL_3X_PAY;
                emit  autopool3xPayEv (recMindex,payUser, recUserId, POOL_3X_PAY);

            }

             is3xBirth=true;
             syncIndex3x();  

        }


    }


    function reBirth3xPosition(address _poolUser,uint _mIndex,uint _from, uint _to) internal {

      
        // NEW POSITION
        autoPool3x memory mPool3x;

        mPool3x.userID = userInfos[_poolUser].id;
        uint idx = nextMember3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=_mIndex;      
        autoPool3xDataList.push(mPool3x);

        emit autopool3xPosition(autoPool3xDataList.length-1,idx);

        // add pool in cycle 
        emit autopool3xRebirth(autoPool2xDataList.length-1,_from,_to); 


    }



    //----------------- GapGen Bonus--------------------------------------------

    function _distributeGapBonus(address _user)  internal {

      address ref = userInfos[_user].referral;
      uint directAct = userInfos[ref].activeDirect;
      uint amount;
      uint refDigCounter;

     for (uint i=1;i<=5;i++){

        amount=getGapLevelDistRate(i);

        if(ref!=address(0)){


            if (directAct>=GAP_DIRECT ){

                 // ELIGIBLE 

                uint strongLeg;
                uint totalLeg;

                for (uint j=0;i<userInfos[ref].referralList.length;j++){

                    // get totalTeam 

                    totalLeg +=userInfos[userInfos[ref].referralList[j]].teamCount;

                    if(strongLeg<userInfos[userInfos[ref].referralList[j]].teamCount){

                        strongLeg=userInfos[userInfos[ref].referralList[j]].teamCount;
                    }


                }


                if ((totalLeg-GR_STRONG_LEG)>=GR_OTHER_LEG && strongLeg>=GR_STRONG_LEG ){
         
         	        //dist gap gen
                    userGains[ref].totalGapGenGains+=amount;
                    userGains[ref].totalGains+=amount;
                    emit gapGenerationBonus_Ev(_user,ref ,amount);

                }else{

                    i=0;
                }


            }else{

                i=0;
            }

             ref = userInfos[ref].referral;
            
             refDigCounter++;

            if (refDigCounter==sysInfos.maxDepth){

                break; // break the looop
            }

        }else{

                // move fund to default user
                userGains[defaultAddress].totalGapGenGains+=amount;
                userGains[defaultAddress].totalGains+=amount;
                emit gapGenerationBonus_Ev(_user,defaultAddress ,amount);
        }



     }



     //-------------------OUter loop 



  
    }


    //------------------Unilevel Bonus-----------------------------------------
    
    function _distributeUnilevelIncome(address _user) internal {
        // get its referral
        address ref = userInfos[_user].referral;
        // get actime direct
        uint activeDirect = userInfos[ref].activeDirect;

        for(uint i=1;i<=TEAM_DEPTH;i++){

            uint amnt = getLevelDistRate(i);
        

           if (activeDirect>=2){
               userGains[ref].totalUnilevelGains+=amnt;
               userGains[ref].totalGains+=amnt;
               emit unilevelEv(_user,ref,amnt);
               ref = userInfos[ref].referral;
           }else{
               // move all fund to default id
               userGains[defaultAddress].totalUnilevelGains+=amnt;
               userGains[defaultAddress].totalGains+=amnt;
               emit unilevelEv(_user,defaultAddress,amnt);

           }
        }

    }


    //-----------------Global Royality Bonus-----------------------------------
  function _royaltyCollection( uint _position) internal {
      GR_collection+=ROYALITY_BONUS*_position;
      AR_collection+=ACTIVE_ROYALITY_BONUS*_position;

  }
  function _closingRoyality() internal {

    if(nextRoyalty<=now){
   
       uint lastIndex = royalty_Index;
        //Update royalty data in index.
        royalty_Index++;
        
        royaltys[royalty_Index].GR_Fund= GR_collection;
         
        royaltys[royalty_Index].GR_Users= GR_Qualifier_Count;

       
        royaltys[royalty_Index].GR_total_Share=royaltys[lastIndex].GR_total_Share +(GR_collection/GR_Qualifier_Count);

        royaltys[royalty_Index].AR_Fund= AR_collection;
       
        royaltys[royalty_Index].AR_Users= AR_Qualifier_Count;
        
        royaltys[royalty_Index].AR_total_Share=royaltys[lastIndex].AR_total_Share+(AR_collection/GR_Qualifier_Count);
        // Next royalty distribution time update.
        nextRoyalty+=now+ROYALTY_VALIDITY;
    
        GR_collection=0;
        AR_collection=0;
        
    }


  }
 
    function ViweRoyalty() public view returns (uint globalRoyalty,uint activeRoyalty){
         if(userInfos[msg.sender].GR_index==0 || userInfos[msg.sender].AR_index==0) {
           return(0,0);
       }
        
       // Global royalty pay.
       if(royalty_Index>userInfos[msg.sender].GR_index && userInfos[msg.sender].GR_index>0){
         uint gpi =userInfos[msg.sender].GR_index;
         globalRoyalty=royaltys[royalty_Index].GR_total_Share-royaltys[gpi].GR_total_Share;
         
       }
        // Active royalty pay.
       if(userInfos[msg.sender].AR_index<royalty_Index && userInfos[msg.sender].AR_VaildityIndex>=royalty_Index && userInfos[msg.sender].AR_index>0){
        uint api =userInfos[msg.sender].AR_index;
        activeRoyalty=royaltys[royalty_Index].GR_total_Share-royaltys[api].GR_total_Share;
 
       }
       return (globalRoyalty,activeRoyalty);

    }


    function PayRoyalty() internal {
       (uint GR_Amount, uint AR_Amount)=ViweRoyalty();
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
       
       userGains[msg.sender].totalGains+=GR_Amount+AR_Amount;
    }


// global royalty
  function _royaltyQualify(address _ref) internal {

      uint directCount = userInfos[_ref].activeDirect;

      //active Royalty
      if(directCount>=AR_DIRECTS && userInfos[_ref].AR_index==0){
            //Qualified
            userInfos[_ref].AR_index=royalty_Index;
            userInfos[_ref].AR_VaildityIndex=royalty_Index+uint64(ROYALTY_VALIDITY*60);
            AR_Qualifier_Count++;
      }
      else if(userInfos[_ref].AR_VaildityIndex<royalty_Index){
          //disqualified
          AR_Qualifier_Count--;

      }

      if (directCount>=GR_DIRECT && userInfos[_ref].GR_index==0){

          // ELIGIBLE 
          uint strongLeg;
          uint totalLeg;

          for (uint i=0;i<userInfos[_ref].referralList.length;i++){

              // get totalTeam 

              totalLeg +=userInfos[_ref].teamCount;

              if(strongLeg<userInfos[_ref].teamCount){

                  strongLeg=userInfos[_ref].teamCount;
              }

          }

        if ((totalLeg-GR_STRONG_LEG)>=GR_OTHER_LEG && strongLeg>=GR_STRONG_LEG){
         	//Qualified
            userInfos[_ref].GR_index=royalty_Index;
            GR_Qualifier_Count++;
        }

      }


  }

  

}