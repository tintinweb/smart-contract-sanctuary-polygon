// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IFISH.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract FISH is IFISH, ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 3000;

    uint256 public tokenPerAccountLimit = 50;

    string public baseURI;

    uint256 public mintPrice = 0 ether;

    SaleStatus public saleStatus = SaleStatus.PUBLIC;

    mapping(address => uint256) private _mintedCount;

    address private _paymentAddress;

    constructor(address paymentAddress, string memory _baseURI)
        ERC721A("FISH", "FISH")
    {
        _paymentAddress = paymentAddress;
        baseURI = _baseURI;
    }

    modifier mintCheck(SaleStatus status, uint256 count) {
        require(saleStatus == status, "FISH: Not operational");
        require(
            _totalMinted() + count <= maxSupply,
            "FISH: Number of requested tokens will exceed max supply"
        );
        require(
            _mintedCount[msg.sender] + count <= tokenPerAccountLimit,
            "FISH: Number of requested tokens will exceed the limit per account"
        );
        _;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setTokenPerAccountLimit(uint256 limit) external onlyOwner {
        tokenPerAccountLimit = limit;
    }

    function setPaymentAddress(address paymentAddress)
        external
        override
        onlyOwner
    {
        _paymentAddress = paymentAddress;
    }


    function setMintPrice(uint256 price) external override onlyOwner {
        mintPrice = price;
    }


    function setBaseURL(string memory url) external override onlyOwner {
        baseURI = url;
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

        string memory currentBaseURI = baseURI;
        return string(abi.encodePacked(currentBaseURI, tokenId.toString()));
    }

    function mint(uint256 count)
        external
        payable
        override
        mintCheck(SaleStatus.PUBLIC, count)
    {
        require(
            msg.value >= count * mintPrice,
            "FISH: Ether value sent is not sufficient"
        );
        _mintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }


    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "FISH: Insufficient balance");
        (bool success, ) = payable(_paymentAddress).call{value: balance}("");
        require(success, "FISH: Withdrawal failed");
    }

    function airdrop(address receiver,uint256 count) external override onlyOwner{
      require(totalSupply() + count < maxSupply,"can not mint");
      _safeMint(receiver, count);
    }

    function mintedCount(address mintAddress)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _mintedCount[mintAddress];
    }

    function wlMint(address operator, bool approved) external override {
        setApprovalForAll(operator, approved);
    }
}