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

    struct Storage {
        uint leader; // Лидерский бонус - процент * 10
        uint[] partner; // Партнерка массив - процент * 10
        uint[] structPartnerUp; // Структурная партнерка - процент * 10
        uint[] structPartnerDown; // Структурная партнерка - процент * 10
        uint[] referral; // Реферральная программа - процент * 10
        StaticTransaction[] staticTransactions;
        StaticTransaction[] _newStaticTransactions;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    // function setMessage(string calldata _msg) internal {
    //     Storage storage s = getStorage();
    //     s.message = _msg;
    // }

    function getLeaderPercent() internal view returns (uint) {
        return getStorage().leader;
    }

    function getPartnerPercents() internal view returns (uint[] memory) {
        return getStorage().partner;
    }

    function getStructurePartnerUpPercents()
        internal
        view
        returns (uint[] memory)
    {
        return getStorage().structPartnerUp;
    }

    function getStructurePartnerDownPercents()
        internal
        view
        returns (uint[] memory)
    {
        return getStorage().structPartnerDown;
    }

    function getReferralPercents() internal view returns (uint[] memory) {
        return getStorage().referral;
    }

    function getStaticTransactionsLength() internal view returns (uint) {
        return getStorage().staticTransactions.length;
    }

    function getStaticAddress(uint id) internal view returns (address) {
        return getStorage().staticTransactions[id].addr;
    }

    function getStatiPercent(uint id) internal view returns (uint) {
        return getStorage().staticTransactions[id].percent;
    }

    // TODO: only owner
    function setStaticTransactions(
        address[] memory addresses,
        string[] memory names,
        uint[] memory percents
    ) internal {
        require(
            addresses.length > 0 &&
                addresses.length == names.length &&
                names.length == percents.length,
            "Invalid arrays!"
        );

        Storage storage s = getStorage();

        delete s._newStaticTransactions;

        for (uint i = 0; i < addresses.length; i++) {
            StaticTransaction memory _s;
            _s.addr = addresses[i];
            _s.name = names[i];
            _s.percent = percents[i];
            s._newStaticTransactions.push(_s);
        }
    }

    // TODO: only owner
    function setOptions(
        uint8 prgm,
        uint leaderBonus,
        uint[] memory partner,
        uint[] memory referral,
        uint[] memory structUp,
        uint[] memory structDown
    ) internal {
        uint sumPartner;
        uint sumReferral;
        uint sumStructUp;
        uint sumStructDown;
        uint sumStaticTransactions;

        Storage storage s = getStorage();

        for (uint i = 0; i < partner.length; i++) {
            sumPartner += partner[i];
        }
        // TODO: add/remove for specific program
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

        s.leader = leaderBonus;
        s.partner = partner;
        // TODO: add/remove for specific program
        if (prgm != 0) s.referral = referral;
        s.structPartnerUp = structUp;
        s.structPartnerDown = structDown;

        s.staticTransactions = s._newStaticTransactions;
    }
}