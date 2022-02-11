// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Rollups Impl
pragma solidity ^0.8.0;

import "./InputImpl.sol";
import "./OutputImpl.sol";
import "./ValidatorManagerImpl.sol";
import "./Rollups.sol";
import "./DisputeManagerImpl.sol";

contract RollupsImpl is Rollups {
    ////
    //                             All claims agreed OR challenge period ended
    //                              functions: claim() or finalizeEpoch()
    //                        +--------------------------------------------------+
    //                        |                                                  |
    //               +--------v-----------+   new input after IPAD     +---------+----------+
    //               |                    +--------------------------->+                    |
    //   START  ---> | Input Accumulation |   firt claim after IPAD    | Awaiting Consensus |
    //               |                    +--------------------------->+                    |
    //               +-+------------------+                            +-----------------+--+
    //                 ^                                                                 ^  |
    //                 |                                              dispute resolved   |  |
    //                 |  dispute resolved                            before challenge   |  |
    //                 |  after challenge     +--------------------+  period ended       |  |
    //                 |  period ended        |                    +---------------------+  |
    //                 +----------------------+  Awaiting Dispute  |                        |
    //                                        |                    +<-----------------------+
    //                                        +--------------------+    conflicting claim
    ///

    InputImpl public input; // contract responsible for inputs
    OutputImpl public output; // contract responsible for outputs
    ValidatorManagerImpl public validatorManager; // contract responsible for validators
    DisputeManagerImpl public disputeManager; // contract responsible for dispute resolution

    struct StorageVar {
        uint32 inputDuration; // duration of input accumulation phase in seconds
        uint32 challengePeriod; // duration of challenge period in seconds
        uint32 inputAccumulationStart; // timestamp when current input accumulation phase started
        uint32 sealingEpochTimestamp; // timestamp on when a proposed epoch (claim) becomes challengeable
        uint32 currentPhase_int; // current phase in integer form
    }
    StorageVar public storageVar;

    /// @notice functions modified by onlyInputContract can only be called
    // by input contract
    modifier onlyInputContract {
        require(msg.sender == address(input), "only Input Contract");
        _;
    }

    /// @notice functions modified by onlyDisputeContract can only be called
    // by dispute contract
    modifier onlyDisputeContract {
        require(msg.sender == address(disputeManager), "only Dispute Contract");
        _;
    }

    /// @notice creates contract
    /// @param _inputDuration duration of input accumulation phase in seconds
    /// @param _challengePeriod duration of challenge period in seconds
    /// @param _inputLog2Size size of the input drive in this machine
    /// @param _validators initial validator set
    constructor(
        uint256 _inputDuration,
        uint256 _challengePeriod,
        // input constructor variables
        uint256 _inputLog2Size,
        // validator manager constructor variables
        address payable[] memory _validators
    ) {
        input = new InputImpl(address(this), _inputLog2Size);
        output = new OutputImpl(address(this));
        validatorManager = new ValidatorManagerImpl(address(this), _validators);
        disputeManager = new DisputeManagerImpl(address(this));

        storageVar = StorageVar(
            uint32(_inputDuration),
            uint32(_challengePeriod),
            uint32(block.timestamp),
            0,
            uint32(Phase.InputAccumulation)
        );

        emit RollupsCreated(
            address(input),
            address(output),
            address(validatorManager),
            address(disputeManager),
            _inputDuration,
            _challengePeriod
        );
    }

    /// @notice claim the result of current epoch
    /// @param _epochHash hash of epoch
    /// @dev ValidatorManager makes sure that msg.sender is allowed
    //       and that claim != bytes32(0)
    /// TODO: add signatures for aggregated claims
    function claim(bytes32 _epochHash) public override {
        ValidatorManager.Result result;
        bytes32[2] memory claims;
        address payable[2] memory claimers;

        Phase currentPhase = Phase(storageVar.currentPhase_int);
        uint256 inputAccumulationStart = storageVar.inputAccumulationStart;
        uint256 inputDuration = storageVar.inputDuration;

        if (
            currentPhase == Phase.InputAccumulation &&
            block.timestamp > inputAccumulationStart + inputDuration
        ) {
            currentPhase = Phase.AwaitingConsensus;
            storageVar.currentPhase_int = uint32(Phase.AwaitingConsensus);
            emit PhaseChange(Phase.AwaitingConsensus);

            // warns input of new epoch
            input.onNewInputAccumulation();
            // update timestamp of sealing epoch proposal
            storageVar.sealingEpochTimestamp = uint32(block.timestamp);
        }

        require(
            currentPhase == Phase.AwaitingConsensus,
            "Phase != AwaitingConsensus"
        );
        (result, claims, claimers) = validatorManager.onClaim(
            payable(msg.sender),
            _epochHash
        );

        // emit the claim event before processing it
        // so if the epoch is finalized in this claim (consensus)
        // the number of final epochs doesnt gets contaminated
        emit Claim(output.getNumberOfFinalizedEpochs(), msg.sender, _epochHash);

        resolveValidatorResult(result, claims, claimers);
    }

    /// @notice finalize epoch after timeout
    /// @dev can only be called if challenge period is over
    function finalizeEpoch() public override {
        Phase currentPhase = Phase(storageVar.currentPhase_int);
        require(
            currentPhase == Phase.AwaitingConsensus,
            "Phase != Awaiting Consensus"
        );

        uint256 sealingEpochTimestamp = storageVar.sealingEpochTimestamp;
        uint256 challengePeriod = storageVar.challengePeriod;
        require(
            block.timestamp > sealingEpochTimestamp + challengePeriod,
            "Challenge period not over"
        );

        require(
            validatorManager.getCurrentClaim() != bytes32(0),
            "No Claim to be finalized"
        );

        startNewEpoch();
    }

    /// @notice called when new input arrives, manages the phase changes
    /// @dev can only be called by input contract
    function notifyInput() public override onlyInputContract returns (bool) {
        Phase currentPhase = Phase(storageVar.currentPhase_int);
        uint256 inputAccumulationStart = storageVar.inputAccumulationStart;
        uint256 inputDuration = storageVar.inputDuration;

        if (
            currentPhase == Phase.InputAccumulation &&
            block.timestamp > inputAccumulationStart + inputDuration
        ) {
            storageVar.currentPhase_int = uint32(Phase.AwaitingConsensus);
            emit PhaseChange(Phase.AwaitingConsensus);
            return true;
        }
        return false;
    }

    /// @notice called when a dispute is resolved by the dispute manager
    /// @param _winner winner of dispute
    /// @param _loser loser of dispute
    /// @param _winningClaim initial claim of winning validator
    /// @dev can only be called by the dispute contract
    function resolveDispute(
        address payable _winner,
        address payable _loser,
        bytes32 _winningClaim
    ) public override onlyDisputeContract {
        ValidatorManager.Result result;
        bytes32[2] memory claims;
        address payable[2] memory claimers;

        (result, claims, claimers) = validatorManager.onDisputeEnd(
            _winner,
            _loser,
            _winningClaim
        );

        // restart challenge period
        storageVar.sealingEpochTimestamp = uint32(block.timestamp);

        emit ResolveDispute(_winner, _loser, _winningClaim);
        resolveValidatorResult(result, claims, claimers);
    }

    /// @notice starts new epoch
    function startNewEpoch() internal {
        // reset input accumulation start and deactivate challenge period start
        storageVar.currentPhase_int = uint32(Phase.InputAccumulation);
        emit PhaseChange(Phase.InputAccumulation);
        storageVar.inputAccumulationStart = uint32(block.timestamp);
        storageVar.sealingEpochTimestamp = type(uint32).max;

        bytes32 finalClaim = validatorManager.onNewEpoch();

        // emit event before finalized epoch is added to the Output contract's storage
        emit FinalizeEpoch(output.getNumberOfFinalizedEpochs(), finalClaim);

        output.onNewEpoch(finalClaim);
        input.onNewEpoch();
    }

    /// @notice resolve results returned by validator manager
    /// @param _result result from claim or dispute operation
    /// @param _claims array of claims in case of new conflict
    /// @param _claimers array of claimers in case of new conflict
    function resolveValidatorResult(
        ValidatorManager.Result _result,
        bytes32[2] memory _claims,
        address payable[2] memory _claimers
    ) internal {
        if (_result == ValidatorManager.Result.NoConflict) {
            Phase currentPhase = Phase(storageVar.currentPhase_int);
            if (currentPhase != Phase.AwaitingConsensus) {
                storageVar.currentPhase_int = uint32(Phase.AwaitingConsensus);
                emit PhaseChange(Phase.AwaitingConsensus);
            }
        } else if (_result == ValidatorManager.Result.Consensus) {
            startNewEpoch();
        } else {
            // for the case when _result == ValidatorManager.Result.Conflict
            Phase currentPhase = Phase(storageVar.currentPhase_int);
            if (currentPhase != Phase.AwaitingDispute) {
                storageVar.currentPhase_int = uint32(Phase.AwaitingDispute);
                emit PhaseChange(Phase.AwaitingDispute);
            }
            disputeManager.initiateDispute(_claims, _claimers);
        }
    }

    /// @notice returns index of current (accumulating) epoch
    /// @return index of current epoch
    /// @dev if phase is input accumulation, then the epoch number is length
    //       of finalized epochs array, else there are two non finalized epochs,
    //       one awaiting consensus/dispute and another accumulating input

    function getCurrentEpoch() public view override returns (uint256) {
        uint256 finalizedEpochs = output.getNumberOfFinalizedEpochs();

        Phase currentPhase = Phase(storageVar.currentPhase_int);

        return
            currentPhase == Phase.InputAccumulation
                ? finalizedEpochs
                : finalizedEpochs + 1;
    }

    /// @notice returns address of input contract
    function getInputAddress() public view override returns (address) {
        return address(input);
    }

    /// @notice returns address of output contract
    function getOutputAddress() public view override returns (address) {
        return address(output);
    }

    /// @notice returns address of validator manager contract
    function getValidatorManagerAddress()
        public
        view
        override
        returns (address)
    {
        return address(validatorManager);
    }

    /// @notice returns address of dispute manager contract
    function getDisputeManagerAddress() public view override returns (address) {
        return address(disputeManager);
    }

    /// @notice returns the current phase
    function getCurrentPhase() public view returns (Phase) {
        Phase currentPhase = Phase(storageVar.currentPhase_int);
        return currentPhase;
    }

    /// @notice returns the input accumulation start timestamp
    function getInputAccumulationStart() public view returns (uint256) {
        uint256 inputAccumulationStart = storageVar.inputAccumulationStart;
        return inputAccumulationStart;
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

/// @title Output Implementation
pragma solidity ^0.8.0;

import "@cartesi/util/contracts/Bitmask.sol";
import "@cartesi/util/contracts/Merkle.sol";

import "./Output.sol";

contract OutputImpl is Output {
    // Here we only need 248 bits as keys in the mapping, but we use 256 bits for gas optimization
    using Bitmask for mapping(uint256 => uint256);

    uint256 constant KECCAK_LOG2_SIZE = 5; // keccak log2 size

    // max size of voucher metadata drive 32 * (2^16) bytes
    uint256 constant VOUCHER_METADATA_LOG2_SIZE = 21;
    // max size of epoch voucher drive 32 * (2^32) bytes
    uint256 constant EPOCH_VOUCHER_LOG2_SIZE = 37;

    // max size of notice metadata drive 32 * (2^16) bytes
    uint256 constant NOTICE_METADATA_LOG2_SIZE = 21;
    // max size of epoch notice drive 32 * (2^32) bytes
    uint256 constant EPOCH_NOTICE_LOG2_SIZE = 37;

    address immutable rollups; // rollups contract using this validator
    mapping(uint256 => uint256) internal voucherBitmask;
    bytes32[] epochHashes;

    bool lock; //reentrancy lock

    /// @notice functions modified by noReentrancy are not subject to recursion
    modifier noReentrancy() {
        require(!lock, "reentrancy not allowed");
        lock = true;
        _;
        lock = false;
    }

    /// @notice functions modified by onlyRollups will only be executed if
    // they're called by Rollups contract, otherwise it will throw an exception
    modifier onlyRollups {
        require(msg.sender == rollups, "Only rollups");
        _;
    }

    // @notice creates OutputImpl contract
    // @params _rollups address of rollupscontract
    constructor(address _rollups)
    {
        rollups = _rollups;
    }

    /// @notice executes voucher
    /// @param _encodedVoucher encoded voucher mocking the behaviour
    //          of abi.encode(address _destination, bytes _payload)
    /// @param _v validity proof for this encoded voucher
    /// @return true if voucher was executed successfully
    /// @dev  vouchers can only be executed once
    function executeVoucher(
        address _destination,
        bytes calldata _payload,
        OutputValidityProof calldata _v
    ) public override noReentrancy returns (bool) {
        bytes memory encodedVoucher = abi.encode(_destination, _payload);

        // check if validity proof matches the voucher provided
        isValidVoucherProof(encodedVoucher, epochHashes[_v.epochIndex], _v);

        uint256 voucherPosition =
            getBitMaskPosition(_v.outputIndex, _v.inputIndex, _v.epochIndex);

        // check if voucher has been executed
        require(
            !voucherBitmask.getBit(voucherPosition),
            "re-execution not allowed"
        );

        // execute voucher
        (bool succ, ) = address(_destination).call(_payload);

        // if properly executed, mark it as executed and emit event
        if (succ) {
            voucherBitmask.setBit(voucherPosition, true);
            emit VoucherExecuted(voucherPosition);
        }

        return succ;
    }

    /// @notice called by rollups when an epoch is finalized
    /// @param _epochHash hash of finalized epoch
    /// @dev an epoch being finalized means that its vouchers can be called
    function onNewEpoch(bytes32 _epochHash) public override onlyRollups {
        epochHashes.push(_epochHash);
    }

    /// @notice functions modified by isValidProof will only be executed if
    //  the validity proof is valid
    //  @dev _epochOutputDriveHash must be _v.epochVoucherDriveHash or
    //                                  or _v.epochNoticeDriveHash
    function isValidProof(
        bytes memory _encodedOutput,
        bytes32 _epochHash,
        bytes32 _epochOutputDriveHash,
        uint256 _epochOutputLog2Size,
        uint256 _outputMetadataLog2Size,
        OutputValidityProof calldata _v
    ) internal pure returns (bool) {
        // prove that outputs hash is represented in a finalized epoch
        require(
            keccak256(
                abi.encodePacked(
                    _v.epochVoucherDriveHash,
                    _v.epochNoticeDriveHash,
                    _v.epochMachineFinalState
                )
            ) == _epochHash,
            "epochHash incorrect"
        );

        // prove that output metadata drive is contained in epoch's output drive
        require(
            Merkle.getRootAfterReplacementInDrive(
                getIntraDrivePosition(_v.inputIndex, KECCAK_LOG2_SIZE),
                KECCAK_LOG2_SIZE,
                _epochOutputLog2Size,
                keccak256(abi.encodePacked(_v.outputMetadataArrayDriveHash)),
                _v.epochOutputDriveProof
            ) == _epochOutputDriveHash,
            "epochOutputDriveHash incorrect"
        );

        // The hash of the output is converted to bytes (abi.encode) and
        // treated as data. The metadata output drive stores that data while
        // being indifferent to its contents. To prove that the received
        // output is contained in the metadata output drive we need to
        // prove that x, where:
        // x = keccak(
        //          keccak(
        //              keccak(hashOfOutput[0:7]),
        //              keccak(hashOfOutput[8:15])
        //          ),
        //          keccak(
        //              keccak(hashOfOutput[16:23]),
        //              keccak(hashOfOutput[24:31])
        //          )
        //     )
        // is contained in it. We can't simply use hashOfOutput because the
        // log2size of the leaf is three (8 bytes) not  five (32 bytes)
        bytes32 merkleRootOfHashOfOutput =
            Merkle.getMerkleRootFromBytes(
                abi.encodePacked(keccak256(_encodedOutput)),
                KECCAK_LOG2_SIZE
            );

        // prove that merkle root hash of bytes(hashOfOutput) is contained
        // in the output metadata array drive
        require(
            Merkle.getRootAfterReplacementInDrive(
                getIntraDrivePosition(_v.outputIndex, KECCAK_LOG2_SIZE),
                KECCAK_LOG2_SIZE,
                _outputMetadataLog2Size,
                merkleRootOfHashOfOutput,
                _v.outputMetadataProof
            ) == _v.outputMetadataArrayDriveHash,
            "outputMetadataArrayDriveHash incorrect"
        );

        return true;
    }

    /// @notice functions modified by isValidVoucherProof will only be executed if
    //  the validity proof is valid
    function isValidVoucherProof(
        bytes memory _encodedVoucher,
        bytes32 _epochHash,
        OutputValidityProof calldata _v
    )
        public
        pure
        returns (bool)
    {
        return isValidProof(
            _encodedVoucher,
            _epochHash,
            _v.epochVoucherDriveHash,
            EPOCH_VOUCHER_LOG2_SIZE,
            VOUCHER_METADATA_LOG2_SIZE,
            _v
        );
    }

    /// @notice functions modified by isValidNoticeProof will only be executed if
    //  the validity proof is valid
    function isValidNoticeProof(
        bytes memory _encodedNotice,
        bytes32 _epochHash,
        OutputValidityProof calldata _v
    )
        public
        pure
        returns (bool)
    {
        return isValidProof(
            _encodedNotice,
            _epochHash,
            _v.epochNoticeDriveHash,
            EPOCH_NOTICE_LOG2_SIZE,
            NOTICE_METADATA_LOG2_SIZE,
            _v
        );
    }

    /// @notice get voucher position on bitmask
    /// @param _voucher of voucher inside the input
    /// @param _input which input, inside the epoch, the voucher belongs to
    /// @param _epoch which epoch the voucher belongs to
    /// @return position of that voucher on bitmask
    function getBitMaskPosition(
        uint256 _voucher,
        uint256 _input,
        uint256 _epoch
    ) public pure returns (uint256) {
        // voucher * 2 ** 128 + input * 2 ** 64 + epoch
        // this can't overflow because its impossible to have > 2**128 vouchers
        return (((_voucher << 128) | (_input << 64)) | _epoch);
    }

    /// @notice returns the position of a intra drive on a drive
    //          with  contents with the same size
    /// @param _index index of intra drive
    /// @param _log2Size of intra drive
    function getIntraDrivePosition(uint256 _index, uint256 _log2Size)
        public
        pure
        returns (uint256)
    {
        return (_index << _log2Size);
    }

    /// @notice get number of finalized epochs
    function getNumberOfFinalizedEpochs()
        public
        view
        override
        returns (uint256)
    {
        return epochHashes.length;
    }

    /// @notice get log2 size of voucher metadata drive
    function getVoucherMetadataLog2Size()
        public
        pure
        override
        returns (uint256)
    {
        return VOUCHER_METADATA_LOG2_SIZE;
    }

    /// @notice get log2 size of epoch voucher drive
    function getEpochVoucherLog2Size()
        public
        pure
        override
        returns (uint256)
    {
        return EPOCH_VOUCHER_LOG2_SIZE;
    }

    /// @notice get log2 size of notice metadata drive
    function getNoticeMetadataLog2Size()
        public
        pure
        override
        returns (uint256)
    {
        return NOTICE_METADATA_LOG2_SIZE;
    }

    /// @notice get log2 size of epoch notice drive
    function getEpochNoticeLog2Size()
        public
        pure
        override
        returns (uint256)
    {
        return EPOCH_NOTICE_LOG2_SIZE;
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

/// @title Validator Manager Implementation
pragma solidity ^0.8.0;

import "./ValidatorManager.sol";

contract ValidatorManagerImpl is ValidatorManager {
    address immutable rollups; // rollups contract using this validator
    bytes32 currentClaim; // current claim - first claim of this epoch
    address payable[] validators; // current validators

    // A bit set for each validator that agrees with current claim,
    // on their respective positions
    uint32 claimAgreementMask;

    // Every validator who should approve (in order to reach consensus) will have a one set on this mask
    // This mask is updated if a validator is added or removed
    uint32 consensusGoalMask;

    // @notice functions modified by onlyRollups will only be executed if
    // they're called by Rollups contract, otherwise it will throw an exception
    function onlyRollups() internal view {
        require(msg.sender == rollups, "Only rollups");
    }

    // @notice populates validators array and creates a consensus mask
    // @params _rollups address of rollupscontract
    // @params _validators initial validator set
    // @dev validators have to be unique, if the same validator is added twice
    //      consensus will never be reached
    constructor(address _rollups, address payable[] memory _validators) {
        rollups = _rollups;
        validators = _validators;

        // create consensus goal, represents the scenario where all
        // all validators claimed and agreed
        consensusGoalMask = updateConsensusGoalMask();
    }

    // @notice called when a claim is received by rollups
    // @params _sender address of sender of that claim
    // @params _claim claim received by rollups
    // @return result of claim, Consensus | NoConflict | Conflict
    // @return [currentClaim, conflicting claim] if there is Conflict
    //         [currentClaim, bytes32(0)] if there is Consensus
    //         [bytes32(0), bytes32(0)] if there is NoConflcit
    // @return [claimer1, claimer2] if there is  Conflcit
    //         [claimer1, address(0)] if there is Consensus
    //         [address(0), address(0)] if there is NoConflcit
    function onClaim(address payable _sender, bytes32 _claim)
        public
        override
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        onlyRollups();
        require(_claim != bytes32(0), "empty claim");
        require(isValidator(_sender), "sender not allowed");

        // cant return because a single claim might mean consensus
        if (currentClaim == bytes32(0)) {
            currentClaim = _claim;
        }

        if (_claim != currentClaim) {
            return
                emitClaimReceivedAndReturn(
                    Result.Conflict,
                    [currentClaim, _claim],
                    [getClaimerOfCurrentClaim(), _sender]
                );
        }
        claimAgreementMask = updateClaimAgreementMask(_sender);

        return
            isConsensus(claimAgreementMask, consensusGoalMask)
                ? emitClaimReceivedAndReturn(
                    Result.Consensus,
                    [_claim, bytes32(0)],
                    [_sender, payable(0)]
                )
                : emitClaimReceivedAndReturn(
                    Result.NoConflict,
                    [bytes32(0), bytes32(0)],
                    [payable(0), payable(0)]
                );
    }

    // @notice called when a dispute ends in rollups
    // @params _winner address of dispute winner
    // @params _loser address of dispute loser
    // @returns result of dispute being finished
    function onDisputeEnd(
        address payable _winner,
        address payable _loser,
        bytes32 _winningClaim
    )
        public
        override
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        onlyRollups();

        // remove validator also removes validator from both bitmask
        removeFromValidatorSetAndBothBitmasks(_loser);

        if (_winningClaim == currentClaim) {
            // first claim stood, dont need to update the bitmask
            return
                isConsensus(claimAgreementMask, consensusGoalMask)
                    ? emitDisputeEndedAndReturn(
                        Result.Consensus,
                        [_winningClaim, bytes32(0)],
                        [_winner, payable(0)]
                    )
                    : emitDisputeEndedAndReturn(
                        Result.NoConflict,
                        [bytes32(0), bytes32(0)],
                        [payable(0), payable(0)]
                    );
        }

        // if first claim lost, and other validators have agreed with it
        // there is a new dispute to be played
        if (claimAgreementMask != 0) {
            return
                emitDisputeEndedAndReturn(
                    Result.Conflict,
                    [currentClaim, _winningClaim],
                    [getClaimerOfCurrentClaim(), _winner]
                );
        }
        // else there are no valdiators that agree with losing claim
        // we can update current claim and check for consensus in case
        // the winner is the only validator left
        currentClaim = _winningClaim;
        claimAgreementMask = updateClaimAgreementMask(_winner);
        return
            isConsensus(claimAgreementMask, consensusGoalMask)
                ? emitDisputeEndedAndReturn(
                    Result.Consensus,
                    [_winningClaim, bytes32(0)],
                    [_winner, payable(0)]
                )
                : emitDisputeEndedAndReturn(
                    Result.NoConflict,
                    [bytes32(0), bytes32(0)],
                    [payable(0), payable(0)]
                );
    }

    // @notice called when a new epoch starts
    // @return current claim
    function onNewEpoch() public override returns (bytes32) {
        onlyRollups();

        bytes32 tmpClaim = currentClaim;

        // clear current claim
        currentClaim = bytes32(0);
        // clear validator agreement bit mask
        claimAgreementMask = 0;

        emit NewEpoch(tmpClaim);
        return tmpClaim;
    }

    // @notice get agreement mask
    // @return current state of agreement mask
    function getCurrentAgreementMask() public view returns (uint32) {
        return claimAgreementMask;
    }

    // @notice get consensus goal mask
    // @return current consensus goal mask
    function getConsensusGoalMask() public view returns (uint32) {
        return consensusGoalMask;
    }

    // @notice get current claim
    // @return current claim
    function getCurrentClaim() public view override returns (bytes32) {
        return currentClaim;
    }

    // INTERNAL FUNCTIONS

    // @notice emits dispute ended event and then return
    // @param _result to be emitted and returned
    // @param _claims to be emitted and returned
    // @param _validators to be emitted and returned
    // @dev this function existis to make code more clear/concise
    function emitDisputeEndedAndReturn(
        Result _result,
        bytes32[2] memory _claims,
        address payable[2] memory _validators
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        emit DisputeEnded(_result, _claims, _validators);
        return (_result, _claims, _validators);
    }

    // @notice emits claim received event and then return
    // @param _result to be emitted and returned
    // @param _claims to be emitted and returned
    // @param _validators to be emitted and returned
    // @dev this function existis to make code more clear/concise
    function emitClaimReceivedAndReturn(
        Result _result,
        bytes32[2] memory _claims,
        address payable[2] memory _validators
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        emit ClaimReceived(_result, _claims, _validators);
        return (_result, _claims, _validators);
    }

    // @notice get one of the validators that agreed with current claim
    // @return validator that agreed with current claim
    function getClaimerOfCurrentClaim()
        internal
        view
        returns (address payable)
    {
        // TODO: we are always getting the first validator
        // on the array that agrees with the current claim to enter a dispute
        // should this be random?
        for (uint256 i; i < validators.length; i++) {
            if (claimAgreementMask & (1 << i) != 0) {
                return validators[i];
            }
        }
        revert("Agreeing validator not found");
    }

    // @notice updates the consensus goal mask
    // @return new consensus goal mask
    function updateConsensusGoalMask() internal view returns (uint32) {
        // consensus goal is a number where
        // all bits related to validators are turned on
        uint256 consensusMask = (1 << validators.length) - 1;
        return uint32(consensusMask);
    }

    // @notice updates mask of validators that agreed with current claim
    // @params _sender address that of validator that will be included in mask
    // @return new claim agreement mask
    function updateClaimAgreementMask(address payable _sender)
        internal
        view
        returns (uint32)
    {
        uint256 tmpClaimAgreement = claimAgreementMask;
        for (uint256 i; i < validators.length; i++) {
            if (_sender == validators[i]) {
                tmpClaimAgreement = (tmpClaimAgreement | (1 << i));
                break;
            }
        }

        return uint32(tmpClaimAgreement);
    }

    // @notice removes a validator
    // @params address of validator to be removed
    // @returns new claim agreement bitmask
    // @returns new consensus goal bitmask
    function removeFromValidatorSetAndBothBitmasks(address _validator)
        internal
    {
        // put address(0) in validators position
        // removes validator from claim agreement bitmask
        // removes validator from consensus goal mask
        for (uint256 i; i < validators.length; i++) {
            if (_validator == validators[i]) {
                validators[i] = payable(0);
                uint32 zeroMask = ~(uint32(1) << uint32(i));
                claimAgreementMask = claimAgreementMask & zeroMask;
                consensusGoalMask = consensusGoalMask & zeroMask;
                break;
            }
        }
    }

    function isValidator(address _sender) internal view returns (bool) {
        for (uint256 i; i < validators.length; i++) {
            if (_sender == validators[i]) return true;
        }
        return false;
    }

    function isConsensus(
        uint256 _claimAgreementMask,
        uint256 _consensusGoalMask
    ) internal pure returns (bool) {
        return _claimAgreementMask == _consensusGoalMask;
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

/// @title DisputeManager
pragma solidity ^0.8.0;

import "./DisputeManager.sol";
import "./Rollups.sol";

contract DisputeManagerImpl is DisputeManager {
    Rollups immutable rollups; // rollups contract

    /// @notice functions modified by onlyRollups will only be executed if
    //  they're called by Rollups contract, otherwise it will throw an exception
    modifier onlyRollups {
        require(
            msg.sender == address(rollups),
            "Only rollups can call this functions"
        );
        _;
    }

    constructor(address _rollups) {
        rollups = Rollups(_rollups);
    }

    /// @notice initiates a dispute betweent two players
    /// @param _claims conflicting claims
    /// @param _claimers addresses of senders of conflicting claim
    /// @dev this is a mock implementation that just gives the win
    ///      to the address in the first posititon of _claimers array
    function initiateDispute(
        bytes32[2] memory _claims,
        address payable[2] memory _claimers
    ) public override onlyRollups {
        rollups.resolveDispute(_claimers[0], _claimers[1], _claims[0]);
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

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

/// @title Bit Mask Library
/// @author Stephen Chen
/// @notice Implements bit mask with dynamic array
library Bitmask {
    /// @notice Set a bit in the bit mask
    function setBit(
        mapping(uint256 => uint256) storage bitmask,
        uint256 _bit,
        bool _value
    ) public {
        // calculate the number of bits has been store in bitmask now
        uint256 positionOfMask = uint256(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        if (_value) {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] |
                (1 << positionOfBit);
        } else {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] &
                ~(1 << positionOfBit);
        }
    }

    /// @notice Get a bit in the bit mask
    function getBit(mapping(uint256 => uint256) storage bitmask, uint256 _bit)
        public
        view
        returns (bool)
    {
        // calculate the number of bits has been store in bitmask now
        uint256 positionOfMask = uint256(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        return ((bitmask[positionOfMask] & (1 << positionOfBit)) != 0);
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Library for Merkle proofs
pragma solidity ^0.8.0;

import "./CartesiMath.sol";

library Merkle {
    using CartesiMath for uint256;

    uint128 constant L_WORD_SIZE = 3; // word = 8 bytes, log = 3
    // number of hashes in EMPTY_TREE_HASHES
    uint128 constant EMPTY_TREE_SIZE = 1952; // 61*32=1952. 32 bytes per 61 indexes (64 words)

    // merkle root hashes of trees of zero concatenated
    // 32 bytes for each root, first one is keccak(0), second one is
    // keccak(keccack(0), keccak(0)) and so on

    bytes constant EMPTY_TREE_HASHES =
        hex"011b4d03dd8c01f1049143cf9c4c817e4b167f1d1b83e5c6f0f10d89ba1e7bce4d9470a821fbe90117ec357e30bad9305732fb19ddf54a07dd3e29f440619254ae39ce8537aca75e2eff3e38c98011dfe934e700a0967732fc07b430dd656a233fc9a15f5b4869c872f81087bb6104b7d63e6f9ab47f2c43f3535eae7172aa7f17d2dd614cddaa4d879276b11e0672c9560033d3e8453a1d045339d34ba601b9c37b8b13ca95166fb7af16988a70fcc90f38bf9126fd833da710a47fb37a55e68e7a427fa943d9966b389f4f257173676090c6e95f43e2cb6d65f8758111e30930b0b9deb73e155c59740bacf14a6ff04b64bb8e201a506409c3fe381ca4ea90cd5deac729d0fdaccc441d09d7325f41586ba13c801b7eccae0f95d8f3933efed8b96e5b7f6f459e9cb6a2f41bf276c7b85c10cd4662c04cbbb365434726c0a0c9695393027fb106a8153109ac516288a88b28a93817899460d6310b71cf1e6163e8806fa0d4b197a259e8c3ac28864268159d0ac85f8581ca28fa7d2c0c03eb91e3eee5ca7a3da2b3053c9770db73599fb149f620e3facef95e947c0ee860b72122e31e4bbd2b7c783d79cc30f60c6238651da7f0726f767d22747264fdb046f7549f26cc70ed5e18baeb6c81bb0625cb95bb4019aeecd40774ee87ae29ec517a71f6ee264c5d761379b3d7d617ca83677374b49d10aec50505ac087408ca892b573c267a712a52e1d06421fe276a03efb1889f337201110fdc32a81f8e152499af665835aabfdc6740c7e2c3791a31c3cdc9f5ab962f681b12fc092816a62f27d86025599a41233848702f0cfc0437b445682df51147a632a0a083d2d38b5e13e466a8935afff58bb533b3ef5d27fba63ee6b0fd9e67ff20af9d50deee3f8bf065ec220c1fd4ba57e341261d55997f85d66d32152526736872693d2b437a233e2337b715f6ac9a6a272622fdc2d67fcfe1da3459f8dab4ed7e40a657a54c36766c5e8ac9a88b35b05c34747e6507f6b044ab66180dc76ac1a696de03189593fedc0d0dbbd855c8ead673544899b0960e4a5a7ca43b4ef90afe607de7698caefdc242788f654b57a4fb32a71b335ef6ff9a4cc118b282b53bdd6d6192b7a82c3c5126b9c7e33c8e5a5ac9738b8bd31247fb7402054f97b573e8abb9faad219f4fd085aceaa7f542d787ee4196d365f3cc566e7bbcfbfd451230c48d804c017d21e2d8fa914e2559bb72bf0ab78c8ab92f00ef0d0d576eccdd486b64138a4172674857e543d1d5b639058dd908186597e366ad5f3d9c7ceaff44d04d1550b8d33abc751df07437834ba5acb32328a396994aebb3c40f759c2d6d7a3cb5377e55d5d218ef5a296dda8ddc355f3f50c3d0b660a51dfa4d98a6a5a33564556cf83c1373a814641d6a1dcef97b883fee61bb84fe60a3409340217e629cc7e4dcc93b85d8820921ff5826148b60e6939acd7838e1d7f20562bff8ee4b5ec4a05ad997a57b9796fdcb2eda87883c2640b072b140b946bfdf6575cacc066fdae04f6951e63624cbd316a677cad529bbe4e97b9144e4bc06c4afd1de55dd3e1175f90423847a230d34dfb71ed56f2965a7f6c72e6aa33c24c303fd67745d632656c5ef90bec80f4f5d1daa251988826cef375c81c36bf457e09687056f924677cb0bccf98dff81e014ce25f2d132497923e267363963cdf4302c5049d63131dc03fd95f65d8b6aa5934f817252c028c90f56d413b9d5d10d89790707dae2fabb249f649929927c21dd71e3f656826de5451c5da375aadecbd59d5ebf3a31fae65ac1b316a1611f1b276b26530f58d7247df459ce1f86db1d734f6f811932f042cee45d0e455306d01081bc3384f82c5fb2aacaa19d89cdfa46cc916eac61121475ba2e6191b4feecbe1789717021a158ace5d06744b40f551076b67cd63af60007f8c99876e1424883a45ec49d497ddaf808a5521ca74a999ab0b3c7aa9c80f85e93977ec61ce68b20307a1a81f71ca645b568fcd319ccbb5f651e87b707d37c39e15f945ea69e2f7c7d2ccc85b7e654c07e96f0636ae4044fe0e38590b431795ad0f8647bdd613713ada493cc17efd313206380e6a685b8198475bbd021c6e9d94daab2214947127506073e44d5408ba166c512a0b86805d07f5a44d3c41706be2bc15e712e55805248b92e8677d90f6d284d1d6ffaff2c430657042a0e82624fa3717b06cc0a6fd12230ea586dae83019fb9e06034ed2803c98d554b93c9a52348cafff75c40174a91f9ae6b8647854a156029f0b88b83316663ce574a4978277bb6bb27a31085634b6ec78864b6d8201c7e93903d75815067e378289a3d072ae172dafa6a452470f8d645bebfad9779594fc0784bb764a22e3a8181d93db7bf97893c414217a618ccb14caa9e92e8c61673afc9583662e812adba1f87a9c68202d60e909efab43c42c0cb00695fc7f1ffe67c75ca894c3c51e1e5e731360199e600f6ced9a87b2a6a87e70bf251bb5075ab222138288164b2eda727515ea7de12e2496d4fe42ea8d1a120c03cf9c50622c2afe4acb0dad98fd62d07ab4e828a94495f6d1ab973982c7ccbe6c1fae02788e4422ae22282fa49cbdb04ba54a7a238c6fc41187451383460762c06d1c8a72b9cd718866ad4b689e10c9a8c38fe5ef045bd785b01e980fc82c7e3532ce81876b778dd9f1ceeba4478e86411fb6fdd790683916ca832592485093644e8760cd7b4c01dba1ccc82b661bf13f0e3f34acd6b88";

    /// @notice Gets merkle root hash of drive with a replacement
    /// @param _position position of _drive
    /// @param _logSizeOfReplacement log2 of size the replacement
    /// @param _logSizeOfFullDrive log2 of size the full drive, which can be the entire machine
    /// @param _replacement hash of the replacement
    /// @param siblings of replacement that merkle root can be calculated
    function getRootAfterReplacementInDrive(
        uint256 _position,
        uint256 _logSizeOfReplacement,
        uint256 _logSizeOfFullDrive,
        bytes32 _replacement,
        bytes32[] calldata siblings
    ) public pure returns (bytes32) {
        require(
            _logSizeOfFullDrive >= _logSizeOfReplacement &&
                _logSizeOfReplacement >= 3 &&
                _logSizeOfFullDrive <= 64,
            "3 <= logSizeOfReplacement <= logSizeOfFullDrive <= 64"
        );

        uint256 size = 1 << _logSizeOfReplacement;

        require(((size - 1) & _position) == 0, "Position is not aligned");
        require(
            siblings.length == _logSizeOfFullDrive - _logSizeOfReplacement,
            "Proof length does not match"
        );

        for (uint256 i; i < siblings.length; i++) {
            if ((_position & (size << i)) == 0) {
                _replacement = keccak256(
                    abi.encodePacked(_replacement, siblings[i])
                );
            } else {
                _replacement = keccak256(
                    abi.encodePacked(siblings[i], _replacement)
                );
            }
        }

        return _replacement;
    }

    /// @notice Gets precomputed hash of zero in empty tree hashes
    /// @param _index of hash wanted
    /// @dev first index is keccak(0), second index is keccak(keccak(0), keccak(0))
    function getEmptyTreeHashAtIndex(uint256 _index)
        public
        pure
        returns (bytes32)
    {
        uint256 start = _index * 32;
        require(EMPTY_TREE_SIZE >= start + 32, "index out of bounds");
        bytes32 hashedZeros;
        bytes memory zeroTree = EMPTY_TREE_HASHES;

        // first word is length, then skip index words
        assembly {
            hashedZeros := mload(add(add(zeroTree, 0x20), start))
        }
        return hashedZeros;
    }

    /// @notice get merkle root of generic array of bytes
    /// @param _data array of bytes to be merklelized
    /// @param _log2Size log2 of total size of the drive
    /// @dev _data is padded with zeroes until is multiple of 8
    /// @dev root is completed with zero tree until log2size is complete
    /// @dev hashes are taken word by word (8 bytes by 8 bytes)
    function getMerkleRootFromBytes(bytes calldata _data, uint256 _log2Size)
        public
        pure
        returns (bytes32)
    {
        require(_log2Size >= 3 && _log2Size <= 64, "range of log2Size: [3,64]");

        // if _data is empty return pristine drive of size log2size
        if (_data.length == 0) return getEmptyTreeHashAtIndex(_log2Size - 3);

        // total size of the drive in words
        uint256 size = 1 << (_log2Size - 3);
        require(
            size << L_WORD_SIZE >= _data.length,
            "data is bigger than drive"
        );
        // the stack depth is log2(_data.length / 8) + 2
        uint256 stack_depth = 2 +
            ((_data.length) >> L_WORD_SIZE).getLog2Floor();
        bytes32[] memory stack = new bytes32[](stack_depth);

        uint256 numOfHashes; // total number of hashes on stack (counting levels)
        uint256 stackLength; // total length of stack
        uint256 numOfJoins; // number of hashes of the same level on stack
        uint256 topStackLevel; // hash level of the top of the stack

        while (numOfHashes < size) {
            if ((numOfHashes << L_WORD_SIZE) < _data.length) {
                // we still have words to hash
                stack[stackLength] = getHashOfWordAtIndex(_data, numOfHashes);
                numOfHashes++;

                numOfJoins = numOfHashes;
            } else {
                // since padding happens in hashOfWordAtIndex function
                // we only need to complete the stack with pre-computed
                // hash(0), hash(hash(0),hash(0)) and so on
                topStackLevel = numOfHashes.ctz();

                stack[stackLength] = getEmptyTreeHashAtIndex(topStackLevel);

                //Empty Tree Hash summarizes many hashes
                numOfHashes = numOfHashes + (1 << topStackLevel);
                numOfJoins = numOfHashes >> topStackLevel;
            }

            stackLength++;

            // while there are joins, hash top of stack together
            while (numOfJoins & 1 == 0) {
                bytes32 h2 = stack[stackLength - 1];
                bytes32 h1 = stack[stackLength - 2];

                stack[stackLength - 2] = keccak256(abi.encodePacked(h1, h2));
                stackLength = stackLength - 1; // remove hashes from stack

                numOfJoins = numOfJoins >> 1;
            }
        }
        require(stackLength == 1, "stack error");

        return stack[0];
    }

    /// @notice Get the hash of a word in an array of bytes
    /// @param _data array of bytes
    /// @param _wordIndex index of word inside the bytes to get the hash of
    /// @dev if word is incomplete (< 8 bytes) it gets padded with zeroes
    function getHashOfWordAtIndex(bytes calldata _data, uint256 _wordIndex)
        public
        pure
        returns (bytes32)
    {
        uint256 start = _wordIndex << L_WORD_SIZE;
        uint256 end = start + (1 << L_WORD_SIZE);

        // TODO: in .lua this just returns zero, but this might be more consistent
        require(start <= _data.length, "word out of bounds");

        if (end <= _data.length) {
            return keccak256(abi.encodePacked(_data[start:end]));
        }

        // word is incomplete
        // fill paddedSlice with incomplete words - the rest is going to be bytes(0)
        bytes memory paddedSlice = new bytes(8);
        uint256 remaining = _data.length - start;

        for (uint256 i; i < remaining; i++) {
            paddedSlice[i] = _data[start + i];
        }

        return keccak256(paddedSlice);
    }

    /// @notice Calculate the root of Merkle tree from an array of power of 2 elements
    /// @param hashes The array containing power of 2 elements
    /// @return byte32 the root hash being calculated
    function calculateRootFromPowerOfTwo(bytes32[] memory hashes)
        public
        pure
        returns (bytes32)
    {
        // revert when the input is not of power of 2
        require((hashes.length).isPowerOf2(), "array len not power of 2");

        if (hashes.length == 1) {
            return hashes[0];
        } else {
            bytes32[] memory newHashes = new bytes32[](hashes.length >> 1);

            for (uint256 i; i < hashes.length; i += 2) {
                newHashes[i >> 1] = keccak256(
                    abi.encodePacked(hashes[i], hashes[i + 1])
                );
            }

            return calculateRootFromPowerOfTwo(newHashes);
        }
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title CartesiMath
/// @author Felipe Argento
pragma solidity ^0.8.0;

library CartesiMath {
    // mapping values are packed as bytes3 each
    // see test/TestCartesiMath.ts for decimal values
    bytes constant log2tableTimes1M =
        hex"0000000F4240182F421E8480236E082771822AD63A2DC6C0305E8532B04834C96736B3C23876D73A187A3B9D4A3D09003E5EA63FA0C540D17741F28843057D440BA745062945F60246DC1047B917488DC7495ABA4A207C4ADF8A4B98544C4B404CF8AA4DA0E64E44434EE3054F7D6D5013B750A61A5134C851BFF05247BD52CC58534DE753CC8D54486954C19C55384255AC75561E50568DE956FB575766B057D00758376F589CFA5900BA5962BC59C3135A21CA5A7EF15ADA945B34BF5B8D805BE4DF5C3AEA5C8FA95CE3265D356C5D86835DD6735E25455E73005EBFAD5F0B525F55F75F9FA25FE85A60302460770860BD0A61023061467F6189FD61CCAE620E98624FBF62902762CFD5630ECD634D12638AA963C7966403DC643F7F647A8264B4E864EEB56527EC6560906598A365D029660724663D9766738566A8F066DDDA6712476746386779AF67ACAF67DF3A6811526842FA68743268A4FC68D55C6905536934E169640A6992CF69C13169EF326A1CD46A4A186A76FF6AA38C6ACFC0";

    /// @notice Approximates log2 * 1M
    /// @param _num number to take log2 * 1M of
    /// @return approximate log2 times 1M
    function log2ApproxTimes1M(uint256 _num) public pure returns (uint256) {
        require(_num > 0, "Number cannot be zero");
        uint256 leading = 0;

        if (_num == 1) return 0;

        while (_num > 128) {
            _num = _num >> 1;
            leading += 1;
        }
        return (leading * uint256(1000000)) + (getLog2TableTimes1M(_num));
    }

    /// @notice navigates log2tableTimes1M
    /// @param _num number to take log2 of
    /// @return result after table look-up
    function getLog2TableTimes1M(uint256 _num) public pure returns (uint256) {
        bytes3 result = 0;
        for (uint8 i = 0; i < 3; i++) {
            bytes3 tempResult = log2tableTimes1M[(_num - 1) * 3 + i];
            result = result | (tempResult >> (i * 8));
        }

        return uint256(uint24(result));
    }

    /// @notice get floor of log2 of number
    /// @param _num number to take floor(log2) of
    /// @return floor(log2) of _num
   function getLog2Floor(uint256 _num) public pure returns (uint8) {
       require(_num != 0, "log of zero is undefined");

       return uint8(255 - clz(_num));
    }

    /// @notice checks if a number is Power of 2
    /// @param _num number to check
    /// @return true if number is power of 2, false if not
    function isPowerOf2(uint256 _num) public pure returns (bool) {
        if (_num == 0) return false;

        return _num & (_num - 1) == 0;
    }

    /// @notice count trailing zeros
    /// @param _num number you want the ctz of
    /// @dev this a binary search implementation
    function ctz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) { n = n + 128; _num = _num >> 128; }
        if (_num & 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF == 0) { n = n + 64; _num = _num >> 64; }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000FFFFFFFF == 0) { n = n + 32; _num = _num >> 32; }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000FFFF == 0) { n = n + 16; _num = _num >> 16; }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000000000FF == 0) { n = n +  8; _num = _num >>  8; }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000000F == 0) { n = n +  4; _num = _num >>  4; }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000003 == 0) { n = n +  2; _num = _num >>  2; }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000001 == 0) { n = n +  1; }

        return n;
    }

    /// @notice count leading zeros
    /// @param _num number you want the clz of
    /// @dev this a binary search implementation
    function clz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 == 0) { n = n + 128; _num = _num << 128; }
        if (_num & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 == 0) { n = n + 64; _num = _num << 64; }
        if (_num & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 == 0) { n = n + 32; _num = _num << 32; }
        if (_num & 0xFFFF000000000000000000000000000000000000000000000000000000000000 == 0) { n = n + 16; _num = _num << 16; }
        if (_num & 0xFF00000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  8; _num = _num <<  8; }
        if (_num & 0xF000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  4; _num = _num <<  4; }
        if (_num & 0xC000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  2; _num = _num <<  2; }
        if (_num & 0x8000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  1; }

        return n;
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

/// @title DisputeManager
pragma solidity >=0.7.0;

interface DisputeManager {
    function initiateDispute(
        bytes32[2] memory _claims,
        address payable[2] memory _claimers
    ) external;
}