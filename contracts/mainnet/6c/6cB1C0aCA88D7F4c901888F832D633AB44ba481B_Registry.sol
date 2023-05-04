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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IAllocationManager is IERC165Upgradeable {
    /**
     * @dev Emitted when a new voting manager contract address
     * 'votingManager' is set.
     */
    event VotingManagerSet(address votingManager);

    /**
     * @dev Sets a new `votingManager` contract address.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingManager(address votingManager) external;

    /**
     * @dev Returns the allocation rate of total rewards for a given
     * consumption `rate`.
     */
    function getAllocationRate(uint256 rate) external pure returns (uint256);

    /**
     * @dev Returns the allocation rate for a given `epochId`.
     */
    function getAllocationRateForEpoch(uint256 epochId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IEpochManager is IERC165Upgradeable {
    struct Epoch {
        uint256 startingTime; // starting timestamp of an epoch
        uint256 endingTime; // ending timestamp of an epoch
        uint256 epochId; // epochId
    }

    struct IdeaIdPool {
        uint256[] ideaIds; // an array of ideaIds
    }

    /**
     * @dev Emitted when `ideaManger`, `votingManager` and `
     * rewardManager` contracts are set.
     */
    event ContractsSet(
        address ideaManger,
        address votingManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the epoch with `epochId` is started with
     * `nIdeas` and `duration`.
     */
    event EpochStarted(uint256 epochId, uint256 nIdeas, uint256 duration);

    /**
     * @dev Emitted when the epoch with `epochId` is updated with
     * `nIdeas` and `duration`.
     */
    event EpochUpdated(uint256 epochId, uint256 nIdeas, uint256 duration);

    /**
     * @dev Emitted when the minEpochLength `oldLength` is updated with
     * a new length `newLength`.
     */
    event MinEpochLengthSet(uint256 oldLength, uint256 newLength);

    /**
     * @dev Emitted when the old maxEpochLength `oldLength` is updated with
     * a new length `newLength`.
     */
    event MaxEpochLengthSet(uint256 oldLength, uint256 newLength);

    /**
     * @dev Emitted when the old minDurationFromNow `oldMinDurationFromNow`
     * is updated with a new length `minDurationFromNow`.
     */
    event MinDurationFromNowSet(
        uint256 oldMinDurationFromNow,
        uint256 minDurationFromNow
    );

    /**
     * @dev Emitted when the maxNumOfIdeasPerEpoch `oldNumber` is updated
     * with a new number `newNumber`.
     */
    event MaxNumOfIdeasPerEpochSet(uint256 oldNumber, uint256 newNumber);

    /**
     * @dev Starts a new epoch if the refresh condition is met with an
     * array of `ideaIds` and the epoch `endTimestamp`.
     *
     * Conditions:
     * - An array of qualified ideas with valid `ideaIds` are provided.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function startNewEpoch(uint256[] calldata ideaIds, uint256 endTimestamp)
        external;

    /**
     * @dev Modifies the parameters of the current epoch with an
     * array of `ideaIds` and `endTimestamp`.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function updateEpoch(uint256[] calldata ideaIds, uint256 endTimestamp)
        external;

    /**
     * @dev Sets `minEpochLength` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMinEpochLength(uint256 minEpochLength) external;

    /**
     * @dev Sets `maxEpochLength` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMaxEpochLength(uint256 maxEpochLength) external;

    /**
     * @dev Sets `minDurationFromNow` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMinDurationFromNow(uint256 minDurationFromNow) external;

    /**
     * @dev Sets `maxNumOfIdeasPerEpoch` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMaxNumOfIdeasPerEpoch(uint256 maxNumOfIdeasPerEpoch) external;

    /**
     * @dev Sets contracts by retrieving addresses from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @dev Returns to normal state provided a new `duration`.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause(uint256 duration) external;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
     * @dev Returns the `Epoch` information given the lookup `epochId`.
     */
    function epoch(uint256 epochId) external view returns (Epoch memory);

    /**
     * @dev Returns the `Epoch` information for the current active epoch.
     */
    function getThisEpoch() external view returns (Epoch memory);

    /**
     * @dev Returns the array of ideaIds for a given `epochId`.
     */
    function getIdeaIds(uint256 epochId)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total number of ideas for a given `epochId`.
     */
    function getNumOfIdeas(uint256 epochId) external view returns (uint256);

    /**
     * @dev Returns if a given `ideaId` is active in the current epoch.
     */
    function isIdeaActive(uint256 ideaId) external view returns (bool);

    /**
     * @dev Returns if this epoch is already ended.
     */
    function isThisEpochEnded() external view returns (bool);

    /**
     * @dev Returns the current value of epochCounter as the next
     * possible `epochId`.
     */
    function getCurEpochId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IIdeaManager is IERC165Upgradeable {
    struct Idea {
        bytes32 contentHash; // the hash of content metadata
        uint256 metaverseId; // metaverse id
    }

    struct IdeaInfo {
        Idea idea;
        address ideator; // ideator's address
    }

    /**
     * @dev Emitted when an idea `ideaId` with transaction hash `contentHash`,
     * for the metaverse `metaverseId` is published.
     */
    event IdeaPublished(
        uint256 ideaId,
        bytes32 contentHash,
        uint256 metaverseId,
        address ideator
    );

    /**
     * @dev Emitted when a new `metaverseManger` contract address is set.
     */
    event ContractsSet(address metaverseManger);

    /**
     * @dev Emitted when a new `wallet` address is set.
     */
    event WalletSet(address wallet);

    /**
     * @dev Emitted when a new proposal fee `newFee` is set to replace an
     * old proposal fee `oldFee`.
     */
    event ProposalFeeSet(uint256 oldFee, uint256 newFee);

    /**
     * @dev Sets a new proposal `fee` for submitting an idea. The fee is
     * denominated by the DAO token specified by `feeToken` state variable.
     */
    function setProposalFee(uint256 fee) external;

    /**
     * @dev Sets a new `wallet` address.
     */
    function setWallet(address wallet) external;

    /**
     * @dev Sets contracts by retrieving addresses from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Publishes an `_idea`.
     *
     * Requirements:
     * - anyone who has a valid idea and pays a submission fee.
     */
    function publishIdea(Idea calldata _idea) external;

    /**
     * @dev Returns if an idea with `ideaId` exists.
     */
    function exists(uint256 ideaId) external view returns (bool);

    /**
     * @dev Returns the Idea struct object for an idea with `ideaId`.
     */
    function getIdeaInfo(uint256 ideaId)
        external
        view
        returns (IdeaInfo memory);

    /**
     * @dev Returns the protocol-level idea proposal fee.
     */
    function getProposalFee() external view returns (uint256);

    /**
     * @dev Returns the current ideaId.
     */
    function getCurIdeaId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IMetaverseManager is IERC165Upgradeable {
    struct Metaverse {
        string name;
    }

    /**
     * @dev Emitted when a new metaverse with `metaverseId` and `name`
     * is added.
     */
    event MetaverseAdded(uint256 metaverseId, string name);

    /**
     * @dev Emitted when an existing metaverse with `metaverseId` and
     * `oldname` is updated with `newName`.
     */
    event MetaverseUpdated(uint256 metaverseId, string oldName, string newName);

    /**
     * @dev Emitted when an existing metaverse with `metaverseId` and
     * `name` is removed.
     */
    event MetaverseRemoved(uint256 metaverseId, string name);

    /**
     * @dev Adds a `metaverse` struct object to the protocol.
     *
     * Requirements:
     *
     * - the caller must be the owner of the smart contract.
     */
    function addMetaverse(Metaverse calldata metaverse) external;

    /**
     * @dev Removes a metaverse with `metaverseId` from the protocol.
     *
     * Requirements:
     *
     * - the caller must be the owner of the smart contract.
     */
    function removeMetaverse(uint256 metaverseId) external;

    /**
     * @dev Updates the metaverse with `metaverseId` with a new
     * `metaverse` object.
     *
     * Requirements:
     *
     * - the caller must be the owner of the smart contract.
     */
    function updateMetaverse(uint256 metaverseId, Metaverse calldata metaverse)
        external;

    /**
     * @dev Returns if a metaverse with `metaverseId` exists.
     */
    function exists(uint256 metaverseId) external view returns (bool);

    /**
     * @dev Returns the metaverse object for a provided `metaverseId`.
     */
    function getMetaverse(uint256 metaverseId)
        external
        view
        returns (Metaverse memory);

    /**
     * @dev Returns the metaverseId for a provided `name`.
     */
    function getMetaverseIdByName(string calldata name)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the next metaverseId.
     */
    function getMetaverseId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRegistry is IERC165 {
    /**
     * @dev Emitted when a new `ideaManger` contract address is set.
     */
    event IdeaManagerSet(address ideaManger);

    /**
     * @dev Emitted when a new `metaverseManager` contract address is set.
     */
    event MetaverseManagerSet(address metaverseManager);

    /**
     * @dev Emitted when a new epoch manager contract `epochManager`
     * is set.
     */
    event EpochManagerSet(address epochManager);

    /**
     * @dev Emitted when a new voting manager contract `votingManager`
     * is set.
     */
    event VotingManagerSet(address votingManager);

    /**
     * @dev Emitted when a new reward pool `rewardPool` is set.
     */
    event RewardPoolSet(address rewardPool);

    /**
     * @dev Emitted when a new `rewardManger` contract address is set.
     */
    event RewardManagerSet(address rewardManger);

    /**
     * @dev Emitted when a new reward vesting manager constract
     * `rewardVestingManager` is set.
     */
    event RewardVestingManagerSet(address rewardVestingManager);

    /**
     * @dev Emitted when a new allocation manager contract
     * `allocationManager` is set.
     */
    event AllocationManagerSet(address allocationManager);

    /**
     * @dev Sets a new `ideaManager` contract address.
     */
    function setIdeaManager(address ideaManager) external;

    /**
     * @dev Sets a new `metaverseManager` address.
     */
    function setMetaverseManager(address metaverseManager) external;

    /**
     * @dev Sets a new `epochManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setEpochManager(address epochManager) external;

    /**
     * @dev Sets a new `votingManager` contract address.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingManager(address votingManager) external;

    /**
     * @dev Sets a new `rewardPool` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardPool(address rewardPool) external;

    /**
     * @dev Sets a new `rewardManager` contract address.
     */
    function setRewardManager(address rewardManager) external;

    /**
     * @dev Sets a new `rewardVestingManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardVestingManager(address rewardVestingManager) external;

    /**
     * @dev Sets a new `allocationManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setAllocationManager(address allocationManager) external;

    /**
     * @dev Returns the idea manager contract address.
     */
    function ideaManager() external view returns (address);

    /**
     * @dev Returns the metaverse manager contract address.
     */
    function metaverseManager() external view returns (address);

    /**
     * @dev Returns the epoch manager contract address.
     */
    function epochManager() external view returns (address);

    /**
     * @dev Returns the voting manager contract address.
     */
    function votingManager() external view returns (address);

    /**
     * @dev Returns the reward pool contract address.
     */
    function rewardPool() external view returns (address);

    /**
     * @dev Returns the reward manager contract address.
     */
    function rewardManager() external view returns (address);

    /**
     * @dev Returns the reward vesting manager contract address.
     */
    function rewardVestingManager() external view returns (address);

    /**
     * @dev Returns the allocation manager contract address.
     */
    function allocationManager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IRewardManager is IERC165Upgradeable {
    struct RewardAmount {
        uint256 total; // Total amount of reward for an epoch
        uint256 unallocated; // Unallocated amount of reward for the same epoch
    }

    /**
     * @dev Emitted when contract addressses are set.
     */
    event ContractsSet(
        address rewardPool,
        address votingManager,
        address epochManager,
        address allocationManager,
        address rewardVestingManager
    );

    /**
     * @dev Emitted when the reward manager gets reloaded with a
     * new supply of tokens of this `amount` from the reward pool
     * for `epochId`.
     */
    event Reloaded(uint256 epochId, uint256 amount);

    /**
     * @dev Emitted when `account` claims `amount` of reward
     * for `epochId`.
     */
    event Claimed(address account, uint256 epochId, uint256 amount);

    /**
     * @dev Emitted when a new `amount` of reward per epoch is updated.
     */
    event RewardAmountPerEpochUpdated(uint256 amount);

    /**
     * @dev Emitted when a new `amount` for the next epoch with
     * `nextEpochId` is (manually) updated.
     */
    event RewardAmountForNextEpochSet(uint256 amount, uint256 nextEpochId);

    /**
     * @dev Emitted when a new `rewardAmount` for the epoch with `epochId`
     * is (algorithmically) updated.
     */
    event RewardAmountUpdated(uint256 epochId, uint256 rewardAmount);

    /**
     * @dev Emitted when the status of algo rewarding is toggled to
     * be `isAlgoRewardingOn`.
     */
    event AlgoRewardingToggled(bool isAlgoRewardingOn);

    /**
     * @dev Emitted when the epoch ended locker is toggled to
     * be `isEpochEndedLockerOn`.
     */
    event EpochEndedLockerToggled(bool isEpochEndedLockerOn);

    /**
     * @dev Reloads the reward amount for the next epoch by retrieving
     * tokens from the reward pool.
     *
     * Requirements: only EpochManager can call this function.
     */
    function reload() external;

    /**
     * @dev Updates the reward amount for the next epoch manually.
     *
     * Requirements: only admin can call this function.
     */
    function updateRewardAmount() external;

    /**
     * @dev Claims the reward for `account` in `epochId` to the
     * reward vesting manager contract.
     */
    function claimRewardForEpoch(address account, uint256 epochId) external;

    /**
     * @dev Claims the rewards for `account` in an array of `epochIds`
     * to the reward vesting manager contract.
     */
    function claimRewardsForEpochs(address account, uint256[] calldata epochIds)
        external;

    /**
     * @dev Updates metrics when the current epoch is ended.
     *
     * Requirements: only the voting manager can call this function.
     */
    function onEpochEnded() external;

    /**
     * @dev Updates the reward amount per epoch with a new `amount`.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardAmountPerEpoch(uint256 amount) external;

    /**
     * @dev Sets contracts by retrieving contracts from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Toggles the status of algo rewarding from true to false or
     * from false to true.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleAlgoRewarding() external;

    /**
     * @dev Toggles the epoch ended locker from true to false or
     * from false to true. This is only used in emergency.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleEpochEndedLocker() external;

    /**
     * @dev Returns the system paramter reward amount per epoch.
     */
    function rewardAmountPerEpoch() external view returns (uint256);

    /**
     * @dev Returns if `account` has claimed reward for `epochId`.
     */
    function hasClaimedRewardForEpoch(address account, uint256 epochId)
        external
        view
        returns (bool);

    /**
     * @dev Returns the eligible amount for `account` to claim given
     * `epochId`.
     */
    function amountEligibleForEpoch(address account, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the unclaimed amount of tokens in this contract.
     */
    function amountUnclaimed() external view returns (uint256);

    /**
     * @dev Returns the reward amount for `account`.
     */
    function getClaimedRewardAmount(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the reward amount for `epochId`.
     */
    function getRewardAmountForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the unallocated reward amount for `epochId`.
     */
    function getUnallocatedRewardAmountForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the allocated reward amount for `epochId`.
     */
    function getAmountOfAllocatedReward(uint256 epochId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IRewardPool is IERC165Upgradeable {
    /**
     * @dev Emitted when a new `rewardManager` contract address is set.
     */
    event ContractsSet(address rewardManager);

    /**
     * @dev Emitted when `amount` of tokens are withdrawn.
     */
    event Withdrawn(uint256 amount);

    /**
     * @dev Emitted when `amount` of tokens are approved by rewardPool to
     * rewardManager.
     */
    event RewardManagerApproved(uint256 amount);

    /**
     * @dev Approves the reward manager for 10 times of the
     * rewardAmountPerEpoch returned from reward manager as the new
     * allowance.
     */
    function approveRewardManager() external;

    /**
     * @dev Returns the total amount of reward available in this
     * contract that is able to be retrieved by the reward manager
     * contract.
     */
    function totalAmount() external view returns (uint256);

    /**
     * @dev Sets new contracts by retrieving addresses from the registry
     * contract.
     */
    function setContracts() external;

    /**
     * @dev Withdraws the remaining tokens to the admin's wallet.
     */
    function withdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IRewardVestingManager is IERC165Upgradeable {
    /**
     * @dev Emitted when `amount` of tokens are claimed by `account`.
     */
    event Claimed(address account, uint256 amount);

    /**
     * @dev Emitted when `epochManager`, `votingManager` and `rewardManager`
     * contracts are set.
     */
    event ContractsSet(
        address epochManager,
        address votingManager,
        address rewardManager
    );

    /**
     * @dev Claims the reward for the caller if there is any.
     */
    function claim() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Returns the total amount of unclaimed reward in this contract.
     *
     */
    function amountUnclaimed() external view returns (uint256);

    /**
     * @dev Returns the total amount of vested reward for `account`.
     */
    function getTotalAmountOfVestedReward(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the current total amount of reward eligible for `account`
     * to claim.
     */
    function getEligibleAmountOfRewardToClaim(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of reward that has been claimed by
     * `account`.
     */
    function getAmountOfRewardClaimed(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the array of epochIds for `account` and `nEpochs`.
     * @param account the account wallet to look up epochIds for
     * @param nEpochs the number of epochIds to retrieve
     */
    function getEpochIdsEligibleForClaimingRewards(
        address account,
        uint256 nEpochs
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IVeContractListener is IERC165Upgradeable {
    /**
     * @dev Updates the voting power for `account` when voting power is
     * added or changed on the voting escrow contract directly.
     *
     * Requirements:
     *
     * - only the voting escrow contract can call this contract.
     */
    function onVotingPowerUpdated(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IEpochManager.sol";
import "./IVeContractListener.sol";

interface IVotingManager is IVeContractListener {
    struct EpochInfo {
        uint256[] epochIds; // epochs that a voter has participated in
    }

    struct Vote {
        uint256 ideaId; // Vote for ideaId
        uint256 percentage; // % of voting power allocated to this vote
    }

    struct Ballot {
        uint256 total; // Total amount of voting power for a ballot
        Vote[] votes; // Array of votes
    }

    /**
     * @dev Emitted when contract addresses are set.
     */
    event ContractsSet(
        address ideaManager,
        address epochManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the voting power is updated for `account` to a new
     * total amount `votingPower`. This can happen when tokens are being
     * locked in the voting escrow contract.
     */
    event VotingPowerUpdated(address account, uint256 votingPower);

    /**
     * @dev Emitted when `oldVotingPowerThreshold` is replaced by a
     * new `votingPowerThreshold`.
     */
    event VotingPowerThresholdSet(
        uint256 oldVotingPowerThreshold,
        uint256 votingPowerThreshold
    );

    /**
     * @dev Emitted when `oldMaxNumOfVotesPerBallot` is replaced by a
     * new `maxNumOfVotesPerBallot`.
     */
    event MaxNumOfVotesPerBallotSet(
        uint256 oldMaxNumOfVotesPerBallot,
        uint256 maxNumOfVotesPerBallot
    );

    /**
     * @dev Emitted when `account` submits a ballot in `epochId` with
     * `votes` and a total amount of `votingPower`.
     */
    event BallotSubmitted(
        address account,
        uint256 epochId,
        Vote[] votes,
        uint256 votingPower
    );

    /**
     * @dev Emitted when the denied status for `account` is toggled.
     */
    event AccountDeniedStatusToggled(address account);

    /**
     * @dev Emitted when the total voting power is updated in `epochId`
     * to a new total amount `totalVotingPower`.
     */
    event TotalVotingPowerUpdated(uint256 epochId, uint256 totalVotingPower);

    /**
     * @dev Submits a ballot with ideas in `votes`.
     */
    function submitBallot(Vote[] calldata votes) external;

    /**
     * @dev Calls this function when a new epoch is started to record the
     * total voting power.
     *
     * Requirements: only the EpochManager contract can call this function.
     */
    function onEpochStarted() external;

    /**
     * @dev Ends this epoch and updates the metrics for the previous epoch.
     */
    function endThisEpoch() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Sets `newThreshold` for the voting power threshold.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingPowerThreshold(uint256 newThreshold) external;

    /**
     * @dev Sets `newNumber` for the maximum number of votes permited
     * per ballot.
     *
     * Requirements: only the admin can call this function.
     */
    function setMaxNumOfVotesPerBallot(uint256 newNumber) external;

    /**
     * @dev Toggles the denied status for an `account`.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleDenied(address account) external;

    /**
     * @dev Returns the Epoch information for this epoch by reading from
     * EpochManager.
     */
    function getThisEpoch() external view returns (IEpochManager.Epoch memory);

    /**
     * @dev Returns the Ballot information for `account` in epoch with
     * `epochId`.
     */
    function getBallot(address account, uint256 epochId)
        external
        view
        returns (Ballot memory);

    /**
     * @dev Returns the array of epochIds that `account` has participated in.
     */
    function getEpochsParticipated(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total amount of voting power that
     * `account` has allocated for the current active epoch.
     */
    function getVotingPowerForCurrentEpoch(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the system parameter `PERCENTAGES_MULTIPLE`.
     */
    function PERCENTAGES_MULTIPLE() external view returns (uint256);

    /**
     * @dev Returns the weight of voting power `account` has gained
     * in `epochId` among all voters.
     */
    function getWeightInVotingPower(address account, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of consumed voting power in `epochId`.
     */
    function getEpochVotingPower(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of voting power available for `epochId`,
     * including the amount that has not been consumed in `epochId`.
     */
    function getTotalVotingPowerForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the voting power consumption rate for `epochId`.
     * It is calculated by comparing the consumed amount with the
     * total available amount of voting power.
     */
    function getVotingPowerConsumptionRate(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `ideaId`
     * in epoch `epochId`.
     */
    function getIdeaVotingPower(uint256 ideaId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `metaverseId`
     * in epoch `epochId`.
     */
    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns if an array of `votes` is a valid ballot.
     */
    function isValidBallot(Vote[] calldata votes) external view returns (bool);

    /**
     * @dev Returns if `voter` is denied from voting.
     */
    function isDenied(address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IIdeaManager.sol";
import "./interfaces/IMetaverseManager.sol";
import "./interfaces/IEpochManager.sol";
import "./interfaces/IVotingManager.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IRewardVestingManager.sol";
import "./interfaces/IAllocationManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/Adminable.sol";

contract Registry is Adminable, IRegistry, ERC165 {
    using ERC165Checker for address;

    bytes4 public constant IID_IREGISTRY = type(IRegistry).interfaceId;

    address public override ideaManager;
    address public override metaverseManager;
    address public override epochManager;
    address public override votingManager;
    address public override rewardPool;
    address public override rewardManager;
    address public override rewardVestingManager;
    address public override allocationManager;

    function setIdeaManager(address _ideaManager) external override onlyAdmin {
        require(
            _ideaManager != address(0) &&
                _ideaManager.supportsInterface(type(IIdeaManager).interfaceId),
            "Registry: invalid address"
        );
        ideaManager = _ideaManager;

        emit IdeaManagerSet(ideaManager);
    }

    function setMetaverseManager(address _metaverseManager)
        external
        override
        onlyAdmin
    {
        require(
            _metaverseManager != address(0) &&
                _metaverseManager.supportsInterface(
                    type(IMetaverseManager).interfaceId
                ),
            "Registry: invalid address"
        );
        metaverseManager = _metaverseManager;

        emit MetaverseManagerSet(metaverseManager);
    }

    function setEpochManager(address _epochManager)
        external
        override
        onlyAdmin
    {
        require(
            _epochManager != address(0) &&
                _epochManager.supportsInterface(
                    type(IEpochManager).interfaceId
                ),
            "Registry: invalid address"
        );
        epochManager = _epochManager;

        emit EpochManagerSet(epochManager);
    }

    function setVotingManager(address _votingManager)
        external
        override
        onlyAdmin
    {
        require(
            _votingManager != address(0) &&
                _votingManager.supportsInterface(
                    type(IVotingManager).interfaceId
                ),
            "Registry: invalid address"
        );
        votingManager = _votingManager;

        emit VotingManagerSet(votingManager);
    }

    function setRewardPool(address _rewardPool) external override onlyAdmin {
        require(
            _rewardPool != address(0) &&
                _rewardPool.supportsInterface(type(IRewardPool).interfaceId),
            "Registry: invalid address"
        );
        rewardPool = _rewardPool;

        emit RewardPoolSet(rewardPool);
    }

    function setRewardManager(address _rewardManager)
        external
        override
        onlyAdmin
    {
        require(
            _rewardManager != address(0) &&
                _rewardManager.supportsInterface(
                    type(IRewardManager).interfaceId
                ),
            "Registry: invalid address"
        );
        rewardManager = _rewardManager;

        emit RewardManagerSet(rewardManager);
    }

    function setRewardVestingManager(address _rewardVestingManager)
        external
        override
        onlyAdmin
    {
        require(
            _rewardVestingManager != address(0) &&
                _rewardVestingManager.supportsInterface(
                    type(IRewardVestingManager).interfaceId
                ),
            "Registry: invalid address"
        );
        rewardVestingManager = _rewardVestingManager;

        emit RewardVestingManagerSet(rewardVestingManager);
    }

    function setAllocationManager(address _allocationManager)
        external
        override
        onlyAdmin
    {
        require(
            _allocationManager != address(0) &&
                _allocationManager.supportsInterface(
                    type(IAllocationManager).interfaceId
                ),
            "Registry: invalid address"
        );
        allocationManager = _allocationManager;

        emit AllocationManagerSet(allocationManager);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRegistry).interfaceId ||
            ERC165.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * This is a direct copy of OpenZeppelin's Ownable at:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */

abstract contract Adminable is Context {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        _transferAdminship(_msgSender());
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // solhint-disable-next-line reason-string
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing adminship will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdminship() public virtual onlyAdmin {
        _transferAdminship(address(0));
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdminship(address newAdmin) public virtual onlyAdmin {
        // solhint-disable-next-line reason-string
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        _transferAdminship(newAdmin);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdminship(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminshipTransferred(oldAdmin, newAdmin);
    }
}