// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import './lib/Models.sol' as Models;

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
 * @title Ticket Marketplace Contract Interface
 * @dev See https://github.com/Fanszoid/contracts/blob/main/src/TicketMarketplace.sol
 */
interface ITicketMarketplace {
    function modifyCreatorRoyaltyOnEvent(uint256 eventId, uint256 creatorRoyalty) external;

    function publishTicketsForOrganizer(
        uint256 eventId,
        address organizer,
        Models.NewAssetSaleInfo[] calldata tickets,
        uint256[][] calldata memberships
    ) external returns (uint256[] memory ticketIds);

    function deleteEvent(uint256 eventId) external;

    function changeEventOwnerInTicketsForEvent(uint256 eventId, address newOwner) external;

    function ticketCreator(uint256 ticketId) external view returns (address);
}

/**
 * @title The Fanszoid's Admin
 * @dev The Fanszoid's Admin is a smart contract that allows you manage events and royalties.
 * @author The Fanszoid's Team. See https://fanszoid.com/
 * Features: create/delete events and tickets, buy and sell tickets, modify royalties.
 */
contract Admin is Initializable, OwnableUpgradeable, PausableUpgradeable {
    /* Storage */

    /// @dev Fanszoid's Royalty for primary sales
    uint16 public primaryMarketplaceRoyalty;

    /// @dev Fanszoid's Royalty for secondary sales
    uint16 public secondaryMarketplaceRoyalty;

    /// @dev Reference to Ticket (ERC1155) contract
    address public ticketMarketplaceAddress;

    /// @dev Reference to Event (ERC721) contract
    address public eventAddress;

    /// @dev Memberships allowed to claim tickets (ticketId => membershipId[])
    mapping(uint256 => uint256[]) public membershipsAllowedForTickets;

    /* Events */

    /// @dev Event emitted when a new event is created
    event EventCreated(uint256 indexed eventId, address organizer, string uri);

    /// @dev Event emitted when an event's URI is modified
    event EventEdited(uint256 indexed eventId, string newUri);

    /// @dev Event emitted when an event is deleted
    event EventDeleted(uint256 indexed eventId);

    /// @dev Event emmited when an event's ownership is transferred
    event EventOwnershipTransferred(uint256 indexed eventId, address newOwner);

    /// @dev Event emmited when memberships are linked to tickets
    event MembershipsAssignedToTicket(uint256 indexed ticketId, uint256[] memberships);

    /// @dev Event emmited when the default primary marketplace royalty is modified
    event PrimaryMarketRoyaltyModified(uint256 newRoyalty);

    /// @dev Event emmited when the default secondary marketplace royalty is modified
    event SecondaryMarketRoyaltyModified(uint256 newRoyalty);

    /// @dev Event emmited when the primary marketplace royalty is modified on an event
    event PrimaryMarketRoyaltyModifiedOnEvent(uint256 indexed eventId, uint256 newRoyalty);

    /// @dev Event emmited when the secondary marketplace royalty is modified on an event
    event SecondaryMarketRoyaltyModifiedOnEvent(uint256 indexed eventId, uint256 newRoyalty);

    /// @dev Event emmited when the creator royalty is modified on an event
    event CreatorRoyaltyModifiedOnEvent(uint256 indexed eventId, uint256 newRoyalty);

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

    /// @dev Verifies that the sender is the Event contract.
    modifier onlyEventContract() {
        require(eventAddress == msg.sender, 'Only Event contract is allowed!');
        _;
    }

    /* Initializer */

    /**
     *  @dev Initializer.
     *  @param _ticketMarketplaceAddress Address of the Ticket Marketplace contract
     *  @param _eventAddress Address of the Event contract
     */
    function initialize(address _ticketMarketplaceAddress, address _eventAddress) external initializer {
        primaryMarketplaceRoyalty = 1500; // Initially 15% for primary sales
        secondaryMarketplaceRoyalty = 750; // Initially 7.5% for secondary sales

        ticketMarketplaceAddress = _ticketMarketplaceAddress;
        eventAddress = _eventAddress;

        __Ownable_init();
        __Pausable_init();
    }

    /* External */

    /**
     *  @dev Creates a new event.
     *  @param eventUri URI of the event containing event's metadata (IPFS)
     *  @param tickets Ticket's information (metadata's uri, amount to sell, price, etc.)
     */
    function createEvent(
        string memory eventUri,
        Models.NewAssetSaleInfo[] calldata tickets,
        uint256[][] calldata memberships
    ) external whenNotPaused returns (uint256) {
        uint256 eventId = IEvent(eventAddress).safeMint(msg.sender, eventUri);

        emit EventCreated(eventId, msg.sender, eventUri);

        if (tickets.length > 0) {
            ITicketMarketplace(ticketMarketplaceAddress).publishTicketsForOrganizer(eventId, msg.sender, tickets, memberships);
        }

        return eventId;
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
     *  @dev Assign memberships to tickets.
     *  @param ticketsIds The ids of the tickets to assign memberships to
     *  @param memberships The memberships to be assigned for each ticket
     */
    function assignMemberships(uint256[] calldata ticketsIds, uint256[][] calldata memberships) external whenNotPaused {
        for (uint256 i = 0; i < ticketsIds.length; i++) {
            require(
                msg.sender == ticketMarketplaceAddress ||
                    msg.sender == ITicketMarketplace(ticketMarketplaceAddress).ticketCreator(ticketsIds[i]),
                'Only Marketplace or creator!'
            );
            if (memberships[i].length > 0) {
                membershipsAllowedForTickets[ticketsIds[i]] = memberships[i];
                emit MembershipsAssignedToTicket(ticketsIds[i], memberships[i]);
            }
        }
    }

    /**
     *  @dev Modifies the owner of a given event  to 'newOwner'
     *  This function can be called only by Event contract in case of an safeTransferFrom
     *  in order to syncronize events ownership in the Marketplace.
     *  @param eventId The id of the event whose owner will be modified
     *  @param newOwner The new owner of the event (will recieve future royalties)
     */
    function changeEventOwnership(uint256 eventId, address newOwner) external whenNotPaused onlyEventContract {
        ITicketMarketplace(ticketMarketplaceAddress).changeEventOwnerInTicketsForEvent(eventId, newOwner);
        emit EventOwnershipTransferred(eventId, newOwner);
    }

    /**
     *  @dev Deletes an event.
     *  @param eventId The id of the event to be deleted
     */
    function deleteEvent(uint256 eventId) external whenNotPaused onlyEventCreatorOrOwner(eventId) {
        ITicketMarketplace(ticketMarketplaceAddress).deleteEvent(eventId);

        IEvent(eventAddress).burn(eventId);

        emit EventDeleted(eventId);
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
     *  @dev Modifies creator's royalty for a given Event.
     *  @dev This function modifies the creator's royalty for all available tickets in the given event.
     *  @param eventId The id of the event whose royalty will be modified
     *  @param newCreatorRoyalty The new royalty to be setted
     */
    function modifyCreatorRoyaltyOnEvent(uint256 eventId, uint256 newCreatorRoyalty) external onlyEventCreator(eventId) whenNotPaused {
        ITicketMarketplace(ticketMarketplaceAddress).modifyCreatorRoyaltyOnEvent(eventId, newCreatorRoyalty);

        emit CreatorRoyaltyModifiedOnEvent(eventId, newCreatorRoyalty);
    }

    /**
     *  @dev Returns allowed memberships for a given ticket.
     *  @param ticketId The id of ticket
     */
    function membershipsAllowedForTicket(uint256 ticketId) external view returns (uint256[] memory) {
        return membershipsAllowedForTickets[ticketId];
    }

    /* public */

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/* Structs */

/// @dev Properties assigned to a particular ticket, including royalties and sellable status.
struct AssetProperties {
    uint256 creatorRoyalty;
    uint256 primaryMarketRoyalty;
    uint256 secondaryMarketRoyalty;
    address creator;
    bool isResellable;
}

/// @dev A particular sale Models.Offer made by a owner, including price and amount.
struct Offer {
    uint256 amount;
    uint256 price;
}

/// @dev all required information for publishing a new ticket.
struct NewAssetSaleInfo {
    uint256 amount;
    uint256 price;
    uint256 royalty;
    uint256 amountToSell;
    bool isResellable;
    string uri;
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