// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IFantasyCoreFacet.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {LibFantasyDraftStorage} from "../libraries/LibFantasyDraftStorage.sol";
import {LibFantasyCoreStorage} from "../libraries/LibFantasyCoreStorage.sol";
import {LibFantasyExternalStorage} from "../libraries/LibFantasyExternalStorage.sol";

import "../interfaces/IERC20Permit.sol";
import "../interfaces/IGen2PlayerToken.sol";
import "../interfaces/IFantasyLeague.sol";
import "../interfaces/IFantasyOperationsFacet.sol";

contract FantasyOperationsFacet is IFantasyOperationsFacet {
    // ============ External Functions ============

    function dropPlayer(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    ) external {
        LibFantasyDraftStorage.enforceDraftEnded(seasonId, divisionId);

        LibFantasyExternalStorage.Storage storage ds = LibFantasyExternalStorage
            .dstorage();

        LibFantasyCoreStorage.removeFromRoster(
            seasonId,
            divisionId,
            msg.sender,
            tokenId
        );

        //TODO blaize: will need integration with the Blaize contracts in regards to pointing out which params to pass when burning aka divsionId/tokenId
        IGen2PlayerToken(ds.playerV2).burn(tokenId);
        if (
            block.timestamp <
            LibFantasyCoreStorage.dstorage().tournamentStartDate
        ) {
            IERC20Permit(ds.dLeagToken).transfer(msg.sender, 1 * 10**18); //todo this should be with a variable
        }
        emit PlayerDropped(seasonId, divisionId, tokenId, msg.sender);
    }

    function buyPlayers(
        uint256[] memory _tokenIds,
        DataTypes.PermitSig memory permit
    ) public {
        LibFantasyDraftStorage.Storage storage draftDs = LibFantasyDraftStorage
            .dstorage();

        LibFantasyExternalStorage.Storage
            storage externalDs = LibFantasyExternalStorage.dstorage();

        uint256 seasonId = IFantasyLeague(externalDs.fantasyLeague).seasonId();

        require(
            IFantasyLeague(externalDs.fantasyLeague).isUser(
                seasonId,
                msg.sender
            ),
            "User is not participant in curr season"
        );

        uint256 divisionId = IFantasyLeague(externalDs.fantasyLeague)
            .UserToDivision(permit.owner);

        LibFantasyDraftStorage.enforceDraftEnded(seasonId, divisionId);

        uint256 _totalCost = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            DataTypes.ReservationState memory _state = draftDs.reservedPlayers[
                seasonId
            ][divisionId][_tokenIds[i]];

            if (
                block.timestamp > _state.startPeriod &&
                block.timestamp < _state.endPeriod
            ) {
                require(!_state.redeemed, "Player Draft: player already owned");

                require(
                    _state.user == msg.sender,
                    "Player Draft: this is already reserved and reservation has not expired"
                );

                draftDs
                .reservedPlayers[seasonId][divisionId][_tokenIds[i]]
                    .redeemed = true;
            }
            LibFantasyCoreStorage.assignToRoster(
                seasonId,
                divisionId,
                msg.sender,
                _tokenIds[i]
            );

            IGen2PlayerToken(externalDs.playerV2).mint(
                _tokenIds[i],
                divisionId,
                permit.owner
            );
        }

        _totalCost = _tokenIds.length * 1 * 10**18; //todo this price needs to be with a setter

        IERC20Permit(externalDs.dLeagToken).permit(
            permit.owner,
            permit.spender,
            _totalCost,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );

        //todo check whether correct token is being used while buyPlayers
        IERC20Permit(externalDs.dLeagToken).transferFrom(
            permit.owner,
            address(this),
            _totalCost
        );

        //todo unify event with draftPlayer. Might use Player bought on both places.. required params
        /**
        emit PlayerDrafted(
            seasonId,
            divisionId,
            round[seasonId][divisionId],
            msg.sender,
            _tokenIds[0]
        ); */
        emit PlayerBought(msg.sender, _tokenIds, _tokenIds.length, _totalCost);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IFantasyCoreFacet {
    event TournamentStartDateSet(uint256 tournamentStartDate);
    event MaxDivisionMembersSet(uint256 maxDivisionMembers);
    event MaxRosterSizeUpdated(uint256 maxRosterSize);

    function initializeCore(DataTypes.CoreCtrArgs memory _args) external;

    // @notice Sets tournament start date
    /// @param _tournamentStartDate start date
    function setTournamentStartDate(uint256 _tournamentStartDate) external;

    /// @notice Sets max division members
    /// @param _maxDivisionMembers the max number of division members
    function setMaxDivisionMembers(uint256 _maxDivisionMembers) external;

    /// @notice Sets max roster length
    /// @param _maxRosterSize the max players a user can have in his roster
    function setMaxRosterSize(uint256 _maxRosterSize) external;

    function getRoster(
        uint256 seasonId,
        uint256 divisionId,
        address user
    ) external view returns (uint256 _roster);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library DataTypes {
    // ============ Constructor Args ============
    struct ExternalCtrArgs {
        address playerV2;
        address leagToken;
        address dLeagToken;
        address nomoNft;
        address leagRewardPool;
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
        uint256 playerTokenId;
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
        uint256 tokenId;
        uint256 salt;
        address user;
        PermitSig permit;
    }

    struct ReservedPlayer {
        //todo might have seasonId and divisionId
        address user;
        uint256 tokenId;
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
pragma solidity ^0.8.0;

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
    }

    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enforceHasDraftStarted() internal view {
        require(
            block.timestamp > dstorage().draftStartDate,
            "Draft has not started!"
        );
    }

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
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

library LibFantasyCoreStorage {
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
        //todo move in draft storage
        /// @notice season id => division id => is draft ended
        mapping(uint256 => mapping(uint256 => bool)) draftEnded;
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
    }

    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enforceValidAddress(address _address) internal pure {
        require(_address != address(0), "Not a valid address");
    }

    function encoreTournamentStarted() internal view {
        require(
            block.timestamp > dstorage().tournamentStartDate,
            "Tournament not started!"
        );
    }

    //!todo tests! Should be tested through processRound, buyPlayer, RemovePlayer
    function assignToRoster(
        uint256 seasonId,
        uint256 divisionId,
        address user,
        uint256 tokenId
    ) internal {
        LibFantasyCoreStorage.Storage storage coreDs = dstorage();

        require(
            coreDs.roster[seasonId][divisionId][user] < coreDs.maxRosterSize,
            "exceeds roster limit"
        );

        coreDs.roster[seasonId][divisionId][user]++;
        emit UserRosterUpdated(seasonId, divisionId, user, tokenId, true);
    }

    function removeFromRoster(
        uint256 seasonId,
        uint256 divisionId,
        address user,
        uint256 tokenId
    ) internal {
        LibFantasyCoreStorage.Storage storage coreDs = dstorage();
        require(
            coreDs.roster[seasonId][divisionId][user] > 0,
            "PlayerDraft: Roster must not be empty"
        );

        coreDs.roster[seasonId][divisionId][user]--;

        emit UserRosterUpdated(seasonId, divisionId, user, tokenId, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import {DataTypes} from "./types/DataTypes.sol";

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
        /// @notice Fantasy League contract
        address fantasyLeague;
    }

    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IGen2PlayerToken {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) external;

    /// @notice Mints gen 2 player token
    /// @param _playerImageId Id of player image
    /// @param _divisionId Id of division to which NFT belongs to
    /// @param _user Address to which NFT will be minted to
    function mint(
        uint256 _playerImageId,
        uint256 _divisionId,
        address _user
    ) external;

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFantasyLeague {
    function UserToDivision(address user_address)
        external
        pure
        returns (uint256);

    function seasonId() external pure returns (uint256);

    function isUser(uint256 seasonId, address user)
        external
        pure
        returns (bool);

    function getNumberOfUsers() external view returns (uint256);

    function getNumberOfDivisions() external view returns (uint256);

    function getDivisionUsers(uint256 _season, uint256 _division) external view returns (address[] memory division);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IFantasyOperationsFacet {
    event PlayerDropped(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId,
        address user
    );

    event PlayerBought(
        address indexed user,
        uint256[] tokenIds,
        uint256 count,
        uint256 indexed value
    );

    function dropPlayer(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    ) external;

    function buyPlayers(
        uint256[] memory _tokenIds,
        DataTypes.PermitSig memory permit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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