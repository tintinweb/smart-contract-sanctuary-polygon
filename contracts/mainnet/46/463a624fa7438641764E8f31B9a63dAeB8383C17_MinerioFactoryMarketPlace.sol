// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IUniSwapPair.sol";

contract MinerioFactoryMarketPlace {
    //////////////////////////////////////////////////////////////////////////////////////////////////// Variables

    address public owner; //owner of MarketPlace
    address public NFTAddress; // address of Nft that we sell on MarketPlace
    address public WMATICAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // address of Wmatic contract
    address public uniswapMaticUSDPair =
        0x604229c960e5CACF2aaEAc8Be68Ac07BA9dF81c3; // address of Wmatic contract
    address public targetWallet; // address of wallet that we want to receive ethers
    bool public active; // MarketPlace is active or not
    bool public staticMaticPrice; // use static matic price for test or not
    uint256 public NFTPrice; // price of the nft in Dollar
    uint256 public MATICPrice; // price of matic
    

    //////////////////////////////////////////////////////////////////////////////////////////////////// Events

    event NFTSold(address _buyer, uint256 _price, uint256 _count);
    event PriceChanged(uint256 _newPrice);
    event ActiveChanged(bool _newActive);

    //////////////////////////////////////////////////////////////////////////////////////////////////// Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isActive() {
        require(active, "Market is closed");
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////// Constructor

    constructor(address _owner, address _target) {
        owner = _owner;
        targetWallet = _target;
        active = true;
        staticMaticPrice = false;
        MATICPrice = 0;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////// Owner Functions

    function setPrice(uint256 _price) public onlyOwner {
        NFTPrice = _price;
        emit PriceChanged(_price);
    }

    function setActive(bool _active) public onlyOwner {
        active = _active;
        emit ActiveChanged(_active);
    }

    function setNFTAddress(address _NFTAddress) public onlyOwner {
        NFTAddress = _NFTAddress;
    }

    function setTargetWallet(address _target) public onlyOwner {
        targetWallet = _target;
    }

    function setStaticMaticPrice(uint256 _price, bool _static) public onlyOwner {
        MATICPrice = _price;
        staticMaticPrice = _static;
    }

    function transferERC20FromMarketPlace(
        address _to,
        address _tokenAddress,
        uint256 _amount
    ) public onlyOwner {
        IIERC20(_tokenAddress).transfer(_to, _amount);
    }

    function transferMATICFromMarketPlace(address _to, uint256 _amount)
        public
        onlyOwner
    {
        payable(_to).transfer(_amount);
    }

    function transferERC721FromMarketPlace(
        address _to,
        address _tokenAddress,
        uint256 _id
    ) public onlyOwner {
        IERC721(_tokenAddress).transferFrom(address(this), _to, _id);
    }

    function transferERC1155FromMarketPlace(
        address _to,
        uint256 _id,
        uint256 _amount
    ) public onlyOwner {
        IERC1155(NFTAddress).safeTransferFrom(
            owner,
            _to,
            _id,
            _amount,
            "0x000000"
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////// Users Functions

    function buyWithMatic(uint256 _nftId, uint256 _amount)
        public
        payable
        isActive
    {
        uint256 balance = IERC1155(NFTAddress).balanceOf(owner, _nftId);

        require(balance > 0, "Balance for the required NFT is 0 !!!");
        // require(
        //     balance > _amount,
        //     "Insufficient Balacne for the required NFT !"
        // );

        // uint256 amountOfMaticRequired = NFTPrice * _amount;
        uint256 amountOfMaticRequired = CalcualteAmountOfMatic(_amount);

        require(msg.value >= amountOfMaticRequired, "insufficient vlaue !");

        //if the sending value is more than required value, return the extra amount

        if (msg.value >= amountOfMaticRequired) {
            payable(msg.sender).transfer(msg.value - amountOfMaticRequired);
        }
        // transfer value to the target wallet

        payable(targetWallet).transfer(amountOfMaticRequired);

        // transfering the nft to buyer

        IERC1155(NFTAddress).safeTransferFrom(
            owner,
            msg.sender,
            _nftId,
            _amount,
            "0x000000"
        );
        emit NFTSold(msg.sender, amountOfMaticRequired, _amount);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////// Changing Dollar and MATIC Functions

    function CalcualteAmountOfMatic(uint256 _tokensCount)
        public
        view
        returns (uint256)
    {
        uint256 maxUsdPrice = CalcualteAmountOfUSD(_tokensCount);
        maxUsdPrice *= 10**18;
        return maxUsdPrice / getMaticPrice();
    }

    function CalcualteAmountOfUSD(uint256 _tokensCount)
        public
        view
        returns (uint256)
    {
        uint256 maxUsdPrice = NFTPrice * _tokensCount;
        return maxUsdPrice;
    }

    function getMaticPrice() public view returns (uint256) {
        if(staticMaticPrice)
            return MATICPrice;
        (uint112 reserve0, uint112 reserve1, ) = IUniSwapPair(
            uniswapMaticUSDPair
        ).getReserves();

        uint256 token0Decimals = IIERC20(
            IUniSwapPair(uniswapMaticUSDPair).token0()
        ).decimals();
        uint256 token1Decimals = IIERC20(
            IUniSwapPair(uniswapMaticUSDPair).token1()
        ).decimals();

        uint256 token0Amount = reserve0;
        uint256 token1Amount = reserve1;

        if (token0Decimals < 18 && token0Decimals != 0)
            token0Amount = token0Amount * (10**(18 - token0Decimals));
        if (token1Decimals < 18 && token1Decimals != 0)
            token1Amount = token1Amount * (10**(18 - token1Decimals));

        uint256 price = 0;
        if (IUniSwapPair(uniswapMaticUSDPair).token0() == WMATICAddress)
            price = (token1Amount * (10**18)) / token0Amount;
        else price = (token0Amount * (10**18)) / token1Amount;

        return price;
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////// Contract is a reciever

    receive() external payable {}
}