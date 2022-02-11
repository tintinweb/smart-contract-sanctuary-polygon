// SPDX-License-Identifier: BUSL-1.1
// License details specified at address returned by calling the function: license()
pragma solidity =0.8.11;

/**
 @title Stakers contract for the Living Assets Platform
 @author Freeverse.io, www.freeverse.io
 @dev Manages Stakers and their deposits. Agnostic of the logic behind.
 @dev All source of truth regarding updates & challenges comes from the LogicOwner contract
 @dev This contract's convention: prepend _ to function inputs only.
*/

import "../interfaces/IStakers.sol";
import "../interfaces/IStorageGetters.sol";

contract Stakers is IStakers {
    /// @inheritdoc IStakers
    address public sto;
    /// @inheritdoc IStakers
    mapping(address => bool) public isStaker;
    /// @inheritdoc IStakers
    mapping(address => bool) public isSlashed;
    /// @inheritdoc IStakers
    mapping(address => bool) public isTrustedParty;
    /// @inheritdoc IStakers
    mapping(address => uint256) public stakes;
    /// @inheritdoc IStakers
    mapping(address => uint256) public pendingWithdrawals;
    /// @inheritdoc IStakers
    mapping(address => uint256) public nUpdates;

    /// @inheritdoc IStakers
    uint256 public nStakers;
    /// @inheritdoc IStakers
    uint256 public requiredStake;
    /// @inheritdoc IStakers
    uint256 public potBalance;
    /// @inheritdoc IStakers
    uint256 public totalNumUpdates;
    /// @inheritdoc IStakers
    address[] public toBeRewarded;
    /// @inheritdoc IStakers
    address[] public updaters;

    // Permission handling

    modifier onlyLogicOwner() {
        require(
            IStorageGetters(sto).writer() == msg.sender,
            "Only logicOwner can call this function."
        );
        _;
    }

    modifier onlySuperUser() {
        require(
            IStorageGetters(sto).superUser() == msg.sender,
            "Only superuser can call this function."
        );
        _;
    }

    constructor(address _storageAddress, uint256 _stake) {
        sto = _storageAddress;
        requiredStake = _stake;
    }

    /// @inheritdoc IStakers
    function license() external view returns (string memory) {
        return IStorageGetters(sto).license();
    }

    /**
     @notice Distributes rewards proportionally to updates made
     */
    function executeReward() external onlySuperUser {
        require(
            toBeRewarded.length > 0,
            "failed to execute rewards: empty array"
        );
        require(totalNumUpdates > 0, "failed to execute rewards: no updates");
        require(
            potBalance >= toBeRewarded.length,
            "failed to execute rewards: Not enough balance to share"
        );
        for (uint256 i = 0; i < toBeRewarded.length; i++) {
            address who = toBeRewarded[i];
            // better to multiply, and then divide, each time, to minimize rounding errors.
            pendingWithdrawals[who] +=
                (potBalance * nUpdates[who]) /
                totalNumUpdates;
            nUpdates[who] = 0;
        }
        delete toBeRewarded;
        potBalance = 0; // there could be a negligible loss of funds in the Pot.
        totalNumUpdates = 0;
        emit RewardsExecuted();
    }

    /// @inheritdoc IStakers
    function withdraw() external {
        // no need to require(isStaker[msg.sender], "failed to withdraw: staker not registered");
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "nothing to withdraw by this msg.sender");
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /**
     @notice Adds address to list of trusted parties
     @param _staker the address to be added
     */
    function addTrustedParty(address _staker) external onlySuperUser {
        assertGoodCandidate(msg.sender);
        require(
            !isTrustedParty[_staker],
            "trying to add a trusted party that is already trusted"
        );
        isTrustedParty[_staker] = true;
        emit AddedTrustedParty(_staker);
    }

    /**
     @notice Removes address from list of trusted parties
     @dev Address cannot be a staker
     @param _addr the address to be added
     */
    function removeTrustedParty(address _addr) external onlySuperUser {
        require(
            isTrustedParty[_addr] == true,
            "failed to removeTrustedPary: address not in list of trusted parties"
        );
        require(
            !isStaker[_addr],
            "failed to removeTrustedPary: cannot remove a trusted party that is still a staker"
        );
        isTrustedParty[_addr] = false;
        emit RemovedTrustedParty(_addr);
    }

    /// @inheritdoc IStakers
    function enrol() external payable {
        assertGoodCandidate(msg.sender);
        require(
            msg.value == requiredStake,
            "failed to enrol: wrong stake amount"
        );
        require(
            isTrustedParty[msg.sender],
            "failed to enrol: staker is not trusted party"
        );
        require(addStaker(msg.sender), "failed to enrol: cannot add staker");
        stakes[msg.sender] = msg.value;
        emit NewEnrol(msg.sender);
    }

    /// @inheritdoc IStakers
    function unEnroll() external {
        require(
            !alreadyDidUpdate(msg.sender),
            "failed to unenroll: staker currently updating"
        );
        require(removeStaker(msg.sender), "failed to unenroll");
        uint256 amount = pendingWithdrawals[msg.sender] + stakes[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        stakes[msg.sender] = 0;
        if (amount > 0) {
            payable(msg.sender).transfer(amount);
        }
        emit NewUnenrol(msg.sender);
    }

    /// @inheritdoc IStakers
    function addChallenge(uint16 _level, address _staker)
        external
        onlyLogicOwner
    {
        require(_level <= level(), "failed to update: wrong level");
        while (_level < level()) {
            // If level is below current, it means the challenge
            // period has passed, so last updater told the truth.
            // The last updater should be rewarded, the one before
            // last should be slashed and level moves back two positions
            require(
                (level() - _level) % 2 == 0,
                "failed to update: resolving wrong level"
            );
            resolve();
        }
        // note: these two following checks must done after resolving previous levels,
        // ...so that if this staker had previously done a successful challenge, he's not banned from participating again
        require(isStaker[_staker], "failed to update: staker not registered");
        require(
            !alreadyDidUpdate(_staker),
            "staker has already challenged this update before"
        );
        updaters.push(_staker);
        emit NewLevel(level());
    }

    /// @inheritdoc IStakers
    function resolveToLevel(uint16 _level) external onlyLogicOwner {
        require(
            (_level + 2) <= level(),
            "failed to resolveToLevel: wrong level"
        );
        while (_level < level()) {
            // If level is below current, it means the challenge
            // period has passed, so last updater told the truth.
            // The last updater should be rewarded, the one before
            // last should be slashed and level moves back two positions
            require(
                (level() - _level) % 2 == 0,
                "failed to update: resolving wrong level"
            );
            resolve();
        }
        emit NewLevel(level());
    }

    /// @inheritdoc IStakers
    function rewindToLevel(uint16 _level) external onlyLogicOwner {
        require(_level < level(), "failed to rewindToLevel: wrong level");
        while (_level < level()) {
            rewind();
        }
        emit NewLevel(level());
    }

    /// @inheritdoc IStakers
    function finalize() external onlyLogicOwner {
        require(level() > 0, "failed to finalize: wrong level");
        while (level() > 1) {
            resolve();
        }
        if (level() == 1) {
            addRewardToUpdater(popUpdaters());
        }
        require(
            level() == 0,
            "failed to finalize: no updaters should have been left"
        );
        emit FinalizedLogicRound();
    }

    /// @inheritdoc IStakers
    function addRewardToPot() external payable {
        require(msg.value > 0, "failed to add reward of zero");
        potBalance += msg.value;
        emit PotBalanceChange(potBalance);
    }

    // Private Functions

    function addStaker(address _staker) private returns (bool) {
        if (_staker == address(0x0)) return false; // prevent null addr
        if (isStaker[_staker]) return false; // staker already registered
        isStaker[_staker] = true;
        nStakers++;
        return true;
    }

    /**
     @dev a staker can only be removed via slash,
     or via explicitly sending the tx from his address
     */
    function removeStaker(address _staker) private returns (bool) {
        if (_staker == address(0x0)) return false; // prevent null addr
        if (!isStaker[_staker]) return false; // staker not registered
        isStaker[_staker] = false;
        nStakers--;
        return true;
    }

    function resolve() private {
        address goodStaker = popUpdaters();
        address badStaker = popUpdaters();
        earnStake(goodStaker, badStaker);
        slash(badStaker);
    }

    function rewind() private {
        popUpdaters();
    }

    function slash(address _staker) private {
        require(removeStaker(_staker), "failed to slash: staker not found");
        isSlashed[_staker] = true;
    }

    /**
     @dev the slashed stake goes into the "pendingWithdrawals" of the good staker,  
     not to his "stake". This way, he can cash it without unenrolling.  
     */
    function earnStake(address _goodStaker, address _badStaker) private {
        uint256 amount = stakes[_badStaker];
        stakes[_badStaker] = 0;
        pendingWithdrawals[_goodStaker] += amount;
        emit SlashedBy(_badStaker, _goodStaker);
    }

    function addRewardToUpdater(address _addr) private {
        if (nUpdates[_addr] == 0) {
            toBeRewarded.push(_addr);
        }
        nUpdates[_addr] += 1;
        totalNumUpdates++;
        emit AddedRewardToUpdater(_addr);
    }

    function popUpdaters() private returns (address _address) {
        uint256 updatersLength = updaters.length;
        require(updatersLength > 0, "cannot pop from an empty AddressStack");
        _address = updaters[updatersLength - 1];
        updaters.pop();
    }

    // View Functions

    /// @inheritdoc IStakers
    function alreadyDidUpdate(address _address) public view returns (bool) {
        for (uint256 i = 0; i < updaters.length; i++) {
            if (updaters[i] == _address) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IStakers
    function level() public view returns (uint16) {
        return uint16(updaters.length);
    }

    /// @inheritdoc IStakers
    function assertGoodCandidate(address _addr) public view {
        require(_addr != address(0x0), "candidate is null addr");
        require(!isSlashed[_addr], "candidate was slashed previously");
        require(stakes[_addr] == 0, "candidate already has a stake");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to the main storage getters
 @author Freeverse.io, www.freeverse.io
*/

interface IStorageGetters {
    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    // UNIVERSE GETTERS

    /**
     * @notice Returns the owner of a universe
     * @param universeIdx The idx of the universe
     * @return The address of the owner
     */
    function universeOwner(uint256 universeIdx) external view returns (address);

    /**
     * @notice Returns the name of a universe
     * @param universeIdx The idx of the universe
     * @return The name of the universe
     */
    function universeName(uint256 universeIdx)
        external
        view
        returns (string memory);

    /**
     * @notice Returns whether owner of a universe authorizes the default relayer
     * @param universeIdx The idx of the universe
     * @return Returns true if owner of a universe authorizes the default relayer
     */
    function universeAuthorizesRelay(uint256 universeIdx)
        external
        view
        returns (bool);

    /**
     * @notice Returns the current verse at which a universe is
     * @param universeIdx The idx of the universe
     * @return The verse
     */
    function universeVerse(uint256 universeIdx) external view returns (uint256);

    /**
     * @notice Returns the root of a universe at the provided verse
     * @param universeIdx The idx of the universe
     * @param verse The verse queried
     * @return The root of the universe at the provided verse
     */
    function universeRootAtVerse(uint256 universeIdx, uint256 verse)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns current root of a universe
     * @param universeIdx The idx of the universe
     * @return The root of the universe at the current verse
     */
    function universeRootCurrent(uint256 universeIdx)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the number of universes created
     * @return The number of universes created
     */
    function nUniverses() external view returns (uint256);

    /**
     * @notice Returns the submission time of a universe root at the
     * provided verse
     * @param universeIdx The idx of the universe
     * @param verse The verse queried
     * @return The submission time
     */
    function universeRootSubmissionTimeAtVerse(
        uint256 universeIdx,
        uint256 verse
    ) external view returns (uint256);

    /**
     * @notice Returns the submission time of the current universe root
     * @param universeIdx The idx of the universe
     * @return The submission time
     */
    function universeRootSubmissionTimeCurrent(uint256 universeIdx)
        external
        view
        returns (uint256);

    /**
     * @notice Returns true if the universe if closed
     * @param universeIdx The idx of the universe
     * @return Returns true if it is closed
     */
    function universeIsClosed(uint256 universeIdx) external view returns (bool);

    /**
     * @notice Returns true if the universe has its closure requested
     * @param universeIdx The idx of the universe
     * @return Returns true if it has its closure requested
     */
    function universeIsClosureRequested(uint256 universeIdx)
        external
        view
        returns (bool);

    // OWNERSHIP GETTERS

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root that is currently set as default for next verses
     * @return the amount of time allowed for challenging
     */
    function challengeWindowNextVerses() external view returns (uint256);

    /**
     * @notice Returns the number of levels contained in each challenge
     * set as default for next verses
     * @return the number of levels contained in each challenge
     */
    function nLevelsPerChallengeNextVerses() external view returns (uint8);

    /**
     * @notice Returns the maximum time since the production of the last
     * verse beyond which assets can be exported without new verses being produced
     * @return the maximum time
     */
    function maxTimeWithoutVerseProduction() external view returns (uint256);

    /**
     * @notice Returns information about possible export requests about the provided asset
     * @param assetId The id of the asset
     * @return owner The owner that requested the asset export
     * @return requestVerse The TX verse at which the export request was received
     * @return completedVerse The TX verse at which the export process was completed (0 if not completed)
     */
    function exportRequestInfo(uint256 assetId)
        external
        view
        returns (
            address owner,
            uint256 requestVerse,
            uint256 completedVerse
        );

    /**
     * @notice Returns the owner that requested the asset export
     * @param assetId The id of the asset
     * @return owner The owner that requested the asset export
     */
    function exportOwner(uint256 assetId) external view returns (address owner);

    /**
     * @notice Returns the TX verse at which the export request was received
     * @param assetId The id of the asset
     * @return requestVerse The TX verse at which the export request was received
     */
    function exportRequestVerse(uint256 assetId)
        external
        view
        returns (uint256 requestVerse);

    /**
     * @notice Returns the TX verse at which the export process was completed (0 if not completed)
     * @param assetId The id of the asset
     * @return completedVerse The TX verse at which the export process was completed (0 if not completed)
     */
    function exportCompletedVerse(uint256 assetId)
        external
        view
        returns (uint256 completedVerse);

    /**
     * @notice Returns the length of the ownership root array
     * @return the length of the ownership root array
     */
    function ownershipCurrentVerse() external view returns (uint256);

    /**
     * @notice Returns the length of the TXs root array
     * @return the length of the TXs root array
     */
    function txRootsCurrentVerse() external view returns (uint256);

    /**
     * @notice Returns the reference verse used in the computation of
     * the time planned for the submission of a TX batch for a given verse
     * @return The reference verse
     */
    function referenceVerse() external view returns (uint256);

    /**
     * @notice Returns the timestamp at which the reference verse took
     * place used, in the computation of the time planned for
     * the submission of a TX batch for a given verse
     * @return The timestamp at which the reference verse took place
     */
    function referenceTime() external view returns (uint256);

    /**
     * @notice Returns the seconds between txVerses between TX batch
     * submissions, used in the computation of the time planned for
     * each submission
     * @return The seconds between txVerses
     */
    function verseInterval() external view returns (uint256);

    /**
     * @notice Returns the ownership root at the provided verse
     * @param verse The verse queried
     * @return The ownership root at the provided verse
     */
    function ownershipRootAtVerse(uint256 verse)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the TX root at the provided verse
     * @param verse The verse queried
     * @return The TX root at the provided verse
     */
    function txRootAtVerse(uint256 verse) external view returns (bytes32);

    /**
     * @notice Returns the number of levels contained in each challenge
     * at the provided verse
     * @param verse The verse queried
     * @return The TX root at the provided verse
     */
    function nLevelsPerChallengeAtVerse(uint256 verse)
        external
        view
        returns (uint8);

    /**
     * @notice Returns the challenge level verifiable on chain
     * at the provided verse
     * @param verse The verse queried
     * @return The level verifiable on chain
     */
    function levelVerifiableOnChainAtVerse(uint256 verse)
        external
        view
        returns (uint8);

    /**
     * @notice Returns the number of TXs included in the batch at
     * the provided verse
     * @param verse The verse queried
     * @return The number of TXs included in the batch
     */
    function nTXsAtVerse(uint256 verse) external view returns (uint256);

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root at the provided verse
     * @param verse The verse queried
     * @return the amount of time allowed for challenging
     */
    function challengeWindowAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the submission time of the TX batch
     * at the provided verse
     * @param verse The verse queried
     * @return the submission time of the TX batch
     */
    function txSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the submission time of the Ownership root
     * at the provided verse
     * @param verse The verse queried
     * @return the submission time of the Ownership root
     */
    function ownershipSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the last entry of the ownership root array
     * @return the last entry of the ownership root array
     */
    function ownershipRootCurrent() external view returns (bytes32);

    /**
     * @notice Returns the last entry of the TXs root array
     * @return the last entry of the TXs root array
     */
    function txRootCurrent() external view returns (bytes32);

    /**
     * @notice Returns the number of levels contained in each challenge
     * in the current verse
     * @return the number of levels contained in each challenge
     */
    function nLevelsPerChallengeCurrent() external view returns (uint8);

    /**
     * @notice Returns the challenge level verifiable on chain
     * in the current verse
     * @return The level verifiable on chain
     */
    function levelVerifiableOnChainCurrent() external view returns (uint8);

    /**
     * @notice Returns the number of TXs included in the batch
     * in the current verse
     * @return The number of TXs included in the batch
     */
    function nTXsCurrent() external view returns (uint256);

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root in the current verse
     * @return the amount of time allowed for challenging
     */
    function challengeWindowCurrent() external view returns (uint256);

    /**
     * @notice Returns the submission time of the TX batch
     * in the current verse
     * @return the submission time of the TX batch
     */
    function txSubmissionTimeCurrent() external view returns (uint256);

    /**
     * @notice Returns the submission time of the Ownership root
     * in the current verse
     * @return the submission time of the Ownership root
     */
    function ownershipSubmissionTimeCurrent() external view returns (uint256);

    // CHALLENGES GETTERS

    /**
     * @notice Returns the ownership root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesOwnershipRoot(uint8 level)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the transitions root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesTransitionsRoot(uint8 level)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the edge-root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesRootAtEdge(uint8 level) external view returns (bytes32);

    /**
     * @notice Returns the position stored at the provided challenge level
     * @param level The queried challenge level
     * @return the position
     */
    function challengesPos(uint8 level) external view returns (uint256);

    /**
     * @notice Returns the level stored in the current challenge process
     * @return the level
     */
    function challengesLevel() external view returns (uint8);

    /**
     * @notice Returns true if all positions stored in the current
     * challenge process are zero
     * @return Returns true if all positions are zero
     */
    function areAllChallengePosZero() external view returns (bool);

    /**
     * @notice Returns number of leaves contained in each challenge
     * in the current verse
     * @return Returns true if all positions are zero
     */
    function nLeavesPerChallengeCurrent() external view returns (uint256);

    /**
     * @notice Returns the position of the leaf at the bottom level
     * of the current challenge process
     * @return bottomLevelLeafPos The position of the leaf
     */
    function computeBottomLevelLeafPos(uint256)
        external
        view
        returns (uint256 bottomLevelLeafPos);

    // ROLES GETTERS

    /**
     * @notice Returns the address with company authorization
     */
    function company() external view returns (address);

    /**
     * @notice Returns the address proposed for company authorization
     */
    function proposedCompany() external view returns (address);

    /**
     * @notice Returns the address with super user authorization
     */
    function superUser() external view returns (address);

    /**
     * @notice Returns the address with universe-roots relayer authorization
     */
    function universesRelayer() external view returns (address);

    /**
     * @notice Returns the address with TX Batch relayer authorization
     */
    function txRelayer() external view returns (address);

    /**
     * @notice Returns the address of the Stakers contract
     */
    function stakers() external view returns (address);

    /**
     * @notice Returns the address of the Writer contract
     */
    function writer() external view returns (address);

    /**
     * @notice Returns the address of the Directory contract
     */
    function directory() external view returns (address);

    /**
     * @notice Returns the address of the NFT contract where
     * assets are minted when exported
     */
    function externalNFTContract() external view returns (address);

    /**
     * @notice Returns the address of the Assets Exporter contract
     */
    function assetExporter() external view returns (address);

    // CLAIMS GETTERS

    /**
     * @notice Returns the (verse, value) pair of the provided key
     * in the provided claim
     * @param claimIdx The Idx that identifies claim
     * @param key The key queried the claim
     * @return verse The verse at which the key was set
     * @return value The value that corresponds to the key
     */
    function claim(uint256 claimIdx, uint256 key)
        external
        view
        returns (uint256 verse, string memory value);

    /**
     * @notice Returns the number of Claims created
     * @return the number of Claims created
     */
    function nClaims() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract that Manages Stakers and their deposits. 
 @author Freeverse.io, www.freeverse.io
*/

interface IStakers {
    event PotBalanceChange(uint256 newBalance);
    event RewardsExecuted();
    event AddedTrustedParty(address indexed party);
    event RemovedTrustedParty(address indexed party);
    event NewEnrol(address indexed staker);
    event NewUnenrol(address indexed staker);
    event SlashedBy(address indexed slashedStaker, address indexed goodStaker);
    event AddedRewardToUpdater(address indexed staker);
    event FinalizedLogicRound();
    event NewLevel(uint16 indexed level);

    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns address of the storage contract that
     * this contract is attached to.
     */
    function sto() external view returns (address);

    /**
     * @notice Returns true if the provided address is registered as staker.
     * @return whether the provided address is a staker
     */
    function isStaker(address) external view returns (bool);

    /**
     * @notice Returns true if the provided address is has been slashed.
     * @return whether the provided address has been slashed
     */
    function isSlashed(address) external view returns (bool);

    /**
     * @notice Returns true if the provided address is registered as trusted party.
     * @return whether the provided address is a trusted party
     */
    function isTrustedParty(address) external view returns (bool);

    /**
     * @notice Returns the amount staked by the provided address.
     * @return the amount staked by the provided address.
     */
    function stakes(address) external view returns (uint256);

    /**
     * @notice Returns the amount available for withdrawal
     * by the the provided address.
     * @return the amount available for withdrawal
     */
    function pendingWithdrawals(address) external view returns (uint256);

    /**
     * @notice Returns the number of updates performed
     * by the the provided address since the last event of
     * reward execution
     * @return the number of updates performed
     */
    function nUpdates(address) external view returns (uint256);

    /**
     * @notice Returns the number of registered stakers
     * @return the number of registered stakers
     */
    function nStakers() external view returns (uint256);

    /**
     * @notice Returns the stake amount required to join as staker
     * @return the stake amount required to join as staker
     */
    function requiredStake() external view returns (uint256);

    /**
     * @notice Returns the amount available in the pot
     * @return the amount available in the pot
     */
    function potBalance() external view returns (uint256);

    /**
     * @notice Returns total number of updates performed since
     * the last event of reward execution
     * @return the total number of updates performed
     */
    function totalNumUpdates() external view returns (uint256);

    /**
     * @notice Returns the address at the provided idx of the array of
     * stakers to be rewarded
     * @param idx The index in the array
     * @return the address of the staker to be rewarded at the idx provided
     */
    function toBeRewarded(uint256 idx) external view returns (address);

    /**
     * @notice Returns the address of the updater at the idx provided
     * @param idx The index in the array
     * @return the address of the updater at the idx provided
     */
    function updaters(uint256 idx) external view returns (address);

    /**
     * @notice Transfers pendingWithdrawals to the calling staker;
     * @dev the stake remains until unenrol is called
     */
    function withdraw() external;

    /**
     * @notice Reverts if the address does not fulfil the conditions
     * required to become a trusted party
     */
    function assertGoodCandidate(address _addr) external view;

    /**
     * @notice Registers a new staker
     * @dev Must be called by the candidate
     */
    function enrol() external payable;

    /**
     * @notice Unregisters a staker and transfers all earnings
     * @dev Must be called by the corresponding staker
     */
    function unEnroll() external;

    /**
     * @notice Update to a new level
     * @dev This function will also resolve previous updates when
     * level is below current or level has reached the end
     * Requiring that _staker is not slashed is already covered by not being part of stakers,
     * because slashing removes address from stakers
     * @param _level to which update
     * @param _staker address of the staker that reports this update
     */
    function addChallenge(uint16 _level, address _staker) external;

    /**
     * @notice Resolves a challenge at the provided level
     * @param _level at which we will end up, due to a level proven right,
     * and previous one proven wrong, possibly a few times.
     */
    function resolveToLevel(uint16 _level) external;

    /**
     * @notice Rewinds a challenge process to a previous level
     * @param _level at which we will end up, due to a challenge to a previously-challenged level.
     */
    function rewindToLevel(uint16 _level) external;

    /**
     * @notice Finalize current challenge process, get ready for next one.
     * @dev Current state will be resolved at this point.
     * If called from level 1, then staker is rewarded.
     * When called from any other level, means that every
     * other staker told the truth but the one in between lied.
     */
    function finalize() external;

    /**
     * @notice Adds funds to pot to be shared by stakers who update
     * @dev Any address can add funds
     */
    function addRewardToPot() external payable;

    /**
     * @notice Returns true if the provided address has already
     * performed an update in the current challenge
     * @return whether the provided address has already performed an update
     */
    function alreadyDidUpdate(address _address) external view returns (bool);

    /**
     * @notice Returns the level at which the challenge is
     * @return the level at which the challenge is
     */
    function level() external view returns (uint16);
}