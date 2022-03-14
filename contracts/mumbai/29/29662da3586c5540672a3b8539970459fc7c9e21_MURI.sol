//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract MURI is ERC721URIStorage, ERC721Burnable, Ownable {
    enum ContractStatus {
        Public,
        AllowListOnly,
        Paused
    }

    // Contract control
    ContractStatus public contractStatus = ContractStatus.Paused;
    string public auctionTimestamp;
    bytes32 public merkleRoot;


    // Tokenization
    string  public baseURI;
    uint256 public price = 0.0001 ether;
    uint256 public totalSupply = 10000;
    uint256 public publicCurrentSupply = 2203;

    // Counters
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;
    mapping(address => uint256) public quantityMintedPublic;
    mapping(address => uint256) public quantityMintedPrivate;

    constructor(bytes32 _merkleRoot, string memory contractBaseURI)
    ERC721 ("MURI", "MURI") {
        merkleRoot = _merkleRoot;
        baseURI = contractBaseURI;
        tokenCounter.increment();
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mintPublic(uint256 quantity) public payable {
        require(contractStatus == ContractStatus.Public, "Public minting not available"); 
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(tokenCounter.current() + quantity <= publicCurrentSupply + 1, "Not enough supply");
        require(quantityMintedPublic[msg.sender] + quantity <= 3, "Exceeds allowed wallet quantity");

        quantityMintedPublic[msg.sender] = quantityMintedPublic[msg.sender] + quantity;

        mintQuantity(quantity);
    }

    function mintPrivate(uint256 quantity, uint256 allowedQuantity, bytes32[] calldata proof) public payable {
        require(contractStatus == ContractStatus.AllowListOnly, "Private minting not available");
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(canMintPrivate(msg.sender, allowedQuantity, proof), "Failed wallet verification");
        require(quantityMintedPrivate[msg.sender] + quantity <= allowedQuantity, "Exceeds allowed wallet quantity");

        quantityMintedPrivate[msg.sender] = quantityMintedPrivate[msg.sender] + quantity;

        mintQuantity(quantity);
    }

    function mintQuantity(uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenCounter.current());
            _setTokenURI(tokenCounter.current(), Strings.toString(tokenCounter.current()));

            tokenCounter.increment();
        }
    }

    function canMintPrivate(address account, uint256 allowedQuantity, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, generateMerkleLeaf(account, allowedQuantity));
    }

    function generateMerkleLeaf(address account, uint256 allowedQuantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowedQuantity));
    }

    function setPrice(uint256 desiredPrice, string memory timestamp) public onlyOwner {
        price = desiredPrice;
        auctionTimestamp = timestamp;
    }

    function setContractStatus(ContractStatus status) public onlyOwner {
        contractStatus = status;
    }

    function getQuantityMinted() public view returns (uint256) {
        return tokenCounter.current();
    }

    function getPublicMintedForAddress(address account) public view returns (uint256) {
        return quantityMintedPublic[account];
    }

    function getPrivateMintedForAddress(address account) public view returns (uint256) {
        return quantityMintedPrivate[account];
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPublicCurrentSupply(uint256 supply) public onlyOwner {
        publicCurrentSupply = supply;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(0x187e979dE20cDD8178FC327AA650aEc0Fec5d350);
        address yw = payable(0x6905669F02ADbbde7D85C29A13847664699C9ea6);

        bool success;

        (success, ) = h.call{value: (sendAmount * 820/1000)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = yw.call{value: (sendAmount * 180/1000)}("");
        require(success, "Transaction Unsuccessful");
    }
}