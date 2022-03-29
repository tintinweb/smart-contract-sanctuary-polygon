// SPDX-License-Identifier: BSL 1.1

pragma solidity 0.8.12;

import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @title Ticket Tokens Interface
 * @dev See https://github.com/Fanszoid/contracts/blob/main/src/Tickets.sol
 */
interface ITicket is IERC1155 {
    /// @dev for publishing new Tickets
    function mintBatch(
        address to,
        uint256[] memory id,
        uint256[] memory amount,
        string[] calldata uris,
        bytes memory data
    ) external;

    /// @dev for deleting Tickets
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    // @dev for editing Tickets metadata
    function setUri(uint256 tokenId, string calldata tokenURI) external;
}

/**
 * @title Events Tokens Interface
 * @dev See https://github.com/Fanszoid/contracts/blob/main/src/Events.sol
 */
interface IEvent is IERC721 {
    /// @dev for publishing new Events
    function safeMint(address to, string calldata uri) external returns (uint256);

    /// @dev for deleting Events
    function burn(uint256 eventId) external;

    // @dev for editing Event metadata
    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external;
}

/**
 * @title The Fanszoid's Marketplace
 * @dev The Fanszoid's Marketplace is a smart contract that allows you manage events and tickets.
 * @author The Fanszoid's Team. See https://fanszoid.com/
 * Features: create/delete events and tickets, buy and sell tickets, modify royalties.
 */
