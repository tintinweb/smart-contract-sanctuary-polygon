// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IRSVP.sol";

contract RSVP is IRSVP, Context {
    struct Event {
        bytes32 id;
        address creator;
        string contentID;
        uint256 startAt;
        uint256 deposit;
        uint32 maxAttendees;
        uint32 numConfirmedRSVPs;
        uint32 numClaimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => Event) public events;
    mapping(bytes32 => mapping(address => bool)) public eventToConfirmedRSVPs;
    mapping(bytes32 => mapping(address => bool)) public eventToClaimedRSVPs;
    uint256 internal constant WITHDRAW_DELAY = 7 days;

    function createEvent(
        string calldata _contentID,
        uint256 _startAt,
        uint256 _deposit,
        uint32 _maxAttendees
    ) external {
        bytes32 eventId = keccak256(abi.encodePacked(_msgSender(), address(this), _startAt, _deposit, _maxAttendees));

        // make sure this id isn't already claimed
        if (events[eventId].creator != address(0)) revert EventAlreadyCreated();

        events[eventId] = Event({
            id: eventId,
            creator: _msgSender(),
            contentID: _contentID,
            startAt: _startAt,
            deposit: _deposit,
            maxAttendees: _maxAttendees,
            numConfirmedRSVPs: 0,
            numClaimedRSVPs: 0,
            paidOut: false
        });
        emit EventCreated(eventId, _msgSender(), _deposit, _startAt, _maxAttendees, _contentID);
    }

    function rsvpEvent(bytes32 eventId) external payable {
        Event memory targetEvent = events[eventId];
        bool isConfirmedRSVP = eventToConfirmedRSVPs[eventId][_msgSender()];

        if (msg.value < targetEvent.deposit) revert InsufficientDeposit();
        else if (block.timestamp >= targetEvent.startAt) revert EventHasBeenStarted();
        else if (targetEvent.numConfirmedRSVPs == targetEvent.maxAttendees) revert ReachedMaxAttendees();
        else if (isConfirmedRSVP) revert AttendeeAlreadyRegistered();

        events[eventId].numConfirmedRSVPs++;
        eventToConfirmedRSVPs[eventId][_msgSender()] = true;
        emit EventRSVP(eventId, _msgSender());
    }

    function checkInEvent(bytes32 eventId, address payable attendee) external {
        Event memory targetEvent = events[eventId];
        bool isConfirmedRSVP = eventToConfirmedRSVPs[eventId][attendee];
        bool isClaimedRSVP = eventToClaimedRSVPs[eventId][attendee];

        if (_msgSender() != targetEvent.creator) revert AccessDenied();
        else if (!isConfirmedRSVP) revert AttendeeNotRegistered();
        else if (isClaimedRSVP) revert AttendeeAlreadyClaimed();
        else if (targetEvent.paidOut) revert AlreadyPaidOut();

        events[eventId].numClaimedRSVPs++;
        eventToClaimedRSVPs[eventId][attendee] = true;
        attendee.transfer(targetEvent.deposit);
        emit EventCheckedIn(eventId, attendee);
    }

    function withdrawUnclaimedDeposit(bytes32 eventId) external {
        Event memory targetEvent = events[eventId];

        if (_msgSender() != targetEvent.creator) revert AccessDenied();
        else if (targetEvent.paidOut) revert AlreadyPaidOut();
        else if (block.timestamp < targetEvent.startAt + WITHDRAW_DELAY) revert WithdrawTooEarly();

        uint256 unclaimedAmount = targetEvent.deposit * (targetEvent.numConfirmedRSVPs - targetEvent.numClaimedRSVPs);

        events[eventId].paidOut = true;
        payable(targetEvent.creator).transfer(unclaimedAmount);
        emit UnclaimedDepositPaid(eventId, unclaimedAmount);
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
pragma solidity ^0.8.4;

interface IRSVP {
    error EventAlreadyCreated();
    error InsufficientDeposit();
    error EventHasBeenStarted();
    error ReachedMaxAttendees();
    error AttendeeAlreadyRegistered();
    error AccessDenied();
    error AttendeeNotRegistered();
    error AttendeeAlreadyClaimed();
    error AlreadyPaidOut();
    error WithdrawTooEarly();

    event EventCreated(
        bytes32 eventId,
        address creator,
        uint256 deposit,
        uint256 startAt,
        uint32 maxAttendees,
        string contentCID
    );
    event EventRSVP(bytes32 eventId, address attendee);
    event EventCheckedIn(bytes32 eventId, address attendee);
    event UnclaimedDepositPaid(bytes32 eventId, uint256 unclaimedAmount);
}