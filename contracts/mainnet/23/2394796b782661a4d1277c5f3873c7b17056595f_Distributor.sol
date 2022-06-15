// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Utils.sol";
import "./rewards/interfaces/IMERC20.sol";
import "./rewards/interfaces/IMERC721.sol";
import "./rewards/interfaces/IMERC1155.sol";

error TokenNotGivenMinterRole(address token);
error OutOfRewards(TokenBundle bundle);

library Distributor {
    /*//////////////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////////////*/

    function deposit(TokenBundle memory bundle) public view {
        for (uint256 x = 0; x < bundle.erc20s.tokens.length; x++) {
            _checkMintRole(bundle.erc20s.tokens[x]);
        }
        for (uint256 x = 0; x < bundle.erc721s.tokens.length; x++) {
            _checkMintRole(bundle.erc721s.tokens[x]);
        }
        for (uint256 x = 0; x < bundle.erc1155s.tokens.length; x++) {
            _checkMintRole(bundle.erc1155s.tokens[x]);
        }
    }

    function _checkMintRole(address token) internal view {
        if (!IAccessControl(token).hasRole(MINTER_ROLE, address(this))) {
            revert TokenNotGivenMinterRole(token);
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////////////*/

    function withdraw(TokenBundle storage bundle, address user) public {
        if (bundle.qty != type(uint256).max) {
            if (bundle.qty == 0) {
                revert OutOfRewards(bundle);
            } else {
                bundle.qty--;
            }
        }
        withdrawERC20(bundle.erc20s, user);
        withdrawERC721(bundle.erc721s, user);
        withdrawERC1155(bundle.erc1155s, user);
    }

    function withdrawERC20(ERC20Rewards memory erc20s, address user) internal {
        for (uint256 x = 0; x < erc20s.tokens.length; x++) {
            IMERC20(erc20s.tokens[x]).mint(user, erc20s.qtys[x]);
        }
    }

    function withdrawERC721(ERC721Rewards memory erc721s, address user) internal {
        for (uint256 x = 0; x < erc721s.tokens.length; x++) {
            IMERC721(erc721s.tokens[x]).mint(user);
        }
    }

    function withdrawERC1155(ERC1155Rewards memory erc1155s, address user) internal {
        for (uint256 x = 0; x < erc1155s.tokens.length; x++) {
            IMERC1155(erc1155s.tokens[x]).batchMint(user, erc1155s.ids[x], erc1155s.qtys[x], "");
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                                BURN
    //////////////////////////////////////////////////////////////////////*/

    function burnTokenBundle(TokenBundle memory bundle) public {
        for (uint256 x = 0; x < bundle.erc20s.tokens.length; x++) {
            IMERC20(bundle.erc20s.tokens[x]).burn(msg.sender, bundle.erc20s.qtys[x]);
        }
        for (uint256 x = 0; x < bundle.erc721s.tokens.length; x++) {
            IMERC721(bundle.erc721s.tokens[x]).burn(msg.sender, bundle.erc721s.ids[x]);
        }
        for (uint256 x = 0; x < bundle.erc1155s.tokens.length; x++) {
            IMERC1155(bundle.erc1155s.tokens[x]).batchBurn(
                msg.sender,
                bundle.erc1155s.ids[x],
                bundle.erc1155s.qtys[x]
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @dev constants used throughout our contracts
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

struct TokenBundle {
    /**
    qty-> number of bundles to give out, if you want to give infinite number of bundles then,
   qty == type(uint).max. if you want an infinite number of bundles,
   then use a finite number.
   */
    uint256 qty;
    ERC20Rewards erc20s;
    ERC721Rewards erc721s;
    ERC1155Rewards erc1155s;
}

struct ERC20Rewards {
    address[] tokens;
    uint256[] qtys;
}

struct ERC721Rewards {
    address[] tokens;
    //only relevant for workshop, dont need to specify in pass/lootbox since 721s are implementation dependent
    uint256[] ids;
}

struct ERC1155Rewards {
    address[] tokens;
    uint256[][] qtys;
    uint256[][] ids;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC20 is IAccessControl {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC721 is IAccessControl {
    function mint(address to) external;

    function burn(address from, uint256 id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC1155 is IAccessControl {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
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