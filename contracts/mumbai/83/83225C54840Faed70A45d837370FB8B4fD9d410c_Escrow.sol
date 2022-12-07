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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * TODO: 用户如何查看自己拥有的NFT
 *       ERC1155  --> ERC721Enumerable
 *       or ---> 使用moralis，thegrah提供的中心化服务
 * 房产中介智能合约
 * - mint nft
 * - approve nft
 * - buyer出价，支付定金 (取消出价，退回定金)
 * - seller不同意，退回定金
 * - seller同意，进入交易流程
 * - 支付余额，nft transfer
 * - 规定时间内未支付余额，交易失败，定金和质押金退给seller --> 该行为在cancelTrade时发生
 * - 取消交易：buyer取消支付定金和赔偿，seller取消支付定金和赔偿
 */

error Escrow_OnlyDepositor();
error Escrow_InsufficientDeposit();
error Escrow_OnlyOwner();
error Escrow_OnlyBuyer();
error Escrow_OnlyBidder();
error Escrow_OnlyListing();
error Escrow_OnlyTrading();
error Escrow_BidderNotExist();
error Escrow_InsufficientEarnest();
error Escrow_InsufficientPayment();
error Escrow_InsufficientBalance();
error Escrow_TradeTimeout();
error Escrow_TransferTokenFail();
error Escrow_IllegalOperation();
error Escrow_LowerPrice();
error Escrow_NotApprove();
error Escrow_Listing();
error Escrow_Tradding();

