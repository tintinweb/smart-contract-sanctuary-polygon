// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Base/RegisterableUpgradeableBase.sol";
import "../Interfaces/IGameTreasury.sol";

error NonceAlreadyUsed();
error NotEnoughClock();
error RunAlreadyStarted();
error SenderIsNotReceiver();
error CryptoRunnerTokenIdNotMatched();
error DeadlineMissed();
error RunAlreadyEnded();
error CryptoRunnerAlreadyRunning();
error CryptoRunnerNotRunning();
error RunIdDoesNotMatch();
error GameplayIsPaused();

/**
@title 2112 Crypto Runner State Contract
@author 2112.run
@notice This contract holds the state of runners and existing runs
*/
contract CryptoRunnerState is RegisterableUpgradeableBase {
    /**
    @notice Structure which holds a Crypto Runner's state
    @dev The "initialized" field is required because tokenIds start at 0
     */
    struct CryptoRunner {
        /**
        @notice Whether the runner is in a run
        */
        bool isRunning;
        /**
        @notice This is used because Crypto Runners start with tokenId 0 so we can't use that as a way to verify usage
        */
        bool initialized;
        /**
        @notice The tokenId of the runner
        @dev Ownership is not verified on chain because runners are on L1 so we require a signature
        */
        uint256 tokenId;
        /**
        @notice Notoriety Points which are translated into levels by the consumer
        */
        uint256 notorietyPoints;
        /**
        @notice Remaining Clock which is calculated every block
        */
        uint256 remainingClock;
        /**
        @notice Runner's current run's ID
        @dev Should be empty if not running
        */
        string currentRunId;
        /**
        @notice Finished Run ID list
        */
        string[] finishedRuns;
    }
    /**
    @notice Structure of a Run
    @dev Not having a "startTime" or "runId" means it does not exist. Having an "endTime" means it finished
    */
    struct Run {
        /**
        @notice The run's ID
        */
        string runId;
        /**
        @notice The Crypto Runner that this run belongs to
        */
        uint256 tokenId;
        /**
        @notice The Notoriety Points gained from this run
        */
        uint256 notorietyPoints;
        /**
        @notice The clock requirement of this run
        */
        uint256 requiredClock;
        /**
        @notice The $DATA earned by this run
        */
        uint256 data;
        /**
        @notice Start time of the run
        */
        uint256 startTime;
        /**
        @notice End time of the run
        */
        uint256 endTime;
    }
    /**
    @notice Value used to set a Crypto Runner's clock in their first run
    */
    uint256 public initialClock;
    /**
    @notice The maximum clock a Crypto Runner can have
    */
    uint256 public maxClock;
    /**
    @notice Used to toggle gameplay
    */
    bool public isGameplayEnabled;
    /**
    @notice Mapping of Run ID to whether it has been used
    */
    mapping(string => bool) public usedRunIds;
    /**
    @notice Mapping of Runs by their ID
    */
    mapping(string => Run) public runsById;
    /**
    @notice Map of Crypto Runners by their tokenId
    @dev When not initialized, default value of the tokenId field is 0
    */
    mapping(uint256 => CryptoRunner) public cryptoRunners;
    /**
    @notice Emitted when a run starts
    @param sender Address of msg.sender
    @param tokenId The Crypto Runner's tokenId
    @param runId ID of the run that started
    */
    event RunStarted(address indexed sender, uint256 tokenId, string runId);
    /**
    @notice Emitted when a run ends
    @param to Address that will receive DATA that should match msg.sender
    @param tokenId The Crypto Runner's tokenId
    @param runId ID of the run that ended
    */
    event RunEnded(address indexed to, uint256 tokenId, string runId);
    /**
    @notice Emitted when the value of "initialClock" is changed
    @param sender Address of msg.sender
    @param previousAmount The previous amount of clock
    @param newAmount The new initial clock amount
    */
    event InitialClockChanged(address indexed sender, uint256 previousAmount, uint256 newAmount);
    /**
    @notice Emitted when the value of "maxClock" is changed
    @param sender Address of msg.sender
    @param previousAmount The previous maximum clock a runner can have
    @param newAmount The new maximum clock a runner can have
    */
    event MaxClockChanged(address indexed sender, uint256 previousAmount, uint256 newAmount);
    /**
    @notice Emitted when toggling gameplay on or off
    @param sender Address of msg.sender
    @param isGameplayEnabled gamplay enabled or not
    */
    event GameplayEnabledChanged(address indexed sender, bool isGameplayEnabled);
    /**
    @notice Used to restrict function calls depending on whether gameplay is enabled or not
    */
    modifier onlyGameplayEnabled() {
        if(!isGameplayEnabled)
            revert GameplayIsPaused();
        _;
    }
    /**
    @notice Function used to initialize the contract
    @dev Used instead of a constructor because of UUPSUpgradeable
    @param registry_ Address of the registry contract used to resolve ecosystem contracts
    @param initialClock_ The "initialClock" amount
    @param maxClock_ The maximum clock a Crypto Runner can reach
    @param isGameplayEnabled_ Whether Gameplay should be enabled immediately
    @param signature_ Signature from deployer for Registry
    */
    function initialize(
        address registry_,
        uint256 initialClock_,
        uint256 maxClock_,
        bool isGameplayEnabled_,
        uint256 nonce_,
        bytes memory signature_
    ) public initializer {
        __RegisterableUpgradeableBase_init(Constants.CRYPTO_RUNNER_STATE, registry_, nonce_, signature_);
        initialClock = initialClock_;
        maxClock = maxClock_;
        isGameplayEnabled = isGameplayEnabled_;
    }
    /**
    @notice Toggle gameplay
    @param isGameplayEnabled_ Bool "true" to enable gameplay or "false" to turn it off
    */
    function setIsGameplayEnabled(bool isGameplayEnabled_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isGameplayEnabled = isGameplayEnabled_;
        emit GameplayEnabledChanged(msg.sender, isGameplayEnabled_);
    }
    /**
    @notice Change the value of the initial clock an unused CryptoRunner will have
    @dev Requires that "msg.sender" has the "DEFAULT_ADMIN_ROLE"
    @param initialClockAmount_ The new amount of initial clock
    */
    function setInitialClock(uint256 initialClockAmount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 previousAmount = initialClock;
        initialClock = initialClockAmount_;
        emit InitialClockChanged(msg.sender, previousAmount, initialClockAmount_);
    }
    /**
    @notice Change the max clock that Crypto Runners can accrue
    @dev Requires that "msg.sender" has the "DEFAULT_ADMIN_ROLE"
    @param maxClock_ The new maximum clock
    */
    function setMaxClock(uint256 maxClock_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 previousAmount = maxClock;
        maxClock = maxClock_;
        emit MaxClockChanged(msg.sender, previousAmount, maxClock_);
    }
    /**
    @notice Starting a run, callable by players
    @dev Validates input data by using a signature that must be from "SIGNER_ROLE"
    @param data_ Bytes data containing the signature and arguments to start a run
    bytes: Signature
    uint256[]:
        0: Token Id
        1: Required Clock
        2: Nonce
        3: Deadline
    bytes32: Run ID
    @return the updated Crypto Runner
    */
    function startRun(bytes calldata data_) external onlyGameplayEnabled() returns (CryptoRunner memory) {
        (uint256[] memory runArgs, string memory runId) = _startRunArgs(data_);
        CryptoRunner memory cryptoRunner = cryptoRunners[runArgs[0]];
        if(cryptoRunner.isRunning)
            revert CryptoRunnerAlreadyRunning();
        if (!cryptoRunner.initialized) {
            cryptoRunner.initialized = true;
            cryptoRunner.tokenId = runArgs[0];
            if(initialClock < runArgs[1])
                revert NotEnoughClock();
            cryptoRunner.remainingClock = initialClock - runArgs[1];
        } else {
            cryptoRunner.remainingClock = _hasEnoughClock(runArgs[0], runArgs[1]);
        }
        runsById[runId] = Run(runId, runArgs[0], 0, runArgs[1], 0, block.timestamp, 0);
        cryptoRunner.isRunning = true;
        cryptoRunner.currentRunId = runId;
        cryptoRunners[runArgs[0]] = cryptoRunner;
        emit RunStarted(msg.sender, runArgs[0], runId);
        return cryptoRunner;
    }
    /**
    @notice Ending a run, callable by players
    @dev Validates input data by using a signature that must be from "SIGNER_ROLE"
    @param data_ Bytes data containing the signature and arguments to end a run
    bytes: Signature
    uint256[]:
        0: Token Id
        1: Notoriety Points
        2: DATA
        3: Nonce
        4: Deadline
    string: Run Id
    address: To
    */
    function endRun(bytes calldata data_) external onlyGameplayEnabled() {
        (uint256[] memory runArgs, string memory runId, address to) = _endRunArgs(data_);
        CryptoRunner memory cryptoRunner = cryptoRunners[runArgs[0]];
        Run memory run = runsById[runId];
        if(cryptoRunner.tokenId != runArgs[0])
            revert CryptoRunnerTokenIdNotMatched();
        if(msg.sender != to)
            revert SenderIsNotReceiver();
        if(run.endTime != 0)
            revert RunAlreadyEnded();
        if(!cryptoRunner.isRunning)
            revert CryptoRunnerNotRunning();
        if(keccak256(bytes(cryptoRunner.currentRunId)) != keccak256(bytes(runId)))
            revert RunIdDoesNotMatch();
        run.endTime = block.timestamp;
        run.notorietyPoints = runArgs[1];
        run.data = runArgs[2];
        runsById[runId] = run;
        cryptoRunner.isRunning = false;
        delete cryptoRunner.currentRunId;
        cryptoRunner.notorietyPoints += runArgs[1];
        cryptoRunners[runArgs[0]] = cryptoRunner;
        cryptoRunners[runArgs[0]].finishedRuns.push(runId);
        if (runArgs[2] > 0) {
            _transferData(to, runArgs[2]);
        }
        emit RunEnded(to, runArgs[0], runId);
    }
    /**
    @notice Retrieve a tokenIds that are running
    @param tokenIds_ The tokenIds to check
    @return List of tokenIds that are running
    */
    function getRunningTokenIds(uint256[] calldata tokenIds_) external view returns (uint256[] memory) {
        uint256[] memory runningIds = new uint256[](tokenIds_.length);
        uint256 index = 0;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (isRunning(tokenIds_[i])) {
                runningIds[index++] = tokenIds_[i];
            }
        }
        return runningIds;
    }
    /**
    @notice Get all runIds of a Crypto Runner
    @param tokenId_ The tokenId of the Crypto RUnner
    @return A list of runIds
    */
    function getRunsByRunner(uint256 tokenId_) external view returns (string[] memory) {
        if(!cryptoRunners[tokenId_].isRunning)
            return cryptoRunners[tokenId_].finishedRuns;

        uint256 allRunsCount = cryptoRunners[tokenId_].finishedRuns.length + 1;
        string[] memory runs = new string[](allRunsCount);
        for (uint256 i = 0; i < allRunsCount; i++) {
            if(i == allRunsCount - 1)
                runs[i] = cryptoRunners[tokenId_].currentRunId;
            else
                runs[i] = cryptoRunners[tokenId_].finishedRuns[i];
        }
        return runs;
    }
    /**
    @notice Get all the Crypto Runners from a list of tokenIds
    @param tokenIds_ The list of tokenIds of runners
    @return A list of Crypto Runners
    */
    function getRunners(uint256[] memory tokenIds_) external view returns (CryptoRunner[] memory) {
        CryptoRunner[] memory runners = new CryptoRunner[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            runners[i] = getRunner(tokenIds_[i]);
        }
        return runners;
    }
    /**
    @notice Check if a specific Crypto Runner is currently in a run
    @param tokenId_ The tokenId of the Crypto Runner
    @return Whether it is running
    */
    function isRunning(uint256 tokenId_) public view returns (bool) {
        return cryptoRunners[tokenId_].isRunning;
    }
    /**
    @notice Get a run by it's ID
    @param runId_ The ID of the run to retrieve
    @return The run
    */
    function getRun(string memory runId_) external view returns (Run memory) {
        return runsById[runId_];
    }
    /**
    @notice Get one Crypto Runner by ID
    @param tokenId_ The Crypto Runner's tokenId
    @return runner
    */
    function getRunner(uint256 tokenId_) public view returns (CryptoRunner memory runner) {
        runner = cryptoRunners[tokenId_];
        if (!runner.initialized) {
            runner.tokenId = tokenId_;
        }
        runner.remainingClock = getClock(tokenId_);
    }
    /**
    @notice Get a CryptoRunner's current Clock
    @dev We calculate the clock because we don't actually update it until there is a transaction to start a run
    @return The amount of Clock
    */
    function getClock(uint256 tokenId_) public view returns (uint256) {
        CryptoRunner memory cryptoRunner = cryptoRunners[tokenId_];
        uint256 secondsForRegen;
        if(!cryptoRunner.initialized) {
            return initialClock;
        } else if(cryptoRunner.isRunning) {
            secondsForRegen = block.timestamp - runsById[cryptoRunner.currentRunId].startTime;

        } else {
            secondsForRegen = block.timestamp - runsById[cryptoRunner.finishedRuns[cryptoRunner.finishedRuns.length - 1]].startTime;
        }
        uint256 totalClock = (secondsForRegen * maxClock / 86400) + cryptoRunner.remainingClock;
        return totalClock > maxClock ? maxClock : totalClock;
    }
    /**
    @notice Check whether a Crypto Runner has enough Clock for a run
    @param tokenId_ The CryptoRunner's Token ID
    @param requiredClock_ The amount of clock required for the run
    @return remainingClock of the Crypto Runner
    */
    function _hasEnoughClock(uint256 tokenId_, uint256 requiredClock_) internal view returns (uint256 remainingClock) {
        uint256 redeemableClock = getClock(tokenId_);
        if(redeemableClock < requiredClock_)
            revert NotEnoughClock();
        return redeemableClock - requiredClock_;
    }
    /**
    @notice Parse arguments that are used to start a run
    @dev We check the signature to ensure that arguments are not tampered
    @param data_ The bytes data that contains the signature and arguments
    @return Array with Token Id, Required Clock, Nonce, and Deadline. String of Run ID
    */
    function _startRunArgs(bytes memory data_) internal returns (uint256[] memory, string memory) {
        (bytes memory signature, uint256[] memory args, string memory runId) = abi.decode(
            data_,
            (bytes, uint256[], string)
        );
        _isValidSignature(signature, args[2], abi.encodePacked(args, runId));
        if(block.timestamp > args[3])
            revert DeadlineMissed();
        if(runsById[runId].startTime != 0)
            revert RunAlreadyStarted();

        return (args, runId);
    }
    /**
    @notice Parse arguments that are used to end a run
    @dev We check the signature to ensure that arguments are not tampered
    @param data_ The bytes data that contains the signature and arguments
    @return Array with Token Id, Notoriety Points, DATA, Nonce, and Deadline. String of Run ID and address of player
    */
    function _endRunArgs(bytes calldata data_)
        internal
        returns (
            uint256[] memory,
            string memory,
            address
        )
    {
        (bytes memory signature, uint256[] memory args, string memory runId, address to) = abi.decode(
            data_,
            (bytes, uint256[], string, address)
        );
        _isValidSignature(signature, args[3], abi.encodePacked(args, runId, to));
        if(block.timestamp > args[4])
            revert DeadlineMissed();

        return (args, runId, to);
    }
    /**
    @notice Call the Treasury to transfer $DATA rewards to players
    @param to_ Player
    @param amount_ $DATA reward
    */
    function _transferData(address to_, uint256 amount_) private {
        IGameTreasury treasury = IGameTreasury(registry.getEntry(Constants.GAME_TREASURY));
        treasury.transferRewards(to_, amount_);
    }

    /**
    @dev Reserved storage to allow layout changes
    */
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./UpgradeableBase.sol";

