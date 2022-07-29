/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

/**
 *Submitted for verification at Etherscan.io on 2020-03-27
*/

pragma solidity 0.5.9; /*


___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



 ██████╗ ██╗██╗     ██╗     ██╗ ██████╗ ███╗   ██╗    ███╗   ███╗ ██████╗ ███╗   ██╗███████╗██╗   ██╗
 ██╔══██╗██║██║     ██║     ██║██╔═══██╗████╗  ██║    ████╗ ████║██╔═══██╗████╗  ██║██╔════╝╚██╗ ██╔╝
 ██████╔╝██║██║     ██║     ██║██║   ██║██╔██╗ ██║    ██╔████╔██║██║   ██║██╔██╗ ██║█████╗   ╚████╔╝ 
 ██╔══██╗██║██║     ██║     ██║██║   ██║██║╚██╗██║    ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔══╝    ╚██╔╝  
 ██████╔╝██║███████╗███████╗██║╚██████╔╝██║ ╚████║    ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║███████╗   ██║   
 ╚═════╝ ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   
                                                                                            


-------------------------------------------------------------------
 Copyright (c) 2020 onwards Billion Money Inc. ( https://billionmoney.live )
-------------------------------------------------------------------
 */


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//

// import "hardhat/console.sol";


contract owned
{
    address internal owner;
    address internal newOwner;
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
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



//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract billionMoney is owned {

    // Replace below address with main token token
    address public tokenAddress;

    mapping(address => uint) public maxDownLimit_;
    uint public startTime = now;
    uint public levelLifeTime = 900;  // =120 days;
    uint public lastIDCount = 0;
    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref 
    address payable defaultAddress;
    bool public goLive;
    uint public autopoolMultiplier=10; // multiplier 10x
    bool USDT_INTERFACE_ENABLE;
    uint Closing_TimeStep_Pool=86400; // 1 day;
     uint Closing_TimeStep_Div=86400; // 1 day;

    mapping(address => bool ) public lockWithdraw;

    struct userInfo {
        bool joined;
        uint id;
        uint parentID;
        uint referrerID;
        uint directCount;
        address[] parent;
        address[] referral;
        uint8 maxLevel;
        mapping(uint=>level) levels;
        bool isDividendDeactive;
        uint passiveExpReturn;
        bool isPoolDivDeactive;
        uint poolExpReturn;
    }

    struct level {

        uint fillBox;
        uint upgradeFund;
        uint reinvestCount;
    }
    

    struct userGain{

        uint256  totalGainInMainNetwork; //Main lavel income system income will go here with owner mapping
        uint256  totalGainInUniLevel; 

        uint256  netTotalUserWithdrawable_;  //Dividend is not included in it
        uint256  totalGainDirect;  //Dividend is not included in it

        uint256  totalWithdrawnInMainNetwork; //Main lavel income system income will go here with owner mapping
        uint256  totalWithdrawnInUniLevel; 
     
        uint256  netTotalUserWithdrawn_;  //Dividend is not included in it
        uint256  totalWithdrawnDirect;  //Dividend is not included in it
        uint     totalWithdrawn;
        
//--------------WonderPoll--------------------
        uint poolReturnShare;
        uint totalPoolGain;

//---------------------Passive----------------
      
        uint passiveReturnShare;
        uint totalPassiveGain;

    }

    uint public passiveReturnTodayCollection; // IT WILL HOLD DAILY  ROI COLLECTION
  
    uint public passiveReturnTotalFundCollection; //total ROI fund
    uint public totalPassiveEligible; // total people eligible for ROI

    uint public lastPassiveClose;

    //--------------wonder Pool Income---------------------


    uint public poolReturnTodayCollection; // IT WILL HOLD DAILY  ROI COLLECTION
  
    uint public poolReturnTotalFundCollection; //total ROI fund
    uint public totalPoolEligible; // total people eligible for ROI

    uint public lastPoolClose;


    
    mapping(uint => uint)  public priceOfLevel;
    mapping(uint => uint)  public distForLevel;
    mapping(uint => uint)  public autoPoolDist;
    mapping(uint => uint)  public uniLevelDistPart;
    mapping(address=>uint) public totalGainInLevel;
    mapping(address=>uint) public totalGainInLevelWithdrawn;

    
  

    uint256 public totalIncomingFund;
    uint256 public totalPaidFromSystem;


    uint[11] public globalDivDistPart;
    uint systemDistPart;
    
    

    mapping (address => userInfo) public userInfos;
    mapping(address=> userGain) public userGains;
    mapping (uint => address payable) public userAddressByID;


    event regLevelEv(address indexed _userWallet, uint indexed _userID, uint indexed _parentID, uint _time, address _refererWallet, uint _referrerID);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event payPassiveEv(uint timeNow,uint payAmount,address paitTo);
    event reinvestEv(uint timeNow,uint level,address paitTo);
    event payPoolEv(uint timeNow,uint payAmount,address paitTo);
    event paidForUniLevelEv(uint timeNow,address PaitTo,uint Amount);
    event paidForSystem(address _against, uint _amount);
    event paidToDirect(address from,address to , uint amount);
    
    constructor(address payable ownerAddress, address payable ID1address) public {
        owner = ownerAddress;
        defaultAddress = address(uint160(owner));

        emit OwnershipTransferred(address(0), owner);
        address payable ownerWallet = ID1address;

        systemDistPart = 1000000;

        globalDivDistPart[1] = 1000000;
        globalDivDistPart[2] = 1000000;
        globalDivDistPart[3] = 2000000;
        globalDivDistPart[4] = 6000000;
        globalDivDistPart[5] = 27500000;
        globalDivDistPart[6] = 120000000;
        globalDivDistPart[7] = 135000000;
        globalDivDistPart[8] = 225000000;
        globalDivDistPart[9] = 360000000;
        globalDivDistPart[10] = 690000000;

        priceOfLevel[1] = 25000000;
        priceOfLevel[2] = 25000000;
        priceOfLevel[3] = 50000000;
        priceOfLevel[4] = 140000000;
        priceOfLevel[5] = 600000000;
        priceOfLevel[6] = 2500000000;
        priceOfLevel[7] = 3000000000;
        priceOfLevel[8] = 5000000000;
        priceOfLevel[9] = 8000000000;
        priceOfLevel[10] = 15000000000;
//------------------------FOR TESTING----------------------

    
        distForLevel[1] = 10000000;
        distForLevel[2] = 15000000;
        distForLevel[3] = 30000000;
        distForLevel[4] = 90000000;
        distForLevel[5] = 412500000;
        distForLevel[6] = 1800000000;
        distForLevel[7] = 2025000000;
        distForLevel[8] = 3375000000;
        distForLevel[9] = 5400000000;
        distForLevel[10] = 10350000000;

        autoPoolDist[1] = 4000000;
        autoPoolDist[2] = 5000000;
        autoPoolDist[3] = 10000000;
        autoPoolDist[4] = 20000000;
        autoPoolDist[5] = 50000000;
        autoPoolDist[6] = 100000000;
        autoPoolDist[7] = 300000000;
        autoPoolDist[8] = 500000000;
        autoPoolDist[9] = 800000000;
        autoPoolDist[10]= 1200000000;         



        uniLevelDistPart[1] = 1000000;
        uniLevelDistPart[2] = 800000;
        uniLevelDistPart[3] = 600000;
        uniLevelDistPart[4] = 400000;

        for (uint i = 5 ; i < 11; i++)
        {
           uniLevelDistPart[i] =  200000;
        } 



        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            parentID: 0,
            referrerID: 0,
            directCount: 31,  
            referral: new address[](0),
            parent: new address[](0),
            maxLevel:10,
            isDividendDeactive:false,
            passiveExpReturn:0,
            isPoolDivDeactive:false,
            poolExpReturn:0
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;


        lastPassiveClose= block.timestamp; // time start after deployment
        lastPoolClose = block.timestamp;
      
        emit regLevelEv(ownerWallet, 1, 0, now, address(this), 0);


        updateROI(ownerWallet, priceOfLevel[1]);

        // pool update

        updatePool(ownerWallet, priceOfLevel[1]);


        USDT_INTERFACE_ENABLE= true; // enable USDT interface

    }

    function () payable external {
        regUser(defaultRefID, 0);
    }


    function goLive_() public onlyOwner returns(bool)
    {
        goLive = true;
        return true;
    }
    function regUser(uint _referrerID, uint _parentID) public payable returns(bool) 
    {
        require(goLive, "pls wait");
        address(uint160(owner)).transfer(msg.value);
        //this saves gas while using this multiple times
        address msgSender = msg.sender; 
        uint pID = _referrerID;

        if(_parentID > 0 && _parentID != _referrerID) pID = _parentID;

        address origRef = userAddressByID[_referrerID];
        if(_referrerID == _parentID && _parentID != 0) increaseDownLimit(origRef);

        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');

        _parentID = lastIDCount; // from here _parentID is lastIDCount
        if(!(pID > 0 && pID <= _parentID)) pID = defaultRefID;

        address pidAddress = userAddressByID[pID];
        if(userInfos[pidAddress].parent.length >= maxDownLimit(pidAddress) ) pID = userInfos[findFreeReferrer(pidAddress)].id;


        uint prc = priceOfLevel[1];
        //transferring tokens from smart user to smart contract for level 1
        if(USDT_INTERFACE_ENABLE==true){
            tokenInterface(tokenAddress).transferFrom(msgSender, address(this), prc);
        }else{
            ERC20In(tokenAddress).transferFrom(msgSender, address(this), prc);
        }
        

        totalIncomingFund += prc;
        //update variables
        userInfo memory UserInfo;
        _parentID++;

        UserInfo = userInfo({
            joined: true,
            id: _parentID,
            parentID: pID,
            referrerID: _referrerID,
            directCount: 0,             
            referral: new address[](0),
            parent: new address[](0),
            maxLevel:1,
            isDividendDeactive:false,
            passiveExpReturn:0,
            isPoolDivDeactive:false,
            poolExpReturn:0
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[_parentID] = address(uint160(msgSender));


        userInfos[userAddressByID[pID]].parent.push(msgSender);

        setUserGain(userAddressByID[_referrerID],1,globalDivDistPart[1] * 4);

        userGains[userAddressByID[1]].totalGainInMainNetwork += systemDistPart;
        userGains[userAddressByID[1]].netTotalUserWithdrawable_ += systemDistPart;
        emit paidForSystem(msgSender, systemDistPart);
        
        CalculateDailyRoi(1);
      
        updateROI(msgSender, priceOfLevel[1]); // only when level buy is not calling inside calling block

        CalculateDailyPool(1);
        updatePool(msgSender, priceOfLevel[1]);
        
        userInfos[origRef].directCount++;
        userInfos[origRef].referral.push(msgSender);
     
        lastIDCount = _parentID;
     
        require(spkitPart(msgSender,_parentID,pID,_referrerID,prc),"split part failed");
     
        return true;
    }

    function spkitPart(address msgSender, uint lID, uint pID, uint _referrerID, uint prc) internal returns(bool)
    {
        require(payForLevel(1, msgSender,0),"pay for level fail");
        emit regLevelEv(msgSender, lID, pID, now,userAddressByID[pID], _referrerID );
        emit levelBuyEv(msgSender, 1, prc, now);
             
        return true;
    }

    function maxDownLimit(address _user) public view returns(uint)
    {
        uint dl = maxDownLimit_[_user];
        if(dl == 0 ) dl = 2;
        return dl;
    }


    function increaseDownLimit(address _user) internal  returns(bool)
    {
        if(maxDownLimit_[_user] == 0) maxDownLimit_[_user] = 3;
        else maxDownLimit_[_user] ++;
        return true;
    }


    function lockMyWithdraw() public returns(bool)
    {
        lockWithdraw[msg.sender] = true;
        return true;
    }

    

    function buyLevel(uint8 _level) public payable returns(bool){
        require(goLive, "pls wait");
        //require(msg.value == levelBuyTxCost, "pls pay tx cost");
        address(uint160(owner)).transfer(msg.value);
        //this saves gas while using this multiple times
        address msgSender = msg.sender;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 

        require(_level >= 1 && _level <= 10, 'Incorrect level');
        require(_level<=userInfos[msgSender].maxLevel+1,"level Invalid");
        
        //transfer tokens
        if(USDT_INTERFACE_ENABLE==true){

            tokenInterface(tokenAddress).transferFrom(msgSender, address(this), priceOfLevel[_level]);

        }else{
            ERC20In(tokenAddress).transferFrom(msgSender, address(this), priceOfLevel[_level]);
        }

        _buyLevel(msgSender,_level);

        return true;
    }


    function _buyLevel(address msgSender, uint8 _level) internal returns(bool) {

        totalIncomingFund += priceOfLevel[_level];
        address reff = userAddressByID[userInfos[msgSender].referrerID];
        setUserGain(reff,_level,globalDivDistPart[_level] * 4);
        
    
        // address origRef = userAddressByID[userInfos[msgSender].referrerID];

        if (userInfos[msgSender].maxLevel<_level){

            userInfos[msgSender].maxLevel=_level;
        }

        // div update--
        CalculateDailyRoi(_level);
        updateROI(msgSender, priceOfLevel[_level]);

        // pool update

        CalculateDailyPool(_level);
        updatePool(msgSender, priceOfLevel[_level]);

        require(payForLevel(_level, msgSender,0),"pay for level fail");
        emit levelBuyEv(msgSender, _level, priceOfLevel[_level] , now);

        return true;

    }



    function anyActive(address _user, uint8 _level) internal view returns(bool)
    {
        if (userInfos[_user].maxLevel>=_level){

             return true;
        }

        return false;

      
    }


    function payForLevel(uint8 _level, address _user, uint _runtime) internal returns(bool) {

        address [] memory userGainList = new address[](_level); 
        address [] memory userLostList = new address[](_level);

        uint gainId;
        uint looseId;

        address referer=_user;


        for (uint i=0; i<_level;i++){

             referer = userAddressByID[userInfos[referer].referrerID];
             // use a check for maxLevel

             if(referer==address(0)){

                referer= userAddressByID[1];
             }

             
            if(anyActive(referer,_level))
            {
                userGainList[gainId]=(referer);
                gainId++;

            }else{
                userLostList[looseId]=(referer);
                looseId++;
            }
        }

        if (userGainList.length==0 && _runtime==5){

            userGainList[0]=(defaultAddress); // default is only eligible after checking recursive five times
        }

        // dist fund calculation

        uint lvlAmount = distForLevel[_level];
        uint loosePerPerson;
        uint gainPerPerson ;

        if (userLostList.length>0){

            loosePerPerson= lvlAmount/(userGainList.length+userLostList.length);
        }

        if (userGainList.length>0){

            gainPerPerson = lvlAmount/userGainList.length;            
        }
       
        for(uint i=0; i< userLostList.length;i++){

            emit lostForLevelEv(userLostList[i], _user, _level,loosePerPerson, now);
        }


        if (userGainList.length>0){

            // distribute

            for(uint i=0; i<userGainList.length;i++){


                //----------------------UPDATE UPGRADE LEVELS---------------

                if (userInfos[userGainList[i]].levels[_level].fillBox>1){

                    // distribute fund as upgrade fund
                    updateLevelUpgrade(userGainList[i], _level,gainPerPerson);

                }else{
                    // distribute fund as normal
                    userInfos[userGainList[i]].levels[_level].fillBox++;
                    userGains[userGainList[i]].netTotalUserWithdrawable_ += gainPerPerson;
                    totalGainInLevel[userGainList[i]]+=gainPerPerson;
                    emit paidForLevelEv(userGainList[i], _user, _level, gainPerPerson, now);
                }


                // if current is level 1 then only run unilevel

                if (_level==1){

                        payForUniLevel(userInfos[_user].parentID, _level);      
                }
            }


        }else{

            // recursion
            _runtime++;
            payForLevel( _level,referer,_runtime);

        }

        return true;


    }




    function findFreeReferrer(address _user) public view returns(address) {
        uint _limit = maxDownLimit(_user);
        if(userInfos[_user].parent.length < _limit ) return _user;

        address[] memory referrals = new address[](126);

        uint j;
        for(j=0;j<_limit;j++)
        {
            referrals[j] = userInfos[_user].parent[j];
        }

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {

            _limit = maxDownLimit(referrals[i]);

            if(userInfos[referrals[i]].parent.length == _limit) {

                if(j < 62) {
                    
                    for(uint k=0;k< _limit;k++)
                    {
                        referrals[j] = userInfos[referrals[i]].parent[k];
                        j++;
                    }

                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }


    function payForUniLevel(uint _referrerID, uint8 _level) internal returns(bool)
    {
        uint256 endID = 21;
        for (uint i = 0 ; i < endID; i++)
        {
            address usr = userAddressByID[_referrerID];
            _referrerID = userInfos[usr].parentID;
            if(usr == address(0) ) usr = defaultAddress;
            uint Amount = uniLevelDistPart[i + 1 ];
            if(anyActive(usr,_level))
            {
                userGains[usr].totalGainInUniLevel += Amount;
                userGains[usr].netTotalUserWithdrawable_ += Amount;
            }
            else
            {
                userGains[defaultAddress].totalGainInUniLevel += Amount;
               userGains[defaultAddress].netTotalUserWithdrawable_ += Amount;
            }
            emit paidForUniLevelEv(now,usr, Amount);
        }
        return true;
    }

    event withdrawMyGainEv(uint timeNow,address caller,uint totalAmount);
 
    function withdrawMyDividendNAll() public payable returns(uint)
    {
        
        require(!lockWithdraw[msg.sender], "you locked withdraw");
            
        address(uint160(owner)).transfer(msg.value);
        address payable caller = msg.sender;
        require(userInfos[caller].joined, 'User not exist');
        uint totalAmount;
        uint totalAmount_;

        if (getPoolIncome(msg.sender)>0){

            claimPoolIncome();
        }

        if (getPassiveIncome(msg.sender)>0){

            claimPassiveIncome();
        }

        totalAmount = totalAmount + totalAmount_ + userGains[caller].netTotalUserWithdrawable_;

        // income reset

        userGains[caller].netTotalUserWithdrawn_+= userGains[caller].netTotalUserWithdrawable_;
        userGains[caller].totalWithdrawnDirect += userGains[caller].totalGainDirect;
        
        userGains[caller].totalWithdrawnInMainNetwork += userGains[caller].totalGainInMainNetwork;
        userGains[caller].totalWithdrawnInUniLevel += userGains[caller].totalGainInUniLevel;
        totalGainInLevelWithdrawn[caller]+=totalGainInLevel[caller];
        totalPaidFromSystem += totalAmount;
        resetUserGain(caller);
        userGains[caller].totalWithdrawn += totalAmount;
        // usergains
        if(totalAmount > 0 && goLive)
        {

            if(USDT_INTERFACE_ENABLE==true){

                tokenInterface(tokenAddress).transfer(msg.sender, totalAmount);

            }else{

                ERC20In(tokenAddress).transfer(msg.sender, totalAmount);
            }     

        }

        emit withdrawMyGainEv(now, caller, totalAmount);
        
    }



    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }





    function viewUsersOfParent(address _user) public view returns(address[] memory) {
        return userInfos[_user].parent;
    }



    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    




    /*======================================
    =            OWNER FUNCTIONS           =
    ======================================*/



    function changetokenaddress(address newtokenaddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        tokenAddress = newtokenaddress;

        return("token address updated successfully");
    }


    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }

    function changeDefaultAddress(address payable _defaultAddress) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        userInfo memory UserInfo;
        UserInfo = userInfo({
            joined: true,
            id: 0,
            parentID: 0,
            referrerID: 0,
            directCount: 31,  
            referral: new address[](0),
            parent: new address[](0),
            maxLevel:10,
            isDividendDeactive:false,
            passiveExpReturn:0,
            isPoolDivDeactive:false,
            poolExpReturn:0
        });
        userInfos[_defaultAddress] = UserInfo;
        userAddressByID[0] = _defaultAddress;
        defaultAddress = _defaultAddress;

        if(defaultAddress == address(0))
        {
            userInfos[userAddressByID[1]].parentID = 1;
            userInfos[userAddressByID[1]].referrerID = 1;
        }

        return("Default address updated successfully");
    }



    // only admin can call this function on request of user in case private key is compormised 
    function changeUserAddress(address oldAddress, address newAddress) public onlyOwner returns(bool)
    {
        require(!userInfos[newAddress].joined , "this is existing address ");
        uint uid = userInfos[oldAddress].id;
        uint pid = userInfos[oldAddress].parentID;
        uint rid = userInfos[oldAddress].referrerID;

        userInfos[newAddress] = userInfos[oldAddress];
        
        uint i;


        userInfo memory temp;
        userInfos[oldAddress] = temp;

        userAddressByID[uid] = address(uint160(newAddress));

        address parent_ = userAddressByID[pid];
        for(i=0;i<userInfos[parent_].parent.length; i++)
        {
            if(userInfos[parent_].parent[i] == oldAddress ) 
            {
                userInfos[parent_].parent[i] = newAddress;
                break;
            }
        }

        address referal_ = userAddressByID[rid];
        for(i=0;i<userInfos[referal_].referral.length; i++)
        {
            if(userInfos[referal_].referral[i] == oldAddress ) 
            {
                userInfos[referal_].referral[i] = newAddress;
                break;
            }
        } 

       // transfer all gain
        userGains[newAddress].netTotalUserWithdrawable_ = userGains[oldAddress].netTotalUserWithdrawable_;

        userGains[newAddress].totalGainDirect = userGains[oldAddress].totalGainDirect;
      
      
        userGains[newAddress].totalGainInMainNetwork = userGains[oldAddress].totalGainInMainNetwork;
       
        userGains[newAddress].totalGainInUniLevel = userGains[oldAddress].totalGainInUniLevel;
        totalGainInLevelWithdrawn[newAddress] = totalGainInLevelWithdrawn[oldAddress];
        

        resetUserGain(oldAddress);
        
        userGains[newAddress].totalWithdrawn = userGains[oldAddress].totalWithdrawn;        
        userGains[oldAddress].totalWithdrawn = 0;
        totalGainInLevelWithdrawn[newAddress]= totalGainInLevelWithdrawn[oldAddress];
        totalGainInLevelWithdrawn[oldAddress] =0;



        return true;
    }


    function unLockWithdraw(address _user) public onlyOwner returns(bool)
    {
        lockWithdraw[_user] = false;
        return true;
    }


    function spkitPart_(address msgSender, uint lID, uint pID, uint _referrerID, uint prc) internal returns(bool)
    {
        require(payForLevel(1, msgSender,0),"pay for level fail");
        emit regLevelEv(msgSender, lID, pID, now,userAddressByID[pID], _referrerID );
        emit levelBuyEv(msgSender, 1, prc, now);
    
        return true;
    }



    function lastUserAddress() external view returns(address _user)
    {
        return userAddressByID[lastIDCount]; 
    }


    function lastIDView() external view returns (uint lastID){
        lastID = lastIDCount;
    }




    function findRefById(uint _id) public view returns(uint)
    {
        return userInfos[(findFreeReferrer(userAddressByID[_id]))].id;
    }


    //------------------OPTIMIZED CODE BLOCKS----------------

    function setUserGain(address _user, uint8 _level, uint _amount) internal {
        address msgSender= msg.sender;

        if(anyActive(_user,_level))
        {        
            userGains[_user].totalGainDirect += _amount;
            userGains[_user].netTotalUserWithdrawable_ += _amount;
            emit paidToDirect(msgSender, _user, _amount);
        }
        else
        {
            userGains[defaultAddress].totalGainDirect += _amount;
            userGains[defaultAddress].netTotalUserWithdrawable_ += _amount;
            emit paidToDirect(msgSender, defaultAddress, _amount);            
        }
    }

    function resetUserGain(address caller) internal{

        userGains[caller].netTotalUserWithdrawable_ = 0;
        userGains[caller].totalGainDirect = 0;
        userGains[caller].totalGainInMainNetwork = 0;
        userGains[caller].totalGainInUniLevel = 0;
        totalGainInLevel[caller]=0;
        
    }

    //----------------------------------------PASSIVE INCOME--------------------------------------

    function updateROI(address userAddress, uint _amount) internal {

        // update user return share 
        if (userInfos[userAddress].passiveExpReturn==0 && userGains[userAddress].passiveReturnShare==0){

            // newly user 
            totalPassiveEligible++;
            userInfos[userAddress].passiveExpReturn=_amount;

        }else if (userInfos[userAddress].passiveExpReturn==0 && userGains[userAddress].passiveReturnShare!=0 && userInfos[userAddress].isDividendDeactive==false ){

            // when user get his all expfund

                totalPassiveEligible--;
                userInfos[userAddress].isDividendDeactive=true;

        }else if (userInfos[userAddress].isDividendDeactive==true && userInfos[userAddress].passiveExpReturn==0 ){

            // re-active old user
            totalPassiveEligible++;
            userInfos[userAddress].passiveExpReturn=_amount;
            userInfos[userAddress].isDividendDeactive=false;

        }else if (userInfos[userAddress].passiveExpReturn!=0 && userInfos[userAddress].isDividendDeactive==false){

            userInfos[userAddress].passiveExpReturn+=_amount; // update exp return on new level buy
        }

        userGains[userAddress].passiveReturnShare=passiveReturnTotalFundCollection;
        

        if(userInfos[userAddress].directCount>=5){

            userInfos[userAddress].passiveExpReturn=_amount*2;
        }

        //return closing 

        if( block.timestamp>=lastPassiveClose+Closing_TimeStep_Div){
            passiveReturnTotalFundCollection+=passiveReturnTodayCollection;
            passiveReturnTodayCollection=0; //reset 
            lastPassiveClose= block.timestamp;
        }

    }


    // passive call

    function CalculateDailyRoi(uint8 _level) internal{

        uint calcAmount = priceOfLevel[_level];
        passiveReturnTodayCollection+=calcAmount;

    } 

    function closeTodayPassiveIncome() public returns(bool) {

        require(passiveReturnTodayCollection>0,"You don't have enough roiFund");
        require(block.timestamp>=lastPassiveClose+Closing_TimeStep_Div,"you can't close before 1 day ");
        passiveReturnTotalFundCollection+=passiveReturnTodayCollection;
        passiveReturnTodayCollection=0; //reset 
        lastPassiveClose= block.timestamp;

        //todayROIShare = returnTotalFundCollection/totalRoiEligible;
        
        return true;

     }

    function claimPassiveIncome() public returns(bool) {

        require(passiveReturnTotalFundCollection>0 ,"You don't have enough roiFund");
        require(userInfos[msg.sender].passiveExpReturn>0,"invalid");
        require(userInfos[msg.sender].isDividendDeactive==false,"you are not eligible");
        uint lastShare = userGains[msg.sender].passiveReturnShare;
        uint transAmount= passiveReturnTotalFundCollection-lastShare;
        
        if (transAmount>userInfos[msg.sender].passiveExpReturn){

            transAmount=userInfos[msg.sender].passiveExpReturn;
        }

        if (transAmount>0){

            userGains[msg.sender].totalPassiveGain+=transAmount;
            userGains[msg.sender].netTotalUserWithdrawable_ += transAmount;
            userInfos[msg.sender].passiveExpReturn-=transAmount;

            emit payPassiveEv(now, transAmount,msg.sender);

        }
        
        userGains[msg.sender].passiveReturnShare=passiveReturnTotalFundCollection;

        return true;

    }

    function getPassiveIncome( address _user) public view returns(uint){

     
       uint transAmount;
        
        if (passiveReturnTotalFundCollection>0 && userInfos[_user].passiveExpReturn>0 && userInfos[_user].isDividendDeactive==false){

                uint lastShare = userGains[_user].passiveReturnShare;
                transAmount= passiveReturnTotalFundCollection-lastShare;
                if (transAmount>userInfos[_user].passiveExpReturn){

                    transAmount=userInfos[_user].passiveExpReturn;
                }

        }

        return (transAmount);
    }


    //----------------------------------------------------WonderPool-Income------------------

    function updatePool(address userAddress, uint _amount) internal {

        // update user return share 
        if (userInfos[userAddress].poolExpReturn==0 && userGains[userAddress].poolReturnShare==0){

            // newly user 
            totalPoolEligible++;
            userInfos[userAddress].poolExpReturn=(_amount*autopoolMultiplier);

        }else if (userInfos[userAddress].poolExpReturn==0 && userGains[userAddress].poolReturnShare!=0 && userInfos[userAddress].isDividendDeactive==false ){

            // when user get his all expfund

                totalPoolEligible--;
                userInfos[userAddress].isDividendDeactive=true;

        }else if (userInfos[userAddress].isDividendDeactive==true && userInfos[userAddress].poolExpReturn==0 ){

            // re-active old user
            totalPoolEligible++;
            userInfos[userAddress].poolExpReturn=(_amount*autopoolMultiplier);
            userInfos[userAddress].isDividendDeactive=false;

        }else if (userInfos[userAddress].poolExpReturn!=0 && userInfos[userAddress].isDividendDeactive==false){

            userInfos[userAddress].poolExpReturn+=(_amount*autopoolMultiplier); // update exp return on new level buy
        }

        userGains[userAddress].poolReturnShare=poolReturnTotalFundCollection;
        

        //return closing 

        if( block.timestamp>=lastPoolClose+Closing_TimeStep_Pool){
            poolReturnTotalFundCollection+=poolReturnTodayCollection;
            poolReturnTodayCollection=0; //reset 
            lastPoolClose= block.timestamp;
        }

    }


    // passive call

    function CalculateDailyPool(uint8 _level) internal{

        uint calcAmount = priceOfLevel[_level];
       poolReturnTodayCollection+=calcAmount;

    } 

    function closeTodayPoolIncome() public returns(bool) {

        require(poolReturnTodayCollection>0,"You don't have enough roiFund");
        require(block.timestamp>=lastPoolClose+Closing_TimeStep_Pool,"you can't close before 1 day ");
        poolReturnTotalFundCollection+=poolReturnTodayCollection;
        poolReturnTodayCollection=0; //reset 
        lastPoolClose= block.timestamp;

        //todayROIShare = returnTotalFundCollection/totalRoiEligible;
        
        return true;

     }

    function claimPoolIncome() public returns(bool) {

        require(poolReturnTotalFundCollection>0 ,"You don't have enough roiFund");
        require(userInfos[msg.sender].poolExpReturn>0,"invalid");
        require(userInfos[msg.sender].isPoolDivDeactive==false,"you are not eligible");
        uint lastShare = userGains[msg.sender].poolReturnShare;
        uint transAmount= poolReturnTotalFundCollection-lastShare;
        
        if (transAmount>userInfos[msg.sender].poolExpReturn){

            transAmount=userInfos[msg.sender].poolExpReturn;
        }

        if (transAmount>0){

            userGains[msg.sender].totalPoolGain+=transAmount;
            userGains[msg.sender].netTotalUserWithdrawable_ += transAmount;
            userInfos[msg.sender].poolExpReturn-=transAmount;

            emit payPoolEv(now, transAmount,msg.sender);

        }
        
        userGains[msg.sender].poolReturnShare=poolReturnTotalFundCollection;

        return true;

    }

    function getPoolIncome( address _user) public view returns(uint){

     
       uint transAmount;
        
        if (poolReturnTotalFundCollection>0 && userInfos[_user].poolExpReturn>0 && userInfos[_user].isPoolDivDeactive==false){

                uint lastShare = userGains[_user].poolReturnShare;
                transAmount= poolReturnTotalFundCollection-lastShare;
                if (transAmount>userInfos[_user].poolExpReturn){

                    transAmount=userInfos[_user].poolExpReturn;
                }


        }

        return (transAmount);
    }




    function rescueToken(address _token,uint amount) external onlyOwner{

        ERC20In(_token).transfer(address(uint160(owner)),amount);
    }


    function changeAutoPoolMultiplier(uint _multiplier) external onlyOwner{

        autopoolMultiplier=_multiplier;
    }


    function Switch_Interface () external onlyOwner  returns (string memory) {

        USDT_INTERFACE_ENABLE=!USDT_INTERFACE_ENABLE;
        
        if (USDT_INTERFACE_ENABLE==true){

            return "USDT INTERFACE ENABLED";

        }else{

            return "ERC20 INTERFACE ENABLED";
        }
    }

    function ChangePoolClosingTime(uint _time) external onlyOwner{

        Closing_TimeStep_Pool= _time;

    }

    function ChangeDivClosingTime(uint _time) external onlyOwner{

        Closing_TimeStep_Div= _time;

    }


    function getUserLevelInfos(address _user, uint8 _level) external view returns(uint,uint,uint) {

        uint fBox; uint UpgradeFund; uint reCount;
        fBox= userInfos[_user].levels[_level].fillBox;
        UpgradeFund=userInfos[_user].levels[_level].upgradeFund;
        reCount= fBox= userInfos[_user].levels[_level].reinvestCount;

        return(fBox,UpgradeFund,reCount);
    }


    function updateLevelUpgrade(address _user, uint8 _level,uint _amount) internal {

        //reset fill box
        userInfos[_user].levels[_level].fillBox=0;
        userInfos[_user].levels[_level].upgradeFund+=_amount;

        // check upgradablity 
        if(userInfos[_user].levels[_level].upgradeFund>=priceOfLevel[_level]){

            userInfos[_user].levels[_level].upgradeFund-=priceOfLevel[_level];

            // upgrade user levels

            _buyLevel(_user,_level);

           emit reinvestEv(block.timestamp,_level,_user);

            userInfos[_user].levels[_level].reinvestCount++;
        }

    }


}