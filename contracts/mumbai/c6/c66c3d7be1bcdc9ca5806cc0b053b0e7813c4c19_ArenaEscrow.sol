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
        uint128 entryFee;
        uint128 remainingPayout;
    }
    mapping(uint256 => mapping(address => eventEntry)) public entries;

    struct eventDetails {
        address trustedParty;
        uint16 numEntrants;
        EventState state;
        uint128 entryFee;
    }
    mapping(uint256 => eventDetails) public details;

    uint256 idCounter = 1;

    enum EventState {
        INITIAL,
        FINISHED,
        REFUND
    }

    ////////////////////////////////////////////////////////////////////////
    // Event Host
    ////////////////////////////////////////////////////////////////////////

    function createEvent(uint128 entryFeeWei) public returns (uint256)  {
        if (entryFeeWei == 0) revert("invalid entry fee");

        idCounter += 1;
        eventDetails memory ed = eventDetails(msg.sender, 0, EventState.INITIAL, entryFeeWei);
        details[idCounter] = ed;

        return idCounter;
    }

    // caller should include as many empty users as they can and then they can have massive
    // savings from the gas refunds
    function finalizePayouts(uint256 eventID, address[] calldata users, uint128[] calldata amounts) public {
        eventDetails memory deets = details[eventID];
        if (msg.sender != deets.trustedParty) revert("unauthorized");
        if (deets.state != EventState.INITIAL) revert("cannot finalize payouts at this time");
        if (users.length != amounts.length) revert("length mismatch");

        address user;
        uint128 amount;
        uint128 rewardSum = 0;
        for (uint256 i = 0; i < users.length; i++) {
            user = users[i];
            amount = amounts[i];
            rewardSum += amount;

            // once we transition to payout stage, refunds are no-longer available,
            // which is why we also update the first field.
            // This has the extra effect of allowing us to completely zero out that users data
            // and claim the gas refund if they are not part of the reward payouts
            entries[eventID][user] = eventEntry(0, amount);
        }

        if (rewardSum != (deets.numEntrants * deets.entryFee)) revert("all funds must be allocated for rewards");

        // advance contract to final stage
        details[eventID].state = EventState.FINISHED;

        // TODO: in v2 we can pay the admin the rake here without an extra step
    }

    ////////////////////////////////////////////////////////////////////////
    // Event Participant
    ////////////////////////////////////////////////////////////////////////

    function joinEvent(uint256 eventID) public payable {
        eventDetails memory deets = details[eventID];
        if (deets.trustedParty == address(0)) revert("invalid eventID");
        if (deets.state != EventState.INITIAL) revert("can no longer join event");
        if (msg.value != (deets.entryFee)) revert("incorrect entry fee");
        if (entries[eventID][msg.sender].entryFee != 0) revert("already joined");

        entries[eventID][msg.sender] = eventEntry(uint128(msg.value), 0);
        details[eventID].numEntrants += 1;
    }

    function claimPrize(uint256 eventID) public {
        eventDetails memory deets = details[eventID];
        if (deets.state != EventState.FINISHED) revert("cannot claim prize at this time");

        uint128 prizeAmount = entries[eventID][msg.sender].remainingPayout;
        if (prizeAmount == 0) revert("prize balance is zero");

        entries[eventID][msg.sender] = eventEntry(0,0); // fully zero out entry struct so that user gets gas refunded
        payable(msg.sender).transfer(prizeAmount);
    }

    function claimRefund(uint256 eventID) public {
        eventDetails memory deets = details[eventID];
        if (deets.state != EventState.REFUND) revert("cannot claim refund at this time");

        uint128 refundAmount = entries[eventID][msg.sender].entryFee;
        if (refundAmount == 0) revert("refund balance is zero");

        entries[eventID][msg.sender] = eventEntry(0,0); // fully zero out entry struct so that user gets gas refunded
        payable(msg.sender).transfer(refundAmount);
    }

    ////////////////////////////////////////////////////////////////////////
    // Admin
    ////////////////////////////////////////////////////////////////////////

    function triggerRefund(uint256 eventID) public {
        eventDetails memory deets = details[eventID];
        if (!(msg.sender == owner || msg.sender == deets.trustedParty)) revert("unauthorized");

        details[eventID].state = EventState.REFUND;
    }

}