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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

interface IDAOTokenFarm {

    function getStakedBalance(address account, address lpToken) external view returns (uint);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import "./PoolLPToken.sol";

/**
*  Pool's functionality required by DAOOperations and DAOFarm
*/

interface IPoolV4 {

    // View functions
    function lpToken() external view returns (PoolLPToken);

    function totalValue() external view returns(uint);
    function riskAssetValue() external view returns(uint);
    function stableAssetValue() external view returns(uint);

    function lpTokensValue (uint lpTokens) external view returns (uint);
    function portfolioValue(address addr) external view returns (uint);

    /**
     * @notice  The fees to withdraw the given amount of LP tokens calcualted as percentage of the outstanding
     *          profit that the user is withdrawing
     * @return fees, in LP tokens, that an account would pay to withdraw 'lpToWithdraw' LP tokens.
     *
     */
    function feesForWithdraw(uint lpToWithdraw, address account) external view returns (uint);

    // Transactional functions
    function deposit(uint amount) external;
    function withdrawLP(uint amount) external;

    // Only Owner functions
    function setFeesPerc(uint feesPerc) external;
    function setSlippageThereshold(uint slippage) external;
    function setStrategy(address strategyAddress) external;
    function setUpkeepInterval(uint upkeepInterval) external;
    function collectFees(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0), "Roles: 0x0 account");
        require(!has(role, account), "Roles: Account already has role");

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0), "Roles: 0x0 account");
        require(has(role, account), "Roles: Account does not have role");

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: 0x0 account");
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: Non minter call");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MinterRole.sol";

/**
 * The LP Token for the Pool representing the share of the value of the Pool held by ther owner.
 * When users deposit into the pool new LP tokens get minted.
 * When users withdraw their funds from the pool, they have to retun their LP tokens which get burt.
 * Only the Pool contract should be able to mint/burn its LP tokens.
 */

