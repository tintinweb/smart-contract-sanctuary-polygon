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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MLDStaking is Ownable {
    /* ========== STATE VARIABLES ========== */
    ERC20Burnable public immutable mldToken;
    ERC20Burnable public immutable lordToken;

    address public feeReciever;
    uint256 public minMLD;
    uint256 public baseAPY;
    uint256 public unstakeLordFeesPercentage;
    uint256 public lordRatio;
    uint256 public preMatureMLDPenalty;
    uint256 public totalMLDStaked;
    uint256[] public stakeDurationInSec;

    struct DurationStakeInfo {
        uint256 multiplier;
        bool valid;
    }

    mapping(uint256 => DurationStakeInfo) public durationwiseStake;

    struct DepositInfo {
        uint256 index;
        uint256 durationStaked;
        uint256 start;
        uint256 maturity;
        uint256 mldStaked;
        uint256 lordStaked;
        uint256 reward;
        bool premature;
        bool claimed;
    }

    struct UserTokenDesposits {
        uint256 totalMLDStaked;
        uint256 totalLordStaked;
    }

    mapping(address => DepositInfo[]) public userDeposits;
    mapping(address => UserTokenDesposits) public userTotalDeposits;

    /* ========== EVENTS ========== */

    event Staked(
        address indexed _of,
        uint256 indexed mldStaked,
        uint256 indexed stakedAt
    );
    event Unstaked(address indexed _of, uint256 indexed _amount);
    event PreWithdrawn(address indexed _of, uint256 indexed _amount);

    modifier withdrawCheck(uint256 _index) {
        require(
            _index < userDeposits[msg.sender].length,
            "Exceed the user history stake length"
        );
        require(!userDeposits[msg.sender][_index].claimed, "Already claimed");
        _;
    }

    modifier incorrectPercentage(uint256 _feesPercentage) {
        require(_feesPercentage < 90, "Very High fees");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor(
        ERC20Burnable _mldToken,
        ERC20Burnable _lordToken,
        address _feeReciever,
        uint256 _minMLD,
        uint256 _lordRatio,
        uint256 _preMatureMLDPenalty,
        uint256 _unstakeLordFeesPercentage,
        uint256 _baseAPY,
        uint256[] memory _stakeDurationInDays,
        uint256[] memory _multiplier
    ) {
        require(
            _stakeDurationInDays.length == _multiplier.length,
            "Arrays length mismatch"
        );
        require(_lordRatio < 90 && _preMatureMLDPenalty < 90, "Very High fees");

        feeReciever = _feeReciever;
        mldToken = _mldToken;
        lordToken = _lordToken;
        baseAPY = _baseAPY;
        minMLD = _minMLD;
        lordRatio = _lordRatio;
        preMatureMLDPenalty = _preMatureMLDPenalty;
        unstakeLordFeesPercentage = _unstakeLordFeesPercentage;

        for (uint256 i = 0; i < _stakeDurationInDays.length; i++) {
            uint256 durationInSec = _stakeDurationInDays[i] * 1 days;
            stakeDurationInSec.push(durationInSec);

            durationwiseStake[durationInSec].valid = true;
            durationwiseStake[durationInSec].multiplier = _multiplier[i];
        }
    }

    function calculateReward(
        uint256 _amount,
        uint256 _stakeDurationInSec
    ) public view returns (uint256) {
        uint256 multiplier = durationwiseStake[_stakeDurationInSec].multiplier;
        if (multiplier == 0) multiplier = 10;
        uint256 effectiveAPY = ((multiplier *
            baseAPY *
            1e10 *
            _stakeDurationInSec) / 365 days) / 10;
        return (effectiveAPY * _amount) / 1e12;
    }

    /**
     * @dev Locks specified amount of tokens for a specified period staking time
     * @param _mldAmount Number of MLD tokens to be locked
     * @param _stakeDurationInSec Stake period in seconds
     */
    function stake(uint256 _mldAmount, uint256 _stakeDurationInSec) external {
        require(
            durationwiseStake[_stakeDurationInSec].valid,
            "Invalid Staking Duration"
        );
        require(_mldAmount >= minMLD, "Insufficient MLD");

        uint256 stakeReward = calculateReward(_mldAmount, _stakeDurationInSec);

        uint256 _requiredLord = (_mldAmount * lordRatio) / 100;

        userDeposits[msg.sender].push(
            DepositInfo(
                userDeposits[msg.sender].length,
                _stakeDurationInSec,
                block.timestamp,
                block.timestamp + _stakeDurationInSec,
                _mldAmount,
                _requiredLord,
                stakeReward,
                false,
                false
            )
        );
        totalMLDStaked += _mldAmount;
        userTotalDeposits[msg.sender].totalMLDStaked += _mldAmount;
        userTotalDeposits[msg.sender].totalLordStaked += _requiredLord;

        mldToken.transferFrom(msg.sender, address(this), _mldAmount);
        lordToken.transferFrom(msg.sender, address(this), _requiredLord);

        emit Staked(msg.sender, _mldAmount, block.timestamp);
    }

    /**
     * @dev Unlocks the initially MLD staked along with the rewards if matured & burning some LORD as fees
     * @param _index User' stake index
     */
    function unstake(uint256 _index) external withdrawCheck(_index) {
        DepositInfo storage userDepositInfo = userDeposits[msg.sender][_index];

        require(
            block.timestamp >= userDepositInfo.maturity,
            "Still pre-mature"
        );
        uint256 userStakedMLD = userDepositInfo.mldStaked;

        uint256 returnAmount = userStakedMLD + userDepositInfo.reward;

        userDepositInfo.claimed = true;
        uint256 _lordStaked = userDepositInfo.lordStaked;
        uint256 lordFees = (_lordStaked * unstakeLordFeesPercentage) / 100;

        totalMLDStaked -= userStakedMLD;
        userTotalDeposits[msg.sender].totalMLDStaked -= userStakedMLD;
        userTotalDeposits[msg.sender].totalLordStaked -= _lordStaked;

        mldToken.transfer(msg.sender, returnAmount);
        lordToken.burn(lordFees);
        lordToken.transfer(msg.sender, _lordStaked - lordFees);
        emit Unstaked(msg.sender, returnAmount);
    }

    /**
     * @dev Pre Mature Withdrawal Will charge PENALTY FEES in MLD & lord staked would be burnt
     * @param _index User' stake index
     */
    function preMatureWithdraw(uint256 _index) external withdrawCheck(_index) {
        DepositInfo storage userDepositInfo = userDeposits[msg.sender][_index];

        require(
            block.timestamp < userDepositInfo.maturity,
            "Investement matured for unstake"
        );

        uint256 stakedMLD = userDepositInfo.mldStaked;
        uint256 _lordStaked = userDepositInfo.lordStaked;

        userDepositInfo.premature = true;
        userDepositInfo.claimed = true;

        uint256 mldPenalty = (stakedMLD * preMatureMLDPenalty) / 100;
        uint256 withdrawableAmount = stakedMLD - mldPenalty;

        totalMLDStaked -= stakedMLD;
        userTotalDeposits[msg.sender].totalMLDStaked -= stakedMLD;
        userTotalDeposits[msg.sender].totalLordStaked -= _lordStaked;

        mldToken.transfer(msg.sender, withdrawableAmount);
        lordToken.burn(_lordStaked);
        mldToken.transfer(feeReciever, mldPenalty);

        emit PreWithdrawn(msg.sender, withdrawableAmount);
    }

    function getUserUnclaimedIndex(
        address _user
    )
        public
        view
        returns (
            uint256[] memory maturedIndexes,
            uint256[] memory preMaturedIndexes
        )
    {
        for (uint256 i = 0; i < userDeposits[_user].length; i++) {
            DepositInfo memory userInfo = userDeposits[msg.sender][i];
            if (!userInfo.claimed) {
                if (block.timestamp >= userInfo.maturity)
                    maturedIndexes[maturedIndexes.length] = userInfo.index;
                else {
                    preMaturedIndexes[preMaturedIndexes.length] = userInfo
                        .index;
                }
            }
        }
    }

    function userNextUnlock(
        address _of
    )
        public
        view
        returns (uint256 upcomingUnlockTime, uint256 upcomingRewards)
    {
        for (uint256 i = 0; i < userDeposits[_of].length; i++) {
            uint256 maturity = userDeposits[_of][i].maturity;
            if (block.timestamp < maturity && !userDeposits[_of][i].claimed) {
                if (upcomingUnlockTime == 0 || upcomingUnlockTime > maturity) {
                    upcomingUnlockTime = maturity;
                    upcomingRewards = userDeposits[_of][i].reward;
                }
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addPeriod(
        uint256 _stakeDurationInDays,
        uint256 _multiplier
    ) external onlyOwner {
        uint256 periodInSecs = _stakeDurationInDays * 1 days;
        durationwiseStake[periodInSecs].multiplier = _multiplier;
        durationwiseStake[periodInSecs].valid = true;
    }

    function invalidatePeriod(uint256 _stakeDurationInSec) external onlyOwner {
        DurationStakeInfo storage stakeInfo = durationwiseStake[
            _stakeDurationInSec
        ];
        require(stakeInfo.valid, "Invalid Staking Duration");
        stakeInfo.valid = false;
    }

    function updatePreMaturePenalty(
        uint256 _penaltyPercentage
    ) external onlyOwner incorrectPercentage(_penaltyPercentage) {
        preMatureMLDPenalty = _penaltyPercentage;
    }

    function updateLordUnstakingFees(
        uint256 _unstakingfees
    ) external onlyOwner incorrectPercentage(_unstakingfees) {
        unstakeLordFeesPercentage = _unstakingfees;
    }

    function updateRequiredLordRatio(uint256 _lordRatio) external onlyOwner {
        lordRatio = _lordRatio;
    }

    function updateAPY(uint256 _baseAPY) external onlyOwner {
        baseAPY = _baseAPY;
    }

    function updateMinMLD(uint256 _minMLD) external onlyOwner {
        minMLD = _minMLD;
    }
}