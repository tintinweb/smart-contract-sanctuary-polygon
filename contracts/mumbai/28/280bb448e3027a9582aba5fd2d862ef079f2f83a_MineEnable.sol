/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Owner {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able, address indexed owner);

    constructor() {
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0), "zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner, "not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _pause;
    }

    function setPaused(bool p) external onlyOwner {
        _pause = p;
    }

    modifier checkContractCall() {
        require(contractCallable() || notContract(msg.sender), "non contract");
        _;
    }

    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }

    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able, _owner);
    }

    function notContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }
}

contract MineEnable is Owner {
    struct Miner {
        string name;
        bool exist;
        bool enable;
    }

    mapping(address => Miner) public miners;
    address[] private allMiners;

    event AddMiner(address indexed miner);
    event MinerEnable(address indexed miner, bool enable);

    function addMinter(address miner_, string memory name_) external onlyOwner {
        require(!miners[miner_].exist, "Comptroller: miner is exist");

        miners[miner_] = Miner({name: name_, exist: true, enable: true});

        allMiners.push(miner_);
        emit AddMiner(miner_);
    }

    constructor() {}

    function minerEnable(address miner_, bool enable) external onlyOwner {
        miners[miner_].enable = enable;
        emit MinerEnable(miner_, enable);
    }

    function getAllMiners() external view returns (address[] memory) {
        return allMiners;
    }

    function isMiner(address account) external view returns (bool) {
        return miners[account].enable;
    }
}