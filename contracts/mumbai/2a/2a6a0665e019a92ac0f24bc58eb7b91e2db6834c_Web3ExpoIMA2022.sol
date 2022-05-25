// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./AggregatorV3Interface.sol";

contract Web3ExpoIMA2022 is Ownable, ERC1155Supply {

    string public name = "Ticket pour l'exposition Web3 Institut du Monde Arabe 2022";

    string public symbol = "IMA EXPO 2022";

    //address allowed to drop nfts
    address private dropperAddress;

    uint256 public PRICE_REGULAR_TICKET_USD = 1;

    uint256 public PRICE_PREMIUM_TICKET_USD = 2;

    //matic to usd chainlink feed
    AggregatorV3Interface private maticToUsdFeed;

    constructor(address _feedAddress)
    ERC1155("ipfs://QmSCTwpish8twxnhd8iA1TpfNFwBbiwb6sWcWMLcBwya9Z/{id}.json")
        {
            maticToUsdFeed = AggregatorV3Interface(_feedAddress);
        }

    function buy(uint256 tokenId, uint256 amount) external {
        buyFor(msg.sender, tokenId, amount);
    }

    function buyFor(address targetAddress, uint256 tokenId, uint256 amount) payable public {
        uint256 weiPrice = getWeiPrice(tokenId);
        require(amount>0&&amount<=100, "amount not in range");
        uint256 minTotalPrice = (weiPrice * amount * 994) / 1000;
        uint256 maxTotalPrice = (weiPrice * amount * 1006) / 1000;
        require(msg.value >= minTotalPrice, "Not enough ETH");
        require(msg.value <= maxTotalPrice, "Too much ETH");
        _mint(targetAddress, tokenId, amount, "");
    }

    function drop(address targetAddress, uint256 tokenId, uint256 amount) external onlyOwner {
        require(tokenId<2, "invalid tokenId");
        require(msg.sender == dropperAddress || msg.sender == owner(), "drop not allowed");
        _mint(targetAddress, tokenId, amount, "");
    }

    function setDropperAddress(address _address) external onlyOwner {
        dropperAddress = _address;
    }

       /**
     * @dev Gets the current price of the token in wei according
     * to a fixed price in USD
     */
    function getWeiPrice(uint256 tokenId) public view returns (uint256) {
        require(tokenId<2, "invalid tokenId");
        uint256 priceInUsd = tokenId == 0 ? PRICE_REGULAR_TICKET_USD : PRICE_PREMIUM_TICKET_USD;
        uint256 dollarByEth = getDollarByEth();
        uint256 power = 18 + maticToUsdFeed.decimals();
        uint256 weiPrice = (priceInUsd * 10**power) / dollarByEth;
        return weiPrice;
    }

    /**
    @dev Gets current dollar price for a single ETH (10^18 wei)
    */
    function getDollarByEth() private view returns (uint256) {
        (, int256 dollarByEth, , , ) = maticToUsdFeed.latestRoundData();
        return uint256(dollarByEth);
    }

}