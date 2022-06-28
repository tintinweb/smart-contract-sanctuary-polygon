// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title JamonTokenRewardVault
 * @notice Profit sharing pool on the JTR tokens deposited in stake. It distributes the tokens received based on the number of tokens staked in each wallet.
 */
contract JamonTokenRewardVault is ReentrancyGuard, Pausable, Ownable {
    //---------- Libraries ----------//
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    //---------- Contracts ----------//
    IERC20 public immutable JTR; // JTR token contract.

    //---------- Variables ----------//
    Counters.Counter public totalHolders; // Total wallets in stake.
    EnumerableSet.AddressSet internal validTokens; // Address map of valid tokens.
    uint256 constant month = 2629743; // 1 Month Timestamp.
    uint256 public totalStaked; // Total balance in stake.
    uint256 public lastUpdated; // Date in timestamp of the last balances update.
    address public treasury; // Treasury address for unstake panalty.

    //---------- Storage -----------//
    struct Wallet {
        // Tokens amount staked.
        uint256 stakedBal;
        // Dame in timestamp of the stake started.
        uint256 startTime;
        // Uint256 map of shared points.
        mapping(address => uint256) tokenPoints;
        // Uint256 map of pending rewards.
        mapping(address => uint256) pendingTokenbal;
    }

    mapping(address => Wallet) private stakeHolders; // Struct map of wallets in stake.
    mapping(address => uint256) private TokenPoints; // Uint256 map of shared points per tokens.
    mapping(address => uint256) private UnclaimedToken; // Uint256 map for store the tokens not claimed.
    mapping(address => uint256) private ProcessedToken; // Uit256 map for store the processed tokens.

    //---------- Events -----------//
    event Deposit(
        address indexed payee,
        address indexed token,
        uint256 amount,
        uint256 totalStaked
    );
    event Withdrawn(address indexed payee, address token, uint256 amount);
    event Staked(address indexed wallet, uint256 amount);
    event UnStaked(address indexed wallet, uint256 amount);

    //---------- Constructor ----------//
    constructor(address jtr_) {
        JTR = IERC20(jtr_);
        validTokens.add(jtr_);
        treasury = msg.sender;
    }

    //---------- Deposits -----------//
    /**
     * @dev Deposit and distribute permitted tokens.
     * @param token_ address of the token contract.
     * @param from_ address of the spender.
     * @param amount_ amount of tokens to distribute.
     */
    function depositTokens(
        address token_,
        address from_,
        uint256 amount_
    ) external nonReentrant {
        require(amount_ > 0, "Tokens too low");
        require(validTokens.contains(token_), "Invalid token");
        require(
            IERC20(token_).transferFrom(from_, address(this), amount_),
            "Transfer error"
        );
        _disburseToken(token_, amount_);
    }

    //----------- Internal Functions -----------//
    /**
     * @dev Distribute permitted tokens.
     * @param token_ address of the token contract.
     * @param amount_ amount of tokens to distribute.
     */
    function _disburseToken(address token_, uint256 amount_) internal {
        if (totalStaked > 1000000 && amount_ >= 1000000) {
            TokenPoints[token_] = TokenPoints[token_].add(
                (amount_.mul(10e18)).div(totalStaked)
            );
            UnclaimedToken[token_] = UnclaimedToken[token_].add(amount_);
            emit Deposit(_msgSender(), token_, amount_, totalStaked);
        }
    }

    /**
     * @dev Calculates the tokens pending distribution and distributes them if there is an undistributed amount.
     */
    function _recalculateBalances() internal virtual {
        uint256 tokensCount = validTokens.length();
        for (uint256 i = 0; i < tokensCount; i++) {
            address token = validTokens.at(i);
            uint256 balance = token == address(JTR)
                ? IERC20(token).balanceOf(address(this)).sub(totalStaked)
                : IERC20(token).balanceOf(address(this));
            uint256 processed = UnclaimedToken[token].add(
                ProcessedToken[token]
            );
            if (balance > processed) {
                uint256 pending = balance.sub(processed);
                if (pending > 1000000) {
                    _disburseToken(token, pending);
                }
            }
        }
    }

    /**
     * @dev Calculates a specific token pending distribution and distributes it if there is an undistributed amount.
     * @param token_ address of the token to calculate.
     */
    function _recalculateTokenBalance(address token_) internal virtual {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        uint256 processed = UnclaimedToken[token_].add(ProcessedToken[token_]);
        if (balance > processed) {
            uint256 pending = balance.sub(processed);
            if (pending > 1000000) {
                _disburseToken(token_, pending);
            }
        }
    }

    /**
     * @dev Process pending rewards from a wallet.
     * @param wallet_ address of the wallet to be processed.
     */
    function _processWalletTokens(address wallet_) internal virtual {
        uint256 tokensCount = validTokens.length();
        for (uint256 i = 0; i < tokensCount; i++) {
            address token = validTokens.at(i);
            _processRewardsToken(token, wallet_);
        }
    }

    /**
     * @dev Process pending rewards from a wallet in a particular token.
     * @param token_ address of the token to process.
     * @param wallet_ address of the wallet to be processed.
     */
    function _processRewardsToken(address token_, address wallet_)
        internal
        virtual
    {
        uint256 rewards = getRewardsToken(token_, wallet_);
        if (rewards > 0) {
            UnclaimedToken[token_] = UnclaimedToken[token_].sub(rewards);
            ProcessedToken[token_] = ProcessedToken[token_].add(rewards);
            stakeHolders[wallet_].tokenPoints[token_] = TokenPoints[token_];
            stakeHolders[wallet_].pendingTokenbal[token_] = stakeHolders[
                wallet_
            ].pendingTokenbal[token_].add(rewards);
        }
    }

    /**
     * @dev Withdraw pending rewards of a specific token from a wallet.
     * @param token_ address of the token to withdraw.
     * @param wallet_ address of the wallet to withdraw.
     */
    function _harvestToken(address token_, address wallet_) internal virtual {
        _processRewardsToken(token_, wallet_);
        uint256 amount = stakeHolders[wallet_].pendingTokenbal[token_];
        if (amount > 0) {
            stakeHolders[wallet_].pendingTokenbal[token_] = 0;
            ProcessedToken[token_] = ProcessedToken[token_].sub(amount);
            IERC20(token_).transfer(wallet_, amount);
            emit Withdrawn(wallet_, token_, amount);
        }
    }

    /**
     * @dev Withdraw pending rewards of all tokens from a wallet.
     * @param wallet_ address of the wallet to withdraw.
     */
    function _harvestAll(address wallet_) internal virtual {
        _processWalletTokens(wallet_);
        uint256 tokensCount = validTokens.length();
        for (uint256 i = 0; i < tokensCount; i++) {
            address token = validTokens.at(i);
            uint256 amount = stakeHolders[wallet_].pendingTokenbal[token];
            if (amount > 0) {
                stakeHolders[wallet_].pendingTokenbal[token] = 0;
                ProcessedToken[token] = ProcessedToken[token].sub(amount);
                IERC20(token).transfer(wallet_, amount);
                emit Withdrawn(wallet_, token, amount);
            }
        }
    }

    /**
     * @dev Initialize a wallet joined with the current participation points.
     * @param wallet_ address of the wallet to initialize.
     */
    function _initWalletPoints(address wallet_) internal virtual {
        uint256 tokensCount = validTokens.length();
        Wallet storage w = stakeHolders[wallet_];
        for (uint256 i = 0; i < tokensCount; i++) {
            address token = validTokens.at(i);
            w.tokenPoints[token] = TokenPoints[token];
        }
    }

    /**
     * @dev Add a wallet to stake for the first time.
     * @param wallet_ address of the wallet to add.
     * @param amount_ amount to add.
     */
    function _initStake(address wallet_, uint256 amount_)
        internal
        virtual
        returns (bool)
    {
        _recalculateBalances();
        _initWalletPoints(wallet_);
        bool success = JTR.transferFrom(wallet_, address(this), amount_);
        stakeHolders[wallet_].startTime = block.timestamp;
        stakeHolders[wallet_].stakedBal = amount_;
        totalStaked = totalStaked.add(amount_);
        totalHolders.increment();
        return success;
    }

    /**
     * @dev Add more tokens to stake from an existing wallet.
     * @param wallet_ address of the wallet.
     * @param amount_ amount to add.
     */
    function _addStake(address wallet_, uint256 amount_)
        internal
        virtual
        returns (bool)
    {
        _recalculateBalances();
        _processWalletTokens(wallet_);
        bool success = JTR.transferFrom(wallet_, address(this), amount_);
        stakeHolders[wallet_].stakedBal = stakeHolders[wallet_].stakedBal.add(
            amount_
        );
        totalStaked = totalStaked.add(amount_);

        return success;
    }

    /**
     * @dev Calculates the penalty for unstake based on the time you have in stake. Being a penalty of 1% on the balance per month in advance before a year.
     * @param wallet_ address of the wallet.
     * @return the amount of tokens to receive.
     */
    function _unStakeBal(address wallet_) internal virtual returns (uint256) {
        uint256 accumulated = block.timestamp.sub(
            stakeHolders[wallet_].startTime
        );
        uint256 balance = stakeHolders[wallet_].stakedBal;
        uint256 minPercent = 88;
        if (accumulated >= month.mul(12)) {
            return balance;
        }
        balance = balance.mul(10e18);
        if (accumulated < month) {
            balance = (balance.mul(minPercent)).div(100);
            return balance.div(10e18);
        }
        for (uint256 m = 1; m < 12; m++) {
            if (accumulated >= month.mul(m) && accumulated < month.mul(m + 1)) {
                minPercent = minPercent.add(m);
                balance = (balance.mul(minPercent)).div(100);
                return balance.div(10e18);
            }
        }
        return 0;
    }

    /**
     * @dev Check the reward amount of a specific token plus the processed balance.
     * @param token_ Address of token to check.
     * @param wallet_ Address of the wallet to check.
     * @return Amount of reward plus the processed for that token.
     */
    function _getPendingBal(address token_, address wallet_)
        internal
        view
        returns (uint256)
    {
        uint256 newTokenPoints = TokenPoints[token_].sub(
            stakeHolders[wallet_].tokenPoints[token_]
        );
        uint256 pending = stakeHolders[wallet_].pendingTokenbal[token_];
        return
            (stakeHolders[wallet_].stakedBal.mul(newTokenPoints))
                .div(10e18)
                .add(pending);
    }

    //----------- External Functions -----------//
    /**
     * @notice Check if a wallet address is in stake.
     * @return Boolean if in stake or not.
     */
    function isInStake(address wallet_) public view returns (bool) {
        return stakeHolders[wallet_].stakedBal > 0;
    }

    /**
     * @notice Check if a token address is distributing rewards.
     * @return Boolean if distributing.
     */
    function isValidToken(address token_) external view returns (bool) {
        return validTokens.contains(token_);
    }

    /**
     * @notice Check the reward amount of a specific token.
     * @param token_ Address of token to check.
     * @param wallet_ Address of the wallet to check.
     * @return Amount of reward for that token.
     */
    function getRewardsToken(address token_, address wallet_)
        public
        view
        returns (uint256)
    {
        uint256 newTokenPoints = TokenPoints[token_].sub(
            stakeHolders[wallet_].tokenPoints[token_]
        );
        return (stakeHolders[wallet_].stakedBal.mul(newTokenPoints)).div(10e18);
    }

    /**
     * @notice Check the reward amount of a specific token plus the processed balance and pending update.
     * @param token_ Address of token to check.
     * @param wallet_ Address of the wallet to check.
     * @return Amount of reward plus the processed for that token.
     */
    function getPendingBal(address token_, address wallet_)
        external
        view
        returns (uint256)
    {
        uint256 processedBal = _getPendingBal(token_, wallet_);
        uint256 balance = token_ == address(JTR)
            ? IERC20(token_).balanceOf(address(this)).sub(totalStaked)
            : IERC20(token_).balanceOf(address(this));
        uint256 processed = UnclaimedToken[token_].add(ProcessedToken[token_]);
        if (balance > processed) {
            uint256 pending = balance.sub(processed);
            {
                if (pending > 1000000) {
                    address holder = wallet_;
                    uint256 oldTokenPoints = TokenPoints[token_].add(
                        (pending.mul(10e18)).div(totalStaked)
                    );
                    uint256 newTokenPoints = oldTokenPoints.sub(
                        stakeHolders[holder].tokenPoints[token_]
                    );
                    uint256 pendingBal = stakeHolders[wallet_].pendingTokenbal[
                        token_
                    ];
                    uint256 unprocessedBal = (
                        stakeHolders[holder].stakedBal.mul(newTokenPoints)
                    ).div(10e18);
                    return unprocessedBal.add(pendingBal);
                }
            }
        }
        return processedBal;
    }

    /**
     * @notice Check the info of stake for a wallet.
     * @param wallet_ Address of the wallet to check.
     * @return stakedBal amount of tokens staked.
     * @return startTime date in timestamp of the stake started.
     */
    function getWalletInfo(address wallet_)
        external
        view
        returns (uint256 stakedBal, uint256 startTime)
    {
        Wallet storage w = stakeHolders[wallet_];
        return (w.stakedBal, w.startTime);
    }

    /**
     * @notice Check if you have rewards for claiming or not.
     * @return If have reawrds.
     */
    function pendingBalances() external view returns (bool) {
        uint256 tokensCount = validTokens.length();
        for (uint256 i = 0; i < tokensCount; i++) {
            address token = validTokens.at(i);
            uint256 balance = token == address(JTR)
                ? IERC20(token).balanceOf(address(this)).sub(totalStaked)
                : IERC20(token).balanceOf(address(this));
            uint256 processed = UnclaimedToken[token].add(
                ProcessedToken[token]
            );
            if (balance > processed) {
                uint256 pending = balance.sub(processed);
                if (pending > 1000000) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @notice Stake tokens to receive rewards.
     * @param amount_ Amount of tokens to deposit.
     */
    function stake(uint256 amount_) external whenNotPaused nonReentrant {
        require(amount_ > 1000000, "Amount too low");
        require(
            JTR.allowance(_msgSender(), address(this)) >= amount_,
            "Amount not allowed"
        );

        if (isInStake(_msgSender())) {
            require(_addStake(_msgSender(), amount_), "Add stake error");
        } else {
            require(_initStake(_msgSender(), amount_), "Init stake error");
        }
        emit Staked(_msgSender(), amount_);
    }

    /**
     * @notice Withdraw rewards from a specific token.
     * @param token_ address of tokens to withdraw.
     */
    function harvestToken(address token_) external whenNotPaused nonReentrant {
        require(isInStake(_msgSender()), "Not in stake");
        require(validTokens.contains(token_), "Invalid token");
        _recalculateTokenBalance(token_);
        _harvestToken(token_, _msgSender());
    }

    /**
     * @notice Withdraw rewards from all tokens.
     */
    function harvestAll() external whenNotPaused nonReentrant {
        require(isInStake(_msgSender()), "Not in stake");
        _harvestAll(_msgSender());
    }

    /**
     * @notice Withdraw stake tokens and collect rewards.
     */
    function unStake() external whenNotPaused nonReentrant {
        require(isInStake(_msgSender()), "Not in stake");
        _harvestAll(_msgSender());
        uint256 stakedBal = stakeHolders[_msgSender()].stakedBal;
        uint256 balance = _unStakeBal(_msgSender());
        uint256 balanceDiff = stakedBal.sub(balance);
        if (balance > 0) {
            require(JTR.transfer(_msgSender(), balance), "Transfer error");
        }
        totalStaked = totalStaked.sub(stakedBal);
        delete stakeHolders[_msgSender()];
        totalHolders.decrement();
        if (balanceDiff > 0) {
            JTR.transfer(treasury, balanceDiff);
        }
        emit UnStaked(_msgSender(), balance);
    }

    /**
     * @notice Safely withdraw staking tokens without collecting rewards.
     */
    function safeUnStake() external whenPaused nonReentrant {
        require(isInStake(_msgSender()), "Not in stake");
        uint256 stakedBal = stakeHolders[_msgSender()].stakedBal;
        delete stakeHolders[_msgSender()];
        require(JTR.transfer(_msgSender(), stakedBal), "Transfer error");
        totalStaked = totalStaked.sub(stakedBal);
        totalHolders.decrement();
    }

    /**
     * @notice Update balances pending distribution if any.
     */
    function updateBalances() external whenNotPaused nonReentrant {
        if (lastUpdated.add(10 minutes) < block.timestamp) {
            lastUpdated = block.timestamp;
            _recalculateBalances();
        }
    }

    /**
     * @notice Updates the balances pending distribution of a specific token in case there are any.
     * @param token_ address of token for update the pending balance.
     */
    function updateTokenBalance(address token_)
        external
        whenNotPaused
        nonReentrant
    {
        require(validTokens.contains(token_), "Invalid token");
        _recalculateTokenBalance(token_);
    }

    /**
     * @notice Modify the list of valid tokens.
     * @param token_ address of token to add on list.
     * @param add_ boolean to enable or disable the token.
     */
    function setTokenList(address token_, bool add_) external onlyOwner {
        require(
            token_ != address(0) && token_ != address(JTR),
            "Invalid address"
        );
        if (add_) {
            validTokens.add(token_);
        } else {
            validTokens.remove(token_);
        }
    }

    /**
     * @notice Change treasury address.
     * @param treasury_ new treasury address.
     */
    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "Invalid address");
        treasury = treasury_;
    }

    /**
     * @notice Get invalid tokens and send to Governor.
     * @param token_ address of token to send.
     */
    function getInvalidTokens(address to_, address token_) external onlyOwner {
        require(to_ != address(0x0), "Invalid to address");
        require(!validTokens.contains(token_), "Invalid token");
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(to_, balance);
    }

    /**
     * @dev Flips the pause state
     */
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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