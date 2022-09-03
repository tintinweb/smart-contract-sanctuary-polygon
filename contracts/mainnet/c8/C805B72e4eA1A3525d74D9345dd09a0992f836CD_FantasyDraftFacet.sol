// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibFantasyCoreStorage} from "../libraries/LibFantasyCoreStorage.sol";
import {LibFantasyExternalStorage} from "../libraries/LibFantasyExternalStorage.sol";
import {LibFantasyDraftStorage} from "../libraries/LibFantasyDraftStorage.sol";
import {EIP712DraftPick} from "../cryptography/EIP712DraftPick.sol";
import {DraftPickLib} from "../libraries/DraftPickLib.sol";

import "../interfaces/IFantasyAuctionFacet.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/IGen2PlayerToken.sol";
import "../interfaces/IFantasyLeague.sol";
import "../interfaces/IFantasyDraftFacet.sol";
import "../interfaces/INomoNFT.sol";

contract FantasyDraftFacet is IFantasyDraftFacet, EIP712DraftPick {
    // ============ Constructor ============
    function initializeDraft(DataTypes.DraftCtrArgs memory args) external {
        setTotalRounds(args.totalRounds);
        setDraftStartDate(args.draftStartDate);
        setReserveExpirationTime(args.expirationTime);
        setDraftPrice(args.draftPrice);
    }

    /// @notice Set the max rounds for the draft
    /// @param _totalRounds The total rounds to set
    /// Emits a {TotalRoundsSet} event.
    function setTotalRounds(uint8 _totalRounds) public {
        LibOwnership.enforceIsContractOwner();
        LibFantasyDraftStorage.dstorage().totalRounds = _totalRounds;

        emit TotalRoundsSet(_totalRounds);
    }

    /// @notice Sets draft start date
    /// @param _draftStartDate start date
    function setDraftStartDate(uint256 _draftStartDate) public {
        LibOwnership.enforceIsContractOwner();

        LibFantasyDraftStorage.dstorage().draftStartDate = _draftStartDate;
        emit DraftStartDateSet(_draftStartDate);
    }

    /// @notice Sets draft price
    /// @param _draftPrice price that needs to be paid when user picks a draft
    function setDraftPrice(uint256 _draftPrice) public {
        LibOwnership.enforceIsContractOwner();

        LibFantasyDraftStorage.dstorage().draftPrice = _draftPrice;
        emit DraftPriceSet(_draftPrice);
    }

    /**
     * @dev Updates the expiration period for the reserved player
     * @param expirationTime expiration period for the reservation of the player
     * Emits a {ReserveExpirationTimeSet} event.
     */
    function setReserveExpirationTime(uint256 expirationTime) public {
        LibOwnership.enforceIsContractOwner();

        require(
            expirationTime >= block.timestamp + 1 hours,
            "Invalid expiration"
        );

        LibFantasyDraftStorage
            .dstorage()
            .reserveExpirationTime = expirationTime;

        emit ReserveExpirationTimeSet(expirationTime);
    }

    /**
     * @dev Gets the draft order on how will be sorted users upon initialization of the contract
     * @param seasonId the season of the fantasy league
     * @param divisionId the division in the current season of the fantasy league
     * @return sorted addresses of the users
     */
    function getDraftOrder(uint256 seasonId, uint256 divisionId)
        external
        view
        returns (address[] memory)
    {
        uint8 round_ = LibFantasyDraftStorage.dstorage().round[seasonId][
            divisionId
        ];

        LibFantasyCoreStorage.Storage storage coreDs = LibFantasyCoreStorage
            .dstorage();

        if (round_ % 2 != 0) {
            address[] memory toBeReturned = coreDs.users[seasonId][divisionId];
            return toBeReturned;
        }

        address[] memory reversedOrder = new address[](
            coreDs.maxDivisionMembers
        );
        uint256 j = coreDs.maxDivisionMembers;
        for (uint256 i = 0; i < coreDs.maxDivisionMembers; i++) {
            reversedOrder[j - 1] = coreDs.users[seasonId][divisionId][i];
            j--;
        }

        return reversedOrder;
    }

    /**
     * @dev Gets the global start date for the Draft process
     * @return draftStartDate_
     */
    function draftStartDate() external view returns (uint256 draftStartDate_) {
        draftStartDate_ = LibFantasyDraftStorage.dstorage().draftStartDate;
    }

    /**
     * @dev Gets the draft order on how will be sorted users upon initialization of the contract
     * @param seasonId the season of the fantasy league
     * @param divisionId the division in the current season of the fantasy league
     * @return round_ sorted addresses of the users
     */
    function round(uint256 seasonId, uint256 divisionId)
        public
        view
        returns (uint8 round_)
    {
        round_ = LibFantasyDraftStorage.dstorage().round[seasonId][divisionId];
    }

    /// @notice Gets the time for which a player is reserved
    /// @return reserveExpirationTime_ The reserve expiration time
    function reserveExpirationTime()
        external
        view
        returns (uint256 reserveExpirationTime_)
    {
        reserveExpirationTime_ = LibFantasyDraftStorage
            .dstorage()
            .reserveExpirationTime;
    }

    /// @notice Gets the reservation state of a player
    /// @param seasonId The season to check for
    /// @param divisionId The division to check for
    /// @param tokenId The token to check for
    /// @return state_ The reservation state of the player
    function reservedPlayers(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    ) external view returns (DataTypes.ReservationState memory state_) {
        state_ = LibFantasyDraftStorage.dstorage().reservedPlayers[seasonId][
            divisionId
        ][tokenId];
    }

    /// @notice Gets the global draft price which the user should be willing to pay in order to receive a player
    /// @return draftPrice_ draft price
    function draftPrice() external view returns (uint256 draftPrice_) {
        draftPrice_ = LibFantasyDraftStorage.dstorage().draftPrice;
    }

    /**
     * @dev Gets the total rounds for the draft
     * @return totalRounds_ sorted addresses of the users
     */
    function totalRounds() public view returns (uint8 totalRounds_) {
        totalRounds_ = LibFantasyDraftStorage.dstorage().totalRounds;
    }

    /// @notice Checks if the round is processed
    /// @param seasonId The season to check for
    /// @param divisionId The division to check for
    /// @param currentRound The round to check for
    /// @return If the round is processed
    function roundProcessed(
        uint256 seasonId,
        uint256 divisionId,
        uint8 currentRound
    ) external view returns (bool) {
        return
            LibFantasyDraftStorage.dstorage().roundProcessed[seasonId][
                divisionId
            ][currentRound];
    }

    /// @notice Process round
    /// @dev Checks if all drafts match all signatures or reserved players and either drafts each player to their corresponding user
    ///       or reserves a player for the corresponding user
    /// @param drafts The drafts for the round to process
    /// @param signatures The signatures for the drafts for the round to process
    /// @param _reservedPlayers The players to reserve and their corresponding user
    /// Emits a {RoundProcessed} event
    function processRound(
        DataTypes.Draft[] memory drafts,
        bytes[] memory signatures,
        DataTypes.ReservedPlayer[] memory _reservedPlayers
    ) external {
        LibFantasyDraftStorage.enforceHasDraftStarted();
        LibAccessControl.onlyRole(LibAccessControl.executorRole());

        require(
            drafts.length + _reservedPlayers.length > 0 &&
                drafts.length + _reservedPlayers.length <=
                LibFantasyCoreStorage.dstorage().maxDivisionMembers,
            "Invalid length. Cannot process round"
        );

        LibFantasyDraftStorage.Storage storage ds = LibFantasyDraftStorage
            .dstorage();

        uint256 seasonId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).getSeasonId();

        uint256 divisionId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).getUserDivisionId(
                seasonId,
                drafts.length != 0 ? drafts[0].user : _reservedPlayers[0].user
            );

        uint8 currentRound = ds.round[seasonId][divisionId];

        LibFantasyCoreStorage.enforceSeasonNotPaused(seasonId);

        require(
            currentRound <= ds.totalRounds &&
                !ds.roundProcessed[seasonId][divisionId][currentRound],
            "Draft already ended"
        );

        require(drafts.length == signatures.length, "Sig mismatch");

        ds.roundProcessed[seasonId][divisionId][currentRound] = true;

        for (uint256 i = 0; i < _reservedPlayers.length; i++) {
            if (
                IFantasyLeague(
                    LibFantasyExternalStorage.dstorage().fantasyLeague
                ).isUser(seasonId, _reservedPlayers[i].user)
            ) {
                reservePlayer(_reservedPlayers[i]);
            }
        }

        for (uint256 i = 0; i < drafts.length; i++) {
            if (
                seasonId == drafts[i].seasonId &&
                divisionId == drafts[i].divisionId &&
                IFantasyLeague(
                    LibFantasyExternalStorage.dstorage().fantasyLeague
                ).isUser(seasonId, drafts[i].user)
            ) {
                draftPlayer(drafts[i], signatures[i]);
            }
        }

        if (currentRound < totalRounds()) {
            ds.round[seasonId][divisionId]++;
        }

        emit RoundProcessed(
            seasonId,
            divisionId,
            ds.round[seasonId][divisionId]
        );
    }

    // ============ Private functions ============

    /// @dev Drafts a player to a user based on a draft and signature
    ///      also transfers the correct amount of tokens from the users to the contract using permit. Mints a PlayerV2 Token on success
    /// @param draft The draft tuple of a player that is going to be verified and executed.
    /// @param signature The signature which is being verified. Encompass Draft Tuple and Permit sig
    /// Emits {PlayerDrafted} event
    function draftPlayer(DataTypes.Draft memory draft, bytes memory signature)
        private
    {
        LibFantasyExternalStorage.Storage
            storage externalDs = LibFantasyExternalStorage.dstorage();

        uint256 seasonId = IFantasyLeague(externalDs.fantasyLeague)
            .getSeasonId();
        uint256 divisionId = IFantasyLeague(externalDs.fantasyLeague)
            .getUserDivisionId(seasonId, draft.permit.owner);

        ///@dev not recommended to revert here, as it will stop the whole transaction for all the users to be processed, rather than just omit the one with invalid value
        if (
            draft.permit.value != LibFantasyDraftStorage.dstorage().draftPrice
        ) {
            emit IncorrectTokenAmount(
                draft.permit.value,
                LibFantasyDraftStorage.dstorage().draftPrice,
                round(seasonId, divisionId),
                draft.permit.owner
            );
            return;
        }

        if (
            IGen2PlayerToken(externalDs.playerV2).isImageInDivision(
                draft.seasonId,
                draft.divisionId,
                draft.cardImageId
            )
        ) {
            emit ImageExists(
                draft.cardImageId,
                round(seasonId, divisionId),
                divisionId,
                draft.permit.owner
            );

            return;
        }

        verify(draft, signature);

        uint256 tokenId = IGen2PlayerToken(externalDs.playerV2).mint(
            draft.cardImageId,
            divisionId,
            draft.permit.owner
        );

        LibFantasyCoreStorage.assignToRoster(
            seasonId,
            divisionId,
            draft.permit.owner,
            tokenId
        );

        IERC20Permit(externalDs.dLeagToken).permit(
            draft.permit.owner,
            draft.permit.spender,
            draft.permit.value,
            draft.permit.deadline,
            draft.permit.v,
            draft.permit.r,
            draft.permit.s
        );

        IERC20Permit(externalDs.dLeagToken).transferFrom(
            draft.permit.owner,
            address(this),
            draft.permit.value
        );

        emit PlayerDrafted(
            seasonId,
            divisionId,
            draft.round,
            draft.permit.owner,
            tokenId,
            draft.cardImageId
        );
    }

    /// @dev Reserves a player for a user for a specific period which consists of the current timestamp
    ///      for the startPeriod and the current timestamp + the reserveExpirationTime for the endPeriod
    /// @param reservedPlayer The player that is being reserving for the corresponding user which was afk during the current round
    /// Emits {PlayerReserved} event
    function reservePlayer(DataTypes.ReservedPlayer memory reservedPlayer)
        private
    {
        LibFantasyCoreStorage.enforceValidAddress(reservedPlayer.user);
        LibFantasyDraftStorage.Storage storage ds = LibFantasyDraftStorage
            .dstorage();

        uint256 seasonId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).getSeasonId();

        uint256 divisionId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).getUserDivisionId(seasonId, reservedPlayer.user);

        ///@dev not recommended to revert here, as it will stop the whole transaction for all the users to be processed, rather than just omit the one with invalid value
        if (
            !INomoNFT(LibFantasyExternalStorage.dstorage().nomoNft)
                .cardImageToExistence(reservedPlayer.cardImageId)
        ) {
            emit ImageDoesNotExist(
                reservedPlayer.cardImageId,
                reservedPlayer.user,
                divisionId,
                round(seasonId, divisionId)
            );
            return;
        }

        ///@dev not recommended to revert here, as it will stop the whole transaction for all the users to be processed, rather than just omit the one with invalid value
        if (
            IGen2PlayerToken(LibFantasyExternalStorage.dstorage().playerV2)
                .isImageInDivision(
                    seasonId,
                    divisionId,
                    reservedPlayer.cardImageId
                )
        ) {
            emit ImageExists(
                reservedPlayer.cardImageId,
                round(seasonId, divisionId),
                divisionId,
                reservedPlayer.user
            );
            return;
        }

        ds.reservedPlayers[seasonId][divisionId][
            reservedPlayer.cardImageId
        ] = DataTypes.ReservationState({
            user: reservedPlayer.user,
            startPeriod: block.timestamp,
            endPeriod: ds.reserveExpirationTime,
            redeemed: false
        });

        emit PlayerReserved(
            seasonId,
            divisionId,
            round(seasonId, divisionId),
            reservedPlayer.user,
            reservedPlayer.cardImageId,
            block.timestamp,
            ds.reserveExpirationTime
        );
    }
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
import "@openzeppelin/contracts/utils/Strings.sol";

