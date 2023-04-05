// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Picart855 is ERC721, Ownable {
    using Strings for uint256;

    //ERC4906
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    //max supply
    uint256 public MAX_SUPPLY_HARICOT = 55;

    uint256 public MAX_SUPPLY_RAINBOW_CAKE = 800;

    //current minted supply
    uint256 public rainbowSupply;

    uint256 public haricotSupply;

    uint256 public burnCount;

    //address allowed to drop
    address public dropperAddress;

    //metadatas
    string public baseURI = "https://app-8ec647a1-8043-4245-bac1-2dd4dcd66592.cleverapps.io/metadatas/picart855/";

    constructor()
    ERC721("Nos premiers NFTs gourmands et surprenants exclusivement pour nos collaborateurs !", "PICART855")
        {
        }

    //utility functions
    function totalSupply() external view returns (uint256) {
        return haricotSupply + rainbowSupply - burnCount;
    }

    //drop functions
    function dropHaricots(address[] calldata targetAddresses) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        uint256 count = targetAddresses.length;
        require(haricotSupply+count<=MAX_SUPPLY_HARICOT, "supply limit reached");
        unchecked {
            for(uint256 i=0;i<count;i++){
                _mint(targetAddresses[i], ++haricotSupply);
            }
        }
    }

    function dropRainbows(address[] calldata targetAddresses) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        uint256 count = targetAddresses.length;
        require(rainbowSupply+count<=MAX_SUPPLY_RAINBOW_CAKE, "supply limit reached");
        unchecked {
            for(uint256 i=0;i<count;i++){
                _mint(targetAddresses[i], ++rainbowSupply + MAX_SUPPLY_HARICOT);
            }
        }
    }

    //burn functions
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId)!=address(0), "unexistant token");
        require(msg.sender==ownerOf(tokenId) || msg.sender == owner(), "sender not owner");
        burnCount++;
        _burn(tokenId);
    }

    //admin functions
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setDropper(address _dropperAddress) external onlyOwner {
        dropperAddress = _dropperAddress;
    }

    //metadatas functions
    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function contractURI() public view
        returns (string memory)
    {
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    //ERC4906
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    //transfer disabled
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        require(to==address(0)||from==address(0), "transfer not allowed");
    }


}