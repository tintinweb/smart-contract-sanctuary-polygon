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
        // Options[3] options;
        mapping(uint8 => Options) options;
        // TODO: move to mappings
        StaticTransaction[] staticTransactions;
        StaticTransaction[] _newStaticTransactions;
        bool initialized;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function getLeaderPercent(uint8 prgm) external view returns (uint) {
        return getStorage().options[prgm].leader;
    }

    function getPartnerPercents(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return getStorage().options[prgm].partner;
    }

    function getStructurePartnerUpPercents(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return getStorage().options[prgm].structPartnerUp;
    }

    function getStructurePartnerDownPercents(
        uint8 prgm
    ) external view returns (uint[] memory) {
        return getStorage().options[prgm].structPartnerDown;
    }

    function getReferralPercents(
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

    function getStaticPercent(uint id) external view returns (uint) {
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
    ) public {
        uint sumPartner;
        uint sumReferral;
        uint sumStructUp;
        uint sumStructDown;
        uint sumStaticTransactions;
        Storage storage s = getStorage();
        require(prgm >= 0 && prgm <= 2, "Program does not exist");

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

    function initialize(
        address _tokenWallet,
        address _presentsWallet
    ) internal {
        Storage storage s = getStorage();
        require(!s.initialized, "already initialized");

        StaticTransaction memory tkn;
        tkn.addr = _tokenWallet;
        tkn.name = "tokenWallet";
        tkn.percent = 50;

        StaticTransaction memory prsnt;
        prsnt.addr = _presentsWallet;
        prsnt.name = "presentsWallet";
        prsnt.percent = 50;

        s.staticTransactions.push(tkn);
        s.staticTransactions.push(prsnt);

        s.options[0].leader = 750;
        s.options[0].partner = [50, 50, 50];

        s.options[1].leader = 400;
        s.options[1].partner = [50, 50, 50];
        s.options[1].referral = [35, 35, 35, 35, 35, 35, 35, 35, 35, 35];

        s.options[2].leader = 100;
        s.options[2].partner = [50, 50, 50];
        s.options[2].referral = [25, 25, 25, 25, 25, 25, 25, 25, 25, 25];
        s.options[2].structPartnerUp = [
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10
        ];
        s.options[2].structPartnerDown = [
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10
        ];
        s.initialized = true;
    }
}