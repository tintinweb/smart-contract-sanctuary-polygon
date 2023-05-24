// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./libs/CoreLib.sol";

contract CoreFacet {
    function getLevelPrice(uint8 _levelNumber) public view returns (uint) {
        return CoreLib.getLevelPrices(_levelNumber);
    }

    function register(uint32 _refferer) external payable {
        require(msg.value >= getLevelPrice(1) * 3, "Insufficient funds");
        CoreLib.register(_refferer);
    }

    function getUser(
        uint32 _userId
    ) external view returns (CoreLib.User memory) {
        return CoreLib.getUser(_userId);
    }

    function getUserByAddress(
        address _address
    ) external view returns (CoreLib.User memory) {
        return CoreLib.getUserByAddress(_address);
    }

    function getUserId(address _address) external view returns (uint32) {
        return CoreLib.getUserId(_address);
    }

    function buyP1Level() external {
        return CoreLib.buyP1Level();
    }

    // function getUsers() external view returns (CoreLib.User[]) {
    //     CoreLib.User[] memory users;
    //     for (uint i = 0; i < array.length; i++) {}
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./OptionsLib.sol";

library CoreLib {
    bytes32 internal constant NAMESPACE = keccak256("magnet.lib.core");

    // struct FirstProgramStruct {
    //     uint32[][3] matrix;
    // }

    struct User {
        uint8[3] programLevels;
        address mainAddress;
        uint32 referrer;
        uint32[] referrals;
        uint[16] balances;
    }

    struct Storage {
        uint8 maxProgramLevel;
        bool initialized;
        uint32 usersCounter;
        mapping(uint32 => User) users;
        mapping(uint8 => uint) levelPrices;
        mapping(address => uint32) userIds;
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

    function getLevelPrices(uint8 _levelNumber) internal view returns (uint) {
        return getStorage().levelPrices[_levelNumber];
    }

    function register(uint32 _referrer) internal {
        Storage storage s = getStorage();
        require(
            s.users[s.userIds[msg.sender]].mainAddress == address(0),
            "User already registered"
        );
        require(
            s.users[_referrer].mainAddress != address(0),
            "Referrer not registered"
        );
        s.usersCounter++;
        s.userIds[msg.sender] = s.usersCounter;
        s.users[s.userIds[msg.sender]].programLevels = [1, 1, 1];
        s.users[s.userIds[msg.sender]].referrer = _referrer;
        s.users[s.userIds[msg.sender]].mainAddress = msg.sender;
        s.users[_referrer].referrals.push(s.usersCounter);
        distributeLeader(1, s.usersCounter, msg.value / 3);
        distributeLeader(2, s.usersCounter, msg.value / 3);
        distributeLeader(3, s.usersCounter, msg.value / 3);

        distributePartner(1, s.usersCounter, msg.value / 3);
        distributePartner(2, s.usersCounter, msg.value / 3);
        distributePartner(3, s.usersCounter, msg.value / 3);

        distributeRefferal(2, s.usersCounter, msg.value / 3);
        distributeRefferal(3, s.usersCounter, msg.value / 3);

        distributeStruct(3, s.usersCounter, msg.value / 3);
    }

    function initialize() internal {
        Storage storage s = getStorage();
        require(!s.initialized, "Core already initialized");
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
        uint32[] memory referrals;
        s.users[s.usersCounter] = User(
            [15, 15, 15],
            msg.sender,
            1,
            referrals,
            balances
        );
    }

    function distributeLeader(
        uint8 _program,
        uint32 _userId,
        uint _value
    ) internal {
        Storage storage s = getStorage();
        payable(s.users[s.users[_userId].referrer].mainAddress).transfer(
            (_value * OptionsLib.getLeaderBonusPercent(_program)) / 1000
        );
    }

    function distributePartner(
        uint8 _program,
        uint32 _userId,
        uint _value
    ) internal {
        Storage storage s = getStorage();
        uint8[] memory partnerPercents = OptionsLib.getPartnerPercents(
            _program
        );
        for (uint8 i = 0; i < partnerPercents.length; i++) {
            s.users[s.users[_userId].referrer].balances[1] +=
                (_value * partnerPercents[i]) /
                1000;
        }
    }

    function distributeRefferal(
        uint8 _program,
        uint32 _userId,
        uint _value
    ) internal {
        Storage storage s = getStorage();
        uint8[] memory refferalPercents = OptionsLib.getReferralPercents(
            _program
        );
        for (uint8 i = 0; i < refferalPercents.length; i++) {
            if (_userId < i + 1) {
                s.users[1].balances[1] += (_value * refferalPercents[i]) / 1000;
                continue;
            }
            s.users[_userId - i + 1].balances[1] +=
                (_value * refferalPercents[i]) /
                1000;
        }
    }

    function distributeStruct(
        uint8 _program,
        uint32 _userId,
        uint _value
    ) internal {
        Storage storage s = getStorage();
        uint8[] memory upPercents = OptionsLib.getStructPartnerUpPercents(
            _program
        );
        uint8[] memory downPercents = OptionsLib.getStructPartnerDownPercents(
            _program
        );
        for (uint8 i = 0; i < upPercents.length; i++) {
            s.users[_userId + 1 + i].balances[1] +=
                (_value * upPercents[i]) /
                1000;
        }
        for (uint8 i = 0; i < downPercents.length; i++) {
            if (_userId < i + 1) {
                s.users[1].balances[1] += (_value * upPercents[i]) / 1000;
                continue;
            }
            s.users[_userId - 1 - i].balances[1] +=
                (_value * downPercents[i]) /
                1000;
        }
    }

    function buyP1Level() internal {
        Storage storage s = getStorage();
        require(
            s.users[s.userIds[msg.sender]].mainAddress != address(0),
            "User not registered"
        );
        require(
            s.users[s.userIds[msg.sender]].programLevels[0] < s.maxProgramLevel,
            "Max level"
        );

        User memory referrer = s.users[s.users[s.userIds[msg.sender]].referrer];

        for (
            uint32 i = 0;
            i < s.users[s.userIds[msg.sender]].referrals.length;
            i++
        ) {
            if (
                s
                    .users[s.users[s.userIds[msg.sender]].referrals[i]]
                    .programLevels[0] <
                s.users[s.userIds[msg.sender]].programLevels[0] + 1
            ) {
                s
                    .users[s.users[s.userIds[msg.sender]].referrals[i]]
                    .referrer = s.userIds[msg.sender];
            }
        }
        s.users[s.userIds[msg.sender]].programLevels[0] += 1;
    }

    function findP1referrer(
        uint32 referrer,
        uint8 programLevel
    ) private view returns (uint32) {
        Storage storage s = getStorage();
        while (s.users[referrer].programLevels[0] <= programLevel) {
            referrer = s.users[referrer].referrer;
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
        mapping(uint16 => uint16) leaderBonuses;
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