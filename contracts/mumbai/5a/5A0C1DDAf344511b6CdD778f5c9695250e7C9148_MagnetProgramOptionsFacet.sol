// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library MagnetProgramOptionsLib {
    bytes32 internal constant NAMESPACE = keccak256("magnet.lib.options");

    // Статические транзакции - аналоги призового фонда и токена, созданы для возможности добавить новые
    struct StaticTransaction {
        address addr;
        string name;
        uint percent;
    }

    struct Options {
        uint leader; // Лидерский бонус - процент * 10
        uint[] partner; // Партнерка массив - процент * 10
        uint[] structPartnerUp; // Структурная партнерка - процент * 10
        uint[] structPartnerDown; // Структурная партнерка - процент * 10
        uint[] referral; // Реферральная программа - процент * 10
    }

    struct Storage {
        Options[3] options;
        StaticTransaction[] staticTransactions;
        StaticTransaction[] _newStaticTransactions;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function getLeaderPercernt(uint8 prgm) external view returns (uint) {
        return getStorage().options[prgm].leader;
    }

    function getPartnerPercernts(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return getStorage().options[prgm].partner;
    }

    function getStructurePartnerUpPercernts(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return getStorage().options[prgm].structPartnerUp;
    }

    function getStructurePartnerDownPercernts(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return getStorage().options[prgm].structPartnerDown;
    }

    function getReferralPercernts(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return getStorage().options[prgm].referral;
    }

    function getStaticTransactionsLength() external view returns (uint) {
        return getStorage().staticTransactions.length;
    }

    function getStaticAddress(uint id) external view returns (address) {
        return getStorage().staticTransactions[id].addr;
    }

    function getStatiPercent(uint id) external view returns (uint) {
        return getStorage().staticTransactions[id].percent;
    }

    // TODO: add only owner
    function setStaticTransactions(
        address[] memory addresses,
        string[] memory names,
        uint[] memory percents
    ) external {
        Storage storage s = getStorage();
        require(
            addresses.length > 0 &&
                addresses.length == names.length &&
                names.length == percents.length,
            "Invalid arrays!"
        );
        delete s._newStaticTransactions;
        for (uint i = 0; i < addresses.length; i++) {
            StaticTransaction memory _s;
            _s.addr = addresses[i];
            _s.name = names[i];
            _s.percent = percents[i];
            s._newStaticTransactions.push(_s);
        }
    }

    // TODO: add only owner
    function setOptions(
        uint8 prgm,
        uint leaderBonus,
        uint[] memory partner,
        uint[] memory referral,
        uint[] memory structUp,
        uint[] memory structDown
    ) external {
        uint sumPartner;
        uint sumReferral;
        uint sumStructUp;
        uint sumStructDown;
        uint sumStaticTransactions;
        Storage storage s = getStorage();
        for (uint i = 0; i < partner.length; i++) {
            sumPartner += partner[i];
        }
        if (prgm != 0) {
            for (uint i = 0; i < referral.length; i++) {
                sumReferral += referral[i];
            }
        }
        for (uint i = 0; i < structUp.length; i++) {
            sumStructUp += structUp[i];
        }
        for (uint i = 0; i < structDown.length; i++) {
            sumStructDown += structDown[i];
        }
        for (uint i = 0; i < s._newStaticTransactions.length; i++) {
            sumStaticTransactions += s._newStaticTransactions[i].percent;
        }
        // TODO: add require for each parameter
        require(
            sumPartner + sumReferral + sumStructUp + sumStructDown == 1000,
            "It's not 100 percent!"
        );
        s.options[prgm].leader = leaderBonus;
        s.options[prgm].partner = partner;
        if (prgm != 0) s.options[prgm].referral = referral;
        s.options[prgm].structPartnerUp = structUp;
        s.options[prgm].structPartnerDown = structDown;
        s.staticTransactions = s._newStaticTransactions;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./libs/MagnetProgramOptionsLib.sol";

contract MagnetProgramOptionsFacet {
    function getPartnerPercernts(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return MagnetProgramOptionsLib.getPartnerPercernts(prgm);
    }
}