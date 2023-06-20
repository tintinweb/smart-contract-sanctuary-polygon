// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/SignerOwnable.sol";
import "../common/ContractRegistry.sol";
import "../common/Globals.sol";
import "./Staking.sol";
import "./ContractKeys.sol";

contract RewardDistributionPool is Initializable, ContractKeys, SignerOwnable {
    struct RewardPosition {
        uint256 balance;
        uint256 lastRewardPoints;
    }

    ContractRegistry public contractRegistry;

    uint256 public collectedRewards;
    uint256 public totalRewardPoints;
    uint256 public providedStake;

    mapping(address => RewardPosition) public rewardPositions;

    event CollectRewards(address validator, uint256 amount);

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function initialize(address _contractRegistry, address _signerGetterAddress) external initializer {
        _setSignerGetter(_signerGetterAddress);
        contractRegistry = ContractRegistry(_contractRegistry);
    }

    function distributeRewards() public {
        uint256 amount = address(this).balance;

        require(amount > 0, "RewardDistributionPool: amount must be greater than 0");

        _updateLastRewardPoints();

        providedStake = _stakingContract().getTotalStake();
        totalRewardPoints += (amount * BASE_DIVISOR) / providedStake;
        collectedRewards += amount;
    }

    function collectRewards() public {
        claimRewards();
        _sendRewards(msg.sender);
    }

    function reinvestRewards() public {
        claimRewards();

        uint256 reward = rewardPositions[msg.sender].balance;

        _sendRewards(address(_stakingContract()));
        _stakingContract().addRewardsToStake(msg.sender, reward);
    }

    function claimRewards() public {
        uint256 rewardsOwingAmount = rewardsOwing();
        if (rewardsOwingAmount > 0) {
            collectedRewards -= rewardsOwingAmount;
            rewardPositions[msg.sender].balance += rewardsOwingAmount;
            rewardPositions[msg.sender].lastRewardPoints = totalRewardPoints;
        }
    }

    function rewardsOwing() public view returns (uint256) {
        uint256 newRewardPoints = totalRewardPoints - rewardPositions[msg.sender].lastRewardPoints;

        return (_stakingContract().getStake(msg.sender) * newRewardPoints) / BASE_DIVISOR;
    }

    function _updateLastRewardPoints() private {
        address[] memory validators = _stakingContract().getValidators();
        for (uint256 i = 0; i < validators.length; i++) {
            rewardPositions[validators[i]].lastRewardPoints = totalRewardPoints;
        }
    }

    function _sendRewards(address _receiver) private {
        uint256 reward = rewardPositions[msg.sender].balance;

        require(reward > 0, "RewardDistributionPool: reward must be greater than 0");

        rewardPositions[msg.sender].balance -= reward;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _receiver.call{value: reward, gas: 21000}("");
        require(success, "RewardDistributionPool: transfer failed");

        emit CollectRewards(msg.sender, reward);
    }

    function _stakingContract() private view returns (Staking) {
        return Staking(payable(contractRegistry.getContract(STAKING_KEY)));
    }

    function _createPath(address _from, address _to) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        return path;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISignerAddress.sol";

abstract contract SignerOwnable {
    ISignerAddress public signerGetter;

    modifier onlySigner() {
        require(signerGetter.getSignerAddress() == msg.sender, "SignerOwnable: only signer");
        _;
    }

    function _setSignerGetter(address _signerGetterAddress) internal virtual {
        signerGetter = ISignerAddress(_signerGetterAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/SignerOwnable.sol";

// ContractRegistry is the contract that stores other contracts of the system.
// It just simply stores a mapping between the contract name and its address.
contract ContractRegistry is SignerOwnable, Initializable {
    mapping(string => address) public contracts;

    event ContractAddressUpdated(string key, address value);

    function initialize(address _signerGetterAddress) external initializer {
        _setSignerGetter(_signerGetterAddress);
    }

    function setContract(string memory _key, address _value) public onlySigner {
        contracts[_key] = _value;
        emit ContractAddressUpdated(_key, _value);
    }

    function getContract(string memory _key) public view returns (address) {
        require(contracts[_key] != address(0), "ContractRegistry: no address was found for the specified key");

        return (contracts[_key]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant BASE_DIVISOR = 1 ether;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/SignerOwnable.sol";
import "../common/AddressStorage.sol";
import "../common/ContractRegistry.sol";
import "./DKG.sol";
import "./ContractKeys.sol";
import "./SlashingVoting.sol";
import "./RewardDistributionPool.sol";

// Staking is the staking contract mechanism.
contract Staking is ContractKeys, SignerOwnable, Initializable {
    enum ValidatorStatus {
        INACTIVE,
        ACTIVE,
        SLASHED
    }

    struct ValidatorInfo {
        address validator;
        uint256 stake;
        ValidatorStatus status;
    }

    struct WithdrawalAnnouncement {
        uint256 amount;
        uint256 time;
    }

    uint256 public minimalStake;
    uint256 public withdrawalPeriod;
    uint256 public totalStake;
    mapping(address => ValidatorInfo) public stakes;
    mapping(address => WithdrawalAnnouncement) public withdrawalAnnouncements;
    ContractRegistry public contractRegistry;
    AddressStorage public addressStorage;

    event MinimalStakeUpdated(uint256 minimalStake);
    event WithdrawalPeriodUpdated(uint256 withdrawalPeriod);
    event ContractRegistryUpdated(address contractRegistry);

    modifier onlyNotSlashed() {
        require(stakes[msg.sender].status != ValidatorStatus.SLASHED, "Staking: validator is slashed");
        _;
    }

    modifier onlySlashingVoting() {
        require(msg.sender == address(_slashingVotingContract()), "Staking: not a slashing voting");
        _;
    }

    modifier onlyRewardDistributionPool() {
        require(
            msg.sender == address(_rewardDistributionPoolContract()),
            "Staking: only RewardDistributionPool contract"
        );
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function initialize(
        address _signerGetterAddress,
        uint256 _minimalStake,
        uint256 _withdrawalPeriod,
        address _contractRegistry,
        address _validatorStorage
    ) external initializer {
        _setSignerGetter(_signerGetterAddress);
        setMinimalStake(_minimalStake);
        setWithdrawalPeriod(_withdrawalPeriod);
        contractRegistry = ContractRegistry(_contractRegistry);
        addressStorage = AddressStorage(_validatorStorage);
    }

    function addRewardsToStake(address _validator, uint256 _amount) external onlyRewardDistributionPool {
        stakes[_validator].stake += _amount;
        totalStake += _amount;
    }

    function isValidatorActive(address _validator) external view returns (bool) {
        return (stakes[_validator].status == ValidatorStatus.ACTIVE);
    }

    function isValidatorSlashed(address _validator) external view returns (bool) {
        return stakes[_validator].status == ValidatorStatus.SLASHED;
    }

    function setMinimalStake(uint256 _minimalStake) public onlySigner {
        minimalStake = _minimalStake;
        emit MinimalStakeUpdated(_minimalStake);
    }

    function setWithdrawalPeriod(uint256 _withdrawalPeriod) public onlySigner {
        withdrawalPeriod = _withdrawalPeriod;
        emit WithdrawalPeriodUpdated(_withdrawalPeriod);
    }

    function slash(address _validator) public onlySlashingVoting {
        stakes[_validator].status = ValidatorStatus.SLASHED;
        _removeValidator(_validator);
    }

    function announceWithdrawal(uint256 _amount) public onlyNotSlashed {
        require(_amount <= stakes[msg.sender].stake, "Staking: amount must be <= to stake");
        withdrawalAnnouncements[msg.sender].amount = _amount;
        // solhint-disable-next-line not-rely-on-time
        withdrawalAnnouncements[msg.sender].time = block.timestamp;

        if (stakes[msg.sender].stake - _amount < minimalStake && addressStorage.contains(msg.sender)) {
            stakes[msg.sender].status = ValidatorStatus.INACTIVE;
            _removeValidator(msg.sender);
        }
    }

    function revokeWithdrawal() public onlyNotSlashed {
        require(withdrawalAnnouncements[msg.sender].amount > 0, "Staking: not announced");

        uint256 amount = withdrawalAnnouncements[msg.sender].amount;

        withdrawalAnnouncements[msg.sender].amount = 0;
        withdrawalAnnouncements[msg.sender].time = 0;

        if (
            stakes[msg.sender].status == ValidatorStatus.INACTIVE && amount + stakes[msg.sender].stake >= minimalStake
        ) {
            stakes[msg.sender].validator = msg.sender;
            stakes[msg.sender].status = ValidatorStatus.ACTIVE;
            _addValidator(msg.sender);
        }
    }

    function withdraw() public onlyNotSlashed {
        require(withdrawalAnnouncements[msg.sender].amount > 0, "Staking: amount must be greater than zero");
        require(
            // solhint-disable-next-line not-rely-on-time
            withdrawalAnnouncements[msg.sender].time + withdrawalPeriod <= block.timestamp,
            "Staking: withdrawal period not passed"
        );

        uint256 withdrawalAmount = withdrawalAnnouncements[msg.sender].amount;

        require(withdrawalAmount <= stakes[msg.sender].stake, "Staking: amount must be <= to validator stake");

        stakes[msg.sender].stake -= withdrawalAmount;
        totalStake -= withdrawalAmount;

        withdrawalAnnouncements[msg.sender].amount = 0;
        withdrawalAnnouncements[msg.sender].time = 0;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: withdrawalAmount, gas: 21000}("");
        require(success, "Staking: transfer failed");
    }

    function stake() public payable onlyNotSlashed {
        require(msg.value > 0, "Staking: amount must be greater than zero");

        if (
            stakes[msg.sender].status == ValidatorStatus.INACTIVE &&
            msg.value + stakes[msg.sender].stake >= minimalStake
        ) {
            stakes[msg.sender].validator = msg.sender;
            stakes[msg.sender].status = ValidatorStatus.ACTIVE;
            _addValidator(msg.sender);
        }

        stakes[msg.sender].stake += msg.value;
        totalStake += msg.value;
    }

    function getValidators() public view returns (address[] memory) {
        return addressStorage.getAddresses();
    }

    function getValidatorsCount() public view returns (uint256) {
        return addressStorage.size();
    }

    function listValidators(uint256 _offset, uint256 _limit) public view returns (ValidatorInfo[] memory) {
        address[] memory validators = getValidators();
        ValidatorInfo[] memory result = new ValidatorInfo[](_limit);
        for (uint256 i = _offset; i < _offset + _limit; i++) {
            result[i - _offset] = stakes[validators[i]];
        }

        return result;
    }

    function getStake(address _validator) public view returns (uint256) {
        return stakes[_validator].stake;
    }

    function getTotalStake() public view returns (uint256) {
        return totalStake;
    }

    function _addValidator(address _validator) private {
        DKG dkg = _dkgContract();

        addressStorage.mustAdd(_validator);
        dkg.updateGeneration();
    }

    function _removeValidator(address _validator) private {
        DKG dkg = _dkgContract();

        addressStorage.mustRemove(_validator);
        dkg.updateGeneration();
    }

    function _dkgContract() private view returns (DKG) {
        return DKG(contractRegistry.getContract(DKG_KEY));
    }

    function _slashingVotingContract() private view returns (SlashingVoting) {
        return SlashingVoting(contractRegistry.getContract(SLASHING_VOTING_KEY));
    }

    function _rewardDistributionPoolContract() private view returns (RewardDistributionPool) {
        return RewardDistributionPool(payable(contractRegistry.getContract(REWARD_DISTRIBUTION_POOL_KEY)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ContractKeys keeps all contract keys/names that can be used to store or get the contract address
// from the contract registry.
abstract contract ContractKeys {
    string public constant STAKING_KEY = "staking";
    string public constant DKG_KEY = "dkg";
    string public constant SUPPORTED_TOKENS_KEY = "supported-tokens";
    string public constant SLASHING_VOTING_KEY = "slashing-voting";
    string public constant REWARD_DISTRIBUTION_POOL_KEY = "reward-distribution-pool";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.18;

// ISignerAddress represents the behavior of the contract that holds the network collective address
// generated during DKG process.
interface ISignerAddress {
    // getSignerAddress returns the current signer address
    function getSignerAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// AddressStorage is the simple addresses storage contract.
// Currently, this is used by staking contract in order to store validators.
contract AddressStorage is Ownable, Initializable {
    mapping(address => uint256) internal indexMap;
    address[] internal addrList;

    function initialize(address[] memory _addrList) external virtual initializer {
        for (uint256 i = 0; i < _addrList.length; i++) {
            addrList.push(_addrList[i]);
            indexMap[_addrList[i]] = addrList.length;
        }
    }

    function mustAdd(address _addr) external {
        require(_add(_addr), "AddressStorage: failed to add address");
    }

    function mustRemove(address _addr) external {
        require(_remove(_addr), "AddressStorage: failed to remove address");
    }

    function clear() external onlyOwner returns (bool) {
        for (uint256 i = 0; i < addrList.length; i++) {
            delete indexMap[addrList[i]];
        }

        delete addrList;

        return true;
    }

    function size() external view returns (uint256) {
        return addrList.length;
    }

    function getAddresses() external view returns (address[] memory) {
        return addrList;
    }

    function contains(address _addr) public view returns (bool) {
        return indexMap[_addr] > 0;
    }

    function _add(address _addr) private onlyOwner returns (bool) {
        if (contains(_addr)) {
            return false;
        }

        addrList.push(_addr);
        indexMap[_addr] = addrList.length;

        _checkEntry(_addr);

        return true;
    }

    function _remove(address _addr) private onlyOwner returns (bool) {
        if (!contains(_addr)) {
            return false;
        }

        uint256 id = indexMap[_addr];

        uint256 lastListID = addrList.length - 1;
        address lastListAddress = addrList[lastListID];
        if (lastListID != id - 1) {
            indexMap[lastListAddress] = id;
            addrList[id - 1] = lastListAddress;
        }

        addrList.pop();
        delete indexMap[_addr];

        _checkEntry(_addr);

        if (lastListAddress != _addr) {
            _checkEntry(lastListAddress);
        }

        return true;
    }

    function _checkEntry(address _addr) private view {
        uint256 id = indexMap[_addr];
        assert(id <= addrList.length);

        if (contains(_addr)) {
            assert(id > 0);
        } else {
            assert(id == 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISignerAddress.sol";
import "../common/ContractRegistry.sol";
import "./Staking.sol";
import "./ContractKeys.sol";
import "./SlashingVoting.sol";

struct GenerationInfo {
    address signer;
    address[] validators;
    uint256 deadline;
    mapping(address => bool) isValidator;
    mapping(address => address) signerVotes;
    mapping(address => uint256) signerVoteCounts;
    mapping(uint256 => RoundData) roundData;
}

struct RoundData {
    uint256 count;
    mapping(address => bytes) data;
}

// DKG represents the on-sidechain logic needed to perform distributed key generation process done by validators.
// Once the DKG process is finished, a new collective/sender address could be stored.
contract DKG is ISignerAddress, ContractKeys, Initializable {
    using ECDSA for bytes;
    using ECDSA for bytes32;

    enum GenerationStatus {
        PENDING,
        EXPIRED,
        ACTIVE
    }

    ContractRegistry public contractRegistry;

    mapping(address => uint256) public signerToGeneration;

    GenerationInfo[] public generations;
    uint256 public lastActiveGeneration;
    uint256 public deadlinePeriod;

    event RoundDataProvided(uint256 generation, uint256 round, address validator);
    event RoundDataFilled(uint256 generation, uint256 round);

    event ValidatorsUpdated(uint256 generation, address[] validators);
    event SignerVoted(uint256 generation, address validator, address collectiveSigner);
    event SignerAddressUpdated(uint256 generation, address signerAddress);

    event ThresholdSignerUpdated(address signer);

    modifier onlyDKGValidator(uint256 _generation) {
        require(
            generations.length > _generation && generations[_generation].isValidator[msg.sender],
            "DKG: not a validator"
        );
        _;
    }

    modifier roundIsFilled(uint256 _generation, uint256 _round) {
        require(
            _round == 0 ||
                generations[_generation].roundData[_round].count == generations[_generation].validators.length,
            "DKG: round was not filled"
        );
        _;
    }

    modifier roundNotProvided(uint256 _generation, uint256 _round) {
        require(
            generations[_generation].roundData[_round].data[msg.sender].length == 0,
            "DKG: round data already provided"
        );
        _;
    }

    modifier onlySigner() {
        require(msg.sender == generations[lastActiveGeneration].signer, "DKG: not a active signer");
        _;
    }

    modifier onlyPending(uint256 _generation) {
        require(getStatus(_generation) == GenerationStatus.PENDING, "DKG: not a pending generation");
        _;
    }

    function initialize(address _contractRegistry, uint256 _deadlinePeriod) external initializer {
        generations.push();
        generations[0].signer = msg.sender;
        signerToGeneration[msg.sender] = 0;
        contractRegistry = ContractRegistry(_contractRegistry);
        deadlinePeriod = _deadlinePeriod;
    }

    function updateGeneration() external {
        uint256 newGeneration = generations.length;
        GenerationInfo storage oldGenerationInfo = generations[newGeneration - 1];

        uint256 validatorsCount = 0;
        bool newValidatorsAdded = false;
        address[] memory stakingValidators = _stakingContract().getValidators();
        address[] memory newValidators = new address[](stakingValidators.length);
        for (uint256 i = 0; i < stakingValidators.length; i++) {
            address validator = stakingValidators[i];

            // Validators banned by DKG reasons do not participate
            // in key generation for some time
            if (
                _isBannedByReason(validator, SlashingReason.REASON_DKG_INACTIVITY) ||
                _isBannedByReason(validator, SlashingReason.REASON_DKG_VIOLATION)
            ) {
                continue;
            }

            if (!oldGenerationInfo.isValidator[validator]) {
                newValidatorsAdded = true;
            }

            newValidators[validatorsCount] = validator;
            validatorsCount++;
        }

        uint256 oldValidatorsCount = oldGenerationInfo.validators.length;
        if (
            // Distributed key generation algorithm requires at least 2 participants
            validatorsCount < 2 ||
            // Validator count same as previous and there is no new validators,
            // meaning both arrays the same, no need to create new DKG generation
            (validatorsCount == oldValidatorsCount && !newValidatorsAdded)
        ) {
            return;
        }

        generations.push();
        for (uint256 i = 0; i < validatorsCount; i++) {
            generations[newGeneration].validators.push(newValidators[i]);
            generations[newGeneration].isValidator[newValidators[i]] = true;
        }

        generations[newGeneration].deadline = block.number + deadlinePeriod;
        lastActiveGeneration = newGeneration;

        emit ValidatorsUpdated(newGeneration, newValidators);
        emit RoundDataFilled(newGeneration, 0);
    }

    function roundBroadcast(
        uint256 _generation,
        uint256 _round,
        bytes memory _rawData
    )
        external
        onlyDKGValidator(_generation)
        roundIsFilled(_generation, _round - 1)
        roundNotProvided(_generation, _round)
        onlyPending(_generation)
    {
        generations[_generation].roundData[_round].count++;
        generations[_generation].roundData[_round].data[msg.sender] = _rawData;
        emit RoundDataProvided(_generation, _round, msg.sender);
        if (generations[_generation].roundData[_round].count == generations[_generation].validators.length) {
            emit RoundDataFilled(_generation, _round);
        }
    }

    function voteSigner(
        uint256 _generation,
        address _signerAddress,
        bytes memory _signature
    ) external onlyDKGValidator(_generation) roundIsFilled(_generation, 3) {
        GenerationInfo storage generationInfo = generations[_generation];
        require(generationInfo.deadline >= block.number, "DKG: voting is ended");

        address recoveredSigner = bytes("verify").toEthSignedMessageHash().recover(_signature);
        require(recoveredSigner == _signerAddress, "DKG: signature is invalid");

        require(generationInfo.signerVotes[msg.sender] == address(0), "DKG: already voted");

        generationInfo.signerVotes[msg.sender] = _signerAddress;
        generationInfo.signerVoteCounts[_signerAddress]++;

        emit SignerVoted(_generation, msg.sender, _signerAddress);

        bool enoughVotes = _enoughVotes(_generation, generationInfo.signerVoteCounts[_signerAddress]);
        bool signerChanged = generationInfo.signer != _signerAddress;
        if (enoughVotes && signerChanged) {
            generationInfo.signer = _signerAddress;
            signerToGeneration[_signerAddress] = _generation;
            emit SignerAddressUpdated(_generation, _signerAddress);
        }
    }

    function isRoundFilled(uint256 _generation, uint256 _round) external view returns (bool) {
        return generations[_generation].roundData[_round].count == generations[_generation].validators.length;
    }

    function getRoundBroadcastCount(uint256 _generation, uint256 _round) external view returns (uint256) {
        return generations[_generation].roundData[_round].count;
    }

    function getRoundBroadcastData(
        uint256 _generation,
        uint256 _round,
        address _validator
    ) external view returns (bytes memory) {
        return generations[_generation].roundData[_round].data[_validator];
    }

    function getCurrentValidators() external view returns (address[] memory) {
        return generations[generations.length - 1].validators;
    }

    function getSignerAddress() external view returns (address) {
        return generations[lastActiveGeneration].signer;
    }

    function getGenerationsCount() external view returns (uint256) {
        return generations.length;
    }

    function isCurrentValidator(address _validator) external view returns (bool) {
        return this.isValidator(lastActiveGeneration, _validator);
    }

    function isValidator(uint256 _generation, address _validator) external view returns (bool) {
        if (generations.length > _generation) {
            return generations[_generation].isValidator[_validator];
        }

        return false;
    }

    function getValidatorsCount(uint256 _generation) external view returns (uint256) {
        return generations[_generation].validators.length;
    }

    function setDeadlinePeriod(uint256 _deadlinePeriod) public onlySigner {
        deadlinePeriod = _deadlinePeriod;
    }

    function getStatus(uint256 _generation) public view returns (GenerationStatus) {
        if (generations[_generation].signer != address(0)) {
            return GenerationStatus.ACTIVE;
        }

        if (generations[_generation].deadline >= block.number) {
            return GenerationStatus.PENDING;
        }

        return GenerationStatus.EXPIRED;
    }

    function getValidators(uint256 _generation) public view returns (address[] memory) {
        return generations[_generation].validators;
    }

    function _enoughVotes(uint256 _generation, uint256 votes) private view returns (bool) {
        return votes > (generations[_generation].validators.length / 2);
    }

    function _stakingContract() private view returns (Staking) {
        return Staking(payable(contractRegistry.getContract(STAKING_KEY)));
    }

    function _slashingVotingContract() private view returns (SlashingVoting) {
        return SlashingVoting(contractRegistry.getContract(SLASHING_VOTING_KEY));
    }

    function _isBannedByReason(address _validator, SlashingReason _reason) private view returns (bool) {
        return _slashingVotingContract().isBannedByReason(_validator, _reason);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/SignerOwnable.sol";
import "../common/ContractRegistry.sol";
import "./ContractKeys.sol";
import "./ValidatorOwnable.sol";
import "./Staking.sol";
import "./DKG.sol";

enum SlashingReason {
    REASON_NO_RECENT_BLOCKS,
    REASON_DKG_INACTIVITY,
    REASON_DKG_VIOLATION,
    REASON_SIGNING_INACTIVITY,
    REASON_SIGNING_VIOLATION
}

enum SlashingReasonGroup {
    NONE,
    REASON_GROUP_BLOCKS,
    REASON_GROUP_DKG,
    REASON_GROUP_SIGNING
}

// SlashingVoting represents the validator slashing mechanism.
// It allows validators to vote for slashing of a specific validator.
contract SlashingVoting is ContractKeys, ValidatorOwnable, SignerOwnable, Initializable {
    struct SlashingProposal {
        address validator;
        string reason;
        mapping(address => bool) slashingProposalVotes;
        uint256 slashingProposalVoteCounts;
    }

    SlashingProposal[] public proposals;

    ContractRegistry public contractRegistry;

    uint256 public epochPeriod;
    uint256 public slashingThresold;
    uint256 public slashingEpochs;

    // Votes
    mapping(bytes32 => mapping(address => bool)) public votes;
    mapping(bytes32 => uint256) public voteCounts;

    // Bans
    mapping(bytes32 => bool) public bans;
    mapping(uint256 => mapping(address => mapping(SlashingReason => bool))) public bansByReason;
    mapping(uint256 => mapping(address => uint256)) public bansByEpoch;
    mapping(uint256 => mapping(SlashingReason => address[])) public bannedValidators;

    event VotedWithReason(address voter, address validator, SlashingReason reason);
    event BannedWithReason(address validator, SlashingReason reason);
    event SlashedWithReason(address validator);

    event ProposalCreated(uint256 proposalId, address validator);
    event ProposalVoted(uint256 proposalId, address validator, address voter);
    event ProposalExecuted(uint256 proposalId, address validator);

    function initialize(
        address _signerGetterAddress,
        address _validatorGetterAddress,
        uint256 _epochPeriod,
        uint256 _slashingThresold,
        uint256 _lashingEpochs,
        address _contractRegistry
    ) external initializer {
        _setSignerGetter(_signerGetterAddress);
        _setValidatorGetter(_validatorGetterAddress);
        setEpochPeriod(_epochPeriod);
        setSlashingThresold(_slashingThresold);
        setSlashingEpochs(_lashingEpochs);
        contractRegistry = ContractRegistry(_contractRegistry);
    }

    function voteWithReason(
        address _validator,
        SlashingReason _reason,
        bytes calldata _nonce
    ) external onlyValidator {
        Staking staking = _stakingContract();
        DKG dkg = _dkgContract();

        bytes32 voteHash = votingHashWithReason(_validator, _reason, _nonce);

        require(staking.isValidatorActive(_validator) == true, "SlashingVoting: target is not active validator");
        require(bans[voteHash] == false, "SlashingVoting: validator is already banned");
        require(votes[voteHash][msg.sender] == false, "SlashingVoting: voter is already voted against given validator");

        votes[voteHash][msg.sender] = true;
        voteCounts[voteHash]++;
        emit VotedWithReason(msg.sender, _validator, _reason);

        uint256 epoch = currentEpoch();
        address[] memory validators = staking.getValidators();
        if (voteCounts[voteHash] >= (validators.length / 2 + 1)) {
            bans[voteHash] = true;
            bansByReason[epoch][_validator][_reason] = true;
            bansByEpoch[epoch][_validator]++;
            bannedValidators[epoch][_reason].push(_validator);
            emit BannedWithReason(_validator, _reason);

            if (_reason == SlashingReason.REASON_DKG_INACTIVITY || _reason == SlashingReason.REASON_DKG_VIOLATION) {
                dkg.updateGeneration();
            }
        }

        if (shouldShash(epoch, _validator)) {
            _stakingContract().slash(_validator);
            emit SlashedWithReason(_validator);
        }
    }

    function createProposal(address _validator, string memory _reason) external onlyValidator {
        SlashingProposal storage newProposal = proposals.push();

        newProposal.validator = _validator;
        newProposal.reason = _reason;

        uint256 proposalId = proposals.length - 1;
        emit ProposalCreated(proposalId, _validator);

        voteProposal(proposalId);
    }

    function voteProposal(uint256 _proposalId) public onlyValidator {
        Staking staking = _stakingContract();

        require(_proposalId < proposals.length, "SlashingVoting: proposal doesn't exist!");

        SlashingProposal storage proposal = proposals[_proposalId];

        require(
            staking.isValidatorActive(proposal.validator) == true,
            "SlashingVoting: target is not active validator"
        );
        require(
            proposals[_proposalId].slashingProposalVotes[msg.sender] == false,
            "SlashingVoting: you already voted in this proposal"
        );

        proposals[_proposalId].slashingProposalVotes[msg.sender] = true;
        proposals[_proposalId].slashingProposalVoteCounts++;

        address[] memory validators = staking.getValidators();
        if (proposals[_proposalId].slashingProposalVoteCounts >= (validators.length / 2 + 1)) {
            _stakingContract().slash(proposal.validator);
            emit ProposalExecuted(_proposalId, proposal.validator);
        }
        emit ProposalVoted(_proposalId, proposal.validator, msg.sender);
    }

    function setEpochPeriod(uint256 _epochPeriod) public onlySigner {
        epochPeriod = _epochPeriod;
    }

    function setSlashingThresold(uint256 _slashingThresold) public onlySigner {
        slashingThresold = _slashingThresold;
    }

    function setSlashingEpochs(uint256 _slashingEpochs) public onlySigner {
        slashingEpochs = _slashingEpochs;
    }

    function isBannedByReason(address _validator, SlashingReason _reason) public view returns (bool) {
        return bansByReason[currentEpoch()][_validator][_reason];
    }

    function shouldShash(uint256 _epoch, address _validator) public view returns (bool) {
        if (_epoch < slashingEpochs) {
            return false;
        }

        uint256 totalBans;
        for (uint256 i = _epoch; i > _epoch - slashingEpochs; i--) {
            uint256 bansInEpoch = bansByEpoch[i][_validator];
            if (bansInEpoch == 0) {
                return false;
            }

            totalBans += bansInEpoch;
        }

        return totalBans >= slashingThresold;
    }

    function getBansByEpoch(uint256 _epoch, address _validator) public view returns (uint256) {
        return bansByEpoch[_epoch][_validator];
    }

    function getBannedValidatorsByReason(SlashingReason _reason) public view returns (address[] memory) {
        return bannedValidators[currentEpoch()][_reason];
    }

    function currentEpoch() public view returns (uint256) {
        return epochByBlock(block.number);
    }

    function epochByBlock(uint256 _blockNumber) public view returns (uint256) {
        return _blockNumber / epochPeriod;
    }

    function votingHashWithReason(
        address _validator,
        SlashingReason _reason,
        bytes calldata _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_validator, _reason, _nonce));
    }

    function _stakingContract() private view returns (Staking) {
        return Staking(payable(contractRegistry.getContract(STAKING_KEY)));
    }

    function _dkgContract() private view returns (DKG) {
        return DKG(contractRegistry.getContract(DKG_KEY));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
pragma solidity ^0.8.0;

interface ValidatorGetter {
    function isValidatorActive(address _sender) external view returns (bool);
}

abstract contract ValidatorOwnable {
    ValidatorGetter public validatorGetter;

    modifier onlyValidator() {
        require(validatorGetter.isValidatorActive(msg.sender), "ValidatorOwnable: only validator");
        _;
    }

    function _setValidatorGetter(address _validatorGetterAddress) internal virtual {
        validatorGetter = ValidatorGetter(_validatorGetterAddress);
    }
}