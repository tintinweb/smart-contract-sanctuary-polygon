/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Directory Reader for Martian Market using On-Chain Directory by 0xInuarashi.eth
// For use with Martian Market, and any other open interfaces built by anyone.

interface iOnChainDirectory {
    function addressToDiscord(address wallet_) external view returns (string memory);
    function addressToTwitter(address wallet_) external view returns (string memory);
}

interface iMartianMarketWL {
    function getWLPurchasersOf(address contract_, uint256 index_) external view 
    returns (address[] memory);
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

contract MartianMarketDirectory is Ownable {

    iOnChainDirectory public OCD = 
        iOnChainDirectory(0x88C6a2aDc73Aaf4A5E659d5f170480fcdc595532);
    iMartianMarketWL public MM = 
        iMartianMarketWL(0x189CFc2cAdEcbDf0f3E54310136beEEBE93EC477);

    function setOCD(address ocd_) external onlyOwner {
        OCD = iOnChainDirectory(ocd_);
    }
    function setMM(address mm_) external onlyOwner {
        MM = iMartianMarketWL(mm_);
    }

    function _getAddressToDiscord(address wallet_) internal view returns (string memory) {
        string memory _discord = OCD.addressToDiscord(wallet_);
        return bytes(_discord).length > 0 ? OCD.addressToDiscord(wallet_) : "Unknown";
    }  
    function _getAddressToTwitter(address wallet_) internal view returns (string memory) {
        string memory _twitter = OCD.addressToTwitter(wallet_);
        return bytes(_twitter).length > 0 ? OCD.addressToTwitter(wallet_) : "Unknown";
    }

    function getDiscordWLPurchasersOf(address contract_, uint256 index_) external view
    returns (string[] memory) {
        address[] memory _purchasers = MM.getWLPurchasersOf(contract_, index_);
        uint256 _length = _purchasers.length;

        string[] memory _discordPurchasers = new string[] (_length);
        uint256 _index;

        for (uint256 i = 0; i < _length; i++) {
            _discordPurchasers[_index++] = _getAddressToDiscord(_purchasers[i]);
        }

        return _discordPurchasers;
    }
    function getTwitterWLPurchasersOf(address contract_, uint256 index_) external view
    returns (string[] memory) {
        address[] memory _purchasers = MM.getWLPurchasersOf(contract_, index_);
        uint256 _length = _purchasers.length;

        string[] memory _twitterPurchasers = new string[] (_length);
        uint256 _index;

        for (uint256 i = 0; i < _length; i++) {
            _twitterPurchasers[_index++] = _getAddressToTwitter(_purchasers[i]);
        }

        return _twitterPurchasers;
    }
}