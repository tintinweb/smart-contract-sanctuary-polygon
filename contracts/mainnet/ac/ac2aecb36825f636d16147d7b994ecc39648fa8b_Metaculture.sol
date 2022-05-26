// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./AggregatorV3Interface.sol";

contract Metaculture is Ownable, ERC1155Supply {
    using Address for address payable;

    string public name = "Metaculture";

    string public symbol = "IMA META";

    mapping(uint256 => uint256) public maxSupplies;

    //address allowed to drop nfts
    address public dropperAddress;

    //address to withdraw funds
    address public fundsRecipient;

    mapping(uint256 => uint256) public pricesInEur;

    //matic to usd chainlink feed
    AggregatorV3Interface private maticToUsdFeed;

    //euro to usd chainlink feed
    AggregatorV3Interface private eurToUsdFeed;

    constructor(address _feedMaticUsdAddress, address _feedEurUsdAddress)
    ERC1155("ipfs://Qmbbfe1wiVDqXr5a8SqQNq7xRvsLJPcXktbEowHejKiFBw/{id}.json")
        {
            maticToUsdFeed = AggregatorV3Interface(_feedMaticUsdAddress);
            eurToUsdFeed = AggregatorV3Interface(_feedEurUsdAddress);
        }

    function buy(uint256 tokenId, uint256 amount) payable external {
        buyFor(msg.sender, tokenId, amount);
    }

    function buyFor(address targetAddress, uint256 tokenId, uint256 amount) payable public {
        uint256 maxSupply = maxSupplies[tokenId];
        require(maxSupply==0||totalSupply(tokenId)+amount<=maxSupply, "out of supply");
        uint256 weiPrice = getWeiPrice(tokenId);
        require(amount>0&&amount<=100, "amount not in range");
        uint256 minTotalPrice = (weiPrice * amount * 994) / 1000;
        uint256 maxTotalPrice = (weiPrice * amount * 1006) / 1000;
        require(msg.value >= minTotalPrice, "Not enough ETH");
        require(msg.value <= maxTotalPrice, "Too much ETH");
        _mint(targetAddress, tokenId, amount, "");
    }

    function drop(address targetAddress, uint256 tokenId, uint256 amount) external {
        uint256 maxSupply = maxSupplies[tokenId];
        require(maxSupply==0||totalSupply(tokenId)+amount<=maxSupply, "out of supply");
        require(msg.sender == dropperAddress || msg.sender == owner(), "drop not allowed");
        _mint(targetAddress, tokenId, amount, "");
    }

    function setDropperAddress(address _address) external onlyOwner {
        dropperAddress = _address;
    }

    function setFundsRecipient(address _address) external onlyOwner {
        fundsRecipient = _address;
    }

    function setMaxSupply(uint256 _tokenId, uint256 _maxSupply) external onlyOwner {
        maxSupplies[_tokenId] = _maxSupply;
    }

    function setPrices(uint256 _tokenId, uint256 _priceInEur) external onlyOwner {
        pricesInEur[_tokenId] = _priceInEur;
    }

    function setUri(string memory _newURI) external onlyOwner {
        _setURI(_newURI);
    }

    function setMaticUsdFeed(address _address) external onlyOwner{
        maticToUsdFeed = AggregatorV3Interface(_address);
    }

    function setEurUsdFeed(address _address) external onlyOwner{
        eurToUsdFeed = AggregatorV3Interface(_address);
    }

    /**
     * @dev Retrieve the funds of the sale
     */
    function retrieveFunds() external {
        require(fundsRecipient!=address(0), "funds recipient not defined");
        require(msg.sender == fundsRecipient || msg.sender == owner(), "Not allowed");
        payable(fundsRecipient).sendValue(address(this).balance);
    }


    /**
     * @dev Gets the current price of the token in wei according
     * to a fixed price in USD
     */
    function getWeiPrice(uint256 tokenId) public view returns (uint256) {
        uint256 priceInEur = pricesInEur[tokenId];
        require(priceInEur!=0, "invalid tokenId");
        uint256 priceInUsd = (priceInEur * getDollarByEur()) / (10**(eurToUsdFeed.decimals()-4));
        uint256 dollarByMatic = getDollarByMatic();
        uint256 power = 18 + maticToUsdFeed.decimals() - 4;
        uint256 weiPrice = (priceInUsd * 10**power) / dollarByMatic;
        return weiPrice;
    }

    /**
    @dev Gets current dollar price for an euro
    */
    function getDollarByEur() private view returns (uint256) {
        (, int256 dollarByEth, , , ) = eurToUsdFeed.latestRoundData();
        return uint256(dollarByEth);
    }

    /**
    @dev Gets current dollar price for a single MATIC
    */
    function getDollarByMatic() private view returns (uint256) {
        (, int256 dollarByEth, , , ) = maticToUsdFeed.latestRoundData();
        return uint256(dollarByEth);
    }

}