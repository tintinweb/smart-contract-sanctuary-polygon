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
                sender = accountFactory.createAccount();
                continue;
            }

            try IAccount(sender).validateUserOp(op) returns (uint256) {} catch {
                revert("EntryPoint: invalid UserOperationVariant");
            }

            require(
                IAccount(sender).verify(op.worldIDVerification),
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
import { WorldIDVerification } from "./WorldIDVerification.sol";

interface IAccount {
    struct CommitmentProof {
        bytes commitment;
        bytes proof;
    }

    function validateUserOp(
        UserOperationVariant calldata userOp
    ) external returns (uint256 validationData);

    function verify(
        WorldIDVerification calldata worldIDVerification
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IAccountFactory {
    function createAccount() external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { UserOperationVariant } from "./UserOperationVariant.sol";

interface IEntryPoint {
    function handleOps(UserOperationVariant[] calldata ops) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { WorldIDVerification } from "./WorldIDVerification.sol";

struct UserOperationVariant {
    address sender;
    WorldIDVerification worldIDVerification;
    bytes callData;
    uint256 callGasLimit;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

struct WorldIDVerification {
    uint256 root;
    uint256 group;
    string signal;
    uint256 nullifierHash;
    string appID;
    string actionID;
    uint256[8] proof;
}