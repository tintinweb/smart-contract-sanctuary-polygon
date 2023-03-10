/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// File: contracts/Vesting.sol


pragma solidity ^0.8.0;



contract Vesting is Ownable {

    //Address of the ERC20 token
    ERC20 public token;
    address crowdsaleContractAddress;

    mapping(address => mapping(uint256 => VestingScheduleStruct))
        internal vestingSchedules;

    constructor(address tokenAddress) {
        require(tokenAddress != address(0x0));
        token = ERC20(tokenAddress);
    }

    receive() external payable {}

    fallback() external payable {}

/*
 * @MODIFIERS
*/
//////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyCrowdsale() {
        require(
            msg.sender == address(crowdsaleContractAddress),
            "Only crowdsale contract can call this function."
        );
        _;
    }

//////////////////////////////////////////////////////////////////////////////////////////

/*
 * @EVENTS
*/
//////////////////////////////////////////////////////////////////////////////////////////

    event VestingScheduleAdded(
        address beneficiary,
        uint256 numberOfCliffMonths,
        uint256 numberOfVestingMonths,
        uint256 unlockRate,
        uint256 allocation,
        uint256 IcoType
    );

    event VestingScheduleRevoked(
        address beneficiary,
        uint256 IcoType,
        bool tgeVested,
        uint256 releasedPeriod,
        uint256 revokedTokenAllocation
    );

//////////////////////////////////////////////////////////////////////////////////////////

    struct VestingScheduleStruct {
        address beneficiaryAddress; //Address of the vesting schedule beneficiary.
        uint256 icoStartDate; //Ico start date
        uint256 numberOfCliff; //Number of cliff months
        uint256 numberOfVesting; //Number of vesting months
        uint256 unlockRate; //Initial vesting rate of beneficiary
        bool revoked; // Whether or not the vesting has been revoked
        uint256 cliffAndVestingAllocation; // Total amount of tokens to be released at the end of the vesting cliff + vesting
        uint256 vestingAllocation; // Total amount of tokens to be released at the end of the vesting only vesting
        uint256 claimedTokenAmount; //total amount of tokens claimed, added to check distributed token amount correctly
        bool tgeVested; //Whether or not the tge has been vested
        uint256 releasedPeriod; //Already released months
        uint256 icoType; //Type of ICO  0=>seed, 1=>private
        uint256 investedUSDT; //Beneficiary addresses and their investments
    }

    /**
     * @dev Owner function. Change crowdsale contract address.
     */
    function setCrowdsaleContractAddress(address _newCrowdsaleContractAddress)
        external
        onlyOwner
    {
        require(
            _newCrowdsaleContractAddress != address(0),
            "ERROR at Vesting setCrowdsaleContractAddress: Crowdsale contract address shouldn't be zero address."
        );
        crowdsaleContractAddress = address(_newCrowdsaleContractAddress);
    }

