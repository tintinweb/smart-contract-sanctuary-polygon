/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Dice game contract
pragma solidity ^0.8.0;

contract DiceGame is Ownable {
    //variable
    bool public isPause;
    mapping(string => Room) public rooms;
    uint256 public commission;
    //structs
    struct Room {
        address creater;
        address joiner;
        string roomId;
        bool roomStatus;
        uint256 amount;
    }

    //events
    event CreateRoom(address creater, uint256 amount, string roomId);
    event JoinRoom(address joiner, string roomId);
    event LeaveRoom(address leaver, string roomId);
    event EndRoom(string roomId);

    constructor() {
        isPause = false;
        commission = 5 ether;
    }

    function pause(bool _isPause) public virtual onlyOwner returns (bool) {
        require(_isPause != isPause, "Already you have set.");
        isPause = _isPause;
        return isPause;
    }

    function setCommission(uint256 _commission)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        commission = _commission;
        return true;
    }

    function createRoom(string calldata _roomId) public payable returns (bool) {
        require(bytes(_roomId).length > 0, "Room Id is required.");
        require(msg.value >= 0, "Insufficient amount.");
        require(
            bytes(rooms[_roomId].roomId).length > 0,
            "The room is already created."
        );

        rooms[_roomId] = Room(msg.sender, address(0), _roomId, true, msg.value);

        emit CreateRoom(msg.sender, msg.value, _roomId);
        return true;
    }

    function joinRoom(string calldata _roomId) public payable returns (bool) {
        Room storage room = rooms[_roomId];
        require(bytes(_roomId).length > 0, "Room Id is required.");

        require(msg.value >= room.amount, "Insufficient amount.");
        require(bytes(room.roomId).length > 0, "The room wasn't created.");
        require(room.creater != msg.sender, "Joiner is not working.");
        require(room.roomStatus == true, "The room wasn't actived.");

        rooms[_roomId] = Room(
            room.creater,
            msg.sender,
            room.roomId,
            false,
            room.amount
        );

        emit JoinRoom(msg.sender, _roomId);
        return true;
    }

    function leaveRoom(string calldata _roomId) public virtual returns (bool) {
        Room storage room = rooms[_roomId];
        require(bytes(_roomId).length > 0, "Room Id is required.");

        require(bytes(room.roomId).length > 0, "The room wasn't created.");
        require(room.roomStatus == true, "The room wasn't actived.");
        require(room.creater == msg.sender, "Owner is not correct.");

        rooms[_roomId] = Room(
            room.creater,
            msg.sender,
            room.roomId,
            false,
            room.amount
        );
        // return money
        payable(msg.sender).transfer(room.amount);

        emit JoinRoom(msg.sender, _roomId);
        return true;
    }

    function endRoom(string calldata _roomId, bool _gameStatus)
        public
        onlyOwner
        returns (bool)
    {
        require(bytes(_roomId).length > 0, "Room Id is required.");
        Room storage room = rooms[_roomId];
        if (_gameStatus) {
            payable(room.creater).transfer(
                ((room.amount * 2) * (100 - commission / 1 ether)) / 100
            );
        } else {
            payable(room.joiner).transfer(
                ((room.amount * 2) * (100 - commission / 1 ether)) / 100
            );
        }
        return true;
    }

    function withraw() public virtual onlyOwner returns (bool) {
        require(address(this).balance >= 0, "Insufficient balance.");
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }
}