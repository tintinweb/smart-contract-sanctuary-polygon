// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Input Implementation
pragma solidity ^0.8.0;

import "./Input.sol";
import "./Rollups.sol";

contract InputImpl is Input {
    Rollups immutable rollups; // rollups contract using this input contract

    // always needs to keep track of two input boxes:
    // 1 for the input accumulation of next epoch
    // and 1 for the messages during current epoch. To save gas we alternate
    // between inputBox0 and inputBox1
    bytes32[] inputBox0;
    bytes32[] inputBox1;

    uint256 immutable inputDriveSize; // size of input flashdrive
    uint256 currentInputBox;

    /// @param _rollups address of rollups contract that will manage inboxes
    /// @param _log2Size size of the input drive of the machine
    constructor(address _rollups, uint256 _log2Size) {
        require(_log2Size >= 3 && _log2Size <= 64, "log size: [3,64]");

        rollups = Rollups(_rollups);
        inputDriveSize = (1 << _log2Size);
    }

    /// @notice add input to processed by next epoch
    /// @param _input input to be understood by offchain machine
    /// @dev offchain code is responsible for making sure
    ///      that input size is power of 2 and multiple of 8 since
    // the offchain machine has a 8 byte word
    function addInput(bytes calldata _input) public override returns (bytes32) {
        require(
            _input.length > 0 && _input.length <= inputDriveSize,
            "input len: (0,driveSize]"
        );

        // notifyInput returns true if that input
        // belongs to a new epoch
        if (rollups.notifyInput()) {
            swapInputBox();
        }

        // points to correct inputBox
        bytes32[] storage inputBox = currentInputBox == 0 ? inputBox0 : inputBox1;

        // keccak 64 bytes into 32 bytes
        bytes32 keccakMetadata =
            keccak256(
                abi.encode(
                    msg.sender,
                    block.number,
                    block.timestamp,
                    rollups.getCurrentEpoch(), // epoch index
                    inputBox.length // input index
                )
            );

        bytes32 keccakInput = keccak256(_input);

        bytes32 inputHash = keccak256(abi.encode(keccakMetadata, keccakInput));

        // add input to correct inbox
        inputBox.push(inputHash);

        emit InputAdded(
            rollups.getCurrentEpoch(),
            msg.sender,
            block.timestamp,
            _input
        );

        return inputHash;
    }

    /// @notice get input inside inbox of currently proposed claim
    /// @param _index index of input inside that inbox
    /// @return hash of input at index _index
    /// @dev currentInputBox being zero means that the inputs for
    ///      the claimed epoch are on input box one
    function getInput(uint256 _index) public view override returns (bytes32) {
        return currentInputBox == 0 ? inputBox1[_index] : inputBox0[_index];
    }

    /// @notice get number of inputs inside inbox of currently proposed claim
    /// @return number of inputs on that input box
    /// @dev currentInputBox being zero means that the inputs for
    ///      the claimed epoch are on input box one
    function getNumberOfInputs() public view override returns (uint256) {
        return currentInputBox == 0 ? inputBox1.length : inputBox0.length;
    }

    /// @notice get inbox currently receiveing inputs
    /// @return input inbox currently receiveing inputs
    function getCurrentInbox() public view override returns (uint256) {
        return currentInputBox;
    }

    /// @notice called when a new input accumulation phase begins
    ///         swap inbox to receive inputs for upcoming epoch
    /// @dev can only be called by Rollups contract
    function onNewInputAccumulation() public override {
        onlyRollups();
        swapInputBox();
    }

    /// @notice called when a new epoch begins, clears deprecated inputs
    /// @dev can only be called by Rollups contract
    function onNewEpoch() public override {
        // clear input box for new inputs
        // the current input box should be accumulating inputs
        // for the new epoch already. So we clear the other one.
        onlyRollups();
        currentInputBox == 0 ? delete inputBox1 : delete inputBox0;
    }

    /// @notice check if message sender is Rollups
    function onlyRollups() internal view {
        require(msg.sender == address(rollups), "Only rollups");
    }

    /// @notice changes current input box
    function swapInputBox() internal {
        currentInputBox == 0 ? currentInputBox = 1 : currentInputBox = 0;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Input
pragma solidity >=0.7.0;

interface Input {
    /// @notice adds input to correct inbox
    /// @param _input bytes array of input
    /// @return merkle root hash of input
    /// @dev  msg.sender and timestamp are preppended log2 size
    ///       has to be calculated offchain taking that into account
    function addInput(bytes calldata _input) external returns (bytes32);

    /// @notice returns input from correct input inbox
    /// @param _index position of the input on inbox
    /// @return root hash of input
    function getInput(uint256 _index) external view returns (bytes32);

    /// @notice returns number of inputs on correct inbox
    /// @return number of inputs of non active inbox
    function getNumberOfInputs() external view returns (uint256);

    /// @notice returns active current inbox index
    /// @return index of current active inbox
    function getCurrentInbox() external view returns (uint256);

    /// @notice called whenever there is a new input accumulation epoch
    /// @dev has to be  called even if new input accumulation happens
    ///      implicitly due to a new epoch
    function onNewInputAccumulation() external;

    /// @notice called when a new epoch begins, clears correct input box
    function onNewEpoch() external;

    /// @notice input added
    /// @param _epochNumber which epoch this input belongs to
    /// @param _sender msg.sender
    /// @param _timestamp block.timestamp
    /// @param _input input data
    event InputAdded(
        uint256 indexed _epochNumber,
        address _sender,
        uint256 _timestamp,
        bytes _input
    );
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface Rollups contract
pragma solidity >=0.7.0;

import "./Input.sol";
import "./Output.sol";
import "./ValidatorManager.sol";

interface Rollups {
    // InputAccumulation - Inputs being accumulated for currrent epoch
    // AwaitingConsensus - No disagreeing claims (or no claims)
    // AwaitingDispute - Waiting for dispute to be over
    // inputs received during InputAccumulation will be included in the
    // current epoch. Inputs received while WaitingClaims or ChallengesInProgress
    // are accumulated for the next epoch
    enum Phase {InputAccumulation, AwaitingConsensus, AwaitingDispute}

    /// @notice claim the result of current epoch
    /// @param _epochHash hash of epoch
    /// @dev ValidatorManager makes sure that msg.sender is allowed
    //       and that claim != bytes32(0)
    /// TODO: add signatures for aggregated claims
    function claim(bytes32 _epochHash) external;

    /// @notice finalize epoch after timeout
    /// @dev can only be called if challenge period is over
    function finalizeEpoch() external;

    /// @notice called when new input arrives, manages the phase changes
    /// @dev can only be called by input contract
    function notifyInput() external returns (bool);

    /// @notice called when a dispute is resolved by the dispute manager
    /// @param _winner winner of dispute
    /// @param _loser lose of sipute
    /// @param _winningClaim initial claim of winning validator
    /// @dev can only by the dispute contract
    function resolveDispute(
        address payable _winner,
        address payable _loser,
        bytes32 _winningClaim
    ) external;

    /// @notice returns index of current (accumulating) epoch
    /// @return index of current epoch
    /// @dev if phase is input accumulation, then the epoch number is length
    //       of finalized epochs array, else there are two epochs two non
    //       finalized epochs, one awaiting consensus/dispute and another
    //      accumulating input
    function getCurrentEpoch() external view returns (uint256);

    /// @notice returns address of input contract
    function getInputAddress() external view returns (address);

    /// @notice returns address of output contract
    function getOutputAddress() external view returns (address);

    /// @notice returns address of validator manager contract
    function getValidatorManagerAddress() external view returns (address);

    /// @notice returns address of dispute manager contract
    function getDisputeManagerAddress() external view returns (address);

    // events

    /// @notice contract created
    /// @param _input address of input contract
    /// @param _output address of output contract
    /// @param _validatorManager address of validatorManager contract
    /// @param _disputeManager address of disputeManager contract
    /// @param _inputDuration duration of input accumulation phase in seconds
    /// @param _challengePeriod duration of challenge period in seconds
    event RollupsCreated(
        address _input,
        address _output,
        address _validatorManager,
        address _disputeManager,
        uint256 _inputDuration,
        uint256 _challengePeriod
    );

    /// @notice claim submitted
    /// @param _epochHash claim being submitted by this epoch
    /// @param _claimer address of current claimer
    /// @param _epochNumber number of the epoch being submitted
    event Claim(uint256 indexed _epochNumber, address _claimer, bytes32 _epochHash);

    /// @notice epoch finalized
    /// @param _epochNumber number of the epoch being finalized
    /// @param _epochHash claim being submitted by this epoch
    event FinalizeEpoch(uint256 indexed _epochNumber, bytes32 _epochHash);

    /// @notice dispute resolved
    /// @param _winner winner of dispute
    /// @param _loser loser of dispute
    /// @param _winningClaim initial claim of winning validator
    event ResolveDispute(
        address _winner,
        address _loser,
        bytes32 _winningClaim
    );

    /// @notice phase change
    /// @param _newPhase new phase
    event PhaseChange(Phase _newPhase);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Output
pragma solidity >=0.7.0;

interface Output {
    /// @param _epochIndex which epoch the output belongs to
    /// @param _inputIndex which input, inside the epoch, the output belongs to
    /// @param _outputIndex index of output inside the input
    /// @param _outputMetadataArrayDriveHash hash of the output's metadata drive where this output is in
    /// @param _epochVoucherDriveHash merkle root of all epoch's voucher metadata drive hashes
    /// @param _epochNoticeDriveHash hash of NoticeMetadataArrayDrive
    /// @param _epochMachineFinalState hash of the machine state claimed this epoch
    /// @param _outputMetadataProof proof that this output's metadata is in meta data drive
    /// @param _epochOutputDriveProof proof that this output metadata drive is in epoch's Output drive
    struct OutputValidityProof {
        uint256 epochIndex;
        uint256 inputIndex;
        uint256 outputIndex;
        bytes32 outputMetadataArrayDriveHash;
        bytes32 epochVoucherDriveHash;
        bytes32 epochNoticeDriveHash;
        bytes32 epochMachineFinalState;
        bytes32[] outputMetadataProof;
        bytes32[] epochOutputDriveProof;
    }

    /// @notice executes voucher
    /// @param _destination address that will execute the payload
    /// @param _payload payload to be executed by destination
    /// @param _v validity proof for this encoded voucher
    /// @return true if voucher was executed successfully
    /// @dev  vouchers can only be executed once
    function executeVoucher(
        address _destination,
        bytes calldata _payload,
        OutputValidityProof calldata _v
    ) external returns (bool);

    /// @notice called by rollups when an epoch is finalized
    /// @param _epochHash hash of finalized epoch
    /// @dev an epoch being finalized means that its vouchers can be called
    function onNewEpoch(bytes32 _epochHash) external;

    /// @notice get number of finalized epochs
    function getNumberOfFinalizedEpochs() external view returns (uint256);

    /// @notice get log2 size of voucher metadata drive
    function getVoucherMetadataLog2Size()
        external
        pure
        returns (uint256);

    /// @notice get log2 size of epoch voucher drive
    function getEpochVoucherLog2Size()
        external
        pure
        returns (uint256);

    /// @notice get log2 size of notice metadata drive
    function getNoticeMetadataLog2Size()
        external
        pure
        returns (uint256);

    /// @notice get log2 size of epoch notice drive
    function getEpochNoticeLog2Size()
        external
        pure
        returns (uint256);

    event VoucherExecuted(uint256 voucherPosition);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Validator Manager
pragma solidity >=0.7.0;

// TODO: What is the incentive for validators to not just copy the first claim that arrived?
interface ValidatorManager {
    // NoConflict - No conflicting claims or consensus
    // Consensus - All validators had equal claims
    // Conflict - Claim is conflicting with previous one
    enum Result {NoConflict, Consensus, Conflict}

    // @notice called when a claim is received by rollups
    // @params _sender address of sender of that claim
    // @params _claim claim received by rollups
    // @returns result of claim, signaling current state of claims
    function onClaim(address payable _sender, bytes32 _claim)
        external
        returns (
            Result,
            bytes32[2] memory claims,
            address payable[2] memory claimers
        );

    // @notice called when a dispute ends in rollups
    // @params _winner address of dispute winner
    // @params _loser address of dispute loser
    // @returns result of dispute being finished
    function onDisputeEnd(
        address payable _winner,
        address payable _loser,
        bytes32 _winningClaim
    )
        external
        returns (
            Result,
            bytes32[2] memory claims,
            address payable[2] memory claimers
        );

    // @notice called when a new epoch starts
    function onNewEpoch() external returns (bytes32);

    // @notice get current claim
    function getCurrentClaim() external view returns (bytes32);

    // @notice emitted on Claim received
    event ClaimReceived(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    // @notice emitted on Dispute end
    event DisputeEnded(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    // @notice emitted on new Epoch
    event NewEpoch(bytes32 claim);
}