// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20Extended as IERC20} from "./IERC20Extended.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/// @title IssueSCI
/// @notice Issuing contract for ScienceCoins (SCI)
contract IssueSCI is Ownable {
    using SafeMath for uint256;
    IERC20 public openTherapoidContract;

    uint256 public transferThreshold;
    uint256 public totalTokensIssued;
    address public pendingOwner;
    mapping(address => bool) public isIssuer;

    event LogUpdateThreshold(uint256 oldThreshold, uint256 newThreshold);
    event LogAddIssuer(address issuer, uint256 addedAt);
    event LogRemoveIssuer(address issuer, uint256 removedAt);
    event OwnershipTransferCancelled(address newOwner);

    /**
     * @dev Modifier to make a function invocable by only the issuer account
     */
    modifier onlyIssuer() {
        require(isIssuer[msg.sender], "Caller is not issuer");
        _;
    }

    /**
     * @dev Sets the values for {OpenTherapoid Contract}.
     *
     * All of these values except _transferThreshold, _tokenIssuers are immutable: they can only be set once during
     * construction.
     */
    constructor(
        IERC20 _openTherapoidContractAddress,
        uint256 _transferThreshold,
        address contractOwner,
        address[] memory _tokenIssuers
    ) {
        //solhint-disable-next-line reason-string
        require(
            contractOwner != address(0),
            "Contract owner can't be address zero"
        );
        //solhint-disable-next-line reason-string
        require(
            address(_openTherapoidContractAddress) != address(0),
            "OpenTherapoid contract can't be address zero"
        );
        uint256 issuerLength = _tokenIssuers.length;
        address issuer;
        for (uint256 i = 0; i < issuerLength; i++) {
            issuer = _tokenIssuers[i];
            require(issuer != address(0), "Issuer can't be address zero");
            isIssuer[issuer] = true;
            //solhint-disable-next-line not-rely-on-time
            emit LogAddIssuer(issuer, block.timestamp);
        }
        openTherapoidContract = _openTherapoidContractAddress;
        transferThreshold = _transferThreshold;
        // Transfers contract ownership to contractOwner
        super.transferOwnership(contractOwner);
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     * The receive function is executed on a call to the contract with empty calldata.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        //solhint-disable-next-line reason-string
        require(
            newOwner != address(this),
            "ISCI: new owner cannot be current contract"
        );
        require(pendingOwner == address(0), "Pending owner exists");
        pendingOwner = newOwner;
    }

    /**
     * @dev To cancel ownership transfer
     *
     * Requirements:
     * - can only be invoked by the contract owner
     * - the pendingOwner must be non-zero
     */
    function cancelTransferOwnership() external onlyOwner {
        require(pendingOwner != address(0), "No pending owner");
        delete pendingOwner;
        emit OwnershipTransferCancelled(pendingOwner);
    }

    /**
     * @dev New owner accepts the contract ownershi
     *
     * Requirements:
     * - The pending owner must be set prior to claiming ownership
     */
    function claimOwnership() external {
        require(msg.sender == pendingOwner, "Caller is not pending owner");
        emit OwnershipTransferred(owner(), pendingOwner);
        _owner = pendingOwner;
        delete pendingOwner;
    }

    /**
     * @dev Moves tokens `amount` from `tokenOwner` to `recipients`.
     */
    function issueBulkSCIToken(
        address[] memory recipients,
        uint256[] memory amounts,
        bytes32[] memory activities
    ) external onlyIssuer {
        uint256 totalAmounts;
        require(
            (recipients.length == amounts.length) &&
                (recipients.length == activities.length),
            "ISCI: Unequal params"
        );
        uint256 amtLength = amounts.length;
        for (uint256 i = 0; i < amtLength; i++) {
            totalAmounts = totalAmounts.add(amounts[i]);
        }
        //solhint-disable-next-line reason-string
        require(
            transferThreshold >= (totalTokensIssued.add(totalAmounts)),
            "issueBulkSCIToken: Threshold exceeds, wait till threshold is updated"
        );
        totalTokensIssued = totalTokensIssued.add(totalAmounts);
        openTherapoidContract.bulkTransfer(recipients, amounts, activities);
    }

    /**
     * @dev To transfer all BNBs/ETHs stored in the contract to the caller
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawAll() external onlyOwner {
        //solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{
            gas: 2300,
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev To transfer stuck ERC20 tokens from within the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawStuckTokens(IERC20 token, address receiver)
        external
        onlyOwner
    {
        require(address(token) != address(0), "Token cannot be address zero");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);
    }

    /**
     * @dev To increase transfer threshold value for this contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function updateThreshold(uint256 newThreshold, bool shouldIncrease)
        external
        onlyOwner
    {
        uint256 oldThreshold = transferThreshold;
        if (shouldIncrease) {
            transferThreshold = transferThreshold.add(newThreshold);
        } else {
            transferThreshold = transferThreshold.sub(newThreshold);
        }
        emit LogUpdateThreshold(oldThreshold, transferThreshold);
    }

    /**
     * @dev To add issuers address in the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function addIssuers(address[] memory _issuers) external onlyOwner {
        address issuer;
        uint256 issuerLength = _issuers.length;
        for (uint256 i = 0; i < issuerLength; i++) {
            issuer = _issuers[i];
            require(issuer != address(0), "Issuer can't be address zero");
            require(!isIssuer[issuer], "Already an issuer");
            isIssuer[issuer] = true;
            //solhint-disable-next-line not-rely-on-time
            emit LogAddIssuer(issuer, block.timestamp);
        }
    }

    /**
     * @dev To remove issuers address from the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function removeIssuers(address[] memory _issuers) external onlyOwner {
        address issuer;
        uint256 issuerLength = _issuers.length;
        for (uint256 i = 0; i < issuerLength; i++) {
            issuer = _issuers[i];
            require(issuer != address(0), "Issuer can't be address zero");
            require(isIssuer[issuer], "Not an issuer");
            isIssuer[issuer] = false;
            //solhint-disable-next-line not-rely-on-time
            emit LogRemoveIssuer(issuer, block.timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    /**
     * @dev Moves tokens `amount` from `tokenOwner` to `recipients`.
     */
    function bulkTransfer(
        address[] memory recipients,
        uint256[] memory amounts,
        bytes32[] memory activities
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}