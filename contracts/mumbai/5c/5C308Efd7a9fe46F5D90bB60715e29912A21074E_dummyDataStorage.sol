/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract dummyDataStorage {
    address public ownerAddress;

    // Grouping together the Jewellery Data.
    struct _fnft{
        uint256 tokenId;
        string netWeight;
        string grossWeight;
        string purity;
        string ownerName;
    }

    // Mapping Jewellery Data against an ID.
    mapping(uint256 => _fnft) public FNFT;

    // Constructor to set the contract's owner address.
    constructor(){
        ownerAddress = msg.sender;
    }

    // Modifier to confirm that function is accessible by none other than the owner.
    modifier onlyOwner(address _ownerAddress){
        require(ownerAddress == _ownerAddress, "Only accessible by owner!");
        _;
    }

    // Example Function to store jewellery's data.
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

    // Example Function to update jewellery's net weight.
    function updateNetWeight(uint256 _tokenId, string memory _netWeight)
        onlyOwner(msg.sender)
        public
    {
        FNFT[_tokenId].netWeight = _netWeight;
    }
}