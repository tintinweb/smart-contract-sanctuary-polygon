pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./SafeMath.sol";
import "./SafeMathUInt128.sol";
import "./SafeCast.sol";
import "./Utils.sol";

import "./Bytes.sol";
import "./Operations.sol";
import "./ZkSyncBase.sol";

/// @title zkSync main contract part 2: commit block, prove block, execute block
/// @author Matter Labs
/// @author ZkLink Labs
contract ZkSyncBlock is ZkSyncBase {
    using SafeMath for uint256;
    using SafeMathUInt128 for uint128;

    bytes32 private constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @notice Data needed to process onchain operation from block public data.
    /// @notice Onchain operations is operations that need some processing on L1: Deposits, Withdrawals, ChangePubKey.
    /// @param ethWitness Some external data that can be needed for operation processing
    /// @param publicDataOffset Byte offset in public data for onchain operation
    struct OnchainOperationData {
        bytes ethWitness;
        uint32 publicDataOffset;
    }

    /// @notice Data needed to commit new block
    struct CommitBlockInfo {
        bytes32 newStateHash;
        bytes publicData;
        uint256 timestamp;
        OnchainOperationData[] onchainOperations;
        uint32 blockNumber;
        uint32 feeAccount;
        uint8 chainId; // current chain id
        uint256[] crtCommitments; // current chain roll up commitments
    }

    /// @notice Data needed to execute committed and verified block
    /// @param commitmentsInSlot verified commitments in one slot
    /// @param commitmentIdx index such that commitmentsInSlot[commitmentIdx] is current block commitment
    struct ExecuteBlockInfo {
        StoredBlockInfo storedBlock;
        bytes[] pendingOnchainOpsPubdata;
    }

    /// @notice Recursive proof input data (individual commitments are constructed onchain)
    struct ProofInput {
        uint256[] recursiveInput;
        uint256[] proof;
        uint256[] commitments;
        uint8[] vkIndexes;
        uint256[16] subproofsLimbs;
    }

    /// @notice Commit block
    /// @notice 1. Checks onchain operations, timestamp.
    /// @notice 2. Store block commitments
    function commitBlocks(StoredBlockInfo memory _lastCommittedBlockData, CommitBlockInfo[] memory _newBlocksData)
    external
    nonReentrant
    {
        requireActive();
        governance.requireActiveValidator(msg.sender);
        // Check that we commit blocks after last committed block
        require(storedBlockHashes[totalBlocksCommitted] == hashStoredBlockInfo(_lastCommittedBlockData), "i"); // incorrect previous block data

        for (uint32 i = 0; i < _newBlocksData.length; ++i) {
            _lastCommittedBlockData = commitOneBlock(_lastCommittedBlockData, _newBlocksData[i]);

            totalCommittedPriorityRequests += _lastCommittedBlockData.priorityOperations;
            storedBlockHashes[_lastCommittedBlockData.blockNumber] = hashStoredBlockInfo(_lastCommittedBlockData);

            emit BlockCommit(_lastCommittedBlockData.blockNumber);
        }

        totalBlocksCommitted += uint32(_newBlocksData.length);

        require(totalCommittedPriorityRequests <= totalOpenPriorityRequests, "j");
    }

    /// @notice Blocks commitment verification.
    /// @notice Only verifies block commitments without any other processing
    function proveBlocks(StoredBlockInfo[] memory _committedBlocks, ProofInput memory _proof) external nonReentrant {
        uint32 currentTotalBlocksProven = totalBlocksProven;
        for (uint256 i = 0; i < _committedBlocks.length; ++i) {
            require(hashStoredBlockInfo(_committedBlocks[i]) == storedBlockHashes[currentTotalBlocksProven + 1], "o1");
            ++currentTotalBlocksProven;

            require(_proof.commitments[i] & INPUT_MASK == uint256(_committedBlocks[i].commitment) & INPUT_MASK, "o"); // incorrect block commitment in proof
        }

        bool success =
        verifier.verifyAggregatedBlockProof(
            _proof.recursiveInput,
            _proof.proof,
            _proof.vkIndexes,
            _proof.commitments,
            _proof.subproofsLimbs
        );
        require(success, "p"); // Aggregated proof verification fail

        require(currentTotalBlocksProven <= totalBlocksCommitted, "q");
        totalBlocksProven = currentTotalBlocksProven;
    }

    /// @notice Execute blocks, completing priority operations and processing withdrawals.
    /// @notice 1. Processes all pending operations (Send Exits, Complete priority requests)
    /// @notice 2. Finalizes block on Ethereum
    function executeBlocks(ExecuteBlockInfo[] memory _blocksData) external nonReentrant {
        requireActive();
        governance.requireActiveValidator(msg.sender);

        uint64 priorityRequestsExecuted = 0;
        uint32 nBlocks = uint32(_blocksData.length);
        for (uint32 i = 0; i < nBlocks; ++i) {
            executeOneBlock(_blocksData[i], i);
            priorityRequestsExecuted += _blocksData[i].storedBlock.priorityOperations;
            emit BlockVerification(_blocksData[i].storedBlock.blockNumber);
        }

        firstPriorityRequestId += priorityRequestsExecuted;
        totalCommittedPriorityRequests -= priorityRequestsExecuted;
        totalOpenPriorityRequests -= priorityRequestsExecuted;

        totalBlocksExecuted += nBlocks;
        require(totalBlocksExecuted <= totalBlocksProven, "n"); // Can't execute blocks more then committed and proven currently.
    }

    /// @notice Reverts unverified blocks
    function revertBlocks(StoredBlockInfo[] memory _blocksToRevert) external nonReentrant {
        governance.requireActiveValidator(msg.sender);

        uint32 blocksCommitted = totalBlocksCommitted;
        uint32 blocksToRevert = Utils.minU32(uint32(_blocksToRevert.length), blocksCommitted - totalBlocksExecuted);
        uint64 revertedPriorityRequests = 0;

        for (uint32 i = 0; i < blocksToRevert; ++i) {
            StoredBlockInfo memory storedBlockInfo = _blocksToRevert[i];
            require(storedBlockHashes[blocksCommitted] == hashStoredBlockInfo(storedBlockInfo), "r"); // incorrect stored block info

            delete storedBlockHashes[blocksCommitted];

            --blocksCommitted;
            revertedPriorityRequests += storedBlockInfo.priorityOperations;
        }

        totalBlocksCommitted = blocksCommitted;
        totalCommittedPriorityRequests -= revertedPriorityRequests;
        if (totalBlocksCommitted < totalBlocksProven) {
            totalBlocksProven = totalBlocksCommitted;
        }

        emit BlocksRevert(totalBlocksExecuted, blocksCommitted);
    }

    /// @notice Checks if Exodus mode must be entered. If true - enters exodus mode and emits ExodusMode event.
    /// @dev Exodus mode must be entered in case of current ethereum block number is higher than the oldest
    /// @dev of existed priority requests expiration block number.
    /// @return bool flag that is true if the Exodus mode must be entered.
    function activateExodusMode() public returns (bool) {
        bool trigger =
        block.number >= priorityRequests[firstPriorityRequestId].expirationBlock &&
        priorityRequests[firstPriorityRequestId].expirationBlock != 0;
        if (trigger) {
            if (!exodusMode) {
                exodusMode = true;
                emit ExodusMode();
            }
            return true;
        } else {
            return false;
        }
    }

    /// @notice Withdraws token from ZkSync to root chain in case of exodus mode. User must provide proof that he owns funds
    /// @param _storedBlockInfo Last verified block
    /// @param _owner Owner of the account
    /// @param _accountId Id of the account in the tree
    /// @param _proof Proof
    /// @param _tokenId Verified token id
    /// @param _amount Amount for owner (must be total amount, not part of it)
    function performExodus(
        StoredBlockInfo memory _storedBlockInfo,
        address _owner,
        uint32 _accountId,
        uint16 _tokenId,
        uint128 _amount,
        uint256[] memory _proof
    ) external nonReentrant {
        bytes22 packedBalanceKey = packAddressAndTokenId(_owner, _tokenId);
        require(exodusMode, "s"); // must be in exodus mode
        require(!performedExodus[_accountId][_tokenId], "t"); // already exited
        require(storedBlockHashes[totalBlocksExecuted] == hashStoredBlockInfo(_storedBlockInfo), "u"); // incorrect sotred block info

        bool proofCorrect =
        verifier.verifyExitProof(_storedBlockInfo.stateHash, _accountId, _owner, _tokenId, _amount, _proof);
        require(proofCorrect, "x");

        increaseBalanceToWithdraw(packedBalanceKey, _amount);
        performedExodus[_accountId][_tokenId] = true;
    }

    /// @notice Set data for changing pubkey hash using onchain authorization.
    ///         Transaction author (msg.sender) should be L2 account address
    /// @notice New pubkey hash can be reset, to do that user should send two transactions:
    ///         1) First `setAuthPubkeyHash` transaction for already used `_nonce` will set timer.
    ///         2) After `AUTH_FACT_RESET_TIMELOCK` time is passed second `setAuthPubkeyHash` transaction will reset pubkey hash for `_nonce`.
    /// @param _pubkey_hash New pubkey hash
    /// @param _nonce Nonce of the change pubkey L2 transaction
    function setAuthPubkeyHash(bytes calldata _pubkey_hash, uint32 _nonce) external {
        require(_pubkey_hash.length == PUBKEY_HASH_BYTES, "y"); // PubKeyHash should be 20 bytes.
        if (authFacts[msg.sender][_nonce] == bytes32(0)) {
            authFacts[msg.sender][_nonce] = keccak256(_pubkey_hash);
        } else {
            uint256 currentResetTimer = authFactsResetTimer[msg.sender][_nonce];
            if (currentResetTimer == 0) {
                authFactsResetTimer[msg.sender][_nonce] = block.timestamp;
            } else {
                require(block.timestamp.sub(currentResetTimer) >= AUTH_FACT_RESET_TIMELOCK, "z");
                authFactsResetTimer[msg.sender][_nonce] = 0;
                authFacts[msg.sender][_nonce] = keccak256(_pubkey_hash);
            }
        }
    }

    /// @notice Accepter accept a fast withdraw, accepter will get a fee of (amount - amountOutMin)
    /// @param accepter Accepter
    /// @param receiver User receive token from accepter
    /// @param tokenId Token id, only non lp token supported
    /// @param amount Fast withdraw amount
    /// @param withdrawFee Fast withdraw fee taken by accepter
    /// @param nonce Used to produce unique accept info
    function accept(address accepter, address receiver, uint16 tokenId, uint128 amount, uint16 withdrawFee, uint32 nonce) external payable {
        uint128 fee = amount * withdrawFee / MAX_WITHDRAW_FEE;
        uint128 amountReceive = amount - fee;
        require(amountReceive > 0 && amountReceive <= amount, 'ZkSyncBlock: amountReceive');

        bytes32 hash = keccak256(abi.encodePacked(receiver, tokenId, amount, withdrawFee, nonce));
        require(accepts[hash] == address(0), 'ZkSyncBlock: accepted');

        accepts[hash] = accepter;

        // send token to receiver from msg.sender
        if (tokenId == 0) {
            // accepter should transfer at least amountReceive platform token to this contract
            require(msg.value >= amountReceive, 'ZkSyncBlock: msg value');
            payable(receiver).transfer(amountReceive);
            // if there are any left return back to accepter
            if (msg.value > amountReceive) {
                payable(msg.sender).transfer(msg.value - amountReceive);
            }
        } else {
            address tokenAddress = governance.tokenAddresses(tokenId);
            governance.validateTokenAddress(tokenAddress);
            // transfer erc20 token from accepter to receiver directly
            Utils.transferFromERC20(IERC20(tokenAddress), msg.sender, receiver, amountReceive);
        }
        emit Accept(accepter, receiver, tokenId, amount, fee, nonce);
    }

    /// @dev Process one block commit using previous block StoredBlockInfo,
    /// @dev returns new block StoredBlockInfo
    /// @dev NOTE: Does not change storage (except events, so we can't mark it view)
    function commitOneBlock(StoredBlockInfo memory _previousBlock, CommitBlockInfo memory _newBlock)
    internal
    view
    returns (StoredBlockInfo memory storedNewBlock)
    {
        require(_newBlock.blockNumber == _previousBlock.blockNumber + 1, "f"); // only commit next block

        // Check timestamp of the new block
        {
            require(_newBlock.timestamp >= _previousBlock.timestamp, "g"); // Block should be after previous block
            bool timestampNotTooSmall = block.timestamp.sub(COMMIT_TIMESTAMP_NOT_OLDER) <= _newBlock.timestamp;
            bool timestampNotTooBig = _newBlock.timestamp <= block.timestamp.add(COMMIT_TIMESTAMP_APPROXIMATION_DELTA);
            require(timestampNotTooSmall && timestampNotTooBig, "h"); // New block timestamp is not valid
        }

        // Check onchain operations
        (bytes32 pendingOnchainOpsHash, uint64 priorityReqCommitted, bytes memory onchainOpsOffsetCommitment) =
        collectOnchainOps(_newBlock);

        // Create block commitment for verification proof
        bytes32 commitment = createBlockCommitment(_previousBlock, _newBlock, onchainOpsOffsetCommitment);

        return
        StoredBlockInfo(
            _newBlock.blockNumber,
            priorityReqCommitted,
            pendingOnchainOpsHash,
            _newBlock.timestamp,
            _newBlock.newStateHash,
            commitment
        );
    }

    /// @dev Increment _recipients balance to withdraw.
    function storePendingBalance(
        uint16 _tokenId,
        address _recipient,
        uint128 _amount
    ) internal {
        bytes22 packedBalanceKey = packAddressAndTokenId(_recipient, _tokenId);
        increaseBalanceToWithdraw(packedBalanceKey, _amount);
    }

    /// @dev Executes one block
    /// @dev 1. Processes all pending operations (Send Exits, Complete priority requests)
    /// @dev 2. Finalizes block on Ethereum
    /// @dev _executedBlockIdx is index in the array of the blocks that we want to execute together
    function executeOneBlock(ExecuteBlockInfo memory _blockExecuteData, uint32 _executedBlockIdx) internal {
        // Ensure block was committed
        require(
            hashStoredBlockInfo(_blockExecuteData.storedBlock) ==
            storedBlockHashes[_blockExecuteData.storedBlock.blockNumber],
            "exe10" // executing block should be committed
        );
        require(_blockExecuteData.storedBlock.blockNumber == totalBlocksExecuted + _executedBlockIdx + 1, "k"); // Execute blocks in order

        bytes32 pendingOnchainOpsHash = EMPTY_STRING_KECCAK;
        for (uint32 i = 0; i < _blockExecuteData.pendingOnchainOpsPubdata.length; ++i) {
            bytes memory pubData = _blockExecuteData.pendingOnchainOpsPubdata[i];

            Operations.OpType opType = Operations.OpType(uint8(pubData[0]));

            if (opType == Operations.OpType.PartialExit) {
                Operations.PartialExit memory op = Operations.readPartialExitPubdata(pubData);
                storePendingBalance(op.tokenId, op.owner, op.amount);
            } else if (opType == Operations.OpType.ForcedExit) {
                Operations.ForcedExit memory op = Operations.readForcedExitPubdata(pubData);
                storePendingBalance(op.tokenId, op.target, op.amount);
            } else if (opType == Operations.OpType.FullExit) {
                Operations.FullExit memory op = Operations.readFullExitPubdata(pubData);
                storePendingBalance(op.tokenId, op.owner, op.amount);
            } else if (opType == Operations.OpType.QuickSwap) {
                Operations.QuickSwap memory op = Operations.readQuickSwapPubdata(pubData);
                // only to chain need to process QuickSwap data in executeBlocks
                if (op.toChainId == CHAIN_ID) {
                    accepterWithdraw(op);
                }
            } else if (opType == Operations.OpType.Mapping) {
                Operations.Mapping memory op = Operations.readMappingPubdata(pubData);
                address tokenAddress = governance.tokenAddresses(op.tokenId);
                uint128 burnAmount = op.amount.sub(op.fee);
                if (op.fromChainId == CHAIN_ID) {
                    // burn token from ZkSync
                    IMappingToken(tokenAddress).burn(burnAmount);
                } else {
                    // mint to controller of token mapping
                    IMappingToken(tokenAddress).mint(op.to, burnAmount);
                }
            } else {
                revert("l"); // unsupported op in block execution
            }

            pendingOnchainOpsHash = Utils.concatHash(pendingOnchainOpsHash, pubData);
        }
        require(pendingOnchainOpsHash == _blockExecuteData.storedBlock.pendingOnchainOperationsHash, "m"); // incorrect onchain ops executed
    }

    /// @dev Gets operations packed in bytes array. Unpacks it and stores onchain operations.
    /// @dev Priority operations must be committed in the same order as they are in the priority queue.
    /// @dev NOTE: does not change storage! (only emits events)
    /// @dev processableOperationsHash - hash of the all operations that needs to be executed  (Deposit, Exits, ChangPubKey)
    /// @dev priorityOperationsProcessed - number of priority operations processed in this block (Deposits, FullExits)
    /// @dev offsetsCommitment - array where 1 is stored in chunk where onchainOperation begins and other are 0 (used in commitments)
    function collectOnchainOps(CommitBlockInfo memory _newBlockData)
    internal
    view
    returns (
        bytes32 processableOperationsHash,
        uint64 priorityOperationsProcessed,
        bytes memory offsetsCommitment
    )
    {
        bytes memory pubData = _newBlockData.publicData;

        uint64 uncommittedPriorityRequestsOffset = firstPriorityRequestId + totalCommittedPriorityRequests;
        priorityOperationsProcessed = 0;
        processableOperationsHash = EMPTY_STRING_KECCAK;

        require(pubData.length % CHUNK_BYTES == 0, "A"); // pubdata length must be a multiple of CHUNK_BYTES
        offsetsCommitment = new bytes(pubData.length / CHUNK_BYTES);
        for (uint256 i = 0; i < _newBlockData.onchainOperations.length; ++i) {
            OnchainOperationData memory onchainOpData = _newBlockData.onchainOperations[i];

            uint256 pubdataOffset = onchainOpData.publicDataOffset;
            require(pubdataOffset < pubData.length, "A1");
            require(pubdataOffset % CHUNK_BYTES == 0, "B"); // offsets should be on chunks boundaries
            uint256 chunkId = pubdataOffset / CHUNK_BYTES;
            require(offsetsCommitment[chunkId] == 0x00, "C"); // offset commitment should be empty
            offsetsCommitment[chunkId] = bytes1(0x01);

            Operations.OpType opType = Operations.OpType(uint8(pubData[pubdataOffset]));

            if (opType == Operations.OpType.Deposit) {
                bytes memory opPubData = Bytes.slice(pubData, pubdataOffset, DEPOSIT_BYTES);

                Operations.Deposit memory depositData = Operations.readDepositPubdata(opPubData);

                checkPriorityOperation(depositData, uncommittedPriorityRequestsOffset + priorityOperationsProcessed);
                priorityOperationsProcessed++;
            } else if (opType == Operations.OpType.ChangePubKey) {
                bytes memory opPubData = Bytes.slice(pubData, pubdataOffset, CHANGE_PUBKEY_BYTES);

                Operations.ChangePubKey memory op = Operations.readChangePubKeyPubdata(opPubData);

                if (onchainOpData.ethWitness.length != 0) {
                    bool valid = verifyChangePubkey(onchainOpData.ethWitness, op);
                    require(valid, "D"); // failed to verify change pubkey hash signature
                } else {
                    bool valid = authFacts[op.owner][op.nonce] == keccak256(abi.encodePacked(op.pubKeyHash));
                    require(valid, "E"); // new pub key hash is not authenticated properly
                }
            } else if (opType == Operations.OpType.QuickSwap) {
                bytes memory opPubData = Bytes.slice(pubData, pubdataOffset, QUICK_SWAP_BYTES);
                Operations.QuickSwap memory quickSwapData = Operations.readQuickSwapPubdata(opPubData);
                require(quickSwapData.fromChainId == CHAIN_ID || quickSwapData.toChainId == CHAIN_ID, 'ZkSyncBlock: chain id');
                // fromChainId and toChainId may be the same
                if (quickSwapData.fromChainId == CHAIN_ID) {
                    checkPriorityOperation(quickSwapData, uncommittedPriorityRequestsOffset + priorityOperationsProcessed);
                    priorityOperationsProcessed++;
                }
                if (quickSwapData.toChainId == CHAIN_ID) {
                    processableOperationsHash = Utils.concatHash(processableOperationsHash, opPubData);
                }
            } else if (opType == Operations.OpType.Mapping) {
                bytes memory opPubData = Bytes.slice(pubData, pubdataOffset, MAPPING_BYTES);
                Operations.Mapping memory mappingData = Operations.readMappingPubdata(opPubData);
                // fromChainId and toChainId will not be the same
                require(mappingData.fromChainId != mappingData.toChainId &&
                    (mappingData.fromChainId == CHAIN_ID || mappingData.toChainId == CHAIN_ID), 'ZkSyncBlock: chain id');
                if (mappingData.fromChainId == CHAIN_ID) {
                    checkPriorityOperation(mappingData, uncommittedPriorityRequestsOffset + priorityOperationsProcessed);
                    priorityOperationsProcessed++;
                }
                // fromChain and toChain both will handle TokenMapping in exec
                processableOperationsHash = Utils.concatHash(processableOperationsHash, opPubData);
            } else {
                bytes memory opPubData;

                if (opType == Operations.OpType.PartialExit) {
                    opPubData = Bytes.slice(pubData, pubdataOffset, PARTIAL_EXIT_BYTES);
                } else if (opType == Operations.OpType.ForcedExit) {
                    opPubData = Bytes.slice(pubData, pubdataOffset, FORCED_EXIT_BYTES);
                } else if (opType == Operations.OpType.FullExit) {
                    opPubData = Bytes.slice(pubData, pubdataOffset, FULL_EXIT_BYTES);

                    Operations.FullExit memory fullExitData = Operations.readFullExitPubdata(opPubData);

                    checkPriorityOperation(
                        fullExitData,
                        uncommittedPriorityRequestsOffset + priorityOperationsProcessed
                    );
                    priorityOperationsProcessed++;
                } else {
                    revert("F"); // unsupported op
                }

                processableOperationsHash = Utils.concatHash(processableOperationsHash, opPubData);
            }
        }
    }

    /// @notice Checks that change operation is correct
    function verifyChangePubkey(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk)
    internal
    pure
    returns (bool)
    {
        Operations.ChangePubkeyType changePkType = Operations.ChangePubkeyType(uint8(_ethWitness[0]));
        if (changePkType == Operations.ChangePubkeyType.ECRECOVER) {
            return verifyChangePubkeyECRECOVER(_ethWitness, _changePk);
        } else if (changePkType == Operations.ChangePubkeyType.CREATE2) {
            return verifyChangePubkeyCREATE2(_ethWitness, _changePk);
        } else if (changePkType == Operations.ChangePubkeyType.OldECRECOVER) {
            return verifyChangePubkeyOldECRECOVER(_ethWitness, _changePk);
        } else {
            revert("G"); // Incorrect ChangePubKey type
        }
    }

    /// @notice Checks that signature is valid for pubkey change message
    /// @param _ethWitness Signature (65 bytes) + 32 bytes of the arbitrary signed data
    /// @param _changePk Parsed change pubkey operation
    function verifyChangePubkeyECRECOVER(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk)
    internal
    pure
    returns (bool)
    {
        (, bytes memory signature) = Bytes.read(_ethWitness, 1, 65); // offset is 1 because we skip type of ChangePubkey
        //        (, bytes32 additionalData) = Bytes.readBytes32(_ethWitness, offset);
        bytes32 messageHash =
        keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n60",
                _changePk.pubKeyHash,
                _changePk.nonce,
                _changePk.accountId,
                bytes32(0)
            )
        );
        address recoveredAddress = Utils.recoverAddressFromEthSignature(signature, messageHash);
        return recoveredAddress == _changePk.owner && recoveredAddress != address(0);
    }

    /// @notice Checks that signature is valid for pubkey change message, old version differs by form of the signed message.
    /// @param _ethWitness Signature (65 bytes)
    /// @param _changePk Parsed change pubkey operation
    function verifyChangePubkeyOldECRECOVER(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk)
    internal
    pure
    returns (bool)
    {
        (, bytes memory signature) = Bytes.read(_ethWitness, 1, 65); // offset is 1 because we skip type of ChangePubkey
        bytes32 messageHash =
        keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n152",
                "Register zkLink pubkey:\n\n",
                Bytes.bytesToHexASCIIBytes(abi.encodePacked(_changePk.pubKeyHash)),
                "\n",
                "nonce: 0x",
                Bytes.bytesToHexASCIIBytes(Bytes.toBytesFromUInt32(_changePk.nonce)),
                "\n",
                "account id: 0x",
                Bytes.bytesToHexASCIIBytes(Bytes.toBytesFromUInt32(_changePk.accountId)),
                "\n\n",
                "Only sign this message for a trusted client!"
            )
        );
        address recoveredAddress = Utils.recoverAddressFromEthSignature(signature, messageHash);
        return recoveredAddress == _changePk.owner && recoveredAddress != address(0);
    }

    /// @notice Checks that signature is valid for pubkey change message
    /// @param _ethWitness Create2 deployer address, saltArg, codeHash
    /// @param _changePk Parsed change pubkey operation
    function verifyChangePubkeyCREATE2(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk)
    internal
    pure
    returns (bool)
    {
        address creatorAddress;
        bytes32 saltArg; // salt arg is additional bytes that are encoded in the CREATE2 salt
        bytes32 codeHash;
        uint256 offset = 1; // offset is 1 because we skip type of ChangePubkey
        (offset, creatorAddress) = Bytes.readAddress(_ethWitness, offset);
        (offset, saltArg) = Bytes.readBytes32(_ethWitness, offset);
        (offset, codeHash) = Bytes.readBytes32(_ethWitness, offset);
        // salt from CREATE2 specification
        bytes32 salt = keccak256(abi.encodePacked(saltArg, _changePk.pubKeyHash));
        // Address computation according to CREATE2 definition: https://eips.ethereum.org/EIPS/eip-1014
        address recoveredAddress =
        address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), creatorAddress, salt, codeHash)))));
        // This type of change pubkey can be done only once
        return recoveredAddress == _changePk.owner && _changePk.nonce == 0;
    }

    /// @dev Creates block commitment from its data
    /// @dev _offsetCommitment - hash of the array where 1 is stored in chunk where onchainOperation begins and 0 for other chunks
    function createBlockCommitment(
        StoredBlockInfo memory _previousBlock,
        CommitBlockInfo memory _newBlockData,
        bytes memory _offsetCommitment
    ) internal view returns (bytes32 commitment) {
        bytes32 hash = sha256(abi.encodePacked(uint256(_newBlockData.blockNumber), uint256(_newBlockData.feeAccount)));
        hash = sha256(abi.encodePacked(hash, _previousBlock.stateHash));
        hash = sha256(abi.encodePacked(hash, _newBlockData.newStateHash));
        hash = sha256(abi.encodePacked(hash, uint256(_newBlockData.timestamp)));

        bytes memory pubdata = abi.encodePacked(_newBlockData.publicData, _offsetCommitment);

        /// The code below is equivalent to `commitment = sha256(abi.encodePacked(hash, _publicData))`

        /// We use inline assembly instead of this concise and readable code in order to avoid copying of `_publicData` (which saves ~90 gas per transfer operation).

        /// Specifically, we perform the following trick:
        /// First, replace the first 32 bytes of `_publicData` (where normally its length is stored) with the value of `hash`.
        /// Then, we call `sha256` precompile passing the `_publicData` pointer and the length of the concatenated byte buffer.
        /// Finally, we put the `_publicData.length` back to its original location (to the first word of `_publicData`).
        assembly {
            let hashResult := mload(0x40)
            let pubDataLen := mload(pubdata)
            mstore(pubdata, hash)
        // staticcall to the sha256 precompile at address 0x2
            let success := staticcall(gas(), 0x2, pubdata, add(pubDataLen, 0x20), hashResult, 0x20)
            mstore(pubdata, pubDataLen)

        // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }

            hash := mload(hashResult)
        }

        // current chain rolling hash
        bytes32 rollingHash = hash & bytes32(INPUT_MASK);
        commitment = calInput(rollingHash, _newBlockData.chainId, _newBlockData.crtCommitments);
    }

    /// @notice Calculate input used in commitment of each chain
    function calInput(bytes32 rollingHash, uint8 chainId, uint256[] memory crtCommitments) internal pure returns (bytes32) {
        bytes memory concatenated = abi.encodePacked(rollingHash, uint256(chainId));
        for (uint i = 0; i < crtCommitments.length; i++) {
            concatenated = abi.encodePacked(concatenated, crtCommitments[i]);
        }
        return sha256(concatenated)  & bytes32(INPUT_MASK);
    }

    /// @notice Checks that deposit is same as operation in priority queue
    /// @param _deposit Deposit data
    /// @param _priorityRequestId Operation's id in priority queue
    function checkPriorityOperation(Operations.Deposit memory _deposit, uint64 _priorityRequestId) internal view {
        Operations.OpType priorReqType = priorityRequests[_priorityRequestId].opType;
        require(priorReqType == Operations.OpType.Deposit, "H"); // incorrect priority op type

        bytes20 hashedPubdata = priorityRequests[_priorityRequestId].hashedPubData;
        require(Operations.checkDepositInPriorityQueue(_deposit, hashedPubdata), "I");
    }

    /// @notice Checks that quick swap is same as operation in priority queue
    /// @param _quickSwap Quick swap data
    /// @param _priorityRequestId Operation's id in priority queue
    function checkPriorityOperation(Operations.QuickSwap memory _quickSwap, uint64 _priorityRequestId) internal view {
        Operations.OpType priorReqType = priorityRequests[_priorityRequestId].opType;
        require(priorReqType == Operations.OpType.QuickSwap, "ZkSyncBlock: QuickSwap Op Type"); // incorrect priority op type

        bytes20 hashedPubdata = priorityRequests[_priorityRequestId].hashedPubData;
        require(Operations.checkQuickSwapInPriorityQueue(_quickSwap, hashedPubdata), "ZkSyncBlock: QuickSwap Hash");
    }

    /// @notice Checks that token mapping is same as operation in priority queue
    /// @param _mapping Mapping data
    /// @param _priorityRequestId Operation's id in priority queue
    function checkPriorityOperation(Operations.Mapping memory _mapping, uint64 _priorityRequestId) internal view {
        Operations.OpType priorReqType = priorityRequests[_priorityRequestId].opType;
        require(priorReqType == Operations.OpType.Mapping, "ZkSyncBlock: Mapping Op Type"); // incorrect priority op type

        bytes20 hashedPubdata = priorityRequests[_priorityRequestId].hashedPubData;
        require(Operations.checkMappingInPriorityQueue(_mapping, hashedPubdata), "ZkSyncBlock: QuickSwap Hash");
    }

    /// @notice Checks that FullExit is same as operation in priority queue
    /// @param _fullExit FullExit data
    /// @param _priorityRequestId Operation's id in priority queue
    function checkPriorityOperation(Operations.FullExit memory _fullExit, uint64 _priorityRequestId) internal view {
        Operations.OpType priorReqType = priorityRequests[_priorityRequestId].opType;
        require(priorReqType == Operations.OpType.FullExit, "J"); // incorrect priority op type

        bytes20 hashedPubdata = priorityRequests[_priorityRequestId].hashedPubData;
        require(Operations.checkFullExitInPriorityQueue(_fullExit, hashedPubdata), "K");
    }

    function increaseBalanceToWithdraw(bytes22 _packedBalanceKey, uint128 _amount) internal {
        uint128 balance = pendingBalances[_packedBalanceKey].balanceToWithdraw;
        pendingBalances[_packedBalanceKey] = PendingBalance(balance.add(_amount), FILLED_GAS_RESERVE_VALUE);
    }

    function accepterWithdraw(Operations.QuickSwap memory op) internal {
        // if amountOutMin is zero it means swap failed
        if (op.amountOutMin == 0) {
            return;
        }
        bytes32 hash = keccak256(abi.encodePacked(op.to, op.toTokenId, op.amountOutMin, op.withdrawFee, op.nonce));
        address accepter = accepts[hash];
        if (accepter == address(0)) {
            // receiver act as a accepter
            accepts[hash] = op.to;
            storePendingBalance(op.toTokenId, op.to, op.amountOutMin);
        } else {
            // accepter profit is (amountOutMin - fee)
            storePendingBalance(op.toTokenId, accepter, op.amountOutMin);
        }
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "14");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "v");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "15");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "x");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "y");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUInt128 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "12");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub(a, b, "aa");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
        require(c / a == b, "13");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        return div(a, b, "ac");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint128 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        return mod(a, b, "ad");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "16");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "17");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "18");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "19");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "1a");
        return uint8(value);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./IERC20.sol";
