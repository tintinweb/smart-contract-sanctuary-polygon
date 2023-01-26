// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";

contract ArenaEscrow is Owned(msg.sender) {

    constructor() {}

    ////////////////////////////////////////////////////////////////////////
    // Contract State
    ////////////////////////////////////////////////////////////////////////

    struct eventEntry {
        bool    entered;
        uint120 contributions;
        uint128 remainingPayout;
    }
    mapping(uint256 => mapping(address => eventEntry)) public entries;

    /// @dev Prize Pool contributions not from entry fees
    mapping(uint256 => uint256) public externalPrizeContributions;

    struct eventDetails {
        address trustedParty;
        uint16 numEntrants;
        EventState state;
        uint64 entryFeeGwei;
        bool locked;
    }
    mapping(uint256 => eventDetails) public details;

    uint256 idCounter = 1;

    enum EventState {
        INITIAL,
        FINISHED,
        REFUND
    }

    ////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////

    event EventCreated(address indexed creator, uint256 indexed eventID, uint64 entryFeeGwei);

    event EventJoined(address indexed user, uint256 indexed eventID);

    event RefundTriggered(address indexed caller, uint256 indexed eventID);

    event PayoutsFinalized(address indexed caller, uint256 indexed eventID, address[] users, uint128[] amounts);

    event PrizeClaimed(address indexed user, uint256 indexed eventID, uint128 amount);

    event RefundClaimed(address indexed user, uint256 indexed eventID, uint120 amount);

    event EventPrizeContribution(address indexed user, uint256 indexed eventID, uint120 amount);

    ////////////////////////////////////////////////////////////////////////
    // Event Host
    ////////////////////////////////////////////////////////////////////////

    function createEvent(uint64 entryFeeGwei) public returns (uint256)  {
        idCounter += 1;
        eventDetails memory ed = eventDetails(msg.sender, 0, EventState.INITIAL, entryFeeGwei, false);
        details[idCounter] = ed;

        emit EventCreated(msg.sender, idCounter, entryFeeGwei);
        return idCounter;
    }

    // caller should include as many empty users as they can and then they can have massive
    // savings from the gas refunds
    function finalizePayouts(uint256 eventID, address[] calldata users, uint128[] calldata amountsWei) public {
        eventDetails storage deets = details[eventID];
        if (msg.sender != deets.trustedParty) revert("unauthorized");
        if (deets.state != EventState.INITIAL) revert("cannot finalize payouts at this time");
        if (users.length != amountsWei.length) revert("length mismatch");

        uint256 rewardSum = 0;
        for (uint256 i = 0; i < users.length; i++) {

            rewardSum += amountsWei[i];

            // once we transition to payout stage, refunds are no-longer available,
            // which is why we also update the first field.
            // This has the extra effect of allowing us to completely zero out that users data
            // and claim the gas refund if they are not part of the reward payouts
            entries[eventID][users[i]] = eventEntry(false, 0, amountsWei[i]);
        }

        uint256 expectedAllocation = externalPrizeContributions[eventID] + (deets.numEntrants * deets.entryFeeGwei * 1e9);
        if (rewardSum != expectedAllocation) revert("all funds must be allocated for rewards");

        // advance contract to final stage
        deets.state = EventState.FINISHED;

        // clear out external contributions for gas refund
        externalPrizeContributions[eventID] = 0;

        emit PayoutsFinalized(msg.sender, eventID, users, amountsWei);

        // TODO: in v2 we can pay the admin the rake here without an extra step
    }

    ////////////////////////////////////////////////////////////////////////
    // Event Participant
    ////////////////////////////////////////////////////////////////////////

    function joinEvent(uint256 eventID) public payable {
        eventDetails storage deets = details[eventID];
        if (deets.trustedParty == address(0)) revert("invalid eventID");
        if (deets.state != EventState.INITIAL) revert("can no longer join event");
        if (deets.locked) revert("event is locked for joining");
        if (msg.value != (deets.entryFeeGwei * 1e9)) revert("incorrect entry fee");

        eventEntry storage userEntry = entries[eventID][msg.sender];
        if (entries[eventID][msg.sender].entered) revert("already joined");

        userEntry.entered = true;
        userEntry.contributions += uint120(msg.value);
        userEntry.remainingPayout = 0;

        deets.numEntrants += 1;

        emit EventJoined(msg.sender, eventID);
    }

    function claimPrize(uint256 eventID) public {
        eventDetails memory deets = details[eventID];
        if (deets.state != EventState.FINISHED) revert("cannot claim prize at this time");

        eventEntry storage userEntry = entries[eventID][msg.sender];
        uint128 prizeAmount = userEntry.remainingPayout;
        if (prizeAmount == 0) revert("prize balance is zero");

        // fully zero out entry struct so that user gets gas refunded
        userEntry.entered = false;
        userEntry.contributions = 0;
        userEntry.remainingPayout = 0;

        // transfer winnings
        payable(msg.sender).transfer(prizeAmount);

        emit PrizeClaimed(msg.sender, eventID, prizeAmount);
    }

    function claimRefund(uint256 eventID) public {
        eventDetails memory deets = details[eventID];
        if (deets.state != EventState.REFUND) revert("cannot claim refund at this time");

        eventEntry storage userEntry = entries[eventID][msg.sender];
        uint120 refundAmount = userEntry.contributions;
        if (refundAmount == 0) revert("refund balance is zero");

        // fully zero out entry struct so that user gets gas refunded
        userEntry.entered = false;
        userEntry.contributions = 0;
        userEntry.remainingPayout = 0;

        // transfer refund
        payable(msg.sender).transfer(refundAmount);

        emit RefundClaimed(msg.sender, eventID, refundAmount);
    }

    ////////////////////////////////////////////////////////////////////////
    // External Prize Support
    ////////////////////////////////////////////////////////////////////////

    function contributeToPrizePool(uint256 eventID) public payable {
        eventDetails memory deets = details[eventID];
        if (deets.state != EventState.INITIAL) revert("cannot contribute at this time");
        if (deets.locked) revert("event is locked for contributing");

        eventEntry storage userEntry = entries[eventID][msg.sender];
        if (userEntry.contributions + msg.value > type(uint120).max) revert("exceeded max contribution");

        // treat the contribution as an additional entry fee for gas efficiency
        // but don't increment the event's numEntrants. This lets us re-use the payout and
        // refund mechanics of normal entries, as well as significant gas savings if
        // the contributing user is also an entrant
        userEntry.contributions += uint120(msg.value);

        // update total external contributions to event
        externalPrizeContributions[eventID] += msg.value;

        emit EventPrizeContribution(msg.sender, eventID, uint120(msg.value));
    }

    ////////////////////////////////////////////////////////////////////////
    // Admin
    ////////////////////////////////////////////////////////////////////////

    // prevent additional joining or contributing to event
    function lockEvent(uint256 eventID, bool isLocked) public {
        eventDetails storage deets = details[eventID];
        if (!(msg.sender == owner || msg.sender == deets.trustedParty)) revert("unauthorized");

        deets.locked = isLocked;
    }

    function triggerRefund(uint256 eventID) public {
        eventDetails storage deets = details[eventID];
        if (deets.state != EventState.INITIAL) revert ("cannot trigger refund once payouts have been set");
        if (!(msg.sender == owner || msg.sender == deets.trustedParty)) revert("unauthorized");

        deets.state = EventState.REFUND;

        emit RefundTriggered(msg.sender, eventID);
    }

}