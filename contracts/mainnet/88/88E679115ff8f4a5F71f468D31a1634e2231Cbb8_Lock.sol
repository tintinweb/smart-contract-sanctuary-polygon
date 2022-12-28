pragma solidity ^0.8.7;

// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IRewardController.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/IController.sol";
import "./ControlledEntry.sol";
import "./interfaces/IPriceFeed.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Lock is ControlledEntry, ReentrancyGuardUpgradeable  {

    // ETH
    IERC20 public depositToken;

    struct DepositInfo {
        uint256 deposit;
        uint128 timeLast;
        uint256 devMultiplicator;
        uint256 amountMultiplicator;
        // save total rewards for correct burn on withdraw
        uint256 totalRewards;
    }
    mapping(address => DepositInfo) public deposits;

    struct VirtualDepositInfo {
        uint256 virtualDeposit;
        uint128 initTime;
        uint128 finishTime;
    }
    mapping(address => VirtualDepositInfo) public virtualDeposits;

    using EnumerableSet for EnumerableSet.AddressSet;

    struct RewardShareData {
        EnumerableSet.AddressSet rewardSharesUsers;
        mapping(address => uint256) rewardSharesPercent;
        uint256 totalPercent;
        bool active;
    }
    // user may distribute their rewards to another wallets
    // but in this case it can't normal withdraw (can't  burn Staby tokens)
    mapping(address => RewardShareData) rewardShares;

    struct MultiplicatorPair {
        uint128 level;
        uint128 value;
    }
    mapping(uint256 => uint256) devFeeMultiplicator;
    MultiplicatorPair[] amountMultiplicator;

    uint256 public startTime;

    uint256 public minLiquidity;

    IPriceFeed public chainLinkOracle;

    uint256 constant MAX_SHARED_REWARDS = 100 * 1e6;

    event Deposit(address _user, uint256 _amount);
    event VirtualDeposit(address _user, uint256 _amount, uint128 _duration);
    event Withdraw(address _user, uint256 _amount);
    event Reward(address _user, uint256 _amount);
    event MinLiquidityChanged(uint256 _newMinLiquidity);

    modifier onlyHumans() {
        require(msg.sender == tx.origin, "!only humans");
        _;
    }

    function getTimeBeforeStart() view public returns(uint256) {
        return (startTime > block.timestamp) ? (startTime - block.timestamp) : 0;
    }

    function initialize(address _controller, address _depositToken, uint256 _startTime, uint256 _minLiquidity, IPriceFeed _chainLinkOracle) public initializer {
        ControlledEntry_Init(_controller);
        __ReentrancyGuard_init();
        depositToken = IERC20(_depositToken);

        chainLinkOracle = _chainLinkOracle;
        minLiquidity = _minLiquidity;
        devFeeMultiplicator[0]                = 1e18;
        devFeeMultiplicator[0.1 * 1e18 / 100] = 1.1 * 1e18;
        devFeeMultiplicator[0.5 * 1e18 / 100] = 2   * 1e18;
        devFeeMultiplicator[1   * 1e18 / 100] = 3   * 1e18;
        devFeeMultiplicator[2   * 1e18 / 100] = 5   * 1e18;
        devFeeMultiplicator[5   * 1e18 / 100] = 8   * 1e18;
        devFeeMultiplicator[10  * 1e18 / 100] = 10  * 1e18;

        amountMultiplicator.push(MultiplicatorPair(10000   * 1e18, 1.5 * 1e18));
        amountMultiplicator.push(MultiplicatorPair(25000   * 1e18, 3   * 1e18));
        amountMultiplicator.push(MultiplicatorPair(50000   * 1e18, 5   * 1e18));
        amountMultiplicator.push(MultiplicatorPair(100000  * 1e18, 7   * 1e18));
        amountMultiplicator.push(MultiplicatorPair(500000  * 1e18, 8   * 1e18));
        amountMultiplicator.push(MultiplicatorPair(1000000 * 1e18, 10  * 1e18));

        require(_startTime > block.timestamp, "!wrong start time");
        startTime = _startTime;
    }

    function setMinLiquidity(uint256 _newMinLiquidity) external {
        require(msg.sender == controller.owner(), "!auth");
        minLiquidity = _newMinLiquidity;
        emit MinLiquidityChanged(_newMinLiquidity);
    }

    function setSharedRewards(address _userAddress, uint128 _newPercent) onlyHumans external {
        RewardShareData storage data = rewardShares[msg.sender];
        uint256 _len = data.rewardSharesUsers.length();
        require(_len < 50, "!too many users");
        uint256 _oldP = data.rewardSharesPercent[_userAddress];
        data.rewardSharesPercent[_userAddress] = _newPercent;
        data.totalPercent -= _oldP;
        if (_newPercent > 0) {
            data.rewardSharesUsers.add(_userAddress);
            data.totalPercent += _newPercent;
        } else {
            data.rewardSharesUsers.remove(_userAddress);
        }
        require(data.totalPercent < MAX_SHARED_REWARDS, "!too much total percent");

        data.active = true;
    }

    function isRewardSharesOwner(address _userAddress) view public returns(bool) {
        return rewardShares[_userAddress].active;
    }

    function calcDevMultiplicator(uint256 _fee) view public returns(uint256 _ret) {
        _ret = devFeeMultiplicator[_fee];
        require(_ret > 0, "!invalid dev bonus");
    }

    function calcAmountMultiplicator(uint256 _amount) view public returns(uint256) {

        uint256 _amountUSD = getDepositTokenPrice() * _amount / 1e18;

        uint256 _index = amountMultiplicator.length;
        for (;_index > 0;_index--) {
            MultiplicatorPair memory p = amountMultiplicator[_index - 1];
            if (_amountUSD >= p.level) return p.value;
        }
        return 1e18;
    }

    function getDepositTokenPrice() view public returns(uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = chainLinkOracle.latestRoundData();
        return uint256(price) * 1e18 / 1e8;
    }

    function getTotalLiquidity() view public returns(uint256) {
        return depositToken.balanceOf(address(this)) * getDepositTokenPrice() / 1e18;
    }

    function isFastWithdrawAllowed() view public returns(bool) {
        // total liquidity > 1M
        return (getTotalLiquidity() > 1000000 * 1e18);
    }

    function roleName() public virtual override returns(string memory) {
        return "Lock";
    }

    function getSystemTime() view public returns(uint256) {
        uint256 _startTime = startTime;
        return (_startTime > block.timestamp) ? _startTime : block.timestamp;
    }

    function virtualDeposit(address _userAddress, uint256 _amount, uint128 duration) onlyHumans external {
        require(msg.sender == controller.owner(), "!auth");

        require(deposits[_userAddress].deposit == 0, "!only users without deposit");

        VirtualDepositInfo storage info = virtualDeposits[_userAddress];
        require(_amount <= minLiquidity, "!too much liquidity");
        require(duration <= 10 days, "!max duration");
        info.virtualDeposit = _amount;
        info.initTime = uint128(block.timestamp);
        info.finishTime = uint128(block.timestamp + duration);
        emit VirtualDeposit(_userAddress, _amount, duration);
    }

    function deposit(uint256 _amount, uint256 _devBonus) onlyHumans external {
        VirtualDepositInfo storage virtualDep = virtualDeposits[msg.sender];
        if (virtualDep.virtualDeposit > 0 && block.timestamp < virtualDep.finishTime) {
            require(_amount >= virtualDep.virtualDeposit, "!liquidity less then virtual deposit");
        } else {
            require(_amount >= minLiquidity, "!min liquidity");
        }

        uint256 _currentDevMultiplicator = calcDevMultiplicator(_devBonus);

        uint256 _now = getSystemTime();

        DepositInfo storage _dep = deposits[msg.sender];

        _claim(_dep, msg.sender);

        if (_devBonus > 0) {
            uint256 _devAmount = _devBonus * _amount / 1e18;
            require(depositToken.transferFrom(msg.sender, controller.getTreasuryAddress(), _devAmount), "!transfer failed");
            _amount -= _devAmount;
        }

        require(depositToken.transferFrom(msg.sender, address(this), _amount), "!transfer failed");

        _dep.devMultiplicator = (_dep.deposit * _dep.devMultiplicator + _amount * _currentDevMultiplicator) / (_dep.deposit + _amount);

        _dep.amountMultiplicator = calcAmountMultiplicator(_dep.deposit + _amount);


        _dep.timeLast = uint128(_now);
        _dep.deposit += _amount;
        emit Deposit(msg.sender, _amount);

        if (virtualDep.virtualDeposit > 0) {
            if (block.timestamp < virtualDep.finishTime) {
                uint256 _duration = block.timestamp - virtualDep.initTime;
                // duration reduced linear if actual deposit greater then virtualDeposit
                _duration = virtualDep.virtualDeposit  * _duration / _amount;
                // credit bonus time to user
                _dep.timeLast -= uint128(_duration);
            }

            virtualDep.virtualDeposit = 0;
            virtualDep.finishTime = 0;
            virtualDep.initTime = 0;
        }
    }


    function _claim(DepositInfo storage _dep, address _depUserAddress) internal returns (uint256 _reward) {
        uint256 _currentTime = getSystemTime();

        IRewardController rewardController = IRewardController(controller.getContractByRole("RewardController"));

        if (_currentTime <= _dep.timeLast) return 0;

        uint256 _timeWeightedLiquidity;
        if (_dep.timeLast > 0) {
            uint256 _multiplicator = _dep.devMultiplicator * _dep.amountMultiplicator / 1e18;

            _timeWeightedLiquidity = (_currentTime - _dep.timeLast) * _dep.deposit * _multiplicator / 1e18 * getDepositTokenPrice() / 1e18;
        }

        _dep.timeLast = uint128(_currentTime);

        if (_timeWeightedLiquidity > 0) {
            RewardShareData storage rewardShareData = rewardShares[_depUserAddress];
            uint256 _len = rewardShareData.rewardSharesUsers.length();
//            console.log("!len", _len);
            if (_len > 0) {
                uint256 _fullTimeWeightedLiquidity = _timeWeightedLiquidity;
                for(uint256 i = 0; i < _len;i++) {
                    address _targetShare = rewardShareData.rewardSharesUsers.at(i);
                    uint256 _shareAmount = rewardShareData.rewardSharesPercent[_targetShare] * _fullTimeWeightedLiquidity / MAX_SHARED_REWARDS;
                    _timeWeightedLiquidity -= _shareAmount;
                    _reward += rewardController.payReward(_targetShare, _shareAmount);
                    emit Reward(_targetShare, _shareAmount);
                }
            }

            _reward += rewardController.payReward(_depUserAddress, _timeWeightedLiquidity);
            _dep.totalRewards += _reward;

            emit Reward(_depUserAddress, _reward);
        }
    }

    function claimReward() external nonReentrant returns (uint256) {
        DepositInfo storage _dep = deposits[msg.sender];
        return _claim(_dep, msg.sender);
    }

    function emergencyWithdraw() onlyHumans external {
        DepositInfo storage _dep = deposits[msg.sender];
        require(_dep.deposit > 0, "!zero deposit");

        // 15% fee because user may still have a GOV tokens (rewards)
        uint256 _fee = _dep.deposit * 15 / 100;
        uint256 _amount = _dep.deposit - _fee;
        _dep.deposit = 0;
        _dep.devMultiplicator = 0;
        _dep.amountMultiplicator = 0;
        _dep.timeLast = 0;
        _dep.totalRewards = 0;
        // send fee to treasury address
        require(depositToken.transfer(controller.getTreasuryAddress(), _fee), "!transfer failed");
        require(depositToken.transfer(msg.sender, _amount), "!transfer failed");
        emit Withdraw(msg.sender, _amount);
    }

    function withdraw() onlyHumans external returns (uint256 _burnedTokens) {
        DepositInfo storage _dep = deposits[msg.sender];

        require(_dep.deposit > 0, "!zero deposit");

        _claim(_dep, msg.sender);

        if (!isFastWithdrawAllowed()) {
            address _govAddress = controller.getContractByRole("GOV");
            uint256 _balance = IERC20(_govAddress).balanceOf(msg.sender);
            _burnedTokens = (_balance < _dep.totalRewards) ? _balance : _dep.totalRewards;

            if (_burnedTokens > 0) {
                require(!isRewardSharesOwner(msg.sender), "!user can't withdraw with shared rewards");
                IGovernanceToken(_govAddress).burnFrom(msg.sender, _burnedTokens);
            }
        }

        uint256 _amount = _dep.deposit;
        _dep.deposit = 0;
        _dep.timeLast = 0;
        _dep.devMultiplicator = 0;
        _dep.amountMultiplicator = 0;
        _dep.totalRewards = 0;
        require(depositToken.transfer(msg.sender, _amount), "!transfer failed");
        emit Withdraw(msg.sender, _amount);
    }
}

