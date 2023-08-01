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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./DugOutReward.sol";
import "./Counters.sol";

contract Dugout {
    using Counters for Counters.Counter;
    Counters.Counter private _stakingPositionId;
    Counters.Counter private _tokenContractId;
    DugOutReward public rewardTokensContract;
    uint256 minimumStakingAmount = 0;
    uint256 MaxmumStakingAmount = 0;
    uint256 public totalStakeTokens = 0;
    uint256 earlyUnstakeFeePercentage = 0;
    bool isStakingPaused = false;
    uint256 apyRate = 0;
    address owner;

    struct Users {
        uint256 stakingId;
        address payable userAddress;
        address payable tokensContract;
        uint256 tokenStaked;
        uint256 createdDate;
        uint256 unLockDate;
        uint256 tokenInterest;
        uint256 rewardTokens;
        uint256 releaseTokens;
        bool ealryUnStake;
    }

    struct TokenAddress {
        uint256 tokenAddressId;
        address payable tokenContractAddress;
    }

    mapping(uint256 => uint256) public tiers;
    mapping(uint256 => Users) public userDetails;
    mapping(uint256 => TokenAddress) public tokenDetails;
    uint256[] public lockTimes;

    event stake(
        address indexed tokenAddress,
        uint256 indexed amount,
        uint256 indexed numdays
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor(address payable _tokenAddress) {
        rewardTokensContract = DugOutReward(_tokenAddress);
        owner = msg.sender;

        tiers[7] = 100;
        tiers[10] = 150;
        tiers[32] = 250;
        tiers[70] = 1000;

        lockTimes.push(7);
        lockTimes.push(10);
        lockTimes.push(32);
        lockTimes.push(70);
    }

    function setMinmumStakingAmount(uint256 _minimumStakingAmount)
        public
        onlyOwner
    {
        minimumStakingAmount = _minimumStakingAmount;
    }

    function setMaxmumStakingAmount(uint256 _MaxmumStakingAmount)
        public
        onlyOwner
    {
        MaxmumStakingAmount = _MaxmumStakingAmount;
    }

    function setearlyUnstakeFeePercentage(uint256 _percentage)
        public
        onlyOwner
    {
        earlyUnstakeFeePercentage = _percentage;
    }

    function setStakingPused(bool _active) public onlyOwner {
        isStakingPaused = _active;
    }

    function setApyRate(uint256 _rate) public onlyOwner {
        apyRate = _rate;
    }

    function changeLockTime(uint256 indexId, uint256 _newLockTime)
        external
        onlyOwner
    {
        require(indexId < lockTimes.length, "Invalid index");
        uint256 existingLockTime = lockTimes[indexId];
        lockTimes[indexId] = _newLockTime;

        if (tiers[existingLockTime] != 0) {
            uint256 rewardTokens = tiers[existingLockTime];
            delete tiers[existingLockTime];
            tiers[_newLockTime] = rewardTokens;
        }
    }

    function addStakingPeriods(uint256 _numdays, uint256 _rewardTokens)
        public
        onlyOwner
    {
        tiers[_numdays] = _rewardTokens;
        lockTimes.push(_numdays);
    }

    function changeStakingReward(uint256 existingDays, uint256 newRewardTokens)
        public
        onlyOwner
    {
        require(tiers[existingDays] != 0, "this tiers is not exits");
        tiers[existingDays] = newRewardTokens;
    }

    function removeStakingPeriod(uint256 _numdays) public onlyOwner {
        require(tiers[_numdays] != 0, "This tier does not exist");
        delete tiers[_numdays];

        for (uint256 i = 0; i < lockTimes.length; i++) {
            if (lockTimes[i] == _numdays) {
                if (i < lockTimes.length - 1) {
                    lockTimes[i] = lockTimes[lockTimes.length - 1];
                }
                lockTimes.pop();
                break;
            }
        }
    }

    function addTokenAddresses(address payable[] memory _tokenContractAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenContractAddresses.length; i++) {
            _tokenContractId.increment();
            uint256 newTokenId = _tokenContractId.current();
            tokenDetails[newTokenId] = TokenAddress(
                newTokenId,
                payable(_tokenContractAddresses[i])
            );
        }
    }

    function updateTokenAddress(
        uint256 tokenId,
        address payable _newtokenAddress
    ) public onlyOwner {
        tokenDetails[tokenId].tokenContractAddress = _newtokenAddress;
    }

    function removeTokenAddress(uint256 tokenId) public onlyOwner {
        require(
            tokenDetails[tokenId].tokenContractAddress != address(0),
            "This token does not exist"
        );

        delete tokenDetails[tokenId];
    }

    function changeRewardToken(address _tokenAddress) public onlyOwner {
        rewardTokensContract = DugOutReward(_tokenAddress);
    }

    function getMinmumStakingAmount() public view returns (uint256) {
        return minimumStakingAmount;
    }

    function getMaxmumStakingAmount() public view returns (uint256) {
        return MaxmumStakingAmount;
    }

    function getUnstakeFees() public view returns (uint256) {
        return earlyUnstakeFeePercentage;
    }

    function getTotalStakeTokens() public view returns (uint256) {
        return totalStakeTokens;
    }

    function getStakeActiveOrNot() public view returns (bool) {
        return isStakingPaused;
    }

    function getApyRate() public view returns (uint256) {
        return apyRate;
    }

    function stakeTokens(
        uint256 tokenAddressId,
        uint256 amount,
        uint256 _numdays
    ) public {
        require(!isStakingPaused, "staking is paused");
        address payable tokenaddress = tokenDetails[tokenAddressId]
            .tokenContractAddress;
        require(
            IERC20(tokenaddress).balanceOf(msg.sender) > amount,
            "StakedToken amount is not sufficient"
        );
        require(tiers[_numdays] > 0, "Mapping not Found");
        require(
            amount >= minimumStakingAmount,
            "Amount is less than minimumStakingAmount"
        );
        require(
            amount <= MaxmumStakingAmount,
            "max staking token limit reached"
        );
        _stakingPositionId.increment();
        uint256 newPositionId = _stakingPositionId.current();
        Users memory newStake = Users(
            newPositionId,
            payable(msg.sender),
            payable(tokenaddress),
            amount,
            block.timestamp,
            block.timestamp + 2 minutes,
            tiers[_numdays],
            0,
            0,
            false
        );

        userDetails[newPositionId] = newStake;
        totalStakeTokens += amount;
        IERC20(tokenaddress).transferFrom(msg.sender, address(this), amount);
        emit stake(tokenaddress, amount, _numdays);
    }

    function unStakeToken(uint256 _positionId, uint256 _amount) public {
        require(
            userDetails[_positionId].userAddress == msg.sender,
            "user can't stake a token"
        );
        require(
            _amount <= userDetails[_positionId].tokenStaked,
            "Amount is less than or equal to tokenStaked by staker"
        );
        uint256 feesEarlyUnstake;

        if (block.timestamp < userDetails[_positionId].unLockDate) {
            feesEarlyUnstake = (_amount * earlyUnstakeFeePercentage) / 10000;
            uint256 amountToUnstake = _amount - feesEarlyUnstake;
            userDetails[_positionId].tokenStaked -= _amount;
            IERC20(userDetails[_positionId].tokensContract).transfer(
                msg.sender,
                amountToUnstake
            );
            totalStakeTokens -= _amount;
            userDetails[_positionId].ealryUnStake = true;
        } else {
            IERC20(userDetails[_positionId].tokensContract).transfer(
                msg.sender,
                _amount
            );
            totalStakeTokens -= _amount;
        }
    }

    function claimReward(uint256 _positionId) public {
        require(
            userDetails[_positionId].userAddress == msg.sender,
            "user doesn't have rewards"
        );

        require(
            block.timestamp > userDetails[_positionId].unLockDate,
            "invalid timestamp for claim"
        );
        require(
            !userDetails[_positionId].ealryUnStake,
            "You can't get a reward token because you have already applied for early unstake."
        );

        uint256 rewardtokens = ((userDetails[_positionId].tokenStaked *
            userDetails[_positionId].tokenInterest *
            apyRate) / 365) / 1000;
        require(
            rewardTokensContract.balanceOf(address(this)) >= rewardtokens,
            "Insufficient funds in the reward"
        );
        userDetails[_positionId].rewardTokens += rewardtokens;
        rewardTokensContract.transfer(msg.sender, rewardtokens);
        userDetails[_positionId].rewardTokens -= rewardtokens;
        userDetails[_positionId].tokenStaked -= 0;
        userDetails[_positionId].releaseTokens += rewardtokens;
        delete userDetails[_positionId].userAddress;
    }

    function getLockPeriods() external view returns (uint256[] memory) {
        return lockTimes;
    }

    function getInterestRate(uint256 stakingPeriod)
        external
        view
        returns (uint256)
    {
        return tiers[stakingPeriod];
    }

    function getStakingDetailsbystakingId(uint256 PositionId)
        public
        view
        returns (Users memory)
    {
        return userDetails[PositionId];
    }

    function getTokenAddressbyId(uint256 tokenId)
        public
        view
        returns (TokenAddress memory)
    {
        return tokenDetails[tokenId];
    }

    function gettiersbydays(uint256 _numdays) public view returns (uint256) {
        return tiers[_numdays];
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function withdrawFunds(address payable _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
            "Insufficient funds"
        );

        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

contract DugOutReward is ERC20 {
    constructor() ERC20("DugOutReward", "DOR") {
        _mint(msg.sender, 4200000000 * (10**18)); // mint initial supply to contract creator
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
        return  18;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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