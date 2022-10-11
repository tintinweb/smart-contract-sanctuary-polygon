// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
contract EightsGame is Ownable {

    enum GameType { 
        Connect4,
        TicTacToe
    }
    enum GameStatus {
        Created,
        InProgress,
        Complete
    }
    enum GameResult {
        Undefined,
        CreatorWon,
        CreatorLost,
        Draw
    }
    struct Room {
        uint256 roomId;
        string roomName;
        address roomOwner;
        address[] players;
        uint256 wagerAmount;
        GameType gameType;
        GameStatus gameStatus;
    }
    Room[] public rooms;
    mapping(uint => Room) public roomMap;
    mapping(address => uint256) public userToRoomId;

    // constructor to initialize the contract
    constructor() {
        // initialize the contract
    }

    event RoomCreated(uint256 gameId, address creator, uint256 wagerAmount);
    event RoomJoined(uint256 gameId, address joiner, uint256 wagerAmount);
    event GameCompleted(uint256 gameId, address winner, address loser, uint256 wagerAmount);
    event RoomCountUpdate(uint256 count);

    function createRoom(
        uint256 _roomId,
        string memory _roomName,
        address _roomOwner,
        uint256 _wagerAmount,
        GameType _gameType
    ) public {

        Room memory room = Room({
            roomId: _roomId,
            roomName: _roomName,
            roomOwner: _roomOwner,
            players: new address[](0),
            wagerAmount: _wagerAmount,
            gameType: _gameType,
            gameStatus: GameStatus.Created
        });

        if(_wagerAmount > 0) {
            // owner must deposit the wager amount
            depositWager(_wagerAmount);
        }
        rooms.push(room);
        roomMap[_roomId] = room;
        userToRoomId[_roomOwner] = _roomId;

        // add room owner to list of players
        roomMap[_roomId].players.push(_roomOwner);
        emit RoomCreated(_roomId, _roomOwner, _wagerAmount);
        emit RoomCountUpdate(rooms.length);
    }
    // make a deposit to the contract
    function depositWager(uint256 _wagerAmount) public payable {
        // add the deposit to the contract
        payable(msg.sender).transfer(_wagerAmount);

    }
    // withdraw from the contract
    function withdraw(uint256 _amount) private{
        // withdraw the amount from the contract

    }


    function joinRoom(uint256 _roomId) public {
        Room storage room = roomMap[_roomId];
        room.players.push(msg.sender);
        room.gameStatus = GameStatus.InProgress;
        userToRoomId[msg.sender] = _roomId;
        emit RoomJoined(_roomId, msg.sender, room.wagerAmount);
    }

    function startGame(uint256 _roomId, uint256 _wagerAmount) public {
        Room storage room = roomMap[_roomId];
        // both players need to deposit 
        room.gameStatus = GameStatus.InProgress;
    }

    function completeGame(uint256 _roomId, address _winner, address _loser) public {
        Room storage room = roomMap[_roomId];
        room.gameStatus = GameStatus.Complete;
        uint wagerAmount = room.wagerAmount;
        if(wagerAmount > 0) {
            // transfer the wager amount to the winner
            payable(_winner).transfer(wagerAmount);
        }
        

        // remove the room from the rooms array
        for (uint256 i = 0; i < rooms.length; i++) {
            if (rooms[i].roomId == _roomId) {
                rooms[i] = rooms[rooms.length - 1];
                rooms.pop();
                break;
            }
        }

        emit GameCompleted(_roomId, _winner, _loser, room.wagerAmount);
        emit RoomCountUpdate(rooms.length);
    }

    function getRoom(uint256 _roomId) public view returns (Room memory) {
        return roomMap[_roomId];
    }

    function getRoomId(address _user) public view returns (uint256) {
        return userToRoomId[_user];
    }

    function getRooms() public view returns (Room[] memory) {
        return rooms;
    }

    function getRoomCount() public view returns (uint256) {
        return rooms.length;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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