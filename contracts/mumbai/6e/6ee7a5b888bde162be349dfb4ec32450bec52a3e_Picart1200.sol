// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Picart1200 is ERC721, Ownable {
    using Strings for uint256;

    //ERC4906
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    //max supply
    uint256 public MAX_SUPPLY_TAGLIATELLES = 30;

    uint256 public MAX_SUPPLY_SALADE_FRUITS = 64;

    uint256 public MAX_SUPPLY_MACARONS = 250;

    uint256 public MAX_SUPPLY_MOCHIS = 856;

    //current minted supply
    uint256 public tagliatellesSupply;

    uint256 public saladeFruitsSupply;

    uint256 public macaronsSupply;

    uint256 public mochisSupply;

    uint256 public burnCount;

    //address allowed to drop
    address public dropperAddress;

    //metadatas
    string public baseURI = "https://nft.picard.fr/nfts/metadatas/picart1200/";

    constructor()
    ERC721("Notre 1\u00E8re collection de NFTs d\u00E9barque dans le web 3.0 !", "PICART1200")
        {
        }

    //utility functions
    function totalSupply() external view returns (uint256) {
        return tagliatellesSupply + saladeFruitsSupply + macaronsSupply + mochisSupply - burnCount;
    }

    //drop functions
    function dropTagliatelles(address[] calldata targetAddresses) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        uint256 count = targetAddresses.length;
        require(tagliatellesSupply+count<=MAX_SUPPLY_TAGLIATELLES, "supply limit reached");
        unchecked {
            for(uint256 i=0;i<count;i++){
                _mint(targetAddresses[i], ++tagliatellesSupply);
            }
        }
    }

    function dropSaladesFruits(address[] calldata targetAddresses) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        uint256 count = targetAddresses.length;
        require(saladeFruitsSupply+count<=MAX_SUPPLY_SALADE_FRUITS, "supply limit reached");
        unchecked {
            for(uint256 i=0;i<count;i++){
                _mint(targetAddresses[i], ++saladeFruitsSupply + MAX_SUPPLY_TAGLIATELLES);
            }
        }
    }

    function dropMacarons(address[] calldata targetAddresses) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        uint256 count = targetAddresses.length;
        require(macaronsSupply+count<=MAX_SUPPLY_MACARONS, "supply limit reached");
        unchecked {
            for(uint256 i=0;i<count;i++){
                _mint(targetAddresses[i], ++macaronsSupply + MAX_SUPPLY_TAGLIATELLES + MAX_SUPPLY_SALADE_FRUITS);
            }
        }
    }

    function dropMochis(address[] calldata targetAddresses) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        uint256 count = targetAddresses.length;
        require(mochisSupply+count<=MAX_SUPPLY_MOCHIS, "supply limit reached");
        unchecked {
            for(uint256 i=0;i<count;i++){
                _mint(targetAddresses[i], ++mochisSupply + MAX_SUPPLY_TAGLIATELLES + MAX_SUPPLY_SALADE_FRUITS + MAX_SUPPLY_MACARONS);
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