library LibAccessControl {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.fantasy.access.control.storage");

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Storage {
        RoleData roleData;
        mapping(bytes32 => RoleData) _roles;
        bytes32 DEFAULT_ADMIN_ROLE;
    }

    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function defaultAdminRole() internal pure returns (bytes32) {
        return 0x00;
    }

    function executorRole() internal pure returns (bytes32) {
        return keccak256("EXECUTOR_ROLE");
    }

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
    function onlyRole(bytes32 role) internal view {
        _checkRole(role, msg.sender);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return dstorage()._roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return dstorage()._roles[role].adminRole;
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
    function grantRole(bytes32 role, address account) internal {
        onlyRole(getRoleAdmin(role));
        _grantRole(role, account);
    }

    function grantExecutorRole(address account) internal {
        onlyRole(defaultAdminRole());
        _grantRole(executorRole(), account);
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
    function revokeRole(bytes32 role, address account) internal {
        onlyRole(getRoleAdmin(role));
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
    function renounceRole(bytes32 role, address account) internal {
        require(
            account == msg.sender,
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    function initAccessControl() internal {
        dstorage().DEFAULT_ADMIN_ROLE = defaultAdminRole();
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

    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        dstorage()._roles[role].adminRole = adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            dstorage()._roles[role].members[account] = true;
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     */
    function _revokeRole(bytes32 role, address account) internal {
        onlyRole(getRoleAdmin(role));
        if (hasRole(role, account)) {
            dstorage()._roles[role].members[account] = false;
        }
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

        require(
            coreDs.roster[seasonId][divisionId][user] < coreDs.maxRosterSize,
            "Exceeds roster limit"
        );

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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {DataTypes} from "../libraries/types/DataTypes.sol";

abstract contract EIP712DraftPick is Context {
    using Address for address;

    /// @dev The EIP712 Domain Typehash
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The draft typehash
    bytes32 private constant DRAFT_TYPEHASH =
        keccak256(
            "Draft(uint256 seasonId,uint256 divisionId,uint256 round,uint256 cardImageId,uint256 salt,address user,PermitSig permit)PermitSig(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)"
        );

    /// @dev The permit typehash
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "PermitSig(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)"
        );

    struct Draft {
        /// @notice Current season that is being played
        uint256 seasonId;
        /// @notice Current division that is being played
        uint256 divisionId;
        /// @notice Current round that is being played
        uint256 round;
        /// @notice Current cardImageId that is being drafted
        uint256 cardImageId;
        /// @notice Current salt that is being used
        uint256 salt;
        /// @notice Current user that is being drafted for
        address user;
        /// @notice Current permit signature used for drafting
        DataTypes.PermitSig permit;
    }

    /// @notice Gets the domain separator
    /// @return The hash of the domain separator
    function DOMAIN_SEPARATOR() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("playerDraft"), // string name
                    keccak256("1"), // string version
                    block.chainid, // uint256 chainId
                    address(this) // address verifyingContract
                )
            );
    }

    /// @notice Gets the hash of a permit
    /// @param permit The permit to hash
    /// @return The hash of the permit
    function hashPermit(DataTypes.PermitSig memory permit)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permit.owner,
                    permit.spender,
                    permit.value,
                    permit.deadline,
                    permit.v,
                    permit.r,
                    permit.s
                )
            );
    }

    /// @notice Gets the hash of a draft
    /// @param draft The draft tuple that will be hashed
    /// @return The hash of the draft
    function hashDraft(DataTypes.Draft memory draft)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            DRAFT_TYPEHASH,
                            draft.seasonId,
                            draft.divisionId,
                            draft.round,
                            draft.cardImageId,
                            draft.salt,
                            draft.user,
                            hashPermit(draft.permit)
                        )
                    )
                )
            );
    }

    /// @notice Gets if the signature is valid
    /// @param draft The draft to validate
    /// @param signature The signature to validate with
    function verify(DataTypes.Draft memory draft, bytes memory signature)
        public
        view
    {
        bytes32 hash = hashDraft(draft);
        require(
            SignatureChecker.isValidSignatureNow(draft.user, hash, signature),
            "draft signature verification error"
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

        address[] memory spliced = new address[](array.length - 1);
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
pragma solidity 0.8.9;
import {DataTypes} from "../libraries/types/DataTypes.sol";

import "./IUserRoster.sol";

interface IFantasyAuctionFacet is IUserRoster {
    event MinAuctionAmountSet(uint256 newAmount);
    event OutbidAmountSet(uint256 newAmount);
    event AuctionStopsSet(uint256 softStop, uint256 hardStop);
    event PriceUpdate(address indexed user, uint256 price);
    event AuctionStarted(
        address indexed user,
        uint256 price,
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId,
        uint256 cardImageId,
        uint256 tokenId,
        uint256 start,
        uint256 softStop,
        uint256 hardStop
    );

    event AuctionBid(
        address indexed user,
        uint256 price,
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId,
        uint256 newSoftEnd
    );

    event AuctionWon(
        address indexed user,
        uint256 price,
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId,
        uint256 cardImageId,
        uint256 tokenId
    );

    /// @dev Constructor
    function initializeAuction(DataTypes.AuctionCtrArgs memory args) external;

    // ============ Setters ============

    /// @notice Sets minimum starting amount for starting a draft
    /// @param _minAuctionAmount Minimum auction amount
    function setMinAuctionAmount(uint256 _minAuctionAmount) external;

    /// @notice Sets minimum outbid step above the current amount in order to bid in an auction
    /// @param _newOutbidAmount Minimum outbid amount
    function setMinOutbidAmount(uint256 _newOutbidAmount) external;

    /// @notice Sets soft / hard stops when an auction will finish
    /// @param _softStop Minimum delay in time before a user can win, if nobody else outbids
    /// @param _hardStop Maximum amount of time to which an auction can prolong
    function setStops(uint256 _softStop, uint256 _hardStop) external;

    // ============ Getters ============

    /// @notice Gets current value of auction id counter
    /// @param seasonId The current seasonId
    /// @param divisionId The current divisionId
    /// @return counter_ The counter value
    function auctionIdCounter(uint256 seasonId, uint256 divisionId)
        external
        view
        returns (uint256);

    /// @notice Gets the minimum amount for starting an auction
    /// @return minAuctionAmount_ The minumum auction amount
    function minAuctionAmount() external view returns (uint256);

    /// @notice Gets soft stop, during which if no body places a bet, the auction ends and the winner can claim the reward
    /// @return softStop_ The soft stop value
    function outbidAmount() external view returns (uint256);

    /// @notice Gets soft stop, during which if no body places a bet, the auction ends and the winner can claim the reward
    /// @return softStop_ The soft stop value
    function softStop() external view returns (uint256);

    /// @notice Gets the hard deadline when an auction must finish, in order to prevent an endless auction
    /// @return hardStop_ The hard stop value
    function hardStop() external view returns (uint256);

    /// @notice Get the current auction state
    /// @param seasonId The ID of the season
    /// @param divisionId The ID of the division
    /// @param auctionId The ID of the auction
    /// @return aucState_ The state of the auction
    function auctionState(
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId
    ) external view returns (DataTypes.AuctionState memory);

    /// @notice Get all auctions for season and division
    /// @param seasonId The ID of the season
    /// @param divisionId The ID of the division
    /// @return auctions_ All auctions
    function auctions(uint256 seasonId, uint256 divisionId)
        external
        view
        returns (DataTypes.AuctionState[] memory);

    /// @notice Check if token has an active auction
    /// @param seasonId The ID of the season
    /// @param divisionId The ID of the division
    /// @param cardImageId The gen2 Player token which the auction will be against
    /// @return hasActiveAuction_ The player token has an active auction
    function hasActiveAuction(
        uint256 seasonId,
        uint256 divisionId,
        uint256 cardImageId
    ) external view returns (bool);

    /// @notice kick off an auction for a specific season and division
    /// @param cardImageId The gen2 Player token which the auction will be against
    /// @param permitSig Permit signature as struct for the owner, spender and value in order for a permit to be successful
    function auctionStart(
        uint256 cardImageId,
        DataTypes.PermitSig calldata permitSig
    ) external;

    /// @notice Place new bid for an active auction in a certain season and division against gen2 Player token
    /// @param auctionId Auction which is about to be finished
    /// @param permitSig Permit signature as struct for the owner, spender and value in order for a permit to be successful
    function auctionBid(
        uint256 auctionId,
        DataTypes.PermitSig calldata permitSig
    ) external;

    /// @notice Finishes an active auction in a certain season and division against gen2 Player token
    /// @param seasonId Season id for the actual sporting season the auction is placed
    /// @param divisionId Division id where this auction will be started
    /// @param auctionId Auction which is about to be finished
    function endAuction(
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.9;

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
    ) external returns (uint256);

    function burn(uint256 tokenId) external;

    function isImageInDivision(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    ) external returns (bool);

    function nftIdToDivisionId(uint256 tokenId) external returns (uint256);

    function nftIdToImageId(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFantasyLeague {
    function getUserDivisionId(uint256 _season, address _user)
        external
        view
        returns (uint256);

    function seasonId() external view returns (uint256);

    function getSeasonId() external view returns (uint256);

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
pragma solidity 0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import "./IUserRoster.sol";

interface IFantasyDraftFacet is IUserRoster {
    event ReserveExpirationTimeSet(uint256 reserveExpirationTime);
    event DraftStartDateSet(uint256 draftStartDate);
    event RoundProcessed(uint256 seasonId, uint256 divisionId, uint8 round);
    event TotalRoundsSet(uint8 rounds);
    event DraftPriceSet(uint256 draftPrice);
    event IncorrectTokenAmount(
        uint256 incorrect,
        uint256 correct,
        uint256 round,
        address user
    );
    event ImageExists(
        uint256 cardImageId,
        uint256 round,
        uint256 division,
        address user
    );

    event ImageDoesNotExist(
        uint256 cardImageId,
        address user,
        uint256 division,
        uint256 round
    );

    event PlayerDrafted(
        uint256 seasonId,
        uint256 divisionId,
        uint256 round,
        address user,
        uint256 tokenId,
        uint256 cardImageId
    );

    event PlayerReserved(
        uint256 seasonId,
        uint256 divisionId,
        uint256 round,
        address user,
        uint256 cardImageId,
        uint256 startPeriod,
        uint256 endPeriod
    );

    // ============ Constructor ============
    function initializeDraft(DataTypes.DraftCtrArgs memory args) external;

    /// @notice Set the max rounds for the draft
    /// @param _totalRounds The total rounds to set
    /// Emits a {TotalRoundsSet} event.
    function setTotalRounds(uint8 _totalRounds) external;

    /// @notice Sets draft start date
    /// @param _draftStartDate start date
    function setDraftStartDate(uint256 _draftStartDate) external;

    /// @notice Sets draft price
    /// @param _draftPrice price that needs to be paid when user picks a draft
    function setDraftPrice(uint256 _draftPrice) external;

    // ============ External functions ============

    /**
     * @dev Updates the expiration period for the reserved player
     * @param expirationTime expiration period for the reservation of the player
     * Emits a {ReserveExpirationTimeSet} event.
     */
    function setReserveExpirationTime(uint256 expirationTime) external;

    /**
     * @dev Gets the draft order on how will be sorted users upon initialization of the contract
     * @param seasonId the season of the fantasy league
     * @param divisionId the division in the current season of the fantasy league
     * @return sorted addresses of the users
     */
    function getDraftOrder(uint256 seasonId, uint256 divisionId)
        external
        view
        returns (address[] memory);

    /**
     * @dev Gets the draft order on how will be sorted users upon initialization of the contract
     * @param seasonId the season of the fantasy league
     * @param divisionId the division in the current season of the fantasy league
     * returns sorted addresses of the users
     */
    function round(uint256 seasonId, uint256 divisionId)
        external
        view
        returns (uint8 round_);

    function reserveExpirationTime()
        external
        view
        returns (uint256 reserveExpirationTime_);

    function reservedPlayers(
        uint256 seasonId,
        uint256 divisionId,
        uint256 tokenId
    ) external view returns (DataTypes.ReservationState memory state_);

    function draftPrice() external view returns (uint256);

    /**
     * @dev Gets the total rounds for the draft
     * returns sorted addresses of the users
     */
    function totalRounds() external view returns (uint8 totalRounds_);

    /// @notice Checks if the round is processed
    /// @param seasonId The season to check for
    /// @param divisionId The division to check for
    /// @param currentRound The round to check for
    /// @return If the round is processed
    function roundProcessed(
        uint256 seasonId,
        uint256 divisionId,
        uint8 currentRound
    ) external view returns (bool);

    /// @notice Process round
    /// @dev Checks if all drafts match all signatures or reserved players and either drafts each player to their corresponding user
    ///       or reserves a player for the corresponding user
    /// @param drafts The drafts for the round to process
    /// @param signatures The signatures for the drafts for the round to process
    /// @param _reservedPlayers The players to reserve and their corresponding user
    /// Emits a {RoundProcessed} event
    function processRound(
        DataTypes.Draft[] memory drafts,
        bytes[] memory signatures,
        DataTypes.ReservedPlayer[] memory _reservedPlayers
    ) external;

    /**
     * @dev Gets the global start date for the Draft process
     * @return draftStartDate_
     */
    function draftStartDate() external view returns (uint256 draftStartDate_);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INomoNFT is IERC721 {
    function getCardImageDataByTokenId(uint256 _tokenId)
        external
        view
        returns (
            string memory name,
            string memory imageURL,
            uint256 league,
            uint256 gen,
            uint256 playerPosition,
            uint256 parametersSetId,
            string[] memory parametersNames,
            uint256[] memory parametersValues,
            uint256 parametersUpdateTime
        );

    function getCardImage(uint256 _cardImageId)
        external
        view
        returns (
            string memory name,
            string memory imageURL,
            uint256 league,
            uint256 gen,
            uint256 playerPosition,
            uint256 parametersSetId,
            string[] memory parametersNames,
            uint256[] memory parametersValues,
            uint256 parametersUpdateTime
        );

    function PARAMETERS_DECIMALS() external view returns (uint256);

    function cardImageToExistence(uint256) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUserRoster {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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