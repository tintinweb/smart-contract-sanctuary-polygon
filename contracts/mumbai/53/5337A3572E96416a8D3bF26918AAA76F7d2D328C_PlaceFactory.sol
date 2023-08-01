// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";

interface ITicketFactory {
    function createTicket(string memory date, string memory name) external;

    function activateTicket(address ticket) external;

    function cancelTicket(address ticket) external;
}

interface IPlace {
    function changeName(string memory newName) external;
}

contract PlaceFactory {
    address private manager;
    uint256 private placeCounter;
    address private ticketFactoryAddress;

    mapping(address => uint256) public idByPlace;
    mapping(address => bool) public activePlace;
    mapping(address => string) public placeToName;

    constructor() {
        manager = msg.sender;
        placeCounter = 0;
    }

    //EVENTS
    event PlaceCreated(address indexed placeAddress, string placeName, uint256 placeId);
    event PlaceActivated(address indexed placeAddress, uint256 placeId);
    event PlaceCanceled(address indexed placeAddress, uint256 placeId);
    //MODIFIERS
    modifier onlyManager() {
        require(manager == msg.sender);
        _;
    }
    modifier active(address place) {
        require(activePlace[place] == true);
        _;
    }
    modifier notActive(address place) {
        require(activePlace[place] == false);
        _;
    }

    //FUNCTIONS
    function setTicketFactoryAddress(address ticketFactory) external onlyManager {
        ticketFactoryAddress = ticketFactory;
    }

    function createPlace(string memory name, address owner) external onlyManager {
        uint256 placeId = placeCounter;
        placeCounter++;
        address newPlace = address(new Place(name, owner, msg.sender, ticketFactoryAddress));
        idByPlace[newPlace] = placeId;
        placeToName[newPlace] = name;
        emit PlaceCreated(newPlace, name, placeId);
    }

    function activatePlace(address place) external onlyManager notActive(place) {
        activePlace[place] = true;
        uint256 placeId = idByPlace[place];
        emit PlaceActivated(place, placeId);
    }

    function cancelPlace(address place) external onlyManager active(place) {
        uint256 placeId = idByPlace[place];
        activePlace[place] = false;
        emit PlaceCanceled(place, placeId);
    }

    function changePlaceName(address place, string memory newName) external onlyManager {
        IPlace(place).changeName(newName);
        placeToName[place] = newName;
    }

    //GETTERS
    function getIdByPlace(address place) external view returns (uint256) {
        return idByPlace[place];
    }

    function getNameByPlace(address place) external view returns (string memory) {
        return placeToName[place];
    }

    function getActivePlace(address place) external view returns (bool) {
        return activePlace[place];
    }
}

contract Place is Pausable {
    string private s_name;
    address private s_owner;
    address private s_manager;
    address private s_ticketFactoryAddress;
    address private s_placeFactoryAddress;

    constructor(string memory name, address owner, address manager, address ticketFactoryAddress) {
        s_name = name;
        s_owner = owner;
        s_manager = manager;
        s_ticketFactoryAddress = ticketFactoryAddress;
        s_placeFactoryAddress = msg.sender;
    }

    //MODIFIERS
    modifier onlyOwner() {
        require(s_owner == msg.sender || s_manager == msg.sender);
        _;
    }
    modifier onlyManager() {
        require(s_manager == msg.sender);
        _;
    }
    modifier onlyFactory() {
        require(s_placeFactoryAddress == msg.sender);
        _;
    }

    //PAUSABLE
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //FUNCTIONS
    function setTicketFactoryAddress(address newAddress) external onlyManager {
        s_ticketFactoryAddress = newAddress;
    }

    function setPlaceFactoryAddress(address newAddress) external onlyManager {
        s_placeFactoryAddress = newAddress;
    }

    function createEvent(string memory date, string memory name) external onlyOwner {
        ITicketFactory(s_ticketFactoryAddress).createTicket(date, name);
    }

    function changeName(string memory newName) external onlyFactory {
        s_name = newName;
    }

    function changeOwner(address newOwner) external onlyManager {
        s_owner = newOwner;
    }

    //GETTERS
    function getName() external view returns (string memory) {
        return s_name;
    }

    function getOwner() external view returns (address) {
        return s_owner;
    }
}