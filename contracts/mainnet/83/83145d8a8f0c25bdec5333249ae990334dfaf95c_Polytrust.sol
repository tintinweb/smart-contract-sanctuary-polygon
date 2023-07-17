/**
 *Submitted for verification at polygonscan.com on 2023-07-17
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
    uint256 public totalDays;

    uint256 public initialRoi;
    uint256 public allRoi;
    uint256 public roiLaunchTime;
    mapping(address => uint256) public userUpgradetime;
    mapping(address => uint256) public roiEndTime;
    mapping(address => uint256) public roiStartTime;

    Polytrust public oldPolytrust;
    Polytrust public oldPolytrustnew;
    address public migrateOwner;

    constructor() public{
        ownerWallet = address(0xF24362C2be0E2d397d0fb7D5fb4269A2DBd0b8B2);
        REFERRER_1_LEVEL_LIMIT = 2;
        currUserID = 1;
        totalUsers = 1;
        directpercentage = 2000; //20%
        indirectpercentage = 0;
        adminFee = 10 * 1e18; // 10Matic
        initialRoi = 1500;
        allRoi = 2000;
        roiLaunchTime = 43406218;

        LEVEL_PRICE[1] = 10 * 1e18;
        LEVEL_PRICE[2] = 20 * 1e18;
        LEVEL_PRICE[3] = 40 * 1e18;
        LEVEL_PRICE[4] = 160 * 1e18;
        LEVEL_PRICE[5] = 1280 * 1e18;
        LEVEL_PRICE[6] = 20480 * 1e18;
        LEVEL_PRICE[7] = 20480 * 1e18;
        LEVEL_PRICE[8] = 40960 * 1e18;
        LEVEL_PRICE[9] = 163840 * 1e18;
        LEVEL_PRICE[10] = 1310720 * 1e18;

        UserStruct storage user = users[ownerWallet];
        user.isExist = true;
        user.id = currUserID;
        user.referrerID = 0;
        user.currentLevel = 10;
        user.earnedAmount = 0;
        user.totalearnedAmount = 0;
        user.referral = new address[](0);
        user.allDirect = new address[](0);
        user.childCount = 0;
        user.upgradeAmount = 0;
        user.upgradePending = 0;
        user.levelEarningmissed[1] = 0;
        user.levelEarningmissed[2] = 0;
        user.levelEarningmissed[3] = 0;
        user.levelEarningmissed[4] = 0;
        user.levelEarningmissed[5] = 0;
        user.levelEarningmissed[6] = 0;
        user.levelEarningmissed[7] = 0;
        user.levelEarningmissed[8] = 0;
        user.levelEarningmissed[9] = 0;
        user.levelEarningmissed[10] = 0;
        userList[currUserID] = ownerWallet;

        userUpgradetime[ownerWallet] = block.timestamp;
        roiStartTime[ownerWallet] = block.timestamp;
        roiEndTime[ownerWallet] = block.timestamp + 100 days;
        oldPolytrust = Polytrust(0x3Cad0Fa215E97BC2e6Abf3E766e0B01cad2aE7F2);
        oldPolytrustnew = Polytrust(0x97A977B3C248F8AAeB2473a494D5F5a07579BDb8);
        migrateOwner = address(0x689CB5f6EEA607073bd63aFDa3F289F29291f57A);
    }

    function regUser(address _referrer) public payable noReentrant {
        require(!users[msg.sender].isExist, "User exist");
        require(users[_referrer].isExist, "Invalid referal");

        uint256 _referrerID = users[_referrer].id;

        require(msg.value == LEVEL_PRICE[1] * 3, "Incorrect Value");

        if (
            users[userList[_referrerID]].referral.length >=
            REFERRER_1_LEVEL_LIMIT
        ) {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }

        currUserID++;
        totalUsers++;

        UserStruct storage user = users[msg.sender];
        user.isExist = true;
        user.id = currUserID;
        user.referrerID = _referrerID;
        user.currentLevel = 1;
        user.earnedAmount = 0;
        user.totalearnedAmount = 0;
        user.referral = new address[](0);
        user.allDirect = new address[](0);
        user.childCount = 0;
        user.upgradeAmount = 0;
        user.upgradePending = 0;
        user.levelEarningmissed[2] = 0;
        user.levelEarningmissed[3] = 0;
        user.levelEarningmissed[4] = 0;
        user.levelEarningmissed[5] = 0;
        user.levelEarningmissed[6] = 0;
        user.levelEarningmissed[7] = 0;
        user.levelEarningmissed[8] = 0;
        user.levelEarningmissed[9] = 0;
        user.levelEarningmissed[10] = 0;
        userList[currUserID] = msg.sender;

        users[userList[_referrerID]].referral.push(msg.sender);
        joinedAddress.push(msg.sender);
        users[_referrer].allDirect.push(msg.sender);
        users[_referrer].childCount = users[_referrer].childCount.add(1);
        address refAddr = userList[_referrerID];
        uint256 refId = users[refAddr].referrerID;
        payReferal(_referrer, refId);
        payForLevel(1, msg.sender);
        userJoinTimestamps[msg.sender] = block.timestamp;
        userUpgradetime[msg.sender] = block.timestamp;
        roiStartTime[msg.sender] = block.timestamp;
        roiEndTime[msg.sender] = block.timestamp + 100 days;
        emit regLevelEvent(msg.sender, userList[_referrerID], block.timestamp);
    }

    function payReferal(address _referrer, uint256 indirectRefId) internal {
        address indirectRefAddr = userList[indirectRefId];
        if (indirectRefAddr == 0x0000000000000000000000000000000000000000) {
            indirectRefAddr = ownerWallet;
        }
        uint256 levelPrice = LEVEL_PRICE[1] * 3;
        uint256 directAmount = (levelPrice * directpercentage) / 10000;
        uint256 indirectAmount = (levelPrice * indirectpercentage) / 10000;
        payable(ownerWallet).transfer(adminFee);
        users[ownerWallet].totalearnedAmount += adminFee;

        if (users[_referrer].currentLevel < 10) {
            users[_referrer].earnedAmount += directAmount;
        } else {
            users[_referrer].earnedAmount += directAmount;
        }
        totalProfit += directAmount;

        if (users[indirectRefAddr].currentLevel < 10) {
            users[indirectRefAddr].earnedAmount += indirectAmount;
        } else {
            users[indirectRefAddr].earnedAmount += indirectAmount;
        }

        totalProfit += indirectAmount;
    }

    function payForLevel(uint256 _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;
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
            referer4 = userList[users[referer3].referrerID];
            referer = userList[users[referer4].referrerID];
        }
        uint256 upgradedAmount = 0;
        if (users[_user].upgradePending >= LEVEL_PRICE[_level]) {
            users[_user].currentLevel = _level;
            uint256 oldupgrade = users[_user].upgradePending - users[_user].upgradeAmount;
            users[_user].upgradeAmount = users[_user].upgradePending - LEVEL_PRICE[_level];
            if(users[_user].upgradeAmount > 0){
               // autoUpgrade(_user);
            }else{
                users[_user].upgradeAmount = 0;
            }
            
            users[_user].upgradePending = 0;
            upgradedAmount = LEVEL_PRICE[_level] - oldupgrade;

            //update old Roi into earning
            uint256 _checkRoiupto = checkRoiUpto(_user);
            users[_user].earnedAmount += _checkRoiupto;
            userUpgradetime[_user] = block.timestamp;
            totalProfit += _checkRoiupto;
        } else {
            upgradedAmount = users[_user].upgradeAmount;
            users[_user].upgradeAmount = 0;
        }

        // if (
        //     users[_user].levelEarningmissed[_level] > 0 &&
        //     users[_user].currentLevel >= _level
        // ) {
        //     users[_user].earnedAmount +=
        //         users[_user].levelEarningmissed[_level] /
        //         2;
        //     users[_user].upgradeAmount +=
        //         users[_user].levelEarningmissed[_level] /
        //         2;
        //     if (users[_user].upgradeAmount > 0) {
        //         autoUpgrade(_user);
        //     }
        //     users[_user].levelEarningmissed[_level] = 0;
        //     totalProfit += users[_user].levelEarningmissed[_level];
        // }
        
        bool isSend = true;
        if (!users[referer].isExist) {
            isSend = false;
        }
        if (isSend) {
            if (users[referer].currentLevel >= _level) {
                if (users[referer].currentLevel < 10) {
                    if (_level == 1) {
                        users[referer].upgradeAmount += LEVEL_PRICE[_level];
                        autoUpgrade(referer);
                        totalProfit += LEVEL_PRICE[_level];
                    } else {
                        users[referer].upgradeAmount += upgradedAmount / 2;
                        autoUpgrade(referer);
                        users[referer].earnedAmount += upgradedAmount / 2;
                        totalProfit += upgradedAmount;
                    }
                } else {
                    uint256 missedAmount = (_level == 1)
                        ? LEVEL_PRICE[_level]
                        : upgradedAmount;
                    users[referer].earnedAmount += missedAmount;
                    totalProfit += missedAmount;
                }
            } else {
                users[referer].upgradeAmount += upgradedAmount / 2;
                autoUpgrade(referer);
                users[referer].earnedAmount += upgradedAmount / 2;
                totalProfit += upgradedAmount;

                // users[referer].levelEarningmissed[_level] += upgradedAmount;

            }
        } else {
            uint256 missedAmount = (_level == 1)
                ? LEVEL_PRICE[_level]
                : upgradedAmount;
            users[ownerWallet].earnedAmount += missedAmount;
        }
    }

    function claimRewards() public noReentrant {
        require(users[msg.sender].isExist, "User not registered");
        uint256 _checkRoiupto = checkRoiUpto(msg.sender);
        users[msg.sender].earnedAmount += _checkRoiupto;
        totalProfit += _checkRoiupto;
        userUpgradetime[msg.sender] = block.timestamp;
        uint256 claimAmount = users[msg.sender].earnedAmount;
        require(claimAmount > 0, "Invalid Claim");
        payable(msg.sender).transfer(claimAmount);
        users[msg.sender].totalearnedAmount += claimAmount;
        users[msg.sender].earnedAmount = 0;
    }

    function findFreeReferrer(address _user) public view returns (address) {
        if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
            return _user;
        }
        address[] memory referrals = new address[](600);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 600; i++) {
            if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if (i < 120) {
                    referrals[(i + 1) * 2] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].referral[
                        1
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

    function getmissedvalue(
        address _userAddress,
        uint256 _level
    ) public view returns (uint256) {
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
            if (
                userJoinTimestamps[userAddress] != 0 &&
                block.timestamp - userJoinTimestamps[userAddress] <= 86400
            ) {
                count++;
            }
        }
        return count;
    }

    receive() external payable {
        require(msg.sender == ownerWallet, "Not an Owner");
    }

    function checkTime(address _user) public view returns (uint256) {
        uint256 startTime = userUpgradetime[_user];
        uint256 endTime = roiEndTime[_user];
        if (!users[_user].isExist) {
            return 0;
        }
        if (userUpgradetime[_user] == 0) {
            startTime = roiLaunchTime;
        }
        if (endTime == 0) {
            endTime = startTime + 100 days;
        }
        uint diff = 0;

        if (block.timestamp <= endTime) {
            uint256 startDate = startTime;
            uint256 endDate = block.timestamp;
            diff = (endDate - startDate) / 60 / 60 / 24;
        } else {
            if (endTime > startTime) {
                uint256 startDate = startTime;
                uint256 endDate = endTime;
                diff = (endDate - startDate) / 60 / 60 / 24;
            }
        }
        return diff;
    }

    function checkRoiUpto(address _user) public view returns (uint256) {
        uint256 startTime = userUpgradetime[_user];
        uint256 endTime = roiEndTime[_user];
        if (!users[_user].isExist) {
            return 0;
        }
        if (userUpgradetime[_user] == 0) {
            startTime = roiLaunchTime;
        }
        if (endTime == 0) {
            endTime = startTime + 100 days;
        }
        uint256 dailyroi = 0;
        uint diff = 0;
        if (block.timestamp <= endTime) {
            uint256 startDate = startTime;
            uint256 endDate = block.timestamp;
            diff = (endDate - startDate) / 60 / 60 / 24;
        } else {
            if (endTime > startTime) {
                uint256 startDate = startTime;
                uint256 endDate = endTime;
                diff = (endDate - startDate) / 60 / 60 / 24;
            }
        }
        // check user level

        if (users[_user].currentLevel == 1) {
            dailyroi = (LEVEL_PRICE[1] * initialRoi) / 100;
        } else {
            uint256 useramount = 0;
            if (
                users[_user].currentLevel > 1 && users[_user].currentLevel <= 5
            ) {
                useramount = LEVEL_PRICE[users[_user].currentLevel];
            } else {
                useramount = LEVEL_PRICE[5];
            }
            dailyroi = (useramount * allRoi) / 100;
        }
        uint256 uptoroi = diff.mul(dailyroi).div(1000);
        return uptoroi;
    }

    function autoUpgrade(address _user) internal {
        require(users[_user].isExist, "User not registered");
        require(users[_user].upgradeAmount >= 0, "Insufficient amount");
        uint256 currentLevel = users[_user].currentLevel;
        uint256 nextLevel = currentLevel + 1;
        if (nextLevel <= 10) {
            users[_user].upgradePending += users[_user].upgradeAmount;
            payForLevel(nextLevel, _user);
        }
    }

    function depositToUpgrade() public payable noReentrant {
        require(users[msg.sender].isExist, "User Not exist");
        require(msg.value > 0, "Not a valid Amount");
        users[msg.sender].upgradeAmount += msg.value;
        autoUpgrade(msg.sender);
    }

    function safeWithDraw(uint256 _amount, address payable addr) public {
        require(msg.sender == ownerWallet, "Not an Owner");
        addr.transfer(_amount);
    }

    function oldPolytrustSync(uint256 oldId, uint limit) public {
        require(address(oldPolytrust) != address(0), "Initialize closed");
        require(msg.sender == migrateOwner, "Access denied");
        for (uint i = 0; i < limit; i++) {
            UserStruct memory olduser;
            address oldusers = oldPolytrust.userList(oldId);

            (
                olduser.isExist,
                olduser.id,
                olduser.referrerID,
                olduser.currentLevel,
                ,
                ,
                olduser.childCount,
                olduser.upgradeAmount,
                olduser.upgradePending
            ) = oldPolytrust.users(oldusers);

            if (olduser.isExist) {
                users[oldusers].isExist = olduser.isExist;
                users[oldusers].id = olduser.id;
                users[oldusers].referrerID = olduser.referrerID;
                users[oldusers].currentLevel = olduser.currentLevel;
                users[oldusers].earnedAmount = 0;
                users[oldusers].totalearnedAmount = 0;
                users[oldusers].referral = oldPolytrust.viewUserReferral(
                    oldusers
                );
                users[oldusers].allDirect = oldPolytrust
                    .viewallDirectUserReferral(oldusers);
                users[oldusers].childCount = olduser.childCount;
                users[oldusers].upgradeAmount = olduser.upgradeAmount;
                users[oldusers].upgradePending = olduser.upgradePending;
                uint256 missedAmounts = 0;
                for (uint256 level = 0; level < 10; level++) {
                    missedAmounts += oldPolytrust.getmissedvalue(oldusers, level.add(1));
                }
                users[oldusers].upgradeAmount += missedAmounts/2;
                users[oldusers].earnedAmount += missedAmounts/2;
                userList[oldId] = oldusers;
                joinedAddress.push(oldusers);
                userJoinTimestamps[oldusers] = oldPolytrust.userJoinTimestamps(
                    oldusers
                );
                oldId++;
            }
        }
        totalProfit = oldPolytrust.totalProfit();
        totalUsers = oldPolytrust.totalUsers();
        currUserID = oldPolytrust.currUserID();
    }
function oldPolytrustSyncnew(uint256 oldId, uint limit) public {
        require(address(oldPolytrustnew) != address(0), "Initialize closed");
        require(msg.sender == migrateOwner, "Access denied");
        for (uint i = 0; i < limit; i++) {
            UserStruct memory olduser;
            address oldusers = oldPolytrustnew.userList(oldId);

            (
                olduser.isExist,
                olduser.id,
                olduser.referrerID,
                olduser.currentLevel,
                ,
                ,
                olduser.childCount,
                olduser.upgradeAmount,
                olduser.upgradePending
            ) = oldPolytrustnew.users(oldusers);

            if (olduser.isExist) {
                users[oldusers].isExist = olduser.isExist;
                users[oldusers].id = olduser.id;
                users[oldusers].referrerID = olduser.referrerID;
                users[oldusers].currentLevel = olduser.currentLevel;
                users[oldusers].earnedAmount = 0;
                users[oldusers].totalearnedAmount = 0;
                users[oldusers].referral = oldPolytrustnew.viewUserReferral(
                    oldusers
                );
                users[oldusers].allDirect = oldPolytrustnew
                    .viewallDirectUserReferral(oldusers);
                users[oldusers].childCount = olduser.childCount;
                users[oldusers].upgradeAmount = olduser.upgradeAmount;
                users[oldusers].upgradePending = olduser.upgradePending;
                uint256 missedAmounts = 0;
                for (uint256 level = 0; level < 10; level++) {
                    missedAmounts += oldPolytrustnew.getmissedvalue(oldusers, level.add(1));
                }
                users[oldusers].upgradeAmount += missedAmounts/2;
                users[oldusers].earnedAmount += missedAmounts/2;
                userList[oldId] = oldusers;
                joinedAddress.push(oldusers);
                userJoinTimestamps[oldusers] = oldPolytrustnew.userJoinTimestamps(
                    oldusers
                );
                oldId++;
            }
        }
        totalProfit = oldPolytrustnew.totalProfit();
        totalUsers = oldPolytrustnew.totalUsers();
        currUserID = oldPolytrustnew.currUserID();
    }

    function oldPolytrustSync1(uint256 oldId, uint limit) public {
        require(address(oldPolytrustnew) != address(0), "Initialize closed");
        require(msg.sender == migrateOwner, "Access denied");

        for (uint i = 0; i < limit; i++) {
            UserStruct memory olduser1;
            address oldusers1 = oldPolytrustnew.userList(oldId);
            (
                olduser1.isExist,
                ,
                ,
                ,
                olduser1.earnedAmount,
                olduser1.totalearnedAmount,
                ,
                ,

            ) = oldPolytrustnew.users(oldusers1);
            if (olduser1.isExist) {
                users[oldusers1].earnedAmount += olduser1.earnedAmount;
                users[oldusers1].totalearnedAmount = olduser1.totalearnedAmount;
                userUpgradetime[oldusers1] = oldPolytrustnew.userUpgradetime(
                    oldusers1
                );
                roiStartTime[oldusers1] = oldPolytrustnew.roiStartTime(oldusers1);
                roiEndTime[oldusers1] = oldPolytrustnew.roiEndTime(oldusers1);
                oldId++;
            }
        }
    }
}