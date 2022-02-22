// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GeoLocation {
    struct Location {
        uint256 lat;
        uint256 long;
        string metadataUrl;
    }

    event LocationAdded(
        uint256 indexed id,
        uint256 lat,
        uint256 long,
        string metadataUrl
    );

    mapping(uint256 => Location) private plantLocation;

    address public allelePlantCoreContract;

    uint16 public decimals = 18;

    constructor(address owner) {
        allelePlantCoreContract = owner;
    }

    function getLocation(uint256 _tokenId)
        external
        view
        returns (Location memory)
    {
        return plantLocation[_tokenId];
    }

    function setLocation(
        uint256 _tokenId,
        uint256 lat,
        uint256 long,
        string memory metadataUrl
    ) external {
        require(
            allelePlantCoreContract == msg.sender,
            "Geolocation: caller is not owner"
        );
        plantLocation[_tokenId] = Location({
            lat: lat,
            long: long,
            metadataUrl: metadataUrl
        });

        emit LocationAdded(_tokenId, lat, long, metadataUrl);
    }
}