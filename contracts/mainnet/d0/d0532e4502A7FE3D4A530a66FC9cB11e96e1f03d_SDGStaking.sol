//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IStaking.sol";
import "./IBorderlessNFT.sol";
import "./strategy/IStrategy.sol";

contract SDGStaking is IStaking, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public name;
    address public feeReceiver;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    IERC20 _usdc;
    IBorderlessNFT _nft;
    Counters.Counter _epochCounter;
    Counters.Counter _initiativesCounter;
    EnumerableSet.AddressSet _activeStrategies;
    EnumerableSet.UintSet _activeInitiatives;
    bool _sharesNeedsUpdate;

    mapping(uint256 => StoredBalance) _epochIdToStoredBalances;
    mapping(uint256 => StakeInfo) _stakeIdToStakeInfo;
    mapping(StakeStatus => EnumerableSet.UintSet) _stakeStatusToStakeIds;
    mapping(uint256 => Initiative) _initiatives;
    mapping(StakePeriod => uint256) _stakePeriodToFee;

    constructor(
        address nft,
        address usdc,
        address sdgFeeReceiver,
        string memory sdgName
    ) {
        _nft = IBorderlessNFT(nft);
        _usdc = IERC20(usdc);
        feeReceiver = sdgFeeReceiver;
        name = sdgName;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTROLLER_ROLE, msg.sender);

        setStakePeriodFees(3, 2, 1);
    }

    function stake(
        uint256 amount,
        StakePeriod period,
        address operator
    ) external override {
        if (amount == 0) {
            revert InvalidAmount(amount, 1**10 * 6);
        }

        uint256 stakeId = _nft.safeMint(operator, address(this));

        bool sent = _usdc.transferFrom(operator, address(this), amount);
        if (!sent) {
            revert TransferFailed(
                address(_usdc),
                operator,
                address(this),
                amount
            );
        }

        uint256 _epoch = _epochCounter.current();
        _epochIdToStoredBalances[_epoch].nextEpochBalance += amount;

        _stakeIdToStakeInfo[stakeId] = StakeInfo({
            amount: amount,
            createdAt: block.timestamp,
            stakePeriod: period,
            status: StakeStatus.UNDELEGATED,
            strategies: new address[](0),
            shares: new uint256[](0),
            epoch: _epoch + 1
        });

        _stakeStatusToStakeIds[StakeStatus.UNDELEGATED].add(stakeId);

        emit Stake(stakeId, amount, 10, operator);
    }

    function _periodToTimestamp(StakePeriod period)
        internal
        pure
        returns (uint256 timestamp)
    {
        if (period == StakePeriod.THREE_MONTHS) {
            return 3 * 30 days;
        } else if (period == StakePeriod.SIX_MONTHS) {
            return 6 * 30 days;
        }

        return 12 * 30 days;
    }

    function computeFee(
        uint256 initialAmount,
        uint256 stakedAt,
        StakePeriod stakePeriod
    ) public view returns (uint256 finalAmount, uint256 totalFee) {
        if (block.timestamp > stakedAt + _periodToTimestamp(stakePeriod)) {
            return (initialAmount, 0);
        }

        uint256 fee = _stakePeriodToFee[stakePeriod];
        totalFee = (fee * initialAmount) / 100;
        finalAmount = initialAmount - totalFee;

        return (finalAmount, totalFee);
    }

    function exit(uint256 stakeId) external nonReentrant {
        if (_nft.ownerOf(stakeId) != msg.sender) {
            revert NotOwnerOfStake(msg.sender, _nft.ownerOf(stakeId), stakeId);
        }
        _nft.burn(stakeId);

        StakeInfo storage stakeInfo = _stakeIdToStakeInfo[stakeId];

        if (stakeInfo.amount == 0) {
            revert NothingToUnstake();
        }

        uint256 undelegatedAmount;

        if (stakeInfo.status == StakeStatus.DELEGATED) {
            _stakeStatusToStakeIds[StakeStatus.DELEGATED].remove(stakeId);
            undelegatedAmount = _undelegate(stakeId);
        } else {
            _stakeStatusToStakeIds[StakeStatus.UNDELEGATED].remove(stakeId);
            undelegatedAmount = stakeInfo.amount;
        }

        (uint256 finalAmount, uint256 totalFee) = computeFee(
            undelegatedAmount,
            stakeInfo.createdAt,
            stakeInfo.stakePeriod
        );

        if (totalFee > 0) {
            bool feeSent = _usdc.transfer(feeReceiver, totalFee);
            if (!feeSent) {
                revert TransferFailed(
                    address(_usdc),
                    address(this),
                    feeReceiver,
                    totalFee
                );
            }
        }

        bool sent = _usdc.transfer(msg.sender, finalAmount);
        if (!sent) {
            revert TransferFailed(
                address(_usdc),
                address(this),
                msg.sender,
                finalAmount
            );
        }

        delete _stakeIdToStakeInfo[stakeId];
        emit Exit(stakeId, finalAmount);
    }

    function _undelegate(uint256 stakeId) internal returns (uint256 amount) {
        StakeInfo storage stakeInfo = _stakeIdToStakeInfo[stakeId];
        if (stakeInfo.status != StakeStatus.DELEGATED) {
            revert StakeIsNotDelegated(stakeId);
        }

        uint256 totalStrategies = stakeInfo.strategies.length;
        for (uint256 i = 0; i < totalStrategies; i++) {
            IStrategy strategy = IStrategy(stakeInfo.strategies[i]);
            uint256 strategyAmount = (stakeInfo.amount * stakeInfo.shares[i]) /
                100;
            amount += strategy.undelegate(strategyAmount);
        }

        return amount;
    }

    function stakeInfoByStakeId(uint256 stakeId)
        public
        view
        override
        returns (StakeInfo memory)
    {
        return _stakeIdToStakeInfo[stakeId];
    }

    function storedBalanceInCurrentEpoch()
        public
        view
        returns (StoredBalance memory)
    {
        uint256 _epoch = _epochCounter.current();
        return storedBalanceByEpochId(_epoch);
    }

    function storedBalanceByEpochId(uint256 epochId)
        public
        view
        override
        returns (StoredBalance memory)
    {
        return _epochIdToStoredBalances[epochId];
    }

    function stakeBalanceByStatus(StakeStatus status)
        public
        view
        override
        returns (uint256 balance)
    {
        uint256 total = _stakeStatusToStakeIds[status].length();

        for (uint256 i = 0; i < total; i++) {
            StakeInfo memory stakeInfo = _stakeIdToStakeInfo[
                _stakeStatusToStakeIds[status].at(i)
            ];
            balance += stakeInfo.amount;
        }
    }

    function stakesByStatus(StakeStatus status)
        public
        view
        override
        returns (uint256[] memory stakeIds)
    {
        uint256 total = _stakeStatusToStakeIds[status].length();
        stakeIds = new uint256[](total);

        for (uint256 i = 0; i < total; i++) {
            stakeIds[i] = _stakeStatusToStakeIds[status].at(i);
        }

        return stakeIds;
    }

    function feeByStakePeriod(StakePeriod period)
        public
        view
        override
        returns (uint256 fee)
    {
        return _stakePeriodToFee[period];
    }

    function setStakePeriodFees(
        uint256 threeMonthsFee,
        uint256 sixMonthsFee,
        uint256 oneYearFee
    ) public onlyRole(CONTROLLER_ROLE) {
        _stakePeriodToFee[StakePeriod.THREE_MONTHS] = threeMonthsFee;
        _stakePeriodToFee[StakePeriod.SIX_MONTHS] = sixMonthsFee;
        _stakePeriodToFee[StakePeriod.ONE_YEAR] = oneYearFee;
    }

    function setFeeReceiver(address newReceiver)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        feeReceiver = newReceiver;
    }

    function delegateAll(address[] memory strategies, uint256[] memory shares)
        external
        override
        onlyRole(CONTROLLER_ROLE)
    {
        if (strategies.length == 0) {
            revert EmptyStrategies();
        }
        if (strategies.length != shares.length) {
            revert StrategiesAndSharesLengthsNotEqual(
                strategies.length,
                shares.length
            );
        }

        uint256 totalShares;
        for (uint256 i = 0; i < strategies.length; i++) {
            totalShares += shares[i];
        }
        if (totalShares != 100) {
            revert InvalidSharesSum(totalShares, 100);
        }

        uint256 totalUndelegated = _stakeStatusToStakeIds[
            StakeStatus.UNDELEGATED
        ].length();
        uint256 undelegatedAmount = 0;
        for (uint256 i = totalUndelegated; i > 0; i--) {
            uint256 stakeId = _stakeStatusToStakeIds[StakeStatus.UNDELEGATED]
                .at(i - 1);
            StakeInfo memory stakeInfo = _stakeIdToStakeInfo[stakeId];
            undelegatedAmount += stakeInfo.amount;
            _stakeIdToStakeInfo[stakeId].status = StakeStatus.DELEGATED;
            _stakeIdToStakeInfo[stakeId].strategies = strategies;
            _stakeIdToStakeInfo[stakeId].shares = shares;
            _stakeStatusToStakeIds[StakeStatus.UNDELEGATED].remove(i - 1);
            _stakeStatusToStakeIds[StakeStatus.DELEGATED].add(stakeId);
        }

        if (undelegatedAmount == 0) {
            revert NothingToDelegate();
        }

        for (uint256 i = 0; i < strategies.length; i++) {
            if (!_activeStrategies.contains(strategies[i])) {
                revert InvalidStrategy(strategies[i]);
            }
            IStrategy strategy = IStrategy(strategies[i]);
            uint256 amount = (undelegatedAmount * shares[i]) / 100;
            _usdc.approve(address(strategy), amount);
            strategy.delegate(amount);
        }
    }

    function endEpoch() external override onlyRole(CONTROLLER_ROLE) {
        if (_sharesNeedsUpdate) {
            revert InitiativesSharesNeedToBeUpdated();
        }

        _epochCounter.increment();
        uint256 currentEpoch = _epochCounter.current();
        _epochIdToStoredBalances[currentEpoch] = StoredBalance({
            currentEpoch: currentEpoch,
            currentEpochBalance: _epochIdToStoredBalances[currentEpoch - 1]
                .nextEpochBalance,
            nextEpochBalance: 0
        });
    }

    function addStrategy(address strategy)
        external
        override
        onlyRole(CONTROLLER_ROLE)
    {
        _activeStrategies.add(strategy);
    }

    function removeStrategy(address strategy)
        external
        override
        onlyRole(CONTROLLER_ROLE)
    {
        _activeStrategies.remove(strategy);
    }

    function activeStrategies()
        public
        view
        returns (address[] memory strategies)
    {
        uint256 total = _activeStrategies.length();
        strategies = new address[](total);

        for (uint256 i = 0; i < total; i++) {
            strategies[i] = _activeStrategies.at(i);
        }

        return strategies;
    }

    function totalRewards() external view override returns (uint256 amount) {
        uint256 totalStrategies = _activeStrategies.length();
        for (uint256 i = 0; i < totalStrategies; i++) {
            IStrategy strategy = IStrategy(_activeStrategies.at(i));
            amount += strategy.availableRewards(address(this));
        }

        return amount;
    }

    function collectedRewards()
        external
        view
        override
        returns (uint256 amount)
    {
        uint256 totalStrategies = _activeStrategies.length();
        for (uint256 i = 0; i < totalStrategies; i++) {
            IStrategy strategy = IStrategy(_activeStrategies.at(i));
            amount += strategy.collectedRewards(address(this));
        }

        return amount;
    }

    function distributeRewards() external override onlyRole(CONTROLLER_ROLE) {
        if (_sharesNeedsUpdate) {
            revert InitiativesSharesNeedToBeUpdated();
        }

        uint256 totalStrategies = _activeStrategies.length();
        uint256 amount;
        for (uint256 i = 0; i < totalStrategies; i++) {
            IStrategy strategy = IStrategy(_activeStrategies.at(i));
            uint256 availableRewards = strategy.availableRewards(address(this)) -
                strategy.collectedRewards(address(this));
            amount += strategy.collectRewards(availableRewards);
        }

        uint256 totalInitiatives = _activeInitiatives.length();
        if (totalInitiatives == 0) {
            revert EmptyInitiatives();
        }

        for (uint256 i = 0; i < totalInitiatives; i++) {
            Initiative memory initiative = _initiatives[
                _activeInitiatives.at(i)
            ];
            uint256 initiativeAmount = (amount * initiative.share) / 100;
            bool sent = _usdc.transfer(initiative.controller, initiativeAmount);
            if (!sent) {
                revert TransferFailed(
                    address(_usdc),
                    address(this),
                    initiative.controller,
                    initiativeAmount
                );
            }
        }
    }

    function addInitiative(string memory initiativeName, address controller)
        public
        override
        onlyRole(CONTROLLER_ROLE)
        returns (uint256 initiativeId)
    {
        initiativeId = _initiativesCounter.current();
        _initiativesCounter.increment();

        _activeInitiatives.add(initiativeId);
        _sharesNeedsUpdate = true;

        _initiatives[initiativeId] = Initiative({
            id: initiativeId,
            name: initiativeName,
            share: 0,
            collectedRewards: 0,
            controller: controller,
            active: true
        });

        return initiativeId;
    }

    function removeInitiative(uint256 initiativeId)
        public
        onlyRole(CONTROLLER_ROLE)
    {
        _activeInitiatives.remove(initiativeId);
        _initiatives[initiativeId].active = false;
        _sharesNeedsUpdate = true;
    }

    function setInitiativesShares(
        uint256[] memory initiativeIds,
        uint256[] memory shares
    ) public override onlyRole(CONTROLLER_ROLE) {
        if (initiativeIds.length == 0) {
            revert EmptyInitiatives();
        }
        if (initiativeIds.length != shares.length) {
            revert InitiativesAndSharesLengthsNotEqual(
                initiativeIds.length,
                shares.length
            );
        }

        _sharesNeedsUpdate = false;

        uint256 totalShares;
        for (uint256 i = 0; i < initiativeIds.length; i++) {
            totalShares += shares[i];
            _initiatives[initiativeIds[i]].share = shares[i];

            if (!_activeInitiatives.contains(initiativeIds[i])) {
                revert InitiativeNotActive(initiativeIds[i]);
            }
        }
        if (totalShares != 100) {
            revert InvalidSharesSum(totalShares, 100);
        }
    }

    function initiatives()
        public
        view
        override
        returns (Initiative[] memory activeInitiatives)
    {
        uint256 total = _activeInitiatives.length();
        activeInitiatives = new Initiative[](total);
        for (uint256 i = 0; i < total; i++) {
            activeInitiatives[i] = _initiatives[_activeInitiatives.at(i)];
        }
        return activeInitiatives;
    }

    function epoch() public view override returns (uint256) {
        return _epochCounter.current();
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// Invalid balance to transfer. Needed `minRequired` but sent `amount`
/// @param sent sent amount.
/// @param minRequired minimum amount to send.
error InvalidAmount(uint256 sent, uint256 minRequired);

/// Strategies cannot be empty
error EmptyStrategies();

/// Strategies and shares lenghts must be equal.
/// @param strategiesLenght lenght of strategies array.
/// @param sharesLenght lenght of shares array.
error StrategiesAndSharesLengthsNotEqual(
    uint256 strategiesLenght,
    uint256 sharesLenght
);

/// Invalid shares sum. Needed `requiredSum` but sent `sum`
/// @param sum sum of shares.
/// @param requiredSum required sum of shares.
error InvalidSharesSum(uint256 sum, uint256 requiredSum);

/// Nothing to delegate
error NothingToDelegate();

/// SDG must not have any USDC left to finish the epoch.
/// @param usdcBalance balance of USDC.
error USDCBalanceIsNotZero(uint256 usdcBalance);

/// Strategy is not active or not exists.
/// @param strategyAddress address of strategy.
error InvalidStrategy(address strategyAddress);

/// Trying to exit a stake thats not owned by the sender.
/// @param sender sender address.
/// @param owner owner address.
/// @param stakeId stake id.
error NotOwnerOfStake(address sender, address owner, uint256 stakeId);

/// Nothing to unstake
error NothingToUnstake();

/// Stake is not delegated
/// @param stakeId stake id.
error StakeIsNotDelegated(uint256 stakeId);

/// Initiatives cannot be empty
error EmptyInitiatives();

/// Initiative ids and shares lenghts must be equal.
/// @param initiativeIdsLength lenght of initiative ids array.
/// @param sharesLenght lenght of shares array.
error InitiativesAndSharesLengthsNotEqual(
    uint256 initiativeIdsLength,
    uint256 sharesLenght
);

/// Initiative is not active
/// @param initiativeId id of initiative.
error InitiativeNotActive(uint256 initiativeId);

/// Initiatives shares neeed to be updated
error InitiativesSharesNeedToBeUpdated();

interface IStaking {
    event Stake(
        uint256 stakeId,
        uint256 amount,
        uint256 stakePeriod,
        address operator
    );
    event Exit(uint256 stakeId, uint256 amount);

    enum StakeStatus {
        UNDELEGATED,
        DELEGATED
    }

    enum StakePeriod {
        THREE_MONTHS,
        SIX_MONTHS,
        ONE_YEAR
    }

    struct StoredBalance {
        uint256 currentEpoch;
        uint256 currentEpochBalance;
        uint256 nextEpochBalance;
    }

    struct StakeInfo {
        StakeStatus status;
        uint256 amount;
        uint256 createdAt;
        StakePeriod stakePeriod;
        uint256 epoch;
        address[] strategies;
        uint256[] shares;
    }

    struct Initiative {
        uint256 id;
        string name;
        uint256 share;
        uint256 collectedRewards;
        address controller;
        bool active;
    }

    /// @dev Stake USDC tokens into SDG. Tokens are stored on the SDG until its delegation to strategies.
    /// @param amount of USDC to stake.
    /// @param period of stake.
    /// @param operator operator address.
    function stake(
        uint256 amount,
        StakePeriod period,
        address operator
    ) external;

    /// @dev Unstake USDC tokens from SDG. Tokens are returned to the sender.
    /// @param stakeId of stake to unstake.
    function exit(uint256 stakeId) external;

    function stakesByStatus(StakeStatus status)
        external
        view
        returns (uint256[] memory stakeIds);

    function stakeInfoByStakeId(uint256 stakeId)
        external
        view
        returns (StakeInfo memory);

    function storedBalanceByEpochId(uint256 epochId)
        external
        view
        returns (StoredBalance memory);

    function stakeBalanceByStatus(StakeStatus status)
        external
        view
        returns (uint256 balance);

    function computeFee(
        uint256 initialAmount,
        uint256 stakedAt,
        StakePeriod stakePeriod
    ) external view returns (uint256 finalAmount, uint256 totalFee);

    function feeByStakePeriod(StakePeriod period)
        external
        view
        returns (uint256 fee);

    function setStakePeriodFees(
        uint256 threeMonthsFee,
        uint256 sixMonthsFee,
        uint256 oneYearFee
    ) external;

    function setFeeReceiver(address) external;

    /// @dev Move USDC tokens to strategies by splitting the remaing balance and delegating it to each strategy.
    /// @param strategies of USDC to stake.
    /// @param shares of USDC to stake.
    function delegateAll(address[] memory strategies, uint256[] memory shares)
        external;

    function addStrategy(address strategy) external;

    function removeStrategy(address strategy) external;

    function activeStrategies() external view returns (address[] memory);

    function endEpoch() external;

    function totalRewards() external view returns (uint256);

    function collectedRewards() external view returns (uint256);

    function distributeRewards() external;

    function addInitiative(string memory name, address controller)
        external
        returns (uint256 initiativeId);

    function removeInitiative(uint256 initiativeId) external;

    function setInitiativesShares(
        uint256[] memory initiativeIds,
        uint256[] memory shares
    ) external;

    function initiatives() external view returns (Initiative[] memory);

    /// @dev Current epoch id
    /// @return Current epoch id
    function epoch() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBorderlessNFT {
    function safeMint(address to, address sdgOperator) external returns (uint256 stakeId);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function operatorByTokenId(uint256 tokenId) external view returns (address);

    function endEpoch() external;

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// Invalid rewards amount. Needed up to `maximumAmount` but sent `amount`
/// @param amount amount collecting
/// @param maximumAmount total rewards available to collect
error InvalidRewardsAmount(uint256 amount, uint256 maximumAmount);

/// Transfer could not be completed.
/// @param token token to transfer.
/// @param from sender address
/// @param to receiver address
/// @param amount amount to transfer.
error TransferFailed(address token, address from, address to, uint256 amount);

interface IStrategy {
    event Delegate(uint256 amount);
    event Withdraw(uint256 amount);
    event CollectRewards(uint256 amount);

    /// @dev Transfer USDC tokens to the strategy contract.
    /// @param amount The amount of USDC tokens to transfer.
    function delegate(uint256 amount) external;

    /// @dev Withdraw USDC tokens from the strategy contract.
    /// @param amount The amount of USDC tokens to withdraw.
    /// @return finalAmount The amount of USDC tokens actually withdrawn.
    function undelegate(uint256 amount) external returns (uint256 finalAmount);

    /// @dev Compute the total rewards for the given SDG.
    /// @param sdg The SDG to compute the rewards for.
    /// @return The total rewards for the given SDG.
    function availableRewards(address sdg) external view returns (uint256);

    /// @dev Compute the total rewards collected by the given SDG.
    /// @param sdg The SDG to compute the rewards for.
    /// @return The total rewards collected by the given SDG.
    function collectedRewards(address sdg) external view returns (uint256);

    /// @dev Collect rewards for the given SDG.
    /// @return finalAmount The amount of USDC tokens actually collected.
    function collectRewards(uint256 amount) external returns (uint256 finalAmount);

    /// @dev Compute the total balance without rewards of the SDG on the strategy.
    /// @param sdg The SDG to compute the balance for.
    /// @return The total balance without rewards of the SDG on the strategy.
    function balanceOf(address sdg) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}