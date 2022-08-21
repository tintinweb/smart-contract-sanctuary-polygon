// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./RouterConfig.sol";

struct Invoice {
    string id;
    uint256 amount;
    uint256 fee;

    uint256 balance;
    uint256 paidAmount;
    uint256 refundedAmount;

    bool isNativeToken;
    address tokenType;
    address[] availableTokenTypes;
    string ref;
    address receipientAddress;
    address senderAddress;
    string receipientName;
    string receipientEmail;

    bool paid;
    bool deposited;
    bool exist;
    bool instant;
    bool refunded;

    uint32 releaseLockTimeout;

    uint32 releaseLockDate;
    uint32 depositDate;
    uint32 confirmDate;
    uint32 refundDate;
    uint32 createdDate;
}

contract TransferSafeRouter is Ownable, RouterConfigContract {
    uint256 nativeFeeBalance = 0;
    uint256 fee = 10;

    mapping(address => uint256) tokensFeeBalances;
    mapping(string => Invoice) private invoices;
    mapping(address => string[]) private userInvoices;

    event PaymentReceived(string invoiceId);
    event InvoiceWithdrawn(Invoice invoice, uint256 amount);
    event InvoiceRefunded(Invoice invoice, uint256 amount);
    event InvoiceCreated(string invoiceId);

    constructor(uint256 _chainId) Ownable() RouterConfigContract(_chainId) {
        chainId = _chainId;
    }

    function createInvoice(Invoice memory invoice) public {
        require(invoices[invoice.id].exist != true, "DUPLICATE_INVOICE");
        invoice.exist = true;
        invoice.receipientAddress = msg.sender;
        invoice.releaseLockDate = uint32(block.timestamp) + invoice.releaseLockTimeout;
        invoice.fee = SafeMath.div(SafeMath.mul(invoice.amount, fee), 1000);
        invoice.paidAmount = 0;
        invoice.refundedAmount = 0;
        invoice.depositDate = 0;
        invoice.confirmDate = 0;
        invoice.refundDate = 0;
        invoice.refunded = false;
        invoice.deposited = false;
        invoice.paid = false;
        invoice.createdDate = uint32(block.timestamp);
        invoices[invoice.id] = invoice;
        userInvoices[invoice.receipientAddress].push(invoice.id);
        emit InvoiceCreated(invoice.id);
    }

    function listInvoices(address userAddress, uint256 take, uint256 skip) public view returns (Invoice[] memory) {
        string[] memory userInvoiceIds = userInvoices[userAddress];
        Invoice[] memory userInvoicesArray = new Invoice[](userInvoiceIds.length);
        if (userInvoiceIds.length == 0) {
            return userInvoicesArray;
        }
        uint256 itemsLength = 0;
        for (uint256 i = userInvoiceIds.length - 1 - skip; i >= 0; i--) {
            userInvoicesArray[i] = invoices[userInvoiceIds[i]];
            itemsLength++;
            if (itemsLength >= take) {
                break;
            }
        }
        return userInvoicesArray;
    }

    function confirmInvoice(string memory invoiceId) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance > 0, "INVOICE_NOT_BALANCED");
        require(invoice.senderAddress == msg.sender, "FORBIDDEN");
        require(invoice.paid == false, "INVOICE_HAS_BEEN_PAID");

        uint256 payoutAmount = SafeMath.sub(invoices[invoiceId].balance, invoices[invoiceId].fee);
        invoices[invoiceId].balance = 0;
        if (invoice.isNativeToken) {
            nativeFeeBalance += invoice.fee;
            invoices[invoiceId].paidAmount = payoutAmount;
            payable(msg.sender).transfer(payoutAmount);
        } else {
            tokensFeeBalances[invoice.tokenType] += invoice.fee;
            IERC20 token = IERC20(invoice.tokenType);
            token.transfer(invoice.receipientAddress, payoutAmount);
        }

        invoices[invoiceId].confirmDate = uint32(block.timestamp);
        invoices[invoiceId].paid = true;

        emit InvoiceWithdrawn(invoices[invoiceId], payoutAmount);
    }

    function refundInvoice(string memory invoiceId) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance > 0, "INVOICE_NOT_BALANCED");
        require(invoice.receipientAddress == msg.sender, "FORBIDDEN");
        require(invoice.paid == false, "INVOICE_HAS_BEEN_PAID");

        uint256 refundAmount = invoice.balance;
        invoices[invoiceId].balance = 0;
        invoices[invoiceId].refunded = true;

        if (invoice.isNativeToken) {
            payable(msg.sender).transfer(refundAmount);
        } else {
            IERC20 token = IERC20(invoice.tokenType);
            token.transfer(invoice.receipientAddress, refundAmount);
        }

        invoices[invoiceId].refundDate = uint32(block.timestamp);

        emit InvoiceRefunded(invoices[invoiceId], refundAmount);
    }

    function deposit(string memory invoiceId, bool instant) payable public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance == 0, "INVOICE_NOT_BALANCED");

        invoices[invoiceId].balance = msg.value;
        invoices[invoiceId].senderAddress = msg.sender;

        invoices[invoiceId].depositDate = uint32(block.timestamp);
        invoices[invoiceId].deposited = true;

        emit PaymentReceived(invoiceId);

        if (instant == true || invoice.instant == true) {
            confirmInvoice(invoiceId);
        }
    }

    function depositErc20(string memory invoiceId, address tokenType, bool instant) public {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.balance == 0, "INVOICE_NOT_BALANCED");

        IERC20 token = IERC20(invoice.tokenType);
        token.transferFrom(msg.sender, address(this), invoice.amount);
        invoices[invoiceId].balance = invoice.amount;
        invoices[invoiceId].tokenType = tokenType;

        invoices[invoiceId].depositDate = uint32(block.timestamp);
        invoices[invoiceId].deposited = true;

        emit PaymentReceived(invoiceId);
    }

    function getNativeFeeBalance() public view returns (uint256) {
        return nativeFeeBalance;
    }
    
    function getTokenFeeBalance(address tokenType) public view returns (uint256) {
        return tokensFeeBalances[tokenType];
    }

    function getInvoice(string memory invoiceId) public view returns (Invoice memory) {
        Invoice memory invoice = invoices[invoiceId];
        return invoice;
    }

    function getUserInvoices(address user) public view returns (Invoice[] memory) {
        string[] memory userInvoiceIds = userInvoices[user];
        Invoice[] memory userInvoicesArray = new Invoice[](userInvoiceIds.length);
        for (uint256 i = 0; i < userInvoiceIds.length; i++) {
            userInvoicesArray[i] = invoices[userInvoiceIds[i]];
        }
        return userInvoicesArray;
    }

    function widthdrawFee(address destination, uint256 amount) public onlyOwner {
        nativeFeeBalance = SafeMath.sub(nativeFeeBalance, amount);
        payable(destination).transfer(amount);
    }

    function widthdrawErc20Fee(address destination, address tokenType, uint256 amount) public onlyOwner {
        tokensFeeBalances[tokenType] = SafeMath.sub(tokensFeeBalances[tokenType], amount);
        IERC20 token = IERC20(tokenType);
        token.transfer(destination, amount);
    }

    function setFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    function getFee() view public returns (uint256) {
        return fee;
    }

    function amountInCurrency(string memory invoiceId, address token) view public returns (uint256) {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.exist, "INVOICE_NOT_EXIST!");
        address chainlinkAddress = config.chainlinkTokensAddresses[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(chainlinkAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return convertAmount(invoice.amount, price, decimals);
    }
    
    function amountInNativeCurrency(string memory invoiceId) view public returns (uint256) {
        Invoice memory invoice = invoices[invoiceId];
        require(invoice.exist, "INVOICE_NOT_EXIST!");
        address chainlinkAddress = config.chainlinkNativeTokenAddress;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(chainlinkAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return convertAmount(invoice.amount, price, decimals);
    }

    function convertAmount(uint256 amount, int256 price, uint8 decimals) pure private returns (uint256) {
        return SafeMath.div(
            SafeMath.mul(
                amount,
                uint256(price)
            ),
            10 ** decimals
        );
    }
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

struct RouterConfig {
    mapping(address => address) chainlinkTokensAddresses;
    address chainlinkNativeTokenAddress;
}

abstract contract RouterConfigContract {
    RouterConfig config;
    uint256 chainId;

    constructor(uint256 _chainId) {
        chainId = _chainId;

        initializeChainlink();
    }

    function initializeChainlink() private {
        if (chainId == 80001) {
            // USDT
            config.chainlinkTokensAddresses[0x326C977E6efc84E512bB9C30f76E30c160eD06FB] = 0x92C09849638959196E976289418e5973CC96d645;
            // DAI
            config.chainlinkTokensAddresses[0xd393b1E02dA9831Ff419e22eA105aAe4c47E1253] = 0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046;
            // MATIC
            config.chainlinkNativeTokenAddress = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
            return;
        }
        revert("Chain id is not supported");
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