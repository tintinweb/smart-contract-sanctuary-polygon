// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICoinbetHousePool.sol";

contract CoinbetHousePool is ICoinbetHousePool, ERC20, Ownable, Pausable {
    /* ========== STATE VARIABLES ========== */

    uint256 public exitFeeBps;
    uint256 public poolMaxCap;
    uint256 public poolBalance;
    uint256 public immutable epochSeconds;
    uint256 public epochStartedAt;
    uint256 public maxBetToPoolRatio;
    uint256 public pendingBetsAmount;
    uint256 public finalizeEpochBonus;
    uint256 public protocolRewardsBalance;
    uint256 public withdrawTimeWindowSeconds;
    uint256 public coinbetTokenRewardMultiplier;
    uint256 public coinbetTokenFeeWaiverThreshold;

    bool public incentiveMode;
    IERC20 public immutable coinbetToken;

    /// Mapping of addresses allowed to call the House Pool Contract
    mapping(address => bool) public authorizedGames;

    modifier onlyCoinbetGame() {
        require(
            authorizedGames[_msgSender()],
            "Coinbet House Pool: Not called from the Coinbet Slot Machine!"
        );
        _;
    }

    modifier onlyEpochNotEnded() {
        require(
            block.timestamp < epochEndAt(),
            "Coinbet House Pool: Current epoch has ended"
        );
        _;
    }

    modifier onlyEpochEnded() {
        require(
            block.timestamp >= epochEndAt(),
            "Coinbet House Pool: Current epoch has not ended"
        );
        _;
    }

    receive() external payable {
        protocolRewardsBalance += msg.value;
        emit HousePoolDonation(msg.sender, msg.value);
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _exitFeeBps,
        uint256 _poolMaxCap,
        uint256 _epochSeconds,
        uint256 _epochStartedAt,
        uint256 _coinbetTokenFeeWaiverThreshold,
        uint256 _withdrawTimeWindowSeconds,
        uint256 _coinbetTokenRewardMultiplier,
        uint256 _finalizeEpochBonus,
        uint256 _maxBetToPoolRatio,
        address _coinbetTokenAddress,
        bool _incentiveMode
    ) ERC20("Coinbet House Pool Token", "CHPT") {
        exitFeeBps = _exitFeeBps;
        poolMaxCap = _poolMaxCap;
        epochSeconds = _epochSeconds;
        epochStartedAt = _epochStartedAt;
        coinbetTokenRewardMultiplier = _coinbetTokenRewardMultiplier;
        coinbetTokenFeeWaiverThreshold = _coinbetTokenFeeWaiverThreshold;
        withdrawTimeWindowSeconds = _withdrawTimeWindowSeconds;
        finalizeEpochBonus = _finalizeEpochBonus;
        maxBetToPoolRatio = _maxBetToPoolRatio;

        incentiveMode = _incentiveMode;
        coinbetToken = IERC20(_coinbetTokenAddress);
    }

    /* ========== VIEWS ========== */

    /// @notice Returns the Coinbet's token balance of the HousePool
    function coinbetTokenBalance() public view returns (uint256) {
        return IERC20(coinbetToken).balanceOf(address(this));
    }

    /// @notice Returns the avaialble funds for Payroll after deducting pending bets amount
    function availableFundsForPayroll() public view returns (uint256) {
        return (poolBalance - pendingBetsAmount) / maxBetToPoolRatio;
    }

    /// @notice Returns the timestamp when the current epoch will end
    function epochEndAt() public view returns (uint256) {
        return epochStartedAt + epochSeconds;
    }

    /// @notice Returns boolean if the epoch has ended
    function hasEpochEnded() public view returns (bool) {
        return block.timestamp >= epochEndAt();
    }

    /// @notice Returns the current block timestamp
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Calculates the next epoch start time
    /// @param currentTime The current block timestamp
    function calculateNextEpochStartTime(uint256 currentTime)
        internal
        view
        returns (uint256)
    {
        uint256 elapsedEpochs = (currentTime - epochStartedAt) / epochSeconds;
        return epochStartedAt + (elapsedEpochs * epochSeconds);
    }

    /// @notice Calculates the exit fee. If the provider holds a certain amount of $CFI tokens
    /// the exit fee is waived. The minimum amount coinbet tokens is set in the constructor
    /// @param _withdrawAmount The amount withdrawn
    /// @param _exitFeeBps The exit fee in basis points
    /// @param _lpProvider The address of the LP provider who withdraws
    function calculateProtocolFee(
        uint256 _withdrawAmount,
        uint256 _exitFeeBps,
        address _lpProvider
    ) internal view returns (uint256 exitFee) {
        uint256 tokenBalance = coinbetToken.balanceOf(_lpProvider);
        if (tokenBalance >= coinbetTokenFeeWaiverThreshold) {
            exitFee = 0;
        } else {
            exitFee = (_exitFeeBps * _withdrawAmount) / 10000;
        }
    }

    /// @notice Converts the LP token amount to staked token amount
    /// @param liquidity The ERC20 LP token amount
    function convertLiquidityToStakedToken(uint256 liquidity)
        external
        view
        returns (uint256 amount)
    {
        require(liquidity > 0, "Coinbet House Pool: Insuffcient Liquidity");
        uint256 balance = poolBalance;
        uint256 _totalSupplyPoolToken = totalSupply();

        // slither-disable-next-line divide-before-multiply
        amount = (liquidity * balance) / _totalSupplyPoolToken;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Adds liquidity used for paying rewards to player and accumulating rewards from players rolls.
    /// ERC20 token is minted, which represents a percantage of the total pool.
    function addRewardsLiquidity()
        external
        payable
        whenNotPaused
        returns (uint256 liquidity)
    {
        uint256 _totalSupplyPoolToken = totalSupply();
        uint256 _reserve = poolBalance;
        uint256 amount = msg.value;

        require(
            _reserve + amount <= poolMaxCap,
            "Coinbet House Pool: Reward Pool Max Cap Exceeded"
        );

        if (_totalSupplyPoolToken == 0) {
            liquidity = amount / 2;
        } else {
            liquidity = (amount * _totalSupplyPoolToken) / _reserve;
        }

        poolBalance += amount;

        require(
            liquidity > 0,
            "Coinbet House Pool: Insuffcient Liquidity Minted"
        );
        _mint(_msgSender(), liquidity);

        emit RewardsLiquidityAdded(amount, liquidity, _msgSender());
    }

    /// @notice Removes liquidity used for paying rewards to player and accumulating rewards from players rolls.
    /// ERC20 token is burned, which represents a percantage of the total pool.
    function removeRewardsLiquidity(uint256 liquidity)
        external
        whenNotPaused
        onlyEpochEnded
        returns (uint256 amount)
    {
        _transfer(_msgSender(), address(this), liquidity);

        uint256 balance = poolBalance;
        uint256 _totalSupplyPoolToken = totalSupply();

        // slither-disable-next-line divide-before-multiply
        amount = (liquidity * balance) / _totalSupplyPoolToken;

        require(amount > 0, "Coinbet House Pool: Insuffcient Liquidity Burned");

        _burn(address(this), liquidity);

        uint256 _exitFee = calculateProtocolFee(
            amount,
            exitFeeBps,
            _msgSender()
        );

        poolBalance -= amount;
        protocolRewardsBalance += _exitFee;

        emit RewardsLiquidityRemoved(amount, liquidity, _msgSender());

        (bool success, ) = _msgSender().call{value: (amount - _exitFee)}("");
        require(success, "Coinbet House Pool: Withdrawal Failed");
    }

    /// @notice Withdraws aggregated protocol fees to the owner of the contract.
    function withdrawProtocolFees()
        external
        onlyOwner
        returns (uint256 amount)
    {
        amount = protocolRewardsBalance;
        protocolRewardsBalance = 0;

        emit ProtocolFeesWithdrawn(amount);

        (bool success, ) = owner().call{value: amount}("");
        require(success, "Coinbet House Pool: Withdrawal Failed");
    }

    /// @notice Withdraws CFI token from contract
    function withdrawCoinbetToken()
        external
        onlyOwner
        onlyEpochEnded
        returns (uint256 amount)
    {
        amount = coinbetTokenBalance();
        emit CoinbetTokenWithdrawn(amount);
        require(
            coinbetToken.transfer(owner(), amount),
            "Coinbet House Pool: Transcation Failed"
        );
    }

    /// @notice Updates the max bet to pool ration
    /// @param newMaxBetToPoolRatio The new max bet to pool ratio.
    function updateMaxBetToPoolRatio(uint256 newMaxBetToPoolRatio)
        external
        onlyOwner
        onlyEpochEnded
    {
        maxBetToPoolRatio = newMaxBetToPoolRatio;

        emit MaxBetToPoolRatioUpdated(newMaxBetToPoolRatio);
    }

    /// @notice Updates the incentiveMode value, used to distribute $CFI to players
    /// @param newIncentiveMode The new incentive mode true/false.
    function updateIncentiveMode(bool newIncentiveMode)
        external
        onlyOwner
        onlyEpochEnded
    {
        incentiveMode = newIncentiveMode;

        emit IncentiveModeUpdated(newIncentiveMode);
    }

    /// @notice Updates the $CFI token reward multiplier, rewarded on every bet.
    /// @param newRewardMultiplier The new $CFI token reward multiplier.
    function updateCoinbetTokenRewardMultiplier(uint256 newRewardMultiplier)
        external
        onlyOwner
        onlyEpochEnded
    {
        coinbetTokenRewardMultiplier = newRewardMultiplier;

        emit CoinbetTokenRewardMultiplierUpdated(newRewardMultiplier);
    }

    /// @notice Updates the finalizeEpoch bonus in $CFI tokens
    /// @param newFinalizeEpochBonus The new bonus amount.
    function updateFinalizeEpochBonus(uint256 newFinalizeEpochBonus)
        external
        onlyOwner
        onlyEpochEnded
    {
        finalizeEpochBonus = newFinalizeEpochBonus;

        emit FinalizeEpochBonusUpdated(newFinalizeEpochBonus);
    }

    /// @notice Updates the threshold of CFI token a liquidity provider should have.
    /// @param newThreshold The new threshold amount in CFI tokens.
    function updateCoinbetTokenFeeWaiverThreshold(uint256 newThreshold)
        external
        onlyOwner
        onlyEpochEnded
    {
        coinbetTokenFeeWaiverThreshold = newThreshold;

        emit CoinbetTokenFeeWaiverThresholdUpdated(newThreshold);
    }

    /// @notice Updates the the withdraw time window for LPs in seconds.
    /// @param newTimeWindowSeconds The new time window in seconds
    function updateWithdrawTimeWindowSeconds(uint256 newTimeWindowSeconds)
        external
        onlyOwner
        onlyEpochEnded
    {
        withdrawTimeWindowSeconds = newTimeWindowSeconds;

        emit WithdrawTimeWindowSecondsUpdated(newTimeWindowSeconds);
    }

    /// @notice Updates the exit fee for withdrawing rewards liquidity.
    /// @param newExitFeeBps The new exit fee in basis points.
    function updateExitFeeBps(uint256 newExitFeeBps)
        external
        onlyOwner
        onlyEpochEnded
    {
        exitFeeBps = newExitFeeBps;

        emit ExitFeeUpdated(newExitFeeBps);
    }

    /// @notice Updates the reward pool max cap.
    /// @param newMaxCap The new max cap in wei.
    function updateRewardPoolMaxCap(uint256 newMaxCap)
        external
        onlyOwner
        onlyEpochEnded
    {
        poolMaxCap = newMaxCap;

        emit RewardPoolMaxCapUpdated(newMaxCap);
    }

    /// @notice Updates the Coinbet Slot Machine connected to the House Pool
    /// @param coinbetGameAddress The new Coinbet game address
    /// @param isAuthorized True or False
    function setAuthorizedCoinbetGame(
        address coinbetGameAddress,
        bool isAuthorized
    ) external onlyOwner onlyEpochEnded {
        authorizedGames[coinbetGameAddress] = isAuthorized;
        emit AuthorizedGameUpdated(coinbetGameAddress, isAuthorized);
    }

    /// @notice Places a bet, only called by the game contract
    /// @param protocolFee The protocol fee which should be deducted
    function placeBet(
        uint256 protocolFee,
        address player,
        uint256 maxWinnableAmount
    ) external payable onlyCoinbetGame onlyEpochNotEnded {
        require(
            maxWinnableAmount <= availableFundsForPayroll(),
            "Coinbet House Pool: Insufficient liquidity to payout bet"
        );
        uint256 betAmount = msg.value;
        uint256 coinbetTokenAmount = betAmount * coinbetTokenRewardMultiplier;
        pendingBetsAmount += maxWinnableAmount;

        poolBalance += (betAmount - protocolFee);
        protocolRewardsBalance += protocolFee;

        if (incentiveMode && coinbetTokenAmount <= coinbetTokenBalance()) {
            require(
                coinbetToken.transfer(player, coinbetTokenAmount),
                "Coinbet House Pool: Transcation Failed"
            );
        }
    }

    /// @notice Settles a bet and transfers win amount to winner, only called by the game contract
    /// @param winAmount The amount which should be transfered
    /// @param player Address of the winner
    function settleBet(
        uint256 winAmount,
        address player,
        uint256 maxWinnableAmount
    ) external onlyCoinbetGame {
        // Deduct the winning amount from the reward pool balance and update the bet as settled
        poolBalance -= winAmount;
        // Deduct the max winnable amount from the pending bets amount
        pendingBetsAmount -= maxWinnableAmount;

        // Transfer the won funds back to the player
        // slither-disable-next-line arbitrary-send-eth
        (bool success, ) = payable(player).call{value: winAmount}("");
        require(success, "Coinbet House Pool: Withdrawal Failed");
    }

    /// @notice Finalizes the last elapsed epoch. The protocol allows for a time window
    /// where, liquidity providers have the option to withdraw their stake, as the funds are locked
    /// during the time the epoch is active. The function is callable by anyone - the first who calls it
    /// receives a $CFI token prize
    function finalizeEpoch() public onlyEpochEnded {
        uint256 timeSinceEpochEnd = getCurrentTime() - epochEndAt();
        require(
            timeSinceEpochEnd > withdrawTimeWindowSeconds,
            "Coinbet House Pool: Withdraw phase has not ended"
        );
        epochStartedAt = calculateNextEpochStartTime(block.timestamp);

        emit EpochEnded(epochStartedAt);

        if (finalizeEpochBonus <= coinbetTokenBalance()) {
            require(
                coinbetToken.transfer(msg.sender, finalizeEpochBonus),
                "Coinbet House Pool: Transcation Failed"
            );
        }
    }

    /* ========== EVENTS ========== */

    event ExitFeeUpdated(uint256 newExitFeeBps);
    event EpochEnded(uint256 newEpochStartedAt);
    event ProtocolFeesWithdrawn(uint256 amount);
    event CoinbetTokenWithdrawn(uint256 amount);
    event RewardPoolMaxCapUpdated(uint256 newMaxCap);
    event IncentiveModeUpdated(bool newIncentiveMode);
    event HousePoolDonation(address sender, uint256 amount);
    event MaxBetToPoolRatioUpdated(uint256 newMaxBetToPoolRatio);
    event FinalizeEpochBonusUpdated(uint256 newFinalizeEpochBonus);
    event CoinbetTokenFeeWaiverThresholdUpdated(uint256 newThreshold);
    event WithdrawTimeWindowSecondsUpdated(uint256 newTimeWindowSeconds);
    event CoinbetTokenRewardMultiplierUpdated(uint256 newRewardMultiplier);
    event AuthorizedGameUpdated(address coinbetGameAddress, bool isAuthorized);
    event RewardsLiquidityAdded(uint256 amount, uint256 liquidity, address providerAddress);
    event RewardsLiquidityRemoved(uint256 amount, uint256 liquidity, address providerAddress);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.17;

interface ICoinbetHousePool {
    function addRewardsLiquidity() external payable returns (uint256 liquidity);

    function poolBalance() external returns (uint256);

    function availableFundsForPayroll() external returns (uint256);

    function placeBet(
        uint256 protocolFee,
        address player,
        uint256 maxWinnableAmount
    ) external payable;

    function settleBet(
        uint256 winAmount,
        address player,
        uint256 maxWinnableAmount
    ) external;

    function removeRewardsLiquidity(uint256 liquidity)
        external
        returns (uint256 amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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