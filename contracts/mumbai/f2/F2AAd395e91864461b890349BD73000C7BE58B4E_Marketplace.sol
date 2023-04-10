// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace is ReentrancyGuard, Ownable{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter public _marketItemIds;
    Counters.Counter public _itemSold;
    Counters.Counter public _itemCanceled;

    address public tokens;
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    struct MarketItem {
        uint256 marketItemId;
        address nftContractAddress;
        uint256 tokenId;
        address payable creator;
        address payable seller;
        address payable owner;
        uint256 bnbPrice;
        uint256 tokenPrice;
        bool sold;
        bool canceled;
    }

    struct UserNFT {
        uint256 totalNFTBuy;
        uint256 totalNFTSell;   
        uint256 totalOffer; 
    }

    struct Offer {   
        address offerBy;  
        uint256 price;
        uint256 deadline;
        bool status;
    }

    struct UserOffer {
        uint256 marketId;
    }
    
    mapping(address => UserOffer[]) public usrCoinOffer;
    mapping(address => UserOffer[]) public usrTokenOffer;

    mapping(uint256 => MarketItem) private marketItemIdToMarketItem;
    mapping(address => UserNFT) public users;
    
    mapping(uint256 => mapping(address => Offer)) public offersToken;  
    mapping(uint256 => mapping(address => Offer)) public offersCoin;    

    mapping(uint256 => mapping(address => Offer[])) private _offersToken;
    mapping(uint256 => mapping(address => Offer[])) private _offersCoin;

    constructor(address _tokenAdress) {
        tokens = _tokenAdress;
    }

    receive() external payable {}

    function sellNFTItem(
        address nftContractAddress, 
        uint256 tokenId, 
        uint256 _inBnbprice, 
        uint256 _inTokenprice
    ) public nonReentrant isNFTAddress(nftContractAddress) returns (uint256) {
        require(_inBnbprice > 0, "Price must be at least 1 wei");
        require(_inTokenprice > 0, "Price must be at least 1 wei");

        _marketItemIds.increment();
        uint256 marketItemId = _marketItemIds.current();
        address creator = IERC721(nftContractAddress).ownerOf(tokenId);

        marketItemIdToMarketItem[marketItemId] = MarketItem(
            marketItemId,
            nftContractAddress,
            tokenId,
            payable(creator),
            payable(msg.sender),
            payable(address(0)),
            _inBnbprice,
            _inTokenprice,
            false,
            false
        );

        IERC721(nftContractAddress).transferFrom(msg.sender, address(this), tokenId);
        users[msg.sender].totalNFTSell += 1;

        emit MarketItemCreated(
            marketItemId,
            nftContractAddress,
            tokenId,
            payable(creator),
            payable(msg.sender),
            payable(address(0)),
            _inBnbprice,
            _inTokenprice,
            false,
            false
        );
        return marketItemId;
    }

    function editNFTItem(uint256 marketItemId, uint256 _inBnbprice, uint256 _inTokenprice) public nonReentrant {
        require(_inBnbprice > 0, "value must be more than zero");
        require(_inTokenprice > 0, "value must be more than zero");

        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        require(tokenId > 0, "Market item has to exist");
        require(marketItemIdToMarketItem[marketItemId].seller == msg.sender, "You are not the seller");

        address creator = IERC721(marketItemIdToMarketItem[marketItemId].nftContractAddress).ownerOf(tokenId);

        marketItemIdToMarketItem[marketItemId] = MarketItem(
            marketItemId,
            marketItemIdToMarketItem[marketItemId].nftContractAddress,
            tokenId,
            payable(creator),
            payable(msg.sender),
            payable(address(0)),
            _inBnbprice,
            _inTokenprice,
            false,
            false
        );        
    }

    function createOfferCoins(uint256 marketItemId, uint256 _deadLine) public payable nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;

        require(tokenId > 0, "Market item has to exist");
        require(msg.value > 0, "value must be more than zero");
        require(_deadLine > block.timestamp + 30 minutes, "deadline must be more than 30 minutes");

        address nftContract = marketItemIdToMarketItem[marketItemId].nftContractAddress;
        uint256 offerlength = _offersCoin[marketItemId][nftContract].length;
        require(offerlength == 0, "offer item has no exist");

        offersCoin[marketItemId][msg.sender] = Offer(
            msg.sender,
            msg.value,
            _deadLine,
            true
        );
  
        _offersCoin[marketItemId][nftContract].push();
        Offer storage _offerCoins = _offersCoin[marketItemId][nftContract][offerlength];
        _offerCoins.offerBy =  msg.sender;
        _offerCoins.price = msg.value;
        _offerCoins.deadline = _deadLine;  
        _offerCoins.status = true;  

        UserOffer memory newOffer = UserOffer(marketItemId);       
        usrCoinOffer[msg.sender].push(newOffer);    

        users[msg.sender].totalOffer += 1;          
    }

    function createOfferTokens(uint256 marketItemId, uint256 _offerAmount,uint256 _deadLine) public nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;

        require(tokenId > 0, "Market item has to exist");
        require(_offerAmount > 0, "value must be more than zero");
        require(IERC20(tokens).balanceOf(msg.sender) >= _offerAmount, "available balance must be same or greater than _offerAmount");
        require(_deadLine > block.timestamp + 30 minutes, "deadline must be more than 30 minutes");

        address nftContract = marketItemIdToMarketItem[marketItemId].nftContractAddress;
        uint256 offerlength = _offersToken[marketItemId][nftContract].length;
        require(offerlength == 0, "offer item has no exist");

        IERC20(tokens).transferFrom(msg.sender, address(this), _offerAmount);

        offersToken[marketItemId][msg.sender] = Offer(
            msg.sender,
            _offerAmount,
            _deadLine,
            true
        );  
  
        _offersToken[marketItemId][nftContract].push();
        Offer storage _offerTokens = _offersToken[marketItemId][nftContract][offerlength];
        _offerTokens.offerBy =  msg.sender;
        _offerTokens.price = _offerAmount;
        _offerTokens.deadline = _deadLine;  
        _offerTokens.status = true; 

        UserOffer memory newOffer = UserOffer(marketItemId);       
        usrTokenOffer[msg.sender].push(newOffer);  

        users[msg.sender].totalOffer += 1;                                    
    }    

    function cancelOfferCoins(uint256 marketItemId) public nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        require(tokenId > 0, "Market item has to exist");
        require(offersCoin[marketItemId][msg.sender].status == true, "offer not valid");
        delete (offersCoin[marketItemId][msg.sender]);        
    }

    function cancelOfferTokens(uint256 marketItemId) public nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        require(tokenId > 0, "Market item has to exist");

        require(offersToken[marketItemId][msg.sender].status == true, "offer not valid");
        delete (offersToken[marketItemId][msg.sender]);        
    }

    function acceptOfferCoins(uint256 marketItemId, address _offerFrom) public nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        address nftContract = marketItemIdToMarketItem[marketItemId].nftContractAddress;

        require(tokenId > 0, "Market item has to exist");
        require(offersCoin[marketItemId][_offerFrom].status == true, "offer not valid");
        require(marketItemIdToMarketItem[marketItemId].seller == msg.sender, "You are not the seller");

        uint256 priceIncoin = offersCoin[marketItemId][_offerFrom].price;

        marketItemIdToMarketItem[marketItemId].owner = payable(_offerFrom);
        marketItemIdToMarketItem[marketItemId].sold = true;
        marketItemIdToMarketItem[marketItemId].seller.transfer(priceIncoin);

        IERC721(nftContract).transferFrom(address(this), _offerFrom, tokenId);

        delete (marketItemIdToMarketItem[marketItemId]);
        _itemSold.increment();        
    }    

    function acceptOfferTokens(uint256 marketItemId, address _offerFrom) public nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        address nftContract = marketItemIdToMarketItem[marketItemId].nftContractAddress;

        require(tokenId > 0, "Market item has to exist");
        require(offersCoin[marketItemId][_offerFrom].status == true, "offer not valid");
        require(marketItemIdToMarketItem[marketItemId].seller == msg.sender, "You are not the seller");

        uint256 priceInToken = offersToken[marketItemId][_offerFrom].price;

        marketItemIdToMarketItem[marketItemId].owner = payable(_offerFrom);
        marketItemIdToMarketItem[marketItemId].sold = true;
        IERC20(tokens).transferFrom(address(this), msg.sender, priceInToken);

        IERC721(nftContract).transferFrom(address(this), _offerFrom, tokenId);

        delete (marketItemIdToMarketItem[marketItemId]);
        _itemSold.increment();        
    } 

    function cancelNFTItem(uint256 marketItemId) public nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        address nftContract = marketItemIdToMarketItem[marketItemId].nftContractAddress;

        require(tokenId > 0, "Market item has to exist");
        require(marketItemIdToMarketItem[marketItemId].seller == msg.sender, "You are not the seller");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        marketItemIdToMarketItem[marketItemId].owner = payable(msg.sender);
        marketItemIdToMarketItem[marketItemId].canceled = true;

        _itemCanceled.increment();
    }

    function buyNFTWithCoin(address nftContractAddress, uint256 marketItemId) public payable nonReentrant isNFTAddress(nftContractAddress) {
        uint256 price = marketItemIdToMarketItem[marketItemId].bnbPrice;
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;

        require(msg.value == price, "Please submit the asking price in order to continue");

        marketItemIdToMarketItem[marketItemId].owner = payable(msg.sender);
        marketItemIdToMarketItem[marketItemId].sold = true;
        marketItemIdToMarketItem[marketItemId].seller.transfer(msg.value);

        IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);

        users[msg.sender].totalNFTBuy += 1;

        _itemSold.increment();
    }

    function buyNFTWithToken(address nftContractAddress, uint256 marketItemId) public nonReentrant isNFTAddress(nftContractAddress) {
        uint256 price = marketItemIdToMarketItem[marketItemId].tokenPrice;
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        uint256 userToken = IERC20(tokens).balanceOf(msg.sender);

        require(userToken >= price, "you dont have enough token to buy NFT");

        marketItemIdToMarketItem[marketItemId].owner = payable(msg.sender);
        marketItemIdToMarketItem[marketItemId].sold = true;

        IERC20(tokens).transferFrom(msg.sender, marketItemIdToMarketItem[marketItemId].seller, price);
        IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);

        users[msg.sender].totalNFTBuy += 1;

        _itemSold.increment();
    }

    function getLatestMarketItemByTokenId(uint256 tokenId) public view returns (MarketItem memory, bool) {
        uint256 itemsCount = _marketItemIds.current();
        for (uint256 i = itemsCount; i > 0; i--) {
            MarketItem memory item = marketItemIdToMarketItem[i];
            if (item.tokenId != tokenId) continue;
            return (item, true);
        }
        MarketItem memory emptyMarketItem;
        return (emptyMarketItem, false);
    }

    function fetchAvailableMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemsCount = _marketItemIds.current();
        uint256 soldItemsCount = _itemSold.current();
        uint256 canceledItemsCount = _itemCanceled.current();
        uint256 availableItemsCount = itemsCount - soldItemsCount - canceledItemsCount;
        MarketItem[] memory marketItems = new MarketItem[](availableItemsCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemsCount; i++) {
            MarketItem memory item = marketItemIdToMarketItem[i + 1];
            if (item.owner != address(0)) continue;
            marketItems[currentIndex] = item;
            currentIndex += 1;
        }
        return marketItems;
    }

    function fetchSellItemByAddress(address _sellers) public view returns (MarketItem[] memory) {
        uint256 itemsCount = _marketItemIds.current();
        MarketItem[] memory marketItems = new MarketItem[](itemsCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemsCount; i++) {
            MarketItem memory item = marketItemIdToMarketItem[i + 1];
            if (item.seller != _sellers) continue;
            marketItems[currentIndex] = item;
            currentIndex += 1;
        }
        return marketItems;
    }

    //offer on market item
    function getAllTokenOffers(uint256 marketItemId, address nftContract) public view returns (Offer[] memory) {
        return _offersToken[marketItemId][nftContract];
    }

    //item add to sell
    function fetchSellingMarketItems() public view returns (MarketItem[] memory) {
        return fetchMarketItemsByAddressProperty("seller");
    }

    //item sold
    function fetchOwnedMarketItems() public view returns (MarketItem[] memory) {
        return fetchMarketItemsByAddressProperty("owner");
    }

    function updateToken(address _newToken) external onlyOwner {
        tokens = _newToken;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokens != tokenAddress, "Cannot recover base token");
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, tokenAmount);
    }

    function fetchMarketItemsByAddressProperty(string memory _addressProperty) internal view returns (MarketItem[] memory){
        require(compareStrings(_addressProperty, "seller") || compareStrings(_addressProperty, "owner"), "Parameter must be seller or owner");
        uint256 totalItemsCount = _marketItemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemsCount; i++) {
            MarketItem storage item = marketItemIdToMarketItem[i + 1];
            address addressPropertyValue = getMarketItemAddressByProperty(item, _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            itemCount += 1;
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemsCount; i++) {
            MarketItem storage item = marketItemIdToMarketItem[i + 1];
            address addressPropertyValue = getMarketItemAddressByProperty(item, _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            items[currentIndex] = item;
            currentIndex += 1;
        }
        return items;
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getMarketItemAddressByProperty(MarketItem memory item, string memory property) private pure returns (address){
        require(compareStrings(property, "seller") || compareStrings(property, "owner"), "Parameter must be seller or owner");
        return compareStrings(property, "seller") ? item.seller : item.owner;
    }

    modifier isNFTAddress(address _nftAddress) {
        require(IERC721(_nftAddress).supportsInterface(INTERFACE_ID_ERC721),"invalid nft address");
        _;
    }

    event MarketItemCreated(
        uint256 indexed marketItemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address seller,
        address owner,
        uint256 bnbPrice,
        uint256 tokenPrice,
        bool sold,
        bool canceled
    );    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}