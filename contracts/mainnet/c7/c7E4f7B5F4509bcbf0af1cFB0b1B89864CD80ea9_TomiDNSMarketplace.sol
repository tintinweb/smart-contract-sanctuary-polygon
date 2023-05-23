// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "../ethregistrar/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ethregistrar/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";



contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IPartner {

   function safeMint(address to) external;
   function updateBaseURI(string memory _URI) external;
}


contract TomiDNSMarketplace is ERC721Holder, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /// @notice Token used for payments
    IERC20 public  tomiToken;

    /// @notice NFT used for auctions
    IERC721 public  tomiDNS;

    /// @notice Name Wrapper
    address public contractor;

    /// @notice Minter NFT
    IPartner public partnerNFT;

    /// @notice Receives all funds from auctions
    address public treasuryWallet;

    /**
     * @notice Base price in dollars for an NFT
     * @dev uses 18 decimals
     */
    uint256 public reservePrice;

    /// @notice Minimum delta between current and previous bid
    uint8 public minBidIncrementPercentage;

    /// @notice Duration of bidding for an auction
    uint256 public auctionDuration;

    uint256 public auctionBufferTime;
    uint256 public auctionBumpTime;

    /// @notice Distribution percentage of royalties and amounts for a successfully completed auction
    uint8[2] public distributionPercentages;

    /// @notice Discount for minter
    uint256 public reclaimDiscount;

    uint256 public expiryTime;

    // structs

    struct Bidding {
        address bidder;
        uint256 amount;
    }

    struct Auction {
        uint256 tokenId;
        address minter;
        uint256 mintAmount;
        uint256 startTime;
        uint256 expiryTime;
        bool isClaimed;
        uint256 minterClaimPercentage;
        uint256 alreadyClaimed;
        string label;
        bytes32 labelhash;
        string tld;
    }






    // mappings

    /// @notice Gives the active/highest bid for an NFT
    mapping (uint256 => Bidding) public getBiddings;

    /// @notice Gives the auction details for an NFT
    mapping (uint256 => Auction) public getAuctions;

    // events

    event UpdatedContractor(address indexed oldContractor, address indexed newContractor);

    event UpdatedReservePrice(uint256 oldReservePrice, uint256 newReservePrice);

    event UpdatedMinBidIncrementPercentage(uint256 oldMinBidIncrementPercentage, uint256 newMinBidIncrementPercentage);

    event UpdatedAuctionBufferTime(uint256 oldAuctionBufferTime, uint256 newAuctionBufferTime);

    event UpdatedAuctionBumpTime(uint256 oldAuctionBumpTime, uint256 newAuctionBumpTime);

    event UpdatedReclaimDiscount(uint256 oldReclaimDiscount, uint256 newReclaimDiscount);

    event PartnerClaimed(uint256 _tokenId, uint256 amount , string label , string tld);

    
    

    event AuctionCreated(
        uint256 tokenId,
        address indexed minter,
        uint256 mintAmount,
        uint256 startTime,
        uint256 expiryTime,
        string label,
        bytes32 indexed labelhash,
        string tld
    );

    event AuctionExtended(
        uint256 tokenId,
        uint256 expiryTime
    );

    event BidCreated(
        uint256 tokenId,
        address indexed bidder,
        uint256 amount
    );

    event Claimed(
        uint256 tokenId,
        address indexed minter,
        address indexed claimer,
        uint256 amount
    );

    event Reclaimed(
        uint256 tokenId,
        address indexed minter,
        uint256 amount
    );

    // constructor

    constructor(IERC20 _tomi , IERC721 _dns , address _contracter, IPartner _partner) {
        treasuryWallet = _msgSender();

        // TODO change
        reservePrice = 1 * (10 ** 8);

        minBidIncrementPercentage = 1; 

        // TODO change
        auctionDuration = 30 minutes;
        // auctionDuration = 24 hours;

        // TODO change
        auctionBumpTime = 3 minutes;
        auctionBufferTime = 3 minutes;
        // auctionBumpTime = 10 minutes;
        // auctionBufferTime = 10 minutes;

        distributionPercentages = [25, 75];

        reclaimDiscount = 25;

        tomiToken = _tomi;
        tomiDNS = _dns;
        contractor = _contracter;
        partnerNFT = _partner;
    }

    function updateContractor(address _contractor) external onlyOwner {
        require(_contractor != contractor, "TomiDNSMarketplace: Contractor is already this address");
        emit UpdatedContractor(contractor, _contractor);
        contractor = _contractor;
    }

    function updateNFT(address _NFT) external onlyOwner {
        require(_NFT != contractor, "TomiDNSMarketplace: NFT is already this address");
        emit UpdatedContractor(contractor, _NFT);
        tomiDNS = IERC721(_NFT);
    }

    function updateReservePrice(uint256 _reservePrice) external onlyOwner {
        require(_reservePrice != reservePrice, "TomiDNSMarketplace: Reserve Price is already this value");
        emit UpdatedReservePrice(reservePrice, _reservePrice);
        reservePrice = _reservePrice;
    }

    function updateDistributionPercentages(uint8[2] calldata _distributionPercentages) external onlyOwner {
        require(_distributionPercentages[0] + _distributionPercentages[1] == 100,
            "TomiDNSMarketplace: Total percentage should always equal 100");
        distributionPercentages = _distributionPercentages;
    }

    function updateMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external onlyOwner {
        require(_minBidIncrementPercentage != minBidIncrementPercentage,
            "TomiDNSMarketplace: Minimum Bid Increment Percentage is already this value");
        emit UpdatedMinBidIncrementPercentage(minBidIncrementPercentage, _minBidIncrementPercentage);
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    function updateAuctionBufferTime(uint256 _auctionBufferTime) external onlyOwner {
        require(_auctionBufferTime != auctionBufferTime, "TomiDNSMarketplace: Auction Buffer Time is already this value");
        emit UpdatedAuctionBufferTime(auctionBufferTime, _auctionBufferTime);
        auctionBufferTime = _auctionBufferTime;
    }

    function updateAuctionBumpTime(uint256 _auctionBumpTime) external onlyOwner {
        require(_auctionBumpTime != auctionBumpTime, "TomiDNSMarketplace: Auction Bump Time is already this value");
        emit UpdatedAuctionBumpTime(auctionBumpTime, _auctionBumpTime);
        auctionBumpTime = _auctionBumpTime;
    }

    function updateReclaimDiscount(uint256 _reclaimDiscount) external onlyOwner {
        require(_reclaimDiscount != reclaimDiscount, "TomiDNSMarketplace: Reclaim Discount is already this value");
        emit UpdatedReclaimDiscount(reclaimDiscount, _reclaimDiscount);
        reclaimDiscount = _reclaimDiscount;
    }

    function getReserveAmount() public view returns (uint256) {
        // TODO change
        return reservePrice;
        // uint256 priceOfTomiInUSD = uniswapRouter.qoute();
        // handle decimals here
        // uint256 reserveAmount = reservePrice / priceOfTomiInUSD;
        // return reserveAmount;
    }


    


    function setOnAuction(
        address _minter,
        uint256 _tokenId,
        string memory _label,
        bytes32 _labelhash,
        string memory _tld
    ) external onlyContract {
        Auction memory auction;
        auction.tokenId = _tokenId;
        auction.minter = _minter;
        auction.mintAmount = getReserveAmount();
        auction.startTime = block.timestamp;
        auction.expiryTime = block.timestamp + auctionDuration;
        auction.minterClaimPercentage = reclaimDiscount;
        auction.alreadyClaimed = auction.mintAmount.mul(reclaimDiscount).div(100);
        auction.label = _label;
        auction.labelhash = _labelhash;
        auction.tld = _tld;

        tomiToken.transfer(_minter, auction.alreadyClaimed);

        getAuctions[_tokenId] = auction;


        emit AuctionCreated(
            _tokenId,
            auction.minter,
            auction.mintAmount,
            auction.startTime,
            auction.expiryTime,
            _label,
            _labelhash,
            _tld
        );
    }

    function bid(uint256 _tokenId, uint256 _amount) external nonReentrant {
        Auction storage auction = getAuctions[_tokenId];

        require(_tokenId == auction.tokenId, "TomiDNSMarketplace: Not on auction");
        require(!auction.isClaimed, "TomiDNSMarketplace: Already claimed");
        require(block.timestamp < auction.expiryTime, "TomiDNSMarketplace: Auction finished");

        Bidding storage bidding = getBiddings[_tokenId];

        bool isFirstBid = bidding.amount == 0;

        uint256 reserveAmount = auction.mintAmount;

        require(
            isFirstBid ?
            _amount >= reserveAmount.add(reserveAmount.mul(minBidIncrementPercentage).div(100)) :
            _amount >= bidding.amount.add(bidding.amount.mul(minBidIncrementPercentage).div(100)),
            "TomiDNSMarketplace: Bid amount should exceed last bid amount or mint amount"
        );

        tomiToken.transferFrom(_msgSender(), address(this), _amount);

        if(!isFirstBid){
        uint256 diff = _amount.sub(bidding.amount);
        tomiToken.transfer(bidding.bidder, bidding.amount.add(diff.mul(10).div(100)));
        }


        bool isBufferTime = auction.expiryTime - block.timestamp < auctionBufferTime;

        if (isBufferTime) {
            auction.expiryTime += auctionBumpTime;

            emit AuctionExtended(_tokenId, auction.expiryTime);
        }

        bidding.bidder = _msgSender();
        bidding.amount = _amount;


        emit BidCreated(_tokenId, _msgSender(), _amount);
    }

    function claim(uint256 _tokenId) external nonReentrant {
        Auction storage auction = getAuctions[_tokenId];

        require(_tokenId == auction.tokenId, "TomiDNSMarketplace: Not on auction");
        require(!auction.isClaimed, "TomiDNSMarketplace: Already claimed");
        require(block.timestamp >= auction.expiryTime, "TomiDNSMarketplace: Auction not yet finished");

        Bidding memory bidding = getBiddings[_tokenId];

        bool isFirstBid = bidding.amount == 0;

        if (isFirstBid) {
            uint256 discountAmount = auction.mintAmount.mul(reclaimDiscount).div(100);

            uint256 treasuryAmount = auction.mintAmount - discountAmount;

            tomiToken.transfer(auction.minter, discountAmount);
            tomiToken.transfer(treasuryWallet, treasuryAmount);

            tomiDNS.transferFrom(address(this), auction.minter, _tokenId);

            emit Reclaimed(_tokenId, auction.minter, treasuryAmount);
        }
        else {
            uint256 minterAmount = bidding.amount.mul(distributionPercentages[0]).div(100);

            uint256 treasuryAmount = bidding.amount.mul(distributionPercentages[1]).div(100);

            tomiToken.transfer(auction.minter, minterAmount);
            tomiToken.transfer(treasuryWallet, treasuryAmount);

            tomiDNS.transferFrom(address(this), bidding.bidder, _tokenId);

            emit Claimed(_tokenId, auction.minter, bidding.bidder, bidding.amount);
        }

        auction.isClaimed = true;
    }


    function getMinterClaimReward(uint256 _tokenId , address minter) view public returns(uint256){
        Auction storage auction = getAuctions[_tokenId];
        Bidding storage bidding = getBiddings[_tokenId];

        require(minter == auction.minter , "TomiDNSMarketplace: Only Original Minter");
        return bidding.amount.mul(25).div(100).sub(auction.alreadyClaimed);
    }

     function MinterClaimReward(uint256 _tokenId) public {
        uint256 toClaim = getMinterClaimReward(_tokenId, _msgSender());
        Auction storage auction = getAuctions[_tokenId];
        auction.alreadyClaimed = auction.alreadyClaimed.add(toClaim);
        tomiToken.transfer(auction.minter, toClaim);
        emit PartnerClaimed(_tokenId, toClaim, auction.label, auction.tld);
    }



    // TODO remove

    // changes bid expiry time of a given NFT
    function testChangeExpiryTime(uint256 _tokenId, uint256 _minutes) public {
        getAuctions[_tokenId].expiryTime = block.timestamp + _minutes.mul(60);
    }

    // changes bid expiry time for all NFTs to be minted from this point onwards
    function testChangeGlobalExpiryTime(uint256 _minutes) public {
        auctionDuration = _minutes.mul(60);
    }

    // modifiers

    modifier onlyContract {
        require(msg.sender == contractor, "TomiDNSMarketplace: Only Registrar Contract can call this function");
        _;
    }
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

pragma solidity >=0.8.4;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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