// SPDX-License-Identifier: MIT

// title: MonstarzMintPass
// author: sadat.pk

pragma solidity ^0.8.4;

import "./ERC721A.sol"; // importing some amazing standard contracts
import "./Ownable.sol";

contract MonstarzMintPass is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply; // 3500 for our favorite communities and a surprise 777 to random
    string private unUsedPasses ="ipfs://QmYgdTEwAdSLtFpa66xNRExc6xF77BoR9KfVbWffB39ivT/"; // un-used pass metadata
    string private usedPasses ="ipfs://QmNYdxjg4rWnCjUvsEVj8PpKhjo6ks6e6xTqohMdavaUMq/"; // used pass metadata
    string private openseaInfo = "ipfs://QmbeBssuQtWAiU6TShUu59KrKE5b3T4LN6WzWy2fGPRzZ4/"; // collection page metadata
    address private redeemer; // contract that can use these passes
    address private royaltyAddress = 0x2d4d806b60737422b66Dae8D83b60912e11821B3; // katmonstarz.eth
    uint96 private royaltyBasisPoints = 770; // 7.7%
    bytes4 private constant IERC2981 = 0x2a55205a; // royalty standard
    bool private endSupply = false; // stops the contract for further mints
    mapping(uint256 => bool) private used; // some paperwork to keep records
    constructor() ERC721A("MonstarzMintPass", "MMP") {}

    // Custom functions, to manage and configure stuff only be dev

    // airdrop a free mint pass each to given list of wallets
    function airdrop(address[] memory _addresses) external onlyOwner canMint {
        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], 1);
        }
    }

    // giveaway x number of free mint passes to given wallet
    function giveaway(address _address, uint256 _qty) external onlyOwner canMint {
        _safeMint(_address, _qty);

    }

    function setRoyalties(address _royaltyAddress, uint96 _royaltyBasisPoints) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setMetadata(string memory _unUsedURI, string memory _usedURI, string memory _osURI) external onlyOwner {
        unUsedPasses = _unUsedURI;
        usedPasses = _usedURI;
        openseaInfo = _osURI;
    }

    function setRedeemer(address _redeemer) external onlyOwner {
        redeemer = _redeemer;
    }

    function freezeContract() external onlyOwner {
        endSupply = true;
        maxSupply = totalSupply();
    }

    // Standard contract functions for marketplaces and dapps

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if (interfaceId == IERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return tokenId;
    }

    function baseTokenURI() external view returns (string memory) {
        return unUsedPasses;
    }

    function contractURI() public view returns (string memory) {
        return openseaInfo;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (used[tokenId]) {
            return usedPasses;
        }
        return unUsedPasses;
    }

    function walletOfOwner(address _address) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loop = totalSupply();
        for (uint256 i = 0; i < _loop; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == _address) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance -1] == 0) { _loop++; }
        }
        return _tokens;
    }

    // Custom functions for other contracts

    function setAsUsed(uint256 tokenId) external {
        require(msg.sender == redeemer, "Invalid caller");
        require(_exists(tokenId), "Nonexistent token");
        require(!used[tokenId], "Pass has been used");
        used[tokenId] = true;
    }

    function isUsed(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "Nonexistent token");
        return used[tokenId];
    }

    // Custom internal functions for contract

    modifier canMint() {
        require(endSupply == false, "its over");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}