// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Generic token interface
interface IToken{
    /// @dev Gets the owner of the token Id.
    /// @param tokenId Token Id.
    /// @return Token Id owner address.
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @dev Provided zero address.
error ZeroAddress();

/// @dev Wrong length of two arrays.
/// @param numValues1 Number of values in a first array.
/// @param numValues2 Number of values in a second array.
error WrongArrayLength(uint256 numValues1, uint256 numValues2);

/// @dev Only `owner` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param owner Required sender address as an owner.
error OwnerOnly(address sender, address owner);

/// @title OperatorWhitelist - Smart contract for whitelisting operator addresses
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract OperatorWhitelist {
    event SetOperatorsCheck(address indexed serviceOwner, uint256 indexed serviceId, bool setCheck);
    event OperatorsWhitelistUpdated(address indexed serviceOwner, uint256 indexed serviceId, address[] operators,
        bool[] statuses, bool setCheck);
    event OperatorsWhitelistCheckSet(address indexed serviceOwner, uint256 indexed serviceId);

    // Service Registry contract address
    address public immutable serviceRegistry;
    // Mapping service Id => need to check for the operator address whitelisting status
    mapping(uint256 => bool) public mapServiceIdOperatorsCheck;
    // Mapping service Id => operator whitelisting status
    mapping(uint256 => mapping(address => bool)) public mapServiceIdOperators;

    /// @dev Contract constructor.
    /// @param _serviceRegistry Service Registry contract address.
    constructor (address _serviceRegistry) {
        // Check for the zero address
        if (_serviceRegistry == address(0)) {
            revert ZeroAddress();
        }

        serviceRegistry = _serviceRegistry;
    }

    /// @dev Controls the necessity of checking operator whitelisting statuses.
    /// @param setCheck True if the whitelisting check is needed, and false otherwise.
    function setOperatorsCheck(uint256 serviceId, bool setCheck) external {
        // Check that the service owner is the msg.sender
        address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);
        if (serviceOwner != msg.sender) {
            revert OwnerOnly(serviceOwner, msg.sender);
        }

        // Set the operator address check requirement
        mapServiceIdOperatorsCheck[serviceId] = setCheck;
        emit SetOperatorsCheck(msg.sender, serviceId, setCheck);
    }
    
    /// @dev Controls operators whitelisting statuses.
    /// @notice Operator is considered whitelisted if its status is set to true.
    /// @param serviceId Service Id.
    /// @param operators Set of operator addresses.
    /// @param statuses Set of whitelisting statuses.
    /// @param setCheck True if the whitelisting check is needed, and false otherwise.
    function setOperatorsStatuses(
        uint256 serviceId,
        address[] memory operators,
        bool[] memory statuses,
        bool setCheck
    ) external {
        // Check for the array length and that they are not empty
        if (operators.length == 0 || operators.length != statuses.length) {
            revert WrongArrayLength(operators.length, statuses.length);
        }

        // Check that the service owner is the msg.sender
        address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);
        if (serviceOwner != msg.sender) {
            revert OwnerOnly(serviceOwner, msg.sender);
        }

        // Set the operator address check requirement
        mapServiceIdOperatorsCheck[serviceId] = setCheck;

        // Set operators whitelisting status
        for (uint256 i = 0; i < operators.length; ++i) {
            // Check for the zero address
            if (operators[i] == address(0)) {
                revert ZeroAddress();
            }
            // Set the operator whitelisting status
            mapServiceIdOperators[serviceId][operators[i]] = statuses[i];
        }
        emit OperatorsWhitelistUpdated(msg.sender, serviceId, operators, statuses, setCheck);
    }

    /// @dev Gets operator whitelisting status.
    /// @param serviceId Service Id.
    /// @param operator Operator address.
    /// @return status Whitelisting status.
    function isOperatorWhitelisted(uint256 serviceId, address operator) external view returns (bool status) {
        status = true;
        // Get the service owner address
        address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);
        // Check the operator whitelisting status, if applied by the service owner
        if (serviceOwner != operator && mapServiceIdOperatorsCheck[serviceId]) {
            status = mapServiceIdOperators[serviceId][operator];
        }
    }
}