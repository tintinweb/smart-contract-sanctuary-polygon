// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RadesRare {
    struct rare {
        uint256 minimumBid;
        uint256 bidUnit;
        uint256 itemAvailable;
        uint256 royalty;
        address creator;
        bool sold;
    }

    struct rareParam {
        uint256 minimumBid;
        uint256 bidUnit;
        uint256 itemAvailable;
        uint256 royalty;
    }

    address private radesMarketplace = address(0);

    modifier isCalledMarketplace() {
        require(radesMarketplace == msg.sender, "Invalid");
        _;
    }

    mapping (uint256 => rare) private lists;
    mapping (uint256 => mapping(address => uint256)) owners;

    function setMarketplaceToRare(address _radesMarketplace) external {
        require(radesMarketplace == address(0), "Invalid Rare");
        radesMarketplace = _radesMarketplace;
    }

    function addRadesRare(uint256 _newId, rareParam memory _rareParam, address _creator, bool _sold) external isCalledMarketplace {
        lists[_newId] = rare (
            _rareParam.minimumBid,
            _rareParam.bidUnit,
            _rareParam.itemAvailable,
            _rareParam.royalty,
            _creator,
            _sold
        );

        owners[_newId][_creator] = 1;
    }

    function updateOwner(uint256 _nftId, address _owner, uint256 _index) external isCalledMarketplace {
        owners[_nftId][_owner] = _index;
    }

    function updateRades(uint256 _nftId, bool _sold) external isCalledMarketplace {
        lists[_nftId].sold = _sold;
    }

    function fetchRare(uint256 _nftId) external view returns(rare memory) {
        return lists[_nftId];
    }

    function checkOwner(uint256 _nftId , address _owner) external view returns(bool) {
        if(owners[_nftId][_owner] > 0) return true ;
        return false ;
    }
}