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

/**
 * SPDX-License-Identifier: MIT
 */
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

/**
 * @author Accubits
 * @title LINGO
 * @dev Implements a custom ERC20 token.
 */
contract LINGO is ERC20, ERC20Burnable, Ownable {
  /**
   * @title  WhiteList Types
   * @notice This enum specifies the types of whitelists available - external or internal.
   */
  enum WhiteListTypes {
    EXTERNAL_WHITELISTED,
    INTERNAL_WHITELISTED
  }

  /// This is an unsigned integer that represents the transfer fee percentage
  /// Eg: 5% will be represented as 500
  uint256 private _transferFee;

  /// This is an address variable that will hold the treasury wallet's address
  address private _treasuryWallet;

  /// This creates a mapping between external addresses and a boolean value indicating if they're whitelisted
  mapping(address => bool) private _isExternalWhiteListed;

  /// This creates a mapping between internal addresses and a boolean value indicating if they're whitelisted
  mapping(address => bool) private _isInternalWhiteListed;

  /// This is an array that stores all external white listed addresses
  address[] private _externalWhitelistedAddresses;

  /// This is an array that stores all internal white listed addresses
  address[] private _internalWhitelistedAddresses;

  /**
   * @dev Emitted when the Treasury wallet is updated
   * @param account The new account address that will be set as the treasury wallet
   */
  event TreasuryWalletUpdated(address account);

  /**
   * @dev Emitted when the whitelist is updated
   * @param whiteListType A variable of type `WhiteListTypes` indicating external or internal whitelists.
   * @param added The boolean value for whether an address has been added to the whitelisted addresses or removed..
   * @param members An array of addresses representing the members being added or removed from the list.
   */
  event WhiteListUpdated(WhiteListTypes whiteListType, bool added, address[] members);

  /**
   * @dev Event emitted when the transfer fee is updated
   * @param fee The updated transfer fee to be set as a uint256 value
   */
  event TransferFeeUpdated(uint256 fee);

  /**
   * @dev Constructor function to initialize values when the contract is created.
   * @param name_ A string representing the name of the token.
   * @param symbol_ A string representing the symbol of the token.
   * @param totalSupply_ An unsigned integer representing the initial total supply of tokens for the contract.
   * @param owner_ An address representing the owner of the contract.
   * @param treasuryAddress_ An address representing the treasury wallet address.
   * @param txnFee_ An unsigned integer representing the percentage transfer fee associated with each token transfer.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    address owner_,
    address treasuryAddress_,
    uint256 txnFee_
  ) ERC20(name_, symbol_) {
    /**
     * Here, we set the treasury wallet address to the specified value.
     * This address will be used to receive the transfer fee from every token transfer.
     */
    require(treasuryAddress_ != address(0), 'LINGO: Zero Address');
    _treasuryWallet = treasuryAddress_;

    /**
     * The total supply of tokens is calculated in the next line
     * by multiplying the specified value by 10 raised to the power of decimals.
     * This is because the token has a fixed number of decimal places,
     * which can be specified by adding a 'decimals' variable to the contract.
     * Finally, the tokens are minted and assigned to the contract owner's address.
     */
    uint256 intialTokenSupply = totalSupply_ * (10 ** decimals());
    _mint(owner_, intialTokenSupply);

    /**
     * In the next line, we set the transfer fee percentage for the token transfers.
     * This is the amount that will be deducted from the transferred amount as a fee
     * and added to the treasury wallet.
     */
    setTransferFee(txnFee_);

    /**
     * The ownership of the contract is transferred to the specified owner address.
     * This provides full control over the contract to the owner.
     */
    _transferOwnership(owner_);

    /**
     * In the final line, we set up the default whitelist.
     * The whitelist ensures that certain addresses can have special permissions within the contract.
     * For instance, they may be able to transfer tokens even if a transfer fee is in place.
     * This function sets the default whitelist for all addresses.
     */
    _setDefaultWhitelist();
  }

  /**
   * @dev Sets the treasury wallet address where transfer fees will be credited.
   * @param account The wallet address of the treasury.
   * @notice Function can only be called by contract owner.
   */
  function setTreasuryWalletAddress(address account) external onlyOwner {
    /// The treasury wallet address cannot be zero-address.
    require(account != address(0), 'LINGO: Zero Address');
    _treasuryWallet = account;
    /// Emitted when `_treasuryWallet` is updated using this function.
    emit TreasuryWalletUpdated(account);
  }

  /**
   * @dev Removes one or more addresses from a specific whitelist
   * @param whiteListType The type of whitelist to remove from
   * @param users An array of addresses to remove from the whitelist
   */
  function removeFromWhiteList(
    WhiteListTypes whiteListType,
    address[] memory users
  ) external onlyOwner {
    if (whiteListType == WhiteListTypes.EXTERNAL_WHITELISTED) {
      _removeFromExternalWhiteList(users);
    } else if (whiteListType == WhiteListTypes.INTERNAL_WHITELISTED) {
      _removeFromInternalWhiteList(users);
    }
  }

  /**
   * @dev Mint new tokens.
   * @param to The address to mint the tokens to.
   * @param amount The amount of tokens to mint.
   */
  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }

  /**
   * @dev Returns the current transfer fee percentage.
   * @return _transferFee the current transfer fee percentage.
   */
  function getTransferFee() external view returns (uint256) {
    return _transferFee;
  }

  /**
   * @dev Checks if the given account is external white-listed.
   * @param account The wallet address to be checked in the white-list.
   * @return bool `true` if the account is white-listed, `false` otherwise.
   */
  function isExternalWhiteListed(address account) external view returns (bool) {
    return _isExternalWhiteListed[account];
  }

  /**
   * @dev Checks if the given account is internal white-listed.
   * @param account The wallet address to be checked in the white-list.
   * @return bool `true` if the account is white-listed, `false` otherwise.
   */
  function isInternalWhiteListed(address account) external view returns (bool) {
    return _isInternalWhiteListed[account];
  }

  /**
   * @dev Returns the current treasury wallet address.
   * @return _treasuryWallet The current treasury wallet address.
   * @notice Function can only be called by contract owner.
   */
  function getTreasuryWalletAddress() external view returns (address) {
    return _treasuryWallet;
  }

  /**
   * @dev Returns an array of addresses that are whitelisted for external users.
   * @return address[] memory An array of whitelisted addresses.
   */
  function getExternalWhitelistedAddresses() external view returns (address[] memory) {
    return _externalWhitelistedAddresses;
  }

  /**
   * @dev Returns an array of addresses that are whitelisted for internal users.
   * @return address[] memory An array of whitelisted addresses.
   */
  function getInternalWhitelistedAddresses() external view returns (address[] memory) {
    return _internalWhitelistedAddresses;
  }

  /**
   * @dev Sets the transfer fee percentage that must be paid by the token sender.
   * @param fee transfer fee in percentage.Eg: 5% as 500.
   * @notice Function can only be called by contract owner.
   */
  function setTransferFee(uint256 fee) public onlyOwner {
    /// Require the fee to be less than or equal to 5%.
    require(fee <= 500, 'LINGO: Transfer Fee should be between 0% - 5%');
    _transferFee = fee;
    /// Emitted when `fee` is updated using this function.
    emit TransferFeeUpdated(fee);
  }

  /**
   * @dev Transfer tokens from sender to another address.
   * @param to The address to transfer the tokens to.
   * @param amount The amount of tokens to transfer.
   * @return bool True if transfer is successful, false otherwise.
   */
  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address sender = _msgSender();
    if (_isFeeRequired(sender, to)) {
      uint256 fee = (amount * _transferFee) / 10000;
      _transfer(sender, _treasuryWallet, fee);
      _transfer(sender, to, amount - fee);
    } else {
      _transfer(sender, to, amount);
    }
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another on behalf of a sender.
   * @param from The address to transfer tokens from.
   * @param to The address to transfer tokens to.
   * @param amount The amount of tokens to transfer.
   * @return bool True if transfer is successful, false otherwise.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    if (_isFeeRequired(from, to)) {
      uint256 charge = (amount * _transferFee) / 10000;
      _transfer(from, _treasuryWallet, charge);
      _transfer(from, to, amount - charge);
    } else {
      _transfer(from, to, amount);
    }
    return true;
  }

  /**
   * @dev Adds addresses to the specified whitelist.
   * @param whiteListType The type of the whitelist (external or internal).
   * @param users The addresses to be added.
   */
  function addToWhiteList(WhiteListTypes whiteListType, address[] memory users) public onlyOwner {
    if (whiteListType == WhiteListTypes.EXTERNAL_WHITELISTED) {
      for (uint i = 0; i < users.length; i++) {
        /// Check if address is already whitelisted
        if (_isExternalWhiteListed[users[i]]) continue;

        /// If not, add it to external whitelist and mark as true
        _externalWhitelistedAddresses.push(users[i]);
        _isExternalWhiteListed[users[i]] = true;
      }
      emit WhiteListUpdated(whiteListType, true, users);
    } else if (whiteListType == WhiteListTypes.INTERNAL_WHITELISTED) {
      for (uint i = 0; i < users.length; i++) {
        /// Check if address is already whitelisted
        if (_isInternalWhiteListed[users[i]]) continue;

        /// If not, add it to internal whitelist and mark as true
        _internalWhitelistedAddresses.push(users[i]);
        _isInternalWhiteListed[users[i]] = true;
      }
      emit WhiteListUpdated(whiteListType, true, users);
    }
  }

  /**
   * @dev Removes one or multiple users from the internal whitelist.
   * Only the contract owner can call this function.
   *
   * @param users Array of addresses to remove from the whitelist
   */
  function _removeFromInternalWhiteList(address[] memory users) internal onlyOwner {
    bool removed = false;
    for (uint i = 0; i < users.length; i++) {
      /// Check if address is already removed from whitelist
      if (!_isInternalWhiteListed[users[i]]) continue;

      removed = false;
      for (uint j = 0; j < _internalWhitelistedAddresses.length; j++) {
        if (users[i] == _internalWhitelistedAddresses[j]) {
          _isInternalWhiteListed[users[i]] = false;

          /// Swap the removed address with the last address in the array and pop it off
          _internalWhitelistedAddresses[j] = _internalWhitelistedAddresses[
            _internalWhitelistedAddresses.length - 1
          ];
          _internalWhitelistedAddresses.pop();

          removed = true;
          break;
        }
      }
    }
    if (removed) emit WhiteListUpdated(WhiteListTypes.INTERNAL_WHITELISTED, false, users);
  }

  /**
   * @dev Removes one or multiple users from the external whitelist.
   * Only the contract owner can call this function.
   *
   * @param users Array of addresses to remove from the whitelist
   */
  function _removeFromExternalWhiteList(address[] memory users) internal onlyOwner {
    bool removed = false;
    for (uint i = 0; i < users.length; i++) {
      /// Check if address is already removed from whitelist
      if (!_isExternalWhiteListed[users[i]]) continue;

      removed = false;
      for (uint j = 0; j < _externalWhitelistedAddresses.length; j++) {
        if (users[i] == _externalWhitelistedAddresses[j]) {
          _isExternalWhiteListed[users[i]] = false;

          /// Swap the removed address with the last address in the array and pop it off
          _externalWhitelistedAddresses[j] = _externalWhitelistedAddresses[
            _externalWhitelistedAddresses.length - 1
          ];
          _externalWhitelistedAddresses.pop();

          removed = true;
          break;
        }
      }
    }
    if (removed) emit WhiteListUpdated(WhiteListTypes.EXTERNAL_WHITELISTED, false, users);
  }

  /**
   * @dev This function sets the default whitelist that contains three addresses: owner, contract address and treasury wallet.
   * @notice The function is internal and cannot be called outside the contract.
   */
  function _setDefaultWhitelist() internal {
    address[3] memory defaultWhiteListedAddresses = [owner(), address(this), _treasuryWallet];

    /// We create a dynamic array of addresses using memory allocation with length equal to defaultWhitelistedAddresses length.

    address[] memory defaultWhiteListedAddressesDynamic = new address[](
      defaultWhiteListedAddresses.length
    );

    /// Copying the elements from static to dynamic array.
    for (uint i = 0; i < defaultWhiteListedAddresses.length; i++) {
      defaultWhiteListedAddressesDynamic[i] = defaultWhiteListedAddresses[i];
    }

    addToWhiteList(WhiteListTypes.INTERNAL_WHITELISTED, defaultWhiteListedAddressesDynamic);
  }

  /**
   * @dev Check if fee is required for transfer.
   * @param from The address sending the tokens.
   * @param to The address receiving the tokens.
   * @return bool True if fee is required, false otherwise.
   */
  function _isFeeRequired(address from, address to) internal view returns (bool) {
    if (
      !_isInternalWhiteListed[from] && !_isInternalWhiteListed[to] && !_isExternalWhiteListed[to]
    ) {
      return true;
    }
    return false;
  }

  /**
   * @dev Hook function that is called before any token transfer.
   * @param from The address tokens are transferred from.
   * @param to The address tokens are transferred to.
   * @param amount The amount of tokens being transferred.
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    super._beforeTokenTransfer(from, to, amount);
  }
}