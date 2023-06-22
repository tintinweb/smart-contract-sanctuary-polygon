/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IS {
//boost factory calling
 //--->boost list contract
    function addBoost(address _boostAdmin, address _boostContract) external;
    function changeOwnerOfLastSpot (address _boostContract, address _ls) external;
    function getIsBoostFromFactory(address _addr) view external returns (bool) ;
    function popInactiveUserBoosts(address _addr) external;
    function readEngagoor(address _addr) external view returns (EngagedContracts[] memory);
 //--->individual boost
    function makeWithdrawal(uint _id, address _addr) external;
    function getUserPendingRewards(address _addr) view external returns (uint);
    function getUsersAlivePendingRewards(address _addr) view external returns (uint);
// individual boost calling 
 // boost factory
    function wasGasFreeIncrement(uint _socialID, uint _wasGasFree) external;
    function revenueIncrement(uint _revenue) external;
    function userRevenueIncrement(uint _id, uint _revenue) external;
 // boost lists contract
    function addEngagedBoost(address _addr, address _boostContract, uint _created) external;
    function addLeaderBoard(string memory _username, address _addr, uint _usersRevenue) external; 
    function isSignatureValid(bytes calldata signature, address _addr) view external returns (bool); 
    function setBoostInactive (address _boostAdmin, address _boost) external;
}

struct EngagedContracts {
 address boostContract;
 uint created;
 }
struct Leaders {
 uint lastContribution;
 string username;
 uint usersRevenue;
 address addr;
 }

