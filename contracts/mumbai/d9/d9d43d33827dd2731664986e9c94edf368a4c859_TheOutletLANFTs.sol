// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "ERC721.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";
import {Ownable} from "Ownable.sol";
import "Counters.sol";
import "Strings.sol";
import "ERC2981.sol";
import "AggregatorV3Interface.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title  ExampleERC721
 * @notice This example contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval
 *         modifier to the approval methods ensures that owners do not approve operators that are not allowed.
 */
contract TheOutletLANFTs is ERC721, DefaultOperatorFilterer, Ownable, ERC2981 {
    using Strings for uint256;

    string public baseURI;
    using Counters for Counters.Counter;
    uint96 royaltyFeesInBips;
    address royaltyAddress;

    string public baseExtension = ".json";
    string public notRevealedUri;

    bool public paused = false;
    bool public public_mint_status = true;
    bool public revealed = true;

    uint256 public MAX_SUPPLY = 20;
    uint256 public publicSaleCostInUSD = 99922;
    string public contractURI;
    uint256 public totalSupply;

    Counters.Counter private _tokenIdCounter;
    AggregatorV3Interface internal priceFeed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory _contractURI,
        address _priceFeedAddress,
        address _deployer
      //  uint96 _royaltyFeesInBips
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        contractURI = _contractURI;
        royaltyAddress = owner();
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        owner_mint(_deployer,1);
    }

    function mint(address to, uint256 _mintAmount) public payable {

        require(public_mint_status, "Public mint not available");
        require(totalSupply + _mintAmount <= MAX_SUPPLY,"Maximum supply exceeds");

        //matic price for 1 NFT
        uint256 maticPricePerNFT = usdToEth(publicSaleCostInUSD/100);

            if (msg.sender != owner()) {
                require(msg.value >= maticPricePerNFT * _mintAmount);
            }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            
            if (!_exists(_tokenIdCounter.current())) {
                _safeMint(to, _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }

        }
        totalSupply = totalSupply + _mintAmount;
    }

    function owner_mint(address to, uint256 _mintAmount) public payable onlyOwner {

        require(totalSupply + _mintAmount <= MAX_SUPPLY,"Maximum supply exceeds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            
            if (!_exists(_tokenIdCounter.current())) {
                _safeMint(to, _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }

        }
        totalSupply = totalSupply + _mintAmount;
    }


    function ethToUsd(uint256 amount) public view returns (uint256) {
    return (amount * getLatestPrice()) / 10**(18); 
    }

    function usdToEth(uint256 amount) public view returns (uint256) {
    require(amount > 0, "Amount must be greater than 0");
    uint256 amountWithSlippage = (amount * 102) / 100;
    return (amountWithSlippage * 10**(24)) / getLatestPrice();
    }

  /**
    * Returns the latest price and # of decimals to use
    */
  function getLatestPrice() public view virtual returns (uint256) {
    int256 price;
    (, price, , , ) = priceFeed.latestRoundData();
    return uint256(price);
  }

    function withdraw() public payable onlyOwner {
        (bool main, ) = payable(owner()).call{value: address(this).balance}("");
        require(main);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setPublic_mint_status(bool _public_mint_status) external onlyOwner {
        public_mint_status = _public_mint_status;
    }

    function toggleReveal() external onlyOwner {
        if (revealed == false) {
            revealed = true;
        } else {
            revealed = false;
        }
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setPublicSaleCostInUSD(uint256 _publicSaleCostInUSD) external onlyOwner {
        publicSaleCostInUSD = _publicSaleCostInUSD;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function set_priceFeed(address _priceFeedAddress) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }
    
    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }
}