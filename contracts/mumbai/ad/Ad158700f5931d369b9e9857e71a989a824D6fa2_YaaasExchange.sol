pragma solidity >=0.4.22 <0.9.0;

import "./interfaces/IERC20.sol";
import "./Ownable.sol";
import "./ERC721Validator.sol";
import "./interfaces/IYaaasExchange.sol";
import "./interfaces/IERC721Receiver.sol";
import "./libraries/SafeMath.sol";
import "./Loyalty.sol";

contract YaaasExchange is
    Ownable,
    ERC721Validator,
    IYaaasExchange,
    Loyalty
{
    mapping(address => mapping(uint256 => Offer)) public offers;
    using SafeMath for uint256;
    // For auctions bid by bider, collection and assetId
    mapping(address => mapping(uint256 => mapping(address => Bid)))
        public bidforAuctions;
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
        address _seller,
        address _collection,
        uint256 _assetId,
        address token,
        bool isEther,
        uint256 _price,
        bool isForSell,
        bool isForAuction,
        uint256 expiresAt,
        uint256 shareIndex,
        uint256 loyaltyPercent
    )external returns (bool success) {
        // get NFT asset from seller
        IERC721 nftCollection = _requireERC721(_collection);
        require(
            nftCollection.ownerOf(_assetId) == _msgSender(),
            "Transfer caller is not owner"
        );
        require(_seller == _msgSender(), "Seller should be equals owner");
        require(
            nftCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );
        addLoyalty(_collection, _assetId, _msgSender(), loyaltyPercent);
        this._addOffer(
             _seller,
             _collection,
             _assetId,
             token,
             isEther,
             _price,
             isForSell,
             isForAuction,
             expiresAt,
             shareIndex
        );
        nftCollection.safeTransferFrom(_seller, address(this), _assetId);
        emit Listed(_seller, _collection, _assetId, token, _price);
        return true;
    }
    function addOffer(
        address _seller,
        address _collection,
        uint256 _assetId,
        address token,
        bool isEther,
        uint256 _price,
        bool isForSell,
        bool isForAuction,
        uint256 expiresAt,
        uint256 shareIndex
    ) external returns (bool success) {
        // get NFT asset from seller
        IERC721 nftCollection = _requireERC721(_collection);
        require(
            nftCollection.ownerOf(_assetId) == _msgSender(),
            "Transfer caller is not owner"
        );
        require(_seller == _msgSender(), "Seller should be equals owner");
        require(
            nftCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );
        this._addOffer(
            _seller,
            _collection,
            _assetId,
            token,
            isEther,
            _price,
            isForSell,
            isForAuction,
            expiresAt,
            shareIndex
        );
        nftCollection.safeTransferFrom(_seller, address(this), _assetId);
        emit Listed(_seller, _collection, _assetId, token, _price);
        return true;
    }

    function _addOffer(
        address _seller,
        address _collection,
        uint256 _assetId,
        address token,
        bool isEther,
        uint256 _price,
        bool isForSell,
        bool isForAuction,
        uint256 expiresAt,
        uint256 shareIndex
    ) external returns (bool success) {
        require(! offers[_collection][_assetId].exists, "Offer exists already");
        bytes32 OfferId = keccak256(
            abi.encodePacked(
                block.timestamp,
                _seller,
                _collection,
                _assetId,
                expiresAt
            )
        );
        offers[_collection][_assetId] = Offer(
            OfferId,
            _seller,
            _collection,
            _assetId,
            token,
            isEther,
            _price,
            isForSell,
            isForAuction,
            expiresAt,
            shareIndex,
            true// offer exists
        );
    }

    function setOfferPrice(
        address collection,
        uint256 assetId,
        uint256 price
    ) external returns (bool) {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        offer.price = price;
        return true;
    }

    function setForSell(
        address collection,
        uint256 assetId,
        bool isForSell
    ) external returns (bool) {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        IERC721 nftCollection = _requireERC721(collection);
        offer.isForSell = isForSell;
        if (!isForSell) {
            nftCollection.safeTransferFrom(
                address(this),
                _msgSender(),
                assetId
            );
        } else {
            nftCollection.safeTransferFrom(
                _msgSender(),
                address(this),
                assetId
            );
        }
        return true;
    }

    function setForAuction(
        address collection,
        uint256 assetId,
        bool isForAuction
    ) external returns (bool) {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        offer.isForAuction = isForAuction;
        return true;
    }

    function setExpiresAt(
        address collection,
        uint256 assetId,
        uint256 expiresAt
    ) external returns (bool) {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        offer.expiresAt = expiresAt;
        return true;
    }
    function cancelOffer(address collection,uint256 assetId) external returns (bool) {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        IERC721 nftCollection = _requireERC721(collection);
         require(_msgSender() == offer.seller, "Marketpalce: invalid owner");
         require(offer.expiresAt < block.timestamp, "Offer should be expired");
         nftCollection.safeTransferFrom(
            address(this),
            offer.seller,
            offer.assetId
        );
        delete offers[collection][assetId];
    }

    function _getOwnerOffer(address collection, uint256 assetId)
        internal
        view
        returns (Offer storage)
    {
        Offer storage offer = offers[collection][assetId];
        require(_msgSender() == offer.seller, "Marketplace: invalid owner");
        return offer;
    }

    function buyOffer(address collection, uint256 assetId)
        external
        payable
        returns (bool success)
    {
        Offer storage offer = offers[collection][assetId];
        require(msg.value > 0, "price must be >0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, collection);
        emit Swapped(
            _msgSender(),
            offer.seller,
            collection,
            assetId,
            msg.value
        );
        return true;
    }

    function _buyOffer(Offer storage offer, address collection) internal {
        IERC721 nftCollection = _requireERC721(collection);
        uint256 total = msg.value;
        uint256 ownerBenif = (offer.price).mul(shares[offer.shareIndex]).div(100);
        uint256 sellerAmount = total.sub(ownerBenif);
        require(
            offer.price <= sellerAmount,
            "price should equal or upper to offer price"
        );
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
            nftCollection.transferFrom(address(this), _msgSender(), offer.assetId);
            delete offers[offer.collection][offer.assetId];
        }
        
    }

    function safePlaceBid(
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        uint256 _expiresAt
    ) public {
        _createBid(_collection, _assetId, _token, _price, _expiresAt);
    }

    function setOwnerShare(uint256 index, uint256 newShare) public onlyOwner {
        require(newShare <= 100, "Owner Share must be >= 0 and <= 100");
        shares[index] = newShare;
        emit SetOwnerShare(index, newShare);
    }

    function _createBid(
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        uint256 _expiresAt
    ) internal {
        // Checks order validity
        Offer memory offer = offers[_collection][_assetId];
        // check on expire time
        if (_expiresAt > offer.expiresAt) {
            _expiresAt = offer.expiresAt;
        }
        // Check price if theres previous a bid
        Bid memory bid = bidforAuctions[_collection][_assetId][_msgSender()];
        require(bid.bidder != _msgSender(), "bid already exists");
        require(_msgSender() != offer.seller, "owner could not place bid");
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
        bidforAuctions[_collection][_assetId][_msgSender()] = Bid({
            id: bidId,
            bidder: _msgSender(),
            token: _token,
            price: _price,
            expiresAt: _expiresAt
        });

        emit BidCreated(
            bidId,
            _collection,
            _assetId,
            _msgSender(), // bidder
            _token,
            _price,
            _expiresAt
        );
    }

    function cancelBid(
        address _collection,
        uint256 _assetId,
        address _bidder
    ) external returns (bool) {
        IERC721 nftCollection = _requireERC721(_collection);
        require(
            _bidder == _msgSender() ||
                _msgSender() == nftCollection.ownerOf(_assetId),
            "Marketplace: Unauthorized operation"
        );
        Bid memory bid = bidforAuctions[_collection][_assetId][_msgSender()];
        delete bidforAuctions[_collection][_assetId][_bidder];
        emit BidCancelled(bid.id);
        return true;
    }

    function acceptBid(
        address _collection,
        uint256 _assetId,
        address _bidder
    ) external {
        //get offer
        Offer memory offer = offers[_collection][_assetId];
        // get bid to accept
        Bid memory bid = bidforAuctions[_collection][_assetId][_bidder];
        require(
            offer.seller == _msgSender(),
            "Marketplace: unauthorized sender"
        );
        require(offer.isForAuction, "Marketplace: offer not in auction");

        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: the bid expired"
        );
        uint256 total = bid.price;
        // get service fees
        uint256 ownerBenif = (total).div(100).mul(shares[offer.shareIndex]);
        uint256 sellerAmount = (total).sub(ownerBenif);
        if( isInLoyalty( offer.collection, offer.assetId ) ){
            address creator = getCreator(offer.collection, offer.assetId);
            if( creator != offer.seller ){
                uint256 percent = getLoyalty(offer.collection, offer.assetId, creator);
                uint256 creatorBenif = (sellerAmount).mul(percent).div(100);
                IERC20(bid.token).transferFrom(bid.bidder, _msgSender(), creatorBenif);
                sellerAmount = sellerAmount.sub(creatorBenif);
            }
        }
        // check seller
        delete bidforAuctions[_collection][_assetId][_bidder];
        emit BidAccepted(bid.id);
        // transfer escrowed bid amount minus market fee to seller
        IERC20(bid.token).transferFrom(bid.bidder, _msgSender(), sellerAmount);
        IERC20(bid.token).transferFrom(bid.bidder, owner(), ownerBenif);

        delete offers[_collection][_assetId];
        // Transfer NFT asset
        IERC721(_collection).safeTransferFrom(
            address(this),
            bid.bidder,
            _assetId
        );
        // Notify ..
        emit BidSuccessful(
            _collection,
            _assetId,
            bid.token,
            bid.bidder,
            bid.price
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
contract IYaaasExchange{
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
        address token,
        uint256 price
    );
    struct Offer{
        bytes32 id;
        address seller;
        address collection;
        uint256 assetId;
        address token;
        bool isEther;
        uint256 price;
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
      uint256 expiresAt
    );
    event BidSuccessful(
        address collection,
        uint256 assetId,
        address token,
        address bidder,
        uint256 price
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `assetId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 assetId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `assetId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed assetId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `assetId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed assetId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `assetId` token.
     *
     * Requirements:
     *
     * - `assetId` must exist.
     */
    function ownerOf(uint256 assetId) external view returns (address owner);

    /**
     * @dev Safely transfers `assetId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `assetId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 assetId) external;

    /**
     * @dev Transfers `assetId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `assetId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 assetId) external;

    /**
     * @dev Gives permission to `to` to transfer `assetId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `assetId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 assetId) external;

    /**
     * @dev Returns the account approved for `assetId` token.
     *
     * Requirements:
     *
     * - `assetId` must exist.
     */
    function getApproved(uint256 assetId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `assetId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `assetId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 assetId, bytes calldata data) external;
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

pragma solidity >=0.4.22 <0.9.0;
import "./interfaces/IERC721.sol";
contract ERC721Validator{
    bytes4  constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    function _requireERC721(address _nftAddress) internal view returns (IERC721) {
    /*  
    require(
      IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
      "The NFT contract has an invalid ERC721 implementation"
    );
    */
    return IERC721(_nftAddress);
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