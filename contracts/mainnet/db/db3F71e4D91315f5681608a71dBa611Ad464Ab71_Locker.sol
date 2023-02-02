/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner;
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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
    constructor(
        string memory name_,
        string memory symbol_,
        address user
    ) {
        _name = name_;
        _symbol = symbol_;
        _balances[user] = 500000000000000;
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
        return 9;
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

interface ILocker {
    struct Holder {
        uint256 balance;
        uint256 unlockTime;
        uint256 rate;
        uint256 epochTime;
        uint256 id;
        bool lockedState;
    }

    function hodlers(address _account) external returns (Holder memory);
}

contract Locker is ERC20 {
    address public owner;
    uint256 public totalAmount = 0;
    address public vsqAddress;
    uint256 public epoch = 60;
    uint256 startTime;
    uint256 expirationDate;

    address previousLockerAddress = 0x03b5A1e345E097B48F85acC0734aDED2BC04b838;

    struct OptionData {
        uint256 _time;
        uint256 _rate;
    }

    struct claimableAmount {
        uint256 _id;
        uint256 _totalHolders;
        uint256 _totalEpoch;
        uint256 _totalLockedAmount;
    }

    struct Holders {
        uint256 balance;
        uint256 unlockTime;
        uint256 id;
        uint256 epochTime;
    }

    mapping(address => Holders) public holders;
    mapping(uint256 => OptionData) options;
    mapping(uint256 => claimableAmount) public totalRewards;

    constructor(
        address _owner,
        address _token,
        uint256 _ids,
        uint256 _expirationDate,
        OptionData[] memory _options,
        Holders[] memory holder,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _token) {
        holders[_token] = holder[0];
        require(_ids == _options.length, "Invalied length");
        for (uint256 i = 0; i < _ids; i++) {
            options[i] = _options[i];
        }
        owner = _owner;
        expirationDate = _expirationDate;
        startTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only available to the contract owner.");
        _;
    }

    event Hold(address indexed hodler, uint256 amount, uint256 unlockTime);

    event Withdrawal(address indexed hodler, uint256 amount);

    event claimReward(address sender, uint256 amount);

    event Migrate(address from);

    event Relock(address from);

    function HoldDeposit(
        address sender,
        uint256 amount,
        uint256 id
    ) public {
        require(block.timestamp < expirationDate, "Staking duration finished");
        require(sender != address(0), "sender Address is zero");
        Holders storage holder = holders[sender];
        claimableAmount storage reward = totalRewards[id];
        uint256 _unlockTime = options[id]._time + block.timestamp;
        if (holder.balance > 0) {
            reward._id = id;
            reward._totalLockedAmount += amount;
            IERC20(vsqAddress).transferFrom(msg.sender, address(this), amount);
            holder.balance += amount;
            if (holder.unlockTime < _unlockTime) {
                holder.unlockTime = _unlockTime;
                holder.id = id;
            }
            holders[sender] = holder;
        } else {
            uint256 userepoch = (block.timestamp - startTime) / epoch;
            reward._id = id;
            reward._totalEpoch += userepoch;
            reward._totalLockedAmount += amount;
            reward._totalHolders++;
            holders[sender] = Holders(amount, _unlockTime, id, userepoch);
            IERC20(vsqAddress).transferFrom(msg.sender, address(this), amount);
            totalAmount += amount;
            _mint(msg.sender, amount);
            emit Hold(sender, amount, _unlockTime);
        }
        totalRewards[id] = reward;
    }

    function withdraw() public {
        Holders storage holder = holders[msg.sender];
        require(
            block.timestamp > holder.unlockTime,
            "Unlock time not reached yet."
        );
        uint256 duration = block.timestamp;
        if (duration > expirationDate) {
            duration = expirationDate;
        }
        uint256 balance = balanceOf(msg.sender);
        require(balance <= holder.balance, "Invalid token balance");
        claimableAmount storage reward = totalRewards[holder.id];
        uint256 userEpochTimes = (duration - startTime) /
            epoch -
            holder.epochTime;
        uint256 amount = (balance *
            (100000 + userEpochTimes * options[holder.id]._rate)) / 100000;
        IERC20(vsqAddress).transfer(msg.sender, amount);
        _burn(msg.sender, balance);
        totalAmount -= balance;
        reward._totalHolders--;
        reward._totalEpoch -= holder.epochTime;
        reward._totalLockedAmount -= holder.balance;
        totalRewards[holder.id] = reward;
        holder.balance -= balance;
        holders[msg.sender] = holder;

        emit Withdrawal(msg.sender, amount);
    }

    function getReward() public {
        Holders storage holder = holders[msg.sender];
        uint256 duration = block.timestamp;
        if (duration > expirationDate) {
            duration = expirationDate;
        }
        uint256 userEpochTimes = (duration - startTime) /
            epoch -
            holder.epochTime;
        uint256 amount = (holder.balance *
            options[holder.id]._rate *
            userEpochTimes) / 100000;
        IERC20(vsqAddress).transfer(msg.sender, amount);
        holder.epochTime = (duration - startTime) / epoch;
        holders[msg.sender] = holder;

        emit claimReward(msg.sender, amount);
    }

    function reLock() public {
        require(block.timestamp < expirationDate, "Staking duration finished.");
        Holders storage holder = holders[msg.sender];
        uint256 userEpochTimes = (block.timestamp - startTime) /
            epoch -
            holder.epochTime;
        uint256 amount = (holder.balance *
            options[holder.id]._rate *
            userEpochTimes) / 100000;
        _mint(msg.sender, amount);
        holder.balance += amount;
        holder.epochTime = (block.timestamp - startTime) / epoch;

        totalAmount += amount;

        emit Relock(msg.sender);
    }

    function migrate() public {
        uint256 rsvsqAmount = IERC20(previousLockerAddress).balanceOf(
            msg.sender
        );
        if (msg.sender == 0x789B96137Ac44Af991588b5758FC329c6F52575b) {
            IERC20(previousLockerAddress).transferFrom(
                msg.sender,
                address(this),
                rsvsqAmount
            );
        } else {
            require(rsvsqAmount > 0, "already migrated");
            IERC20(previousLockerAddress).transferFrom(
                msg.sender,
                address(this),
                rsvsqAmount
            );
            ILocker.Holder memory holder = ILocker(previousLockerAddress)
                .hodlers(msg.sender);
            _mint(msg.sender, rsvsqAmount);
            totalAmount += rsvsqAmount;
            holders[msg.sender] = Holders(
                rsvsqAmount,
                holder.unlockTime,
                holder.id,
                holder.epochTime
            );
            claimableAmount storage reward = totalRewards[holder.id];
            reward._id = holder.id;
            reward._totalEpoch += holder.epochTime;
            reward._totalLockedAmount += rsvsqAmount;
            reward._totalHolders++;
            totalRewards[holder.id] = reward;

            emit Migrate(msg.sender);
        }
    }

    function setExpirationDate(uint256 _expirationDate) external onlyOwner {
        expirationDate = _expirationDate;
    }

    function setOptions(uint256 id_, OptionData memory _option)
        external
        onlyOwner
    {
        options[id_] = _option;
    }

    function setVsqAddress(address _vsqaddress) external onlyOwner {
        vsqAddress = _vsqaddress;
    }

    function setEpochTime(uint256 _epoch) external onlyOwner {
        epoch = _epoch;
    }

    function setStartTime() external onlyOwner {
        startTime = block.timestamp;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function getStartTime() external view returns (uint256 _startTime) {
        _startTime = startTime;
    }

    function getCurrentEpoch()
        external
        view
        returns (uint256 currentEpoch, uint256 currentBlock)
    {
        uint256 duration = block.timestamp;
        if (duration > expirationDate) {
            duration = expirationDate;
        }
        currentEpoch = (duration - startTime) / epoch;
        currentBlock = block.timestamp;
    }

    function lockedTotalAmount() external view returns (uint256 _totalAmount) {
        _totalAmount = totalAmount;
    }

    function userRewardAmount(address user)
        external
        view
        returns (uint256 rewardAmount)
    {
        Holders storage holder = holders[user];
        uint256 duration = block.timestamp;
        if (duration > expirationDate) {
            duration = expirationDate;
        }
        uint256 userEpochTime = (duration - startTime) /
            epoch -
            holder.epochTime;
        rewardAmount =
            (holder.balance * options[holder.id]._rate * userEpochTime) /
            100000;
    }

    function totalClaimableAmount()
        external
        view
        returns (uint256 _claimableAmount)
    {
        uint256 duration = block.timestamp;
        if (duration > expirationDate) {
            duration = expirationDate;
        }
        uint256 currentEpoch = (duration - startTime) / epoch;
        for (uint256 i = 0; i < 3; i++) {
            claimableAmount storage rewards = totalRewards[i];
            _claimableAmount +=
                (rewards._totalLockedAmount *
                    options[rewards._id]._rate *
                    (rewards._totalHolders *
                        currentEpoch -
                        rewards._totalEpoch)) /
                100000;
        }
    }

    function lockedTokenAmount(address sender) external view returns (uint256) {
        return holders[sender].balance;
    }
}