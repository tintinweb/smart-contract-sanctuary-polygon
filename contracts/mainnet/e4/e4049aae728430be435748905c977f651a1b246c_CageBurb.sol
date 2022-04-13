// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./IBurbCage.sol";



pragma solidity ^0.8.0;

contract CageBurb is
    Context,
    Ownable,
    ERC721Enumerable
{
    

    bool public tokenURIFrozen = false;
    string public baseTokenURI;

    string public contractURI;

    IBurbCage public immutable burbCage = IBurbCage(0xAa60011f71B82829df199a7E308F5070B9EBeeC2);

    mapping(uint256 => bool) public burbVisited;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        string memory contracturi
    ) ERC721(name, symbol) {
        baseTokenURI = uri;
        contractURI = contracturi;
    }
    
    function visitCagedBurb(uint256 burb) public {
        require(_msgSender() == burbCage.cagerOf(burb), "Only the cager can visit this burb.");
        require(!burbVisited[burb],"This burb has already been visited.");
        burbVisited[burb] = true;
        _safeMint(_msgSender(), burb);
    }
    
    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        baseTokenURI = uri;
    }
    
    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}