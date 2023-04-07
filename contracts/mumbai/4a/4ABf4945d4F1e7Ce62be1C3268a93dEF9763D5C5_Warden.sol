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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// Specify the version of Solidity to use
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the Ownable contract from the OpenZeppelin library
import "@openzeppelin/contracts/access/Ownable.sol";

// Import the EpisapientToken contract
import "./EpisapientToken.sol";

// Define the Community contract which inherits from the Ownable contract
contract Community is Ownable {
    // Declare a variable to store the EpisapientToken contract
    EpisapientToken token;

    // Declare a counter for the community category IDs
    uint256 public categoryIdCounter = 0;

    // Declare a counter for the number of communities added
    uint8 public addcommunityCounter = 0;

    // Declare a counter for the membership IDs
    uint256 public membershipCounter = 0;

    // Define a struct for storing information about a community
    struct Communities {
        address ContractAddress;
        uint256 categoryId;
        uint256 id;
        address[] membersAddress;
        address[] wardenAddress;
    }

    // Define a struct for storing information about a category
    struct Category {
        string name;
        uint256 id;
    }

    // Define a struct for storing information about a member
    struct Member {
        address communityAddress;
        address walletAddress;
        uint256 id;
    }

    // Declare a mapping to store details about each category
    mapping(uint256 => Category) public categoryDetails;

    // Declare a mapping to store details about each community
    mapping(address => Communities) public communityDetails;

    // Declare a mapping to store details about each member
    mapping(address => Member) public memberDetails;

    // Declare an array to store the addresses of all communities
    address[] public communityList;

    // Declare an array to store the IDs of all categories
    uint256[] public categoryList;

    // Declare an array to store the addresses of all members
    address[] public membersList;

    // Define a constructor function for the Community contract
    constructor(address tokenAddress) {
        // Set the token variable to the EpisapientToken contract
        token = EpisapientToken(tokenAddress);
    }

    // Define a modifier to allow only the owner or a warden of a community to call a function
    modifier onlyOwnerAndWarden(
        address contractAddress,
        address wardenAddress
    ) {
        require(
            msg.sender == owner() || isWarden(contractAddress, msg.sender),
            "only owner and wadern can call"
        );
        _;
    }

    // Define a function to add a new community
    function addCommunity(address ContractAddress, uint256 categoryId) public {
        // Check if the specified category ID exists
        require(categoryId < categoryIdCounter, "Category not Exist");
        // Declare empty arrays for members and wardens
        address[] memory arr;
        address[] memory arr1;
        // Create a new Communities struct with the specified values
        Communities memory newCommunities = Communities(
            ContractAddress,
            categoryId,
            addcommunityCounter,
            arr,
            arr1
        );
        // Add the new community to the communityDetails mapping
        communityDetails[ContractAddress] = newCommunities;
        // Add the new community to the communityList array
        communityList.push(ContractAddress);
        // Increment the addcommunityCounter
        addcommunityCounter++;
    }

    // Adds a new category with the provided name
    function addCategorie(string memory name) public onlyOwner {
        // Create a new Category object with the provided name and categoryIdCounter
        Category memory newCategory = Category(name, categoryIdCounter);
        // Add the new category object to the categoryDetails mapping with categoryIdCounter as the key
        categoryDetails[categoryIdCounter] = newCategory;
        // Add the categoryIdCounter to the end of the categoryList array
        categoryList.push(categoryIdCounter);
        // Increment the categoryIdCounter for the next category to be added
        categoryIdCounter++;
    }

    // Removes a category with the provided categoryId
    function removeCategoryByID(uint256 categoryId) public onlyOwner {
        // Check if the categoryId exists in the categoryList array
        require(
            categoryId <= categoryList.length,
            "This Category does not Exist"
        );
        // Overwrite the category to be removed with the last category in the list
        categoryList[categoryId] = categoryList[categoryList.length - 1];
        // Remove the last element in the categoryList array
        categoryList.pop();
    }

    // Returns an array of all Category objects in the categoryList array
    function getCategoryList() public view returns (Category[] memory) {
        // Create a new array of Category objects with a length of categoryList
        Category[] memory result = new Category[](categoryList.length);
        // Iterate over the categoryList array and add the corresponding Category object from categoryDetails to the result array
        for (uint256 i = 0; i < categoryList.length; i++) {
            result[i] = categoryDetails[categoryList[i]];
        }
        // Return the result array of Category objects
        return result;
    }

    // Adds a new member to a community
    function addMember(address communityAddress, address walletAddress)
        public
        payable
    {
        // Get the community details from the communityDetails mapping
        Communities storage community = communityDetails[communityAddress];
        // Check if the community exists
        require(community.ContractAddress != address(0), "Community not found");
        // Check if the member already exists

        if (memberDetails[walletAddress].communityAddress == address(0)) {
            uint256 platformFee = token.getPlatformFee("Register");
            address platformAddress = token.getPlatformAddress();
            // Transfer the platform fee to the platform address
            if (platformFee > 0) {
                token.TokenTransfer(platformAddress, platformFee);
            }
            // Add the walletAddress to the membersAddress array in the community
            community.membersAddress.push(walletAddress);
            // Create a new Member object with the communityAddress, walletAddress, and membershipCounter
            Member memory newmember = Member(
                communityAddress,
                walletAddress,
                membershipCounter
            );
            // Add the new Member object to the memberDetails mapping with the walletAddress as the key
            memberDetails[walletAddress] = newmember;
            // Add the walletAddress to the end of the membersList array
            membersList.push(walletAddress);
            // Increment the membershipCounter for the next member to be added
            membershipCounter++;
        }
        // Get the platform fee and address for the registration
    }

    // This function returns an array of all members in the contract
    function getMemberList() public view returns (Member[] memory) {
        // Create a new array to store member details
        Member[] memory result = new Member[](membersList.length);

        // Loop through each member and add their details to the result array
        for (uint256 i = 0; i < membersList.length; i++) {
            result[i] = memberDetails[membersList[i]];
        }

        // Return the result array
        return result;
    }

    // This function returns platform fee and balance details for a given account
    function read(address acc)
        public
        view
        returns (
            uint256 _platformFee,
            address _PlatformFeeAddress,
            uint256 balance
        )
    {
        // Get the platform fee and platform address from the token contract
        _platformFee = token.getPlatformFee("Register");
        _PlatformFeeAddress = token.getPlatformAddress();

        // Get the account balance from the token contract
        balance = token.balanceOf(acc);
    }

    // This function sends tokens to a given address
    function sendfees(address to, uint256 amount) public {
        // Call the token contract to transfer tokens to the given address
        token.TokenTransfer(to, amount);
    }

    // This function removes a member from a given community contract by their wallet address
    function removeMemberByWalletAddress(
        address contractAddress,
        address walletAddress
    ) public onlyOwnerAndWarden(contractAddress, walletAddress) {
        // Get the array of members of the community from the contract storage
        address[] storage arr = communityDetails[contractAddress]
            .membersAddress;
        // Loop through the array to find the member with the given wallet address
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == walletAddress) {
                // If found, shift all elements to the left to remove the member from the array
                for (uint256 j = i; j < arr.length - 1; j++) {
                    arr[j] = arr[j + 1];
                }
                // Remove the last element of the array (which is now a duplicate) and update the storage
                arr.pop();
                // Return true to indicate that the member was successfully removed
            }
        }
        // Return false to indicate that the member was not found
    }

    // This function adds a warden to a given community contract
    function addWarden(address _contract, address _address) public {
        // Get the array of wardens of the community from the contract storage
        address[] storage arr = communityDetails[_contract].wardenAddress;
        // Add the new warden to the array and update the storage
        arr.push(_address);
    }

    // This function removes a warden from a community
    function removeWarden(address _contract, address item)
        public
        returns (bool)
    {
        address[] storage arr = communityDetails[_contract].wardenAddress; // get the array of wardens of the community
        for (uint256 i = 0; i < arr.length; i++) {
            // loop through the array to find the warden
            if (arr[i] == item) {
                // if the warden is found
                for (uint256 j = i; j < arr.length - 1; j++) {
                    // shift the remaining elements to the left
                    arr[j] = arr[j + 1];
                }
                arr.pop(); // remove the last element of the array
                return true; // indicate that the warden was successfully removed
            }
        }
        return false;
    }

    // This function returns a list of all the members' addresses of a particular community specified by '_contractaddress'.
    function communityMembersList(address _contractaddress)
        public
        view
        returns (address[] memory)
    {
        return communityDetails[_contractaddress].membersAddress;
    }

    // This function returns a list of all the wardens' addresses of a particular community specified by '_contractaddress'.
    function communityWardenList(address _contractaddress)
        public
        view
        returns (address[] memory)
    {
        return communityDetails[_contractaddress].wardenAddress;
    }

    // This function checks whether the provided _wardenAddress is a warden of the community with the given _contractaddress or not.
    // It returns a boolean value: true if the address is a warden, false otherwise.
    function isWarden(address _contractaddress, address _wardenAddress)
        public
        view
        returns (bool)
    {
        // get the array of wardens of the community
        address[] storage arr = communityDetails[_contractaddress]
            .wardenAddress;
        // loop through the array to check if the given _wardenAddress is present or not
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == _wardenAddress) {
                return true; // if the address is found, return true
            }
        }
        return false; // if the address is not found, return false
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract EpisapientToken is ERC20, Ownable{
    
    ERC20 public usdc;
    uint256 public tokenPrice; // current token price in USDC
    address payable public PlatformFeeAddress; // address to which platform fees are sent
    uint256 public feeAmount; // current amount of platform fees in USDC
    // address public TreasuryPool = 0xafb924b42C7A1fBA26657569a290dBf05dE42F08; // address of TreasuryPool
    // address public SDAMPool = 0x4489D76D66112328b227FA7E77B835dA571bb993; // address of SDAMPool
    // address public CharityPool = 0x3DbBb9FE57138bD7D16B1FEb69D6d2EeB9e36f00; // address of CharityPool
    
    struct PlatformFee {
        string feeType; // type of platform fee
        uint256 amount; // amount of platform fee in USDC
    }

    struct Tokenomics{
        string Type; // type of tokenomics (e.g. "burn")
        uint256 Percentage; // percentage of total supply affected by tokenomics
    }

    mapping(string => PlatformFee) public platformfee; // mapping of platform fees by type
    mapping(string => Tokenomics) public tokenomics; // mapping of tokenomics by type

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender,4200000000*(10**18)); // mint initial supply to contract creator
        tokenPrice = 10**16; // set initial token price to 0.01 USDC
    }

    function setPeggedTokenAddress(address _usdcaddress) public onlyOwner {
        usdc = ERC20(_usdcaddress); // set address of the USDC token contract
    }

    function calculateUsdcperTokenAmount(uint256 usdcAmount) public view returns(uint256) {
        uint256 tokenAmount = usdcAmount * tokenPrice / 10**18; // calculate token amount from USDC amount
        return tokenAmount; // return token amount
    }
    
    function calculateTokenPerUsdcAmount(uint256 tokenAmount) public view returns(uint256) {
        uint256 usdcAmount = tokenAmount * 10**18 / tokenPrice; // calculate USDC amount from token amount
        return usdcAmount; // return USDC amount
    }

    // This function is used to set the address where platform fees will be sent to
    function setPlatformFeeAddress(address payable _PlatformFeeAddress) public onlyOwner {
        PlatformFeeAddress = _PlatformFeeAddress;
    }

    // This function is used to set the platform fees
    function setPlatformFee(string memory feeType, uint256 amount) public onlyOwner {
        // Ensure that the fee amount is not negative
        require(amount >= 0, "Fee amount cannot be negative");
        // Create a new PlatformFee struct with the specified feeType and amount
        PlatformFee memory newFee = PlatformFee(feeType, amount);
        // Set the fee for the specified feeType in the platformfee mapping
        platformfee[feeType] = newFee;
    }

   // This function is used to set the tokenomics (i.e., the distribution of tokens)
    function setTokenomics(string memory Type, uint256 percentage) public onlyOwner{
        // Ensure that the percentage is less than or equal to 100
        require(percentage <= 100, "Percentage is less than 100");
        // Calculate the amount of tokens to be allocated based on the percentage
        uint256 Amount = (totalSupply()*percentage)/100;
        // Create a new Tokenomics struct with the specified Type and Amount
        Tokenomics memory newTokenomics = Tokenomics(Type, Amount); 
        // Set the tokenomics for the specified Type in the tokenomics mapping
        tokenomics[Type] = newTokenomics;
    }


    function getPlatformFee(string memory feeType) public view returns (uint256) {
        PlatformFee memory fee = platformfee[feeType];
        return fee.amount;
    }
    

    function getPlatformAddress() public view returns(address){
        return PlatformFeeAddress;
    }

    function TokenTransfer(address to , uint256 amount) public{
        transfer(to,amount);
    }

    function burnToken(address to , uint256 amount)public {
        _burn(to,amount);
    }
}

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Community.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Warden {
    using SafeMath for uint256;

    EpisapientToken public token;
    Community community;

    address payable owner;
    uint256 public wardenCount;
    uint256 public wardensPerCommunityRate;
    uint256 public rewardsPerBlock;
    uint256 public minimumStakeAmount;

    constructor(address _community, address _token) {
        community = Community(_community);
        owner = payable(msg.sender);
        token = EpisapientToken(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not an owner");
        _;
    }

    function changeToken(address _token) public onlyOwner {
        token = EpisapientToken(_token);
    }

    struct WardenStructure {
        address wardenAddress;
        address[] activeInCategories;
        uint256 tokensStaked;
        uint256 stakingTime;
    }

    mapping(address => WardenStructure) public wardenDetails;

    mapping(uint256 => uint256) public currentWardenCount;

    //wardens per community memebers
    mapping(uint256 => uint256) public wardensPerCommunity;

    function stakeTokens(uint256 amount)
        internal
        returns (uint256 amountStaked)
    {
        require(amount >= minimumStakeAmount, "stake amount is not sufficient");
        require(
            amount <= token.allowance(msg.sender, address(this)),
            "Less Allowance"
        );
        token.transferFrom(msg.sender, address(this), amount);
        amountStaked = amount;
    }

    function unStakeTokens(address _address) internal {
        require(
            wardenDetails[_address].tokensStaked > 0,
            "You don't have any tokens staked yet"
        );
        token.transfer(msg.sender, wardenDetails[msg.sender].tokensStaked);
    }

    // setWardensPerThousandMember(int) : this will define number of wardens a community can have per 1K members
    function changeWardensPerCommunityRate(uint256 _wardensPerCommunityRate)
        public
        onlyOwner
    {
        wardensPerCommunityRate = _wardensPerCommunityRate;
    }

    // becomeWarden(stackAmount, categoryId) - Check if user is whitelisted, Check if currentWardenCount < memberCapacity
    function becomeWarden(address communityId, uint256 amount)
        public
        returns (uint256 _wardenCount)
    {
        //updates warden
        // updateWardens(communityId);

        address[] memory totalMembers = community.communityMembersList(
            communityId
        );
        address[] memory totalWardens = community.communityWardenList(
            communityId
        );

        if (totalWardens.length > 0) {
            uint256 Res = totalMembers.length / wardensPerCommunityRate;
            require(Res > totalWardens.length, "Warden Limit Exceeded");
        }

        require(
            wardenDetails[msg.sender].tokensStaked <= 0,
            "You already are a warden!"
        );
        uint256 amountStaked = stakeTokens(amount);
        require(amountStaked > 0, "Stake Some Tokens to become a Warden");

        wardenDetails[msg.sender].wardenAddress = msg.sender;
        wardenDetails[msg.sender].activeInCategories.push(communityId);
        wardenDetails[msg.sender].tokensStaked = amountStaked;
        wardenDetails[msg.sender].stakingTime = block.timestamp;

        community.addWarden(communityId, msg.sender);

        wardenCount++;
        _wardenCount = wardenCount;
    }

    // Remove the last element.
    function removeItem(address[] storage arr, address item)
        internal
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                for (uint256 j = i; j < arr.length - 1; j++) {
                    arr[j] = arr[j + 1];
                }
                arr.pop();
                return true;
            }
        }
        return false;
    }

    // removeWarden(walletAddress, categoryId) - Remove warden of particular category - Only Owner / Contract Only
    function removeWarden(address communityId, address wardenAddress)
        public
        returns (uint256 _wardenCount)
    {
        //updates warden
        // updateWardens(communityId);

        require(
            wardenDetails[wardenAddress].activeInCategories.length > 0,
            "It's Not a Warden"
        );

        unStakeTokens(wardenAddress);
        removeItem(
            wardenDetails[wardenAddress].activeInCategories,
            communityId
        );
        wardenDetails[wardenAddress].tokensStaked = 0;
        wardenDetails[wardenAddress].stakingTime = 0;

        community.removeWarden(communityId, wardenAddress);

        wardenCount--;
        _wardenCount = wardenCount;
    }

    // resign(categoryId) : will unstake the tokens and user will be removed from warden position
    function resign(address communityId) public returns (uint256 _wardenCount) {
        require(
            wardenDetails[msg.sender].activeInCategories.length > 0,
            "You're not an Warden"
        );

        //updates warden
        updateWardens(communityId);

        unStakeTokens(msg.sender);
        removeItem(wardenDetails[msg.sender].activeInCategories, communityId);
        wardenDetails[msg.sender].tokensStaked = 0;
        wardenDetails[msg.sender].stakingTime = 0;

        community.removeWarden(communityId, msg.sender);

        wardenCount--;
        _wardenCount = wardenCount;
    }

    // isWarden(walletAddress) : will check if user is warden
    function isWarden(address _address) public view returns (bool _isIt) {
        if (wardenDetails[_address].activeInCategories.length > 0) {
            _isIt = true;
        } else {
            _isIt = false;
        }
    }

    // setRewardPerBlock : Only Owner
    function setRewardPerBlock(uint256 newRewardsPerBlock) public onlyOwner {
        rewardsPerBlock = newRewardsPerBlock;
    }

    // setMiniumStakeAmount - Only Owner
    function setMiniumStakeAmount(uint256 newMinimumStakeAmount)
        public
        onlyOwner
    {
        minimumStakeAmount = newMinimumStakeAmount;
    }

    // updateWardens :  for all categories check if currentWardenCount > memberCapacity, then remove the last warden

    function updateWardens(address communityId) public returns (bool isValid) {
        address[] memory totalMembers = community.communityMembersList(
            communityId
        );
        address[] memory totalWardens = community.communityWardenList(
            communityId
        );

        uint256 wardenRate = wardensPerCommunityRate;

        if (totalWardens.length > 0) {
            // uint256 newWardenRate = totalMembers.div(totalWardens);
            uint256 newWardenRate = totalMembers.length / totalWardens.length;
            if (wardenRate > newWardenRate) {
                address[] memory arr = community.communityWardenList(communityId);
                uint256 noOfWardens = arr.length-1;
                address last = arr[noOfWardens];
                community.removeWarden(communityId, last);
                isValid = true;
            } else {
                isValid = false;
            }
        } else {
            isValid = false;
        }
        isValid;
    }

    function updateAllWardens(address communityId) public {
        address[] memory totalWardens = community.communityWardenList(communityId);

        for (uint256 i = 0; i <= totalWardens.length; i++) {
            updateWardens(communityId);
        }
    }

    function displayAll(address id)
        public
        view
        returns (address[] memory _data1, address[] memory _data2)
    {
        _data1 = community.communityWardenList(id);
        _data2 = community.communityMembersList(id);
    }
}