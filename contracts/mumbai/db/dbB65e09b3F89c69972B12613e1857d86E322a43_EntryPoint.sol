// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { IEntryPoint, UserOperationVariant } from "./interfaces/IEntryPoint.sol";
import { IAccount } from "./interfaces/IAccount.sol";
import { IAccountFactory } from "./interfaces/IAccountFactory.sol";

contract EntryPoint is IEntryPoint {
    IAccountFactory public accountFactory;

    constructor(IAccountFactory _accountFactory) {
        accountFactory = _accountFactory;
    }

    function handleOps(UserOperationVariant[] calldata ops) external {
        for (uint256 i = 0; i < ops.length; i++) {
            UserOperationVariant calldata op = ops[i];

            address sender = op.sender;

            if (sender == address(0)) {
                sender = accountFactory.createAccount(op.commitment);
            }

            try IAccount(sender).validateUserOp(op) returns (uint256) {} catch {
                revert("EntryPoint: invalid UserOperationVariant");
            }

            require(
                IAccount(sender).verify(op.commitment, op.proof),
                "EntryPoint: invalid proof"
            );

            if (op.callData.length == 0) {
                continue;
            }

            require(
                _handleOp(sender, 0, op.callData, op.callGasLimit),
                "EntryPoint: _handleOp failed"
            );
        }
    }

    function _handleOp(
        address to,
        uint256 value,
        bytes memory callData,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(
                txGas,
                to,
                value,
                add(callData, 0x20),
                mload(callData),
                0,
                0
            )
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { UserOperationVariant } from "./UserOperationVariant.sol";

interface IAccount {
    struct CommitmentProof {
        bytes commitment;
        bytes proof;
    }

    function validateUserOp(
        UserOperationVariant calldata userOp
    ) external returns (uint256 validationData);

    function verify(
        bytes calldata commitment,
        bytes calldata proof
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IAccountFactory {
    function createAccount(
        bytes calldata _commitment
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { UserOperationVariant } from "./UserOperationVariant.sol";

interface IEntryPoint {
    function handleOps(UserOperationVariant[] calldata ops) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

struct UserOperationVariant {
    address sender;
    bytes callData;
    bytes commitment;
    bytes proof;
    uint256 callGasLimit;
}