contract PoolLPToken is ERC20, MinterRole {

    uint8 immutable decs;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol) {
        decs = _decimals;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address to, uint256 value) public onlyMinter returns (bool) {
        _burn(to, value);
        return true;
    }

    function decimals() public view override returns (uint8) {
        return decs;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./IPoolV4.sol";
import "./IDAOTokenFarm.sol";
import "./PoolLPToken.sol";
import "./TokenMaths.sol";

import "./strategies/IStrategy.sol";
import "./swaps/IUniswapV2Router.sol";
import "./swaps/ISwapsRouter.sol";


/**
 * The contract of the HashStrat Pool. A pool is a digital valult that holds:
 * - A risk asset (e.g WETH or WBTC), also called invest token.
 * - A stable asset (e.g USDC), also called depoist token.
 * Each pool is configured with:
 * - Chainlink price feeds for the risk and stable assets of the pool.
 * - A Strategy, that represent the rules about how to trade between the risk asset and the stable asset in the pool.
 * - A SwapsRouter, that will route the swaps performed by the strategy to the appropriate AMM.
 * - Addresses of the tokens used by the pool: the pool LP token, a deposit and a risk tokens.
 *
 * Users who deposit funds into a pool receive an amount LP tokens proportional to the value they provided.
 * Users withdraw their funds by returning their LP tokens to the pool, that get burnt.
 * A Pool can charge a fee to the profits withdrawn from the pool in the form of percentage of LP tokens that
 * will remain in the pool at the time when users withdraws their funds.
 * A pool automates the execution of its strategy and the executon of swaps using ChainLink Automation.
 * Large swaps are broken into up to 256 smaller chunks and executed over a period of time to reduce slippage.
 */

contract PoolV4 is IPoolV4, ReentrancyGuard, AutomationCompatibleInterface, Ownable {

    using TokenMaths for uint256;

    enum UserOperation {
        NONE,
        DEPOSIT,
        WITHDRAWAL
    }

    struct SwapInfo {
        uint256 timestamp;
        string side;
        uint256 feedPrice;
        uint256 bought;
        uint256 sold;
        uint256 depositTokenBalance;
        uint256 investTokenBalance;
    }

    struct TWAPSwap {
        StrategyAction side;
        address tokenIn;
        address tokenOut;
        uint256 total; // the total amount of the tokenIn to spend (e.g. the total size of this twap swap)
        uint256 size; // the max size of each indivitual swap
        uint256 sold; // the cumulative amount of the tokenIn tokens spent
        uint256 bought; // the cumulative amount of the tokenOut tokens bought
        uint256 lastSwapTimestamp; // timestamp of the last attempted/executed swap
    }

    struct UserInfo {
        uint256 timestamp;
        UserOperation operation;
        uint256 amount;
    }

    uint256 public twapSwapInterval = 5 * 60; // 5 minutes between swaps
    uint8 public immutable feesPercDecimals = 4;
    uint256 public feesPerc; // using feePercDecimals precision (e.g 100 is 1%)

    IDAOTokenFarm public daoTokenFarm;

    // Pool tokens
    IERC20Metadata public immutable depositToken;
    IERC20Metadata public immutable investToken;
    PoolLPToken public immutable lpToken;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Swapped(string side, uint256 sold, uint256 bought, uint256 slippage);
    event SwapError(string reason);
    event InvalidAmount();
    event MaxSlippageExceeded(string side, uint256 amountIn, uint256 amountOutMin, uint256 slippage);

    uint256 public totalDeposited = 0;
    uint256 public totalWithdrawn = 0;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public withdrawals;
    mapping(address => UserInfo[]) public userInfos;

    address[] public users;
    mapping(address => bool) usersMap;

    // Chainlink price feeds
    AggregatorV3Interface public immutable riskAssetFeed;
    AggregatorV3Interface public immutable stableAssetFeed;

    ISwapsRouter public immutable swapRouter;
    IStrategy public strategy;

    // Swap data
    TWAPSwap public twapSwaps; // the pending swap
    SwapInfo[] public swaps; // logs of compteted swaps
    uint256 public slippageThereshold = 100; // allow for 1% slippage on swaps (aka should receive at least 99% of the expected token amount)

    uint24 public immutable feeV3;
    uint256 public swapMaxValue;

    uint private lastTransactionTimestamp;

    constructor(
        address swapRouterAddress,
        address stableAssetFeedAddress,
        address riskAssetFeedAddress,
        address depositTokenAddress,
        address investTokenAddress,
        address lpTokenAddress,
        address strategyAddress,
        uint256 poolFees,
        uint24 uniswapV3Fee,
        uint256 swapValue
    ) {
        swapRouter = ISwapsRouter(swapRouterAddress);

        stableAssetFeed = AggregatorV3Interface(stableAssetFeedAddress);
        riskAssetFeed = AggregatorV3Interface(riskAssetFeedAddress);

        depositToken = IERC20Metadata(depositTokenAddress);
        investToken = IERC20Metadata(investTokenAddress);

        lpToken = PoolLPToken(lpTokenAddress);
        strategy = IStrategy(strategyAddress);
        feesPerc = poolFees;
        feeV3 = uniswapV3Fee;

        swapMaxValue = swapValue;
    }

    //// External functions ////

    function deposit(uint256 amount) external override nonReentrant {
        require(depositToken.allowance(msg.sender, address(this)) >= amount, "PoolV4: Insufficient allowance");

        if (amount == 0) return;

        lastTransactionTimestamp = block.timestamp;

        // 0. total asset value and risk asset allocation before receiving the deposit
        uint valueBefore = totalValue();
        uint256 investTokenPerc = investTokenPercentage();

        // 1. Transfer deposit amount to the pool
        depositToken.transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] += amount;
        totalDeposited += amount;

        // and record user address (if new user) and deposit infos
        if (!usersMap[msg.sender]) {
            usersMap[msg.sender] = true;
            users.push(msg.sender);
        }

        userInfos[msg.sender].push(
            UserInfo({
                timestamp: block.timestamp,
                operation: UserOperation.DEPOSIT,
                amount: amount
            })
        );

        // 2. Rebalance the pool to ensure the deposit does not alter the pool allocation
        if (lpToken.totalSupply() == 0) {
            // if the pool was empty before this deposit => exec the strategy once to establish the initial asset allocation
            strategyExec();
        } else {
            // if the pool was not empty before this deposit => ensure the pool remains balanced after this deposit.
            uint256 rebalanceAmountIn = (investTokenPerc * amount) / (10**uint256(portfolioPercentageDecimals()));
   
            if (rebalanceAmountIn > 0) {
                // performa a rebalance operation
                (uint256 sold, uint256 bought, uint256 slippage) = swapIfNotExcessiveSlippage(
                    address(depositToken),
                    address(investToken),
                    StrategyAction.BUY,
                    rebalanceAmountIn
                );

                require(sold > 0 && bought > 0, "PoolV4: swap error");
                emit Swapped("BUY", sold, bought, slippage);
            }
        }

        // 3. Calculate LP tokens for this deposit that will be minted to the depositor based on the value in the pool AFTER the swaps
        uint valueAfter = totalValue();
        uint256 depositLPTokens = lpTokensForDeposit(valueAfter - valueBefore);

        // 4. Mint LP tokens to the user
        lpToken.mint(msg.sender, depositLPTokens);

        emit Deposited(msg.sender, amount);
    }

    function withdrawAll() external nonReentrant {
        collectFeeAndWithdraw(lpToken.balanceOf(msg.sender));
    }

    function withdrawLP(uint256 amount) external nonReentrant {
        collectFeeAndWithdraw(amount);
    }

    // onlyOwner functions //

    function setSlippageThereshold(uint256 slippage) external onlyOwner {
        slippageThereshold = slippage;
    }

    function setStrategy(address strategyAddress) external onlyOwner {
        strategy = IStrategy(strategyAddress);
    }

    function setUpkeepInterval(uint256 innterval) external onlyOwner {
        strategy.setUpkeepInterval(innterval);
    }

    function setFeesPerc(uint256 _feesPerc) external onlyOwner {
        feesPerc = _feesPerc;
    }

    function setFarmAddress(address farmAddress) external onlyOwner {
        daoTokenFarm = IDAOTokenFarm(farmAddress);
    }

    function setSwapMaxValue(uint256 value) external onlyOwner {
        swapMaxValue = value;
    }

    function setTwapSwapInterval(uint256 interval) external onlyOwner {
        twapSwapInterval = interval;
    }

    // Withdraw the given amount of LP token fees in deposit tokens
    function collectFees(uint256 amount) external onlyOwner {
        uint256 lpAmount = amount == 0 ? lpToken.balanceOf(address(this)) : amount;
        if (lpAmount > 0) {
            lpToken.transfer(msg.sender, lpAmount);
            _withdrawLP(lpAmount);
        }
    }

    /**
     *  Process a TWAP swap if there is one in progress, othewise check if it's time to run the strategy.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        if (
            (twapSwaps.sold < twapSwaps.total) &&
            (block.timestamp >= twapSwaps.lastSwapTimestamp + twapSwapInterval)
        ) {
            handleTwapSwap();
        } else if (
            (twapSwaps.sold == twapSwaps.total) && 
            strategy.shouldPerformUpkeep()
        ) {
            strategyExec();
        }
    }


    // External view functions //

    /**
     * Perfor upkeep if:
     *  1. The current twap swap was fully executed AND enough time has elapsed since the last time the twap swap was processed
     *  2. The strategy should run
     */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        return (
            ( (twapSwaps.sold < twapSwaps.total) && (block.timestamp >= twapSwaps.lastSwapTimestamp + twapSwapInterval) ) ||
            ( twapSwaps.sold == twapSwaps.total && strategy.shouldPerformUpkeep() ),
            ""
        );
    }

    function getSwapsInfo() external view returns (SwapInfo[] memory) {
        return swaps;
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function getUserInfos(address account) external view returns (UserInfo[] memory) {
        return userInfos[account];
    }

    // Return the value of the assets for the account (in USD)
    function portfolioValue(address account) external view returns (uint256) {
        // the value of the portfolio allocated to the user, espressed in deposit tokens
        uint256 precision = 10**uint256(portfolioPercentageDecimals());
        return (totalValue() * portfolioPercentage(account)) / precision;
    }

    //// Public view functions ////

    /**
     * @notice The fees to withdraw are calcualted as percentage of the outstanding profit that the user is withdrawing
     * For example:
     *  given a 1% fees on profits,
     *  when a user having $1000 in outstaning profits is withdrawing 20% of his LP tokens
     *  then he will have to pay the LP equivalent of $2.00 in fees
     *
     *     withdraw_value : = pool_value * lp_to_withdraw / lp_total_supply
     *     fees_value := fees_perc * gains_perc(account) * withdraw_value
     *                := fees_perc * gains_perc(account) * pool_value * lp_to_withdraw / lp_total_supply
     *
     *     fees_lp := fees_value * lp_total_supply / pool_value            <= fees_lp / lp_total_supply = fees_value / pool_value)
     *             := fees_perc * gains_perc(account) * pool_value * lp_to_withdraw / lp_total_supply * lp_total_supply / pool_value
     *             := fees_perc * gains_perc(account) * lp_to_withdraw
     *
     * @param lpToWithdraw the amount of LP tokens to withdraw
     * @param account the account withdrawing the LP tokens
     *
     * @return amount, in LP tokens, that 'account' would pay to withdraw 'lpToWithdraw' LP tokens.
     */

    function feesForWithdraw(uint256 lpToWithdraw, address account) public view returns (uint256) {
        return
            (feesPerc * gainsPerc(account) * lpToWithdraw) /
            (10**(2 * uint256(feesPercDecimals)));
    }

    /**
     * @param account used to determine the percentage of gains
     * @return the percentage percentage for the account provided using 'feesPercDecimals' decimals
     */
    function gainsPerc(address account) public view returns (uint256) {
        // if the address has no deposits (e.g. LPs were transferred from original depositor)
        // then consider the entire LP value as gains.
        // This is to prevent fee avoidance by withdrawing the LPs to different addresses
        if (deposits[account] == 0) return 10**uint256(feesPercDecimals); // 100% of LP tokens are taxable

        // take into account for staked LP when calculating the value held in the pool
        uint256 stakedLP = address(daoTokenFarm) != address(0)
            ? daoTokenFarm.getStakedBalance(account, address(lpToken))
            : 0;
        uint256 valueInPool = lpTokensValue(
            lpToken.balanceOf(account) + stakedLP
        );

        // check if accounts is in profit
        bool hasGains = withdrawals[account] + valueInPool > deposits[account];

        // return the fees on the gains or 0 if there are no gains
        return
            hasGains
                ? (10**uint256(feesPercDecimals) *
                    (withdrawals[account] + valueInPool - deposits[account])) /
                    deposits[account]
                : 0;
    }

    // Return the value of the given amount of LP tokens (in USD)
    function lpTokensValue(uint256 amount) public view returns (uint256) {
        return
            lpToken.totalSupply() > 0
                ? (totalValue() * amount) / lpToken.totalSupply()
                : 0;
    }

    // Return the % of the pool owned by 'account' with the precision of the risk asset price feed decimals
    function portfolioPercentage(address account)
        public
        view
        returns (uint256)
    {
        if (lpToken.totalSupply() == 0) return 0;

        return
            (10**uint256(portfolioPercentageDecimals()) *
                lpToken.balanceOf(account)) / lpToken.totalSupply();
    }

    // Return the pool total value in USD
    function totalValue() public view override returns (uint256) {
        return stableAssetValue() + riskAssetValue();
    }

    /**
     * @return value of the stable assets in the pool (in USD)
     */
    function stableAssetValue() public view override returns (uint256) {
        (
            ,
            /*uint80 roundID**/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = stableAssetFeed.latestRoundData();

        if (price <= 0) return 0;

        return depositToken.balanceOf(address(this)).mul(uint256(price), depositToken.decimals(), stableAssetFeed.decimals(), depositToken.decimals());
    }

    /**
     * @return value of the risk assets in the pool (in USD)
     */
    function riskAssetValue() public view override returns (uint256) {
        (
            ,
            /*uint80 roundID**/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = riskAssetFeed.latestRoundData();
        if (price <= 0) return 0;

        return investToken.balanceOf(address(this)).mul(uint256(price), investToken.decimals(), riskAssetFeed.decimals(), depositToken.decimals());
    }

    //// Internal Functions ////

    function investTokenPercentage() internal view returns (uint256) {
        return
            (lpToken.totalSupply() == 0)
                ? 0
                : (10**uint256(portfolioPercentageDecimals()) *
                    riskAssetValue()) / totalValue();
    }

    function portfolioPercentageDecimals() internal view returns (uint8) {
        return riskAssetFeed.decimals();
    }

    // calculate the LP tokens for a deposit of 'amount' tokens after the deposit tokens have been transferred into the pool
    function lpTokensForDeposit(uint256 amount) internal view returns (uint256) {

        uint256 depositLPTokens;
        if (lpToken.totalSupply() == 0) {
            /// If pool is empty  => allocate the inital LP tokens amount to the user
            depositLPTokens = amount;
        } else {
            ///// if there are already LP tokens => calculate the additional LP tokens for this deposit
            // calculate portfolio % of the deposit (using lpPrecision digits precision)
            uint256 lpPrecision = 10**uint256(lpToken.decimals());
            uint256 portFolioPercentage = (lpPrecision * amount) / totalValue();

            // calculate the amount of LP tokens for the deposit so that they represent
            // a % of the existing LP tokens equivalent to the % value of this deposit to the whole portfolio value.
            //
            // X := P * T / (1 - P)
            //      X: additinal LP toleks to allocate to the user to account for this deposit
            //      P: Percentage of portfolio accounted by this deposit
            //      T: total LP tokens allocated before this deposit

            depositLPTokens = (portFolioPercentage * lpToken.totalSupply()) / ((1 * lpPrecision) - portFolioPercentage);
        }

        return depositLPTokens;
    }

    /**
     * @notice Withdraw 'amount' of LP tokens from the pool and receive the equivalent amount of deposit tokens
     *         If fees are due, those are deducted from the LP amount before processing the withdraw.
     *
     * @param amount the amount of LP tokent to withdraw
     */
    function collectFeeAndWithdraw(uint256 amount) internal {

        require(lastTransactionTimestamp < block.timestamp, "PoolV4: Invalid withdrawal");

        lastTransactionTimestamp = block.timestamp;

        uint256 fees = feesForWithdraw(amount, msg.sender);
        uint256 netAmount = amount - fees;

        // transfer fees to Pool by burning the and minting lptokens to the pool
        if (fees > 0) {
            lpToken.burn(msg.sender, fees);
            lpToken.mint(address(this), fees);
        }

        _withdrawLP(netAmount);
    }

    /**
     *   @notice Burns the 'amount' of LP tokens and sends to the sender the equivalent value in deposit tokens.
     *           If withdrawal producesa a swap with excessive slippage the transaction will be reverted.
     *   @param amount the amount of LP tokent being withdrawn.
     */
    function _withdrawLP(uint256 amount) internal {
        if (amount == 0) return;

        require(amount <= lpToken.balanceOf(msg.sender), "PoolV4: LP balance exceeded");

        uint256 precision = 10**uint256(portfolioPercentageDecimals());
        uint256 withdrawPerc = (precision * amount) / lpToken.totalSupply();

        // 1. Calculate amount of depositTokens & investTokens to withdraw
        uint256 depositTokensBeforeSwap = depositToken.balanceOf(address(this));
        uint256 investTokensBeforeSwap = investToken.balanceOf(address(this));
        
        // if these are the last LP being withdrawn ensure no dust tokens are left in the pool
        bool isWithdrawAll = (amount == lpToken.totalSupply());
        uint256 withdrawDepositTokensAmount = isWithdrawAll ? depositTokensBeforeSwap : (depositTokensBeforeSwap * withdrawPerc) / precision;
        uint256 withdrawInvestTokensTokensAmount = isWithdrawAll ? investTokensBeforeSwap : (investTokensBeforeSwap * withdrawPerc) / precision;

        // 2. burn the user's LP tokens
        lpToken.burn(msg.sender, amount);

        // 3. swap some invest tokens back into deposit tokens
        uint256 depositTokensReceived = 0;
        if (withdrawInvestTokensTokensAmount > 0) {
            uint256 amountOutMin = swapRouter.getAmountOutMin(address(investToken), address(depositToken), withdrawInvestTokensTokensAmount, feeV3);
            (, uint256 slippage) = slippagePercentage(address(investToken), address(depositToken), withdrawInvestTokensTokensAmount);
            depositTokensReceived = swap(address(investToken), address(depositToken), withdrawInvestTokensTokensAmount, amountOutMin, address(this));

            emit Swapped("SELL", withdrawInvestTokensTokensAmount, depositTokensReceived, slippage);
        }

        // 4. transfer depositTokens to the user
        uint256 amountToWithdraw = withdrawDepositTokensAmount + depositTokensReceived;

        withdrawals[msg.sender] += amountToWithdraw;
        totalWithdrawn += amountToWithdraw;
        userInfos[msg.sender].push(
            UserInfo({
                timestamp: block.timestamp,
                operation: UserOperation.WITHDRAWAL,
                amount: amountToWithdraw
            })
        );

        depositToken.transfer(msg.sender, amountToWithdraw);

        emit Withdrawn(msg.sender, amountToWithdraw);
    }


    // STRATEGY EXECUTION //

    /**
     * 
     */
    function handleTwapSwap() internal {
        
        // determine swap size avoiding very small amounts that would not be possible to swap
        // end ensuring the whole total amount gets swapped
        uint256 size = (twapSwaps.total > twapSwaps.sold + (2 * twapSwaps.size)) ? twapSwaps.size
            : (twapSwaps.total > twapSwaps.sold) ? twapSwaps.total - twapSwaps.sold : 0;

        if (size > 0) {

            (uint256 sold, uint256 bought, uint256 slippage) = swapIfNotExcessiveSlippage(
                twapSwaps.tokenIn, 
                twapSwaps.tokenOut, 
                twapSwaps.side,
                size
            );

            twapSwaps.lastSwapTimestamp = block.timestamp;
            string memory side = (twapSwaps.side == StrategyAction.BUY)
                ? "BUY"
                : (twapSwaps.side == StrategyAction.SELL)
                ? "SELL"
                : "NONE";

            if (sold > 0 && bought > 0) {
                twapSwaps.sold += sold;
                twapSwaps.bought += bought;
                if (twapSwaps.sold == twapSwaps.total) {
                    // log that the twap swap has been fully executed
                    SwapInfo memory info = swapInfo(
                        side,
                        twapSwaps.sold,
                        twapSwaps.bought
                    );
                    swaps.push(info);
                }
            }

            emit Swapped(side, sold, bought, slippage);
        }
    }

    /**
     * Exec the strategy and start a TWAP swap if a swap is needed
     */
    function strategyExec() internal {

        (StrategyAction action, uint256 amountIn) = strategy.exec();

        if (action != StrategyAction.NONE && amountIn > 0) {
            address tokenIn;
            address tokenOut;
            AggregatorV3Interface feed;

            if (action == StrategyAction.BUY) {
                tokenIn = address(depositToken);
                tokenOut = address(investToken);
                feed = stableAssetFeed;
            } else if (action == StrategyAction.SELL) {
                tokenIn = address(investToken);
                tokenOut = address(depositToken);
                feed = riskAssetFeed;
            }

            (
                ,
                /*uint80 roundID**/
                int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
                ,
                ,

            ) = feed.latestRoundData();
            require(price > 0, "PoolV4: negative price");
            twapSwaps = twapSwapsInfo(
                action,
                tokenIn,
                tokenOut,
                amountIn,
                uint256(price),
                feed.decimals()
            );

            handleTwapSwap();
        }
    }

    // Swap Execution //

    /**
     * @notice uses SwapsRouter to performa a single swap 'amountOutMin' of tokenIn into tokenOut.
     *          It does not check slippage and it's not expected to revert
     * @return amountOut the amount received from the swap
     */
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address recipent) internal returns (uint256 amountOut) {
        if (amountIn > 0 && amountOutMin > 0) {
            IERC20Metadata token = tokenIn == address(depositToken) ? depositToken : investToken;
            token.approve(address(swapRouter), amountIn);
            try swapRouter.swap(tokenIn, tokenOut, amountIn, amountOutMin, recipent, feeV3) returns (uint256 received) {
                amountOut = received;
            } catch Error(string memory reason) {
                // log catch failing revert() and require()
                emit SwapError(reason);
            } catch (bytes memory reason) {
                // catch failing assert()
                emit SwapError(string(reason));
            }
        }
    }

    /**
     * @return size of the TWAP swaps.
     * The TWAP size is determined by dividing the deised swap size (amountIn) by 2 up to 8 times
     * or until TWAP size is below swapMaxValue.
     * If, for example, swapMaxValue is set to $20k, it would take 256 TWAP swaps to process a $5m swap.
     * A $1m Swap would be processed in 64 TWAP swaps of $15,625 each.
     */
    function twapSwapsInfo(StrategyAction side, address tokenIn, address tokenOut, uint256 amountIn, uint256 price, uint8 feedDecimals) internal view returns (TWAPSwap memory) {
        IERC20Metadata token = tokenIn == address(depositToken)
            ? depositToken
            : investToken;

        uint256 swapValue = amountIn.mul(uint256(price), token.decimals(), feedDecimals, depositToken.decimals());

        // if the value of the swap is less than swapMaxValue than we can swap in one go.
        // otherwise break the swap into chunks.
        if (swapValue <= swapMaxValue)
            return
                TWAPSwap({
                    side: side,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    total: amountIn,
                    size: amountIn,
                    sold: 0,
                    bought: 0,
                    lastSwapTimestamp: 0
                });

        // determine the size of each chunk
        uint256 size = amountIn;
        uint8 i = 0;
        do {
            size /= 2;
            swapValue /= 2;
        } while (++i < 8 && swapValue > swapMaxValue);

        return
            TWAPSwap({
                side: side,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                total: amountIn,
                size: size == 0 ? amountIn : size,
                sold: 0,
                bought: 0,
                lastSwapTimestamp: 0
            });
    }

    /**
     * Perform a swap as part of processing a potentially larger TWAP swap.
     * if max slippage is exceeded the swap does not happen.
     * @param tokenIn the token being sold
     * @param tokenOut the token being bought
     * @param side the side of the swap (e.g Buy or Sell)
     * @param amountIn the amount of tokens to sell. Expected to be > 0
     */
    function swapIfNotExcessiveSlippage (
        address tokenIn,
        address tokenOut,
        StrategyAction side,
        uint256 amountIn
    ) internal returns (
            uint256 sold,
            uint256 bought,
            uint256 slppgg
        )
    {
        // ensure max slippage is not exceeded
        (uint256 amountOutMin, uint256 slippage) = slippagePercentage(tokenIn, tokenOut, amountIn);

        if (slippage > slippageThereshold) {
            string memory sideName = (side == StrategyAction.BUY)
                ? "BUY"
                : (side == StrategyAction.SELL)
                ? "SELL"
                : "NONE";

            emit MaxSlippageExceeded(sideName, amountIn, amountOutMin, slippage);
            return (0, 0, slippage);
        }

        // esnure swap returns some amount
        if (amountOutMin == 0) {
            emit InvalidAmount();
            return (0, 0, slippage);
        }

        uint256 depositTokenBalanceBefore = depositToken.balanceOf(address(this));
        uint256 investTokenBalanceBefore = investToken.balanceOf(address(this));

        swap(tokenIn, tokenOut, amountIn, amountOutMin, address(this));

        uint256 depositTokenBalanceAfter = depositToken.balanceOf(address(this));
        uint256 investTokenBalanceAfter = investToken.balanceOf(address(this));

        if (side == StrategyAction.BUY) {
            sold = depositTokenBalanceBefore - depositTokenBalanceAfter;
            bought = investTokenBalanceAfter - investTokenBalanceBefore;
        } else if (side == StrategyAction.SELL) {
            sold = investTokenBalanceBefore - investTokenBalanceAfter;
            bought = depositTokenBalanceAfter - depositTokenBalanceBefore;
        }

        return (sold, bought, slippage);
    }

    /**
     * @return amountOutMin the min amount of tokenOut to accept based on max allowed slippage from oracle prices
     */
    function slippagePercentage(address tokenIn, address tokenOut, uint256 amountIn) internal returns (uint256 amountOutMin, uint256 slippage) {
        (
            ,
            /*uint80 roundID**/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = riskAssetFeed.latestRoundData();

        // if received a negative price the return amountOutMin = 0 to avoid swap
        if (price < 0) return (0, 0);

        uint256 amountExpected = 0;

        // swap USD => ETH
        if (tokenIn == address(depositToken) && tokenOut == address(investToken)) {
            amountExpected = amountIn.div(uint256(price), depositToken.decimals(), riskAssetFeed.decimals(), investToken.decimals());
        }

        // swap ETH => USD
        if (tokenIn == address(investToken) && tokenOut == address(depositToken)) {
            amountExpected = amountIn.mul(uint256(price), investToken.decimals(), riskAssetFeed.decimals(), depositToken.decimals());
        }

        amountOutMin = swapRouter.getAmountOutMin(tokenIn, tokenOut, amountIn, feeV3);

        if (amountOutMin >= amountExpected) return (amountOutMin, 0);

        slippage = 10000 - ((10000 * amountOutMin) / amountExpected); // e.g 10000 - 9500 = 500  (5% slippage) - min slipage: 1 = 0.01%

        uint256 minAmountAccepted = ((10000 - slippageThereshold) * amountExpected) / 10000;

        // receive from the swap an amount of tokens compatible with our max slippage
        amountOutMin = minAmountAccepted > amountOutMin ? minAmountAccepted : amountOutMin;
    }

    function swapInfo(string memory side, uint256 amountIn, uint256 amountOut) internal view returns (SwapInfo memory) {
        (
            ,  /*uint80 roundID**/
            int256 price,
            , /*uint startedAt*/
            ,  /*uint80 answeredInRound*/ 
            /*uint timeStamp*/
        ) = riskAssetFeed.latestRoundData();

        // Record swap info
        SwapInfo memory info = SwapInfo({
            timestamp: block.timestamp,
            side: side,
            feedPrice: uint256(price),
            bought: amountOut,
            sold: amountIn,
            depositTokenBalance: depositToken.balanceOf(address(this)),
            investTokenBalance: investToken.balanceOf(address(this))
        });

        return info;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;


enum StrategyAction { NONE, BUY, SELL }

interface IStrategy {
    function name() external view returns(string memory);
    function description() external view returns(string memory);
    function exec() external returns(StrategyAction action, uint amount);
    function shouldPerformUpkeep() external view returns (bool);
    function setUpkeepInterval(uint innterval) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;


/**
*  Pool's functionality required by DAOOperations and DAOFarm
*/

interface ISwapsRouter {

    function getAmountOutMin(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 feeV3
    ) external returns (uint amountOut);

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient,
        uint24 feeV3
    ) external returns (uint amountOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

interface IUniswapV2Router {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn, //amount of tokens we are sending in
        uint amountOutMin, //the minimum amount of tokens we want out of the trade
        address[] calldata path,  //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address to,  //this is the address we are going to send the output tokens to
        uint deadline //the last time that the trade is valid for
    ) external returns (uint[] memory amounts);

    function WETH() external returns (address addr);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;


/**
 * @title TokenMaths
 * @dev Library for simple arithmetics operations between tokens of different decimals, up to 18 decimals.
 */
library TokenMaths {

    /**
     * @notice division between 2 token amounts with different decimals. Assumes decimals1 <= 18 and decimals2 <= 18.
     * The returns value is provided with decimalsOut decimals.
     */
    function div(uint amount1, uint amount2, uint8 decimals1, uint8 decimals2, uint8 decimalsOut) internal pure returns (uint) {
        return (10 ** decimalsOut * toWei(amount1, decimals1) / toWei(amount2, decimals2));
    }


    /**
     * @notice multiplication between 2 token amounts with different decimals. Assumes decimals1 <= 18 and decimals2 <= 18.
     * The returns value is provided with decimalsOut decimals.
     */
    function mul(uint amount1, uint amount2, uint8 decimals1, uint8 decimals2, uint8 decimalsOut) internal pure returns (uint) {
       return 10 ** decimalsOut * amount1 * amount2 / 10 ** (decimals1 + decimals2);
    }


    /**
     * @notice converts an amount, having less than 18 decimals, to to a value with 18 decimals.
     * Otherwise returns the provided amount unchanged.
     */
    function toWei(uint amount, uint8 decimals) internal pure returns (uint) {

        if (decimals >= 18) return amount;

        return amount * 10 ** (18 - decimals);
    }


    /**
     * @notice converts an amount, having 18 decimals, to to a value with less than 18 decimals.
     * Otherwise returns the provided amount unchanged.
     */
    function fromWei(uint amount, uint8 decimals) internal pure returns (uint) {

        if (decimals >= 18) return amount;

        return amount / 10 ** (18 - decimals);
    }

}