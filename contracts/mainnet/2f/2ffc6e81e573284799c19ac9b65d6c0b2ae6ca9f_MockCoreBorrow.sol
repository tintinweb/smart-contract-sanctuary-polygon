/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

/// @title ICoreBorrow
/// @author Angle Core Team
/// @notice Interface for the `CoreBorrow` contract
/// @dev This interface only contains functions of the `CoreBorrow` contract which are called by other contracts
/// of this module
interface ICoreBorrow {
    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

contract MockCoreBorrow is ICoreBorrow {
    mapping(address => bool) public governors;
    mapping(address => bool) public guardians;

    function isGovernor(address admin) external view returns (bool) {
        return governors[admin];
    }

    function isGovernorOrGuardian(address admin) external view returns (bool) {
        return guardians[admin] || governors[admin];
    }

    function toggleGovernor(address admin) external {
        governors[admin] = !governors[admin];
    }

    function toggleGuardian(address admin) external {
        guardians[admin] = !guardians[admin];
    }
}