/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract MarketPlaceProxy {
    error DelegateCallError();

    address public factory;

    address public proxyOwner;
    address public implementation;

    address public marketFeeTaker;
    uint8 public marketFee;

    address[] public tokens;

    struct SellOrder {
        address seller;
        address token;
        address contractAddr;
        uint256 nftId;
        address buyer;
        uint256 price;
        uint256 startedAt;
        uint256 endedAt;
        bool isCanceled;
        bool isEnded;
    }
    uint256 public sellOrderCount = 1;

    struct Bid {
        address bidder;
        address token;
        address nftOwner;
        uint256 sellOrderId;
        uint256 price;
        uint256 biddedAt;
        uint256 bidEndedAt;
        bool isCanceled;
        bool isEnded;
    }
    uint256 public bidCount = 1;

    // from sell-order id to sell-order info
    mapping (uint256 => SellOrder) private sellOrders;
    // from bid id to bid info
    mapping (uint256 => Bid) private bids;
    // from user to his/her created ERC721 created contract
    mapping (address => address) private userContract;
    // monitor all contracts which created in the markeplace
    mapping (address => bool) private allContracts;
    // monitor all validated and confirmed tokens
    mapping (address => bool) private marketTokens;
     
    constructor(
        uint8 _marketFee,
        address _marketFeeTaker,
        address[] memory _tokens,
        address _factory,
        address _implementation
    ) {
        proxyOwner = msg.sender;

        factory = _factory;
        marketFee = _marketFee;
        marketFeeTaker = _marketFeeTaker;

        implementation = _implementation;

        require(_tokens.length > 0, "At least one token needed!");
        for (uint256 i; i < _tokens.length; ++i) {
            require(marketTokens[_tokens[i]] == false, "Duplicate token.");

            marketTokens[_tokens[i]] = true;
            tokens.push(_tokens[i]);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == proxyOwner, "Only owner.");
        _;
    }

    // interact with the implementation contract
    fallback(bytes calldata _data) external payable returns(bytes memory) {
        (bool result, bytes memory data) = implementation.delegatecall(_data);
        if (result == false) {
            revert DelegateCallError();
        }

        return data;
    }

    // change marketplace state
    function upgradeImpelementation(
        address _newImp
    ) external onlyOwner {
        implementation = _newImp;
    }

    function changeOwner(
        address _newOwner
    ) external onlyOwner {
        proxyOwner = _newOwner;
    }

    function changeMarketFee(
        uint8 _newFee
    ) external onlyOwner {
        marketFee = _newFee;
    }

    function changeMarketFeeTaker(
        address _newFeeTaker
    ) external onlyOwner {
        marketFeeTaker = _newFeeTaker;
    }

    function changeFactory(
        address _newFactory
    ) external onlyOwner {
        factory = _newFactory;
    }
}