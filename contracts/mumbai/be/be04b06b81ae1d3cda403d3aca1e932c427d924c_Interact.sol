/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Ischolarmarketplace {
    function hireScholar(address, uint256, uint256, uint256, uint256) external;
    function respondOffer(uint256, uint256) external;
    function cancelOffer(uint256) external;
    function settleNFT(uint256) external;
    function updateMatch(address[] memory, uint256[] memory, bool[] memory) external;
    function startMatch(uint256, uint256) external;
    function createMatch() external;
    function rewardDistribution(uint256[] memory, uint256) external;
    function getReward() external;
}

contract Interact {
    address _scholarmarketplace;

    constructor(address scholarmarketplace){
        _scholarmarketplace = scholarmarketplace;
    }

    function _hireScholar(address wallet, uint256 nftId, uint256 matchFee, uint256 matchesAllowed, uint256 stopLoss ) external {
        Ischolarmarketplace(_scholarmarketplace).hireScholar(wallet, nftId, matchFee, matchesAllowed, stopLoss);
    }

    function _respondOffer(uint256 nftid, uint256 reponse) external {
        Ischolarmarketplace(_scholarmarketplace).respondOffer(nftid, reponse);
    }

    function _cancelOffer(uint256 nftid) external {
        Ischolarmarketplace(_scholarmarketplace).cancelOffer(nftid);
    }

    function _settleNFT(uint256 nftid) external {
        Ischolarmarketplace(_scholarmarketplace).settleNFT(nftid);
    }

    function _updateMatch(address[] memory wallet, uint256[] memory nftId, bool[] memory won) external {
        Ischolarmarketplace(_scholarmarketplace).updateMatch(wallet, nftId, won);
    }

    function _startMatch(uint256 nftid, uint256 matchid) external {
        Ischolarmarketplace(_scholarmarketplace).startMatch(nftid, matchid);
    }

    function _createMatch() external {
        Ischolarmarketplace(_scholarmarketplace).createMatch();
    }

    function rewardsDistribution(uint256[] memory nftid, uint256 matchid) external {
        Ischolarmarketplace(_scholarmarketplace).rewardDistribution(nftid, matchid);
    }

    function getRewards() external {
        Ischolarmarketplace(_scholarmarketplace).getReward();
    }
}