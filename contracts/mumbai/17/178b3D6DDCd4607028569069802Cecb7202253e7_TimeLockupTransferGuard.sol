//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../interfaces/ITransferGuard.sol";

contract TimeLockupTransferGuard is TransferGuardBase {
    function checkTransfer(
        address, /* asset */
        address initiator,
        address sender,
        address, /* receiver */
        uint256, /* quantity */
        bytes memory data
    ) external view override {
        (
            uint32 unlockTime,
            address[] memory approvedSenders,
            address[] memory approvedInitiators
        ) = abi.decode(data, (uint32, address[], address[]));

        for (uint256 i = 0; i < approvedInitiators.length; ++i) {
            if (initiator == approvedInitiators[i]) {
                return;
            }
        }

        for (uint256 i = 0; i < approvedSenders.length; ++i) {
            if (sender == approvedSenders[i]) {
                return;
            }
        }

        require(block.timestamp >= unlockTime, "asset timelocked");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title an interface enabling pluggable criteria for transfer agents to validate transactions
 */
interface ITransferGuard {
    /**
     * @notice this function is called for any asset transfer, and should revert if the transfer is invalid
     * @param asset the address of the asset being transferred
     * @param initiator the address of the account initiating this transaction
     * @param sender the address of the account sending the asset
     * @param receiver the address of the account receiving the asset
     * @param quantity the number of tokens being sent
     * @param data any additional parameters needed to perform this check; this data is application-specific
     */
    function checkTransfer(
        address asset,
        address initiator,
        address sender,
        address receiver,
        uint256 quantity,
        bytes memory data
    ) external;

    /// @notice contracts must implement this function to indicate that they can be used as a transfer guard
    /// @return result keccak256("checkTransfer(address,address,address,uint,bytes)") iff the contract supports this interface
    function isTransferGuard() external pure returns (bytes32);
}

abstract contract TransferGuardBase is ITransferGuard {
    bytes32 public constant _TRANSFER_GUARD_HASH =
        keccak256("checkTransfer(address,address,address,address,uint,bytes)");

    function isTransferGuard() external pure override returns (bytes32) {
        return _TRANSFER_GUARD_HASH;
    }
}