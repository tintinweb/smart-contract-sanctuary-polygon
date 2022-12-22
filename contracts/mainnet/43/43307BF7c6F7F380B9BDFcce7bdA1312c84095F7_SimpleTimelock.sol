/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/utils/timelock.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleTimelock {

    error NotOwnerError();
    error NotPendingError();
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint blockTimestmap, uint timestamp);
    error TimestampExpiredError(uint blockTimestamp, uint expiresAt);
    error TxFailedError();
    error NoTimelock(string func);
    error TimelockAlreadyAdded();
    error TimelockNotPresent();
    error TimelockRemovalPresent();
    error TimelockRemovalMissing();
    error ValueMissing(uint expected, uint actual);

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    event Cancel(bytes32 indexed txId);

    /*
    Event Definitions:
        add timelock = 1
        queue removal = 2
        remove timelock = 0 (aka default status)
        cancel timelock removal queue = -1
    */
    event UpdatedTimelock(string func, int status);

    uint public constant MIN_DELAY = 86_400; // seconds, 1 day
    uint public constant MAX_DELAY = 259_200; // seconds, 3 days
    uint public constant GRACE_PERIOD = 259_200; // seconds, 3 days grace

    address public owner;
    address public pending;

    // tx id => queued
    mapping(bytes32 => bool) public queued;

    // func signature => timelocked
    mapping(string => bool) public timelock;

    // func => time to remove
    mapping(string => uint256) public queueTimelock;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }

    modifier onlyPending() {
        if (msg.sender != pending) {
            revert NotPendingError();
        }
        _;
    }
    receive() external payable {}


    /**
     * @notice return txId of a transaction
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send.
     * @param _timestamp Timestamp after which the transaction can be executed.
     */
    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }

    /**
     * @notice adds a tx to a queue
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send.
     * @param _timestamp Timestamp after which the transaction can be executed.
     * @return txId id of queued transaction
     */
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner returns (bytes32 txId) {
        if(!timelock[_func]) {
            revert NoTimelock(_func);
        }

        txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }
        // ---|------------|---------------|-------
        //  block    block + min     block + max
        if (
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        queued[txId] = true;

        emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }


    /**
     * @notice exectus a tx from the queue
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send.
     * @param _timestamp Timestamp after which the transaction can be executed.
     * @return res result of executed transaction
     */
    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {

        if(msg.value != _value) {
            revert ValueMissing(_value, msg.value);
        }

        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (!queued[txId] && timelock[_func]) {
            // if not queued and not timelocked, execute passthrough.
            revert NotQueuedError(txId);
        }
        // ----|-------------------|-------
        //  timestamp    timestamp + grace period
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
        }

        queued[txId] = false;

        // prepare data
        bytes memory data;
        if (bytes(_func).length > 0) {
            // data = func selector + _data
            data = abi.encodePacked(
                    bytes4(keccak256(bytes(_func))), _data);
        } else {
            // call fallback with data
            data = _data;
        }
        
        // call target
        (bool ok, bytes memory res) = _target.call{value: _value}(data);
        if (!ok) {
            revert TxFailedError();
        }
        emit Execute(txId, _target, _value, _func, _data, _timestamp);

        return res;
    }

    /**
     * @notice cancels a tx from the queue
     * @param _txId txId of the tx to cancel from queue
     */
    function cancel(bytes32 _txId) external onlyOwner {
        if (!queued[_txId]) {
            revert NotQueuedError(_txId);
        }

        queued[_txId] = false;

        emit Cancel(_txId);
    }

    /**
     * @notice add a timelock for a method signature
     * @param _func method signature to add a timelock for
     */
    function addTimelock(string calldata _func) external onlyOwner {
        if(timelock[_func]){
            revert TimelockAlreadyAdded();
        }
        timelock[_func]=true;
        emit UpdatedTimelock(_func,1);
    }

    /**
     * @notice remove a timelock for a method signature by adding it to a removal queue
     * @param _func method signature to queue a timelock removal for
     */
    function queueRemoveTimelock(string calldata _func) external onlyOwner {
        if(!timelock[_func]){
            revert TimelockNotPresent();
        }

        if((queueTimelock[_func]>0)){
            revert TimelockRemovalPresent();
        }

        queueTimelock[_func]=block.timestamp + MIN_DELAY; // min delay is required to remove timelocked functions
        emit UpdatedTimelock(_func,2);
    }

    /**
     * @notice cancels a queued removal of a timelock
     * @param _func method signature to cancel a timelock for
     */
    function cancelTimelockQueue(string calldata _func) external onlyOwner {
        if(!timelock[_func]){
            revert TimelockNotPresent();
        }
        if(!(queueTimelock[_func]>0)){
            revert TimelockRemovalMissing();
        }
        queueTimelock[_func]=0; // uint256
        emit UpdatedTimelock(_func,-1); 
    }

    /**
     * @notice removed a timelock for a method signature
     * @param _func method signature to remove a timelock for
     */
    function removeTimelock(string calldata _func) external onlyOwner {
        if(!timelock[_func]){
            revert TimelockNotPresent();
        }
        if(!(queueTimelock[_func]>0)){
            revert TimelockRemovalMissing();
        }
        if(block.timestamp < queueTimelock[_func]) {
            revert TimestampNotPassedError(block.timestamp, queueTimelock[_func]);
        }

        queueTimelock[_func]=0; // uint256
        timelock[_func]=false; // boolean
        emit UpdatedTimelock(_func,0);
    }

    /**
     * @notice propose a new owner for the contract
     * @param newOwner address to be a potential owner
     */
    function proposeOwner(address newOwner) external onlyOwner {
        pending = newOwner;
    }

    /**
     * @notice accept ownership of the contract
     */
    function acceptOwner() external onlyPending() {
        owner = pending;
    }
    
    // /**
    //  * @notice transfer ETH out of itself
    //  * @param to address to send ETH to
    //  * @param amount amount of eth to send to address
    //  */
    // function transferNative(address payable to, uint256 amount) external onlyOwner {
    //     to.transfer(amount);
    // }
}