// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IJPEGXController.sol";

contract AuctionERCManager is Ownable, ReentrancyGuard {
    event Start(uint256 _nftId, uint256 startingBid);
    event End(address actualBidder, uint256 highestBid);
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);

    IERC20 public erc20;
    address public maincontract;

    uint256 public interval = 1 days / 4;
    uint256 public liquidationRatio = 900;

    struct Auction {
        uint256 highestBid;
        address actualBidder;
        mapping(address => uint256) bids;
        address optionWriter;
        address optionOwner;
        uint256 debt;
        uint256 tlastBid;
        bool isGoing;
    }
    struct AuctionLight {
        uint256 highestBid;
        address actualBidder;
        address optionWriter;
        address optionOwner;
        uint256 debt;
        uint256 tlastBid;
        bool isGoing;
    }

    mapping(address => mapping(uint256 => Auction)) auctions;

    constructor(address _wrappedEtherAddress) {
        erc20 = IERC20(_wrappedEtherAddress);
    }

    function start(
        address _tokenAddress,
        uint256 _nftId,
        uint256 _startingBid,
        address _optionWriter,
        address _optionOwner,
        uint256 _debt
    ) public nonReentrant {
        Auction storage auction = auctions[_tokenAddress][_nftId];
        require(
            msg.sender ==
                IJPEGXController(maincontract).getPoolFromTokenAddress(
                    _tokenAddress
                ),
            "Call this function from pool contract"
        );
        require(!auction.isGoing, "Already started[_nftId]!");
        auction.isGoing = true;
        auction.highestBid = _startingBid;
        auction.actualBidder = address(0);
        auction.tlastBid = block.timestamp;
        auction.optionWriter = _optionWriter;
        auction.optionOwner = _optionOwner;
        auction.debt = _debt;
        emit Start(_nftId, _startingBid);
    }

    function bid(
        address _tokenAddress,
        uint256 _nftId,
        uint256 _bidAmount,
        address _user
    ) external {
        Auction storage auction = auctions[_tokenAddress][_nftId];
        require(auction.isGoing, "Auction didn't started");
        require(
            block.timestamp < auction.tlastBid + interval ||
                auction.actualBidder == address(0),
            "Action ended"
        );
        require(
            _bidAmount + auction.bids[_user] > auction.highestBid,
            "The total bid is lower than actual maxBid"
        );
        require(
            erc20.transferFrom(_user, address(this), _bidAmount),
            "ERC20 - transfer is not allowed"
        );
        auction.bids[_user] += _bidAmount;
        auction.highestBid = auction.bids[_user];
        auction.actualBidder = _user;
        auction.tlastBid = block.timestamp;
        emit Bid(auction.actualBidder, auction.highestBid);
    }

    //  Users can retract at any times if they aren't the actual bidder
    function withdraw(
        address _tokenAddress,
        uint256 _nftId,
        address _user
    ) external payable nonReentrant {
        Auction storage auction = auctions[_tokenAddress][_nftId];
        require(_user != auction.actualBidder, "You are the actual bidder");
        uint256 bal = auction.bids[_user];
        auction.bids[_user] = 0;
        erc20.transferFrom(address(this), _user, bal);
        emit Withdraw(_user, bal);
    }

    // End auction
    function end(
        address _tokenAddress,
        address _pool,
        uint256 _nftId
    ) external nonReentrant returns (bool) {
        Auction storage auction = auctions[_tokenAddress][_nftId];
        require(
            msg.sender ==
                IJPEGXController(maincontract).getPoolFromTokenAddress(
                    _tokenAddress
                ),
            "Call this function from pool contract"
        );
        require(auction.isGoing, "Auction not started");
        require(
            block.timestamp >= auction.tlastBid + interval,
            "Auction is still ongoing!"
        );
        require(auction.actualBidder != address(0), "no bids");
        auction.isGoing = false;
        auction.bids[auction.actualBidder] = 0;
        //Transfers the NFT to the actualBidder and erc20 to stakeholders
        IERC721(_tokenAddress).safeTransferFrom(
            address(_pool),
            auction.actualBidder,
            _nftId
        );
        erc20.transfer(auction.optionOwner, auction.debt);
        erc20.transfer(
            auction.optionWriter,
            ((auction.highestBid - auction.debt) * liquidationRatio) / 1000
        );

        emit End(auction.actualBidder, auction.highestBid);
        return true;
    }

    function setMainContact(address _mainConctract) public onlyOwner {
        maincontract = _mainConctract;
    }

    function getAuction(
        address _tokenAddress,
        uint256 _tokenId
    ) public view returns (AuctionLight memory auctionLight) {
        Auction storage auction = auctions[_tokenAddress][_tokenId];
        auctionLight = AuctionLight({
            highestBid: auction.highestBid,
            actualBidder: auction.actualBidder,
            optionWriter: auction.optionWriter,
            optionOwner: auction.optionOwner,
            debt: auction.debt,
            tlastBid: auction.tlastBid,
            isGoing: auction.isGoing
        });
        return auctionLight;
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
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
pragma solidity ^0.8.13;

interface IJPEGXController {
    function deployPool(address _erc721) external returns (address pool);

    function getPoolFromTokenAddress(
        address _tokenAddress
    ) external view returns (address);

    function setAuctionManager(address _auctionManager) external;

    /*** Call PoolContract - setters functions  ***/

    /*** Call PoolContract - getters functions  ***/

    function getfloorprice(
        address _pool,
        uint256 _epoch
    ) external view returns (uint256);

    function getEpoch_2e(address _pool) external view returns (uint256);

    function getSharesAtOf(
        address _pool,
        uint256 _epoch,
        uint256 _strikePrice,
        address _add
    ) external view returns (uint256);

    function getAmountLockedAt(
        address _pool,
        uint256 _epoch,
        uint256 _strikePrice
    ) external view returns (uint256);

    function getOptionAvailableAt(
        address _pool,
        uint256 _epoch,
        uint256 _strikePrice
    ) external view returns (uint256);

    function getEpochDuration(
        address _pool
    ) external view returns (uint256 epochduration);

    function getInterval(
        address _pool
    ) external view returns (uint256 interval);

    /***Call Auction Contract ***/

    function bid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function endAuction(address _tokenAddress, uint256 _tokenId) external;
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