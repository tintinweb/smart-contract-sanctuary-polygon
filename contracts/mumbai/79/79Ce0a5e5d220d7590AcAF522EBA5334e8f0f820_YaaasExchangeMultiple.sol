pragma solidity >=0.4.22 <0.9.0;

import "./interfaces/IERC20.sol";
import "./Ownable.sol";
import "./interfaces/IYaaasExchangeMultiple.sol";
import "./libraries/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "./Loyalty.sol";


contract YaaasExchangeMultiple is
    Ownable,
    IYaaasExchangeMultiple,
    Loyalty,
    ERC1155HolderUpgradeable
{
    using SafeMath for uint256;

    //ERC1155
    mapping(uint256 => Offer) public offers;
    // For auctions bid by bider, collection and assetId
    mapping(uint256 => mapping(address => Bid)) public bidforAuctions;

    mapping(uint256 => uint256) public shares;

    constructor() {
        shares[1] = 1;
        shares[2] = 1;
        shares[3] = 1;
        shares[4] = 1;
        shares[5] = 1;
        shares[6] = 1;
        shares[7] = 1;
        shares[8] = 1;
    }
    function addLoyaltyOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        bool _isEther,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex,
        uint256 _loyaltyPercent
     ) public returns (bool success) {
        addLoyalty(_collection, _assetId, _msgSender(), _loyaltyPercent);
        // get NFT asset from seller
        IERC1155Upgradeable nftCollection = IERC1155Upgradeable(_collection);
        require(
            nftCollection.balanceOf(_msgSender(), _assetId) >= _amount,
            "Insufficient token balance"
        );
        
        require(_seller == _msgSender(), "Seller should be equals owner");
        require(
            nftCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );
        this._addOffer(
            _id,
            _seller,
            _collection,
            _assetId,
            _isEther,
            _price,
            _amount,
            _isForSell,
            _isForAuction,
            _expiresAt,
            _shareIndex
        );
        IERC1155Upgradeable(_collection).safeTransferFrom(
            _seller,
            address(this),
            _assetId,
            _amount,
            ""
        );
        return true;
    }
    /**
    * @dev Create new offer
    * @param _id an unique offer id
    * @param _seller the token owner
    * @param _collection the ERC1155 address
    * @param _assetId the NFT id
    * @param _isEther if sale in ether price
    * @param _price the sale price
    * @param _amount the amount of tokens owner wants to put in sale.
    * @param _isForSell if the token in direct sale
    * @param _isForAuction if the token in auctions
    * @param _expiresAt the offer's exprice date.
    * @param _shareIndex the percentage the contract owner earns in every sale
    */
    function addOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        bool _isEther,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex
    ) public returns (bool success) {
        // get NFT asset from seller
        IERC1155Upgradeable nftCollection = IERC1155Upgradeable(_collection);
        require(
            nftCollection.balanceOf(_msgSender(), _assetId) >= _amount,
            "Insufficient token balance"
        );
        
        require(_seller == _msgSender(), "Seller should be equals owner");
       require(
            nftCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );
        this._addOffer(
            _id,
            _seller,
            _collection,
            _assetId,
            _isEther,
            _price,
            _amount,
            _isForSell,
            _isForAuction,
            _expiresAt,
            _shareIndex
        );
        IERC1155Upgradeable(_collection).safeTransferFrom(
            _seller,
            address(this),
            _assetId,
            _amount,
            ""
        );
        return true;
    }
    function _addOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        bool _isEther,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex
    ) external returns (bool success) {
        require(!offers[_id].exists, "Offer exists already");
        offers[_id] = Offer(
            _seller,
            _collection,
            _assetId,
            _isEther,
            _price,
            _amount,
            _isForSell,
            _isForAuction,
            _expiresAt,
            _shareIndex,
            true//offer exists
        );
        emit Listed(_seller, _collection, _assetId, _amount, _price);
    }

    function setOfferPrice(
        uint256 id,
        uint256 price
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(id);
        offer.price = price;
        return true;
    }

    function setForSell(
        uint256 offerID,
        bool isForSell
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.isForSell = isForSell;
        return true;
    }

    function setForAuction(
        uint256 offerID,
        bool isForAuction
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.isForAuction = isForAuction;
        return true;
    }

    function setExpiresAt(
        uint256 offerID,
        uint256 expiresAt
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(offerID);
        require(_msgSender() == offer.seller, "Marketplace: invalid owner");
        offer.expiresAt = expiresAt;
        return true;
    }
    function cancelOffer(uint256 offerID) external returns (bool) {
         Offer storage offer = _getOwnerOffer(offerID);
         require(_msgSender() == offer.seller, "Marketpalce: invalid owner");
         require(offer.expiresAt < block.timestamp, "Offer should be expired");
         IERC1155Upgradeable(offer.collection).safeTransferFrom(
            address(this),
            offer.seller,
            offer.assetId,
            offer.amount,
            ""
        );
        delete offers[offerID];
    }

    function _getOwnerOffer(uint256 id)
        internal
        view
        returns (Offer storage)
    {
        Offer storage offer = offers[id];
        require(_msgSender() == offer.seller, "Marketplace: invalid owner");
        return offer;
    }

    function buyOffer(uint256 id, uint256 amount)
        public
        payable
        returns (bool success)
    {
        Offer storage offer = offers[id];
        require(msg.value > 0, "price must be >0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, offer.collection, amount);
        emit Swapped(
            _msgSender(),
            offer.seller,
            offer.collection,
            offer.assetId,
            msg.value
        );
        offer.amount = offer.amount.sub(amount);
        if(offer.amount == 0)
            delete offers[id];
        return true;
    }

    function _buyOffer(Offer storage offer, address collection, uint256 amount) internal {
        IERC1155Upgradeable nftCollection = IERC1155Upgradeable(collection);
        uint256 ownerBenif = (offer.price.mul(amount)).mul(shares[offer.shareIndex]).div(100);
        require(msg.value >= (offer.price.mul(amount).add(ownerBenif)),"Yaaas: Insufficient funds");
        uint256 sellerAmount = (msg.value).sub(ownerBenif);
        if( isInLoyalty( offer.collection, offer.assetId ) ){
            address creator = getCreator(offer.collection, offer.assetId);
            if( creator != offer.seller ){
                uint256 percent = getLoyalty(offer.collection, offer.assetId, creator);
                uint256 creatorBenif = (sellerAmount).mul(percent).div(100);
                (bool sentCreatorBenif, ) = creator.call{value: creatorBenif}("");
                if(sentCreatorBenif){
                    sellerAmount = sellerAmount.sub(creatorBenif);
                }
            }
        }
        
        address _to = offer.seller;
        if (offer.isEther) {
            (bool sent, ) = _to.call{value: sellerAmount}("");
            (bool benifSent, ) = owner().call{value: ownerBenif}("");
            require(sent, "Failed to send Ether");
            require(benifSent, "Failed to send Ether");
            nftCollection.safeTransferFrom(address(this), _msgSender(), offer.assetId, amount, "");
        }
       
    }

    function safePlaceBid(
        uint256 _offer_id,
        address _token,
        uint256 _price,
        uint256 _amount,
        uint256 _expiresAt
    ) public {
        _createBid(_offer_id, _token, _price, _amount,_expiresAt);
    }

    function setOwnerShare(uint256 index, uint256 newShare) public onlyOwner {
        require(newShare <= 100, "Owner Share must be >= 0 and <= 100");
        shares[index] = newShare;
        emit SetOwnerShare(index, newShare);
    }

    function _createBid(
        uint256 offerID,
        address _token,
        uint256 _price,
        uint256 _amount,
        uint256 _expiresAt
    ) internal {
        // Checks order validity
        Offer memory offer = offers[offerID];
        // check on expire time
        if (_expiresAt > offer.expiresAt) {
            _expiresAt = offer.expiresAt;
        }
        // Check price if theres previous a bid
        Bid memory bid = bidforAuctions[offerID][_msgSender()];
        require(bid.id == 0, "bid already exists");
        require(offer.isForAuction, "NFT Marketplace: NFT token not in sell");
        require(
            IERC20(_token).allowance(_msgSender(), address(this)) >= _price,
            "NFT Marketplace: Allowance error"
        );
        // Create bid
        bytes32 bidId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, _price, _expiresAt)
        );

        // Save Bid for this order
        bidforAuctions[offerID][_msgSender()] = Bid({
            id: bidId,
            bidder: _msgSender(),
            token: _token,
            price: _price,
            amount: _amount,
            expiresAt: _expiresAt
        });

        emit BidCreated(
            bidId,
            offer.collection,
            offer.assetId,
            _msgSender(), // bidder
            _token,
            _price,
            _amount,
            _expiresAt
        );
    }

    function cancelBid(
        uint256 _offerId,
        address _bidder
    ) external returns (bool) {
        Offer memory offer = offers[_offerId];
        require(
            _bidder == _msgSender() ||
                _msgSender() == offer.seller,
            "Marketplace: Unauthorized operation"
        );
        Bid memory bid = bidforAuctions[_offerId][_msgSender()];
        delete bidforAuctions[_offerId][_bidder];
        emit BidCancelled(bid.id);
        return true;
    }

    function acceptBid(
        uint256 _offerID,
        address _bidder
    ) public {
        //get offer
        Offer memory offer = offers[_offerID];
        // get bid to accept
        Bid memory bid = bidforAuctions[_offerID][_bidder];

        // get service fees
        uint256 ownerBenif = (bid.price).div(100).mul(shares[offer.shareIndex]);
        uint256 sellerAmount = (bid.price).sub(ownerBenif);
        // check seller
        if( isInLoyalty( offer.collection, offer.assetId )  ){
            address creator = getCreator(offer.collection, offer.assetId);
            if( creator != offer.seller ){
                uint256 percent = getLoyalty(offer.collection, offer.assetId, creator);
                uint256 creatorBenif = (sellerAmount).mul(percent).div(100);
                IERC20(bid.token).transferFrom(bid.bidder, _msgSender(), creatorBenif);
                sellerAmount = sellerAmount.sub(creatorBenif);
            }
        }
        require(
            offer.seller == _msgSender(),
            "Marketplace: unauthorized sender"
        );
        require(offer.isForAuction, "Marketplace: offer not in auction");
        require(offer.amount >= bid.amount , "Marketplace: insufficient balance");

        require(
            bid.expiresAt > block.timestamp,
            "Marketplace: the bid expired"
        );

        delete bidforAuctions[_offerID][_bidder];
        emit BidAccepted(bid.id);
        // transfer escrowed bid amount minus market fee to seller
        IERC20(bid.token).transferFrom(bid.bidder, _msgSender(), sellerAmount);
        IERC20(bid.token).transferFrom(bid.bidder, owner(), ownerBenif);
        offer.amount = offer.amount.sub(bid.amount);
        // Transfer NFT asset
        IERC1155Upgradeable(offer.collection).safeTransferFrom(
            address(this),
            bid.bidder,
            offer.assetId,
            bid.amount,
            ""
        );
        if(offer.amount == 0 )
            delete offers[_offerID];
        // Notify ..
        emit BidSuccessful(
            offer.collection,
            offer.assetId,
            bid.token,
            bid.bidder,
            bid.price,
            bid.amount
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity >=0.4.22 <0.9.0;

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity >=0.4.22 <0.9.0;
contract IYaaasExchangeMultiple{
     event Swapped(
        address  buyer,
        address  seller,
        address  token,
        uint256  assetId,
        uint256  price
    );
    event Listed(
        address seller,
        address collection,
        uint256 assetId,
        uint256 price,
        uint256 amount
    );
    struct Offer{
        address seller;
        address collection;
        uint256 assetId;
        bool isEther;
        uint256 price;
        uint256 amount;
        bool isForSell;
        bool isForAuction;
        uint256 expiresAt;
        uint shareIndex;
        bool exists;
    }
    struct Bid{
        bytes32 id;
        address bidder;
        address token;
        uint256 price;
        uint256 amount;
        uint256 expiresAt;
    }
    // BID EVENTS
    event BidCreated(
      bytes32 id,
      address indexed collection,
      uint256 indexed assetId,
      address indexed bidder,
      address  token,
      uint256 price,
      uint256 amount,
      uint256 expiresAt
    );
    event BidSuccessful(
        address collection,
        uint256 assetId,
        address token,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);
    event SetOwnerShare(uint256 index, uint256 newShare);
}

pragma solidity >=0.4.22 <0.9.0;

interface ILoyalty{

    function getLoyalty(
        address  collection, 
        uint256 assetId,
        address right_holder
    ) external view returns( uint256);

     event AddLoyalty( 
        address  collection, 
        uint256 assetId, 
        address  right_holder, 
        uint256  percent);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.4.22 <0.9.0;

import './interfaces/ILoyalty.sol';

contract Loyalty is ILoyalty{
    
    mapping(address=> mapping(uint256 => mapping(address=>uint256))) public loyalties;
    mapping(address=> mapping(uint256 => address)) public creators;
    mapping(address=> mapping(uint256 => bool)) public hasLoyalty;

    function addLoyalty(
        address  collection, 
        uint256  assetId, 
        address  right_holder, 
        uint256  percent) internal returns (bool)
    {
        require(percent > 0 && percent<=10 , 'Loyalty percent must be between 0 and 10');
        require(!_isInLoyalty(collection, assetId), 'NFT already in loyalty');
        creators[collection][assetId] = right_holder;
        return _addLoyalty(
            collection, 
            assetId, 
            right_holder, 
            percent);
    }
    function getLoyalty(
        address  collection, 
        uint256 assetId,
        address right_holder
    ) public view returns( uint256)
    {
        return loyalties[collection][assetId][right_holder];
    }
    function getCreator(
        address  collection, 
        uint256 assetId
    ) public view returns( address)
    {
        return creators[collection][assetId];
    }
    function isInLoyalty(address  collection, uint256 assetId) public view returns (bool){
        return _isInLoyalty(collection, assetId);
    }
    function _isInLoyalty(address  collection, uint256 assetId) internal view returns (bool){
        return hasLoyalty[collection][assetId];
    }
    function _addLoyalty(
        address  collection, 
        uint256 assetId, 
        address  right_holder, 
        uint256  percent
    )internal returns (bool){
        loyalties[collection][assetId][right_holder] = percent;
        hasLoyalty[collection][assetId] = true;
        emit AddLoyalty(collection, assetId, right_holder, percent);
        return true;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}