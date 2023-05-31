/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// File: contracts/EthermonEnum.sol

pragma solidity 0.6.6;

contract EthermonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum BattleResult {
        CASTLE_WIN,
        CASTLE_LOSE,
        CASTLE_DESTROYED
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

// File: contracts/EthermonAdventureSetting.sol

/**
 *Submitted for verification at Etherscan.io on 2020-03-29
 */

/**
 *Submitted for verification at Etherscan.io on 2018-09-03
 */

pragma solidity ^0.6.6;

contract BasicAccessControl {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address payable _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) public onlyOwner {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

interface IEthermonDataContract {
    function getElementInArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index
    ) external view returns (uint8);
}

contract EtheremonAdventureSetting is EthermonEnum, BasicAccessControl {
    struct RewardData {
        uint256 monster_rate;
        uint256 monster_id;
        uint256 shard_rate; //gem stones
        uint256 shard_id;
        uint256 level_rate;
        uint256 exp_perecent_rate;
        uint256 evo_rate;
    }
    address public ethermonData;
    mapping(uint256 => uint256[]) public siteSet; // monster class -> site id
    mapping(uint256 => uint256) public monsterClassSiteSet;
    mapping(uint256 => RewardData) public siteRewards; // site id => rewards (monster_rate, monster_id, shard_rate, shard_id, level_rate, exp_rate, emon_rate)
    uint256 public levelItemClass = 200;
    uint256 public expItemClass = 201;
    uint256 public evoItemClass = 202;
    uint256 public advSiteItemClass = 203;
    uint256[4] public levelRewards = [1, 1, 1, 2];
    //Can be changed to % means 5% in 1st index 10% in 2nd etc
    uint256[11] public expRewards = [
        500,
        500,
        500,
        500,
        500,
        500,
        1000,
        1000,
        1000,
        5000,
        20000
    ]; // Increase ExpBot Old: [50, 50, 50, 50, 100, 100, 100, 100, 200, 200, 500]
    uint256[11] public expPerecentRewards = [
        10,
        10,
        10,
        10,
        10,
        25,
        25,
        25,
        50,
        50,
        75
    ];

    function setConfig(
        uint256 _levelItemClass,
        uint256 _expItemClass,
        uint256 _evoItemClass,
        uint256 _advSiteItemClass
    ) public onlyModerators {
        levelItemClass = _levelItemClass;
        expItemClass = _expItemClass;
        evoItemClass = _evoItemClass;
        advSiteItemClass = _advSiteItemClass;
    }

    function addSiteSet(uint256 _setId, uint256 _siteId) public onlyModerators {
        uint256[] storage siteList = siteSet[_setId];
        for (uint256 index = 0; index < siteList.length; index++) {
            if (siteList[index] == _siteId) {
                return;
            }
        }
        siteList.push(_siteId);
    }

    function removeSiteSet(
        uint256 _setId,
        uint256 _siteId
    ) public onlyModerators {
        uint256[] storage siteList = siteSet[_setId];
        uint256 foundIndex = 0;
        for (; foundIndex < siteList.length; foundIndex++) {
            if (siteList[foundIndex] == _siteId) {
                break;
            }
        }
        if (foundIndex < siteList.length) {
            siteList[foundIndex] = siteList[siteList.length - 1];
            siteList.pop();
            //delete siteList[siteList.length-1];
            //siteList.length--;
        }
    }

    function setMonsterClassSiteSet(
        uint256 _monsterId,
        uint256 _siteSetId
    ) public onlyModerators {
        monsterClassSiteSet[_monsterId] = _siteSetId;
    }

    function setSiteRewards(
        uint256 _siteId,
        uint256 _monster_rate,
        uint256 _monster_id,
        uint256 _shard_rate,
        uint256 _shard_id,
        uint256 _level_rate,
        uint256 _exp_perecent_rate
    ) public onlyModerators {
        RewardData storage reward = siteRewards[_siteId];
        reward.monster_rate = _monster_rate;
        reward.monster_id = _monster_id;
        reward.shard_rate = _shard_rate;
        reward.shard_id = _shard_id;
        reward.level_rate = _level_rate;
        reward.exp_perecent_rate = _exp_perecent_rate;
    }

    function setLevelRewards(
        uint256 _index,
        uint256 _value
    ) public onlyModerators {
        levelRewards[_index] = _value;
    }

    function setExpPerecentRewards(
        uint256 _index,
        uint256 _value
    ) public onlyModerators {
        expPerecentRewards[_index] = _value;
    }

    function initSiteSet(uint256 _turn) public onlyModerators {
        if (_turn == 1) {
            siteSet[1] = [
                2,
                4,
                5,
                9,
                12,
                13,
                17,
                21,
                24,
                25,
                28,
                32,
                35,
                38,
                42,
                48,
                49,
                53
            ]; //Insect
            siteSet[2] = [
                1,
                3,
                6,
                8,
                10,
                15,
                17,
                20,
                24,
                25,
                29,
                33,
                34,
                37,
                41,
                45,
                46,
                50
            ]; //Dragon
            siteSet[3] = [
                2,
                4,
                7,
                9,
                11,
                15,
                16,
                21,
                23,
                25,
                30,
                32,
                34,
                38,
                42,
                43,
                48,
                49,
                53
            ]; //Mystic
            siteSet[4] = [
                3,
                4,
                8,
                11,
                13,
                15,
                18,
                19,
                23,
                27,
                30,
                31,
                35,
                39,
                41,
                43,
                48,
                49,
                53
            ]; //Fire
            siteSet[5] = [
                3,
                5,
                7,
                8,
                11,
                12,
                14,
                16,
                21,
                22,
                26,
                30,
                31,
                35,
                37,
                38,
                40,
                45,
                51,
                52
            ]; //Phantom
            siteSet[6] = [
                1,
                5,
                9,
                10,
                14,
                16,
                18,
                19,
                23,
                27,
                29,
                33,
                34,
                37,
                41,
                45,
                47,
                51,
                52
            ]; //Earth
            siteSet[7] = [
                1,
                6,
                8,
                10,
                12,
                13,
                17,
                20,
                22,
                24,
                25,
                29,
                33,
                34,
                39,
                40,
                44,
                46,
                50,
                54
            ]; //Neutral
            siteSet[8] = [
                2,
                6,
                7,
                10,
                15,
                17,
                20,
                21,
                24,
                25,
                29,
                32,
                34,
                39,
                40,
                44,
                48,
                50,
                52
            ]; //Telepath
            siteSet[9] = [
                1,
                5,
                9,
                10,
                14,
                18,
                20,
                22,
                27,
                28,
                32,
                36,
                39,
                41,
                43,
                46,
                51,
                53,
                54
            ]; //Iron

            //TODO: Remeber to remove 10 with 18 as on backend we have no 10 instead we have 18 as fighter
            // siteSet[10] = []; //fighter
        } else {
            siteSet[11] = [
                3,
                5,
                7,
                12,
                13,
                17,
                19,
                24,
                26,
                28,
                29,
                31,
                36,
                37,
                42,
                43,
                44,
                47,
                51,
                52
            ]; //Lightning
            siteSet[12] = [
                1,
                5,
                9,
                11,
                15,
                16,
                19,
                23,
                27,
                28,
                32,
                36,
                37,
                38,
                41,
                45,
                48,
                49
            ]; //Combat
            siteSet[13] = [
                1,
                6,
                8,
                12,
                13,
                17,
                19,
                23,
                26,
                28,
                32,
                33,
                36,
                38,
                40,
                44,
                48,
                49,
                53,
                54
            ]; //Flyer
            siteSet[14] = [
                3,
                4,
                8,
                11,
                15,
                16,
                19,
                23,
                27,
                30,
                31,
                35,
                36,
                37,
                41,
                45,
                47,
                51,
                52
            ]; //Leaf
            siteSet[15] = [
                2,
                6,
                7,
                11,
                13,
                18,
                20,
                22,
                26,
                27,
                30,
                33,
                34,
                39,
                39,
                40,
                42,
                43,
                47,
                50,
                52
            ]; //Ice
            siteSet[16] = [
                3,
                4,
                10,
                14,
                18,
                21,
                22,
                26,
                28,
                33,
                35,
                38,
                42,
                43,
                45,
                46,
                47,
                50,
                54
            ]; //Toxin
            siteSet[17] = [
                2,
                6,
                7,
                14,
                18,
                21,
                22,
                26,
                30,
                31,
                35,
                42,
                44,
                46,
                50,
                51,
                53
            ]; //Rock
            siteSet[18] = [
                2,
                4,
                9,
                12,
                14,
                16,
                20,
                24,
                25,
                29,
                31,
                36,
                40,
                44,
                46,
                47,
                49,
                54,
                54
            ]; //Water
        }
    }

    function initMonsterClassSiteSet() public onlyModerators {
        monsterClassSiteSet[1001] = 1;
        monsterClassSiteSet[1002] = 2;
        monsterClassSiteSet[1003] = 3;
        monsterClassSiteSet[1004] = 4;
        monsterClassSiteSet[1005] = 5;
        monsterClassSiteSet[1006] = 6;
        monsterClassSiteSet[1007] = 7;
        monsterClassSiteSet[1008] = 8;
        monsterClassSiteSet[1009] = 8;
        monsterClassSiteSet[1010] = 2;
        monsterClassSiteSet[1011] = 9;
        monsterClassSiteSet[1012] = 18;
        monsterClassSiteSet[1013] = 11;
        monsterClassSiteSet[1014] = 12;
        monsterClassSiteSet[1015] = 3;
        monsterClassSiteSet[1016] = 13;
        monsterClassSiteSet[1017] = 3;
        monsterClassSiteSet[1018] = 8;
        monsterClassSiteSet[1019] = 8;
        monsterClassSiteSet[1020] = 14;
        monsterClassSiteSet[1021] = 13;
        monsterClassSiteSet[1022] = 4;
        monsterClassSiteSet[1023] = 9;
        monsterClassSiteSet[1024] = 1;
        monsterClassSiteSet[1025] = 1;
        monsterClassSiteSet[1026] = 3;
        monsterClassSiteSet[1027] = 2;
        monsterClassSiteSet[1028] = 6;
        monsterClassSiteSet[1029] = 4;
        monsterClassSiteSet[1030] = 14;
        monsterClassSiteSet[1031] = 18;
        monsterClassSiteSet[1032] = 1;
        monsterClassSiteSet[1033] = 15;
        monsterClassSiteSet[1034] = 3;
        monsterClassSiteSet[1035] = 3;
        monsterClassSiteSet[1036] = 2;
        monsterClassSiteSet[1037] = 8;
        monsterClassSiteSet[1038] = 1;
        monsterClassSiteSet[1039] = 2;
        monsterClassSiteSet[1040] = 3;
        monsterClassSiteSet[1041] = 4;
        monsterClassSiteSet[1042] = 5;
        monsterClassSiteSet[1043] = 6;
        monsterClassSiteSet[1044] = 7;
        monsterClassSiteSet[1045] = 8;
        monsterClassSiteSet[1046] = 8;
        monsterClassSiteSet[1047] = 2;
        monsterClassSiteSet[1048] = 9;
        monsterClassSiteSet[1049] = 18;
        monsterClassSiteSet[1050] = 8;
        monsterClassSiteSet[1051] = 14;
        monsterClassSiteSet[1052] = 1;
        monsterClassSiteSet[1053] = 3;
        monsterClassSiteSet[1054] = 2;
        monsterClassSiteSet[1055] = 6;
        monsterClassSiteSet[1056] = 4;
        monsterClassSiteSet[1057] = 14;
        monsterClassSiteSet[1058] = 18;
        monsterClassSiteSet[1059] = 1;
        monsterClassSiteSet[1060] = 15;
        monsterClassSiteSet[1061] = 3;
        monsterClassSiteSet[1062] = 8;
        monsterClassSiteSet[1063] = 8;
        monsterClassSiteSet[1064] = 1;
        monsterClassSiteSet[1065] = 2;
        monsterClassSiteSet[1066] = 4;
        monsterClassSiteSet[1067] = 5;
        monsterClassSiteSet[1068] = 14;
        monsterClassSiteSet[1069] = 1;
        monsterClassSiteSet[1070] = 3;
        monsterClassSiteSet[1071] = 3;
        monsterClassSiteSet[1072] = 16;
        monsterClassSiteSet[1073] = 17;
        monsterClassSiteSet[1074] = 5;
        monsterClassSiteSet[1075] = 7;
        monsterClassSiteSet[1076] = 1;
        monsterClassSiteSet[1077] = 17;
        monsterClassSiteSet[1078] = 18;
        monsterClassSiteSet[1079] = 1;
        monsterClassSiteSet[1080] = 13;
        monsterClassSiteSet[1081] = 4;
        monsterClassSiteSet[1082] = 17;
        monsterClassSiteSet[1083] = 18;
        monsterClassSiteSet[1084] = 1;
        monsterClassSiteSet[1085] = 13;
        monsterClassSiteSet[1086] = 4;
        monsterClassSiteSet[1087] = 1;
        monsterClassSiteSet[1088] = 4;
        monsterClassSiteSet[1089] = 1;
        monsterClassSiteSet[1090] = 2;
        monsterClassSiteSet[1091] = 2;
        monsterClassSiteSet[1092] = 2;
        monsterClassSiteSet[1093] = 15;
        monsterClassSiteSet[1094] = 15;
        monsterClassSiteSet[1095] = 15;
        monsterClassSiteSet[1096] = 12;
        monsterClassSiteSet[1097] = 12;
        monsterClassSiteSet[1098] = 12;
        monsterClassSiteSet[1099] = 5;
        monsterClassSiteSet[1100] = 5;
        monsterClassSiteSet[1101] = 8;
        monsterClassSiteSet[1102] = 8;
        monsterClassSiteSet[1103] = 2;
        monsterClassSiteSet[1104] = 2;
        monsterClassSiteSet[1105] = 15;
        monsterClassSiteSet[1106] = 1;
        monsterClassSiteSet[1107] = 1;
        monsterClassSiteSet[1108] = 1;
        monsterClassSiteSet[1109] = 9;
        monsterClassSiteSet[1110] = 18;
        monsterClassSiteSet[1111] = 13;
        monsterClassSiteSet[1112] = 11;
        monsterClassSiteSet[1113] = 14;
        monsterClassSiteSet[1114] = 6;
        monsterClassSiteSet[1115] = 8;
        monsterClassSiteSet[1116] = 3;
        monsterClassSiteSet[1117] = 3;
        monsterClassSiteSet[1118] = 3;
        monsterClassSiteSet[1119] = 13;
        monsterClassSiteSet[1120] = 13;
        monsterClassSiteSet[1121] = 13;
        monsterClassSiteSet[1122] = 5;
        monsterClassSiteSet[1123] = 5;
        monsterClassSiteSet[1124] = 5;
        monsterClassSiteSet[1125] = 15;
        monsterClassSiteSet[1126] = 15;
        monsterClassSiteSet[1127] = 15;
        monsterClassSiteSet[1128] = 1;
        monsterClassSiteSet[1129] = 1;
        monsterClassSiteSet[1130] = 1;
        monsterClassSiteSet[1131] = 14;
        monsterClassSiteSet[1132] = 14;
        monsterClassSiteSet[1133] = 14;
        monsterClassSiteSet[1134] = 16;
        monsterClassSiteSet[1135] = 16;
        monsterClassSiteSet[1136] = 13;
        monsterClassSiteSet[1137] = 13;
        monsterClassSiteSet[1138] = 4;
        monsterClassSiteSet[1139] = 4;
        monsterClassSiteSet[1140] = 7;
        monsterClassSiteSet[1141] = 7;
        monsterClassSiteSet[1142] = 4;
        monsterClassSiteSet[1143] = 4;
        monsterClassSiteSet[1144] = 13;
        monsterClassSiteSet[1145] = 13;
        monsterClassSiteSet[1146] = 9;
        monsterClassSiteSet[1147] = 9;
        monsterClassSiteSet[1148] = 14;
        monsterClassSiteSet[1149] = 14;
        monsterClassSiteSet[1150] = 14;
        monsterClassSiteSet[1151] = 1;
        monsterClassSiteSet[1152] = 1;
        monsterClassSiteSet[1153] = 12;
        monsterClassSiteSet[1154] = 9;
        monsterClassSiteSet[1155] = 14;
        monsterClassSiteSet[1156] = 16;
        monsterClassSiteSet[1157] = 16;
        monsterClassSiteSet[1158] = 8;
        monsterClassSiteSet[1159] = 7;
        monsterClassSiteSet[1160] = 7;
        monsterClassSiteSet[1161] = 12;
        monsterClassSiteSet[1162] = 12;
        monsterClassSiteSet[1163] = 3;
        monsterClassSiteSet[1164] = 3;
        monsterClassSiteSet[1165] = 16;
        monsterClassSiteSet[1166] = 13;
        monsterClassSiteSet[1167] = 13;
        monsterClassSiteSet[1168] = 15;
        monsterClassSiteSet[1169] = 15;
        monsterClassSiteSet[1170] = 17;
        monsterClassSiteSet[1171] = 17;
        monsterClassSiteSet[1172] = 17;
        monsterClassSiteSet[1173] = 2;
        monsterClassSiteSet[1174] = 2;
        monsterClassSiteSet[1175] = 2;
        monsterClassSiteSet[1176] = 3;
        monsterClassSiteSet[1177] = 3;
        monsterClassSiteSet[1178] = 3;
        monsterClassSiteSet[1179] = 2;

        /////////////////////////////////////////
        ///////////////// New Mons //////////////
        /////////////////////////////////////////
        monsterClassSiteSet[1300] = 1;
        monsterClassSiteSet[1301] = 2;
        monsterClassSiteSet[1303] = 3;
        monsterClassSiteSet[1304] = 4;
        monsterClassSiteSet[1305] = 5;
        monsterClassSiteSet[1306] = 6;
        monsterClassSiteSet[1307] = 7;
        monsterClassSiteSet[1308] = 8;
        monsterClassSiteSet[1309] = 8;
        monsterClassSiteSet[1310] = 2;
        monsterClassSiteSet[1311] = 9;
        monsterClassSiteSet[1312] = 18;
        monsterClassSiteSet[1313] = 11;
        monsterClassSiteSet[1314] = 12;
        monsterClassSiteSet[1315] = 3;
        monsterClassSiteSet[1316] = 13;
        monsterClassSiteSet[1317] = 3;
        monsterClassSiteSet[1318] = 8;
        monsterClassSiteSet[1319] = 8;
        monsterClassSiteSet[1320] = 14;
        monsterClassSiteSet[1321] = 13;
        monsterClassSiteSet[1322] = 4;
        monsterClassSiteSet[1323] = 9;
        monsterClassSiteSet[1324] = 1;
        monsterClassSiteSet[1325] = 1;
        monsterClassSiteSet[1326] = 3;
        monsterClassSiteSet[1327] = 2;
        monsterClassSiteSet[1328] = 6;
        monsterClassSiteSet[1329] = 4;
        monsterClassSiteSet[1330] = 14;
        monsterClassSiteSet[1331] = 18;
        monsterClassSiteSet[1332] = 1;
        monsterClassSiteSet[1333] = 15;
        monsterClassSiteSet[1334] = 3;
        monsterClassSiteSet[1335] = 3;
        monsterClassSiteSet[1336] = 2;
        monsterClassSiteSet[1337] = 8;
        monsterClassSiteSet[1338] = 1;
        monsterClassSiteSet[1339] = 2;
        monsterClassSiteSet[1340] = 3;
        monsterClassSiteSet[1341] = 4;
        monsterClassSiteSet[1342] = 5;
        monsterClassSiteSet[1343] = 6;
        monsterClassSiteSet[1344] = 7;
        monsterClassSiteSet[1345] = 8;
        monsterClassSiteSet[1346] = 8;
        monsterClassSiteSet[1347] = 2;
        monsterClassSiteSet[1348] = 9;
        monsterClassSiteSet[1349] = 18;
        monsterClassSiteSet[1350] = 8;
        monsterClassSiteSet[1351] = 14;
        monsterClassSiteSet[1352] = 1;
        monsterClassSiteSet[1353] = 3;
        monsterClassSiteSet[1354] = 2;
        monsterClassSiteSet[1355] = 6;
        monsterClassSiteSet[1356] = 4;
        monsterClassSiteSet[1357] = 14;
        monsterClassSiteSet[1358] = 18;
        monsterClassSiteSet[1359] = 1;
        monsterClassSiteSet[1360] = 15;
        monsterClassSiteSet[1361] = 3;
        monsterClassSiteSet[1362] = 8;
        monsterClassSiteSet[1363] = 8;
        monsterClassSiteSet[1364] = 1;
        monsterClassSiteSet[1365] = 2;
        monsterClassSiteSet[1366] = 4;
        monsterClassSiteSet[1367] = 5;
        monsterClassSiteSet[1368] = 14;
        monsterClassSiteSet[1369] = 1;
        monsterClassSiteSet[1370] = 3;
        monsterClassSiteSet[1371] = 3;
        monsterClassSiteSet[1372] = 16;
        monsterClassSiteSet[1373] = 17;
        monsterClassSiteSet[1374] = 5;
        monsterClassSiteSet[1375] = 7;
        monsterClassSiteSet[1376] = 1;
        monsterClassSiteSet[1377] = 17;
        monsterClassSiteSet[1378] = 18;
        monsterClassSiteSet[1379] = 1;
        monsterClassSiteSet[1380] = 13;
        monsterClassSiteSet[1381] = 4;
        monsterClassSiteSet[1382] = 17;
        monsterClassSiteSet[1383] = 18;
        monsterClassSiteSet[1384] = 1;
        monsterClassSiteSet[1385] = 13;
        monsterClassSiteSet[1386] = 4;
        monsterClassSiteSet[1387] = 1;
        monsterClassSiteSet[1388] = 4;
        monsterClassSiteSet[1389] = 1;
        monsterClassSiteSet[1390] = 2;
        monsterClassSiteSet[1391] = 2;
        monsterClassSiteSet[1392] = 2;
        monsterClassSiteSet[1393] = 15;
        monsterClassSiteSet[1394] = 15;
        monsterClassSiteSet[1395] = 15;
        monsterClassSiteSet[1396] = 12;
        monsterClassSiteSet[1397] = 12;
        monsterClassSiteSet[1398] = 12;
        monsterClassSiteSet[1399] = 5;
    }

    //TODO: Have to update rewards given from Eric.
    function initSiteRewards(uint256 _turn) public onlyModerators {
        if (_turn == 1) {
            // struct RewardData {
            //     uint256 monster_rate;
            //     uint256 monster_id;
            //     uint256 shard_rate;
            //     uint256 shard_id;
            //     uint256 level_rate;
            //     uint256 exp_perecent_rate;
            //     uint256 evo_rate;
            // }
            siteRewards[1] = RewardData(25, 1387, 150, 350, 323, 500, 2);
            siteRewards[2] = RewardData(30, 1369, 150, 350, 318, 500, 2);
            siteRewards[3] = RewardData(30, 1380, 150, 350, 318, 500, 2);
            siteRewards[4] = RewardData(25, 1387, 150, 351, 323, 500, 2);
            siteRewards[5] = RewardData(30, 1369, 150, 351, 318, 500, 2);
            siteRewards[6] = RewardData(15, 1384, 150, 351, 323, 500, 2);
            siteRewards[7] = RewardData(25, 1387, 150, 352, 323, 500, 2);
            siteRewards[8] = RewardData(30, 1369, 150, 352, 318, 500, 2);
            siteRewards[9] = RewardData(15, 1384, 150, 352, 333, 500, 2);
            siteRewards[10] = RewardData(4, 1397, 150, 320, 344, 500, 2);
            siteRewards[11] = RewardData(15, 1392, 150, 320, 333, 500, 2);
            siteRewards[12] = RewardData(30, 1380, 150, 320, 318, 500, 2);
            siteRewards[13] = RewardData(15, 1392, 150, 321, 333, 500, 2);
            siteRewards[14] = RewardData(15, 1392, 150, 321, 333, 500, 2);
            siteRewards[15] = RewardData(30, 1380, 150, 321, 318, 500, 2);
            siteRewards[16] = RewardData(30, 1328, 150, 322, 318, 500, 2);
            siteRewards[17] = RewardData(30, 1332, 150, 322, 318, 500, 2);
            siteRewards[18] = RewardData(30, 1326, 150, 322, 318, 500, 2);
            siteRewards[19] = RewardData(30, 1328, 150, 340, 318, 500, 2);
            siteRewards[20] = RewardData(30, 1332, 150, 340, 318, 500, 2);
            siteRewards[21] = RewardData(30, 1326, 150, 340, 318, 500, 2);
            siteRewards[22] = RewardData(30, 1328, 150, 341, 318, 500, 2);
            siteRewards[23] = RewardData(30, 1332, 150, 341, 318, 500, 2);
            siteRewards[24] = RewardData(30, 1326, 150, 341, 318, 500, 2);
            siteRewards[25] = RewardData(30, 1328, 150, 342, 318, 500, 2);
            siteRewards[26] = RewardData(30, 1332, 150, 342, 323, 500, 2);
            siteRewards[27] = RewardData(30, 1323, 150, 342, 318, 500, 2);
        } else {
            siteRewards[28] = RewardData(30, 1314, 150, 300, 318, 500, 2);
            siteRewards[29] = RewardData(25, 1355, 150, 300, 323, 500, 2);
            siteRewards[30] = RewardData(25, 1377, 150, 300, 318, 500, 2);
            siteRewards[31] = RewardData(30, 1314, 150, 301, 318, 500, 2);
            siteRewards[32] = RewardData(25, 1377, 150, 301, 323, 500, 2);
            siteRewards[33] = RewardData(25, 1380, 150, 301, 323, 500, 2);
            siteRewards[34] = RewardData(30, 1314, 150, 302, 318, 500, 2);
            siteRewards[35] = RewardData(25, 1355, 150, 302, 318, 500, 2);
            siteRewards[36] = RewardData(25, 1377, 150, 302, 323, 500, 2);
            siteRewards[37] = RewardData(4, 1397, 150, 310, 344, 500, 2);
            siteRewards[38] = RewardData(30, 1326, 150, 310, 318, 500, 2);
            siteRewards[39] = RewardData(15, 1392, 150, 310, 333, 500, 2);
            siteRewards[40] = RewardData(25, 1325, 150, 311, 323, 500, 2);
            siteRewards[41] = RewardData(30, 1330, 150, 311, 318, 500, 2);
            siteRewards[42] = RewardData(15, 1375, 150, 311, 333, 500, 2);
            siteRewards[43] = RewardData(25, 1325, 150, 312, 323, 500, 2);
            siteRewards[44] = RewardData(30, 1330, 150, 312, 318, 500, 2);
            siteRewards[45] = RewardData(30, 1323, 150, 312, 318, 500, 2);
            siteRewards[46] = RewardData(30, 1323, 150, 330, 318, 500, 2);
            siteRewards[47] = RewardData(25, 1325, 150, 330, 323, 500, 2);
            siteRewards[48] = RewardData(30, 1330, 150, 330, 318, 500, 2);
            siteRewards[49] = RewardData(30, 1323, 150, 331, 318, 500, 2);
            siteRewards[50] = RewardData(30, 1380, 150, 331, 318, 500, 2);
            siteRewards[51] = RewardData(15, 1375, 150, 331, 333, 500, 2);
            siteRewards[52] = RewardData(30, 1314, 150, 332, 318, 500, 2);
            siteRewards[53] = RewardData(4, 1397, 150, 332, 344, 500, 2);
            siteRewards[54] = RewardData(30, 1330, 150, 332, 318, 500, 2);
        }
    }

    function getSiteRewards(
        uint256 _siteId
    )
        public
        view
        returns (
            uint256 monster_rate,
            uint256 monster_id,
            uint256 shard_rate,
            uint256 shard_id,
            uint256 level_rate,
            uint256 exp_perecent_rate,
            uint256 evo_rate
        )
    {
        RewardData storage reward = siteRewards[_siteId];
        return (
            reward.monster_rate,
            reward.monster_id,
            reward.shard_rate,
            reward.shard_id,
            reward.level_rate,
            reward.exp_perecent_rate,
            reward.evo_rate
        );
    }

    function getSiteId(
        uint64 _monsterId,
        uint256 _seed
    ) public view returns (uint256) {
        // DONE: Call EthermonData contract to get first type.
        IEthermonDataContract ethermonDataContract = IEthermonDataContract(
            ethermonData
        );
        uint8 monType = ethermonDataContract.getElementInArrayType(
            ArrayType.CLASS_TYPE,
            _monsterId,
            0
        );
        uint256[] storage siteList = siteSet[monType];
        // uint256[] storage siteList = siteSet[monsterClassSiteSet[_classId]];
        if (siteList.length == 0) return 0;
        return siteList[_seed % siteList.length];
    }

    // function getSiteItem(
    //     uint256 _siteId,
    //     uint256 _exp,
    //     uint256 _seed
    // )
    //     public
    //     view
    //     returns (
    //         uint256 _monsterClassId,
    //         uint256 _tokenClassId,
    //         uint256 _value
    //     )
    // {
    //     uint256 value = _seed % 1000;
    //     RewardData storage reward = siteRewards[_siteId];
    //     // assign monster
    //     if (value < reward.monster_rate) {
    //         return (reward.monster_id, 0, 0);
    //     }
    //     value -= reward.monster_rate;
    //     // shard
    //     if (value < reward.shard_rate) {
    //         return (0, reward.shard_id, 0);
    //     }
    //     value -= reward.shard_rate;
    //     // level
    //     if (value < reward.level_rate) {
    //         return (0, levelItemClass, levelRewards[value % 4]);
    //     }
    //     value -= reward.level_rate;
    //     // exp

    //     //Level 5 = 5%
    //     //Basic X = 1%
    //     // 1 3 5 10 25
    //     if (value < reward.exp_rate) {
    //         require(_exp > 0, "Invalid EXP");
    //         uint256 exp = (expRewards[value % 11] * _exp) / 10000;
    //         return (0, expItemClass, expRewards[value % 11]);
    //     }
    //     value -= reward.exp_rate;
    //     return (0, 0, 0);
    //     //return (0, 0, emonRewards[value%6]);
    // }

    function getSiteItem(
        uint256 _siteId,
        uint256 _seed
    )
        public
        view
        returns (uint256 _monsterClassId, uint256 _tokenClassId, uint256 _value)
    {
        // _seed will be under 100K
        uint256 value = _seed % 1000;
        RewardData storage reward = siteRewards[_siteId];
        if (value < reward.evo_rate) {
            return (0, evoItemClass, 0);
        }
        value -= reward.evo_rate;
        // assign monster
        if (value < reward.monster_rate) {
            return (reward.monster_id, 0, 0);
        }
        value -= reward.monster_rate;
        // shard
        if (value < reward.shard_rate) {
            return (0, reward.shard_id, 0);
        }
        value -= reward.shard_rate;
        // level
        if (value < reward.level_rate) {
            return (0, levelItemClass, levelRewards[value % 4]);
        }
        value -= reward.level_rate;
        // exp
        if (value < reward.exp_perecent_rate) {
            return (0, expItemClass, expPerecentRewards[value % 11]);
        }
        value -= reward.exp_perecent_rate;
        return (0, expItemClass, expPerecentRewards[value % 11]);
    }
}