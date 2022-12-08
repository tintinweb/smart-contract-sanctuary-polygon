// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // security for non-reentrant
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../utils/AcceptedTokensList.sol";

import {Errors} from "../utils/Errors.sol";
import {DataTypes} from "../utils/DataTypes.sol";

contract ERC721Market is ReentrancyGuard, AccessControl, AcceptedTokenList {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //Percent of fee taken from sales
    uint256 public feePercent;

    //Fee collected from every sale
    //collectedFee[addressOfERC20Token] = amountOfTokensTakenAsFee
    mapping(address => uint256) public collectedFee;

    //marketItem[addressOfToken][tokenId] = array of item orders
    mapping(address => mapping(uint256 => DataTypes.MarketItem[])) public marketItems;

    //englishAuctions[addressOfToken][tokenId] = arrey of item auctions
    mapping(address => mapping(uint256 => DataTypes.EnglishAuctionConfig[])) public englishAuctions;

    //Emitted when some address "listMarketItemOnEnglishAuction"
    event EnglishAuctionStarted(
        uint256 startPrice,
        uint256 minIncreaseInterval,
        uint256 instantBuyPrice,
        uint256 tokenId,
        uint256 endDate,
        address erc20Token,
        address erc721Token,
        address tokenOwner
    );

    //Emitted when some address "makeBidAtEnglishAuction"
    event BidMade(address bidder, uint256 currentPrice, address erc721Token, uint256 tokenId);

    //Emitted when auction finished
    event AuctionFinished(address seller, address winner, address erc721Address, uint256 tokenId, uint256 price);

    //Emitted when some address "listFixedPriceMarketItem"
    event FixedPriceMarketItemListed(address erc721Token, uint256 tokenId, uint256 price, address erc20Token);

    //Emitted when some address "buyItemOnFixedPriceMarket"
    event ItemBoughtAtFixedPrice(address buyer, address erc721Token, uint256 tokenId, uint256 price);

    //Emitted when owner of token "delistFixedPriceMarketItem"
    event Delisted(address erc721Token, uint256 tokenId);

    //Emitted when contract "receive" value
    event ValueReceived(address user, uint amount);

    //Emitted when admin "setFeePErcent"
    event FeePercentChanged(uint256 feePercent, address admin);

    constructor(uint256 _feePercent) {
        _setFeePercent(_feePercent);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _grantRole(ADMIN_ROLE, msg.sender);

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /** @notice Create fixed price market sale for ERC721 token, set price for it and transfer ERC721 token to contract
     * @param _erc721Token Address of ERC721 token for sale
     * @param _tokenId Id of token for sale
     * @param _price Amount of tokens which seller whant to get for ERC721 token
     * @param _erc20Token Address of token in which seller whant to get payment
     */
    function listFixedPriceMarketItem(
        address _erc721Token,
        uint256 _tokenId,
        uint256 _price,
        address _erc20Token
    ) public {
        if(_price == 0) {
            revert Errors.AmountCanNotBeZero();
        }

        if(hasStatus(_erc20Token, TokenState.unaccepted)) {
            revert Errors.TokenIsUnaccepted();
        }

        marketItems[_erc721Token][_tokenId].push(
            DataTypes.MarketItem({price: _price, erc20Token: _erc20Token, seller: payable(msg.sender), isActive: true})
        );

        IERC721(_erc721Token).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit FixedPriceMarketItemListed(_erc721Token, _tokenId, _price, _erc20Token);
    }   

    /** @notice Function for buy token on fixed price market sale, transfer ERC20 tokens to seller and transfer ERC721 token to buyer
     * @param _erc721Token Address of ERC721 token for sale
     * @param _tokenId Id of token for sale
     */
    function buyItemOnFixedPriceMarket(address _erc721Token, uint256 _tokenId) public payable {
        if(marketItems[_erc721Token][_tokenId].length == 0) {
            revert Errors.ItemDidNotListed();
        }

        DataTypes.MarketItem storage marketItem = marketItems[_erc721Token][_tokenId][marketItems[_erc721Token][_tokenId].length - 1];

        if(marketItem.isActive != true) {
            revert Errors.InvalidFixedPriceMarketSaleState();
        }

        IERC20(marketItem.erc20Token).transferFrom(msg.sender, address(this), marketItem.price);

        _payWithRoyalty(marketItem.erc20Token, marketItem.price, _erc721Token, _tokenId, marketItem.seller);

        marketItem.isActive = false;

        emit ItemBoughtAtFixedPrice(msg.sender, _erc721Token, _tokenId, marketItem.price);
    }

    /** @notice Delist ERC721 token from fixed price market sale and transfer ERC721 token back to seller
     * @param _erc721Token Address of ERC721 token for sale
     * @param _tokenId Id of token for sale
     */
    function delistFixedPriceMarketItem(address _erc721Token, uint256 _tokenId) public payable {
        if(marketItems[_erc721Token][_tokenId].length == 0) {
            revert Errors.ItemDidNotListed();
        }

        DataTypes.MarketItem storage marketItem = marketItems[_erc721Token][_tokenId][marketItems[_erc721Token][_tokenId].length - 1];

        if(marketItem.isActive != true) {
            revert Errors.InvalidFixedPriceMarketSaleState();
        }

        if(marketItem.seller != msg.sender) {
            revert Errors.NotTokenOwner();
        }

        require(marketItem.seller == msg.sender, "Not token owner");

        marketItem.isActive = false;

        IERC721(_erc721Token).safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Delisted(_erc721Token, _tokenId);
    }

    /** @notice Function for listing token on auction, transfer ERC721 token to contract address and create auction struct
     * @param _startPrice Amount of token from which auction price will start
     * @param _minIncreaseInterval Amount of tokens by which the price should increase with each bid
     * @param _instantBuyPrice Amount of tokens for which address can buy a token instantly
     * @param _tokenId Id of token that will be sold at the auction
     * @param _endDate Block timestamp in which auction will be finished
     * @param _erc20Token Address of ERC20 token in which payment will be made
     * @param _erc721Token Address of ERC721 token which will be sold at auction
     */
    function listMarketItemOnEnglishAuction(
        uint256 _startPrice,
        uint256 _minIncreaseInterval,
        uint256 _instantBuyPrice,
        uint256 _tokenId,
        uint256 _endDate,
        address _erc20Token,
        address _erc721Token
    ) public {
        DataTypes.EnglishAuctionConfig[] storage auction = englishAuctions[_erc721Token][_tokenId];
        if(auction.length > 0 && auction[auction.length - 1].state == DataTypes.AuctionState.STARTED) {
            revert Errors.InvalidAuctionState();
        }

        if(_minIncreaseInterval == 0 || _startPrice == 0) {
            revert Errors.AmountCanNotBeZero();
        }

        if(_endDate < block.timestamp) {
            revert Errors.InvalidTimeForFunction();
        }

        if(hasStatus(_erc20Token, TokenState.unaccepted)) {
            revert Errors.TokenIsUnaccepted();
        }

        if(_startPrice + _minIncreaseInterval >= _instantBuyPrice) {
            revert Errors.InstantBuyPriceMustBeGreaterThanMin();
        }
       
        auction.push(
            DataTypes.EnglishAuctionConfig({
                tokenOwner: msg.sender,
                minIncreaseInterval: _minIncreaseInterval,
                endDate: _endDate,
                instantBuyPrice: _instantBuyPrice,
                latestBidder: address(0),
                erc20Token: _erc20Token,
                erc721Token: _erc721Token,
                tokenId: _tokenId,
                currentPrice: _startPrice - _minIncreaseInterval,
                state: DataTypes.AuctionState.STARTED
            })
        );

        IERC721(_erc721Token).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit EnglishAuctionStarted(
            _startPrice,
            _minIncreaseInterval,
            _instantBuyPrice,
            _tokenId,
            _endDate,
            _erc20Token,
            _erc721Token,
            msg.sender
        );
    }

    /** @notice Create bid at auction, transfer tokens of bidder to contract and send tokens to latest bidder back
     * @param _erc721Token Address of ERC721 token for sale
     * @param _tokenId Id of token for sale
     * @param _bidAmount Amount of token which address want to bid
     */
    function makeBidAtEnglishAuction(
        address _erc721Token,
        uint256 _tokenId,
        uint256 _bidAmount
    ) public {
        DataTypes.EnglishAuctionConfig storage auction = englishAuctions[_erc721Token][_tokenId][englishAuctions[_erc721Token][_tokenId].length - 1];
        if(_bidAmount < (auction.currentPrice + auction.minIncreaseInterval)) {
            revert Errors.InvalidBidAmount();
        }      
        if(auction.endDate < block.timestamp) {
            revert Errors.InvalidTimeForFunction();
        }
        if(auction.state != DataTypes.AuctionState.STARTED) {
            revert Errors.InvalidAuctionState();
        }

        if (_bidAmount < auction.instantBuyPrice) {
            IERC20(auction.erc20Token).transferFrom(msg.sender, address(this), _bidAmount);

            if (auction.latestBidder != address(0)) {
                IERC20(auction.erc20Token).transfer(auction.latestBidder, auction.currentPrice);
            }

            auction.currentPrice = _bidAmount;
            auction.latestBidder = msg.sender;

            emit BidMade(msg.sender, auction.currentPrice, _erc721Token, _tokenId);
        } else if (_bidAmount >= auction.instantBuyPrice) {
            IERC20(auction.erc20Token).transferFrom(msg.sender, address(this), auction.instantBuyPrice);
            
            if (auction.latestBidder != address(0)) {
                IERC20(auction.erc20Token).transfer(auction.latestBidder, auction.currentPrice);
            }

            _payWithRoyalty(
                auction.erc20Token,
                auction.instantBuyPrice,
                auction.erc721Token,
                auction.tokenId,
                auction.tokenOwner
            );

            auction.currentPrice = auction.instantBuyPrice;
            auction.latestBidder = msg.sender;

            auction.state = DataTypes.AuctionState.FINISHED;

            emit AuctionFinished(auction.tokenOwner, msg.sender, auction.erc721Token, auction.tokenId, auction.instantBuyPrice);
        }
    }

    /** @notice Buy token for fixed price
     * @param _erc721Token Address of ERC721 token which sold at auction
     * @param _tokenId Id of token that will be sold at the auction
     */
    function instantBuyAtEnglishAuction(address _erc721Token, uint256 _tokenId) public {
        DataTypes.EnglishAuctionConfig storage auction = englishAuctions[_erc721Token][_tokenId][englishAuctions[_erc721Token][_tokenId].length - 1];

        if(auction.state != DataTypes.AuctionState.STARTED) {
            revert Errors.InvalidAuctionState();
        }
        if(auction.endDate <= block.timestamp) {
            revert Errors.InvalidTimeForFunction();
        }

        IERC20(auction.erc20Token).transferFrom(msg.sender, address(this), auction.instantBuyPrice);

        if (auction.latestBidder != address(0)) {
            IERC20(auction.erc20Token).transfer(auction.latestBidder, auction.currentPrice);
        }

        _payWithRoyalty(
            auction.erc20Token,
            auction.instantBuyPrice,
            auction.erc721Token,
            auction.tokenId,
            auction.tokenOwner
        );

        auction.state = DataTypes.AuctionState.FINISHED;

        emit AuctionFinished(auction.tokenOwner, msg.sender, auction.erc721Token, auction.tokenId, auction.instantBuyPrice);
    }

    /** @notice Function for finish auction if amount of bids is zero
     * @param _erc721Token Address of ERC721 token which will be sold at auction
     * @param _tokenId Id of token that will be sold at the auction
     */
    function finishUnsuccessfulAuction(address _erc721Token, uint256 _tokenId) public {
        DataTypes.EnglishAuctionConfig storage auction = englishAuctions[_erc721Token][_tokenId][englishAuctions[_erc721Token][_tokenId].length - 1];
        if(auction.state != DataTypes.AuctionState.STARTED) {
            revert Errors.InvalidAuctionState();
        }
        if(auction.latestBidder != address(0)) {
            revert Errors.IncorrectProcessingOfTheAuctionResult();
        }

        IERC721(auction.erc721Token).safeTransferFrom(address(this), auction.tokenOwner, _tokenId);

        auction.state = DataTypes.AuctionState.UNSUCESSFUL;

        emit AuctionFinished(auction.tokenOwner, auction.tokenOwner, auction.erc721Token, auction.tokenId, 0); 
    }

      /** @notice Function for finish auction after end date
     * @param _erc721Token Address of ERC721 token which will be sold at auction
     * @param _tokenId Id of token that will be sold at the auction
     */
    function finishEnglishAuction(address _erc721Token, uint256 _tokenId) public {
        DataTypes.EnglishAuctionConfig storage auction = englishAuctions[_erc721Token][_tokenId][englishAuctions[_erc721Token][_tokenId].length - 1];
        if(auction.endDate > block.timestamp) {
            revert Errors.InvalidTimeForFunction();
        }

        if(auction.state != DataTypes.AuctionState.STARTED) {
            revert Errors.InvalidAuctionState();
        }

        if(auction.latestBidder == address(0)) {
            revert Errors.IncorrectProcessingOfTheAuctionResult();
        }

        uint256 feeAmount;
        if (acceptedTokenList[auction.erc20Token] == TokenState.accepted) {
            feeAmount += percentFrom(feePercent, auction.currentPrice);
            collectedFee[auction.erc20Token] += feeAmount;
        }

        feeAmount += _payRoyalty(_erc721Token, _tokenId, auction.erc20Token, auction.currentPrice);
     
        IERC20(auction.erc20Token).transfer(auction.tokenOwner, auction.currentPrice - feeAmount);
        IERC721(auction.erc721Token).safeTransferFrom(address(this), auction.latestBidder, _tokenId);

        auction.state = DataTypes.AuctionState.FINISHED;

        emit AuctionFinished(auction.tokenOwner, auction.latestBidder, auction.erc721Token, auction.tokenId, auction.currentPrice);
    }

    /**
     * @dev Add or remove a token address from the list of allowed to be accepted for exchange
     */
    function updateTokenList(address _token, TokenState _state) external {
        if(!hasRole(ADMIN_ROLE, msg.sender)) {
            revert Errors.CallerHasNoRole();
        }

        _updateTokenList(_token, _state);
    }

    /**
     * @dev Sets fee percent taken from sales
     * @param _feePercent percent multiplied by 1000, cannot be greater than 10000
     */
    function setFeePercent(uint256 _feePercent) public {
        if(!hasRole(ADMIN_ROLE, msg.sender)) {
            revert Errors.CallerHasNoRole();
        }
        _setFeePercent(_feePercent);
    }

    /**
     * @dev Withdrawn native currency received by contract
     * @param _recipient address which receive native currency
     * @param _amount Amount of currewncy for withdrawn
     */
    function sendValue(address payable _recipient, uint256 _amount) public {
        if(!hasRole(ADMIN_ROLE, msg.sender)) {
            revert Errors.CallerHasNoRole();
        }
        if(_recipient == address(0)) {
            revert Errors.CanNotBeZeroAddress();
        }
        if(address(this).balance < _amount) {
            revert Errors.IncorrectProcessingOfTheAuctionResult();
        }

        (bool success, ) = _recipient.call{value: _amount}("");

        if(!success) {
            revert Errors.RecipientMayHaveReverted();
        }
    }

    /** @notice Withdraw fee tokens from contract
     * @param _token Address of token
     * @param _receiver Address of token receiver.
     * @param _amount Aount of tokens for transfer.
     */
    function withdrawFee(
        address _token,
        address _receiver,
        uint256 _amount
    ) public onlyRole(ADMIN_ROLE) {
        if(_receiver == address(0)) {
            revert Errors.CanNotBeZeroAddress();
        }

        IERC20(_token).transfer(_receiver, _amount);
        collectedFee[_token] -= _amount;//back
    }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    function getLatestMarketItem(address _erc721Token, uint256 _tokenId) external view returns (DataTypes.MarketItem memory) {
        if(marketItems[_erc721Token][_tokenId].length == 0) {
            revert Errors.ItemDidNotListed();
        }

        return marketItems[_erc721Token][_tokenId][marketItems[_erc721Token][_tokenId].length - 1];
    }

    function getMarketItem(address _erc721Token, uint256 _tokenId, uint256 _id) external view returns (DataTypes.MarketItem memory) {
        if(marketItems[_erc721Token][_tokenId].length == 0) {
            revert Errors.ItemDidNotListed();
        }

        return marketItems[_erc721Token][_tokenId][_id];
    }

    function getLatestEnglishAuction(address _erc721Token, uint256 _tokenId)
        external
        view
        returns (DataTypes.EnglishAuctionConfig memory)
    {
        if(englishAuctions[_erc721Token][_tokenId].length == 0) {
            revert Errors.ItemDidNotListed();
        }

        return englishAuctions[_erc721Token][_tokenId][englishAuctions[_erc721Token][_tokenId].length - 1];
    }

    function getEnglishAuction(address _erc721Token, uint256 _tokenId, uint256 _id)
        external
        view
        returns (DataTypes.EnglishAuctionConfig memory)
    {
        if(englishAuctions[_erc721Token][_tokenId].length == 0) {
            revert Errors.ItemDidNotListed();
        }

        return englishAuctions[_erc721Token][_tokenId][_id];
    }

    function _setFeePercent(uint256 _feePercent) private {
        if(_feePercent > 10000) {
            revert Errors.FeePercentTooHigh();
        }

        feePercent = _feePercent;

        emit FeePercentChanged(_feePercent, msg.sender);
    }

    /**
     * @dev Pays the receiver the selected amount;
     * @param _erc20Token the sender of the payament
     * @param _amount Total amount of tokens paid
     * @param _erc721Token Address of purchased token
     * @param _tokenId Id of purchased token
     * @param _receiver Receiver of payment in ERC20 tokens
     */
    function _payWithRoyalty(
        address _erc20Token,
        uint256 _amount,
        address _erc721Token,
        uint256 _tokenId,
        address _receiver
    ) private {
        uint256 feeAmount;
        if (acceptedTokenList[_erc20Token] == TokenState.accepted) {
            feeAmount += percentFrom(feePercent, _amount);
            collectedFee[_erc20Token] += feeAmount;
        }

        feeAmount += _payRoyalty(_erc721Token, _tokenId, _erc20Token, _amount);

        IERC20(_erc20Token).transfer(_receiver, _amount - feeAmount);
        IERC721(_erc721Token).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function _payRoyalty(
        address _erc721Token,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _amount
    ) private returns (uint256 paidAmount) {
        if (checkRoyalties(_erc721Token)) {
            (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(_erc721Token).royaltyInfo(_tokenId, _amount);

            if (royaltyAmount > 0) {
                paidAmount = royaltyAmount;
                IERC20(_erc20Token).transfer(royaltyReceiver, royaltyAmount);
            }
        }
    }

    function checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    function percentFrom(uint256 _percent, uint256 _amount) private pure returns (uint256) {
        return ((_percent * _amount) / 10000);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library DataTypes {
    struct MarketItem {
        address payable seller;
        uint256 price;
        address erc20Token; //address of token in which, ERC721 token will sold
        bool isActive;
    }

    struct EnglishAuctionConfig {
        uint256 currentPrice;
        uint256 instantBuyPrice; //Price for instant buy
        uint256 minIncreaseInterval;
        uint256 tokenId;
        uint256 endDate; //block.timestemp in whcih auction finished
        address tokenOwner;
        address erc20Token;
        address erc721Token;
        address latestBidder;
        AuctionState state;
    }

    enum AuctionState {
        UNSPECIFIED,
        STARTED,
        FINISHED,
        UNSUCESSFUL
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract AcceptedTokenList {
    enum TokenState {
        unaccepted,
        accepted,
        feeFree
    }

    //List the status of the tokens
    //acceptedTokenList[tokenAddress] = TokenState
    mapping(address => TokenState) public acceptedTokenList;

    /**
     * @dev Emitted when `updateTokenList` change state of token
     */
    event TokenListUpdated(address indexed token, TokenState state);

    /**
     * @dev Add or remove a token address from the list of allowed to be accepted for exchange
     */
    function _updateTokenList(address _token, TokenState _state) internal {
        require(_token != address(0), "Token address can't be address(0).");

        acceptedTokenList[_token] = _state;

        emit TokenListUpdated(_token, _state);
    }

    function hasStatus(address _token, TokenState _status) public view returns (bool) {
        return acceptedTokenList[_token] == _status;
    }

    function getTokenStatus(address token) public view returns (TokenState) {
        return acceptedTokenList[token];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataTypes} from "./DataTypes.sol";

library Errors {
    error ItemDidNotListed();
    error InvalidFixedPriceMarketSaleState();
    error NotTokenOwner();
    error IncorrectProcessingOfTheAuctionResult();
    error InvalidAuctionState();
    error InvalidTimeForFunction();
    error InvalidBidAmount();
    error AmountCanNotBeZero();
    error TokenIsUnaccepted();
    error InstantBuyPriceMustBeGreaterThanMin();
    error BalanceOfContractIsTooLow();
    error RecipientMayHaveReverted();
    error FeePercentTooHigh();
    error CallerHasNoRole();
    error InsufficientBalance();
    error CanNotBeZeroAddress();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}