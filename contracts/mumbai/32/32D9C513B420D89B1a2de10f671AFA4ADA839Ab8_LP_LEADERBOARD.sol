/**
 *Submitted for verification at polygonscan.com on 2023-05-30
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

// File: contracts/LP_LEADERBOARD.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title NEKO DEX LP_LEADERBOARD
/// @author gas-limit.eth
/// @notice This contract allows users to lock LP tokens and earn points based on the amount of time they have locked their LP tokens.
/// @notice getLeaderboard() returns all user scores in descending order

/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠔⠒⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠢⠤⢄⣀⠀⠀⠀⠀⠀⠀⠈⢢⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠨⠧⠀⠀⠀⠀⢀⡾⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⣀⠤⠔⠒⠉⠉⠁⠀⠀⢀⣀⠤⠴⠚⠉⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⡠⠖⠊⠁⠀⠀⣀⠠⠄⠒⠂⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢸⣴⠀⠀⠀⠰⡋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠉⠁⠒⠒⠒⠛⠓⠶⣒⠀⠀⠀⠠⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢀⣀⣤⠴⠶⠓⠓⢛⡟⠉⠉⢉⠽⠛⠓⠲⠦⣤⣄⡀⠀⠀⠀⠀⠀⠀
⠀⢀⣶⡟⠉⠀⠀⠀⣀⣖⣉⣠⣴⣮⣥⣀⣀⡀⠀⠀⠀⠉⠻⣶⡀⠀⠀⠀⠀
⠀⣾⣿⣧⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⣷⣤⣄⠀⣸⣇⣀⣀⡀⠀
⠀⢹⣿⣿⣿⣧⣿⣯⣭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣾⣿⠿⠿⢿⣿⠥⢄⠹⡄
⠀⠈⣿⣿⣿⣉⠉⠉⠛⠛⠛⠿⠟⠛⠛⠛⠛⠛⠉⠀⠀⠀⢠⡿⠁⠀⢸⠀⡇
⠀⠀⠘⣿⣿⣿⣤⡀⠀⠀⠀⠀N E K O⠀⠀⠀⢀⡞⠁⢀⡴⣋⠞⠁
⠀⠀⠀⠙⣿⣿⣿⣷⡆⢀⠀⠀D E X⠀⠀⠀⠀⣠⣿⡷⠭⠷⠊⠁⠀⠀
⠀⢀⣤⠶⠿⢻⣿⣿⣿⣷⣷⣦⣀⣀⣀⠀⡀⣀⣴⡞⠻⠶⣤⡀⠀⠀⠀⠀⠀
⣼⠋⠀⠀⢰⣿⣿⣿⣿⣿⣿⠿⠿⠿⠿⠟⣛⡏⠉⠻⡦⠀⠈⣿⡆⠀⠀⠀⠀
⣿⣜⢆⡀⠸⢿⢯⡉⢉⣉⠉⠉⠛⠋⠉⠉⠉⠀⣀⠜⠁⠀⠀⢋⡿⠀⠀⠀⠀
⠈⠙⠿⣿⣶⣦⣤⣈⣀⡀⠁⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣴⠶⠛⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠉⠙⠛⠻⠿⠿⠿⠿⠿⠿⠒⠒⠒⠚⠋⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀
*/

