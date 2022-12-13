// The Licensed Work is (c) 2022 Sygma
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../interfaces/IHandler.sol";

/**
    @title Handles generic deposits and deposit executions.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract PermissionedGenericHandler is IHandler {
    address public immutable _bridgeAddress;

    // resourceID => contract address
    mapping (bytes32 => address) public _resourceIDToContractAddress;

    // contract address => resourceID
    mapping (address => bytes32) public _contractAddressToResourceID;

    // contract address => deposit function signature
    mapping (address => bytes4) public _contractAddressToDepositFunctionSignature;

    // contract address => depositor address position offset in the metadata
    mapping (address => uint256) public _contractAddressToDepositFunctionDepositorOffset;

    // contract address => execute proposal function signature
    mapping (address => bytes4) public _contractAddressToExecuteFunctionSignature;

    // token contract address => is whitelisted
    mapping (address => bool) public _contractWhitelist;

    event FailedHandlerExecution();

    modifier onlyBridge() {
        _onlyBridge();
        _;
    }

    function _onlyBridge() private view {
        require(msg.sender == _bridgeAddress, "sender must be bridge contract");
    }

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
     */
    constructor(
        address          bridgeAddress
    ) public {
        _bridgeAddress = bridgeAddress;
    }

    /**
        @notice Sets {_resourceIDToContractAddress} with {contractAddress},
        {_contractAddressToResourceID} with {resourceID},
        {_contractAddressToDepositFunctionSignature} with {depositFunctionSig},
        {_contractAddressToDepositFunctionDepositorOffset} with {depositFunctionDepositorOffset},
        {_contractAddressToExecuteFunctionSignature} with {executeFunctionSig},
        and {_contractWhitelist} to true for {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param args Additional data to be passed to specified handler.
        Permissioned handler structure should be it constructed as follows:
          depositFunctionSig:              bytes4   bytes 0  - 4
          depositFunctionDepositorOffset:  uint256  bytes 4  - 36
          executeFunctionSig:              bytes4   bytes 36 - 40
     */
    function setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes calldata args
    ) external onlyBridge {
        bytes4   depositFunctionSig = bytes4(args[0:4]);
        uint256  depositFunctionDepositorOffset = uint256(bytes32(args[4:36]));
        bytes4   executeFunctionSig = bytes4(args[36:40]);

        _setResource(resourceID, contractAddress, depositFunctionSig, depositFunctionDepositorOffset, executeFunctionSig);
    }

    /**
        @notice A deposit is initiated by making a deposit in the Bridge contract.
        @param resourceID ResourceID used to find address of contract to be used for deposit.
        @param depositor Address of the account making deposit in the Bridge contract.
        @param data Consists of: {resourceID}, {lenMetaData}, and {metaData} all padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        len(data)                              uint256     bytes  0  - 32
        data                                   bytes       bytes  64 - END
        @notice {contractAddress} is required to be whitelisted
        @notice If {_contractAddressToDepositFunctionSignature}[{contractAddress}] is set,
        {metaData} is expected to consist of needed function arguments.
        @return Returns the raw bytes returned from the call to {contractAddress}.
     */
    function deposit(bytes32 resourceID, address depositor, bytes calldata data) external onlyBridge returns (bytes memory) {
        uint256      lenMetadata;
        bytes memory metadata;

        lenMetadata = abi.decode(data, (uint256));
        metadata = bytes(data[32:32 + lenMetadata]);

        address contractAddress = _resourceIDToContractAddress[resourceID];
        uint256 depositorOffset = _contractAddressToDepositFunctionDepositorOffset[contractAddress];
        if (depositorOffset > 0) {
            uint256 metadataDepositor;
            // Skipping 32 bytes of length prefix and depositorOffset bytes.
            assembly {
                metadataDepositor := mload(add(add(metadata, 32), depositorOffset))
            }
            // metadataDepositor contains 0xdepositorAddressdepositorAddressdeposite************************
            // Shift it 12 bytes right:   0x000000000000000000000000depositorAddressdepositorAddressdeposite
            require(depositor == address(uint160(metadataDepositor >> 96)), 'incorrect depositor in the data');
        }

        require(_contractWhitelist[contractAddress], "provided contractAddress is not whitelisted");

        bytes4 sig = _contractAddressToDepositFunctionSignature[contractAddress];
        if (sig != bytes4(0)) {
            bytes memory callData = abi.encodePacked(sig, metadata);
            (bool success, bytes memory handlerResponse) = contractAddress.call(callData);
            require(success, "call to contractAddress failed");
            return handlerResponse;
        }
    }

    /**
        @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
        @param resourceID ResourceID to be used when making deposits.
        @param data Consists of {resourceID}, {lenMetaData}, and {metaData}.
        @notice Data passed into the function should be constructed as follows:
        len(data)                              uint256     bytes  0  - 32
        data                                   bytes       bytes  32 - END
        @notice {contractAddress} is required to be whitelisted
        @notice If {_contractAddressToExecuteFunctionSignature}[{contractAddress}] is set,
        {metaData} is expected to consist of needed function arguments.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external onlyBridge {
        uint256      lenMetadata;
        bytes memory metaData;

        lenMetadata = abi.decode(data, (uint256));
        metaData = bytes(data[32:32 + lenMetadata]);

        address contractAddress = _resourceIDToContractAddress[resourceID];
        require(_contractWhitelist[contractAddress], "provided contractAddress is not whitelisted");

        bytes4 sig = _contractAddressToExecuteFunctionSignature[contractAddress];
        if (sig != bytes4(0)) {
            bytes memory callData = abi.encodePacked(sig, metaData);
            (bool success, ) = contractAddress.call(callData);

            if (!success) {
                emit FailedHandlerExecution();
            }
        }
    }

    function _setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint256 depositFunctionDepositorOffset,
        bytes4 executeFunctionSig
    ) internal {

        _resourceIDToContractAddress[resourceID] = contractAddress;
        _contractAddressToResourceID[contractAddress] = resourceID;
        _contractAddressToDepositFunctionSignature[contractAddress] = depositFunctionSig;
        _contractAddressToDepositFunctionDepositorOffset[contractAddress] = depositFunctionDepositorOffset;
        _contractAddressToExecuteFunctionSignature[contractAddress] = executeFunctionSig;

        _contractWhitelist[contractAddress] = true;
    }
}

// The Licensed Work is (c) 2022 Sygma
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
    @title Interface for handler that handles generic deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IHandler {
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param depositor Address of account making the deposit in the Bridge contract.
        @param data Consists of additional data needed for a specific deposit.
     */
    function deposit(bytes32 resourceID, address depositor, bytes calldata data) external returns (bytes memory);

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
        @param resourceID ResourceID to be used when making deposits.
        @param data Consists of additional data needed for a specific deposit execution.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external;

    /**
        @notice Correlates {_resourceIDToContractAddress} with {contractAddress}, {_contractAddressToResourceID} with {resourceID} and marks
        {_contractWhitelist} to true for {contractAddress} in ERCHandlerHelpers contract.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param args Additional data to be passed to specified handler.
     */
    function setResource(bytes32 resourceID, address contractAddress, bytes calldata args) external;
}