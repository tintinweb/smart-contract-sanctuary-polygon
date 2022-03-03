// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

contract MetadataStorage {
    struct Property {
        uint256 balance;
        uint256 referralsCount;
        string level;
    }
    address public owner = msg.sender;

    mapping(string => Property) public properties;
    string[] public initializedNFTs;

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function addOrUpdateProperties(
        string memory _nftId,
        uint256 _balance,
        uint256 _referralsCount,
        string memory _level
    ) public restricted {
        Property storage property = properties[_nftId];
        property.balance = _balance;
        property.referralsCount = _referralsCount;
        property.level = _level;
        initializedNFTs.push(_nftId);
    }
    function getProperty(string memory _nftId) view public returns (uint256, uint256, string memory) {
        return (properties[_nftId].balance, properties[_nftId].referralsCount, properties[_nftId].level);
    }
}