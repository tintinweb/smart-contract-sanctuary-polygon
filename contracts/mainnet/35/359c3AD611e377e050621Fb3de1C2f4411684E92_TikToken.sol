/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

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

// File: contracts/TikToken.sol



// The Solidity version of the contract is set to 0.8.9
pragma solidity ^0.8.9;

// Import ERC20 and Ownable contracts from the OpenZeppelin library



// Define the contract named "TikToken" which extends the ERC20 and Ownable contracts using a 18 decimal token
// Depreciated the 24 decimal contract for the 18 decimal contract in the interest of maximum wallet compatibility
contract TikToken is ERC20, Ownable {

    // Define several private constants and variables related to the tokenomics of TikToken
    // _maxSupply represents the total supply of TikTokens that will ever exist
    // _initialSupply represents the initial non-owner supply at the time of contract deployment
    // _minReward represents the minimum reward that will be given out for minting tokens
    // _followerSet is how many followers are considered a set, in my initial concept it was 1000
    // _remainingSupply is a rolling value of the remaining TikTokens that can be minted
    // _currentReward represents the current reward that is given for each set of followers
    // _halvingCount keeps track of the number of times the reward has been halved
    // _nextHalving keeps track of the next halving supply amount
    // _allUsersEarn determines whether the follower is rounded up or down to the nearest set of followers
    uint256 private constant _maxSupply = 1 * 10**18;
    uint256 private constant _initialSupply = 0.8192 * 10**18;
    uint256 private constant _minReward = 1;
    uint256 private constant _followerSet = 1000;
    uint256 private constant _rewardReduction = 10;
    bool private _allUsersEarn = true;
    uint256 private _remainingSupply = _initialSupply;
    uint256 private _currentReward = 0.00001 * 10**18;
    uint256 private _halvingCount = 1;
    uint256 private _nextHalving = _initialSupply / (2 ** _halvingCount);
    uint256 private _userCounter = 0;

    // Mapping to keep track of each unique TikTok user ID that has minted tokens
    mapping(string => bool) private _minted;
    // Mapping to associate user addresses with their IDs
    mapping(address => string[]) private _userIDs;
    // Mapping to associate user ID with their addresses for the TikTok Domain Service
    mapping(string => address) private _userAddress;

    // Contract Events
    event Minted(address account, uint256 amount, string id, uint256 followers);
    event HalvingOccurred(uint256 halvingCount, uint256 currentReward, uint256 remainingSupply);
    event AddressUpdated(string id, address oldAccount, address newAccount);

    // Constructor function that initializes the TikToken contract
    // Mints initial tokens and sends them to the contract owner
    constructor() ERC20("TikToken", "TIK") {
        uint256 initialMintAmount = _maxSupply - _initialSupply;
        _mint(msg.sender, initialMintAmount);
    }

    // Functions prevent Owner from dumping tokens before first halving
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_halvingCount > 1 || msg.sender != owner(), "Owner transfer locked until first halving");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_halvingCount > 1 || msg.sender != owner(), "Owner transfer locked until first halving");
        return super.transferFrom(sender, recipient, amount);
    }

    function calculateRewards(uint256 followers) private view returns (uint256) {
        uint256 baseReward = _allUsersEarn ? _currentReward : 0; //if all users earn followers get rounded up to the next thousand so even with 0 followers you earn something if not the users with 1 follower set or more will earn
        uint256 amountToMint = (followers / _followerSet) * _currentReward + baseReward; //Rewards calculated based on follower count
        uint256 amountToHalving = _remainingSupply - _nextHalving; //calculates token supply until _nextHalving

        //Ensures a user with too many followers doesn't earn too much unless halving is complete
        if (amountToHalving <= amountToMint && _currentReward > _minReward) {
            uint256 preHalvingReward = amountToMint;
            amountToMint = amountToHalving; //mint the remaining tokens in this halving cycle
            uint256 postHalvingReward = (preHalvingReward - amountToMint) / _rewardReduction; //mint remaining reward at the new _currentReward
            uint256 rewardMax = _nextHalving / 2;

            //ensure the remaining reward doesn't create a double halving event, this will also limit a potential exploit
            if (postHalvingReward >= rewardMax) {
                postHalvingReward = rewardMax - _currentReward; //create a buffer of 1 reward until the next halving, unfortunately this user will have rewards capped off, this can only happen to creators with mote than 10M followers.
            }
            amountToMint += postHalvingReward; //adds the additional reward to the mint amount
        }
        return amountToMint;
    }

    // Mint function allows the owner of the contract to mint tokens this is a owner function and this gives rise to a potential abuse of the function
    // This type of control means you must have alot of trust in the project and contract's owner espescially since there are no built-in follower limits
    // Fortunately there's a public getter function to audit the minting so it's associated with a user ID and anyone can check the minting.
    // It gives out a large amount of tokens to early adopters and gradually reduces the reward as more tokens are minted based on an agressive 1/10th halving policy
    // Each user can earn tokens based on the number of their followers and how many halving cycles have happened
    function mint(address account, uint256 followers, string calldata id) public onlyOwner{

        require(_remainingSupply > 0, "No more tokens to mint"); //Ensures supply exists
        require(!_minted[id], "User has already minted");
        require(followers > _followerSet || _allUsersEarn, "Not enough followers to mint");

        uint256 amountToMint = calculateRewards(followers);

        //reduces supply to remaining supply
        if (_remainingSupply < amountToMint) {
            amountToMint = _remainingSupply;
        }

        //mint the tokens, adjust remaining supply and log the user id
        _mint(account, amountToMint);
        _remainingSupply -= amountToMint;
        // Flag user ID as minted to prevent multiple minting
        _minted[id] = true;
        // Add the ID to the user's list of IDs and register a Web3 address
        _userCounter++;
        updateAddress(id, account);
        emit Minted(account, amountToMint, id, followers);

        //performs a halving function, adding a new 0 after the decimal place to the current reward per follower set assuming halving hasn't maxed out.
        if (_remainingSupply <= _nextHalving && _currentReward >= _rewardReduction) {
            _currentReward /= _rewardReduction; 
            _halvingCount++;
            _nextHalving = _initialSupply / (2 ** _halvingCount);

            // Checks if this is last halving and requires users have at least _followerSet
            if (_currentReward <= _minReward) {
                _allUsersEarn = false;
                _nextHalving = 0;
            }
            
            emit HalvingOccurred(_halvingCount, _currentReward, _remainingSupply);
        }
        if (_currentReward < _minReward) {
            _currentReward = _minReward;
        }
    }

    // Batch mint function allows the contract owner to mint tokens for multiple users at once
    // This function can save gas compared to calling the mint function individually for each user
    function batchMint(address[] calldata accounts, uint256[] calldata followers, string[] calldata ids) external onlyOwner {
        require(accounts.length == followers.length, "Mismatched input arrays");
        require(accounts.length == ids.length, "Mismatched input arrays");

        //loop over all items in the batch
        for (uint256 i = 0; i < accounts.length; i++) {

            mint(accounts[i], followers[i], ids[i]);

        }
    }

    // Update function allows users to update their wallet for the TikTok Name Service
    // This will allow a user to update the wallet associated with their ID, in future this could enable sending crypto tokens to a handle instead of an address
    function updateAddress(string calldata id, address account) public onlyOwner() {
        address oldAccount = _userAddress[id];
        emit AddressUpdated(id, oldAccount, account);
        _userAddress[id] = account;
        _userIDs[account].push(id);
    }

    // Getter functions to view the remaining supply of tokens, the current reward, the user's minted status, and the number of halvings, 
    // the IDs associated with a user's address and the address associated with an address.
    function remainingSupply() external view returns (uint256) {
        return _remainingSupply; //amount of TikTokens remaining to be minted
    }

    function currentReward() external view returns (uint256) {
        return _currentReward; //provides the the reward value per follower set also the minimum reward
    }

    function hasMinted(string calldata id) external view returns (bool) {
        return _minted[id]; //determines if the user has minted already
    }

    function getHalvingCount() external view returns (uint256) {
        return _halvingCount - 1; //provides the actual number of halvings the rewards have gone through
    }

    function getNextHalving() external view returns (uint256) {
        return _nextHalving; //provides the next halving
    }

    function getUserCounter() external view returns (uint256) {
        return _userCounter;
    }

    function getUserIDs(address account) external view returns (string[] memory) {
        return _userIDs[account];
    }

    // This getter function enables TDS for wallets wanting to use TikTok ID as an address
    function getUserAccount(string calldata id) external view returns (address) {
        return _userAddress[id];
    }
    
    // For now these features must remain immutable. Commented out because this gives the contract owner 
    // way too much unilateral control! This must be done as Governance using the community and only after 
    // the 3rd-5th halving to ensure fair distribution before such impactful changes can be made to the contract.
    // should evaluate how this roll out works before adding governance into a cantract.
    // // Set function allows the owner of the contract to change the _allUsersEarn variable
    // function setAllUsersEarn(bool value) external onlyOwner {
    //     _allUsersEarn = value;
    // }

    // // Set function allows the owner of the contract to change the _followerSet variable
    // function setFollowerSet(uint256 value) external onlyOwner {
    //     _followerSet = value;
    // }

    // Allows me to send the contract to another wallet debating on leaving this out for immutability 
    // Could be good if the wallet ever became compromised. Look into multi-sig for security.
    // function transferTIKOwnership(address newOwner) public onlyOwner {
    //     require(newOwner != address(0), "New owner is the zero address");
    //     transferOwnership(newOwner);
    // } 
}