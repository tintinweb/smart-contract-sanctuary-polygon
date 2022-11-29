// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ModuleBase.sol";
import "./PairPrice.sol";

contract UtopiaFarmAppData is ModuleBase, SafeMath {

    address internal signer;

    struct SowData {
        uint32 sowId;
        address account;
        uint256 sowAmount;
        uint256 usdtAmount;
        uint256 profitPercent;
        uint256 claimCycle;
        uint256 sowTime;
        uint256 lastClaimTime;
    }

    uint32 internal roundIndex;
    //mapping for all sowing data
    //key: index => SowData
    mapping(uint32 => SowData) internal mapSowData;

    mapping(uint32 => uint32) internal mapSowIdRoundNumber;

    mapping(uint32 => bool) mapWithdrawStatus;

    constructor(address _auth, address _moduleMgr) ModuleBase(_auth, _moduleMgr) {
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function getSigner() external view returns (address res) {
        res = signer;
    }

    function getCurrentRoundNumber() external view returns (uint32 res) {
        res = roundIndex;
    }

    function increaseRoundNumber(uint32 n) external onlyCaller {
        roundIndex += n;
    }

    function newSowData(
        uint32 roundNumber, 
        uint32 sowId, 
        address account, 
        uint256 sowAmount, 
        uint256 usdtAmount,
        uint256 profitPercent,
        uint256 claimCycle
    ) external onlyCaller {
        mapSowData[roundNumber] = SowData(
            sowId,
            account, 
            sowAmount, 
            usdtAmount,
            profitPercent,
            claimCycle,
            block.timestamp,
            block.timestamp
        );
        mapSowIdRoundNumber[sowId] = roundNumber;
    }

    function isShowIdExists(uint32 sowId) external view returns (bool res) {
        uint32 roundNumber = mapSowIdRoundNumber[sowId];
        if(roundNumber > 0) {
            res = true;
        }
    }

    function checkMatured(address account, uint32 sowId) external view returns(bool res, uint256 outAmount, uint256 beginCulTime) {
        (res, outAmount, beginCulTime) = _checkMatured(account, sowId);
    }

    function _checkMatured(address account, uint32 sowId) internal view returns(bool res, uint256 outAmount, uint256 beginCulTime) {
        uint32 roundNumber = mapSowIdRoundNumber[sowId];
        if(roundNumber > 0) {
            SowData memory sd = mapSowData[roundNumber];
            if(sd.account == account) {
                uint256 eraseTime = block.timestamp - sd.lastClaimTime;
                uint256 timeCount = eraseTime % 24;
                if(timeCount <= 3) {
                    beginCulTime = block.timestamp - timeCount * 24*3600;
                    uint256 outUSDT = 0;
                    if(5*60 <= block.timestamp - beginCulTime) {
                        res = true;
                        outUSDT = sd.usdtAmount * sd.profitPercent;
                    } else {
                        uint256 eraseHour = 1 + (block.timestamp - beginCulTime) % (24*3600);
                        uint256 rottedAmount = sd.usdtAmount*sd.profitPercent*eraseHour*5/100;
                        if(rottedAmount >= sd.usdtAmount*sd.profitPercent) {
                            res = false;
                            outUSDT = 0;
                        } else {
                            res = true;
                            outUSDT = sd.usdtAmount*sd.profitPercent - rottedAmount;
                        }
                    }
                    if(res) {
                        outAmount = PairPrice(moduleMgr.getPairPrice()).cumulateMUTAmountOut(outUSDT);
                    }
                }
            }
        }
    }

    function updateLastClaimTime(uint32 sowId, uint256 beginCulTime) external onlyCaller {
        uint32 roundNumber = mapSowIdRoundNumber[sowId];
        if(roundNumber > 0) {
            SowData storage sd = mapSowData[roundNumber];
            sd.lastClaimTime = beginCulTime;
        }
    }

    function getSowData(uint32 roundNumber) external view returns (
        bool res, 
        uint32 sowId,
        address account,
        uint256 sowAmount,
        uint256 usdtAmount
    )
    {
        if(mapSowData[roundNumber].sowAmount > 0) {
            res = true;
            sowId = mapSowData[roundNumber].sowId;
            account = mapSowData[roundNumber].account;
            sowAmount = mapSowData[roundNumber].sowAmount;
            usdtAmount = mapSowData[roundNumber].usdtAmount;
        }
    }

    function getUserSowData(address account, uint32 sowId) 
        external 
        view 
        returns (
            bool res,
            uint256 sowAmount,
            uint256 usdtAmount
        ) 
    {
        uint32 roundNumber = mapSowIdRoundNumber[sowId];
        if(roundNumber > 0) {
            SowData memory sd = mapSowData[roundNumber];
            if(account == sd.account){
                res = true;
                sowId = sd.sowId;
                sowAmount = sd.sowAmount;
                usdtAmount = sd.usdtAmount;
            }
        }
    }

    function setWithdrawStatus(uint32 withdrawId, bool status) external onlyCaller {
        mapWithdrawStatus[withdrawId] = status;
    }

    function getWithdrawStatus(uint32 withdrawId) external view returns (bool status) {
        status = mapWithdrawStatus[withdrawId];
    }
}