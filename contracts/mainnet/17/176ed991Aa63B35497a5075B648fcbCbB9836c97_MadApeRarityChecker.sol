// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract MadApeRarityChecker is Ownable{
    struct Range {
        uint256 lowerBound;
        uint256 upperBound;
        uint256 multiplier;
    }

    uint256 internal levels;
    mapping(uint256 => uint256) internal rarity;
    mapping(uint256 => Range) internal rarityMultipliers;

    constructor(){
    }

    function setRarity(uint256 _tokenId, uint256 _rarity) public onlyOwner{
        rarity[_tokenId] = _rarity;
    }

    function setMultiRarity(uint256[] memory _tokenIds, uint256[] memory _rarity) public onlyOwner{
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            rarity[_tokenIds[i]] = _rarity[i];
        }
    }

    function setMultipliers(uint256 _levels, uint256[] memory _lowerBounds, uint256[] memory _upperBounds, uint256[] memory _multipliers) public onlyOwner{
        levels = _levels;
        for (uint256 i = 0; i < _levels; i++) {
            Range storage range = rarityMultipliers[i];
            range.lowerBound = _lowerBounds[i];
            range.upperBound = _upperBounds[i];
            range.multiplier = _multipliers[i];
        }
    }

    function getRarity(uint256 tokenId) view public returns (uint256){
        return rarity[tokenId];
    }

    function getMultipliers() view public returns (uint256[] memory){
        uint256[] memory multipliers = new uint256[](levels);
        for (uint256 i = 0; i < levels; i++) {
            multipliers[i] = rarityMultipliers[i].multiplier;
        }
        return multipliers;
    }

    function getMultiplierForTokenId(uint256 tokenId) view public returns (uint256){
        uint256 tokenRarity = rarity[tokenId];
        for (uint256 i = 0; i < levels; i++) {
            uint256 lowerBound = rarityMultipliers[i].lowerBound;
            uint256 upperBound = rarityMultipliers[i].upperBound;
            if (lowerBound <= tokenRarity && tokenRarity <= upperBound) {
                return rarityMultipliers[i].multiplier;
            }
        }
        revert("Should have found a multiplier");
    }
}