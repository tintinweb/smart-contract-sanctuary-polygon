/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: MEME.sol


pragma solidity ^0.8.9;





contract MEME is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("MEME", "MEME") {
        _mint(msg.sender, 50000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// File: DEX.sol


pragma solidity ^0.8.19;





contract DEX is Pausable, Ownable {
    struct Stack_Struct {
        uint256 meme_amount;
        uint256 eth_amount;
        uint256 time;
    }
    ERC20 meme;

    event Buy(address indexed from, uint256 Meme_amount, uint256 eth_amount);
    event Sell(address indexed from, uint256 Meme_amount, uint256 eth_amount);
    event Stack(address indexed from, uint256 Meme_amount, uint256 eth_amount);
    event UnStack(
        address indexed from,
        uint256 Meme_amount,
        uint256 eth_amount
    );

    mapping(address => Stack_Struct[]) internal Stacked;

    mapping(uint256 => uint256) public dailyTax;

    uint256 public stackingRate;

    uint256 public _k;
    uint256 public _x;
    uint256 public _y;

    uint256 public precision = 10e18;

    uint256 public taxRate = (3 * precision) / 10;

    constructor(address addr) {
        meme = MEME(addr);

        //_stack(10000000, 10000000);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _updateK() internal {
        _k = _x * _y;
    }

    function getStacks() public view returns (Stack_Struct[] memory) {
        return Stacked[msg.sender];
    }

    function stack(uint256 meme_amount) public payable {
        require(meme_amount > 0, "Send more MEME");
        require(msg.value > 0, "Send more ETH");
        require(
            stackingRate <= (msg.value * precision) / meme_amount,
            "Stacking Rate not met"
        );
        _stack(meme_amount, msg.value);
    }

    function unstack(uint256 index) public {
        require(index >= 0, "Index can't be less then 0");
        _unstack(index);
    }

    function _stack(uint256 meme_amount, uint256 eth_amount) internal {
        meme.transferFrom(msg.sender, address(this), meme_amount);
        _x += meme_amount;
        _y += eth_amount;

        Stack_Struct memory ss = Stack_Struct(
            meme_amount,
            eth_amount,
            block.timestamp
        );
        Stacked[msg.sender].push(ss);

        stackingRate = ((_y * precision) / _x);

        _updateK();
        emit Stack(msg.sender, meme_amount, msg.value);
    }

    function _unstack(uint256 index) internal {
        Stack_Struct memory ss = Stacked[msg.sender][index];
        uint256 tax = _distributeTax();

        uint256 meme_to_return = ss.meme_amount;
        uint256 eth_to_return = ss.eth_amount + tax;

        require(
            meme.balanceOf(address(this)) >= meme_to_return,
            "Sorry Currently this contract doesn't have Meme to return, Check back Soon!"
        );
        require(
            address(this).balance >= eth_to_return,
            "Sorry Currently this contract doesn't have Eth to return, Check back Soon!"
        );

        _x -= meme_to_return;
        _y -= eth_to_return;

        meme.transfer(msg.sender, meme_to_return);
        payable(msg.sender).transfer(eth_to_return);

        if (_x == 0) {
            stackingRate = 0;
        } else {
            stackingRate = (_y * precision) / _x;
        }

        _removeArr(index);

        _updateK();
        emit UnStack(msg.sender, meme_to_return, eth_to_return);
    }

    function _removeArr(uint256 index) internal {
        require(index < Stacked[msg.sender].length, "Index out of bounds");
        for (uint256 i = index; i < Stacked[msg.sender].length - 1; i++) {
            Stacked[msg.sender][i] = Stacked[msg.sender][i + 1];
        }
        Stacked[msg.sender].pop();
    }

    function _distributeTax() internal view returns (uint256) {
        uint256 taxShare = 0;
        if (dailyTax[block.timestamp / 1 days] > 0) {
            Stack_Struct[] storage stacks = Stacked[msg.sender];
            uint256 numStacks = stacks.length;
            uint256 totalStackTime = 0;
            for (uint256 i = 0; i < numStacks; i++) {
                Stack_Struct memory ss = stacks[i];
                totalStackTime += (block.timestamp - ss.time);
            }
            for (uint256 i = 0; i < numStacks; i++) {
                Stack_Struct memory ss = stacks[i];
                uint256 poolShare = ((ss.meme_amount * precision) / _x);
                uint256 stackTime = (block.timestamp - ss.time);
                uint256 stackWeight = stackTime / totalStackTime;
                taxShare +=
                    (poolShare *
                        dailyTax[block.timestamp / 1 days] *
                        stackWeight) /
                    _k;
            }
        }
        return taxShare;
    }

    function getMemePrice(uint256 meme_amount) public view returns (uint256) {
        require(_k > 0, "Not enough liquidity");
        uint256 dx = 0;
        uint256 dy = 0;
        if (_y == 0) {
            dx = _k / 1 - meme_amount;
        } else {
            dx = _k / _y - meme_amount;
        }
        if (dx == 0) {
            dy = _k / 1;
        } else {
            dy = _k / dx;
        }
        uint256 eth_price_without_tax = dy - _y;
        uint256 eth_tax = (eth_price_without_tax * taxRate) / precision;

        uint256 eth_price_with_tax = eth_price_without_tax + eth_tax;
        return eth_price_with_tax;
    }

    function getETHPrice(uint256 eth_amount) public view returns (uint256) {
        require(_k > 0, "Not enough liquidity");
        uint256 dx = 0;
        uint256 dy = 0;
        if (_x == 0) {
            dy = _k / 1 - eth_amount;
        } else {
            dy = _k / _x - eth_amount;
        }
        if (dy == 0) {
            dx = _k / 1;
        } else {
            dx = _k / dy;
        }
        uint256 meme_price_without_tax = dx - _x;
        uint256 meme_tax = (meme_price_without_tax * taxRate) / precision;

        uint256 meme_price_with_tax = meme_price_without_tax - meme_tax;

        return meme_price_with_tax;
    }

    function buy(uint256 meme_amount) public payable {
        require(meme_amount > 0, "Send Some Meme");
        uint256 meme_price = getMemePrice(meme_amount);
        require(meme_price <= msg.value, "Send More ETH");

        meme.transfer(msg.sender, meme_amount);
        payable(msg.sender).transfer(msg.value - meme_price);

        dailyTax[block.timestamp / 1 days] +=
            (meme_amount * (precision + taxRate)) /
            precision;

        _x -= meme_amount;
        _y = (_k / _x);

        emit Buy(msg.sender, meme_amount, meme_price);
    }

    function sell(uint256 eth_amount) public {
        require(eth_amount > 0, "Send Some ETH");
        uint256 eth_price = getETHPrice(eth_amount);

        require(eth_price <= meme.balanceOf(msg.sender), "You don't have enough meme");
        meme.transferFrom(msg.sender, address(this), eth_price);
        payable(msg.sender).transfer(eth_amount);

        dailyTax[block.timestamp / 1 days] +=
            (eth_price * (precision + taxRate)) /
            precision;

        _y -= eth_amount;
        _x = (_k / _y);

        emit Sell(msg.sender, eth_price, eth_amount);
    }

    // function secondsToDays(uint256 second) public pure returns (uint256) {
    //     return second / 1 days;
    // }

    // function check(uint256 index) public view returns (uint256) {
    //     Stack_Struct memory ss = Stacked[msg.sender][index];

    //     uint256 timestamp = block.timestamp - ss.time;
    //     uint256 poolShare = ((ss.meme_amount * taxRate * timestamp) / _x);

    //     return poolShare;
    // }
}

// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "MEME.sol";

// struct Stack_Struct {
//     uint256 meme_amount;
//     uint256 eth_amount;
//     uint256 time;
//     uint256 stackingRate;
// }

// contract DEX is Pausable, Ownable {
//     ERC20 meme;

//     mapping(address => Stack_Struct) public Stacked;

//     uint256 public stackingRate;

//     uint256 public _k;
//     uint256 public _x;
//     uint256 public _y;

//     uint256 public precision = 10**18;

//     constructor(address addr) {
//         meme = MEME(addr);

//         //_stack(10000000, 10000000);
//     }

//     function pause() public onlyOwner {
//         _pause();
//     }

//     function unpause() public onlyOwner {
//         _unpause();
//     }

//     function _updateK() internal {
//         _k = _x * _y;
//     }

//     function stack(uint256 meme_amount) public payable {
//         require(0 < msg.value , "Eth can't be 0");
//         require(0 < meme_amount , "Meme can't be 0");
//         // if(Stacked[msg.sender].stackingRate != 0){
//         // }
//         require(stackingRate <= ((msg.value * precision) / meme_amount));
//         _stack(meme_amount);
//     }

//     function unstack(uint256 meme_amount) public {
//         require(0 < meme_amount , "Meme can't be 0");

//         uint256 eth_amount2 = ((Stacked[msg.sender].stackingRate * meme_amount) / precision);
//         _unstack(meme_amount, eth_amount2, msg.sender);
//     }

//     function _stack(uint256 meme_amount) internal {
//         meme.transferFrom(msg.sender, address(this), meme_amount);

//         _x += meme_amount;
//         _y += msg.value;

//         Stacked[msg.sender].meme_amount += meme_amount;
//         Stacked[msg.sender].eth_amount += msg.value;
//         Stacked[msg.sender].time = block.timestamp;

//         Stacked[msg.sender].stackingRate = ((_y * precision) / _x);
//         stackingRate = Stacked[msg.sender].stackingRate;

//         _updateK();
//     }

//     function _unstack(
//         uint256 meme_amount,
//         uint256 eth_amount,
//         address to
//     ) public {
//         _x -= meme_amount;
//         _y -= eth_amount;

//         Stacked[to].meme_amount -= meme_amount;
//         Stacked[to].eth_amount -= eth_amount;
//         Stacked[to].time = block.timestamp;

//         meme.transfer(to, meme_amount);
//         payable(to).transfer(eth_amount);

//         if (_x == 0) {
//             Stacked[msg.sender].stackingRate = 0;
//             stackingRate = 0;
//         } else {
//             Stacked[msg.sender].stackingRate = (_y * precision) / _x;
//             stackingRate = Stacked[msg.sender].stackingRate;
//         }

//         _updateK();
//     }

//     // function _buy(uint128 meme_amount) public payable {
//     //     uint dx = meme_amount;
//     //     uint dy = _y;

//     //     _x += dx;
//     //     _y = _k / _x;

//     //     dy -= _y;

//     //     memeBalance += dx;
//     //     ethBalance -= dy;
//     // }

//     // function _sell(uint128 meme_amount) public payable {
//     //     uint256 dx = meme_amount;
//     //     uint256 dy = _y;

//     //     _x -= dx;
//     //     _y = _k / _x;

//     //     dy = _y - dy;

//     //     memeBalance -= dx;
//     //     ethBalance += dy;
//     // }
// }