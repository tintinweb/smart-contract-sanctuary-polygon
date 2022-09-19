// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/ILevels.sol";

/**
 * @title Levels
 * @notice This contract is a static storage with utility functions to determine the level
 * table for the [Experience](/docs/core/Experience.md) contract.
 *
 * @notice Implementation of the [ILevels](/docs/interfaces/ILevels.md) interface.
 */
contract Levels is ILevels {
    // =============================================== Storage ========================================================

    /** @notice Map to track the levels. */
    mapping(uint256 => Level) levels;

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     * @notice Initializes the lable table.
     */
    constructor() {
        levels[0] = Level(0, 1000);
        levels[1] = Level(1000, 2020);
        levels[2] = Level(2020, 3060);
        levels[3] = Level(3060, 4121);
        levels[4] = Level(4121, 5203);
        levels[5] = Level(5203, 6320);
        levels[6] = Level(6320, 7473);
        levels[7] = Level(7473, 8663);
        levels[8] = Level(8663, 9891);
        levels[9] = Level(9891, 11158);
        levels[10] = Level(11158, 12466);
        levels[11] = Level(12466, 13816);
        levels[12] = Level(13816, 15209);
        levels[13] = Level(15209, 16647);
        levels[14] = Level(16647, 18135);
        levels[15] = Level(18135, 19671);
        levels[16] = Level(19671, 21256);
        levels[17] = Level(21256, 22892);
        levels[18] = Level(22892, 24580);
        levels[19] = Level(24580, 26322);
        levels[20] = Level(26322, 28099);
        levels[21] = Level(28099, 29912);
        levels[22] = Level(29912, 31761);
        levels[23] = Level(31761, 33647);
        levels[24] = Level(33647, 35571);
        levels[25] = Level(35571, 37533);
        levels[26] = Level(37533, 39534);
        levels[27] = Level(39534, 41575);
        levels[28] = Level(41575, 43657);
        levels[29] = Level(43657, 45781);
        levels[30] = Level(45781, 47947);
        levels[31] = Level(47947, 50156);
        levels[32] = Level(50156, 52409);
        levels[33] = Level(52409, 54707);
        levels[34] = Level(54707, 57085);
        levels[35] = Level(57085, 59546);
        levels[36] = Level(59546, 62093);
        levels[37] = Level(62093, 64729);
        levels[38] = Level(64729, 67457);
        levels[39] = Level(67457, 70280);
        levels[40] = Level(70280, 73193);
        levels[41] = Level(73193, 76199);
        levels[42] = Level(76199, 79301);
        levels[43] = Level(79301, 82502);
        levels[44] = Level(82502, 85805);
        levels[45] = Level(85805, 89174);
        levels[46] = Level(89174, 92610);
        levels[47] = Level(92610, 96115);
        levels[48] = Level(96115, 99690);
        levels[49] = Level(99690, 103337);
        levels[50] = Level(103337, 107101);
        levels[51] = Level(107101, 110985);
        levels[52] = Level(110985, 114993);
        levels[53] = Level(114993, 119129);
        levels[54] = Level(119129, 123397);
        levels[55] = Level(123397, 127750);
        levels[56] = Level(127750, 132190);
        levels[57] = Level(132190, 136719);
        levels[58] = Level(136719, 141339);
        levels[59] = Level(141339, 146051);
        levels[60] = Level(146051, 150914);
        levels[61] = Level(150914, 155933);
        levels[62] = Level(155933, 161113);
        levels[63] = Level(161113, 166459);
        levels[64] = Level(166459, 171976);
        levels[65] = Level(171976, 177670);
        levels[66] = Level(177670, 183546);
        levels[67] = Level(183546, 189610);
        levels[68] = Level(189610, 195868);
        levels[69] = Level(195868, 202326);
        levels[70] = Level(202326, 209010);
        levels[71] = Level(209010, 215928);
        levels[72] = Level(215928, 223088);
        levels[73] = Level(223088, 230499);
        levels[74] = Level(230499, 238169);
        levels[75] = Level(238169, 246107);
        levels[76] = Level(246107, 254323);
        levels[77] = Level(254323, 262827);
        levels[78] = Level(262827, 271629);
        levels[79] = Level(271629, 280739);
        levels[80] = Level(280739, 290141);
        levels[81] = Level(290141, 299844);
        levels[82] = Level(299844, 309857);
        levels[83] = Level(309857, 320190);
        levels[84] = Level(320190, 330854);
        levels[85] = Level(330854, 341731);
        levels[86] = Level(341731, 352826);
        levels[87] = Level(352826, 364143);
        levels[88] = Level(364143, 375686);
        levels[89] = Level(375686, 387460);
        levels[90] = Level(387460, 399611);
        levels[91] = Level(399611, 412151);
        levels[92] = Level(412151, 425092);
        levels[93] = Level(425092, 438447);
        levels[94] = Level(438447, 452229);
        levels[95] = Level(452229, 466452);
        levels[96] = Level(466452, 481130);
        levels[97] = Level(481130, 496278);
        levels[98] = Level(496278, 511911);
        levels[99] = Level(511911, 528044);
        levels[100] = Level(528044, 544500);
        levels[101] = Level(544500, 561285);
        levels[102] = Level(561285, 578406);
        levels[103] = Level(578406, 595869);
        levels[104] = Level(595869, 613681);
        levels[105] = Level(613681, 631849);
        levels[106] = Level(631849, 650380);
        levels[107] = Level(650380, 669282);
        levels[108] = Level(669282, 688562);
        levels[109] = Level(688562, 708228);
        levels[110] = Level(708228, 728582);
        levels[111] = Level(728582, 749648);
        levels[112] = Level(749648, 771451);
        levels[113] = Level(771451, 794017);
        levels[114] = Level(794017, 817373);
        levels[115] = Level(817373, 841546);
        levels[116] = Level(841546, 866565);
        levels[117] = Level(866565, 892460);
        levels[118] = Level(892460, 919261);
        levels[119] = Level(919261, 947000);
        levels[120] = Level(947000, 975627);
        levels[121] = Level(975627, 1005170);
        levels[122] = Level(1005170, 1035658);
        levels[123] = Level(1035658, 1067122);
        levels[124] = Level(1067122, 1099593);
        levels[125] = Level(1099593, 1132713);
        levels[126] = Level(1132713, 1166495);
        levels[127] = Level(1166495, 1200953);
        levels[128] = Level(1200953, 1236100);
        levels[129] = Level(1236100, 1271950);
        levels[130] = Level(1271950, 1308517);
        levels[131] = Level(1308517, 1345815);
        levels[132] = Level(1345815, 1383859);
        levels[133] = Level(1383859, 1422664);
        levels[134] = Level(1422664, 1462245);
        levels[135] = Level(1462245, 1503093);
        levels[136] = Level(1503093, 1545248);
        levels[137] = Level(1545248, 1588752);
        levels[138] = Level(1588752, 1633648);
        levels[139] = Level(1633648, 1680115);
        levels[140] = Level(1680115, 1728208);
        levels[141] = Level(1728208, 1777984);
        levels[142] = Level(1777984, 1829502);
        levels[143] = Level(1829502, 1882823);
        levels[144] = Level(1882823, 1938010);
        levels[145] = Level(1938010, 1995129);
        levels[146] = Level(1995129, 2054247);
        levels[147] = Level(2054247, 2115434);
        levels[148] = Level(2115434, 2178763);
        levels[149] = Level(2178763, 2244309);
        levels[150] = Level(2244309, 5000000);
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function to return the level number from an experience amount.
     *
     * Requirements:
     * @param _experience   Amount of experience to check.
     *
     * @return _level       Level number of the provided experience.
     */
    function getLevel(uint256 _experience)
        public
        view
        returns (uint256 _level)
    {
        uint256 i = 0;

        if (_experience < levels[25].min) {
            i = 0;
        } else if (
            _experience >= levels[25].min && _experience < levels[50].min
        ) {
            i = 25;
        } else if (
            _experience >= levels[50].min && _experience < levels[75].min
        ) {
            i = 50;
        } else if (
            _experience >= levels[75].min && _experience < levels[100].min
        ) {
            i = 75;
        } else if (
            _experience >= levels[100].min && _experience < levels[125].min
        ) {
            i = 100;
        } else if (
            _experience >= levels[125].min && _experience < levels[150].min
        ) {
            i = 125;
        }

        while (true) {
            if (_experience >= levels[i].min && _experience < levels[i].max) {
                return i;
            }
            if (i > 150) {
                break;
            }
            i++;
        }
        return 150;
    }

    /**
     * @notice External function to return the total amount of experience required to reach a level.
     *
     * Requirements:
     * @param _level        Amount of experience to check.
     *
     * @return _experience  Experience required to reach the level provided.
     */
    function getExperience(uint256 _level)
        public
        view
        returns (uint256 _experience)
    {
        return levels[_level].max;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ILevels
 * @notice Interface for the [Levels](/docs/codex/Levels.md) contract.
 */
interface ILevels {
    /**
     * @notice Internal struct to define the level ranges.
     *
     * Requirements:
     * @param min   The minimum amount of experience to achieve the level.
     * @param max   The maximum amount of experience for this level (non inclusive).
     */
    struct Level {
        uint256 min;
        uint256 max;
    }

    /** @notice See [Levels#getLevel](/docs/codex/Levels.md#getLevel) */
    function getLevel(uint256 _experience) external view returns (uint256);

    /** @notice See [Levels#getExperience](/docs/codex/Levels.md#getExperience) */
    function getExperience(uint256 _level) external view returns (uint256);
}