/*
 * @ONLYCROWDSALE
*/
//////////////////////////////////////////////////////////////////////////////////////////

    /**
    * @dev Creates a new vesting schedule.
    */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _numberOfCliffMonths,
        uint256 _numberOfVestingMonths,
        uint256 _unlockRate,
        uint256 _allocation,
        uint256 _IcoType,
        uint256 _investedUsdt,
        uint256 _icoStartDate
    ) external onlyCrowdsale {

        uint256 totalVestingAllocation = (_allocation -
            (_unlockRate * _allocation) /
            100);

        vestingSchedules[_beneficiary][_IcoType] = VestingScheduleStruct(
            _beneficiary,
            _icoStartDate,
            _numberOfCliffMonths,
            _numberOfVestingMonths,
            _unlockRate,
            false,
            _allocation,
            totalVestingAllocation,
            0,
            false,
            0,
            _IcoType,
            _investedUsdt
        );

        emit VestingScheduleAdded(
            _beneficiary,
            _numberOfCliffMonths,
            _numberOfVestingMonths,
            _unlockRate,
            _allocation,
            _IcoType
        );
    }

    /**
     * @dev Revokes given vesting schedule.
     * @dev revoke edilen vesting schedule içerisindeki allocation değerleri getvestinglistte kullanıldığından değiştirilmedi
     */
    function vestingRevocation(address _beneficiary, uint256 _icoType, uint256 _notVestedTokenAllocation) external onlyCrowdsale {
        VestingScheduleStruct storage vestingSchedule = vestingSchedules[
            _beneficiary
        ][_icoType];

        require(
            vestingSchedule.beneficiaryAddress != address(0x0),
            "ERROR: Vesting does not exist."
        );

        vestingSchedule.revoked = true;

        /*
        if(_notVestedTokenAllocation<vestingSchedule.cliffAndVestingAllocation || _notVestedTokenAllocation<vestingSchedule.vestingAllocation){
            vestingSchedule.cliffAndVestingAllocation-=_notVestedTokenAllocation;
            vestingSchedule.vestingAllocation-=_notVestedTokenAllocation;
        }else{
            vestingSchedule.cliffAndVestingAllocation=0;
            vestingSchedule.vestingAllocation=0;
        }
        */

        emit VestingScheduleRevoked(
            _beneficiary,
            _icoType,
            vestingSchedule.tgeVested,
            vestingSchedule.releasedPeriod,
            _notVestedTokenAllocation
        );
    }

    /**
     * @dev Calculates the vested amount of given vesting schedule.
     */
    function getReleasableAmount(address _beneficiary, uint256 _icoType)
        external
        onlyCrowdsale
        returns (uint256)
    {
        VestingScheduleStruct storage vestingSchedule = vestingSchedules[
            _beneficiary
        ][_icoType];

        require(
            vestingSchedule.icoStartDate != 0,
            "ERROR at getReleasableAmount: Vesting does not exist."
        );
        
        /*
        require(
            vestingSchedule.releasedPeriod < vestingSchedule.numberOfVesting,
            "ERROR at getReleasableAmount: You claimed all of your vesting."
        );
        */

        uint256 currentTime = block.timestamp;

        require(
            currentTime > vestingSchedule.icoStartDate,
            "ERROR at getReleasableAmount: ICO is not started yet"
        );
        
        uint256 elapsedMonthNumber = _getElapsedMonth(
            vestingSchedule,
            currentTime
        );

        if (
            elapsedMonthNumber >
            vestingSchedule.numberOfVesting + vestingSchedule.numberOfCliff
        ) {
            elapsedMonthNumber =
                vestingSchedule.numberOfVesting +
                vestingSchedule.numberOfCliff;
        }

        uint256 releasableAmount = 0;
        
        if (!vestingSchedule.tgeVested) {
            uint256 unlockAmount = (vestingSchedule.cliffAndVestingAllocation *
                vestingSchedule.unlockRate) / 100;
            releasableAmount += unlockAmount;
            vestingSchedule.tgeVested = true;
        }

        if (elapsedMonthNumber > vestingSchedule.numberOfCliff + vestingSchedule.releasedPeriod) {
            uint256 vestedMonthNumber = elapsedMonthNumber -
            vestingSchedule.numberOfCliff -
            vestingSchedule.releasedPeriod;

            uint256 vestedAmount = (vestingSchedule.vestingAllocation /
                vestingSchedule.numberOfVesting) * vestedMonthNumber;
            releasableAmount += vestedAmount;
            vestingSchedule.releasedPeriod += vestedMonthNumber;
        }

        vestingSchedule.claimedTokenAmount+=releasableAmount;
        
        return releasableAmount;
    }

    /**
     * @dev Only crowdsale contract functions can call this function. Crowdsale buytokens function calls this function.
     */
    function updateBuyTokens(
        address _beneficiary,
        uint256 _icoType,
        uint256 _tokenAmount,
        uint256 _totalVestingAllocation,
        uint256 _usdtAmount
    ) external onlyCrowdsale {
        vestingSchedules[_beneficiary][_icoType]
            .cliffAndVestingAllocation += _tokenAmount;

        vestingSchedules[_beneficiary][_icoType]
            .vestingAllocation += _totalVestingAllocation;
        
        vestingSchedules[_beneficiary][_icoType].investedUSDT += _usdtAmount;
    }

//////////////////////////////////////////////////////////////////////////////////////////

/*
 * @INTERNALS
*/
//////////////////////////////////////////////////////////////////////////////////////////    

    /**
     * @dev Calculates the elapsed month.
     * @param vestingSchedule Beneficiary vesting schedule struct.
     * @param currentTime Given by parameter to avoid transaction call latency.
     */
    function _getElapsedMonth(
        VestingScheduleStruct memory vestingSchedule,
        uint256 currentTime
    ) internal pure returns (uint256) {
        return (currentTime - vestingSchedule.icoStartDate) / 300;
    }

//////////////////////////////////////////////////////////////////////////////////////////

