/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract Test is Ownable {

//-------------------[PRICE CHART STORAGE]----------------

    // DEPOSIT
    uint128 constant JOIN_PRICE = 6e18;     // join price / entry price.
    uint128 constant BOOSTER_PRICE = 10e18;  // Meta booster growth price.
    
    //DISTRIBUTION    
    uint128 constant SPONSER_PAY = 1e18;    // Direct sponsor pay.
    uint128 constant SLOT_SPONSOR = 2e18;   // Slot sponsor pay.
    uint128 constant INFINITY_PAY = 1e18;   // Infinity pay.
   

    // SLOT PRICE
    uint8 public constant LAST_SLOT_LEVEL = 9;  // [4,8,16,32,64,128,256,512,1024]
    uint128 constant TEAM_DEPTH = 5;        // Uni-level distribution on depth.
   
    //Dividend Collection
    uint128  dividend_Collection;
    
    // Dividend storage
    uint64 public nextDividend;
    uint32 public dividend_Index;
    uint32  dividendUser_Count;
    // system Storage
    uint128 totalBoosterFund;
    uint32 public lastIDCount;

   

    address defaultAddress; //this is 1 number ID.
    address  constant zeroAddress=0x0000000000000000000000000000000000000000;// zero address.

    struct sysInfo{

        uint32 splitDividend; // withdraw fee that is dedcut when you will proccess for withdraw.
        uint32 infinityHelpCount;//infinity help from systems.
        uint64 dividendClosing;// Divivdend closing time.
        uint128 boosterPayDaily;//global pool help from systems.
        
    }
    sysInfo public sysInfos ;



   struct userInfo {
        bool        joined;         // for checking user active/deactive status
        bool        isDividendQualify;  // Dividend qualify done or not.
        address     referrer;       // user sponser address. 
        uint32      id;             // user id.
        uint32      activeDirect;   // active direct user
        uint32      pay_Index;      // where you from claim your dividend.
        uint32      booster_Index;  // where you from claim your dividend.
        uint32      lastSlotBuy;    // store last slot buy
        mapping(uint32 => P6) p6Pool;
        mapping(uint32 => bool) activeP6Slots; //* we can check here to optimize
    }


    struct P6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

     struct userIncome{
       
        uint128 sponserGains; // direct gains.
        uint128 slotSponsorGains; // Slot Sponsor gains.
        uint128 metaP6Gain;// P6 matrix gain
        uint128 uniLevelGains; // Unilevel gains.
        uint128 infinityGains;// infinity club income.
        
        uint128 dividendGains; // how much you get dividend.
        uint128 dividendLimit; // how much you get dividend.
        
        uint128 boosterSponsorGains; //Active Royality.
        uint128 boosterGains; //Active Royality.
        uint128 boosterLimit; //Active Royality.
        uint128 lastBoosterPay;//  Last Booster paid.

        uint32  booster_Count;//   who much booster 
        
    }

    
    struct infinity3x
    { 
        uint32 userID;
        uint32 autoPoolParent;
        uint32 mIndex;
    }

    struct dividend
    {  
        uint32 dividend_Users;
        uint128 dividend_Fund;
        uint128 dividend_Total_Share; 
    }

    
    infinity3x[] public infinity3xDataList;
    mapping(uint=>bool) infinity3xControl;
    
    uint32 public mIndex3x;
    uint32 infinity3xParentFill;
    uint32 infinity3xDownlineFill;

    mapping (uint => dividend) public dividends;
    mapping (address => userInfo) public userInfos;
    mapping (address=> userIncome) public userGains;
    mapping (uint => address) public userAddressByID;
    mapping(uint32 => uint) public slotLevelPrice;

 


//--------------------------------EVENT SECTION --------------------------------------


    event NewUserPlace(address indexed user, address indexed referrer, uint32 level, uint32 place);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint32 level);
    event MissedEthReceive(address indexed receiver, address indexed from, uint32 level);
    event metaP6_Ev(address from_user, address to_user, uint amount);
    event BuyNewSlot(address user, uint level);
      // FINANCIAL EVENT
    event regUser_Ev(address indexed user, address referral,uint id);
    event sponsorDirect_Ev(address from_user,address to_user,uint amount);
    event slotDirect_Ev(address from_user,address to_user,uint amount);
    event metaM6_Ev(address from_user, address to_user, uint amount);
    event unilevel_Ev(address _from , address _to,uint level,uint amount);
    event boosterDeposit_Ev(address user, uint amount, uint count);
    event boosterSponsorGrowth_Ev(address _from , address user,uint amount);
    event boosterGrowth_Ev(address user,uint amount);
    event dividendGrowth_Ev(address user,uint amount);

    // INFINITY EVENTS 

    event infinity3xPayEv (uint _index,uint _from,uint _toUser, uint _amount);
    event infinity3xRebirth (uint _index, uint _fromUser, uint _toUser);
    event infinity3xPosition (uint _index,uint usrID, uint _parentIndex,uint _mainIndex);
    
    


    constructor(address _defaultAddress){

        for (uint8 i = 1; i <= LAST_SLOT_LEVEL; i++) {

             if (i==1){

                 slotLevelPrice[i] = 4 ether;

                 continue;
             }

            slotLevelPrice[i] = slotLevelPrice[i-1] * 2;
        }

        defaultAddress = _defaultAddress;

                // like _reguser(defaultAddress)

        lastIDCount++;


        userInfos[defaultAddress].joined=true;
        userInfos[defaultAddress].id=lastIDCount;
        userInfos[defaultAddress].isDividendQualify=true;

         emit regUser_Ev(defaultAddress,address(0),lastIDCount);

        for (uint8 i = 1; i <= LAST_SLOT_LEVEL; i++) {

            userInfos[defaultAddress].activeP6Slots[i] = true;
        }

    }
  


    function p6QualificationNddeduction(address user,uint level, uint allotFund) internal view returns (uint) {

            uint direct = userInfos[user].activeDirect;
            uint elDirect;

            if(direct<10){


                if (level==2){

                    if (direct<level){

                        return (allotFund*50/100);
                    }

                }else{

                    elDirect = ((level*2)-2);

                    if(direct<elDirect){

                        return (allotFund*50/100);
                    }
                    
                }

            }

            return (0);
    }


    function registration(address referrerAddress) public payable {
        
     require(msg.value == JOIN_PRICE, "Insufficient Joining Fund");
     require(referrerAddress!=zeroAddress && userInfos[referrerAddress].joined==true,"Referral address is not exist");
     require(userInfos[_msgSender()].referrer==zeroAddress && userInfos[_msgSender()].joined==false,"You are already Joined");
        address userAddress=_msgSender();
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        lastIDCount++;
        userInfos[userAddress].joined=true;
        userInfos[userAddress].referrer=referrerAddress;
        userInfos[userAddress].id=lastIDCount;
        userInfos[userAddress].isDividendQualify=true;
        userAddressByID[lastIDCount] = userAddress;
        
        userInfos[referrerAddress].activeDirect++;
        userGains[userAddress].sponserGains += SPONSER_PAY;
        sendFund(referrerAddress,SPONSER_PAY);
       
        _slotBuy(1);
        _infinity3xPosition(userAddress,false);

        emit sponsorDirect_Ev(userAddress,referrerAddress,SPONSER_PAY);
        emit regUser_Ev(userAddress,referrerAddress,lastIDCount);
        
        
    }

    function buyNewSlot() public payable returns(bool){
        
        require(userInfos[_msgSender()].joined==true,"You are not Joined");
        uint32 myLevel=userInfos[_msgSender()].lastSlotBuy++;
        require(msg.value == slotLevelPrice[myLevel], "Insufficient slot fund");
        require( myLevel>0 && myLevel <= LAST_SLOT_LEVEL, "Invalid level");

        _slotBuy(myLevel);

        return true;

    }

    function _slotBuy(uint32 level)internal{

        address freeP6Referrer = findFreeP6Referrer(_msgSender(),level);   
        userInfos[_msgSender()].activeP6Slots[level] = true;

        _distributeLevelAndSponsor(uint128(msg.value));
        
        uint allotFund=msg.value/4;  // 4XpOOL

        updateX6Referrer(_msgSender(), freeP6Referrer, level,allotFund);
        


    }


    // P6 REFERALL UPDATES

    function updateX6Referrer(address userAddress, address referrerAddress, uint32 level, uint allotFund) private {
        require(userInfos[referrerAddress].activeP6Slots[level], "500. Referrer level is inactive");
        
        if (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals.length < 2) {
            userInfos[referrerAddress].p6Pool[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, level, uint32(userInfos[referrerAddress].p6Pool[level].firstLevelReferrals.length));
            
            //set current level
            userInfos[userAddress].p6Pool[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner()) {
                return sendMaticDividends(referrerAddress, userAddress, level, allotFund);
            }
            
            address ref = userInfos[referrerAddress].p6Pool[level].currentReferrer;            
            userInfos[ref].p6Pool[level].secondLevelReferrals.push(userAddress); 
            
            uint len = userInfos[ref].p6Pool[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (userInfos[ref].p6Pool[level].firstLevelReferrals[0] == referrerAddress) &&
                (userInfos[ref].p6Pool[level].firstLevelReferrals[1] == referrerAddress)) {
                if (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals.length == 1) {

                    // need for deduction 
                    emit NewUserPlace(userAddress, ref, level, 5);

                } else {
                    emit NewUserPlace(userAddress, ref, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    userInfos[ref].p6Pool[level].firstLevelReferrals[0] == referrerAddress) {
                if (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref,  level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref,  level, 4);
                }
            } else if (len == 2 && userInfos[ref].p6Pool[level].firstLevelReferrals[1] == referrerAddress) {
                if (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref,  level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref,  level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level,allotFund);
        }
        
        userInfos[referrerAddress].p6Pool[level].secondLevelReferrals.push(userAddress);

        if (userInfos[referrerAddress].p6Pool[level].closedPart != address(0)) {
            if ((userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0] == 
                userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1]) &&
                (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0] ==
                userInfos[referrerAddress].p6Pool[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level,allotFund);
            } else if (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0] == 
                userInfos[referrerAddress].p6Pool[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level,allotFund);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level,allotFund);
            }
        }

        if (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level,allotFund);
        } else if (userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level,allotFund);
        }
        
        if (userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0]].p6Pool[level].firstLevelReferrals.length <= 
            userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1]].p6Pool[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level,allotFund);
    }

    function updateX6(address userAddress, address referrerAddress, uint32 level, bool x2) private {
        if (!x2) {
            userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0]].p6Pool[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0],  level, uint8(userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0]].p6Pool[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress,  level, 2 + uint8(userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0]].p6Pool[level].firstLevelReferrals.length));
            //set current level
            userInfos[userAddress].p6Pool[level].currentReferrer = userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[0];
        } else {
            userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1]].p6Pool[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1], level, uint8(userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1]].p6Pool[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, level, 4 + uint8(userInfos[userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1]].p6Pool[level].firstLevelReferrals.length));
            //set current level
            userInfos[userAddress].p6Pool[level].currentReferrer = userInfos[referrerAddress].p6Pool[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint32 level, uint allotFund) private {
        if (userInfos[referrerAddress].p6Pool[level].secondLevelReferrals.length < 4) {


            findMaticReceiver(userAddress, referrerAddress, level);

            return sendMaticDividends(referrerAddress, userAddress,  level,allotFund);
        }
        
        address[] memory x6 = userInfos[userInfos[referrerAddress].p6Pool[level].currentReferrer].p6Pool[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                userInfos[userInfos[referrerAddress].p6Pool[level].currentReferrer].p6Pool[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    userInfos[userInfos[referrerAddress].p6Pool[level].currentReferrer].p6Pool[level].closedPart = referrerAddress;
                }
            }
        }
        
        userInfos[referrerAddress].p6Pool[level].firstLevelReferrals = new address[](0);
        userInfos[referrerAddress].p6Pool[level].secondLevelReferrals = new address[](0);
        userInfos[referrerAddress].p6Pool[level].closedPart = address(0);

        if (!userInfos[referrerAddress].activeP6Slots[level+1] && level != LAST_SLOT_LEVEL) {
            userInfos[referrerAddress].p6Pool[level].blocked = true;
        }

        userInfos[referrerAddress].p6Pool[level].reinvestCount++;
        
        if (referrerAddress != owner()) {
            address freeReferrerAddress = findFreeP6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level,allotFund);
        } else {
            emit Reinvest(owner(), address(0), userAddress, level);
            sendMaticDividends(owner(), userAddress,  level,allotFund);
        }

        // check for upgrade

    }


    function findFreeP6Referrer(address userAddress, uint32 level) public view returns(address) {
        while (true) {
            if (userInfos[userInfos[userAddress].referrer].activeP6Slots[level]) {
                return userInfos[userAddress].referrer;
            }
            
            userAddress = userInfos[userAddress].referrer;
        }

        return address(0);
    }
        
    function usersActiveP6Levels(address userAddress, uint32 level) public view returns(bool) {
        return userInfos[userAddress].activeP6Slots[level];
    }



    function findMaticReceiver(address userAddress, address _from,  uint32 level) private returns(address) {
        address receiver = userAddress;
      

            while (true) {
                if (userInfos[receiver].p6Pool[level].blocked) {
                    emit MissedEthReceive(receiver, _from,  level);
                    receiver = userInfos[receiver].p6Pool[level].currentReferrer;
                }else{

                    return (receiver);
                }

            }


            return (address(0));


    }


    // this function should avoid due to contract balance withdraw 

    function sendMaticDividends(address userAddress, address _from, uint32 level, uint allotFund) private {
        (address receiver) = findMaticReceiver(userAddress, _from, level);


       

        uint128 deducted  = uint128 (p6QualificationNddeduction(receiver,level, allotFund));

        if (deducted>0){

            dividend_Collection += deducted;
            allotFund= deducted;

             // close dividend here  with this fund 
        }


        sendFund(receiver,allotFund);

        emit metaP6_Ev(_from, receiver, level);
        

    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    
    function _distributeLevelAndSponsor(uint128 _amount) internal {
        
        address ref = userInfos[_msgSender()].referrer;
        userGains[_msgSender()].slotSponsorGains += (_amount/2);
        sendFund(ref,(_amount/2));

        emit slotDirect_Ev(_msgSender(),ref,(_amount/2));
       
        
        uint128 levelAmt = ((_amount/4)/TEAM_DEPTH);
        
        for (uint i=1 ; i <= TEAM_DEPTH; i++){
            
            address usr = ref;
            ref = userInfos[usr].referrer;
            
            if(usr == zeroAddress) usr = defaultAddress;
  
            userGains[usr].uniLevelGains+= levelAmt;
            
            sendFund(usr,levelAmt);
            emit unilevel_Ev(_msgSender(),usr,i,levelAmt);
            
            
        }
   
    }


//====================BOOSTER PROGRAM===================//
  
    function buyBooster(uint32 _count) public payable returns  (bool) {
        
        uint128 totBoostPrice=(BOOSTER_PRICE* _count);
        uint128 boosterFund = totBoostPrice +(INFINITY_PAY* _count);

        require(msg.value == boosterFund,"Insufficient fund");
        require(_msgSender() != zeroAddress && userInfos[_msgSender()].joined == true,"You are not Joined");
        require(userGains[_msgSender()].lastBoosterPay == 0 || userInfos[_msgSender()].booster_Index == 0, "Your booster gain is not finshed");
        require((0 == userGains[_msgSender()].booster_Count && _count <= 2 ) || ( 0 != userGains[_msgSender()].booster_Count && _count <= _boosterBuyLimit()),"Invalid booster entry");
         
    
            totalBoosterFund += totBoostPrice;
            userGains[_msgSender()].lastBoosterPay = totBoostPrice;
            userGains[_msgSender()].boosterLimit += (totBoostPrice*3);
            userGains[_msgSender()].booster_Count += _count;
            userInfos[_msgSender()].booster_Index =  dividend_Index;               
            
            if(_count > 4){
               
               sysInfos.infinityHelpCount += _count - 4;
                _count = 4;

            } 

            for(uint i =0; i<_count ; i++){
                _infinity3xPosition(_msgSender(),true); 
            }
 
       
        emit boosterDeposit_Ev (_msgSender(),(BOOSTER_PRICE*_count),_count);
        
        return true;
    }

     function boosterPotential(address userAddress ) public view returns (uint128 boosterGrowth, uint128 boosterLimit){
     
      
        // 2x limit
       uint128 growthLimit = (userGains[userAddress].boosterLimit - (userGains[userAddress].boosterGains + userGains[userAddress].lastBoosterPay));
       // total limit
       uint128 gainLimit = (userGains[userAddress].boosterLimit - (userGains[userAddress].boosterGains + userGains[userAddress].boosterSponsorGains));



       if(dividend_Index > userInfos[userAddress].booster_Index && userGains[userAddress].lastBoosterPay != 0){
        
         uint128 boosterday = (dividend_Index - userInfos[userAddress].booster_Index);
         boosterGrowth = ((userGains[userAddress].lastBoosterPay*sysInfos.boosterPayDaily/100) * boosterday); 

         if (gainLimit >0 && growthLimit > 0){
           
                if (boosterGrowth > growthLimit){

                    boosterGrowth = growthLimit;

                } 
                
            }


       }
       return (boosterGrowth,growthLimit);

    }

    function _boosterBuyLimit()public view returns(uint buyPotential){
        
        buyPotential = userGains[_msgSender()].boosterGains/BOOSTER_PRICE;
        if(buyPotential > 20) buyPotential = 20;
        return buyPotential;
    }

    function _payBooster() internal {
       
       (uint128 booster_Growth, uint128 booster_limit)=boosterPotential(_msgSender());
    
        address ref =userInfos[_msgSender()].referrer;
        uint128 sponGrowth;
        
            if (booster_Growth > 0 && booster_Growth <= totalBoosterFund && booster_limit > 0 ){

                userGains[_msgSender()].boosterGains += booster_Growth;
                sendFund(_msgSender(),booster_Growth);
                emit boosterGrowth_Ev(_msgSender(),booster_Growth);

                uint128 SponsorGainLimit = (userGains[ref].boosterLimit - (userGains[ref].boosterGains+userGains[ref].boosterSponsorGains));
                
                // Pay Sponsor Gain
                if (SponsorGainLimit > 0 ){
                    sponGrowth= (booster_Growth/2);
                    
                    if(sponGrowth > SponsorGainLimit) sponGrowth = SponsorGainLimit;
                    
                    userGains[ref].boosterSponsorGains += sponGrowth ;

                }
                 
                if (booster_Growth == booster_limit){
                   
                   delete userGains[_msgSender()].lastBoosterPay;
                   delete userInfos[_msgSender()].booster_Index;

                } 

                
                emit boosterGrowth_Ev(_msgSender(),booster_Growth);
                emit boosterSponsorGrowth_Ev(_msgSender(),ref,sponGrowth);

                sendFund(_msgSender(),booster_Growth); 
                sendFund(ref,sponGrowth);
                
            }
             
       
    }

//====================DIVIDEND PROGRAM===================//

     function _closingDividend() internal {
        dividend memory divi=dividends[dividend_Index];
        uint32 tmpDiv = dividendUser_Count;
        
        uint current = block.timestamp;
        if(nextDividend<=current || (defaultAddress==msg.sender) ){
           
            divi.dividend_Users= tmpDiv; 
            divi.dividend_Fund= dividend_Collection;
            divi.dividend_Total_Share=divi.dividend_Total_Share +(divi.dividend_Fund/tmpDiv);
            
            nextDividend= uint64(current + 86400);
          
            delete dividend_Collection;
            
            dividend_Index++;
            dividends[ dividend_Index]=divi;
        }
    }
    

    function viewDividendPotential(address userAddress) public view returns (uint128 dividend_Growth, uint128 dividend_Limit){
     
       uint128 diviGrowth;
       uint128 diviLimit=(userGains[userAddress].dividendLimit - userGains[userAddress].dividendGains);

       if(dividend_Index > userInfos[userAddress].pay_Index && userInfos[userAddress].isDividendQualify == true){
            
            diviGrowth = dividends[dividend_Index].dividend_Total_Share - dividends[ userInfos[userAddress].pay_Index ].dividend_Total_Share; 
   
               
       }
       return (diviGrowth,diviLimit);

    }



    function _PayDividend() internal  {
       
       (uint128 div_Growth, uint128 div_limit)=viewDividendPotential(_msgSender());
        
            if (div_Growth > div_limit){
                 
                 dividend_Collection += (div_Growth-div_limit); 
                 div_Growth = div_limit;

            }
            
            if (div_Growth > 0){

                uint32 divIndex = dividend_Index;
                userGains[_msgSender()].dividendGains+=div_Growth;
                sendFund(_msgSender(),div_Growth);

                if(div_Growth == div_limit){
                 divIndex = 0;
                 userInfos[_msgSender()].isDividendQualify = false;
                 dividendUser_Count--;

                }
                userInfos[_msgSender()].pay_Index = divIndex;
            
                
            }
             
        
       
    }

    function claimDividends() public returns (bool){
        _PayDividend();
        _payBooster();
        helpInfinity();
        return true;
    }

 

    function infinity3xLastIndex() view public returns(uint){

        if (infinity3xDataList.length>0) return infinity3xDataList.length-1;
        revert();
    }


    function totalGains_(address _user) public view returns (uint128){

     
        uint128 total;
        
        total=(userGains[_user].sponserGains + userGains[_user].slotSponsorGains + userGains[_user].metaP6Gain+ userGains[_user].uniLevelGains + userGains[_user].infinityGains + userGains[_user].dividendGains + userGains[_user].boosterSponsorGains + userGains[_user].boosterGains);

        return(total);

    }
    

    function helpInfinity() public {
        
        if(sysInfos.infinityHelpCount>0) {
 
          _infinity3xPosition(defaultAddress,true);
        
          sysInfos.infinityHelpCount--;

            
        }

    }



    function _infinity3xPosition(address _user ,bool _joined) internal returns (bool)
    {

        uint32 tmp;

        if(!_joined){
            mIndex3x++;
            tmp =mIndex3x;
        }

        infinity3x memory mPool3x;
        mPool3x.userID = userInfos[_user].id;
        uint32 idx = infinity3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=tmp;      
        infinity3xDataList.push(mPool3x);
        
       
        emit infinity3xPosition(infinity3xDataList.length-1,mPool3x.userID,idx,tmp);

        if(tmp!=1) payNbirth3x(_user,infinity3xParentFill);

        return true;
    }


    function syncIndex3x() internal {

        if (infinity3xDownlineFill==0) infinity3xDownlineFill=1;
        else if (infinity3xDownlineFill==1) infinity3xDownlineFill=2;
      
        else{

            delete infinity3xDownlineFill;
            infinity3xParentFill++;
            uint32 nextParent= infinity3xParentFill;
            uint recMindex = infinity3xDataList[nextParent].mIndex;

            if(recMindex==0){

                while(recMindex==0){

                    infinity3xParentFill++;
                    nextParent= infinity3xParentFill;
                    recMindex = infinity3xDataList[nextParent].mIndex;
                }

            }


        }
        
    }


    function payNbirth3x(address _user, uint recParentIndx ) internal {

        uint32 recId= infinity3xDataList[recParentIndx].userID;
        address recUser = userAddressByID[recId];

        uint payUser   = userInfos[_user].id;
        uint32 mIndex = infinity3xDataList[recParentIndx].mIndex;
        bool is3xBirth =  infinity3xControl[mIndex];

        if (is3xBirth){

            
            syncIndex3x();
            reBirth3xPosition(mIndex,payUser,recId);
            infinity3xControl[mIndex]=false;
            payNbirth3x(_user,infinity3xParentFill);

        }else{

            
            if (lastIDCount!=1){

               
                
                userGains[recUser].infinityGains+=INFINITY_PAY;
                emit  infinity3xPayEv (mIndex,payUser,recId, INFINITY_PAY);
                sendFund(recUser,INFINITY_PAY); 
                  
               
            }

             infinity3xControl[mIndex]=true;
             syncIndex3x();  

        }


    }


    function reBirth3xPosition(uint32 _mIndex,uint _from, uint32 _to) internal {


        
        infinity3x memory mPool3x;

        mPool3x.userID = _to;
        uint32 idx = infinity3xParentFill;
        mPool3x.autoPoolParent = idx;  
        mPool3x.mIndex=_mIndex;      
        infinity3xDataList.push(mPool3x);


        emit infinity3xPosition(infinity3xDataList.length-1,mPool3x.userID,idx,_mIndex);
        emit infinity3xRebirth(infinity3xDataList.length-1,_from,_to); 

    }





    //----------------------------For receving matic--------------------------------------

    fallback () external {


    }


    receive () external payable {
        
    }

     function sendFund(address _user,uint _amount) internal {

        uint dedectAmt = (_amount*sysInfos.splitDividend/100);
        dividend_Collection += uint128 (dedectAmt);

        payable (_user).transfer(_amount);

    }



}