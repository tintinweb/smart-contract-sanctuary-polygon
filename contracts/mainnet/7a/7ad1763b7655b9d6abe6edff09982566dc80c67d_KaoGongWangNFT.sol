// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";

// KaoGongWang.com (考公网) creates 3,000 SYG (师医公) NFTs.
// All NFTs are permanently frozen as files on IPFS.
// Minting is free.
// See https://kaogongwang.com/nft_v1/ for more details.

contract KaoGongWangNFT is ERC721 {

    uint256 public constant SHI_BEGIN = 0;
    uint256 public constant YI_BEGIN = 1000;
    uint256 public constant GONG_BEGIN = 2000;

    uint256 public SHI_SUPPLY = 0;
    uint256 public YI_SUPPLY = 0;
    uint256 public GONG_SUPPLY = 0;

    uint256 public MAX_SUPPLY_EACH = 1000;

    function _baseURI() override internal view virtual returns (string memory) {
        return "ipfs://Qmf5vUUdY3V5xBDCCuxG5dtV7JN6uLdkb9TSE1hb5JfsPF/";
    }

    constructor() ERC721("KaoGongWangNFT", "SYG") {}

    function mintSHI(address to) public {
        require(SHI_SUPPLY < MAX_SUPPLY_EACH);
        _mint(to, SHI_BEGIN + SHI_SUPPLY);
        SHI_SUPPLY++;
    }

    function mintYI(address to) public {
        require(YI_SUPPLY < MAX_SUPPLY_EACH);
        _mint(to, YI_BEGIN + YI_SUPPLY);
        YI_SUPPLY++;
    }

    function mintGONG(address to) public {
        require(GONG_SUPPLY < MAX_SUPPLY_EACH);
        _mint(to, GONG_BEGIN + GONG_SUPPLY);
        GONG_SUPPLY++;
    }

    function mintSYG(address to) public {
        mintSHI(to);
        mintYI(to);
        mintGONG(to);
    }
}