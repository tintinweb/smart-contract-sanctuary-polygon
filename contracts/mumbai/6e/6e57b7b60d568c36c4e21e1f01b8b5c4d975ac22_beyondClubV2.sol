/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract beyondClubV2 {

    uint public totalBrands = 0;
    uint public totalCampaigns = 0;

    mapping (string => address) usernameToAddress;
    // mapping (string => uint) brandId;
    mapping (string => string) brandHash;
    mapping (string => uint) campaignPerBrand;
    mapping (string => mapping(uint => string)) brandCampaignName;
    mapping (string => mapping(uint => string)) brandCampaignHashes;

    
    event brandHashCreated (
        string username,
        string hash,
        address brandAddress
    );

    event campaignCreated (
        string _username,
        string _hash,
        string _name
    );

    function brandOwner (string memory _username) public view returns (address) {
        return (usernameToAddress[_username]);
    }

    function getBrandHash(string memory _username) public view returns (string memory) {
        return brandHash[_username];
    }

    function usernameAvailable (string memory _username) public view returns (bool) {
        if (usernameToAddress[_username] == address(0)) {
            return true;
        }
        else return false;
    }

    function createBrand (string memory _username) public {
        totalBrands++;
        usernameToAddress[_username] = msg.sender;
        campaignPerBrand[_username] = 0;
    }
    
    function setBrandHash (string memory _username, string memory _hash) public {
        brandHash[_username] = _hash;
        emit brandHashCreated(_username, _hash, usernameToAddress[_username]);
    }
    function newCampaign (string memory _brand, string memory _campaignHash, string memory _campaignName) public {
        campaignPerBrand[_brand]++;
        totalCampaigns++;
        brandCampaignName[_brand][campaignPerBrand[_brand]] = _campaignName;
        brandCampaignHashes[_brand][campaignPerBrand[_brand]] = _campaignHash;
        emit campaignCreated(_brand, _campaignHash, _campaignName);
    }

    // function checkCampaigns (string memory _brand, uint i) public view returns (string memory) {
    //     return campaignHashes[_brandId][i];
    // }

    function checkNumberOfCampaigns (string memory _brand) public view returns (uint) {
        return campaignPerBrand[_brand];
    }

}