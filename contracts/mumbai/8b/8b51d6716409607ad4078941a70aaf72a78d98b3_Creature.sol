// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("NFT Collection", "OSC", _proxyRegistryAddress)
    {}


    function baseTokenURI() override public pure returns (string memory) {
        // return "https://ipfs.io/ipfs/QmX7LukhxPzyxcHgDq87DLDwX7PgDYxTQ98X2FQYYG4PVv/image_";
            return "https://storage.googleapis.com/not-collection/nftcollection/json/";

    }

    function contractURI() public pure returns (string memory) {
        return "https://storage.googleapis.com/not-collection/nftcollection/json/contract.json";
    }
}