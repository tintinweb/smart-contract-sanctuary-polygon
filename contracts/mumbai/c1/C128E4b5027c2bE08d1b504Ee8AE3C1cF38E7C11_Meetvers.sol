// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./taxes/ITaxHandler.sol";
import "./taxes/ITreasuryHandler.sol";

/**
 * @title Meetverse token contract
 * @dev The Meetverse token has modular systems for tax and treasury handler.
 */
contract Meetvers is IERC20, Ownable {
    using SafeMath for uint256;

    /// @dev Registry of user token balances.
    mapping(address => uint256) private _balances;

    /// @notice The contract implementing tax calculations.
    ITaxHandler public taxHandler;

    /// @notice The contract that performs treasury-related operations.
    ITreasuryHandler public treasuryHandler;

    /// @notice Emitted when the tax handler contract is changed.
    event TaxHandlerChanged(address oldAddress, address newAddress);

    /// @notice Emitted when the treasury handler contract is changed.
    event TreasuryHandlerChanged(address oldAddress, address newAddress);

    event GetWETHPath(address WETHAddress);

    event SwapAndTransferToTreasury(address from, uint256 tax);

    event TransferToTreasury(address treasuryAddress, uint256 tax);

    /// @dev Name of the token.
    string private _name;

    /// @dev Symbol of the token.
    string private _symbol;

    /// @dev Registry of addresses users have given allowances to.
    mapping(address => mapping(address => uint256)) private _allowances;

    address primaryPoolTokenAddress;

    bool private swapping = false;

    /**
     * @param name_ Name of the token.
     * @param symbol_ Symbol of the token.
     * @param taxHandlerAddress Initial tax handler contract.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address taxHandlerAddress
    ) {
        _name = name_;
        _symbol = symbol_;

        taxHandler = ITaxHandler(taxHandlerAddress);

        _balances[_msgSender()] = totalSupply();

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    /**
     * @notice Get token name.
     * @return Name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Get token symbol.
     * @return Symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Get number of decimals used by the token.
     * @return Number of decimals used by the token.
     */
    function decimals() external pure returns (uint8) {
        return 9;
    }

    /**
     * @notice Get the maximum number of tokens.
     * @return The maximum number of tokens that will ever be in existence.
     */
    function totalSupply() public pure override returns (uint256) {
        // Ten trillion, i.e., 10,000,000,000,000 tokens.
        return 1e13 * 1e9;
    }

    /**
     * @notice Get token balance of given given account.
     * @param account Address to retrieve balance for.
     * @return The number of tokens owned by `account`.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfer tokens from caller's address to another.
     * @param recipient Address to send the caller's tokens to.
     * @param amount The number of tokens to transfer to recipient.
     * @return True if transfer succeeds, else an error is raised.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice Get the allowance `owner` has given `spender`.
     * @param owner The address on behalf of whom tokens can be spent by `spender`.
     * @param spender The address authorized to spend tokens on behalf of `owner`.
     * @return The allowance `owner` has given `spender`.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve address to spend caller's tokens.
     * @dev This method can be exploited by malicious spenders if their allowance is already non-zero. See the following
     * document for details: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit.
     * Ensure the spender can be trusted before calling this method if they've already been approved before. Otherwise
     * use either the `increaseAllowance`/`decreaseAllowance` functions, or first set their allowance to zero, before
     * setting a new allowance.
     * @param spender Address to authorize for token expenditure.
     * @param amount The number of tokens `spender` is allowed to spend.
     * @return True if the approval succeeds, else an error is raised.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @param sender Address to move tokens from.
     * @param recipient Address to send the caller's tokens to.
     * @param amount The number of tokens to transfer to recipient.
     * @return True if the transfer succeeds, else an error is raised.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "MEETVERSE:transferFrom:ALLOWANCE_EXCEEDED: Transfer amount exceeds allowance."
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @notice Increase spender's allowance.
     * @param spender Address of user authorized to spend caller's tokens.
     * @param addedValue The number of tokens to add to `spender`'s allowance.
     * @return True if the allowance is successfully increased, else an error is raised.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;
    }

    /**
     * @notice Decrease spender's allowance.
     * @param spender Address of user authorized to spend caller's tokens.
     * @param subtractedValue The number of tokens to remove from `spender`'s allowance.
     * @return True if the allowance is successfully decreased, else an error is raised.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "MEETVERSE:decreaseAllowance:ALLOWANCE_UNDERFLOW: Subtraction results in sub-zero allowance."
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Set new tax handler contract.
     * @param taxHandlerAddress Address of new tax handler contract.
     */
    function setTaxHandler(address taxHandlerAddress) external onlyOwner {
        address oldTaxHandlerAddress = address(taxHandler);
        taxHandler = ITaxHandler(taxHandlerAddress);

        emit TaxHandlerChanged(oldTaxHandlerAddress, taxHandlerAddress);
    }

    /**
     * @notice Set new treasury handler contract.
     * @param treasuryHandlerAddress Address of new treasury handler contract.
     */
    function setTreasuryHandler(address treasuryHandlerAddress) external onlyOwner {
        address oldTreasuryHandlerAddress = address(treasuryHandler);
         treasuryHandler = ITreasuryHandler(treasuryHandlerAddress);

        emit TreasuryHandlerChanged(oldTreasuryHandlerAddress, treasuryHandlerAddress);
    }

    /**
     * @notice Approve spender on behalf of owner.
     * @param owner Address on behalf of whom tokens can be spent by `spender`.
     * @param spender Address to authorize for token expenditure.
     * @param amount The number of tokens `spender` is allowed to spend.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "MEETVERS:_approve:OWNER_ZERO: Cannot approve for the zero address.");
        require(spender != address(0), "MEETVERS:_approve:SPENDER_ZERO: Cannot approve to the zero address.");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Withdraw any tokens or MATIC stuck in the treasury handler.
     * @param tokenAddress Address of the token to withdraw. If set to the zero address, MATIC will be withdrawn.
     * @param amount The number of tokens to withdraw.
     */
    function withdraw(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transferFrom(address(this), _msgSender(), amount);
    }

    function setPrimaryPoolTokenAddress(address _primaryPoolTokenAddress) external onlyOwner {
        primaryPoolTokenAddress = _primaryPoolTokenAddress;
    }

    /**
     * @notice Transfer `amount` tokens from account `from` to account `to`.
     * @param from Address the tokens are moved out of.
     * @param to Address the tokens are moved to.
     * @param amount The number of tokens to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "MEETVERSE:_transfer:FROM_ZERO: Cannot transfer from the zero address.");
        require(to != address(0), "MEETVERSE:_transfer:TO_ZERO: Cannot transfer to the zero address.");
        require(amount > 0, "MEETVERSE:_transfer:ZERO_AMOUNT: Transfer amount must be greater than zero.");
        require(amount <= _balances[from], "MEETVERSE:_transfer:INSUFFICIENT_BALANCE: Transfer amount exceeds balance.");

        treasuryHandler.beforeTransferHandler(from, to, amount);

        uint256 tax = taxHandler.getTax(from, to, amount);
        uint256 taxedAmount = amount - tax;
        _balances[from] -= amount;
        _balances[to] += taxedAmount;
        emit Transfer(from, to, taxedAmount);

        if (tax > 0) {
            _balances[address(treasuryHandler)] += tax;
            emit Transfer(from, address(treasuryHandler), tax);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Treasury handler interface
 * @dev Any class that implements this interface can be used for protocol-specific operations pertaining to the treasury.
 */
interface ITreasuryHandler {
    /**
     * @notice Perform operations before a transfer is executed.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function beforeTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external;

    /**
     * @notice Perform operations after a transfer is executed.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function afterTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Tax handler interface
 * @dev Any class that implements this interface can be used for protocol-specific tax calculations.
 */
interface ITaxHandler {
    /**
     * @notice Get number of tokens to pay as tax.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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