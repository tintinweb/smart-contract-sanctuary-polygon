// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract QSMatrix {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        bool autoUpgrade;
        uint8 Max_Level;
        mapping(address => uint256) productFund;
        mapping(uint8 => bool)activeLevels;
        mapping(uint8 => Matrix)matrices;
    }

    struct Matrix {
        address currentReferrer;
        address[] Referrals;
        address[] SecondLevelReferrals;
        bool blocked;
        address closedPart;
        uint reinvestCount; 
    }
    uint8 public constant LASTLEVEL = 12;
    mapping(address => User) users;
    mapping(uint => address)idToAddress;
    mapping(uint => address)userIds;
    uint public lastUserId = 2;
    address public owner;
    mapping(uint8 => uint256) levelPrice;
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    IERC20 private Dai;
    address public DaiAddress = 0x6D8873f56a56f0Af376091beddDD149f3592e854; 

       constructor (address ownerAddress) {
        levelPrice[1] = 10 * 10**18;
        for (uint8 i = 2; i <= LASTLEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        Dai = IERC20(DaiAddress);

        
        owner = ownerAddress;
        
        User storage user = users[owner];
        user.id = lastUserId;
        user.referrer = address(0);
        user.partnersCount = 0;
        user.autoUpgrade = true;
        user.Max_Level = 0;

        idToAddress[1] = ownerAddress;        
        userIds[1] = ownerAddress;

        
        for (uint8 i = 1; i <= LASTLEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;
        }}

        function registrationExt(address referrerAddress) public  {
            registration(msg.sender, referrerAddress);
        }

        function registration(address userAddress, address referrerAddress) private {
            require(users[userAddress].id == 0, "user exists");
            require(users[referrerAddress].id != 0, "referrer not exists");
            
            User storage user = users[userAddress];
            user.id = lastUserId;
            user.referrer = referrerAddress;
            user.partnersCount = 0;
            user.autoUpgrade = true;
            user.Max_Level = 0;
            idToAddress[lastUserId] = userAddress;
            users[userAddress].activeLevels[1] = true;
            updateX6Referrer(userAddress, referrerAddress, 1);
            userIds[lastUserId] = userAddress;
            lastUserId++;
            users[referrerAddress].partnersCount++;
            
            //emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        }
        //paymentRequire(level)   
        function buyNewLevels(uint8 level) public isUserExists  {
            require(level >= 1 && level <= LASTLEVEL, "invalid level");
            require(!users[msg.sender].activeLevels[level], "level already activated");

            if (users[msg.sender].matrices[level-1].blocked) {
                users[msg.sender].matrices[level-1].blocked = false;
            }

            
            users[msg.sender].activeLevels[level] = true; 
            if (level == 3 ||level == 6 ||level == 9 ||level == 12 ) {
                updateX3Referrer(msg.sender, findFreeReferrer(msg.sender, 1), level);
            } else {
                updateX6Referrer(msg.sender, findFreeReferrer(msg.sender, 1), level);
            }

            //emit Upgrade(msg.sender, freeReferrer, level);
            users[msg.sender].Max_Level++;
        }


        function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) internal {
            uint referralsCount = users[referrerAddress].matrices[level].Referrals.length;
            users[referrerAddress].matrices[level].Referrals.push(userAddress);

            if (referralsCount < 3) {
                //return sendDividends(referrerAddress, userAddress, level, 3, referralsCount);
            }

            Matrix storage refMatrix = users[referrerAddress].matrices[level];
            refMatrix.Referrals = new address[](0);

            if (!users[referrerAddress].activeLevels[level+1] && level != LASTLEVEL) {
                refMatrix.blocked = true;
            }

            if (referrerAddress != owner) {
                address freeReferrerAddress = findFreeReferrer(referrerAddress, level);
                refMatrix.currentReferrer = freeReferrerAddress;
                refMatrix.reinvestCount++;
                emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
                updateX3Referrer(referrerAddress, freeReferrerAddress, level);
            } else {
                //sendDividends(owner, userAddress, level, 3, referralsCount);
                refMatrix.reinvestCount++;
                emit Reinvest(owner, address(0), userAddress, 1, level);
            }
        }


    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeLevels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].matrices[level].Referrals.length < 2) {
            users[referrerAddress].matrices[level].Referrals.push(userAddress);
            //emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].matrices[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                //return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].matrices[level].currentReferrer;            
            users[ref].matrices[level].SecondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].matrices[level].Referrals.length;
            
            if ((len == 2) && 
                (users[ref].matrices[level].Referrals[0] == referrerAddress) &&
                (users[ref].matrices[level].Referrals[1] == referrerAddress)) {
                if (users[referrerAddress].matrices[level].Referrals.length == 1) {
                   // emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                   // emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].matrices[level].Referrals[0] == referrerAddress) {
                if (users[referrerAddress].matrices[level].Referrals.length == 1) {
                   // emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                   // emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].matrices[level].Referrals[1] == referrerAddress) {
                if (users[referrerAddress].matrices[level].Referrals.length == 1) {
                  //  emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    //emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].matrices[level].Referrals.push(userAddress);

        if (users[referrerAddress].matrices[level].closedPart != address(0)) {
            if ((users[referrerAddress].matrices[level].Referrals[0] == 
                users[referrerAddress].matrices[level].Referrals[1]) &&
                (users[referrerAddress].matrices[level].Referrals[0] ==
                users[referrerAddress].matrices[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].matrices[level].Referrals[0] == 
                users[referrerAddress].matrices[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].matrices[level].Referrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].matrices[level].Referrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].matrices[level].Referrals[0]].matrices[level].Referrals.length <= 
            users[users[referrerAddress].matrices[level].Referrals[1]].matrices[level].Referrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].matrices[level].Referrals[0]].matrices[level].Referrals.push(userAddress);
           // emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
           // emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].matrices[level].currentReferrer = users[referrerAddress].matrices[level].Referrals[0];
        } else {
            users[users[referrerAddress].matrices[level].Referrals[1]].matrices[level].Referrals.push(userAddress);
            //emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
           // emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].matrices[level].currentReferrer = users[referrerAddress].matrices[level].Referrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].matrices[level].SecondLevelReferrals.length < 4) {
            //return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].matrices[level].currentReferrer].matrices[level].Referrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].matrices[level].currentReferrer].matrices[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].matrices[level].currentReferrer].matrices[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].matrices[level].Referrals = new address[](0);
        users[referrerAddress].matrices[level].SecondLevelReferrals = new address[](0);
        users[referrerAddress].matrices[level].closedPart = address(0);

        if (!users[referrerAddress].activeLevels[level+1] && level != LASTLEVEL) {
            users[referrerAddress].matrices[level].blocked = true;
        }

        users[referrerAddress].matrices[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            //sendETHDividends(owner, userAddress, 2, level);
        }
    }
    

    function findFreeReferrer(address userAddress, uint8 level) private view returns (address) {
        address referrer = address(0);
        while (true) {
            if (users[users[userAddress].referrer].activeLevels[level]) {
                referrer = users[userAddress].referrer;
                break;
            }
            
            userAddress = users[userAddress].referrer;
            
            if (userAddress == owner) {
                referrer = owner;
                break;
            }
        }
        
        return referrer;
        }

        modifier isUserExists {
            require (users[msg.sender].id != 0, "UserAddress is not Exists, Register First");
            _; 
        }

        modifier paymentRequire (uint8 level) {
            require (Dai.transfer(address(this), levelPrice[level]), "Payment Fail, not enought Balance Or not Enought Allowance");
            _;
        }

        modifier approval {
            require(Dai.approve(address(this), levelPrice[LASTLEVEL]),"cannot Approve Account");
            _;
        }


}