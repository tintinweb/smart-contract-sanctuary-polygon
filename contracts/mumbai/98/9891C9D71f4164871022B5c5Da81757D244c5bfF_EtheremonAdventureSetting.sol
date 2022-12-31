/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

// File: contracts/EtheremonAdventureSetting.sol

/**
 *Submitted for verification at Etherscan.io on 2020-03-29
 */

/**
 *Submitted for verification at Etherscan.io on 2018-09-03
 */

pragma solidity ^0.6.6;

contract BasicAccessControl {
    address public owner;
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

    function ChangeOwner(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
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
        uint256 adv_site_rate;
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
        3,
        3,
        3,
        3,
        3,
        5,
        5,
        5,
        10,
        10,
        25
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

    function removeSiteSet(uint256 _setId, uint256 _siteId)
        public
        onlyModerators
    {
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

    function setMonsterClassSiteSet(uint256 _monsterId, uint256 _siteSetId)
        public
        onlyModerators
    {
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

    function setLevelRewards(uint256 _index, uint256 _value)
        public
        onlyModerators
    {
        levelRewards[_index] = _value;
    }

    function setExpRewards(uint256 _index, uint256 _value)
        public
        onlyModerators
    {
        expRewards[_index] = _value;
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
        monsterClassSiteSet[1] = 1;
        monsterClassSiteSet[2] = 2;
        monsterClassSiteSet[3] = 3;
        monsterClassSiteSet[4] = 4;
        monsterClassSiteSet[5] = 5;
        monsterClassSiteSet[6] = 6;
        monsterClassSiteSet[7] = 7;
        monsterClassSiteSet[8] = 8;
        monsterClassSiteSet[9] = 8;
        monsterClassSiteSet[10] = 2;
        monsterClassSiteSet[11] = 9;
        monsterClassSiteSet[12] = 18;
        monsterClassSiteSet[13] = 11;
        monsterClassSiteSet[14] = 12;
        monsterClassSiteSet[15] = 3;
        monsterClassSiteSet[16] = 13;
        monsterClassSiteSet[17] = 3;
        monsterClassSiteSet[18] = 8;
        monsterClassSiteSet[19] = 8;
        monsterClassSiteSet[20] = 14;
        monsterClassSiteSet[21] = 13;
        monsterClassSiteSet[22] = 4;
        monsterClassSiteSet[23] = 9;
        monsterClassSiteSet[24] = 1;
        monsterClassSiteSet[25] = 1;
        monsterClassSiteSet[26] = 3;
        monsterClassSiteSet[27] = 2;
        monsterClassSiteSet[28] = 6;
        monsterClassSiteSet[29] = 4;
        monsterClassSiteSet[30] = 14;
        monsterClassSiteSet[31] = 18;
        monsterClassSiteSet[32] = 1;
        monsterClassSiteSet[33] = 15;
        monsterClassSiteSet[34] = 3;
        monsterClassSiteSet[35] = 3;
        monsterClassSiteSet[36] = 2;
        monsterClassSiteSet[37] = 8;
        monsterClassSiteSet[38] = 1;
        monsterClassSiteSet[39] = 2;
        monsterClassSiteSet[40] = 3;
        monsterClassSiteSet[41] = 4;
        monsterClassSiteSet[42] = 5;
        monsterClassSiteSet[43] = 6;
        monsterClassSiteSet[44] = 7;
        monsterClassSiteSet[45] = 8;
        monsterClassSiteSet[46] = 8;
        monsterClassSiteSet[47] = 2;
        monsterClassSiteSet[48] = 9;
        monsterClassSiteSet[49] = 18;
        monsterClassSiteSet[50] = 8;
        monsterClassSiteSet[51] = 14;
        monsterClassSiteSet[52] = 1;
        monsterClassSiteSet[53] = 3;
        monsterClassSiteSet[54] = 2;
        monsterClassSiteSet[55] = 6;
        monsterClassSiteSet[56] = 4;
        monsterClassSiteSet[57] = 14;
        monsterClassSiteSet[58] = 18;
        monsterClassSiteSet[59] = 1;
        monsterClassSiteSet[60] = 15;
        monsterClassSiteSet[61] = 3;
        monsterClassSiteSet[62] = 8;
        monsterClassSiteSet[63] = 8;
        monsterClassSiteSet[64] = 1;
        monsterClassSiteSet[65] = 2;
        monsterClassSiteSet[66] = 4;
        monsterClassSiteSet[67] = 5;
        monsterClassSiteSet[68] = 14;
        monsterClassSiteSet[69] = 1;
        monsterClassSiteSet[70] = 3;
        monsterClassSiteSet[71] = 3;
        monsterClassSiteSet[72] = 16;
        monsterClassSiteSet[73] = 17;
        monsterClassSiteSet[74] = 5;
        monsterClassSiteSet[75] = 7;
        monsterClassSiteSet[76] = 1;
        monsterClassSiteSet[77] = 17;
        monsterClassSiteSet[78] = 18;
        monsterClassSiteSet[79] = 1;
        monsterClassSiteSet[80] = 13;
        monsterClassSiteSet[81] = 4;
        monsterClassSiteSet[82] = 17;
        monsterClassSiteSet[83] = 18;
        monsterClassSiteSet[84] = 1;
        monsterClassSiteSet[85] = 13;
        monsterClassSiteSet[86] = 4;
        monsterClassSiteSet[87] = 1;
        monsterClassSiteSet[88] = 4;
        monsterClassSiteSet[89] = 1;
        monsterClassSiteSet[90] = 2;
        monsterClassSiteSet[91] = 2;
        monsterClassSiteSet[92] = 2;
        monsterClassSiteSet[93] = 15;
        monsterClassSiteSet[94] = 15;
        monsterClassSiteSet[95] = 15;
        monsterClassSiteSet[96] = 12;
        monsterClassSiteSet[97] = 12;
        monsterClassSiteSet[98] = 12;
        monsterClassSiteSet[99] = 5;
        monsterClassSiteSet[100] = 5;
        monsterClassSiteSet[101] = 8;
        monsterClassSiteSet[102] = 8;
        monsterClassSiteSet[103] = 2;
        monsterClassSiteSet[104] = 2;
        monsterClassSiteSet[105] = 15;
        monsterClassSiteSet[106] = 1;
        monsterClassSiteSet[107] = 1;
        monsterClassSiteSet[108] = 1;
        monsterClassSiteSet[109] = 9;
        monsterClassSiteSet[110] = 18;
        monsterClassSiteSet[111] = 13;
        monsterClassSiteSet[112] = 11;
        monsterClassSiteSet[113] = 14;
        monsterClassSiteSet[114] = 6;
        monsterClassSiteSet[115] = 8;
        monsterClassSiteSet[116] = 3;
        monsterClassSiteSet[117] = 3;
        monsterClassSiteSet[118] = 3;
        monsterClassSiteSet[119] = 13;
        monsterClassSiteSet[120] = 13;
        monsterClassSiteSet[121] = 13;
        monsterClassSiteSet[122] = 5;
        monsterClassSiteSet[123] = 5;
        monsterClassSiteSet[124] = 5;
        monsterClassSiteSet[125] = 15;
        monsterClassSiteSet[126] = 15;
        monsterClassSiteSet[127] = 15;
        monsterClassSiteSet[128] = 1;
        monsterClassSiteSet[129] = 1;
        monsterClassSiteSet[130] = 1;
        monsterClassSiteSet[131] = 14;
        monsterClassSiteSet[132] = 14;
        monsterClassSiteSet[133] = 14;
        monsterClassSiteSet[134] = 16;
        monsterClassSiteSet[135] = 16;
        monsterClassSiteSet[136] = 13;
        monsterClassSiteSet[137] = 13;
        monsterClassSiteSet[138] = 4;
        monsterClassSiteSet[139] = 4;
        monsterClassSiteSet[140] = 7;
        monsterClassSiteSet[141] = 7;
        monsterClassSiteSet[142] = 4;
        monsterClassSiteSet[143] = 4;
        monsterClassSiteSet[144] = 13;
        monsterClassSiteSet[145] = 13;
        monsterClassSiteSet[146] = 9;
        monsterClassSiteSet[147] = 9;
        monsterClassSiteSet[148] = 14;
        monsterClassSiteSet[149] = 14;
        monsterClassSiteSet[150] = 14;
        monsterClassSiteSet[151] = 1;
        monsterClassSiteSet[152] = 1;
        monsterClassSiteSet[153] = 12;
        monsterClassSiteSet[154] = 9;
        monsterClassSiteSet[155] = 14;
        monsterClassSiteSet[156] = 16;
        monsterClassSiteSet[157] = 16;
        monsterClassSiteSet[158] = 8;
        monsterClassSiteSet[159] = 7;
        monsterClassSiteSet[160] = 7;
        monsterClassSiteSet[161] = 12;
        monsterClassSiteSet[162] = 12;
        monsterClassSiteSet[163] = 3;
        monsterClassSiteSet[164] = 3;
        monsterClassSiteSet[165] = 16;
        monsterClassSiteSet[166] = 13;
        monsterClassSiteSet[167] = 13;
        monsterClassSiteSet[168] = 15;
        monsterClassSiteSet[169] = 15;
        monsterClassSiteSet[170] = 17;
        monsterClassSiteSet[171] = 17;
        monsterClassSiteSet[172] = 17;
        monsterClassSiteSet[173] = 2;
        monsterClassSiteSet[174] = 2;
        monsterClassSiteSet[175] = 2;
        monsterClassSiteSet[176] = 3;
        monsterClassSiteSet[177] = 3;
        monsterClassSiteSet[178] = 3;
        monsterClassSiteSet[179] = 2;
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
            //     uint256 adv_site_rate;
            // }
            siteRewards[1] = RewardData(20, 1116, 450, 350, 25, 3, 55, 0);
            siteRewards[2] = RewardData(20, 1119, 450, 350, 25, 3, 55, 0);
            siteRewards[3] = RewardData(20, 1122, 450, 350, 25, 3, 55, 0);
            siteRewards[4] = RewardData(20, 1116, 450, 351, 25, 3, 55, 0);
            siteRewards[5] = RewardData(20, 1119, 450, 351, 25, 3, 55, 0);
            siteRewards[6] = RewardData(20, 1122, 450, 351, 25, 3, 55, 0);
            siteRewards[7] = RewardData(20, 1116, 450, 352, 25, 3, 55, 0);
            siteRewards[8] = RewardData(20, 1119, 450, 352, 25, 3, 55, 0);
            siteRewards[9] = RewardData(20, 1122, 450, 352, 25, 3, 55, 0);
            siteRewards[10] = RewardData(20, 1120, 450, 320, 25, 3, 55, 0);
            siteRewards[11] = RewardData(20, 1128, 450, 320, 25, 3, 55, 0);
            siteRewards[12] = RewardData(50, 1166, 450, 320, 25, 3, 25, 0);
            siteRewards[13] = RewardData(20, 1125, 450, 321, 25, 3, 55, 0);
            siteRewards[14] = RewardData(20, 1128, 450, 321, 25, 3, 55, 0);
            siteRewards[15] = RewardData(50, 1166, 450, 321, 25, 3, 25, 0);
            siteRewards[16] = RewardData(20, 1125, 450, 322, 25, 3, 55, 0);
            siteRewards[17] = RewardData(20, 1128, 450, 322, 25, 3, 55, 0);
            siteRewards[18] = RewardData(50, 1166, 450, 322, 25, 3, 25, 0);
            siteRewards[19] = RewardData(20, 1134, 450, 340, 25, 3, 55, 0);
            siteRewards[20] = RewardData(20, 1136, 450, 340, 25, 3, 55, 0);
            siteRewards[21] = RewardData(20, 1138, 450, 340, 25, 3, 55, 0);
            siteRewards[22] = RewardData(20, 1134, 450, 341, 25, 3, 55, 0);
            siteRewards[23] = RewardData(20, 1136, 450, 341, 25, 3, 55, 0);
            siteRewards[24] = RewardData(20, 1138, 450, 341, 25, 3, 55, 0);
            siteRewards[25] = RewardData(20, 1134, 450, 342, 25, 3, 55, 0);
            siteRewards[26] = RewardData(20, 1136, 450, 342, 25, 3, 55, 0);
            siteRewards[27] = RewardData(20, 1138, 450, 342, 25, 3, 55, 0);
        } else {
            siteRewards[28] = RewardData(15, 1176, 450, 300, 25, 3, 60, 0);
            siteRewards[29] = RewardData(50, 1168, 450, 300, 25, 3, 25, 0);
            siteRewards[30] = RewardData(20, 1144, 450, 300, 25, 3, 55, 0);
            siteRewards[31] = RewardData(15, 1176, 450, 301, 25, 3, 60, 0);
            siteRewards[32] = RewardData(50, 1168, 450, 301, 25, 3, 25, 0);
            siteRewards[33] = RewardData(20, 1144, 450, 301, 25, 3, 55, 0);
            siteRewards[34] = RewardData(15, 1176, 450, 302, 25, 3, 60, 0);
            siteRewards[35] = RewardData(50, 1168, 450, 302, 25, 3, 25, 0);
            siteRewards[36] = RewardData(20, 1144, 450, 302, 25, 3, 55, 0);
            siteRewards[37] = RewardData(1, 1179, 450, 310, 25, 3, 74, 0);
            siteRewards[38] = RewardData(25, 1134, 450, 310, 25, 3, 55, 0);
            siteRewards[39] = RewardData(25, 1125, 450, 310, 25, 3, 55, 0);
            siteRewards[40] = RewardData(15, 1170, 450, 311, 25, 3, 60, 0);
            siteRewards[41] = RewardData(20, 1148, 450, 311, 25, 3, 55, 0);
            siteRewards[42] = RewardData(1, 1179, 450, 311, 25, 3, 74, 0);
            siteRewards[43] = RewardData(15, 1170, 450, 312, 25, 3, 60, 0);
            siteRewards[44] = RewardData(20, 1148, 450, 312, 25, 3, 55, 0);
            siteRewards[45] = RewardData(15, 1173, 450, 312, 25, 3, 60, 0);
            siteRewards[46] = RewardData(15, 1173, 450, 330, 25, 3, 60, 0);
            siteRewards[47] = RewardData(15, 1170, 450, 330, 25, 3, 60, 0);
            siteRewards[48] = RewardData(20, 1148, 450, 330, 25, 3, 55, 0);
            siteRewards[49] = RewardData(25, 1138, 450, 331, 25, 3, 55, 0);
            siteRewards[50] = RewardData(25, 1119, 450, 331, 25, 3, 55, 0);
            siteRewards[51] = RewardData(1, 1179, 450, 331, 25, 3, 74, 0);
            siteRewards[52] = RewardData(15, 1173, 450, 332, 25, 3, 60, 0);
            siteRewards[53] = RewardData(20, 1146, 450, 332, 25, 3, 55, 0);
            siteRewards[54] = RewardData(20, 1148, 450, 332, 25, 3, 55, 0);
        }
    }

    function getSiteRewards(uint256 _siteId)
        public
        view
        returns (
            uint256 monster_rate,
            uint256 monster_id,
            uint256 shard_rate,
            uint256 shard_id,
            uint256 level_rate,
            uint256 exp_perecent_rate,
            uint256 evo_rate,
            uint256 adv_site_rate
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
            reward.evo_rate,
            reward.adv_site_rate
        );
    }

    function getSiteId(uint256 _classId, uint256 _seed)
        public
        view
        returns (uint256)
    {
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

    function getSiteItem(uint256 _siteId, uint256 _seed)
        public
        view
        returns (
            uint256 _monsterClassId,
            uint256 _tokenClassId,
            uint256 _value
        )
    {
        uint256 value = _seed % 1000;
        RewardData storage reward = siteRewards[_siteId];
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
            return (0, expItemClass, expPerecentRewards[value % 3]);
        }
        value -= reward.exp_perecent_rate;
        if (value < reward.evo_rate) {
            return (0, evoItemClass, 0);
        }
        value -= reward.evo_rate;
        if (value < reward.adv_site_rate) {
            return (0, advSiteItemClass, 0);
        }
        value -= reward.adv_site_rate;
        return (0, 0, 0);
    }
}