error RegistryAddressCannotBeZero();

/**
@title 2112 Registerable Upgradeable Base
@author 2112.run
@notice Enables registration with the ecosystem's Registry
@dev Uses UUPS proxy for upgrades and requires roles for different admin functions
*/
abstract contract RegisterableUpgradeableBase is UpgradeableBase {
    /**
    @notice Registry
    */
    IRegistry internal registry;
    /**
    @notice Emitted once the Registry address is changed
    @param sender The msg.sender
    @param previousRegistry The previous Registry address
    @param newRegistry The new Registry address
    */
    event RegistryChanged(address indexed sender, address previousRegistry, address newRegistry);
    /**
    @notice Setting the Registry address of the ecosystem
    @param registry_ The registry's address
    */
    function setRegistry(address registry_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(registry_ == address(0))
            revert RegistryAddressCannotBeZero();
        address previousRegistry = address(registry);
        registry = IRegistry(registry_);
        emit RegistryChanged(msg.sender, previousRegistry, registry_);
    }
    /**
    @notice Register with Registry
    @param key_ Key to register with
    @param registry_ The registry's address
    @param nonce_ Prevent re-using signature
    @param signature_ Used to validate the whether the caller can register
    */
    function __RegisterableUpgradeableBase_init(bytes32 key_, address registry_, uint256 nonce_, bytes memory signature_) internal {
        __UpgradeableBase_init();
        registry = IRegistry(registry_);
        registry.register(key_, nonce_, signature_);
    }
    /**
    @notice Calls init
    @param key_ Key to register with
    @param registry_ The registry's address
    @param nonce_ Prevent re-using signature
    @param signature_ Used to validate the whether the caller can register
    */
    function __RegisterableUpgradeableBase_init_unchained(bytes32 key_, address registry_, uint256 nonce_, bytes memory signature_) internal {
        __RegisterableUpgradeableBase_init(key_, registry_, nonce_, signature_);
    }
    /**
    @dev Reserved storage to allow layout changes
    */
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IGameTreasury {
    event OperatorApproval(address indexed sender, address indexed operator, bool approved);
    event RewardTransferred(address indexed sender, address indexed beneficiary, uint256 amount);

    function approve(address operator_, bool approved_) external;
    function isApproved(address operator_) external view returns (bool);
    function setMaximumReward(uint256 maximumReward_) external;
    function transferRewards(address to_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../Interfaces/IRegistry.sol";
import "../Interfaces/IDATA.sol";
import "../Libraries/Constants.sol";

error SignatureMismatch();
error NonceUsed();

/**
@title 2112 Base Upgradeable Contract
@author 2112.run
@notice Provides common initialization for upgradeable contracts in the 2112 ecosystem
*/
abstract contract UpgradeableBase is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;
    /**
    @notice DATA reference to be used by implementations
    @dev the address is not set by default and must be set by implementer
    */
    IDATA internal data;
    /**
    @notice Keep track of nonces to avoid hijacking
    */
    mapping(uint256 => bool) internal nonces;
    /**
    @notice Used to initialize upgradeable contracts and grant roles
    @dev Initializer
    */
    function __UpgradeableBase_init() internal {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, Constants.MULTI_SIG);
        _grantRole(Constants.UPGRADER_ROLE, msg.sender);
        _grantRole(Constants.SIGNER_ROLE, Constants.SIGNER);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    /**
    @dev Initializer
    */
    function __UpgradeableBase_init_unchained() internal {
        __UpgradeableBase_init();
    }
    /**
    @notice Function required by UUPSUpgradeable in order to authorize upgrades
    @dev Only "UPGRADER_ROLE" addresses can perform upgrades
    @param newImplementation The address of the new implementation contract for the upgrade
    */
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(Constants.UPGRADER_ROLE) {}
    /**
    @notice Validate a signature and check whether the signer has the "SIGNER_ROLE"
    @param signature_ Signed hash
    @param encodedArgs_ Arguments to validate
    */
    function _isValidSignature(bytes memory signature_, uint256 nonce_, bytes memory encodedArgs_) internal {
        bytes32 msgHash = keccak256(encodedArgs_);
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        if(nonces[nonce_])
            revert NonceUsed();
        if(!hasRole(Constants.SIGNER_ROLE, (signedHash.recover(signature_))))
            revert SignatureMismatch();
        nonces[nonce_] = true;
    }
    /**
    @notice Validate a signature and check whether the signer has the "UPGRADER_ROLE"
    @param signature_ Signed hash
    @param encodedArgs_ Arguments to validate
    @return The address of the signer
    */
    function _isUpgrader(bytes memory signature_, uint256 nonce_, bytes memory encodedArgs_) internal returns (address) {
        bytes32 msgHash = keccak256(encodedArgs_);
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        address signer = signedHash.recover(signature_);
        if(!hasRole(Constants.UPGRADER_ROLE, signer))
            revert SignatureMismatch();
        if(nonces[nonce_])
            revert NonceUsed();
        nonces[nonce_] = true;
        return signer;
    }
    /**
    @dev Reserved storage to allow layout changes
    */
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRegistry {
    event EntryChanged(address indexed sender, bytes32 key, address previousAddress, address newAddress);
    event EntryRemoved(address indexed sender, bytes32 key, address previousAddress);
    event Registered(address indexed sender, bytes32 key, address newAddress);

    function setEntry(bytes32 key_, address address_) external;
    function removeEntry(bytes32 key_) external;
    function getEntry(bytes32 key_) external view returns (address);
    function getKey(address address_) external view returns (bytes32);
    function register(bytes32 key_, uint256 nonce_, bytes memory signature_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDATA {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
/**
@title 2112 Constants
@author 2112.run
@notice This library is used by the ecosystem to provide constant values
*/
library Constants {
    address internal constant MULTI_SIG           = 0xF62C299AAA62E57003594ee26d6870B2BD15010A;
    address internal constant LIQUIDITY_PROVIDER  = 0x23Dd037dD2cda90b8f208274240fB385D4aD5c20;
    address internal constant SIGNER              = 0xB0F3B0aa2f7FbBBE4d309e60e1B07fD7513cE534;
    bytes32 internal constant UPGRADER_ROLE       = keccak256("UPGRADER_ROLE");
    bytes32 internal constant SIGNER_ROLE         = keccak256("SIGNER_ROLE");
    bytes32 internal constant GAME_TREASURY       = keccak256("GameTreasury");
    bytes32 internal constant DATA                = keccak256("Data");
    bytes32 internal constant REGISTRY            = keccak256("Registry");
    bytes32 internal constant CRYPTO_RUNNER_STATE = keccak256("CryptoRunnerState");
    bytes32 internal constant COMMUNITY_TREASURY  = keccak256("CommunityTreasury");
    bytes32 internal constant VESTING             = keccak256("Vesting");
    bytes32 internal constant AIRDROPS            = keccak256("Airdrops");
    uint256 internal constant UINT256_MAX         = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant DECIMALS_18         = 1000000000000000000;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}