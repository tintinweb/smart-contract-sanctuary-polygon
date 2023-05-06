// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IErrorsRegistries.sol";

/// @title Generic Manager - Smart contract for generic registry manager template
/// @author Aleksandr Kuperman - <[email protected]>
abstract contract GenericManager is IErrorsRegistries {
    event OwnerUpdated(address indexed owner);
    event Pause(address indexed owner);
    event Unpause(address indexed owner);

    // Owner address
    address public owner;
    // Pause switch
    bool public paused;

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Pauses the contract.
    function pause() external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        paused = true;
        emit Pause(msg.sender);
    }

    /// @dev Unpauses the contract.
    function unpause() external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        paused = false;
        emit Unpause(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @dev Errors.
interface IErrorsRegistries {
    /// @dev Only `manager` has a privilege, but the `sender` was provided.
    /// @param sender Sender address.
    /// @param manager Required sender address as a manager.
    error ManagerOnly(address sender, address manager);

    /// @dev Only `owner` has a privilege, but the `sender` was provided.
    /// @param sender Sender address.
    /// @param owner Required sender address as an owner.
    error OwnerOnly(address sender, address owner);

    /// @dev Hash already exists in the records.
    error HashExists();

    /// @dev Provided zero address.
    error ZeroAddress();

    /// @dev Agent Id is not correctly provided for the current routine.
    /// @param agentId Component Id.
    error WrongAgentId(uint256 agentId);

    /// @dev Wrong length of two arrays.
    /// @param numValues1 Number of values in a first array.
    /// @param numValues2 Numberf of values in a second array.
    error WrongArrayLength(uint256 numValues1, uint256 numValues2);

    /// @dev Canonical agent Id is not found.
    /// @param agentId Canonical agent Id.
    error AgentNotFound(uint256 agentId);

    /// @dev Component Id is not found.
    /// @param componentId Component Id.
    error ComponentNotFound(uint256 componentId);

    /// @dev Multisig threshold is out of bounds.
    /// @param currentThreshold Current threshold value.
    /// @param minThreshold Minimum possible threshold value.
    /// @param maxThreshold Maximum possible threshold value.
    error WrongThreshold(uint256 currentThreshold, uint256 minThreshold, uint256 maxThreshold);

    /// @dev Agent instance is already registered with a specified `operator`.
    /// @param operator Operator that registered an instance.
    error AgentInstanceRegistered(address operator);

    /// @dev Wrong operator is specified when interacting with a specified `serviceId`.
    /// @param serviceId Service Id.
    error WrongOperator(uint256 serviceId);

    /// @dev Operator has no registered instances in the service.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    error OperatorHasNoInstances(address operator, uint256 serviceId);

    /// @dev Canonical `agentId` is not found as a part of `serviceId`.
    /// @param agentId Canonical agent Id.
    /// @param serviceId Service Id.
    error AgentNotInService(uint256 agentId, uint256 serviceId);

    /// @dev The contract is paused.
    error Paused();

    /// @dev Zero value when it has to be different from zero.
    error ZeroValue();

    /// @dev Value overflow.
    /// @param provided Overflow value.
    /// @param max Maximum possible value.
    error Overflow(uint256 provided, uint256 max);

    /// @dev Service must be inactive.
    /// @param serviceId Service Id.
    error ServiceMustBeInactive(uint256 serviceId);

    /// @dev All the agent instance slots for a specific `serviceId` are filled.
    /// @param serviceId Service Id.
    error AgentInstancesSlotsFilled(uint256 serviceId);

    /// @dev Wrong state of a service.
    /// @param state Service state.
    /// @param serviceId Service Id.
    error WrongServiceState(uint256 state, uint256 serviceId);

    /// @dev Only own service multisig is allowed.
    /// @param provided Provided address.
    /// @param expected Expected multisig address.
    /// @param serviceId Service Id.
    error OnlyOwnServiceMultisig(address provided, address expected, uint256 serviceId);

    /// @dev Multisig is not whitelisted.
    /// @param multisig Address of a multisig implementation.
    error UnauthorizedMultisig(address multisig);

    /// @dev Incorrect deposit provided for the registration activation.
    /// @param sent Sent amount.
    /// @param expected Expected amount.
    /// @param serviceId Service Id.
    error IncorrectRegistrationDepositValue(uint256 sent, uint256 expected, uint256 serviceId);

    /// @dev Insufficient value provided for the agent instance bonding.
    /// @param sent Sent amount.
    /// @param expected Expected amount.
    /// @param serviceId Service Id.
    error IncorrectAgentBondingValue(uint256 sent, uint256 expected, uint256 serviceId);

    /// @dev Failure of a transfer.
    /// @param token Address of a token.
    /// @param from Address `from`.
    /// @param to Address `to`.
    /// @param value Value.
    error TransferFailed(address token, address from, address to, uint256 value);

    /// @dev Caught reentrancy violation.
    error ReentrancyGuard();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @dev Required interface for the service manipulation.
interface IService{
    struct AgentParams {
        // Number of agent instances
        uint32 slots;
        // Bond per agent instance
        uint96 bond;
    }

    /// @dev Creates a new service.
    /// @param serviceOwner Individual that creates and controls a service.
    /// @param configHash IPFS hash pointing to the config metadata.
    /// @param agentIds Canonical agent Ids in a sorted ascending order.
    /// @param agentParams Number of agent instances and required bond to register an instance in the service.
    /// @param threshold Signers threshold for a multisig composed by agent instances.
    /// @return serviceId Created service Id.
    function create(
        address serviceOwner,
        bytes32 configHash,
        uint32[] memory agentIds,
        AgentParams[] memory agentParams,
        uint32 threshold
    ) external returns (uint256 serviceId);

    /// @dev Updates a service in a CRUD way.
    /// @param serviceOwner Individual that creates and controls a service.
    /// @param configHash IPFS hash pointing to the config metadata.
    /// @param agentIds Canonical agent Ids in a sorted ascending order.
    /// @param agentParams Number of agent instances and required bond to register an instance in the service.
    /// @param threshold Signers threshold for a multisig composed by agent instances.
    /// @param serviceId Service Id to be updated.
    /// @return success True, if function executed successfully.
    function update(
        address serviceOwner,
        bytes32 configHash,
        uint32[] memory agentIds,
        AgentParams[] memory agentParams,
        uint32 threshold,
        uint256 serviceId
    ) external returns (bool success);

    /// @dev Activates the service.
    /// @param serviceOwner Individual that creates and controls a service.
    /// @param serviceId Correspondent service Id.
    /// @return success True, if function executed successfully.
    function activateRegistration(address serviceOwner, uint256 serviceId) external payable returns (bool success);

    /// @dev Registers agent instances.
    /// @param operator Address of the operator.
    /// @param serviceId Service Id to be updated.
    /// @param agentInstances Agent instance addresses.
    /// @param agentIds Canonical Ids of the agent correspondent to the agent instance.
    /// @return success True, if function executed successfully.
    function registerAgents(
        address operator,
        uint256 serviceId,
        address[] memory agentInstances,
        uint32[] memory agentIds
    ) external payable returns (bool success);

    /// @dev Creates multisig instance controlled by the set of service agent instances and deploys the service.
    /// @param serviceOwner Individual that creates and controls a service.
    /// @param serviceId Correspondent service Id.
    /// @param multisigImplementation Multisig implementation address.
    /// @param data Data payload for the multisig creation.
    /// @return multisig Address of the created multisig.
    function deploy(
        address serviceOwner,
        uint256 serviceId,
        address multisigImplementation,
        bytes memory data
    ) external returns (address multisig);

    /// @dev Terminates the service.
    /// @param serviceOwner Owner of the service.
    /// @param serviceId Service Id to be updated.
    /// @return success True, if function executed successfully.
    /// @return refund Refund to return to the serviceOwner.
    function terminate(address serviceOwner, uint256 serviceId) external returns (bool success, uint256 refund);

    /// @dev Unbonds agent instances of the operator from the service.
    /// @param operator Operator of agent instances.
    /// @param serviceId Service Id.
    /// @return success True, if function executed successfully.
    /// @return refund The amount of refund returned to the operator.
    function unbond(address operator, uint256 serviceId) external returns (bool success, uint256 refund);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interface for the service registration token utility manipulation.
interface IServiceTokenUtility {
    /// @dev Creates a record with the token-related information for the specified service.
    /// @param serviceId Service Id.
    /// @param token Token address.
    /// @param agentIds Set of agent Ids.
    /// @param bonds Set of correspondent bonds.
    function createWithToken(
        uint256 serviceId,
        address token,
        uint32[] memory agentIds,
        uint256[] memory bonds
    ) external;

    /// @dev Resets a record with token and security deposit data.
    /// @param serviceId Service Id.
    function resetServiceToken(uint256 serviceId) external;

    /// @dev Deposit a token security deposit for the service registration after its activation.
    /// @param serviceId Service Id.
    /// @return isTokenSecured True if the service Id is token secured, false if ETH secured otherwise.
    function activateRegistrationTokenDeposit(uint256 serviceId) external returns (bool isTokenSecured);

    /// @dev Deposits bonded tokens from the operator during the agent instance registration.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @param agentIds Set of agent Ids for corresponding agent instances opertor is registering.
    /// @return isTokenSecured True if the service Id is token secured, false if ETH secured otherwise.
    function registerAgentsTokenDeposit(
        address operator,
        uint256 serviceId,
        uint32[] memory agentIds
    ) external returns (bool isTokenSecured);

    /// @dev Withdraws a token security deposit to the service owner after the service termination.
    /// @param serviceId Service Id.
    /// @return securityRefund Returned token security deposit, or zero if the service is ETH-secured.
    function terminateTokenRefund(uint256 serviceId) external returns (uint256 securityRefund);

    /// @dev Withdraws bonded tokens to the operator during the unbond phase.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return refund Returned bonded token amount, or zero if the service is ETH-secured.
    function unbondTokenRefund(address operator, uint256 serviceId) external returns (uint256 refund);

    /// @dev Gets service token secured status.
    /// @param serviceId Service Id.
    /// @return True if the service Id is token secured.
    function isTokenSecuredService(uint256 serviceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {GenericManager} from "./GenericManager.sol";
import {OperatorSignedHashes} from "./utils/OperatorSignedHashes.sol";
import "./interfaces/IService.sol";
import "./interfaces/IServiceTokenUtility.sol";

// Operator whitelist interface
interface IOperatorWhitelist {
    /// @dev Gets operator whitelisting status.
    /// @param serviceId Service Id.
    /// @param operator Operator address.
    /// @return status Whitelisting status.
    function isOperatorWhitelisted(uint256 serviceId, address operator) external view returns (bool status);
}

// Generic token interface
interface IToken {
    /// @dev Gets the owner of the token Id.
    /// @param tokenId Token Id.
    /// @return Token Id owner address.
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title Service Manager - Periphery smart contract for managing services with custom ERC20 tokens or ETH
/// @author Aleksandr Kuperman - <[email protected]>
/// @author AL
contract ServiceManagerToken is GenericManager, OperatorSignedHashes {
    event OperatorWhitelistUpdated(address indexed operatorWhitelist);
    event CreateMultisig(address indexed multisig);

    // Service Registry address
    address public immutable serviceRegistry;
    // Service Registry Token Utility address
    address public immutable serviceRegistryTokenUtility;
    // A well-known representation of ETH as an address
    address public constant ETH_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    // Bond wrapping constant
    uint96 public constant BOND_WRAPPER = 1;
    // Operator whitelist address
    address public operatorWhitelist;

    /// @dev ServiceRegistryTokenUtility constructor.
    /// @param _serviceRegistry Service Registry contract address.
    /// @param _serviceRegistryTokenUtility Service Registry Token Utility contract address.
    constructor(address _serviceRegistry, address _serviceRegistryTokenUtility, address _operatorWhitelist)
        OperatorSignedHashes("Service Manager Token", "1.1.1")
    {
        // Check for the Service Registry related contract zero addresses
        if (_serviceRegistry == address(0) || _serviceRegistryTokenUtility == address(0)) {
            revert ZeroAddress();
        }

        serviceRegistry = _serviceRegistry;
        serviceRegistryTokenUtility = _serviceRegistryTokenUtility;
        operatorWhitelist = _operatorWhitelist;
        owner = msg.sender;
    }

    /// @dev Sets the operator whitelist contract address.
    /// @param newOperatorWhitelist New operator whitelist contract address.
    function setOperatorWhitelist(address newOperatorWhitelist) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        operatorWhitelist = newOperatorWhitelist;
        emit OperatorWhitelistUpdated(newOperatorWhitelist);
    }

    /// @dev Creates a new service.
    /// @param serviceOwner Individual that creates and controls a service.
    /// @param token ERC20 token address for the security deposit, or ETH.
    /// @param configHash IPFS hash pointing to the config metadata.
    /// @param agentIds Canonical agent Ids.
    /// @param agentParams Number of agent instances and required bond to register an instance in the service.
    /// @param threshold Threshold for a multisig composed by agents.
    /// @return serviceId Created service Id.
    function create(
        address serviceOwner,
        address token,
        bytes32 configHash,
        uint32[] memory agentIds,
        IService.AgentParams[] memory agentParams,
        uint32 threshold
    ) external returns (uint256 serviceId)
    {
        // Check if the minting is paused
        if (paused) {
            revert Paused();
        }

        // Check for the zero address
        if (token == address(0)) {
            revert ZeroAddress();
        }

        // Check for the custom ERC20 token or ETH based bond
        if (token == ETH_TOKEN_ADDRESS) {
            // Call the original ServiceRegistry contract function
            serviceId = IService(serviceRegistry).create(serviceOwner, configHash, agentIds, agentParams, threshold);
        } else {
            // Wrap agent params with just 1 WEI bond going to the original ServiceRegistry contract,
            // and actual token bonds being recorded with the ServiceRegistryTokenUtility contract
            uint256 numAgents = agentParams.length;
            uint256[] memory bonds = new uint256[](numAgents);
            for (uint256 i = 0; i < numAgents; ++i) {
                // Check for the zero bond value
                if (agentParams[i].bond == 0) {
                    revert ZeroValue();
                }

                // Copy actual bond values for each agent Id
                bonds[i] = agentParams[i].bond;
                // Wrap bonds with the BOND_WRAPPER value for the original ServiceRegistry contract
                agentParams[i].bond = BOND_WRAPPER;
            }

            // Call the original ServiceRegistry contract function
            serviceId = IService(serviceRegistry).create(serviceOwner, configHash, agentIds, agentParams, threshold);
            // Create a token-related record for the service
            IServiceTokenUtility(serviceRegistryTokenUtility).createWithToken(serviceId, token, agentIds, bonds);
        }
    }

    /// @dev Updates a service in a CRUD way.
    /// @param token ERC20 token address for the security deposit, or ETH.
    /// @param configHash IPFS hash pointing to the config metadata.
    /// @param agentIds Canonical agent Ids.
    /// @param agentParams Number of agent instances and required bond to register an instance in the service.
    /// @param threshold Threshold for a multisig composed by agents.
    /// @param serviceId Service Id to be updated.
    /// @return success True, if function executed successfully.
    function update(
        address token,
        bytes32 configHash,
        uint32[] memory agentIds,
        IService.AgentParams[] memory agentParams,
        uint32 threshold,
        uint256 serviceId
    ) external returns (bool success)
    {
        // Check for the zero address
        if (token == address(0)) {
            revert ZeroAddress();
        }

        uint256 numAgents = agentParams.length;
        if (token == ETH_TOKEN_ADDRESS) {
            // If any of the slots is a non-zero, the correspondent bond cannot be zero
            for (uint256 i = 0; i < numAgents; ++i) {
                // Check for the zero bond value
                if (agentParams[i].slots > 0 && agentParams[i].bond == 0) {
                        revert ZeroValue();
                }
            }
            // Call the original ServiceRegistry contract function
            success = IService(serviceRegistry).update(msg.sender, configHash, agentIds, agentParams, threshold, serviceId);
            // Reset the service token-based data
            // This function still needs to be called as the previous token could be a custom ERC20 token
            IServiceTokenUtility(serviceRegistryTokenUtility).resetServiceToken(serviceId);
        } else {
            // Wrap agent params with just 1 WEI bond going to the original ServiceRegistry contract,
            // and actual token bonds being recorded with the ServiceRegistryTokenUtility contract
            uint256[] memory bonds = new uint256[](numAgents);
            for (uint256 i = 0; i < numAgents; ++i) {
                // Copy actual bond values for each agent Id that has at least one slot in the updated service
                if (agentParams[i].slots > 0) {
                    // Check for the zero bond value
                    if (agentParams[i].bond == 0) {
                        revert ZeroValue();
                    }
                    bonds[i] = agentParams[i].bond;
                    // Wrap bonds with the BOND_WRAPPER value for the original ServiceRegistry contract
                    agentParams[i].bond = BOND_WRAPPER;
                }
            }

            // Call the original ServiceRegistry contract function
            success = IService(serviceRegistry).update(msg.sender, configHash, agentIds, agentParams, threshold, serviceId);
            // Update relevant data in the ServiceRegistryTokenUtility contract
            // We follow the optimistic design where existing bonds are just overwritten without a clearing
            // bond values of agent Ids that are not going to be used in the service. This is coming from the fact
            // that all the checks are done on the original ServiceRegistry side
            IServiceTokenUtility(serviceRegistryTokenUtility).createWithToken(serviceId, token, agentIds, bonds);
        }
    }

    /// @dev Activates the service and its sensitive components.
    /// @param serviceId Correspondent service Id.
    /// @return success True, if function executed successfully.
    function activateRegistration(uint256 serviceId) external payable returns (bool success) {
        // Record the actual ERC20 security deposit
        bool isTokenSecured = IServiceTokenUtility(serviceRegistryTokenUtility).activateRegistrationTokenDeposit(serviceId);

        // Activate registration in the original ServiceRegistry contract
        if (isTokenSecured) {
            // If the service Id is based on the ERC20 token, the provided value to the standard registration is 1
            success = IService(serviceRegistry).activateRegistration{value: BOND_WRAPPER}(msg.sender, serviceId);
        } else {
            // Otherwise follow the standard msg.value path
            success = IService(serviceRegistry).activateRegistration{value: msg.value}(msg.sender, serviceId);
        }
    }

    /// @dev Registers agent instances.
    /// @param serviceId Service Id to be updated.
    /// @param agentInstances Agent instance addresses.
    /// @param agentIds Canonical Ids of the agent correspondent to the agent instance.
    /// @return success True, if function executed successfully.
    function registerAgents(
        uint256 serviceId,
        address[] memory agentInstances,
        uint32[] memory agentIds
    ) external payable returns (bool success) {
        if (operatorWhitelist != address(0)) {
            // Check if the operator is whitelisted
            if (!IOperatorWhitelist(operatorWhitelist).isOperatorWhitelisted(serviceId, msg.sender)) {
                revert WrongOperator(serviceId);
            }
        }

        // Record the actual ERC20 bond
        bool isTokenSecured = IServiceTokenUtility(serviceRegistryTokenUtility).registerAgentsTokenDeposit(msg.sender,
            serviceId, agentIds);

        // Register agent instances in a main ServiceRegistry contract
        if (isTokenSecured) {
            // If the service Id is based on the ERC20 token, the provided value to the standard registration is 1
            // multiplied by the number of agent instances
            success = IService(serviceRegistry).registerAgents{value: agentInstances.length * BOND_WRAPPER}(msg.sender,
                serviceId, agentInstances, agentIds);
        } else {
            // Otherwise follow the standard msg.value path
            success = IService(serviceRegistry).registerAgents{value: msg.value}(msg.sender, serviceId, agentInstances, agentIds);
        }
    }

    /// @dev Creates multisig instance controlled by the set of service agent instances and deploys the service.
    /// @param serviceId Correspondent service Id.
    /// @param multisigImplementation Multisig implementation address.
    /// @param data Data payload for the multisig creation.
    /// @return multisig Address of the created multisig.
    function deploy(
        uint256 serviceId,
        address multisigImplementation,
        bytes memory data
    ) external returns (address multisig)
    {
        multisig = IService(serviceRegistry).deploy(msg.sender, serviceId, multisigImplementation, data);
        emit CreateMultisig(multisig);
    }

    /// @dev Terminates the service.
    /// @param serviceId Service Id.
    /// @return success True, if function executed successfully.
    /// @return refund Refund for the service owner.
    function terminate(uint256 serviceId) external returns (bool success, uint256 refund) {
        // Withdraw the ERC20 token if the service is token-based
        uint256 tokenRefund = IServiceTokenUtility(serviceRegistryTokenUtility).terminateTokenRefund(serviceId);

        // Terminate the service with the regular service registry routine
        (success, refund) = IService(serviceRegistry).terminate(msg.sender, serviceId);

        // If the service is token-based, the actual refund is provided via the serviceRegistryTokenUtility contract
        if (tokenRefund > 0) {
            refund = tokenRefund;
        }
    }

    /// @dev Unbonds agent instances of the operator from the service.
    /// @param serviceId Service Id.
    /// @return success True, if function executed successfully.
    /// @return refund The amount of refund returned to the operator.
    function unbond(uint256 serviceId) external returns (bool success, uint256 refund) {
        // Withdraw the ERC20 token if the service is token-based
        uint256 tokenRefund = IServiceTokenUtility(serviceRegistryTokenUtility).unbondTokenRefund(msg.sender, serviceId);

        // Unbond with the regular service registry routine
        (success, refund) = IService(serviceRegistry).unbond(msg.sender, serviceId);

        // If the service is token-based, the actual refund is provided via the serviceRegistryTokenUtility contract
        if (tokenRefund > 0) {
            refund = tokenRefund;
        }
    }

    /// @dev Unbonds agent instances of the operator by the service owner via the operator's pre-signed message hash.
    /// @notice Note that this function accounts for the operator being the EOA, or the contract that has an
    ///         isValidSignature() function that would confirm the message hash was signed by the operator contract.
    ///         Otherwise, if the message hash has been pre-approved, the corresponding map of hashes is going to
    ///         to verify the signed hash, similar to the Safe contract implementation in v1.3.0:
    ///         https://github.com/safe-global/safe-contracts/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/GnosisSafe.sol#L240-L304
    ///         Also note that only the service owner is able to call this function on behalf of the operator.
    /// @param operator Operator address that signed the unbond message hash.
    /// @param serviceId Service Id.
    /// @param signature Signature byte array associated with operator message hash signature.
    /// @return success True, if the function executed successfully.
    /// @return refund The amount of refund returned to the operator.
    function unbondWithSignature(
        address operator,
        uint256 serviceId,
        bytes memory signature
    ) external returns (bool success, uint256 refund)
    {
        // Check the service owner
        address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);
        if (msg.sender != serviceOwner) {
            revert OwnerOnly(msg.sender, serviceOwner);
        }

        // Get the (operator | serviceId) nonce for the unbond message
        // Push a pair of key defining variables into one key. Service Id or operator are not enough by themselves
        // as another service might use the operator address at the same time frame
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits
        operatorService |= serviceId << 160;
        uint256 nonce = mapOperatorUnbondNonces[operatorService];
        // Get the unbond message hash
        bytes32 msgHash = getUnbondHash(operator, serviceOwner, serviceId, nonce);

        // Verify the signed hash against the operator address
        _verifySignedHash(operator, msgHash, signature);

        // Update corresponding nonce value
        nonce++;
        mapOperatorUnbondNonces[operatorService] = nonce;

        // Withdraw the ERC20 token if the service is token-based
        uint256 tokenRefund = IServiceTokenUtility(serviceRegistryTokenUtility).unbondTokenRefund(operator, serviceId);

        // Unbond with the regular service registry routine
        (success, refund) = IService(serviceRegistry).unbond(operator, serviceId);

        // If the service is token-based, the actual refund is provided via the serviceRegistryTokenUtility contract
        if (tokenRefund > 0) {
            refund = tokenRefund;
        }
    }

    /// @dev Registers agent instances of the operator by the service owner via the operator's pre-signed message hash.
    /// @notice Note that this function accounts for the operator being the EOA, or the contract that has an
    ///         isValidSignature() function that would confirm the message hash was signed by the operator contract.
    ///         Otherwise, if the message hash has been pre-approved, the corresponding map of hashes is going to
    ///         to verify the signed hash, similar to the Safe contract implementation in v1.3.0:
    ///         https://github.com/safe-global/safe-contracts/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/GnosisSafe.sol#L240-L304
    ///         Also note that only the service owner is able to call this function on behalf of the operator.
    /// @param operator Operator address that signed the register agents message hash.
    /// @param serviceId Service Id.
    /// @param agentInstances Agent instance addresses.
    /// @param agentIds Canonical Ids of the agent correspondent to the agent instance.
    /// @param signature Signature byte array associated with operator message hash signature.
    /// @return success True, if the the function executed successfully.
    function registerAgentsWithSignature(
        address operator,
        uint256 serviceId,
        address[] memory agentInstances,
        uint32[] memory agentIds,
        bytes memory signature
    ) external payable returns (bool success) {
        // Check the service owner
        address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);
        if (msg.sender != serviceOwner) {
            revert OwnerOnly(msg.sender, serviceOwner);
        }

        // Get the (operator | serviceId) nonce for the registerAgents message
        // Push a pair of key defining variables into one key. Service Id or operator are not enough by themselves
        // as another service might use the operator address at the same time frame
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits as serviceId is limited by the 2^32 - 1 value
        operatorService |= serviceId << 160;
        uint256 nonce = mapOperatorRegisterAgentsNonces[operatorService];
        // Get register agents message hash
        bytes32 msgHash = getRegisterAgentsHash(operator, serviceOwner, serviceId, agentInstances, agentIds, nonce);

        // Verify the signed hash against the operator address
        _verifySignedHash(operator, msgHash, signature);

        // Update corresponding nonce value
        nonce++;
        mapOperatorRegisterAgentsNonces[operatorService] = nonce;

        // Record the actual ERC20 bond
        bool isTokenSecured = IServiceTokenUtility(serviceRegistryTokenUtility).registerAgentsTokenDeposit(operator,
            serviceId, agentIds);

        // Register agent instances in a main ServiceRegistry contract
        if (isTokenSecured) {
            // If the service Id is based on the ERC20 token, the provided value to the standard registration is 1
            // multiplied by the number of agent instances
            success = IService(serviceRegistry).registerAgents{value: agentInstances.length * BOND_WRAPPER}(operator,
                serviceId, agentInstances, agentIds);
        } else {
            // Otherwise follow the standard msg.value path
            success = IService(serviceRegistry).registerAgents{value: msg.value}(operator, serviceId, agentInstances, agentIds);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISignatureValidator {
    /// @dev Should return whether the signature provided is valid for the provided hash.
    /// @notice MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///         MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    ///         MUST allow external calls.
    /// @param hash Hash of the data to be signed.
    /// @param signature Signature byte array associated with hash.
    /// @return magicValue bytes4 magic value.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

/// @dev Provided zero address.
error ZeroOperatorAddress();

/// @dev Incorrect signature length provided.
/// @param signature Signature bytes.
/// @param provided Provided signature length.
/// @param expected Expected signature length.
error IncorrectSignatureLength(bytes signature, uint256 provided, uint256 expected);

/// @dev Hash is not validated.
/// @param operator Operator contract address.
/// @param msgHash Message hash.
/// @param signature Signature bytes associated with the message hash.
error HashNotValidated(address operator, bytes32 msgHash, bytes signature);

/// @dev Hash is not approved.
/// @param operator Operator address.
/// @param msgHash Message hash.
/// @param signature Signature bytes associated with the message hash.
error HashNotApproved(address operator, bytes32 msgHash, bytes signature);

/// @dev Obtained wrong operator address.
/// @param provided Provided address.
/// @param expected Expected address.
error WrongOperatorAddress(address provided, address expected);

/// @title OperatorSignedHashes - Smart contract for managing operator signed hashes
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract OperatorSignedHashes {
    event OperatorHashApproved(address indexed operator, bytes32 hash);

    // Value for the contract signature validation: bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal MAGIC_VALUE = 0x1626ba7e;
    // Domain separator type hash
    bytes32 public constant DOMAIN_SEPARATOR_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // Unbond type hash
    bytes32 public constant UNBOND_TYPE_HASH =
        keccak256("Unbond(address operator,address serviceOwner,uint256 serviceId,uint256 nonce)");
    // Register agents type hash
    bytes32 public constant REGISTER_AGENTS_TYPE_HASH =
        keccak256("RegisterAgents(address operator,address serviceOwner,uint256 serviceId,bytes32 agentsData,uint256 nonce)");
    // Original domain separator value
    bytes32 public immutable domainSeparator;
    // Original chain Id
    uint256 public immutable chainId;
    // Name hash
    bytes32 public immutable nameHash;
    // Version hash
    bytes32 public immutable versionHash;

    // Name of a signing domain
    string public name;
    // Version of a signing domain
    string public version;

    // Map of operator address and serviceId => unbond nonce
    mapping(uint256 => uint256) public mapOperatorUnbondNonces;
    // Map of operator address and serviceId => register agents nonce
    mapping(uint256 => uint256) public mapOperatorRegisterAgentsNonces;
    // Mapping operator address => approved hashes status
    mapping(address => mapping(bytes32 => bool)) public mapOperatorApprovedHashes;

    /// @dev Contract constructor.
    /// @param _name Name of a signing domain.
    /// @param _version Version of a signing domain.
    constructor(string memory _name, string memory _version) {
        name = _name;
        version = _version;
        nameHash = keccak256(bytes(_name));
        versionHash = keccak256(bytes(_version));
        chainId = block.chainid;
        domainSeparator = _computeDomainSeparator();
    }

    /// @dev Verifies provided message hash against its signature.
    /// @param operator Operator address.
    /// @param msgHash Message hash.
    /// @param signature Signature bytes associated with the signed message hash.
    function _verifySignedHash(address operator, bytes32 msgHash, bytes memory signature) internal view {
        // Check for the operator zero address
        if (operator == address(0)) {
            revert ZeroOperatorAddress();
        }

        // Check for the signature length
        if (signature.length != 65) {
            revert IncorrectSignatureLength(signature, signature.length, 65);
        }

        // Decode the signature
        uint8 v = uint8(signature[64]);
        // For the correct ecrecover() function execution, the v value must be set to {0,1} + 27
        // Although v in a very rare case can be equal to {2,3} (with a probability of 3.73e-37%)
        // If v is set to just 0 or 1 when signing  by the EOA, it is most likely signed by the ledger and must be adjusted
        if (v < 4 && operator.code.length == 0) {
            // In case of a non-contract, adjust v to follow the standard ecrecover case
            v += 27;
        }
        bytes32 r;
        bytes32 s;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
        }

        address recOperator;
        // Go through signature cases based on the value of v
        if (v == 4) {
            // Contract signature case, where the address of the contract is encoded into r
            recOperator = address(uint160(uint256(r)));

            // Check for the signature validity in the contract
            if (ISignatureValidator(recOperator).isValidSignature(msgHash, signature) != MAGIC_VALUE) {
                revert HashNotValidated(recOperator, msgHash, signature);
            }
        } else if (v == 5) {
            // Case of an approved hash, where the address of the operator is encoded into r
            recOperator = address(uint160(uint256(r)));

            // Hashes have been pre-approved by the operator via a separate message, see operatorApproveHash() function
            if (!mapOperatorApprovedHashes[recOperator][msgHash]) {
                revert HashNotApproved(recOperator, msgHash, signature);
            }
        } else {
            // Case of ecrecover with the message hash for EOA signatures
            recOperator = ecrecover(msgHash, v, r, s);
        }

        // Final check is for the operator address itself
        if (recOperator != operator) {
            revert WrongOperatorAddress(recOperator, operator);
        }
    }

    /// @dev Approves message hash for the operator address.
    /// @param hash Provided message hash to approve.
    function operatorApproveHash(bytes32 hash) external {
        mapOperatorApprovedHashes[msg.sender][hash] = true;
        emit OperatorHashApproved(msg.sender, hash);
    }

    /// @dev Computes domain separator hash.
    /// @return Hash of the domain separator based on its name, version, chain Id and contract address.
    function _computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPE_HASH,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Gets the already computed domain separator of recomputes one if the chain Id is different.
    /// @return Original or recomputed domain separator.
    function getDomainSeparator() public view returns (bytes32) {
        return block.chainid == chainId ? domainSeparator : _computeDomainSeparator();
    }

    /// @dev Gets the unbond message hash for the operator.
    /// @param operator Operator address.
    /// @param serviceOwner Service owner address.
    /// @param serviceId Service Id.
    /// @param nonce Nonce for the unbond message from the pair of (operator | service Id).
    /// @return Computed message hash.
    function getUnbondHash(
        address operator,
        address serviceOwner,
        uint256 serviceId,
        uint256 nonce
    ) public view returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                keccak256(
                    abi.encode(
                        UNBOND_TYPE_HASH,
                        operator,
                        serviceOwner,
                        serviceId,
                        nonce
                    )
                )
            )
        );
    }

    /// @dev Gets the register agents message hash for the operator.
    /// @param operator Operator address.
    /// @param serviceOwner Service owner address.
    /// @param serviceId Service Id.
    /// @param agentInstances Agent instance addresses operator is going to register.
    /// @param agentIds Agent Ids corresponding to each agent instance address.
    /// @param nonce Nonce for the register agents message from the pair of (operator | service Id).
    /// @return Computed message hash.
    function getRegisterAgentsHash(
        address operator,
        address serviceOwner,
        uint256 serviceId,
        address[] memory agentInstances,
        uint32[] memory agentIds,
        uint256 nonce
    ) public view returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                keccak256(
                    abi.encode(
                        REGISTER_AGENTS_TYPE_HASH,
                        operator,
                        serviceOwner,
                        serviceId,
                        keccak256(abi.encode(agentInstances, agentIds)),
                        nonce
                    )
                )
            )
        );
    }

    /// @dev Checks if the hash provided by the operator is approved.
    /// @param operator Operator address.
    /// @param hash Message hash.
    /// @return True, if the hash provided by the operator is approved.
    function isOperatorHashApproved(address operator, bytes32 hash) external view returns (bool) {
        return mapOperatorApprovedHashes[operator][hash];
    }

    /// @dev Gets the (operator | service Id) nonce for the unbond message data.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return nonce Obtained nonce.
    function getOperatorUnbondNonce(address operator, uint256 serviceId) external view returns (uint256 nonce) {
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits as serviceId is limited by the 2^32 - 1 value
        operatorService |= serviceId << 160;
        nonce = mapOperatorUnbondNonces[operatorService];
    }

    /// @dev Gets the (operator | service Id) nonce for the register agents message data.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return nonce Obtained nonce.
    function getOperatorRegisterAgentsNonce(address operator, uint256 serviceId) external view returns (uint256 nonce) {
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits as serviceId is limited by the 2^32 - 1 value
        operatorService |= serviceId << 160;
        nonce = mapOperatorRegisterAgentsNonces[operatorService];
    }
}