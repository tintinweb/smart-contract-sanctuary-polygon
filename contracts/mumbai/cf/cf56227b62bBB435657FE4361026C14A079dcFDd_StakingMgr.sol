/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

//SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
contract StakingMgr {
    bytes32 constant internal SMName = "StakingMgr";
    address constant internal AddrLib = 0x9e4D79EFe6C34921056d758976209FB8Ac147b6E;
    struct userStacks {
        bool valid;
        uint96 currentStack;  //WEI
        uint96 maxStack;      //WEI
        uint8 currentLevel;
        uint8 maxLevel;
    }
    mapping(address => userStacks) internal stackers;
    event SecurityLog(bytes32 indexed SCMgr, bytes32 indexed Action, uint indexed timestamp, address sender);
    event StakingLog(address indexed sender, uint8 Action, uint96 value, uint8 Level);    //Action: 0 = currentStake Update, 1 = maxStake Update
    function getCurrentStack(address userAddr) external view returns (uint96) { return stackers[userAddr].currentStack; }
    function getMaxStack(address userAddr) external view returns (uint96) { return stackers[userAddr].maxStack; }
    function getCurrentLevel(address userAddr) external view returns (uint8) { return stackers[userAddr].currentLevel; }
    function getMaxLevel(address userAddr) external view returns (uint8) { return stackers[userAddr].maxLevel; }
    function getUserStack(address userAddr) external view returns (userStacks memory) { return stackers[userAddr]; }
    function addStack(address userAddr, uint96 coin) external returns (userStacks memory) {
        stackers[userAddr].currentStack += coin;
        uint8 nLev = getLevel(stackers[userAddr].currentStack);
        if(nLev > stackers[userAddr].currentLevel) { stackers[userAddr].currentLevel = nLev; }
        emit StakingLog(msg.sender, 0, stackers[userAddr].currentStack, nLev);
        if(stackers[userAddr].currentStack > stackers[userAddr].maxStack) {
            stackers[userAddr].maxStack = stackers[userAddr].currentStack;
            uint8 nMaxLev = getLevel(stackers[userAddr].maxStack);
            if(nMaxLev > stackers[userAddr].maxLevel) { stackers[userAddr].maxLevel = nMaxLev; }
            emit StakingLog(msg.sender, 1, stackers[userAddr].maxStack, nMaxLev);
        }
        emit SecurityLog(SMName, "addStack", block.timestamp, msg.sender);
        return stackers[userAddr];
    }
    function subStack(address userAddr, uint96 coin) external returns (userStacks memory) {
        if(coin > stackers[userAddr].currentStack) { coin = stackers[userAddr].currentStack; }
        stackers[userAddr].currentStack -= coin;
        uint8 nLev = getLevel(stackers[userAddr].currentStack);
        if(nLev < stackers[userAddr].currentLevel) { stackers[userAddr].currentLevel = nLev; }
        emit SecurityLog(SMName, "subStack", block.timestamp, msg.sender);
        emit StakingLog(msg.sender, 0, stackers[userAddr].currentStack, nLev);
        return stackers[userAddr];
    }
    function getLevel(uint96 coin) public pure returns (uint8) {
        if(coin >= 10) { return 10; }
        else if(coin >= 9) { return 9; }
        else if(coin >= 9) { return 8; }
        else if(coin >= 7) { return 7; }
        else if(coin >= 6) { return 6; }
        else if(coin >= 5) { return 5; }
        else if(coin >= 4) { return 4; }
        else if(coin >= 3) { return 3; }
        else if(coin >= 2) { return 2; }
        else if(coin >= 1) { return 1; }
        else { return 0; } //coin >= 0
    }
}
//[Funzioni Utente x ShibaWorldsMgr.sol]
//addStack
//subStack
//getUserStack