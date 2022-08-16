// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {LibOwnership} from "../libraries/LibOwnership.sol";
import {LibFantasyExternalStorage} from "../libraries/LibFantasyExternalStorage.sol";
import {LibFantasyCoreStorage} from "../libraries/LibFantasyCoreStorage.sol";
import {LibFantasyAuctionStorage} from "../libraries/LibFantasyAuctionStorage.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {DraftPickLib} from "../libraries/DraftPickLib.sol";

import "../interfaces/IFantasyAuctionFacet.sol";
import "../interfaces/IFantasyLeague.sol";
import "../interfaces/IGen2PlayerToken.sol";
import "../interfaces/IERC20Permit.sol";

contract FantasyAuctionFacet is IFantasyAuctionFacet, ERC721Holder {
    using SafeERC20 for IERC20Permit;
    using Counters for Counters.Counter;

    // ============ Constructor ============
    function initializeAuction(DataTypes.AuctionCtrArgs memory args) external {
        setMinAuctionAmount(args.minAuctionAmount);
        setMinOutbidAmount(args.outbidAmount);
        setStops(args.softStop, args.hardStop);
    }

    // ============ Setters ============

    /// @notice Sets minimum starting amount for starting a draft
    /// @param _minAuctionAmount Minimum auction amount
    function setMinAuctionAmount(uint256 _minAuctionAmount) public {
        LibOwnership.enforceIsContractOwner();

        LibFantasyAuctionStorage
            .dstorage()
            .minAuctionAmount = _minAuctionAmount;
        emit MinAuctionAmountSet(_minAuctionAmount);
    }

    /// @notice Sets minimum outbid step above the current amount in order to bid in an auction
    /// @param _newOutbidAmount Minimum outbid amount
    function setMinOutbidAmount(uint256 _newOutbidAmount) public {
        LibOwnership.enforceIsContractOwner();

        LibFantasyAuctionStorage.dstorage().outbidAmount = _newOutbidAmount;
        emit OutbidAmountSet(_newOutbidAmount);
    }

    /// @notice Sets soft / hard stops when an auction will finish
    /// @param _softStop Minimum delay in time before a user can win, if nobody else outbids
    /// @param _hardStop Maximum amount of time to which an auction can prolong
    function setStops(uint256 _softStop, uint256 _hardStop) public {
        LibOwnership.enforceIsContractOwner();

        require(_softStop != 0 && _hardStop != 0, "Incorrect stops provided");
        require(_softStop < _hardStop, "HardStop must be greater");

        LibFantasyAuctionStorage.dstorage().softStop = _softStop;
        LibFantasyAuctionStorage.dstorage().hardStop = _hardStop;
        emit AuctionStopsSet(_softStop, _hardStop);
    }

    // ============ Getters ============

    /// @notice Gets current value of auction id counter
    /// @param seasonId The current seasonId
    /// @param divisionId The current divisionId
    /// @return counter_ The counter value
    function auctionIdCounter(uint256 seasonId, uint256 divisionId)
        external
        view
        returns (uint256 counter_)
    {
        counter_ = LibFantasyAuctionStorage
        .dstorage()
        .auctionIdCounter[seasonId][divisionId].current();
    }

    /// @notice Gets the minimum amount for starting an auction
    /// @return minAuctionAmount_ The minumum auction amount
    function minAuctionAmount()
        external
        view
        returns (uint256 minAuctionAmount_)
    {
        minAuctionAmount_ = LibFantasyAuctionStorage
            .dstorage()
            .minAuctionAmount;
    }

    /// @notice Gets the minimum amount for an outbid to be exectued
    /// @return outbidAmount_ The outbid amount
    function outbidAmount() external view returns (uint256 outbidAmount_) {
        outbidAmount_ = LibFantasyAuctionStorage.dstorage().outbidAmount;
    }

    /// @notice Gets soft stop, during which if no body places a bet, the auction ends and the winner can claim the reward
    /// @return softStop_ The soft stop value
    function softStop() external view returns (uint256 softStop_) {
        softStop_ = LibFantasyAuctionStorage.dstorage().softStop;
    }

    /// @notice Gets the hard deadline when an auction must finish, in order to prevent an endless auction
    /// @return hardStop_ The hard stop value
    function hardStop() external view returns (uint256 hardStop_) {
        hardStop_ = LibFantasyAuctionStorage.dstorage().hardStop;
    }

    /// @notice Get the current auction state
    /// @param seasonId The ID of the season
    /// @param divisionId The ID of the division
    /// @param auctionId The ID of the auction
    /// @return aucState_ The state of the auction
    function auctionState(
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId
    ) external view returns (DataTypes.AuctionState memory aucState_) {
        aucState_ = LibFantasyAuctionStorage.dstorage().auctionState[seasonId][
            divisionId
        ][auctionId];
    }

    /// @notice Get all auctions for season and division
    /// @param seasonId The ID of the season
    /// @param divisionId The ID of the division
    /// @return auctions_ All auctions
    function auctions(uint256 seasonId, uint256 divisionId)
        external
        view
        returns (DataTypes.AuctionState[] memory auctions_)
    {
        auctions_ = LibFantasyAuctionStorage.dstorage().auctions[seasonId][
            divisionId
        ];
    }

    /// @notice Check if token has an active auction
    /// @param seasonId The ID of the season
    /// @param divisionId The ID of the division
    /// @param cardImageId The gen2 Player token which the auction will be against
    /// @return hasActiveAuction_ The player token has an active auction
    function hasActiveAuction(
        uint256 seasonId,
        uint256 divisionId,
        uint256 cardImageId
    ) external view returns (bool hasActiveAuction_) {
        hasActiveAuction_ = LibFantasyAuctionStorage
            .dstorage()
            .hasActiveAuction[seasonId][divisionId][cardImageId];
    }

    // ============ External Functions ============

    /// @notice kick off an auction for a specific season and division
    /// @param cardImageId The gen2 Player token which the auction will be against
    /// @param permitSig Permit signature as struct for the owner, spender and value in order for a permit to be successful
    function auctionStart(
        uint256 cardImageId,
        DataTypes.PermitSig calldata permitSig
    ) external {
        // LibFantasyCoreStorage.enforceTournamentStarted();

        LibFantasyAuctionStorage.Storage
            storage auctionDs = LibFantasyAuctionStorage.dstorage();

        LibFantasyExternalStorage.Storage
            storage externalDs = LibFantasyExternalStorage.dstorage();

        require(
            permitSig.value >= auctionDs.minAuctionAmount,
            "Open value too low"
        );

        uint256 seasonId = IFantasyLeague(externalDs.fantasyLeague).seasonId();

        uint256 divisionId = IFantasyLeague(externalDs.fantasyLeague)
            .getUserDivisionId(seasonId, permitSig.owner);

        LibFantasyExternalStorage.enforceIsUser(seasonId, permitSig.owner);
        // LibFantasyCoreStorage.enforceSeasonNotPaused(seasonId);

        // require(
        //     LibFantasyCoreStorage.dstorage().roster[seasonId][divisionId][
        //         permitSig.owner
        //     ] < LibFantasyCoreStorage.dstorage().maxRosterSize,
        //     "Forbidden. Roster full"
        // );

        require(
            !auctionDs.hasActiveAuction[seasonId][divisionId][cardImageId],
            "Active Auction for player"
        );

        require(
            !IGen2PlayerToken(externalDs.playerV2).isImageInDivision(
                seasonId,
                divisionId,
                cardImageId
            ),
            "Image exists"
        );

        auctionDs.auctionIdCounter[seasonId][divisionId].increment();
        uint256 auctionId = auctionDs
        .auctionIdCounter[seasonId][divisionId].current();

        auctionDs.hasActiveAuction[seasonId][divisionId][cardImageId] = true;

        IERC20Permit(externalDs.leagToken).permit(
            permitSig.owner,
            permitSig.spender,
            permitSig.value,
            permitSig.deadline,
            permitSig.v,
            permitSig.r,
            permitSig.s
        );

        // IERC20Permit(externalDs.leagToken).transferFrom(
        //     permitSig.owner,
        //     address(this),
        //     permitSig.value
        // );

        uint256 tokenId = IGen2PlayerToken(externalDs.playerV2).mint(
            cardImageId,
            divisionId,
            address(this)
        );

        // LibFantasyCoreStorage.assignToRoster(
        //     seasonId,
        //     divisionId,
        //     permitSig.owner,
        //     tokenId
        // );

        auctionDs.auctionState[seasonId][divisionId][auctionId] = DataTypes
            .AuctionState({
                auctionId: auctionId,
                auctionStart: block.timestamp,
                auctionSoftStop: block.timestamp + auctionDs.softStop,
                auctionHardStop: block.timestamp + auctionDs.hardStop,
                cardImageId: cardImageId,
                tokenId: tokenId,
                winning: permitSig.owner,
                price: permitSig.value,
                status: DataTypes.Status.live
            });

        auctionDs.auctions[seasonId][divisionId].push(
            auctionDs.auctionState[seasonId][divisionId][auctionId]
        );

        emit AuctionStarted(
            permitSig.owner,
            permitSig.value,
            seasonId,
            divisionId,
            auctionId,
            cardImageId,
            tokenId,
            block.timestamp,
            block.timestamp + auctionDs.softStop,
            block.timestamp + auctionDs.hardStop
        );
    }

    /// @notice Place new bid for an active auction in a certain season and division against gen2 Player token
    /// @param auctionId Auction which is about to be finished
    /// @param permitSig Permit signature as struct for the owner, spender and value in order for a permit to be successful
    function auctionBid(
        uint256 auctionId,
        DataTypes.PermitSig calldata permitSig
    ) external {
        LibFantasyAuctionStorage.Storage
            storage auctionDs = LibFantasyAuctionStorage.dstorage();

        uint256 seasonId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).seasonId();
        uint256 divisionId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).getUserDivisionId(seasonId, permitSig.owner);

        uint256 prevWinnerDivisionId = IFantasyLeague(
            LibFantasyExternalStorage.dstorage().fantasyLeague
        ).getUserDivisionId(
                seasonId,
                auctionDs.auctionState[seasonId][divisionId][auctionId].winning
            );

        LibFantasyExternalStorage.enforceIsUser(seasonId, permitSig.owner);
        LibFantasyCoreStorage.enforceSeasonNotPaused(seasonId);

        require(prevWinnerDivisionId == divisionId, "Incorrect division");

        // require(
        //     permitSig.value >=
        //         auctionDs.auctionState[seasonId][divisionId][auctionId].price +
        //             auctionDs.outbidAmount,
        //     "Bid amount too low"
        // );
        require(
            auctionDs.auctionState[seasonId][divisionId][auctionId].status ==
                DataTypes.Status.live,
            "Inactive auction"
        );
        // require(
        //     block.timestamp <
        //         auctionDs
        //         .auctionState[seasonId][divisionId][auctionId].auctionHardStop,
        //     "Hard stop hit"
        // ); // make sure there is a hard stop so we don't get into an endless auction
        // require(
        //     block.timestamp <
        //         auctionDs
        //         .auctionState[seasonId][divisionId][auctionId].auctionSoftStop,
        //     "Soft stop hit"
        // ); // if nobody claimed within the softStop auction ends

        uint256 prevBid = auctionDs
        .auctionState[seasonId][divisionId][auctionId].price;
        address prevWinner = auctionDs
        .auctionState[seasonId][divisionId][auctionId].winning;

        // LibFantasyCoreStorage.assignToRoster(
        //     seasonId,
        //     divisionId,
        //     permitSig.owner,
        //     auctionDs.auctionState[seasonId][divisionId][auctionId].tokenId
        // );

        // LibFantasyCoreStorage.removeFromRoster(
        //     seasonId,
        //     divisionId,
        //     prevWinner,
        //     auctionDs.auctionState[seasonId][divisionId][auctionId].tokenId
        // );

        auctionDs
        .auctionState[seasonId][divisionId][auctionId].winning = permitSig
            .owner;
        auctionDs
        .auctionState[seasonId][divisionId][auctionId].price = permitSig.value;
        auctionDs
        .auctionState[seasonId][divisionId][auctionId].auctionSoftStop =
            block.timestamp +
            auctionDs.softStop;

        // IERC20Permit(LibFantasyExternalStorage.dstorage().leagToken)
        //     .safeTransfer(prevWinner, prevBid);
        IERC20Permit(LibFantasyExternalStorage.dstorage().leagToken).permit(
            permitSig.owner,
            permitSig.spender,
            permitSig.value,
            permitSig.deadline,
            permitSig.v,
            permitSig.r,
            permitSig.s
        );

        // IERC20Permit(LibFantasyExternalStorage.dstorage().leagToken)
        //     .safeTransferFrom(permitSig.owner, address(this), permitSig.value);

        emit AuctionBid(
            permitSig.owner,
            auctionDs.auctionState[seasonId][divisionId][auctionId].price,
            seasonId,
            divisionId,
            auctionId,
            auctionDs
            .auctionState[seasonId][divisionId][auctionId].auctionSoftStop
        );
    }

    /// @notice Finishes an active auction in a certain season and division against gen2 Player token
    /// @param seasonId Season id for the actual sporting season the auction is placed
    /// @param divisionId Division id where this auction will be started
    /// @param auctionId Auction which is about to be finished
    function endAuction(
        uint256 seasonId,
        uint256 divisionId,
        uint256 auctionId
    ) external {
        LibFantasyAuctionStorage.Storage
            storage auctionDs = LibFantasyAuctionStorage.dstorage();

        LibFantasyExternalStorage.Storage
            storage externalDs = LibFantasyExternalStorage.dstorage();

        LibFantasyCoreStorage.Storage storage coreDs = LibFantasyCoreStorage
            .dstorage();

        DataTypes.AuctionState storage aucState = auctionDs.auctionState[
            seasonId
        ][divisionId][auctionId];

        LibFantasyCoreStorage.enforceSeasonNotPaused(seasonId);

        require(aucState.status == DataTypes.Status.live, "Auction not live");
        // require(
        //     block.timestamp >= aucState.auctionSoftStop,
        //     "Bidding is still open"
        // );

        aucState.status = DataTypes.Status.ended;
        auctionDs.hasActiveAuction[seasonId][divisionId][
            aucState.cardImageId
        ] = false;

        uint256 treasuryFraction = (aucState.price * 30) / 100;

        uint256 usersFraction = aucState.price - treasuryFraction;

        uint256 userFraction = usersFraction /
            coreDs.users[seasonId][divisionId].length;

        uint256 dust = (aucState.price) -
            (treasuryFraction +
                (userFraction * coreDs.users[seasonId][divisionId].length));

        address[] memory filtered = DraftPickLib.spliceByAddress(
            coreDs.users[seasonId][divisionId],
            aucState.winning
        );

        // for (uint256 i = 0; i < filtered.length; i++) {
        //     IERC20Permit(externalDs.leagToken).safeTransfer(
        //         filtered[i],
        //         userFraction
        //     );
        // }

        // IERC20Permit(externalDs.leagToken).safeTransfer(
        //     externalDs.leagRewardPool,
        //     userFraction
        // );

        // IERC20Permit(externalDs.leagToken).safeTransfer(
        //     externalDs.daoTreasury,
        //     treasuryFraction + dust
        // );

        IGen2PlayerToken(externalDs.playerV2).safeTransferFrom(
            address(this),
            aucState.winning,
            aucState.tokenId
        );

        emit AuctionWon(
            aucState.winning,
            aucState.price,
            seasonId,
            divisionId,
            auctionId,
            aucState.cardImageId,
            aucState.tokenId
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
import "@openzeppelin/contracts/utils/Counters.sol";

library LibFantasyAuctionStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.fantasy.auction.storage");

    using Counters for Counters.Counter;

    struct Storage {
        /// @notice auction details for the current season => division id => auctionId
        mapping(uint256 => mapping(uint256 => mapping(uint256 => DataTypes.AuctionState))) auctionState; //seasonId => divisionId => auctionId => AuctionState
        /// @notice tracks auction ids for different seasons and division ids
        mapping(uint256 => mapping(uint256 => Counters.Counter)) auctionIdCounter; //seasonId => divisionId => counter
        /// @notice keeps track for all the auctions that have happened in a particular season => division id
        mapping(uint256 => mapping(uint256 => DataTypes.AuctionState[])) auctions; //seasonId => divisionId => auctions
        /// @notice keeps track if there is an active auction of a certain playerTokenId
        mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) hasActiveAuction; // seasonId => divisionId => playerTokenId
        /// @notice minimum auction amount required for starting an auction
        uint256 minAuctionAmount;
        /// @notice minimum required step as amount for bidding in an active auction
        uint256 outbidAmount; // min allowed outbid amount for all auctions;
        /// @notice hard deadline when an auction must finish, in order to prevent an endless auction
        uint256 hardStop;
        /// @notice when nobody place new bid within the softStop, the auction ends and the winner can claim its reward.
        uint256 softStop;
    }

    /// @dev Gets the diamond storage for the Auction
    /// @return ds The diamond storage pointer
    function dstorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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