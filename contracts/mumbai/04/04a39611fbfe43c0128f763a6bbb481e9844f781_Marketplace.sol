/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: dgalery/MarketplaceDgalery.sol


pragma solidity ^0.8.0;







interface NFTS{
    function artistOf(uint256 _tokenId) external view returns(address);
}

contract Marketplace is Ownable, ReentrancyGuard, ERC721Holder {
    using Counters for Counters.Counter;
    Counters.Counter public totalOrders;

    address public payTokenContract;
    address public NftsContract;

    uint256 public sellFeePercentage;   // example: 500 = 5%
    address public walletReceivingSellFee;

    uint256 public minIncrement; // example: 500 = 5% (min increment for new bids from highest)

    bool public lockNewSellOrders;
    mapping(uint256 => SellOrder) public marketList;
    mapping(uint256 => Bid) public _bids;

    struct SellOrder {
        uint256 token_id;
        uint256 price;
        address seller;
        bool status; // false:closed, true: open
        uint256 sell_method; // 1 : fixed, 2 : bids
        uint256 expire_at;
        uint256 royalty;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    // Events
    event OrderAdded(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price,
        uint256 sell_method,
        uint256 expire_at
    );
    event OrderSuccessful(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price,
        address indexed buyer
    );
    event OrderAuctionResolved(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 totalPrice,
        address indexed buyer
    );
    event OrderCanceled(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price
    );

    event SetArtistFee(uint256 oldValue, uint256 newValue);

    event SetSellFee(uint256 oldValue, uint256 newValue);

    event RefundCoinsFromAuction(uint256 indexed orderId, address indexed bidder, uint256 amount);
    event NewHighestBid(uint256 indexed orderId, address indexed bidder, uint256 newHighestBid);

    event Set_TokenContracts(address payTokenContract, address NftsContract);

    event Set_WalletReceivingSellFee(address walletReceivingSellFee);

    event Set_LockNewSellOrders(bool lockStatus);

    event Set_MinIncrementForBids(uint256 minIncrement);

    event Change_SellOrder(uint256 indexed orderId, uint256 price, uint256 expire_at);

    constructor(uint256 _minIncrementForBids, uint256 _sellFeePercentage, address _walletReceivingSellFee, address _payTokenContract, address _NftsContract) {
        setMinIncrementForBids(_minIncrementForBids);
        setSellFeePercentage(_sellFeePercentage);
        setWalletReceivingSellFee(_walletReceivingSellFee);
        setContractsAddress(_payTokenContract, _NftsContract);
    }

    function setContractsAddress(address _payTokenContract, address _NftsContract) public onlyOwner {
        payTokenContract = _payTokenContract;
        NftsContract = _NftsContract;
        emit Set_TokenContracts(_payTokenContract, _NftsContract);
    }

    function setWalletReceivingSellFee(address _walletReceivingSellFee) public onlyOwner {
        walletReceivingSellFee = _walletReceivingSellFee;
        emit Set_WalletReceivingSellFee(_walletReceivingSellFee);
    }

    function setLockNewSellOrders(bool _newVal) external onlyOwner{
        lockNewSellOrders = _newVal;
        emit Set_LockNewSellOrders(_newVal);
    }

    function setMinIncrementForBids(uint256 _newVal) public onlyOwner {
        minIncrement = _newVal;
        emit Set_MinIncrementForBids(_newVal);
    }

    function setSellFeePercentage(uint256 _newVal) public onlyOwner {
        require(_newVal <= 9900, "the new value should range from 0 to 9900");
        emit SetSellFee(sellFeePercentage, _newVal);
        sellFeePercentage = _newVal;
    }

    function _computePercent(uint256 _amount, uint256 _feePercentage) internal pure returns (uint256) {
        return (_amount*_feePercentage)/(10**4);
    }

    function newSellOrder(uint256 _token_id, uint256 _price, uint256 _sell_method, uint256 _expire_at, uint256 _royalty) external returns (uint256) {
        require(lockNewSellOrders == false, "cannot currently create new sales orders");
        require(IERC721(NftsContract).ownerOf(_token_id) == _msgSender(), "you don't have enough balance to sell");
        require(_price > 0, "price must be greater than 0");
        require(_sell_method>=1 && _sell_method<=2, "_sell_method parameter is wrong");
        IERC721(NftsContract).safeTransferFrom(msg.sender, address(this), _token_id, "");

        totalOrders.increment();
        uint256 newOrderId = totalOrders.current();
        marketList[newOrderId] = SellOrder(
            _token_id,
            _price,
            msg.sender,
            true,
            _sell_method,
            _expire_at,
            _royalty
        );

        emit OrderAdded(newOrderId, _token_id, msg.sender, _price, _sell_method, _expire_at);
        return newOrderId;
    }


    function cancelSellOrder(uint256 _orderId) external nonReentrant{
        require(marketList[_orderId].seller == msg.sender, "you are not authorized to cancel this order");
        require(marketList[_orderId].status == true, "this order sell already closed");
        if(marketList[_orderId].sell_method == 2){
            require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: time no expired yet');
            require(_bids[_orderId].bidder == address(0) && _bids[_orderId].amount == 0, "MARKET: there is a pending auction to be resolved");
        }

        marketList[_orderId].status = false;
        IERC721(NftsContract).safeTransferFrom(address(this), marketList[_orderId].seller, marketList[_orderId].token_id, "");
        emit OrderCanceled(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price);
    }


    function buy(uint256 _orderId, uint256 _amountToBuy) external nonReentrant{
        require(msg.sender != address(0) && msg.sender != marketList[_orderId].seller, "current sender is already owner of this token");
        require(marketList[_orderId].status == true, "this sell order is closed");
        require(marketList[_orderId].sell_method == 1, "this sell order is on auction");
        marketList[_orderId].status = false;
        uint256 totalPay = marketList[_orderId].price * _amountToBuy;        
        uint256 artistFee = _computePercent(totalPay, marketList[_orderId].royalty);
        uint256 sellFee = _computePercent(totalPay, sellFeePercentage);
        uint256 sellerProfit = totalPay - (artistFee + sellFee);
        address artistAddress = NFTS(NftsContract).artistOf(marketList[_orderId].token_id);
        IERC20(payTokenContract).transferFrom(msg.sender, marketList[_orderId].seller, sellerProfit);
        IERC20(payTokenContract).transferFrom(msg.sender, artistAddress, artistFee);
        IERC20(payTokenContract).transferFrom(msg.sender, walletReceivingSellFee, sellFee);

        IERC721(NftsContract).safeTransferFrom(address(this), msg.sender, marketList[_orderId].token_id, "");
        emit OrderSuccessful(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price, msg.sender);
    }

    function reverseOrders(uint256[] memory _orders_id) external onlyOwner{
        for (uint256 i=0; i<_orders_id.length; i++) {
            if(marketList[_orders_id[i]].status == true){
                
                if(marketList[_orders_id[i]].sell_method == 2){
                    if(block.timestamp >= marketList[_orders_id[i]].expire_at && _bids[_orders_id[i]].bidder == address(0) && _bids[_orders_id[i]].amount == 0){
                        // the order has already expired and there are no bids
                    }else{
                        continue;
                    }
                }

                marketList[_orders_id[i]].status = false;
                IERC721(NftsContract).safeTransferFrom(address(this), marketList[_orders_id[i]].seller, marketList[_orders_id[i]].token_id, "");
                emit OrderCanceled(_orders_id[i], marketList[_orders_id[i]].token_id, marketList[_orders_id[i]].seller, marketList[_orders_id[i]].price);
            }
        }
    }


    modifier isOpenToAuctions(uint256 _orderId) {
        require(block.timestamp < marketList[_orderId].expire_at, 'MARKET: Time expired to do bids');
        _;
    }

    modifier auctionsEnded(uint256 _orderId) {
        require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: Time no expired yet');
        _;
    }

    modifier isOnAuctions(uint256 _orderId) {
        require(marketList[_orderId].sell_method == 2, "MARKET: It's not open to bids");
        require(marketList[_orderId].status == true, "MARKET: It's not for sale currently");
        _;
    }

    function minAmountForBid(uint256 _orderId) public view isOpenToAuctions(_orderId) returns (uint256){
        uint256 totalOrderPrice = marketList[_orderId].price;
        uint256 maxValue = (totalOrderPrice  >= _bids[_orderId].amount) ? totalOrderPrice : _bids[_orderId].amount;
        uint256 amountRequired = _computePercent(maxValue, minIncrement);
        return maxValue + amountRequired;
    }

    function bid(uint256 _orderId, uint256 _amount) external isOnAuctions(_orderId) isOpenToAuctions(_orderId) nonReentrant{
        require(marketList[_orderId].seller != msg.sender, "MARKET: Owner can't bid on its token");
        uint256 amountRequired = minAmountForBid(_orderId);
        require(_amount >= amountRequired, 'MARKET: Bid amount lower than current min bids');

        address oldBidder = _bids[_orderId].bidder;
        uint256 oldAmount = _bids[_orderId].amount;

        _bids[_orderId] = Bid({ bidder: msg.sender, amount: _amount });

        if (oldBidder != address(0) && oldAmount > 0) {
            IERC20(payTokenContract).transfer(oldBidder, oldAmount);
            emit RefundCoinsFromAuction(_orderId, oldBidder, oldAmount);
        }

        IERC20(payTokenContract).transferFrom(msg.sender, address(this), _amount);
        emit NewHighestBid(_orderId, msg.sender, _amount);
    }

    function resolveAuction(uint256 _orderId) external isOnAuctions(_orderId) auctionsEnded(_orderId) nonReentrant{
        SellOrder memory order = marketList[_orderId];
        uint256 totalOrderPrice = order.price;
        require(_bids[_orderId].amount >= totalOrderPrice, "MARKET: There is nothing pending to solve");

        marketList[_orderId].status = false;
        address tokenSeller = order.seller;
        uint256 sellerProceeds = _bids[_orderId].amount;
        address bidder = _bids[_orderId].bidder;

        uint256 artistFee = _computePercent(sellerProceeds, order.royalty);
        uint256 sellFee = _computePercent(sellerProceeds, sellFeePercentage);
        uint256 feesByTransfer = artistFee + sellFee;
        address artistAddress = NFTS(NftsContract).artistOf(order.token_id);
        IERC20(payTokenContract).transfer(tokenSeller, sellerProceeds - feesByTransfer);
        IERC20(payTokenContract).transfer(artistAddress, artistFee);
        IERC20(payTokenContract).transfer(walletReceivingSellFee, sellFee);

        IERC721(NftsContract).safeTransferFrom(address(this), bidder, order.token_id, "");

        delete _bids[_orderId];
        emit OrderAuctionResolved(_orderId, order.token_id, tokenSeller, sellerProceeds, bidder);
    }


    function changeSellOrder(uint256 _orderId, uint256 _price, uint256 _expire_at) external nonReentrant{
        require(marketList[_orderId].seller == msg.sender, "you are not authorized to change this order");
        require(marketList[_orderId].status == true, "this sell order is closed");
        if(marketList[_orderId].sell_method == 2){
            require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: time no expired yet');
            require(_bids[_orderId].bidder == address(0) && _bids[_orderId].amount == 0, "MARKET: there is a pending auction to be resolved");
        }

        marketList[_orderId].price = _price;
        marketList[_orderId].expire_at = _expire_at;
        
        emit Change_SellOrder(_orderId, _price, _expire_at);
    }

    
    function ResolveOrder(uint256 _orderId, address _buyer) external onlyOwner nonReentrant{
        require(msg.sender == marketList[_orderId].seller, "you are not authorized to resolve this order");
        require(marketList[_orderId].status == true, "this sell order is closed");
        require(marketList[_orderId].sell_method == 1, "this sell order is on auction");
        marketList[_orderId].status = false;
        
        IERC721(NftsContract).safeTransferFrom(address(this), _buyer, marketList[_orderId].token_id, "");
        emit OrderSuccessful(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price, _buyer);
    }


}