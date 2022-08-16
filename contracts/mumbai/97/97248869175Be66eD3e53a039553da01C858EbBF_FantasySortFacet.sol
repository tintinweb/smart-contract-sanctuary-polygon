// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibOwnership} from "../libraries/LibOwnership.sol";
import {LibFantasyCoreStorage} from "../libraries/LibFantasyCoreStorage.sol";
import {LibFantasyMerkleStorage} from "../libraries/LibFantasyMerkleStorage.sol";
import {LibFantasyExternalStorage} from "../libraries/LibFantasyExternalStorage.sol";
import {LibFantasyDraftStorage} from "../libraries/LibFantasyDraftStorage.sol";
import {DraftPickLib} from "../libraries/DraftPickLib.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../interfaces/IFantasyLeague.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/IFantasySortFacet.sol";

import {DataTypes} from "../libraries/types/DataTypes.sol";

contract FantasySortFacet is IFantasySortFacet {
    /// @notice Sorts users based on their staked balance and the current balance of LEAG tokens they currently posses in descending order. Even balances are randomly sorted
    /// @param mp user in a particular season and division which are to be sorted
    /// Emits {UsersSorted} event
    function sortUsers(DataTypes.MerkleProof[] memory mp) external {
        LibOwnership.enforceIsContractOwner();
        LibFantasyMerkleStorage.enforceMerkleTreeSet();

        require(
            mp.length == LibFantasyCoreStorage.dstorage().maxDivisionMembers,
            "Invalid length"
        );

        uint256 balance;
        bool foundEqual;
        uint256 equalStartIndex;
        uint256 equalEndIndex;
        bytes32 node;

        uint256 seasonId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).seasonId();

        uint256 divisionId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).getUserDivisionId(seasonId, mp[0].user);

        LibFantasyDraftStorage.dstorage().round[seasonId][divisionId] = 1;

        for (uint256 i = 0; i < mp.length; i++) {
            uint256 userDivision = IFantasyLeague(
                LibFantasyExternalStorage.dstorage().fantasyLeague
            ).getUserDivisionId(seasonId, mp[i].user);

            require(divisionId == userDivision, "Division mismatch");

            node = keccak256(
                abi.encodePacked(mp[i].index, mp[i].user, mp[i].amount)
            );

            uint256 userBalance = IERC20Permit(
                LibFantasyExternalStorage.dstorage().leagToken
            ).balanceOf(mp[i].user);

            userBalance += MerkleProof.verify(
                mp[i].proof,
                LibFantasyMerkleStorage.dstorage().merkleRoot,
                node
            )
                ? mp[i].amount
                : 0;

            for (uint256 j = i + 1; j < mp.length; j++) {
                node = keccak256(
                    abi.encodePacked(mp[j].index, mp[j].user, mp[j].amount)
                );

                uint256 nextUserBalance = IERC20Permit(
                    LibFantasyExternalStorage.dstorage().leagToken
                ).balanceOf(mp[j].user);

                nextUserBalance += MerkleProof.verify(
                    mp[j].proof,
                    LibFantasyMerkleStorage.dstorage().merkleRoot,
                    node
                )
                    ? mp[j].amount
                    : 0;

                if (nextUserBalance > userBalance) {
                    DataTypes.MerkleProof memory temp = mp[i];
                    mp[i] = mp[j];
                    mp[j] = temp;
                    userBalance = nextUserBalance;
                }
            }

            LibFantasyCoreStorage.dstorage().users[seasonId][divisionId].push(
                mp[i].user
            );

            if (userBalance == balance) {
                if (!foundEqual) {
                    equalStartIndex = i > 0 ? i - 1 : 0; // prevent underflow if all accounts have zero token balances
                    equalEndIndex = i;
                    foundEqual = true;
                } else {
                    equalEndIndex = i;
                }
            } else {
                if (equalStartIndex != equalEndIndex) {
                    LibFantasyCoreStorage.dstorage().users[seasonId][
                            divisionId
                        ] = DraftPickLib.randomizeArray(
                        LibFantasyCoreStorage.dstorage().users[seasonId][
                            divisionId
                        ],
                        equalStartIndex,
                        equalEndIndex
                    );

                    equalStartIndex = 0;
                    equalEndIndex = 0;
                }

                balance = userBalance;
                foundEqual = false;
            }
        }

        if (equalStartIndex != equalEndIndex) {
            LibFantasyCoreStorage.dstorage().users[seasonId][
                divisionId
            ] = DraftPickLib.randomizeArray(
                LibFantasyCoreStorage.dstorage().users[seasonId][divisionId],
                equalStartIndex,
                equalEndIndex
            );
        }

        emit UsersSorted(
            LibFantasyCoreStorage.dstorage().users[seasonId][divisionId]
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./LibDiamond.sol";

library LibOwnership {
    /// @notice Emitted when ownership is transfered
    /// @param previousOwner The old owner address
    /// @param newOwner The new owner address
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Sets a new contract owner
    /// @param _newOwner The new owner address
    /// Emits {OwnershipTransferred} event
    function setContractOwner(address _newOwner) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        address previousOwner = ds.contractOwner;
        require(
            previousOwner != _newOwner,
            "Previous owner and new owner must be different"
        );

        ds.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @dev Gets the current contract owner address
    /// @return contractOwner_ The contract owner address
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamond.diamondStorage().contractOwner;
    }

    /// @dev Enforces that the caller is contract owner
    function enforceIsContractOwner() internal view {
        require(
            msg.sender == LibDiamond.diamondStorage().contractOwner,
            "Must be contract owner"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/LibDiamond.sol";

library LibFantasyCoreStorage {
    /// @notice Emitted when a user's roster is updated
    /// @param seasonId The season the roster was updated for
    /// @param divisionId The division the roster was updated for
    /// @param user The user the roster was updated for
    /// @param tokenId The token that was used for the update
    /// @param added If the token was added or removed from the user roster
    event UserRosterUpdated(
        uint256 seasonId,
        uint256 divisionId,
        address indexed user,
        uint256 tokenId,
        bool added
    );

    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.fantasy.core.storage");

    struct Storage {
        /// @notice starts date of the tournament
        uint256 tournamentStartDate;
        /// @notice draft users order per season id => division id => draft order
        mapping(uint256 => mapping(uint256 => address[])) users; // 12 teams in each division
        ///@notice max amount of player that a user can have
        mapping(uint256 => mapping(uint256 => mapping(address => uint256))) roster; //seasonId => mapping(divisionId => mapping(address => roster)))
        /// @notice Total members in division
        uint256 maxDivisionMembers;
        /// @notice the max players a user can have in his roster
        uint256 maxRosterSize;
        /// @notice is given season paused. season id => isSeasonPaused
        mapping(uint256 => bool) isSeasonPaused;
    }

    /// @dev The diamond storage for the Core
    /// @return ds The core diamond storage pointer
    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Enforces that the address specified is not address(0)
    /// @param _address The address that is being validated
    function enforceValidAddress(address _address) internal pure {
        require(_address != address(0), "Not a valid address");
    }

    /// @dev Enforces that the tournament has started
    function enforceTournamentStarted() internal view {
        require(
            block.timestamp > dstorage().tournamentStartDate,
            "Tournament not started!"
        );
    }

    /// @dev Enforces that the tournament has started
    function enforceTournamentNotStarted() internal view {
        require(
            block.timestamp < dstorage().tournamentStartDate,
            "Tournament already started!"
        );
    }

    /// @dev Enforces that the tournament is not paused
    function enforceSeasonNotPaused(uint256 seasonId) internal view {
        require(!dstorage().isSeasonPaused[seasonId], "Season Paused");
    }

    /// @dev Assigns a token to a user's roster
    /// @param seasonId The season to which roster will be assigned
    /// @param divisionId The division to which roster will be assigned
    /// @param user The user to which roster will be assigned
    /// @param tokenId The token to which roster will be assigned
    /// Emits {UserRosterUpdated} event
    function assignToRoster(
        uint256 seasonId,
        uint256 divisionId,
        address user,
        uint256 tokenId
    ) internal {
        LibFantasyCoreStorage.Storage storage coreDs = dstorage();

        // require(
        //     coreDs.roster[seasonId][divisionId][user] < coreDs.maxRosterSize,
        //     "Exceeds roster limit"
        // );

        coreDs.roster[seasonId][divisionId][user]++;
        emit UserRosterUpdated(seasonId, divisionId, user, tokenId, true);
    }

    /// @dev Removes a token from a user's roster
    /// @param seasonId The season to which roster will be deducted
    /// @param divisionId The division to which roster will be deducted
    /// @param user The user to which roster will be deducted
    /// @param tokenId The token to which roster will be deducted
    /// Emits {UserRosterUpdated} event
    function removeFromRoster(
        uint256 seasonId,
        uint256 divisionId,
        address user,
        uint256 tokenId
    ) internal {
        LibFantasyCoreStorage.Storage storage coreDs = dstorage();
        require(
            coreDs.roster[seasonId][divisionId][user] > 0,
            "Roster must not be empty"
        );

        coreDs.roster[seasonId][divisionId][user]--;

        emit UserRosterUpdated(seasonId, divisionId, user, tokenId, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/LibDiamond.sol";
import {DataTypes} from "./types/DataTypes.sol";

library LibFantasyMerkleStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.fantasy.merkle.storage");

    struct Storage {
        /// @notice The merkle tree root
        bytes32 merkleRoot;
    }

    /// @dev Gets the merkle tree diamond storage
    /// @return ds The merkle tree diamond storage
    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Enforces that the merkle tree root is set
    function enforceMerkleTreeSet() internal view {
        require(dstorage().merkleRoot != "", "Merkle Tree Not Set!");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {DataTypes} from "./types/DataTypes.sol";

import "../interfaces/IFantasyLeague.sol";

library LibFantasyExternalStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.fantasy.external.storage");

    struct Storage {
        /// @notice PlayerV2 token contract
        address playerV2;
        /// @notice LEAG token contract
        address leagToken;
        /// @notice DLEAG token contract
        address dLeagToken;
        /// @notice NomoNFT contract
        address nomoNft;
        /// @notice LEAG Reward Pool contract
        address leagRewardPool;
        /// @notice DAO Treasury contract
        address daoTreasury;
        /// @notice Fantasy League contract
        address fantasyLeague;
    }

    /// @dev Gets the external diamond storage
    /// @return ds The diamond storage
    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Enforce that the address is a member of the fantasy league
    /// @param _seasonId The current seasonId
    /// @param _address The address of the user
    function enforceIsUser(uint256 _seasonId, address _address) internal view {
        require(
            IFantasyLeague(dstorage().fantasyLeague).isUser(
                _seasonId,
                _address
            ),
            "User is not registered"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/LibDiamond.sol";
import {LibFantasyCoreStorage} from "./LibFantasyCoreStorage.sol";
import {DataTypes} from "./types/DataTypes.sol";

library LibFantasyDraftStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.fantasy.draft.storage");

    struct Storage {
        /// @notice start of the draft for all divisions
        uint256 draftStartDate;
        /// @notice season id => division id => current round
        mapping(uint256 => mapping(uint256 => uint8)) round;
        /// @notice season id => division id => is round processed
        mapping(uint256 => mapping(uint256 => mapping(uint8 => bool))) roundProcessed;
        /// @notice player reservation details per season id => division id => tokenId => reservation state
        mapping(uint256 => mapping(uint256 => mapping(uint256 => DataTypes.ReservationState))) reservedPlayers;
        /// @notice player reservation expiration time
        uint256 reserveExpirationTime;
        /// @notice total rounds for the drafts
        uint8 totalRounds;
        /// @notice the price for each PlayerV2 Token while in draft stage. If token is burnt after draft, this price is being returned to msg.sender
        uint256 draftPrice;
    }

    /// @dev Returns the draft diamond storage
    /// @return ds The draft diamond storage pointer
    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Verifies if the draft has started
    function enforceHasDraftStarted() internal view {
        require(
            block.timestamp > dstorage().draftStartDate,
            "Draft has not started!"
        );
    }

    /// @dev Verifies if the draft has ended
    /// @param seasonId The season which is checked whether draft has ended for
    /// @param divisionId The division which is checked whether draft has ended for
    function enforceDraftEnded(uint256 seasonId, uint256 divisionId)
        internal
        view
    {
        require(
            dstorage().roundProcessed[seasonId][divisionId][
                dstorage().totalRounds
            ],
            "Draft has not ended!"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library DraftPickLib {
    /**
     * @dev Returns the randomly chosen index.
     * @param max current length of the collection.
     * @return length of the collection
     */
    function randomize(uint256 max) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        keccak256(
                            abi.encodePacked(
                                msg.sender,
                                tx.origin,
                                gasleft(),
                                block.timestamp,
                                block.difficulty,
                                block.number,
                                blockhash(block.number),
                                address(this)
                            )
                        )
                    )
                )
            ) % max;
    }

    /**
     * @dev Returns the sliced array.
     * @param array the array to be sliced.
     * @param from the index to start the slicing.
     * @param to the index to end the slicing.
     * @return array of addresses
     */
    function slice(
        address[] memory array,
        uint256 from,
        uint256 to
    ) internal pure returns (address[] memory) {
        require(
            array.length >= to,
            "the end element for the slice is out of bounds"
        );
        address[] memory sliced = new address[](to - from + 1);

        for (uint256 i = from; i <= to; i++) {
            sliced[i - from] = array[i];
        }

        return sliced;
    }

    /**
     * @dev Returns the spliced array.
     * @param array the array to be spliced.
     * @param _address the address of the user that will be spliced.
     * @return array of addresses
     */
    function spliceByAddress(address[] memory array, address _address)
        internal
        pure
        returns (address[] memory)
    {
        require(array.length != 0, "empty array");
        require(_address != address(0), "the array index is negative");
        // require(index < array.length, "the array index is out of bounds");

        address[] memory spliced = new address[](array.length);
        uint256 indexCounter = 0;

        for (uint256 i = 0; i < array.length; i++) {
            if (_address != array[i]) {
                spliced[indexCounter] = array[i];
                indexCounter++;
            }
        }

        return spliced;
    }

    /**
     * @dev Returns the spliced array.
     * @param array the array to be spliced.
     * @param index the index of the element that will be spliced.
     * @return array of addresses
     */
    function splice(address[] memory array, uint256 index)
        internal
        pure
        returns (address[] memory)
    {
        require(array.length != 0, "empty array");
        require(index >= 0, "the array index is negative");
        require(index < array.length, "the array index is out of bounds");

        address[] memory spliced = new address[](array.length - 1);
        uint256 indexCounter = 0;

        for (uint256 i = 0; i < array.length; i++) {
            if (i != index) {
                spliced[indexCounter] = array[i];
                indexCounter++;
            }
        }

        return spliced;
    }

    /**
     * @dev Method that randomizes array in a specific range
     * @param array the array to be randomized, with 12 records inside.
     * @param startIndex the index of the element where the randomization starts.
     * @param endIndex the index of the element where the randomiation ends.
     */
    function randomizeArray(
        address[] memory array,
        uint256 startIndex,
        uint256 endIndex
    ) internal view returns (address[] memory) {
        address[] memory sliced = slice(array, startIndex, endIndex);

        uint256 slicedLen = sliced.length;
        uint256 startIndexReplace = startIndex;
        for (uint256 i = 0; i < slicedLen; i++) {
            uint256 rng = randomize(sliced.length);

            address selected = sliced[rng];

            sliced = splice(sliced, rng);

            array[startIndexReplace] = selected;
            startIndexReplace++;
        }

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFantasyLeague {
    function getUserDivisionId(uint256 _season, address _user)
        external
        view
        returns (uint256);

    function seasonId() external view returns (uint256);

    function isUser(uint256 seasonId, address user)
        external
        view
        returns (bool);

    /**
     * @notice How many users in the game registered
     *
     * @return Amount of the users
     */
    function getNumberOfUsers() external view returns (uint256);

    /**
     * @notice Total amount of divisions
     */
    function getNumberOfDivisions() external view returns (uint256);

    function getDivisionUsers(uint256 _season, uint256 _division)
        external
        view
        returns (address[] memory division);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IFantasySortFacet {
    event UsersSorted(address[] players);

    // @notice Sorts users based on their staked balance and the current balance of LEAG tokens they currently posses in descending order. Even balances are randomly sorted
    /// @param mp user in a particular season and division which are to be sorted
    function sortUsers(DataTypes.MerkleProof[] memory mp) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library DataTypes {
    // ============ Constructor Args ============
    struct ExternalCtrArgs {
        address playerV2;
        address leagToken;
        address dLeagToken;
        address nomoNft;
        address leagRewardPool;
        address daoTreasury;
        address fantasyLeague;
    }

    struct CoreCtrArgs {
        uint256 tournamentStartDate;
        uint256 maxDivisionMembers;
        uint256 maxRosterSize;
    }

    struct AuctionCtrArgs {
        uint256 minAuctionAmount;
        uint256 outbidAmount;
        uint256 softStop;
        uint256 hardStop;
    }

    struct DraftCtrArgs {
        uint8 totalRounds;
        uint256 draftStartDate;
        uint256 expirationTime;
        uint256 draftPrice;
    }

    // ============ Swap ============

    /// @notice swap listing struct
    struct SwapProposal {
        uint256 proposedTokenId;
        uint256 requestedTokenId;
        address requestedTokenOwner;
    }

    /// @notice life cycle of the swap
    enum SwapStatus {
        inactive,
        active,
        accepted,
        canceled,
        voteRejected,
        completed
    }

    /// @notice the state of the swap
    struct SwapState {
        uint256 swapId;
        uint256 proposedTokenId;
        uint256 requestedTokenId;
        address from;
        address to;
        uint256 voteHardStop;
        address[] rejectVotes;
        SwapStatus status;
    }

    // ============ Auction ============

    /// @notice life cycle of the auction
    enum Status {
        inactive,
        live,
        ended
    }

    /// @notice the state of the auction
    struct AuctionState {
        uint256 auctionId;
        uint256 auctionStart;
        uint256 auctionSoftStop;
        uint256 auctionHardStop;
        uint256 cardImageId;
        uint256 tokenId;
        address winning;
        uint256 price;
        Status status;
    }

    // ============ Permit ============

    struct PermitSig {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // ============ Draft ============

    struct Draft {
        uint256 seasonId;
        uint256 divisionId;
        uint256 round;
        uint256 cardImageId;
        uint256 salt;
        address user;
        PermitSig permit;
    }

    struct ReservedPlayer {
        address user;
        uint256 cardImageId;
    }

    struct ReservationState {
        address user;
        uint256 startPeriod;
        uint256 endPeriod;
        bool redeemed;
    }

    // ============ Merkle Snapshots ============

    struct MerkleProof {
        uint256 index;
        address user;
        uint256 amount;
        bytes32[] proof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.fantasy.diamond.storage");

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

    /// @dev Gets the diamond storage by position pointer
    /// @return ds The diamond storage
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

    /// @notice Emitted when a new Diamond Cut happens
    /// @param _diamondCut The diamond cut
    /// @param _init The initializer address
    /// @param _calldata The calldata
    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    /// @dev Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    /// Emits {DiamondCut} event
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

    /// @dev Adds a function to the diamond by specifing the facet and the function selectors
    /// @param _facetAddress The address of the facet
    /// @param _functionSelectors The function selectors which
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

    /// @dev Replaces a function to the diamond by specifing the facet and the function selectors
    /// @param _facetAddress The address of the facet
    /// @param _functionSelectors The function selectors which
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

    /// @dev Removes a function to the diamond by specifing the facet and the function selectors
    /// @param _facetAddress The address of the facet
    /// @param _functionSelectors The function selectors which
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

    /// @dev Adds a facet to the diamond
    /// @param _facetAddress The address of the facet that's being added
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

    /// @dev Adds a function to the diamond storage by specifing the facet address using selector and selector position
    /// @param ds The diamond storage
    /// @param _selector The selector to use
    /// @param _selectorPosition The position of the selector
    /// @param _facetAddress The address of the facet
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

    /// @dev Removes a function from the diamond storage by specifing the facet address using selector
    /// @param ds The diamond storage
    /// @param _facetAddress The address of the facet
    /// @param _selector The selector to use
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

    /// @dev Initializes the diamond cut by using init address and calldata
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
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

    /// @dev Enforces that the contract specified has code
    /// @param _contract The contract for verification
    /// @param _errorMessage The error message
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
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
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