/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// File: @0xcert/ethereum-utils-contracts/src/contracts/permission/ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control which
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string constant NOT_OWNER = "018001";
  string constant ZERO_ADDRESS_NOT_ALLOWED = "018002";

  /**
   * @dev Address of the owner.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    virtual
    onlyOwner
  {
    require(_newOwner != address(0), ZERO_ADDRESS_NOT_ALLOWED);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: openzeppelin-solidity/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/ArianeeEvent/Pausable.sol


pragma solidity 0.8.0;

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/ArianeeEvent/ArianeeEvent.sol



pragma solidity 0.8.0;



abstract contract ERC721Interface {
    function canOperate(uint256 _tokenId, address _operator)virtual public returns(bool);
    function isTokenValid(uint256 _tokenId, bytes32 _hash, uint256 _tokenType, bytes memory _signature) virtual public view returns (bool);
    function issuerOf(uint256 _tokenId) virtual external view returns(address _tokenIssuer);
    function tokenCreation(uint256 _tokenId) virtual external view returns(uint256);
}

abstract contract iArianeeWhitelist {
    function addWhitelistedAddress(uint256 _tokenId, address _address) virtual public;
}

contract ArianeeEvent is
Ownable, Pausable{
    using SafeMath for uint256;

    address arianeeStoreAddress;
    iArianeeWhitelist arianeeWhitelist;
    ERC721Interface smartAsset;

    uint256 eventDestroyDelay = 31536000;

    /// Event ID per token
    mapping(uint256 => uint256[]) public tokenEventsList;

    mapping(uint256 => uint256) public idToTokenEventIndex;

    /// Mapping from tokenid to pending events
    mapping(uint256 => uint256[]) public pendingEvents;

    /// Mapping from event ID to its index in the pending events list
    mapping(uint256 => uint256) public idToPendingEvents;

    mapping(uint256 => uint256) public eventIdToToken;

    mapping(uint256 => uint256) public rewards;

    mapping(uint256 => bool) destroyRequest;

    /**
     * @dev Event list
     */
    mapping(uint256 => Event) internal events;
    //Event[] public events;

    struct Event{
        string URI;
        bytes32 imprint;
        address provider;
        uint destroyLimitTimestamp;
    }

    event EventCreated(uint256 indexed _tokenId, uint256 indexed _eventId, bytes32 indexed _imprint, string _uri, address _provider);
    event EventAccepted(uint256 indexed _eventId, address indexed _sender);
    event EventRefused(uint256 indexed _eventId, address indexed _sender);
    event EventDestroyed(uint256 indexed _eventId);
    event DestroyRequestUpdated(uint256 indexed _eventId, bool _active);
    event EventDestroyDelayUpdated(uint256 _newDelay);

    modifier onlyStore(){
        require(msg.sender == arianeeStoreAddress);
        _;
    }

    modifier canOperate(uint256 _eventId,address _operator){
        uint256 _tokenId = eventIdToToken[_eventId];
        require(smartAsset.canOperate(_tokenId, _operator) || smartAsset.issuerOf(_tokenId) == _operator);
        _;
    }

    modifier isProvider(uint256 _eventId) {
        require(msg.sender == events[_eventId].provider);
        _;
    }


    constructor(address _smartAssetAddress, address _arianeeWhitelistAddress){
        arianeeWhitelist = iArianeeWhitelist(address(_arianeeWhitelistAddress));
        smartAsset = ERC721Interface(address(_smartAssetAddress));
    }

    /**
     * @dev set a new store address
     * @notice can only be called by the contract owner.
     * @param _storeAddress new address of the store.
     */
    function setStoreAddress(address _storeAddress) public onlyOwner(){
        arianeeStoreAddress = _storeAddress;
    }


    /**
     * @dev create a new event linked to a nft
     * @notice can only be called through the store.
     * @param _tokenId id of the NFT
     * @param _imprint of the JSON.
     * @param _uri uri of the JSON of the service.
     * @param _reward total rewards of this event.
     * @param _provider address of the event provider.
     */
    function create(uint256 _eventId, uint256 _tokenId, bytes32 _imprint, string calldata _uri, uint256 _reward, address _provider) external onlyStore() whenNotPaused() {
        require(smartAsset.tokenCreation(_tokenId)>0);
        require(events[_eventId].provider == address(0));

        Event memory _event = Event({
            URI : _uri,
            imprint : _imprint,
            provider : _provider,
            destroyLimitTimestamp : eventDestroyDelay.add(block.timestamp)
        });

        events[_eventId] = _event;

        pendingEvents[_tokenId].push(_eventId);
        uint256 length = pendingEvents[_tokenId].length;
        idToPendingEvents[_eventId] = length.sub(1);

        eventIdToToken[_eventId] = _tokenId;

        rewards[_eventId]= _reward;

        emit EventCreated(_tokenId, _eventId, _imprint, _uri, _provider);
    }


    /**
     * @dev Accept an event so it can be concidered as valid.
     * @notice can only be called through the store by an operator of the NFT.
     * @param _eventId id of the service.
     */
    function accept(uint256 _eventId, address _sender) external onlyStore() canOperate(_eventId, _sender) whenNotPaused() returns(uint256){

        uint256 _tokenId = eventIdToToken[_eventId];
        uint256 pendingEventToRemoveIndex = idToPendingEvents[_eventId];
        uint256 lastPendingIndex = pendingEvents[_tokenId].length.sub(1);

        if(lastPendingIndex != pendingEventToRemoveIndex){
            uint256 lastPendingEvent = pendingEvents[_tokenId][lastPendingIndex];
            pendingEvents[_tokenId][pendingEventToRemoveIndex]=lastPendingEvent;
            idToPendingEvents[lastPendingEvent] = pendingEventToRemoveIndex;
        }

        pendingEvents[_tokenId].pop();
        delete idToPendingEvents[_eventId];

        tokenEventsList[_tokenId].push(_eventId);
        uint256 length = tokenEventsList[_tokenId].length;
        idToTokenEventIndex[_eventId] = length.sub(1);

        arianeeWhitelist.addWhitelistedAddress(_tokenId, events[_eventId].provider);
        uint256 reward = rewards[_eventId];
        delete rewards[_eventId];

        emit EventAccepted(_eventId, _sender);
        return reward;
    }

    /**
     * @dev refuse an event so it can be concidered as valid.
     * @notice can only be called through the store by an operator of the NFT.
     * @param _eventId id of the service.
     */
    function refuse(uint256 _eventId, address _sender) external onlyStore() canOperate(_eventId, _sender) whenNotPaused() returns(uint256){
        _destroyPending(_eventId);
        uint256 reward = rewards[_eventId];
        delete rewards[_eventId];
        emit EventRefused(_eventId, _sender);

        return reward;
    }

    function destroy(uint256 _eventId) external isProvider(_eventId) whenNotPaused(){
        require(block.timestamp < events[_eventId].destroyLimitTimestamp);
        require(idToPendingEvents[_eventId] == 0);
        _destroy(_eventId);
    }

    function updateDestroyRequest(uint256 _eventId, bool _active) external isProvider(_eventId) whenNotPaused() {
        require(idToPendingEvents[_eventId] == 0);
        destroyRequest[_eventId] = _active;
        emit DestroyRequestUpdated(_eventId, _active);
    }

    function validDestroyRequest(uint256 _eventId) external onlyOwner() whenNotPaused() {
        require(destroyRequest[_eventId] == true);
        destroyRequest[_eventId] = false;
        _destroy(_eventId);
    }

    function updateEventDestroyDelay(uint256 _newDelay) external onlyOwner() whenNotPaused() {
        eventDestroyDelay = _newDelay;
        emit EventDestroyDelayUpdated(_newDelay);
    }

    function getEvent(uint256 _eventId) public view returns(string memory uri, bytes32 imprint, address provider, uint timestamp){
        require(events[_eventId].provider != address(0));
        return (events[_eventId].URI, events[_eventId].imprint, events[_eventId].provider, events[_eventId].destroyLimitTimestamp);
    }

    function _destroy(uint256 _eventId) internal{

        uint256 _tokenId = eventIdToToken[_eventId];

        uint256 eventIdToRemove = idToTokenEventIndex[_eventId];
        uint256 lastEventId = tokenEventsList[_tokenId].length - 1;

        if(eventIdToRemove != lastEventId){
            uint256 lastEvent = tokenEventsList[_tokenId][lastEventId];
            tokenEventsList[_tokenId][eventIdToRemove] = lastEvent;
            idToTokenEventIndex[lastEvent] = eventIdToRemove;
        }

        tokenEventsList[_tokenId].length.sub(1);
        delete idToTokenEventIndex[_eventId];
        delete eventIdToToken[_eventId];
        delete events[_eventId];

        emit EventDestroyed(_eventId);

    }

    function _destroyPending(uint256 _eventId) internal{

        uint256 _tokenId = eventIdToToken[_eventId];
        uint256 pendingEventToRemoveIndex = idToPendingEvents[_eventId];
        uint256 lastPendingIndex = pendingEvents[_tokenId].length - 1;

        if(lastPendingIndex != pendingEventToRemoveIndex){
            uint256 lastPendingEvent = pendingEvents[_tokenId][lastPendingIndex];
            pendingEvents[_tokenId][pendingEventToRemoveIndex]=lastPendingEvent;
            idToPendingEvents[lastPendingEvent] = pendingEventToRemoveIndex;
        }

        pendingEvents[_tokenId].length.sub(1);

        delete idToPendingEvents[_eventId];
        delete eventIdToToken[_eventId];
        delete events[_eventId];

        emit EventDestroyed(_eventId);

    }

    function pendingEventsLength(uint256 _tokenId) public view returns(uint256){
        return pendingEvents[_tokenId].length;
    }

    function eventsLength(uint256 _tokenId) public view returns(uint256){
        return tokenEventsList[_tokenId].length;
    }

}