import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Sends tokens
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transfer` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function sendERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
        // `transfer` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Transfers token from one address to another
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transferFrom` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _from Address of sender
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function transferFromERC20(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _amount));
        // `transferFrom` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "P"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    function hashBytesToBytes20(bytes memory _bytes) internal pure returns (bytes20) {
        return bytes20(uint160(uint256(keccak256(_bytes))));
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
                add(bts, 32), // BYTES_HEADER_SIZE
                data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(self), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return new_offset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 new_offset, bytes memory data) {
        data = slice(_data, _offset, _length);
        new_offset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bool r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint8 r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint32 r) {
        new_offset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint128 r) {
        new_offset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, address r) {
        new_offset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes20 r) {
        new_offset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes32 r) {
        new_offset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _new_length) internal pure returns (uint256 r) {
        require(_new_length <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _new_length, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _new_length) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
                // here outStringByte from each half of input byte calculates by the next:
                //
                // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
                // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                    out_curr,
                    shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                    add(out_curr, 0x01),
                    shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./Bytes.sol";
import "./Utils.sol";

/// @title zkSync operations tools
library Operations {
    // Circuit ops and their pubdata (chunks * bytes)

    /// @notice zkSync circuit operation type
    enum OpType {
        Noop,
        Deposit,
        TransferToNew,
        PartialExit,
        _CloseAccount, // used for correct op id offset
        Transfer,
        FullExit,
        ChangePubKey,
        ForcedExit,
        AddLiquidity,
        RemoveLiquidity,
        Swap,
        QuickSwap,
        Mapping
    }

    // Byte lengths

    uint8 constant OP_TYPE_BYTES = 1;

    uint8 constant CHAIN_BYTES = 1;

    uint8 constant TOKEN_BYTES = 2;

    uint8 constant PUBKEY_BYTES = 32;

    uint8 constant NONCE_BYTES = 4;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    uint8 constant ADDRESS_BYTES = 20;

    /// @dev Packed fee bytes lengths
    uint8 constant FEE_BYTES = 2;

    /// @dev zkSync account id bytes lengths
    uint8 constant ACCOUNT_ID_BYTES = 4;

    uint8 constant AMOUNT_BYTES = 16;

    /// @dev Signature (for example full exit signature) bytes length
    uint8 constant SIGNATURE_BYTES = 64;

    // Deposit pubdata
    struct Deposit {
        // uint8 opType
        uint32 accountId;
        uint16 tokenId;
        uint128 amount;
        address owner;
    }

    uint256 public constant PACKED_DEPOSIT_PUBDATA_BYTES =
        OP_TYPE_BYTES + ACCOUNT_ID_BYTES + TOKEN_BYTES + AMOUNT_BYTES + ADDRESS_BYTES;

    /// Deserialize deposit pubdata
    function readDepositPubdata(bytes memory _data) internal pure returns (Deposit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset); // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset); // amount
        (offset, parsed.owner) = Bytes.readAddress(_data, offset); // owner

        require(offset == PACKED_DEPOSIT_PUBDATA_BYTES, "N"); // reading invalid deposit pubdata size
    }

    /// Serialize deposit pubdata
    function writeDepositPubdataForPriorityQueue(Deposit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.Deposit),
            bytes4(0), // accountId (ignored) (update when ACCOUNT_ID_BYTES is changed)
            op.tokenId, // tokenId
            op.amount, // amount
            op.owner // owner
        );
    }

    /// @notice Write deposit pubdata for priority queue check.
    function checkDepositInPriorityQueue(Deposit memory op, bytes20 hashedPubdata) internal pure returns (bool) {
        return Utils.hashBytesToBytes20(writeDepositPubdataForPriorityQueue(op)) == hashedPubdata;
    }

    // FullExit pubdata

    struct FullExit {
        // uint8 opType
        uint32 accountId;
        address owner;
        uint16 tokenId;
        uint128 amount;
    }

    uint256 public constant PACKED_FULL_EXIT_PUBDATA_BYTES =
        OP_TYPE_BYTES + ACCOUNT_ID_BYTES + ADDRESS_BYTES + TOKEN_BYTES + AMOUNT_BYTES;

    function readFullExitPubdata(bytes memory _data) internal pure returns (FullExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.owner) = Bytes.readAddress(_data, offset); // owner
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset); // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset); // amount

        require(offset == PACKED_FULL_EXIT_PUBDATA_BYTES, "O"); // reading invalid full exit pubdata size
    }

    function writeFullExitPubdataForPriorityQueue(FullExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.FullExit),
            op.accountId, // accountId
            op.owner, // owner
            op.tokenId, // tokenId
            uint128(0) // amount -- ignored
        );
    }

    function checkFullExitInPriorityQueue(FullExit memory op, bytes20 hashedPubdata) internal pure returns (bool) {
        return Utils.hashBytesToBytes20(writeFullExitPubdataForPriorityQueue(op)) == hashedPubdata;
    }

    // PartialExit pubdata

    struct PartialExit {
        //uint8 opType; -- present in pubdata, ignored at serialization
        //uint32 accountId; -- present in pubdata, ignored at serialization
        uint16 tokenId;
        uint128 amount;
        //uint16 fee; -- present in pubdata, ignored at serialization
        address owner;
    }

    function readPartialExitPubdata(bytes memory _data) internal pure returns (PartialExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES + ACCOUNT_ID_BYTES; // opType + accountId (ignored)
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset); // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset); // amount
        offset += FEE_BYTES; // fee (ignored)
        (offset, parsed.owner) = Bytes.readAddress(_data, offset); // owner
    }

    // ForcedExit pubdata

    struct ForcedExit {
        //uint8 opType; -- present in pubdata, ignored at serialization
        //uint32 initiatorAccountId; -- present in pubdata, ignored at serialization
        //uint32 targetAccountId; -- present in pubdata, ignored at serialization
        uint16 tokenId;
        uint128 amount;
        //uint16 fee; -- present in pubdata, ignored at serialization
        address target;
    }

    function readForcedExitPubdata(bytes memory _data) internal pure returns (ForcedExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES + ACCOUNT_ID_BYTES * 2; // opType + initiatorAccountId + targetAccountId (ignored)
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset); // tokenId
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset); // amount
        offset += FEE_BYTES; // fee (ignored)
        (offset, parsed.target) = Bytes.readAddress(_data, offset); // target
    }

    // ChangePubKey

    enum ChangePubkeyType {ECRECOVER, CREATE2, OldECRECOVER}

    struct ChangePubKey {
        // uint8 opType; -- present in pubdata, ignored at serialization
        uint32 accountId;
        bytes20 pubKeyHash;
        address owner;
        uint32 nonce;
        //uint16 tokenId; -- present in pubdata, ignored at serialization
        //uint16 fee; -- present in pubdata, ignored at serialization
    }

    function readChangePubKeyPubdata(bytes memory _data) internal pure returns (ChangePubKey memory parsed) {
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset); // accountId
        (offset, parsed.pubKeyHash) = Bytes.readBytes20(_data, offset); // pubKeyHash
        (offset, parsed.owner) = Bytes.readAddress(_data, offset); // owner
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset); // nonce
    }

    // QuickSwap pubdata
    struct QuickSwap {
        // uint8 opType
        uint8 fromChainId;
        uint8 toChainId;
        address owner;
        uint16 fromTokenId;
        uint128 amountIn;
        address to;
        uint16 toTokenId;
        // amountOutMin has two meanings, the first refers to swap slippage of the from chain
        // and the second refers to the actual amountOut of the to chain
        uint128 amountOutMin;
        uint16 withdrawFee;
        uint32 nonce;
    }

    uint256 public constant PACKED_QUICK_SWAP_PUBDATA_BYTES =
    OP_TYPE_BYTES + 2 * (CHAIN_BYTES + AMOUNT_BYTES + TOKEN_BYTES + ADDRESS_BYTES) + FEE_BYTES + NONCE_BYTES;

    /// Deserialize quick swap pubdata
    function readQuickSwapPubdata(bytes memory _data) internal pure returns (QuickSwap memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.fromChainId) = Bytes.readUint8(_data, offset); // fromChainId
        (offset, parsed.toChainId) = Bytes.readUint8(_data, offset); // toChainId
        (offset, parsed.owner) = Bytes.readAddress(_data, offset); // owner
        (offset, parsed.fromTokenId) = Bytes.readUInt16(_data, offset); // fromTokenId
        (offset, parsed.amountIn) = Bytes.readUInt128(_data, offset); // amountIn
        (offset, parsed.to) = Bytes.readAddress(_data, offset); // to
        (offset, parsed.toTokenId) = Bytes.readUInt16(_data, offset); // toTokenId
        (offset, parsed.amountOutMin) = Bytes.readUInt128(_data, offset); // amountOutMin
        (offset, parsed.withdrawFee) = Bytes.readUInt16(_data, offset); // withdrawAmountOutMin
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset); // nonce

        require(offset == PACKED_QUICK_SWAP_PUBDATA_BYTES, "Operations: Read QuickSwap"); // reading invalid quick swap pubdata size
    }

    /// Serialize quick swap pubdata
    function writeQuickSwapPubdataForPriorityQueue(QuickSwap memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.QuickSwap),
            op.fromChainId,
            op.toChainId,
            op.owner,
            op.fromTokenId,
            op.amountIn,
            op.to,
            op.toTokenId,
            uint128(0), // amountOutMin ignored
            op.withdrawFee,
            op.nonce
        );
    }

    /// @notice Write quick swap pubdata for priority queue check.
    function checkQuickSwapInPriorityQueue(QuickSwap memory op, bytes20 hashedPubdata) internal pure returns (bool) {
        return Utils.hashBytesToBytes20(writeQuickSwapPubdataForPriorityQueue(op)) == hashedPubdata;
    }

    // Mapping pubdata
    struct Mapping {
        // uint8 opType
        uint8 fromChainId;
        uint8 toChainId;
        address owner;
        address to;
        uint16 tokenId;
        uint128 amount;
        uint128 fee; // present in pubdata, ignored at serialization
    }

    uint256 public constant PACKED_MAPPING_PUBDATA_BYTES =
    OP_TYPE_BYTES + 2 * CHAIN_BYTES + 2 * ADDRESS_BYTES + TOKEN_BYTES + 2 * AMOUNT_BYTES;

    /// Deserialize mapping pubdata
    function readMappingPubdata(bytes memory _data) internal pure returns (Mapping memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.fromChainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.toChainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.to) = Bytes.readAddress(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        (offset, parsed.fee) = Bytes.readUInt128(_data, offset);

        require(offset == PACKED_MAPPING_PUBDATA_BYTES, "Operations: Read Mapping");
    }

    /// Serialize mapping pubdata
    function writeMappingPubdataForPriorityQueue(Mapping memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.Mapping),
            op.fromChainId,
            op.toChainId,
            op.owner,
            op.to,
            op.tokenId,
            op.amount,
            uint128(0) // fee (ignored)
        );
    }

    /// @notice Write mapping pubdata for priority queue check.
    function checkMappingInPriorityQueue(Mapping memory op, bytes20 hashedPubdata) internal pure returns (bool) {
        return Utils.hashBytesToBytes20(writeMappingPubdataForPriorityQueue(op)) == hashedPubdata;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./ReentrancyGuard.sol";
import "./Storage.sol";
import "./Config.sol";
import "./Events.sol";
import "./IMappingToken.sol";

/// @title zkSync base contract
/// @author ZkLink Labs
contract ZkSyncBase is Storage, Config, Events, ReentrancyGuard {

    /// @notice Checks that current state not is exodus mode
    function requireActive() internal view {
        require(!exodusMode, "L"); // exodus mode activated
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    function initializeReentrancyGuard() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        assembly {
            sstore(LOCK_FLAG_ADDRESS, 1)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bool notEntered;
        assembly {
            notEntered := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(notEntered, "1b");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, 0)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, 1)
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./IERC20.sol";

import "./Governance.sol";
import "./Verifier.sol";
import "./Operations.sol";
import "./IVault.sol";

/// @title zkSync storage contract
/// @author Matter Labs
contract Storage {
    /// @dev Flag indicates that upgrade preparation status is active
    /// @dev Will store false in case of not active upgrade mode
    bool internal upgradePreparationActive;

    /// @dev Upgrade preparation activation timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint256 internal upgradePreparationActivationTime;

    /// @dev Verifier contract. Used to verify block proof and exit proof
    Verifier public verifier;

    /// @dev Governance contract. Contains the governor (the owner) of whole system, validators list, possible tokens list
    Governance public governance;

    /// @dev Vault contract. Used to hold token user deposited to L1
    IVault public vault;

    uint8 internal constant FILLED_GAS_RESERVE_VALUE = 0xff; // we use it to set gas revert value so slot will not be emptied with 0 balance
    struct PendingBalance {
        uint128 balanceToWithdraw;
        uint8 gasReserveValue; // gives user opportunity to fill storage slot with nonzero value
    }

    /// @dev Root-chain balances (per owner and token id, see packAddressAndTokenId) to withdraw
    mapping(bytes22 => PendingBalance) internal pendingBalances;

    /// @notice Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
    uint32 public totalBlocksExecuted;

    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint32 public totalBlocksCommitted;

    /// @notice Flag indicates that a user has exited in the exodus mode certain token balance (per account id and tokenId)
    mapping(uint32 => mapping(uint16 => bool)) public performedExodus;

    /// @notice Flag indicates that exodus (mass exit) mode is triggered
    /// @notice Once it was raised, it can not be cleared again, and all users must exit
    bool public exodusMode;

    /// @notice User authenticated fact hashes for some nonce.
    mapping(address => mapping(uint32 => bytes32)) public authFacts;

    /// @notice First open priority request id
    uint64 public firstPriorityRequestId;

    /// @notice Total number of requests
    uint64 public totalOpenPriorityRequests;

    /// @notice Total number of committed requests.
    /// @dev Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
    uint64 public totalCommittedPriorityRequests;

    /// @notice Packs address and token id into single word to use as a key in balances mapping
    function packAddressAndTokenId(address _address, uint16 _tokenId) internal pure returns (bytes22) {
        return bytes22((uint176(_address) | (uint176(_tokenId) << 160)));
    }

    /// @Rollup block stored data
    /// @member blockNumber Rollup block number
    /// @member priorityOperations Number of priority operations processed
    /// @member pendingOnchainOperationsHash Hash of all operations that must be processed after verify
    /// @member timestamp Rollup block timestamp, have the same format as Ethereum block constant
    /// @member stateHash Root hash of the rollup state
    /// @member commitment Verified input for the zkSync circuit
    struct StoredBlockInfo {
        uint32 blockNumber;
        uint64 priorityOperations;
        bytes32 pendingOnchainOperationsHash;
        uint256 timestamp;
        bytes32 stateHash;
        bytes32 commitment;
    }

    /// @notice Returns the keccak hash of the ABI-encoded StoredBlockInfo
    function hashStoredBlockInfo(StoredBlockInfo memory _storedBlockInfo) internal pure returns (bytes32) {
        return keccak256(abi.encode(_storedBlockInfo));
    }

    /// @dev Stored hashed StoredBlockInfo for some block number
    mapping(uint32 => bytes32) internal storedBlockHashes;

    /// @notice Total blocks proven.
    uint32 public totalBlocksProven;

    /// @notice Priority Operation container
    /// @member hashedPubData Hashed priority operation public data
    /// @member expirationBlock Expiration block number (ETH block) for this request (must be satisfied before)
    /// @member opType Priority operation type
    struct PriorityOperation {
        bytes20 hashedPubData;
        uint64 expirationBlock;
        Operations.OpType opType;
    }

    /// @dev Priority Requests mapping (request id - operation)
    /// @dev Contains op type, pubdata and expiration block of unsatisfied requests.
    /// @dev Numbers are in order of requests receiving
    mapping(uint64 => PriorityOperation) internal priorityRequests;

    /// @dev Timer for authFacts entry reset (address, nonce -> timer).
    /// @dev Used when user wants to reset `authFacts` for some nonce.
    mapping(address => mapping(uint32 => uint256)) internal authFactsResetTimer;

    address public zkSyncBlock;

    /// @dev Accept infos of fast withdraw
    /// @dev Key is keccak256(abi.encodePacked(receiver, tokenId, amount, withdrawFee, nonce))
    /// @dev Value is the accepter address
    mapping(bytes32 => address) public accepts;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    /// @dev None LP ERC20 tokens and ETH withdrawals gas limit, used only for complete withdrawals
    uint256 constant WITHDRAWAL_FROM_VAULT_GAS_LIMIT = 300000;

    /// @dev Bytes in one chunk
    uint8 constant CHUNK_BYTES = 9;

    /// @dev zkSync address length
    uint8 constant ADDRESS_BYTES = 20;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    /// @dev Public key bytes length
    uint8 constant PUBKEY_BYTES = 32;

    /// @dev Ethereum signature r/s bytes length
    uint8 constant ETH_SIGN_RS_BYTES = 32;

    /// @dev Success flag bytes length
    uint8 constant SUCCESS_FLAG_BYTES = 1;

    /// @dev Max amount of tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 127;

    /// @dev Max account id that could be registered in the network
    uint32 constant MAX_ACCOUNT_ID = (2**24) - 1;

    /// @dev Expected average period of block creation
    uint256 constant BLOCK_PERIOD = 3 seconds;

    /// @dev ETH blocks verification expectation
    /// @dev Blocks can be reverted if they are not verified for at least EXPECT_VERIFICATION_IN.
    /// @dev If set to 0 validator can revert blocks at any time.
    uint256 constant EXPECT_VERIFICATION_IN = 0 hours / BLOCK_PERIOD;

    uint256 constant NOOP_BYTES = 1 * CHUNK_BYTES;
    uint256 constant DEPOSIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant QUICK_SWAP_BYTES = 10 * CHUNK_BYTES;
    uint256 constant TRANSFER_TO_NEW_BYTES = 6 * CHUNK_BYTES;
    uint256 constant PARTIAL_EXIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant TRANSFER_BYTES = 2 * CHUNK_BYTES;
    uint256 constant FORCED_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @dev Full exit operation length
    uint256 constant FULL_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @dev ChangePubKey operation length
    uint256 constant CHANGE_PUBKEY_BYTES = 6 * CHUNK_BYTES;
    uint256 constant MAPPING_BYTES = 7 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 constant PRIORITY_EXPIRATION_PERIOD = 3 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 constant PRIORITY_EXPIRATION =
        PRIORITY_EXPIRATION_PERIOD/BLOCK_PERIOD;

    /// @dev Maximum number of priority request to clear during verifying the block
    /// @dev Cause deleting storage slots cost 5k gas per each slot it's unprofitable to clear too many slots
    /// @dev Value based on the assumption of ~750k gas cost of verifying and 5 used storage slots per PriorityOperation structure
    uint64 constant MAX_PRIORITY_REQUESTS_TO_DELETE_IN_VERIFY = 6;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 constant MASS_FULL_EXIT_PERIOD = 9 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 constant UPGRADE_NOTICE_PERIOD =
        0;

    /// @dev Timestamp - seconds since unix epoch
    uint256 constant COMMIT_TIMESTAMP_NOT_OLDER = 24 hours;

    /// @dev Maximum available error between real commit block timestamp and analog used in the verifier (in seconds)
    /// @dev Must be used cause miner's `block.timestamp` value can differ on some small value (as we know - 15 seconds)
    uint256 constant COMMIT_TIMESTAMP_APPROXIMATION_DELTA = 15 minutes;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock
    uint256 constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev When set fee = 100, it means 1%
    uint16 constant MAX_WITHDRAW_FEE = 10000;

    /// @dev Chain id
    uint8 constant CHAIN_ID = 0;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Upgradeable.sol";
import "./Operations.sol";

/// @title zkSync events
/// @author Matter Labs
interface Events {
    /// @notice Event emitted when a block is committed
    event BlockCommit(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is verified
    event BlockVerification(uint32 indexed blockNumber);

    /// @notice Event emitted when user funds are withdrawn from the zkSync contract
    event Withdrawal(uint16 indexed tokenId, uint128 amount);

    /// @notice Event emitted when user funds are deposited to the zkSync contract
    event Deposit(uint16 indexed tokenId, uint128 amount);

    /// @notice Event emitted when user funds are deposited and swap to the zkSync contract
    event QuickSwap(address indexed sender,
        uint128 amountIn,
        uint128 amountOutMin,
        uint16 withdrawFee,
        uint16 indexed fromTokenId,
        uint8 toChainId,
        uint16 toTokenId,
        address to,
        uint32 nonce);

    /// @notice Event emitted when user mapping token
    event TokenMapping(uint16 indexed tokenId, uint128 amount, uint8 toChainId);

    /// @notice Event emitted when accepter accept a fast withdraw
    event Accept(address indexed accepter, address indexed receiver, uint16 indexed tokenId, uint128 amount, uint128 fee, uint32 nonce);

    /// @notice Event emitted when user sends a authentication fact (e.g. pub-key hash)
    event FactAuth(address indexed sender, uint32 nonce, bytes fact);

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(uint32 totalBlocksVerified, uint32 totalBlocksCommitted);

    /// @notice Exodus mode entered event
    event ExodusMode();

    /// @notice New priority request event. Emitted when a request is placed into mapping
    event NewPriorityRequest(
        address sender,
        uint64 serialId,
        Operations.OpType opType,
        bytes pubData,
        uint256 expirationBlock
    );

    /// @notice Deposit committed event.
    event DepositCommit(
        uint32 indexed zkSyncBlockId,
        uint32 indexed accountId,
        address owner,
        uint16 indexed tokenId,
        uint128 amount
    );

    /// @notice Full exit committed event.
    event FullExitCommit(
        uint32 indexed zkSyncBlockId,
        uint32 indexed accountId,
        address owner,
        uint16 indexed tokenId,
        uint128 amount
    );
}

/// @title Upgrade events
/// @author Matter Labs
interface UpgradeEvents {
    /// @notice Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    event NewUpgradable(uint256 indexed versionId, address indexed upgradeable);

    /// @notice Upgrade mode enter event
    event NoticePeriodStart(
        uint256 indexed versionId,
        address[] newTargets,
        uint256 noticePeriod // notice period (in seconds)
    );

    /// @notice Upgrade mode cancel event
    event UpgradeCancel(uint256 indexed versionId);

    /// @notice Upgrade mode preparation status event
    event PreparationStart(uint256 indexed versionId);

    /// @notice Upgrade mode complete event
    event UpgradeComplete(uint256 indexed versionId, address[] newTargets);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED


/**
 * @dev Interface of the Mapping token.
 */
interface IMappingToken {

    /// @notice mint amount of token to receiver
    function mint(address receiver, uint256 amount) external returns (bool);

    /// @notice burn amount of token from msg.sender
    function burn(uint256 amount) external returns (bool);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Config.sol";

/// @title Governance Contract
/// @author Matter Labs
contract Governance is Config {
    /// @notice Token added to Franklin net
    event NewToken(address indexed token, uint16 indexed tokenId);

    /// @notice Governor changed
    event NewGovernor(address newGovernor);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    event TokenPausedUpdate(address indexed token, bool paused);

    event TokenMappingUpdate(address indexed token, bool isMapping);

    /// @notice Address which will exercise governance over the network i.e. add tokens, change validator set, conduct upgrades
    address public networkGovernor;

    /// @notice Total number of ERC20 tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 public totalTokens;

    /// @notice List of registered tokens by tokenId
    mapping(uint16 => address) public tokenAddresses;

    /// @notice List of registered tokens by address
    mapping(address => uint16) public tokenIds;

    /// @notice List of permitted validators
    mapping(address => bool) public validators;

    /// @notice Paused tokens list, deposits are impossible to create for paused tokens
    mapping(uint16 => bool) public pausedTokens;

    /// @notice Mapping tokens list
    mapping(uint16 => bool) public mappingTokens;

    /// @notice Governance contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    ///     _networkGovernor The address of network governor
    function initialize(bytes calldata initializationParameters) external {
        address _networkGovernor = abi.decode(initializationParameters, (address));

        networkGovernor = _networkGovernor;
    }

    /// @notice Governance contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external {
        requireGovernor(msg.sender);
        require(_newGovernor != address(0), "z0");
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Add token to the list of networks tokens，token must not be taken fees when transfer
    /// @param _token Token address
    function addToken(address _token) external {
        requireGovernor(msg.sender);
        require(tokenIds[_token] == 0, "1e"); // token exists
        require(totalTokens < MAX_AMOUNT_OF_REGISTERED_TOKENS, "1f"); // no free identifiers for tokens

        totalTokens++;
        uint16 newTokenId = totalTokens; // it is not `totalTokens - 1` because tokenId = 0 is reserved for eth

        tokenAddresses[newTokenId] = _token;
        tokenIds[_token] = newTokenId;
        emit NewToken(_token, newTokenId);
    }

    /// @notice Pause token deposits for the given token
    /// @param _tokenAddr Token address
    /// @param _tokenPaused Token paused status
    function setTokenPaused(address _tokenAddr, bool _tokenPaused) external {
        requireGovernor(msg.sender);

        uint16 tokenId = this.validateTokenAddress(_tokenAddr);
        if (pausedTokens[tokenId] != _tokenPaused) {
            pausedTokens[tokenId] = _tokenPaused;
            emit TokenPausedUpdate(_tokenAddr, _tokenPaused);
        }
    }

    /// @notice Set token mapping
    /// @param _tokenAddr Token address
    /// @param _tokenMapping Token mapping status
    function setTokenMapping(address _tokenAddr, bool _tokenMapping) external {
        requireGovernor(msg.sender);

        uint16 tokenId = this.validateTokenAddress(_tokenAddr);
        if (mappingTokens[tokenId] != _tokenMapping) {
            mappingTokens[tokenId] = _tokenMapping;
            emit TokenMappingUpdate(_tokenAddr, _tokenMapping);
        }
    }

    /// @notice Change validator status (active or not active)
    /// @param _validator Validator address
    /// @param _active Active flag
    function setValidator(address _validator, bool _active) external {
        requireGovernor(msg.sender);
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    /// @notice Check if specified address is is governor
    /// @param _address Address to check
    function requireGovernor(address _address) public view {
        require(_address == networkGovernor, "1g"); // only by governor
    }

    /// @notice Checks if validator is active
    /// @param _address Validator address
    function requireActiveValidator(address _address) external view {
        require(validators[_address], "1h"); // validator is not active
    }

    /// @notice Validate token id (must be less than or equal to total tokens amount)
    /// @param _tokenId Token id
    /// @return bool flag that indicates if token id is less than or equal to total tokens amount
    function isValidTokenId(uint16 _tokenId) external view returns (bool) {
        return _tokenId <= totalTokens;
    }

    /// @notice Validate token address
    /// @param _tokenAddr Token address
    /// @return tokens id
    function validateTokenAddress(address _tokenAddr) external view returns (uint16) {
        uint16 tokenId = tokenIds[_tokenAddr];
        require(tokenId != 0, "1i"); // 0 is not a valid token
        return tokenId;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0




import "./KeysWithPlonkVerifier.sol";
import "./Config.sol";

// Hardcoded constants to avoid accessing store
contract Verifier is KeysWithPlonkVerifier, KeysWithPlonkVerifierOld, Config {
    function initialize(bytes calldata) external {}

    /// @notice Verifier contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    function verifyAggregatedBlockProof(
        uint256[] memory _recursiveInput,
        uint256[] memory _proof,
        uint8[] memory _vkIndexes,
        uint256[] memory _individual_vks_inputs,
        uint256[16] memory _subproofs_limbs
    ) external view returns (bool) {
        // #if DUMMY_VERIFIER
        uint256 oldGasValue = gasleft();
        // HACK: ignore warnings from unused variables
        abi.encode(_recursiveInput, _proof, _vkIndexes, _individual_vks_inputs, _subproofs_limbs);
        uint256 tmp;
        while (gasleft() + 500000 > oldGasValue) {
            tmp += 1;
        }
        return true;
        // #else
        for (uint256 i = 0; i < _individual_vks_inputs.length; ++i) {
            uint256 commitment = _individual_vks_inputs[i];
            _individual_vks_inputs[i] = commitment & INPUT_MASK;
        }
        VerificationKey memory vk = getVkAggregated(uint32(_vkIndexes.length));

        return
            verify_serialized_proof_with_recursion(
                _recursiveInput,
                _proof,
                VK_TREE_ROOT,
                VK_MAX_INDEX,
                _vkIndexes,
                _individual_vks_inputs,
                _subproofs_limbs,
                vk
            );
        // #endif
    }

    function verifyExitProof(
        bytes32 _rootHash,
        uint32 _accountId,
        address _owner,
        uint16 _tokenId,
        uint128 _amount,
        uint256[] calldata _proof
    ) external view returns (bool) {
        bytes32 commitment = sha256(abi.encodePacked(_rootHash, _accountId, _owner, _tokenId, _amount));

        uint256[] memory inputs = new uint256[](1);
        inputs[0] = uint256(commitment) & INPUT_MASK;
        ProofOld memory proof = deserialize_proof_old(inputs, _proof);
        VerificationKeyOld memory vk = getVkExit();
        require(vk.num_inputs == inputs.length);
        return verify_old(proof, vk);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the vault contract
/// @author ZkLink Labs
interface IVault {

    /// @notice Record user deposit(can only be call by zkSync)
    /// @param tokenId Token id
    function recordDeposit(uint16 tokenId) external;

    /// @notice Withdraw token from vault to satisfy user withdraw request(can only be call by zkSync)
    /// @dev More details see test/vault_withdraw_test.js
    /// @param tokenId Token id
    /// @param to Token receive address
    /// @param amount Amount of tokens to transfer
    function withdraw(uint16 tokenId, address to, uint256 amount) external;
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x0dcb14ce7946e22fc026c347f336da4853e7d16cb3d9de11ee45d8aa43557509;
    uint8 constant VK_MAX_INDEX = 2;

    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(1)) { return getVkAggregated1(); }
        else if (_proofs == uint32(4)) { return getVkAggregated4(); }
    }

    
    function getVkAggregated1() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 4194304;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x19fbd6706b4cbde524865701eae0ae6a270608a09c3afdab7760b685c1c6c41b,
            0x25082a191f0690c175cc9af1106c6c323b5b5de4e24dc23be1e965e1851bca48
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x16c02d9ca95023d1812a58d16407d1ea065073f02c916290e39242303a8a1d8e,
            0x230338b422ce8533e27cd50086c28cb160cf05a7ae34ecd5899dbdf449dc7ce0
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1db0d133243750e1ea692050bbf6068a49dc9f6bae1f11960b6ce9e10adae0f5,
            0x12a453ed0121ae05de60848b4374d54ae4b7127cb307372e14e8daf5097c5123
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x1062ed5e86781fd34f78938e5950c2481a79f132085d2bc7566351ddff9fa3b7,
            0x2fd7aac30f645293cc99883ab57d8c99a518d5b4ab40913808045e8653497346
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x062755048bb95739f845e8659795813127283bf799443d62fea600ae23e7f263,
            0x2af86098beaa241281c78a454c5d1aa6e9eedc818c96cd1e6518e1ac2d26aa39
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0994e25148bbd25be655034f81062d1ebf0a1c2b41e0971434beab1ae8101474,
            0x27cc8cfb1fafd13068aeee0e08a272577d89f8aa0fb8507aabbc62f37587b98f
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x044edf69ce10cfb6206795f92c3be2b0d26ab9afd3977b789840ee58c7dbe927,
            0x2a8aa20c106f8dc7e849bc9698064dcfa9ed0a4050d794a1db0f13b0ee3def37
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x136967f1a2696db05583a58dbf8971c5d9d1dc5f5c97e88f3b4822aa52fefa1c,
            0x127b41299ea5c840c3b12dbe7b172380f432b7b63ce3b004750d6abb9e7b3b7a
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x02fd5638bf3cc2901395ad1124b951e474271770a337147a2167e9797ab9d951,
            0x0fcb2e56b077c8461c36911c9252008286d782e96030769bf279024fc81d412a
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x1865c60ecad86f81c6c952445707203c9c7fdace3740232ceb704aefd5bd45b3,
            0x2f35e29b39ec8bb054e2cff33c0299dd13f8c78ea24a07622128a7444aba3f26
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x2a86ec9c6c1f903650b5abbf0337be556b03f79aecc4d917e90c7db94518dde6,
            0x15b1b6be641336eebd58e7991be2991debbbd780e70c32b49225aa98d10b7016
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x213e42fcec5297b8e01a602684fcd412208d15bdac6b6331a8819d478ba46899,
            0x03223485f4e808a3b2496ae1a3c0dfbcbf4391cffc57ee01e8fca114636ead18
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x2e9b02f8cf605ad1a36e99e990a07d435de06716448ad53053c7a7a5341f71e1,
            0x2d6fdf0bc8bd89112387b1894d6f24b45dcb122c09c84344b6fc77a619dd1d59
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkAggregated4() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x2988e24b15bce9a1e3a4d1d9a8f7c7a65db6c29fd4c6f4afe1a3fbd954d4b4b6,
            0x0bdb6e5ba27a22e03270c7c71399b866b28d7cec504d30e665d67be58e306e12
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x20f3d30d3a91a7419d658f8c035e42a811c9f75eac2617e65729033286d36089,
            0x07ac91e8194eb78a9db537e9459dd6ca26bef8770dde54ac3dd396450b1d4cfe
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x0311872bab6df6e9095a9afe40b12e2ed58f00cc88835442e6b4cf73fb3e147d,
            0x2cdfc5b5e73737809b54644b2f96494f8fcc1dd0fb440f64f44930b432c4542d
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x28fd545b1e960d2eff3142271affa4096ef724212031fdabe22dd4738f36472b,
            0x2c743150ee9894ff3965d8f1129399a3b89a1a9289d4cfa904b0a648d3a8a9fa
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x2c283ce950eee1173b78657e57c80658a8398e7970a9a45b20cd39aff16ad61a,
            0x081c003cbd09f7c3e0d723d6ebbaf432421c188d5759f5ee8ff1ee1dc357d4a8
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x2eb50a2dd293a71a0c038e958c5237bd7f50b2f0c9ee6385895a553de1517d43,
            0x15fdc2b5b28fc351f987b98aa6caec7552cefbafa14e6651061eec4f41993b65
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x17a9403e5c846c1ca5e767c89250113aa156fdb1f026aa0b4db59c09d06816ec,
            0x2512241972ca3ee4839ac72a4cab39ddb413a7553556abd7909284b34ee73f6b
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x09edd69c8baa7928b16615e993e3032bc8cbf9f42bfa3cf28caba1078d371edb,
            0x12e5c39148af860a87b14ae938f33eafa91deeb548cda4cc23ed9ba3e6e496b8
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x0e25c0027706ca3fd3daae849f7c50ec88d4d030da02452001dec7b554cc71b4,
            0x2421da0ca385ff7ba9e5ae68890655669248c8c8187e67d12b2a7ae97e2cff8b
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x151536359fe184567bce57379833f6fae485e5cc9bc27423d83d281aaf2701df,
            0x116beb145bc27faae5a8ae30c28040d3baafb3ea47360e528227b94adb9e4f26
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x23ee338093db23364a6e44acfb60d810a4c4bd6565b185374f7840152d3ae82c,
            0x0f6714f3ee113b9dfb6b653f04bf497602588b16b96ac682d9a5dd880a0aa601
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x05860b0ea3c6f22150812aee304bf35e1a95cfa569a8da52b42dba44a122378a,
            0x19e5a9f3097289272e65e842968752c5355d1cdb2d3d737050e4dfe32ebe1e41
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x3046881fcbe369ac6f99fea8b9505de85ded3de3bc445060be4bc6ef651fa352,
            0x06fe14c1dd6c2f2b48aebeb6fd525573d276b2e148ad25e75c57a58588f755ec
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    

}

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifierOld is VerifierWithDeserializeOld {

    
    function getVkExit() internal pure returns(VerificationKeyOld memory vk) {
        vk.domain_size = 262144;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0f60c8fe0414cb9379b2d39267945f6bd60d06a05216231b26a9fcf88ddbfebe);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x129493cf9e26ed55dbfb5e48fb7b1d324b7e3fafaf6f15dfb7c9154ec984218c,
            0x267cb223a819d52b2f58c184e585ae16c2a376a9bdf4d3187168d3632f668573
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x09a1e2f772d2bf2caf3fb213b4fb921e0c6cdfab382fd7c08e5b34c7ea4b3d6d,
            0x1f022cecbaee32d3292a6d915b3b5dc0af0fb57fa5b7b6385d0620dd6898ee44
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x024a6b5cb3ae607d6d379f156a473facdc0d19959382fdf477ace3e54df18a04,
            0x2c17000cd320261a63c7c8893eeae02db578f2a45fb131d83a53d167623f4762
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x295836fb819cf05cfe5b9634d3a4bd4e671e115f7f83b8d35d068fd27db0b8a0,
            0x0744119705751e09b8ac4df2d49f73bee44fd7fc736e7f7c822474368810457f
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x15f3d2d32ddca3946c625c7d515f4d743e45a00ab82d07ad6142e9ef00dd2608,
            0x2a19b93041d341645a060ed6e7fb863c19df8dea5d37868415d982bafb31a02d
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x19d9aeccf78a51208556efb25e09270b3fe5eb944583299acbb94dd339068c17,
            0x024d28d7447b7ec77d42921df71b1a5fcf78cf79d1c54cd46e89fe0c0de76831
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x1f252b6fc01068f76b22b746904649f7b6bde70e0c26fda209c1d5b6dce38ad9,
            0x0f3446d1870b3a1ab952e1a1b3a6ef5ebffa561798956785d6f4d21a38df781e
        );

        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x27ec862bdc7e068c8a88ad60cfd147a3fccccf7850de6006896b2cd29c842e90,
            0x2b55022007bdf10f8303f5f9475015ea7b3818029d86456e2de8959a5d4e3e18
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x284b5e954c1324cd1526743963cadbce4236a4e1b248a7a2f535539c058b94dd,
            0x1f9c29b5672c7e7829ccbe09a710077531e6efe058f6eb172134bb3b619a2df6
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x00e69bd9cd622feb03f0c67be0f8c4cef5f80e8af4db54a3f7329f010e2e2ef6,
            0x098312e3fc78e32137397d64facb0460320c4959fc4397459e99e871947092ec
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x1c72410474e6277ffbfb451d3f4638fbca559061b23239b114adfa285a52026c,
            0x1aaf58e68cacd951c5eb321bc562dc907d0110a46cbfdba412d31fd9993e78c9
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1, 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4, 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
}

pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0




library PairingsBn254 {
    uint256 constant q_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    struct Fr {
        uint256 value;
    }

    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod);
        return Fr({value: fr});
    }

    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }

    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0);
        return pow(fr, r_mod - 2);
    }

    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }

    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }

    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }

    function pow(Fr memory self, uint256 power) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        return Fr({value: result[0]});
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function new_g1(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }

        // check encoding
        require(x < q_mod);
        require(y < q_mod);
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2
        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs);

        return G1Point(x, y);
    }

    function new_g2(uint256[2] memory x, uint256[2] memory y) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }

    function copy_g1(G1Point memory self) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form

        return
            G2Point(
                [
                    0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                    0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
                ],
                [
                    0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                    0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
                ]
            );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        point_add_into_dest(p1, p2, r);
        return r;
    }

    function point_add_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_sub_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_mul(G1Point memory p, Fr memory s) internal view returns (G1Point memory r) {
        point_mul_into_dest(p, s, r);
        return r;
    }

    function point_mul_assign(G1Point memory p, Fr memory s) internal view {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(
        G1Point memory p,
        Fr memory s,
        G1Point memory dest
    ) internal view {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}

library TranscriptLibrary {
    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant DST_0 = 0;
    uint32 constant DST_1 = 1;
    uint32 constant DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state_0;
        bytes32 state_1;
        uint32 challenge_counter;
    }

    function new_transcript() internal pure returns (Transcript memory t) {
        t.state_0 = bytes32(0);
        t.state_1 = bytes32(0);
        t.challenge_counter = 0;
    }

    function update_with_u256(Transcript memory self, uint256 value) internal pure {
        bytes32 old_state_0 = self.state_0;
        self.state_0 = keccak256(abi.encodePacked(DST_0, old_state_0, self.state_1, value));
        self.state_1 = keccak256(abi.encodePacked(DST_1, old_state_0, self.state_1, value));
    }

    function update_with_fr(Transcript memory self, PairingsBn254.Fr memory value) internal pure {
        update_with_u256(self, value.value);
    }

    function update_with_g1(Transcript memory self, PairingsBn254.G1Point memory p) internal pure {
        update_with_u256(self, p.X);
        update_with_u256(self, p.Y);
    }

    function get_challenge(Transcript memory self) internal pure returns (PairingsBn254.Fr memory challenge) {
        bytes32 query = keccak256(abi.encodePacked(DST_CHALLENGE, self.state_0, self.state_1, self.challenge_counter));
        self.challenge_counter += 1;
        challenge = PairingsBn254.Fr({value: uint256(query) & FR_MASK});
    }
}

