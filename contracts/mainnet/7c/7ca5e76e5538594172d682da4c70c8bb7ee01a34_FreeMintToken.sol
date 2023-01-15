// SPDX-License-Identifier: MIT
// Made by @Crypto974
//Address contract mainnet: 0x7ca5E76E5538594172d682Da4c70c8bB7eE01a34
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract FreeMintToken is ERC721A {

    uint256 public constant MAX_SUPPLY = 10000;

    constructor(string memory baseuri) ERC721A("Nasty puppies", "NPNFT") 
    {
         bytes memory EmptyStringTest = bytes(baseuri);
        require(EmptyStringTest.length>0, "You must set ipfs path");
        SetBaseURI(baseuri);
    }

    function mint(uint256 quantity) external {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not more supply left");
        // add allowlist verification here
        _mint(msg.sender, quantity);
    }

}