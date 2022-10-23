//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../interfaces/IApprovals.sol";
import "../../interfaces/ITransferGuard.sol";

/**
 * @title ensures that an asset can only be transferred between users who have been approved
 * @notice the approval contract address and approval level must be provided as parameters to the `checkTransfer` call
 */
contract ApprovalTransferGuard is TransferGuardBase {
    function checkTransfer(
        address, /* asset */
        address, /* initiator */
        address sender,
        address receiver,
        uint256, /* quantity */
        bytes memory data
    ) external view override {
        (address approvalsContract, uint256 level) = abi.decode(data, (address, uint256));

        // XXX: make these messages include approval contract address, since there could be multiple approval checks for a single transfer
        require(
            sender == address(0) ||
                IFiboApprovals(approvalsContract).getUserApprovalLevel(sender) >= level,
            "sender not approved"
        );
        require(
            receiver == address(0) ||
                IFiboApprovals(approvalsContract).getUserApprovalLevel(receiver) >= level,
            "receiver not approved"
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFiboApprovals {
    function setUserApproval(
        address user,
        uint256 level,
        uint256 expiration
    ) external;

    function getUserApprovalLevel(address user) external view returns (uint256 level);
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