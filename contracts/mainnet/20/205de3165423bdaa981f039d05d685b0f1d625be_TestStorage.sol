/**
 *Submitted for verification at polygonscan.com on 2022-07-31
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

struct SubOneSlot {
    address account;   // 20 bytes
    bool flag;         // 1 byte
    int8 count;        // 1 byte
}

struct OneSlot {
    address account; // 20 bytes
    uint88 sum;      // 11 bytes
    uint8 count;     // 1 bytes
}

struct SubTwoSlots {
    address account1;
    address account2;
    bool flag1;
    bool flag2;
}


struct ContractLevelStruct0 {
    uint256 param1;
    bool param2;
}

struct ContractLevelStruct1 {
    uint256 param1;
    address param2;
    uint8 param3;
    bytes1 param4;
}

struct ContractLevelStruct2 {
    ContractLevelStruct0 param1;
    ContractLevelStruct1 param2;
}

struct ContractLevelStruct11 {
    ContractLevelStruct1 param1;
}

enum Severity {
    Low,
    Medium,
    High
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract GrandParent {
    bool initGP;
    address grandParent;
}

contract Parent is GrandParent {
    bool initP;
    address parent;
}

contract Parent2 is GrandParent {
    bool initP2;
    address parent2;
}

contract TestStorage is Parent, Parent2 {

    struct TwoSlots {
        bytes32 hash1;
        bytes32 hash2;
    }

    struct FixedArray {
        uint16 num1;
        bytes30[2] data;
        uint16 num2;
    }

    struct FlagsStruct {
        bool flag1;
        bool[2] flags;
        bool flag2;
    }

    enum Status {
        Open,
        Resolved
    }

    uint256 public constant N_COINS = 2;
    uint256 public constant MAX_COINS = 3;
    uint256 public constant SCALE = 1e18;
    uint256 internal constant DIVISOR = 1e18;
    address public immutable superUser;
    address internal immutable superUser2;

    address owner = 0x2f2Db75C5276481E2B018Ac03e968af7763Ed118;
    IERC20 token = IERC20(0x34f08F2A3f4a86531e9C4139Fde571a62689AFEC);
    address[] tokensDyn = [0x1000000000000000000000000000000000000001, 0x2000000000000000000000000000000000000002, 0x3000000000000000000000000000000000000003, 0x4000000000000000000000000000000000000004];
    IERC20[2] tokenPair = [IERC20(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5), IERC20(0x945Facb997494CC2570096c74b5F66A3507330a1)];
    address[12] dozenTokens = [0xa57Bd00134B2850B2a1c55860c9e9ea100fDd6CF, 0x1000000000000000000000000000000000000001, 0x2000000000000000000000000000000000000002, 0x3000000000000000000000000000000000000003, 0x4000000000000000000000000000000000000004, 0x5000000000000000000000000000000000000005, 0x6000000000000000000000000000000000000006, 0x7000000000000000000000000000000000000007, 0x8000000000000000000000000000000000000008, 0x9000000000000000000000000000000000000009, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48];
    address[N_COINS] coins = [0x1000000000000000000000000000000000000001, 0x2000000000000000000000000000000000000002];
    address[N_COINS][3][N_COINS] multiDimension;
    uint256[MAX_COINS] maxCoins = [1234, 567, 8910];
    IERC20[N_COINS] tokens = [IERC20(0x1000000000000000000000000000000000000001), IERC20(0x2000000000000000000000000000000000000002)];
    // address[2 * N_COINS] doubleTokens;

    uint256 totalSupply = 123123123123456789012345678;
    uint128 rate1 = 123 * 1e18;
    uint128 rate2 = 456 * 1e18;
    // fixed float1 = 1.0234;
    // ufixed float2 = 99.9999;
    // ufixed128x18 float3 = 0.001;
    // fixed128x18 float4 = 12345.0123;
    bytes32 hash;
    bool public flag1 = true;
    bool private flag2 = true;
    bool internal flag3 = true;
    bool flag4 = false;
    bool[2] flags = [true, true];
    bool flag5 = true;
    bool[2][2] flags2x2 = [[true, false], [true, true]];
    bool flag6 = true;
    bool[2][3] flags2x3 = [[true, false], [false, true], [true, true]];
    bool flag7 = true;
    bool[3][2] flags3x2 = [[true, false, true], [false, true, false]];
    bool[33][2] flags33x2;
    bool flag8 = true;
    bool[2][] flags2xDyn = [[true, true], [true, true], [false, true], [true, false], [false, false], [true, true]];
    bool flag9 = true;
    bool[][2] flagsDynx2 = [[true, false, false, true, true], [true, false, true, false, true]];
    bool[33][2][2] bool_33x2x2;
    bool flag10 = true;
    bytes30[2][6] bytes30_2x6;
    bytes30[6][2] bytes30_6x2;
    bytes32[] bytes32Dyn = [bytes32(0xFF00128251ec233d387a0af31db13f8318b61e40975c27476e1c1a02b79700FF), 0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD];
    bool flag11 = true;
    Status status = Status.Open;
    Severity severity = Severity.High;
    SubOneSlot subSlot = SubOneSlot(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5, true, -121);
    uint8 oneByteNumber = 253;
    OneSlot oneSlot = OneSlot(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5, 1234567890, 253);
    SubTwoSlots subTwoSlot = SubTwoSlots(0xF4dDc5FF5AbA6E8739E5E056340827c573d191Ec, 0xe63dfF84aa562dE11B28894f0391702b814f812D, true, true);
    TwoSlots twoSlots = TwoSlots(0xAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9, 0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD);
    FixedArray fixedArray;
    FlagsStruct flagStruct;
    int16 arrayCount = -2000;
    uint64[] dynamicIntArray = [2000, 1, 254, 0, 254, 2, 256];
    uint256[3] fixedIntArray = [1000, 2000, 3000];
    mapping (address => bool) blacklist;
    mapping (address => uint256) balance;
    mapping (address => ContractLevelStruct2) mapStruct;
    mapping (address => mapping (address => ContractLevelStruct2)) mapOfMapStruct;
    string name = "TestStorage contract";
    string short = "Less than 31 bytes";
    string exactly32 = "exactly 32 bytes so uses 2 slots";
    string long2 = "more than 31 bytes so data is stored dynamically in 2 slots";
    string long3 = "more than sixty four (64) bytes so data is stored dynamically in three slots";

    constructor(address _superUser) {
        superUser = _superUser;
        superUser2 = _superUser;
        fixedArray.num1 = 65535;
        fixedArray.num2 = 65001;
        // fixedArray.data[0] = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        // fixedArray.data[1] = bytes30("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

        blacklist[0x2f2Db75C5276481E2B018Ac03e968af7763Ed118] = true;
        balance[0x2f2Db75C5276481E2B018Ac03e968af7763Ed118] = 0x1234566789ABCDEF;
    }
}