contract Escrow is ReentrancyGuard {
    struct Estate {
        address seller;
        uint256 floorPrice;
    }
    struct TradeTrack {
        address buyer;
        uint256 tokenId;
        uint256 purchasePrice;
        uint256 time;
    }
    // 出价人
    struct Bidder {
        address buyer;
        uint256 purchasePrice;
        uint256 time;
    }

    IERC721 erc721;

    uint256 public minimumDeposit;

    uint256 public tradeTimeout;

    // Mapping for address to eth
    mapping(address => uint256) balance;

    mapping(uint256 => bool) isListing;

    mapping(address => uint256) depositor;

    mapping(uint256 => bool) isTrading;

    mapping(uint256 => Estate) estates;

    mapping(uint256 => TradeTrack) private trade;

    // tokenId => bidder => Bidder
    mapping(uint256 => mapping(address => Bidder)) private bidders;
    // todo: 使用 morali 改进智能合约
    mapping(uint256 => address[]) private biddersArray;

    modifier onlyDepositor() {
        if (depositor[msg.sender] < minimumDeposit) {
            revert Escrow_OnlyDepositor();
        }
        _;
    }

    modifier onlyBuyer(uint256 tokenId) {
        if (trade[tokenId].buyer != msg.sender) {
            revert Escrow_OnlyBuyer();
        }
        _;
    }

    modifier onlyOwner(uint256 tokenId) {
        if (msg.sender != erc721.ownerOf(tokenId)) {
            revert Escrow_OnlyOwner();
        }
        _;
    }

    modifier onlyBidder(uint256 tokenId) {
        if (bidders[tokenId][msg.sender].buyer == address(0)) {
            revert Escrow_OnlyBidder();
        }
        _;
    }

    modifier notListing(uint256 tokenId) {
        if (isListing[tokenId]) {
            revert Escrow_Listing();
        }
        _;
    }

    modifier onlyListing(uint256 tokenId) {
        if (!isListing[tokenId]) {
            revert Escrow_OnlyListing();
        }
        _;
    }

    modifier onlyTrading(uint256 tokenId) {
        if (!isTrading[tokenId]) {
            revert Escrow_OnlyTrading();
        }
        _;
    }

    modifier notTrading(uint256 tokenId) {
        if (isTrading[tokenId]) {
            revert Escrow_Tradding();
        }
        _;
    }

    modifier checkApprove(uint256 tokenId) {
        if (erc721.getApproved(tokenId) != address(this)) {
            revert Escrow_NotApprove();
        }
        _;
    }

    event EstateListing(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 indexed price
    );

    event Bid(
        address indexed bidder,
        uint256 indexed tokenId,
        uint256 indexed price
    );

    event UpdateBid(
        address indexed bidder,
        uint256 indexed tokenId,
        uint256 indexed price
    );

    event CancelBid(address indexed bidder, uint256 indexed tokenId);

    event Deposit(address indexed depositor, uint256 value);

    event EnterTrade(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer
    );

    event CancelTrade(uint256 indexed tokenId, address seller, address buyer);

    event FinishTrade(uint256 indexed tokenId);

    event getDepositEvent(address indexed sender, uint256 indexed deposit);

    constructor(
        address _nftAddress,
        uint256 _minimumDeposit,
        uint256 _tradeTimeout
    ) {
        erc721 = IERC721(_nftAddress);
        minimumDeposit = _minimumDeposit;
        tradeTimeout = _tradeTimeout;
    }

    function deposit() public payable {
        if (msg.value < minimumDeposit) {
            revert Escrow_InsufficientDeposit();
        }
        depositor[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * 添加房产
     */
    function addEstate(
        uint256 tokenId,
        uint256 price
    )
        public
        onlyOwner(tokenId)
        onlyDepositor
        notListing(tokenId)
        checkApprove(tokenId)
    {
        if (estates[tokenId].seller != address(0)) {
            revert Escrow_IllegalOperation();
        }
        estates[tokenId] = Estate(msg.sender, price);
        isListing[tokenId] = true;
        unchecked {
            depositor[msg.sender] -= minimumDeposit;
        }
        emit EstateListing(msg.sender, tokenId, price);
    }

    /**
     * seller确认交易，进入交易审核流程
     */
    function enterTrade(
        uint256 tokenId,
        address buyer
    )
        public
        onlyListing(tokenId)
        notTrading(tokenId)
        onlyOwner(tokenId)
        nonReentrant
    {
        Bidder storage bidder = bidders[tokenId][buyer];
        if (bidder.buyer == address(0)) {
            revert Escrow_BidderNotExist();
        }
        isTrading[tokenId] = true;
        trade[tokenId] = TradeTrack(
            buyer,
            tokenId,
            bidder.purchasePrice,
            block.timestamp
        );
        // 剩余人退回定金
        for (uint256 i = 0; i < biddersArray[tokenId].length; i++) {
            address bd = biddersArray[tokenId][i];
            if (bidders[tokenId][bd].buyer == address(0)) {
                continue;
            }
            if (bd != buyer) {
                depositor[bd] += minimumDeposit;
            }
            delete bidders[tokenId][bd];
        }
        delete biddersArray[tokenId];
        emit EnterTrade(tokenId, msg.sender, buyer);
    }

    /**
     * 取消交易
     * 退定金
     *      超时没有完成交易: seller获得定金和抵押金
     *      seller 取消: 抵押金
     *      buyer  取消: 抵押金
     */
    function cancelTrade(
        uint256 tokenId
    ) public onlyTrading(tokenId) nonReentrant {
        address seller = estates[tokenId].seller;
        address buyer = trade[tokenId].buyer;
        uint256 payment = minimumDeposit;
        if (block.timestamp - trade[tokenId].time > tradeTimeout) {
            balance[seller] += payment;
        } else if (msg.sender == seller) {
            if (depositor[seller] < minimumDeposit) {
                revert Escrow_InsufficientDeposit();
            }
            transferToken(buyer, minimumDeposit);
            unchecked {
                depositor[buyer] += minimumDeposit;
                depositor[seller] -= minimumDeposit;
            }
        } else if (msg.sender == buyer) {
            transferToken(seller, payment);
        } else {
            revert Escrow_IllegalOperation();
        }
        delete trade[tokenId];
        isTrading[tokenId] = false;
        emit CancelTrade(tokenId, seller, buyer);
    }

    /**
     * 超时不允许支付，只能取消交易
     * 支付尾款，完成交易，nft转移
     * 超过一定时间没有支付则取消交易，并且支付赔偿
     */
    function finishTrade(
        uint256 tokenId
    ) public payable onlyTrading(tokenId) onlyBuyer(tokenId) {
        if (block.timestamp - trade[tokenId].time > tradeTimeout) {
            revert Escrow_TradeTimeout();
        }
        // check value
        // transfer
        TradeTrack storage tradeTrack = trade[tokenId];
        Estate storage estate = estates[tokenId];
        if (msg.value < tradeTrack.purchasePrice) {
            revert Escrow_InsufficientPayment();
        }
        address seller = estate.seller;
        address buyer = msg.sender;
        erc721.transferFrom(seller, buyer, tokenId);
        unchecked {
            balance[seller] += tradeTrack.purchasePrice;
            depositor[seller] += minimumDeposit;
            depositor[buyer] += minimumDeposit;
        }
        delete isListing[tokenId];
        delete isTrading[tokenId];
        delete estates[tokenId];
        delete trade[tokenId];
        emit FinishTrade(tokenId);
    }

    /**
     * 出价 todo: 添加不在交易中的限制！！！
     */
    function bid(
        uint256 tokenId,
        uint256 purchasePrice
    )
        public
        onlyDepositor
        notTrading(tokenId)
        onlyListing(tokenId)
        returns (bool)
    {
        if (purchasePrice < estates[tokenId].floorPrice) {
            revert Escrow_LowerPrice();
        }
        bidders[tokenId][msg.sender] = Bidder(
            msg.sender,
            purchasePrice,
            block.timestamp
        );
        biddersArray[tokenId].push(msg.sender);
        depositor[msg.sender] -= minimumDeposit;
        emit Bid(msg.sender, tokenId, purchasePrice);
        return true;
    }

    /**
     * 更新出价
     */
    function updateBid(
        uint256 tokenId,
        uint256 _purchasePrice
    ) public notTrading(tokenId) onlyBidder(tokenId) {
        if (_purchasePrice < estates[tokenId].floorPrice) {
            revert Escrow_LowerPrice();
        }
        // 这样时直接改变 storage 指向的内存
        // 如果先使用memory拷贝，则不会改变合约变量
        // Bidder memory bd = bidders[tokenId][msg.sender];
        // bd.purchasePrice = _purchasePrice;
        // bd.time = block.timestamp;  --> not work

        // memory ---> copy variable and use
        // storate ---> 直接返回指针
        bidders[tokenId][msg.sender].purchasePrice = _purchasePrice;
        bidders[tokenId][msg.sender].time = block.timestamp;
        emit UpdateBid(msg.sender, tokenId, _purchasePrice);
    }

    /**
     *  取消出价
     *  未进入交易流程才能取消出价
     *  进入交易流程前，未中标人的定金原路返回
     */
    function cancelBid(
        uint256 tokenId
    )
        public
        onlyBidder(tokenId)
        notTrading(tokenId)
        onlyListing(tokenId)
        returns (bool)
    {
        delete bidders[tokenId][msg.sender];
        depositor[msg.sender] += minimumDeposit;
        emit CancelBid(msg.sender, tokenId);
        return true;
    }

    function withdrawBalance(uint256 amount) external nonReentrant {
        if (balance[msg.sender] < amount) {
            revert Escrow_InsufficientBalance();
        }
        unchecked {
            balance[msg.sender] -= amount;
        }
        transferToken(msg.sender, amount);
    }

    function withdrawDeposit(uint256 amount) external nonReentrant {
        if (depositor[msg.sender] < amount) {
            revert Escrow_InsufficientDeposit();
        }
        unchecked {
            depositor[msg.sender] -= amount;
        }
        transferToken(msg.sender, amount);
    }

    function transferToken(address to, uint256 value) private {
        (bool success, ) = payable(to).call{value: value}("");
        if (!success) {
            revert Escrow_TransferTokenFail();
        }
    }

    function balanceOf() public view returns (uint256) {
        return balance[msg.sender];
    }

    /**
     *  pure or view function
     *  TODO: 测试 stroage 和 memory 的gas开销
     *  是否读取合约变量用stroage比memory要更加省gas费用
     */

    function getErc721() public view returns (IERC721) {
        return erc721;
    }

    function getIsListing(uint256 tokenId) public view returns (bool) {
        return isListing[tokenId];
    }

    function getDeposit(address _depositor) public view returns (uint256) {
        return depositor[_depositor];
    }

    function getIsTrading(uint256 tokenId) public view returns (bool) {
        return isTrading[tokenId];
    }

    function getEstate(uint256 tokenId) public view returns (Estate memory) {
        return estates[tokenId];
    }

    function getTrade(uint256 tokenId) public view returns (TradeTrack memory) {
        return trade[tokenId];
    }

    function getTradeTimeout() public view returns (uint256) {
        return tradeTimeout;
    }

    function getBiddersLen(uint256 tokenId) public view returns (uint256) {
        return biddersArray[tokenId].length;
    }

    function getBidders(
        uint256 tokenId,
        address bidder
    ) public view returns (Bidder memory) {
        return bidders[tokenId][bidder];
    }

    function getAllBidderAddress(
        uint256 tokenId
    ) public view returns (address[] memory) {
        return biddersArray[tokenId];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMinimumDeposit() public view returns (uint256) {
        return minimumDeposit;
    }

    function getMinimumDepositTest() public returns (uint256) {
        emit getDepositEvent(msg.sender, minimumDeposit);
        return minimumDeposit;
    }
}