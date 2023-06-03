// Step 1
// create a smart contract wallet that executes user operations
// Step 2
// allow an executor to pay for gas and get reimbursed using the smart contract wallet

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IWorldIDGroups } from "./interfaces/IWorldIDGroups.sol";

contract WorldcoinSmartWallet {
  address authorized;

  constructor(address _owner) {
    authorized = _owner;
  }

  modifier onlyAuthorized() {
    require(msg.sender == authorized);
    _;
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

//   function verify(
//         uint256 root,
//         // uint256 signalHash,
//         // uint256 nullifierHash,
//         // uint256 externalNullifierHash,
//         // uint256[8] calldata proof
//     ) external {
//         IWorldIDGroups(address(0x719683F13Eeea7D84fCBa5d7d17Bf82e03E3d260))
//             .verifyProof(
//                 root,
//                 0, // Or `0` if you want to check for phone verification only
//                 abi.encodePacked("0x7730809Fde523F8A8b064787Aa32Eb0df40768fC").hashToField(),
//                 nullifierHash,
//                 abi.encodePacked("app_staging_23b713ea1ef2e814d19b3550de74409f").hashToField(),
//                 proof
//             );
//     }

  function executeUserOperation(
    bytes calldata userOp,
    uint256 chainID,
    address addressToExecute
    // uint256 nullifierHash,
    // uint256[8] calldata proof
    ) external {
    // (bool success, bytes memory data) = addressToExecute.call({value: userOp});
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { IBaseWorldID } from "./IBaseWorldID.sol";

interface IWorldIDGroups is IBaseWorldID {
   function verifyProof(
        uint256 groupId,
        uint256 root,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IBaseWorldID {
    error ExpiredRoot();

    error NonExistentRoot();
}