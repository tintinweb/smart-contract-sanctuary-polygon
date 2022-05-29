// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./imarket.sol";

contract Market is IMarket {
    using SafeMath for uint256;

    event TradeStatusChange(
        uint256 id,
        address itemTokenAddr,
        uint256 itemTokenID,
        bytes32 status
    );

    string private _version = "2.0.0";

    address private _owner;

    address private _feeSinkAddr;
    address private _creatorFundAddr;

    IERC20 private _currencyTokenContract;

    uint256 private _minPrice;
    uint256 private _maxAmount = uint256(5);

    // Trades
    mapping(uint256 => Trade) private _trades;
    mapping(address => mapping(uint256 => uint256)) private _tradeIDs;
    mapping(address => uint256) private _tradesPerAddressCount;
    uint256 private _tradeCounter;

    uint256 private _itemsSoldCounter;

    modifier onlyOwner {
      require(msg.sender == _owner, "only-owner");
      _;
    }
    constructor(address arg_currencyTokenAddr, address arg_feeSinkAddr, address arg_creatorFundAddr) {
        _currencyTokenContract = IERC20(arg_currencyTokenAddr);
        _feeSinkAddr = arg_feeSinkAddr;
        _creatorFundAddr = arg_creatorFundAddr;
        _owner = msg.sender;
    }

    function version() public view returns (string memory) {
        return _version;
    }

    function minPrice() public view returns (uint256) {
        return _minPrice;
    }

    function perAddressAmount(address arg_addr) public view returns (uint256) {
        return _tradesPerAddressCount[arg_addr];
    }

    function setMinPrice(uint256 arg_minPrice) public onlyOwner {
        _minPrice = arg_minPrice;
    }

    function maxAmount() public view returns (uint256) {
        return _maxAmount;
    }

    function setMaxAmount(uint256 arg_maxAmount) public onlyOwner {
        require(arg_maxAmount > uint256(0), "Max amount cant be zero");

        _maxAmount = arg_maxAmount;
    }

    function getTradeByID(uint256 arg_tradeID) public view returns (Trade memory) {
        Trade memory trade = _trades[arg_tradeID];
        require(trade.id > 0, "trade not exists");

        return trade;
    }

    function getTradeID(address arg_tokenContractAddr, uint256 arg_itemID) public view returns (uint256) {
        uint256 tradeID = _tradeIDs[arg_tokenContractAddr][arg_itemID];
        require(tradeID > 0, "trade not exists");

        return tradeID;
    }

    function openTrade(address arg_sellerAddr, address arg_tokenContractAddr, uint256 arg_itemID, uint256 arg_price) public virtual {
        require(arg_tokenContractAddr != address(0), "token contract address cant be empty");
        require(arg_price >= _minPrice, "Price too low");

        _tradesCounterInc();
        uint256 tradeID = _tradeCounter;

        address sellerAddr = msg.sender;
        if (arg_sellerAddr != address(0)) {
            sellerAddr = arg_sellerAddr;
        }

        Trade memory trade = Trade(tradeID, sellerAddr, arg_tokenContractAddr, arg_itemID, arg_price);

        _trades[tradeID] = trade;
        _tradeIDs[arg_tokenContractAddr][arg_itemID] = tradeID;

        IERC721(arg_tokenContractAddr).transferFrom(msg.sender, address(this), trade.itemTokenID);

        emit TradeStatusChange(tradeID, arg_tokenContractAddr, arg_itemID, "Open");
    }

    function buyBox(uint256[] memory arg_tradeIDs) public {
        require(arg_tradeIDs.length != 0,  "Empty trade ids");
        require(arg_tradeIDs.length < _maxAmount,  "Max amount exceeded");
        require((_tradesPerAddressCount[msg.sender] + arg_tradeIDs.length) < _maxAmount,  "Max amount per address exceeded");

        for (uint256 i = 0; i < arg_tradeIDs.length; i++) {
          uint256 tradeID = arg_tradeIDs[i];
          executeTrade(tradeID);
        }
    }

    function executeTrade(uint256 arg_tradeID) public {
        Trade memory trade = _trades[arg_tradeID];
        require(msg.sender != trade.seller, "The buyer cannot be the seller");
        require(trade.id > 0, "Trade not exists");

        uint256 totalAmount = trade.price;

        uint256 feeSinkAmount = totalAmount.div(10);
        _currencyTokenContract.transferFrom(msg.sender, _feeSinkAddr, feeSinkAmount);

        uint256 fundAmount = totalAmount.div(20);
        _currencyTokenContract.transferFrom(msg.sender, _creatorFundAddr, fundAmount);

        uint256 sellerAmount = totalAmount.sub(feeSinkAmount).sub(fundAmount);
        _currencyTokenContract.transferFrom(msg.sender, trade.seller, sellerAmount);


        IERC721(trade.itemTokenAddr).transferFrom(address(this), msg.sender, trade.itemTokenID);

        delete _tradeIDs[trade.itemTokenAddr][trade.itemTokenID];
        delete _trades[arg_tradeID];
        _tradesPerAddressCounterInc(msg.sender);

        emit TradeStatusChange(trade.id, trade.itemTokenAddr, trade.itemTokenID, "Executed");
    }

    function cancelTrade(uint256 arg_tradeID) public virtual {
        Trade memory trade = _trades[arg_tradeID];
        require(msg.sender == trade.seller, "Trade can be cancelled only by seller.");
        require(trade.id > 0, "Trade not exists");

        IERC721(trade.itemTokenAddr).transferFrom(address(this), trade.seller, trade.itemTokenID);

        delete _tradeIDs[trade.itemTokenAddr][trade.itemTokenID];
        delete _trades[arg_tradeID];

        emit TradeStatusChange(trade.id, trade.itemTokenAddr, trade.itemTokenID, "Cancelled");
    }

    function _tradesCounterInc() private {
        require(_tradeCounter < type(uint256).max, "Increment overflow");

        _tradeCounter += 1;
    }

    function _tradesPerAddressCounterInc(address arg_addr) private {
        require(_tradesPerAddressCount[arg_addr] < type(uint256).max, "Increment overflow");

        _tradesPerAddressCount[arg_addr] += 1;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IMarket {
    struct Trade {
        uint256 id;
        address seller;
        address itemTokenAddr;
        uint256 itemTokenID;
        uint256 price;
    }

    function version()
        external
        view
        returns (string memory);

    function minPrice()
        external
        view
        returns (uint256);

    function setMinPrice(uint256 arg_minPrice)
        external;

    function perAddressAmount(address arg_addr)
        external
        view
        returns (uint256);

    function maxAmount()
        external
        view
        returns (uint256);

    function setMaxAmount(uint256 arg_maxAmount)
        external;

    function getTradeByID(uint256 arg_tradeID)
        external
        view
        returns (Trade memory);

    function getTradeID(
        address arg_tokenContractAddr,
        uint256 arg_itemID
    )
        external
        view
        returns (uint256);

    function openTrade(
        address arg_tokenContractAddr,
        address arg_sellerAddr,
        uint256 arg_itemID,
        uint256 arg_price
    )
        external;

    function executeTrade(uint256 arg_tradeID)
        external;

    function cancelTrade(uint256 arg_tradeID)
        external;
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