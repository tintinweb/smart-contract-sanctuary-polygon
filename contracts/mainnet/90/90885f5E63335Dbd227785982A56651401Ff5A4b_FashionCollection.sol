// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract FashionCollection is ERC721Enumerable, Ownable {
    string _baseTokenURI;

    constructor() ERC721("FashionCollection", "FASHION")  {
        _setBaseURI('https://spactio.com/api/fashion/metadata/');
        
        for(uint i = 0; i < 38; i++){
            _safeMint(_msgSender(), totalSupply());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function _setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
}