// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155.sol";

contract RGBNFTs is ERC1155 {

    constructor() ERC1155("ipfs://QmNrYQkYzgFmWKEAYfiDnoYHaWVFvoGSnVe1cuox7EpuzF/{id}.json") {
        for(uint256 i = 0 ; i < 10 ; i++){
            _mint(msg.sender,i,1,"");
        }        
    }
}