// SPDX-License-Identifier: GPL-3.0
/*
*  is good
*  is the new DAO
*/
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Test123 is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseExtension = ".json";
    string public baseURI;
    uint256 public constant maxNFT = 138;
    bool public paused = false;

    constructor() ERC721("SuperApe Army69", "SuperApe Army69") {
        setBaseURI("ipfs://QmTUzEY2W1jb6beL8fHB1dCCv7dS2i5aUGZ7Vr5g5EGj6k/");
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function Mint69() public payable onlyOwner {
        uint256 supply = totalSupply();
        unchecked { 
            require(supply + 23 <= maxNFT, 'MAX_REACHED'); 
            require(!paused);
        }
        if (supply == 0){
            for (uint256 i = 1; i <= 23; i++) {
                _safeMint(msg.sender, supply + i);
            }
        }

        if (supply >0){
            for (uint256 i = (supply + 1); i <= (supply + 23); i++) {
                _safeMint(msg.sender, i);
            }
        }
       
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
}