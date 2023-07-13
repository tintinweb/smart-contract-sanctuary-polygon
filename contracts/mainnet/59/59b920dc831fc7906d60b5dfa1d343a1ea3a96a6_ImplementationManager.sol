// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title ImplementationManager
/// @author Cloover
/// @notice Contract that manages the list of contracts deployed for the protocol
contract ImplementationManager is IImplementationManager {
    //----------------------------------------
    // Storage
    //----------------------------------------

    mapping(bytes32 => address) _interfacesImplemented;

    //----------------------------------------
    // Events
    //----------------------------------------

    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    //----------------------------------------
    // Modifiers
    //----------------------------------------

    modifier onlyMaintainer() {
        IAccessController accessController =
            IAccessController(_interfacesImplemented[ImplementationInterfaceNames.AccessController]);
        if (!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // Initialization function
    //----------------------------------------
    constructor(address accessController) {
        _interfacesImplemented[ImplementationInterfaceNames.AccessController] = accessController;
    }

    //----------------------------------------
    // Externals functions
    //----------------------------------------

    /// @inheritdoc IImplementationManager
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress)
        external
        override
        onlyMaintainer
    {
        _interfacesImplemented[interfaceName] = implementationAddress;

        emit InterfaceImplementationChanged(interfaceName, implementationAddress);
    }

    /// @inheritdoc IImplementationManager
    function getImplementationAddress(bytes32 interfaceName)
        external
        view
        override
        returns (address implementationAddress)
    {
        implementationAddress = _interfacesImplemented[interfaceName];
        if (implementationAddress == address(0x0)) revert Errors.IMPLEMENTATION_NOT_FOUND();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessController is IAccessControl {
    function MAINTAINER_ROLE() external view returns (bytes32);
    function MANAGER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IImplementationManager {
    /// @notice Updates the address of the contract that implements `interfaceName`
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /// @notice Return the address of the contract that implements the given `interfaceName`
    function getImplementationAddress(bytes32 interfaceName) external view returns (address implementationAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ImplementationInterfaceNames
/// @author Cloover
/// @notice Library exposing interfaces names used in Cloover
library ImplementationInterfaceNames {
    bytes32 public constant AccessController = "AccessController";
    bytes32 public constant RandomProvider = "RandomProvider";
    bytes32 public constant NFTWhitelist = "NFTWhitelist";
    bytes32 public constant TokenWhitelist = "TokenWhitelist";
    bytes32 public constant ClooverRaffleFactory = "ClooverRaffleFactory";
    bytes32 public constant Treasury = "Treasury";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Errors library
/// @author Cloover
/// @notice Library exposing errors used in Cloover's contracts
library Errors {
    error CANT_BE_ZERO(); // 'Value can't must be higher than 0'
    error NOT_MAINTAINER(); // 'Caller is not the maintainer'
    error IMPLEMENTATION_NOT_FOUND(); // 'Implementation interfaces is not registered'
    error ALREADY_WHITELISTED(); //'address already whitelisted'
    error NOT_WHITELISTED(); //'address not whitelisted'
    error EXCEED_MAX_PERCENTAGE(); //'Percentage value must be lower than max allowed'
    error EXCEED_MAX_VALUE_ALLOWED(); //'Value must be lower than max allowed'
    error BELOW_MIN_VALUE_ALLOWED(); //'Value must be higher than min allowed'
    error WRONG_DURATION_LIMITS(); //'The min duration must be lower than the max one'
    error OUT_OF_RANGE(); //'The value is not in the allowed range'
    error SALES_ALREADY_STARTED(); // 'At least one ticket has already been sold'
    error RAFFLE_CLOSE(); // 'Current timestamps greater or equal than the close time'
    error RAFFLE_STILL_OPEN(); // 'Current timestamps lesser or equal than the close time'
    error DRAW_NOT_POSSIBLE(); // 'Raffle is status forwards than DRAWING'
    error TICKET_SUPPLY_OVERFLOW(); // 'Maximum amount of ticket sold for the raffle has been reached'
    error WRONG_MSG_VALUE(); // 'msg.value not valid'
    error WRONG_AMOUNT(); // 'msg.value not valid'
    error MSG_SENDER_NOT_WINNER(); // 'msg.sender is not winner address'
    error NOT_CREATOR(); // 'msg.sender is not the creator of the raffle'
    error TICKET_NOT_DRAWN(); // 'ticket must be drawn'
    error TICKET_ALREADY_DRAWN(); // 'ticket has already be drawn'
    error NOT_REGISTERED_RAFFLE(); // 'Caller is not a raffle contract registered'
    error NOT_RANDOM_PROVIDER_CONTRACT(); // 'Caller is not the random provider contract'
    error COLLECTION_NOT_WHITELISTED(); //'NFT collection not whitelisted'
    error ROYALTIES_NOT_POSSIBLE(); //'NFT collection creator '
    error TOKEN_NOT_WHITELISTED(); //'Token not whitelisted'
    error IS_ETH_RAFFLE(); //'Ticket can only be purchase with native token (ETH)'
    error NOT_ETH_RAFFLE(); //'Ticket can only be purchase with ERC20 token'
    error NO_INSURANCE_TAKEN(); //'ClooverRaffle's creator didn't took insurance to claim prize refund'
    error INSURANCE_AMOUNT(); //'insurance cost paid'
    error SALES_EXCEED_MIN_THRESHOLD_LIMIT(); //'Ticket sales exceed min ticket sales covered by the insurance paid'
    error ALREADY_CLAIMED(); //'User already claimed his part'
    error NOTHING_TO_CLAIM(); //'User has nothing to claim'
    error EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE(); //'User exceed allowed ticket to purchase limit'
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