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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract NFTInterface {
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
    function transferFrom(address from, address to, uint256 tokenId) external virtual;
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function getPrice(uint256 tokenId) public view virtual returns (uint256);
    function unlistNFT(uint256 tokenId) public virtual;
    function isOnSale(uint256 tokenId) public view virtual returns(bool);
    function isOnAuction(uint256 tokenId) public view virtual returns(bool);
    function approve(address to, uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) external view virtual returns (address operator);
    function getCreator(uint256 tokenId) external view virtual returns (address);
}

contract Escrow is Ownable, ReentrancyGuard  {
    
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    struct Auction {
        uint256 auctionId;
        uint256 duration;
        uint256 firstBidTime;
        uint256 reservePrice;
        uint256 bid;
        address tokenOwner;
        address bidder;
    }
    
    struct Sale {
        uint256 saleId;
        uint256 price;
        address tokenOwner;
    }
    
    Counters.Counter private _saleCounter;
    Counters.Counter private _auctionCounter;
    
    address public nftAddress;
    NFTInterface nftContract;
    
    uint256 public curatorCutPercentage;
    uint256 public creatorRoylatyPercentage;
    address public curator;
    
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Sale) public sales;
    
    event SaleComplete (uint256 saleId, uint256 tokenId, address seller, address buyer, uint256 price);
    event AuctionCreated (uint256 auctionId, uint256 tokenId, uint256 duration, uint256 reservePrice, address tokenOwner, address curator, uint256 curatorFeePercentage);
    event AuctionBid (uint256 auctionId, uint256 tokenId, address bidder, uint256 bid, bool firstBid);
    event AuctionDurationExtended (uint256 auctionId, uint256 tokenId, uint256 newDuration);
    event AuctionEnded (uint256 auctionId, uint256 tokenId, address tokenOwner, address curator, address bidder, uint256 ownerProfit, uint256 curatorFee);
    event AuctionCanceled (uint256 auctionId, uint256 tokenId, address tokenOwner);
    event SaleCreated (uint256 saleId, uint256 tokenId, uint256 price, address tokenOwner);
    event SaleCanceled (uint256 saleId, uint256 tokenId, address tokenOwner);
    
    modifier auctionExists(uint256 tokenId) {
        require(auctions[tokenId].tokenOwner != address(0), "Auction doesn't exist");
        _;
    }
    
    modifier saleExists(uint256 tokenId) {
        require(sales[tokenId].tokenOwner != address(0), "Token not for sale");
        _;
    }
        
    constructor(address _nft, uint256 _curatorCut, uint256 _creatorRoyalty) Ownable()
    {
        curatorCutPercentage = _curatorCut;
        creatorRoylatyPercentage = _creatorRoyalty;
        curator = msg.sender;
        nftAddress = _nft;
        nftContract = NFTInterface(nftAddress);
    }
    
    function setCurator(address _curator) external onlyOwner {
        curator = _curator;
    }
    
    function createAuction(uint256 tokenId, uint256 duration, uint256 reservePrice) public nonReentrant
    {
        address tokenOwner = nftContract.ownerOf(tokenId);
        require(msg.sender == nftContract.getApproved(tokenId) || msg.sender == tokenOwner, "Caller must be approved or owner for token id");
        require(sales[tokenId].tokenOwner == address(0), "Token is already on sale");
        
        _auctionCounter.increment();
        uint256 _auctionId = _auctionCounter.current();
        
        auctions[tokenId] = Auction({
            auctionId: _auctionId,
            bid: 0,
            duration: duration,
            firstBidTime: 0,
            reservePrice: reservePrice,
            tokenOwner: tokenOwner,
            bidder: address(0)
        });
        
        nftContract.transferFrom(tokenOwner, address(this), tokenId);
        
        emit AuctionCreated(_auctionId, tokenId, duration, reservePrice, tokenOwner, curator, 5);
    }
    
    function createBid(uint256 tokenId) external payable auctionExists(tokenId) nonReentrant
    {
        uint256 amount = msg.value;
        address lastBidder = auctions[tokenId].bidder;

        require( amount >= auctions[tokenId].reservePrice, "Must send at least reservePrice");
        require(
            amount >= auctions[tokenId].bid.add(auctions[tokenId].bid.mul(5).div(100)), 
            "Must send more than last bid by 5% amount"
        );
        
        if(auctions[tokenId].firstBidTime == 0) {
            auctions[tokenId].firstBidTime = block.timestamp;
        } 
        else if(lastBidder != address(0)) {
            payable(lastBidder).transfer(auctions[tokenId].bid);
        }
        
        auctions[tokenId].bid = amount;
        auctions[tokenId].bidder = msg.sender;
        
        emit AuctionBid(
            auctions[tokenId].auctionId,
            tokenId,
            msg.sender,
            amount,
            lastBidder == address(0) // firstBid boolean
        );
    }
    
    function endAuction(uint256 tokenId) external auctionExists(tokenId) nonReentrant
    {
        
        // require( uint256(auctions[tokenId].firstBidTime) != 0, "Auction hasn't begun");
        require(block.timestamp >= auctions[tokenId].duration, "Auction hasn't completed");
        
        uint256 ownerProfit = auctions[tokenId].bid;
        address bidder = auctions[tokenId].bidder;
        address tokenOwner = auctions[tokenId].tokenOwner;
        
        address creator = nftContract.getCreator(tokenId);
        
        uint256 curatorFee = ownerProfit.mul(curatorCutPercentage).div(100);
        uint256 creatorRoylaty = ownerProfit.mul(creatorRoylatyPercentage).div(100);
        
        ownerProfit = ownerProfit.sub(curatorFee);
        
        if(tokenOwner != creator)
        {
            ownerProfit = ownerProfit.sub(creatorRoylaty);
            payable(creator).transfer(creatorRoylaty);
        }
        payable(curator).transfer(curatorFee);
        payable(tokenOwner).transfer(ownerProfit);
        
        if(bidder != address(0)){
            nftContract.transferFrom(address(this), bidder,tokenId);
        }
        else {
            nftContract.transferFrom(address(this), auctions[tokenId].tokenOwner, tokenId);
        }
        
        emit AuctionEnded(auctions[tokenId].auctionId, tokenId, tokenOwner, curator, bidder, ownerProfit, curatorFee);
        
        unlistToken(tokenId);        
        
    }
    
    function cancelAuction(uint256 tokenId) external nonReentrant auctionExists(tokenId) {
        require(
            auctions[tokenId].tokenOwner == msg.sender || curator == msg.sender,
            "Can only be called by auction creator or curator"
        );
        require(
            uint256(auctions[tokenId].firstBidTime) == 0,
            "Can't cancel an auction once it's begun"
        );
        _cancelAuction(tokenId);
    }
    
    function _cancelAuction(uint256 tokenId) internal {
        address tokenOwner = auctions[tokenId].tokenOwner;
        nftContract.safeTransferFrom(address(this), tokenOwner, tokenId);

        emit AuctionCanceled(auctions[tokenId].auctionId, tokenId, tokenOwner);
        
        unlistToken(tokenId);
        
    }
    
    
    function getEndTime (uint256 tokenId) public view returns(uint256)
    {
        return auctions[tokenId].firstBidTime.add(auctions[tokenId].duration);
    }
    
    function getAuction (uint256 tokenId) public view auctionExists(tokenId) returns(Auction memory)
    {
        return auctions[tokenId];
    }
    
    function createSale (uint256 tokenId, uint256 price) external nonReentrant {
        
        address tokenOwner = nftContract.ownerOf(tokenId);
        require(msg.sender == nftContract.getApproved(tokenId) || msg.sender == tokenOwner, "Caller must be approved or owner for token id");
        
        require(auctions[tokenId].tokenOwner == address(0), "Token is already up for auction");
        
        _saleCounter.increment();
        uint256 _saleId = _saleCounter.current();
        
        sales[tokenId] = Sale({
            saleId: _saleId,
            price: price,
            tokenOwner: tokenOwner
        });
        
        nftContract.transferFrom(tokenOwner, address(this), tokenId);
        
        emit SaleCreated(_saleId, tokenId, price, tokenOwner);
    }
    
    function buySaleToken (uint256 tokenId) external payable saleExists(tokenId) nonReentrant {
        uint256 price = sales[tokenId].price;
        require(msg.value >= price, "Not enough funds sent");
        
        address tokenOwner = sales[tokenId].tokenOwner;
        require(msg.sender != address(0) && msg.sender != tokenOwner, "Owner cannot buy their own tokens");
        
        uint256 ownerProfit = msg.value;
        
        address creator = nftContract.getCreator(tokenId);
        
        uint256 curatorFee = ownerProfit.mul(curatorCutPercentage).div(100);
        uint256 creatorRoylaty = ownerProfit.mul(creatorRoylatyPercentage).div(100);
        
        ownerProfit = ownerProfit.sub(curatorFee);
        
        if(tokenOwner != creator)
        {
            ownerProfit = ownerProfit.sub(creatorRoylaty);
            payable(creator).transfer(creatorRoylaty);
        }
        
        payable(curator).transfer(curatorFee);
        payable(tokenOwner).transfer(ownerProfit);
        
        nftContract.safeTransferFrom(address(this),msg.sender,tokenId);
        
        emit SaleComplete(sales[tokenId].saleId, tokenId, tokenOwner, msg.sender, ownerProfit);
        
        unlistToken(tokenId);
    }
    
    function cancelSale(uint256 tokenId) external saleExists(tokenId) nonReentrant {
        require(
            sales[tokenId].tokenOwner == msg.sender || curator == msg.sender,
            "Can only be called by tokenOwner or curator"
        );
        address tokenOwner = sales[tokenId].tokenOwner;
        nftContract.safeTransferFrom(address(this), tokenOwner, tokenId);

        emit SaleCanceled(sales[tokenId].saleId, tokenId, tokenOwner);

        unlistToken(tokenId);

    }
    
    function getSale (uint256 tokenId) public view saleExists(tokenId) returns(Sale memory)
    {
        return sales[tokenId];
    }
    
    function unlistToken(uint tokenId) internal {
        delete sales[tokenId];
        delete auctions[tokenId];
    }
    
    // function getContractFunds() public onlyOwner {
    //     address owner = owner();
    //     payable(owner).transfer(address(this).balance);
    // }
    
    // function getContractBalance() public view onlyOwner returns(uint256) {
    //     return address(this).balance;
    // }
}