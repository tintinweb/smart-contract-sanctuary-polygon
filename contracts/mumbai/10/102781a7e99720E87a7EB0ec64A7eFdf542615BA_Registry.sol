// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/SignerOwnable.sol";
import "../interfaces/IGateway.sol";
import "./RegistryGateway.sol";
import "./RegistryWorkflow.sol";
import "./RegistryBalance.sol";

// TODO: 1. Charge user for the workflow registration and cancellation in order to perform the internal workflow.
//          Charged amount to the reward distribution pool.
// TODO: 2. Reward distribution on mainchain and sidechain logic.
//          Mainchain: send to the reward distribution pool.

// Registry is the internal smart contract needed to secure the network and support important features of Nerif.
contract Registry is Initializable, SignerOwnable, RegistryGateway, RegistryWorkflow, RegistryBalance {
    // Config contains the configuration options
    struct Config {
        // performanceOverhead is the cost of the performance transaction excluding the client contract call.
        uint256 performanceOverhead;
        // performancePremiumThreshold is the network premium threshold in percents.
        uint8 performancePremiumThreshold;
        // registrationOverhead is the cost of the workflow registration.
        uint256 registrationOverhead;
        // cancellationOverhead is the cost of the workflow cancellation.
        uint256 cancellationOverhead;
        // maxWorkflowsPerAccount is the maximum number of workflows per user.
        // 0 value means there is no limit.
        uint16 maxWorkflowsPerAccount;
    }

    uint256 internal constant PERFORM_GAS_CUSHION = 5_000;
    string internal constant GATEWAY_PERFORM_FUNC_SIGNATURE = "perform(uint256,address,bytes)";

    bool public isMainChain;
    Config public config;
    uint256 public networkRewards;

    event BalanceFunded(address addr, uint256 amount);
    event BalanceWithdrawn(address addr, uint256 amount);
    event RewardsWithdrawn(address addr, uint256 amount);
    event GatewaySet(address owner, address gateway);
    event WorkflowRegistered(address owner, uint256 id, bytes hash);
    event WorkflowStatusChanged(uint256 id, WorkflowStatus status);
    event Performance(uint256 id, uint256 gasUsed, bool success);

    // onlyMainchain permits transactions on the mainchain only
    modifier onlyMainchain() {
        require(isMainChain, "Registry: operation is not permitted");
        _;
    }

    // onlyMsgSender checks that the given address is the transaction sender one.
    modifier onlyMsgSender(address addr) {
        require(addr == msg.sender, "Registry: operation is not permitted");
        _;
    }

    // onlyMsgSenderOrSigner modifier for message sender or collective address only
    modifier onlyMsgSenderOrSigner(address addr) {
        if (isMainChain) {
            require(addr == msg.sender, "Registry: operation is not permitted");
            _;
        } else {
            require(signerGetter.getSignerAddress() == msg.sender, "Registry: operation is not permitted");
            _;
        }
    }

    // onlyWorkflowOwnerOrSigner permits operation for the workflow owner if it is mainnet
    // or for the network collective address.
    modifier onlyWorkflowOwnerOrSigner(uint256 id) {
        if (isMainChain) {
            Workflow memory workflow = getWorkflow(id);
            require(workflow.owner == msg.sender, "Registry: operation is not permitted");
            _;
        } else {
            // Only network can execute the function on the sidechain.
            // The transaction must come from the network after reaching consensus.
            // Basically, the transaction must come from the registry contract itself,
            // namely from the perform function after passing all checks.
            require(signerGetter.getSignerAddress() == msg.sender, "Registry: operation is not permitted");
            _;
        }
    }

    function initialize(
        bool _isMainChain,
        address _signerGetterAddress,
        Config calldata _config
    ) external initializer {
        isMainChain = _isMainChain;
        _setSignerGetter(_signerGetterAddress);
        config = _config;
    }

    // fundBalance funds the balance of the sender's address with the given amount.
    function fundBalance() external payable {
        uint256 currentBalance = getBalance(msg.sender);
        _setBalance(msg.sender, currentBalance + msg.value);
        emit BalanceFunded(msg.sender, msg.value);
    }

    // setConfig sets the given configuration
    function setConfig(Config calldata _config) external onlySigner {
        config = _config;
    }

    // withdrawBalance withdraws the remaining balance of the sender's public key.
    // Permissions:
    //  - Only balance owner can withdraw its balance.
    // TODO: Handle cases when the withdrawal happens during the workflow execution. Introduce withdrawal request.
    function withdrawBalance() external {
        address payable sender = payable(msg.sender);
        uint256 balance = getBalance(sender);

        // Ensure the sender has a positive balance
        require(balance > 0, "Registry: no balance to withdraw");

        // Update the sender's balance
        _setBalance(sender, 0);

        // Transfer the balance to the sender
        sender.transfer(balance);

        // Emit an event to log the withdrawal transaction
        emit BalanceWithdrawn(sender, balance);
    }

    // withdrawRewards sends network rewards to the rewards withdrawal address
    function withdrawRewards() external {
        require(networkRewards > 0, "Registry: nothing to withdraw");
        require(address(signerGetter) != address(0x0), "Registry: signer storage address is not specified");

        address payable addr = payable(signerGetter.getSignerAddress());
        require(addr != address(0x0), "Registry: withdrawal address is not specified");

        // Transfer rewards
        addr.transfer(networkRewards);
        networkRewards = 0;

        // Emit an event to log the withdrawal transaction
        emit RewardsWithdrawn(addr, networkRewards);
    }

    // setGateway sets gateway for the given owner address.
    function setGateway(address gateway) external {
        _setGateway(msg.sender, IGateway(gateway));
        emit GatewaySet(msg.sender, gateway);
    }

    // pauseWorkflow pauses an existing active workflow.
    // Arguments:
    //  - "id" is the workflow identifier.
    // Permissions:
    //  - Permitted on MAINCHAIN only.
    //  - Only workflow owner can pause an existing active workflow.
    function pauseWorkflow(uint256 id) external onlyMainchain onlyExistingWorkflow(id) onlyWorkflowOwner(id) {
        // Find the workflow in the list
        Workflow memory workflow = getWorkflow(id);

        // Check current workflow status
        require(workflow.status == WorkflowStatus.ACTIVE, "Registry: only active workflows could be paused");

        // Update status
        workflow.status = WorkflowStatus.PAUSED;
        require(_updateWorkflow(workflow), "Registry: failed to update workflow");

        emit WorkflowStatusChanged(id, WorkflowStatus.PAUSED);
    }

    // resumeWorkflow resumes an existing paused workflow.
    // Arguments:
    //  - "id" is the workflow identifier.
    // Permissions:
    //  - Permitted on MAINCHAIN only.
    //  - Only workflow owner can resume an existing active workflow.
    function resumeWorkflow(uint256 id) external onlyMainchain onlyExistingWorkflow(id) onlyWorkflowOwner(id) {
        // Find the workflow in the list
        Workflow memory workflow = getWorkflow(id);

        // Check current workflow status
        require(workflow.status == WorkflowStatus.PAUSED, "Registry: only paused workflows could be resumed");

        // Update status
        workflow.status = WorkflowStatus.ACTIVE;
        require(_updateWorkflow(workflow), "Registry: failed to update workflow");

        emit WorkflowStatusChanged(id, WorkflowStatus.ACTIVE);
    }

    // perform performs the contract execution defined in the registered workflow.
    // The function checks that the given performance transaction was signed by the majority
    // of the network so the workflow owner could be charged and the transaction
    // with the given payload could be passed to the customer's contract.
    // Arguments:
    //  - "workflowId" is the workflow ID
    //  - "gasAmount" is the maximum number of gas used to execute the transaction
    //  - "data" is the contract call data
    //  - "target" is the client contract address
    // Permissions:
    //  - Only network can execute this function.
    function perform(
        uint256 workflowId,
        uint256 gasAmount,
        bytes calldata data,
        address target
    ) external onlySigner onlyExistingWorkflow(workflowId) {
        uint256 gasUsed = gasleft();

        // Get a workflow by ID
        Workflow memory workflow = getWorkflow(workflowId);
        require(workflow.id > 0, "Registry: workflow not found");

        // Make sure the workflow is not paused
        require(workflow.status == WorkflowStatus.ACTIVE, "Registry: workflow must be active");

        // Get current balance of workflow owner
        uint256 currentBalance = getBalance(workflow.owner);

        // Make sure workflow owner has enough funds
        require(currentBalance > 0, "Registry: not enough funds on balance");

        // Cannot self-execute if not internal
        require(address(this) != target, "Registry: operation is not permitted");

        // TODO: Make sure the given transaction was not performed yet

        // Execute client's contract through gateway
        // Get workflow owner's gateway
        IGateway existingGateway = getGateway(workflow.owner); // TODO: Make sure it is not zero address

        // Execute customer contract through its gateway
        bool success = _callWithExactGas(
            gasAmount,
            address(existingGateway),
            abi.encodeWithSignature(GATEWAY_PERFORM_FUNC_SIGNATURE, workflowId, target, data)
        );

        gasUsed -= gasleft();

        // Adding performance overhead if exists
        gasUsed += config.performanceOverhead;

        // Adding performance premium
        if (config.performancePremiumThreshold > 0) {
            gasUsed += gasUsed / uint256(config.performancePremiumThreshold);
        }

        // Calculate amount to charge
        uint256 amountToCharge = gasUsed * tx.gasprice;

        // Make sure owner has enough funds
        require(currentBalance >= amountToCharge, "Registry: not enough funds on balance");

        // Charge workflow owner balance
        _setBalance(workflow.owner, currentBalance - amountToCharge);

        // Move amount to the network rewards balance
        networkRewards += amountToCharge;

        // Update total spent amount of the current workflow
        workflow.totalSpent += amountToCharge;
        require(_updateWorkflow(workflow), "Registry: failed to update workflow");

        // Emit performance event
        emit Performance(workflowId, gasUsed, success);
    }

    // registerWorkflow registers a new workflow metadata.
    // Arguments:
    //  - "id" is the workflow identifier.
    //  - "owner" is the workflow owner address.
    //  - "hash" is the workflow hash.
    // The given signature must correspond to the given hash and created by the transaction sender.
    // Permissions:
    //  - Only workflow owner can register a workflow on MAINCHAIN.
    //  - Only network can register a workflow on SIDECHAIN through the regular performance process.
    function registerWorkflow(
        uint256 id,
        address owner,
        bytes calldata hash,
        bool requireGateway
    ) external onlyMsgSenderOrSigner(owner) {
        // Check if the given workflow owner has a gateway registered.
        if (requireGateway) {
            IGateway existingGateway = getGateway(owner);
            require(address(existingGateway) != address(0x0), "Registry: gateway not found");
        }

        // Check if the given sender has capacity to create one more workflow
        if (isMainChain && config.maxWorkflowsPerAccount > 0) {
            require(
                _workflowsPerAddress(msg.sender) < config.maxWorkflowsPerAccount,
                "Registry: reached max workflows capacity"
            );
        }

        // Use ACTIVE workflow status by default for sidechains
        WorkflowStatus workflowStatus = WorkflowStatus.ACTIVE;

        // Or set the PENDING one for the mainchain
        if (isMainChain) {
            workflowStatus = WorkflowStatus.PENDING;
        }

        // Store a new workflow
        require(_addWorkflow(Workflow(id, owner, hash, workflowStatus, 0)), "Registry: failed to add workflow");

        // Emmit the event
        emit WorkflowRegistered(msg.sender, id, hash);
    }

    // activateWorkflow updates the workflow state from PENDING to ACTIVE.
    // Arguments:
    //  - "id" is the workflow identifier.
    //  - "status" is the workflow status.
    // Permissions:
    //  - Permitted on MAINCHAIN only.
    //  - Only network can execute it through the regular performance process.
    function activateWorkflow(uint256 id) external onlyMainchain onlySigner onlyExistingWorkflow(id) {
        // Find the workflow in the list
        Workflow memory workflow = getWorkflow(id);

        // Must be PENDING
        require(workflow.status == WorkflowStatus.PENDING, "Registry: workflow must be pending");

        // Update status
        workflow.status = WorkflowStatus.ACTIVE;
        require(_updateWorkflow(workflow), "Registry: failed to update workflow");

        emit WorkflowStatusChanged(id, WorkflowStatus.ACTIVE);
    }

    // cancelWorkflow cancels an existing workflow.
    // Arguments:
    //  - "id" is the workflow identifier.
    // Permissions:
    //  - Only workflow owner can cancel an existing active workflow on MAINCHAIN.
    //  - Only network can cancel a workflow on SIDECHAIN through the regular performance process.
    function cancelWorkflow(uint256 id) external onlyExistingWorkflow(id) onlyWorkflowOwnerOrSigner(id) {
        // Find the workflow in the list
        Workflow memory workflow = getWorkflow(id);

        // Check current workflow status
        require(workflow.status != WorkflowStatus.CANCELLED, "Registry: workflow is already cancelled");

        // Update status
        workflow.status = WorkflowStatus.CANCELLED;
        require(_updateWorkflow(workflow), "Registry: failed to update workflow");

        emit WorkflowStatusChanged(id, WorkflowStatus.CANCELLED);
    }

    // getWorkflowOwnerBalance returns the current balance of the given workflow ID.
    function getWorkflowOwnerBalance(uint256 id) public view returns (uint256) {
        // Find the workflow in the list
        Workflow memory workflow = getWorkflow(id);
        require(workflow.owner != address(0x0), "Registry: workflow does not exist");

        // Return owner's balance
        return getBalance(workflow.owner);
    }

    // _callWithExactGas calls target address with exactly gasAmount gas and data as calldata
    // or reverts if at least gasAmount gas is not available
    function _callWithExactGas(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) private returns (bool success) {
        assembly {
            let g := gas()

            // Compute g -= PERFORM_GAS_CUSHION and check for underflow
            if lt(g, PERFORM_GAS_CUSHION) {
                revert(0, 0)
            }

            g := sub(g, PERFORM_GAS_CUSHION)

            // if g - g//64 <= gasAmount, revert
            // (we subtract g//64 because of EIP-150)
            if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
                revert(0, 0)
            }

            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                revert(0, 0)
            }

            // call and return whether we succeeded. ignore return data
            success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
        }
        return success;
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
pragma solidity ^0.8.18;

