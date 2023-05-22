/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract Polytrust is ReentrancyGuard {
  using SafeMath for uint256;
  event regLevelEvent(
      address indexed _user,
      address indexed _referrer,
      uint256 _time
  );
  event buyLevelEvent(address indexed _user, uint256 _level, uint256 _time);

  mapping(uint256 => uint256) public LEVEL_PRICE;
  uint256 REFERRER_1_LEVEL_LIMIT;

  uint256 directpercentage;
  uint256 indirectpercentage;

  struct UserStruct {
      bool isExist;
      uint256 id;
      uint256 referrerID;
      uint256 currentLevel;
      uint256 earnedAmount;
      uint256 totalearnedAmount;
      address[] referral;
      address[] allDirect;
      uint256 childCount;
      uint256 upgradeAmount;
      uint256 upgradePending;
      mapping(uint256 => uint256) levelEarningmissed;
  }

  mapping(address => UserStruct) public users;

  mapping(uint256 => address) public userList;

  uint256 public currUserID;
  uint256 public totalUsers;
  address public ownerWallet;
  uint256 public adminFee;
  address[] public joinedAddress;
  mapping(address => uint256) public userJoinTimestamps;
  uint256 public totalProfit;
  uint256 public minwithdraw;
  
  uint256 public totalDays;

    uint256 public initialRoi;
    uint256 public allRoi;
    uint256 public roiLaunchTime;
    mapping(address => uint256) public userUpgradetime;
    mapping(address => uint256) public roiEndTime;
    mapping(address => uint256) public roiStartTime;
   constructor() public {
        ownerWallet = address(0xF24362C2be0E2d397d0fb7D5fb4269A2DBd0b8B2);
        REFERRER_1_LEVEL_LIMIT = 2;
        currUserID = 1;
        totalUsers = 1;
        directpercentage = 10 * 1e18; // 10Matic
        indirectpercentage = 1200; //12%
        adminFee = 10 * 1e18; // 10Matic

        initialRoi = 1500;
        allRoi = 2000;
        roiLaunchTime = 1685161800;

        LEVEL_PRICE[1] = 10 * 1e18; // 10Matic
        LEVEL_PRICE[2] = 20 * 1e18;
        LEVEL_PRICE[3] = 40 * 1e18;
        LEVEL_PRICE[4] = 160 * 1e18;
        LEVEL_PRICE[5] = 1280 * 1e18;
        LEVEL_PRICE[6] = 20480 * 1e18;
        LEVEL_PRICE[7] = 20480 * 1e18;
        LEVEL_PRICE[8] = 40960 * 1e18;
        LEVEL_PRICE[9] = 163840 * 1e18;
        LEVEL_PRICE[10] = 1310720 * 1e18;


        UserStruct memory userStruct;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            currentLevel: 10,
            earnedAmount: 0,
            totalearnedAmount: 0,
            referral: new address[](0),
            allDirect : new address[](0),
            childCount: 0,
            upgradeAmount:0,
            upgradePending : 0
        });

        users[ownerWallet] = userStruct;
        users[ownerWallet].levelEarningmissed[1] = 0;
        users[ownerWallet].levelEarningmissed[2] = 0;
        users[ownerWallet].levelEarningmissed[3] = 0;
        users[ownerWallet].levelEarningmissed[4] = 0;
        users[ownerWallet].levelEarningmissed[5] = 0;
        users[ownerWallet].levelEarningmissed[6] = 0;
        users[ownerWallet].levelEarningmissed[7] = 0;
        users[ownerWallet].levelEarningmissed[8] = 0;
        users[ownerWallet].levelEarningmissed[9] = 0;
        users[ownerWallet].levelEarningmissed[10] = 0;
        userList[currUserID] = ownerWallet;
         
    }

      

    function regUser(address _referrer) public payable noReentrant {
       require(!users[msg.sender].isExist, "User exist");
       require(users[_referrer].isExist, "Invalid referal");

       uint256 _referrerID = users[_referrer].id;

       require(msg.value == LEVEL_PRICE[1] * 2, "Incorrect Value");

       if (
           users[userList[_referrerID]].referral.length >=
           REFERRER_1_LEVEL_LIMIT
       ) {
           _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
       }

       UserStruct memory userStruct;
       currUserID++;
       totalUsers++;

       userStruct = UserStruct({
           isExist: true,
           id: currUserID,
           referrerID: _referrerID,
           earnedAmount: 0,
           totalearnedAmount: 0,
           referral: new address[](0),
           allDirect: new address[](0),
           currentLevel: 1,
           childCount: 0,
           upgradeAmount : 0,
           upgradePending : 0
       });

       users[msg.sender] = userStruct;
       users[msg.sender].levelEarningmissed[2] = 0;
       users[msg.sender].levelEarningmissed[3] = 0;
       users[msg.sender].levelEarningmissed[4] = 0;
       users[msg.sender].levelEarningmissed[5] = 0;
       users[msg.sender].levelEarningmissed[6] = 0;
       users[msg.sender].levelEarningmissed[7] = 0;
       users[msg.sender].levelEarningmissed[8] = 0;
       users[msg.sender].levelEarningmissed[10] = 0;
        
       userList[currUserID] = msg.sender;
       users[userList[_referrerID]].referral.push(msg.sender);
       joinedAddress.push(msg.sender);
       users[_referrer].allDirect.push(msg.sender);
       users[_referrer].childCount = users[_referrer].childCount.add(1);
       payReferal(_referrer);
       payForLevel(1,msg.sender);
       userJoinTimestamps[msg.sender] = block.timestamp;
       userUpgradetime[msg.sender] = block.timestamp;
       roiStartTime[msg.sender] = block.timestamp;
       roiEndTime[msg.sender] = block.timestamp + 100 days;
       emit regLevelEvent(msg.sender, userList[_referrerID], now);
   }


   function payReferal(address _referrer) internal {
       uint256 indirectRefId = users[_referrer].referrerID;
       address indirectRefAddr = userList[indirectRefId];
       if (indirectRefAddr == 0x0000000000000000000000000000000000000000) {
           indirectRefAddr = ownerWallet;
       }
       uint256 levelPrice = LEVEL_PRICE[1] * 2;
       uint256 directAmount = (levelPrice* directpercentage) / 10000;
       uint256 indirectAmount = (levelPrice * indirectpercentage) / 10000;
       payable(ownerWallet).transfer(adminFee);
       users[ownerWallet].totalearnedAmount += adminFee;

       if(users[_referrer].currentLevel < 10){
         users[_referrer].upgradeAmount += directAmount/2;
         users[_referrer].earnedAmount += directAmount/2;
       }else{
         users[_referrer].earnedAmount += directAmount;
       }
       totalProfit +=directAmount;

       if(users[indirectRefAddr].currentLevel < 10){
         users[indirectRefAddr].upgradeAmount += indirectAmount/2;
         users[indirectRefAddr].earnedAmount += indirectAmount/2;
       }else{
         users[indirectRefAddr].earnedAmount += indirectAmount;
       }

       totalProfit +=indirectAmount;

   }

      function payForLevel(uint256 _level, address _user) internal {
          address referer;
          address referer1;
          address referer2;
          address referer3;
          if (_level == 1 || _level == 6) {
              referer = userList[users[_user].referrerID];
          } else if (_level == 2 || _level == 7) {
              referer1 = userList[users[_user].referrerID];
              referer = userList[users[referer1].referrerID];
          } else if (_level == 3 || _level == 8) {
              referer1 = userList[users[_user].referrerID];
              referer2 = userList[users[referer1].referrerID];
              referer = userList[users[referer2].referrerID];
          } else if (_level == 4 || _level == 9) {
              referer1 = userList[users[_user].referrerID];
              referer2 = userList[users[referer1].referrerID];
              referer3 = userList[users[referer2].referrerID];
              referer = userList[users[referer3].referrerID];
          } else if (_level == 5 || _level == 10) {
              referer1 = userList[users[_user].referrerID];
              referer2 = userList[users[referer1].referrerID];
              referer3 = userList[users[referer2].referrerID];
              referer = userList[users[referer3].referrerID];
          }
          uint256 upgradedAmount = 0;
          if(users[msg.sender].upgradePending >= LEVEL_PRICE[_level]){
              users[msg.sender].currentLevel =  _level;
              uint256 oldupgrade = users[msg.sender].upgradePending - users[msg.sender].upgradeAmount;
              users[msg.sender].upgradeAmount = users[msg.sender].upgradePending - LEVEL_PRICE[_level];
              users[msg.sender].upgradePending = 0;
              upgradedAmount = LEVEL_PRICE[_level] - oldupgrade;

              //update old Roi into earning
               uint256 _checkRoiupto = checkRoiUpto(msg.sender);
               users[msg.sender].earnedAmount +=  _checkRoiupto;
               userUpgradetime[_user] = block.timestamp;
               totalProfit += _checkRoiupto;

          }else{
            upgradedAmount = users[msg.sender].upgradeAmount;
            users[msg.sender].upgradeAmount = 0;
          }

          if (users[_user].levelEarningmissed[_level] > 0 && users[msg.sender].currentLevel >= _level) {
              users[_user].earnedAmount += users[_user].levelEarningmissed[_level]/2;
              users[_user].upgradeAmount += users[_user].levelEarningmissed[_level]/2;
              users[_user].levelEarningmissed[_level] = 0;
              totalProfit += users[_user].levelEarningmissed[_level];
          }

          bool isSend = true;
          if (!users[referer].isExist) {
              isSend = false;
          }
          if (isSend) {
              if (users[referer].currentLevel >= _level) {
                  if(users[referer].currentLevel < 10){
                    if(_level == 1){
                      users[referer].upgradeAmount += LEVEL_PRICE[_level];
                      totalProfit += LEVEL_PRICE[_level];
                    }else{
                      users[referer].upgradeAmount += upgradedAmount/2;
                      users[referer].earnedAmount += upgradedAmount/2;
                      totalProfit += upgradedAmount;
                    }
                  }else{
                    uint256 missedAmount = (_level == 1) ? LEVEL_PRICE[_level] : upgradedAmount;
                    users[referer].earnedAmount += missedAmount;
                    totalProfit += missedAmount;
                  }
              } else {
                  users[referer].levelEarningmissed[_level] += upgradedAmount;
              }
          }else{
              uint256 missedAmount = (_level == 1) ? LEVEL_PRICE[_level] : upgradedAmount;
              users[ownerWallet].earnedAmount += missedAmount;
          }
      }

      function upgradeNextLevel() public noReentrant{
        require(users[msg.sender].upgradeAmount >= 0,"Insufficient amount");
        uint256 currentLevel = users[msg.sender].currentLevel;
        uint256 nextLevel = currentLevel+1;
        if(nextLevel <= 10){
          users[msg.sender].upgradePending += users[msg.sender].upgradeAmount;
          payForLevel(nextLevel, msg.sender);
        }
      }

      function claimRewards() public noReentrant{
          require(users[msg.sender].isExist, "User not registered");
          uint256 _checkRoiupto = checkRoiUpto(msg.sender);
          users[msg.sender].earnedAmount += _checkRoiupto;
          totalProfit += _checkRoiupto;
          userUpgradetime[msg.sender] = block.timestamp;
          uint256 claimAmount = users[msg.sender].earnedAmount;
          if (claimAmount > 0) {
              require(users[msg.sender].upgradeAmount == 0 || users[msg.sender].currentLevel >= 8,"Upgrade first then process claim");
               
              payable(msg.sender).transfer(claimAmount);
              users[msg.sender].totalearnedAmount += claimAmount;
              users[msg.sender].earnedAmount = 0;
          }
      }

      function findFreeReferrer(address _user) public view returns (address) {
          if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
              return _user;
          }
          address[] memory referrals = new address[](600);
          referrals[0] = users[_user].referral[0];
          referrals[1] = users[_user].referral[1];
          referrals[2] = users[_user].referral[2];
          address freeReferrer;
          bool noFreeReferrer = true;

          for (uint256 i = 0; i < 600; i++) {
              if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                  if (i < 120) {
                      referrals[(i + 1) * 3] = users[referrals[i]].referral[0];
                      referrals[(i + 1) * 3 + 1] = users[referrals[i]].referral[
                          1
                      ];
                      referrals[(i + 1) * 3 + 2] = users[referrals[i]].referral[
                          2
                      ];
                  }
              } else {
                  noFreeReferrer = false;
                  freeReferrer = referrals[i];
                  break;
              }
          }
          require(!noFreeReferrer, "No Free Referrer");
          return freeReferrer;
      }

      function viewUserReferral(
          address _user
      ) public view returns (address[] memory) {
          return users[_user].referral;
      }

      function getmissedvalue(address _userAddress, uint256 _level)
      public
      view
      returns(uint256)
      {
          return users[_userAddress].levelEarningmissed[_level];
      }

      function viewallDirectUserReferral(
          address _user
      ) public view returns (address[] memory) {
          return users[_user].allDirect;
      }

      function getUsersJoinedLast24Hours() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < totalUsers; i++) {
            address userAddress = userList[i];
            if (userJoinTimestamps[userAddress] != 0 && block.timestamp - userJoinTimestamps[userAddress] <= 86400) {
                count++;
            }
        }
        return count;
      }

    receive() external payable {
        require(msg.sender == ownerWallet,"Not an Owner");
    }

    function checkTime(address _user) public view returns(uint256){
        uint256 startTime = userUpgradetime[_user];
        uint256 endTime = roiEndTime[_user];
        if(!users[_user].isExist){
          return 0;
        }
        if(userUpgradetime[_user] == 0){
          startTime = roiLaunchTime;
        }
        if(endTime == 0){
          endTime = startTime + 100 days;
        }
        uint diff = 0;

        if(block.timestamp <= endTime){
          uint256 startDate = startTime;
          uint256 endDate = block.timestamp;
          diff = (endDate - startDate) / 60 / 60 / 24;
        }else{
          if(endTime > startTime){
            uint256 startDate = startTime;
            uint256 endDate = endTime;
            diff = (endDate - startDate) / 60 / 60 / 24;
          }
        }
        return diff;
    }
    
    function checkRoiUpto(address _user) public view returns(uint256){
      uint256 startTime = userUpgradetime[_user];
      uint256 endTime = roiEndTime[_user];
      if(!users[_user].isExist){
          return 0;
        }
      if(userUpgradetime[_user] == 0){
        startTime = roiLaunchTime;
      }
      if(endTime == 0){
        endTime = startTime + 100 days;
      }
        uint256 dailyroi = 0;
        uint diff = 0;
        if(block.timestamp <= endTime){
          uint256 startDate = startTime;
          uint256 endDate = block.timestamp;
          diff = (endDate - startDate) / 60 / 60 / 24;
        }else{
          if(endTime > startTime){
            uint256 startDate = startTime;
            uint256 endDate = endTime;
            diff = (endDate - startDate) / 60 / 60 / 24;
          }
        }
          // check user level

           if(users[_user].currentLevel == 1){
              dailyroi = (LEVEL_PRICE[2] * initialRoi)/100;
           }else{
             uint256 useramount = 0;
             if(users[_user].currentLevel > 1 && users[_user].currentLevel <=5){
               useramount = LEVEL_PRICE[users[_user].currentLevel];
             }else{
               useramount = LEVEL_PRICE[5];
             }
             dailyroi = (useramount * allRoi)/100;
           }
          uint256 uptoroi = diff.mul(dailyroi).div(1000);
          return uptoroi;
        }

}