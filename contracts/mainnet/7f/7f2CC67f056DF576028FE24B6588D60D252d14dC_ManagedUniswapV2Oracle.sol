//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./UniswapV2Oracle.sol";

import "./AccessControl.sol";

import "./Roles.sol";

contract ManagedUniswapV2Oracle is AccessControl, UniswapV2Oracle {
    constructor(
        address liquidityAccumulator_,
        address uniswapFactory_,
        bytes32 initCodeHash_,
        address quoteToken_,
        uint256 period_
    ) UniswapV2Oracle(liquidityAccumulator_, uniswapFactory_, initCodeHash_, quoteToken_, period_) {
        initializeRoles();
    }

    /**
     * @notice Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */

    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            require(hasRole(role, msg.sender), "ManagedUniswapV2Oracle: MISSING_ROLE");
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, UniswapV2Oracle)
        returns (bool)
    {
        return interfaceId == type(IAccessControl).interfaceId || UniswapV2Oracle.supportsInterface(interfaceId);
    }

    function initializeRoles() internal virtual {
        // Setup admin role, setting msg.sender as admin
        _setupRole(Roles.ADMIN, msg.sender);
        _setRoleAdmin(Roles.ADMIN, Roles.ADMIN);

        // Set admin of ORACLE_UPDATER as ADMIN
        _setRoleAdmin(Roles.ORACLE_UPDATER, Roles.ADMIN);
    }

    function _update(address token) internal virtual override onlyRoleOrOpenRole(Roles.ORACLE_UPDATER) returns (bool) {
        return super._update(token);
    }
}