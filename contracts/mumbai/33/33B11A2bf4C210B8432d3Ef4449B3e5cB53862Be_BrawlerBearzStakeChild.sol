// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20Rewards.sol";
import "./common/NativeMetaTransaction.sol";
import "./tunnel/FxBaseChildTunnel.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IBrawlerBearzStakeChild} from "./interfaces/IBrawlerBearzStakeChild.sol";
import {IBrawlerBearzStakeEvents} from "./interfaces/IBrawlerBearzStakeEvents.sol";
import {IBrawlerBearzQuesting} from "./interfaces/IBrawlerBearzQuesting.sol";
import {IBrawlerBearzQuestCommon} from "./interfaces/IBrawlerBearzQuestCommon.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzStakeChild
 * @author @ScottMitchell18
 **************************************************/

contract BrawlerBearzStakeChild is
    FxBaseChildTunnel,
    AccessControl,
    IBrawlerBearzStakeChild,
    IBrawlerBearzStakeEvents,
    IBrawlerBearzQuestCommon,
    NativeMetaTransaction,
    ReentrancyGuard
{
    /// @dev Sync actions
    bytes32 public constant STAKE = keccak256("STAKE");
    bytes32 public constant UNSTAKE = keccak256("UNSTAKE");
    bytes32 public constant XP_SYNC = keccak256("XP_SYNC");
    bytes32 public constant REWARDS_CLAIM = keccak256("REWARDS_CLAIM");

    /// @dev Reward types
    bytes32 public constant SHOP = keccak256(abi.encodePacked("SHOP"));
    bytes32 public constant CRAWLERZ = keccak256(abi.encodePacked("CRAWLERZ"));
    bytes32 public constant XP = keccak256(abi.encodePacked("XP"));
    bytes32 public constant CREDIT = keccak256(abi.encodePacked("CREDIT"));

    /// @dev Roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant YIELD_MANAGER = keccak256("YIELD_MANAGER");
    bytes32 public constant XP_MANAGER = keccak256("XP_MANAGER");
    bytes32 public constant QUEST_MANAGER = keccak256("QUEST_MANAGER");

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;

    /// @notice amount of token yield for a staked token earns per day
    uint256 public tokensPerYield = 5 ether;
    uint256 public yieldPeriod = 1 days;

    uint256 public trainingYieldPeriod = 1 days;
    uint256 public trainingYield = 1000;

    uint256 public questPrice = 20 ether;

    IERC20Rewards public rewardsToken;

    /// @dev Users' stakes mapped from their address
    mapping(address => Stake) public stakes;

    /// @dev Token id to xp tracking
    mapping(uint256 => TokenXP) public xpTracker;

    /// @dev Token id train tracking
    mapping(uint256 => Train) public training;

    /// @dev Address to reward items
    mapping(address => uint256[]) public rewardIds;

    /// @dev Contract for questing that we can upgrade if needed
    IBrawlerBearzQuesting public questContract;

    constructor(
        address _fxChild,
        address _tokenAddress,
        address _questContractAddress
    ) FxBaseChildTunnel(_fxChild) {
        rewardsToken = IERC20Rewards(_tokenAddress);
        // Setup access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(YIELD_MANAGER, _msgSender());
        _setupRole(XP_MANAGER, _msgSender());
        _setupRole(QUEST_MANAGER, _msgSender());
        // Setup questing contract
        questContract = IBrawlerBearzQuesting(_questContractAddress);
    }

    // ========================================
    // Management
    // ========================================

    /**
     * @notice MANUAL OVERRIDE - Set XP accumulation for a given token
     * @param _xp The xp to set
     */
    function setTokenXP(uint256 _tokenId, uint256 _xp)
        external
        onlyRole(XP_MANAGER)
    {
        xpTracker[_tokenId].xp = _xp;
        xpTracker[_tokenId].lastUpdatedAt = block.timestamp;
    }

    /**
     * @notice Updates the yield period
     * @param _yieldPeriod The time period in seconds for yield
     */
    function setYield(uint256 _yieldPeriod) external onlyRole(YIELD_MANAGER) {
        yieldPeriod = _yieldPeriod;
    }

    /**
     * @notice Sets the reward calculation schema.
     * @param _tokensPerYield - a list of held amounts in increasing order.
     */
    function setTokensPerYield(uint256 _tokensPerYield)
        public
        onlyRole(YIELD_MANAGER)
    {
        tokensPerYield = _tokensPerYield;
    }

    /**
     * @notice Sets the cost of a quest
     * @param _questPrice - The price to run a quest
     */
    function setQuestPrice(uint256 _questPrice) public onlyRole(YIELD_MANAGER) {
        questPrice = _questPrice;
    }

    /**
     * @notice Sets the reward calculation for the training per day
     * @param _trainingYield - the xp yield per day for training
     */
    function setTrainingYield(uint256 _trainingYield)
        public
        onlyRole(YIELD_MANAGER)
    {
        trainingYield = _trainingYield;
    }

    /**
     * @notice Updates the training yield period
     * @param _trainingYieldPeriod The time period in seconds for yield
     */
    function setTrainingYieldPeriod(uint256 _trainingYieldPeriod)
        external
        onlyRole(YIELD_MANAGER)
    {
        trainingYieldPeriod = _trainingYieldPeriod;
    }

    // ========================================
    // $CREDIT Claims
    // ========================================

    /// @notice Claims the $CREDIT reward for the transaction
    function claim() external nonReentrant {
        Stake storage stake = stakes[_msgSender()];
        uint256 reward = _calculateReward(stake);
        stake.claimedAt = block.timestamp;
        if (reward > 0) {
            if (!stake.hasClaimed) stake.hasClaimed = true;
            rewardsToken.mint(reward, _msgSender());
            emit RewardClaimed(_msgSender(), reward, stake.claimedAt);
        }
    }

    // ========================================
    // Training
    // ========================================

    /**
     * @notice Train a set of staked token ids
     * @param tokenIds the tokenIds to stake
     */
    function train(uint256[] calldata tokenIds) external {
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(isStakedByUser(_msgSender(), tokenId), "!staked");
            require(!isTraining(tokenId), "training");
            require(!isQuesting(tokenId), "questing");
            training[tokenId].startAt = block.timestamp;
            training[tokenId].endAt = 0;
            training[tokenId].xp = 0;
            emit TrainStart(tokenId, training[tokenId].startAt);
        }
    }

    /**
     * @notice Removes tokens from training
     * @param tokenIds the tokenIds to stake
     */
    function stopTraining(uint256[] calldata tokenIds) external {
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(isStakedByUser(_msgSender(), tokenId), "!staked");
            require(isTraining(tokenId), "!training");
            _resetTraining(tokenId);
        }
    }

    // ========================================
    // Questing
    // ========================================

    /**
     * @notice Quest a set of staked token ids
     * @param tokenIds the tokenIds to quest
     * @param questTypeIds the questTypeIds for quest
     * @param tokenAmount the tokenAmount
     */
    function quest(
        uint256[] calldata tokenIds,
        uint256[] calldata questTypeIds,
        uint256 tokenAmount
    ) external nonReentrant {
        require(
            tokenAmount >= questPrice * tokenIds.length,
            "Not enough token to go on quests"
        );
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(isStakedByUser(_msgSender(), tokenId), "!staked");
            require(!isTraining(tokenId), "training");
        }
        rewardsToken.burn(_msgSender(), tokenAmount);
        questContract.quest(tokenIds, questTypeIds);
    }

    /**
     * @notice Quest a set of staked token ids
     * @param tokenIds the tokenIds to stake
     */
    function endQuest(uint256[] calldata tokenIds) external nonReentrant {
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(isStakedByUser(_msgSender(), tokenId), "!staked");
        }
        questContract.endQuest(_msgSender(), tokenIds);
    }

    /**
     * @notice Sets/updates the address for questing contract
     * @param _questContractAddress - the quest contract address
     */
    function setQuestContract(address _questContractAddress)
        external
        onlyRole(QUEST_MANAGER)
    {
        questContract = IBrawlerBearzQuesting(_questContractAddress);
    }

    // ========================================
    // Read operations
    // ========================================

    /**
     * @notice Gets the pending reward for the provided user.
     * @param user - the user whose reward is being sought.
     */
    function getReward(address user) external view returns (uint256) {
        return _calculateReward(stakes[user]);
    }

    /**
     * @notice Gets the pending training XP for a token
     * @param tokenId - The token id of the item to look at pending XP
     */
    function getTrainingXP(uint256 tokenId) external view returns (uint256) {
        return _calculateXP(training[tokenId].startAt);
    }

    /**
     * @notice Gets the pending reward for a token
     * @param tokenId - The token id of the item to look at pending XP
     */
    function getXP(uint256 tokenId) external view returns (uint256) {
        return xpTracker[tokenId].xp;
    }

    /**
     * @notice Gets the xpTracker struct for a token id
     * @param tokenId - The token id of the item
     */
    function getXPData(uint256 tokenId) external view returns (TokenXP memory) {
        return xpTracker[tokenId];
    }

    /**
     * @notice Gets the trainings struct for a tokenId
     * @param tokenId - The token id of the item
     */
    function getTrainingData(uint256 tokenId)
        external
        view
        returns (Train memory)
    {
        Train storage instance = training[tokenId];
        return
            Train({
                xp: isTraining(tokenId) ? _calculateXP(instance.startAt) : 0,
                startAt: instance.startAt,
                endAt: instance.endAt
            });
    }

    /**
     * @notice Returns whether a token is training or not
     * @param tokenId - The nft token id
     */
    function isTraining(uint256 tokenId) public view returns (bool) {
        return training[tokenId].startAt > 0;
    }

    /**
     * @notice Returns whether a token is questing or not
     * @param tokenId - The nft token id
     */
    function isQuesting(uint256 tokenId) public view returns (bool) {
        return questContract.isQuesting(tokenId);
    }

    /**
     * @notice Tricks collab.land and other ERC721 balance checkers into believing that the user has a balance.
     * @dev a duplicate stakes(user).amount.
     * @param user - the user to get the balance of.
     */
    function balanceOf(address user) external view returns (uint256) {
        return stakes[user].amount;
    }

    /**
     * @dev Returns staked token ids
     * @param owner - address to lookup
     */
    function getStakedTokens(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return stakes[owner].tokenIds;
    }

    /**
     * Determines if a particular token is staked or not by a user
     * @param owner of token id
     * @param tokenId id of the token
     */
    function isStakedByUser(address owner, uint256 tokenId)
        internal
        returns (bool)
    {
        uint256 tokenIndex = findToken(owner, tokenId);
        return tokenIndex < stakes[owner].tokenIds.length;
    }

    // ========================================
    // Internals
    // ========================================

    /**
     * @dev To be called on stake/unstake, evaluates the user's current balance and resets any timers.
     * @param user - the user to update for.
     */
    function _updateBalance(address user) internal {
        Stake storage stake = stakes[user];
        uint256 reward = _calculateReward(stake);
        stake.claimedAt = block.timestamp;
        if (reward > 0) {
            if (!stake.hasClaimed) stake.hasClaimed = true;
            rewardsToken.mint(reward, user);
        }
    }

    /**
     * @dev Resets the training storage and xp tracker with latest
     * @param tokenId - the token id of an nft
     */
    function _resetTraining(uint256 tokenId) internal {
        uint256 originalStartAt = training[tokenId].startAt;
        uint256 gainedXP = _calculateXP(originalStartAt);
        xpTracker[tokenId].xp += gainedXP;
        training[tokenId].startAt = 0;
        training[tokenId].xp = 0;
        training[tokenId].endAt = block.timestamp;
        emit TrainEnd(tokenId, gainedXP, originalStartAt, block.timestamp);
    }

    /**
     * @dev Calculates the reward based
     * @param stake - the stake for the user to calculate upon.
     */
    function _calculateReward(Stake memory stake)
        internal
        view
        returns (uint256)
    {
        uint256 periodsPassed = (block.timestamp - stake.claimedAt) /
            yieldPeriod;
        return stake.amount * periodsPassed * tokensPerYield;
    }

    /**
     * @dev Calculates the training reward
     * @param timestamp - the timestamp to calculate from
     */
    function _calculateXP(uint256 timestamp) internal view returns (uint256) {
        if (timestamp == 0) return 0;
        uint256 periodsPassed = (block.timestamp - timestamp) /
            trainingYieldPeriod;
        return periodsPassed * trainingYield;
    }

    /**
     * @dev Stakes tokens by user and token id
     * @param user - a user address
     * @param tokenIds - a set of token ids
     */
    function _stake(address user, uint256[] memory tokenIds) internal {
        _updateBalance(user);
        stakes[user].amount += tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakes[user].tokenIds.push(tokenIds[i]);
        }
    }

    /**
     * @dev Updates the stake to represent new tokens, starts over the current period.
     * @param user - a user address
     * @param tokenIds - a set of token ids
     */
    function _unstake(address user, uint256[] memory tokenIds) internal {
        _updateBalance(user);
        stakes[user].amount -= tokenIds.length;
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(
                !isTraining(tokenId) && !isQuesting(tokenId),
                "training or questing"
            );
            removeTokenByValue(user, tokenId);
        }
    }

    // ========================================
    // Helpers
    // ========================================

    function findToken(address user, uint256 value) internal returns (uint256) {
        uint256 i = 0;
        while (stakes[user].tokenIds[i] != value) {
            i++;
        }
        return i;
    }

    function removeTokenByIndex(address user, uint256 i) internal {
        while (i < stakes[user].tokenIds.length - 1) {
            stakes[user].tokenIds[i] = stakes[user].tokenIds[i + 1];
            i++;
        }
    }

    function removeTokenByValue(address user, uint256 value) internal {
        uint256 i = findToken(user, value);
        removeTokenByIndex(user, i);
    }

    // ========================================
    // Portal integrations
    // ========================================

    /**
     * @notice Sets/updates the address for the root tunnel
     * @param _fxRootTunnel - the fxRootTunnel address
     */
    function setFxRootTunnel(address _fxRootTunnel)
        external
        override
        onlyRole(OWNER_ROLE)
    {
        fxRootTunnel = _fxRootTunnel;
    }

    /// @notice withdraw XP to source chain (ETH)
    function withdrawXP() external {
        uint256[] memory syncTokenIds = stakes[_msgSender()].tokenIds;
        uint256[] memory amounts = new uint256[](syncTokenIds.length);
        uint256 tokenId;
        for (uint256 i = 0; i < syncTokenIds.length; i++) {
            tokenId = syncTokenIds[i];
            amounts[i] = xpTracker[tokenId].xp;
            xpTracker[tokenId].xp = 0;
            xpTracker[tokenId].lastUpdatedAt = block.timestamp;
        }
        // Encode XP data to send to the root chain
        _sendMessageToRoot(
            abi.encode(XP_SYNC, abi.encode(syncTokenIds, amounts, true))
        );
    }

    /// @notice withdraws claimable rewards (ETH)
    function withdrawQuestRewards() external nonReentrant {
        Reward[] memory rewards = questContract.getClaimableRewards(
            _msgSender()
        );

        uint256 totalReward = 0 ether;
        address to = _msgSender();

        Reward memory currentReward;

        for (uint256 i = 0; i < rewards.length; i++) {
            currentReward = rewards[i];
            bytes32 rewardType = keccak256(
                abi.encodePacked(currentReward.typeOf)
            );

            if (XP == rewardType) {
                xpTracker[currentReward.tokenId].xp += currentReward.amount;
            } else if (CREDIT == rewardType) {
                totalReward += currentReward.amount * (1 ether); // tokenId is unused
            } else if (SHOP == rewardType || CRAWLERZ == rewardType) {
                rewardIds[to].push(currentReward.tokenId);
            }
        }

        if (totalReward > 0) {
            rewardsToken.mint(totalReward, to);
            emit RewardClaimed(to, totalReward, block.timestamp);
        }

        // Encode XP data to send to the root chain
        _sendMessageToRoot(
            abi.encode(REWARDS_CLAIM, abi.encode(to, rewardIds[to]))
        );

        // Clear out rewards on both sides address items
        questContract.emptyClaimableRewards(to);

        delete rewardIds[to];
    }

    /**
     * @notice Process message received from FxChild
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            message,
            (bytes32, bytes)
        );
        if (syncType == STAKE) {
            (address from, uint256[] memory tokenIds) = abi.decode(
                syncData,
                (address, uint256[])
            );
            _stake(from, tokenIds);
        } else if (syncType == UNSTAKE) {
            (address from, uint256[] memory tokenIds) = abi.decode(
                syncData,
                (address, uint256[])
            );
            _unstake(from, tokenIds);
        } else {
            revert("INVALID_SYNC_TYPE");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Rewards is IERC20 {
    /**
     * Mints to the given account from the sender provided the sender is authorized.
     */
    function mint(uint256 amount, address to) external;

    /**
     * Mints to the given accounts from the sender provided the sender is authorized.
     */
    function bulkMint(uint256[] calldata amounts, address[] calldata to)
        external;

    /**
     * Burns the given amount for the user provided the sender is authorized.
     */
    function burn(address from, uint256 amount) external;

    /**
     * Gets the amount of mints the user is entitled to.
     */
    function getMintAllowance(address user) external view returns (uint256);

    /**
     * Updates the allowance for the given user to mint. Set to zero to revoke.
     *
     * @dev This functionality programatically enables allowing other platforms to
     *      distribute the token on our behalf.
     */
    function updateMintAllowance(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(
            fxRootTunnel == address(0x0),
            "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET"
        );
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzStakeChild {
    struct Stake {
        uint256 amount;
        uint256 claimedAt;
        uint256[] tokenIds;
        bool hasClaimed;
    }

    struct TokenXP {
        uint256 xp;
        uint256 lastUpdatedAt;
    }

    struct Train {
        uint256 xp;
        uint256 startAt;
        uint256 endAt;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzStakeEvents {
    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event TrainStart(uint256 tokenId, uint256 startAt);

    event TrainEnd(
        uint256 tokenId,
        uint256 xpReward,
        uint256 startAt,
        uint256 endAt
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBrawlerBearzQuestCommon} from "./IBrawlerBearzQuestCommon.sol";

interface IBrawlerBearzQuesting is IBrawlerBearzQuestCommon {
    function quest(uint256[] calldata tokenIds, uint256[] calldata questTypeIds)
        external;

    function endQuest(address _address, uint256[] calldata tokenIds) external;

    function emptyClaimableRewards(address _address) external;

    function getAllQuests() external view returns (QuestMetadata[] memory);

    function getActiveQuests() external view returns (QuestMetadata[] memory);

    function getClaimableRewards(address _address)
        external
        view
        returns (Reward[] memory);

    function addQuest(QuestMetadata calldata addQuest) external;

    function updateQuest(QuestMetadata calldata updateQuest) external;

    function setQuestIsActive(uint256 questId, bool isActive) external;

    function getQuestData(uint256 tokenId) external view returns (Quest memory);

    function isQuesting(uint256 tokenId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzQuestCommon {
    struct Reward {
        uint256 tokenId;
        uint256 amount;
        string typeOf;
    }

    struct QuestMetadata {
        uint256 questId;
        string questType;
        string name;
        string description;
        bool isActive;
        bool canDropItems;
        bool canFindCrawlerz;
        uint256 duration;
        uint256 maxCredits;
        uint256 maxXP;
    }

    struct Quest {
        uint256 questId;
        uint256 xp;
        uint256 startAt;
        uint256 endAt;
        uint256 seed;
    }

    event QuestStart(
        uint256 tokenId,
        uint256 questId,
        string name,
        uint256 startAt,
        uint256 endAt,
        uint256 seed
    );

    event QuestEnd(
        uint256 tokenId,
        uint256 questId,
        string name,
        uint256 duration,
        uint256 endAt,
        uint256 xpReward,
        uint256 creditReward,
        uint256 itemIdFound,
        uint256 crawlerzIdFound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

contract Initializable {
    bool inited;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
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