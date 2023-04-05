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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity =0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./helpers/TypeSupport.sol";
import "./interfaces/IAuction.sol";

contract Auction is IAuction, Context, ReentrancyGuard, ERC721Holder {
    using SafeMath for uint256;

    struct BidInfo {
        address bidder;
        uint256 bid;
        uint256 timestamp;
    }

    struct Info {
        address owner;
        address admin;
        uint256 duration;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 tokenId;
        uint256 buyValue;
        address erc721Instance;
        address payTokenInstance;
        Type auctionType;
        States auctionState;
        uint256 highestBindingBid;
        address highestBidder;
        uint256 currentBid;
        bool erc721present;
    }

    // static

    address public owner; // auction owner
    address public admin; // can change admin and contractFeeAddresses
    uint256 public duration;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public tokenId;
    uint256 public buyValue;
    IERC721 public erc721Instance;
    IERC20 public payTokenInstance;
    Type public auctionType;

    // state
    States public auctionState;
    uint256 public highestBindingBid;
    address public highestBidder;
    uint256 public currentBid;
    bool public erc721present;
    uint256 public commissionPercent; // part of 1000: example 2.5% => value 25
    address public commissionWallet;
    bool private _initialized;

    BidInfo[] public bids;
    mapping(address => uint256) public fundsByBidder;

    event LogStartAuction(address indexed erc721address, uint256 tokenId, uint256 startTimestamp, uint256 endTimestamp);
    event LogBid(address indexed auction, address indexed bidder, uint256 bid, uint256 endTimestamp);
    event LogWithdrawal(address indexed withdrawer, address indexed withdrawalAccount, uint256 amount);
    event LogTokenClaimed(address indexed receiver, address indexed tokenAddress, uint256 tokenId);
    event LogCanceled(address indexed auctionAddr);
    event LogBuy(address indexed buyer, uint256 price);
    event LogSetTimestamp(uint256 newEndTimestamp);

    function initialize(AuctionConfig calldata _configs) external override {
        require(!_initialized, "Already initialized");
        require(commissionPercent < 1000, "Only 100% + 1 decimals");

        owner = _configs.owner;
        admin = _configs.admin;
        erc721Instance = IERC721(_configs.nftToken);
        tokenId = _configs.nftId;
        duration = _configs.duration;
        payTokenInstance = IERC20(_configs.payTokenAddress);
        buyValue = _configs.buyValue;
        currentBid = _configs.buyValue;
        auctionType = _configs.auctionType;
        auctionState = States.Initialize;
        commissionPercent = _configs.commissionPercent;
        commissionWallet = _configs.commissionWallet;

        _initialized = true;
    }

    function getBidInfo() external view returns (BidInfo[] memory) {
        return bids;
    }

    function getInfo() external view returns (Info memory data) {
        data = Info({
            owner: owner,
            admin: admin,
            duration: duration,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            tokenId: tokenId,
            buyValue: buyValue,
            erc721Instance: address(erc721Instance),
            payTokenInstance: address(payTokenInstance),
            auctionState: auctionState,
            auctionType: auctionType,
            highestBidder: highestBidder,
            highestBindingBid: highestBindingBid,
            currentBid: currentBid,
            erc721present: erc721present
        });
    }

    function isVisible() public view returns (bool) {
        return _checkVisible(_msgSender());
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function setTimestampAdmin(uint256 _endTimestamp) external onlyAdmin {
        endTimestamp = _endTimestamp;
        emit LogSetTimestamp(endTimestamp);
    }

    function getNeededAllowancePaytoken() external view returns (uint256) {
        return currentBid.sub(fundsByBidder[_msgSender()]);
    }

    function placeBid() external onlyStarted onlyBeforeEnd onlyNotOwner returns (bool success) {
        uint256 needAmount = currentBid.sub(fundsByBidder[_msgSender()]);
        highestBidder = _msgSender();
        BidInfo memory oneBidInfo = BidInfo(_msgSender(), currentBid, block.timestamp);
        bids.push(oneBidInfo);

        if (auctionType == Type.Auction) {
            highestBindingBid = fundsByBidder[highestBidder] + needAmount;
            fundsByBidder[highestBidder] = highestBindingBid;
            require(payTokenInstance.transferFrom(_msgSender(), address(this), needAmount), "Transfer bid failed");
            _setNewCurrentBid();
            emit LogBid(address(this), _msgSender(), highestBindingBid, endTimestamp);
            if (endTimestamp - block.timestamp < 3600) {
                endTimestamp += 600;
            }
        } else {
            uint256 _commission;
            uint256 _remain;
            (_commission, _remain) = _calculateFee(needAmount);
            erc721Instance.safeTransferFrom(address(this), _msgSender(), tokenId);
            require(payTokenInstance.transferFrom(_msgSender(), commissionWallet, _commission), "Transfer fee failed");
            require(payTokenInstance.transferFrom(_msgSender(), owner, _remain), "Transfer to owner failed");
            erc721present = false;
            auctionState = States.EndAuction;
            endTimestamp = block.timestamp;
            highestBidder = _msgSender();
            emit LogBuy(_msgSender(), needAmount);
        }
        return true;
    }

    function cancelAuction() external onlyOwner onlyNotCancelled onlyBeforeStartOrOnlyTrade returns (bool success) {
        auctionState = States.CancelAuction;
        erc721Instance.safeTransferFrom(address(this), owner, tokenId);
        erc721present = false;
        emit LogCanceled(address(this));
        return true;
    }

    function withdraw() external onlyNotCancelled onlyEndedTime nonReentrant returns (bool success) {
        require(_msgSender() != address(0), "Sender should not be zero.");
        uint256 withdrawalAmount;
        auctionState = States.EndAuction;
        if (_msgSender() == owner) {
            // the auction's owner should be allowed to withdraw the highestBindingBid
            withdrawalAmount = fundsByBidder[highestBidder];
            require(withdrawalAmount > 0, "Already withdrawn.");
            unchecked {
                fundsByBidder[highestBidder] -= withdrawalAmount;
            }

            uint256 _commission;
            uint256 _remain;
            (_commission, _remain) = _calculateFee(withdrawalAmount);
            require(payTokenInstance.transfer(address(commissionWallet), _commission), "Transfer fee failed");
            require(payTokenInstance.transfer(owner, _remain), "Transfer to owner failed");

            emit LogWithdrawal(_msgSender(), highestBidder, withdrawalAmount);
        } else if (_msgSender() == highestBidder) {
            require(erc721Instance.ownerOf(tokenId) == address(this), "NFT already withdrawn.");
            erc721present = false;
            erc721Instance.safeTransferFrom(address(this), highestBidder, tokenId);
            emit LogTokenClaimed(_msgSender(), address(erc721Instance), tokenId);
        } else {
            // anyone who participated but did not win the auction should be allowed to withdraw
            // the full amount of their funds
            withdrawalAmount = fundsByBidder[_msgSender()];
            require(withdrawalAmount > 0, "Already withdrawn");
            require(payTokenInstance.transfer(_msgSender(), withdrawalAmount), "Transfer failed");
            unchecked {
                fundsByBidder[_msgSender()] -= withdrawalAmount;
            }
            emit LogWithdrawal(_msgSender(), _msgSender(), withdrawalAmount);
        }
        return true;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override returns (bytes4) {
        //Here we check that owner of auction can`t change nft when auction starts
        require(auctionState == States.Initialize, "Should be in init state.");
        require(_from != address(0), "Should be not zero address.");
        require(_msgSender() == address(erc721Instance) && _tokenId == tokenId, "Wrong NFT");
        require(erc721Instance.ownerOf(tokenId) == address(this), "NFT not transferred.");

        erc721present = true;

        auctionState = States.StartAuction;
        startTimestamp = block.timestamp;
        endTimestamp = startTimestamp + duration;

        emit LogStartAuction(_msgSender(), _tokenId, startTimestamp, endTimestamp);

        return super.onERC721Received(_operator, _from, _tokenId, _data);
    }

    function _checkVisible(address _account) internal view returns (bool) {
        if (auctionState == States.StartAuction) {
            if (_account == owner) {
                // is Owner
                if (highestBidder == address(0)) {
                    // no bids
                    if (erc721present == true) {
                        return true;
                    }
                } else if (fundsByBidder[highestBidder] > 0) {
                    // any bids present and not withdrawn
                    return true;
                }
            } else if (_account == highestBidder) {
                // winner
                if (erc721present == true) {
                    // NFT not withdrawn
                    return true;
                }
            } else if (fundsByBidder[_account] > 0) {
                // just partisipant, not withdrawn
                return true;
            } else if (block.timestamp < endTimestamp) {
                // visible until end time
                return true;
            }
        }
        return false;
    }

    function _calculateFee(uint256 _amount) internal view returns (uint256 commission, uint256 remain) {
        commission = _amount * commissionPercent / 1000;
        require(_amount >= commission, "Commission is to high");
        unchecked {
            remain = _amount - commission;
        }
    }

    /**
     * @dev The first transaction only initialize auction(buy, placeBid)
     */
    function _setNewCurrentBid() private {
        uint256 increase = currentBid.div(10);
        currentBid += increase;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "Only owner");
        _;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Only admin");
        _;
    }

    modifier onlyNotOwner() {
        require(_msgSender() != owner, "Only not owner");
        _;
    }

    modifier onlyStarted() {
        require(auctionState == States.StartAuction, "Only after started");
        _;
    }

    modifier onlyEndedTime() {
        require(block.timestamp >= endTimestamp, "Only ended");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endTimestamp, "Only before end");
        _;
    }

    modifier onlyNotCancelled() {
        require(auctionState != States.CancelAuction, "Only not canceled");
        _;
    }

    modifier onlyBeforeStartOrOnlyTrade() {
        if (highestBidder != address(0) && auctionType != Type.Trade) {
            revert("Only before start or only trade");
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

enum Type {
    Auction,
    Trade
}

enum States {
    Initialize,
    ClaimToken,
    StartAuction,
    EndAuction,
    CancelAuction
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import "../helpers/TypeSupport.sol";

interface IAuction {
    struct AuctionConfig {
        address owner;
        address admin;
        uint256 duration;
        address nftToken;
        uint256 nftId;
        address payTokenAddress;
        uint256 buyValue;
        Type auctionType;
        address commissionWallet;
        uint256 commissionPercent;
    }

    function initialize(AuctionConfig calldata configs) external;
}