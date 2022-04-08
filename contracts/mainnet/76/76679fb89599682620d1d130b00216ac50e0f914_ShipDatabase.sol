/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns(address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Controllable is Ownable {
    mapping(address => bool) internal _controllers;

    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    function addController(address _controller)
    external
    onlyOwner {
        _controllers[_controller] = true;
    }

    function delController(address _controller)
    external
    onlyOwner {
        delete _controllers[_controller];
    }

    function disableController(address _controller)
    external
    onlyOwner {
        _controllers[_controller] = false;
    }

    function isController(address _address)
    external
    view
    returns(bool allowed) {
        allowed = _controllers[_address];
    }

    function relinquishControl() external onlyController {
        delete _controllers[msg.sender];
    }
}

contract ShipDatabase is Controllable {

    struct Spaceship {
        uint256 id;
        uint256 speed;
        uint256 strength;
        uint256 attack;
        uint256 fuel;
        uint256 class;
    }
    mapping(uint256 => Spaceship) spaceships;

    function pushSpeed(uint256 shipnum, uint256 newSpeed) public onlyController {
        spaceships[shipnum].speed = newSpeed;
    }

    function pushStrength(uint256 shipnum, uint256 newStrength) public onlyController {
        spaceships[shipnum].strength = newStrength;
    }

    function pushAttack(uint256 shipnum, uint256 newAttack) public onlyController {
        spaceships[shipnum].attack = newAttack;
    }

    function pushID(uint256 shipnum) public onlyController {
        spaceships[shipnum].id = shipnum;
    }

    function pushFuel(uint256 shipnum, uint256 newFuel) public onlyController {
        spaceships[shipnum].fuel = newFuel;
    }

    function pushClass(uint256 shipnum, uint256 newClass) public onlyController {
        spaceships[shipnum].class = newClass;
    }

    function pushAll(uint256 shipnum, uint256 newSpeed, uint256 newStrength, uint256 newAttack, uint256 newFuel, uint256 newClass) external onlyController {
        pushSpeed(shipnum, newSpeed);
        pushStrength(shipnum, newStrength);
        pushAttack(shipnum, newAttack);
        pushID(shipnum);
        pushFuel(shipnum, newFuel);
        pushClass(shipnum, newClass);
    }

    function getSpeed(uint256 shipnum) public view returns(uint256) {
        return spaceships[shipnum].speed;
    }

    function getStrength(uint256 shipnum) public view returns(uint256) {
        return spaceships[shipnum].strength;
    }

    function getAttack(uint256 shipnum) public view returns(uint256) {
        return spaceships[shipnum].attack;
    }

    function getID(uint256 shipnum) public view returns(uint256) {
        return spaceships[shipnum].id;
    }

    function getFuel(uint256 shipnum) public view returns(uint256) {
        return spaceships[shipnum].fuel;
    }

    function getClass(uint256 shipnum) public view returns(uint256) {
        return spaceships[shipnum].class;
    }
}