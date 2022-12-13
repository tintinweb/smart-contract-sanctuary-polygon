/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract dummyDataStorage {
    address public ownerAddress;

    // Grouping together the Jewellery Data.
    struct Jewellery{
        uint256 tokenId;
        string netWeight;
        string grossWeight;
        string purity;
        string ownerName;
    }

    struct Valuations{
        string valuerName;
        string valuationOrganization;
        string purity;
        string netWeight;
        string grossWeight;
        string deductions;
        uint256 price;
        uint256 valuationId;
    }

    // Mapping Jewellery Data against an ID.
    mapping(uint256 => Jewellery) public JewelleryData;

    mapping(uint256 => Valuations) public ValuationsData;

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
    function storeData
    (   uint256 _tokenId,
        string memory _netWeight, 
        string memory _grossWeight, 
        string memory _purity, 
        string memory _ownerName
    )
        onlyOwner(msg.sender) 
        public 
    {
        Jewellery memory jewellery;
        jewellery.tokenId = _tokenId;
        jewellery.netWeight = _netWeight;
        jewellery.grossWeight = _grossWeight;
        jewellery.purity = _purity;
        jewellery.ownerName = _ownerName;

        JewelleryData[_tokenId]  = jewellery;
    }

    // Example Function to Set Jewellery's Valuation.
    function setValuation
    (
        uint256 _tokenId,
        string memory _valuerName,
        string memory _valuationOrganization,
        string memory _purity,
        string memory _netWeight,
        string memory _grossWeight,
        string memory _deductions,
        uint256 _price,
        uint256 _valuationId
    ) 
        public 
        onlyOwner(msg.sender)
    {
        Valuations memory valuations;
        valuations.valuerName = _valuerName;
        valuations.valuationOrganization = _valuationOrganization;
        valuations.purity = _purity;
        valuations.netWeight = _netWeight;
        valuations.grossWeight = _grossWeight;
        valuations.deductions = _deductions;
        valuations.price = _price;
        valuations.valuationId = _valuationId;

        ValuationsData[_tokenId] = valuations;
    }

    // Example Function to update jewellery's net weight.
    function updateNetWeight
    (   
        uint256 _tokenId, 
        string memory _netWeight
    )
        onlyOwner(msg.sender)
        public
    {
        JewelleryData[_tokenId].netWeight = _netWeight;
    }

    // Example Function to update jewellery's current market gold price.
    function updateMarketPrice
    (   
        uint256 _tokenId, 
        uint256 _price
    )
        onlyOwner(msg.sender)
        public
    {
        ValuationsData[_tokenId].price = _price;
    }
}