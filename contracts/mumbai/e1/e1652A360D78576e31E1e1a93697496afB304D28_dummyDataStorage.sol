/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract dummyDataStorage {
    address public ownerAddress;

    struct _fnft{
        uint256 tokenId;
        string netWeight;
        string grossWeight;
        string purity;
        string ownerName;
    }

    mapping(uint256 => _fnft) public FNFT;

    constructor(){
        ownerAddress = msg.sender;
    }

    modifier onlyOwner(address _ownerAddress){
        require(ownerAddress == _ownerAddress, "Only accessible by owner!");
        _;
    }

    function storeData(uint256 _tokenId, string memory _netWeight, string memory _grossWeight, string memory _purity, string memory _ownerName)
        onlyOwner(msg.sender) public 
    {
        _fnft memory fnft;
        fnft.tokenId = _tokenId;
        fnft.netWeight = _netWeight;
        fnft.grossWeight = _grossWeight;
        fnft.purity = _purity;
        fnft.ownerName = _ownerName;

        FNFT[_tokenId]  = fnft;
    }
}