/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/DODOFee/PoolHeartBeat.sol


contract PoolHeartBeat is InitializableOwnable {

    struct heartBeat {
        uint256 lastHeartBeat;
        uint256 maxInterval;
    }
    
    mapping(address => address) public poolHeartBeatManager; // pool => heartbeat manager
    mapping(address => heartBeat) public beats; // heartbeat manager => heartbeat

    function isPoolHeartBeatLive(address pool) external view returns(bool) {
        if(poolHeartBeatManager[pool]==address(0)) {
            return true;
        }
        heartBeat memory beat = beats[poolHeartBeatManager[pool]];
        return block.timestamp - beat.lastHeartBeat < beat.maxInterval;
    }

    function triggerBeat() external {
        heartBeat storage beat = beats[msg.sender];
        beat.lastHeartBeat = block.timestamp;
    }

    function setBeatInterval(uint256 interval) external {
        heartBeat storage beat = beats[msg.sender];
        beat.maxInterval = interval;
    }

    function bindPoolHeartBeat(address[] memory pools, address manager) external onlyOwner {
        for(uint256 i=0; i<pools.length; i++) {
            poolHeartBeatManager[pools[i]] = manager;
        }
    }
}