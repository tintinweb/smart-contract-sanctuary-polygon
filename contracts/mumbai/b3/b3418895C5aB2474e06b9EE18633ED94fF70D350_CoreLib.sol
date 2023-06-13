// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./OptionsLib.sol";

library CoreLib {
    event Registration(uint32 userId);

    enum BalanceType {
        Direct,
        BNB
    }

    bytes32 internal constant NAMESPACE = keccak256("magnet.lib.core");

    struct User {
        uint8[3] programLevels;
        address mainAddress;
        uint32 p1Parent;
        uint32 referrer;
        uint32[] directReferrals;
        uint[16] balances;
        uint[16] bnbBalances;
    }

    struct Storage {
        uint8 maxProgramLevel;
        bool initialized;
        uint32 usersCounter;
        mapping(uint32 => User) users;
        mapping(uint8 => uint) levelPrices;
        mapping(address => uint32) userIds;
        mapping(uint32 => uint32[3][]) p1Referrals; // user ID => array of matrices of referrals of users
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function getUserId(address _address) internal view returns (uint32) {
        return getStorage().userIds[_address];
    }

    function getUser(uint32 _userId) internal view returns (User memory) {
        return getStorage().users[_userId];
    }

    function getUsersCounter() internal view returns (uint32) {
        return getStorage().usersCounter;
    }

    function getUserByAddress(
        address _address
    ) internal view returns (User memory) {
        return getStorage().users[getStorage().userIds[_address]];
    }

    function getUserBalances(
        address _address,
        BalanceType _balanceType
    ) internal view returns (uint[16] memory) {
        return getTargetBalance(getStorage().userIds[_address], _balanceType);
    }

    function getUserBalance(
        address _address,
        uint8 _program,
        BalanceType _balanceType
    ) internal view returns (uint) {
        require(0 < _program && _program < 16, "The program does not exist");
        return
            getTargetBalance(getStorage().userIds[_address], _balanceType)[
                _program
            ];
    }

    function getUserProgramLevel(
        uint32 _userId,
        uint8 _program
    ) internal view returns (uint8) {
        return getStorage().users[_userId].programLevels[_program - 1];
    }

    function getLevelPrices(uint8 _levelNumber) internal view returns (uint) {
        return getStorage().levelPrices[_levelNumber];
    }

    function getAmountToClaim(
        address _address,
        BalanceType _balanceType
    ) internal view returns (uint) {
        uint[16] memory balances = getTargetBalance(
            getStorage().userIds[_address],
            _balanceType
        );
        uint amountToClaim;
        for (uint i = 0; i < balances.length; i++) {
            amountToClaim += balances[i];
        }
        return amountToClaim;
    }

    function getP1Referrals(
        uint32 _userId
    ) internal view returns (uint32[3][] memory) {
        return getStorage().p1Referrals[_userId];
    }

    function register(
        address _address,
        uint32 _referrer,
        uint _value,
        BalanceType _balanceType
    ) internal {
        Storage storage s = getStorage();
        require(
            s.users[s.userIds[_address]].mainAddress == address(0),
            "User is already registered"
        );
        require(
            s.users[_referrer].mainAddress != address(0),
            "Referrer is not registered"
        );
        s.usersCounter++;
        s.userIds[_address] = s.usersCounter;
        s.users[s.userIds[_address]].programLevels = [1, 1, 1];
        s.users[s.userIds[_address]].p1Parent = _referrer;
        s.users[s.userIds[_address]].referrer = _referrer;
        s.users[s.userIds[_address]].mainAddress = _address;
        s.users[_referrer].directReferrals.push(s.usersCounter);

        setP1UserPos(s.usersCounter, _referrer);

        if (_balanceType == BalanceType.Direct) {
            distributeLeader(1, s.usersCounter, _value / 3);
            distributeLeader(2, s.usersCounter, _value / 3);
            distributeLeader(3, s.usersCounter, _value / 3);
        }

        // distributePartnerP1(s.usersCounter, _value / 3, BalanceType.Direct);

        distributePartner(1, s.usersCounter, _value / 3, _balanceType);
        distributePartner(2, s.usersCounter, _value / 3, _balanceType);
        distributePartner(3, s.usersCounter, _value / 3, _balanceType);

        // distributeRefferal(
        //     2,
        //     s.usersCounter,
        //     _value / 3,
        //     BalanceType.Direct
        // );
        // distributeRefferal(
        //     3,
        //     s.usersCounter,
        //     _value / 3,
        //     BalanceType.Direct
        // );

        // distributeStruct(3, s.usersCounter, _value / 3, BalanceType.Direct);

        emit Registration(s.usersCounter);
    }

    function initialize() internal {
        Storage storage s = getStorage();
        require(!s.initialized, "Core is already initialized");
        uint price = 1000000000000000;
        for (uint8 i = 1; i < 16; i++) {
            s.levelPrices[i] = price;
            price = price * 2;
        }
        s.initialized = true;
        s.usersCounter++;
        s.userIds[msg.sender] = s.usersCounter;
        s.maxProgramLevel = 15;
        uint[16] memory balances;
        uint32[] memory directReferrals;
        s.users[s.usersCounter] = User(
            [15, 15, 15],
            msg.sender,
            1,
            1,
            directReferrals,
            balances,
            balances
        );
    }

    function distributeLeader(
        uint8 _program,
        uint32 _userId,
        uint _value
    ) internal {
        Storage storage s = getStorage();
        payable(s.users[s.users[_userId].p1Parent].mainAddress).transfer(
            (_value * OptionsLib.getLeaderBonusPercent(_program)) / 1000
        );
    }

    function distributePartner(
        uint8 _program,
        uint32 _userId,
        uint _value,
        BalanceType _balanceType
    ) internal {
        Storage storage s = getStorage();
        uint8[] memory partnerPercents = OptionsLib.getPartnerPercents(
            _program
        );
        uint8 programLevel = getUserProgramLevel(_userId, _program);
        uint32 currentReferrerId = s.users[s.users[_userId].referrer].referrer;

        for (uint8 i = 0; i < partnerPercents.length; i++) {
            uint[16] storage targetBalance = getTargetBalance(
                currentReferrerId,
                _balanceType
            );
            targetBalance[programLevel] += (_value * partnerPercents[i]) / 1000;

            currentReferrerId = s.users[currentReferrerId].referrer;
        }
    }

    // function distributeReferralP1(
    //     uint32 _userId,
    //     uint _value,
    //     BalanceType balanceType
    // ) internal {
    //     Storage storage s = getStorage();
    //     uint8 programLevel = getUserProgramLevel(_userId, 1);
    //     uint8[] memory referralPercents = OptionsLib.getReferralPercents(1);

    //     // Start with the direct parent
    //     uint32 currentParentId = s.users[_userId].p1Parent;

    //     for (uint8 i = 0; i < referralPercents.length; i++) {
    //         // выбираем соответствующий баланс
    //         uint[16] storage targetBalance;
    //         if (balanceType == BalanceType.Direct) {
    //             targetBalance = s.users[currentParentId].balances;
    //         } else {
    //             targetBalance = s.users[currentParentId].bnbBalances;
    //         }

    //         // Distribute the referral bonus
    //         targetBalance[programLevel] +=
    //             (_value * referralPercents[i]) /
    //             1000;

    //         // Move up in the referral tree
    //         currentParentId = s.users[currentParentId].p1Parent;
    //     }
    // }

    // function distributeRefferal(
    //     uint8 _program,
    //     uint32 _userId,
    //     uint _value,
    //     BalanceType balanceType // новый параметр
    // ) internal {
    //     Storage storage s = getStorage();
    //     uint8 programLevel = getUserProgramLevel(_userId, _program);
    //     uint8[] memory refferalPercents = OptionsLib.getReferralPercents(
    //         _program
    //     );

    //     for (uint8 i = 0; i < refferalPercents.length; i++) {
    //         uint[16] storage targetBalance = getTargetBalance(
    //             _userId - i + 1,
    //             BalanceType.Direct
    //         );
    //         targetBalance[programLevel] +=
    //             (_value * refferalPercents[i]) /
    //             1000;
    //     }
    // }

    function distributeStruct(
        uint8 _program,
        uint32 _userId,
        uint _value,
        BalanceType balanceType
    ) internal {
        Storage storage s = getStorage();
        uint8 programLevel = getUserProgramLevel(_userId, _program);
        uint8[] memory upPercents = OptionsLib.getStructPartnerUpPercents(
            _program
        );
        uint8[] memory downPercents = OptionsLib.getStructPartnerDownPercents(
            _program
        );

        for (uint8 i = 0; i < upPercents.length; i++) {
            uint[16] storage targetBalance = getTargetBalance(
                _userId + 1 + i,
                balanceType
            );
            targetBalance[programLevel] += (_value * upPercents[i]) / 1000;
        }

        for (uint8 i = 0; i < downPercents.length; i++) {
            uint32 targetUserId = _userId < i + 1 ? 1 : _userId - 1 - i;
            uint[16] storage targetBalance = getTargetBalance(
                targetUserId,
                balanceType
            );

            targetBalance[programLevel] += (_value * downPercents[i]) / 1000;
        }
    }

    // Функция для выбора нужного баланса в зависимости от типа
    function getTargetBalance(
        uint32 userId,
        BalanceType balanceType
    ) internal view returns (uint[16] storage) {
        Storage storage s = getStorage();
        if (balanceType == BalanceType.Direct) {
            return s.users[userId].balances;
        } else {
            return s.users[userId].bnbBalances;
        }
    }

    function setP1UserPos(uint32 _userId, uint32 _referrerId) private {
        Storage storage s = getStorage();
        bool userSet = false;
        for (uint i = 0; i < s.p1Referrals[_referrerId].length; i++) {
            for (uint j = 0; j < s.p1Referrals[_referrerId][i].length; j++) {
                // Check if this position in the matrix is set (assuming 0 means not set)
                if (s.p1Referrals[_referrerId][i][j] == 0) {
                    s.p1Referrals[_referrerId][i][j] = _userId;
                    userSet = true;
                    break;
                }
            }
            if (userSet) {
                break;
            }
        }
        if (!userSet) {
            // All existing referral matrices are full, so add a new one
            uint32[3] memory newMatrix = [_userId, 0, 0];
            s.p1Referrals[_referrerId].push(newMatrix);
        }
    }

    function buyP1Level() internal {
        Storage storage s = getStorage();
        require(
            s.users[s.userIds[msg.sender]].mainAddress != address(0),
            "User is not registered"
        );
        require(
            s.users[s.userIds[msg.sender]].programLevels[0] < s.maxProgramLevel,
            "Maximum level has been reached"
        );
        s.users[s.userIds[msg.sender]].programLevels[0] += 1;
        relocateUser(s.userIds[msg.sender]);
    }

    function reinvestP1() internal {
        Storage storage s = getStorage();
        require(
            s.users[s.userIds[msg.sender]].mainAddress != address(0),
            "User is not registered"
        );
        uint32[3][] storage parentMatrix = s.p1Referrals[
            s.users[s.userIds[msg.sender]].p1Parent
        ];
        removeUserFromP1Matrix(parentMatrix, s.userIds[msg.sender]);
        uint32[3] memory newMatrix = [s.userIds[msg.sender], 0, 0];
        parentMatrix.push(newMatrix);
    }

    function relocateUser(uint32 _userId) private {
        Storage storage s = getStorage();
        User storage user = s.users[_userId];
        uint8 p1Level = user.programLevels[0];
        uint32 oldParentId = user.p1Parent;
        if (p1Level > s.users[oldParentId].programLevels[0]) {
            uint32 newParent = findNewP1ParentUp(user.p1Parent, p1Level);
            user.p1Parent = newParent;
            removeUserFromP1Matrix(s.p1Referrals[oldParentId], _userId);
            addUserToP1Matrix(s.p1Referrals[newParent], _userId);
        }
        for (uint i = 0; i < user.directReferrals.length; i++) {
            uint32 directReferralId = user.directReferrals[i];
            User storage directReferral = s.users[directReferralId];
            if (
                directReferral.p1Parent != _userId &&
                directReferral.programLevels[0] < p1Level
            ) {
                // Remove the referral from the current parent's matrix
                removeUserFromP1Matrix(
                    s.p1Referrals[directReferral.p1Parent],
                    directReferralId
                );
                // Add the referral back to the matrix of the direct inviter (_userId)
                addUserToP1Matrix(s.p1Referrals[_userId], directReferralId);
                // Update the direct referral's parent to be _userId
                directReferral.p1Parent = _userId;
            }
        }
    }

    function removeUserFromP1Matrix(
        uint32[3][] storage _matrix,
        uint32 _userId
    ) private {
        uint i = 0;
        while (i < _matrix.length) {
            bool allZero = true;
            for (uint j = 0; j < _matrix[i].length; j++) {
                if (_matrix[i][j] == _userId) {
                    delete _matrix[i][j];
                }
                if (_matrix[i][j] != 0) {
                    allZero = false;
                }
            }
            if (allZero) {
                // shift remaining elements to the left
                for (uint k = i; k < _matrix.length - 1; k++) {
                    _matrix[k] = _matrix[k + 1];
                }
                _matrix.pop();
            } else {
                i++;
            }
        }
    }

    function addUserToP1Matrix(
        uint32[3][] storage _matrix,
        uint32 _userId
    ) private {
        bool userAdded = false;
        for (uint i = 0; i < _matrix.length; i++) {
            for (uint j = 0; j < _matrix[i].length; j++) {
                if (_matrix[i][j] == 0) {
                    _matrix[i][j] = _userId;
                    userAdded = true;
                    break;
                }
            }
            if (userAdded) {
                break;
            }
        }
        if (!userAdded) {
            uint32[3] memory newMatrix = [_userId, 0, 0];
            _matrix.push(newMatrix);
        }
    }

    function findNewP1ParentUp(
        uint32 referrer,
        uint8 programLevel
    ) private view returns (uint32) {
        Storage storage s = getStorage();
        while (s.users[referrer].programLevels[0] < programLevel) {
            referrer = s.users[referrer].p1Parent;
            if (referrer == 1) {
                break;
            }
        }
        return referrer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OptionsLib {
    bytes32 internal constant NAMESPACE = keccak256("magnet.lib.options");

    struct Storage {
        bool initialized;
        uint16 companyFee;
        mapping(uint8 => uint16) leaderBonuses;
        mapping(uint8 => uint8[]) referralPercents;
        mapping(uint8 => uint8[]) partnerPercents;
        mapping(uint8 => uint8[]) structPartnerUpPercents;
        mapping(uint8 => uint8[]) structPartnerDownPercents;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function getCompanyFee() internal view returns (uint16) {
        return getStorage().companyFee;
    }

    function getLeaderBonusPercent(
        uint8 _program
    ) internal view returns (uint16) {
        return getStorage().leaderBonuses[_program];
    }

    function getReferralPercents(
        uint8 _program
    ) internal view returns (uint8[] memory) {
        return getStorage().referralPercents[_program];
    }

    function getPartnerPercents(
        uint8 _program
    ) internal view returns (uint8[] memory) {
        return getStorage().partnerPercents[_program];
    }

    function getStructPartnerUpPercents(
        uint8 _program
    ) internal view returns (uint8[] memory) {
        return getStorage().structPartnerUpPercents[_program];
    }

    function getStructPartnerDownPercents(
        uint8 _program
    ) internal view returns (uint8[] memory) {
        return getStorage().structPartnerDownPercents[_program];
    }

    function initialize(
        uint16 _companyFee,
        uint16[3] memory _leaderBonuses,
        uint8[][3] memory _referralPercents,
        uint8[][3] memory _partnerPercents,
        uint8[][3] memory _structPartnerUpPercents,
        uint8[][3] memory _structPartnerDownPercents
    ) internal {
        // uint[3] memory optionSums;

        // for (uint8 i = 0; i < 3; i++) {
        //     optionSums[i] += _leaderBonuses[i];
        //     for (uint j = 0; j < _referralPercents.length; j++) {
        //         optionSums[i] += _referralPercents[i + 1][j];
        //     }
        //     for (uint j = 0; j < _partnerPercents.length; j++) {
        //         optionSums[i] += _partnerPercents[i + 1][j];
        //     }
        //     for (uint j = 0; j < _structPartnerUpPercents.length; j++) {
        //         optionSums[i] += _structPartnerUpPercents[i + 1][j];
        //     }
        //     for (uint j = 0; j < _structPartnerDownPercents.length; j++) {
        //         optionSums[i] += _structPartnerDownPercents[i + 1][j];
        //     }
        // }

        // require(optionSums[0] == 1000, "Insufficent funds");
        // require(optionSums[1] == 1000, "Options sum in p2 not equal 1000");
        // require(optionSums[2] == 1000, "Options sum in p3 not equal 1000");

        Storage storage s = getStorage();
        require(!s.initialized, "Options already initialized");
        s.initialized = true;
        s.companyFee = _companyFee;
        for (uint8 i = 0; i < 3; i++) {
            s.leaderBonuses[i + 1] = _leaderBonuses[i];
            s.referralPercents[i + 1] = _referralPercents[i];
            s.partnerPercents[i + 1] = _partnerPercents[i];
            s.structPartnerUpPercents[i + 1] = _structPartnerUpPercents[i];
            s.structPartnerDownPercents[i + 1] = _structPartnerDownPercents[i];
        }
    }
}