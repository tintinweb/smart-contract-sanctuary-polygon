/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity 0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.5.17;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity 0.5.17;


/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

// File: contracts/Penton.sol

pragma solidity 0.5.17;

contract Penton is ERC20 {
    string public constant name = "PENTON";
    string public constant symbol = "PENTON";
    uint256 public constant initialSupply = 3 * (10 ** 9) * (10 ** uint256(decimals));
    uint256 private constant UNIX_DAY_TIME = 86400;
    uint8 public constant decimals = 18;

    constructor() public {
        address _owner = 0xA3CDa573593F5F2d73903aF82FDC3FEC4c9a525d;
        address _foundation = 0xAF63349f20e060e649412d94f619D445e3E0453A;        
        super._mint(_foundation, initialSupply);        
        owner = _owner;
    }

    /**
    *
    * Ownership features
    *
    */
    address public owner;
    address public potentialOwner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnerNominated(address indexed potentialOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
        potentialOwner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @notice Transfer Ownership will nominate a owner.
    * Ownership takes over when the nominated owner accepts ownership.
    * @param pendingOwner The address to transfer ownership to.
    */
    function transferOwnership(address pendingOwner) external onlyOwner {
        require(pendingOwner != address(0), "Potential owner can not be the zero address");
        potentialOwner = pendingOwner;
        emit OwnerNominated(pendingOwner);
    }

    /**
    * @dev Accept to transfer control of the contract to a potentialOwner.
    */
    function acceptOwnership() external {
        require(
            msg.sender == potentialOwner,
            "You must be nominated before you accept ownership"
        );
        emit OwnershipTransferred(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = address(0);
    } 
    
    /**
    *
    * Pause features
    *
    */
    event Pause();
    event Unpause();
    
    bool public paused = false;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Paused by owner");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Not paused");
        _;
    }
    
    /**
    * @dev Called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev Called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
    
    /**
    *
    * Freeze features
    *
    */
    event Frozen(address target);
    event Unfrozen(address target);

    mapping(address => bool) internal freezes;
    
    modifier whenNotFrozen() {
        require(!freezes[msg.sender], "Sender account is frozen");
        _;
    }

    /**
    * @dev Freeze the holder's address.
    * @param _target The address to freeze.
    */
    function freeze(address _target) public onlyOwner {
        freezes[_target] = true;
        emit Frozen(_target);
    }
    /**
    * @dev Unfreeze the holder's address.
    * @param _target The address to unfreeze.
    */
    function unfreeze(address _target) public onlyOwner {
        freezes[_target] = false;
        emit Unfrozen(_target);
    }

    /**
    * @dev Check if the holder's address is frozen.
    * @param _target The address to check.
    */
    function isFrozen(address _target) public view returns (bool) {
        return freezes[_target];
    }

    /**
    *
    * Transfer features
    *
    */

    /**
    * @dev Moves tokens from the caller's account to recipient.
    * @param _to The address of recipient.
    * @param _value Amount of tokens to transfer.
    */
    function transfer(address _to, uint256 _value)
        public
        whenNotFrozen
        whenNotPaused
        returns (bool)
    {
        _releaseLock(msg.sender);
        require(_value <= super.balanceOf(msg.sender), "Insufficient balance");
        return super.transfer(_to, _value);
    }

    /**
    * @dev Moves tokens from sender to recipient using the allowance mechanism.
    * @param _from The address of sender.
    * @param _to The address of recipient.
    * @param _value Amount of tokens to transfer.
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        require(!freezes[_from], "From account is frozen");
        _releaseLock(_from);
        require(_value <= super.balanceOf(_from), "Insufficient balance");
        return super.transferFrom(_from, _to, _value);
    }

    /**
    *
    * Burn features
    *
    */
    event Burn(address indexed burner, uint256 value);

    /**
    * @dev Destroys tokens from account, reducing the total supply.
    * @param _who The address to destroy tokens.
    * @param _value Amount of tokens to destroy.
    */
    function burn(address _who, uint256 _value) public onlyOwner {
        require(_value <= super.balanceOf(_who), "Insufficient balance");
        
        _burn(_who, _value);
        emit Burn(_who, _value);
    }

    /**
    *
    * Lock features
    *
    */
    struct LockInfo {
        uint256 releaseStartTime;
        uint256 releaseDays;
        uint256 unitValue;
        uint256 extraValue;
    }

    mapping(address => LockInfo[]) internal lockInfo;

    event Lock(address indexed holder, uint256 value, uint256 releaseTime);
    event Lock(
        address indexed holder,
        uint256 totalValue,
        uint256 releaseDays,
        uint256 releaseStartTime
    );
    event Unlock(address indexed holder, uint256 value);
    
    /**
    * @dev Returns the amount of tokens owned by the account.
    * @param _holder The address to check the balance.
    */
    function balanceOf(address _holder) public view returns (uint256) {
        uint256 lockedBalance = 0;
        uint256 length = lockInfo[_holder].length;
        for (uint256 i = 0; i < length; i++ ) {
            LockInfo memory acc = lockInfo[_holder][i];
            lockedBalance = lockedBalance.add(
                acc.unitValue.mul(acc.releaseDays).add(acc.extraValue)
            );
        }
        return super.balanceOf(_holder).add(lockedBalance);
    }

    /**
    * @dev Returns the amount of total, locked, and available tokens owned by the account.
    * @param _holder The address to check the balance.
    */
    function detailBalance(address _holder)
        public
        view
        returns (uint256 totalBalance, uint256 lockedBalance, uint256 availableBalance)
    {
        uint256 length = lockInfo[_holder].length;
        for (uint256 i = 0; i < length; i++ ) {
            LockInfo memory acc = lockInfo[_holder][i];
            
            if (acc.releaseStartTime > block.timestamp) {
                lockedBalance = lockedBalance.add(
                    acc.releaseDays.mul(acc.unitValue).add(acc.extraValue)
                );
                continue;
            }

            uint256 pastDays = block.timestamp
                .sub(acc.releaseStartTime)
                .div(UNIX_DAY_TIME)
                .add(1);

            if (acc.releaseDays > pastDays) {
                uint256 leftDays = acc.releaseDays.sub(pastDays);
                lockedBalance = lockedBalance.add(
                    acc.unitValue.mul(leftDays).add(acc.extraValue)
                );
            }
        }
        totalBalance = balanceOf(_holder);
        availableBalance = totalBalance.sub(lockedBalance);
    }

    /**
    * @dev Release expired locked tokens and apply to available balance.
    * @param _holder The address to release expired locked tokens.
    */
    function releaseLockByOwner(address _holder) public onlyOwner returns (bool) {
        _releaseLock(_holder);
        return true;
    }

    /**
    * @dev Release expired locked tokens and apply to available balance.
    */
    function releaseLock() public returns (bool) {
        _releaseLock(msg.sender);
        return true;
    }

    /**
    * @dev Returns the number of locks applied to the holder.
    * @param _holder The address to check the number of locks.
    */
    function lockCount(address _holder) public view returns (uint256) {
        return lockInfo[_holder].length;
    }

    /**
    * @dev Returns the lock information applied to the holder.
    * @notice Locked tokens starts unlocking at `releaseStartTime` and is unlocked for
    * `releaseDays` days. Amount of tokens unlocking per day is the total amount of locked tokens
    * divided by `releaseDays`, rounded down. Amount of rounded down tokens is unlocking on the
    * last day. (`extraValue`)
    * @param _holder The address to check the lock information.
    * @param _idx The index number of lock to check.
    * @return releaseStartTime Time to start releasing.
    * @return releaseDays Lock release period. (days)
    * @return unitValue Amount of tokens to unlock per day.
    * @return extraValue Amount of remaining tokens to unlock on the last day.
    */
    function lockState(address _holder, uint256 _idx)
        public
        view
        returns (
            uint256 releaseStartTime,
            uint256 releaseDays,
            uint256 unitValue,
            uint256 extraValue
        )
    {
        releaseStartTime = lockInfo[_holder][_idx].releaseStartTime;
        releaseDays = lockInfo[_holder][_idx].releaseDays;
        unitValue = lockInfo[_holder][_idx].unitValue;
        extraValue = lockInfo[_holder][_idx].extraValue;
    }

    /**
    * @dev Lock tokens so that it cannot be used until a set point in time.
    * @param _holder The address to lock tokens.
    * @param _value Amount of tokens to lock.
    * @param _releaseTime The lock is releaseing at `_releaseTime`.
    */
    function lock(address _holder, uint256 _value, uint256 _releaseTime) public onlyOwner {
        require(_value > 0, "Invalid lock value");
        require(_releaseTime > block.timestamp, "Token release time must be after the current time.");
        _releaseLock(_holder);
        require(super.balanceOf(_holder) >= _value, "Insufficient balance");
        _balances[_holder] = _balances[_holder].sub(_value);
        lockInfo[_holder].push(
            LockInfo(_releaseTime, 1, _value, 0)
        );
        emit Lock(_holder, _value, _releaseTime);
    }

    /**
    * @dev Lock tokens so that it cannot be used until a set point in time.
    * @notice Same as function dailyLockAfter except the way to specify the release point.
    * @param _holder The address to lock tokens.
    * @param _value Amount of tokens to lock.
    * @param _afterTime The lock is releasing after `_afterTime` time. (now + _afterTime)
    */
    function lockAfter(address _holder, uint256 _value, uint256 _afterTime) public onlyOwner {
        lock(_holder, _value, block.timestamp.add(_afterTime));
    }

    /**
    * @dev Lock tokens so that it cannot be used until a set point in time.
    * @notice A certain number of locked tokens are unlocking each day. It starts unlocking at
    * `_releaseStartTime` and is unlocked for`_releaseDays` days. Amount of tokens unlocking per
    * day is the total amount of locked tokens divided by `releaseDays`, rounded down. Amount of
    * rounded down tokens is unlocking on the last day. (`extraValue`)
    * @param _holder The address to lock tokens.
    * @param _totalValue Total amount of tokens to lock.
    * @param _releaseDays Lock release period. (days)
    * @param _releaseStartTime Time to start releasing.
    */
    function dailyLock(
        address _holder,
        uint256 _totalValue,
        uint256 _releaseDays,
        uint256 _releaseStartTime
    )
        public
        onlyOwner
    {
        require(_totalValue > 0, "Invalid lock totalValue");
        require(
            _releaseDays > 0 && _releaseDays <= 1000,
            "Invalid releaseDays (0 < releaseDays <= 1000"
        );
        require(_releaseStartTime > block.timestamp, "Token release start time must be after the current time.");

        _releaseLock(_holder);
        require(_totalValue <= super.balanceOf(_holder), "Insufficient balance");

        uint256 unitValue = _totalValue.div(_releaseDays);
        uint256 extraValue = _totalValue.sub(unitValue.mul(_releaseDays));
        
        _balances[_holder] = _balances[_holder].sub(_totalValue);

        lockInfo[_holder].push(
            LockInfo(_releaseStartTime, _releaseDays, unitValue, extraValue)
        );

        emit Lock(_holder, _totalValue, _releaseDays, _releaseStartTime);
    }

    /**
    * @dev Lock tokens so that it cannot be used until a set point in time.
    * @notice Same as function dailyLockAfter except the way to specify the release point.
    * @param _holder The address to lock tokens.
    * @param _totalValue Total amount of tokens to lock.
    * @param _releaseDays Lock release period. (days)
    * @param _afterTime The lock starting to release after `_afterTime` time. (now + _afterTime)
    */
    function dailyLockAfter(
        address _holder,
        uint256 _totalValue,
        uint256 _releaseDays,
        uint256 _afterTime
    )
        public
        onlyOwner
    {
        dailyLock(_holder, _totalValue, _releaseDays, block.timestamp.add(_afterTime));
    }

    /**
    * @dev Forcibly releases the lock and apply to available balance.
    * @param _holder The address to unlock tokens.
    * @param i Index of lock to unlock tokens.
    */
    function unlock(address _holder, uint256 i) public onlyOwner {
        require(i < lockInfo[_holder].length, "No lock");

        uint256 unlockValue;
        LockInfo memory acc = lockInfo[_holder][i];

        unlockValue = acc.releaseDays.mul(acc.unitValue).add(acc.extraValue);

        _balances[_holder] = _balances[_holder].add(unlockValue);
        emit Unlock(_holder, unlockValue);

        if (i != lockInfo[_holder].length - 1) {
            lockInfo[_holder][i] = lockInfo[_holder][lockInfo[_holder].length - 1];
        }
        lockInfo[_holder].length--;
    }

    /**
    * @dev Moves tokens from the caller's account to the recipient and lock those token.
    * @notice The lock method is the same as the lock function.
    * @param _to The address of recipient.
    * @param _value Amount of tokens to transfer and lock.
    * @param _releaseTime The lock is releaseing at `_releaseTime`.
    */
    function transferWithLock(address _to, uint256 _value, uint256 _releaseTime)
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0), "Invalid address");
        require(_value <= super.balanceOf(owner), "Insufficient balance");
        require(_releaseTime > block.timestamp, "Token release time must be after the current time.");

        _balances[owner] = _balances[owner].sub(_value);

        lockInfo[_to].push(
            LockInfo(_releaseTime, 1, _value, 0)
        );

        emit Transfer(owner, _to, _value);
        emit Lock(_to, _value, _releaseTime);

        return true;
    }

    /**
    * @dev Moves tokens from the caller's account to the recipient and lock those token.
    * @notice Same as function transferWithLock except the way to specify the release point.
    * @param _to The address of recipient.
    * @param _value Amount of tokens to transfer and lock.
    * @param _afterTime The lock is releasing after `_afterTime` time. (now + _afterTime)
    */
    function transferWithLockAfter(address _to, uint256 _value, uint256 _afterTime)
        public
        onlyOwner
        returns (bool)
    {
        transferWithLock(_to, _value, block.timestamp.add(_afterTime));
        return true;
    }

    /**
    * @dev Moves tokens from the caller's account to the recipient and lock those token.
    * @notice The lock method is the same as the dailyLock function.
    * @param _to The address of recipient.
    * @param _totalValue Total amount of tokens to transfer and lock.
    * @param _releaseDays Lock release period. (days)
    * @param _releaseStartTime Time to start releasing.
    */
    function transferWithDailyLock(
        address _to,
        uint256 _totalValue,
        uint256 _releaseDays,
        uint256 _releaseStartTime
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0), "Invalid address");
        require(_totalValue > 0, "Invalid totalValue");
        require(_totalValue <= super.balanceOf(owner), "Insufficient balance");
        require(
            _releaseDays > 0 && _releaseDays <= 1000,
            "Invalid releaseDays (0 < releaseDays <= 1000)"
        );
        require(_releaseStartTime > block.timestamp, "Token release start time must be after the current time.");
        
        uint256 unitValue = _totalValue.div(_releaseDays);
        uint256 extraValue = _totalValue.sub(unitValue.mul(_releaseDays));
        
        _balances[owner] = _balances[owner].sub(_totalValue);

        lockInfo[_to].push(
            LockInfo(_releaseStartTime, _releaseDays, unitValue, extraValue)
        );

        emit Transfer(owner, _to, _totalValue);
        emit Lock(_to, _totalValue, _releaseDays, _releaseStartTime);

        return true;
    }

    /**
    * @dev Moves tokens from the caller's account to the recipient and lock those token.
    * @notice Same as function transferWithDailyLock except the way to specify the release point.
    * @param _to The address of recipient.
    * @param _totalValue Total amount of tokens to transfer and lock.
    * @param _releaseDays Lock release period. (days)
    * @param _afterTime The lock starting to release after `_afterTime` time. (now + _afterTime)
    */
    function transferWithDailyLockAfter(
        address _to,
        uint256 _totalValue,
        uint256 _releaseDays,
        uint256 _afterTime
    )
        public
        onlyOwner
        returns (bool)
    {
        transferWithDailyLock(_to, _totalValue, _releaseDays, block.timestamp.add(_afterTime));
        return true;
    }

    /**
    * @dev Returns the current time.
    */    
    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /**
    * @dev Release expired locked tokens and apply to available balance.
    * @param _holder The address to release expired locked tokens.
    */
    function _releaseLock(address _holder) internal {
        uint256 unlockedValue = 0;
        for (uint256 i = 0; i < lockInfo[_holder].length; i++) {
            LockInfo memory acc = lockInfo[_holder][i];

            if (acc.releaseStartTime > block.timestamp) {
                continue;
            }

            uint256 pastDays = block.timestamp
                .sub(acc.releaseStartTime)
                .div(UNIX_DAY_TIME)
                .add(1);
            if (acc.releaseDays > pastDays) {
                lockInfo[_holder][i].releaseStartTime = lockInfo[_holder][i].releaseStartTime.add(
                    pastDays.mul(UNIX_DAY_TIME)
                );
                lockInfo[_holder][i].releaseDays = lockInfo[_holder][i].releaseDays.sub(pastDays);

                unlockedValue = unlockedValue.add(pastDays.mul(acc.unitValue));
            } else {
                unlockedValue = unlockedValue.add(
                    acc.releaseDays.mul(acc.unitValue).add(acc.extraValue)
                );
                if (i != lockInfo[_holder].length - 1) {
                    lockInfo[_holder][i] = lockInfo[_holder][lockInfo[_holder].length - 1];
                    i--;
                }
                lockInfo[_holder].length--;
            }
        }
        _balances[_holder] = _balances[_holder].add(unlockedValue);
        emit Unlock(_holder, unlockedValue);
    }
}