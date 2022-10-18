/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: GNU GENERAL PUBLIC LICENSE V3

// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
contract ERC20 is Context, IERC20, IERC20Metadata,Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _maxTotalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxTotalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _maxTotalSupply = maxTotalSupply_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        require(
            _totalSupply <= _maxTotalSupply,
            "ERC20: minting amount exceeds max total supply"
        );
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.7.0 <0.9.0;

contract Decentrawood is ERC20 {
    using SafeMath for uint256;

    uint256 public allotmentCount;
    uint256 public maxTotalSupply = 2000000000 * 10**18;
    uint256 public maxAllotmentByAdmin = maxTotalSupply.mul(10).div(100);
    uint256 public totalAllotmentByAdmin;
    uint256 public maxAllotmentByMarketingTeam = maxTotalSupply.mul(10).div(100);
    uint256 public totalAllotmentByMarketingTeam;
    uint256 public maxAllotmentByDevelopmentTeam = maxTotalSupply.mul(10).div(100);
    uint256 public totalAllotmentByDevelopmentTeam;
    uint256 public maxAllotmentByStrategicAllianceTeam = maxTotalSupply.mul(10).div(100);
    uint256 public totalAllotmentByStrategicAllianceTeam;
    uint256 public maxPublicSupply = maxTotalSupply.mul(55).div(100);
    uint256 public totalAllotmentToPublic;
    uint256 public airdropTokenAmount = maxTotalSupply.mul(1).div(100); 
    uint256 public liquidityTokenAmount = maxTotalSupply.mul(4).div(100); 

    uint256 public totalTokensAllotedTillDate;
    uint256 public currentMillion;
    uint256 public rate;

    address public constant admin = 0x65c0cb0E58D0a45D294Bc0D1C37ee8C714E1372D;
    address public constant marketingTeamAddress = 0xde5222980234799300DD7f6D324E10435D1bD692;
    address public constant developmentTeamAddress = 0xF9dAF9cC3835b78591f09b22FDC6F552D9aE6E76;
    address public constant strategicAllianceTeamAddress = 0xd4E7371E22F1DdEca24b797473F6CBCfB0CA4BB0;
    address public constant airdropWalletAddress = 0x4A8CA6F4e245a3573A88Fbe5925F445BC1724419;
    address public constant liquidityWalletAddress = 0xcF6418116002B1e5681Cd3279aAB579E53742910;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256[] public REFERRAL_PERCENTS = [100, 20, 20, 20, 20, 20];
    uint256 public constant PERCENTS_DIVIDER = 1000; 
    uint256 public totalPendingReferalWithdrawalAmount;

    IERC20 USDT = IERC20(0xd64cb49E1DBFcCE67ba6Cd528083d2522aFB1B8B);

    struct Allotment {
        uint256 allotmentID;
        address referedTo;
        address userAddress;
        uint256 startTime;
        uint256 tokenAlloted;
    }

    struct Referal {
        uint256[] referalIds;
        address referrer;
        uint256[6] levels;
        uint256 amount;
    }

    mapping(address => Referal) internal referals;
    mapping(address => uint256[]) public userReferalIds;
    mapping(address => uint256) public userReferalCount;
    mapping(uint256 => Allotment) public allotments;
    mapping(address => uint256) public userAllotmentCount;
    mapping(address => uint256[]) public userAllotmentIds;
    mapping(address => uint256) public totalTokensPurchased;
    mapping(address => uint256) public userMintedBalance;

    modifier onlyAdmin() {
        require(admin == msg.sender, "ONLY_ADMIN_CAN_EXECUTE_THIS_FUNCTION");
        _;
    }

    modifier onlyMarketingTeam() {
        require(
            marketingTeamAddress == msg.sender,
            "ONLY_MARKETING_TEAM_CAN_EXECUTE_THIS_FUNCTION"
        );
        _;
    }

    modifier onlyDevelopmentTeam() {
        require(
            developmentTeamAddress == msg.sender,
            "ONLY_DEVELOPMENT_TEAM_CAN_EXECUTE_THIS_FUNCTION"
        );
        _;
    }

    modifier onlyStrategicAllianceTeam() {
        require(
            strategicAllianceTeamAddress == msg.sender,
            "ONLY_STRATEGIC_ALLIANCE_TEAM_CAN_EXECUTE_THIS_FUNCTION"
        );
        _;
    }

    constructor() ERC20("Decentrawood", "Deod", maxTotalSupply) {
        _mint(airdropWalletAddress, airdropTokenAmount);
        _mint(liquidityWalletAddress, liquidityTokenAmount);
        rate = 400; 
    }

    // Function for admin to allot tokens to certain address
    function allotmentByAdmin(address _address, uint256 _amount)
        public
        onlyAdmin
    {
        totalAllotmentByAdmin = totalAllotmentByAdmin.add(_amount);
        require(totalAllotmentByAdmin <= maxAllotmentByAdmin,"MAX_ADMIN_ALLOTMENT_REACHED");
        allotmentCount = allotmentCount + 1;
        Allotment memory alt = Allotment(allotmentCount, deadAddress, _address, block.timestamp, _amount
        );
        allotments[allotmentCount] = alt;
        totalTokensPurchased[_address] = totalTokensPurchased[_address].add(_amount);
        userAllotmentIds[_address].push(allotmentCount);
        
    }

    // Function for marketing team to allot tokens to certain address
    function allotmentByMarketingTeam(address _address, uint256 _amount)
        public
        onlyMarketingTeam
    {
        totalAllotmentByMarketingTeam = totalAllotmentByMarketingTeam.add(_amount);
        require(totalAllotmentByMarketingTeam <= maxAllotmentByMarketingTeam,"MAX_MARKETING_TEAM_ALLOTMENT_REACHED");
        allotmentCount = allotmentCount + 1;
        Allotment memory alt = Allotment(allotmentCount,deadAddress,_address,block.timestamp,_amount);
        allotments[allotmentCount] = alt;
        totalTokensPurchased[_address] = totalTokensPurchased[_address].add(_amount);
        userAllotmentIds[_address].push(allotmentCount);
    }

    // Function for development team to allot tokens to certain address
    function allotmentByDevelopmentTeam(address _address, uint256 _amount)
        public
        onlyDevelopmentTeam
    {
        totalAllotmentByDevelopmentTeam = totalAllotmentByDevelopmentTeam.add(_amount);
        require(totalAllotmentByDevelopmentTeam <= maxAllotmentByDevelopmentTeam,"MAX_DEVELOPMENT_TEAM_ALLOTMENT_REACHED");
        allotmentCount = allotmentCount + 1;
        Allotment memory alt = Allotment(allotmentCount,deadAddress,_address,block.timestamp,_amount);
        allotments[allotmentCount] = alt;
        totalTokensPurchased[_address] = totalTokensPurchased[_address].add(_amount);
        userAllotmentIds[_address].push(allotmentCount);
    }

    // Function for Strategic Alliance Team to allot tokens to certain address
    function allotmentByStrategicAllianceTeam(address _address, uint256 _amount)
        public
        onlyStrategicAllianceTeam
    {
        totalAllotmentByStrategicAllianceTeam = totalAllotmentByStrategicAllianceTeam.add(_amount);
        require(totalAllotmentByStrategicAllianceTeam <=maxAllotmentByStrategicAllianceTeam,
            "MAX_STRATEGIC_ALLIANCE_TEAM_ALLOTMENT_REACHED");
        allotmentCount = allotmentCount + 1;
        Allotment memory alt = Allotment(allotmentCount,deadAddress,_address,block.timestamp,_amount);
        allotments[allotmentCount] = alt;
        totalTokensPurchased[_address] = totalTokensPurchased[_address].add(_amount);
        userAllotmentIds[_address].push(allotmentCount);
    }

    function getTokenAllotment(
        address _address,
        address _referedTo,
        uint256 _amount
    ) internal {
        totalAllotmentToPublic = totalAllotmentToPublic.add(_amount);
        require(
            totalAllotmentToPublic <= maxPublicSupply,
            "MAX_PUBLIC_SUPPLY_REACHED"
        );
        allotmentCount = allotmentCount + 1;
        Allotment memory alt = Allotment(
            allotmentCount,
            _referedTo,
            _address,
            block.timestamp,
            _amount
        );
        allotments[allotmentCount] = alt;
        totalTokensPurchased[_address] = totalTokensPurchased[_address].add(
            _amount
        );
        userAllotmentIds[_address].push(allotmentCount);
        userAllotmentCount[_address] = userAllotmentCount[_address] + 1;
        totalTokensAllotedTillDate = totalTokensAllotedTillDate.add(_amount);
    }

    function buyToken(uint256 _amount, address referrer) public {
        uint256 halfUSDT = _amount.mul(50).div(100);

        USDT.transferFrom(msg.sender, liquidityWalletAddress, halfUSDT);
        USDT.transferFrom(msg.sender, admin, halfUSDT);

        uint256 tokenAmount = _amount.mul(rate) * 10**12;

        getTokenAllotment(msg.sender, deadAddress, tokenAmount);

        Referal storage ref = referals[msg.sender];

        if (ref.referrer == address(0)) {
            if (
                referals[referrer].referalIds.length > 0 &&
                referrer != msg.sender
            ) {
                ref.referrer = referrer;
            }

            address upline = ref.referrer;
            for (uint256 i = 0; i < 6; i++) {
                if (upline != address(0)) {
                    referals[upline].levels[i] = referals[upline].levels[i].add(
                        1
                    );
                    upline = referals[upline].referrer;
                } else break;
            }
        }

        if (ref.referrer != address(0)) {
            address upline = ref.referrer;
            for (uint256 i = 0; i < 6; i++) {
                if (upline != address(0)) {
                    uint256 amount = tokenAmount.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    getTokenAllotment(upline, msg.sender, amount);
                    userReferalCount[upline] = userReferalCount[upline] + 1;
                    userReferalIds[upline].push(allotmentCount);
                    upline = referals[upline].referrer;
                } else break;
            }
        }

        ref.referalIds.push(allotmentCount);
        uint256 newCurrentMillion = totalTokensAllotedTillDate.div(
            1000000 * 10**18
        );
        uint256 millionDifference = newCurrentMillion.sub(currentMillion);

        // Increment Price
        if (millionDifference >= 1) {
            rate = rate.sub(rate.mul(millionDifference).div(100));
            currentMillion = newCurrentMillion;
        }
    }

    // Function to get tokens available for minting for given address
    function tokensAvaliableForMinting(address _address)
        public
        view
        returns (uint256)
    {
        uint256 balance = 0;
        // require(userAllotmentIds[_address].length == 0, "length equal to zero");
        for (uint256 i = 0; i < userAllotmentIds[_address].length; i++) {
            uint256 numberOfDays = (
                block.timestamp.sub(
                    allotments[userAllotmentIds[_address][i]].startTime
                )
            ).div(1 minutes);
            if (numberOfDays <= 365) {
                // 1st Year
                uint256 firstYearAllotment = (
                    allotments[userAllotmentIds[_address][i]].tokenAlloted
                ).mul(40).div(100);
                uint256 oneDayAllotment = firstYearAllotment.div(365);
                balance = balance + numberOfDays.mul(oneDayAllotment);
            } else if (numberOfDays > 365 && numberOfDays <= 730) {
                // 2nd Year
                uint256 firstYearAllotment = (
                    allotments[userAllotmentIds[_address][i]].tokenAlloted
                ).mul(40).div(100);
                uint256 secondYearAllotment = (
                    allotments[userAllotmentIds[_address][i]].tokenAlloted
                ).mul(30).div(100);
                uint256 oneDayAllotment = secondYearAllotment.div(365);
                balance =
                    balance +
                    firstYearAllotment.add(
                        numberOfDays.sub(365).mul(oneDayAllotment)
                    );
            } else if (numberOfDays > 730 && numberOfDays <= 1095) {
                // 3rd Year
                uint256 firstYearAllotment = (
                    allotments[userAllotmentIds[_address][i]].tokenAlloted
                ).mul(40).div(100);
                uint256 secondYearAllotment = (
                    allotments[userAllotmentIds[_address][i]].tokenAlloted
                ).mul(30).div(100);
                uint256 thirdYearAllotment = (
                    allotments[userAllotmentIds[_address][i]].tokenAlloted
                ).mul(30).div(100);
                uint256 oneDayAllotment = thirdYearAllotment.div(365);
                balance =
                    balance +
                    firstYearAllotment.add(secondYearAllotment).add(
                        numberOfDays.sub(730).mul(oneDayAllotment)
                    );
            } else {
                balance =
                    balance +
                    allotments[userAllotmentIds[_address][i]].tokenAlloted;
            }
        }

        return balance.sub(userMintedBalance[_address]);
    }

    // Function for users to claim the alloted tokens
    function claimTokens() public {
        _mint(msg.sender, tokensAvaliableForMinting(msg.sender));
        userMintedBalance[msg.sender] = userMintedBalance[msg.sender] + tokensAvaliableForMinting(msg.sender);
    }
}