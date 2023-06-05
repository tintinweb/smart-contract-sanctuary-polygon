/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: finalERC20.sol


pragma solidity ^0.8.0;




interface RewardContract {
    function updateBalances() external;
}

contract ProjectX is ERC20, Ownable {
    using SafeMath for uint256;
    RewardContract private myRewardContract;
    address private _stakingAddress = 0x1111111111111111111111111111111111111111; 
    address private _charityAddress = 0x2222222222222222222222222222222222222222; 
    address private _managementAddress = 0x3333333333333333333333333333333333333333; 
    address private _liquidityAddress = 0x4444444444444444444444444444444444444444; 
    address private _burnAddress = 0x0000000000000000000000000000000000000000;
    uint256 private _stakingPoolFee = 50;
    uint256 private _charityFundFee = 5;
    uint256 private _tokenBurnFee = 5;
    uint256 private _managementFee = 100;
    uint256 private _liquidityPoolFee = 20;

    mapping(address => bool) private isExemptFromFees;
    uint256 private constant maxSupply = 10000000000000000;
    mapping(address => bool) private isHolder;
    uint256 private holdersList;
    uint256 private tokenBurned;

    // Events
    event TransferWithFees(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 totalTaxAmount
    );
    event TokenMinted(address indexed sender, uint256 amount);
    event TokenBurned(address indexed sender, uint256 amount);
    event Approved(
        address indexed sender,
        address indexed spender,
        uint256 amount
    );
    event EthRescued(address indexed sender, uint256 amount);
    event IERC20Rescued(address indexed sender, uint256 amount);

    constructor() ERC20("Project", "X") {
    }

    // // Token decimals
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function getRewardContract() external view returns(RewardContract){
        return myRewardContract;
    }
    
    // To mint
    function mint(uint256 amount) external onlyOwner {
        require(amount > 0, "mint: Amount can't be zero");
        require(
            totalSupply() + amount <= getMaxSupply(),
            "mint: Total supply exceeds maximum supply"
        );
        _mint(_msgSender(), amount);

        // To add or remove holder
        if (balanceOf(_msgSender()) == 0 && isHolder[_msgSender()]) {
            isHolder[_msgSender()] = false;
            holdersList--;
        } else if (balanceOf(_msgSender()) > 0 && !isHolder[_msgSender()]) {
            isHolder[_msgSender()] = true;
            holdersList++;
        }
        emit TokenMinted(_msgSender(), amount);
    }

    // Update RewardContract
    function UpdateRewardContract(
        address newRewardContract
    ) external onlyOwner {
        myRewardContract = RewardContract(newRewardContract);
    }

    // Internal function of RewardContract
    function updateBalances() internal {
        return myRewardContract.updateBalances();
    }

    // To burn token from any users
    function burn(uint256 amount) external {
        require(amount > 0, "burn:Amount must be greater than zero.");
        require(balanceOf(msg.sender) >= amount, "burn:Insufficient balance.");
         _burn(_msgSender(), amount);
        emit TokenBurned(msg.sender, amount);
    }

    // View total holders
    function totalHolder() public view returns (uint256) {
        return holdersList;
    }

    // View max total supply
    function getMaxSupply() public pure returns (uint256) {
        return maxSupply;
    }

    // To view totalburned
    function totalBurned() public view returns (uint256) {
        return tokenBurned;
    }

    // Set Fee exemption
    function setExemptFromFees(
        address exemptAddress,
        bool exemptStatus
    ) public onlyOwner {
        isExemptFromFees[exemptAddress] = exemptStatus;
    }

    // To approve spending of tokens
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        require(
            balanceOf(_msgSender()) >= amount,
            "approve:Insufficient balance."
        );
        require(amount > 0, "approve: zero approval not allowed.");
        _approve(owner, spender, amount);
        emit Approved(owner, spender, amount);
        return true;
    }

    // Controller to transfer from the msg.sender()
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(amount > 0, "transfer: Zero transfer not allowed.");
        require(
            balanceOf(_msgSender()) >= amount,
            "transfer:Insufficient balance."
        );
        uint256 totalTaxAmount = amount
            .mul(
                _stakingPoolFee
                    .add(_charityFundFee)
                    .add(_managementFee)
                    .add(_liquidityPoolFee)
                    .add(_tokenBurnFee)
            )
            .div(10000); //default is div.100 for 100% rate
        uint256 amountAfterTax = amount.sub(totalTaxAmount);

        uint256 balance = balanceOf(_msgSender()).sub(amount);

        // To add or remove holder
        if (balanceOf(_msgSender()) == 0 && isHolder[_msgSender()]) {
            isHolder[_msgSender()] = false;
            holdersList--;
        } else if (balanceOf(_msgSender()) > 0 && !isHolder[_msgSender()]) {
            isHolder[_msgSender()] = true;
            holdersList++;
        }
        // To add or remove holder
        if (balanceOf(recipient) > 0 && !isHolder[recipient]) {
            isHolder[recipient] = true;
            holdersList++;
        } else if (balanceOf(recipient) == 0 && isHolder[recipient]) {
            isHolder[recipient] = false;
            holdersList--;
        }

        // Check if the sender is exempt from transfer fees
        if (isExemptFromFees[_msgSender()]) {
            amountAfterTax = amount;
            totalTaxAmount = 0;
        }

        // Make sure the sender has enough tokens
        require(
            balanceOf(_msgSender()) >= amount,
            "transfer: Not enough tokens to transfer"
        );

        // Make sure the calle is not the zero address
        require(
            msg.sender != address(0),
            "transfer: transfer from the zero address"
        );

        if (amountAfterTax > 0) {
            // Make sure the transfer amount is not zero
            _transfer(_msgSender(), recipient, amountAfterTax);
            balance = balanceOf(recipient).add(amountAfterTax);
        }

        if (totalTaxAmount > 0) {
            // Calculate the tax amounts for each recipient based on their percentage
            uint256 stakingTax = totalTaxAmount.mul(_stakingPoolFee).div(
                _stakingPoolFee
                    .add(_charityFundFee)
                    .add(_managementFee)
                    .add(_liquidityPoolFee)
                    .add(_tokenBurnFee)
            );
            uint256 charityTax = totalTaxAmount.mul(_charityFundFee).div(
                _stakingPoolFee
                    .add(_charityFundFee)
                    .add(_managementFee)
                    .add(_liquidityPoolFee)
                    .add(_tokenBurnFee)
            );
            uint256 managementTax = totalTaxAmount.mul(_managementFee).div(
                _stakingPoolFee
                    .add(_charityFundFee)
                    .add(_managementFee)
                    .add(_liquidityPoolFee)
                    .add(_tokenBurnFee)
            );
            uint256 liquidityTax = totalTaxAmount.mul(_liquidityPoolFee).div(
                _stakingPoolFee
                    .add(_charityFundFee)
                    .add(_managementFee)
                    .add(_liquidityPoolFee)
                    .add(_tokenBurnFee)
            );
            uint256 tokenBurnTax = totalTaxAmount.mul(_tokenBurnFee).div(
                _stakingPoolFee
                    .add(_charityFundFee)
                    .add(_managementFee)
                    .add(_liquidityPoolFee)
                    .add(_tokenBurnFee)
            );

            balance = balanceOf(_msgSender()).sub(totalTaxAmount);

            // Transfer the tax amounts to the tax recipients
            if (stakingTax > 0) {
                _transfer(_msgSender(), _stakingAddress, stakingTax);
                balance = balanceOf(_stakingAddress).add(stakingTax);
                updateBalances();
                if (
                    balanceOf(_stakingAddress) > 0 && !isHolder[_stakingAddress]
                ) {
                    isHolder[_stakingAddress] = true;
                    holdersList++;
                } else if (
                    balanceOf(_stakingAddress) == 0 && isHolder[_stakingAddress]
                ) {
                    isHolder[_stakingAddress] = false;
                    holdersList--;
                }
            }

            if (charityTax > 0) {
                _transfer(_msgSender(), _charityAddress, charityTax);
                balance = balanceOf(_charityAddress).add(charityTax);
                if (
                    balanceOf(_charityAddress) > 0 && !isHolder[_charityAddress]
                ) {
                    isHolder[_charityAddress] = true;
                    holdersList++;
                } else if (
                    balanceOf(_charityAddress) == 0 && isHolder[_charityAddress]
                ) {
                    isHolder[_charityAddress] = false;
                    holdersList--;
                }
            }

            if (managementTax > 0) {
                _transfer(_msgSender(), _managementAddress, managementTax);
                balance = balanceOf(_managementAddress).add(managementTax);
                if (
                    balanceOf(_managementAddress) > 0 &&
                    !isHolder[_managementAddress]
                ) {
                    isHolder[_managementAddress] = true;
                    holdersList++;
                } else if (
                    balanceOf(_managementAddress) == 0 &&
                    isHolder[_managementAddress]
                ) {
                    isHolder[_managementAddress] = false;
                    holdersList--;
                }
            }

            if (liquidityTax > 0) {
                _transfer(_msgSender(), _liquidityAddress, liquidityTax);
                balance = balanceOf(_liquidityAddress).add(liquidityTax);
                if (
                    balanceOf(_liquidityAddress) > 0 &&
                    !isHolder[_liquidityAddress]
                ) {
                    isHolder[_liquidityAddress] = true;
                    holdersList++;
                } else if (
                    balanceOf(_liquidityAddress) == 0 &&
                    isHolder[_liquidityAddress]
                ) {
                    isHolder[_liquidityAddress] = false;
                    holdersList--;
                }
            }

            if (tokenBurnTax > 0) {
                _burn(_msgSender(), tokenBurnTax);
                balance = balanceOf(_burnAddress).add(tokenBurnTax);
                tokenBurned += tokenBurnTax;
                emit TokenBurned(_msgSender(), tokenBurnTax);
            }
        }
        // Emit a TransferWithTax event
        emit TransferWithFees(
            _msgSender(),
            recipient,
            amountAfterTax,
            totalTaxAmount
        );
        return true;
    }
    
    function transferFrom(
    address sender,
    address recipient,
    uint256 amount
) public virtual override returns (bool) {
    require(amount > 0, "transferFrom: zero transfer not allowed.");
    require(
        balanceOf(_msgSender()) >= amount,
        "transferFrom: Insufficient balance."
    );
    
    address spender = _msgSender();
    _spendAllowance(sender, spender, amount);
    transfer(recipient, amount);
    
    return true; 
}

    function setStakingAddress(address newStakingAddress) external onlyOwner {
        _stakingAddress = newStakingAddress;
    }

    function setCharityAddress(address newCharityAddress) external onlyOwner {
        _charityAddress = newCharityAddress;
    }

    function setManagementAddress(
        address newManagementAddress
    ) external onlyOwner {
        _managementAddress = newManagementAddress;
    }

    function setLiquidityAddress(
        address newLiquidityAddress
    ) external onlyOwner {
        _liquidityAddress = newLiquidityAddress;
    }

    function setBurnAddress(address newBurnAddress) external onlyOwner {
        _burnAddress = newBurnAddress;
    }

    function stakingAddress() public view returns (address) {
        return _stakingAddress;
    }

    function charityAddress() public view returns (address) {
        return _charityAddress;
    }

    function managementAddress() public view returns (address) {
        return _managementAddress;
    }

    function liquidityAddress() public view returns (address) {
        return _liquidityAddress;
    }

    function burnAddress() public view returns (address) {
        return _burnAddress;
    }

    function stakingPoolFee() public view returns (uint256) {
        return _stakingPoolFee;
    }

    function charityFundFee() public view returns (uint256) {
        return _charityFundFee;
    }

    function managementFee() public view returns (uint256) {
        return _managementFee;
    }

    function liquidityPoolFee() public view returns (uint256) {
        return _liquidityPoolFee;
    }

    function tokenBurnFee() public view returns (uint256) {
        return _tokenBurnFee;
    }

    function calculateFees(uint256 amount) public view returns (uint256) {
        uint256 totalTaxAmount = (
            amount.mul(
                _stakingPoolFee
                    .add(_charityFundFee)
                    .add(_managementFee)
                    .add(_liquidityPoolFee)
                    .add(_tokenBurnFee)
            )
        ).div(10000);
        return totalTaxAmount;
    }

    // To show total fee
    function totalFees() public view returns (uint256) {
        return (
            _stakingPoolFee
                .add(_charityFundFee)
                .add(_managementFee)
                .add(_liquidityPoolFee)
                .add(_tokenBurnFee)
        );
    }

    // Fallback function
    receive() external payable {}

    // To rescue eth
    function rescueEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero.");
        payable(owner()).transfer(balance);
        emit EthRescued(msg.sender, balance);
    }

    // To rescue any erc20 tokens
    function rescueERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint amount = token.balanceOf(address(this));
        require(amount > 0, "balance is zero");
        require(token.transfer(msg.sender, amount), "Token transfer failed.");
        emit IERC20Rescued(msg.sender, amount);
    }
}