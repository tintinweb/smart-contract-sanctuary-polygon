/// SPDX-License-Identifier: MIT
/// @by: Nativas ClimaTech
/// @author: Juan Pablo Crespi
/// @dev: https://eips.ethereum.org/EIPS/eip-1167

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "IERC165.sol";
import "Context.sol";
import "Clones.sol";
import "IERC1155Holder.sol";
import "Controllable.sol";
import "NativasRoles.sol";

/**
 * ERC1167 implementation to create new holders
 */
contract NativasFactory is Context, Controllable {
    using Clones for address;

    // NativasHolder template
    address internal _template;
    // Mapping user id to holder address
    mapping(uint256 => address) internal _holders;

    /**
     * @dev MUST trigger when a new holder is created.
     */
    event HolderCreated(
        uint256 indexed holderId,
        address indexed holderAddress
    );

    /**
     * @dev Set NativasHolder contract template.
     */
    constructor(address controller_, address template_)
        Controllable(controller_)
    {
        _setTemplate(template_);
    }

    /**
     * @dev get holder contract template
     */
    function template() public view virtual returns (address) {
        return _template;
    }

    /**
     * @dev get holder contract by holderId.
     */
    function getHolder(uint256 holderId) public view virtual returns (address) {
        return _holders[holderId];
    }

    /**
     * @dev See {Controllable-_safeTransferControl}.
     *
     * Requirements:
     *
     * - the caller must be admin.
     * - new controller must implement IAccessControl interface
     */
    function transferControl(address controller_) public virtual {
        require(
            _hasRole(Roles.ADMIN_ROLE),
            "NativasFactory: caller must have admin role to tranfer control"
        );
        require(
            controller_ != address(0),
            "NativasFactory: new controller is the zero address"
        );
        require(
            IERC165(controller_).supportsInterface(
                type(IAccessControl).interfaceId
            ),
            "NativasFactory: new controller does not support IAccessControl interface"
        );
        _transferControl(controller_);
    }

    /**
     * @dev See {NativasFactory-_setHolder}
     *
     * Requirements:
     *
     * - the caller must be editor.
     */
    function setHolder(
        address entity_,
        uint256 holderId_,
        string memory nin_,
        string memory name_,
        address controller_,
        address operator_
    ) public virtual {
        require(
            _hasRole(Roles.MANAGER_ROLE),
            "NativasFactory: caller must have manager role to set holder"
        );
        _setHolder(entity_, holderId_, nin_, name_, operator_, controller_);
    }

    /**
     * @dev See {NativasFactory-_updateTemplate}
     *
     * Requirements:
     *
     * - the caller must be editor.
     */
    function setTemplate(address template_) public virtual {
        require(
            _hasRole(Roles.ADMIN_ROLE),
            "NativasFactory: caller must have admin role to set template"
        );
        _setTemplate(template_);
    }

    /**
     * @dev Create a new holder contract.
     */
    function _setHolder(
        address entity,
        uint256 holderId,
        string memory nin,
        string memory name,
        address controller,
        address operator
    ) internal virtual {
        require(
            _template != address(0),
            "NativasFactory: template is the zero address"
        );
        address holderAddress = _template.clone();
        IERC1155Holder(holderAddress).init(
            entity,
            operator,
            controller,
            holderId,
            nin,
            name
        );
        _holders[holderId] = holderAddress;
        emit HolderCreated(holderId, holderAddress);
    }

    /**
     * @dev See {IAccessControl-hasRole}
     */
    function _hasRole(bytes32 role) internal virtual returns (bool) {
        return IAccessControl(controller()).hasRole(role, _msgSender());
    }

    /**
     * @dev Sets the holder template contract
     *
     * Requirements:
     *
     * - the template address must not be address 0.
     * - tem template contract must implemente the IERC1155Holder interface
     */
    function _setTemplate(address template_) internal virtual {
        require(
            template_ != address(0),
            "NativasFactory: new template is the zero address"
        );
        require(
            IERC165(template_).supportsInterface(
                type(IERC1155Holder).interfaceId
            ),
            "NativasFactory: new template does not support IERC1155Holder interface"
        );
        _template = template_;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas ClimaTech
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

/**
 * @title Extension of ERC1155 that adds backward compatibility
 */
interface IERC1155Holder {
    /**
     * @dev Initialize contract
     */
    function init(
        address entity_,
        address operator_,
        address controller_,
        uint256 holderId_,
        string memory nin_,
        string memory name_
    ) external;
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas ClimaTech
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism.
 */
contract Controllable is Context {
    address private _controller;

    event ControlTransferred(
        address indexed oldController,
        address indexed newControllerr
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial controller.
     */
    constructor(address controller_) {
        _transferControl(controller_);
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view virtual returns (address) {
        return _controller;
    }

    /**
     * @dev Transfers control of the contract to a new account (`controller_`).
     * Can only be called by the current controller.
     *
     * NOTE: Renouncing control will leave the contract without a controller,
     * thereby removing any functionality that is only available to the controller.
     */
    function _transferControl(address controller_) internal virtual {
        address current = _controller;
        _controller = controller_;
        emit ControlTransferred(current, controller_);
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas ClimaTech
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

library Roles {
    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
}