pragma solidity ^0.8.7;


interface IAuction {
    function removeUserFromDistribution(address _userAddress) external;
    function globalTotalCollectedDai() view external returns (uint256);
}

pragma solidity ^0.8.7;

import "./interfaces/IController.sol";
import "./interfaces/INamedContract.sol";

abstract contract ControlledEntry is INamedContract {
    IController public controller;

    function ControlledEntry_Init(address _controller) internal {
        controller = IController(_controller);
    }

    function roleName() public virtual returns(string memory);
}

pragma solidity ^0.8.7;

interface IRewardController {
    function payReward(address _userAddress, uint256 _timeWeightedLiquidity) external returns(uint256);
    function getUnlockSpeed(address _userAddress) view external returns(uint256);
    function getRewardToken() view external returns(address);
    function setBaseUnlockSpeed(uint256 _newBaseUnlockSpeed) external;
    function getCurrentMultiplier() view external returns(uint256);
}

pragma solidity ^0.8.7;


interface IController {
    function checkRole(bytes32 _role, address _account) external;
    function getContractByRole(string memory _roleName) view external returns(address );
    function owner() view external returns(address);
    function getTreasuryAddress() view external returns(address);
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IGovernanceToken is IERC20 {
    function transferWithLock(address _to, uint256 _amount) external;
    function mint(address account, uint256 amount) external;
    function getLockedAmount(address _userAddress) external view returns(uint256);
    function burn(uint256 amount) external;
    function burnFrom(address userAddress, uint256 amount) external;
    function unlock(address _userAddress) external returns(uint256);
}

pragma solidity ^0.8.7;

interface IPriceFeed {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

pragma solidity ^0.8.7;

interface INamedContract {
    function roleName() external returns(string memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}