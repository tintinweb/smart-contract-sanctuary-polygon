// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IOwnable} from "../interfaces/IOwnable.sol";

/// @notice this contract would be changing the address of the treasury owner
contract UpgradeTreasuryAddressFacet {
    /// @notice error message
    error CannotBeAddressZero();

    /// @notice this function would be used for updating the address of the treasury
    /// @param _oldAddress: previous address of the treasury owner
    /// @param _newAddress: new addresss of the treasury owner
    function changeTreasuryOwnerAddress(address _oldAddress, address _newAddress) external {
        if (_newAddress == address(0) || _oldAddress == address(0)) {
            revert CannotBeAddressZero();
        }
        IOwnable(_oldAddress).transferManagment(_newAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Ownable contract.
 */
interface IOwnable {
    function transferManagment(address _newOwner) external;
}