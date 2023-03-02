// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./../library/Structs.sol";

contract BlameStorage {
    /// @notice mapping of dynasty => epoch => blame => validatorIds
    mapping(uint256 => mapping(uint256 => mapping(uint8 => uint32[]))) public blamesPerEpoch;
    /// @notice mapping of validatorId => dynasty => epoch => blame attestations
    mapping(uint32 => mapping(uint256 => mapping(uint256 => mapping(uint8 => bytes32)))) public blameAttestations;
    /// @notice mapping of dynasty => epoch => blames attested in dynasty
    mapping(uint256 => mapping(uint256 => bytes32)) public attestedBlames;
    /// @notice mapping of dynasty => epoch => blame => numVotes
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) public blameVotesPerAttestation;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library Structs {
    struct Validator {
        uint32 id;
        address _validatorAddress;
        uint256 stake;
        uint256 jailEndDynasty;
    }

    struct SignerAttestation {
        uint32 validatorId;
        address signerAddress;
    }

    struct Request {
        bool fulfilled;
        uint32 requestId;
        uint256 epoch;
        bytes requestData;
    }

    struct Block {
        uint256 timestamp;
        bytes message;
        bytes signature;
    }

    struct SignerTransfer {
        address newSignerAddress;
        uint256 epoch;
        bytes signature;
    }

    struct Value {
        int8 power;
        uint16 collectionId;
        bytes32 name;
        uint256 value;
    }

    struct SignerAddressDetails {
        bool isDisputed;
        bool signerTransferCompleted;
        uint32 numBlocksLimit;
        address signerAddress;
        uint256 epochAssigned;
        uint256 disputeExpiry;
        uint256[] blocksConfirmedDuringDisputePeriod;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./StateManager.sol";
import "../interface/IBridge.sol";
import "../interface/IStakeManager.sol";
import "../Storage/BlameStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../library/Random.sol";

/**
 * @notice this contract is part of the bridge ecosystem and has to be deployed on the native chain
 */
contract BlameManager is BlameStorage, StateManager, Initializable {
    IBridge public bridge;
    IStakeManager public stakeManager;

    /// @notice reverts with the error if validatorId is incorrect
    error InvalidValidator();
    ///@notice reverts with the error if non selected validator is tying to attest blame
    error ValidatorNotSelected(uint32 validatorId, uint256 dynasty);
    ///@notice reverts with the error if type of blame attested is incorrect
    error InvalidBlameType();
    ///@notice reverts with the error if no culprits are atteseted in blame
    error NoCulprits();
    ///@notice reverts with the error if non selected validators are attested in blame
    error InvalidCulprits();
    ///@notice reverts with the error if the validator has already attested particular blame in an epoch, dynasty
    error AlreadyAttested();

    constructor(uint256 _firstDynastyCreation) {
        firstDynastyCreation = _firstDynastyCreation;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @param bridgeAddress The address of the bridge contract
     * @param stakeManagerAddress The address of the stake manager contract
     */
    function initialize(address bridgeAddress, address stakeManagerAddress) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        bridge = IBridge(bridgeAddress);
        stakeManager = IStakeManager(stakeManagerAddress);
    }

    /**
     * @notice validators that are part of the active set in the current dynasty can attest blames,
     * all culprits should also be part of the same active set. Validators can attest one blameType per epoch
     * but can attest multiple blames (with a different blameType)
     * @param blameType type of blame
     * @param culprits validator IDs in ascending order
     */
    function attestBlame(uint8 blameType, uint32[] memory culprits) external {
        // validator checks
        uint32 validatorId = stakeManager.getValidatorId(msg.sender);
        if (validatorId == 0) revert InvalidValidator();

        uint256 dynasty = getDynasty();
        uint256 epoch = getEpoch();

        if (!bridge.getIsValidatorSelectedPerDynasty(validatorId, dynasty)) revert ValidatorNotSelected(validatorId, dynasty);
        if (blameType > uint8(type(BlameType).max)) revert InvalidBlameType();
        if (culprits.length == 0) revert NoCulprits();

        //slither-disable-next-line timestamp
        if (blameAttestations[validatorId][dynasty][epoch][blameType] != bytes32(0)) revert AlreadyAttested();

        for (uint8 i = 0; i < culprits.length; i++) {
            //slither-disable-next-line calls-loop
            if (!bridge.getIsValidatorSelectedPerDynasty(culprits[i], dynasty)) revert InvalidCulprits();
        }

        // culprits should be in ascending order
        bytes32 blameHash = keccak256(abi.encode(blameType, culprits));

        blameVotesPerAttestation[dynasty][epoch][blameHash] = blameVotesPerAttestation[dynasty][epoch][blameHash] + 1;
        blameAttestations[validatorId][dynasty][epoch][blameType] = blameHash;

        // registering vote on public key if passed threshold
        if (blameVotesPerAttestation[dynasty][epoch][blameHash] > bridge.getThreshold()) {
            blamesPerEpoch[dynasty][epoch][blameType] = culprits;
        }
    }

    /**
     * @notice get culprits of particular blame type in an epoch, dynasty
     * @param dynasty dynasty
     * @param epoch epoch
     * @param blameType type of blame
     * @return validatorsIds of culprits
     */
    function getBlamesPerEpoch(uint256 dynasty, uint256 epoch, uint8 blameType) external view returns (uint32[] memory) {
        return blamesPerEpoch[dynasty][epoch][blameType];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "../Storage/Parameters.sol";

contract StateManager is Parameters {
    //slither-disable-next-line immutable-states
    uint256 public firstDynastyCreation;
    //slither-disable-next-line constable-states
    uint256 public baseEpochIncrement = 0;
    //slither-disable-next-line constable-states
    uint256 public baseTimeIncrement = 0;

    /**
     * @return the value of current dynasty
     */
    function getDynasty() public view returns (uint256) {
        return ((getEpoch() - 1) / dynastyLength) + 1;
    }

    /**
     * @return the value of current epoch in the dynasty
     */
    function getEpoch() public view returns (uint256) {
        return (((block.timestamp - firstDynastyCreation) + baseTimeIncrement) / epochLength) + baseEpochIncrement + 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

interface IBridge {
    function getMode() external view returns (uint8 mode);

    function getNumParticipantsPerDynasty(uint256 dynasty) external view returns (uint32);

    function getNumChurnedOut(uint256 dynasty) external view returns (uint256);

    function getThreshold() external view returns (uint32);

    function getValidatorIteration(uint32 validatorId, uint256 dynasty) external view returns (uint256);

    function getIsValidatorSelectedPerDynasty(uint32 validatorId, uint256 dynasty) external view returns (bool);

    function getActiveSetPerDynasty(uint256 dynasty) external view returns (uint32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

interface IStakeManager {
    function giveBlockReward(uint32 selectedValidator) external;

    function slashValidators(uint32[] memory _ids) external;

    function jailValidators(uint32[] memory _ids) external;

    function updateBaseParameters(uint256 _baseEpochIncrement, uint256 _baseTimeIncrement) external;

    function getWithdrawAfterPerValidator(uint32 validatorId) external view returns (uint256);

    function getValidatorId(address validatorAddress) external view returns (uint32);

    function getStake(uint32 validatorId) external view returns (uint256);

    function getNumValidators() external view returns (uint32);

    function getValidatorJailEndDynasty(uint32 validatorId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library Random {
    // pseudo random number generator based on hash. returns 0 -> max-1
    // slither ignore reason : Internal library
    // slither-disable-next-line dead-code
    function prng(uint256 max, bytes32 randHash) internal pure returns (uint256) {
        uint256 sum = uint256(randHash);
        return (sum % max);
    }

    // pseudo random hash generator based on hashes.
    // slither ignore reason : Internal library
    // slither-disable-next-line dead-code
    function prngHash(bytes32 seed, bytes32 salt) internal pure returns (bytes32) {
        bytes32 prngHashVal = keccak256(abi.encodePacked(seed, salt));
        return (prngHashVal);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract Parameters is AccessControl {
    /**
     * @notice Enum of EpochMode, used to check current state of the network
     * @dev ValidatorSelection: validators for the current dynasty are selected
     *  SignerCreation: selected validators attest and confirm a new public signing address
     *  Signing: blocks are finalized using the new public signing address
     */
    enum EpochMode {
        ValidatorSelection,
        SignerCreation,
        Signing
    }

    /**
     * @notice Enum of BlameType, used to blame a validator for specific behavior that should be penalised.
     *  All validators and culprits should be part of the active set in the current dynasty
     * @dev UnresponsiveSigner: when validator(s) does not participate in SignerCreation,
     *  after being selected in the active set of the current dynasty thereby stalling the network
     * UnresponsiveSigning: when validator(s) create a valid public signing address,
     * but do not participate further in the block signing process therefore do not allow the network to finalize blocks (T + 1 not reached)
     * UnresponsiveNode: when validator(s) creates a valid public signing address,
     * but do not participate further in the block signing process (T + 1 reached)
     * InvalidSigning: the signature being signed by validator(s) is invalid
     */
    enum BlameType {
        UnresponsiveSigner,
        UnresponsiveSigning,
        UnresponsiveNode,
        InvalidSigning
    }

    /// @notice epoch length in seconds
    uint256 public epochLength = 1200;

    /// @notice length of a dynasty in epochs
    uint256 public dynastyLength = 100;

    /// @notice minimum stake required to be a validator
    uint256 public minStake = 1000 * (10 ** 18);

    /// @notice block reward given to validator for each finalized block
    uint256 public blockReward = 10 * (10 ** 18);

    /// @notice number of dynasties a validator will be jailed
    uint256 public numJailDynasty = 10;

    /// @notice number of epochs in which a validator should be selected
    uint8 public validatorSelectionTimelimit = 2;

    /// @notice number of epochs stake is locked before allowing withdrawal
    uint16 public withdrawLockPeriod = 1;

    /// @notice maximum number of iterations for electing proposer
    uint32 public maxIteration = 100_000;

    /// @notice maximum number of requestIds that can be fulfilled per request
    uint16 public maxRequests = 20;

    /// @notice percentage by which validators stake is penalised
    uint32 public slashPercentage = 1_000_000; // 10%

    uint32 public maxChurnPercentage = 3_300_000; // 33%

    //keccak256(STAKE_MODIFIER_ROLE)
    bytes32 public constant STAKE_MODIFIER_ROLE = 0xdbaaaff2c3744aa215ebd99971829e1c1b728703a0bf252f96685d29011fc804;
    // slither-disable-next-line too-many-digits
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice denominator used to calculate stake amount to be burned
    uint32 public constant BASE_DENOMINATOR = 10_000_000; // 100%

    // kecckeccak256(JAILER_ROLE)
    bytes32 public constant JAILER_ROLE = 0x3a612eb9ead461499ef30313166f3e259cef70ffda582b57c4dedbb097274d99;

    // keccak256(BASE_MODIFIER_ROLE)
    bytes32 public constant BASE_MODIFIER_ROLE = 0x51053cf7af63fc6b96ba407869e545d500b12200989281339d9fd33087b2f3ed;

    /// @notice sets max iteration for electing a proposer
    function setMaxIteration(uint32 _maxIteration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxIteration = _maxIteration;
    }

    /// @notice sets time limit in epochs allowing for validator selection
    function setValidatorSelectionTimelimit(uint8 _validatorSelectionTimelimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validatorSelectionTimelimit = _validatorSelectionTimelimit;
    }

    /// @notice sets block reward validator receives for each finalized block
    function setBlockReward(uint256 _blockReward) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blockReward = _blockReward;
    }

    /// @notice sets minimum stake required to be a validator
    function setMinStake(uint256 _minStake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minStake = _minStake;
    }

    /// @notice sets withdraw lock period in epochs
    function setWithdrawLockPeriod(uint16 _withdrawLockPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        withdrawLockPeriod = _withdrawLockPeriod;
    }

    /// @notice sets dynasty length in epochs
    function setDynastyLength(uint256 _dynastyLength) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dynastyLength = _dynastyLength;
    }

    /// @notice sets epoch length in seconds
    function setEpochLength(uint256 _epochLength) external onlyRole(DEFAULT_ADMIN_ROLE) {
        epochLength = _epochLength;
    }

    /// @notice sets maximum requestIds that can be fulfilled per request
    function setMaxRequests(uint16 _maxRequests) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxRequests = _maxRequests;
    }

    /// @notice sets slash percentage by which validators stake will be penalised
    function setMaxChurnPercentage(uint32 _maxChurnPercentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxChurnPercentage = _maxChurnPercentage;
    }

    /// @notice sets slash percentage by which validators stake will be penalised
    function setSlashPercentage(uint32 _slashPercentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        slashPercentage = _slashPercentage;
    }

    /// @notice sets number of dynasties a validator will be jailed for
    function setNumJailDynasty(uint256 _numJailDynasty) external onlyRole(DEFAULT_ADMIN_ROLE) {
        numJailDynasty = _numJailDynasty;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract SourceChain {
    using Address for address;

    function getData(address target, bytes memory payload) external view returns (bytes memory) {
        return target.functionStaticCall(payload);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./StateManager.sol";
import "../interface/IBridge.sol";
import "../interface/IStakeManager.sol";
import "../Storage/StakeStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
 * @notice this contract is part of the bridge ecosystem and has to be deployed on the native chain
 */
contract StakeManager is StakeStorage, StateManager, Initializable, IStakeManager {
    IERC20 public bridgeToken;
    IBridge public bridge;

    /**
     * @dev Emitted when a address has staked tokens.
     * @param amount staked by validator
     * @param validator address
     * @param validatorId ID of given validator address
     * @param epoch current epoch validator has staked in
     * @param dynasty current dynasty validator has staked in
     */
    event Staked(uint256 amount, address validator, uint32 indexed validatorId, uint256 indexed epoch, uint256 indexed dynasty);

    /**
     * @dev Emitted when a address has unstaked  tokens.
     * @param validator address
     * @param validatorId ID of given validator address
     * @param epoch current epoch validator has unstaked in
     * @param dynasty current dynasty validator has unstaked in
     */
    event Unstaked(address validator, uint32 indexed validatorId, uint256 indexed epoch, uint256 indexed dynasty);

    /**
     * @dev Emitted when a address has withdrawn tokens.
     * @param validator address
     * @param validatorId ID of given validator address
     * @param mode current mode
     * @param epoch current epoch validator has unstaked in
     * @param dynasty current dynasty validator has unstaked in
     */
    event Withdraw(address validator, uint32 indexed validatorId, uint8 mode, uint256 indexed epoch, uint256 indexed dynasty);

    /**
     * @dev Emitted when a validator has been slashed.
     * @param validator address of the validator
     * @param validatorId ID of given validator address
     * @param epoch current epoch validator has unstaked in
     * @param dynasty current dynasty validator has unstaked in
     * @param prevStake previous stake before slashing
     * @param newStake new stake after slashing
     * @param sender caller of slash()
     */
    event Slashed(
        address validator,
        uint32 indexed validatorId,
        uint256 indexed epoch,
        uint256 indexed dynasty,
        uint256 prevStake,
        uint256 newStake,
        address sender
    );

    /**
     * @dev Emitted when a validator is jailed
     * @param validatorId ID of validator that is jailed
     * @param jailStart dynasty at which jail starts
     * @param jailEndDynasty dynasty at which jail ends
     * @param epoch epoch in which validator is jailed
     * @param sender caller of jailValidator()
     */
    event ValidatorJailed(
        uint32 indexed validatorId, uint256 indexed jailStart, uint256 jailEndDynasty, uint256 indexed epoch, address sender
    );

    // Common errors
    /// @notice reverts with the error if validator does not exist
    error ValidatorDoesNotExist();
    /// @notice reverts with the error if validatorId is incorrect
    error InvalidValidator();
    /// @notice reverts with the error if an operation was not performed in required mode
    error IncorrectMode();
    /// @notice reverts with the error if erc20 token transfer fails
    error TokenTransferFailed(address from, address to, uint256 amount);

    // stake() errors
    /// @notice reverts with the error if the stake amount is less than minStake
    error LessThanMinStake();
    /// @notice reverts with the error if the existing validator is trying to stake
    error AlreadyValidator(uint32 validatorId);

    // unstake() errors
    /// @notice reverts with the error during unstake if withdraw lock already exist for validator
    error ExistingWithdrawLock(uint256 unlockAfter);

    // withdraw() errors
    /// @notice reverts with the error during withdraw if validator has already participated in selection
    error AlreadyParticipated();
    /// @notice reverts with the error if the withdraw lock doesn't exist during withdraw
    error NoWithdrawLock();
    /// @notice reverts with the error if withdraw lock period has not passed
    error InvalidWithdrawRequest();
    /// @notice reverts with the error if validator in the activeSet
    error StillInActiveSet();

    // jailValidator() errors
    /// @notice reverts with the error if validator is being jailed in jail period
    error ValidatorAlreadyInJail();

    constructor(uint256 _firstDynastyCreation) {
        firstDynastyCreation = _firstDynastyCreation;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @param bridgeTokenAddress The address of the bridge token ERC20 contract
     * @param bridgeAddress The address of the bridge contract
     */
    function initialize(address bridgeTokenAddress, address bridgeAddress) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgeToken = IERC20(bridgeTokenAddress);
        bridge = IBridge(bridgeAddress);
    }

    /**
     * @notice Validator to stake
     * @param amount The amount to be staked
     */
    function stake(uint256 amount) external {
        if (amount < minStake) revert LessThanMinStake();
        if (validatorIds[msg.sender] != 0) revert AlreadyValidator(validatorIds[msg.sender]);

        numValidators = numValidators + 1;
        validatorIds[msg.sender] = numValidators;
        validators[numValidators] = Structs.Validator(numValidators, msg.sender, amount, 0);

        emit Staked(amount, msg.sender, validatorIds[msg.sender], getEpoch(), getDynasty());
        if (!bridgeToken.transferFrom(msg.sender, address(this), amount)) revert TokenTransferFailed(msg.sender, address(this), amount);
    }

    /**
     * @notice a signal to the network that the validator is planning to withdraw their funds from the network.
     * validator would still continue to participate till the validator withdraws
     */
    function unstake() external {
        uint32 validatorId = validatorIds[msg.sender];
        if (validatorId == 0) revert InvalidValidator();
        //slither-disable-next-line incorrect-equality,timestamp
        if (withdrawAfterPerValidator[msg.sender] != 0) revert ExistingWithdrawLock(withdrawAfterPerValidator[msg.sender]);

        uint256 dynasty = getDynasty();
        withdrawAfterPerValidator[msg.sender] = dynasty + withdrawLockPeriod;
        emit Unstaked(msg.sender, validatorId, getEpoch(), dynasty);
    }

    /**
     * @notice allows validator to withdraw their funds once withdrawLockPeriod has passed
     */
    function withdraw() external {
        uint32 validatorId = validatorIds[msg.sender];
        if (validatorId == 0) revert InvalidValidator();

        uint8 mode = bridge.getMode();
        //slither-disable-next-line timestamp,incorrect-equality
        if (withdrawAfterPerValidator[msg.sender] == 0) revert NoWithdrawLock();
        if (mode != uint8(EpochMode.ValidatorSelection)) revert IncorrectMode();

        uint256 dynasty = getDynasty();
        //slither-disable-next-line incorrect-equality
        if (bridge.getValidatorIteration(validatorId, dynasty) != 0) revert AlreadyParticipated();

        //slither-disable-next-line incorrect-equality
        bool prevDynastyAndChurnCheck = (
            bridge.getNumChurnedOut(dynasty) == 0 && bridge.getIsValidatorSelectedPerDynasty(validatorId, dynasty - 1)
                && bridge.getActiveSetPerDynasty(dynasty - 1).length == bridge.getNumParticipantsPerDynasty(dynasty - 1)
        );

        if (bridge.getIsValidatorSelectedPerDynasty(validatorId, dynasty) || prevDynastyAndChurnCheck) revert StillInActiveSet();

        uint256 epoch = getEpoch();
        if (dynasty < withdrawAfterPerValidator[msg.sender]) revert InvalidWithdrawRequest();

        uint256 withdrawAmount = validators[validatorId].stake;
        validators[validatorId].stake = 0;
        withdrawAfterPerValidator[msg.sender] = 0;

        emit Withdraw(msg.sender, validatorId, mode, epoch, dynasty);
        if (!bridgeToken.transfer(msg.sender, withdrawAmount)) revert TokenTransferFailed(address(this), msg.sender, withdrawAmount);
    }

    function updateBaseParameters(uint256 _baseEpochIncrement, uint256 _baseTimeIncrement) external override onlyRole(BASE_MODIFIER_ROLE) {
        baseTimeIncrement = _baseTimeIncrement;
        baseEpochIncrement = _baseEpochIncrement;
    }

    /**
     * @notice slashing multiple validators at once so that only one external call is required
     * @param _ids validator ids array that are to be slashed
     */
    function slashValidators(uint32[] memory _ids) external override onlyRole(STAKE_MODIFIER_ROLE) {
        for (uint32 i = 0; i < _ids.length; i++) {
            _slash(_ids[i]);
        }
    }

    /**
     * @notice jailing multiple validators at once so that only one external call is required
     * @param _ids validator ids array that are to be jailed
     */
    function jailValidators(uint32[] memory _ids) external override onlyRole(JAILER_ROLE) {
        for (uint32 i = 0; i < _ids.length; i++) {
            _jailValidator(_ids[i]);
        }
    }

    /**
     * @notice give block reward to selected validator
     * @param selectedValidator ID of the validator
     */
    function giveBlockReward(uint32 selectedValidator) external override onlyRole(STAKE_MODIFIER_ROLE) {
        _setValidatorStake(selectedValidator, validators[selectedValidator].stake + blockReward);
    }

    /**
     * @param validatorId ID of the validator
     * @return withdraw after for the validator Id
     */
    function getWithdrawAfterPerValidator(uint32 validatorId) external view override returns (uint256) {
        return withdrawAfterPerValidator[validators[validatorId]._validatorAddress];
    }

    /**
     * @param validatorAddress validator address
     * @return ID of the validator
     */
    function getValidatorId(address validatorAddress) external view override returns (uint32) {
        return validatorIds[validatorAddress];
    }

    /**
     * @param validatorId ID of the validator
     * @return validator jail end dynasty
     */
    function getValidatorJailEndDynasty(uint32 validatorId) external view override returns (uint256) {
        return validators[validatorId].jailEndDynasty;
    }

    /**
     * @param validatorId ID of the validator
     * @return stake of validator
     */
    function getStake(uint32 validatorId) external view override returns (uint256) {
        return validators[validatorId].stake;
    }

    /**
     * @param validatorId ID of the validator
     * @return validator The Struct of validator information
     */
    function getValidator(uint32 validatorId) external view returns (Structs.Validator memory validator) {
        return validators[validatorId];
    }

    /**
     * @return total number of validators
     */
    function getNumValidators() external view override returns (uint32) {
        return numValidators;
    }

    /**
     * @notice Internal function for setting stake of a validator
     * @param _id Id of the validator
     * @param _stake the amount of Razor bridge tokens staked
     */
    function _setValidatorStake(uint32 _id, uint256 _stake) internal {
        validators[_id].stake = _stake;
    }

    /**
     * @notice internal function where validators are slashed
     * @param _id Id of the validator
     */
    function _slash(uint32 _id) internal {
        if (_id == 0) revert InvalidValidator();
        Structs.Validator memory validator = validators[_id];
        if (validator._validatorAddress == address(0)) revert ValidatorDoesNotExist();
        uint256 dynasty = getDynasty();
        uint256 epoch = getEpoch();
        uint256 _stake = validator.stake;
        uint256 amountToBeBurned = (_stake * slashPercentage) / BASE_DENOMINATOR;
        _stake = _stake - amountToBeBurned;
        _setValidatorStake(_id, _stake);
        emit Slashed(validator._validatorAddress, _id, epoch, dynasty, _stake + amountToBeBurned, _stake, msg.sender);
        //slither-disable-next-line calls-loop
        if (!bridgeToken.transfer(BURN_ADDRESS, amountToBeBurned)) {
            revert TokenTransferFailed(address(this), BURN_ADDRESS, amountToBeBurned);
        }
    }

    /**
     * @notice allow addresses with JAILER_ROLE to jail validator
     * @param validatorId id of validator to be jailed
     */
    function _jailValidator(uint32 validatorId) internal {
        if (validatorId == 0) revert InvalidValidator();
        if (validators[validatorId]._validatorAddress == address(0)) revert ValidatorDoesNotExist();
        uint256 dynasty = getDynasty();
        //slither-disable-next-line incorrect-equality,timestamp
        if (validators[validatorId].jailEndDynasty >= dynasty) revert ValidatorAlreadyInJail();

        validators[validatorId].jailEndDynasty = dynasty + numJailDynasty;
        uint256 epoch = getEpoch();
        emit ValidatorJailed(validatorId, dynasty, dynasty + numJailDynasty, epoch, msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./../library/Structs.sol";

contract StakeStorage {
    /// @notice mapping of validator address => validator id
    mapping(address => uint32) public validatorIds;
    /// @notice mapping of validator id => validator struct
    mapping(uint32 => Structs.Validator) public validators;
    /// @notice mapping of validator address => unstake lock epoch
    mapping(address => uint256) public withdrawAfterPerValidator;

    /// @notice total number of validators
    uint32 public numValidators;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "../Storage/ResultStorage.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
 * @notice this contract is part of the bridge ecosystem and has to be deployed on the destination chains
 */
contract ResultManager is ResultStorage, AccessControl, Initializable {
    /**
     * @dev Emitted when proof of old signer transfering ownership to the new signer address is sent to Result Manager.
     * @param signerDetails details of the signer in a struct
     */
    event SignerSet(Structs.SignerAddressDetails signerDetails);

    /// @notice reverts with the error if zero address
    error ZeroAddress();
    // Dispute errors
    /// @notice reverts when signer addresses are different in the dispute
    error InvalidSignatureDispute();
    /// @notice reverts when the details of the signer proofs are not different ie, same
    error InvalidDetailsDispute();
    /// @notice reverts when the signer address does not exist
    error InvalidDynasty();
    /// @notice reverts when the dispute time period has expired
    error DisputeExpired();
    /// @notice reverts when trying to dispute signer proof done by admin
    error AdminSignerTransfer();

    // Set Block errors
    /// @notice reverts with error signer address has not yet been confirmed
    error SignerAddressNotConfirmed();
    /// @notice reverts with error signer address has been disputed
    error SignerAddressDisputed();
    /// @notice reverts with the error if the signature is not signed by required signer
    error InvalidSignature();
    /// @notice reverts with error if the epoch in which signer address was assigned is greater than or equal to epoch in the block message
    error IncorrectBlockSent();
    /// @notice reverts with error if the block is already set for the epoch
    error BlockAlreadySet();
    /// @notice reverts with error when a signer address has exhausted the number of blocks it can set
    error BlockLimitReached();

    constructor(address _nativeAdmin) {
        if (_nativeAdmin == address(0)) revert ZeroAddress();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _nativeAdmin);
        nativeAdmin =  _nativeAdmin;
    }

    /**
     * @notice sets the new signer address by providing signer transfer proof
     * @dev the signer address can be updated only when the dynasty changes as the nodes
     *  that created the previous signer address must transfer ownership to the newly created signer address
     * @param signerTransferProof a struct containing epoch, new signer address and a signature signed by the previous signer address
     */
    function setSigner(Structs.SignerTransfer memory signerTransferProof) external {

        // if network has stalled for one or more dynasties then increase current dynasty accordingly
        if (signerTransferProof.epoch > (expectedDynastyEnd + dynastyLength)) {
            uint256 epochDiff = signerTransferProof.epoch - (expectedDynastyEnd + dynastyLength);
            uint256 dynastyJumped = (epochDiff / dynastyLength) + 1;
            currentDynasty += dynastyJumped + 1;
            expectedDynastyEnd += ((dynastyJumped + 1) * dynastyLength);
        } else {
            currentDynasty += 1;
            expectedDynastyEnd += dynastyLength;
        }

        bytes32 messageHash = keccak256(abi.encodePacked(signerTransferProof.epoch, signerTransferProof.newSignerAddress));
        address recoveredAddress = ECDSA.recover(messageHash, signerTransferProof.signature);

        //slither-disable-next-line timestamp
        if (recoveredAddress != signerAddressPerDynasty[currentDynasty - 1].signerAddress) {
            // incase of admin intervention is required for signer transfer
            if (!hasRole(DEFAULT_ADMIN_ROLE, recoveredAddress)) revert InvalidSignature();
        }

        signerAddressPerDynasty[currentDynasty] = Structs.SignerAddressDetails(
            false,
            false,
            uint32(expectedDynastyEnd - signerTransferProof.epoch),
            signerTransferProof.newSignerAddress,
            signerTransferProof.epoch,
            block.timestamp + DISPUTE_TIME_PERIOD,
            new uint256[](0)
        );

        emit SignerSet(signerAddressPerDynasty[currentDynasty]);
    }

    /**
     * @notice Incase of double signing/incorrect handover where the details on the native chain is different to
     * what it is set on the destination chain is different, a dispute can be generated on destination chain where
     * native chain details are sent here. If the dispute goes through, the new signer address is invalidated and any blocks
     * merged during the dispute period will be removed
     * @param dynasty the dynasty for which the dispute is being generated
     * @param signerTransferProof struct of transfer proof present on native chain
     */
    function disputeSigner(uint256 dynasty, Structs.SignerTransfer memory signerTransferProof) external {
        address signerAddress = signerAddressPerDynasty[dynasty].signerAddress;
        //slither-disable-next-line incorrect-equality
        if (signerAddress == address(0)) revert InvalidDynasty();
        //slither-disable-next-line timestamp
        if (signerAddressPerDynasty[dynasty].disputeExpiry <= block.timestamp) revert DisputeExpired();

        bytes32 messageHash = keccak256(abi.encodePacked(signerTransferProof.epoch, signerTransferProof.newSignerAddress));
        address recoveredSignerAddress = ECDSA.recover(messageHash, signerTransferProof.signature);

        if (hasRole(DEFAULT_ADMIN_ROLE, recoveredSignerAddress)) revert AdminSignerTransfer();
        if (recoveredSignerAddress != signerAddressPerDynasty[dynasty - 1].signerAddress) revert InvalidSignatureDispute();

        if (
            signerTransferProof.epoch == signerAddressPerDynasty[dynasty].epochAssigned
                && signerTransferProof.newSignerAddress == signerAddressPerDynasty[dynasty].signerAddress
        ) revert InvalidDetailsDispute();

        signerAddressPerDynasty[dynasty].isDisputed = true;
        signerAddressPerDynasty[dynasty].numBlocksLimit = 0;

        for (uint256 i = 0; i < signerAddressPerDynasty[dynasty].blocksConfirmedDuringDisputePeriod.length; i++) {
            blocks[signerAddressPerDynasty[dynasty].blocksConfirmedDuringDisputePeriod[i]] = Structs.Block(0, bytes(""), bytes(""));
        }
    }

    /**
     * @notice sets the block by providing message data and signature of the current dynasty signer address
     * @dev Once the block is confirmed on the source chain, anyone can set the block by calling this function to the destination
     * chain. Signature verification are being done here as well to ensure a valid block is being set to the contract. After verification,
     * we decode the message and assign results to their corresponding collectionIds
     * @param confirmedBlock block confirmed on the native chain
     */
    function setBlock(Structs.Block memory confirmedBlock) external {
        bytes32 messageHash = keccak256(confirmedBlock.message);

        (uint256 dynasty, uint256 epoch, uint32[] memory requestIds, bytes[] memory values) =
            abi.decode(confirmedBlock.message, (uint256, uint256, uint32[], bytes[])); // solhint-disable-line

        address signerAddress = signerAddressPerDynasty[dynasty].signerAddress;

        if (signerAddressPerDynasty[dynasty].isDisputed) revert SignerAddressDisputed();
        if (signerAddressPerDynasty[dynasty].epochAssigned >= epoch) revert IncorrectBlockSent();
        if (ECDSA.recover(messageHash, confirmedBlock.signature) != signerAddress) revert InvalidSignature();
        if (bytes32(blocks[epoch].signature) != bytes32(0)) revert BlockAlreadySet();
        //slither-disable-next-line incorrect-equality
        if (signerAddressPerDynasty[dynasty].numBlocksLimit == 0) revert BlockLimitReached();

        //slither-disable-next-line timestamp
        if (signerAddressPerDynasty[dynasty].disputeExpiry > block.timestamp) {
            signerAddressPerDynasty[dynasty].blocksConfirmedDuringDisputePeriod.push(epoch);
        }

        signerAddressPerDynasty[dynasty].numBlocksLimit -= 1;
        blocks[epoch] = confirmedBlock;

        uint16[] memory ids = new uint16[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            Structs.Value memory collectionValue = abi.decode(values[i], (Structs.Value));
            requestToCollection[requestIds[i]] = collectionValue.collectionId;
            collectionResults[collectionValue.collectionId] = collectionValue;
            collectionIds[collectionValue.name] = collectionValue.collectionId;
            ids[i] = collectionValue.collectionId;
        }

        activeCollectionIds = ids;
        lastUpdatedTimestamp = confirmedBlock.timestamp;
    }

    /**
     * @notice changes native admin address
     */
    function setNativeAdmin(address _nativeAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_nativeAdmin == address(0)) revert ZeroAddress();
        grantRole(DEFAULT_ADMIN_ROLE, _nativeAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, nativeAdmin);
        nativeAdmin = _nativeAdmin;
    }

    /**
     * @notice sets dynasty length in epochs
     */
    function setDynastyLength(uint256 _dynastyLength) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dynastyLength = _dynastyLength;
    }

    /**
     * @notice return the struct of signer details based on the dynasty provided
     * @param dynasty dynasty for which signer details is to be fetched
     * @return _signerDetails : struct of the signer details
     */
    function getSignerAddressDetails(uint256 dynasty) external view returns (Structs.SignerAddressDetails memory) {
        return signerAddressPerDynasty[dynasty];
    }

    /**
     * @notice return the struct of the block based on the epoch provided
     * @param epoch epoch for which the block is to be fetched
     * @return _block : struct of the confirmed block
     */
    function getBlock(uint256 epoch) external view returns (Structs.Block memory) {
        return blocks[epoch];
    }

    /**
     * @notice using the hash of collection name, clients can query the result of that collection
     * @param _name bytes32 hash of the collection name
     * @return result of the collection and its power
     */
    function getResult(bytes32 _name) external view returns (uint256, int8) {
        uint16 id = collectionIds[_name];
        return getResultFromID(id);
    }

    /**
     * @notice return the collectionId based on the requestId provided
     * @param requestId request ID
     * @return collectionId : collectionId fulfilled in the request
     */
    function getRequestToCollection(uint32 requestId) external view returns (uint16) {
        return requestToCollection[requestId];
    }

    /**
     * @notice using the hash of collection name, clients can query collection id with respect to its hash
     * @param _name bytes32 hash of the collection name
     * @return collection ID
     */
    function getCollectionID(bytes32 _name) external view returns (uint16) {
        return collectionIds[_name];
    }

    /**
     * @return ids of active collections in the oracle
     */
    function getActiveCollections() external view returns (uint16[] memory) {
        return activeCollectionIds;
    }

    /**
     * @notice using the collection id, clients can query the status of collection
     * @param _id collection ID
     * @return status of the collection
     */
    function getCollectionStatus(uint16 _id) external view returns (bool) {
        bool isActive = false;
        for (uint256 i = 0; i < activeCollectionIds.length; i++) {
            if (activeCollectionIds[i] == _id) {
                isActive = true;
                break;
            }
        }
        return isActive;
    }

    /**
     * @notice using the collection id, clients can query the result of the collection
     * @param collectionId collection ID
     * @return result of the collection and its power
     */
    function getResultFromID(uint16 collectionId) public view returns (uint256, int8) {
        return (collectionResults[collectionId].value, collectionResults[collectionId].power);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./../library/Structs.sol";

contract ResultStorage {
    /// @notice mapping of epoch => Block
    mapping(uint256 => Structs.Block) public blocks;
    /// @notice mapping of requestId => collectionId
    mapping(uint32 => uint16) public requestToCollection;
    /// @notice mapping for latest result of collectionId => Value
    mapping(uint16 => Structs.Value) public collectionResults;
    /// @notice mapping of dynasty => signer address details
    mapping(uint256 => Structs.SignerAddressDetails) public signerAddressPerDynasty;
    /// @notice mapping of collection name => collection id
    mapping(bytes32 => uint16) public collectionIds;
    // signer address => time expiry
    mapping(address => uint256) public disputeExpiryPerSigner;
    // signer address => disputed bool
    mapping(address => bool) public isSignerDisputed;

    /// @notice admin on the native chain
    address public nativeAdmin;
    /// @notice active collections ids
    uint16[] public activeCollectionIds;
    /// @notice timestamp when result was last updated
    uint256 public lastUpdatedTimestamp;
    /// @notice dispute time period for fraud proofs
    uint256 public constant DISPUTE_TIME_PERIOD = 1200;
    /// @notice current dynasty
    uint256 public currentDynasty;
    /// @notice when the current dynasty would end in epochs
    uint256 public expectedDynastyEnd;
    /// @notice length of a dynasty in epochs
    uint256 public dynastyLength = 100;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./../library/Structs.sol";

contract BridgeStorage {
    // SIGNER ADDRESS
    /// @notice mapping dynasty => epoch
    mapping(uint256 => uint256) public modeChange;
    /// @notice mapping dynasty => epoch => signerAddress
    mapping(uint256 => mapping(uint256 => address)) public signerAddressPerDynasty;
    /// @notice mapping validatorId => dynasty => epoch => signerAttestation
    mapping(uint32 => mapping(uint256 => mapping(uint256 => Structs.SignerAttestation))) public signerAttestations;
    /// @notice mapping dynasty => epoch => signerAddresses attested this dynasty
    mapping(uint256 => mapping(uint256 => address)) public attestedSignerAddress;
    /// @notice mapping dynasty => epoch => signerAddress => numVotes
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public signerVotesPerAttestation;
    // signer address => bool
    mapping(address => bool) public isSignerDisputed;

    // REQUEST

    /// @notice mapping requestId => request
    mapping(uint32 => Structs.Request) public requests;

    /// @notice mapping dynasty => epoch => message => numVotes
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) public numMessageVotesPerEpoch;
    /// @notice mapping dynasty => epoch => message
    mapping(uint256 => mapping(uint256 => bytes32)) public messagePerEpoch;
    /// @notice mapping validatorId => dynasty => epoch => bool
    mapping(uint32 => mapping(uint256 => mapping(uint256 => bool))) public hasValidatorCommitMessage;

    // SIGNING
    /// @notice mapping epoch => Block Struct
    mapping(uint256 => Structs.Block) public blocks;

    // TRANSFER PROOF

    /// @notice mapping dynasty => Signer Transfer
    mapping(uint256 => Structs.SignerTransfer) public signerTransferProofs;

    //VALIDATOR SELECTION
    /// @notice mapping dynasty => activeSet
    mapping(uint256 => uint32[]) public activeSetPerDynasty;
    /// @notice mapping validatorId => dynasty => iteration
    mapping(uint32 => mapping(uint256 => uint256)) public validatorIterationPerDynasty;
    /// @notice mapping validatorId => dynasty => isSelected
    mapping(uint32 => mapping(uint256 => bool)) public isValidatorSelectedPerDynasty;
    /// @notice mapping dynasty => biggestStake
    mapping(uint256 => uint256) public biggestStakePerDynasty;
    /// @notice mapping dynasty => numParticipants
    mapping(uint256 => uint32) public numParticipantsPerDynasty;
    /// @notice mapping dynasty => churned Out validators
    mapping(uint256 => uint32[]) public churnedOutValidators;
    /// @notice mapping dynasty => validator id => numParticipants
    mapping(uint256 => mapping(uint32 => bool)) public isChurnedOut;

    /// @notice number of requests created, refer to createRequest()
    uint32 public numRequests;
    /// @notice number of requests fulfilled, refer to finalizeBlock()
    uint32 public numRequestsFulfilled;
    /// @notice current dynasty and previous dynasties active set encoded(keccak256)
    /// @dev this salt is used to select validators in _isElectedProposer() using a bias implementation
    bytes32 public salt;
    /// @notice number of participants N required by the network
    uint32 public numParticipants = 10;
    /// @notice threshold T required by the network to reach consensus (T + 1)
    uint32 public threshold = 8;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./StateManager.sol";
import "../interface/IBridge.sol";
import "../interface/IStakeManager.sol";
import "../Storage/BridgeStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../library/Random.sol";

/**
 * @notice this contract is part of the bridge ecosystem and has to be deployed on the native chain
 */
contract Bridge is BridgeStorage, StateManager, Initializable, IBridge {
    IStakeManager public stakeManager;

    /**
     * @dev Emitted when there has been a call to createRequest. Can only be called by the admin
     * @param numRequests number of requests so far (requestId)
     * @param sourceChainId chain id of the source from where the data is to be queried
     * @param sourceAddress smart contract address on the source chain
     * @param payload payload to query from the source chain smart contract (function signature + encoded parameters)
     * @param targetChainId destination chain id where the queried data is to be sent
     * @param requesterAddress address of the createRequest caller
     */
    event CreatedRequest(
        uint32 numRequests,
        uint32 sourceChainId,
        address sourceAddress,
        bytes payload,
        uint32 targetChainId,
        address indexed requesterAddress,
        uint256 indexed epoch,
        uint256 indexed dynasty
    );

    /**
     * @dev Emitted when validators are churned out
     * @param churnedOutValidators validators churned out for the dynasty
     * @param epoch current epoch of validatorSelection
     * @param dynasty current dynasty of validatorSelection
     */
    event ValidatorsChurnedOut(uint32[] churnedOutValidators, uint256 indexed epoch, uint256 indexed dynasty);

    /**
     * @dev Emitted when a validator takes part the validator selection process.
     * @param validatorId ID of the validator
     * @param activeSet validators selected for the dynasty
     * @param iteration value generated by the validator
     * @param isValidatorSelected if the validator has been selected
     * @param epoch current epoch of validatorSelection
     * @param dynasty current dynasty of validatorSelection
     */
    event ValidatorSelection(
        uint32 validatorId,
        uint32[] activeSet,
        uint256 iteration,
        uint256 biggestStake,
        bool isValidatorSelected,
        uint256 indexed epoch,
        uint256 indexed dynasty
    );

    /**
     * @dev Emitted when a validator tries to attest signerAddress for the first time.
     * @param signerAddress address attested by all validators
     * @param validatorId ID of the validator from the active set of validators
     * @param sender caller of the attestSigner
     * @param epoch current epoch of attestSigner
     * @param dynasty current dynasty of attestSigner
     */
    event AttestSigner(address signerAddress, uint32 indexed validatorId, address sender, uint256 indexed epoch, uint256 indexed dynasty);

    /**
     * @dev Emitted when old signer transfers ownership to the new signer address.
     * @param signature with which the message is signed by old signer address
     * @param oldSignerAddress address of the public old signer address
     * @param newSignerAddress address of the public new signer address
     * @param epoch current epoch of signerTransfer
     * @param dynasty current dynasty of signerTransfer
     */
    event ConfirmTransfer(
        bytes signature, address oldSignerAddress, address newSignerAddress, uint256 indexed epoch, uint256 indexed dynasty
    );

    /**
     * @dev Emitted when a validator tries to commit message for the first time.
     * @param message the message being committed by the validator
     * @param validatorId ID of the validator from the active set of validators
     * @param sender caller of the attestSigner
     * @param epoch current epoch of attestSigner
     * @param dynasty current dynasty of attestSigner
     */
    event MessageCommitted(bytes message, uint32 indexed validatorId, address sender, uint256 indexed epoch, uint256 dynasty);

    /**
     * @dev Emitted when a block is successfully created and finalized.
     * @param blockWinner Winner of the block reward
     * @param signature with which the message is signed
     * @param signerAddress address of the public signer address
     * @param messageData the data being finalized
     * @param sender caller of finalizeRequest ie, finalizing address
     * @param epoch current epoch of finalizeRequest
     * @param dynasty current dynasty of finalizeRequest
     */
    event FinalizeBlock(
        uint32 blockWinner,
        bytes signature,
        address signerAddress,
        bytes messageData,
        address indexed sender,
        uint256 indexed epoch,
        uint256 indexed dynasty
    );

    //Common errors
    /// @notice reverts with the error if Bridge is initialized with a zero address
    error ZeroAddress();
    /// @notice reverts with the error if validatorId is 0
    error InvalidValidator();
    /// @notice reverts with the error if ECDSA recover of the messageHash and signature are not equal to expected signer address
    error InvalidSignature();
    /// @notice reverts with the error if incorrect mode is detected, depends on current state of the network
    error IncorrectMode();
    /// @notice reverts with the error if validator tries to attest signer address or commit message without being in current active set
    error ValidatorNotSelected();
    /// @notice reverts with the error if validator tries to attest a zero address or confirmSigner when attestedSignerAddress is empty
    error ZeroSignerAddress();

    //Mode:ValidatorSelection errors
    /// @notice reverts with the error if threshold is set greater than or equal to the number of participants in the network
    error InvalidUpdation();
    /// @notice reverts with the error if validator has less than minStake during validator selection
    error LessThanMinStake(uint256 validatorStake);
    /// @notice reverts with the error if validator is jailed during validator selection
    error ValidatorInJailPeriod();
    /// @notice reverts with the error if validator has already called validatorSelection in the current dynasty
    error IterationAlreadyCalculated();
    /// @notice reverts with the error if validator has not been selected in the current dynasties active set
    error NotElected();

    //Mode:SignerCreation errors
    /// @notice reverts with the error if validator tries to attest a signer address more than once in an epoch
    error AlreadyAttested();
    /// @notice reverts with the error if confirmSigner is called, but the public signing address
    /// of the current dynasty has already been set
    error SignerAlreadyConfirmed();

    //Mode:Signing errors
    /// @notice reverts with the error if validator has already committed a message in the current epoch
    error ValidatorAlreadyCommitted();
    /// @notice reverts with the error if validator tries to commit a message, when the block for the epoch is already proposed
    error BlockAlreadyConfirmed();
    /// @notice reverts with the error if the messageData being sent to commitMessage or finalizeBlock is incorrect
    error InvalidMessage();
    /// @notice reverts with the error if there are no pending requests, and the message values are not empty
    /// as expected for mining an empty block
    error EmptyMessageExpected();
    /// @notice reverts with the error if there is no message attested in the current epoch, and a validator tries to finalizeBlock
    error NoMessageCommitted();
    /// @notice reverts with the error if the _dynasty in the message being committed, does not match current dynasty
    error InvalidDynastyInMessageData(uint256 dynasty, uint256 messageDynasty);
    /// @notice reverts with the error if the _epoch in the message being committed, does not match current epoch
    error InvalidEpochInMessageData(uint256 epoch, uint256 messageEpoch);
    /// @notice reverts with the error if requestId == 0 is detected within messageData
    error RequestIdCantBeZero();
    /// @notice reverts with the error if requests[requestId] is already fulfilled
    error RequestAlreadyFulfilled(uint32 requestId);
    /// @notice reverts with the error if the requests[requestId].epoch is greater than or equal to the current epoch
    error IncorrectRequestEpoch(uint256 epoch, uint256 requestEpoch);
    /// @notice reverts with the error if requestIds of messageData are not in ascending order
    error RequestIdsNotInOrder();
    /// @notice reverts with the error if the length of requestIds of messageData is greater than the maximum allowed requests; maxRequests
    error TooManyRequests();
    /// @notice reverts with the error if the if previous request is not fulfilled yet
    error PreviousRequestNotFulfilled();

    //Dispute errors
    /// @notice reverts when signer addresses are different in the dispute
    error InvalidSignatureDispute();
    /// @notice reverts when the details of the signer proofs are not different ie, same
    error InvalidDetailsDispute();
    /// @notice reverts when the signer address does not exist
    error InvalidDispute();

    constructor() {
        firstDynastyCreation = block.timestamp;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice creates a request that is to be fulfilled by the bridge node
     * @dev numRequests is incremented here and the request struct is set,
     *  which is later verified using requestIds to make sure the correct requests are fulfilled, payload is bytes("getResult()")
     * @param requesterAddress address of the requester
     * @param sourceChainId chain id of the source from where the data is to be queried
     * @param sourceAddress smart contract address on the source chain
     * @param payload payload to query from the source chain smart contract (function signature + encoded parameters)
     * @param targetChainId destination chain id where the queried data is to be sent
     */
    function createRequest(
        address requesterAddress,
        uint32 sourceChainId,
        address sourceAddress,
        bytes memory payload,
        uint32 targetChainId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        numRequests = numRequests + 1;
        bytes memory requestData = abi.encode(requesterAddress, sourceChainId, sourceAddress, payload, targetChainId);
        requests[numRequests] = Structs.Request(false, numRequests, getEpoch(), requestData);
        emit CreatedRequest(
            numRequests, sourceChainId, sourceAddress, payload, targetChainId, msg.sender, getEpoch(), getDynasty()
            );
    }

    /**
     * @param stakeManagerAddress The address of the stake manager contract
     */
    function initialize(address stakeManagerAddress) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        if (stakeManagerAddress == address(0)) revert ZeroAddress();
        stakeManager = IStakeManager(stakeManagerAddress);
    }

    /**
     * @notice validator take part in the selection process to be part of the active set
     * @dev Before taking part in the selection process iteration, if there are validators
     * in the previous active set, we churn out validators (check _churnOut internal funtion for details)
     * is calculated off chain by the validator nodes then is used to select a validator in a bias
     * way using _isElectedProposer(). This function can be called only once every dynasty
     * @param iteration iteration of validator with maximum of maxIteration
     * @param biggestValidatorId validatorId of the validator with biggest stake
     */
    function validatorSelection(uint256 iteration, uint32 biggestValidatorId) external {
        if (_getMode() != uint8(EpochMode.ValidatorSelection)) revert IncorrectMode();
        uint32 validatorId = stakeManager.getValidatorId(msg.sender);
        uint256 validatorStake = stakeManager.getStake(validatorId);
        uint256 biggestValidatorStake = stakeManager.getStake(biggestValidatorId);
        if (validatorId == 0) revert InvalidValidator();
        if (validatorStake < minStake) revert LessThanMinStake(validatorStake);

        uint256 dynasty = getDynasty();
        uint256 epoch = getEpoch();
        //slither-disable-next-line timestamp
        if (stakeManager.getValidatorJailEndDynasty(validatorId) > dynasty) revert ValidatorInJailPeriod();

        //slither-disable-next-line timestamp
        if (validatorIterationPerDynasty[validatorId][dynasty] != 0) revert IterationAlreadyCalculated();

        {
            uint8 validatorsChurnedOut = _churnOut(dynasty);

            // update the num participants for the current dynasty. If value already updated then ignore
            if (numParticipantsPerDynasty[dynasty] == 0) {
                // set the number of participants required in the current dynasty
                numParticipantsPerDynasty[dynasty] = numParticipants;
            }

            // After churning if the validator has been selected or churned out for the current dynasty then return
            // Churned out validators are not allowed to take part in the validtaor selection process of the current dyansty
            if (isValidatorSelectedPerDynasty[validatorId][dynasty] || isChurnedOut[dynasty][validatorId]) {
                if (validatorsChurnedOut > 0) {
                    emit ValidatorsChurnedOut(churnedOutValidators[dynasty], epoch, dynasty);
                }
                return;
            }

            // Will only do this calculation if the validator has not been selected in the previous dynasty
            // and the active set was complete in the previous dynasty

            salt = keccak256(abi.encodePacked(dynasty, activeSetPerDynasty[dynasty - 1]));

            if (!_isElectedProposer(iteration, validatorId, biggestValidatorStake, validatorStake)) revert NotElected();

            validatorIterationPerDynasty[validatorId][dynasty] = iteration;

            bool isAdded = _insertAppropriately(validatorId, iteration, biggestValidatorStake, dynasty);

            if (validatorsChurnedOut > 0) {
                emit ValidatorsChurnedOut(churnedOutValidators[dynasty], epoch, dynasty);
            }

            if (isAdded) {
                emit ValidatorSelection(
                    validatorId,
                    activeSetPerDynasty[dynasty],
                    iteration,
                    biggestStakePerDynasty[dynasty],
                    isValidatorSelectedPerDynasty[validatorId][dynasty],
                    epoch,
                    dynasty
                    );
            }
        }
    }

    /**
     * @notice each validator is required to send their attestation of the public signing address
     * that is generated off chain by the validator nodes. Once the votes of a particular signer address exceeds the threshold,
     * that address is set as public signing address for the rest of the dynasty
     * @param signerAddress address of the public signing address that is being attested by the validator
     */
    function attestSigner(address signerAddress) external {
        // signer checks
        if (_getMode() != uint8(EpochMode.SignerCreation)) revert IncorrectMode();
        uint32 validatorId = stakeManager.getValidatorId(msg.sender);
        if (validatorId == 0) revert InvalidValidator();

        uint256 dynasty = getDynasty();
        if (!isValidatorSelectedPerDynasty[validatorId][dynasty]) revert ValidatorNotSelected();

        if (signerAddress == address(0)) revert ZeroSignerAddress();

        uint256 epoch = getEpoch();
        //slither-disable-next-line timestamp
        if (signerAttestations[validatorId][dynasty][epoch].validatorId != 0) revert AlreadyAttested();

        signerVotesPerAttestation[dynasty][epoch][signerAddress] = signerVotesPerAttestation[dynasty][epoch][signerAddress] + 1;
        signerAttestations[validatorId][dynasty][epoch] = Structs.SignerAttestation(validatorId, signerAddress);

        // registering vote on public key if passed threshold
        if (signerVotesPerAttestation[dynasty][epoch][signerAddress] > threshold) {
            attestedSignerAddress[dynasty][epoch] = signerAddress;
        }

        emit AttestSigner(signerAddress, validatorId, msg.sender, epoch, dynasty);
    }

    /**
     * @notice previous set of validators who created the signerAddress (public sigining address) for the previous dynasty
     * have to transfer ownership to the new signerAddress attested by the new set of validators of the current dynasty
     * by creating a signature on the new signerAddress
     * @dev signature is created by signing the (currentEpoch, newSignerAddress) using the previous signerAddress.
     * There is a condition where the admin can create the signature if there is no previous signerAddress available
     * for the validators to sign with
     * @param signature signature proof created by the previous signerAddress
     */
    function confirmSigner(bytes memory signature) external {
        if (_getMode() != uint8(EpochMode.SignerCreation)) revert IncorrectMode();

        uint256 dynasty = getDynasty();
        uint256 epoch = getEpoch();
        //slither-disable-next-line timestamp
        if (signerAddressPerDynasty[dynasty][epoch] != address(0)) revert SignerAlreadyConfirmed();
        if (attestedSignerAddress[dynasty][epoch] == address(0)) revert ZeroSignerAddress();
        address signerAddress = attestedSignerAddress[dynasty][epoch];
        bytes32 messageHash = keccak256(abi.encodePacked(epoch, signerAddress));
        if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            //slither-disable-next-line incorrect-equality,timestamp
            if (ECDSA.recover(messageHash, signature) != msg.sender) revert InvalidSignature();
        } else {
            //slither-disable-next-line incorrect-equality,timestamp
            if (ECDSA.recover(messageHash, signature) != signerAddressPerDynasty[dynasty - 1][modeChange[dynasty - 1]]) {
                revert InvalidSignature();
            }
        }

        signerTransferProofs[dynasty] = Structs.SignerTransfer(signerAddress, epoch, signature);
        signerAddressPerDynasty[dynasty][epoch] = signerAddress;
        modeChange[dynasty] = epoch;

        emit ConfirmTransfer(
            signature,
            signerAddressPerDynasty[dynasty - 1][modeChange[dynasty - 1]],
            signerAddressPerDynasty[dynasty][modeChange[dynasty]],
            epoch,
            dynasty
            );
    }

    /**
     * @notice validators commit the message that they want to finalize. The message with votes greater than the threshold is
     * set as the message for the current epoch
     * @dev messageData consists of currentDynasty, currentEpoch, requestIds to be fulfilled with a maximum of maxRequests
     * and values which will be mapped to each requestId respectively. If there are no pending requests,
     * values and requestIds should be empty so that an empty block can be finalized by the active set
     * @param messageData the message validator is committing
     */
    function commitMessage(bytes calldata messageData) external {
        if (_getMode() != uint8(EpochMode.Signing)) revert IncorrectMode();

        uint256 dynasty = getDynasty();
        uint256 epoch = getEpoch();
        uint32 validatorId = stakeManager.getValidatorId(msg.sender);
        //slither-disable-next-line timestamp
        if (bytes32(blocks[epoch].signature) != bytes32(0)) revert BlockAlreadyConfirmed();
        //slither-disable-next-line timestamp
        if (hasValidatorCommitMessage[validatorId][dynasty][epoch]) revert ValidatorAlreadyCommitted();
        //slither-disable-next-line timestamp
        if (!isValidatorSelectedPerDynasty[validatorId][dynasty]) revert ValidatorNotSelected();
        (uint256 _dynasty, uint256 _epoch, uint32[] memory requestIds, bytes[] memory values) =
            abi.decode(messageData, (uint256, uint256, uint32[], bytes[]));
        //slither-disable-next-line incorrect-equality,timestamp
        if (_dynasty != dynasty) revert InvalidDynastyInMessageData(dynasty, _dynasty);
        if (_epoch != epoch) revert InvalidEpochInMessageData(epoch, _epoch);
        if (requestIds.length > maxRequests) revert TooManyRequests();
        if (values.length != requestIds.length) revert InvalidMessage();

        //Propose an empty block if no pending requests
        if (numRequestsFulfilled == numRequests) {
            if (values.length != 0) revert EmptyMessageExpected();
        } else {
            if (values.length == 0) revert InvalidMessage();
        }

        if (requestIds.length != 0) {
            for (uint32 i = 0; i < requestIds.length; i++) {
                uint32 requestId = requestIds[i];
                if (requestId == 0) revert RequestIdCantBeZero();
                if (requests[requestId].fulfilled) revert RequestAlreadyFulfilled(requestId);
                if (requests[requestId].epoch >= epoch) revert IncorrectRequestEpoch(epoch, requests[requestId].epoch);
                if (i != 0) {
                    if (requestId <= requestIds[i - 1]) revert RequestIdsNotInOrder();
                }
            }
            if (requestIds[0] != 1) {
                if (!requests[requestIds[0] - 1].fulfilled) revert PreviousRequestNotFulfilled();
            }
        }

        bytes32 messageHash = keccak256(messageData);

        numMessageVotesPerEpoch[dynasty][epoch][messageHash] = numMessageVotesPerEpoch[dynasty][epoch][messageHash] + 1;
        hasValidatorCommitMessage[validatorId][dynasty][epoch] = true;

        // registering vote on message if passed threshold
        if (numMessageVotesPerEpoch[dynasty][epoch][messageHash] > threshold) {
            messagePerEpoch[dynasty][epoch] = messageHash;
        }

        emit MessageCommitted(messageData, validatorId, msg.sender, epoch, dynasty);
    }

    /**
     * @notice Once the signature has been generated by the validators for a particular message,
     * a validator can call this function which will verify the signature created with the message that is to be bridged (finalized)
     * and a validator from the active set is randomly selected and rewarded with a blockReward
     * @dev The message has to be encoded and then sent to the contracts. Encoding is to be done in the following pattern:
     * dynasty(uint256), epoch(uint256), requestId(uint32[]), values(bytes[])
     * @param signature messageData signed by the current dynasty public signing address
     * @param messageData the message that is to be bridged
     */
    function finalizeBlock(bytes calldata signature, bytes calldata messageData) external {
        if (_getMode() != uint8(EpochMode.Signing)) revert IncorrectMode();

        uint256 dynasty = getDynasty();

        uint256 epoch = getEpoch();

        if (bytes32(blocks[epoch].signature) == bytes32(0)) {
            bytes32 messageHash = keccak256(messageData);
            //slither-disable-next-line timestamp
            if (messagePerEpoch[dynasty][epoch] == bytes32(0)) revert NoMessageCommitted();
            //slither-disable-next-line timestamp
            if (messagePerEpoch[dynasty][epoch] != messageHash) revert InvalidMessage();
            //slither-disable-next-line timestamp
            if (ECDSA.recover(messageHash, signature) != signerAddressPerDynasty[dynasty][modeChange[dynasty]]) revert InvalidSignature();

            (,, uint32[] memory requestIds,) = abi.decode(messageData, (uint256, uint256, uint32[], bytes[]));

            blocks[epoch] = Structs.Block(block.timestamp, messageData, signature);

            //Fulfill the pending requests based on the messageData's requestIds
            {
                uint32 _numRequestsFulfilled;
                for (uint32 i = 0; i < requestIds.length; i++) {
                    requests[requestIds[i]].fulfilled = true;
                    _numRequestsFulfilled++;
                }
                numRequestsFulfilled += _numRequestsFulfilled;
            }

            uint32 selectedValidator = _selectValidator(dynasty);

            emit FinalizeBlock(
                selectedValidator, signature, signerAddressPerDynasty[dynasty][modeChange[dynasty]], messageData, msg.sender, epoch, dynasty
                );

            stakeManager.giveBlockReward(selectedValidator);
        }
    }

    /**
     * @notice Incase of double signing/incorrect handover where the details on the native chain is different to
     * what it is set on the destination chain is different, a dispute can be generated on the native chain where you send
     * the native chain as well as the destination chain details here. If dispute goes through, the entire active set is slashed
     * and jailed.
     * @param signerTransferDisputeB struct of transfer proof present on native/destination chain
     */
    function resultManagerProofDispute(Structs.SignerTransfer memory signerTransferDisputeB) external {
        uint256 dynasty = getDynasty();
        address signerAddress = signerAddressPerDynasty[dynasty - 1][modeChange[dynasty - 1]];
        if (signerAddress == address(0)) revert ZeroSignerAddress();
        bytes32 messageHashB = keccak256(abi.encodePacked(signerTransferDisputeB.epoch, signerTransferDisputeB.newSignerAddress));

        address signerAddressB = ECDSA.recover(messageHashB, signerTransferDisputeB.signature);
        if (signerAddress != signerAddressB) revert InvalidSignatureDispute();
        if (
            signerTransferProofs[dynasty].epoch == signerTransferDisputeB.epoch
                && signerTransferProofs[dynasty].newSignerAddress == signerTransferDisputeB.newSignerAddress
        ) revert InvalidDetailsDispute();

        uint256 currentEpoch = getEpoch();

        //slither-disable-next-line weak-prng
        baseEpochIncrement += dynastyLength - (currentEpoch % dynastyLength);
        //slither-disable-next-line weak-prng
        baseTimeIncrement += epochLength - ((block.timestamp - firstDynastyCreation) % epochLength);

        stakeManager.slashValidators(activeSetPerDynasty[dynasty - 1]);
        stakeManager.jailValidators(activeSetPerDynasty[dynasty - 1]);
        stakeManager.updateBaseParameters(baseEpochIncrement, baseTimeIncrement);
    }

    /**
     * @notice this threshold(T) value is used by the network to reach consensus (T + 1) on the public singing address and
     * the message to be finalized by the validator nodes. T needs to be less than the number of participants
     * @param _threshold threshold value to be set for the network
     */
    function setThreshold(uint32 _threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_getMode() != uint8(EpochMode.ValidatorSelection)) revert IncorrectMode();
        if (_threshold >= numParticipants) revert InvalidUpdation();
        threshold = _threshold;
    }

    /**
     * @notice the number of participants in the network should always be greater than the threshold(T) for the network to reach consensus
     * @param _numParticipants sets the number of participants N allowed in the network
     */
    function setNumParticipants(uint32 _numParticipants) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_getMode() == uint8(EpochMode.ValidatorSelection)) revert IncorrectMode();
        numParticipants = _numParticipants;
    }

    /**
     * @notice returns the validators signing attestion in the particular dynasty and epoch sent
     * @param dynasty dynasty of the validators attestion
     * @param epoch epoch of the validators attestion
     * @param validatorId id of the validator whose signer attestion we want to fetch
     * @return the Struct of the signer attestation
     */
    function getSignerAttestation(uint256 dynasty, uint256 epoch, uint32 validatorId)
        external
        view
        returns (Structs.SignerAttestation memory)
    {
        return signerAttestations[validatorId][dynasty][epoch];
    }

    /**
     * @param requestId the id of the request
     * @return request Struct with all the related information for that requestId
     */
    function getRequest(uint32 requestId) external view returns (Structs.Request memory) {
        return requests[requestId];
    }

    /**
     * @param epoch epoch in which block was created
     * @return blocks Struct of the epoch sent
     */
    function getBlock(uint256 epoch) external view returns (Structs.Block memory) {
        return blocks[epoch];
    }

    function getChurnedOutValidatorsPerDynasty(uint256 dynasty) external view returns (uint32[] memory) {
        return churnedOutValidators[dynasty];
    }

    /**
     * @param validatorId id of the validator
     * @param dynasty dynasty for which iteration is to be fetched
     * @return iteration of the validator in the selected dynasty
     */
    function getValidatorIteration(uint32 validatorId, uint256 dynasty) external view override returns (uint256) {
        return validatorIterationPerDynasty[validatorId][dynasty];
    }

    /**
     * @param validatorId id of the validator
     * @param dynasty dynasty to check if validator is part of active set
     * @return boolean to confirm if validatorId is part of the active set in the selected dynasty
     */
    function getIsValidatorSelectedPerDynasty(uint32 validatorId, uint256 dynasty) external view override returns (bool) {
        return isValidatorSelectedPerDynasty[validatorId][dynasty];
    }

    /**
     * @notice returns an array of validatorIds active in the current dynasty
     * @param dynasty dynasty to check for active set
     * @return activeSetPerDynasty array of validatorIds
     */
    function getActiveSetPerDynasty(uint256 dynasty) external view override returns (uint32[] memory) {
        return activeSetPerDynasty[dynasty];
    }

    /**
     * @notice used to query the number of participants (N) that being selected in the provided dynasty
     * @return numParticipants
     */
    function getNumParticipantsPerDynasty(uint256 dynasty) external view override returns (uint32) {
        return numParticipantsPerDynasty[dynasty];
    }

    /**
     * @notice used to query the number of validator churned out in the provided dynasty
     * @return number of validators churned out
     */
    function getNumChurnedOut(uint256 dynasty) external view override returns (uint256) {
        return churnedOutValidators[dynasty].length;
    }

    /**
     * @notice used to query the threshold set for the network
     * @return threshold
     */
    function getThreshold() external view override returns (uint32) {
        return threshold;
    }

    /**
     * @notice used to query the current mode (state) of the network
     * @dev external function that interacts with an internal function, so that getMode can be used by other contracts
     * @return mode _getMode() calculates the current mode
     */
    function getMode() external view override returns (uint8 mode) {
        return _getMode();
    }

    /**
     * @notice used to query the current mode (state) of the network
     * @dev internal function that calculates the mode based on factors like epoch, dynasty, numParticipants and activeSetPerDynasty
     * @return mode
     */
    function _getMode() internal view returns (uint8 mode) {
        uint256 dynasty = getDynasty();
        uint256 epoch = getEpoch();
        uint32 _numParticipants = numParticipantsPerDynasty[dynasty];
        if (_numParticipants == 0) {
            _numParticipants = numParticipants;
        }

        if (
            epoch <= (validatorSelectionTimelimit + ((dynasty - 1) * dynastyLength))
                || activeSetPerDynasty[dynasty].length < _numParticipants
        ) {
            return uint8(EpochMode.ValidatorSelection);
        }
        //slither-disable-next-line incorrect-equality,timestamp
        else if (modeChange[dynasty] == 0 || modeChange[dynasty] == epoch) {
            return uint8(EpochMode.SignerCreation);
        } else {
            return uint8(EpochMode.Signing);
        }
    }

    /**
     * @notice calculates whether or not a validator should be selected for the active set of the current dynasty
     * @dev internal function that selects validator in a biased selection, iteration is calculated off chain by
     * the validator nodes
     * @return bool that indicates whether a validator is selected in the active set of the current dynasty
     */
    function _isElectedProposer(uint256 iteration, uint32 validatorId, uint256 biggestStake, uint256 validatorStake)
        internal
        view
        returns (bool)
    {
        // generating pseudo random number (range 0..(totalstake - 1)), add (+1) to the result,
        // since prng returns 0 to max-1 and staker start from 1
        //roll an n sided fair die where n == numStakers to select a staker pseudoRandomly
        bytes32 seed1 = Random.prngHash(salt, keccak256(abi.encode(iteration)));
        uint256 rand1 = Random.prng(stakeManager.getNumValidators(), seed1);
        //slither-disable-next-line timestamp
        if ((rand1 + 1) != validatorId) {
            return false;
        }
        //toss a biased coin with increasing iteration till the following equation returns true.
        // stake/biggest stake >= prng(iteration,stakerid, salt), staker wins
        // stake/biggest stake < prng(iteration,stakerid, salt), staker loses
        // simplified equation:- stake < prng * biggestStake
        // stake * 2^32 < prng * 2^32 * biggestStake
        // multiplying by 2^32 since seed2 is bytes32 so rand2 goes from 0 to 2^32
        bytes32 seed2 = Random.prngHash(salt, keccak256(abi.encode(validatorId, iteration)));
        uint256 rand2 = Random.prng(2 ** 32, seed2);

        // Below line can't be tested since it can't be assured if it returns true or false
        if (rand2 * (biggestStake) > validatorStake * (2 ** 32)) return (false);
        return true;
    }

    /**
     * @notice randomly selects a validator from the active set of the current dynasty
     * @dev internal function that selects validator in a random fashion from activeSetPerDynasty, this validator is
     * selected to finalize the block and receives the block reward
     */
    function _selectValidator(uint256 dynasty) internal view returns (uint32 selectedValidator) {
        uint256 randVal = Random.prng(activeSetPerDynasty[dynasty].length, blockhash(block.number - 1));
        selectedValidator = activeSetPerDynasty[dynasty][randVal];
    }

    /**
     * @notice churns out validator from the active validator set
     * @dev order of churning out is:-
     * Step 1. If any validator has called unstake and their withdraw lock is about to unlock this dynasty, then churn them out
     * but maximum only 1/3rd of the activeSet can be churned out at a time
     * Step 2. we churn out a validator randomly
     */
    function _churnOut(uint256 dynasty) internal returns (uint8) {
        uint8 validatorsChurnedOut = 0;
        if (churnedOutValidators[dynasty].length == 0) {
            if (
                activeSetPerDynasty[dynasty - 1].length < numParticipantsPerDynasty[dynasty - 1]
                    || activeSetPerDynasty[dynasty - 1].length == 0
            ) return 0;

            uint32 numValidatorsToChurnOut = (numParticipants * maxChurnPercentage) / BASE_DENOMINATOR;

            activeSetPerDynasty[dynasty] = activeSetPerDynasty[dynasty - 1];
            // Step 1: Unstaking validators
            uint8 activeSetPerDynastylength = uint8(activeSetPerDynasty[dynasty].length);

            for (uint256 i = 0; i < activeSetPerDynastylength; i++) {
                uint32 id = activeSetPerDynasty[dynasty][i];
                activeSetPerDynastylength = uint8(activeSetPerDynasty[dynasty].length);
                uint256 withdrawAfter = stakeManager.getWithdrawAfterPerValidator(id);
                //slither-disable-next-line timestamp,incorrect-equality
                if (withdrawAfter <= dynasty && withdrawAfter != 0) {
                    if (validatorsChurnedOut == numValidatorsToChurnOut) {
                        isValidatorSelectedPerDynasty[id][dynasty] = true;
                        continue;
                    }
                    if (isChurnedOut[dynasty][id]) continue;
                    activeSetPerDynasty[dynasty][i] = activeSetPerDynasty[dynasty][activeSetPerDynastylength - 1];
                    activeSetPerDynasty[dynasty].pop();
                    churnedOutValidators[dynasty].push(id);
                    isChurnedOut[dynasty][id] = true;
                    validatorsChurnedOut++;
                } else {
                    isValidatorSelectedPerDynasty[id][dynasty] = true;
                }
            }
            // Step 2: Random Churn
            if (validatorsChurnedOut < numValidatorsToChurnOut) {
                uint256 randVal = Random.prng(activeSetPerDynastylength, blockhash(block.number - 1));
                uint32 randomChurn = activeSetPerDynasty[dynasty][randVal];
                activeSetPerDynasty[dynasty][randVal] = activeSetPerDynasty[dynasty][activeSetPerDynastylength - 1];
                activeSetPerDynasty[dynasty].pop();
                churnedOutValidators[dynasty].push(randomChurn);
                isChurnedOut[dynasty][randomChurn] = true;
                isValidatorSelectedPerDynasty[randomChurn][dynasty] = false;
                validatorsChurnedOut++;
            }

            return validatorsChurnedOut;
        }
        return 0;
    }

    /**
     * @dev inserts the validator in the approporiate place based on the iteration of the validator. The validator
     * with the lowest iteration is given a higher priority
     * @param validatorId id of the validator
     * @param iteration iteration calculated off chain by validator nodes
     * @param biggestValidatorStake the stake of the validator with the largest stake
     * @param dynasty current dynasty
     * @return isAdded : whether the validator was added to the active set
     */
    function _insertAppropriately(uint32 validatorId, uint256 iteration, uint256 biggestValidatorStake, uint256 dynasty)
        internal
        returns (bool isAdded)
    {
        uint8 activeSetPerDynastylength = uint8(activeSetPerDynasty[dynasty].length);
        uint8 churnedOutValidatorslength = uint8(churnedOutValidators[dynasty].length);
        uint8 numValidatorsAlreadySelected = 0;

        if (churnedOutValidatorslength != 0) {
            numValidatorsAlreadySelected = uint8(numParticipantsPerDynasty[dynasty] - churnedOutValidatorslength);
        }

        if (activeSetPerDynastylength == numValidatorsAlreadySelected) {
            activeSetPerDynasty[dynasty].push(validatorId);
            isValidatorSelectedPerDynasty[validatorId][dynasty] = true;
            biggestStakePerDynasty[dynasty] = biggestValidatorStake;
            return true;
        }

        if (biggestStakePerDynasty[dynasty] > biggestValidatorStake) {
            return false;
        }

        if (biggestStakePerDynasty[dynasty] < biggestValidatorStake) {
            for (uint8 i = activeSetPerDynastylength; i > numValidatorsAlreadySelected; i--) {
                isValidatorSelectedPerDynasty[activeSetPerDynasty[dynasty][i - 1]][dynasty] = false;
                activeSetPerDynasty[dynasty].pop();
            }
            activeSetPerDynasty[dynasty].push(validatorId);
            isValidatorSelectedPerDynasty[validatorId][dynasty] = true;
            biggestStakePerDynasty[dynasty] = biggestValidatorStake;

            return true;
        }

        for (uint8 i = numValidatorsAlreadySelected; i < activeSetPerDynastylength; i++) {
            if (validatorIterationPerDynasty[activeSetPerDynasty[dynasty][i]][dynasty] > iteration) {
                activeSetPerDynasty[dynasty].push(validatorId);
                isValidatorSelectedPerDynasty[validatorId][dynasty] = true;

                activeSetPerDynastylength = activeSetPerDynastylength + 1;

                for (uint256 j = activeSetPerDynastylength - 1; j > i; j--) {
                    activeSetPerDynasty[dynasty][j] = activeSetPerDynasty[dynasty][j - 1];
                }

                activeSetPerDynasty[dynasty][i] = validatorId;

                if (activeSetPerDynasty[dynasty].length > numParticipantsPerDynasty[dynasty]) {
                    isValidatorSelectedPerDynasty[activeSetPerDynasty[dynasty][activeSetPerDynasty[dynasty].length - 1]][dynasty] = false;
                    activeSetPerDynasty[dynasty].pop();
                }

                return true;
            }
        }
        // Worst Iteration and for all other blocks, influence was >=
        if (activeSetPerDynasty[dynasty].length < numParticipantsPerDynasty[dynasty]) {
            activeSetPerDynasty[dynasty].push(validatorId);
            isValidatorSelectedPerDynasty[validatorId][dynasty] = true;

            return true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title RAZOR
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */

contract BridgeToken is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("BridgeToken", "BRIDGE") {
        _mint(msg.sender, 1e25);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

contract MockSource {
    struct Value {
        int8 power;
        uint16 collectionId;
        bytes32 name;
        uint256 value;
    }

    Value public value;

    function setResult() external {
        value = Value(-2, 1, keccak256("collectionName"), 12000);
    }

    function getResult() external view returns (Value memory) {
        return value;
    }
}