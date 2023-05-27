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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**

$$\   $$\ $$\ $$\                 $$\
$$$\  $$ |\__|$$ |                $$ |
$$$$\ $$ |$$\ $$ |  $$\  $$$$$$\  $$ |$$\   $$\  $$$$$$\
$$ $$\$$ |$$ |$$ | $$  |$$  __$$\ $$ |$$ |  $$ | \____$$\
$$ \$$$$ |$$ |$$$$$$  / $$ /  $$ |$$ |$$ |  $$ | $$$$$$$ |
$$ |\$$$ |$$ |$$  _$$<  $$ |  $$ |$$ |$$ |  $$ |$$  __$$ |
$$ | \$$ |$$ |$$ | \$$\ \$$$$$$  |$$ |\$$$$$$$ |\$$$$$$$ |
\__|  \__|\__|\__|  \__| \______/ \__| \____$$ | \_______|
                                      $$\   $$ |
                                      \$$$$$$  |
                                       \______/

**/
contract KolyaToken is ERC20, ERC20Burnable, Ownable {
    string[] private _friends = [
        "Pavel Naydanov",
        "Roman Yarlykov",
        "Aleksei Kutsenko"
    ];

    bytes private _congratulations =
        hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000002e0000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000003a000000000000000000000000000000000000000000000000000000000000003e0000000000000000000000000000000000000000000000000000000000000044000000000000000000000000000000000000000000000000000000000000004e0000000000000000000000000000000000000000000000000000000000000054000000000000000000000000000000000000000000000000000000000000005a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000068000000000000000000000000000000000000000000000000000000000000006e000000000000000000000000000000000000000000000000000000000000000272022426573742077697368657320616e64206120776f6e64657266756c204269727468646179220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222022596f752061726520616765696e67206c696b6520612066696e652077696e652200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000142022486176652061206772656174206f6e652122000000000000000000000000000000000000000000000000000000000000000000000000000000000000003820224d617920616c6c20796f757220647265616d7320636f6d6520747275652120486170707920426972746864617920746f20796f752122000000000000000000000000000000000000000000000000000000000000000000000000000000302022446f6e277420636f756e74207468652063616e646c65732e204a75737420656e6a6f792074686520676c6f77212200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001620224d616e792068617070792072657475726e7321220000000000000000000000000000000000000000000000000000000000000000000000000000000000282022426573742077697368657320616e64206120776f6e64657266756c2042697274686461792122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007820224c657420476f64206b6565707320796f7520617761792066726f6d206576696c20746f6e677565732c2073756464656e206d6973666f7274756e652c20636c6576657220656e656d69657320616e6420736d616c6c2d6d696e64656420667269656e64732120486170707920426972746864617921220000000000000000000000000000000000000000000000000000000000000000000000000000002d20225769736820796f7520616c6c207468652062657374206f6e20796f7572207370656369616c20646179212200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d2022436f6e67726174756c6174696f6e732120596f7520737572766976656420616e6f7468657220747269702061726f756e64207468652053756e2122000000000000000000000000000000000000000000000000000000000000000000003c202253656e64696e6720796f7520486170707920426972746864617920776973686573207772617070656420696e20616c6c206d79206c6f7665212200000000000000000000000000000000000000000000000000000000000000000000001b2022486170707920776f6d62206576696374696f6e2064617921220000000000000000000000000000000000000000000000000000000000000000000000000e2022486170707920323173742122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003520224d617920796f7572206461792062652066696c6c65642077697468206c6175676874657220616e642070726573656e74732122000000000000000000000000000000000000000000000000000000000000000000000000000000000000132022486170707920626565722064617921222000000000000000000000000000";

    bytes private _factsAboutKolya =
        hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002a00000000000000000000000000000000000000000000000000000000000000014496e636f7272656374206661637420696e646578000000000000000000000000000000000000000000000000000000000000000000000000000000000000004cd09ad0bed0bbd18f20d0bdd0b0d0b4d0b5d0b6d0bdd0b5d0b520d0bad0b0d0b7d0bdd0b0d187d0b5d0b9d181d0bad0b8d18520d0bed0b1d0bbd0b8d0b3d0b0d186d0b8d0b920d0a1d0a8d0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ad09ad0bed0bbd18f20d0b7d0bdd0b0d0b5d18220d182d0bed0bbd0ba20d0b220d0bfd0bbd0bed0b2d0b500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003cd09ad0bed0bbd18f20d0b4d0b5d0bbd0b0d0b5d18220d184d0bed182d0bed0bad0b0d180d182d0bed187d0bad0b820d0bbd183d187d188d0b520414900000000000000000000000000000000000000000000000000000000000000000000003ed0a320d09ad0bed0bbd0b820d187d0b5d180d0bdd18bd0b920d0bfd0bed18fd18120d0bfd0be20d0b7d0bdd0b0d0bdd0b8d18e20d0bcd0b5d0bcd0bed0b200000000000000000000000000000000000000000000000000000000000000000078d095d181d0bbd0b820d18320d0b2d0b0d18120d0b5d181d182d18c20d0b8d0b4d0b5d18f202d20d09ad0bed0bbd18f20d0b7d0bdd0b0d0b5d18220d0bad0b0d0ba20d180d0b5d0b0d0bbd0b8d0b7d0bed0b2d0b0d182d18c20d0b5d19120d0b2d181d0b5d0b3d0be20d0b7d0b0203220d187d0b0d181d0b00000000000000000";

    uint256 public birthTimestamp;

    constructor(address Kolya) ERC20("KolyaToken", "BNV") {
        birthTimestamp = _getUnixTimestampFromDate(1997, 5, 27);
        _mint(Kolya, 1_000_000e18);
        _transferOwnership(Kolya);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function getCongratulation() external view returns (string memory) {
        string[] memory congratulations = abi.decode(_congratulations, (string[]));
        uint256 index = _random(congratulations.length);
        return congratulations[index];
    }

    function getFriends() external view returns (string[] memory) {
        return _friends;
    }

    function getCongratulationYear() external pure returns (string memory) {
        return "2023";
    }

    function fiveFactsAboutKolya(uint256 factNumber) external view returns (string memory fact) {
        if (factNumber > 5) {
            return "Incorrect fact index";
        }
        string[] memory arr = abi.decode(_factsAboutKolya, (string[]));
        return arr[factNumber];
    }

    function getAgeOfKolya() external view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp >= birthTimestamp, "Invalid current year");

        uint256 age = (currentTimestamp - birthTimestamp) / (365 days);
        return age;
    }

    function _getUnixTimestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) private pure returns (uint256) {
        require(year >= 1970, "Invalid year");
        require(month >= 1 && month <= 12, "Invalid month");
        require(day >= 1 && day <= 31, "Invalid day");

        uint256 hour = 12;
        uint256 minute = 0;
        uint256 second = 0;

        uint256 unixTimestamp = 0;

        for (uint256 i = 1970; i < year; i++) {
            if (_isLeapYear(i)) {
                unixTimestamp += 366 days;
            } else {
                unixTimestamp += 365 days;
            }
        }

        uint8[12] memory daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        for (uint256 i = 1; i < month; i++) {
            if (i == 2 && _isLeapYear(year)) {
                unixTimestamp += 29 days;
            } else {
                unixTimestamp += daysInMonth[i - 1] * 1 days;
            }
        }

        unixTimestamp += (day - 1) * 1 days;

        unixTimestamp += hour * 1 hours;
        unixTimestamp += minute * 1 minutes;
        unixTimestamp += second;

        return unixTimestamp;
    }

    function _isLeapYear(uint256 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }

        if (year % 100 != 0) {
            return true;
        }

        if (year % 400 == 0) {
            return true;
        }

        return false;
    }

    function _random(uint256 randomCap) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp)));
        return random % randomCap;
    }
}