contract Marketplace is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* Structs */

    /// @dev Properties assigned to a particular ticket, including royalties and sellable status.
    struct TicketProperties {
        uint256 creatorRoyalty;
        uint256 primaryMarketRoyalty;
        uint256 secondaryMarketRoyalty;
        address creator;
        bool isResellable;
    }

    /// @dev A particular sale offer made by a ticket's owner, including price and amount.
    struct SellingInfo {
        uint256 amount;
        uint256 price;
    }

    /// @dev all required information for publishing a new ticket.
    struct NewTicketInfo {
        uint256 amount;
        uint256 price;
        uint256 royalty;
        uint256 amountToSell;
        bool isResellable;
        string uri;
    }

    /* Storage */

    /// @dev Fanszoid's Royalty for primary sales
    uint16 public primaryMarketplaceRoyalty;

    /// @dev Fanszoid's Royalty for secondary sales
    uint16 public secondaryMarketplaceRoyalty;

    /// @dev A multiplier for calculating royalties with some digits of presicion
    uint16 public constant HUNDRED_PERCENT = 10000; // For two digits precision

    /// @dev Upper boundary for the number of different tickets that a event can have
    uint32 public constant MAX_TICKET_TYPES = 300;

    /// @dev Lower boundary for beign able to calculates fees with the given HUNDRED_PERCENT presicion
    uint256 public constant MINIMUM_ASK = 10000; // For fee calculation

    /// @dev Reference to Ticket (ERC1155) contract
    address public ticketAddress;

    /// @dev Reference to Event (ERC721) contract
    address public eventAddress;

    /// @dev Mapping of ticket per event - [eventId, [ticketIds]]
    mapping(uint256 => uint256[]) public eventTicket;

    /// @dev Mapping of ticket properties (creator, royalties, etc.) - [ticketId, TicketProperties]
    mapping(uint256 => TicketProperties) public ticketsProperties;

    /// @dev Market offers: Mapping of selling info - [seller, [ticketId, SellingInfo]]
    mapping(address => mapping(uint256 => SellingInfo)) public sellingInfo;

    /// @dev the Ticket's Id's counter
    CountersUpgradeable.Counter internal _ticketIds;

    /* Events */

    /// @dev Event emitted when a new event is created
    event EventCreated(uint256 eventId, address organizer, string uri);

    /// @dev Event emitted when an event's URI is modified
    event EventEdited(uint256 eventId, string newUri);

    /// @dev Event emitted when an event is deleted
    event EventDeleted(uint256 eventId);

    /// @dev Event emitted when a new ticket is created
    event TicketPublished(uint256 eventId, uint256[] ticketIds);

    /// @dev Event emitted when an ticket's URI is modified
    event TicketEdited(uint256 ticketId, string newUri);

    /// @dev Event emitted when a ticket is deleted
    event TicketDeleted(uint256 eventId, uint256[] ids, uint256[] amounts);

    /// @dev Event emitted when a ticket is sold
    event TicketBought(uint256 ticketId, address seller, address buyer, uint256 price, uint256 amount);

    /// @dev Event emitted when a new sale offer is published
    event AskSetted(uint256 ticketId, address seller, uint256 ticketPrice);

    /// @dev Event emitted when a sale offer is deleted
    event AskRemoved(address seller, uint256 ticketId);

    /// @dev Event emmited when an event's ownership is transferred
    event EventOwnershipTransferred(uint256 eventId, address newOwner);

    /// @dev Event emmited when the default primary marketplace royalty is modified
    event PrimaryMarketRoyaltyModified(uint256 newRoyalty);

    /// @dev Event emmited when the default secondary marketplace royalty is modified
    event SecondaryMarketRoyaltyModified(uint256 newRoyalty);

    /// @dev Event emmited when the primary marketplace royalty is modified on an event
    event PrimaryMarketRoyaltyModifiedOnEvent(uint256 eventId, uint256 newRoyalty);

    /// @dev Event emmited when the secondary marketplace royalty is modified on an event
    event SecondaryMarketRoyaltyModifiedOnEvent(uint256 eventId, uint256 newRoyalty);

    /// @dev Event emmited when the primary marketplace royalty is modified on a ticket
    event PrimaryMarketRoyaltyModifiedOnTicket(uint256 ticketId, uint256 newRoyalty);

    /// @dev Event emmited when the secondary marketplace royalty is modified on a ticket
    event SecondaryMarketRoyaltyModifiedOnTicket(uint256 ticketId, uint256 newRoyalty);

    /// @dev Event emmited when the creator royalty is modified on an event
    event CreatorRoyaltyModifiedOnEvent(uint256 eventId, uint256 newRoyalty);

    /// @dev Event emmited when the creator royalty is modified on a ticket
    event CreatorRoyaltyModifiedOnTicket(uint256 ticketId, uint256 newRoyalty);

    /* Modifiers */

    /// @dev Verifies that the sender is either the marketplace's owner nor the given event's creator.
    modifier onlyEventCreatorOrOwner(uint256 eventId) {
        require(IEvent(eventAddress).ownerOf(eventId) == msg.sender || this.owner() == msg.sender, 'Not allowed!');
        _;
    }

    /// @dev Verifies that the sender is the given event's creator.
    modifier onlyEventCreator(uint256 eventId) {
        require(IEvent(eventAddress).ownerOf(eventId) == msg.sender, 'Only creator is allowed!');
        _;
    }

    /// @dev Verifies that the sender is either the marketplace's owner nor the given ticket's creator.
    modifier onlyTicketCreatorOrOwner(uint256 ticketId) {
        require(ticketsProperties[ticketId].creator == msg.sender || this.owner() == msg.sender, 'Not allowed!');
        _;
    }

    /// @dev Verifies that the sender is the given ticket's creator.
    modifier onlyTicketCreator(uint256 ticketId) {
        require(ticketsProperties[ticketId].creator == msg.sender, 'Only creator is allowed!');
        _;
    }

    /// @dev Verifies that the sender is the Event contract.
    modifier onlyEventContract() {
        require(eventAddress == msg.sender, 'Only Event contract is allowed!');
        _;
    }

    /* Initializer */

    /**
     *  @dev Constructor.
     *  @param _ticketAddress Address of the Ticket contract
     *  @param _eventAddress Address of the Event contract
     */
    function initialize(address _ticketAddress, address _eventAddress) external initializer {
        primaryMarketplaceRoyalty = 1500; // Initially 15% for primary sales
        secondaryMarketplaceRoyalty = 750; // Initially 7.5% for secondary sales

        ticketAddress = _ticketAddress;
        eventAddress = _eventAddress;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /* External */

    /**
     *  @dev Creates a new event.
     *  @param eventUri URI of the event containing event's metadata (IPFS)
     *  @param ticketTypesCount Number of different tickets that the event will initialilly publish
     *  @param tickets Ticket's information (metadata's uri, amount to sell, price, etc.)
     */
    function createEvent(
        string memory eventUri,
        uint256 ticketTypesCount,
        NewTicketInfo[] calldata tickets
    ) external whenNotPaused returns (uint256) {
        require(ticketTypesCount <= MAX_TICKET_TYPES, 'Too much ticket types!');
        require(ticketTypesCount == tickets.length, 'Ticket count mismatch!');

        uint256 eventId = IEvent(eventAddress).safeMint(msg.sender, eventUri);

        if (ticketTypesCount > 0) {
            publishTickets(eventId, ticketTypesCount, tickets);
        }

        emit EventCreated(eventId, msg.sender, eventUri);
        return eventId;
    }

    /**
     *  @dev Claim free Ticket.
     *  @param ticketId The id of the ticket to be claimed
     *  @param seller The seller from whom would like to claim (should be a zero price offer setted)
     *  @param claimer Address of the person who would be the ticket holder
     */
    function claimFreeTicket(
        uint256 ticketId,
        address seller,
        address claimer
    ) external {
        require(ITicket(ticketAddress).balanceOf(seller, ticketId) >= 1, 'Seller has not enough tickets.');
        require(ITicket(ticketAddress).balanceOf(claimer, ticketId) == 0, 'Claimer already has one ticket.');
        require(sellingInfo[seller][ticketId].price == 0, 'Ticket is not free.');
        require(sellingInfo[seller][ticketId].amount >= 1, 'Not enough tickets for claim');

        ITicket(ticketAddress).safeTransferFrom(address(seller), claimer, ticketId, 1, '');
        sellingInfo[seller][ticketId].amount -= 1;

        emit TicketBought(ticketId, seller, claimer, 0, 1);
    }

    /**
     *  @dev Buy market Tickets.
     *  @param ticketId The id of the ticket to buy
     *  @param seller The seller from whom would like to buy (should be a sale offer setted)
     *  @param amount Amount of tickets to buy (Tickets are ERC1155)
     */
    function buyMarketTicket(
        uint256 ticketId,
        address seller,
        uint256 amount
    ) external payable whenNotPaused nonReentrant {
        require(ITicket(ticketAddress).balanceOf(seller, ticketId) >= amount, 'Seller has not enough ticket.');
        require(amount <= sellingInfo[seller][ticketId].amount, 'Not enough ticket for sale');
        require(msg.value == (amount * sellingInfo[seller][ticketId].price), 'Value does not match price');
        require(msg.sender != seller, 'You cannot buy your own ticket');

        uint256 ticketPrice = sellingInfo[seller][ticketId].price;
        address creator = ticketsProperties[ticketId].creator;

        ITicket(ticketAddress).safeTransferFrom(address(seller), msg.sender, ticketId, amount, '');
        sellingInfo[seller][ticketId].amount -= amount;
        uint256 previousBalance = address(this).balance;
        if (ticketPrice == 0) {
            require(amount == 1, 'Can only buy one free ticket');
        } else {
            // Paid Tickets
            if (seller == creator) {
                // primary sale, selling by event organizer.

                uint256 marketplaceShare = _calculateFee(ticketPrice, ticketsProperties[ticketId].primaryMarketRoyalty);
                uint256 creatorShare = ticketPrice - marketplaceShare;

                _transferFundsSupportingGnosisSafe(creator, creatorShare * amount); // Untrusted transfer
                _transferFundsSupportingGnosisSafe(owner(), amount * marketplaceShare); // Trusted transfer, Gnosis Safe Wallet
            } else {
                // secondary sale, seller is not event organizer.

                uint256 marketplaceShare = _calculateFee(ticketPrice, ticketsProperties[ticketId].secondaryMarketRoyalty);
                uint256 creatorShare = _calculateFee(ticketPrice, ticketsProperties[ticketId].creatorRoyalty);
                uint256 sellerShare = ticketPrice - marketplaceShare - creatorShare;

                _transferFundsSupportingGnosisSafe(seller, sellerShare * amount); // Untrusted transfer
                _transferFundsSupportingGnosisSafe(creator, creatorShare * amount); // Untrusted transfer
                _transferFundsSupportingGnosisSafe(owner(), marketplaceShare * amount); // Trusted transfer, Gnosis Safe Wallet
            }
        }

        assert((previousBalance - address(this).balance) == msg.value); // All value should be distributed.

        emit TicketBought(ticketId, seller, msg.sender, ticketPrice, amount);
    }

    /**
     *  @dev Sets a new sale offer.
     *  @param ticketId The id of the ticket to set the sale offer (sender should have balance of this one)
     *  @param ticketPrice The price to be setted for this offer
     *  @param amount The amount of tickets that will be available for sale
     */
    function setAsk(
        uint256 ticketId,
        uint256 ticketPrice,
        uint256 amount
    ) external whenNotPaused {
        require(ticketPrice >= MINIMUM_ASK, 'Price below minimum.');
        require(ITicket(ticketAddress).balanceOf(msg.sender, ticketId) > 0, 'Sender does not have ticket.');
        require(ticketsProperties[ticketId].isResellable == true, 'Ticket is not resellable.');

        sellingInfo[msg.sender][ticketId].price = ticketPrice;
        sellingInfo[msg.sender][ticketId].amount = amount;
        emit AskSetted(ticketId, msg.sender, ticketPrice);
    }

    /**
     *  @dev Removes a sale offer
     *  @param ticketId The id of the ticket to remove the sale offer (only sender's offer)
     */
    function removeAsk(uint256 ticketId) external whenNotPaused {
        require(ITicket(ticketAddress).balanceOf(msg.sender, ticketId) > 0, 'Sender has no ticket.');

        delete sellingInfo[msg.sender][ticketId];
        emit AskRemoved(msg.sender, ticketId);
    }

    /**
     *  @dev Deletes an event.
     *  @param eventId The id of the event to be deleted
     */
    function deleteEvent(uint256 eventId) external whenNotPaused onlyEventCreatorOrOwner(eventId) {
        IEvent(eventAddress).burn(eventId);

        delete eventTicket[eventId];

        emit EventDeleted(eventId);
    }

    /**
     *  @dev Deletes a ticket.
     *  @param ticketId The id of the ticket to be deleted
     */
    function deleteTicket(
        uint256 ticketId,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external whenNotPaused onlyTicketCreatorOrOwner(ticketId) {
        require(ids.length == amounts.length, 'Ids and amounts count mismatch.');

        ITicket(ticketAddress).burnBatch(msg.sender, ids, amounts);

        emit TicketDeleted(ticketId, ids, amounts);
    }

    /**
     *  @dev Modifies an event's URI.
     *  @param eventId The id of the event to be deleted
     *  @param newUri The new URI
     */
    function setEventUri(uint256 eventId, string calldata newUri) external whenNotPaused onlyEventCreatorOrOwner(eventId) {
        IEvent(eventAddress).setTokenURI(eventId, newUri);

        emit EventEdited(eventId, newUri);
    }

    /**
     *  @dev Modifies a ticket's URI.
     *  @param ticketId The id of the ticket to be deleted
     *  @param newUri The new URI
     */
    function setTicketUri(uint256 ticketId, string calldata newUri) external whenNotPaused onlyTicketCreatorOrOwner(ticketId) {
        ITicket(ticketAddress).setUri(ticketId, newUri);

        emit TicketEdited(ticketId, newUri);
    }

    /**
     *  @dev Modifies creator's royalty for a given Event.
     *  @dev This function modifies the creator's royalty for all available tickets in the given event.
     *  @param eventId The id of the event whose royalty will be modified
     *  @param newCreatorRoyalty The new royalty to be setted
     */
    function modifyCreatorRoyaltyOnEvent(uint256 eventId, uint256 newCreatorRoyalty) external onlyEventCreator(eventId) whenNotPaused {
        uint256[] memory ticketIds = eventTicket[eventId];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            require(newCreatorRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketIds[i]].secondaryMarketRoyalty), 'Above 100%.');
            ticketsProperties[ticketIds[i]].creatorRoyalty = newCreatorRoyalty;
        }

        emit CreatorRoyaltyModifiedOnEvent(eventId, newCreatorRoyalty);
    }

    /**
     *  @dev Modifies creator's royalty for a given Ticket.
     *  @param ticketId The id of the ticket whose royalty will be modified
     *  @param newCreatorRoyalty The new royalty to be setted
     */
    function modifyCreatorRoyaltyOnTicket(uint256 ticketId, uint256 newCreatorRoyalty) external onlyTicketCreator(ticketId) whenNotPaused {
        require(newCreatorRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketId].secondaryMarketRoyalty), 'Above 100%.');

        ticketsProperties[ticketId].creatorRoyalty = newCreatorRoyalty;

        emit CreatorRoyaltyModifiedOnTicket(ticketId, newCreatorRoyalty);
    }

    /**
     *  @dev Modifies Primary Marketplace royalty for future events.
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifyPrimaryMarketplaceRoyalty(uint16 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        primaryMarketplaceRoyalty = newMarketplaceRoyalty;
        emit PrimaryMarketRoyaltyModified(newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Secondary Marketplace royalty for future events.
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifySecondaryMarketplaceRoyalty(uint16 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        secondaryMarketplaceRoyalty = newMarketplaceRoyalty;
        emit SecondaryMarketRoyaltyModified(newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Primary Marketplace royalty for a given event.
     *  @dev This function modifies the creator's royalty for all available tickets in the given event.
     *  @param eventId The id of the event whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifyPrimaryMarketplaceRoyaltyOnEvent(uint256 eventId, uint256 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        uint256[] memory ticketIds = eventTicket[eventId];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            require(newMarketplaceRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketIds[i]].creatorRoyalty), 'Above 100%.');
            ticketsProperties[ticketIds[i]].primaryMarketRoyalty = newMarketplaceRoyalty;
        }

        emit PrimaryMarketRoyaltyModifiedOnEvent(eventId, newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Secondary Marketplace royalty for a given event.
     *  @dev This function modifies the creator's royalty for all available tickets in the given event.
     *  @param eventId The id of the event whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifySecondaryMarketplaceRoyaltyOnEvent(uint256 eventId, uint256 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        uint256[] memory ticketIds = eventTicket[eventId];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            require(newMarketplaceRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketIds[i]].creatorRoyalty), 'Above 100%.');
            ticketsProperties[ticketIds[i]].secondaryMarketRoyalty = newMarketplaceRoyalty;
        }

        emit SecondaryMarketRoyaltyModifiedOnEvent(eventId, newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Primary Marketplace royalty for a given ticket.
     *  @param ticketId The id of the ticket whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifyPrimaryMarketplaceRoyaltyOnTicket(uint256 ticketId, uint256 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        require(newMarketplaceRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketId].creatorRoyalty), 'Above 100%.');

        ticketsProperties[ticketId].primaryMarketRoyalty = newMarketplaceRoyalty;

        emit PrimaryMarketRoyaltyModifiedOnTicket(ticketId, newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Secondary Marketplace royalty for a given ticket.
     *  @param ticketId The id of the ticket whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifySecondaryMarketplaceRoyaltyOnTicket(uint256 ticketId, uint256 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        require(newMarketplaceRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketId].creatorRoyalty), 'Above 100%.');

        ticketsProperties[ticketId].secondaryMarketRoyalty = newMarketplaceRoyalty;

        emit SecondaryMarketRoyaltyModifiedOnTicket(ticketId, newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies the owner of a given event  to 'newOwner'
     *  This function can be called only by Event contract in case of an safeTransferFrom
     *  in order to syncronize events ownership in the Marketplace.
     *  @param eventId The id of the event whose owner will be modified
     *  @param newOwner The new owner of the event (will recieve future royalties)
     */
    function changeEventOwnership(uint256 eventId, address newOwner) external whenNotPaused onlyEventContract {
        _changeEventOwnerInTicket(eventId, newOwner);
        emit EventOwnershipTransferred(eventId, newOwner);
    }

    /* public */

    /**
     *  @dev Pubilish new tickets for an event.
     *  @param eventId The id of the event which will contain the new tickets
     *  @param ticketTypesCount Number of different tickets that the event will initialilly publish
     *  @param tickets Ticket's information (metadata's uri, amount to sell, price, etc.), See NewTicket struct.
     */
    function publishTickets(
        uint256 eventId,
        uint256 ticketTypesCount,
        NewTicketInfo[] calldata tickets
    ) public whenNotPaused nonReentrant returns (uint256[] memory ticketIds) {
        require(IEvent(eventAddress).ownerOf(eventId) == msg.sender, 'Not allowed!');
        require((ticketTypesCount + eventTicket[eventId].length) <= MAX_TICKET_TYPES, 'Too much ticket types!');
        require(ticketTypesCount == tickets.length, 'Ticket count mismatch!');

        uint256[] memory amounts = new uint256[](ticketTypesCount);
        string[] memory uris = new string[](ticketTypesCount);

        // Create Ticket
        for (uint8 i = 0; i < ticketTypesCount; i++) {
            require(tickets[i].royalty <= (HUNDRED_PERCENT - secondaryMarketplaceRoyalty), 'Creator royalty above the limit.');
            require(tickets[i].price == 0 || tickets[i].price >= MINIMUM_ASK, 'Asking price below minimum.');
            require(tickets[i].amountToSell <= tickets[i].amount, 'Amount to sell is too high.');
            if (tickets[i].isResellable == true) {
                require(tickets[i].price != 0, 'Free are not resellable.');
            }

            _ticketIds.increment();
            uint256 ticketId = _ticketIds.current();
            ticketsProperties[ticketId] = TicketProperties(
                tickets[i].royalty,
                primaryMarketplaceRoyalty,
                secondaryMarketplaceRoyalty,
                msg.sender,
                tickets[i].isResellable
            );
            sellingInfo[msg.sender][ticketId] = SellingInfo(tickets[i].amountToSell, tickets[i].price);
            eventTicket[eventId].push(ticketId);
            amounts[i] = tickets[i].amount;
            uris[i] = tickets[i].uri;
        }

        ITicket(ticketAddress).mintBatch(msg.sender, eventTicket[eventId], amounts, uris, '');

        emit TicketPublished(eventId, eventTicket[eventId]);
        return eventTicket[eventId];
    }

    /**
     *  @dev Pauses the contract in case of an emergency. Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *  @dev Re-plays the contract in case a prior emergency has been solved. Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /* internal */

    /**
     * @dev Transfers funds to a given address.
     * @dev Necesary to avoid gas error since eip 2929, more info in eip 2930.
     * @param to The address to transfer the funds to
     * @param amount The amount to be transfered
     */
    function _transferFundsSupportingGnosisSafe(address to, uint256 amount) internal {
        (bool sent, ) = payable(to).call{value: amount, gas: 2600}(''); // solhint-disable-line
        require(sent, 'Error while paying the receiver');
    }

    /**
     *  @dev Modifies the owner (creator) of each ticket's in a given event to 'newOwner'
     *  @param eventId The id of the event whose owner will be modified
     *  @param newOwner The new owner of the event (will recieve future royalties)
     */
    function _changeEventOwnerInTicket(uint256 eventId, address newOwner) internal {
        uint256[] memory ticket = eventTicket[eventId];
        for (uint256 id = 0; id < ticket.length; id++) {
            ticketsProperties[id].creator = newOwner;
        }
    }

    /**
     *  @dev Calculated a fee given an amount and a fee percentage
     *  @dev HUNDRED_PERCENT is used as 100% to enhanced presicion.
     *  @param totalAmount The total amount to be paid
     *  @param fee The percentage of the fee over the full amount.
     */
    function _calculateFee(uint256 totalAmount, uint256 fee) internal pure returns (uint256) {
        return (totalAmount * fee) / HUNDRED_PERCENT;
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
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