pragma solidity ^0.8.10;
// SPDX-License-Identifier: Unlicensed

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Strings.sol";
import "Guard.sol";
import "VRFConsumerBase.sol";

contract ProjE is VRFConsumerBase, ERC721Enumerable, Ownable, Guard  {
    using Strings for uint256;

    bytes32 internal keyHash;
    uint256 internal fee = 0.0001 * 10 ** 18;

    uint256 public linkVRFOffset;
    string public baseURI;

    string public attributesZipHash;

    //settings
    uint256 public maxSupply = 2000;
    bool public publicStatus = true;

    event VRFOffsetSet(uint vrfResult, bytes32 requestId);
    event AttributesZipHashSet(string attributesZipHash);
    event FreeMintComplete();

    //token
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        bytes32 _keyHash
    )
    VRFConsumerBase(
        0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
    )
    ERC721(_name, _symbol){
        setURI(_initBaseURI);
        keyHash = _keyHash;
    }

    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK!");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 s = totalSupply();
        linkVRFOffset = randomness % s;
        emit VRFOffsetSet(linkVRFOffset, requestId);
    }

    function setAttributesZipHash(string memory _zipHash) external onlyOwner {
        attributesZipHash = _zipHash;
        emit AttributesZipHashSet(attributesZipHash);
    }

    function airdrop(address[] memory airdropList) public onlyOwner {
        uint s = totalSupply();
        require (s + airdropList.length <= maxSupply, "Exceeded max supply!");
        for (uint i = 0; i < airdropList.length; i++) {
            _safeMint(airdropList[i], s + i, "");
        }
        emit FreeMintComplete();
    }

    //read metadata
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= maxSupply, "Token ID out of bounds!");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    //write metadata
    function setURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}