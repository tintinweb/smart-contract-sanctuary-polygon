// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SystemContext.sol";
import "./PaypoolV1ERC20.sol";

contract DailyLimit {
    struct Schedule {
        uint256 startTimestamp;
        uint256 maxPerDay;
        uint256 maxExistingInPool;
    }

    SystemContext public systemContext;
    PaypoolV1ERC20 public rewardToken;
    Schedule[] public schedules;
    uint256 internal scheduleIndex;
    uint256 public lastReward;
    uint256 public lastPoolAmount;

    modifier onlyManagerRole() {
        systemContext.checkRole(systemContext.LEDGER_MANAGER_ROLE(), msg.sender);
        _;
    }

    modifier onlyAssetAccessRole() {
        systemContext.checkRole(systemContext.ASSETS_ACCESS_ROLE(), msg.sender);
        _;
    }

    constructor (SystemContext systemContext_, uint256 startingPoolSize_, uint256[] memory startTimestamps_, uint256[] memory maxPerDays_, uint256[] memory maxExistingInPools_) {
        systemContext = systemContext_;
        rewardToken = systemContext_.brightPoolToken();
        uint256 startTimestampsLen = startTimestamps_.length;
        require(startTimestampsLen == maxPerDays_.length, "Arr len incorrect");
        require(startTimestampsLen == maxExistingInPools_.length, "Arr len incorrect");
        require(startTimestampsLen != 0, "Arrays empty");

        lastReward = startTimestamps_[0];
        lastPoolAmount = startingPoolSize_;

        for (uint256 i = 0; i < startTimestampsLen;) {
            schedules.push(Schedule(startTimestamps_[i], maxPerDays_[i], maxExistingInPools_[i]));
            if (startTimestampsLen > i + 1) {
                require(startTimestamps_[i] < startTimestamps_[i + 1], "Timestamps not sorted");
            }
            // Gas optimisation
            unchecked { ++i; }
        }
    }

    function _max(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? a : b;
    }

    function _recalculatePool(uint256 time) internal view returns(uint256, uint256) {
        if (lastReward == time) {
            return (lastPoolAmount, scheduleIndex);
        }

        uint256 newPoolAmount = lastPoolAmount;
        uint256 lastScheduleIndex = scheduleIndex;
        uint256 schedulesLength = schedules.length;

        for (uint256 i = lastScheduleIndex; i < schedulesLength;) {
            if (schedules[i].startTimestamp < time) {
                // Gas optimisation
                unchecked { ++i; }
                continue;
            }
            lastScheduleIndex = i - 1;
            break;
        }

        for (uint256 i = lastScheduleIndex + 1; i > scheduleIndex;) {
            Schedule memory schedule = schedules[i - 1];
            newPoolAmount += (time - _max(schedule.startTimestamp, lastReward)) * schedule.maxPerDay / 86400;
            if (newPoolAmount > schedule.maxExistingInPool) {
                newPoolAmount = schedule.maxExistingInPool;
                break;
            }
            // Gas optimisation
            unchecked { --i; }
        }

        return (newPoolAmount, lastScheduleIndex);
    }

    function _calculateReward(uint256 reward_, uint256 currentlyInPool_, uint256 scheduleIndex_) internal view returns(uint256) {
        Schedule memory schedule = schedules[scheduleIndex_];
        return (reward_ * currentlyInPool_) / schedule.maxPerDay;
    }

    function getCurrentPool() external view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time, no-unused-vars
        (uint256 pool, uint256 _notUsed) = _recalculatePool(block.timestamp);

        return pool;
    }

    function calculateReward(uint256 time, uint256 reward) public view returns(uint256) {
        (uint256 pool, uint256 index) = _recalculatePool(time);
        return _calculateReward(reward, pool, index);
    }

    function calculateRewardNow(uint256 reward) external view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        return calculateReward(block.timestamp, reward);
    }

    function withdrawReward(address userAddress, uint256 userReward) external onlyManagerRole() returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        (lastPoolAmount, scheduleIndex) = _recalculatePool(block.timestamp);
        // solhint-disable-next-line not-rely-on-time
        lastReward = block.timestamp;
        uint256 reward = _calculateReward(userReward, lastPoolAmount, scheduleIndex);

        require(lastPoolAmount > reward, "Not enough tokens in a pool");
        lastPoolAmount -= reward;

        require(rewardToken.transfer(userAddress, reward), "Transfer failed");

        return reward;
    }

    function adminWithdraw(uint256 amount) external onlyAssetAccessRole {
        require(rewardToken.transfer(msg.sender, amount), "");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./SlidingWindowLedger.sol";
import "./LedgerManager.sol";
import "./ProfitSplitter.sol";
import "./PaypoolV1ERC20.sol";

contract SystemRoles is AccessControlEnumerable {

    // SYSTEM_ADMIN_ROLE == 0x73e9313463d20ecb48d57e0f6f5d83b7adbe3a3f694bf9358ab1f80d8ebcd90a
    bytes32 constant public SYSTEM_ADMIN_ROLE = keccak256("SYSTEM_ADMIN_ROLE");
    // SYSTEM_CONTEXT_ROLE == 0x60a33b332a502c360fd59058c37d9b39e8b3204e61ee9836ab0ae6ca9b990706
    bytes32 constant public SYSTEM_CONTEXT_ROLE = keccak256("SYSTEM_CONTEXT_ROLE");
    // PRICE_ENGINE_ROLE == 0x9fcf1715ef27eb4c6733ee57d54ec41c7e9d224bbdc2fe780e92ab9a3121ac23
    bytes32 constant public PRICE_ENGINE_ROLE = keccak256("PRICE_ENGINE_ROLE");
    // ORDER_SETTLEMENT_ROLE == 0xe86b8cfb9aa65728dcd630ae4251d1ffddc3fa87d7c7c21b8c0260fd9c23ebd7
    bytes32 constant public ORDER_SETTLEMENT_ROLE = keccak256("ORDER_SETTLEMENT_ROLE");
    // LEDGER_MANAGER_ROLE == 0x7b92c0c7fdcf766fb7ab1ec799b8a5d63ffbb8f32562df76cfe6f15236646b1e
    bytes32 constant public LEDGER_MANAGER_ROLE = keccak256("LEDGER_MANAGER_ROLE");
    // ASSETS_ACCESS_ROLE == c1e5733ec28e234d484b6103bdef83a5673ff69184743307c0b0c96db66e276e
    bytes32 constant public ASSETS_ACCESS_ROLE = keccak256("ASSETS_ACCESS_ROLE");

    modifier onlyAdmin() {
        require(hasRole(SYSTEM_ADMIN_ROLE, msg.sender) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        _;
    }

    /**
    * @dev Calls internal AccessControl function which reverts with a standard message if `account` is missing `role`.
    */
    function checkRole(bytes32 role, address account) external view {
        return _checkRole(role, account);
    }

    /**
    * @dev Calls internal AccessControl function which reverts with a standard message if `account` is missing `ASSETS_ACCESS_ROLE`.
    *
    * This function is here to lower gas usage as it might be called in the loop.
    */
    function checkAssetsAccessRole(address account) external view {
        return _checkRole(ASSETS_ACCESS_ROLE, account);
    }
}

contract SystemContext is SystemRoles {
    SlidingWindowLedger public slidingWindowLedger;
    LedgerManager public ledgerManager;
    ProfitSplitter public profitSplitter;
    PaypoolV1ERC20 public brightPoolToken;
    RewardReduction public rewardReduction;
    DailyLimit public dailyLimit;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SYSTEM_CONTEXT_ROLE, address(this));
    }

    /**
    * @dev Sets address of sliding window ledger.
    *
    * Requirements:
    * - `msg.sender` has one of admin roles.
    */
    function setSlidingWindowLedger(SlidingWindowLedger slidingWindowLedger_) external onlyAdmin {
        slidingWindowLedger = slidingWindowLedger_;
    }

    /**
    * @dev Sets address of ledger manager and,
    *
    * Requirements:
    * - `msg.sender` has one of admin roles.
    */
    function setLedgerManager(LedgerManager ledgerManager_) external onlyAdmin {
        ledgerManager = ledgerManager_;
    }

    /**
    * @dev Sets address of profit splitter contract.
    *
    * Requirements:
    * - `msg.sender` has one of admin roles.
    */
    function setProfitSplitter(ProfitSplitter profitSplitter_) external onlyAdmin {
        profitSplitter = profitSplitter_;
    }

    /**
    * @dev Sets address of Bright Pool One token.
    *
    * Requirements:
    * - `msg.sender` has one of admin roles.
    */
    function setBrightPoolToken(PaypoolV1ERC20 brightPoolToken_) external onlyAdmin {
        brightPoolToken = brightPoolToken_;
    }

    /**
    * @dev Sets address of reward reduction contract.
    *
    * Requirements:
    * - `msg.sender` has one of admin roles.
    */
    function setRewardReduction(RewardReduction rewardReduction_) external onlyAdmin {
        rewardReduction = rewardReduction_;
    }

    /**
    * @dev Sets address of daily limit contract.
    *
    * Requirements:
    * - `msg.sender` has one of admin roles.
    */
    function setDailyLimit(DailyLimit dailyLimit_) external onlyAdmin {
        dailyLimit = dailyLimit_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IOFTUpgradeable.sol";
import "./libraries/NonblockingLzAppUpgradeable.sol";

contract PaypoolV1ERC20 is NonblockingLzAppUpgradeable, ERC20Upgradeable, PausableUpgradeable, IOFTUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint256 public maxLocalSupply;
    uint256 internal globalSupply;

    /**
    * @dev Initialize token.
    * @param _lzEndpoint - Layer Zero endpoint address.
    * @param _globalSupply - sum of token supplies on all network.
    * @param _localSupply - local total supply. This amount of tokens will be minted to `msg.sender`
    *
    * IMPORTANT! The purpose of initializer is not to have proxy support, but to be able to deploy token
    * with the same address on multiple networks.
    *
    * Requirements:
    * - it is first initialization
    */
    function initialize(address _admin, ILayerZeroEndpoint _lzEndpoint, uint256 _globalSupply, uint256 _localSupply, uint256 _maxLocalSupply, string memory _tokenName, string memory _ticker) public initializer {
        __PaypoolV1ERC20_init(_admin, _lzEndpoint, _globalSupply, _localSupply, _maxLocalSupply, _tokenName, _ticker);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __PaypoolV1ERC20_init(address _admin, ILayerZeroEndpoint _lzEndpoint, uint256 _globalSupply, uint256 _localSupply, uint256 _maxLocalSupply, string memory _tokenName, string memory _ticker) internal onlyInitializing {
        __PaypoolV1ERC20_init_unchained(_admin, _globalSupply, _localSupply, _maxLocalSupply);
        __ERC20_init_unchained(_tokenName, _ticker);
        __Pausable_init_unchained();
        __LzApp_init_unchained(_lzEndpoint);
        _transferOwnership(_admin);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __PaypoolV1ERC20_init_unchained(address _admin, uint256 _globalSupply, uint256 _localSupply, uint256 _maxLocalSupply) internal onlyInitializing {
        // solhint-disable-next-line reason-string
        require(_maxLocalSupply >= _localSupply, "PaypoolV1ERC20: mint cannot exceed maximum");
        // solhint-disable-next-line reason-string
        require(_globalSupply >= _maxLocalSupply, "PaypoolV1ERC20: global supply must be bigger than max local supply");
        globalSupply = _globalSupply;
        maxLocalSupply = _maxLocalSupply;
        if(_localSupply > 0) {
            _mint(_admin, _localSupply);
        }
        _pause();
    }

    /**
    * @dev Sets Layer Zero endpoint address to communicate with.
    * @param _lzEndpoint - a new endpoint address
    *
    * Requirements:
    *
    * - `msg.sender` is a contract admin.
    */
    function setLzEndpoint(ILayerZeroEndpoint _lzEndpoint) external onlyOwner {
        lzEndpoint = _lzEndpoint;
    }

    /**
    * @dev Based on provided parameters it estimates native currency (ETH / MATIC etc) fee of L0 tx.
    * @param _dstChainId - Layer Zero chain id of destination network (it's not equal to EVM chain id!)
    * @param _toAddress - receiving address on destination chain. Bytes format to support not-evm chains.
    * @param _amount - amount of native currency to be send (ETH / Matic etc).
    * @param _useZro - boolean use or not ZRO for fees payment.
    * @param _adapterParams - encoded raw LayerZero adapter params (it has info about max gas usage etc)
    */
    function estimateSendFee(uint16 _dstChainId, bytes calldata _toAddress, uint256 _amount, bool _useZro, bytes calldata _adapterParams) external view virtual override returns (uint nativeFee, uint zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _amount);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    /**
    * @dev Sends transaction into the Layer Zero endpoint.
    * @param _dstChainId - Layer Zero chain id of destination network (it's not equal to EVM chain id!)
    * @param _toAddress - receiving address on destination chain. Bytes format to support not-evm chains.
    * @param _amount - amount of native currency to be send (ETH / Matic etc).
    * @param _refundAddress - address where the native currency will be returned if send to much (on local network).
    * @param _zroPaymentAddress - address which can pays fee in ZRO (currently not used).
    * @param _adapterParams - encoded raw LayerZero adapter params (it has info about max gas usage etc)
    *
    * Requirements:
    *
    * - send it not paused.
    */
    function send(uint16 _dstChainId, bytes calldata _toAddress, uint256 _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable virtual override {
        _send(_msgSender(), _dstChainId, _toAddress, _amount, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    /**
    * @dev Sends transaction into the Layer Zero endpoint.
    * @param _from - Address of funds owner which function transfers from.
    * @param _dstChainId - Layer Zero chain id of destination network (it's not equal to EVM chain id!)
    * @param _toAddress - receiving address on destination chain. Bytes format to support not-evm chains.
    * @param _amount - amount of native currency to be send (ETH / Matic etc).
    * @param _refundAddress - address where the native currency will be returned if send to much (on local network).
    * @param _zroPaymentAddress - address which can pays fee in ZRO (currently not used).
    * @param _adapterParams - encoded raw LayerZero adapter params (it has info about max gas usage etc)
    *
    * Requirements:
    *
    * - send it not paused.
    */
    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint256 _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable virtual override {
        if (_from != _msgSender()) {
            _spendAllowance(_from, _msgSender(), _amount);
        }
        _send(_from, _dstChainId, _toAddress, _amount, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    /**
    * @dev returns the type of OFT
     */
    function getType() external view virtual override returns (uint) {
        return 0;
    }

    /**
    * @dev returns the total amount of tokens across all chains
     */
    function getGlobalSupply() external view virtual override returns (uint) {
        return globalSupply;
    }

    /**
    * @dev Function enforces that transaction cannot fail because of wrong processing information.
    */
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory, /*_srcAddress*/
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint amount) = abi.decode(_payload, (bytes, uint256));
        address toAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        _creditTo(_srcChainId, toAddress, amount);

        emit ReceiveFromChain(_srcChainId, toAddress, amount, _nonce);
    }

    function _send(address _from, uint16 _dstChainId, bytes memory _toAddress, uint256 _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParam) internal virtual {
        _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory payload = abi.encode(_toAddress, _amount);
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParam);

        uint64 nonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendToChain(_from, _dstChainId, _toAddress, _amount, nonce);
    }

    function _debitFrom(
        address _from,
        uint16, // _dstChainId
        bytes memory, // _toAddress
        uint256 _amount
    ) internal virtual whenNotPaused {
        _burn(_from, _amount);
    }

    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual {
        _mint(_toAddress, _amount);
        // solhint-disable-next-line reason-string
        require(totalSupply() <= maxLocalSupply, "PaypoolV1ERC20: total supply too high");
    }

    /**
    * @dev Burns `msg.sender` tokens.
    * @param _amount - amount of tokens to burn.
    *
    * Requirements:
    *
    * - `msg.sender` is a contract admin.
    */
    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
        maxLocalSupply -= _amount;
    }

    /**
    * @dev Sets maximum per network supply.
    * @param _maxNetSupply - amount of maximum supply on current chain.
    *
    * Requirements:
    *
    * - `msg.sender` is a contract admin.
    */
    function setMaxLocalSupply(uint256 _maxNetSupply) external onlyOwner {
        maxLocalSupply = _maxNetSupply;
    }

    /**
    * @dev Pauses or unpauses Layer Zero multi-chain transfers
    * @param pause - boolean to pause or unpause token.
    *
    * Requirements:
    *
    * - `msg.sender` is a contract admin.
    */
    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/LedgerTypes.sol";
import "./SystemContext.sol";


contract SlidingWindowLedger {
    using EnumerableSet for EnumerableSet.UintSet;

    // Events emit when a new order is created
    event OrderAdded(uint256 indexed orderId, address askAsset, uint256 askAmount, address offerAsset, uint256 offerAmount, address owner, bool isPut);
    // Events emit when existing order is removed
    event OrderRemoved(uint256 indexed orderId);

    // system access control and access to other system contracts.
    SystemContext public systemContext;
    // Contains available orders lengths.
    EnumerableSet.UintSet internal availableOrderLengths;

    // Order library
    mapping(uint256 => LedgerTypes.OrderInfo) internal orders;
    mapping(uint256 => uint256) internal endTime;

    modifier onlyAdmin() {
        systemContext.checkRole(0x0, msg.sender);
        _;
    }

    modifier onlyManager() {
        systemContext.checkRole(systemContext.LEDGER_MANAGER_ROLE(), msg.sender);
        _;
    }

    constructor (SystemContext systemContext_, uint256[] memory orderLengths_) {
        systemContext = systemContext_;
        uint256 orderLengthsLength = orderLengths_.length;
        for (uint256 i = 0; i < orderLengthsLength;) {
            // slither-disable-next-line unused-return
            availableOrderLengths.add(orderLengths_[i]);

            // Gas optimisation
            unchecked { ++i; }
        }
    }

    /**
    * @dev Adds available order lengths.
     *
     * Requirements:
     *
     * - any of `orderLengths` must be not added yet.
     */
    function addOrderLengths(uint256[] memory orderLengths) external onlyAdmin {
        uint256 orderLengthsLength = orderLengths.length;
        for (uint256 i = 0; i < orderLengthsLength;) {
            require(availableOrderLengths.add(orderLengths[i]), "Order length already added");

            // Gas optimisation
            unchecked { ++i; }
        }
    }

    /**
    * @dev Remove available order lengths.
     *
     * Requirements:
     *
     * - any of `orderLengths` must be present.
     */
    function removeOrderLengths(uint256[] memory orderLengths) external onlyAdmin {
        uint256 orderLengthsLength = orderLengths.length;
        for (uint256 i = 0; i < orderLengthsLength;) {
            require(availableOrderLengths.remove(orderLengths[i]), "Order length not available");

            // Gas optimisation
            unchecked { ++i; }
        }
    }

    /**
    * @dev Returns possible order lengths.
     */
    function getOrderLengths() external view returns(uint256[] memory) {
        return availableOrderLengths.values();
    }

    /**
    * @dev Adds order and sets all of it's parameters.
     */
    function _addOrder(LedgerTypes.OrderInfo memory orderInfo, uint256 endsInSec) internal {
        require(orders[orderInfo.id].id == 0, "Order Id used");
        orders[orderInfo.id] = orderInfo;
        // solhint-disable-next-line not-rely-on-time
        endTime[orderInfo.id] = block.timestamp + endsInSec;
    }

    /**
    * @dev Removes order and deletes expiration time.
     */
    function _deleteOrder(uint256 orderId_) internal {
        delete orders[orderId_];
        delete endTime[orderId_];
    }

    /**
    * @dev Returns owner of order with id `orderId_`.
     */
    function ownerOfOrder(uint256 orderId_) external view returns(address) {
        return orders[orderId_].owner;
    }

    /**
    * @dev Adds a new order into the order pool.
     *
     * Requirements:
     *
     * - order duration `endsInSec` must be whitelisted.
     */
    function addOrder(LedgerTypes.OrderInfo memory orderInfo, uint256 endsInSec) external onlyManager returns(uint256) {
        require(availableOrderLengths.contains(endsInSec), "Order length is not supported.");
        require(orderInfo.id != 0, "Order Id cannot be zero");

        _addOrder(orderInfo, endsInSec);

        emit OrderAdded(orderInfo.id, orderInfo.askAsset, orderInfo.askAmount, orderInfo.offerAsset, orderInfo.offerAmount, orderInfo.owner, orderInfo.isPut);
        return orderInfo.id;
    }

    /**
    * @dev Removes existing order from order pool.
     *
     * Requirements:
     *
     * - order exists in order pool.
     */
    function removeOrder(uint256 orderId_) external onlyManager {
        emit OrderRemoved(orderId_);
        _deleteOrder(orderId_);
    }

    /**
    * @dev Returns order info for order with particular id `orderId_`.
     */
    function getOrder(uint256 orderId_) external view returns(LedgerTypes.OrderInfo memory) {
        return orders[orderId_];
    }

    /**
    * @dev Returns operation status along with order info for order with particular id `orderId_` and removes order from orders list.
     */
    function tryPopOrder(uint256 orderId_) external returns(bool, LedgerTypes.OrderInfo memory) {
        bool exists = orders[orderId_].id != 0;
        LedgerTypes.OrderInfo memory order = orders[orderId_];
        _deleteOrder(orderId_);

        return (exists, order);
    }

    /**
    * @dev Returns order end window for order with particular id `orderId_`.
     */
    function getOrderEndTime(uint256 orderId_) external view returns(uint256) {
        return endTime[orderId_];
    }

    function orderExists(uint256 orderId_) external view returns(bool) {
        return orders[orderId_].id != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SlidingWindowLedger.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Erc20Asset.sol";
import "./NativeAsset.sol";
import "./PaypoolV1ERC20.sol";
import "./ProfitSplitter.sol";
import "./RewardReduction.sol";
import "./DailyLimit.sol";

contract LedgerManager is ReentrancyGuard {
    using ECDSA for bytes32;

    string constant internal ERROR_NATIVE_NOT_SUPPORTED = "Native asset not supported";

    event OrderFilled(address owner, address askAsset, uint256 askAmount);
    event OrderReverted(address owner, address offerAsset, uint256 offerAmount);

    mapping(address => mapping(address => bool)) internal allowedPairs;
    mapping(address => Erc20Asset) public assets;
    NativeAsset public nativeAsset;

    SystemContext public systemContext;
    SlidingWindowLedger public ledger;
    PaypoolV1ERC20 public rewardToken;
    ProfitSplitter public profitSplitter;
    RewardReduction public rewardReduction;
    DailyLimit public dailyLimit;
    address public teamWallet;

    uint256 public withdrawnRewards;

    constructor (SystemContext systemContext_) {
        systemContext = systemContext_;

        ledger = systemContext_.slidingWindowLedger();
        profitSplitter = systemContext_.profitSplitter();
        rewardReduction = systemContext_.rewardReduction();
        dailyLimit = systemContext_.dailyLimit();
        rewardToken = systemContext_.brightPoolToken();
    }

    modifier onlyAdmin() {
        systemContext.checkRole(0x0, msg.sender);
        _;
    }

    modifier onlyRole(bytes32 role) {
        systemContext.checkRole(role, msg.sender);
        _;
    }

    /**
    * @dev Adds a new supported asset.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function addAsset(Erc20Asset assetStorage) external onlyAdmin {
        address assetAddress = address(assetStorage.assetAddress());
        assets[assetAddress] = assetStorage;
    }

    /**
    * @dev Remove asset from whitelist.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function removeAsset(address assetWrapped) external onlyAdmin {
        delete assets[assetWrapped];
    }

    /**
    * @dev Sets address of NativeAsset instance.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function setNativeAsset(NativeAsset nativeAssetStorage_) external onlyAdmin {
        nativeAsset = nativeAssetStorage_;
    }

    /**
    * @dev Sets address of the reward token.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function setRewardToken(PaypoolV1ERC20 rewardToken_) external onlyAdmin {
        rewardToken = rewardToken_;
    }

    /**
    * @dev Sets address of the profit splitter.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function setProfitSplitter(ProfitSplitter profitSplitter_) external onlyAdmin {
        profitSplitter = profitSplitter_;
    }

    /**
    * @dev Sets address of the reward reduction contract.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function setRewardReduction(RewardReduction rewardReduction_) external onlyAdmin {
        rewardReduction = rewardReduction_;
    }

    /**
    * @dev Sets address of the daily limit contract.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function setDailyLimit(DailyLimit dailyLimit_) external onlyAdmin {
        dailyLimit = dailyLimit_;
    }

    /**
    * @dev Sets team wallet.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function setTeamWallet(address teamWallet_) external onlyAdmin {
        teamWallet = teamWallet_;
    }

    /**
    * @dev Returns address of the signer.
    */
    function _getMessageSigner(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        return messageHash
        .toEthSignedMessageHash()
        .recover(signature);
    }

    /**
    * @dev Creates message from ethAddress and phrAddress and returns hash.
    */
    function _createAddOrderMessageHash(LedgerTypes.OrderInfo memory orderInfo, uint256 endsInSec, uint256 deadline, uint256 rewardBaseAmount) internal pure returns (bytes32) {
        // TODO maybe it would be possible to pack entire OrderInfo as 1 parameter (abi.encode(orderInfo))
        return keccak256(abi.encodePacked(orderInfo.id, orderInfo.askAsset, orderInfo.askAmount, orderInfo.offerAsset, orderInfo.offerAmount, orderInfo.owner, orderInfo.isPut, endsInSec, deadline, rewardBaseAmount));
    }

    /**
    * @dev Creates message for remove order and returns hash.
    */
    function _createRemoveOrderMessageHash(uint256 orderId, uint256 baseReward) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, baseReward));
    }

    /**
    * @dev Checks if particular pair is whitelisted.
    */
    function pairExists(address tokenA, address tokenB) public view returns (bool) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return allowedPairs[token0][token1];
    }

    /**
    * @dev Adds new whitelisted pair.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function addPair(address tokenA, address tokenB) external onlyAdmin {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(allowedPairs[token0][token1] == false, "This pair is already whitelisted");
        allowedPairs[token0][token1] = true;
    }

    /**
    * @dev Removes whitelisted pair.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function removePair(address tokenA, address tokenB) external onlyAdmin {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(allowedPairs[token0][token1], "This pair is not whitelisted");
        allowedPairs[token0][token1] = false;
    }

    /**
    * @dev Sends funds from user to our erc20 or native asset storage.
    *
    * Requirements:
    *
    * - `asset` is supported by smart contract (can be 0x00 for native).
    */
    function _depositAsset(address asset, uint256 amount) internal {
        if (asset == address(0)) {
            require(address(nativeAsset) != address(0), ERROR_NATIVE_NOT_SUPPORTED);
            require(msg.value == amount, "Native amount incorrect");
            payable(nativeAsset).transfer(amount);

        } else {
            // solhint-disable-next-line reason-string
            require(IERC20(asset).allowance(msg.sender, address(this)) >= amount, "Allowance for offerAsset is missing");
            require(address(assets[asset]) != address(0), string(abi.encodePacked("Asset ", Strings.toHexString(uint160(asset), 20), " not supported")));

            require(IERC20(asset).transferFrom(msg.sender, address(assets[asset]), amount), "transferFrom failed");
        }
    }

    /**
    * @dev Adds order into internal order pool and starts other operations.
    *
    * Requirements:
    *
    * - `deadline` must be strictly less than `block.timestamp`.
    * - contract has enough allowance to transfer `msg.sender` token (offerAsset).
    * - pair (offer + ask assets) is whitelisted.
    */
    function addOrder(LedgerTypes.OrderInfo memory orderInfo, uint256 endsInSec, uint256 deadline, uint256 rewardBaseAmount, bytes memory signature) external payable returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(deadline >= block.timestamp, "Order approval expired");
        require(pairExists(orderInfo.offerAsset, orderInfo.askAsset), "This pair is not whitelisted");
        require(orderInfo.owner == msg.sender, "Sender is not an owner of order");

        bytes32 msgHash = _createAddOrderMessageHash(orderInfo, endsInSec, deadline, rewardBaseAmount);
        systemContext.checkRole(systemContext.PRICE_ENGINE_ROLE(), _getMessageSigner(msgHash, signature));

        _depositAsset(orderInfo.offerAsset, orderInfo.offerAmount);

        uint256 reward = rewardReduction.reduceReward(withdrawnRewards, rewardBaseAmount);
        withdrawnRewards += dailyLimit.withdrawReward(msg.sender, reward);

        return ledger.addOrder(orderInfo, endsInSec);
    }

    /**
    * @dev Removes order from internal order pool.
    *
    */
    function removeOrder(uint256 orderId, uint256 rewardBaseAmount, bytes memory signature) external payable {
        require(teamWallet != address(0), "Team wallet not set");

        bytes32 msgHash = _createRemoveOrderMessageHash(orderId, rewardBaseAmount);
        systemContext.checkRole(systemContext.PRICE_ENGINE_ROLE(), _getMessageSigner(msgHash, signature));

        (bool success, LedgerTypes.OrderInfo memory orderInfo) = ledger.tryPopOrder(orderId);
        require(success, "Order don't exist");

        profitSplitter.withdrawAsset(orderInfo.owner, orderInfo.offerAsset, orderInfo.offerAmount);

        uint256 reward = rewardReduction.reduceReward(withdrawnRewards, rewardBaseAmount);
        assert(rewardToken.transferFrom(msg.sender, teamWallet, reward));
    }

    /**
    * @dev Function executed by dex cron, it prepares assets for future orders
    *
    * Requirements:
    *
    * - `msg.sender` must have ORDER_SETTLEMENT_ROLE role.
    * - fundsInfo is correctly calculated and given to manager.
    */
    function swapAssets(LedgerTypes.FundsInfo[] calldata fundsInfo) external onlyRole(systemContext.ORDER_SETTLEMENT_ROLE()) nonReentrant {
        return profitSplitter.swapAssets(fundsInfo);
    }

    /**
    * @dev Function executed by dex cron, it fulfills orders given in the `settleInfo` list
    *
    * Requirements:
    *
    * - `msg.sender` must have ORDER_SETTLEMENT_ROLE role.
    * - fundsInfo is correctly calculated and given to manager.
    * - all orders from `settleInfo` list exists.
    */
    function settleOrders(LedgerTypes.SettlementInfo[] calldata settleInfo, LedgerTypes.FundsInfo[] calldata fundsInfo) external onlyRole(systemContext.ORDER_SETTLEMENT_ROLE()) nonReentrant {
        if (fundsInfo.length != 0) {
            profitSplitter.swapAssets(fundsInfo);
        }

        uint256 length = settleInfo.length;
        for (uint256 i = 0; i < length;) {
            LedgerTypes.SettlementInfo memory info = settleInfo[i];
            (bool success, LedgerTypes.OrderInfo memory orderInfo) = ledger.tryPopOrder(info.orderId);
            require(success, "Order don't exist");

            if (info.fillOrder) {
                profitSplitter.withdrawAsset(orderInfo.owner, orderInfo.askAsset, orderInfo.askAmount);
                emit OrderFilled(orderInfo.owner, orderInfo.askAsset, orderInfo.askAmount);
            } else {
                profitSplitter.withdrawAsset(orderInfo.owner, orderInfo.offerAsset, orderInfo.offerAmount);
                emit OrderReverted(orderInfo.owner, orderInfo.offerAsset, orderInfo.offerAmount);
            }
            // Gas optimisation
            unchecked { ++i; }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IAsset.sol";
import "./libraries/LedgerTypes.sol";
import "./Erc20Asset.sol";
import "./LedgerManager.sol";
import "./UniswapExchangeAdapter.sol";
import "./SystemContext.sol";

contract ProfitSplitter {

    struct SplitConfig {
        address toAddress;
        uint16 feePercent;
    }

    string constant private ERROR_NATIVE_NOT_SUPPORTED = "Native asset not supported";

    event Profit(uint256 profit, address token, IAsset storedAt);
    event Loss(uint256 loss, address token, IAsset storedAt);

    UniswapExchangeAdapter public adapter;
    SystemContext public systemContext;
    SplitConfig[] public splitConfig;

    modifier onlyAdmin() {
        systemContext.checkRole(0x0, msg.sender);
        _;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.checkRole(role_, msg.sender);
        _;
    }

    constructor (SystemContext systemContext_, UniswapExchangeAdapter adapter_,
        address[] memory splitConfigAddresses_, uint16[] memory splitConfigFeePercent_) {
        systemContext = systemContext_;
        adapter = adapter_;
        _setSplitConfig(splitConfigAddresses_, splitConfigFeePercent_);
    }

    /**
    * @dev Function sets new split config.
    */
    function setSplitConfig(address[] memory splitConfigAddresses_, uint16[] memory splitConfigFeePercent_) external onlyAdmin {
        _setSplitConfig(splitConfigAddresses_, splitConfigFeePercent_);
    }

    /**
    * @dev Function sets new split config.
    */
    function _setSplitConfig(address[] memory splitConfigAddresses_, uint16[] memory splitConfigFeePercent_) internal {
        uint256 splitConfigAddressesLength = splitConfigAddresses_.length;
        require(splitConfigAddressesLength == splitConfigFeePercent_.length, "Arr length mismatch");

        delete splitConfig;
        uint16 percentSum = 0;
        for (uint256 i = 0; i < splitConfigAddressesLength;) {
            percentSum += splitConfigFeePercent_[i];
            splitConfig.push(
                SplitConfig({
                    toAddress: splitConfigAddresses_[i],
                    feePercent: splitConfigFeePercent_[i]
                })
            );
            // Gas optimisation
            unchecked { ++i; }
        }

        // solhint-disable-next-line reason-string
        require(percentSum <= 100, "Cannot redistribute more than 100% of earnings");
    }

    /**
    * @dev Redistribute rewards using specified config.
    */
    function _splitReward(uint256 profit_, IAsset asset_) internal {
        uint256 splitConfigLength = splitConfig.length;
        for (uint256 i = 0; i < splitConfigLength;) {
            asset_.transfer(splitConfig[i].toAddress, (profit_ * splitConfig[i].feePercent) / 100);
            // Gas optimisation
            unchecked { ++i; }
        }
    }

    /**
    * @dev Function which emits status of swap (Loss or Profit).
    */
    function _handle(uint256 sold, uint256 zeroProfitLimit, IAsset asset) internal {
        if (sold > zeroProfitLimit) { // report loss
            emit Loss(sold - zeroProfitLimit, asset.getAddress(), asset);
        } else { // report profit
            uint256 profit_ = zeroProfitLimit - sold;
            emit Profit(profit_, asset.getAddress(), asset);
            _splitReward(profit_, asset);
        }
    }

    /**
    * @dev Function executed by dex cron, it prepares assets for future orders
    *
    * Requirements:
    *
    * - `msg.sender` must have LEDGER_MANAGER_ROLE role.
    * - fundsInfo is correctly calculated and given to manager.
    */
    function swapAssets(LedgerTypes.FundsInfo[] calldata fundsInfo) external onlyRole(systemContext.LEDGER_MANAGER_ROLE()) {
        _swapAssets(fundsInfo);
    }

    /**
    * @dev See 'swapAssets' docs
    */
    function _swapAssets(LedgerTypes.FundsInfo[] calldata fundsInfo) internal {
        LedgerManager ledger = systemContext.ledgerManager();
        uint256 fundsInfoLength = fundsInfo.length;
        for (uint256 i = 0; i < fundsInfoLength;) {
            LedgerTypes.FundsInfo memory fundInfo = fundsInfo[i];

            if (fundInfo.from == address(0)) { // from native to token
                // solhint-disable-next-line reason-string
                require(fundInfo.to != address(0), "Cannot exchange native for native");
                NativeAsset nativeAsset = ledger.nativeAsset();
                require(address(nativeAsset) != address(0), ERROR_NATIVE_NOT_SUPPORTED);

                bytes memory call = adapter.exchangeNativeForToken(nativeAsset, fundInfo.fromMaxAmount, ledger.assets(fundInfo.to), fundInfo.toAmount);

                uint256 beforeBalance = nativeAsset.balance();
                nativeAsset.execute(address(adapter.router()), call, fundInfo.fromMaxAmount);
                _handle(beforeBalance - nativeAsset.balance(), fundInfo.fromZeroProfit, nativeAsset);
            } else if (fundInfo.to == address(0)) { // from token to native
                NativeAsset nativeAsset = ledger.nativeAsset();
                require(address(nativeAsset) != address(0), ERROR_NATIVE_NOT_SUPPORTED);
                require(address(ledger.assets(fundInfo.from)) != address(0), string(abi.encodePacked("Asset ", Strings.toHexString(uint160(fundInfo.from), 20), " not supported")));

                Erc20Asset from = ledger.assets(fundInfo.from);
                bytes memory call = adapter.exchangeTokenForNative(from, fundInfo.fromMaxAmount, nativeAsset, fundInfo.toAmount);

                uint256 beforeBalance = from.balance();
                from.execute(address(adapter.router()), call, fundInfo.fromMaxAmount);
                _handle(beforeBalance - from.balance(), fundInfo.fromZeroProfit, from);
            } else { // tokens
                require(address(ledger.assets(fundInfo.from)) != address(0), string(abi.encodePacked("Asset ", Strings.toHexString(uint160(fundInfo.from), 20), " not supported")));
                require(address(ledger.assets(fundInfo.to)) != address(0), string(abi.encodePacked("Asset ", Strings.toHexString(uint160(fundInfo.to), 20), " not supported")));

                Erc20Asset from = ledger.assets(fundInfo.from);
                bytes memory call = adapter.exchangeTokens(from, fundInfo.fromMaxAmount, ledger.assets(fundInfo.to), fundInfo.toAmount);

                uint256 beforeBalance = from.balance();
                from.execute(address(adapter.router()), call, fundInfo.fromMaxAmount);
                _handle(beforeBalance - from.balance(), fundInfo.fromZeroProfit, from);
            }

            // Gas optimisation
            unchecked { ++i; }
        }
    }

    /**
    * @dev Withdraw funds from asset storage to `recipient`
    *
    * Requirements:
    *
    * - `asset` is supported by smart contract (can be 0x00 for native).
    */
    function withdrawAsset(address recipient, address asset, uint256 amount) external onlyRole(systemContext.LEDGER_MANAGER_ROLE()) {
        LedgerManager ledger = systemContext.ledgerManager();
        if (asset == address(0)) {
            // native asset
            NativeAsset nativeAsset = ledger.nativeAsset();
            require(address(nativeAsset) != address(0), ERROR_NATIVE_NOT_SUPPORTED);
            nativeAsset.transfer(payable(recipient), amount);
        } else {
            // erc20 asset
            require(address(ledger.assets(asset)) != address(0), string(abi.encodePacked("Asset ", Strings.toHexString(uint160(asset), 20), " not supported")));
            ledger.assets(asset).transfer(recipient, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


library LedgerTypes {
    struct OrderInfo {
        uint256 id;
        address askAsset;
        uint256 askAmount;
        address offerAsset;
        uint256 offerAmount;
        address owner;
        bool isPut;
    }

    struct SettlementInfo {
        uint256 orderId;
        bool fillOrder;
    }

    struct FundsInfo {
        address from;
        uint256 fromMaxAmount; // sell no more than this amount
        uint256 fromZeroProfit; // when no more that this is sold we earned
        address to;
        uint256 toAmount;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAsset.sol";
import "./SystemContext.sol";

contract Erc20Asset is IAsset {
    IERC20 public assetAddress;
    SystemContext public systemContext;

    constructor (address assetAddress_, SystemContext systemContext_) {
        assetAddress = IERC20(assetAddress_);
        systemContext = systemContext_;
    }

    modifier onlyAssetAccessRole() {
        systemContext.checkAssetsAccessRole(msg.sender);
        _;
    }

    /**
    * @dev Returns address of wrapped erc20 in that case it is equal to `assetAddress`.
    */
    function getAddress() external view override returns(address) {
        return address(assetAddress);
    }

    /**
    * @dev Transfers ERC20 `amount` to `recipient`.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function transfer(address recipient, uint256 amount) override external onlyAssetAccessRole {
        require(recipient != address(0), "Cannot send to zero address");
        require(assetAddress.transfer(recipient, amount), "Erc20Asset: transfer failed");
    }

    /**
    * @dev Returns balance of underlying ERC20 asset.
    */
    function balance() external view override returns (uint256) {
        return assetAddress.balanceOf(address(this));
    }

    /**
    * @dev Executes low level call given from LedgerManager to swap token into the native or other token.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function execute(address target, bytes calldata call, uint256 minApprove) override external onlyAssetAccessRole returns (bytes memory) {
        require(target != address(0), "Cannot send to zero address");
        require(assetAddress.approve(target, minApprove) == true, "Approval failed");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call(call);
        require(success, "External swap on dex failed");

        return returnData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAsset.sol";
import "./SystemContext.sol";

contract NativeAsset is IAsset {
    address public nativeWrapped;
    SystemContext public systemContext;

    constructor (address nativeWrapped_, SystemContext systemContext_) {
        nativeWrapped = nativeWrapped_;
        systemContext = systemContext_;
    }

    modifier onlyAssetAccessRole() {
        systemContext.checkAssetsAccessRole(msg.sender);
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
    fallback() external payable {}

    /**
    * @dev Returns address of wrapped asset, we treat native as address(0), so it returns it always.
    */
    function getAddress() external pure override returns(address) {
        return address(0);
    }

    /**
    * @dev Exposes `deposit` function for depositing native asset, it can be used instead of regular fallback function.
    */
    // solhint-disable-next-line no-empty-blocks
    function deposit() external payable  {
    }

    /**
    * @dev Transfers native `amount` to `recipient`.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function transfer(address recipient, uint256 amount) override external onlyAssetAccessRole {
        require(recipient != address(0), "Cannot send to zero address");
        payable(recipient).transfer(amount);
    }

    /**
    * @dev Returns balance of native asset.
    */
    function balance() override external view returns (uint256) {
        return address(this).balance;
    }

    /**
    * @dev Executes low level call given from LedgerManager to swap native into the token.
    *
    * Requirements:
    *
    * - `msg.sender` is contract admin.
    */
    function execute(address target, bytes calldata call, uint256 nativeAmount) override external onlyAssetAccessRole returns (bytes memory) {
        require(target != address(0), "Cannot send to zero address");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: nativeAmount}(call);
        require(success, "External swap on dex failed");

        return returnData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SystemContext.sol";

contract RewardReduction {
    uint32[] public cumulativeSupply = [4000000, 4000540, 4002135, 4004743, 4008326, 4012847, 4018269, 4024554, 4031668, 4039577, 4048247, 4057645, 4067739, 4078498, 4089892, 4101891, 4114466, 4127590, 4141234, 4155373, 4169981, 4185032, 4200503, 4216368, 4232607, 4249195, 4266111, 4283335, 4300846, 4318623, 4336649, 4354904, 4373370, 4392031, 4410868, 4429867, 4449012, 4468287, 4487677, 4507170, 4526751, 4546407, 4566126, 4585897, 4605707, 4625546, 4645403, 4665268, 4685132, 4704985, 4724819, 4744625, 4764397, 4784126, 4803805, 4823428, 4842988, 4862481, 4881900, 4901241, 4920498, 4939668, 4958747, 4977730, 4996616, 5015400, 5034080, 5052655, 5071121, 5089478, 5107723, 5125857, 5143878, 5161785, 5179579, 5197260, 5214828, 5232283, 5249626, 5266859, 5283983, 5300999, 5317909, 5334715, 5351420, 5368026, 5384535, 5400951, 5417277, 5433515, 5449670, 5465744, 5481743, 5497669, 5513528, 5529322, 5545058, 5560740, 5576372, 5591959, 5607507, 5623020, 5638505, 5653967, 5669412, 5684844, 5700271, 5715698, 5731132, 5746578, 5762044, 5777535, 5793058, 5808620, 5824228, 5839888, 5855608, 5871394, 5887253, 5903194, 5919223, 5935347, 5951573, 5967911, 5984366, 6000946, 6017660, 6034514, 6051517, 6068677, 6086000, 6103496, 6121172, 6139036, 6157097, 6175361, 6193838, 6212535, 6231461, 6250624, 6270031, 6289692, 6309614, 6329806, 6350276, 6371032, 6392082, 6413436, 6435101, 6457085, 6479397, 6502045, 6525038, 6548384, 6572091, 6596168, 6620623, 6645463, 6670699, 6696337, 6722387, 6748856, 6775753, 6803086, 6830863, 6859093, 6887783, 6916942, 6946579, 6976701, 7007316, 7038434, 7070060, 7102205, 7134875, 7168079, 7201825, 7236121, 7270975, 7306394, 7342387, 7378962, 7416125, 7453886, 7492252, 7531230, 7570828, 7611055, 7651917, 7693422, 7735578, 7778393, 7821873, 7866026, 7910860, 7956382, 8002600, 8049520, 8097151, 8145499, 8194571, 8244374, 8294917, 8346205, 8398247, 8451048, 8504616, 8558958, 8614081, 8669991, 8726696, 8784202, 8842516, 8901644, 8961594, 9022372, 9083984, 9146438, 9209739, 9273894, 9338910, 9404793, 9471549, 9539184, 9607706, 9677120, 9747432, 9818648, 9890776, 9963820, 10037787, 10112683, 10188514, 10265286, 10343005, 10421676, 10501307, 10581901, 10663466, 10746007, 10829530, 10914040, 10999543, 11086045, 11173552, 11262069, 11351601, 11442154, 11533734, 11626346, 11719995, 11814687, 11910428, 12007222, 12105076, 12203994, 12303981, 12405043, 12507186, 12610413, 12714732, 12820146, 12926661, 13034282, 13143014, 13252863, 13363832, 13475929, 13589156, 13703521, 13819026, 13935679, 14053482, 14172442, 14292564, 14413852, 14536311, 14659946, 14784763, 14910765, 15037958, 15166347, 15295937, 15426732, 15558737, 15691958, 15826398, 15962064, 16098959, 16237088, 16376457, 16517070, 16658932, 16802048, 16946422, 17092060, 17238966, 17387144, 17536601, 17687340, 17839367, 17992686, 18147302, 18303220, 18460445, 18618981, 18778834, 18940008, 19102508, 19266340, 19431507, 19598015, 19765869, 19935073, 20105633, 20277554, 20450839, 20625496, 20801527, 20978939, 21157736, 21337924, 21519507, 21702491, 21886879, 22072679, 22259894, 22448530, 22638592, 22830086, 23023015, 23217386, 23413204, 23610473, 23809200, 24009390, 24211047, 24414177, 24618786, 24824879, 25032461, 25241538, 25452115, 25664198, 25877792, 26092903, 26309536, 26527697, 26747392, 26968626, 27191405, 27415734, 27641620, 27869068, 28098084, 28328674, 28560843, 28794598, 29029945, 29266889, 29505437, 29745594, 29987366, 30230761, 30475783, 30722439, 30970736, 31220679, 31472274, 31725529, 31980449, 32237041, 32495312, 32755266, 33016913, 33280256, 33545305, 33812064, 34080540, 34350741, 34622673, 34896342, 35171756, 35448921, 35727845, 36008534, 36290995, 36575235, 36861261, 37149080, 37438700, 37730127, 38023368, 38318432, 38615325, 38914054, 39214627, 39517051, 39821334, 40127483, 40435506, 40745410, 41057202, 41370891, 41686484, 42003988, 42323412, 42644764, 42968050, 43293279, 43620459, 43949598, 44280704, 44613784, 44948847, 45285901, 45624954, 45966015, 46309090, 46654190, 47001321, 47350492, 47701712, 48054989, 48410332, 48767748, 49127247, 49488836, 49852525, 50218322, 50586236, 50956275, 51328449, 51702765, 52079232, 52457861, 52838658, 53221633, 53606796, 53994155, 54383718, 54775495, 55169496, 55565728, 55964202, 56364926, 56767909, 57173161, 57580690, 57990507, 58402620, 58817038, 59233772, 59652829, 60074220, 60497954, 60924041, 61352489, 61783309, 62216509, 62652100, 63090090, 63530490, 63973308, 64418555, 64866240, 65316373, 65768963, 66224021, 66681554, 67141575, 67604091, 68069113, 68536651, 69006714, 69479312, 69954455, 70432152, 70912414, 71395250, 71880670, 72368684, 72859301, 73352532, 73848386, 74346874, 74848004, 75351788, 75858234, 76367353, 76879154, 77393648, 77910844, 78430752, 78953382, 79478744, 80006847, 80537702, 81071319, 81607706, 82146875, 82688835, 83233595, 83781166, 84331557, 84884778, 85440840, 85999750, 86561521, 87126160, 87693679, 88264086, 88837392, 89413605, 89992736, 90574795, 91159790, 91747732, 92338630, 92932494, 93529332, 94129156, 94731974, 95337795, 95946629, 96558486, 97173375, 97791304, 98412285, 99036324, 99663433, 100293620, 100926894, 101563265, 102202741, 102845332, 103491046, 104139893, 104791882, 105447020, 106105319, 106766785, 107431427, 108099256, 108770278, 109444503, 110121940, 110802596, 111486481, 112173602, 112863969, 113557589, 114254470, 114954621, 115658051, 116364766, 117074775, 117788086, 118504707, 119224646, 119947910, 120674507, 121404446, 122137732, 122874374, 123614380, 124357756, 125104510, 125854650, 126608181, 127365112, 128125450, 128889201, 129656371, 130426969, 131201000, 131978472, 132759390, 133543762, 134331593, 135122890, 135917658, 136715905, 137517637, 138322858, 139131575, 139943794, 140759520, 141578760, 142401517, 143227799, 144057609, 144890954, 145727839, 146568267, 147412245, 148259778, 149110869, 149965523, 150823746, 151685541, 152550913, 153419865, 154292403, 155168529, 156048249, 156931565, 157818481, 158709001, 159603129, 160500867, 161402218, 162307187, 163215776, 164127988, 165043825, 165963290, 166886386, 167813115, 168743480, 169677482, 170615124, 171556408, 172501335, 173449907, 174402126, 175357993, 176317509, 177280676, 178247495, 179217966, 180192090, 181169869, 182151303, 183136391, 184125135, 185117535, 186113590, 187113301, 188116666, 189123687, 190134362, 191148691, 192166673, 193188307, 194213592, 195242527, 196275111, 197311341, 198351217, 199394737, 200441899, 201492701, 202547141, 203605216, 204666924, 205732263, 206801230, 207873822, 208950035, 210029868, 211113316, 212200376, 213291045, 214385319, 215483194, 216584666, 217689731, 218798385, 219910623, 221026441, 222145834, 223268796, 224395324, 225525412, 226659055, 227796247, 228936982, 230081255, 231229061, 232380392, 233535244, 234693608, 235855480, 237020853, 238189719, 239362072, 240537905, 241717210, 242899980, 244086209, 245275887, 246469008, 247665564, 248865545, 250068945, 251275755, 252485966, 253699570, 254916558, 256136921, 257360650, 258587736, 259818169, 261051940, 262289040, 263529458, 264773184, 266020209, 267270523, 268524115, 269780974, 271041090, 272304453, 273571051, 274840873, 276113909, 277390147, 278669575, 279952182, 281237957, 282526887, 283818961, 285114167, 286412492, 287713924, 289018450, 290326059, 291636737, 292950471, 294267249, 295587058, 296909884, 298235714, 299564534, 300896332, 302231093, 303568804, 304909450, 306253019, 307599495, 308948864, 310301113, 311656226, 313014190, 314374988, 315738608, 317105034, 318474250, 319846243, 321220996, 322598495, 323978724, 325361668, 326747311, 328135637, 329526632, 330920278, 332316561, 333715465, 335116972, 336521068, 337927736, 339336960, 340748723, 342163009, 343579802, 344999084, 346420841, 347845053, 349271706, 350700782, 352132265, 353566137, 355002381, 356440981, 357881920, 359325180, 360770744, 362218595, 363668717, 365121090, 366575700, 368032527, 369491555, 370952766, 372416143, 373881669, 375349325, 376819096, 378290962, 379764907, 381240914, 382718964, 384199041, 385681126, 387165203, 388651254, 390139261, 391629207, 393121075, 394614847, 396110505, 397608034, 399107414, 400608629, 402111662, 403616495, 405123112, 406631494, 408141626, 409653489, 411167068, 412682345, 414199303, 415717925, 417238196, 418760097, 420283614, 421808728, 423335425, 424863686, 426393498, 427924842, 429457704, 430992067, 432527916, 434065234, 435604007, 437144219, 438685855, 440228899, 441773336, 443319152, 444866332, 446414861, 447964725, 449515909, 451068399, 452622182, 454177243, 455733570, 457291147, 458849963, 460410004, 461971257, 463533710, 465097350, 466662165, 468228142, 469795270, 471363538, 472932933, 474503446, 476075064, 477647777, 479221575, 480796447, 482372385, 483949377, 485527415, 487106489, 488686591, 490267712, 491849844, 493432979, 495017109, 496602228, 498188327, 499775401, 501363442, 502952446, 504542405, 506133315, 507725171, 509317969, 510911703, 512000000];
    // decimal precision of price is 4 digits, so just divide it by 10000
    uint32[] public price = [32000000, 31981567, 31962267, 31942097, 31921053, 31899133, 31876334, 31852655, 31828092, 31802646, 31776313, 31749092, 31720983, 31691985, 31662097, 31631318, 31599648, 31567087, 31533635, 31499293, 31464061, 31427939, 31390929, 31353031, 31314247, 31274578, 31234026, 31192592, 31150279, 31107088, 31063021, 31018081, 30972271, 30925593, 30878050, 30829645, 30780381, 30730262, 30679290, 30627469, 30574804, 30521297, 30466953, 30411775, 30355768, 30298937, 30241285, 30182817, 30123537, 30063452, 30002564, 29940880, 29878404, 29815142, 29751098, 29686279, 29620689, 29554335, 29487221, 29419353, 29350738, 29281381, 29211289, 29140466, 29068921, 28996657, 28923683, 28850003, 28775626, 28700556, 28624802, 28548368, 28471263, 28393493, 28315064, 28235983, 28156258, 28075895, 27994902, 27913285, 27831052, 27748209, 27664764, 27580724, 27496097, 27410890, 27325109, 27238764, 27151860, 27064406, 26976408, 26887876, 26798815, 26709234, 26619140, 26528541, 26437444, 26345858, 26253790, 26161247, 26068238, 25974770, 25880851, 25786488, 25691690, 25596465, 25500819, 25404761, 25308299, 25211441, 25114194, 25016566, 24918565, 24820199, 24721475, 24622403, 24522988, 24423240, 24323166, 24222774, 24122071, 24021066, 23919767, 23818180, 23716314, 23614176, 23511775, 23409118, 23306213, 23203067, 23099689, 22996085, 22892264, 22788232, 22683999, 22579570, 22474955, 22370160, 22265192, 22160061, 22054772, 21949333, 21843752, 21738036, 21632193, 21526229, 21420152, 21313970, 21207689, 21101317, 20994861, 20888328, 20781726, 20675060, 20568339, 20461569, 20354758, 20247911, 20141037, 20034141, 19927232, 19820315, 19713397, 19606485, 19499585, 19392705, 19285851, 19179028, 19072245, 18965507, 18858821, 18752192, 18645628, 18539134, 18432718, 18326384, 18220139, 18113990, 18007941, 17902000, 17796172, 17690463, 17584880, 17479426, 17374110, 17268935, 17163908, 17059035, 16954321, 16849771, 16745391, 16641187, 16537163, 16433325, 16329679, 16226229, 16122981, 16019939, 15917110, 15814497, 15712106, 15609941, 15508008, 15406311, 15304855, 15203645, 15102685, 15001980, 14901534, 14801353, 14701439, 14601798, 14502434, 14403352, 14304555, 14206047, 14107833, 14009917, 13912302, 13814993, 13717994, 13621308, 13524939, 13428891, 13333167, 13237771, 13142707, 13047979, 12953588, 12859540, 12765838, 12672483, 12579481, 12486834, 12394545, 12302617, 12211053, 12119857, 12029031, 11938578, 11848500, 11758802, 11669484, 11580551, 11492004, 11403846, 11316079, 11228707, 11141731, 11055153, 10968977, 10883204, 10797836, 10712876, 10628325, 10544186, 10460461, 10377151, 10294259, 10211786, 10129734, 10048104, 9966899, 9886120, 9805769, 9725847, 9646355, 9567296, 9488669, 9410478, 9332723, 9255404, 9178525, 9102084, 9026085, 8950527, 8875412, 8800741, 8726514, 8652732, 8579397, 8506509, 8434069, 8362077, 8290534, 8219440, 8148797, 8078604, 8008863, 7939573, 7870735, 7802350, 7734416, 7666936, 7599908, 7533334, 7467213, 7401545, 7336331, 7271570, 7207262, 7143407, 7080006, 7017057, 6954562, 6892518, 6830927, 6769788, 6709100, 6648864, 6589078, 6529742, 6470856, 6412420, 6354432, 6296892, 6239799, 6183153, 6126953, 6071199, 6015888, 5961022, 5906598, 5852616, 5799075, 5745974, 5693312, 5641089, 5589302, 5537951, 5487035, 5436553, 5386503, 5336885, 5287697, 5238937, 5190606, 5142700, 5095220, 5048163, 5001529, 4955315, 4909521, 4864144, 4819184, 4774639, 4730508, 4686788, 4643478, 4600577, 4558083, 4515994, 4474309, 4433026, 4392143, 4351658, 4311570, 4271877, 4232577, 4193669, 4155149, 4117017, 4079271, 4041909, 4004928, 3968327, 3932104, 3896257, 3860784, 3825683, 3790951, 3756588, 3722590, 3688955, 3655683, 3622769, 3590213, 3558013, 3526165, 3494668, 3463520, 3432718, 3402261, 3372145, 3342370, 3312932, 3283829, 3255060, 3226621, 3198511, 3170727, 3143267, 3116129, 3089310, 3062808, 3036620, 3010745, 2985180, 2959923, 2934970, 2910321, 2885972, 2861921, 2838165, 2814703, 2791532, 2768649, 2746053, 2723740, 2701708, 2679955, 2658479, 2637276, 2616345, 2595683, 2575288, 2555157, 2535288, 2515678, 2496325, 2477226, 2458379, 2439782, 2421432, 2403327, 2385464, 2367841, 2350455, 2333304, 2316385, 2299697, 2283236, 2267000, 2250987, 2235195, 2219620, 2204261, 2189115, 2174179, 2159452, 2144931, 2130613, 2116496, 2102578, 2088856, 2075328, 2061991, 2048844, 2035884, 2023108, 2010514, 1998101, 1985864, 1973803, 1961915, 1950197, 1938647, 1927264, 1916044, 1904985, 1894086, 1883344, 1872756, 1862320, 1852035, 1841898, 1831907, 1822059, 1812353, 1802785, 1793355, 1784060, 1774898, 1765866, 1756963, 1748186, 1739534, 1731004, 1722594, 1714302, 1706127, 1698065, 1690115, 1682276, 1674545, 1666919, 1659398, 1651979, 1644660, 1637439, 1630315, 1623286, 1616348, 1609502, 1602745, 1596074, 1589489, 1582987, 1576567, 1570227, 1563965, 1557779, 1551668, 1545629, 1539662, 1533765, 1527935, 1522171, 1516472, 1510836, 1505261, 1499746, 1494289, 1488888, 1483543, 1478251, 1473011, 1467822, 1462681, 1457589, 1452542, 1447540, 1442581, 1437665, 1432789, 1427952, 1423152, 1418390, 1413662, 1408969, 1404308, 1399679, 1395079, 1390509, 1385966, 1381450, 1376960, 1372493, 1368050, 1363628, 1359228, 1354847, 1350485, 1346141, 1341814, 1337502, 1333204, 1328921, 1324650, 1320391, 1316143, 1311904, 1307675, 1303454, 1299240, 1295033, 1290832, 1286635, 1282443, 1278253, 1274067, 1269882, 1265698, 1261515, 1257332, 1253147, 1248961, 1244773, 1240582, 1236387, 1232189, 1227986, 1223777, 1219564, 1215344, 1211117, 1206883, 1202642, 1198392, 1194134, 1189867, 1185591, 1181305, 1177009, 1172702, 1168385, 1164056, 1159716, 1155365, 1151001, 1146625, 1142237, 1137836, 1133422, 1128995, 1124554, 1120100, 1115633, 1111151, 1106656, 1102146, 1097623, 1093085, 1088532, 1083965, 1079384, 1074789, 1070178, 1065554, 1060914, 1056261, 1051593, 1046910, 1042213, 1037502, 1032776, 1028036, 1023283, 1018515, 1013734, 1008939, 1004130, 999308, 994473, 989625, 984764, 979891, 975005, 970107, 965197, 960275, 955342, 950398, 945443, 940477, 935501, 930515, 925520, 920515, 915501, 910478, 905447, 900408, 895361, 890307, 885246, 880179, 875105, 870026, 864941, 859851, 854757, 849659, 844557, 839452, 834344, 829234, 824122, 819009, 813894, 808779, 803664, 798550, 793437, 788324, 783214, 778107, 773002, 767900, 762803, 757710, 752622, 747539, 742462, 737392, 732329, 727273, 722225, 717186, 712156, 707135, 702125, 697125, 692137, 687160, 682196, 677244, 672306, 667381, 662471, 657576, 652696, 647832, 642984, 638154, 633341, 628547, 623770, 619013, 614276, 609558, 604861, 600186, 595532, 590900, 586291, 581705, 577142, 572604, 568090, 563601, 559138, 554701, 550290, 545906, 541550, 537221, 532920, 528649, 524406, 520193, 516010, 511858, 507736, 503645, 499586, 495559, 491564, 487602, 483674, 479778, 475916, 472089, 468296, 464538, 460815, 457127, 453475, 449859, 446279, 442736, 439230, 435761, 432329, 428935, 425579, 422260, 418980, 415738, 412535, 409371, 406245, 403159, 400112, 397104, 394136, 391208, 388319, 385470, 382661, 379892, 377163, 374474, 371825, 369216, 366647, 364119, 361631, 359182, 356774, 354406, 352078, 349790, 347541, 345332, 343163, 341033, 338943, 336892, 334880, 332906, 330972, 329076, 327218, 325398, 323616, 321871, 320164, 318494, 316860, 315263, 313703, 312178, 310688, 309233, 307814, 306428, 305077, 303759, 302474, 301222, 300003, 298815, 297658, 296533, 295438, 294373, 293337, 292330, 291351, 290400, 289477, 288580, 287709, 286863, 286042, 285246, 284473, 283723, 282995, 282289, 281604, 280939, 280294, 279667, 279059, 278468, 277893, 277335, 276791, 276262, 275746, 275244, 274753, 274273, 273804, 273344, 272893, 272449, 272013, 271582, 271157, 270737, 270319, 269905, 269492, 269080, 268667, 268254, 267839, 267421, 266999, 266572, 266139, 265700, 265254, 264798, 264334, 263858, 263372, 262873, 262360, 261834, 261292, 260734, 260158, 259564, 258951, 258318, 257664, 256988, 256289, 255565, 254817, 254043, 253241, 252412, 250000];
    uint32 public constant DECIMALS = 18;

    SystemContext public systemContext;
    uint256 public lastTableIndex;


    constructor (SystemContext systemContext_) {
        systemContext = systemContext_;
        lastTableIndex = 0;
    }

    /**
    * @dev Searches for index in table where conditions are met (total supply in range)
    */
    function _getIndex(uint256 totalSupply) internal view returns (uint256) {
        for(uint256 i = lastTableIndex; i < cumulativeSupply.length - 1; i++) {
            if (totalSupply < _getSupply(i + 1)) {
                return i;
            }
        }

        return cumulativeSupply.length - 1;
    }

    /**
    * @dev Returns supply standardized to 10 ** DECIMALS
    */
    function _getSupply(uint256 index) internal view returns (uint256) {
        return cumulativeSupply[index] * 10 ** DECIMALS;
    }

    /**
    * @dev Returns price for a particular supply
    */
    function getPriceForSupply(uint256 supply) public view returns(uint256) {
        if (supply < _getSupply(0)) {
            return price[0] * 2;
        }
        uint256 index = _getIndex(supply);
        if (index >= price.length - 1) {
            return price[price.length - 1];
        }

        uint256 maxSupplyDiff = _getSupply(index + 1) - _getSupply(index);
        uint256 currentDiff = supply - _getSupply(index);

        uint256 priceShare = price[index] - price[index + 1];
        return price[index] - (priceShare * currentDiff / maxSupplyDiff);
    }

    /**
    * @dev Recalculates reward based on current supply
    */
    function reduceReward(uint256 supply, uint256 baseReward) external view returns(uint256) {
        return baseReward * getPriceForSupply(supply) / price[0];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAsset {
    function getAddress() external view returns(address);
    function transfer(address recipient, uint256 amount) external;
    function balance() external view returns (uint256);
    function execute(address target, bytes calldata call, uint256) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./NativeAsset.sol";
import "./Erc20Asset.sol";
import "./interfaces/IExchangeAdapter.sol";
import "./interfaces/Uniswap.sol";

contract UniswapExchangeAdapter is IExchangeAdapter {

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;

    constructor (IUniswapV2Factory factory_, IUniswapV2Router02 router_) {
        factory = factory_;
        router = router_;
    }

    function _getPair(address from, address to) internal view returns (IUniswapV2Pair) {
        address pair = factory.getPair(from, to);
        require(pair != address(0), "ExchangeAdapter: pair is missing");
        return IUniswapV2Pair(pair);
    }

    function exchangeTokens(Erc20Asset from, uint256 fromAmount, Erc20Asset to, uint256 toAmount) public override view returns (bytes memory) {
        address fromAddr = address(from.assetAddress());
        address toAddr = address(to.assetAddress());
        // solhint-disable-next-line no-unused-vars
        IUniswapV2Pair pair = _getPair(fromAddr, toAddr);

        bytes4 sig = router.swapTokensForExactTokens.selector;
        address[] memory path = new address[](2);
        path[0] = fromAddr;
        path[1] = toAddr;
        // solhint-disable-next-line not-rely-on-time
        return abi.encodeWithSelector(sig, toAmount, fromAmount, path, address(to), block.timestamp);
    }

    function exchangeTokenForNative(Erc20Asset from, uint256 fromAmount, NativeAsset to, uint256 toAmount) public override view returns (bytes memory) {
        address fromAddr = address(from.assetAddress());
        // solhint-disable-next-line no-unused-vars
        IUniswapV2Pair pair = _getPair(address(from.assetAddress()), address(to.nativeWrapped()));

        bytes4 sig = router.swapTokensForExactETH.selector;
        address[] memory path = new address[](2);
        path[0] = fromAddr;
        path[1] = to.nativeWrapped();
        // solhint-disable-next-line not-rely-on-time
        return abi.encodeWithSelector(sig, toAmount, fromAmount, path, address(to), block.timestamp);
    }

    // solhint-disable-next-line no-unused-vars
    function exchangeNativeForToken(NativeAsset from, uint256 fromAmount, Erc20Asset to, uint256 toAmount) public override view returns (bytes memory) {
        address toAddr = address(to.assetAddress());
        // solhint-disable-next-line no-unused-vars
        IUniswapV2Pair pair = _getPair(address(from.nativeWrapped()), address(to.assetAddress()));

        bytes4 sig = router.swapETHForExactTokens.selector;
        address[] memory path = new address[](2);
        path[0] = from.nativeWrapped();
        path[1] = toAddr;
        // solhint-disable-next-line not-rely-on-time
        return abi.encodeWithSelector(sig, toAmount, path, address(to), block.timestamp);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFTUpgradeable is IERC20Upgradeable {

    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _tokenId - token Id to transfer
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes calldata _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);


    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`)
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function send(uint16 _dstChainId, bytes calldata _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    /**
     * @dev returns the type of OFT
     */
    function getType() external returns (uint);

    /**
     * @dev returns the total amount of tokens across all chains
     */
    function getGlobalSupply() external returns (uint);

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(address indexed _sender, uint16 indexed _dstChainId, bytes indexed _toAddress, uint _amount, uint64 _nonce);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 _srcChainId, address _toAddress, uint _amount, uint64 _nonce);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./LzAppUpgradeable.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzAppUpgradeable is LzAppUpgradeable {

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __NonblockingLzApp_init() internal onlyInitializing {
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __NonblockingLzApp_init_unchained() internal onlyInitializing {
    }

    mapping(uint16 => mapping(bytes => mapping(uint => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        // try-catch all errors/exceptions
        // solhint-disable-next-line no-empty-blocks
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "LzReceiver: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    /**
    * @dev Function allowing to retry failed message. If message failed because of low gas limit, it can be easily retried.
     */
    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "LzReceiver: no stored message");
        require(keccak256(_payload) == payloadHash, "LzReceiver: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzAppUpgradeable is Initializable, OwnableUpgradeable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint internal lzEndpoint;

    mapping(uint16 => bytes) internal trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    // solhint-disable-next-line func-name-mixedcase
    function __LzApp_init(ILayerZeroEndpoint endpoint_) internal onlyInitializing {
        __LzApp_init_unchained(endpoint_);
        __Ownable_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __LzApp_init_unchained(ILayerZeroEndpoint endpoint_) internal onlyInitializing {
        lzEndpoint = endpoint_;
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external override {
        // lzReceive must be called by the endpoint for security
        // solhint-disable-next-line reason-string
        require(_msgSender() == address(lzEndpoint));
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        // solhint-disable-next-line reason-string
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), "LzReceiver: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParam) internal {
        // solhint-disable-next-line reason-string
        require(trustedRemoteLookup[_dstChainId].length != 0, "LzSend: destination chain is not a trusted source.");
        // solhint-disable-next-line check-send-result
        lzEndpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _adapterParam);
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(lzEndpoint.getSendVersion(address(this)), _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function setTrustedRemoteAsThis(uint16 _srcChainId) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = toBytes(address(this));
        emit SetTrustedRemote(_srcChainId, toBytes(address(this)));
    }

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    // interacting with the LayerZero Endpoint and remote contracts

    function getTrustedRemote(uint16 _chainId) external view returns (bytes memory) {
        return trustedRemoteLookup[_chainId];
    }

    function getLzEndpoint() external view returns (address) {
        return address(lzEndpoint);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../NativeAsset.sol";
import "../Erc20Asset.sol";

interface IExchangeAdapter {
    function exchangeTokens(Erc20Asset from, uint256 fromAmount, Erc20Asset to, uint256 toAmount) external returns (bytes memory);

    function exchangeTokenForNative(Erc20Asset from, uint256 fromAmount, NativeAsset to, uint256 toAmount) external returns (bytes memory);

    function exchangeNativeForToken(NativeAsset from, uint256 fromAmount, Erc20Asset to, uint256 toAmount) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // solhint-disable-next-line func-name-mixedcase
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}