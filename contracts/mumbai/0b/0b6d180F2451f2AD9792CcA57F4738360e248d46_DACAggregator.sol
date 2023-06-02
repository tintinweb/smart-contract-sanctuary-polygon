// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/// @dev Used for registering an Upkeep
struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}
/// @dev Used for transmitting information about a specific Upkeep
struct UpkeepInfo {
    address target;
    uint32 executeGas;
    bytes checkData;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    uint32 lastPerformBlockNumber;
    uint96 amountSpent;
    bool paused;
    bytes offchainConfig;
}

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

interface KeeperRegistryInterface {
    function addFunds(uint256 id, uint96 amount) external;

    function withdrawFunds(uint256 id, address to) external;

    function cancelUpkeep(uint256 id) external;

    function getUpkeep(
        uint256 id
    ) external view returns (UpkeepInfo memory upkeepInfo);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DACProject.sol";
import "./DACContributorAccount.sol";

/**
 * @title DAC (Decentralized Autonomous Crowdfunding) Factory
 * @author polarzero
 * @notice ...
 * @dev ...
 */

contract DACAggregator {
    /* -------------------------------------------------------------------------- */
    /*                                CUSTOM ERRORS                               */
    /* -------------------------------------------------------------------------- */

    /// @dev This function can only be called by the owner of the contract
    error DACAggregator__NOT_OWNER();
    /// @dev The transfer failed
    error DACAggregator__TRANSFER_FAILED();

    /**
     * @dev submitProject()
     */

    /// @dev The length of the collaborators and shares arrays should be the same
    error DACAggregator__INVALID_LENGTH();
    /// @dev The collaborators array should include the initiator
    error DACAggregator__DOES_NOT_INCLUDE_INITIATOR();
    /// @dev The total shares should be 100
    error DACAggregator__INVALID_SHARES();
    /// @dev The name should be at least 2 characters and at most 50 characters
    error DACAggregator__INVALID_NAME();

    /**
     * @dev createContributorAccount()
     */

    /// @dev The contributor account already exists
    error DACAggregator__ALREADY_EXISTS();
    /// @dev The payment interval is too short or too long
    error DACAggregator__INVALID_PAYMENT_INTERVAL();

    /**
     * @dev pingProject()
     */

    /// @dev The project doesn't exist
    error DACAggregator__DOES_NOT_EXIST();
    /// @dev The caller is not a collaborator of the project
    error DACAggregator__NOT_COLLABORATOR();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted when a project is submitted to the DAC process
    /// @dev See the struct `Project` for more details about the parameters
    /// @dev See the function `submitProject()` for more details about the process
    /// @param project The struct of the project that was submitted
    event DACAggregator__ProjectSubmitted(Project project);

    /// @dev Emitted when a contributor account is created
    /// @dev See the struct `ContributorAccount` for more details about the parameters
    /// @dev See the function `createContributorAccount()` for more details about the process
    /// @param owner The address of the owner of the contributor account
    /// @param contributorAccountContract The address of the contributor account contract
    event DACAggregator__ContributorAccountCreated(
        address owner,
        address contributorAccountContract
    );

    /// @dev Emitted when a project is updated (pinged by a collaborator)
    /// @param projectAddress The address of the project contract
    /// @param collaborator The address of the collaborator who pinged the project
    event DACAggregator__ProjectPinged(
        address projectAddress,
        address collaborator
    );

    /// @dev Emitted when the maximum amount of contributions is updated
    /// @param maxContributions The new maximum amount of contributions
    event DACAggregator__MaxContributionsUpdated(uint256 maxContributions);

    /// @dev Emitted when the maximum gas limit for upkeep calls is updated
    /// @param upkeepGasLimit The new maximum gas limit for upkeep calls
    event DACAggregator__UpkeepGasLimitUpdated(uint32 upkeepGasLimit);
    /// @dev Emitted when the approximate native token / LINK rate is updated
    /// @param nativeTokenLinkRate The new approximate native token / LINK rate
    event DACAggregator__NativeTokenLinkRateUpdated(
        uint256 nativeTokenLinkRate
    );
    /// @dev Emitted when the premium % of this chain is updated
    /// @param premiumPercent The new premium % for this chain
    event DACAggregator__PremiumPercentUpdated(uint256 premiumPercent);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev The address of the owner (deployer) of this contract
    address private immutable i_owner;

    /// @dev Chainlink addresses: LINK token
    address private immutable i_linkTokenAddress;
    /// @dev Chainlink addresses: Keeper Registrar
    address private immutable i_keeperRegistrarAddress;
    /// @dev Chainlink addresses: Keeper Registry
    address private immutable i_keeperRegistryAddress;

    /// @dev The maximum amount of contributions for a contributor account
    uint256 private s_maxContributions;
    /// @dev The approximate native token / LINK rate
    uint256 private s_nativeTokenLinkRate;
    /// @dev The premium % of this chain
    uint32 private s_premiumPercent;
    /// @dev The maximum gas limit for upkeep calls
    uint32 private s_upkeepGasLimit;

    /// @dev The array of projects
    // Project[] private s_projects;
    /// @dev The array of contributor accounts
    // ContributorAccount[] private s_contributorAccounts;
    /// @dev The mapping of project contract addresses to their project information
    mapping(address => Project) private s_projects;
    /// @dev The mapping of contributor addresses to their account (contract) address
    mapping(address => address) private s_contributorAccounts;

    /// @dev A project that was submitted to the DAC process
    /// @param collaborators The addresses of the collaborators (including the initiator)
    /// @param shares The shares of each collaborator (in the same order as the collaborators array)
    /// @param projectContract The address of the child contract for this project
    /// @param initiator The address of the initiator of this project
    /// @param createdAt The timestamp of when the project was submitted
    /// @param name The name of the project
    /// @param description A short description of the project
    /// @dev See the `submitProject()` function for more details
    struct Project {
        address[] collaborators;
        uint256[] shares;
        address projectContract;
        address initiator;
        uint256 createdAt;
        uint256 lastActivityAt;
        string name;
        string description;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Restricts the access to the owner of the contract
     */

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert DACAggregator__NOT_OWNER();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice The constructor of the DAC aggregator contract
     * @param _linkTokenAddress The address of the LINK token
     * @param _keeperRegistrarAddress The address of the Keeper Registrar
     * @param _keeperRegistryAddress The address of the Keeper Registry
     * @param _maxContributions The maximum amount of contributions for a contributor account
     * @param _nativeTokenLinkRate The approximate native token / LINK rate
     * @param _premiumPercent The premium % of this chain
     * @param _upkeepGasLimit The maximum gas limit for upkeep calls
     */

    constructor(
        address _linkTokenAddress,
        address _keeperRegistrarAddress,
        address _keeperRegistryAddress,
        uint256 _maxContributions,
        uint256 _nativeTokenLinkRate,
        uint32 _premiumPercent,
        uint32 _upkeepGasLimit
    ) {
        // Set the deployer
        i_owner = msg.sender;

        // Set the Chainlink addresses
        i_linkTokenAddress = _linkTokenAddress;
        i_keeperRegistrarAddress = _keeperRegistrarAddress;
        i_keeperRegistryAddress = _keeperRegistryAddress;

        // Set the storage variables
        s_maxContributions = _maxContributions;
        s_nativeTokenLinkRate = _nativeTokenLinkRate;
        s_premiumPercent = _premiumPercent;
        s_upkeepGasLimit = _upkeepGasLimit;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Submits a project to the DAC process
     * @param _collaborators The addresses of the collaborators (including the initiator)
     * @param _shares The shares of each collaborator (in the same order as the collaborators array)
     * @param _name The name of the project
     * @param _description A short description of the project
     * @dev Note the following requirements:
     * - The initiator should be included in the collaborators array
     * - The shares should add up to 100
     * - The timespan should be at least 30 days
     * - The name should be at least 2 characters and at most 50 characters
     * - The description is optional
     * @dev This will create a child contract for the project with the current parameters
     */

    function submitProject(
        address[] memory _collaborators,
        uint256[] memory _shares,
        string memory _name,
        string memory _description
    ) external {
        // It should have a share for each collaborator
        if (_collaborators.length != _shares.length)
            revert DACAggregator__INVALID_LENGTH();

        uint256 totalShares = 0;
        bool includesInitiator = false;
        for (uint256 i = 0; i < _collaborators.length; i++) {
            // Calculate the total shares
            totalShares += _shares[i];
            // Make sure the initiator is included
            if (_collaborators[i] == msg.sender) {
                includesInitiator = true;
            }
        }
        // It should include the initiator
        if (!includesInitiator)
            revert DACAggregator__DOES_NOT_INCLUDE_INITIATOR();
        // The total shares should be 100
        if (totalShares != 100) revert DACAggregator__INVALID_SHARES();

        // It should have a name of at least 2 characters and at most 50 characters
        if (bytes(_name).length < 2 || bytes(_name).length > 50)
            revert DACAggregator__INVALID_NAME();

        // Create a child contract for the project
        DACProject projectContract = new DACProject(
            _collaborators,
            _shares,
            msg.sender,
            _name,
            _description
        );

        Project memory project = Project(
            _collaborators,
            _shares,
            address(projectContract),
            msg.sender,
            block.timestamp,
            block.timestamp,
            _name,
            _description
        );

        // Add it to the projects array and mapping
        // s_projects.push(project);
        s_projects[address(projectContract)] = project;
        // Emit an event
        emit DACAggregator__ProjectSubmitted(project);
    }

    /**
     * @notice Create a contributor wallet
     * @param _paymentInterval The payment interval in seconds, meaning how frequently will the upkeep be called
     * A higher upkeep meaning a higher cost in LINK tokens
     * Minimum is 1 day (86400 seconds) and maximum is 30 days (2592000 seconds)
     * @dev This will create a child contract for the contributor, including a Chainlink upkeep
     * @dev This is kind of a smart contract wallet
     * @dev For more information, see the `DACContributorAccount` contract
     */

    function createContributorAccount(uint256 _paymentInterval) external {
        // It should not have a contributor account already
        if (s_contributorAccounts[msg.sender] != address(0))
            revert DACAggregator__ALREADY_EXISTS();

        // It should be at least 1 day and at most 30 days
        if (_paymentInterval < 1 days || _paymentInterval > 30 days)
            revert DACAggregator__INVALID_PAYMENT_INTERVAL();

        // Create a child contract for the contributor
        DACContributorAccount contributorContract = new DACContributorAccount(
            msg.sender,
            i_linkTokenAddress,
            i_keeperRegistrarAddress,
            i_keeperRegistryAddress,
            _paymentInterval,
            s_maxContributions,
            s_upkeepGasLimit
        );

        // Add it to the contributors array and mapping
        s_contributorAccounts[msg.sender] = address(contributorContract);

        emit DACAggregator__ContributorAccountCreated(
            msg.sender,
            address(contributorContract)
        );
    }

    /**
     * @notice Ping a project as a collaborator
     * @param _projectAddress The address of the project
     * @dev This will update the project's last activity timestamp
     * @dev It should be done by any of the collaborators at least once every 30 days so it can
     * keep receiving contributions
     */

    function pingProject(address _projectAddress) external {
        // It should be an existing project
        if (s_projects[_projectAddress].initiator == address(0))
            revert DACAggregator__DOES_NOT_EXIST();

        // It should be a collaborator
        if (!DACProject(payable(_projectAddress)).isCollaborator(msg.sender))
            revert DACAggregator__NOT_COLLABORATOR();

        // Update the project's last activity timestamp
        s_projects[_projectAddress].lastActivityAt = block.timestamp;
        // Emit an event
        emit DACAggregator__ProjectPinged(_projectAddress, msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   SETTERS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Update the maximum amount of contributions for a contributor account
     * @param _maxContributions The new maximum amount of contributions
     * @dev This will only affect new contributor accounts
     */

    function setMaxContributions(uint256 _maxContributions) external onlyOwner {
        s_maxContributions = _maxContributions;
        emit DACAggregator__MaxContributionsUpdated(_maxContributions);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GETTERS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Know if a project is active
     * @param _projectAddress The address of the project
     * @return bool Whether the project is active or not
     * @dev A project is active if it has been pinged by a collaborator during the last 30 days
     */

    function isProjectActive(
        address _projectAddress
    ) external view returns (bool) {
        return
            block.timestamp - s_projects[_projectAddress].lastActivityAt <
            30 days;
    }

    /**
     * @notice Returns the project information
     * @param _projectAddress The address of the project
     * @return struct The project
     */

    function getProject(
        address _projectAddress
    ) external view returns (Project memory) {
        return s_projects[_projectAddress];
    }

    /**
     * @notice Returns a specific contributor's account contract address
     * @param _contributor The address of the contributor
     * @return address The address of the contract of the contributor's account
     */

    function getContributorAccount(
        address _contributor
    ) external view returns (address) {
        return s_contributorAccounts[_contributor];
    }

    /**
     * @notice Returns the address of the owner of this contract
     * @return address The address of the owner
     */

    function getOwner() external view returns (address) {
        return i_owner;
    }

    /**
     * @notice Returns the maximum amount of contributions for a contributor account
     * @return uint256 The maximum amount of contributions
     */

    function getMaxContributions() external view returns (uint256) {
        return s_maxContributions;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   UPKEEP                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Update the native token / LINK rate
     * @param _rate The new rate
     */

    function setNativeTokenLinkRate(uint256 _rate) external onlyOwner {
        s_nativeTokenLinkRate = _rate;
        emit DACAggregator__NativeTokenLinkRateUpdated(_rate);
    }

    /**
     * @notice Update the premium % for this chain
     * @param _premium The new premium %
     */

    function setPremiumPercent(uint32 _premium) external onlyOwner {
        s_premiumPercent = _premium;
        emit DACAggregator__PremiumPercentUpdated(_premium);
    }

    /**
     * @notice Update the gas limit for an upkeep call
     * @param _gasLimit The new gas limit
     * @dev This will only affect new contributor accounts
     */

    function setUpkeepGasLimit(uint32 _gasLimit) external onlyOwner {
        s_upkeepGasLimit = _gasLimit;
        emit DACAggregator__UpkeepGasLimitUpdated(_gasLimit);
    }

    /**
     * @dev Calculate the approximate price of an upkeep based on the number of contributions
     * @param _upkeepGasLimit The gas limit of the upkeep (since we can't use the stored one, that could be updated here
     * but not on a previously created contributor account)
     * @return uint256 The approximate price of an upkeep
     */

    function calculateUpkeepPrice(
        uint32 _upkeepGasLimit
    ) external view returns (uint256) {
        // The formula is the following:
        // [gasUsed * gasPrice * (1 + premium%) + (80,000 * gasPrice)] * (NativeToken / LINK rate)
        // e.g. on Polygon Mumbai the premium is 429 % & the MATIC/LINK rate is ~ 1/7 (may 2023)

        // We need to assume a gas price, and should better use a high one
        uint256 gasPrice = 200 gwei;

        // Return the price
        return ((((_upkeepGasLimit * (gasPrice /* / 1e9 */)) *
            (1 + s_premiumPercent / 100) +
            (80_000 * (gasPrice /* / 1e9 */))) * (s_nativeTokenLinkRate)) /
            // / 100 because the native token / LINK rate has been multiplied by 100
            100);
    }

    /**
     * @notice Returns the address of the LINK token
     * @return address The address of the LINK token
     */

    function getLinkTokenAddress() external view returns (address) {
        return i_linkTokenAddress;
    }

    /**
     * @notice Returns the address of the Keeper Registrar
     * @return address The address of the Keeper Registrar
     */

    function getKeeperRegistrarAddress() external view returns (address) {
        return i_keeperRegistrarAddress;
    }

    /**
     * @notice Returns the address of the Keeper Registry
     * @return address The address of the Keeper Registry
     */

    function getKeeperRegistryAddress() external view returns (address) {
        return i_keeperRegistryAddress;
    }

    /**
     * @notice Get the native token / LINK rate
     * @return uint256 The native token / LINK rate
     */

    function getNativeTokenLinkRate() external view returns (uint256) {
        return s_nativeTokenLinkRate;
    }

    /**
     * @notice Get the premium % for this chain
     * @return uint256 The premium %
     */

    function getPremiumPercent() external view returns (uint32) {
        return s_premiumPercent;
    }

    /**
     * @notice Returns the gas limit for an upkeep call
     * @return uint32 The gas limit
     */

    function getUpkeepGasLimit() external view returns (uint32) {
        return s_upkeepGasLimit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface DACAggregatorInterface {
    function isProjectActive(
        address _projectAddress
    ) external view returns (bool);

    function calculateUpkeepPrice(
        uint32 _upkeepGasLimit
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ChainlinkManager.sol";
import "./DACAggregatorInterface.sol";

/**
 * @title DAC (Decentralized Autonomous Crowdfunding) Contributor account
 * @author polarzero
 * @notice ...
 */

contract DACContributorAccount is AutomationCompatibleInterface {
    LinkTokenInterface internal immutable LINK;
    KeeperRegistrarInterface internal immutable REGISTRAR;
    KeeperRegistryInterface internal immutable REGISTRY;
    DACAggregatorInterface internal immutable DAC_AGGREGATOR;

    /* -------------------------------------------------------------------------- */
    /*                                CUSTOM ERRORS                               */
    /* -------------------------------------------------------------------------- */

    /// @dev This function can only be called by the owner of the account
    error DACContributorAccount__NOT_OWNER();
    /// @dev The transfer failed
    error DACContributorAccount__TRANSFER_FAILED();

    /**
     * @dev Contributions
     */

    /// @dev The call to an external contract failed
    error DACContributorAccount__CALL_FAILED();
    /// @dev The contribution is already fully distributed
    error DACContributorAccount__CONTRIBUTION_ALREADY_DISTRIBUTED();
    /// @dev The project is not active anymore
    error DACContributorAccount__PROJECT_NOT_ACTIVE();
    /// @dev The amount sent is not correct
    error DACContributorAccount__INCORRECT_AMOUNT();
    /// @dev There are already too many contributions
    error DACContributorAccount__TOO_MANY_CONTRIBUTIONS();
    /// @dev The timestamp is in the past
    error DACContributorAccount__INVALID_TIMESTAMP();
    /// @dev There is no contribution to send (already fully distributed or the project is not active anymore)
    error DACContributorAccount__NO_CONTRIBUTION_TO_SEND();

    /**
     * @dev Upkeep
     */

    /// @dev An upkeep is already registered
    error DACContributorAccount__UPKEEP_ALREADY_REGISTERED();
    /// @dev The upkeep is not registered
    error DACContributorAccount__UPKEEP_NOT_REGISTERED();
    /// @dev The upkeep registration failed
    error DACContributorAccount__UPKEEP_REGISTRATION_FAILED();
    /// @dev The amount of LINK to fund the upkeep is too low
    error DACContributorAccount__FUNDING_AMOUNT_TOO_LOW();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Contributions
     */

    /// @dev Emitted when a new contribution is created
    /// @param projectContract The address of the project contract
    /// @param amount The amount of the contribution
    /// @param endDate The timestamp when the contribution ends
    event DACContributorAccount__ContributionCreated(
        address indexed projectContract,
        uint256 amount,
        uint256 endDate
    );

    /// @dev Emitted when a contribution is updated
    /// @param projectContract The address of the project contract
    /// @param amount The new amount of the contribution
    event DACContributorAccount__ContributionUpdated(
        address indexed projectContract,
        uint256 amount
    );

    /// @dev Emitted when a contribution is deleted
    /// @param projectContract The address of the project contract
    /// @param amount The amount of the contribution that is withdrawn
    event DACContributorAccount__ContributionCanceled(
        address indexed projectContract,
        uint256 amount
    );

    /// @dev Emitted when all the contributions are deleted
    /// @param contributions The structs of the contributions that are withdrawn
    /// @param amount The amount of the contributions that are withdrawn
    event DACContributorAccount__AllContributionsCanceled(
        Contribution[] contributions,
        uint256 amount
    );

    /// @dev Emitted when the contributions are sent to the projects
    /// @param contributions The structs of the contributions that are sent (minimized)
    event DACContributorAccount__ContributionsTransfered(
        ContributionMinimal[] contributions
    );

    /**
     * @dev Upkeep
     */

    /// @dev Emitted when the upkeep is registered
    /// @param upkeepId The ID of the upkeep
    /// @param interval The interval between each payment (upkeep)
    event DACContributorAccount__UpkeepRegistered(
        uint256 upkeepId,
        uint256 interval
    );

    /// @dev Emitted when the upkeep is funded
    /// @param sender The address that sent the LINK
    /// @param amount The amount of LINK sent to the upkeep
    event DACContributorAccount__UpkeepFunded(address sender, uint256 amount);

    /// @dev Emitted when the upkeep is canceled
    /// @param upkeepId The ID of the upkeep
    event DACContributorAccount__UpkeepCanceled(uint256 upkeepId);

    /// @dev Emitted when the upkeep funds are withdrawn
    /// @param upkeepId The ID of the upkeep
    event DACContributorAccount__UpkeepFundsWithdrawn(uint256 upkeepId);

    /// @dev Emitted when the upkeep interval is updated
    /// @param interval The new interval between each payment (upkeep)
    event DACContributorAccount__UpkeepIntervalUpdated(uint256 interval);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev The address of the owner of the account
    address private immutable i_owner;
    /// @dev The creation date of this account
    uint256 private immutable i_createdAt;
    /// @dev The maximum amount of contributions that can be stored in the account
    // This prevents the upkeeps from failing if the load were to be too high
    uint256 private immutable i_maxContributions;

    /// @dev The ID of the Chainlink Upkeep
    uint256 private s_upkeepId;
    /// @dev The gas limit of the Chainlink Upkeep
    uint32 private s_upkeepGasLimit;
    /// @dev The last time the contributions were sent to the supported projects though the upkeep
    uint256 private s_lastUpkeep;
    /// @dev The interval between each payment
    // The owner of the account can change this value, knowing that a smaller value will require more LINK
    uint256 private s_upkeepInterval;
    /// @dev Whether an upkeep is registered or not
    bool private s_upkeepRegistered;

    /// @dev The projects the account is contributing to
    Contribution[] private s_contributions;

    /// @dev The status and infos of a contribution
    /// @param projectContract The address of the project contract
    /// @param amountStored The amount of the contribution stored in the account
    /// @param amountDistributed The amount of the contribution that was already sent to the project
    /// @param startedAt The timestamp when the contribution started
    /// @param endsAt The timestamp when the contribution ends
    struct Contribution {
        address projectContract;
        uint256 amountStored;
        uint256 amountDistributed;
        uint256 startedAt;
        uint256 endsAt;
    }

    /// @dev The minimal infos of a contribution to prepare the upkeep
    /// @param projectContract The address of the project contract
    /// @param amount The amount of the contribution that should be sent (based on the current date, start and end date)
    /// @param index The index of the contribution in the array of contributions
    struct ContributionMinimal {
        address projectContract;
        uint256 amount;
        uint256 index;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Restricts the access to the initiator of the project
     */

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert DACContributorAccount__NOT_OWNER();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice The constructor of the account contract
     * @param _owner The address of the owner of the account
     * @param _linkToken The address of the LINK token
     * @param _registrar The address of the Chainlink Keeper Registrar
     * @param _registry The address of the Chainlink Keeper Registry
     * @param _paymentInterval The interval between each payment (upkeep)
     * @param _maxContributions The maximum amount of contributions that can be stored in the account
     * @param _upkeepGasLimit The gas limit for the Chainlink Upkeep
     * @dev This will register a new Chainlink Upkeep in the fly
     */
    constructor(
        address _owner,
        address _linkToken,
        address _registrar,
        address _registry,
        uint256 _paymentInterval,
        uint256 _maxContributions,
        uint32 _upkeepGasLimit
    ) {
        // Initialize the owner and the creation date
        i_owner = _owner;
        i_createdAt = block.timestamp;
        i_maxContributions = _maxContributions;

        // Initialize storage variables
        s_lastUpkeep = block.timestamp;
        s_upkeepInterval = _paymentInterval;
        s_upkeepGasLimit = _upkeepGasLimit;

        // Initialize the Chainlink variables
        LINK = LinkTokenInterface(_linkToken);
        REGISTRAR = KeeperRegistrarInterface(_registrar);
        REGISTRY = KeeperRegistryInterface(_registry);

        // Initialize the DAC Aggregator
        DAC_AGGREGATOR = DACAggregatorInterface(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Create a new contribution to a project
     * @param _projectContract The address of the project contract
     * @param _amount The amount of the contribution
     * @param _endDate The timestamp when the contribution ends
     */

    function createContribution(
        address _projectContract,
        uint256 _amount,
        uint256 _endDate
    ) external payable onlyOwner {
        // Check if the project is still active
        if (!isProjectStillActive(_projectContract))
            revert DACContributorAccount__PROJECT_NOT_ACTIVE();

        // Check if the amount is correct
        if (_amount == 0 || msg.value != _amount)
            revert DACContributorAccount__INCORRECT_AMOUNT();

        // Check if the amount is not higher than the maximum amount of contributions
        if (s_contributions.length > i_maxContributions)
            revert DACContributorAccount__TOO_MANY_CONTRIBUTIONS();

        // Check if the end date is not in the past
        if (_endDate < block.timestamp)
            revert DACContributorAccount__INVALID_TIMESTAMP();

        // Create the contribution
        s_contributions.push(
            Contribution({
                projectContract: _projectContract,
                amountStored: _amount,
                amountDistributed: 0,
                startedAt: block.timestamp,
                endsAt: _endDate
            })
        );

        emit DACContributorAccount__ContributionCreated(
            _projectContract,
            _amount,
            _endDate
        );
    }

    /**
     * @notice Update the amount of a contribution
     * @param _index The index of the contribution in the array
     * @param _amount The new amount
     */

    function updateContribution(
        uint256 _index,
        uint256 _amount
    ) external payable onlyOwner {
        Contribution memory contribution = s_contributions[_index];
        // Check if the contribution is still active
        if (!isContributionAlreadyDistributed(contribution))
            revert DACContributorAccount__CONTRIBUTION_ALREADY_DISTRIBUTED();

        if (_amount > contribution.amountStored) {
            // If it's an increase, check that the amount sent is correct
            if (msg.value != _amount - contribution.amountStored)
                revert DACContributorAccount__INCORRECT_AMOUNT();

            // Increment the amount of the contribution
            s_contributions[_index].amountStored = _amount;
        } else {
            // If it's a decrease, check that the amount is not lower than what is left to distribute
            if (_amount < contribution.amountDistributed)
                revert DACContributorAccount__INCORRECT_AMOUNT();

            // Decrement the amount of the contribution
            s_contributions[_index].amountStored = _amount;

            // Withdraw the difference
            uint256 difference = contribution.amountStored - _amount;
            (bool success, ) = msg.sender.call{value: difference}("");
            if (!success) revert DACContributorAccount__TRANSFER_FAILED();
        }

        emit DACContributorAccount__ContributionUpdated(
            contribution.projectContract,
            _amount
        );
    }

    /**
     * @notice Cancel all the contributions and withdraw the funds
     */

    function cancelAllContributions() external onlyOwner {
        Contribution[] memory contributions = s_contributions;
        uint256 contractBalance = address(this).balance;

        // Withdraw everything from this contract
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert DACContributorAccount__TRANSFER_FAILED();

        // Remove all the contributions from the array
        delete s_contributions;

        emit DACContributorAccount__AllContributionsCanceled(
            contributions,
            contractBalance
        );
    }

    /**
     * @notice Trigger the payment of all the contributions manually
     * @dev This can be called by the owner of the account if the Chainlink Upkeeps failed,
     * or just if they want to trigger the payment manually at any time
     */

    function triggerManualPayment() external onlyOwner {
        // Check which contributions need to be sent
        ContributionMinimal[]
            memory contributionsToSend = calculateContributions();

        // If there is no contribution to send, revert
        if (contributionsToSend.length == 0)
            revert DACContributorAccount__NO_CONTRIBUTION_TO_SEND();

        // Update the timestamp of the last upkeep
        s_lastUpkeep = block.timestamp;

        // If at least one project is still active
        if (contributionsToSend.length > 0) {
            // Send the contributions
            transferContributions(contributionsToSend);
        }
    }

    /**
     * @notice Send the contributions to the projects
     * @param _contributionsToSend The contributions to send
     * TODO MAYBE CAN USE A MULTICALL INSTEAD OF A FOR LOOP
     */

    function transferContributions(
        ContributionMinimal[] memory _contributionsToSend
    ) internal {
        // For each contribution
        for (uint256 i = 0; i < _contributionsToSend.length; ) {
            // Update the amount distributed
            unchecked {
                s_contributions[_contributionsToSend[i].index]
                    .amountDistributed += _contributionsToSend[i].amount;
            }

            // Send the contribution
            (bool success, ) = _contributionsToSend[i].projectContract.call{
                value: _contributionsToSend[i].amount
            }("");

            if (!success) revert DACContributorAccount__CALL_FAILED();

            unchecked {
                i++;
            }
        }

        emit DACContributorAccount__ContributionsTransfered(
            _contributionsToSend
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                                   UPKEEP                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Register a new Chainlink Upkeep
     * @param _fundingAmount The amount of LINK to initially fund the upkeep
     */

    function registerNewUpkeep(uint96 _fundingAmount) public onlyOwner {
        if (s_upkeepRegistered)
            revert DACContributorAccount__UPKEEP_ALREADY_REGISTERED();

        if (_fundingAmount < 0.1 * 10 ** 18)
            revert DACContributorAccount__FUNDING_AMOUNT_TOO_LOW();

        // Approve spending of LINK
        // LINK.approve(address(REGISTRAR), _fundingAmount);

        // Register the Chainlink Upkeep
        uint256 upkeepId = REGISTRAR.registerUpkeep(
            RegistrationParams({
                name: "DACContributorAccount",
                encryptedEmail: hex"",
                upkeepContract: address(this),
                gasLimit: s_upkeepGasLimit,
                adminAddress: i_owner,
                checkData: hex"",
                offchainConfig: hex"",
                amount: _fundingAmount
            })
        );

        if (upkeepId == 0)
            revert DACContributorAccount__UPKEEP_REGISTRATION_FAILED();

        s_upkeepId = upkeepId;
        s_upkeepRegistered = true;

        emit DACContributorAccount__UpkeepRegistered(
            s_upkeepId,
            s_upkeepInterval
        );
    }

    /**
     * @notice Cancel the registration of the Chainlink Upkeep
     * @dev This will cancel the upkeep but it won't withdraw the funds
     */

    function cancelUpkeep() external onlyOwner {
        if (!s_upkeepRegistered)
            revert DACContributorAccount__UPKEEP_NOT_REGISTERED();

        // Cancel the Chainlink Upkeep
        REGISTRY.cancelUpkeep(s_upkeepId);
        // Set the upkeep as not registered
        s_upkeepRegistered = false;

        emit DACContributorAccount__UpkeepCanceled(s_upkeepId);
    }

    /**
     * @notice Withdraw the funds from the Chainlink Upkeep
     * @dev The upkeep needs to be canceled first, and the funds can be withdrawn
     * only after 50 blocks
     * @dev It will send the funds to the owner of the account
     * @dev The frontend should carefully let the owner cancel the upkeep and withdraw the funds, before
     * allowing them to create a new upkeep, or they would lose the ID ; even though it could still be grabbed
     * from the registry/events to withdraw the funds later
     */

    function withdrawUpkeepFunds() external onlyOwner {
        // Withdraw the funds from the Chainlink Upkeep
        REGISTRY.withdrawFunds(s_upkeepId, i_owner);

        emit DACContributorAccount__UpkeepFundsWithdrawn(s_upkeepId);
    }

    /**
     * @notice Fund the upkeep of the account after a transfer of LINK tokens
     * @param _sender The sender of the LINK tokens (most probably the owner of the account)
     * @param _amount The amount of LINK tokens sent
     * @dev This function is called by the LINK token contract after being called with the `transferAndCall` function
     * @dev The recommended process for funding the upkeep is therefore to let the user in the frontend call this function
     * directly from the LINK contract, using the address of this account as the receiver, which will automatically add the funds
     */
    function onTokenTransfer(
        address _sender,
        uint256 _amount,
        bytes calldata /* _data */
    ) external {
        // We don't really need to perform any checks here (e.g. is the caller LINK, is the amount correct...)
        // because in any case we want any LINK funds here to be used for the upkeep
        // Fund the upkeep
        REGISTRY.addFunds(s_upkeepId, uint96(LINK.balanceOf(address(this))));

        emit DACContributorAccount__UpkeepFunded(_sender, _amount);
    }

    /**
     * @notice The Chainlink Upkeep method to check if an upkeep is needed
     * @dev This will be called by a Chainlink Automation node
     * @dev This won't use any gas so we take advantage of this to calculate the contributions here
     */

    function checkUpkeep(
        bytes calldata
    ) external view override returns (bool, bytes memory) {
        // If the interval has passed
        if (block.timestamp - s_lastUpkeep > s_upkeepInterval) {
            // Check which contributions need to be sent
            ContributionMinimal[]
                memory contributionsToSend = calculateContributions();

            // If at least one contribution to a project is still active
            if (contributionsToSend.length > 0) {
                // Encode the array to bytes
                bytes memory data = abi.encode(contributionsToSend);

                // Return true to trigger the upkeep, along with the array of contributions as bytes
                return (true, data);
            }
        }

        // If no projects need to be topped up or the interval has not passed, do not trigger the upkeep
        return (false, "");
    }

    /**
     * @notice The Chainlink Upkeep method to perform an upkeep
     * @dev This will be called by a Chainlink Automation node
     */

    function performUpkeep(bytes calldata performData) external override {
        // Update the timestamp of the last upkeep
        s_lastUpkeep = block.timestamp;

        // Decode the array of contributions to send
        ContributionMinimal[] memory contributionsToSend = abi.decode(
            performData,
            (ContributionMinimal[])
        );

        // Send the contributions
        transferContributions(contributionsToSend);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   SETTERS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Set the interval between each upkeep
     * @param _interval The interval between each upkeep
     */

    function setUpkeepInterval(uint256 _interval) external onlyOwner {
        s_upkeepInterval = _interval;
        emit DACContributorAccount__UpkeepIntervalUpdated(_interval);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GETTERS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Get the address of the LINK token contract
     * @return address The address of the contract
     */

    function getLink() external view returns (address) {
        return address(LINK);
    }

    /**
     * @notice Get the address of the Upkeep registry
     * @return address The address of the contract
     */

    function getUpkeepRegistry() external view returns (address) {
        return address(REGISTRY);
    }

    /**
     * @notice Get the address of the Upkeep registrar
     * @return address The address of the contract
     */

    function getUpkeepRegistrar() external view returns (address) {
        return address(REGISTRAR);
    }

    /**
     * @notice Get the address of the DAC Aggregator
     * @return address The address of the contract
     */

    function getDACAggregator() external view returns (address) {
        return address(DAC_AGGREGATOR);
    }

    /**
     * @notice Get the address of the owner of the account
     * @return address The address of the owner of the account
     */

    function getOwner() external view returns (address) {
        return i_owner;
    }

    /**
     * @notice Get the creation date of the account
     * @return uint256 The creation date of the account
     */

    function getCreatedAt() external view returns (uint256) {
        return i_createdAt;
    }

    /**
     * @notice Get the maximum amount of contributions that this account can hold
     * @return uint256 The maximum amount of contributions
     */

    function getMaxContributions() external view returns (uint256) {
        return i_maxContributions;
    }

    /**
     * @notice Get the last time the contributions were sent to the supported projects though the upkeep
     * @return uint256 The timestamp of the last upkeep
     */

    function getLastUpkeep() external view returns (uint256) {
        return s_lastUpkeep;
    }

    /**
     * @notice Get the interval between each upkeep
     * @return uint256 The timestamp of the interval between each upkeep
     */

    function getUpkeepInterval() external view returns (uint256) {
        return s_upkeepInterval;
    }

    /**
     * @notice Get the contributions of the account
     * @return array The contributions of the account
     */

    function getContributions() external view returns (Contribution[] memory) {
        return s_contributions;
    }

    /**
     * @notice Get the Chainlink Upkeep ID
     * @return uint256 The Chainlink Upkeep ID
     */

    function getUpkeepId() external view returns (uint256) {
        return s_upkeepId;
    }

    /**
     * @notice Get the Chainlink Upkeep registered status
     * @return bool Whether the Chainlink Upkeep is registered or not
     */

    function isUpkeepRegistered() external view returns (bool) {
        return s_upkeepRegistered;
    }

    /**
     * @notice Calculate if the contract holds enough LINK to process the next upkeep
     * @return bool Whether the contract can process the next upkeep or not
     * @dev It will be approximated with a fixed high gas price and the gas limit fixed at the creation of this contract
     * @dev See the DACAggregator contract for more details about the calculation
     */

    function hasEnoughLinkForNextUpkeep() external view returns (bool) {
        // Calculate the amount of LINK needed for the next upkeep
        uint256 amountNeeded = DAC_AGGREGATOR.calculateUpkeepPrice(
            s_upkeepGasLimit
        );

        // If the upkeep holds enough LINK, return true
        if (REGISTRY.getUpkeep(s_upkeepId).balance >= amountNeeded) return true;
        // If the contract doesn't hold enough LINK, return false
        return false;
    }

    /**
     * @notice Calculate the overall amount of the contributions that should be sent
     * @return array The contributions that should be sent
     */

    function calculateContributions()
        internal
        view
        returns (ContributionMinimal[] memory)
    {
        // Cache the contributions
        Contribution[] memory contributions = s_contributions;
        // Prepare the array to hold the contributions that need to be sent
        ContributionMinimal[]
            memory contributionsToSend = new ContributionMinimal[](
                contributions.length
            );
        // And the number of contributions that need to be sent
        uint256 contributionsToSendCount = 0;

        for (uint256 i = 0; i < contributions.length; ) {
            // If the project is still active and there are still some funds to send
            if (
                isProjectStillActive(contributions[i].projectContract) &&
                isContributionAlreadyDistributed(contributions[i])
            ) {
                // Calculate the amount of the contribution that can be sent based on the time left
                uint256 amountToSend = calculateIndividualContribution(
                    contributions[i]
                );

                // If the amount to send is not 0
                if (amountToSend > 0) {
                    // Add the contribution to the array
                    contributionsToSend[
                        contributionsToSendCount
                    ] = ContributionMinimal({
                        projectContract: contributions[i].projectContract,
                        amount: amountToSend,
                        index: i
                    });
                    unchecked {
                        contributionsToSendCount++;
                    }
                }
            }

            unchecked {
                i++;
            }
        }

        // Shrink the array to the correct size
        assembly {
            mstore(contributionsToSend, contributionsToSendCount)
        }

        return contributionsToSend;
    }

    /**
     * @notice Get the amount of a contribution that should be sent based on the date
     * @param _contribution The contribution to check
     * @return uint256 The amount of the contribution that should be sent
     * @dev This will not check if the contribution is still active or not, so it should be done before calling this function
     */

    function calculateIndividualContribution(
        Contribution memory _contribution
    ) internal view returns (uint256) {
        // If there is nothing to distribute anymore, return 0
        if (_contribution.amountStored == 0) return 0;

        // If the contribution period has ended, return the amount that is left
        if (_contribution.endsAt < block.timestamp)
            return _contribution.amountStored - _contribution.amountDistributed;

        // Calculate the amount of the contribution that should be sent based on the time left
        uint256 remainingDuration = _contribution.endsAt - block.timestamp;
        uint256 remainingIntervals = remainingDuration / s_upkeepInterval;
        uint256 remainingAmount = _contribution.amountStored -
            _contribution.amountDistributed;

        // Calculate the amount to distribute based on the remaining intervals.
        // If there's an incomplete interval, it will be counted as a whole one.
        return remainingAmount / (remainingIntervals + 2); // "+1" for rounding up
        // and "+1" for the incomplete interval (we want a payment at the end of the period)
    }

    /**
     * @notice Know if the project is still active or not
     * @param _projectContract The address of the project contract
     * @return bool Whether the project is still active or not
     */

    function isProjectStillActive(
        address _projectContract
    ) internal view returns (bool) {
        return DAC_AGGREGATOR.isProjectActive(_projectContract);
    }

    /**
     * @notice Know if the contribution is still active or not
     * @param _contribution The contribution to check
     * @return bool Whether the contribution is still active or not
     */

    function isContributionAlreadyDistributed(
        Contribution memory _contribution
    ) internal pure returns (bool) {
        if (_contribution.amountStored > _contribution.amountDistributed)
            return true;

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

/**
 * @title DAC (Decentralized Autonomous Crowdfunding) Project
 * @author polarzero
 * @notice ...
 */

contract DACProject {
    /* -------------------------------------------------------------------------- */
    /*                                CUSTOM ERRORS                               */
    /* -------------------------------------------------------------------------- */

    /// @dev This function can only be called by a collaborator of the project
    error DACProject__NOT_COLLABORATOR();
    /// @dev The collaborator doesn't have enough funds available to withdraw
    error DACProject__NOT_ENOUGH_FUNDS_AVAILABLE();
    /// @dev The transfer of funds failed
    error DACProject__TRANSFER_FAILED();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted when a new contribution is received
    /// @param contributor The address of the contributor
    /// @param amount The amount of funds received
    event DACProject__ReceivedContribution(
        address indexed contributor,
        uint256 amount
    );

    /// @dev Emitted when a collaborator withdraws their share
    /// @param collaborator The address of the collaborator
    /// @param amount The amount of funds withdrawn
    event DACProject__ShareWithdrawn(
        address indexed collaborator,
        uint256 amount
    );

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Main informations
     */

    // Won't be updated after the creation
    /// @dev The address of the initiator of this project
    address private immutable i_initiator;
    /// @dev The creation date of this project
    uint256 private immutable i_createdAt;
    /// @dev The name of the project
    string private s_name;
    /// @dev A short description of the project
    string private s_description;

    // Will be updated after each contribution
    /// @dev The amount of funds received from contributions
    uint256 private s_totalRaised;

    /**
     * @dev Contributors
     * @dev The addresses will either be individuals (if sending directly to the contract) or
     * contracts (if sending from a contributor account, or any other contract)
     */

    /// @dev The addresses of the contributors
    address[] private s_contributorsAddresses;

    /// @dev The amount of funds contributed by each contributor
    mapping(address => uint256) private s_contributors;

    /**
     * @dev Collaborators
     */

    // Collaborators
    /// @dev The addresses of the collaborators
    address[] private s_collaboratorsAddresses;

    /// @dev The status and infos of a collaborator
    /// @param shares The share of contributions of the collaborator
    /// @param amountAvailable The amount of funds available for the collaborator to withdraw
    struct Collaborator {
        uint256 share;
        uint256 amountAvailable;
    }

    /// @dev The status and infos of the collaborators (share & total withdrawn)
    mapping(address => Collaborator) private s_collaborators;

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Restricts the access to the collaborators of the project
     */

    modifier onlyCollaborator() {
        if (!isCollaborator(msg.sender)) revert DACProject__NOT_COLLABORATOR();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice The constructor of the DAC aggregator contract
     * @param _collaborators The addresses of the collaborators (including the initiator)
     * @param _shares The shares of each collaborator (in the same order as the collaborators array)
     * @param _initiator The address of the initiator
     * @param _name The name of the project
     * @param _description A short description of the project
     * @dev All verifications have been done already in the factory contract, so we don't need to check them again
     * @dev This will register a new Chainlink Upkeep in the fly
     */
    constructor(
        address[] memory _collaborators,
        uint256[] memory _shares,
        address _initiator,
        string memory _name,
        string memory _description
    ) {
        // Initialize immutable variables
        i_initiator = _initiator;
        // (not marked immutable but can't be changed afterwards)
        s_name = _name;
        s_description = _description;
        i_createdAt = block.timestamp;

        // Initialize collaborators
        for (uint256 i = 0; i < _collaborators.length; i++) {
            // Add their address to the array
            s_collaboratorsAddresses.push(_collaborators[i]);
            // Initialize their share
            s_collaborators[_collaborators[i]] = Collaborator(_shares[i], 0);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Receive function, triggered when the contract receives funds
     */

    receive() external payable {
        onContributionReceived(msg.sender, msg.value);
    }

    /**
     * @notice Fallback function, triggered when the contract receives funds along with some data
     */

    fallback() external payable {
        onContributionReceived(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw the funds available for the collaborator
     * @param _amount The amount of funds to withdraw
     * @dev This function can only be called by the collaborators of the project
     */

    function withdrawShare(uint256 _amount) external onlyCollaborator {
        // Get the amount available and withdrawn for the collaborator
        Collaborator memory collaborator = s_collaborators[msg.sender];

        // Check if the collaborator has enough funds available
        if (collaborator.amountAvailable < _amount)
            revert DACProject__NOT_ENOUGH_FUNDS_AVAILABLE();

        // Update the amount available
        unchecked {
            s_collaborators[msg.sender].amountAvailable -= _amount;
        }

        // Transfer the funds to the collaborator
        (bool success, ) = msg.sender.call{value: _amount}("");
        if (!success) revert DACProject__TRANSFER_FAILED();

        emit DACProject__ShareWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Called by `receive` or `fallback` when the contract receives funds
     * @param _contributor The address of the contributor (either an individual or a contract)
     * @param _amount The amount of funds received
     */

    function onContributionReceived(
        address _contributor,
        uint256 _amount
    ) private {
        // Update the total amount raised
        s_totalRaised += _amount;
        // Update the amount contributed by the contributor
        s_contributors[_contributor] += _amount;
        // Add the contributor to the array if they have never contributed before
        if (s_contributors[_contributor] == _amount)
            s_contributorsAddresses.push(_contributor);

        // Get the addresses of the collaborators
        address[] memory collaboratorsAddresses = s_collaboratorsAddresses;

        // Update the amount available for each collaborator
        for (uint256 i = 0; i < collaboratorsAddresses.length; ) {
            // Update the amount available for the collaborator
            s_collaborators[collaboratorsAddresses[i]].amountAvailable +=
                (_amount * s_collaborators[collaboratorsAddresses[i]].share) /
                100;

            unchecked {
                i++;
            }
        }

        emit DACProject__ReceivedContribution(msg.sender, msg.value);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GETTERS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Know if an address is a collaborator
     * @param _collaborator The address to check
     */

    function isCollaborator(address _collaborator) public view returns (bool) {
        for (uint256 i = 0; i < s_collaboratorsAddresses.length; i++) {
            if (s_collaboratorsAddresses[i] == _collaborator) return true;
        }
        return false;
    }

    /**
     * @notice Get the addresses of the collaborators
     * @return array The addresses of the collaborators
     */

    function getCollaboratorsAddresses()
        external
        view
        returns (address[] memory)
    {
        return s_collaboratorsAddresses;
    }

    /**
     * @notice Get the informations of a specific collaborator
     * @param _collaborator The address of the collaborator
     * @return struct The share of the collaborator and the total amount already withdrawn
     */

    function getCollaborator(
        address _collaborator
    ) external view returns (Collaborator memory) {
        return s_collaborators[_collaborator];
    }

    /**
     * @notice Get the addresses of the contributors
     * @return array The addresses of the contributors
     */

    function getContributorsAddresses()
        external
        view
        returns (address[] memory)
    {
        return s_contributorsAddresses;
    }

    /**
     * @notice Get the amount contributed by a specific contributor
     * @param _contributor The address of the contributor
     * @return uint256 The amount contributed
     */

    function getContributedAmount(
        address _contributor
    ) external view returns (uint256) {
        return s_contributors[_contributor];
    }

    /**
     * @notice Get the total amount raised
     * @return uint256 The total amount raised
     */

    function getTotalRaised() external view returns (uint256) {
        return s_totalRaised;
    }

    /**
     * @notice Get the total amount contributed by each contributor
     * @return array All the contributors
     * @return array All the amounts contributed (in the same order)
     */

    function getContributorsWithAmounts()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        // Get the addresses of the contributors
        address[] memory contributorsAddresses = s_contributorsAddresses;
        // Initialize the array of amounts
        uint256[] memory amounts = new uint256[](contributorsAddresses.length);

        // Get the amount contributed by each contributor
        for (uint256 i = 0; i < contributorsAddresses.length; ) {
            amounts[i] = s_contributors[contributorsAddresses[i]];

            unchecked {
                i++;
            }
        }

        return (contributorsAddresses, amounts);
    }

    /**
     * @notice Get the initiator of the project
     * @return address The address of the initiator
     */

    function getInitiator() external view returns (address) {
        return i_initiator;
    }

    /**
     * @notice Get the creation date of the project
     * @return uint256 The creation date of the project
     */

    function getCreatedAt() external view returns (uint256) {
        return i_createdAt;
    }

    /**
     * @notice Get the name of the project
     * @return string The name of the project
     */

    function getName() external view returns (string memory) {
        return s_name;
    }

    /**
     * @notice Get the description of the project
     * @return string The description of the project
     */

    function getDescription() external view returns (string memory) {
        return s_description;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}