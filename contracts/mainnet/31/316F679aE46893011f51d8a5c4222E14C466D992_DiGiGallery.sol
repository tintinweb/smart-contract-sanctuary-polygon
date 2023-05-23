/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/** @author DiGi Official credit to thirdweb
*    
*   ██████╗ ██╗ ██████╗ ██╗     ██████╗  █████╗ ██╗     ██╗     ███████╗██████╗ ██╗   ██╗
*   ██╔══██╗██║██╔════╝ ██║    ██╔════╝ ██╔══██╗██║     ██║     ██╔════╝██╔══██╗╚██╗ ██╔╝
*   ██║  ██║██║██║  ███╗██║    ██║  ███╗███████║██║     ██║     █████╗  ██████╔╝ ╚████╔╝ 
*   ██║  ██║██║██║   ██║██║    ██║   ██║██╔══██║██║     ██║     ██╔══╝  ██╔══██╗  ╚██╔╝  
*   ██████╔╝██║╚██████╔╝██║    ╚██████╔╝██║  ██║███████╗███████╗███████╗██║  ██║   ██║   
*   ╚═════╝ ╚═╝ ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝      
*
* @author  digiofficial.xyz
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

pragma solidity ^0.8.0;

contract DiGiGallery is Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant VERSION = "0.1.0";
    
    mapping(address => bool) ERC20TokenSupport;
    
    enum OrderType { None, FixedPrice, DutchAuction}
    enum Status { Unknown, Open, Executed, Cancelled}

    uint256 public maxAuctionDuration = 2 weeks;

    struct Order {
        OrderType orderType;
        Status  status;
        address collection;
        address ERC20Token;
        address maker;
        address taker;
        uint256 basePrice;
        uint256 endingPrice;
        uint256 nftid;
        uint256 listingTime;
        uint256 expirationTime;
    }

    struct Offer{
        Status  status; 
        address collection;
        address ERC20Token;
        address buyer;
        uint256 nftid;
        uint256 price;
        uint256 expirationTime;
    }

    struct Auction {
        address collection;
        address ERC20Token;
        address maker;
        address maxBidder;
        uint256 listingTime;
        uint256 expirationTime;
        Status status;
        uint256 nftid;
        uint256 basePrice;
        uint256 minimalIncrement; 
        uint256 extra;            
        uint256 maxPrice;
    }

    Counters.Counter private orderCounter;
    mapping(uint256 => Order) private orders;

    Counters.Counter private offerCounter;
    mapping(uint256 => Offer) private offers;

    Counters.Counter private auctionCounter;
    mapping(uint256 => Auction) private auctions;

    Counters.Counter private bidCounter;
    
    mapping (address => mapping(uint256 => mapping(address => uint256))) private exclusiveSpot; 

    uint256 private feeBps = 500;  
    address private feeBeneficiary = 0xd53B6196F526b2cf0a5F3a35a03B23B2D02b26c4;  
    uint256 public maxAllowedRoyaltyBps = 2000;

    mapping(address => bool) private collection2CustomizedRoyaltyFlag;
    mapping(address => uint256) private collection2royaltyratio;
    mapping(address => address) private collection2royaltybeneficiary;
    

    /*╔═════════════════════════════╗
      ║      Admin Operations       ║
      ╚═════════════════════════════╝*/

    function pause() external onlyOwner { _pause();}
    function unpause() external onlyOwner {_unpause();}

    function getCollectionRoyaltyInfo(address _collection) external view returns(bool, address,uint256){
        return (collection2CustomizedRoyaltyFlag[_collection], collection2royaltybeneficiary[_collection], collection2royaltyratio[_collection]);
    }

    function setCollectionRoyaltyInfo(
             address _collection, 
             bool    _flag,
             address _newBeneficiary,
             uint256 _newRatio) external onlyOwner{ 
        require(_newRatio <= maxAllowedRoyaltyBps, "Royalty is too high");

        collection2CustomizedRoyaltyFlag[_collection] = _flag;
        collection2royaltybeneficiary[_collection] = _newBeneficiary;
        collection2royaltyratio[_collection] = _newRatio;

        emit SetRoyalty(_collection,_newBeneficiary,_newRatio);
    } 

    function getERC20TokenSupport(address _collection) external view returns(bool) { return ERC20TokenSupport[_collection];} 
    function setERC20TokenSupport(address _collection, bool _ifSupported) external onlyOwner{ ERC20TokenSupport[_collection] = _ifSupported;} 
    
    function getMaxAllowedRoyaltyRatio() external view returns(uint256) { return maxAllowedRoyaltyBps;}
    function setMaxAllowedRoyaltyRatio(uint256 _newValue) external onlyOwner{ maxAllowedRoyaltyBps = _newValue;}
    
    function getMaxAuctionDuration() external view returns(uint256) { return maxAuctionDuration;}
    function setMaxAuctionDuration(uint256 _newValue) external onlyOwner{ maxAuctionDuration = _newValue;} 

    constructor (){}

    function getPlatformFee() external view returns(address, uint256) {
        return (feeBeneficiary,feeBps);
    }

    function setPlatformFee(address _beneficiary,uint256 _feeBps) external onlyOwner{
        require(_feeBps<5000, "invalid feerate");
        feeBeneficiary = _beneficiary;
        feeBps = _feeBps;
    }


   /*╔═════════════════════════════╗
     ║           Orders            ║
     ╚═════════════════════════════╝*/   

    /**
     * @dev List an NFT with a price, which can be bought immediately
     * 
     * Requirements:
     *  
     *      `_collection` should implement IERC721 interfaces
     *      `_ERC20Token` is address(0) if seller uses $Rose for settlement, 
     *                    or it should be an ERC20 Token supported by MMG.  see {ERC20TokenSupport}
     *      `_basePrice`  should be at least 1 wei
     *      `_endingPrice` is used in Dutch auction, and it should always be lower than `_basePrice`
     *      `_taker`      is address(0) if anyone can buy it
     *      `_expirationTime` should be larger than `_listingTime`
     *
     *      Also, a seller can only have up to one valid order of the same item at a time
     */
    function newOrder(address _collection, 
                      address _ERC20Token,
                      uint256 _nftid,
                      OrderType _ordertype, 
                      uint256 _basePrice,
                      uint256 _endingPrice, 
                      address _taker, 
                      uint256 _listingTime, 
                      uint256 _expirationTime) 
                      external  nonReentrant whenNotPaused{
        
        require(_basePrice > 0, "Price must be at least 1 wei");
        require(_endingPrice <= _basePrice, "Invalid ending price");
        require( _expirationTime > _listingTime, "Invalid time");
        
        if(_ERC20Token!=address(0)){
            require( ERC20TokenSupport[_ERC20Token], "ERC20Token is not supported");
        }

        require(
            IERC721(_collection).ownerOf(_nftid) == msg.sender,
            "You are not the owner"
        );

        uint256 orderidOnExclusiveSpot = exclusiveSpot[_collection][_nftid][msg.sender];
        require( orderidOnExclusiveSpot==0 || (!_validateOrder(orderidOnExclusiveSpot-1)), "You can only have up to one valid order at a time" );
        
        uint256 orderId = orderCounter.current();
        orderCounter.increment();

        orders[orderId] = Order({
            collection:_collection,
            ERC20Token:_ERC20Token,
            orderType:_ordertype,
            maker: msg.sender,
            taker: _taker,
            nftid: _nftid,
            basePrice: _basePrice,
            endingPrice: _endingPrice,
            listingTime:_listingTime,
            expirationTime:_expirationTime,
            status: Status.Open        
        });

        exclusiveSpot[_collection][_nftid][msg.sender] = orderId+1;
        emit NewOrder(_collection, orderId, _nftid,_ERC20Token, _ordertype, msg.sender, _taker, _basePrice, _endingPrice, _listingTime, _expirationTime, block.timestamp);
    }
    

    /**
     * @dev Update the price of an Item
     * 
     * Requirements:
     *  
     *      Only fixedprice order can be updated, i.e. `orderType` == 1
     *      Only valid order can be updated, i.e., `status` == 1 && `now` is in [listingTime, expirationTime]
     */
    function updateOrderPrice(uint256 _orderid, 
                              uint256 _basePrice) 
                              external  whenNotPaused{
        Order storage order = orders[_orderid];
        require(order.status == Status.Open, "Order is closed.");
        require(order.orderType == OrderType.FixedPrice, "Only fixedprice order can be updated.");
        require(block.timestamp <= order.expirationTime && block.timestamp >= order.listingTime, "Invalid time.");
        require(msg.sender == order.maker,"Order can be updated only by seller.");

        uint256 oldPrice = order.basePrice;
        order.basePrice = _basePrice;
        emit UpdateOrderPrice(order.collection, _orderid, oldPrice, _basePrice, block.timestamp);
    } 

    
    function cancelOrder(uint256 _orderid) external {
        Order storage order = orders[_orderid];
        require(order.status == Status.Open, "Order is already closed.");
        require(block.timestamp <= order.expirationTime && block.timestamp >= order.listingTime, "Invalid time.");
        require(msg.sender == order.maker,"Order can be cancelled only by seller.");

        order.status = Status.Cancelled;
        emit CancelOrder(order.collection, _orderid, block.timestamp);
    } 

    /**
     * @dev buy the item 
     * 
     * Requirements:
     *  
     *      The owner is still the owner, and MMG has the approval 
     *      Only valid order can be updated, i.e., `status` == 1 && `now` is in [listingTime, expirationTime]
     *      Once `_taker` is not address(0), only the `_taker` can buy it
     *      If $Rose is not used for settlement, this function will not accept any $Rose
     *
     */
    function buynow (uint256 _orderid) external payable nonReentrant whenNotPaused{
    
        Order storage order = orders[_orderid];
        IERC721 collection_contract = IERC721(order.collection);
        require(order.status == Status.Open, "Order is closed.");
        require(collection_contract.ownerOf(order.nftid) == order.maker, "Owner changed.");
        require(block.timestamp <= order.expirationTime && block.timestamp >= order.listingTime, "Invalid time.");
        
        if(order.taker != address(0)){
            require(msg.sender == order.taker, "This order is not for you.");
        }

        uint256 currentPrice = getCurrentPrice(order.orderType, order.basePrice, order.endingPrice, order.listingTime, order.expirationTime);

        //For Dutch auction with $Rose settlment, it is possible to give more $Rose than the actual price. So I will return the excess here.  
        if(order.ERC20Token == address(0)){
            require(msg.value >= currentPrice, "Invalid rose amount");
            
            uint256 moneyToRefund =  msg.value - currentPrice;
            if(moneyToRefund > 0){
                require(payable(msg.sender).send(moneyToRefund), "Failed to refund.");
            }
        }else{
            require(msg.value == 0, "You should not pay any Rose.");
        }

        _revenueShare(currentPrice, order.collection, order.nftid, order.ERC20Token, order.maker, msg.sender);

        collection_contract.transferFrom(order.maker, msg.sender, order.nftid);
        
        order.status = Status.Executed;
        emit Purchase(order.collection, _orderid, order.nftid, order.maker, msg.sender, currentPrice, block.timestamp);

    }

    /*╔═════════════════════════════╗
      ║           Offers            ║
      ╚═════════════════════════════╝*/
    
    /**
     * @dev Make a new offer for some item 
     * 
     * Requirements:
     *   
     *      If $Rose is used for settlement, buyer should transfer $Rose to MMG in advance
     *      If $Rose is not used for settlement, this function will not accept any $Rose
     *
     */
    function newOffer( address _collection, 
                       address _erc20Token, 
                       uint256 _nftid, 
                       uint256 _price, 
                       uint256 _expirationTime) 
                       external payable nonReentrant whenNotPaused{
        
        if(_erc20Token == address(0)){
            require(msg.value == _price, "Invalid rose amount");
        }else{
            require( ERC20TokenSupport[_erc20Token], "ERC20Token is not supported");
            require(msg.value == 0, "You should not pay any Rose.");
            IERC20 paymenttoken = IERC20(_erc20Token);
            require(paymenttoken.balanceOf(msg.sender)>=_price && paymenttoken.allowance(msg.sender, address(this))>=_price, "Exceed max allowance" );
        }

        uint256 offerId = offerCounter.current();
        offerCounter.increment();

        offers[offerId] = Offer({
            collection:_collection,
            ERC20Token:_erc20Token,
            buyer: msg.sender,
            nftid: _nftid,
            price: _price,
            expirationTime:_expirationTime,
            status: Status.Open
        });

        emit NewOffer(_collection, offerId, _nftid, msg.sender, _erc20Token, _price, _expirationTime, block.timestamp);
    }
    
    /**
     * @dev Accept the offer 
     * 
     * Requirements:
     *   
     *      The owner is still the owner
     *      The offer is still valid, i.e. `status` ==1 && not expired
     *
     */
    function takeOffer(uint256 _offerid) external nonReentrant whenNotPaused{

        Offer storage offer = offers[_offerid];
        IERC721 collection_contract = IERC721(offer.collection);
        require(offer.status == Status.Open, "Offer is not Open.");
        
        //Only the owner can take the offer
        require(collection_contract.ownerOf(offer.nftid) == msg.sender, "You are not the owner");

        require(block.timestamp <= offer.expirationTime, "Invalid time.");

        _revenueShare(offer.price, offer.collection, offer.nftid, offer.ERC20Token, msg.sender, offer.buyer);

        collection_contract.transferFrom(msg.sender, offer.buyer, offer.nftid);
        offer.status = Status.Executed;
        emit TakeOffer(offer.collection, _offerid, offer.nftid, msg.sender, offer.buyer, offer.ERC20Token, offer.price, block.timestamp);
    }

    /**
     * @dev Cancel the offer 
     * 
     * Note: The buyer can still cancel the offer even when the offer is expired.
     *   
     *
     */
    function cancelOffer(uint256 _offerid) external nonReentrant whenNotPaused {
        Offer storage offer = offers[_offerid];
        
        require( msg.sender == offer.buyer, "Offer can be cancelled only by buyer.");
        require(offer.status == Status.Open, "Offer is not Open.");
        // require(block.timestamp <= offer.expirationTime, "Invalid time.");

        if(offer.ERC20Token == address(0)){
            require(payable(offer.buyer).send(offer.price), "Failed to send to the buyer.");
        }

        offer.status = Status.Cancelled;
        emit CancelOffer(offer.collection, _offerid, block.timestamp); 
    }

    /*╔═════════════════════════════╗
      ║            Bid              ║
      ╚═════════════════════════════╝*/

    /**
     * @dev Create a new auction
     * 
     * NOTE Auction is in custodial pattern.
     *      We allow cancellation of the auction until a bid is placed.
     *      Seller can set both basePrice and a buynowPrice.
     *
     * Requirements:
     *   
     *      `_minimalIncrement` means that this bid needs to exceed the previous one by a percentage.
     *                          It the should be in [1-100], which means the 1%-100% 
     *      `_extra` is the buynow price. But why don't I just name it "buynowPrice"?
     *       Also, if you has listed the item with a fixed price, you cannot make an auction for it.
     *
     */
    function newAuction(address _collection, 
                      address _ERC20Token,  
                      uint256 _nftid, 
                      uint256 _basePrice,
                      uint256 _minimalIncrement,
                      uint256 _extra, 
                      uint256 _listingTime, 
                      uint256 _expirationTime) 
                      external nonReentrant whenNotPaused{
        
        IERC721 collection_contract = IERC721(_collection);
        collection_contract.transferFrom(msg.sender, address(this), _nftid);
        require(_minimalIncrement >=1 && _minimalIncrement <=100, "Invalid increment");
        require( (_expirationTime > _listingTime) && (_expirationTime - _listingTime <= maxAuctionDuration), "Invalid time");
        if(_ERC20Token!=address(0)){
            require( ERC20TokenSupport[_ERC20Token], "ERC20Token is not supported");
        }

        uint256 orderidOnExclusiveSpot = exclusiveSpot[_collection][_nftid][msg.sender];
        require( orderidOnExclusiveSpot==0 || (!_validateOrder(orderidOnExclusiveSpot-1)), "You can only have up to one valid order at a time" );
        
        uint256 auctionId = auctionCounter.current();
        auctionCounter.increment();

        auctions[auctionId] = Auction({
            collection:_collection,
            ERC20Token:_ERC20Token,
            maker: msg.sender,
            nftid: _nftid,
            basePrice: _basePrice,
            minimalIncrement: _minimalIncrement,
            extra:_extra,
            maxPrice:_basePrice,
            maxBidder:address(0),
            listingTime:_listingTime,
            expirationTime:_expirationTime,
            status: Status.Open
        });

        emit NewAuction(_collection, auctionId, _nftid, _ERC20Token, msg.sender, _basePrice, _minimalIncrement, _extra, _listingTime, _expirationTime, block.timestamp);
    }


    /**
     * @dev Create a new bid
     * 
     * NOTE Each bid will immediately refund the previous bid
     *      If the bid price is higher than the buynow price, the auction will be settled immediately with the `_bidPrice`
     *      
     *
     * Requirements:
     *    
     *      `_bidPrice` should higher than (100+minimalIncrement)% * previous bid price
     *       If $Rose is not used for settlement, this function will not accept any $Rose
     *       
     *
     */
    function bid(uint256 _auctionId, 
                 uint256 _bidPrice) 
                 external payable nonReentrant whenNotPaused {

        Auction storage auction = auctions[_auctionId];
        IERC20 paymenttoken = IERC20(auction.ERC20Token);
        require(msg.sender == tx.origin);
        require(auction.status == Status.Open, "Auction is not open.");
        require(block.timestamp <= auction.expirationTime && block.timestamp >= auction.listingTime, "Invalid time.");
        if(auction.ERC20Token == address(0)){
            require(_bidPrice == msg.value, "Invalid Rose amount.");
        }else{
            require(msg.value == 0, "You should not pay any Rose.");
        }
        
        /**
          * Check the price & refund to last bidder
          * if this is the first bid, 
          *      1) _bidPrice >= basePrice 
          *      2) no need to refund
          *  or 
          *      1) _bidPrice >= lastbidprice + minimalIncrement 
          *      2) refund
          */
        if(auction.maxBidder != address(0)){
            require(_bidPrice >= getMinBidPrice(auction.maxPrice, auction.minimalIncrement), "Your price is too slow.");
            
            if(auction.ERC20Token != address(0)){
                paymenttoken.transfer(auction.maxBidder, auction.maxPrice);
            }else{
                payable(auction.maxBidder).transfer(auction.maxPrice);
            }
            
        }else{
            require(_bidPrice >= auction.basePrice, "Your price is too slow." );   
        }

        // buy now
        if(auction.extra>0 && _bidPrice >= auction.extra){
            IERC721 collection_contract = IERC721(auction.collection);
            collection_contract.transferFrom( address(this), msg.sender, auction.nftid);

            _revenueShare(_bidPrice, auction.collection, auction.nftid, auction.ERC20Token, auction.maker, msg.sender);

            auction.status = Status.Executed;
            emit SettleAuction(auction.collection, _auctionId, auction.nftid, auction.maker, msg.sender, msg.value, block.timestamp);
            return;
        }

        // transfer token to mp contract
        if(auction.ERC20Token != address(0)){
            paymenttoken.transferFrom(msg.sender, address(this), _bidPrice);   
        }

        auction.maxPrice  = _bidPrice;
        auction.maxBidder = msg.sender;

        //refresh the expirationTime
        if (block.timestamp + 10 minutes > auction.expirationTime){
            auction.expirationTime = block.timestamp + 10 minutes;
        }

        //for UU
        uint256 bidId = bidCounter.current();
        bidCounter.increment();

        emit NewBid(auction.collection, _auctionId, auction.nftid, msg.sender, _bidPrice, block.timestamp, bidId);
    }

    /**
     * @dev Settle the auction
     * 
     * NOTE If there is no bid, this function will serve as cancellation
     *      
     *      
     *
     * Requirements:
     *    
     *       Once there is a bid, the auction can only be settled after expiration.
     *       Only the winner/seller/MMG can settle the auction.
     *      
     *
     */
    function settleAuction(uint256 _auctionId) external nonReentrant whenNotPaused{

        Auction storage auction = auctions[_auctionId];
        require(auction.status == Status.Open , "Auction is not open.");
        IERC721 collection_contract = IERC721(auction.collection);
        
        if(auction.maxBidder == address(0)){
            require(auction.maker == msg.sender || msg.sender == owner(), "Only maker can cancel the auction.");
            collection_contract.transferFrom( address(this), auction.maker, auction.nftid);
            auction.status = Status.Cancelled;
            emit CancelAuction(auction.collection, _auctionId, block.timestamp);

        }else{
            require(block.timestamp > auction.expirationTime, "You can only settle the auction after the expiration.");
            require(msg.sender == auction.maker || msg.sender ==auction.maxBidder || msg.sender == owner(), "You are not allowed to settle the auction.");
            collection_contract.transferFrom( address(this), auction.maxBidder, auction.nftid);
            uint256 currentPrice = auction.maxPrice;

            _revenueShare(currentPrice, auction.collection, auction.nftid, auction.ERC20Token, auction.maker, address(this));
            
            auction.status = Status.Executed;

            emit SettleAuction(auction.collection, _auctionId, auction.nftid, auction.maker, auction.maxBidder, auction.maxPrice, block.timestamp);
        }
    }

    /*╔═════════════════════════════╗
      ║           utils             ║
      ╚═════════════════════════════╝*/


    function _validateOrder(uint256 _orderid) internal view returns (bool){

        Order storage order = orders[_orderid];
        return order.status == Status.Open && block.timestamp <= order.expirationTime && block.timestamp >= order.listingTime;
    }

    function getCurrentPrice(OrderType _orderType, 
                             uint256 basePrice, 
                             uint256 endingPrice, 
                             uint256 listingTime, 
                             uint256 expirationTime)
                             public view returns (uint256){
        
        if (_orderType == OrderType.FixedPrice) {
            return basePrice;
        }

        require(endingPrice < basePrice, "Invalid price");
        require(expirationTime > listingTime, "Invalid timestamp");

        if(block.timestamp >= expirationTime){
            return endingPrice;
        }
        
        uint256 extra = basePrice - endingPrice;
        uint256 diff = (extra * (block.timestamp - listingTime)) /(expirationTime - listingTime);
        return  basePrice - diff;
        
    }

    function getMinBidPrice(uint256 currentBidPrice, uint256 minimalIncrement) public pure returns (uint256 minBidPrice){
        require(minimalIncrement >=1 && minimalIncrement <=100, "invalid increment");
        minBidPrice = currentBidPrice * (100 + minimalIncrement)/100;
    }

    /**
     * @dev get tbe royalty information of an item
     * 
     * NOTE If the owner of the collection config the royalties on MMG, we will use it directly.
     *      Otherwise we will try to access the ERC2981. 
     *      Also, we will refuse some excessively high royalties 
     *
     */
    function getRoyaltyInfo(address _collection,
                            uint256 _tokenId, 
                            uint256 _salePrice) 
                            public view returns (address receiver, uint256 amount){
        
        if(collection2CustomizedRoyaltyFlag[_collection]){
            receiver = collection2royaltybeneficiary[_collection];
            amount = _salePrice * collection2royaltyratio[_collection]/10_000;
        }else{
            IERC2981 collection_contract = IERC2981(_collection);
            if (
                !collection_contract.supportsInterface(
                    type(IERC2981).interfaceId
                )
            ) {
                return (address(0), 0);
            }
            (receiver, amount) = collection_contract.royaltyInfo(
                _tokenId,
                _salePrice
            );
            //validate the royalty amount. return 0,0 if too high
            if (amount > (_salePrice * maxAllowedRoyaltyBps) / 10_000) {
                return (address(0), 0);
            }

        }
    }


    function _revenueShare(uint256 _currentPrice, 
                           address _collection, 
                           uint256 _nftid, 
                           address _ERC20token,
                           address _seller,
                           address _erc20From) internal{

            uint256 fee = (_currentPrice * feeBps) / 10_000;
            (address beneficiary, uint256 royaltyAmount) = getRoyaltyInfo(_collection, _nftid, _currentPrice);
            uint256 amount_after = _currentPrice - (royaltyAmount + fee);

            //settlement in Rose
            if(_ERC20token == address(0)){
                require(payable(feeBeneficiary).send(fee), "Failed to send");
                require(payable(_seller).send(amount_after), "Failed to send to the seller.");

                if(royaltyAmount >0 && beneficiary != address(0)) {
                    require(payable(beneficiary).send(royaltyAmount), "Failed to send to the royalty beneficiary.");
                }
                return;
            //settlement in ERC20 
            }else{
                require( ERC20TokenSupport[_ERC20token], "ERC20Token is not supported");
                IERC20 paymenttoken = IERC20(_ERC20token);
                _ERC20transfer(paymenttoken, _erc20From, _seller, amount_after);
                _ERC20transfer(paymenttoken, _erc20From, feeBeneficiary, fee);
                _ERC20transfer(paymenttoken, _erc20From, beneficiary, royaltyAmount);

            }
    }

    function _ERC20transfer(IERC20 target, address from, address to, uint256 amount) internal{
        if(to == address(0) || amount == 0) return;
        
        if(from == address(this)){
            target.transfer(to, amount);
        }else{
            target.transferFrom(from, to, amount);
        }
    }

    /*╔═════════════════════════════╗
      ║          migration          ║
      ╚═════════════════════════════╝*/ 

    //I will refund the offer(if they paid py $Rose) when I rug
    function cancelOfferByAdmin(uint256 _offerid) external onlyOwner  nonReentrant{

        Offer storage offer = offers[_offerid];
        require(offer.status == Status.Open, "Offer is not Open.");

        if(offer.ERC20Token == address(0)){
            require(payable(offer.buyer).send(offer.price), "Failed to send to the buyer.");
        }
        offer.status = Status.Cancelled;
        emit CancelOffer(offer.collection, _offerid, block.timestamp); 
    }

    /*╔═════════════════════════════╗
      ║           Events            ║
      ╚═════════════════════════════╝*/

    event NewOrder(address indexed collection, uint256 indexed orderId, uint256 indexed nftid, address erc20Token, OrderType orderType, address maker, address taker, uint256 basePrice, uint256 endingPrice, uint256 listingTime, uint256 expirationTime, uint256 blockTime);
    event UpdateOrderPrice(address indexed collection,uint256 indexed orderId, uint256 oldPrice, uint256 newPrice, uint256 blockTime);
    event CancelOrder(address indexed collection, uint256 indexed orderId, uint256 blockTime);
    event Purchase(address indexed collection, uint256 indexed orderId, uint256 indexed nftid, address from ,address to, uint256 price, uint256 blockTime);
    event NewOffer(address indexed collection, uint256 indexed offerId, uint256 indexed nftid, address buyer, address erc20Token, uint256 price, uint256 _expirationTime, uint256 blockTime);
    event TakeOffer(address indexed collection, uint256 indexed offerId, uint256 indexed nftid, address from, address to, address erc20Token, uint256 price, uint256 blockTime);
    event CancelOffer(address indexed collection, uint256 indexed offerId, uint256 blockTime);
    event NewAuction(address indexed collection, uint256 indexed auctionId, uint256 indexed nftid, address erc20Token, address maker, uint256 basePrice, uint256 minimalIncrement,uint256 extra, uint256 listingTime, uint256 expirationTime, uint256 blockTime);
    event NewBid(address indexed collection, uint256 indexed auctionId, uint256 indexed nftid, address bidder, uint256 price, uint256 blockTime, uint256 bidId);
    event SettleAuction(address indexed collection, uint256 indexed auctionId, uint256 indexed nftid, address from, address tp, uint256 price, uint256 blockTime);
    event CancelAuction(address indexed collection, uint256 indexed auctionId, uint256 blockTime);

    event SetRoyalty(address indexed collection, address newBeneficiary, uint256 newRatio);
}