// IGateway represents the customer gateway contract behaviour.
interface IGateway {
    // perform is the entrypoint function of all customer contracts.
    // This function accepts the workflow ID and the end customer contract
    // execution payload.
    // The function checks that the given transaction is permitted and can be forwarded
    // next to the end customer contract.
    function perform(
        uint256 id,
        address target,
        bytes calldata payload
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IGateway.sol";

abstract contract RegistryGateway {
    struct Gateway {
        IGateway gateway;
        address owner;
    }

    mapping(address => uint256) private indexMap;
    Gateway[] private gateways;

    function getGateways() external view returns (Gateway[] memory) {
        return gateways;
    }

    function getGateway(address owner) public view returns (IGateway) {
        if (!_hasGateway(owner)) {
            return IGateway(address(0x0));
        }

        return gateways[indexMap[owner] - 1].gateway;
    }

    function _setGateway(address owner, IGateway gateway) internal {
        if (_hasGateway(owner)) {
            gateways[indexMap[owner] - 1] = Gateway(gateway, owner);
        } else {
            gateways.push(Gateway(gateway, owner));
            indexMap[owner] = gateways.length;
        }

        _checkGatewayEntry(owner);
    }

    function _checkGatewayEntry(address owner) private view {
        uint256 index = indexMap[owner];
        assert(index <= gateways.length);

        if (_hasGateway(owner)) {
            assert(index > 0);
        } else {
            assert(index == 0);
        }
    }

    function _hasGateway(address owner) private view returns (bool) {
        return indexMap[owner] > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum WorkflowStatus {
    PENDING,
    ACTIVE,
    PAUSED,
    CANCELLED
}

struct Workflow {
    uint256 id;
    address owner;
    bytes hash;
    WorkflowStatus status;
    uint256 totalSpent;
}

abstract contract RegistryWorkflow {
    mapping(uint256 => uint256) private indexMap;
    Workflow[] private workflows;
    mapping(address => uint64) private perAddress;

    modifier onlyExistingWorkflow(uint256 id) {
        Workflow memory workflow = getWorkflow(id);
        require(workflow.id > 0, "Registry: workflow does not exist");
        _;
    }

    modifier onlyWorkflowOwner(uint256 id) {
        Workflow memory workflow = getWorkflow(id);
        require(workflow.owner == msg.sender, "Registry: operation not permitted");
        _;
    }

    function getWorkflow(uint256 id) public view returns (Workflow memory) {
        require(_hasWorkflow(id), "Registry: workflow does not exist");
        return workflows[indexMap[id] - 1];
    }

    function getWorkflows() public view returns (Workflow[] memory) {
        return workflows;
    }

    function _addWorkflow(Workflow memory _workflow) internal returns (bool) {
        if (_hasWorkflow(_workflow.id)) {
            return false;
        }

        workflows.push(_workflow);
        indexMap[_workflow.id] = workflows.length;
        perAddress[_workflow.owner]++;

        _checkWorkflowEntry(_workflow.id);

        return true;
    }

    function _updateWorkflow(Workflow memory _workflow) internal returns (bool) {
        if (!_hasWorkflow(_workflow.id)) {
            return false;
        }

        workflows[indexMap[_workflow.id] - 1] = _workflow;

        _checkWorkflowEntry(_workflow.id);

        return true;
    }

    function _workflowsPerAddress(address owner) internal view returns (uint256) {
        return perAddress[owner];
    }

    function _checkWorkflowEntry(uint256 id) private view {
        uint256 index = indexMap[id];
        assert(index <= workflows.length);

        if (_hasWorkflow(id)) {
            assert(index > 0);
        } else {
            assert(index == 0);
        }
    }

    function _hasWorkflow(uint256 id) private view returns (bool) {
        return indexMap[id] > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract RegistryBalance {
    struct Balance {
        address user;
        uint256 balance;
    }

    mapping(address => uint256) private indexMap;
    Balance[] private balances;

    function getBalances() external view returns (Balance[] memory) {
        return balances;
    }

    function getBalance(address user) public view returns (uint256) {
        if (!_hasBalance(user)) {
            return 0;
        }

        return balances[indexMap[user] - 1].balance;
    }

    function _setBalance(address user, uint256 balance) internal {
        if (_hasBalance(user)) {
            balances[indexMap[user] - 1] = Balance(user, balance);
        } else {
            balances.push(Balance(user, balance));
            indexMap[user] = balances.length;
        }

        _checkBalanceEntry(user);
    }

    function _checkBalanceEntry(address user) private view {
        uint256 index = indexMap[user];
        assert(index <= balances.length);

        if (_hasBalance(user)) {
            assert(index > 0);
        } else {
            assert(index == 0);
        }
    }

    function _hasBalance(address user) private view returns (bool) {
        return indexMap[user] > 0;
    }
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