contract Boost {
// contract addresses
 address protocol;
 address boostFactory;
 address boostListContract;
 // distribution of revenue
 uint flips_flipperShare;
 uint flips_flipper_spotCashBack;
 uint flips_boostAdminShare;
 uint flips_usersShare;
 uint spot_boostAdminShare;
 uint spot_usersShare;
 //boost time attributes
 uint spotBusyTime;
 uint created;
 uint startTime;
 uint actTimer;
 uint duration;
 uint extention;
 // price and price increase
 uint initPrice;
 uint nextPriceIncrease;
// boost admin
 address boostAdmin;
 string username;
 string mainPromo;
 string url;
// others
 uint maxUsers; 
 address lastSpotPotCurrentOwner;
 address lastSpotPot;
 uint spotCounter;
 uint revenue;
 uint usersRevenue;

    function _a(address _addr) private view {
        require (_addr == boostAdmin, "");
        }
        modifier onlyBoostAdmin(address _addr) {
        _a(_addr);
        _;
        }
 mapping (address => uint) pendingReward;
 mapping (address => uint) pendingRewardCreator;
 error NotEnoughEther();
 error TooManyUsers();

 constructor(address _boostFactory, address _boostListContract, address _protocol, address _boostAdmin, uint _initPrice, uint _nextPriceIncrease, uint _extention, uint _duration, string memory _mainPromo, string memory _url, string memory _username) {
 protocol = _protocol;
 spot_boostAdminShare=0;
 spot_usersShare=64;
 flips_flipperShare=0;
 flips_boostAdminShare=0;
 flips_usersShare=100;
 flips_flipper_spotCashBack=50;
 maxUsers=3500;
 spotBusyTime=1800; 
 boostFactory=_boostFactory;
 boostAdmin=_boostAdmin;
 boostListContract=_boostListContract;
 lastSpotPot=0xFD350CDf9587DA9533bdb17E5CABb10BCD6217CB;
 initPrice =_initPrice;
 nextPriceIncrease=_nextPriceIncrease;
 extention=_extention;
 duration=_duration;
 mainPromo=_mainPromo;
 actTimer=duration;
 startTime=block.timestamp;
 lastSpotPotCurrentOwner=boostAdmin;
 created=block.timestamp;
 username=_username;
 url=_url;
 }

 struct Spots {
    uint spotNumber;
    uint priceOfSpot;
    uint bu; 
    address flipper;
    string promo;
    string avatar;
    }
 Spots [] spots;
 
 struct HeartBeat{
    uint index;
    uint livesUntil;
    }
 mapping(address => HeartBeat) addressToHeartBeat;
 address[] engagedKeyList;
 
 // Engage to be alive
    function engageToBeAlive (uint _socialID, address _addr, bytes calldata signature, uint _type, uint _wasGasFree) public {
        require(IS(boostListContract).isSignatureValid(signature, _addr)==true, "");
        require((startTime+actTimer) > block.timestamp, "");
        HeartBeat storage engaged = addressToHeartBeat[_addr];
        engaged.livesUntil=block.timestamp + _type;
            if(engaged.index > 0){
            return;}
            else if (engagedKeyList.length < maxUsers) {
                engagedKeyList.push(_addr);
                uint keyListIndex = engagedKeyList.length - 1;
                engaged.index = keyListIndex + 1;
                engaged.livesUntil = block.timestamp + _type; 
                IS(boostListContract).addEngagedBoost(_addr, address(this), created);
            }
            else revert TooManyUsers();
        IS(boostFactory).wasGasFreeIncrement(_socialID, _wasGasFree);
        }
 //Create spot
    function createSpot(string memory _promo, string memory _avatar) external payable {
        require((startTime+actTimer) > block.timestamp, "end");
        if (msg.value != initPrice) revert NotEnoughEther();
        revenue += initPrice;
        IS(boostFactory).revenueIncrement(initPrice);
        pendingReward[protocol] += (initPrice * 6/100);
        pendingReward[lastSpotPot] += (initPrice * 30/100);
        pendingRewardCreator[boostAdmin] += (initPrice * spot_boostAdminShare/100);
        usersRevenue += (initPrice * spot_usersShare/100);
        // loop active users to distribute
            uint totalAlive;
            for (uint i = 0; i < engagedKeyList.length; i++) {
            HeartBeat storage engaged = addressToHeartBeat[engagedKeyList[i]];
            if (engaged.livesUntil > block.timestamp) {
            totalAlive += 1;}
            }
            for (uint i = 0; i < engagedKeyList.length; i++) {
            HeartBeat storage engaged = addressToHeartBeat[engagedKeyList[i]];
            if (engaged.livesUntil > block.timestamp) {
            pendingReward[engagedKeyList[i]] += ((initPrice * spot_usersShare/100)/totalAlive);}
            }
            // if zero active then distribute to boost admin
            if (totalAlive == 0) {
            pendingRewardCreator[boostAdmin]+=(initPrice * spot_usersShare/100);}
        uint nextPrice = initPrice + ((initPrice * nextPriceIncrease)/100);
        spotCounter=spotCounter+1;
        uint spotNumber = spotCounter;
        string memory promo = _promo;
        string memory avatar= _avatar;
        lastSpotPotCurrentOwner=msg.sender;
        //timer start
        uint timeLeft = actTimer - (block.timestamp-startTime);
        if (block.timestamp - created > 604800)
        {actTimer= 0;}
        else if (timeLeft+extention >=duration)
        {actTimer=duration;}
        else {actTimer= timeLeft+ extention;}
        startTime = block.timestamp;
        //timer end
        spots.push(Spots(spotNumber, nextPrice,block.timestamp+spotBusyTime, msg.sender, promo, avatar));
        IS(boostListContract).changeOwnerOfLastSpot(address(this), lastSpotPotCurrentOwner);
        }
 //Flip spot
    function flipSpot(uint _index, string memory _promo, string memory _avatar) external payable {
        uint cashback;
        Spots storage spot = spots[_index];
        require(spot.bu < block.timestamp, "");
        require((startTime+actTimer) > block.timestamp, "");
        if (msg.value != spot.priceOfSpot) revert NotEnoughEther();
        revenue += spot.priceOfSpot;
        IS(boostFactory).revenueIncrement(spot.priceOfSpot);
        uint currentPrice = spot.priceOfSpot;
        uint previousPrice = ((currentPrice / ((100 + nextPriceIncrease)))*100);
        cashback = ((previousPrice * flips_flipper_spotCashBack)/100);
        uint exFlipperProfit = ((currentPrice - previousPrice) * flips_flipperShare)/100;
        uint nextPrice = ((spot.priceOfSpot * ((100 + nextPriceIncrease)))/100);
        pendingReward[spot.flipper] += (cashback + exFlipperProfit);
        //give back to flipper now
        uint flipReward = pendingReward[spot.flipper];
        pendingReward[spot.flipper] = 0;
        payable(spot.flipper).transfer(flipReward);
        //give back to flipper end
        uint toDistro = spot.priceOfSpot - (cashback + exFlipperProfit);
        usersRevenue += (toDistro - (toDistro * flips_boostAdminShare/100));
        pendingRewardCreator[boostAdmin] += (toDistro * flips_boostAdminShare/100);
        // loop active users to distribute
            uint totalAlive;
            for (uint i = 0; i < engagedKeyList.length; i++) {
            HeartBeat storage engaged = addressToHeartBeat[engagedKeyList[i]];
            if (engaged.livesUntil > block.timestamp) {
            totalAlive += 1;}
            }
            for (uint i = 0; i < engagedKeyList.length; i++) {
            HeartBeat storage engaged = addressToHeartBeat[engagedKeyList[i]];
            if (engaged.livesUntil > block.timestamp) {
            pendingReward[engagedKeyList[i]] += (toDistro * flips_usersShare/100) /totalAlive;}
            }
            // if zero active then distribute to boost admin
            if (totalAlive == 0) {
            pendingRewardCreator[boostAdmin]+=(toDistro * flips_usersShare/100);}
        spot.flipper = msg.sender;
        spot.priceOfSpot = nextPrice;
        spot.bu = block.timestamp+spotBusyTime;
        spot.promo = _promo;
        spot.avatar= _avatar;
        lastSpotPotCurrentOwner=msg.sender;
        //timer start
        uint timeLeft = actTimer - (block.timestamp-startTime);
        if (block.timestamp - created > 604800)
        {actTimer= 0;}
        else if (timeLeft+extention >=duration)
        {actTimer=duration;}
        else {actTimer= timeLeft+ extention;}
        startTime = block.timestamp;
        //timer end
        IS(boostListContract).changeOwnerOfLastSpot(address(this), lastSpotPotCurrentOwner);
        }
//Get spots
    function getSpots() public view returns (Spots[] memory){
        Spots[] memory id = new Spots[](spots.length);
        for (uint i = 0; i < spots.length; i++) {
        Spots storage spot = spots[i];
        id[i] = spot;
        }
        return id;
        }
//Spot reset
    function resetSpot(address _addr, uint _index) external onlyBoostAdmin(_addr){
        Spots storage spot = spots[_index];
        spot.priceOfSpot=initPrice;
        spot.bu=0;
        lastSpotPotCurrentOwner=boostAdmin;
        }
//make withdrawal 
    function makeWithdrawal(uint _id, address _addr) external {
        HeartBeat storage engaged = addressToHeartBeat[_addr];
        if (engaged.livesUntil < block.timestamp || pendingReward[_addr] == 0) {
            return;
        } else {
            uint amount = pendingReward[_addr];
            pendingReward[_addr] = 0;
            payable(_addr).transfer(amount);
            IS(boostFactory).userRevenueIncrement(_id, amount);
            }
        }
//make withdrawal of Last Spot Pot
    function makeWithdrawalLSP(string memory _username, address _addr) external {
        require((startTime+actTimer) <= block.timestamp, "");
        uint amountLsp = pendingReward[lastSpotPot];
        uint amountBoostAdmin = pendingRewardCreator[boostAdmin];
        pendingReward[lastSpotPot] = 0;
        pendingRewardCreator[boostAdmin] = 0;
        payable(lastSpotPotCurrentOwner).transfer(amountLsp);
        payable(boostAdmin).transfer(amountBoostAdmin);
        //collect dust
        uint totalInactiveSum;
        for (uint i = 0; i < engagedKeyList.length; i++) {
        HeartBeat storage engaged = addressToHeartBeat[engagedKeyList[i]];
        if (engaged.livesUntil < (startTime+actTimer) && pendingReward[engagedKeyList[i]] > 0) {
        totalInactiveSum += pendingReward[engagedKeyList[i]];
        pendingReward[engagedKeyList[i]] = 0; 
        }
        }
        pendingReward[protocol] += totalInactiveSum;
        // end collecting dust
        uint amountProtocol= pendingReward[protocol];
        pendingReward[protocol] = 0;
        payable(protocol).transfer(amountProtocol);
        IS(boostListContract).addLeaderBoard(_username, _addr, usersRevenue);
        IS(boostListContract).setBoostInactive(boostAdmin, address(this));
        actTimer=0;
        }
//Get boost data
    function getBoostDetailInfo() view external returns (uint, uint,address,uint, uint, uint, uint, uint, string memory, string memory,string memory,uint) {
        return (pendingRewardCreator[boostAdmin], pendingReward[lastSpotPot],lastSpotPotCurrentOwner,created,duration, extention, actTimer,startTime, mainPromo, username, url, revenue);
        }
//Get user data
    function getUserDetailInfo(address _addr) view external returns (uint, uint, uint) {
        HeartBeat storage engaged = addressToHeartBeat[_addr];
        return (engaged.livesUntil, pendingReward[_addr], engagedKeyList.length);
        }
// Get user pending rewards
    function getUserPendingRewards(address _addr) view external returns (uint) {
        uint stillWithdrawableRewards;
        HeartBeat memory engaged = addressToHeartBeat[_addr];
        if ((startTime+actTimer) > block.timestamp || engaged.livesUntil > block.timestamp){
            stillWithdrawableRewards=pendingReward[_addr];
        } else {stillWithdrawableRewards=0;}
    return stillWithdrawableRewards;
        }
//Get only Living pending rewards
    function getUsersAlivePendingRewards(address _addr) view external returns (uint) {
        uint pendingLivingRewards;
        HeartBeat memory engaged = addressToHeartBeat[_addr];
        if (engaged.livesUntil > block.timestamp){
            pendingLivingRewards=pendingReward[_addr];
        } else {pendingLivingRewards=0;}
    return pendingLivingRewards;
    }
//Get changable boost parameters in first 5 minutes
    function getBoostParameters() public view returns (uint, uint, uint, uint, uint, uint, uint, uint,uint, address, address) {
        return (flips_flipperShare,flips_flipper_spotCashBack,flips_boostAdminShare, flips_usersShare, spot_boostAdminShare, spot_usersShare, maxUsers,spotBusyTime,initPrice, boostAdmin, protocol);
        }
//Set changable boost parameters in first 5 minutes
 function setBoostParameters (address _addr, uint _flips_flipperShare, uint _flips_boostAdminShare, uint _flips_flipper_spotCashBack, uint _flips_usersShare, uint _spot_boostAdminShare, uint _spot_usersShare, uint _spotBusyTime) external onlyBoostAdmin(_addr){
    require ((flips_boostAdminShare+flips_usersShare) == 100 && (spot_boostAdminShare+spot_usersShare) == 64 && flips_flipperShare <=100 && flips_flipper_spotCashBack<=100 && (created+300) > block.timestamp, "");
    flips_flipperShare = _flips_flipperShare;
    flips_flipper_spotCashBack = _flips_flipper_spotCashBack;
    flips_boostAdminShare = _flips_boostAdminShare;
    flips_usersShare = _flips_usersShare;
    spot_boostAdminShare = _spot_boostAdminShare;
    spot_usersShare = _spot_usersShare;
    spotBusyTime = _spotBusyTime;
    }
//Update mainPromo
    function changePromoTweet(address _addr, string memory _mainPromo) external onlyBoostAdmin(_addr){
        mainPromo = _mainPromo;
        } 
    }

 contract BoostFactory {
 address protocol;
 address boostContract;
 address boostListContract;
 mapping (uint => uint) gasFreeCounter;
 uint revenue;
 mapping (uint => uint) userRevenue;
 
 constructor (address _boostListContract) {
 protocol = msg.sender;
 boostListContract=_boostListContract;
 }

    function _onlyBF() private view {
        require(IS(boostListContract).getIsBoostFromFactory(msg.sender)==true, "");
        }
        modifier _onlyBoostFactoryBoosts() {
        _onlyBF();
        _;
        }
        
 //0xCa3316440f7a79263b5c0E082393A44193D943c2, 10000000000000000, 20, 5, 60, 1635936373822865414, https://pbs.twimg.com/profile_images/1624229555333373952/JXGKFcO__normal.jpg, biconomy
 //creating a new boost
    event createNewBoost (string username, address boost);
    function createBoost(address _addr, uint _initPrice, uint _np, uint _extention, uint _duration, string memory _mainPromo, string memory _url, string memory _username) external returns(address){
        require(_extention <=3600 && _duration<= 604800 && _duration >= 3600, "");
        boostContract = address(new Boost(address(this),boostListContract,protocol, _addr, _initPrice, _np, _extention, _duration, _mainPromo, _url, _username));
        IS(boostListContract).addBoost(_addr, boostContract);
        emit createNewBoost (_username, boostContract); 
        return (boostContract);
        }
// user revenue increment
    function userRevenueIncrement(uint _id, uint _revenue) external _onlyBoostFactoryBoosts() { 
        userRevenue[_id] += _revenue;
        }
// read user revenue
    function getUserRevenue(uint _id) view external returns (uint) {
        return userRevenue[_id];
        }

// revenue increment
    function revenueIncrement(uint _revenue) external _onlyBoostFactoryBoosts() { 
        revenue += _revenue;
        }
// read revenue
    function getRevenue() view external returns (uint) {
        return revenue;
        }
// gas free increment 
    function wasGasFreeIncrement(uint _socialID, uint _wasGasFree) external _onlyBoostFactoryBoosts()  { 
        gasFreeCounter[_socialID] += _wasGasFree;
        }
// read free gas counter
    function getFreeGasCounter(uint _socialID) view external returns (uint) {
        return (gasFreeCounter[_socialID]);
        }
//make batch withdrawal
    function batchWithDrawal(uint _socialID, address _addr, uint _wasGasFree) external {
        IS(boostListContract).popInactiveUserBoosts(_addr);
        EngagedContracts[] memory contracts = IS(boostListContract).readEngagoor(_addr);
        for (uint i = 0; i < contracts.length; i++) {
        IS(contracts[i].boostContract).makeWithdrawal(_socialID, _addr);
        }
        gasFreeCounter[_socialID] += _wasGasFree;
        }
// read all balances
    function readAllBalances (address _addr) view external returns (uint) {
        EngagedContracts[] memory contracts = IS(boostListContract).readEngagoor(_addr);
        uint balances;
        for (uint i = 0; i < contracts.length; i++) {
        uint balance;
        balance= IS(contracts[i].boostContract).getUserPendingRewards(_addr);
        balances += balance;
        }
        return (balances);
        }
// read only Alive balances
    function readOnlyAliveBalances (address _addr) view external returns (uint) {
        EngagedContracts[] memory contracts = IS(boostListContract).readEngagoor(_addr);
        uint balances;
        for (uint i = 0; i < contracts.length; i++) {
        uint balance;
        balance= IS(contracts[i].boostContract).getUsersAlivePendingRewards(_addr);
        balances += balance;
        }
        return (balances);
        }
// read all engaged boosts in order to show user if he/she is still active
    function readAllEngagedContracts (address _addr) view external returns (EngagedContracts[] memory) {
        EngagedContracts[] memory contracts = IS(boostListContract).readEngagoor(_addr);
        return (contracts);
        }
}