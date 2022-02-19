// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// @title Diamond Initialization Contract
pragma solidity ^0.8.0;

// Rollups-related dependencies
import {Phase} from "../interfaces/IRollups.sol";
import {LibRollups} from "../libraries/LibRollups.sol";
import {LibInput} from "../libraries/LibInput.sol";
import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";
import {LibSERC20Portal} from "../libraries/LibSERC20Portal.sol";
import {LibClaimsMask} from "../libraries/LibClaimsMask.sol";
import {LibFeeManager} from "../libraries/LibFeeManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Diamond-related dependencies
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol"; // not in openzeppelin-contracts yet
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract DiamondInit {
    using LibValidatorManager for LibValidatorManager.DiamondStorage;

    /// @notice initialize the Rollups contract
    /// @param _inputDuration duration of input accumulation phase in seconds
    /// @param _challengePeriod duration of challenge period in seconds
    /// @param _inputLog2Size size of the input drive in this machine
    /// @param _feePerClaim fee per claim to reward the validators
    /// @param _erc20ForFee the ERC-20 used as rewards for validators
    /// @param _feeManagerOwner fee manager owner address
    /// @param _validators initial validator set
    /// @param _erc20ForPortal ERC-20 contract address used by the portal
    /// @dev validators have to be unique, if the same validator is added twice
    ///      consensus will never be reached
    function init(
        // rollups init variables
        uint256 _inputDuration,
        uint256 _challengePeriod,
        // input init variables
        uint256 _inputLog2Size,
        // fee manager init variables
        uint256 _feePerClaim,
        address _erc20ForFee,
        address _feeManagerOwner,
        // validator manager init variables
        address payable[] memory _validators,
        // specific ERC-20 portal init variables
        address _erc20ForPortal
    ) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // initializing facets
        initInput(_inputLog2Size);
        initValidatorManager(_validators);
        initRollups(_inputDuration, _challengePeriod);
        initSERC20Portal(_erc20ForPortal);
        initFeeManager(_feePerClaim, _erc20ForFee, _feeManagerOwner);
    }

    /// @notice initalize the Input facet
    /// @param _inputLog2Size size of the input drive in this machine
    function initInput(uint256 _inputLog2Size) private {
        LibInput.DiamondStorage storage inputDS = LibInput.diamondStorage();

        require(
            _inputLog2Size >= 3 && _inputLog2Size <= 64,
            "Log of input size: [3,64]"
        );

        inputDS.inputDriveSize = (1 << _inputLog2Size);
    }

    /// @notice initialize the Validator Manager facet
    /// @param _validators initial validator set
    function initValidatorManager(address payable[] memory _validators)
        private
    {
        LibValidatorManager.DiamondStorage storage vmDS = LibValidatorManager
            .diamondStorage();

        uint256 maxNumValidators = _validators.length;

        require(maxNumValidators <= 8, "up to 8 validators");

        vmDS.validators = _validators;
        vmDS.maxNumValidators = maxNumValidators;

        // create a new ClaimsMask, with only the consensus goal set,
        //      according to the number of validators
        vmDS.claimsMask = LibClaimsMask.newClaimsMaskWithConsensusGoalSet(
            maxNumValidators
        );
    }

    /// @notice rollups contract initialized
    /// @param _inputDuration duration of input accumulation phase in seconds
    /// @param _challengePeriod duration of challenge period in seconds
    event RollupsInitialized(uint256 _inputDuration, uint256 _challengePeriod);

    /// @notice initialize the Rollups facet
    /// @param _inputDuration duration of input accumulation phase in seconds
    /// @param _challengePeriod duration of challenge period in seconds
    function initRollups(uint256 _inputDuration, uint256 _challengePeriod)
        private
    {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();

        rollupsDS.inputDuration = uint32(_inputDuration);
        rollupsDS.challengePeriod = uint32(_challengePeriod);
        rollupsDS.inputAccumulationStart = uint32(block.timestamp);
        rollupsDS.currentPhase_int = uint32(Phase.InputAccumulation);

        emit RollupsInitialized(_inputDuration, _challengePeriod);
    }

    /// @notice initialize the specific ERC-20 portal
    /// @param _erc20ForPortal ERC-20 contract address used by the portal
    function initSERC20Portal(address _erc20ForPortal) private {
        LibSERC20Portal.DiamondStorage storage serc20DS = LibSERC20Portal
            .diamondStorage();

        serc20DS.erc20Contract = _erc20ForPortal;
    }

    /// @notice FeeManagerImpl contract initialized
    /// @param _feePerClaim fee per claim to reward the validators
    /// @param _erc20ForFee the ERC-20 used as rewards for validators
    /// @param _feeManagerOwner fee manager owner address
    event FeeManagerInitialized(
        uint256 _feePerClaim,
        address _erc20ForFee,
        address _feeManagerOwner
    );

    /// @notice initalize the Fee Manager facet
    /// @param _feePerClaim fee per claim to reward the validators
    /// @param _erc20ForFee the ERC-20 used as rewards for validators
    /// @param _feeManagerOwner fee manager owner address
    function initFeeManager(
        uint256 _feePerClaim,
        address _erc20ForFee,
        address _feeManagerOwner
    ) private {
        LibFeeManager.DiamondStorage storage feeManagerDS = LibFeeManager
            .diamondStorage();

        feeManagerDS.feePerClaim = _feePerClaim;
        feeManagerDS.token = IERC20(_erc20ForFee);
        feeManagerDS.owner = _feeManagerOwner;

        emit FeeManagerInitialized(
            _feePerClaim,
            _erc20ForFee,
            _feeManagerOwner
        );
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

/// @title Rollups interface
pragma solidity >=0.7.0;

// InputAccumulation - Inputs being accumulated for currrent epoch
// AwaitingConsensus - No disagreeing claims (or no claims)
// AwaitingDispute - Waiting for dispute to be over
// inputs received during InputAccumulation will be included in the
// current epoch. Inputs received while WaitingClaims or ChallengesInProgress
// are accumulated for the next epoch
enum Phase {
    InputAccumulation,
    AwaitingConsensus,
    AwaitingDispute
}

interface IRollups {
    /// @notice claim the result of current epoch
    /// @param _epochHash hash of epoch
    /// @dev ValidatorManager makes sure that msg.sender is allowed
    ///      and that claim != bytes32(0)
    /// TODO: add signatures for aggregated claims
    function claim(bytes32 _epochHash) external;

    /// @notice finalize epoch after timeout
    /// @dev can only be called if challenge period is over
    function finalizeEpoch() external;

    /// @notice returns index of current (accumulating) epoch
    /// @return index of current epoch
    /// @dev if phase is input accumulation, then the epoch number is length
    ///      of finalized epochs array, else there are two epochs two non
    ///      finalized epochs, one awaiting consensus/dispute and another
    ///      accumulating input
    function getCurrentEpoch() external view returns (uint256);

    /// @notice claim submitted
    /// @param _epochHash claim being submitted by this epoch
    /// @param _claimer address of current claimer
    /// @param _epochNumber number of the epoch being submitted
    event Claim(
        uint256 indexed _epochNumber,
        address _claimer,
        bytes32 _epochHash
    );

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

/// @title Rollups library
pragma solidity ^0.8.0;

import {Phase} from "../interfaces/IRollups.sol";
import {Result} from "../interfaces/IValidatorManager.sol";

import {LibInput} from "../libraries/LibInput.sol";
import {LibOutput} from "../libraries/LibOutput.sol";
import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";
import {LibDisputeManager} from "../libraries/LibDisputeManager.sol";

library LibRollups {
    using LibInput for LibInput.DiamondStorage;
    using LibOutput for LibOutput.DiamondStorage;
    using LibValidatorManager for LibValidatorManager.DiamondStorage;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Rollups.diamond.storage");

    struct DiamondStorage {
        uint32 inputDuration; // duration of input accumulation phase in seconds
        uint32 challengePeriod; // duration of challenge period in seconds
        uint32 inputAccumulationStart; // timestamp when current input accumulation phase started
        uint32 sealingEpochTimestamp; // timestamp on when a proposed epoch (claim) becomes challengeable
        uint32 currentPhase_int; // current phase in integer form
    }

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

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice called when new input arrives, manages the phase changes
    /// @param ds diamond storage pointer
    /// @dev can only be called by input contract
    function notifyInput(DiamondStorage storage ds) internal returns (bool) {
        Phase currentPhase = Phase(ds.currentPhase_int);
        uint256 inputAccumulationStart = ds.inputAccumulationStart;
        uint256 inputDuration = ds.inputDuration;

        if (
            currentPhase == Phase.InputAccumulation &&
            block.timestamp > inputAccumulationStart + inputDuration
        ) {
            ds.currentPhase_int = uint32(Phase.AwaitingConsensus);
            emit PhaseChange(Phase.AwaitingConsensus);
            return true;
        }
        return false;
    }

    /// @notice called when a dispute is resolved by the dispute manager
    /// @param ds diamond storage pointer
    /// @param winner winner of dispute
    /// @param loser loser of dispute
    /// @param winningClaim initial claim of winning validator
    function resolveDispute(
        DiamondStorage storage ds,
        address payable winner,
        address payable loser,
        bytes32 winningClaim
    ) internal {
        Result result;
        bytes32[2] memory claims;
        address payable[2] memory claimers;
        LibValidatorManager.DiamondStorage storage vmDS = LibValidatorManager
            .diamondStorage();

        (result, claims, claimers) = vmDS.onDisputeEnd(
            winner,
            loser,
            winningClaim
        );

        // restart challenge period
        ds.sealingEpochTimestamp = uint32(block.timestamp);

        emit ResolveDispute(winner, loser, winningClaim);
        resolveValidatorResult(ds, result, claims, claimers);
    }

    /// @notice resolve results returned by validator manager
    /// @param ds diamond storage pointer
    /// @param result result from claim or dispute operation
    /// @param claims array of claims in case of new conflict
    /// @param claimers array of claimers in case of new conflict
    function resolveValidatorResult(
        DiamondStorage storage ds,
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory claimers
    ) internal {
        if (result == Result.NoConflict) {
            Phase currentPhase = Phase(ds.currentPhase_int);
            if (currentPhase != Phase.AwaitingConsensus) {
                ds.currentPhase_int = uint32(Phase.AwaitingConsensus);
                emit PhaseChange(Phase.AwaitingConsensus);
            }
        } else if (result == Result.Consensus) {
            startNewEpoch(ds);
        } else {
            // for the case when result == Result.Conflict
            Phase currentPhase = Phase(ds.currentPhase_int);
            if (currentPhase != Phase.AwaitingDispute) {
                ds.currentPhase_int = uint32(Phase.AwaitingDispute);
                emit PhaseChange(Phase.AwaitingDispute);
            }
            LibDisputeManager.initiateDispute(claims, claimers);
        }
    }

    /// @notice starts new epoch
    /// @param ds diamond storage pointer
    function startNewEpoch(DiamondStorage storage ds) internal {
        LibInput.DiamondStorage storage inputDS = LibInput.diamondStorage();
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();
        LibValidatorManager.DiamondStorage storage vmDS = LibValidatorManager
            .diamondStorage();

        // reset input accumulation start and deactivate challenge period start
        ds.currentPhase_int = uint32(Phase.InputAccumulation);
        emit PhaseChange(Phase.InputAccumulation);
        ds.inputAccumulationStart = uint32(block.timestamp);
        ds.sealingEpochTimestamp = type(uint32).max;

        bytes32 finalClaim = vmDS.onNewEpoch();

        // emit event before finalized epoch is added to the Output storage
        emit FinalizeEpoch(outputDS.getNumberOfFinalizedEpochs(), finalClaim);

        outputDS.onNewEpoch(finalClaim);
        inputDS.onNewEpoch();
    }

    /// @notice returns index of current (accumulating) epoch
    /// @param ds diamond storage pointer
    /// @return index of current epoch
    /// @dev if phase is input accumulation, then the epoch number is length
    ///      of finalized epochs array, else there are two non finalized epochs,
    ///      one awaiting consensus/dispute and another accumulating input
    function getCurrentEpoch(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();

        uint256 finalizedEpochs = outputDS.getNumberOfFinalizedEpochs();

        Phase currentPhase = Phase(ds.currentPhase_int);

        return
            currentPhase == Phase.InputAccumulation
                ? finalizedEpochs
                : finalizedEpochs + 1;
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

/// @title Input library
pragma solidity ^0.8.0;

import {LibRollups} from "../libraries/LibRollups.sol";

library LibInput {
    using LibRollups for LibRollups.DiamondStorage;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Input.diamond.storage");

    struct DiamondStorage {
        // always needs to keep track of two input boxes:
        // 1 for the input accumulation of next epoch
        // and 1 for the messages during current epoch. To save gas we alternate
        // between inputBox0 and inputBox1
        bytes32[] inputBox0;
        bytes32[] inputBox1;
        uint256 inputDriveSize; // size of input flashdrive
        uint256 currentInputBox;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice get input inside inbox of currently proposed claim
    /// @param ds diamond storage pointer
    /// @param index index of input inside that inbox
    /// @return hash of input at index index
    /// @dev currentInputBox being zero means that the inputs for
    ///      the claimed epoch are on input box one
    function getInput(DiamondStorage storage ds, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return
            ds.currentInputBox == 0 ? ds.inputBox1[index] : ds.inputBox0[index];
    }

    /// @notice get number of inputs inside inbox of currently proposed claim
    /// @param ds diamond storage pointer
    /// @return number of inputs on that input box
    /// @dev currentInputBox being zero means that the inputs for
    ///      the claimed epoch are on input box one
    function getNumberOfInputs(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        return
            ds.currentInputBox == 0 ? ds.inputBox1.length : ds.inputBox0.length;
    }

    /// @notice add input to processed by next epoch
    /// @param ds diamond storage pointer
    /// @param input input to be understood by offchain machine
    /// @dev offchain code is responsible for making sure
    ///      that input size is power of 2 and multiple of 8 since
    ///      the offchain machine has a 8 byte word
    function addInput(DiamondStorage storage ds, bytes memory input)
        internal
        returns (bytes32)
    {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();

        require(
            input.length > 0 && input.length <= ds.inputDriveSize,
            "input len: (0,driveSize]"
        );

        // notifyInput returns true if that input
        // belongs to a new epoch
        if (rollupsDS.notifyInput()) {
            swapInputBox(ds);
        }

        // points to correct inputBox
        bytes32[] storage inputBox = ds.currentInputBox == 0
            ? ds.inputBox0
            : ds.inputBox1;

        // get current epoch index
        uint256 currentEpoch = rollupsDS.getCurrentEpoch();

        // keccak 64 bytes into 32 bytes
        bytes32 keccakMetadata = keccak256(
            abi.encode(
                msg.sender,
                block.number,
                block.timestamp,
                currentEpoch, // epoch index
                inputBox.length // input index
            )
        );

        bytes32 keccakInput = keccak256(input);

        bytes32 inputHash = keccak256(abi.encode(keccakMetadata, keccakInput));

        // add input to correct inbox
        inputBox.push(inputHash);

        emit InputAdded(currentEpoch, msg.sender, block.timestamp, input);

        return inputHash;
    }

    /// @notice called when a new input accumulation phase begins
    ///         swap inbox to receive inputs for upcoming epoch
    /// @param ds diamond storage pointer
    function onNewInputAccumulation(DiamondStorage storage ds) internal {
        swapInputBox(ds);
    }

    /// @notice called when a new epoch begins, clears deprecated inputs
    /// @param ds diamond storage pointer
    function onNewEpoch(DiamondStorage storage ds) internal {
        // clear input box for new inputs
        // the current input box should be accumulating inputs
        // for the new epoch already. So we clear the other one.
        ds.currentInputBox == 0 ? delete ds.inputBox1 : delete ds.inputBox0;
    }

    /// @notice changes current input box
    /// @param ds diamond storage pointer
    function swapInputBox(DiamondStorage storage ds) internal {
        ds.currentInputBox = (ds.currentInputBox == 0) ? 1 : 0;
    }

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

/// @title Validator Manager library
pragma solidity ^0.8.0;

import {Result} from "../interfaces/IValidatorManager.sol";

import {LibClaimsMask, ClaimsMask} from "../libraries/LibClaimsMask.sol";

library LibValidatorManager {
    using LibClaimsMask for ClaimsMask;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("ValidatorManager.diamond.storage");

    struct DiamondStorage {
        bytes32 currentClaim; // current claim - first claim of this epoch
        address payable[] validators; // up to 8 validators
        uint256 maxNumValidators; // the maximum number of validators, set in the constructor
        // A bit set used for up to 8 validators.
        // The first 8 bits are used to indicate whom supports the current claim
        // The second 8 bits are used to indicate those should have claimed in order to reach consensus
        // The following every 30 bits are used to indicate the number of total claims each validator has made
        // | agreement mask | consensus mask | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
        // |     8 bits     |     8 bits     |      30 bits       |      30 bits       | ... |      30 bits       |
        ClaimsMask claimsMask;
    }

    /// @notice emitted on Claim received
    event ClaimReceived(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on Dispute end
    event DisputeEnded(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on new Epoch
    event NewEpoch(bytes32 claim);

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice called when a dispute ends in rollups
    /// @param ds diamond storage pointer
    /// @param winner address of dispute winner
    /// @param loser address of dispute loser
    /// @param winningClaim the winnning claim
    /// @return result of dispute being finished
    function onDisputeEnd(
        DiamondStorage storage ds,
        address payable winner,
        address payable loser,
        bytes32 winningClaim
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        removeValidator(ds, loser);

        if (winningClaim == ds.currentClaim) {
            // first claim stood, dont need to update the bitmask
            return
                isConsensus(ds)
                    ? emitDisputeEndedAndReturn(
                        Result.Consensus,
                        [winningClaim, bytes32(0)],
                        [winner, payable(0)]
                    )
                    : emitDisputeEndedAndReturn(
                        Result.NoConflict,
                        [winningClaim, bytes32(0)],
                        [winner, payable(0)]
                    );
        }

        // if first claim lost, and other validators have agreed with it
        // there is a new dispute to be played
        if (ds.claimsMask.getAgreementMask() != 0) {
            return
                emitDisputeEndedAndReturn(
                    Result.Conflict,
                    [ds.currentClaim, winningClaim],
                    [getClaimerOfCurrentClaim(ds), winner]
                );
        }
        // else there are no valdiators that agree with losing claim
        // we can update current claim and check for consensus in case
        // the winner is the only validator left
        ds.currentClaim = winningClaim;
        updateClaimAgreementMask(ds, winner);
        return
            isConsensus(ds)
                ? emitDisputeEndedAndReturn(
                    Result.Consensus,
                    [winningClaim, bytes32(0)],
                    [winner, payable(0)]
                )
                : emitDisputeEndedAndReturn(
                    Result.NoConflict,
                    [winningClaim, bytes32(0)],
                    [winner, payable(0)]
                );
    }

    /// @notice called when a new epoch starts
    /// @param ds diamond storage pointer
    /// @return current claim
    function onNewEpoch(DiamondStorage storage ds) internal returns (bytes32) {
        // reward validators who has made the correct claim by increasing their #claims
        claimFinalizedIncreaseCounts(ds);

        bytes32 tmpClaim = ds.currentClaim;

        // clear current claim
        ds.currentClaim = bytes32(0);
        // clear validator agreement bit mask
        ds.claimsMask = ds.claimsMask.clearAgreementMask();

        emit NewEpoch(tmpClaim);
        return tmpClaim;
    }

    /// @notice called when a claim is received by rollups
    /// @param ds diamond storage pointer
    /// @param sender address of sender of that claim
    /// @param claim claim received by rollups
    /// @return result of claim, Consensus | NoConflict | Conflict
    /// @return [currentClaim, conflicting claim] if there is Conflict
    ///         [currentClaim, bytes32(0)] if there is Consensus or NoConflcit
    /// @return [claimer1, claimer2] if there is  Conflcit
    ///         [claimer1, address(0)] if there is Consensus or NoConflcit
    function onClaim(
        DiamondStorage storage ds,
        address payable sender,
        bytes32 claim
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        require(claim != bytes32(0), "empty claim");
        require(isValidator(ds, sender), "sender not allowed");

        // require the validator hasn't claimed in the same epoch before
        uint256 index = getValidatorIndex(ds, sender);
        require(
            !ds.claimsMask.alreadyClaimed(index),
            "sender had claimed in this epoch before"
        );

        // cant return because a single claim might mean consensus
        if (ds.currentClaim == bytes32(0)) {
            ds.currentClaim = claim;
        }

        if (claim != ds.currentClaim) {
            return
                emitClaimReceivedAndReturn(
                    Result.Conflict,
                    [ds.currentClaim, claim],
                    [getClaimerOfCurrentClaim(ds), sender]
                );
        }
        updateClaimAgreementMask(ds, sender);

        return
            isConsensus(ds)
                ? emitClaimReceivedAndReturn(
                    Result.Consensus,
                    [claim, bytes32(0)],
                    [sender, payable(0)]
                )
                : emitClaimReceivedAndReturn(
                    Result.NoConflict,
                    [claim, bytes32(0)],
                    [sender, payable(0)]
                );
    }

    /// @notice emits dispute ended event and then return
    /// @param result to be emitted and returned
    /// @param claims to be emitted and returned
    /// @param validators to be emitted and returned
    /// @dev this function existis to make code more clear/concise
    function emitDisputeEndedAndReturn(
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory validators
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        emit DisputeEnded(result, claims, validators);
        return (result, claims, validators);
    }

    /// @notice emits claim received event and then return
    /// @param result to be emitted and returned
    /// @param claims to be emitted and returned
    /// @param validators to be emitted and returned
    /// @dev this function existis to make code more clear/concise
    function emitClaimReceivedAndReturn(
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory validators
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        emit ClaimReceived(result, claims, validators);
        return (result, claims, validators);
    }

    /// @notice only call this function when a claim has been finalized
    ///         Either a consensus has been reached or challenge period has past
    /// @param ds pointer to diamond storage
    function claimFinalizedIncreaseCounts(DiamondStorage storage ds) internal {
        uint256 agreementMask = ds.claimsMask.getAgreementMask();
        for (uint256 i; i < ds.validators.length; i++) {
            // if a validator agrees with the current claim
            if ((agreementMask & (1 << i)) != 0) {
                // increase #claims by 1
                ds.claimsMask = ds.claimsMask.increaseNumClaims(i, 1);
            }
        }
    }

    /// @notice removes a validator
    /// @param ds diamond storage pointer
    /// @param validator address of validator to be removed
    function removeValidator(DiamondStorage storage ds, address validator)
        internal
    {
        for (uint256 i; i < ds.validators.length; i++) {
            if (validator == ds.validators[i]) {
                // put address(0) in validators position
                ds.validators[i] = payable(0);
                // remove the validator from claimsMask
                ds.claimsMask = ds.claimsMask.removeValidator(i);
                break;
            }
        }
    }

    /// @notice check if consensus has been reached
    /// @param ds pointer to diamond storage
    function isConsensus(DiamondStorage storage ds)
        internal
        view
        returns (bool)
    {
        ClaimsMask claimsMask = ds.claimsMask;
        return
            claimsMask.getAgreementMask() == claimsMask.getConsensusGoalMask();
    }

    /// @notice get one of the validators that agreed with current claim
    /// @param ds diamond storage pointer
    /// @return validator that agreed with current claim
    function getClaimerOfCurrentClaim(DiamondStorage storage ds)
        internal
        view
        returns (address payable)
    {
        // TODO: we are always getting the first validator
        // on the array that agrees with the current claim to enter a dispute
        // should this be random?
        uint256 agreementMask = ds.claimsMask.getAgreementMask();
        for (uint256 i; i < ds.validators.length; i++) {
            if (agreementMask & (1 << i) != 0) {
                return ds.validators[i];
            }
        }
        revert("Agreeing validator not found");
    }

    /// @notice updates mask of validators that agreed with current claim
    /// @param ds diamond storage pointer
    /// @param sender address of validator that will be included in mask
    function updateClaimAgreementMask(
        DiamondStorage storage ds,
        address payable sender
    ) internal {
        uint256 validatorIndex = getValidatorIndex(ds, sender);
        ds.claimsMask = ds.claimsMask.setAgreementMask(validatorIndex);
    }

    /// @notice check if the sender is a validator
    /// @param ds pointer to diamond storage
    /// @param sender sender address
    function isValidator(DiamondStorage storage ds, address sender)
        internal
        view
        returns (bool)
    {
        require(sender != address(0), "address 0");

        for (uint256 i; i < ds.validators.length; i++) {
            if (sender == ds.validators[i]) return true;
        }

        return false;
    }

    /// @notice find the validator and return the index or revert
    /// @param ds pointer to diamond storage
    /// @param sender validator address
    /// @return validator index or revert
    function getValidatorIndex(DiamondStorage storage ds, address sender)
        internal
        view
        returns (uint256)
    {
        require(sender != address(0), "address 0");
        for (uint256 i; i < ds.validators.length; i++) {
            if (sender == ds.validators[i]) return i;
        }
        revert("validator not found");
    }

    /// @notice get number of claims the sender has made
    /// @param ds pointer to diamond storage
    /// @param _sender validator address
    /// @return #claims
    function getNumberOfClaimsByAddress(
        DiamondStorage storage ds,
        address payable _sender
    ) internal view returns (uint256) {
        for (uint256 i; i < ds.validators.length; i++) {
            if (_sender == ds.validators[i]) {
                return getNumberOfClaimsByIndex(ds, i);
            }
        }
        // if validator not found
        return 0;
    }

    /// @notice get number of claims by the index in the validator set
    /// @param ds pointer to diamond storage
    /// @param index the index in validator set
    /// @return #claims
    function getNumberOfClaimsByIndex(DiamondStorage storage ds, uint256 index)
        internal
        view
        returns (uint256)
    {
        return ds.claimsMask.getNumClaims(index);
    }

    /// @notice get the maximum number of validators defined in validator manager
    /// @param ds pointer to diamond storage
    /// @return the maximum number of validators
    function getMaxNumValidators(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        return ds.maxNumValidators;
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

/// @title Specific ERC20 Portal library
pragma solidity ^0.8.0;

library LibSERC20Portal {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("specific.erc20.diamond.storage");

    struct DiamondStorage {
        address erc20Contract;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
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

/// @title ClaimsMask library
pragma solidity >=0.8.8;

// ClaimsMask is used to keep track of the number of claims for up to 8 validators
// | agreement mask | consensus goal mask | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
// |     8 bits     |        8 bits       |      30 bits       |      30 bits       | ... |      30 bits       |
// In Validator Manager, #claims_validator indicates the #claims the validator has made.
// In Fee Manager, #claims_validator indicates the #claims the validator has redeemed. In this case,
//      agreement mask and consensus goal mask are not used.

type ClaimsMask is uint256;

library LibClaimsMask {
    uint256 constant claimsBitLen = 30; // #bits used for each #claims

    /// @notice this function creates a new ClaimsMask variable with value _value
    /// @param  _value the value following the format of ClaimsMask
    function newClaimsMask(uint256 _value) public pure returns (ClaimsMask) {
        return ClaimsMask.wrap(_value);
    }

    /// @notice this function creates a new ClaimsMask variable with the consensus goal mask set,
    ///         according to the number of validators
    /// @param  _numValidators the number of validators
    function newClaimsMaskWithConsensusGoalSet(uint256 _numValidators)
        public
        pure
        returns (ClaimsMask)
    {
        require(_numValidators <= 8, "up to 8 validators");
        uint256 consensusMask = (1 << _numValidators) - 1;
        return ClaimsMask.wrap(consensusMask << 240); // 256 - 8 - 8 = 240
    }

    /// @notice this function returns the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    ///     this index can be obtained though `getNumberOfClaimsByIndex` function in Validator Manager
    function getNumClaims(ClaimsMask _claimsMask, uint256 _validatorIndex)
        public
        pure
        returns (uint256)
    {
        require(_validatorIndex < 8, "index out of range");
        uint256 bitmask = (1 << claimsBitLen) - 1;
        return
            (ClaimsMask.unwrap(_claimsMask) >>
                (claimsBitLen * _validatorIndex)) & bitmask;
    }

    /// @notice this function increases the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    /// @param  _value the increase amount
    function increaseNumClaims(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex,
        uint256 _value
    ) public pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        uint256 currentNum = getNumClaims(_claimsMask, _validatorIndex);
        uint256 newNum = currentNum + _value; // overflows checked by default with sol0.8
        return setNumClaims(_claimsMask, _validatorIndex, newNum);
    }

    /// @notice this function sets the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    /// @param  _value the set value
    function setNumClaims(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex,
        uint256 _value
    ) public pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        require(_value <= ((1 << claimsBitLen) - 1), "ClaimsMask Overflow");
        uint256 bitmask = ~(((1 << claimsBitLen) - 1) <<
            (claimsBitLen * _validatorIndex));
        uint256 clearedClaimsMask = ClaimsMask.unwrap(_claimsMask) & bitmask;
        _claimsMask = ClaimsMask.wrap(
            clearedClaimsMask | (_value << (claimsBitLen * _validatorIndex))
        );
        return _claimsMask;
    }

    /// @notice get consensus goal mask
    /// @param  _claimsMask the ClaimsMask value
    function clearAgreementMask(ClaimsMask _claimsMask)
        public
        pure
        returns (ClaimsMask)
    {
        uint256 clearedMask = ClaimsMask.unwrap(_claimsMask) & ((1 << 248) - 1); // 256 - 8 = 248
        return ClaimsMask.wrap(clearedMask);
    }

    /// @notice get the entire agreement mask
    /// @param  _claimsMask the ClaimsMask value
    function getAgreementMask(ClaimsMask _claimsMask)
        public
        pure
        returns (uint256)
    {
        return (ClaimsMask.unwrap(_claimsMask) >> 248); // get the first 8 bits
    }

    /// @notice check if a validator has already claimed
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function alreadyClaimed(ClaimsMask _claimsMask, uint256 _validatorIndex)
        public
        pure
        returns (bool)
    {
        // get the first 8 bits. Then & operation on the validator's bit to see if it's set
        return
            (((ClaimsMask.unwrap(_claimsMask) >> 248) >> _validatorIndex) &
                1) != 0;
    }

    /// @notice set agreement mask for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function setAgreementMask(ClaimsMask _claimsMask, uint256 _validatorIndex)
        public
        pure
        returns (ClaimsMask)
    {
        require(_validatorIndex < 8, "index out of range");
        uint256 setMask = (ClaimsMask.unwrap(_claimsMask) |
            (1 << (248 + _validatorIndex))); // 256 - 8 = 248
        return ClaimsMask.wrap(setMask);
    }

    /// @notice get the entire consensus goal mask
    /// @param  _claimsMask the ClaimsMask value
    function getConsensusGoalMask(ClaimsMask _claimsMask)
        public
        pure
        returns (uint256)
    {
        return ((ClaimsMask.unwrap(_claimsMask) << 8) >> 248); // get the second 8 bits
    }

    /// @notice remove validator from the ClaimsMask
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function removeValidator(ClaimsMask _claimsMask, uint256 _validatorIndex)
        public
        pure
        returns (ClaimsMask)
    {
        require(_validatorIndex < 8, "index out of range");
        uint256 claimsMaskValue = ClaimsMask.unwrap(_claimsMask);
        // remove validator from agreement bitmask
        uint256 zeroMask = ~(1 << (_validatorIndex + 248)); // 256 - 8 = 248
        claimsMaskValue = (claimsMaskValue & zeroMask);
        // remove validator from consensus goal mask
        zeroMask = ~(1 << (_validatorIndex + 240)); // 256 - 8 - 8 = 240
        claimsMaskValue = (claimsMaskValue & zeroMask);
        // remove validator from #claims
        return
            setNumClaims(ClaimsMask.wrap(claimsMaskValue), _validatorIndex, 0);
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Fee Manager library
pragma solidity ^0.8.0;

import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibClaimsMask, ClaimsMask} from "../libraries/LibClaimsMask.sol";

library LibFeeManager {
    using LibValidatorManager for LibValidatorManager.DiamondStorage;
    using LibFeeManager for LibFeeManager.DiamondStorage;
    using LibClaimsMask for ClaimsMask;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("FeeManager.diamond.storage");

    struct DiamondStorage {
        address owner; // owner of Fee Manager
        uint256 feePerClaim;
        IERC20 token; // the token that is used for paying fees to validators
        bool lock; // reentrancy lock
        // A bit set used for up to 8 validators.
        // The first 16 bits are not used to keep compatibility with the validator manager contract.
        // The following every 30 bits are used to indicate the number of total claims each validator has made
        // |     not used    | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
        // |     16 bits     |      30 bits       |      30 bits       | ... |      30 bits       |
        ClaimsMask numClaimsRedeemed;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage feeManagerDS)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            feeManagerDS.slot := position
        }
    }

    function onlyOwner(DiamondStorage storage ds) internal view {
        require(ds.owner == msg.sender, "caller is not the owner");
    }

    /// @notice this function can be called to check the number of claims that's redeemable for the validator
    /// @param  feeManagerDS pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator
    function numClaimsRedeemable(
        DiamondStorage storage feeManagerDS,
        address _validator
    ) internal view returns (uint256) {
        require(_validator != address(0), "address should not be 0");

        LibValidatorManager.DiamondStorage
            storage ValidatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = ValidatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        uint256 totalClaims = ValidatorManagerDS.claimsMask.getNumClaims(
            valIndex
        );
        uint256 redeemedClaims = feeManagerDS.numClaimsRedeemed.getNumClaims(
            valIndex
        );

        return totalClaims - redeemedClaims; // underflow checked by default with sol0.8
    }

    /// @notice this function can be called to check the number of claims that has been redeemed for the validator
    /// @param  feeManagerDS pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator
    function getNumClaimsRedeemed(
        DiamondStorage storage feeManagerDS,
        address _validator
    ) internal view returns (uint256) {
        require(_validator != address(0), "address should not be 0");

        LibValidatorManager.DiamondStorage
            storage ValidatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = ValidatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        uint256 redeemedClaims = feeManagerDS.numClaimsRedeemed.getNumClaims(
            valIndex
        );

        return redeemedClaims;
    }

    /// @notice contract owner can reset the value of fee per claim
    /// @param  feeManagerDS pointer to FeeManager's diamond storage
    /// @param  _value the new value of fee per claim
    function resetFeePerClaim(
        DiamondStorage storage feeManagerDS,
        uint256 _value
    ) internal {
        // before resetting the feePerClaim, pay fees for all validators as per current rates
        LibValidatorManager.DiamondStorage
            storage ValidatorManagerDS = LibValidatorManager.diamondStorage();
        for (uint256 i; i < ValidatorManagerDS.maxNumValidators; i++) {
            address validator = ValidatorManagerDS.validators[i];
            if (
                validator != address(0) &&
                feeManagerDS.numClaimsRedeemable(validator) > 0
            ) {
                feeManagerDS.redeemFee(validator);
            }
        }
        feeManagerDS.feePerClaim = _value;
        emit FeePerClaimReset(_value);
    }

    /// @notice this function can be called to redeem fees for validators
    /// @param  feeManagerDS pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator that is redeeming
    function redeemFee(DiamondStorage storage feeManagerDS, address _validator)
        internal
    {
        // follow the Checks-Effects-Interactions pattern for security

        // ** checks **
        uint256 nowRedeemingClaims = feeManagerDS.numClaimsRedeemable(
            _validator
        );
        require(nowRedeemingClaims > 0, "nothing to redeem yet");

        // ** effects **
        LibValidatorManager.DiamondStorage
            storage ValidatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = ValidatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        feeManagerDS.numClaimsRedeemed = feeManagerDS
            .numClaimsRedeemed
            .increaseNumClaims(valIndex, nowRedeemingClaims);

        // ** interactions **
        uint256 feesToSend = nowRedeemingClaims * feeManagerDS.feePerClaim; // number of erc20 tokens to send
        require(
            feeManagerDS.token.transfer(_validator, feesToSend),
            "Failed to redeem fees"
        );
        emit FeeRedeemed(_validator, feesToSend);
    }

    /// @notice emitted on resetting feePerClaim
    event FeePerClaimReset(uint256 _value);

    /// @notice emitted on ERC20 funds redeemed by validator
    event FeeRedeemed(address _validator, uint256 _amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

/// @title Validator Manager interface
pragma solidity >=0.7.0;

// NoConflict - No conflicting claims or consensus
// Consensus - All validators had equal claims
// Conflict - Claim is conflicting with previous one
enum Result {
    NoConflict,
    Consensus,
    Conflict
}

// TODO: What is the incentive for validators to not just copy the first claim that arrived?
interface IValidatorManager {
    /// @notice get current claim
    function getCurrentClaim() external view returns (bytes32);

    /// @notice emitted on Claim received
    event ClaimReceived(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on Dispute end
    event DisputeEnded(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on new Epoch
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

/// @title Output library
pragma solidity ^0.8.0;

library LibOutput {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Output.diamond.storage");

    struct DiamondStorage {
        mapping(uint256 => uint256) voucherBitmask;
        bytes32[] epochHashes;
        bool lock; //reentrancy lock
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice to be called when an epoch is finalized
    /// @param ds diamond storage pointer
    /// @param epochHash hash of finalized epoch
    /// @dev an epoch being finalized means that its vouchers can be called
    function onNewEpoch(DiamondStorage storage ds, bytes32 epochHash) internal {
        ds.epochHashes.push(epochHash);
    }

    /// @notice get number of finalized epochs
    /// @param ds diamond storage pointer
    function getNumberOfFinalizedEpochs(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        return ds.epochHashes.length;
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

/// @title Dispute Manager library
pragma solidity ^0.8.0;

import {LibRollups} from "../libraries/LibRollups.sol";

library LibDisputeManager {
    using LibRollups for LibRollups.DiamondStorage;

    /// @notice initiates a dispute betweent two players
    /// @param claims conflicting claims
    /// @param claimers addresses of senders of conflicting claim
    /// @dev this is a mock implementation that just gives the win
    ///      to the address in the first posititon of claimers array
    function initiateDispute(
        bytes32[2] memory claims,
        address payable[2] memory claimers
    ) internal {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        rollupsDS.resolveDispute(claimers[0], claimers[1], claims[0]);
    }
}