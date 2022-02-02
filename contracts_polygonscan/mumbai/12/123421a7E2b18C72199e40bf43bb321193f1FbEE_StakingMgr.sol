/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

//SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
contract StakingMgr {
    bytes32 constant internal SMName = "StakingMgr";
    struct userStakes {
        bool valid;
        uint96 currentStake;  //WEI
        uint96 maxStake;      //WEI
        uint8 currentLevel;
        uint8 maxLevel;
    }
    mapping(address => userStakes) internal stakers;
    event SecurityLog(bytes32 indexed SCMgr, bytes32 indexed Action, uint indexed timestamp, address sender);
    event StakingLog(address indexed sender, uint8 Action, uint96 value, uint8 Level);    //Action: 0 = currentStake Update, 1 = maxStake Update
    function getCurrentStake(address userAddr) external view returns (uint96) { return stakers[userAddr].currentStake; }
    function getMaxStake(address userAddr) external view returns (uint96) { return stakers[userAddr].maxStake; }
    function getCurrentLevel(address userAddr) external view returns (uint8) { return stakers[userAddr].currentLevel; }
    function getMaxLevel(address userAddr) external view returns (uint8) { return stakers[userAddr].maxLevel; }
    function getUserStake(address userAddr) external view returns (userStakes memory) { return stakers[userAddr]; }
    function addStake(address userAddr, uint96 coin) external returns (userStakes memory) {
        stakers[userAddr].currentStake += coin;
        uint8 nLev = getLevel(stakers[userAddr].currentStake);
        if(nLev > stakers[userAddr].currentLevel) { stakers[userAddr].currentLevel = nLev; }
        emit StakingLog(msg.sender, 0, stakers[userAddr].currentStake, nLev);
        if(stakers[userAddr].currentStake > stakers[userAddr].maxStake) {
            stakers[userAddr].maxStake = stakers[userAddr].currentStake;
            uint8 nMaxLev = getLevel(stakers[userAddr].maxStake);
            if(nMaxLev > stakers[userAddr].maxLevel) { stakers[userAddr].maxLevel = nMaxLev; }
            emit StakingLog(msg.sender, 1, stakers[userAddr].maxStake, nMaxLev);
        }
        emit SecurityLog(SMName, "addStake", block.timestamp, msg.sender);
        return stakers[userAddr];
    }
    function subStake(address userAddr, uint96 coin) external returns (userStakes memory) {
        if(coin > stakers[userAddr].currentStake) { coin = stakers[userAddr].currentStake; }
        stakers[userAddr].currentStake -= coin;
        uint8 nLev = getLevel(stakers[userAddr].currentStake);
        if(nLev < stakers[userAddr].currentLevel) { stakers[userAddr].currentLevel = nLev; }
        emit SecurityLog(SMName, "subStake", block.timestamp, msg.sender);
        emit StakingLog(msg.sender, 0, stakers[userAddr].currentStake, nLev);
        return stakers[userAddr];
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
//addStake
//subStake
//getUserStake