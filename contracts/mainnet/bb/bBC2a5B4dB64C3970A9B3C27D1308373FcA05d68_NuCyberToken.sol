// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IArrayErrors {
  /**
  * @dev Thrown when two related arrays have different lengths
  */
  error ARRAY_LENGTH_MISMATCH();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @dev Required interface of an ERC173 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-173[EIP].
*/
interface IERC173 /* is IERC165 */ {
  /**
  * @dev This emits when ownership of a contract changes.
  * 
  * @param previousOwner the previous contract owner
  * @param newOwner the new contract owner
  */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
  * @notice Set the address of the new owner of the contract.
  * @dev Set newOwner_ to address(0) to renounce any ownership.
  */
  function transferOwnership(address newOwner_) external; 

  /**
  * @notice Returns the address of the owner.
  */
  function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC173Errors {
  /**
  * @dev Thrown when `operator` is not the contract owner.
  * 
  * @param operator address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER(address operator);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC173.sol";
import "../interfaces/IERC173Errors.sol";

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
abstract contract ERC173 is IERC173, IERC173Errors {
  // The owner of the contract
  address private _owner;

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
      if (owner() != msg.sender) {
        revert IERC173_NOT_OWNER(msg.sender);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Sets the contract owner.
    * 
    * Note: This function needs to be called in the contract constructor to initialize the contract owner, 
    * if it is not, then parts of the contract might be non functional
    * 
    * @param owner_ : address that owns the contract
    */
    function _setOwner(address owner_) internal {
      _owner = owner_;
    }
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    /**
    * @dev Transfers ownership of the contract to `newOwner_`.
    * 
    * @param newOwner_ : address of the new contract owner
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function transferOwnership(address newOwner_) public virtual onlyOwner {
      address _oldOwner_ = _owner;
      _owner = newOwner_;
      emit OwnershipTransferred(_oldOwner_, newOwner_);
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @dev Returns the address of the current contract owner.
    * 
    * @return address : the current contract owner
    */
    function owner() public view virtual returns (address) {
      return _owner;
    }
  // **************************************
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

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IArrayErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { FxBaseChildTunnel } from "fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

contract NuCyberToken is IArrayErrors, ERC173, ERC20, FxBaseChildTunnel {
  // **************************************
  // *****        CUSTOM TYPES        *****
  // **************************************
    /**
    * @dev A list of possible rarities for a token
    */
    enum Rarity {
      NONE,
      SMALL,
      MEDIUM,
      LARGE,
      LUXURY,
      PENTHOUSE
    }
    /**
    * @dev A structure to save a user's current rewards and last update
    */
    struct StakingInfo {
      uint16 small;
      uint16 medium;
      uint16 large;
      uint16 luxury;
      uint16 penthouse;
      uint128 lastUpdate;
    }
  // **************************************

  // **************************************
  // *****           ERRORS           *****
  // **************************************
    /**
    * @dev Thrown when trying to unstake tokens not owned
    * 
    * @param account owning the tokens
    * @param rarity the rarity of the tokens being unstaked
    * @param amount the quantity of tokens being unstaked
    */
    error NCT_INSUFFICIENT_BALANCE(address account, Rarity rarity, uint256 amount);
    /**
    * @dev Thrown when user tries to withdraw $CYBER when none is due
    * 
    * @param account the address trying to withdraw
    */
    error NCT_NO_BALANCE_DUE(address account);
  // **************************************

  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint private constant _MAX_SUPPLY = 100_000_000 * 1e18;
  // **************************************

  // **************************************
  // *****     STORAGE  VARIABLES     *****
  // **************************************
    // Wallet address mapped to proxy status
    mapping (address => bool) public isProxy;
    // Rarity mapped to reward rate
    mapping (Rarity => uint256) private _rewardRates;
    // Wallet address mapped to staking info
    mapping (address => StakingInfo) private _stakingInfo;
  // **************************************

  // fxChild_ special contract on Polygon to enable communication with Ethereum mainnet
  constructor(address fxChild_)
  FxBaseChildTunnel(fxChild_)
  ERC20("NuCyber Token", "CYBER") {
    _setOwner(msg.sender);
    _rewardRates[Rarity.SMALL] = 6;
    _rewardRates[Rarity.MEDIUM] = 7;
    _rewardRates[Rarity.LARGE] = 8;
    _rewardRates[Rarity.LUXURY] = 12;
    _rewardRates[Rarity.PENTHOUSE] = 30;
    _mint(address(this), _MAX_SUPPLY);
  }

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function to process a message received from the parent contract on Eth Mainnet.
    * 
    * @param stateId_ unique state id
    * @param sender_ root message sender
    * @param message_ bytes message that was sent from Root Tunnel
    */
    function _processMessageFromRoot(uint256 stateId_, address sender_, bytes memory message_)
    internal
    override
    validateSender(sender_) {
      (address _from_, uint8 _rarity_, uint16 _count_, bool _isStake_) = abi.decode(
        message_,
        (address, uint8, uint16, bool)
      );
      _isStake_ ? 
        _processStake(_from_, Rarity(_rarity_), _count_) :
        _processUnstake(_from_, Rarity(_rarity_), _count_);
    }
    /**
    * @dev Internal function to stake an amount of a specific token type.
    * 
    * @param tokenOwner_ the address which will be staking
    * @param rarity_ the token type to stake
    * @param amount_ the amount to stake
    */
    function _processStake(address tokenOwner_, Rarity rarity_, uint16 amount_) internal {
      StakingInfo memory _stakingInfo_ = _stakingInfo[tokenOwner_];
      uint256 _rewards_ = _totalRewards(tokenOwner_);
      _stakingInfo_.lastUpdate = uint128(block.timestamp);
      if (rarity_ == Rarity.SMALL) {
        unchecked {
          _stakingInfo_.small += amount_;
        }
      }
      if (rarity_ == Rarity.MEDIUM) {
        unchecked {
          _stakingInfo_.medium += amount_;
        }
      }
      if (rarity_ == Rarity.LARGE) {
        unchecked {
          _stakingInfo_.large += amount_;
        }
      }
      if (rarity_ == Rarity.LUXURY) {
        unchecked {
          _stakingInfo_.luxury += amount_;
        }
      }
      if (rarity_ == Rarity.PENTHOUSE) {
        unchecked {
          _stakingInfo_.penthouse += amount_;
        }
      }

      _stakingInfo[tokenOwner_] = _stakingInfo_;
      if (_rewards_ > 0) {
        _transfer(address(this), tokenOwner_, _rewards_);
      }
    }
    /**
    * @dev Internal function to unstake an amount of a specific token type.
    * 
    * @param tokenOwner_ the address which will be unstaking
    * @param rarity_ the token type to unstake
    * @param amount_ the amount to unstake
    */
    function _processUnstake(address tokenOwner_, Rarity rarity_, uint16 amount_) internal {
      StakingInfo memory _stakingInfo_ = _stakingInfo[tokenOwner_];
      uint256 _rewards_ = _totalRewards(tokenOwner_);
      _stakingInfo_.lastUpdate = uint128(block.timestamp);
      if (rarity_ == Rarity.SMALL) {
        if (_stakingInfo_.small < amount_) {
          revert NCT_INSUFFICIENT_BALANCE(tokenOwner_, rarity_, amount_);
        }
        unchecked {
          _stakingInfo_.small -= amount_;
        }
      }
      if (rarity_ == Rarity.MEDIUM) {
        if (_stakingInfo_.medium < amount_) {
          revert NCT_INSUFFICIENT_BALANCE(tokenOwner_, rarity_, amount_);
        }
        unchecked {
          _stakingInfo_.medium -= amount_;
        }
      }
      if (rarity_ == Rarity.LARGE) {
        if (_stakingInfo_.large < amount_) {
          revert NCT_INSUFFICIENT_BALANCE(tokenOwner_, rarity_, amount_);
        }
        unchecked {
          _stakingInfo_.large -= amount_;
        }
      }
      if (rarity_ == Rarity.LUXURY) {
        if (_stakingInfo_.luxury < amount_) {
          revert NCT_INSUFFICIENT_BALANCE(tokenOwner_, rarity_, amount_);
        }
        unchecked {
          _stakingInfo_.luxury -= amount_;
        }
      }
      if (rarity_ == Rarity.PENTHOUSE) {
        if (_stakingInfo_.penthouse < amount_) {
          revert NCT_INSUFFICIENT_BALANCE(tokenOwner_, rarity_, amount_);
        }
        unchecked {
          _stakingInfo_.penthouse -= amount_;
        }
      }

      _stakingInfo[tokenOwner_] = _stakingInfo_;
      if (_rewards_ > 0) {
        _transfer(address(this), tokenOwner_, _rewards_);
      }
    }
    /**
    * @dev Internal function that calculates and returns the amount of rewards earned by `tokenOwner_` so far.
    * 
    * @param tokenOwner_ the owner of the NFTs
    */
    function _totalRewards(address tokenOwner_) private view returns (uint256) {
      uint256 _totalRewards_;
      StakingInfo memory _stakingInfo_ = _stakingInfo[tokenOwner_];
      if (_stakingInfo_.lastUpdate != 0) {
        uint256 _timeDiff_;

        if (uint128(block.timestamp) > _stakingInfo_.lastUpdate) {
          unchecked {
            _timeDiff_ = uint128(block.timestamp) - _stakingInfo_.lastUpdate;
            _totalRewards_ = rewardsPerDay(tokenOwner_) * _timeDiff_ * 1e18 / 1 days;
          }
        }
      }
      return _totalRewards_;
    }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @notice Moves `amount_` tokens from_ `from` to `to_` using the allowance mechanism.
    *   `amount_` is then deducted from the caller's allowance.
    * 
    * @param from_ the address the tokens are being sent from
    * @param to_ the address the tokens are being sent to
    * @param amount_ the amount of tokens being sent
    * 
    * @return a boolean value indicating whether the operation succeeded.
    * 
    * Emits a {Transfer} event.
    */
    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
      if (! isProxy[msg.sender]) {
        _spendAllowance(from_, msg.sender, amount_);
      }
      _transfer(from_, to_, amount_);
      return true;
    }
    /**
    * @notice Withdraws all rewards earned and unclaimed by the caller.
    */
    function withdrawCyber() public {
      uint256 _rewards_ = _totalRewards(msg.sender);
      StakingInfo memory _stakingInfo_ = _stakingInfo[msg.sender];
      if (_rewards_ == 0) {
        revert NCT_NO_BALANCE_DUE(msg.sender);
      }
      _stakingInfo_.lastUpdate = uint128(block.timestamp);
      _stakingInfo[msg.sender] = _stakingInfo_;
      _transfer(address(this), msg.sender, _rewards_);
    }
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    /**
    * @notice Grants or revokes proxy access to `newProxyOperator_`.
    * 
    * @param newProxyOperator_ the address being granted or revoked access
    * @param approved_ whether the access is granted or revoked
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setProxyOperator(address newProxyOperator_, bool approved_) external onlyOwner {
      isProxy[newProxyOperator_] = approved_;
    }
    /**
    * @dev Updates the daily rewards for staking a token.
    * 
    * @param smallRate_ the new daily rewards for staking a Small NuCyber
    * @param mediumRate_ the new daily rewards for staking a Medium NuCyber
    * @param largeRate_ the new daily rewards for staking a Large NuCyber
    * @param luxuryRate_ the new daily rewards for staking a Luxury NuCyber
    * @param penthouseRate_ the new daily rewards for staking a Penthouse NuCyber
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setRates(
      uint256 smallRate_,
      uint256 mediumRate_,
      uint256 largeRate_,
      uint256 luxuryRate_,
      uint256 penthouseRate_
    ) external onlyOwner {
      _rewardRates[Rarity.SMALL] = smallRate_;
      _rewardRates[Rarity.MEDIUM] = mediumRate_;
      _rewardRates[Rarity.LARGE] = largeRate_;
      _rewardRates[Rarity.LUXURY] = luxuryRate_;
      _rewardRates[Rarity.PENTHOUSE] = penthouseRate_;
    }
    /**
    * @notice Updates the staking contract address.
    * 
    * @param fxRootTunnel_ the new staking contract address
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function updateFxRootTunnel(address fxRootTunnel_) external onlyOwner {
      fxRootTunnel = fxRootTunnel_;
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @dev Returns the amount of rewards earned by `tokenOwner_` so far.
    * 
    * @param tokenOwner_ the owner of the NFT
    */
    function getTotalRewards(address tokenOwner_) public view returns (uint256) {
      return _totalRewards(tokenOwner_);
    }
    /**
    * @dev Returns the rewards that `tokenOwner_` earns per second.
    * 
    * @param tokenOwner_ the owner of the NFT
    */
    function rewardsPerDay(address tokenOwner_) public view returns (uint256) {
      uint256 _reward_;
      StakingInfo memory _stakingInfo_ = _stakingInfo[tokenOwner_];
      if (_stakingInfo_.small > 0) {
        unchecked {
          _reward_ += _stakingInfo_.small * _rewardRates[Rarity.SMALL];
        }
      }
      if (_stakingInfo_.medium > 0) {
        unchecked {
          _reward_ += _stakingInfo_.medium * _rewardRates[Rarity.MEDIUM];
        }
      }
      if (_stakingInfo_.large > 0) {
        unchecked {
          _reward_ += _stakingInfo_.large * _rewardRates[Rarity.LARGE];
        }
      }
      if (_stakingInfo_.luxury > 0) {
        unchecked {
          _reward_ += _stakingInfo_.luxury * _rewardRates[Rarity.LUXURY];
        }
      }
      if (_stakingInfo_.penthouse > 0) {
        unchecked {
          _reward_ += _stakingInfo_.penthouse * _rewardRates[Rarity.PENTHOUSE];
        }
      }
      return _reward_;
    }
  // **************************************
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}