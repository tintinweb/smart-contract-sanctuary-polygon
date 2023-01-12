/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/helpers/TokenTypes.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library TokenTypes{
    uint256  public constant UNKNOWN = 0x0000;
    uint256  public constant ALICE = 0x0001;
    uint256  public constant QUEEN = 0x0002;
    uint256  public constant CARD = 0x0003;
    uint256  public constant CLUBS_OF_RUNNER = 0x0013;
    uint256  public constant DIAMOND_OF_ENERGY = 0x0023;
    uint256  public constant SPADES_OF_MARKER = 0x0033;
    uint256  public constant HEART_OF_ALL_ROUNDER = 0x0043;

}

library VRFRequestStatus {
    uint8 public constant NO_REQUEST =0;
    uint8 public constant PENDING = 1;
    uint8 public constant COMPLETED =2;
}

library AuctionDetails{


    struct BidHistory {
        address bidder;
        uint256 bidAmount;
        uint256 bidtime;
    }


    struct Auction {
        uint256 nftId;
        BidHistory[] bidHistorybyId;
        uint256 bidCounter;
        uint256 startTime;
        uint256 endTime;
        bool isClaimed;
        uint256 highestBid;
        address highestBidder;
    }
}





// File: contracts/interfaces/IAuction.sol

pragma solidity ^0.8.0;


interface IAuction {

    function getBidHistoryById(
        uint256 _auctionid,
        uint256 _page,
        uint256 _pagelimit
    ) external view returns (AuctionDetails.BidHistory[] memory);

    function auctionRegistry(uint256 _auctionId) external returns (AuctionDetails.Auction memory);
}
// File: contracts/Copy_auction/Changer.sol

pragma solidity ^0.8.0;





contract Changer is Ownable {
    
    
    mapping(uint256 => AuctionDetails.Auction) public auctionRegistry;


    function setAuctionRegistry(IAuction _auction,uint256 _auctionId) external onlyOwner {
        AuctionDetails.Auction memory auctionDetails = _auction.auctionRegistry(_auctionId);
        auctionRegistry[_auctionId].nftId = auctionDetails.nftId;
        auctionRegistry[_auctionId].bidCounter = auctionDetails.bidCounter;
        auctionRegistry[_auctionId].startTime = auctionDetails.startTime;
        auctionRegistry[_auctionId].endTime = auctionDetails.endTime;
        auctionRegistry[_auctionId].isClaimed = auctionDetails.isClaimed;
        auctionRegistry[_auctionId].highestBid = auctionDetails.highestBid;
        auctionRegistry[_auctionId].highestBidder = auctionDetails.highestBidder;
        AuctionDetails.BidHistory[] memory bidHistory = _auction.getBidHistoryById(_auctionId, 1, 100);
        uint256 loop = bidHistory.length;
        for (uint i; i < loop; i++) {
            auctionRegistry[_auctionId].bidHistorybyId.push(bidHistory[i]);
        }
    }

}