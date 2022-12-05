// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interface/IBlockManager.sol";
import "./interface/IStakeManager.sol";
import "./interface/IRewardManager.sol";
import "./interface/IVoteManager.sol";
import "./interface/ICollectionManager.sol";
import "../randomNumber/IRandomNoProvider.sol";
import "./storage/BlockStorage.sol";
import "./parameters/child/BlockManagerParams.sol";
import "./StateManager.sol";
import "../lib/Random.sol";
import "../Initializable.sol";

/** @title BlockManager
 * @notice BlockManager manages the proposal, confirmation and dispute of blocks
 */

contract BlockManager is Initializable, BlockStorage, StateManager, BlockManagerParams, IBlockManager {
    IStakeManager public stakeManager;
    IRewardManager public rewardManager;
    IVoteManager public voteManager;
    ICollectionManager public collectionManager;
    IRandomNoProvider public randomNoProvider;

    /**
     * @dev Emitted when a block is confirmed
     * @param epoch epoch when the block was confirmed
     * @param stakerId id of the staker that confirmed the block
     * @param ids of the proposed block
     * @param medians of the confirmed block
     * @param timestamp time when the block was confirmed
     */
    event BlockConfirmed(uint32 epoch, uint32 indexed stakerId, uint16[] ids, uint256 timestamp, uint256[] medians);

    /**
     * @dev Emitted when a staker claims block reward
     * @param epoch epoch when the block reward was claimed
     * @param stakerId id of the staker that claimed the block reward
     * @param timestamp time when the block reward was claimed
     */
    event ClaimBlockReward(uint32 epoch, uint32 indexed stakerId, uint256 timestamp);

    /**
     * @dev Emitted when a block is proposed
     * @param epoch epoch when the block was proposed
     * @param stakerId id of the staker that proposed the block
     * @param ids of the proposed block
     * @param medians of the proposed block
     * @param iteration staker's iteration
     * @param biggestStakerId id of the staker that has the highest stake amongst the stakers that revealed
     * @param timestamp time when the block was proposed
     */
    event Proposed(
        uint32 epoch,
        uint32 indexed stakerId,
        uint32 biggestStakerId,
        uint16[] ids,
        uint256 iteration,
        uint256 timestamp,
        uint256[] medians
    );

    /**
     * @dev Emitted when the staker calls giveSorted
     * @param epoch epoch in which the dispute was setup and raised
     * @param leafId index of the collection that is to be disputed
     * @param sortedValues values reported by staker for a collection in ascending order
     */
    event GiveSorted(uint32 epoch, uint16 indexed leafId, uint256[] sortedValues);

    /**
     * @dev Emitted when the disputer raise dispute for biggestStakeProposed
     * @param epoch epoch in which the dispute was raised
     * @param blockIndex index of the block that is to be disputed
     * @param correctBiggestStakerId the correct biggest staker id
     * @param disputer address that raised the dispute
     */
    event DisputeBiggestStakeProposed(uint32 epoch, uint8 blockIndex, uint32 indexed correctBiggestStakerId, address indexed disputer);

    /**
     * @dev Emitted when the disputer raise dispute for collection id that should be absent
     * @param epoch epoch in which the dispute was raised
     * @param blockIndex index of the block that is to be disputed
     * @param id collection id
     * @param postionOfCollectionInBlock position of collection id to be disputed inside ids proposed by block
     * @param disputer address that raised the dispute
     */
    event DisputeCollectionIdShouldBeAbsent(
        uint32 epoch,
        uint8 blockIndex,
        uint32 indexed id,
        uint256 postionOfCollectionInBlock,
        address indexed disputer
    );

    /**
     * @dev Emitted when the disputer raise dispute for collection id that should be present
     * @param epoch epoch in which the dispute was raised
     * @param blockIndex index of the block that is to be disputed
     * @param id collection id that should be present
     * @param disputer address that raised the dispute
     */
    event DisputeCollectionIdShouldBePresent(uint32 epoch, uint8 blockIndex, uint32 indexed id, address indexed disputer);

    /**
     * @dev Emitted when the disputer raise dispute for the ids passed are not sorted in ascend order, or there is duplication
     * @param epoch epoch in which the dispute was raised
     * @param blockIndex index of the block that is to be disputed
     * @param index0 lower
     * @param index1 upper
     * @param disputer address that raised the dispute
     */
    event DisputeOnOrderOfIds(uint32 epoch, uint8 blockIndex, uint256 index0, uint256 index1, address indexed disputer);

    /**
     * @dev Emitted when the disputer calls finalizeDispute
     * @param epoch epoch in which the dispute was raised
     * @param blockIndex index of the block that is to be disputed
     * @param postionOfCollectionInBlock position of collection id to be disputed inside ids proposed by block
     * @param disputer address that raised the dispute
     */
    event FinalizeDispute(uint32 epoch, uint8 blockIndex, uint256 postionOfCollectionInBlock, address indexed disputer);

    /**
     * @param stakeManagerAddress The address of the StakeManager contract
     * @param rewardManagerAddress The address of the RewardManager contract
     * @param voteManagerAddress The address of the VoteManager contract
     * @param collectionManagerAddress The address of the CollectionManager contract
     * @param randomNoManagerAddress The address of the RandomNoManager contract
     */
    function initialize(
        address stakeManagerAddress,
        address rewardManagerAddress,
        address voteManagerAddress,
        address collectionManagerAddress,
        address randomNoManagerAddress
    ) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeManager = IStakeManager(stakeManagerAddress);
        rewardManager = IRewardManager(rewardManagerAddress);
        voteManager = IVoteManager(voteManagerAddress);
        collectionManager = ICollectionManager(collectionManagerAddress);
        randomNoProvider = IRandomNoProvider(randomNoManagerAddress);
    }

    /**
     * @notice elected proposer proposes block.
     * we use a probabilistic method to elect stakers weighted by stake
     * protocol works like this.
     * to find the iteration of a staker, a bias coin is tossed such that
     * bias = hisStake/biggestStake revealed. if its heads, he can propose block
     * end of iteration. try next iteration
     * stakers elected in higher iterations can also propose hoping that
     * stakers with lower iteration do not propose for some reason
     * @dev The IDs being passed here, are only used for disputeForNonAssignedCollection
     * for delegator, we have seprate registry
     * If user passes invalid ids, disputeForProposedCollectionIds can happen
     * @param epoch in which the block was proposed
     * @param ids ids of the proposed block
     * @param medians medians of the proposed block
     * @param iteration number of times a biased coin was thrown to get a head
     * @param biggestStakerId id of the staker that has the biggest stake amongst the stakers that have revealed
     */
    function propose(
        uint32 epoch,
        uint16[] memory ids,
        uint256[] memory medians,
        uint256 iteration,
        uint32 biggestStakerId
    ) external initialized checkEpochAndState(State.Propose, epoch, buffer) {
        uint32 proposerId = stakeManager.getStakerId(msg.sender);
        //staker can just skip commit/reveal and only propose every epoch to avoid penalty.
        //following line is to prevent that
        require(voteManager.getEpochLastRevealed(proposerId) == epoch, "Cannot propose without revealing");
        require(_isElectedProposer(iteration, biggestStakerId, proposerId, epoch), "not elected");
        require(stakeManager.getStake(proposerId) >= minStake, "stake below minimum stake");
        require(epochLastProposed[proposerId] != epoch, "Already proposed");
        require(ids.length == medians.length, "Invalid block proposed");

        uint256 biggestStake = voteManager.getStakeSnapshot(epoch, biggestStakerId);
        if (sortedProposedBlockIds[epoch].length == 0) numProposedBlocks = 0;
        proposedBlocks[epoch][numProposedBlocks] = Structs.Block(true, proposerId, ids, iteration, biggestStake, medians);
        bool isAdded = _insertAppropriately(epoch, numProposedBlocks, iteration, biggestStake);
        epochLastProposed[proposerId] = epoch;
        if (isAdded) {
            numProposedBlocks = numProposedBlocks + 1;
        }
        emit Proposed(epoch, proposerId, biggestStakerId, ids, iteration, block.timestamp, medians);
    }

    /**
     * @notice if someone feels that median result of a collection in a block is not in accordance to the protocol,
     * giveSorted() needs to be called to setup the dispute where in, the correct median will be calculated based on the votes
     * reported by stakers
     * @param epoch in which the dispute was setup and raised
     * @param leafId index of the collection that is to be disputed
     * @param sortedValues values reported by staker for a collection in ascending order
     */
    function giveSorted(
        uint32 epoch,
        uint16 leafId,
        uint256[] memory sortedValues
    ) external initialized checkEpochAndState(State.Dispute, epoch, buffer) {
        require(leafId <= (collectionManager.getNumActiveCollections() - 1), "Invalid leafId");
        uint256 medianWeight = voteManager.getTotalInfluenceRevealed(epoch, leafId) / 2;
        uint256 accWeight = disputes[epoch][msg.sender].accWeight;
        uint256 lastVisitedValue = disputes[epoch][msg.sender].lastVisitedValue;

        if (disputes[epoch][msg.sender].accWeight == 0) {
            disputes[epoch][msg.sender].leafId = leafId;
        } else {
            require(disputes[epoch][msg.sender].leafId == leafId, "leafId mismatch");
            // require(disputes[epoch][msg.sender].median == 0, "median already found");
        }
        for (uint32 i = 0; i < sortedValues.length; i++) {
            require(sortedValues[i] > lastVisitedValue, "sortedValue <= LVV "); // LVV : Last Visited Value
            lastVisitedValue = sortedValues[i];

            // reason to ignore : has to be done, as each vote will have diff weight
            // slither-disable-next-line calls-loop
            uint256 weight = voteManager.getVoteWeight(epoch, leafId, sortedValues[i]);
            accWeight = accWeight + weight;
            if (disputes[epoch][msg.sender].median == 0 && accWeight > medianWeight) {
                disputes[epoch][msg.sender].median = sortedValues[i];
            }
        }
        disputes[epoch][msg.sender].lastVisitedValue = lastVisitedValue;
        disputes[epoch][msg.sender].accWeight = accWeight;
        emit GiveSorted(epoch, leafId, sortedValues);
    }

    /**
     * @notice if any mistake made during giveSorted, resetDispute will reset their dispute calculations
     * and they can start again
     * @param epoch in which the dispute was setup and raised
     */
    function resetDispute(uint32 epoch) external initialized checkEpochAndState(State.Dispute, epoch, buffer) {
        disputes[epoch][msg.sender] = Structs.Dispute(0, 0, 0, 0);
    }

    /**
     * @notice claimBlockReward() is to be called by the selected staker whose proposed block has the lowest iteration
     * and is valid. This will confirm the block and rewards the selected staker with the block reward
     */
    function claimBlockReward() external initialized checkState(State.Confirm, buffer) {
        uint32 epoch = _getEpoch();
        uint32 stakerId = stakeManager.getStakerId(msg.sender);
        require(stakerId > 0, "Structs.Staker does not exist");
        // slither-disable-next-line timestamp
        require(blocks[epoch].proposerId == 0, "Block already confirmed");
        // proposerId, epoch, timestamp

        if (sortedProposedBlockIds[epoch].length != 0 && blockIndexToBeConfirmed != -1) {
            uint32 proposerId = proposedBlocks[epoch][sortedProposedBlockIds[epoch][uint8(blockIndexToBeConfirmed)]].proposerId;
            require(proposerId == stakerId, "Block Proposer mismatches");
            emit ClaimBlockReward(epoch, stakerId, block.timestamp);
            _confirmBlock(epoch, proposerId);
        }
        uint32 updateRegistryEpoch = collectionManager.getUpdateRegistryEpoch();
        // slither-disable-next-line incorrect-equality, timestamp
        if (updateRegistryEpoch <= epoch) {
            collectionManager.updateDelayedRegistry();
        }
    }

    /// @inheritdoc IBlockManager
    function confirmPreviousEpochBlock(uint32 stakerId) external override initialized onlyRole(BLOCK_CONFIRMER_ROLE) {
        uint32 epoch = _getEpoch();

        if (sortedProposedBlockIds[epoch - 1].length != 0 && blockIndexToBeConfirmed != -1) {
            _confirmBlock(epoch - 1, stakerId);
        }
        uint32 updateRegistryEpoch = collectionManager.getUpdateRegistryEpoch();
        // slither-disable-next-line incorrect-equality,timestamp
        if (updateRegistryEpoch <= epoch - 1) {
            collectionManager.updateDelayedRegistry();
        }
    }

    /**
     * @notice a dispute can be raised on the block if the block proposed has the incorrect biggest Stake.
     * If the dispute is passed and executed, the stake of the staker who proposed such a block will be slashed.
     * The address that raised the dispute will receive a bounty on the staker's stake depending on SlashNums
     * @param epoch in which this dispute was raised
     * @param blockIndex index of the block that is to be disputed
     * @param correctBiggestStakerId the correct biggest staker id
     */
    function disputeBiggestStakeProposed(
        uint32 epoch,
        uint8 blockIndex,
        uint32 correctBiggestStakerId
    ) external initialized checkEpochAndState(State.Dispute, epoch, buffer) {
        uint32 blockId = sortedProposedBlockIds[epoch][blockIndex];
        require(proposedBlocks[epoch][blockId].valid, "Block already has been disputed");
        uint256 correctBiggestStake = voteManager.getStakeSnapshot(epoch, correctBiggestStakerId);
        require(correctBiggestStake > proposedBlocks[epoch][blockId].biggestStake, "Invalid dispute : Stake");
        emit DisputeBiggestStakeProposed(epoch, blockIndex, correctBiggestStakerId, msg.sender);
        _executeDispute(epoch, blockIndex, blockId);
    }

    /**
     * @notice Dispute to prove that id should be absent, when its present in a proposed block.
     * @param epoch in which the dispute was setup
     * @param blockIndex index of the block that is to be disputed
     * @param id collection id
     * @param postionOfCollectionInBlock position of collection id to be disputed inside ids proposed by block
     */
    function disputeCollectionIdShouldBeAbsent(
        uint32 epoch,
        uint8 blockIndex,
        uint16 id,
        uint256 postionOfCollectionInBlock
    ) external initialized checkEpochAndState(State.Dispute, epoch, buffer) {
        uint32 blockId = sortedProposedBlockIds[epoch][blockIndex];
        require(proposedBlocks[epoch][blockId].valid, "Block already has been disputed");
        // Step 1 : If its active collection, total influence revealed should be zero
        if (collectionManager.getCollectionStatus(id)) {
            // Get leafId from collectionId, as voting is done w.r.t leafIds
            uint16 leafId = collectionManager.getLeafIdOfCollection(id);
            uint256 totalInfluenceRevealed = voteManager.getTotalInfluenceRevealed(epoch, leafId);
            require(totalInfluenceRevealed == 0, "Dispute: ID should be present");
        }
        // Step 2: Prove that given id is indeed present in block
        require(proposedBlocks[epoch][blockId].ids[postionOfCollectionInBlock] == id, "Dispute: ID absent only");
        emit DisputeCollectionIdShouldBeAbsent(epoch, blockIndex, id, postionOfCollectionInBlock, msg.sender);
        _executeDispute(epoch, blockIndex, blockId);
    }

    /**
     * @notice Dispute to prove that id should be present, when its not in a proposed block.
     * @param epoch in which the dispute was setup
     * @param blockIndex index of the block that is to be disputed
     * @param id collection id
     */
    function disputeCollectionIdShouldBePresent(
        uint32 epoch,
        uint8 blockIndex,
        uint16 id
    ) external initialized checkEpochAndState(State.Dispute, epoch, buffer) {
        uint32 blockId = sortedProposedBlockIds[epoch][blockIndex];
        require(proposedBlocks[epoch][blockId].valid, "Block already has been disputed");
        // Get leafId from collectionId, as voting is done w.r.t leafIds
        uint16 leafId = collectionManager.getLeafIdOfCollection(id);
        uint256 totalInfluenceRevealed = voteManager.getTotalInfluenceRevealed(epoch, leafId);

        require(totalInfluenceRevealed != 0, "Dispute: ID should be absent");

        Structs.Block memory _block = proposedBlocks[epoch][blockId];
        bool toDispute = true;

        if (_block.ids.length != 0) {
            // normal search
            // for (uint256 i = 0; i < _block.ids.length; i++)
            //         if (_block.ids[i] == id) {
            //             toDispute = false;
            //             break;
            //         }

            // binary search
            // impl taken and modified from
            // https://github.com/compound-finance/compound-protocol/blob/4a8648ec0364d24c4ecfc7d6cae254f55030d65f/contracts/Governance/Comp.sol#L207
            uint256 lower = 0;
            uint256 upper = _block.ids.length - 1;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                uint16 _id = _block.ids[center];
                if (_id == id) {
                    toDispute = false;
                    break;
                } else if (_id < id) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
            if (_block.ids[lower] == id) toDispute = false;
        }

        require(toDispute, "Dispute: ID present only");
        emit DisputeCollectionIdShouldBePresent(epoch, blockIndex, id, msg.sender);
        _executeDispute(epoch, blockIndex, blockId);
    }

    /**
     * @notice Dispute to prove the ids passed or not sorted in ascend order, or there is duplication
     * @param epoch in which the dispute was setup
     * @param blockIndex index of the block that is to be disputed
     * @param index0 lower
     * @param index1 upper
     *  Valid Block :
     *  If index0 < index1 &&
     *  value0 < value1
     */
    function disputeOnOrderOfIds(
        uint32 epoch,
        uint8 blockIndex,
        uint256 index0,
        uint256 index1
    ) external initialized checkEpochAndState(State.Dispute, epoch, buffer) {
        uint32 blockId = sortedProposedBlockIds[epoch][blockIndex];
        require(proposedBlocks[epoch][blockId].valid, "Block already has been disputed");
        require(index0 < index1, "index1 not greater than index0 0");
        require(proposedBlocks[epoch][blockId].ids[index0] >= proposedBlocks[epoch][blockId].ids[index1], "ID at i0 not gt than of i1");
        emit DisputeOnOrderOfIds(epoch, blockIndex, index0, index1, msg.sender);
        _executeDispute(epoch, blockIndex, blockId);
    }

    /**
     * @notice dispute on median result of a collection in a particular block is finalized after giveSorted was
     * called by the address who setup the dispute. If the dispute is passed and executed, the stake of the staker who
     * proposed such a block will be slashed. The address that raised the dispute will receive a bounty on the
     * staker's stake depending on SlashNums
     * @param epoch in which the dispute was setup
     * @param blockIndex index of the block that is to be disputed
     * @param postionOfCollectionInBlock position of collection id to be disputed inside ids proposed by block
     */
    function finalizeDispute(
        uint32 epoch,
        uint8 blockIndex,
        uint256 postionOfCollectionInBlock
    ) external initialized checkEpochAndState(State.Dispute, epoch, buffer) {
        require(
            disputes[epoch][msg.sender].accWeight == voteManager.getTotalInfluenceRevealed(epoch, disputes[epoch][msg.sender].leafId),
            "TIR is wrong"
        ); // TIR : total influence revealed
        require(disputes[epoch][msg.sender].accWeight != 0, "Invalid dispute");
        // Would revert if no block is proposed, or the asset specifed was not revealed
        uint32 blockId = sortedProposedBlockIds[epoch][blockIndex];
        require(proposedBlocks[epoch][blockId].valid, "Block already has been disputed");
        uint16 leafId = disputes[epoch][msg.sender].leafId;
        // Get collection id from leafId, as propose happens w.r.t to ids
        uint16 id = collectionManager.getCollectionIdFromLeafId(leafId);

        Structs.Block memory _block = proposedBlocks[epoch][blockId];
        require(_block.ids[postionOfCollectionInBlock] == id, "Wrong Coll Index passed");
        uint256 proposedValue = proposedBlocks[epoch][blockId].medians[postionOfCollectionInBlock];

        require(proposedValue != disputes[epoch][msg.sender].median, "Block proposed with same medians");
        emit FinalizeDispute(epoch, blockIndex, postionOfCollectionInBlock, msg.sender);
        _executeDispute(epoch, blockIndex, blockId);
    }

    /// @inheritdoc IBlockManager
    function getBlock(uint32 epoch) external view override returns (Structs.Block memory _block) {
        return (blocks[epoch]);
    }

    /**
     * @notice return the struct of the proposed block
     * @param epoch in which this block was proposed
     * @param proposedBlock id of the proposed block
     * @return _block : struct of the proposed block
     */
    function getProposedBlock(uint32 epoch, uint32 proposedBlock) external view returns (Structs.Block memory _block) {
        _block = proposedBlocks[epoch][proposedBlock];
        return (_block);
    }

    /**
     * @notice returns number of the block proposed in a particular epoch
     * @param epoch in which blocks were proposed
     * @return number of the block proposed
     */
    function getNumProposedBlocks(uint32 epoch) external view returns (uint8) {
        return (uint8(sortedProposedBlockIds[epoch].length));
    }

    /// @inheritdoc IBlockManager
    function isBlockConfirmed(uint32 epoch) external view override returns (bool) {
        return (blocks[epoch].proposerId != 0);
    }

    /// @inheritdoc IBlockManager
    function getLatestResults(uint16 id) external view override returns (uint256) {
        return latestResults[id];
    }

    /**
     * @notice an internal function in which the block is confirmed.
     * @dev The staker who confirms the block receives the block reward, creates the salt for the next epoch and stores
     * it in the voteManager and provides this salt as secret to the random Manager to generate random number
     * @param epoch in which the block is being confirmed
     * @param stakerId id of the staker that is confirming the block
     */
    function _confirmBlock(uint32 epoch, uint32 stakerId) internal {
        uint32 blockId = sortedProposedBlockIds[epoch][uint8(blockIndexToBeConfirmed)];
        blocks[epoch] = proposedBlocks[epoch][blockId];
        bytes32 salt = keccak256(abi.encodePacked(epoch, blocks[epoch].medians)); // not iteration as it can be manipulated

        Structs.Block memory _block = blocks[epoch];
        for (uint256 i = 0; i < _block.ids.length; i++) {
            latestResults[_block.ids[i]] = _block.medians[i];
        }

        emit BlockConfirmed(epoch, _block.proposerId, _block.ids, block.timestamp, _block.medians);

        voteManager.storeSalt(salt);
        rewardManager.giveBlockReward(stakerId, epoch);
        randomNoProvider.provideSecret(epoch, salt);
    }

    /**
     * @dev inserts the block in the approporiate place based the iteration of each block proposed. the block
     * with the lowest iteration is given a higher priority to a lower value
     * @param epoch in which the block was proposed
     * @param blockId id of the proposed block
     * @param iteration number of tosses of a biased coin required for a head
     * @param biggestStake biggest Stake that was revealed
     * @return isAdded : whether the block was added to the array
     */
    function _insertAppropriately(
        uint32 epoch,
        uint32 blockId,
        uint256 iteration,
        uint256 biggestStake
    ) internal returns (bool isAdded) {
        uint8 sortedProposedBlockslength = uint8(sortedProposedBlockIds[epoch].length);

        if (sortedProposedBlockslength == 0) {
            sortedProposedBlockIds[epoch].push(0);
            blockIndexToBeConfirmed = 0;
            return true;
        }

        if (proposedBlocks[epoch][sortedProposedBlockIds[epoch][0]].biggestStake > biggestStake) {
            return false;
        }

        if (proposedBlocks[epoch][sortedProposedBlockIds[epoch][0]].biggestStake < biggestStake) {
            for (uint8 i = 0; i < sortedProposedBlockslength; i++) {
                sortedProposedBlockIds[epoch].pop();
            }
            sortedProposedBlockIds[epoch].push(blockId);
            return true;
        }

        for (uint8 i = 0; i < sortedProposedBlockslength; i++) {
            // Push and Shift
            if (proposedBlocks[epoch][sortedProposedBlockIds[epoch][i]].iteration > iteration) {
                sortedProposedBlockIds[epoch].push(blockId);

                sortedProposedBlockslength = sortedProposedBlockslength + 1;

                for (uint256 j = sortedProposedBlockslength - 1; j > i; j--) {
                    sortedProposedBlockIds[epoch][j] = sortedProposedBlockIds[epoch][j - 1];
                }

                sortedProposedBlockIds[epoch][i] = blockId;

                if (sortedProposedBlockIds[epoch].length > maxAltBlocks) {
                    sortedProposedBlockIds[epoch].pop();
                }

                return true;
            }
        }
        // Worst Iteration and for all other blocks, influence was >=
        if (sortedProposedBlockIds[epoch].length < maxAltBlocks) {
            sortedProposedBlockIds[epoch].push(blockId);
            return true;
        }
    }

    /**
     * @dev internal function executes dispute if a dispute has been passed
     * @param epoch in which the dispute was raised and passed
     * @param blockIndex index of the block that is disputed
     * @param blockId id of the block being disputed
     */
    function _executeDispute(
        uint32 epoch,
        uint8 blockIndex,
        uint32 blockId
    ) internal {
        proposedBlocks[epoch][blockId].valid = false;

        uint8 sortedProposedBlocksLength = uint8(sortedProposedBlockIds[epoch].length);
        if (uint8(blockIndexToBeConfirmed) == blockIndex) {
            // If the chosen one only is the culprit one, find successor
            // O(maxAltBlocks)

            blockIndexToBeConfirmed = -1;
            for (uint8 i = blockIndex + 1; i < sortedProposedBlocksLength; i++) {
                uint32 _blockId = sortedProposedBlockIds[epoch][i];
                if (proposedBlocks[epoch][_blockId].valid) {
                    // slither-disable-next-line costly-loop
                    blockIndexToBeConfirmed = int8(i);
                    break;
                }
            }
        }

        uint32 proposerId = proposedBlocks[epoch][blockId].proposerId;
        stakeManager.slash(epoch, proposerId, msg.sender);
    }

    /**
     * @dev an internal function that checks whether the iteration value sent by the staker is correct or no
     * @param iteration number of tosses of a biased coin required for a head
     * @param biggestStakerId id of the Staker that has the biggest stake amongst the stakers that have revealed
     * @param stakerId id of the staker
     * @param epoch in which the block was proposed
     */
    function _isElectedProposer(
        uint256 iteration,
        uint32 biggestStakerId,
        uint32 stakerId,
        uint32 epoch
    ) internal view initialized returns (bool) {
        // generating pseudo random number (range 0..(totalstake - 1)), add (+1) to the result,
        // since prng returns 0 to max-1 and staker start from 1

        bytes32 salt = voteManager.getSalt();
        //roll an n sided fair die where n == numStakers to select a staker pseudoRandomly
        bytes32 seed1 = Random.prngHash(salt, keccak256(abi.encode(iteration)));
        uint256 rand1 = Random.prng(stakeManager.getNumStakers(), seed1);
        if ((rand1 + 1) != stakerId) {
            return false;
        }
        //toss a biased coin with increasing iteration till the following equation returns true.
        // stake/biggest stake >= prng(iteration,stakerid, salt), staker wins
        // stake/biggest stake < prng(iteration,stakerid, salt), staker loses
        // simplified equation:- stake < prng * biggestStake
        // stake * 2^32 < prng * 2^32 * biggestStake
        // multiplying by 2^32 since seed2 is bytes32 so rand2 goes from 0 to 2^32
        bytes32 seed2 = Random.prngHash(salt, keccak256(abi.encode(stakerId, iteration)));
        uint256 rand2 = Random.prng(2**32, seed2);

        uint256 biggestStake = voteManager.getStakeSnapshot(epoch, biggestStakerId);
        uint256 stake = voteManager.getStakeSnapshot(epoch, stakerId);
        // Below line can't be tested since it can't be assured if it returns true or false
        if (rand2 * (biggestStake) > stake * (2**32)) return (false);
        return true;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * Forked from OZ's (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b9125001f0a1c44d596ca3a47536f1a467e3a29d/contracts/proxy/utils/Initializable.sol)
 */

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "contract already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier initialized() {
        require(_initialized, "Contract should be initialized");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";

interface IRewardManager {
    /**
     * @notice gives penalty to stakers for failing to reveal or
     * reveal value deviations
     * @param stakerId The id of staker currently in consideration
     * @param epoch the epoch value
     */
    function givePenalties(uint32 epoch, uint32 stakerId) external;

    /**
     * @notice The function gives block reward for one valid proposer in the
     * previous epoch by increasing stake of staker
     * called from confirmBlock function of BlockManager contract. Commission
     * from the delegator's pool is given out to the staker from the block reward
     * @param stakerId The ID of the staker
     */
    function giveBlockReward(uint32 epoch, uint32 stakerId) external;

    /**
     * @notice The function gives out penalties to stakers during commit.
     * The penalties are given for inactivity, failing to reveal
     * , deviation from the median value of particular asset
     * @param stakerId The staker id
     * @param epoch The Epoch value in consideration
     */
    function giveInactivityPenalties(uint32 epoch, uint32 stakerId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Random {
    // pseudo random number generator based on hash. returns 0 -> max-1
    // slither ignore reason : Internal library
    // slither-disable-next-line dead-code
    function prng(uint256 max, bytes32 randHash) internal pure returns (uint256) {
        uint256 sum = uint256(randHash);
        return (sum % max);
    }

    // pseudo random hash generator based on hashes.
    // slither ignore reason : Internal library
    // slither-disable-next-line dead-code
    function prngHash(bytes32 seed, bytes32 salt) internal pure returns (bytes32) {
        bytes32 prngHashVal = keccak256(abi.encodePacked(seed, salt));
        return (prngHashVal);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRandomNoProvider {
    /**
     * @notice Called by BlockManager in ClaimBlockReward or ConfirmBlockLastEpoch
     * @param epoch current epoch
     * @param _secret hash of encoded rando secret from stakers
     */
    function provideSecret(uint32 epoch, bytes32 _secret) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../../lib/Structs.sol";

contract BlockStorage {
    /// @notice mapping of epoch -> address -> dispute
    mapping(uint32 => mapping(address => Structs.Dispute)) public disputes;
    /// @notice mapping of epoch -> blockId -> block
    mapping(uint32 => mapping(uint32 => Structs.Block)) public proposedBlocks;
    /// @notice mapping of epoch->blockId
    mapping(uint32 => uint32[]) public sortedProposedBlockIds;
    /// @notice mapping of stakerId->epoch
    mapping(uint32 => uint32) public epochLastProposed;
    // @notice mapping for latest results of collection id->result
    mapping(uint16 => uint256) public latestResults;
    /// @notice total number of proposed blocks in an epoch
    // slither-disable-next-line constable-states
    uint32 public numProposedBlocks;
    /// @notice block index that is to be confirmed if not disputed
    // slither-disable-next-line constable-states
    int8 public blockIndexToBeConfirmed; // Index in sortedProposedBlockIds
    /// @notice mapping of  epoch -> blocks
    mapping(uint32 => Structs.Block) public blocks;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";
import "../storage/Constants.sol";

interface IStakeManager {
    /**
     * @notice External function for setting stake of the staker
     * Used by RewardManager
     * @param _epoch The epoch in which stake changes
     * @param _id of the staker
     * @param reason the reason for stake to change
     * @param prevStake previous stake of the staker
     * @param _stake updated stake of the staker
     */
    function setStakerStake(
        uint32 _epoch,
        uint32 _id,
        Constants.StakeChanged reason,
        uint256 prevStake,
        uint256 _stake
    ) external;

    /**
     * @notice The function is used by the Votemanager reveal function and BlockManager FinalizeDispute
     * to penalise the staker who lost his secret and make his stake less by "slashPenaltyAmount" and
     * transfer to bounty hunter half the "slashPenaltyAmount" of the staker
     * @param stakerId The ID of the staker who is penalised
     * @param bountyHunter The address of the bounty hunter
     */
    function slash(
        uint32 epoch,
        uint32 stakerId,
        address bountyHunter
    ) external;

    /**
     * @notice External function for setting staker age of the staker
     * Used by RewardManager
     * @param _epoch The epoch in which age changes
     * @param _id of the staker
     * @param _age the updated new age
     * @param reason the reason for age change
     */
    function setStakerAge(
        uint32 _epoch,
        uint32 _id,
        uint32 _age,
        Constants.AgeChanged reason
    ) external;

    /**
     * @notice External function for setting stakerReward of the staker
     * Used by RewardManager
     * @param _epoch The epoch in which stakerReward changes
     * @param _id of the staker
     * @param reason the reason for stakerReward to change
     * @param prevStakerReward previous stakerReward of the staker
     * @param _stakerReward updated stakerReward of the staker
     */
    function setStakerReward(
        uint32 _epoch,
        uint32 _id,
        Constants.StakerRewardChanged reason,
        uint256 prevStakerReward,
        uint256 _stakerReward
    ) external;

    /**
     * @notice External function for setting epochLastPenalized of the staker
     * Used by RewardManager
     * @param _id of the staker
     */
    function setStakerEpochFirstStakedOrLastPenalized(uint32 _epoch, uint32 _id) external;

    /**
     * @notice remove all funds in case of emergency
     */
    function escape(address _address) external;

    /**
     * @notice event being thrown after every successful sRZR transfer taking place
     * @param from sender
     * @param to recepient
     * @param amount srzr amount being transferred
     * @param stakerId of the staker
     */
    function srzrTransfer(
        address from,
        address to,
        uint256 amount,
        uint32 stakerId
    ) external;

    /**
     * @param _address Address of the staker
     * @return The staker ID
     */
    function getStakerId(address _address) external view returns (uint32);

    /**
     * @param _id The staker ID
     * @return staker The Struct of staker information
     */
    function getStaker(uint32 _id) external view returns (Structs.Staker memory staker);

    /**
     * @return The number of stakers in the razor network
     */
    function getNumStakers() external view returns (uint32);

    /**
     * @return influence of staker
     */
    function getInfluence(uint32 stakerId) external view returns (uint256);

    /**
     * @return stake of staker
     */
    function getStake(uint32 stakerId) external view returns (uint256);

    /**
     * @return epochFirstStakedOrLastPenalized of staker
     */
    function getEpochFirstStakedOrLastPenalized(uint32 stakerId) external view returns (uint32);

    /**
     * @return length of maturities array
     */
    function maturitiesLength() external view returns (uint32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";

interface IBlockManager {
    /**
     * @notice if the proposed staker, whose block is valid and has the lowest iteration, does not call claimBlockReward()
     * then in commit state, the staker who commits first will confirm this block and will receive the block reward inturn
     * @param stakerId id of the staker that is confirming the block
     */
    function confirmPreviousEpochBlock(uint32 stakerId) external;

    /**
     * @notice return the struct of the confirmed block
     * @param epoch in which this block was confirmed
     * @return _block : struct of the confirmed block
     */
    function getBlock(uint32 epoch) external view returns (Structs.Block memory _block);

    /**
     * @notice this is to check whether a block was confirmed in a particular epoch or not
     * @param epoch for which this check is being done
     * @return true or false. true if a block has been confirmed, else false
     */
    function isBlockConfirmed(uint32 epoch) external view returns (bool);

    /**
     * @notice Allows to get latest result of collection from id, used by delegator
     * @param id Collection ID
     */
    function getLatestResults(uint16 id) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";

interface IVoteManager {
    /**
     * @notice stores the salt calculated in block manager
     * @param _salt the hash of the last epoch and medians of the block
     */
    function storeSalt(bytes32 _salt) external;

    /**
     * @notice stores the depth of a valid merkle tree. Depth of the merkle tree sent by the stakers should match with this
     * for a valid commit/reveal
     * @param _depth depth of the merkle tree
     */
    function storeDepth(uint256 _depth) external;

    /**
     * @notice returns vote value of a collection reported by a particular staker
     * @param epoch in which the staker reveal this value
     * @param stakerId id of the staker
     * @param leafId seq position of collection in merkle tree
     * @return vote value
     */
    function getVoteValue(
        uint32 epoch,
        uint32 stakerId,
        uint16 leafId
    ) external view returns (uint256);

    /**
     * @notice returns vote weight of the value of the collection reported
     * @param epoch in which the staker reveal this value
     * @param leafId seq position of collection in merkle tree
     * @param voteValue one of the values of the collection being reported
     * @return vote weight of the vote
     */
    function getVoteWeight(
        uint32 epoch,
        uint16 leafId,
        uint256 voteValue
    ) external view returns (uint256);

    /**
     * @notice returns snapshot of influence of the staker when they revealed
     * @param epoch when the snapshot was taken
     * @param stakerId id of the staker
     * @return influence of the staker
     */
    function getInfluenceSnapshot(uint32 epoch, uint32 stakerId) external view returns (uint256);

    /**
     * @notice returns snapshot of stake of the staker when they revealed
     * @param epoch when the snapshot was taken
     * @param stakerId id of the staker
     * @return stake of the staker
     */
    function getStakeSnapshot(uint32 epoch, uint32 stakerId) external view returns (uint256);

    /**
     * @notice returns the total influence revealed of the collection
     * @param epoch when asset was being revealed
     * @param leafId seq position of collection in merkle tree
     * @return total influence revealed of the collection
     */
    function getTotalInfluenceRevealed(uint32 epoch, uint16 leafId) external view returns (uint256);

    /**
     * @notice returns the epoch a staker last revealed their votes
     * @param stakerId id of the staker
     * @return epoch last revealed
     */
    function getEpochLastRevealed(uint32 stakerId) external view returns (uint32);

    /**
     * @notice returns the epoch a staker last committed their votes
     * @param stakerId id of the staker
     * @return epoch last committed
     */
    function getEpochLastCommitted(uint32 stakerId) external view returns (uint32);

    /**
     * @return the salt
     */
    function getSalt() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICollectionManager {
    /**
     * @notice updates the collectionIdToLeafIdRegistryOfLastEpoch resgistries.
     * @dev It is called by the blockManager when a block is confirmed. It is only called if there was a change in the
     * status of collections in the network
     */
    function updateDelayedRegistry() external;

    /**
     * @param id the id of the collection
     * @return status of the collection
     */
    function getCollectionStatus(uint16 id) external view returns (bool);

    /**
     * @return total number of active collections
     */
    function getNumActiveCollections() external view returns (uint16);

    /**
     * @return ids of active collections
     */
    function getActiveCollections() external view returns (uint16[] memory);

    /**
     * @param id the id of the collection
     * @return power of the collection
     */
    function getCollectionPower(uint16 id) external view returns (int8);

    /**
     * @return total number of collections
     */
    function getNumCollections() external view returns (uint16);

    /**
     * @param i the leafId of the collection
     * @return tolerance of the collection
     */
    function getCollectionTolerance(uint16 i) external view returns (uint32);

    /**
     * @param id the id of the collection
     * @return the leafId of the collection from collectionIdToLeafIdRegistry
     */
    function getLeafIdOfCollection(uint16 id) external view returns (uint16);

    /**
     * @param leafId, the leafId of the collection
     * @return the id of the collection
     */
    function getCollectionIdFromLeafId(uint16 leafId) external view returns (uint16);

    /**
     * @param id the id of the collection
     * @return the leafId of the collection from collectionIdToLeafIdRegistryOfLastEpoch
     */
    function getLeafIdOfCollectionForLastEpoch(uint16 id) external view returns (uint16);

    /**
     * @param _name the name of the collection in bytes32
     * @return collection ID
     */
    function getCollectionID(bytes32 _name) external view returns (uint16);

    /**
     * @notice returns the result of the collection based on the name sent by the client
     * @param _name the name of the collection in bytes32
     * @return result of the collection
     * @return power of the resultant collection
     */
    function getResult(bytes32 _name) external view returns (uint256, int8);

    /**
     * @notice returns the result of the collection based on the id sent by the client
     * @param _id the id of the collection
     * @return result of the collection
     * @return power of the resultant collection
     */
    function getResultFromID(uint16 _id) external view returns (uint256, int8);

    /**
     * @return epoch in which the registry needs to be updated
     */
    function getUpdateRegistryEpoch() external view returns (uint32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./storage/Constants.sol";

/** @title StateManager
 * @notice StateManager manages the state of the network
 */

contract StateManager is Constants {
    /**
     * @notice a check to ensure the epoch value sent in the function is of the currect epoch
     */
    modifier checkEpoch(uint32 epoch) {
        // slither-disable-next-line incorrect-equality
        require(epoch == _getEpoch(), "incorrect epoch");
        _;
    }

    /**
     * @notice a check to ensure the function was called in the state specified
     */
    modifier checkState(State state, uint8 buffer) {
        // slither-disable-next-line incorrect-equality
        require(state == _getState(buffer), "incorrect state");
        _;
    }

    /**
     * @notice a check to ensure the function was not called in the state specified
     */
    modifier notState(State state, uint8 buffer) {
        // slither-disable-next-line incorrect-equality
        require(state != _getState(buffer), "incorrect state");
        _;
    }

    /** @notice a check to ensure the epoch value sent in the function is of the currect epoch
     * and was called in the state specified
     */
    modifier checkEpochAndState(
        State state,
        uint32 epoch,
        uint8 buffer
    ) {
        // slither-disable-next-line incorrect-equality
        require(epoch == _getEpoch(), "incorrect epoch");
        // slither-disable-next-line incorrect-equality
        require(state == _getState(buffer), "incorrect state");
        _;
    }

    function _getEpoch() internal view returns (uint32) {
        return (uint32(block.timestamp) / (EPOCH_LENGTH));
    }

    function _getState(uint8 buffer) internal view returns (State) {
        uint8 lowerLimit = buffer;

        uint16 upperLimit = EPOCH_LENGTH / NUM_STATES - buffer;
        // slither-disable-next-line timestamp,weak-prng
        if (block.timestamp % (EPOCH_LENGTH / NUM_STATES) > upperLimit || block.timestamp % (EPOCH_LENGTH / NUM_STATES) < lowerLimit) {
            return State.Buffer;
        }
        // slither-disable-next-line timestamp,weak-prng
        uint8 state = uint8(((block.timestamp) / (EPOCH_LENGTH / NUM_STATES)) % (NUM_STATES));
        return State(state);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/IBlockManagerParams.sol";
import "../ACL.sol";
import "../../storage/Constants.sol";

abstract contract BlockManagerParams is ACL, IBlockManagerParams, Constants {
    /// @notice maximum number of best proposed blocks to be considered for dispute
    uint8 public maxAltBlocks = 5;
    uint8 public buffer = 5;
    /// @notice reward given to staker whose block is confirmed
    uint256 public blockReward = 100 * (10**18);
    /// @notice minimum amount of stake required to participate
    uint256 public minStake = 20000 * (10**18);

    /// @inheritdoc IBlockManagerParams
    function setMaxAltBlocks(uint8 _maxAltBlocks) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        maxAltBlocks = _maxAltBlocks;
    }

    function setBufferLength(uint8 _bufferLength) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        buffer = _bufferLength;
    }

    /// @inheritdoc IBlockManagerParams
    function setBlockReward(uint256 _blockReward) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        blockReward = _blockReward;
    }

    /// @inheritdoc IBlockManagerParams
    function setMinStake(uint256 _minStake) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        minStake = _minStake;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Structs {
    struct Commitment {
        uint32 epoch;
        bytes32 commitmentHash;
    }
    struct Staker {
        // Slot 1
        bool acceptDelegation;
        bool isSlashed;
        uint8 commission;
        uint32 id;
        uint32 age;
        address _address;
        // Slot 2
        address tokenAddress;
        uint32 epochFirstStakedOrLastPenalized;
        uint32 epochCommissionLastUpdated;
        // Slot 3
        uint256 stake;
        uint256 stakerReward;
    }

    struct Lock {
        uint256 amount; //amount in sRZR/RZR
        uint256 unlockAfter; // Can be made uint32 later if packing is possible
    }

    struct BountyLock {
        uint32 redeemAfter;
        address bountyHunter;
        uint256 amount; //amount in RZR
    }

    struct Block {
        bool valid;
        uint32 proposerId;
        uint16[] ids;
        uint256 iteration;
        uint256 biggestStake;
        uint256[] medians;
    }

    struct Dispute {
        uint16 leafId;
        uint256 lastVisitedValue;
        uint256 accWeight;
        uint256 median;
    }

    struct Job {
        uint16 id;
        uint8 selectorType; // 0-1
        uint8 weight; // 1-100
        int8 power;
        string name;
        string selector;
        string url;
    }

    struct Collection {
        bool active;
        uint16 id;
        int8 power;
        uint32 tolerance;
        uint32 aggregationMethod;
        uint16[] jobIDs;
        string name;
    }

    struct AssignedAsset {
        uint16 leafId;
        uint256 value;
    }

    struct MerkleTree {
        Structs.AssignedAsset[] values;
        bytes32[][] proofs;
        bytes32 root;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Constants {
    enum State {
        Commit,
        Reveal,
        Propose,
        Dispute,
        Confirm,
        Buffer
    }

    enum StakeChanged {
        BlockReward,
        InactivityPenalty,
        Slashed
    }

    enum StakerRewardChanged {
        StakerRewardAdded,
        StakerRewardClaimed
    }

    enum AgeChanged {
        InactivityPenalty,
        VotingRewardOrPenalty
    }

    uint8 public constant NUM_STATES = 5;

    uint16 public constant EPOCH_LENGTH = 1200;

    // slither-disable-next-line too-many-digits
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint32 public constant BASE_DENOMINATOR = 10_000_000;
    // keccak256("BLOCK_CONFIRMER_ROLE")
    bytes32 public constant BLOCK_CONFIRMER_ROLE = 0x18797bc7973e1dadee1895be2f1003818e30eae3b0e7a01eb9b2e66f3ea2771f;

    // keccak256("STAKE_MODIFIER_ROLE")
    bytes32 public constant STAKE_MODIFIER_ROLE = 0xdbaaaff2c3744aa215ebd99971829e1c1b728703a0bf252f96685d29011fc804;

    // keccak256("REWARD_MODIFIER_ROLE")
    bytes32 public constant REWARD_MODIFIER_ROLE = 0xcabcaf259dd9a27f23bd8a92bacd65983c2ebf027c853f89f941715905271a8d;

    // keccak256("COLLECTION_MODIFIER_ROLE")
    bytes32 public constant COLLECTION_MODIFIER_ROLE = 0xa3a75e7cd2b78fcc3ae2046ab93bfa4ac0b87ed7ea56646a312cbcb73eabd294;

    // keccak256("VOTE_MODIFIER_ROLE")
    bytes32 public constant VOTE_MODIFIER_ROLE = 0x912208965b92edeb3eb82a612c87b38b5e844f7539cb396f0d08ec012e511b07;

    // keccak256("DELEGATOR_MODIFIER_ROLE")
    bytes32 public constant DELEGATOR_MODIFIER_ROLE = 0x6b7da7a33355c6e035439beb2ac6a052f1558db73f08690b1c9ef5a4e8389597;

    // keccak256("REGISTRY_MODIFIER_ROLE")
    bytes32 public constant REGISTRY_MODIFIER_ROLE = 0xca51085219bef34771da292cb24ee4fcf0ae6bdba1a62c17d1fb7d58be802883;

    // keccak256("SECRETS_MODIFIER_ROLE")
    bytes32 public constant SECRETS_MODIFIER_ROLE = 0x46aaf8a125792dfff6db03d74f94fe1acaf55c8cab22f65297c15809c364465c;

    // keccak256("PAUSE_ROLE")
    bytes32 public constant PAUSE_ROLE = 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d;

    // keccak256("GOVERNANCE_ROLE")
    bytes32 public constant GOVERNANCE_ROLE = 0x71840dc4906352362b0cdaf79870196c8e42acafade72d5d5a6d59291253ceb1;

    // keccak256("STOKEN_ROLE")
    bytes32 public constant STOKEN_ROLE = 0xce3e6c780f179d7a08d28e380f7be9c36d990f56515174f8adb6287c543e30dc;

    // keccak256("SALT_MODIFIER_ROLE")
    bytes32 public constant SALT_MODIFIER_ROLE = 0xf31dda80d37c96a1a0852ace387dda52a75487d7d4eb74895e749ede3e0987b4;

    // keccak256("DEPTH_MODIFIER_ROLE)")
    bytes32 public constant DEPTH_MODIFIER_ROLE = 0x91f5d9ea80c4d04985e669bc72870410b28b57afdf61c0d50d377766d86a3748;

    // keccak256("ESCAPE_HATCH_ROLE")
    bytes32 public constant ESCAPE_HATCH_ROLE = 0x518d8c39717318f051dfb836a4ebe5b3c34aa2cb7fce26c21a89745422ba8043;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract ACL is AccessControl {
    /**
     * @dev the deployer of the network is given to the default admin role which gives other roles to contracts
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBlockManagerParams {
    /**
     * @notice changing the maximum number of best proposed blocks to be considered for dispute
     * @dev can be called only by the the address that has the governance role
     * @param _maxAltBlocks updated value to be set for maxAltBlocks
     */
    function setMaxAltBlocks(uint8 _maxAltBlocks) external;

    /**
     * @notice changing the block reward given out to stakers
     * @dev can be called only by the the address that has the governance role
     * @param _blockReward updated value to be set for blockReward
     */
    function setBlockReward(uint256 _blockReward) external;

    /**
     * @notice changing minimum amount that to be staked for participation
     * @dev can be called only by the the address that has the governance role
     * @param _minStake updated value to be set for minStake
     */
    function setMinStake(uint256 _minStake) external;

    /**
     * @notice changing buffer length between the states
     * @dev can be called only by the the address that has the governance role
     * @param _bufferLength updated value to be set for buffer
     */
    function setBufferLength(uint8 _bufferLength) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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