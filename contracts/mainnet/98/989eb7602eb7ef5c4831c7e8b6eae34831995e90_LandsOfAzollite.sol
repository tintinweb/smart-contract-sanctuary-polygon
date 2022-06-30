pragma solidity ^0.5.5;

import "./TRC721.sol";
import "./TRC721Enumerable.sol";
import "./TRC721MetadataMintable.sol";


contract LandsOfAzollite is TRC721, TRC721Enumerable, TRC721MetadataMintable {

    constructor() public TRC721Metadata("Lands Of Azollite", "LOAZLT") {
        TRC721Metadata._setBaseURI( "https://landsofazolite.com/api/nfts/");
    }

    // Metadata
    function setBaseURI(string memory uri) public onlyMinter  {
        TRC721Metadata._setBaseURI( uri );
    }

    // Transfer
    function setPause() public onlyMinter {
        TRC721.isPaused = !TRC721.isPaused;
    }
}