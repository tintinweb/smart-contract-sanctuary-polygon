/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

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

contract EtheremonAdventureSetting is BasicAccessControl {
    struct RewardData {
        uint256 monster_rate;
        uint256 monster_id;
        uint256 shard_rate; //gem stones
        uint256 shard_id;
        uint256 level_rate;
        uint256 exp_perecent_rate;
        uint256 evo_rate;
    }
    mapping(uint256 => uint256[]) public siteSet; // monster class -> site id
    mapping(uint256 => uint256) public monsterClassSiteSet;
    mapping(uint256 => RewardData) public siteRewards; // site id => rewards (monster_rate, monster_id, shard_rate, shard_id, level_rate, exp_rate, emon_rate)
    uint256 public levelItemClass = 200;
    uint256 public expItemClass = 201;
    uint256 public evoItemClass = 202;
    uint256 public advSiteItemClass = 203;
    uint256[4] public levelRewards = [1, 1, 1, 1]; // remove +2 level stones used to be 25% chance Old:  [1, 1, 1, 2]
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
                35,
                3,
                4,
                37,
                51,
                8,
                41,
                11,
                45,
                47,
                15,
                16,
                19,
                52,
                23,
                36,
                27,
                30,
                31
            ]; //Insect
            siteSet[2] = [
                35,
                3,
                4,
                49,
                39,
                8,
                41,
                11,
                13,
                15,
                48,
                43,
                18,
                19,
                53,
                23,
                27,
                30,
                31
            ]; //Dragon
            siteSet[3] = [
                2,
                4,
                39,
                40,
                9,
                47,
                12,
                14,
                44,
                16,
                49,
                20,
                46,
                54,
                24,
                25,
                27,
                36,
                29,
                31
            ]; //Mystic
            siteSet[4] = [
                51,
                3,
                5,
                38,
                7,
                40,
                11,
                12,
                45,
                14,
                47,
                16,
                35,
                52,
                21,
                22,
                26,
                30,
                31
            ]; //Fire
            siteSet[5] = [
                33,
                3,
                4,
                54,
                38,
                8,
                10,
                43,
                45,
                14,
                50,
                18,
                35,
                21,
                22,
                46,
                26,
                28,
                42
            ]; //Phantom
            siteSet[6] = [
                51,
                3,
                36,
                5,
                7,
                44,
                42,
                12,
                13,
                47,
                17,
                37,
                19,
                52,
                24,
                26,
                28,
                29,
                31
            ]; //Earth
            siteSet[7] = [
                32,
                48,
                2,
                43,
                4,
                38,
                7,
                9,
                42,
                11,
                34,
                15,
                16,
                49,
                21,
                23,
                25,
                30,
                53
            ]; //Neutral
            siteSet[8] = [
                1,
                34,
                54,
                6,
                33,
                8,
                44,
                39,
                12,
                13,
                46,
                17,
                50,
                20,
                22,
                40,
                24,
                25,
                29
            ]; //Telepath
            siteSet[9] = [
                32,
                2,
                6,
                7,
                40,
                10,
                39,
                44,
                34,
                15,
                48,
                17,
                50,
                20,
                21,
                24,
                25,
                29,
                52
            ]; //Iron

            //TODO: Remeber to remove 10 with 18 as on backend we have no 10 instead we have 18 as fighter
            // siteSet[10] = []; //fighter
        } else {
            siteSet[11] = [
                2,
                35,
                37,
                6,
                7,
                10,
                46,
                44,
                50,
                14,
                18,
                51,
                21,
                22,
                26,
                53,
                42,
                30,
                31
            ]; //Lightning
            siteSet[12] = [
                1,
                34,
                5,
                51,
                33,
                9,
                10,
                45,
                14,
                47,
                16,
                18,
                19,
                52,
                41,
                23,
                27,
                29,
                37
            ]; //Combat
            siteSet[13] = [
                32,
                2,
                35,
                4,
                5,
                38,
                49,
                9,
                42,
                43,
                12,
                13,
                48,
                17,
                21,
                24,
                25,
                28,
                53
            ]; //Flyer
            siteSet[14] = [
                1,
                34,
                3,
                37,
                6,
                33,
                8,
                41,
                10,
                45,
                46,
                15,
                17,
                50,
                20,
                54,
                24,
                25,
                29
            ]; //Leaf
            siteSet[15] = [
                33,
                2,
                34,
                6,
                7,
                40,
                42,
                11,
                13,
                47,
                50,
                43,
                18,
                20,
                22,
                39,
                26,
                30,
                52
            ]; //Ice
            siteSet[16] = [
                32,
                1,
                36,
                5,
                39,
                54,
                9,
                10,
                43,
                14,
                18,
                51,
                20,
                46,
                22,
                41,
                27,
                28,
                53
            ]; //Toxin
            siteSet[17] = [
                32,
                1,
                49,
                36,
                38,
                6,
                33,
                8,
                44,
                12,
                13,
                48,
                17,
                19,
                40,
                54,
                23,
                26,
                28
            ]; //Rock
            siteSet[18] = [
                32,
                1,
                36,
                5,
                38,
                48,
                9,
                11,
                45,
                15,
                16,
                49,
                19,
                41,
                23,
                27,
                28,
                53,
                37
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
            siteRewards[1] = RewardData(20, 1116, 450, 350, 25, 3, 55);
            siteRewards[2] = RewardData(20, 1119, 450, 350, 25, 3, 55);
            siteRewards[3] = RewardData(20, 1122, 450, 350, 25, 3, 55);
            siteRewards[4] = RewardData(20, 1116, 450, 351, 25, 3, 55);
            siteRewards[5] = RewardData(20, 1119, 450, 351, 25, 3, 55);
            siteRewards[6] = RewardData(20, 1122, 450, 351, 25, 3, 55);
            siteRewards[7] = RewardData(20, 1116, 450, 352, 25, 3, 55);
            siteRewards[8] = RewardData(20, 1119, 450, 352, 25, 3, 55);
            siteRewards[9] = RewardData(20, 1122, 450, 352, 25, 3, 55);
            siteRewards[10] = RewardData(20, 1120, 450, 320, 25, 3, 55);
            siteRewards[11] = RewardData(20, 1128, 450, 320, 25, 3, 55);
            siteRewards[12] = RewardData(50, 1166, 450, 320, 25, 3, 25);
            siteRewards[13] = RewardData(20, 1125, 450, 321, 25, 3, 55);
            siteRewards[14] = RewardData(20, 1128, 450, 321, 25, 3, 55);
            siteRewards[15] = RewardData(50, 1166, 450, 321, 25, 3, 25);
            siteRewards[16] = RewardData(20, 1125, 450, 322, 25, 3, 55);
            siteRewards[17] = RewardData(20, 1128, 450, 322, 25, 3, 55);
            siteRewards[18] = RewardData(50, 1166, 450, 322, 25, 3, 25);
            siteRewards[19] = RewardData(20, 1134, 450, 340, 25, 3, 55);
            siteRewards[20] = RewardData(20, 1136, 450, 340, 25, 3, 55);
            siteRewards[21] = RewardData(20, 1138, 450, 340, 25, 3, 55);
            siteRewards[22] = RewardData(20, 1134, 450, 341, 25, 3, 55);
            siteRewards[23] = RewardData(20, 1136, 450, 341, 25, 3, 55);
            siteRewards[24] = RewardData(20, 1138, 450, 341, 25, 3, 55);
            siteRewards[25] = RewardData(20, 1134, 450, 342, 25, 3, 55);
            siteRewards[26] = RewardData(20, 1136, 450, 342, 25, 3, 55);
            siteRewards[27] = RewardData(20, 1138, 450, 342, 25, 3, 55);
        } else {
            siteRewards[28] = RewardData(15, 1176, 450, 300, 25, 3, 60);
            siteRewards[29] = RewardData(50, 1168, 450, 300, 25, 3, 25);
            siteRewards[30] = RewardData(20, 1144, 450, 300, 25, 3, 55);
            siteRewards[31] = RewardData(15, 1176, 450, 301, 25, 3, 60);
            siteRewards[32] = RewardData(50, 1168, 450, 301, 25, 3, 25);
            siteRewards[33] = RewardData(20, 1144, 450, 301, 25, 3, 55);
            siteRewards[34] = RewardData(15, 1176, 450, 302, 25, 3, 60);
            siteRewards[35] = RewardData(50, 1168, 450, 302, 25, 3, 25);
            siteRewards[36] = RewardData(20, 1144, 450, 302, 25, 3, 55);
            siteRewards[37] = RewardData(1, 1179, 450, 310, 25, 3, 74);
            siteRewards[38] = RewardData(25, 1134, 450, 310, 25, 3, 55);
            siteRewards[39] = RewardData(25, 1125, 450, 310, 25, 3, 55);
            siteRewards[40] = RewardData(15, 1170, 450, 311, 25, 3, 60);
            siteRewards[41] = RewardData(20, 1148, 450, 311, 25, 3, 55);
            siteRewards[42] = RewardData(1, 1179, 450, 311, 25, 3, 74);
            siteRewards[43] = RewardData(15, 1170, 450, 312, 25, 3, 60);
            siteRewards[44] = RewardData(20, 1148, 450, 312, 25, 3, 55);
            siteRewards[45] = RewardData(15, 1173, 450, 312, 25, 3, 60);
            siteRewards[46] = RewardData(15, 1173, 450, 330, 25, 3, 60);
            siteRewards[47] = RewardData(15, 1170, 450, 330, 25, 3, 60);
            siteRewards[48] = RewardData(20, 1148, 450, 330, 25, 3, 55);
            siteRewards[49] = RewardData(25, 1138, 450, 331, 25, 3, 55);
            siteRewards[50] = RewardData(25, 1119, 450, 331, 25, 3, 55);
            siteRewards[51] = RewardData(1, 1179, 450, 331, 25, 3, 74);
            siteRewards[52] = RewardData(15, 1173, 450, 332, 25, 3, 60);
            siteRewards[53] = RewardData(20, 1146, 450, 332, 25, 3, 55);
            siteRewards[54] = RewardData(20, 1148, 450, 332, 25, 3, 55);
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
        uint256 _classId,
        uint256 _seed
    ) public view returns (uint256) {
        uint256[] storage siteList = siteSet[monsterClassSiteSet[_classId]];
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