contract LP_LEADERBOARD {
    mapping(address => mapping(address => uint256)) public userLockedBalances; /// @notice user address -> token -> amount
    mapping(address => mapping(address => uint256)) public userLockTimes;  //user address -> token -> lock time
    mapping(uint256 => address) public userIdToAddress; /// @notice userId -> user address
    mapping(address => uint256) public addressToUserId; /// @notice user address -> userId
    uint256 public userIdCounter; /// @notice counter for userIds

    mapping(address => userScore) public userScores; /// @notice user address -> userScore

    address[] public LPTokens; /// @notice array of approved LP tokens


    /// @notice userScore struct
    struct userScore {
        address user; // user address
        uint256 score; // user score
    }


    
    /// @notice constructor
    /// @param _LPTokens array of approved LP tokens
    constructor(address[] memory _LPTokens){
        LPTokens = _LPTokens;
    }

    /// @notice checks if a token is an approved LP token
    /// @param _token token address
    function isLPToken(address _token) public view returns(bool isToken){
        address[] memory LPTokens_ = LPTokens; // gas optimization
        uint256 arrLength = LPTokens_.length; // gas optimization
        for(uint i; i < arrLength; i++){ /// @notice loop through array of approved LP tokens
            if(LPTokens_[i] == _token){ /// @notice if token is in array, return true
                isToken = true;
            }
        }
    }

    /// @notice deposit LP tokens into contract
    /// @param _token  token address
    /// @param _amount  amount of tokens to deposit
    function depositLP(address _token, uint256 _amount) public {
        require(isLPToken(_token), "Not an approved token");
        require(_amount > 0, "deposit amount must be more than 0");
        require(userLockedBalances[msg.sender][_token] == 0,"already locked");
        // require(userLocks[msg.sender][_token].unlockTime == 0, "already locked"); //redundant but yolo
        if(addressToUserId[msg.sender] != 0){
            require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "tx failed");
            userLockedBalances[msg.sender][_token] += _amount;
            userLockTimes[msg.sender][_token] = block.timestamp;
        }
        else {
            require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "tx failed");
            uint256 userIdCounter_ = ++userIdCounter;
            addressToUserId[msg.sender] = userIdCounter_;
            userIdToAddress[userIdCounter_] = msg.sender;
            userLockedBalances[msg.sender][_token]+=_amount;
            userLockTimes[msg.sender][_token] = block.timestamp;
        }
    }

    /// @notice withdraw LP tokens from contract
    /// @notice removes balnce of specified LP tokens from contract and adds score to user score struct
    /// @param _token  token address
    function withdrawLP(address _token) public {
        require(isLPToken(_token),"address is invalid!"); /// @notice check if token is approved
        uint256 amount = userLockedBalances[msg.sender][_token]; /// @notice get amount of tokens locked
        require(IERC20(_token).transfer(msg.sender, amount),"transfer failed"); /// @notice transfer tokens to user
        // userLocks[msg.sender][_token].unlockTime = block.timestamp; /// @notice set unlock time
        uint256 lockTime = userLockTimes[msg.sender][_token] = block.timestamp; /// @notice get lock time
        uint256 unlockTime = block.timestamp; /// @notice get unlock time
        /// score is calculated by subtracting the unlock time from the lock time, then multiplying by the amount of tokens locked, then dividing by 10 ** 16
        /// (lock time * amount of tokens locked) / 10 ** 16
        uint256 score = (((unlockTime - lockTime) * userLockedBalances[msg.sender][_token]) / 10 ** 16); /// @notice calculate score
        userScores[msg.sender].score +=  score; /// @notice add score to user score struct
        delete userLockedBalances[msg.sender][_token]; /// @notice delete user balance
    }

    /// @notice get user scor
    /// @dev user score is calculated by adding the amount of time each LP token has been locked for
    /// lock time is calculated by subtracting the unlock time from the lock time, then multiplying by the amount of tokens locked, then dividing by 10 ** 16
    /// (lock time * amount of tokens locked) / 10 ** 16
    function getIndividualScore() public view returns (uint256){
        uint256 estimatedScore = userScores[msg.sender].score;
        for(uint i; i < LPTokens.length; i++){
            address token = LPTokens[i];
            uint256 lockTime = userLockTimes[msg.sender][token];
            estimatedScore += userLockedBalances[msg.sender][token] * (block.timestamp - lockTime);
        }
       
        return estimatedScore / 10**16;
    } 

    /// @notice returns an array of userScore structs in descending order of score
    /// @dev leaderboard is calculated by adding the amount of time each LP token has been locked for
    /// lock time is calculated by subtracting the unlock time from the lock time, then multiplying by the amount of tokens locked, then dividing by 10 ** 16
    /// (lock time * amount of tokens locked) / 10 ** 16
    function getLeaderboard() public view returns (userScore[] memory) {
        userScore[] memory scores = new userScore[](userIdCounter);

        for (uint256 i = 1; i <= userIdCounter; i++) {
            address user = userIdToAddress[i];
            uint256 totalScore;
            for (uint256 j = 0; j < LPTokens.length; j++) {
                address token = LPTokens[j];
                uint256 lockTime = userLockTimes[msg.sender][token];
                totalScore += (userLockedBalances[user][token] * (block.timestamp - lockTime)) / 10 ** 16;
            }
            scores[i - 1] = userScore(user, totalScore);
        }

        // Sort scores in descending order
        for (uint256 i = 0; i < userIdCounter - 1; i++) {
            for (uint256 j = 0; j < userIdCounter - i - 1; j++) {
                if (scores[j].score < scores[j + 1].score) {
                    userScore memory temp = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = temp;
                }
            }
        }

        return scores ;
    }

    function getIndividualLockedBalance(address _tokenAddress) public view returns (uint256) {
        return userLockedBalances[msg.sender][_tokenAddress];
    }

}