contract Plonk4VerifierWithAccessToDNext {
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant ZERO = 0;
    uint256 constant ONE = 1;
    uint256 constant TWO = 2;
    uint256 constant THREE = 3;
    uint256 constant FOUR = 4;

    uint256 constant STATE_WIDTH = 4;
    uint256 constant NUM_DIFFERENT_GATES = 2;
    uint256 constant NUM_SETUP_POLYS_FOR_MAIN_GATE = 7;
    uint256 constant NUM_SETUP_POLYS_RANGE_CHECK_GATE = 0;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP = 1;
    uint256 constant NUM_GATE_SELECTORS_OPENED_EXPLICITLY = 1;

    uint256 constant RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK =
        0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant LIMB_WIDTH = 68;

    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[NUM_SETUP_POLYS_FOR_MAIN_GATE + NUM_SETUP_POLYS_RANGE_CHECK_GATE] gate_setup_commitments;
        PairingsBn254.G1Point[NUM_DIFFERENT_GATES] gate_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH] copy_permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH - 1] copy_permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct Proof {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH] wire_commitments;
        PairingsBn254.G1Point copy_permutation_grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] wire_values_at_z_omega;
        PairingsBn254.Fr[NUM_GATE_SELECTORS_OPENED_EXPLICITLY] gate_selector_values_at_z;
        PairingsBn254.Fr copy_grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length - 1; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(dens[i]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            dens[i].assign(tmp_2); // all inversed
            dens[i].mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing(uint256 domain_size, PairingsBn254.Fr memory at)
        internal
        view
        returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory inputs_term = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            inputs_term.add_assign(tmp);
        }

        inputs_term.mul_assign(proof.gate_selector_values_at_z[0]);
        rhs.add_assign(inputs_term);

        // now we need 5th power
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.copy_grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function add_contribution_from_range_constraint_gates(
        PartialVerifierState memory state,
        Proof memory proof,
        PairingsBn254.Fr memory current_alpha
    ) internal pure returns (PairingsBn254.Fr memory res) {
        // now add contribution from range constraint gate
        // we multiply selector commitment by all the factors (alpha*(c - 4d)(c - 4d - 1)(..-2)(..-3) + alpha^2 * (4b - c)()()() + {} + {})

        PairingsBn254.Fr memory one_fr = PairingsBn254.new_fr(ONE);
        PairingsBn254.Fr memory two_fr = PairingsBn254.new_fr(TWO);
        PairingsBn254.Fr memory three_fr = PairingsBn254.new_fr(THREE);
        PairingsBn254.Fr memory four_fr = PairingsBn254.new_fr(FOUR);

        res = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t0 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t2 = PairingsBn254.new_fr(0);

        for (uint256 i = 0; i < 3; i++) {
            current_alpha.mul_assign(state.alpha);

            // high - 4*low

            // this is 4*low
            t0 = PairingsBn254.copy(proof.wire_values_at_z[3 - i]);
            t0.mul_assign(four_fr);

            // high
            t1 = PairingsBn254.copy(proof.wire_values_at_z[2 - i]);
            t1.sub_assign(t0);

            // t0 is now t1 - {0,1,2,3}

            // first unroll manually for -0;
            t2 = PairingsBn254.copy(t1);

            // -1
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(one_fr);
            t2.mul_assign(t0);

            // -2
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(two_fr);
            t2.mul_assign(t0);

            // -3
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(three_fr);
            t2.mul_assign(t0);

            t2.mul_assign(current_alpha);

            res.add_assign(t2);
        }

        // now also d_next - 4a

        current_alpha.mul_assign(state.alpha);

        // high - 4*low

        // this is 4*low
        t0 = PairingsBn254.copy(proof.wire_values_at_z[0]);
        t0.mul_assign(four_fr);

        // high
        t1 = PairingsBn254.copy(proof.wire_values_at_z_omega[0]);
        t1.sub_assign(t0);

        // t0 is now t1 - {0,1,2,3}

        // first unroll manually for -0;
        t2 = PairingsBn254.copy(t1);

        // -1
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(one_fr);
        t2.mul_assign(t0);

        // -2
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(two_fr);
        t2.mul_assign(t0);

        // -3
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(three_fr);
        t2.mul_assign(t0);

        t2.mul_assign(current_alpha);

        res.add_assign(t2);

        return res;
    }

    function reconstruct_linearization_commitment(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^{6} * (selector(x) - selector(z))
        // + v^{7..9} * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^10 (z(x) - z(z*omega)) <- we need this power
        // + v^11 * (d(x) - d(z*omega))
        // ]
        //

        // we reconstruct linearization polynomial virtual selector
        // for that purpose we first linearize over main gate (over all it's selectors)
        // and multiply them by value(!) of the corresponding main gate selector
        res = PairingsBn254.copy_g1(vk.gate_setup_commitments[STATE_WIDTH + 1]); // index of q_const(x)

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            tmp_g1 = vk.gate_setup_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH + 2].point_mul(proof.wire_values_at_z_omega[0]); // index of q_d_next(x)
        res.point_add_assign(tmp_g1);

        // multiply by main gate selector(z)
        res.point_mul_assign(proof.gate_selector_values_at_z[0]); // these is only one explicitly opened selector

        PairingsBn254.Fr memory current_alpha = PairingsBn254.new_fr(ONE);

        // calculate scalar contribution from the range check gate
        tmp_fr = add_contribution_from_range_constraint_gates(state, proof, current_alpha);
        tmp_g1 = vk.gate_selector_commitments[1].point_mul(tmp_fr); // selector commitment for range constraint gate * scalar
        res.point_add_assign(tmp_g1);

        // proceed as normal to copy permutation
        current_alpha.mul_assign(state.alpha); // alpha^5

        PairingsBn254.Fr memory alpha_for_grand_product = PairingsBn254.copy(current_alpha);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.copy_permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.copy_permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(alpha_for_grand_product);

        // alpha^n & L_{0}(z), and we bump current_alpha
        current_alpha.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(current_alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        // prefactor for grand_product(x) is complete

        // add to the linearization a part from the term
        // - (a(z) + beta*perm_a + gamma)*()*()*z(z*omega) * beta * perm_d(X)
        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.copy_grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(alpha_for_grand_product); // we multiply by the power of alpha from the argument

        // actually multiply prefactors by z(x) and perm_d(x) and combine them
        tmp_g1 = proof.copy_permutation_grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.copy_permutation_commitments[STATE_WIDTH - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        // multiply them by v immedately as linearization has a factor of v^1
        res.point_mul_assign(state.v);
        // res now contains contribution from the gates linearization and
        // copy permutation part

        // now we need to add a part that is the rest
        // for z(x*omega):
        // - (a(z) + beta*perm_a + gamma)*()*()*(d(z) + gamma) * z(x*omega)
    }

    function aggregate_commitments(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point[2] memory res) {
        PairingsBn254.G1Point memory d = reconstruct_linearization_commitment(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < NUM_GATE_SELECTORS_OPENED_EXPLICITLY; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.gate_selector_commitments[0].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < vk.copy_permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.copy_permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        // now do prefactor for grand_product(x*omega)
        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        commitment_aggregation.point_add_assign(proof.copy_permutation_grand_product_commitment.point_mul(tmp_fr));

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_fr.assign(proof.gate_selector_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.copy_grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        res[0] = pair_with_generator;
        res[1] = pair_with_x;

        return res;
    }

    function verify_initial(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.copy_permutation_grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        transcript.update_with_fr(proof.gate_selector_values_at_z[0]);

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.copy_grand_product_at_z_omega);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function aggregate_for_verification(Proof memory proof, VerificationKey memory vk)
        internal
        view
        returns (bool valid, PairingsBn254.G1Point[2] memory part)
    {
        PartialVerifierState memory state;

        valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return (valid, part);
        }

        part = aggregate_commitments(state, proof, vk);

        (valid, part);
    }

    function verify(Proof memory proof, VerificationKey memory vk) internal view returns (bool) {
        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        valid = PairingsBn254.pairingProd2(
            recursive_proof_part[0],
            PairingsBn254.P2(),
            recursive_proof_part[1],
            vk.g2_x
        );

        return valid;
    }

    function verify_recursive(
        Proof memory proof,
        VerificationKey memory vk,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs
    ) internal view returns (bool) {
        (uint256 recursive_input, PairingsBn254.G1Point[2] memory aggregated_g1s) =
            reconstruct_recursive_public_input(
                recursive_vks_root,
                max_valid_index,
                recursive_vks_indexes,
                individual_vks_inputs,
                subproofs_limbs
            );

        assert(recursive_input == proof.input_values[0]);

        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        // aggregated_g1s = inner
        // recursive_proof_part = outer
        PairingsBn254.G1Point[2] memory combined = combine_inner_and_outer(aggregated_g1s, recursive_proof_part);

        valid = PairingsBn254.pairingProd2(combined[0], PairingsBn254.P2(), combined[1], vk.g2_x);

        return valid;
    }

    function combine_inner_and_outer(PairingsBn254.G1Point[2] memory inner, PairingsBn254.G1Point[2] memory outer)
        internal
        view
        returns (PairingsBn254.G1Point[2] memory result)
    {
        // reuse the transcript primitive
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        transcript.update_with_g1(inner[0]);
        transcript.update_with_g1(inner[1]);
        transcript.update_with_g1(outer[0]);
        transcript.update_with_g1(outer[1]);
        PairingsBn254.Fr memory challenge = transcript.get_challenge();
        // 1 * inner + challenge * outer
        result[0] = PairingsBn254.copy_g1(inner[0]);
        result[1] = PairingsBn254.copy_g1(inner[1]);
        PairingsBn254.G1Point memory tmp = outer[0].point_mul(challenge);
        result[0].point_add_assign(tmp);
        tmp = outer[1].point_mul(challenge);
        result[1].point_add_assign(tmp);

        return result;
    }

    function reconstruct_recursive_public_input(
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_aggregated
    ) internal pure returns (uint256 recursive_input, PairingsBn254.G1Point[2] memory reconstructed_g1s) {
        assert(recursive_vks_indexes.length == individual_vks_inputs.length);
        bytes memory concatenated = abi.encodePacked(recursive_vks_root);
        uint8 index;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            index = recursive_vks_indexes[i];
            assert(index <= max_valid_index);
            concatenated = abi.encodePacked(concatenated, index);
        }
        uint256 input;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            input = individual_vks_inputs[i];
            assert(input < r_mod);
            concatenated = abi.encodePacked(concatenated, input);
        }

        concatenated = abi.encodePacked(concatenated, subproofs_aggregated);

        bytes32 commitment = sha256(concatenated);
        recursive_input = uint256(commitment) & RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK;

        reconstructed_g1s[0] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[0] +
                (subproofs_aggregated[1] << LIMB_WIDTH) +
                (subproofs_aggregated[2] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[3] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[4] +
                (subproofs_aggregated[5] << LIMB_WIDTH) +
                (subproofs_aggregated[6] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[7] << (3 * LIMB_WIDTH))
        );

        reconstructed_g1s[1] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[8] +
                (subproofs_aggregated[9] << LIMB_WIDTH) +
                (subproofs_aggregated[10] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[11] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[12] +
                (subproofs_aggregated[13] << LIMB_WIDTH) +
                (subproofs_aggregated[14] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[15] << (3 * LIMB_WIDTH))
        );

        return (recursive_input, reconstructed_g1s);
    }
}

