// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IAddressListRegistry} from "./IAddressListRegistry.sol";

/// @title EnzymeUtils
/// @dev Treat this like an external library - pure external functions only, no state.
/// @notice Helper library for interacting with Enzyme vaults.
contract EnzymeUtils {
    /// @notice Encode config for `ManagementFee#addFundSettings`
    /// @param scaledPerSecondRate must be > 0
    /// @param recipient fund manager
    /// @return raw bytes to be passed into `_settingsData`
    function encodeManagementFeeConfig(
        uint128 scaledPerSecondRate,
        address recipient
    ) external pure returns (bytes memory) {
        return abi.encode(scaledPerSecondRate, recipient);
    }

    /// @notice Helper to encode config for a single Enzyme policy that inherit AddressListRegistryPolicyBase
    /// @param addressesToAdd Addresses to add to the config
    function encodeAddressListRegistryPolicyConfig(
        address[] memory addressesToAdd
    ) external pure returns (bytes memory) {
        // PolicyManager#__enablePolicyForFund[1] -> Policy#addFundSettings[2] -> Policy#__updateListsForFund[3]
        // [1] https://github.com/enzymefinance/protocol/blob/v4/contracts/release/extensions/policy-manager/PolicyManager.sol#L231
        // [2] https://github.com/enzymefinance/protocol/blob/v4/contracts/release/extensions/policy-manager/policies/utils/AddressListRegistryPolicyBase.sol#L46
        // [3] https://github.com/enzymefinance/protocol/blob/v4/contracts/release/extensions/policy-manager/policies/utils/AddressListRegistryPolicyBase.sol#L84
        uint256[] memory existingListIds;
        // Policy#__createAddressListFromData -> Policy#__decodeNewListData
        bytes[] memory newListsData = new bytes[](1);
        newListsData[0] = abi.encode(
            IAddressListRegistry.UpdateType.AddOnly,
            addressesToAdd
        ); // (UpdateType, address[])
        // https://github.com/enzymefinance/protocol/blob/v4/contracts/release/extensions/policy-manager/PolicyManager.sol#L145
        return abi.encode(existingListIds, newListsData);
    }

    /// @notice Helper to encode config for an Enzyme entrance fee
    /// @param rateBps rate to tax depositors upon entering the vault, in bps
    /// @param recipient address that will receive this fee
    function encodeEntranceFeeConfig(
        uint256 rateBps,
        address recipient
    ) external pure returns (bytes memory) {
        return abi.encode(rateBps, recipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

interface IAddressListRegistry {
    enum UpdateType {
        None,
        AddOnly,
        RemoveOnly,
        AddAndRemove
    }
}