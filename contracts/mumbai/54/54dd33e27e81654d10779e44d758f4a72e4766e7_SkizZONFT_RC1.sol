// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract SkizZONFT_RC1 is ERC721Tradable {  
    
    constructor(address _proxyRegistryAddress) ERC721Tradable("SkizZO Squares NFT", "SkN", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "ipfs://QmaEEo7zyoqQx59NBERcByLL6Bf3xcpTQfQ2fN5VUPKLPk/";
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmaEEo7zyoqQx59NBERcByLL6Bf3xcpTQfQ2fN5VUPKLPk/contracturi.json";
    }
}