/*
 * @VIEWS
*/
//////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Get token allocation of vesting schedule
     * @dev silinebilir
     */
    function getScheduleTokenAllocation(address _beneficiary, uint256 _icoType)
        external
        view
        returns (uint256)
    {
        return
            vestingSchedules[_beneficiary][_icoType].cliffAndVestingAllocation;
    }

    /**
     * @dev Views releasable token amount of vesting schedule.
     * @dev silinebilir
     */
    function viewReleasableAmount(address _beneficiary, uint256 _icoType)
        public
        view
        returns (uint256)
    {
        VestingScheduleStruct memory vestingSchedule = vestingSchedules[
            _beneficiary
        ][_icoType];

        require(
            _beneficiary != address(0),
            "ERROR at viewReleasableAmount: Beneficiary address is not valid."
        );
        require(
            vestingSchedule.icoStartDate != 0,
            "ERROR at viewReleasableAmount: Vesting does not exist."
        );
        
        require(
            vestingSchedule.releasedPeriod < vestingSchedule.numberOfVesting,
            "ERROR at viewReleasableAmount: You claimed all of your vesting."
        );

        uint256 currentTime = block.timestamp;

        require(
            currentTime > vestingSchedule.icoStartDate,
            "ERROR at viewReleasableAmount: ICO is not started yet"
        );
        
        uint256 elapsedMonthNumber = _getElapsedMonth(
            vestingSchedule,
            currentTime
        );

        if (
            elapsedMonthNumber >
            vestingSchedule.numberOfVesting + vestingSchedule.numberOfCliff
        ) {
            elapsedMonthNumber =
                vestingSchedule.numberOfVesting +
                vestingSchedule.numberOfCliff;
        }

        uint256 releasableAmount = 0;
        
        if (!vestingSchedule.tgeVested) {
            uint256 unlockAmount = (vestingSchedule.cliffAndVestingAllocation *
                vestingSchedule.unlockRate) / 100;
            releasableAmount += unlockAmount;
        }

        if (elapsedMonthNumber > vestingSchedule.numberOfCliff + vestingSchedule.releasedPeriod) {
            uint256 vestedMonthNumber = elapsedMonthNumber -
            vestingSchedule.numberOfCliff -
            vestingSchedule.releasedPeriod;

            uint256 vestedAmount = (vestingSchedule.vestingAllocation /
                vestingSchedule.numberOfVesting) * vestedMonthNumber;
            releasableAmount += vestedAmount;
        }
        return releasableAmount;
    }

    /**
     * @dev Views releasable usdt amount of vesting schedule.
     * @dev silinebilir
     */
    function viewReleasableUsdtAmount(address _beneficiary, uint256 _icoType)
        external 
        view
        returns (uint256)
    {
        VestingScheduleStruct memory vestingSchedule = vestingSchedules[
            _beneficiary
        ][_icoType];

        require(
            _beneficiary != address(0),
            "ERROR at viewReleasableUsdtAmount: Beneficiary address is not valid."
        );
        require(
            vestingSchedule.icoStartDate != 0,
            "ERROR at viewReleasableUsdtAmount: Vesting does not exist !"
        );

        require(
            vestingSchedule.releasedPeriod < vestingSchedule.numberOfVesting,
            "ERROR at viewReleasableUsdtAmount: You claimed all of your vesting."
        );

        uint256 currentTime = block.timestamp;

        require(
            currentTime > vestingSchedule.icoStartDate,
            "ERROR at viewReleasableUsdtAmount: ICO is not started yet"
        );
        
        uint256 elapsedMonthNumber = _getElapsedMonth(
            vestingSchedule,
            currentTime
        );

        if (
            elapsedMonthNumber >
            vestingSchedule.numberOfVesting + vestingSchedule.numberOfCliff
        ) {
            elapsedMonthNumber =
                vestingSchedule.numberOfVesting +
                vestingSchedule.numberOfCliff;
        }

        uint256 releasableUsdtAmount = 0;

        if (!vestingSchedule.tgeVested) {
            uint256 unlockUsdtAmount = (vestingSchedule.investedUSDT *
                vestingSchedule.unlockRate) / 100;
            releasableUsdtAmount += unlockUsdtAmount;
        }

        if (elapsedMonthNumber > vestingSchedule.numberOfCliff + vestingSchedule.releasedPeriod) {
            uint256 vestedMonthNumber = elapsedMonthNumber -
            vestingSchedule.numberOfCliff -
            vestingSchedule.releasedPeriod;

            uint256 totalVestingUsdtAmount = (vestingSchedule.investedUSDT *
                (100 - vestingSchedule.unlockRate)) / 100;
                
            uint256 vestedUsdtAmount = (totalVestingUsdtAmount *
                vestedMonthNumber) / vestingSchedule.numberOfVesting;

            releasableUsdtAmount += vestedUsdtAmount;
        }
        
        return releasableUsdtAmount;
    }

    function getBeneficiaryVesting(address beneficiary, uint256 icoType)
        external 
        view
        returns (VestingScheduleStruct memory)
    {
        return vestingSchedules[beneficiary][icoType];
    }

//////////////////////////////////////////////////////////////////////////////////////////
    
}