pragma solidity ^0.8.0;

import {EnumerableSet} from "contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "contracts/utils/math/SafeMath.sol";
import {IERC20} from "contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "contracts/security/ReentrancyGuard.sol";

import "contracts/utils/NFTWalletOwnershipPauserMintPriceTransferTaxBase.sol";
import "contracts/utils/NFTPassportStorage.sol";

/**
 * @title TWSStaking
 * @notice This contract allows users to stake tokens and rewards them based on staking time and amount.
 */
contract TWSStaking is
    NFTWalletOwnershipPauserMintPriceTransferTaxBase,
    NFTPassportStorage,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice The total amount of tokens currently staked in the contract.
    uint256 public totalStakingAmount;

    /// @notice The maximum total amount of tokens that can be staked in the contract.
    uint256 public maxTotalStakingAmount;

    /// @notice The maximum amount of tokens that a single account can stake in the contract.
    uint256 public maxAccountStakingAmount;

    /// @notice The duration, in seconds, for which tokens need to be staked. If set to 0, staking is disabled.
    uint256 public stakingPeriod;

    /// @notice The total amount of rewards available for staking.
    uint256 public availableRewardAmount;

    /// @notice The additional reward ratio for staking for citizens. A value of 10000 means 100% of staked amount will be rewarded (so user gets x2). If set to 0, rewards are disabled.
    uint256 public addRewardRatioNumeratorForCitizens;

    /// @notice The additional reward ratio for staking for non citizens. A value of 10000 means 100% of staked amount will be rewarded (so user gets x2). If set to 0, rewards are disabled.
    uint256 public addRewardRatioNumeratorForNonCitizens;

    /// @notice The timestamp when staking started.
    uint256 public startTimestamp;

    /// @notice The timestamp when staking ends.
    uint256 public endTimestamp;

    /// @notice If set to true, only TWS Citizens are allowed to stake. Otherwise, anyone can stake.
    bool public onlyForTWSCitizens;

    uint256 public minStakingAmount;

    event StartAndEndTimestampsUpdated(uint256 oldStartTimestamp, uint256 newStartTimestamp, uint256 oldEndTimestamp, uint256 newEndTimestamp);
    event AvailableRewardPut(uint256 amount);
    event UnusedRewardWithdrawn(address to, uint256 amount);
    event Staked(
        address indexed account,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 unstakeAt,
        uint256 rewardAmount,
        uint256 availableRewardAmount,
        bool isCitizen
    );
    event Unstaked(address indexed account, uint256 indexed tokenId, uint256 initialAmount, uint256 rewardAmount);

    event MaxTotalStakingAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event MaxAccountStakingAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event StakingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event AddRewardRatioNumeratorForCitizensUpdated(uint256 oldRatio, uint256 newRatio);
    event AddRewardRatioNumeratorForNonCitizensUpdated(uint256 oldRatio, uint256 newRatio);
    event OnlyForTWSCitizensUpdated(bool oldValue, bool newValue);
    event AvailableRewardAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event MinStakingAmountUpdated(uint256 oldValue, uint256 newValue);

    struct StakingInfo {
        uint256 initialAmount;
        uint256 additionalRewardAmount;
        uint256 mintAt;
        uint256 unstakeAt;
        bool unstaked;
    }

    mapping (uint256 /* tokenId */ => StakingInfo) public stakingInfo;

    mapping (address => EnumerableSet.UintSet) private _activeTokens;
    function getActiveTokensCount(address account) external view returns (uint256) {
        return _activeTokens[account].length();
    }
    function getActiveTokenAt(address account, uint256 index) external view returns (uint256) {
        return _activeTokens[account].at(index);
    }
    function getAllActiveTokens(address account) external view returns (uint256[] memory) {
        return _activeTokens[account].values();
    }

    bool public transferUnstakedProhibited;

    event TransferUnstakedProhibitedUpdated(bool oldValue, bool newValue);

    function setTransferUnstakedProhibited(bool _transferUnstakedProhibited) external onlyOwner {
        emit TransferUnstakedProhibitedUpdated(transferUnstakedProhibited, _transferUnstakedProhibited);
        transferUnstakedProhibited = _transferUnstakedProhibited;
    }

    struct InitializeArgs {
        string name;
        string symbol;
        string version;
        address coinAddress;
        address treasuryAddress;
        uint256 mintPriceValue;
        uint256 transferTaxValue;
        uint256 saleTaxNumeratorValue;
        address ownerValue;
        uint256 maxTotalStakingAmount;
        uint256 maxAccountStakingAmount;
        uint256 stakingPeriod;
        uint256 addRewardRatioNumeratorForCitizens;
        uint256 addRewardRatioNumeratorForNonCitizens;
        bool onlyForTWSCitizens;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address nftPassport;
    }

    function initialize(InitializeArgs calldata args) public initializer {
        __NFTWalletOwnershipPauserMintPriceTransferTaxBase_init({
            name_: args.name,
            symbol_: args.symbol,
            version: args.version,
            coinAddress: args.coinAddress,
            treasuryAddress: args.treasuryAddress,
            mintPriceValue: args.mintPriceValue,
            transferTaxValue: args.transferTaxValue,
            saleTaxNumeratorValue: args.saleTaxNumeratorValue,
            ownerValue: args.ownerValue
        });

        maxTotalStakingAmount = args.maxTotalStakingAmount;
        maxAccountStakingAmount = args.maxAccountStakingAmount;
        stakingPeriod = args.stakingPeriod;
        addRewardRatioNumeratorForCitizens = args.addRewardRatioNumeratorForCitizens;
        addRewardRatioNumeratorForNonCitizens = args.addRewardRatioNumeratorForNonCitizens;
        onlyForTWSCitizens = args.onlyForTWSCitizens;
        startTimestamp = args.startTimestamp;
        endTimestamp = args.endTimestamp;

        __NFTPassportStorage_init_unchained(args.nftPassport);
    }

    function setMinStakingAmount(uint256 _minStakingAmount) external onlyOwner {
        emit MinStakingAmountUpdated(minStakingAmount, _minStakingAmount);
        minStakingAmount = _minStakingAmount;
    }

    function setStartAndEndTimestamps(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        require(_startTimestamp < _endTimestamp, "StakingContract: startTimestamp must be less than endTimestamp");
        emit StartAndEndTimestampsUpdated(startTimestamp, _startTimestamp, endTimestamp, _endTimestamp);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    /**
     * @notice Set the maximum total staking amount allowed in the contract.
     * @dev Can only be called by the contract owner.
     * @param _maxTotalStakingAmount The maximum total staking amount.
     */
    function setMaxTotalStakingAmount(uint256 _maxTotalStakingAmount) external onlyOwner {
        emit MaxTotalStakingAmountUpdated(maxTotalStakingAmount, _maxTotalStakingAmount);
        maxTotalStakingAmount = _maxTotalStakingAmount;  // note: could exceed totalStakingAmount
    }

    /**
     * @notice Set the maximum staking amount per account.
     * @dev Can only be called by the contract owner.
     * @param _maxAccountStakingAmount The maximum staking amount per account.
     */
    function setMaxAccountStakingAmount(uint256 _maxAccountStakingAmount) external onlyOwner {
        emit MaxAccountStakingAmountUpdated(maxAccountStakingAmount, _maxAccountStakingAmount);
        maxAccountStakingAmount = _maxAccountStakingAmount;  // note: could exceed some user staking amount
    }

    /**
     * @notice Set the staking period in seconds.
     * @dev Can only be called by the contract owner.
     * @param _stakingPeriod The staking period in seconds.
     */
    function setStakingPeriod(uint256 _stakingPeriod) external onlyOwner {
        emit StakingPeriodUpdated(stakingPeriod, _stakingPeriod);
        stakingPeriod = _stakingPeriod;
    }
    
    /**
     * @notice Set the additional reward ratio numerator for citizens.
     * @dev Can only be called by the contract owner.
     * @param _addRewardRatioNumerator The reward ratio numerator.
     */
    function setAddRewardRatioNumeratorForCitizens(uint256 _addRewardRatioNumerator) external onlyOwner {
        emit AddRewardRatioNumeratorForCitizensUpdated(addRewardRatioNumeratorForCitizens, _addRewardRatioNumerator);
        addRewardRatioNumeratorForCitizens = _addRewardRatioNumerator;
    }

    /**
     * @notice Set the additional reward ratio numerator for citizens.
     * @dev Can only be called by the contract owner.
     * @param _addRewardRatioNumerator The reward ratio numerator.
     */
    function setAddRewardRatioNumeratorForNonCitizens(uint256 _addRewardRatioNumerator) external onlyOwner {
        emit AddRewardRatioNumeratorForNonCitizensUpdated(addRewardRatioNumeratorForNonCitizens, _addRewardRatioNumerator);
        addRewardRatioNumeratorForNonCitizens = _addRewardRatioNumerator;
    }

    /**
     * @notice Set whether staking is only for TWS citizens.
     * @dev Can only be called by the contract owner.
     * @param _onlyForTWSCitizens Whether staking is only for TWS citizens.
     */
    function setOnlyForTWSCitizens(bool _onlyForTWSCitizens) external onlyOwner {
        emit OnlyForTWSCitizensUpdated(onlyForTWSCitizens, _onlyForTWSCitizens);
        onlyForTWSCitizens = _onlyForTWSCitizens;
    }

    /**
     * @notice Returns the total amount staked by a specific account.
     * @dev Iterates over all the active tokens of the account and sums up their initial staking amounts.
     * @param account The address of the account to check.
     * @return total The total amount of tokens staked by the specified account.
     */
    function totalStakedByAccount(address account) public view returns(uint256) {
        uint256 total = 0;
        EnumerableSet.UintSet storage activeTokens = _activeTokens[account];
        uint256 length = activeTokens.length();
        for(uint256 i = 0; i < length; i++) {
            StakingInfo storage info = stakingInfo[activeTokens.at(i)];
            total += info.initialAmount;
        }
        return total;
    }

    /**
     * @notice The function allows the owner to put rewards into the contract.
     * @param amount The amount of rewards to be put into the contract.
     */
    function putReward(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        availableRewardAmount += amount;
        IERC20(coin).safeTransferFrom(msg.sender, address(this), amount);
        emit AvailableRewardPut(amount);
    }

    /**
     * @notice The function allows the owner to withdraw unused rewards from the contract.
     * @param amount The amount of rewards to be withdrawn from the contract.
     * @param to The address where the withdrawn rewards should be transferred to.
     */
    function withdrawUnusedReward(uint256 amount, address to) external onlyOwner {
        availableRewardAmount = availableRewardAmount.sub(amount, "Too big");
        IERC20(coin).safeTransfer(to, amount);
        emit UnusedRewardWithdrawn(to, amount);
    }

    /**
     * @notice The function allows a user to stake tokens.
     * @dev The function checks whether the user is a valid passport holder if staking is only for TWS citizens.
     * @param amount The amount of tokens to be staked.
     */
    function stake(uint256 amount) external nonReentrant returns(uint256) {
        require(stakingPeriod > 0, "Staking is disabled");
        require(block.timestamp >= startTimestamp, "Staking has not started yet");
        require(block.timestamp < endTimestamp, "Staking has ended");
        require(amount > 0, "Amount must be greater than zero");
        require(amount >= minStakingAmount, "Amount must be greater than min staking amount");

        uint256 _totalStakedByAccount = totalStakedByAccount(msg.sender);
        require(_totalStakedByAccount + amount <= maxAccountStakingAmount, "Exceeded max address staking amount");

        require(totalStakingAmount + amount <= maxTotalStakingAmount, "Exceeded max total staking amount");
        totalStakingAmount += amount;

        uint256 addRewardRatioNumerator = 0;
        bool isCitizen = false;
        if (nftPassport.balanceOf(msg.sender) == 1) {
            require(addRewardRatioNumeratorForCitizens > 0, "Reward is disabled for citizens");
            addRewardRatioNumerator = addRewardRatioNumeratorForCitizens;
            isCitizen = true;
        } else {
            require(!onlyForTWSCitizens, "Only for TWS citizens");
            require(addRewardRatioNumeratorForNonCitizens > 0, "Reward is disabled for non-citizens");
            addRewardRatioNumerator = addRewardRatioNumeratorForNonCitizens;
            isCitizen = false;
        }

        uint256 tokenId = ++_lastTokenId;
        uint256 rewardAmount = amount * addRewardRatioNumerator / DENOMINATOR;
        stakingInfo[tokenId] = StakingInfo(
            amount,
            rewardAmount,
            block.timestamp,
            block.timestamp + stakingPeriod,
            false
        );
        _activeTokens[msg.sender].add(tokenId);
        availableRewardAmount = availableRewardAmount.sub(rewardAmount, "Not enough available reward");

        IERC20(coin).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, tokenId);
        emit Staked(msg.sender, tokenId, amount, stakingInfo[tokenId].unstakeAt, rewardAmount, availableRewardAmount, isCitizen);
        return tokenId;
    }

    /**
     * @notice The function allows a user to unstake tokens.
     * @param tokenId The ID of the token to be unstaked.
     */
    function unstake(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "No permissions");
        StakingInfo storage info = stakingInfo[tokenId];
        require(block.timestamp >= stakingInfo[tokenId].unstakeAt, "Staking period not finished");
        require(!info.unstaked, "Already unstaked");
        info.unstaked = true;

        _activeTokens[msg.sender].remove(tokenId);
        totalStakingAmount -= stakingInfo[tokenId].initialAmount;

        IERC20(coin).safeTransfer(msg.sender, stakingInfo[tokenId].additionalRewardAmount + stakingInfo[tokenId].initialAmount);
        emit Unstaked(msg.sender, tokenId, stakingInfo[tokenId].initialAmount, stakingInfo[tokenId].additionalRewardAmount);
    }

    /**
     * @notice The function allows a user to burn tokens.
     * @dev The function requires that the user is the owner of the token or the owner of the contract.
     * @param tokenId The ID of the token to be burned.
     */
    function burn(uint256 tokenId) public nonReentrant override(NFTWalletOwnershipPauserMintPriceTransferTaxBase) {
        require(ownerOf(tokenId) == msg.sender, "No permissions");
        StakingInfo storage info = stakingInfo[tokenId];
        require(info.unstaked, "Not unstaked");
        _burn(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal nonReentrant override {
        if (stakingInfo[tokenId].unstaked) {
            require(!transferUnstakedProhibited, "Transfer unstaked prohibited");
        }
        super._transfer(from, to, tokenId);
        if (_activeTokens[from].remove(tokenId)) {
            _activeTokens[to].add(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "contracts/token/ERC20/IERC20.sol";
import "contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity 0.8.6;

import {SafeERC20} from "contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "contracts/token/ERC20/IERC20.sol";

import "contracts/token/ERC721/ERC721Upgradeable.sol";
import "contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "contracts/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

import "contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "contracts/utils/ContextUpgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";
import "contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "contracts/utils/cryptography/draft-EIP712Upgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

import "contracts/utils/TreasuryStorage.sol";
import "contracts/utils/TransferTaxStorage.sol";
import "contracts/utils/SaleTaxNumeratorStorage.sol";
import "contracts/utils/MintPriceStorage.sol";
import "contracts/utils/CoinStorage.sol";
import "contracts/utils/Access.sol";
import "contracts/interfaces/ISaleTax.sol";


/// @title ERC721 with offchain marketplace and some other general features
contract NFTWalletOwnershipPauserMintPriceTransferTaxBase is
    Initializable,
    EIP712Upgradeable,
    Access,
    CoinStorage,
    TreasuryStorage,
    TransferTaxStorage,
    MintPriceStorage,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    SaleTaxNumeratorStorage
{
    using SafeERC20 for IERC20;

    uint256 internal _lastTokenId;  // note: start from 1

    function __NFTWalletOwnershipPauserMintPriceTransferTaxBase_init(
        string memory name_,
        string memory symbol_,
        string memory version,
        address coinAddress,
        address treasuryAddress,
        uint256 mintPriceValue,
        uint256 transferTaxValue,
        uint256 saleTaxNumeratorValue,
        address ownerValue
    ) internal {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __Access_init_unchained(ownerValue);

        __ERC721_init_unchained(name_, symbol_);

        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();

//        __Pausable_init_unchained();
//        __ERC721Pausable_init_unchained();

        __EIP712_init_unchained(name_, version);
        __CoinStorage_init_unchained(coinAddress);
        __TreasuryStorage_init_unchained(treasuryAddress);
        __SaleTaxNumeratorStorage_init_unchained(saleTaxNumeratorValue);

        __TransferTaxStorage_init_unchained(transferTaxValue);
        __MintPriceStorage_init_unchained(mintPriceValue);
    }

    event MintPricePaid(address indexed payer, uint256 indexed tokenId, uint256 amount);

    function _mintPayingPrice(address to, uint256 tokenId, uint256 _mintPrice, address payTo) internal virtual {
        if (_mintPrice != 0) {
            IERC20(coin).safeTransferFrom(_msgSender(), payTo, _mintPrice);
        }
        emit MintPricePaid(_msgSender(), tokenId, _mintPrice);
        super._mint(to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved");
        transferTaxIfNeeded(from);
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        transferTaxIfNeeded(from);
        _safeTransfer(from, to, tokenId, _data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
//    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        if ((from != address(0)) && (to != address(0))){
            require(!transfersNotAllowed, "transfers are not allowed");
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, SaleTaxNumeratorStorage) view returns(bool) {
        return ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            SaleTaxNumeratorStorage.supportsInterface(interfaceId)
        ;
    }

    function burn(uint256 tokenId) public onlyOwner virtual override {  // warning: centralization power
        _burn(tokenId);
    }


    bool public transfersNotAllowed;

    event TransfersNotAllowedSet(bool value);

    /// @notice Set new "transfersNotAllowed" setting value (only contract owner may call)
    /// @param value new setting value
    function setTransfersNotAllowed(bool value) external onlyOwner {
        transfersNotAllowed = value;
        emit TransfersNotAllowedSet(value);
    }

    string public baseURI;

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    event BaseURISet(string value);

    /// @notice Set new "baseURI" setting value (only contract owner may call)
    /// @param value new setting value
    function setBaseURI(string memory value) external onlyOwner {
        baseURI = value;
        emit BaseURISet(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/IERC721Upgradeable.sol";
import "contracts/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "contracts/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "contracts/utils/AddressUpgradeable.sol";
import "contracts/utils/ContextUpgradeable.sol";
import "contracts/utils/StringsUpgradeable.sol";
import "contracts/utils/introspection/ERC165Upgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "contracts/proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.0;

import "contracts/utils/introspection/IERC165Upgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/ERC721Upgradeable.sol";
import "contracts/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/ERC721Upgradeable.sol";
import "contracts/utils/ContextUpgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Burnable_init_unchained();
    }

    function __ERC721Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/ERC721Upgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/utils/cryptography/ECDSAUpgradeable.sol";
import "contracts/utils/AddressUpgradeable.sol";
import "contracts/interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271Upgradeable.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/utils/cryptography/ECDSAUpgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {SafeERC20} from "contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "contracts/token/ERC20/IERC20.sol";
import "contracts/utils/Access.sol";
import "contracts/utils/Utils.sol";


/// @title TreasuryStorage
abstract contract TreasuryStorage is
    Access
{
    using Utils for address;
    address public treasury;
    event TreasurySet(address indexed treasury);

    function __TreasuryStorage_init_unchained(address treasuryAddress) internal {
        treasury = treasuryAddress.ensureNotZero();
    }

    /// @notice Set new "treasury" setting value (only contract owner may call)
    /// @param treasuryAddress new setting value
    function setTreasury(address treasuryAddress) public onlyOwner {
        treasury = treasuryAddress.ensureNotZero();
        emit TreasurySet(treasuryAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "contracts/access/OwnableUpgradeable.sol";
import "contracts/utils/AccessControlEnumerableUpgradeable.sol";


/// @title useful access features of combination of Roles model and Ownable
abstract contract Access is OwnableUpgradeable, AccessControlEnumerableUpgradeable {
    function __Access_init(address ownerValue) internal initializer {
        __Ownable_init_unchained();
        __Access_init_unchained(ownerValue);
    }

    function __Access_init_unchained(address ownerValue) internal {
        transferOwnership(ownerValue);
    }

    /// @notice Grant role to account
    /// @param role role
    /// @param account account
    function grantRole(bytes32 role, address account) public virtual override onlyOwner {
        _grantRole(role, account);
    }

    /// @notice Revokes role from account
    /// @param role role
    /// @param account account
    function revokeRole(bytes32 role, address account) public virtual override onlyOwner {
        _revokeRole(role, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/utils/ContextUpgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "contracts/access/IAccessControlEnumerableUpgradeable.sol";
import "contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";

import "contracts/access/IAccessControlUpgradeable.sol";
import "contracts/utils/ContextUpgradeable.sol";
import "contracts/utils/StringsUpgradeable.sol";
import "contracts/utils/introspection/ERC165Upgradeable.sol";
import "contracts/proxy/utils/Initializable.sol";


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
 * roles.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is
    Initializable,
    ContextUpgradeable,
    IAccessControlUpgradeable
{
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _grantRole(bytes32 role, address account) internal {  // here it's internal not private as in openzeppelin
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal {  // here it's internal not private as in openzeppelin
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[10] private __gap_AccessControlUpgradeable;
}


/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {

//    depends on:
//        __Context_init_unchained();
//        __ERC165_init_unchained();

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[10] private __gap_AccessControlEnumerableUpgradeable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/access/IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
library EnumerableSetUpgradeable {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
pragma solidity 0.8.6;


/// @title Utils
library Utils {
    function ensureNotZero(address addr) internal pure returns(address) {
        require(addr != address(0), "ZERO_ADDRESS");
        return addr;
    }

    modifier onlyNotZeroAddress(address addr) {
        require(addr != address(0), "ZERO_ADDRESS");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/token/ERC20/IERC20.sol";

import "contracts/utils/Access.sol";
import "contracts/utils/CoinStorage.sol";
import "contracts/utils/TreasuryStorage.sol";


/// @title TransferTaxStorage
abstract contract TransferTaxStorage is
    Access,
    CoinStorage,
    TreasuryStorage
{
    using SafeERC20 for IERC20;

    uint256 public transferTax;
    event TransferTaxSet(uint256 indexed transferTax);

    function __TransferTaxStorage_init_unchained(uint256 transferTaxValue) internal {
        transferTax = transferTaxValue;
    }

    /// @notice Set new "transferTax" setting value (only contract owner may call)
    /// @param value new setting value
    function setTransferTax(uint256 value) public onlyOwner {
        transferTax = value;
        emit TransferTaxSet(value);
    }

    // no transfer tax storage

    event NoTransferTaxAccountSet(address indexed account, bool flag);

    mapping(address => bool) public isNoTransferTaxAccount;

    function setNoTransferTaxAccount(address account, bool flag) external onlyOwner {
        isNoTransferTaxAccount[account] = flag;
        emit NoTransferTaxAccountSet(account, flag);
    }

    function transferTaxIfNeeded(address from) internal {
        if (transferTax == 0) {
            return;
        }
        if (isNoTransferTaxAccount[msg.sender] || isNoTransferTaxAccount[from]) {
            return;
        }
        IERC20(coin).safeTransferFrom(from, treasury, transferTax);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IERC20} from "contracts/token/ERC20/IERC20.sol";

import "contracts/utils/Utils.sol";


/// @title CoinStorage
abstract contract CoinStorage {
    using Utils for address;
    address public coin;

    function __CoinStorage_init_unchained(address coinAddress) internal {
        coin = coinAddress.ensureNotZero();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "contracts/interfaces/IERC165.sol";
import "contracts/utils/Access.sol";
import "contracts/interfaces/ISaleTax.sol";
import "contracts/utils/DenominatorStorage.sol";


/// @title SaleTaxNumeratorStorage
abstract contract SaleTaxNumeratorStorage is ISaleTax, Access, DenominatorStorage {
    uint256 public saleTaxNumerator;
    uint256 constant public MAX_TAX_NUMERATOR = 500;  // 5%

    event SaleTaxNumeratorSet(uint256 indexed value);

    function __SaleTaxNumeratorStorage_init_unchained(uint saleTaxNumeratorValue) internal {
        require(saleTaxNumeratorValue <= MAX_TAX_NUMERATOR, "TAX_IS_TOO_HIGH");
        saleTaxNumerator = saleTaxNumeratorValue;
    }

    /// @notice Set new "saleTaxNumerator" setting value (only contract owner may call)
    /// @param value new setting value
    function setSaleTaxNumerator(uint256 value) public onlyOwner {
        require(value <= MAX_TAX_NUMERATOR, "TAX_IS_TOO_HIGH");
        saleTaxNumerator = value;
        emit SaleTaxNumeratorSet(value);
    }

    /// @inheritdoc ISaleTax
    function saleTax(uint256 tokenId, uint256 salePrice) external view override returns(uint256 taxAmount) {
        taxAmount = saleTaxNumerator * salePrice / DENOMINATOR;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return interfaceId == type(ISaleTax).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "contracts/utils/introspection/IERC165.sol";

interface ISaleTax is IERC165 {
    /// @notice get information for sale on marketplace, how much taxAmount should be transferred to treasury
    ///     based on tokenId and price amount
    /// @param tokenId id of the token to sale
    /// @param salePrice sale price amount
    /// @return taxAmount tax amount to charge
    function saleTax(uint256 tokenId, uint256 salePrice) external view returns(uint256 taxAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


abstract contract DenominatorStorage {
    uint256 constant public DENOMINATOR = 10000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {SafeERC20} from "contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "contracts/token/ERC20/IERC20.sol";

import "contracts/utils/Access.sol";
import "contracts/utils/TreasuryStorage.sol";
import "contracts/utils/CoinStorage.sol";


/// @title MintPriceStorage
abstract contract MintPriceStorage is
    Access,
    CoinStorage,
    TreasuryStorage
{
    using SafeERC20 for IERC20;

    uint256 public mintPrice;
    event MintPriceSet(uint256 indexed mintPrice);

    function __MintPriceStorage_init_unchained(uint256 mintPriceValue) internal {
        mintPrice = mintPriceValue;
    }

    /// @notice Set new "mintPrice" setting value (only contract owner may call)
    /// @param mintPriceValue new setting value
    function setMintPrice(uint256 mintPriceValue) external onlyOwner {
        mintPrice = mintPriceValue;
        emit MintPriceSet(mintPriceValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {SafeERC20} from "contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "contracts/token/ERC20/IERC20.sol";
import "contracts/utils/StringsUpgradeable.sol";
import "contracts/NFTPassport.sol";
import "contracts/utils/Access.sol";
import "contracts/utils/Utils.sol";


/// @title NFTPassportStorage
abstract contract NFTPassportStorage is Access {
    using Utils for address;

    NFTPassport public nftPassport;

    function __NFTPassportStorage_init_unchained(address nftPassportValue) internal {
        require(nftPassportValue != address(0), "ZERO_ADDRESS");
        nftPassport = NFTPassport(nftPassportValue);
    }

    /// @notice require the wallet to has a valid passport
    /// @param wallet some address
    function isValidPassportHolder(address wallet) public view {
        require((nftPassport.balanceOf(wallet) == 1), "NO_PASSPORT");
    }

    modifier onlyValidPassportHolder(address wallet) {
        require((nftPassport.balanceOf(wallet) == 1), "NO_PASSPORT");
        _;
    }

    /// @notice require the wallet to has a valid passport (or wallet = 0)
    /// @param wallet some address
    function isValidPassportHolderOrZeroAddress(address wallet) public view {
        require((wallet == address(0)) || (nftPassport.balanceOf(wallet) == 1), "NO_PASSPORT");
    }

    modifier onlyValidPassportHolderOrZeroAddress(address wallet) {
        require((wallet == address(0)) || (nftPassport.balanceOf(wallet) == 1), "NO_PASSPORT");
        _;
    }

    /// @notice get passport token id of the caller
    /// @return passport token id
    function getPassportId() public view returns(uint256) {
        address msgSender = _msgSender();
        require((nftPassport.balanceOf(msgSender) == 1), "NO_PASSPORT");
        return nftPassport.tokenOfOwnerByIndex(msgSender, 0);
    }

    /// @notice get passport token id of some wallet
    /// @param wallet some address
    /// @return passport token id
    function getPassportId(address wallet) public view returns(uint256) {
        require((nftPassport.balanceOf(wallet) == 1), "NO_PASSPORT");
        return nftPassport.tokenOfOwnerByIndex(wallet, 0);
    }

    /// @notice return the owner of some passport token id
    /// @param passportId passport token id
    /// @return owner
    function ownerOfPassportId(uint256 passportId) public view returns(address) {
        return nftPassport.ownerOf(passportId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {SafeERC20} from "contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "contracts/token/ERC20/IERC20.sol";
import {IERC721Enumerable} from "contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "contracts/utils/TreasuryStorage.sol";
import "contracts/utils/CoinStorage.sol";
import "contracts/utils/Access.sol";
import "contracts/utils/AvatarsMixin.sol";
import "contracts/utils/NFTWalletOwnershipPauserMintPriceTransferTaxBase.sol";
import "contracts/utils/AmbassadorStorage.sol";
import "contracts/utils/DocsCustodyStorage.sol";
import "contracts/utils/PowerPointsOnFinalizeStorage.sol";
import {INFTParty} from "contracts/interfaces/INFTParty.sol";

interface IPM is IERC721Enumerable {
    function burnTransferringProperty(
        uint256 tokenId,
        uint256 maxBatchSize,
        uint256 currentBatchSize
    ) external returns(bool, uint256);
}

interface IDocsCustodyTransfer {
    function transferToDocsCustody(
        uint256 tokenId,
        address docsCustody
    ) external;
}

interface IBurnOnBurn {
    function burnOnBurn(uint256 tokenId) external;
}

/**
 * @title NFT Passport ERC721 token confirming citizenship.
 */
contract NFTPassport is
    AmbassadorStorage,
    AvatarsMixin,
    NFTWalletOwnershipPauserMintPriceTransferTaxBase,
    DocsCustodyStorage,
    PowerPointsOnFinalizeStorage
{
    using SafeERC20 for IERC20;
    using SignatureCheckerUpgradeable for address;

    bytes32 internal constant NFT_ACT = keccak256("NFT_ACT");
    bytes32 internal constant NFT_LEGISLATIVE_INITIATIVE = keccak256("NFT_LEGISLATIVE_INITIATIVE");
    bytes32 internal constant NFT_BILL = keccak256("NFT_BILL");
    bytes32 internal constant NFT_PARTY = keccak256("NFT_PARTY");
    bytes32 internal constant NFT_NOMINEE_FOR_CANDIDATE = keccak256("NFT_NOMINEE_FOR_CANDIDATE");
    bytes32 internal constant NFT_NOMINEE_FOR_PRESIDENT = keccak256("NFT_NOMINEE_FOR_PRESIDENT");
    bytes32 internal constant NFT_PRESIDENT = keccak256("NFT_PRESIDENT");
    mapping (bytes32 /*contractCode*/ => address /*contract*/) internal contractsRegistry;

    // Each citizen receives PowerPoints (PP) for activity,
    // which are recorded and stored in the NFT Passport for each ID.
    mapping (uint256 /*tokenId*/ => uint256 /*points*/) public powerPoints;

    // The NFT Passport records how many times a citizen has become President.
    mapping (uint256 /*tokenId*/ => uint256 /*count*/) public presidentCounter;

    uint256 public powerPointsBurnRateNumeratorOnTransfer;

    bytes32 public constant ADD_POWER_POINTS_ROLE = keccak256("ADD_POWER_POINTS_ROLE");
    bytes32 public constant ICO_MINTER_ROLE = keccak256("ICO_MINTER_ROLE");
    bytes32 public constant RESTRICTED_MINTER_ROLE = keccak256("RESTRICTED_MINTER_ROLE");
    bytes32 public constant INCREASE_PRESIDENT_COUNTER_ROLE = keccak256("INCREASE_PRESIDENT_COUNTER_ROLE");

    event ContractRegistered(bytes32 indexed contractCode, address indexed contractAddress);
    event PowerPointsBurnRateNumeratorOnTransferSet(uint256 indexed value);
    event PowerPointsBurnOnTransfer(uint256 indexed tokenId, uint256 indexed burnPowerPoints, uint256 restPowerPoints);
    event PowerPointsAdded(uint256 indexed tokenId, uint256 indexed points, uint256 totalPoints);
    event PresidentCounterIncreased(uint256 indexed tokenId, uint256 newValue);

    uint256 public maxAmountICO;

    event MaxAmountICOSet(uint256 value);

    /// @notice register related contract (could be called only once for every contract)
    /// @param contractCode contract code
    /// @param contractAddress contract address
    function registerContract(bytes32 contractCode, address contractAddress) external onlyOwner {
        require(contractsRegistry[contractCode] == address(0), "ALREADY_SET");
        contractsRegistry[contractCode] = contractAddress;
        emit ContractRegistered(contractCode, contractAddress);
    }

    function setMaxAmountICO(uint256 value) external onlyOwner {
        require((
                maxAmountICO > _lastTokenId ||
                _lastTokenId == 0
            ), "CANNOT_CHANGE_FINISHED_ICO");
        require(maxAmountICO != value, "UNCHANGED");
        maxAmountICO = value;
        emit MaxAmountICOSet(value);
    }

    /// @notice initialize the contract
    /// @param nameValue name
    /// @param symbolValue symbol
    /// @param versionValue version
    /// @param treasuryAddress treasury to receive fees
    /// @param coinAddress coin address
    /// @param mintPriceValue mint price
    /// @param transferTaxValue transfer tax
    /// @param saleTaxNumeratorValue sale tax numerator value
    /// @param ownerValue contract owner
    function initialize(
        string memory nameValue,
        string memory symbolValue,
        string memory versionValue,
        address treasuryAddress,
        address coinAddress,
        uint256 mintPriceValue,
        uint256 transferTaxValue,
        uint256 saleTaxNumeratorValue,
        uint256 powerPointsBurnRateNumeratorOnTransferValue,
        address ownerValue
    ) external virtual initializer {
        __NFTWalletOwnershipPauserMintPriceTransferTaxBase_init({
            name_: nameValue,
            symbol_: symbolValue,
            version: versionValue,
            coinAddress: coinAddress,
            treasuryAddress: treasuryAddress,
            mintPriceValue: mintPriceValue,
            transferTaxValue: transferTaxValue,
            saleTaxNumeratorValue: saleTaxNumeratorValue,
            ownerValue: ownerValue
        });
        require(powerPointsBurnRateNumeratorOnTransferValue <= DENOMINATOR, "BURN_RATE_TOO_HIGH");
        powerPointsBurnRateNumeratorOnTransfer = powerPointsBurnRateNumeratorOnTransferValue;
    }

    /// @notice Set new "powerPointsBurnRateNumeratorOnTransfer" setting value (only contract owner may call)
    /// @param newValue new setting value
    function setPowerPointsBurnRateNumeratorOnTransfer(uint256 newValue) external onlyOwner {
        require(newValue <= DENOMINATOR, "BURN_RATE_TOO_HIGH");
        powerPointsBurnRateNumeratorOnTransfer = newValue;
        emit PowerPointsBurnRateNumeratorOnTransferSet(newValue);
    }

    event MintedDuringICO(address indexed minter, address indexed to, uint256 indexed tokenId);

    // disabled since not is use
//    /// @notice mint new passport during ICO (for free but only ICO_MINTER_ROLE can call)
//    /// @param recipients list of recipients
//    function mintICO(address[] memory recipients) external onlyRole(ICO_MINTER_ROLE) {
//        uint256 currentTokenId = _lastTokenId;
//         require(currentTokenId + recipients.length <= maxAmountICO, "EXCEED_ICO_MAX_AMOUNT");
//        _lastTokenId = currentTokenId + recipients.length;
//
//        for (uint256 index=0; index < recipients.length; ++index) {
//            address to = recipients[index];
//            currentTokenId += 1;
//            _mint(to, currentTokenId);
//            emit MintedDuringICO({
//                minter: _msgSender(),
//                to: to,
//                tokenId: currentTokenId
//            });
//            _mintDefaultAvatarAndConnectToToken(currentTokenId);
//        }
//    }

    /// @notice mint new passport by owner or RESTRICTED_MINTER_ROLE (for free)
    /// @param to recipient
    /// @return tokenId minted token id
    function mintRestricted(address to) external returns(uint256) {
        require(msg.sender == owner() || hasRole(RESTRICTED_MINTER_ROLE, msg.sender), "NOT_ALLOWED");
        uint256 currentTokenId = ++_lastTokenId;
        _mint(to, currentTokenId);
        _mintDefaultAvatarAndConnectToToken(currentTokenId);
        return currentTokenId;
    }

    /// @notice mint new passport
    function mint() external {
        uint256 tokenId = ++_lastTokenId;  // note: id starts from 1
        require(tokenId > maxAmountICO, "ICO_NOT_FINISHED");

        _mintPayingPrice({
            to: _msgSender(),
            tokenId: tokenId,
            _mintPrice: mintPrice,
            payTo: treasury
        });

        _mintDefaultAvatarAndConnectToToken(tokenId);
    }

    /// @notice mint new passport via ambassador
    /// @param ambassador ambassador
    /// @param nonce user verifier signature nonce
    /// @param deadline signature deadline
    /// @param verifier verifier
    /// @param verifierSignature verifier signature
    function mintViaAmbassador(
        address ambassador,
        uint256 nonce,
        uint256 deadline,
        address verifier,
        bytes memory verifierSignature
    ) external {
        uint256 tokenId = ++_lastTokenId;  // note: id starts from 1
        require(tokenId > maxAmountICO, "ICO_NOT_FINISHED");
        _checkMintViaAmbassadorSignature({
            minter: _msgSender(),
            ambassador: ambassador,
            nonce: nonce,
            deadline: deadline,
            signer: verifier,
            signature: verifierSignature
        });

        _mintPayingPrice({
            to: _msgSender(),
            tokenId: tokenId,
            _mintPrice: ambassadorPrice,
            payTo: address(this)
        });

        IERC20(coin).safeTransfer(treasury, ambassadorPrice-ambassadorReward);
        IERC20(coin).safeTransfer(ambassador, ambassadorReward);

        emit AmbassadorRewardPaid({
            minter: _msgSender(),
            ambassador: ambassador,
            tokenId: tokenId,
            reward: ambassadorReward
        });

        _mintDefaultAvatarAndConnectToToken(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // Transfer / resale is only possible if AllowTransfers = True.
        // ERC721AllowedTransfer

        super._beforeTokenTransfer(from, to, tokenId);
        // Only one NFT Passport can have one network address at a time.
        // The recipient address must not have an NFT Passport.
        if (to != address(0)){
            require(balanceOf(to) == 0, "ONLY_ONE_NFT_PASSPORT_PER_ACCOUNT");

            require(!isBanned[to], "BANNED_RECEIVER");  // note: tiny gas optimisation to skip the check on burn
        }

        uint256 burnPowerPoints = powerPoints[tokenId] * powerPointsBurnRateNumeratorOnTransfer / DENOMINATOR;
        powerPoints[tokenId] -= burnPowerPoints;
        emit PowerPointsBurnOnTransfer(tokenId, burnPowerPoints, powerPoints[tokenId]);

        // note: we do not reset the presidentCounter upon transfer
    }

    /// @notice add more power points to the passport onlyRole(ADD_POWER_POINTS_ROLE)
    /// @param tokenId token id
    /// @param points points amount to add
    function addPowerPoints(
        uint256 tokenId,
        uint256 points
    ) external onlyRole(ADD_POWER_POINTS_ROLE) {
        powerPoints[tokenId] += points;
        emit PowerPointsAdded(tokenId, points, powerPoints[tokenId]);
    }

    /// @notice increase presidentCounter of the passport
    /// @param tokenId passport id
    function increasePresidentCounter(uint256 tokenId)
        external onlyRole(INCREASE_PRESIDENT_COUNTER_ROLE)
    {
        presidentCounter[tokenId] += 1;
        emit PresidentCounterIncreased(tokenId, presidentCounter[tokenId]);
    }

    function _transferAllToCustody(
        bytes32 contractCode,
        address account,
        uint256 maxBatchSize,
        uint256 currentBatchSize
    ) internal returns (bool finished, uint256 /*currentBatchSize*/) {
        address contractAddress = contractsRegistry[contractCode];
        require(contractAddress != address(0), "WRONG_SETUP");

        uint256 tokensNumber = IERC721Enumerable(contractAddress).balanceOf(account);
        uint256 restBatchSize = maxBatchSize - currentBatchSize;
        uint256 numberToProcess = 0;
        if (tokensNumber <= restBatchSize) {
            finished = true;
            numberToProcess = tokensNumber;
        } else {
            finished = false;
            numberToProcess = restBatchSize;
        }
        for (uint256 _counter = 0; _counter < numberToProcess; ) {
            IDocsCustodyTransfer(contractAddress).transferToDocsCustody({
                tokenId: IERC721Enumerable(contractAddress).tokenOfOwnerByIndex(account, 0),
                docsCustody: docsCustody
            });
            unchecked {
                _counter += 1;
            }
        }
        return (finished, currentBatchSize+numberToProcess);
    }

    function _burnAll(
        bytes32 contractCode,
        address account,
        uint256 maxBatchSize,
        uint256 currentBatchSize
    ) internal returns (bool finished, uint256 /*currentBatchSize*/) {
        address contractAddress = contractsRegistry[contractCode];
        require(contractAddress != address(0), "WRONG_SETUP");

        uint256 tokensNumber = IERC721Enumerable(contractAddress).balanceOf(account);
        uint256 restBatchSize = maxBatchSize - currentBatchSize;
        uint256 numberToProcess = 0;
        if (tokensNumber <= restBatchSize) {
            finished = true;
            numberToProcess = tokensNumber;
        } else {
            finished = false;
            numberToProcess = restBatchSize;
        }
        for (uint256 _counter = 0; _counter < numberToProcess; ) {
            IBurnOnBurn(contractAddress).burnOnBurn({
                tokenId: IERC721Enumerable(contractAddress).tokenOfOwnerByIndex(account, 0)
            });
            unchecked {
                _counter += 1;
            }
        }
        return (finished, currentBatchSize+numberToProcess);
    }

    event Banned(address indexed account);
    event Unbanned(address indexed account);
    mapping (address /*account*/ => bool /*is banned*/) public isBanned;

    function _ban(address account) internal {
        require(!isBanned[account], "ALREADY_BANNED");
        isBanned[account] = true;
        emit Banned(account);
    }

    function ban(address account) external onlyOwner {
        require(balanceOf(account) == 0, "has passport, use burn");
        _ban(account);
    }

    function unban(address account) external onlyOwner {
        require(isBanned[account], "NOT_BANNED");
        isBanned[account] = false;
        emit Unbanned(account);
    }

    event BURN_TRANSFERRING_PROPERTY_UNFINISHED();
    event BURN_TRANSFERRING_PROPERTY_FINISHED();

    function burnTransferringProperty(
        uint256 tokenId,
        uint256 maxBatchSize,
        bool banAccount
    ) external onlyOwner {
        uint256 currentBatchSize = 0;
        address account = ownerOf(tokenId);
        bool finished;

        if (banAccount) {
            _ban(account);
        }

        (finished, currentBatchSize) = _transferAllToCustody({
            contractCode: NFT_LEGISLATIVE_INITIATIVE,
            account: account,
            maxBatchSize: maxBatchSize,
            currentBatchSize: currentBatchSize
        });
        if (!finished) {
            emit BURN_TRANSFERRING_PROPERTY_UNFINISHED();
            return;
        }

        (finished, currentBatchSize) = _transferAllToCustody({
            contractCode: NFT_BILL,
            account: account,
            maxBatchSize: maxBatchSize,
            currentBatchSize: currentBatchSize
        });
        if (!finished) {
            emit BURN_TRANSFERRING_PROPERTY_UNFINISHED();
            return;
        }

        (finished, currentBatchSize) = _transferAllToCustody({
            contractCode: NFT_ACT,
            account: account,
            maxBatchSize: maxBatchSize,
            currentBatchSize: currentBatchSize
        });
        if (!finished) {
            emit BURN_TRANSFERRING_PROPERTY_UNFINISHED();
            return;
        }

        (finished, currentBatchSize) = _burnAll({
            contractCode: NFT_NOMINEE_FOR_CANDIDATE,
            account: account,
            maxBatchSize: maxBatchSize,
            currentBatchSize: currentBatchSize
        });
        if (!finished) {
            emit BURN_TRANSFERRING_PROPERTY_UNFINISHED();
            return;
        }

        (finished, currentBatchSize) = _burnAll({
            contractCode: NFT_NOMINEE_FOR_PRESIDENT,
            account: account,
            maxBatchSize: maxBatchSize,
            currentBatchSize: currentBatchSize
        });
        if (!finished) {
            emit BURN_TRANSFERRING_PROPERTY_UNFINISHED();
            return;
        }

        (finished, currentBatchSize) = _burnAll({
            contractCode: NFT_PRESIDENT,
            account: account,
            maxBatchSize: maxBatchSize,
            currentBatchSize: currentBatchSize
        });
        if (!finished) {
            emit BURN_TRANSFERRING_PROPERTY_UNFINISHED();
            return;
        }

        INFTParty nftParty = INFTParty(contractsRegistry[NFT_PARTY]);
        require(address(nftParty) != address(0), "WRONG_SETUP");
        while (nftParty.membershipsNumber(account) != 0) {
            uint256 partyId = nftParty.membershipByIndex(account, 0);
            IPM pm = IPM(nftParty.getNFTPartyMembership(partyId));
            uint256 partyMembershipId = pm.tokenOfOwnerByIndex(account, 0);
            (finished, currentBatchSize) = pm.burnTransferringProperty({
                tokenId: partyMembershipId,
                maxBatchSize: maxBatchSize,
                currentBatchSize: currentBatchSize
            });
            if (!finished) {
                emit BURN_TRANSFERRING_PROPERTY_UNFINISHED();
                return;
            }
        }

        // all preparation finished
        _burn(tokenId);
        emit BURN_TRANSFERRING_PROPERTY_FINISHED();
    }

    /// @notice burning NFTP passport involves
    ///     1. passport avatar is detached from the passport and transferred to the owner
    ///     2. remove from enumeration - https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.3.3/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol#L92
    ///     3. clear storage: remove powerPoints, presidentCounter
    function _burn(uint256 tokenId) internal virtual override {
        _clearAvatar(tokenId, ownerOf(tokenId));
        super._burn(tokenId);
        delete powerPoints[tokenId];
        delete presidentCounter[tokenId];
    }

    // proposal address implement
    // voteForUpgrade

    uint256[10] private __gap_NFTPassport;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IERC721} from "contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "contracts/token/ERC721/utils/ERC721Holder.sol";
import {EnumerableSet} from "contracts/utils/structs/EnumerableSet.sol";
import "contracts/utils/Access.sol";


interface IERC721MintReturningTokenId is IERC721 {
    function mint() external returns(uint256 tokenId);
}


/// @title AvatarsMixin
abstract contract AvatarsMixin is Access, ERC721Holder {
    using EnumerableSet for EnumerableSet.AddressSet;
    address public defaultAvatarSmartContractAddress;
    EnumerableSet.AddressSet internal _availableAvatarSmartContractAddresses;

    event DefaultAvatarSmartContractAddressSet(address indexed value);
    event AvailableAvatarSmartContractAddressAdded(address indexed value);
    event AvailableAvatarSmartContractAddressRemoved(address indexed value);

    event AvatarSet(
        uint256 indexed tokenId,
        address indexed avatarSmartContract,
        uint256 indexed avatarTokenId
    );

    struct Avatar {
        address avatarSmartContract;
        uint256 avatarTokenId;
    }
    mapping (uint256 /*passport or membership tokenId*/ => Avatar) public tokenAvatar;

    /// @notice Set new "DefaultAvatarSmartContractAddress" setting value (only contract owner may call)
    /// @param value new setting value
    function setDefaultAvatarSmartContractAddress(address value) external onlyOwner {
        require(value != address(0), "zero address");
        defaultAvatarSmartContractAddress = value;
        emit DefaultAvatarSmartContractAddressSet(value);
    }

    function _mintDefaultAvatarAndConnectToToken(uint256 tokenId) internal {
        require(defaultAvatarSmartContractAddress != address(0), "defaultAvatarSmartContractAddress not set");

        uint256 avatarTokenId = IERC721MintReturningTokenId(defaultAvatarSmartContractAddress).mint();
        tokenAvatar[tokenId] = Avatar({
            avatarSmartContract: defaultAvatarSmartContractAddress,
            avatarTokenId: avatarTokenId
        });
        emit AvatarSet(tokenId, defaultAvatarSmartContractAddress, avatarTokenId);
    }

    /// @notice clear avatar (on burn)
    /// @param tokenId token id
    /// @param to send avatar to the account
    function _clearAvatar(uint256 tokenId, address to) internal {
        Avatar memory currentAvatar = tokenAvatar[tokenId];
        delete tokenAvatar[tokenId];
        IERC721(currentAvatar.avatarSmartContract).safeTransferFrom(address(this), to, currentAvatar.avatarTokenId);
        emit AvatarSet(tokenId, address(0), 0);
    }

    /// @notice set avatar on token
    /// @param tokenId token id
    /// @param avatarSmartContract new avatar SmartContract
    /// @param avatarTokenId new avatar TokenId
    function setAvatar(uint256 tokenId, address avatarSmartContract, uint256 avatarTokenId) external {
        require(
            IERC721(address(this)).ownerOf(tokenId) == msg.sender,
            "not owner"
        );
        require(
            _availableAvatarSmartContractAddresses.contains(avatarSmartContract) ||
            avatarSmartContract == defaultAvatarSmartContractAddress,
            "wrong avatarSmartContract"
        );
        Avatar memory currentAvatar = tokenAvatar[tokenId];
        tokenAvatar[tokenId] = Avatar(avatarSmartContract, avatarTokenId);
        IERC721(currentAvatar.avatarSmartContract).safeTransferFrom(address(this), msg.sender, currentAvatar.avatarTokenId);
        IERC721(avatarSmartContract).safeTransferFrom(msg.sender, address(this), avatarTokenId);
        emit AvatarSet(tokenId, avatarSmartContract, avatarTokenId);
    }

    /// @notice add some address to list of AvailableAvatarSmartContractAddress
    /// @param availableAvatarSmartContractAddress some address
    function addAvailableAvatarSmartContractAddress(address availableAvatarSmartContractAddress) public onlyOwner {
        require(availableAvatarSmartContractAddress != address(0), "zero address");
        require(_availableAvatarSmartContractAddresses.add(availableAvatarSmartContractAddress), "already added");
        emit AvailableAvatarSmartContractAddressAdded(availableAvatarSmartContractAddress);
    }

    /// @notice remove address from AvailableAvatarSmartContractAddress
    /// @param availableAvatarSmartContractAddress some address
    function removeAvailableAvatarSmartContractAddress(address availableAvatarSmartContractAddress) public onlyOwner {
        require(_availableAvatarSmartContractAddresses.remove(availableAvatarSmartContractAddress), "not added");
        emit AvailableAvatarSmartContractAddressRemoved(availableAvatarSmartContractAddress);
    }

    /// @notice return the length of _availableAvatarSmartContractAddresses
    /// @return length
    function availableAvatarSmartContractAddressesLength() external view returns(uint256) {
        return _availableAvatarSmartContractAddresses.length();
    }

    /// @notice address at index in _availableAvatarSmartContractAddresses
    /// @param index index
    /// @return address
    function availableAvatarSmartContractAddressAt(uint256 index) external view returns(address) {
        return _availableAvatarSmartContractAddresses.at(index);
    }

    /// @notice addresses of _availableAvatarSmartContractAddresses
    /// @return addresses
    function availableAvatarSmartContractAddresses() external view returns(address[] memory) {
        return _availableAvatarSmartContractAddresses.values();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "contracts/utils/cryptography/draft-EIP712Upgradeable.sol";
import "contracts/utils/Access.sol";

abstract contract AmbassadorStorage is EIP712Upgradeable, Access {
    using SignatureCheckerUpgradeable for address;

    bytes32 public constant AMBASSADOR_VERIFIER_ROLE = keccak256("AMBASSADOR_VERIFIER_ROLE");

    event AmbassadorPriceSet(uint256 value);
    event AmbassadorRewardSet(uint256 value);

    uint256 public ambassadorPrice;
    uint256 public ambassadorReward;

    event AmbassadorRewardPaid(
        address indexed minter,
        address indexed ambassador,
        uint256 indexed tokenId,
        uint256 reward
    );

    event AmbassadorRewardManyPaid(
        address indexed minter,
        address indexed ambassador,
        uint256 indexed startTokenId,
        uint256 mintedTokensAmount,
        uint256 totalReward
    );

    // to avoid re-using the same signature twice
    mapping (address /*user*/ => mapping (address /*verifier*/ => mapping(uint256 /*nonce*/ => bool /*used*/))) public userVerifierNonceIsUsed;

    /// @notice set ambassador price
    /// @param value new ambassador price value
    function setAmbassadorPrice(uint256 value) external onlyOwner {
        require(ambassadorPrice != value, "unchanged value");
        ambassadorPrice = value;
        emit AmbassadorPriceSet(value);
    }

    /// @notice set ambassador reward
    /// @param value new ambassador reward value
    function setAmbassadorReward(uint256 value) external onlyOwner {
        require(ambassadorReward != value, "unchanged value");
        ambassadorReward = value;
        emit AmbassadorRewardSet(value);
    }

    function mintViaAmbassadorDigest(
        address minter,
        address ambassador,
        uint256 nonce,
        uint256 deadline
    ) public view returns(bytes32 digest) {
        digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("mintViaAmbassador(address minter,address ambassador,uint256 nonce,uint256 deadline)"),
            minter,
            ambassador,
            nonce,
            deadline
        )));
    }

    function _checkMintViaAmbassadorSignature(
        address minter,
        address ambassador,
        uint256 nonce,
        uint256 deadline,
        address signer,
        bytes memory signature
    ) internal {
        require(block.timestamp < deadline, "EXPIRED");
        bytes32 digest = mintViaAmbassadorDigest({
            minter: minter,
            ambassador: ambassador,
            nonce: nonce,
            deadline: deadline
        });

        require(!userVerifierNonceIsUsed[msg.sender][signer][nonce], "NONCE_ALREADY_USED");
        userVerifierNonceIsUsed[msg.sender][signer][nonce] = true;
        require(signer != address(0), "SIGNER_IS_ZERO_ADDRESS");
        require(signer.isValidSignatureNow({hash: digest, signature: signature}), "INVALID_SIGNATURE");
        require(hasRole(AMBASSADOR_VERIFIER_ROLE, signer), "SIGNER_HAS_NO_VERIFIER_ROLE");
    }

    function _checkMintManyViaAmbassadorSignature(
        address minter,
        address ambassador,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        address signer,
        bytes memory signature
    ) internal {
        require(block.timestamp < deadline, "EXPIRED");
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("mintManyViaAmbassador(address minter,address ambassador,uint256 amount,uint256 nonce,uint256 deadline)"),
            minter,
            ambassador,
            amount,
            nonce,
            deadline
        )));

        require(!userVerifierNonceIsUsed[msg.sender][signer][nonce], "NONCE_ALREADY_USED");
        userVerifierNonceIsUsed[msg.sender][signer][nonce] = true;
        require(signer != address(0), "SIGNER_IS_ZERO_ADDRESS");
        require(signer.isValidSignatureNow({hash: digest, signature: signature}), "INVALID_SIGNATURE");
        require(hasRole(AMBASSADOR_VERIFIER_ROLE, signer), "SIGNER_HAS_NO_VERIFIER_ROLE");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "contracts/utils/Access.sol";

abstract contract DocsCustodyStorage is Access {
    event DocsCustodySet(address indexed value);
    address public docsCustody;

    /// @notice set docs custody
    /// @param value new address
    function setDocsCustody(address value) external onlyOwner {
        require(docsCustody != value, "unchanged value");
        docsCustody = value;
        emit DocsCustodySet(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "contracts/utils/Access.sol";

/// @title PowerPointsOnFinalizeStorage
abstract contract PowerPointsOnFinalizeStorage is Access {
    uint256 public powerPointsOnFinalize;
    event PowerPointsOnFinalizeSet(uint256 value);

    /// @notice Set new "powerPointsOnFinalize" setting value (only contract owner may call)
    /// @param newValue new setting value
    function setPowerPointsOnFinalize(uint256 newValue) public onlyOwner {
        powerPointsOnFinalize = newValue;
        emit PowerPointsOnFinalizeSet(newValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title NFT NfC is an ERC721 token confirming the founding of a party.
 */
interface INFTParty
{
    enum Status {
        None,
        InProgress,
        Accepted,
        Declined,
        Founded,
        Expired
    }

    /// @notice the number of parties where the account is participating
    /// @param account account
    /// @return count number of parties
    function membershipsNumber(address account) external view returns(uint256 count);

    /// @notice party token id of the account by the index
    /// @param account account
    /// @param index index
    /// @return partyId party token id
    function membershipByIndex(address account, uint256 index) external view returns(uint256 partyId);

    function transferMembership(address from, address to) external;

    function assignMembership(address account) external;

    function resignMembership(address account) external;

    /// @notice get token info
    /// @param tokenId token id
    /// @return mintedTimestamp mintedTimestamp
    /// @return status status
    /// @return votes votes
    /// @return nftPartyMembership nftPartyMembership
    /// @return nftDraftPartyRules nftDraftPartyRules
    /// @return nftPartyRules nftPartyRules
    /// @return nftNomineeForPartyLeader nftNomineeForPartyLeader
    /// @return nftPartyLeader nftPartyLeader
    /// @return partyVotingWindow partyVotingWindow
    function getTokenInfo(uint256 tokenId) external view returns(
        uint256 mintedTimestamp,
        Status status,
        uint256 votes,
        address nftPartyMembership,
        address nftDraftPartyRules,
        address nftPartyRules,
        address nftNomineeForPartyLeader,
        address nftPartyLeader,
        address partyVotingWindow
    );

    /// @notice get related contract address
    /// @param tokenId token id
    /// @return contract address
    function getNFTPartyMembership(uint256 tokenId) external view returns(address);

    /// @notice get related contract address
    /// @param tokenId token id
    /// @return contract address
    function getNFTPartyDraftRules(uint256 tokenId) external view returns(address);

    /// @notice get related contract address
    /// @param tokenId token id
    /// @return contract address
    function getNFTPartyRules(uint256 tokenId) external view returns(address);

    /// @notice get related contract address
    /// @param tokenId token id
    /// @return contract address
    function getNFTNomineeForPartyLeader(uint256 tokenId) external view returns(address);

    /// @notice get related contract address
    /// @param tokenId token id
    /// @return contract address
    function getNFTPartyLeader(uint256 tokenId) external view returns(address);

    /// @notice get related contract address
    /// @param tokenId token id
    /// @return contract address
    function getPartyVotingWindow(uint256 tokenId) external view returns(address);
}