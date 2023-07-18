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


        function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) internal {
            Matrix storage referrer = users[referrerAddress].matrices[level];
            Matrix storage referrer1 = users[referrer.Referrals[0]].matrices[level];
            Matrix storage referrer2 = users[referrer.Referrals[1]].matrices[level];

            if (referrer1.Referrals.length == 0 && referrer2.Referrals.length == 0) {
                users[userAddress].matrices[level].currentReferrer = referrer.Referrals[0];
                referrer1.Referrals.push(userAddress);
            } else if (referrer1.Referrals.length <= referrer2.Referrals.length) {
                users[userAddress].matrices[level].currentReferrer = referrer.Referrals[0];
                referrer1.Referrals.push(userAddress);
            } else {
                users[userAddress].matrices[level].currentReferrer = referrer.Referrals[1];
                referrer2.Referrals.push(userAddress);
            }

            if (referrerAddress == owner) {
                //return sendDividends(owner, userAddress, level, 6, referrer.Referrals.length);
            }

            updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }

            function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) internal {
        Matrix storage referrerMatrix = users[referrerAddress].matrices[level];

        if (referrerMatrix.SecondLevelReferrals.length < 4) {
            //return sendDividends(referrerAddress, userAddress, level, 6, referrerMatrix.secondLevelReferrals.length);
        }

        Matrix storage referrer = users[referrerAddress].matrices[level];
        Matrix storage ref = users[referrer.currentReferrer].matrices[level];

        if (referrer.Referrals.length == 2 && (referrer.Referrals[0] == referrerAddress || referrer.Referrals[1] == referrerAddress)) {
            ref.closedPart = referrerAddress;
        } else if (referrer.Referrals.length == 1 && referrer.Referrals[0] == referrerAddress) {
            ref.closedPart = referrerAddress;
        }

        referrer.Referrals = new address[](0);
        referrer.SecondLevelReferrals = new address[](0);
        referrer.closedPart = address(0);

        if (!users[referrerAddress].activeLevels[level+1] && level != LASTLEVEL) {
            referrer.blocked = true;
        }

        referrer.reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            //sendDividends(owner, userAddress, level, 6, referrerMatrix.secondLevelReferrals.length);
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