contract VerifierWithDeserialize is Plonk4VerifierWithAccessToDNext {
    uint256 constant SERIALIZED_PROOF_LENGTH = 34;

    function deserialize_proof(uint256[] memory public_inputs, uint256[] memory serialized_proof)
        internal
        pure
        returns (Proof memory proof)
    {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);

            j += 2;
        }

        proof.copy_permutation_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j + 1]
        );
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            proof.gate_selector_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.copy_grand_product_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
    }

    function verify_serialized_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify(proof, vk);

        return valid;
    }

    function verify_serialized_proof_with_recursion(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid =
            verify_recursive(
                proof,
                vk,
                recursive_vks_root,
                max_valid_index,
                recursive_vks_indexes,
                individual_vks_inputs,
                subproofs_limbs
            );

        return valid;
    }
}

contract Plonk4VerifierWithAccessToDNextOld {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant STATE_WIDTH_OLD = 4;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD = 1;

    struct VerificationKeyOld {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[STATE_WIDTH_OLD + 2] selector_commitments; // STATE_WIDTH for witness + multiplication + constant
        PairingsBn254.G1Point[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD] next_step_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH_OLD - 1] permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct ProofOld {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] wire_commitments;
        PairingsBn254.G1Point grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH_OLD] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD] wire_values_at_z_omega;
        PairingsBn254.Fr grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH_OLD - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierStateOld {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain_old(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain_old(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length - 1; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(dens[i]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            dens[i].assign(tmp_2); // all inversed
            dens[i].mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing_old(uint256 domain_size, PairingsBn254.Fr memory at)
        internal
        view
        returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing_old(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            rhs.add_assign(tmp);
        }

        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH_OLD - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function reconstruct_d(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^(6..8) * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^9 (z(x) - z(z*omega)) <- we need this power
        // + v^10 * (d(x) - d(z*omega))
        // ]
        //
        // we pay a little for a few arithmetic operations to not introduce another constant
        uint256 power_for_z_omega_opening = 1 + 1 + STATE_WIDTH_OLD + STATE_WIDTH_OLD - 1;
        res = PairingsBn254.copy_g1(vk.selector_commitments[STATE_WIDTH_OLD + 1]);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            tmp_g1 = vk.selector_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.selector_commitments[STATE_WIDTH_OLD].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.next_step_selector_commitments[0].point_mul(proof.wire_values_at_z_omega[0]);
        res.point_add_assign(tmp_g1);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(state.alpha);
        tmp_fr.mul_assign(state.alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        PairingsBn254.Fr memory grand_product_part_at_z_omega = state.v.pow(power_for_z_omega_opening);
        grand_product_part_at_z_omega.mul_assign(state.u);

        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(state.alpha);

        // add to the linearization
        tmp_g1 = proof.grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.permutation_commitments[STATE_WIDTH_OLD - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        res.point_mul_assign(state.v);

        res.point_add_assign(proof.grand_product_commitment.point_mul(grand_product_part_at_z_omega));
    }

    function verify_commitments(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        PairingsBn254.G1Point memory d = reconstruct_d(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < vk.permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH_OLD - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        return PairingsBn254.pairingProd2(pair_with_generator, PairingsBn254.P2(), pair_with_x, vk.g2_x);
    }

    function verify_initial(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain_old(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);
        transcript.update_with_fr(proof.grand_product_at_z_omega);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function verify_old(ProofOld memory proof, VerificationKeyOld memory vk) internal view returns (bool) {
        PartialVerifierStateOld memory state;

        bool valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return false;
        }

        valid = verify_commitments(state, proof, vk);

        return valid;
    }
}

contract VerifierWithDeserializeOld is Plonk4VerifierWithAccessToDNextOld {
    uint256 constant SERIALIZED_PROOF_LENGTH_OLD = 33;

    function deserialize_proof_old(uint256[] memory public_inputs, uint256[] memory serialized_proof)
        internal
        pure
        returns (ProofOld memory proof)
    {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH_OLD);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);

            j += 2;
        }

        proof.grand_product_commitment = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.grand_product_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable contract
/// @author Matter Labs
interface Upgradeable {
    /// @notice Upgrades target of upgradeable contract
    /// @param newTarget New target
    /// @param newTargetInitializationParameters New target initialization parameters
    function upgradeTarget(address newTarget, bytes calldata newTargetInitializationParameters) external;
}

