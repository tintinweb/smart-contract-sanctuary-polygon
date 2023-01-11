// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ChallengeDetail.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract HistoryChallenges{
    using SafeMath for uint256;

    function challengesInfo1(address payable _contractChallengeAddress) public view returns(
        address sponsor,
        address challenger,
        uint256 challengeStart,
        uint256 challengeEnd,
        uint256 challengeDays,
        uint256 targetChallenge,
        uint256 minimumAchievementDays,
        uint256[] memory awardReceiversPercent,
        address payable[] memory awardReceivers
    ){
        sponsor = ChallengeDetail(_contractChallengeAddress).sponsor();
        challenger = ChallengeDetail(_contractChallengeAddress).challenger();
        challengeStart = ChallengeDetail(_contractChallengeAddress).startTime();
        challengeEnd = ChallengeDetail(_contractChallengeAddress).endTime();
        challengeDays = ChallengeDetail(_contractChallengeAddress).duration();
        targetChallenge = ChallengeDetail(_contractChallengeAddress).goal();
        minimumAchievementDays = ChallengeDetail(_contractChallengeAddress).dayRequired();
        awardReceiversPercent = ChallengeDetail(_contractChallengeAddress).getAwardReceiversPercent();
        awardReceivers = ChallengeDetail(_contractChallengeAddress).getAwardReceivers();
    }

    function challengesInfo2(address payable _contractChallengeAddress) public view returns(
        uint256 depopsitMatic, uint256 depopsitTTJP, uint256 depopsitJPYC, 
        uint256 indexNft, address contractChallengeAddress, 
        address contractNftAddress, uint256 chainId, uint256 challengeResult
    ){  
        bool isChallengeSuccess = ChallengeDetail(_contractChallengeAddress).isSuccess();
        if(isChallengeSuccess) {
            assembly {
                chainId := chainid()
            }
            
            address[] memory erc20ListAddress = ChallengeDetail(_contractChallengeAddress).allContractERC20();

            if(ChallengeDetail(_contractChallengeAddress).allowGiveUp(1)) {
                return(
                    ChallengeDetail(_contractChallengeAddress).totalReward(),
                    0,
                    0,
                    ChallengeDetail(_contractChallengeAddress).indexNft(),
                    _contractChallengeAddress,
                    ChallengeDetail(_contractChallengeAddress).erc721Address(0),
                    chainId,
                    1
                );
            } else {
                if(compareStrings(ERC20(erc20ListAddress[0]).symbol(), "TTJP")) {
                    return(
                        0,
                        ChallengeDetail(_contractChallengeAddress).totalReward(),
                        0,
                        ChallengeDetail(_contractChallengeAddress).indexNft(),
                        _contractChallengeAddress,
                        ChallengeDetail(_contractChallengeAddress).erc721Address(0),
                        chainId,
                        1
                    );
                } else {
                    return(
                        0,
                        0,
                        ChallengeDetail(_contractChallengeAddress).totalReward(),
                        ChallengeDetail(_contractChallengeAddress).indexNft(),
                        _contractChallengeAddress,
                        ChallengeDetail(_contractChallengeAddress).erc721Address(0),
                        chainId,
                        1
                    );
                }
            }
        }
        
    }

    function getHistoryTokenAndCoinSendToContract(address payable _contractChallengeAddress) public view returns(
        uint256, 
        uint256, 
        uint256[] memory, 
        uint256[] memory,
        string[] memory
    ) {
        bool isCoinChallenges = ChallengeDetail(_contractChallengeAddress).allowGiveUp(1);
        uint256 totalReward = ChallengeDetail(_contractChallengeAddress).totalReward();
        address[] memory erc20ListAddress = ChallengeDetail(_contractChallengeAddress).allContractERC20();
        uint256[] memory tokenBalanceBefor = new uint256[](erc20ListAddress.length); 
        string[] memory listTokenSymbol = new string[](erc20ListAddress.length); 
        uint256[] memory tokenBalanceAfter = new uint256[](erc20ListAddress.length); 
        uint256 contractBalance = ChallengeDetail(_contractChallengeAddress).getContractBalance();
        if(isCoinChallenges) {
            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                tokenBalanceAfter[i] = ERC20(erc20ListAddress[i]).balanceOf(_contractChallengeAddress);
                listTokenSymbol[i] = ERC20(erc20ListAddress[i]).symbol();
            }
            
            uint256 balanceContract;

            if(contractBalance > totalReward) {
                balanceContract = contractBalance.sub(totalReward);
            }
            
            if(ChallengeDetail(_contractChallengeAddress).isChallengeFinish()) {
                uint256 balanceMatic = ChallengeDetail(_contractChallengeAddress).totalBalanceBaseToken();
                uint256[] memory balanceToken = ChallengeDetail(_contractChallengeAddress).getBalanceToken();
                return(totalReward, balanceMatic.sub(totalReward), tokenBalanceBefor, balanceToken, listTokenSymbol);
            } else {
                return(totalReward, balanceContract, tokenBalanceBefor, tokenBalanceAfter, listTokenSymbol);
            }
        } else {
            address payable challengeAddress = _contractChallengeAddress;
            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                listTokenSymbol[i] = ERC20(erc20ListAddress[i]).symbol();
                uint256 balance = ERC20(erc20ListAddress[i]).balanceOf(challengeAddress);
                if(i == 0) {
                    tokenBalanceBefor[i] = totalReward;

                    if(tokenBalanceAfter[i] > totalReward) {
                        tokenBalanceAfter[i] = balance.sub(totalReward);
                    }
                } else {
                    tokenBalanceAfter[i] = balance;
                }
            }

            if(ChallengeDetail(_contractChallengeAddress).isChallengeFinish()) {
                uint256 balanceMatic = ChallengeDetail(_contractChallengeAddress).totalBalanceBaseToken();
                uint256[] memory balanceToken = ChallengeDetail(_contractChallengeAddress).getBalanceToken();
                balanceToken[0] = balanceToken[0].sub(totalReward);
                return(0, balanceMatic, tokenBalanceBefor, balanceToken, listTokenSymbol);
            } else {
                return(0, contractBalance, tokenBalanceBefor, tokenBalanceAfter, listTokenSymbol);
            }
        }
    }


    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}