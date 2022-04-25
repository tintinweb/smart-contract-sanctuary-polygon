// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155.sol";
import "./Strings.sol";

contract RGBNFTs is ERC1155 {

    string private constant _name = "RGB Loopers";
    string private constant _symbol = "RGBLOOP";
    address private _owner;
    uint256 private constant _ntokens = 1000;
    string private constant _ipfs = "ipfs://QmVdxKaGp9ykwyvPGhH2gcFyz8avj1Wk15FM1LfPvBwbym/";

    constructor() ERC1155(string(abi.encodePacked(_ipfs, "{id}.json"))) {
        _owner = msg.sender;
        // for(uint256 i = 0 ; i < _ntokens ; i++){
        //     _mint(msg.sender,i,1,"");
        // }        
    }

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        require(tokenId < _ntokens,"Error! tokenId is bigger than available tokens");
        return string(
            abi.encodePacked(
                _ipfs,Strings.toHexStringNo0x(tokenId,32),".json"
            )            
        );                
    }
    
    function mintBatch(uint256 init, uint256 end) public {
        require(msg.sender == _owner, "only owner allowed");
        require(end < _ntokens,"end is bigger than total supply");
        for(uint256 i = init ; i <= end ; i++){
            _mint(msg.sender,i,1,"");
        }        
    }

    function close() public {
        require(msg.sender == _owner, "only owner allowed");
        selfdestruct(payable(_owner)); 
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function contractURI() public pure returns (string memory) {
        return "https://rgb-loopers.netlify.app/metadata/metadatargb.json";
    }
}