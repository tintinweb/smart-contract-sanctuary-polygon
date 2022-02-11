/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

//SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
    struct card {
        uint8 Epoch;
        uint8 Collection;
        uint16 Id;
        uint8 Level;
        uint8 Rarity;
        uint8 Res1;
        uint8 Res2;
        uint8 EpocRes;
        uint8 Type;
        uint8 Class;
        uint8 Heart;
        uint8 Agi;
        uint8 Int;
        uint8 Mana;
        bytes32 Name;
        string Description;
        string Picture;
    }
    struct userStakes {
        bool valid;
        uint96 currentStake;  //WEI
        uint96 maxStake;      //WEI
        uint8 currentLevel;
        uint8 maxLevel;
    }
interface IAddrLib {
    function canDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool);
    function get(bytes32 ContractName) external view returns (address);
}
interface ICardLib { function getCard(uint8 Epoch, uint8 Collection, uint16 CardId) external view returns (card memory); }
interface IStakingLib {
    function addStake(address userAddr, uint96 coin) external returns (bool);
    function subStake(address userAddr, uint96 coin) external returns (bool);
    function getUserStake(address userAddr) external view returns (userStakes memory);
}
contract ShibaWorldsMgr {
    address constant internal AddrLib = 0xd6eEDE49893f4b361c0C5ac02D48EC686846A4b2;
    bytes32 constant internal SMCard = "CardMgr";
    bytes32  constant internal SMStaking = "StakingMgr";
    function canDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool) { return IAddrLib(AddrLib).canDo(ContractName, FuncName, Sender); }
    function getAddr(bytes32 ContractName) external view returns (address) { return IAddrLib(AddrLib).get(ContractName); }
    function getCard(uint8 Epoch, uint8 Collection, uint16 CardId) external view returns (card memory) {
        address destLib = IAddrLib(AddrLib).get(SMCard);
        require(destLib != address(0), "CardMgr Not Found!");
        return ICardLib(destLib).getCard(Epoch, Collection, CardId);
    }
    function addStake(address userAddr, uint96 coin) external returns (bool) {
        address destLib = IAddrLib(AddrLib).get(SMStaking);
        require(destLib != address(0), "CardMgr Not Found!");
        return IStakingLib(destLib).addStake(userAddr, coin);
    }
    function subStake(address userAddr, uint96 coin) external returns (bool) {
        address destLib = IAddrLib(AddrLib).get(SMStaking);
        require(destLib != address(0), "CardMgr Not Found!");
        return IStakingLib(destLib).subStake(userAddr, coin);
    }
    function getUserStake(address userAddr) external view returns (userStakes memory) {
        address destLib = IAddrLib(AddrLib).get(SMStaking);
        require(destLib != address(0), "CardMgr Not Found!");
        return IStakingLib(destLib).getUserStake(userAddr);
    }
}