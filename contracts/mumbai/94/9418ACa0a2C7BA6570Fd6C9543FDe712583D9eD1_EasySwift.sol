/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier fromOwner() {
        require(msg.sender == owner, "Only owner can access");
        _;
    }

    function setOwner(address newOwner) public fromOwner {
        owner = newOwner;
    }
}

pragma solidity ^0.8.8;

contract EasySwift is Owned {
    
    function authenticate(
        bytes32 input1,
        bytes32 input2,
        bytes32 password1,
        bytes32 password2
    ) internal pure returns (bool authenticated) {
        if (input1 == password1 && input2 == password2) {
            return true;
        }
        return false;
    }

    function createKey(bytes32 hash1, bytes32 hash2)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(hash1, hash2));
    }

    // Data
    struct LockBox {
        address creator;
        address receiver;
        uint256 amount;
        bytes32 hash1;
        bytes32 hash2;
        uint256 creationTime;
        bool active;
        uint256 index;
    }

    struct LockBoxes {
        mapping(bytes32 => LockBox) boxes;
    }

    struct LockBoxIndex {
        bytes32[] boxIndex;
    }

    function boxExists(
        LockBoxes storage s1,
        LockBoxIndex storage s2,
        bytes32 lockBoxKey
    ) internal view returns (bool exists) {
        if (s2.boxIndex.length == 0) return false;
        return (s2.boxIndex[s1.boxes[lockBoxKey].index] == lockBoxKey);
    }

    function insert(
        LockBoxes storage s1,
        LockBoxIndex storage s2,
        address _receiver,
        address _creator,
        uint256 _amount,
        bytes32 _password1,
        bytes32 _password2
    ) internal returns (bool) {
        bytes32 lockBoxKey = keccak256(
            abi.encodePacked(_password1, _password2)
        );
        if (s1.boxes[lockBoxKey].active) return false;

        s2.boxIndex.push(lockBoxKey);
        s1.boxes[lockBoxKey] = LockBox({
            creator: _creator,
            receiver: _receiver,
            amount: _amount,
            hash1: _password1,
            hash2: _password2,
            creationTime: block.timestamp,
            active: true,
            index: s2.boxIndex.length - 1
        });
        return true;
    }

    LockBoxes private lockBox;
    LockBoxIndex private lockBoxIndex;

    mapping(address => uint256) private pendingWithdrawals;

    bool private locked;
    uint256 public totalAmountInHolding;
    uint256 private totalAmountOnDeposit;
    uint256 private totalAmountFees;
    uint256 public ownerFee = 100000 wei;
    uint256 public deadline = 6 days;
    uint256 public deadlineLimit = 2 weeks;
    bool public stopped = false;

    // events
    event LogLockBoxCreated(
        address indexed receiver,
        uint256 indexed amount,
        bytes32 indexed lockBoxKey,
        bool result
    );

    event LogFundsUnlocked(
        address indexed account,
        uint256 indexed amount,
        bool indexed result
    );

    event LogWithdrawal(
        address indexed payee,
        uint256 indexed amount,
        bool indexed result
    );

    event LogDeposit(address indexed account, uint256 indexed amount);

    event transfer_(address indexed account, uint256 indexed totalAmountFees);

    event Transfer(address indexed from, address indexed to, uint256 value);

    // modifiers
    modifier boxExists1(bytes32 _lockBoxKey) {
        if (!boxExists(lockBox, lockBoxIndex, _lockBoxKey))
            revert("box does not exist");
        _;
    }

    modifier authenticate1(
        bytes32 _password1,
        bytes32 _password2,
        bytes32 lockBoxKey
    ) {
        if (
            !authenticate(
                _password1,
                _password2,
                lockBox.boxes[lockBoxKey].hash1,
                lockBox.boxes[lockBoxKey].hash2
            )
        ) revert("authentication error");

        _;
    }

    modifier onlyBy(address _account) {
        if (msg.sender != _account) revert("You can't access");
        _;
    }

    modifier onlyAfterDeadline(uint256 _creationTime) {
        if (block.timestamp < _creationTime + deadline)
            revert("deadline is not reached");
        _;
    }

    modifier onlyBeforeDeadline(uint256 _creationTime) {
        if (block.timestamp > (_creationTime + deadline))
            revert("deadline reached");
        _;
    }

    modifier stopInEmergency() {
        if (stopped) revert("stop in emergency");
        _;
    }

    modifier onlyInEmergency() {
        if (stopped) revert("only in emergency");
        _;
    }

    constructor() {}

    function createLockBox(
        address _receiver,
        bytes32 _password1,
        bytes32 _password2
    ) public payable stopInEmergency returns (bool) {
        if (_receiver != msg.sender) {
            uint256 amount = msg.value - ownerFee;
            if (
                insert(
                    lockBox,
                    lockBoxIndex,
                    _receiver,
                    msg.sender,
                    amount,
                    _password1,
                    _password2
                )
            ) {
                emit LogLockBoxCreated(
                    _receiver,
                    amount,
                    getKey(_password1, _password2),
                    true
                );
                totalAmountInHolding += msg.value;
                depositFee(ownerFee);
                return true;
            } else {
                emit LogLockBoxCreated(_receiver, amount, 0x0, false);
                revert();
            }
        }
        revert("Sender and Receiver are same");
    }

    function getLockBox(bytes32 _lockBoxKey)
        public
        view
        returns (
            address creator,
            address receiver,
            uint256 amount,
            uint256 creationTime,
            bool active,
            uint256 index
        )
    {
        LockBox memory box;
        box = lockBox.boxes[_lockBoxKey];
        return (
            box.creator,
            box.receiver,
            box.amount,
            box.creationTime,
            box.active,
            box.index
        );
    }

    function getLockBoxCount() public view returns (uint256 count) {
        return lockBoxIndex.boxIndex.length;
    }

    function getLockBoxKeyAtIndex(uint256 index)
        public
        view
        returns (bytes32 lockBoxKey)
    {
        return lockBoxIndex.boxIndex[index];
    }

    function unlockFunds(bytes32 _lockBoxKey, address _beneficiary)
        private
        returns (bool)
    {
        if (!locked) {
            locked = true;
            uint256 amtToDeposit;

            amtToDeposit = lockBox.boxes[_lockBoxKey].amount;
            lockBox.boxes[_lockBoxKey].amount = 0;
            lockBox.boxes[_lockBoxKey].active = false;
            payable(msg.sender).transfer(amtToDeposit);
            totalAmountInHolding -= amtToDeposit;
            deposit(_beneficiary, amtToDeposit);

            locked = false;
            if (address(this).balance < totalAmountInHolding)
                emit LogFundsUnlocked(_beneficiary, amtToDeposit, true);

            return true;
        }
        revert();
    }

    function claimFunds(
        bytes32 password1,
        bytes32 password2,
        bytes32 lockBoxKey
    )
        public
        onlyBy(lockBox.boxes[lockBoxKey].receiver)
        authenticate1(password1, password2, lockBoxKey)
        boxExists1(lockBoxKey)
        onlyBeforeDeadline(lockBox.boxes[lockBoxKey].creationTime)
        stopInEmergency
        returns (bool)
    {
        return unlockFunds(lockBoxKey, msg.sender);
    }

    function reclaimFunds(bytes32 lockBoxKey)
        public
        boxExists1(lockBoxKey)
        onlyAfterDeadline(lockBox.boxes[lockBoxKey].creationTime)
        stopInEmergency
        returns (bool)
    {
        return unlockFunds(lockBoxKey, msg.sender);
    }

    function getBalance(address account) public view returns (uint256 balance) {
        return pendingWithdrawals[account];
    }

    function withdraw(uint256 amount) public stopInEmergency returns (bool) {
        getBalance(msg.sender);
        if (!locked && amount > 0 && pendingWithdrawals[msg.sender] <= amount) {
            locked = true;
            pendingWithdrawals[msg.sender] -= amount;
            totalAmountOnDeposit -= amount;
            payable(msg.sender).transfer(amount);
            locked = false;
            emit LogWithdrawal(msg.sender, amount, false);
            return false;
        }
        locked = false;
        if (address(this).balance < totalAmountOnDeposit) revert();
        emit LogWithdrawal(msg.sender, amount, true);
        return true;
    }

    function deposit(address _account, uint256 _deposit) private {
        pendingWithdrawals[_account] += _deposit;
        totalAmountOnDeposit += _deposit;
        emit LogDeposit(_account, _deposit);
    }

    function depositFee(uint256 _deposit) private {
        totalAmountFees += _deposit;
    }

    function withdrawFees() public fromOwner stopInEmergency {
        require(address(this).balance >= totalAmountFees, "Insufficent Funds");
        payable(owner).transfer(totalAmountFees);
        emit Transfer(address(this), msg.sender, totalAmountFees);
        totalAmountFees = 0;
    }

    function getCollectedFeeAmount() public view fromOwner returns (uint256) {
        return totalAmountFees;
    }

    function setOwnerFee(uint256 _fee)
        public
        fromOwner
        stopInEmergency
        returns (uint256)
    {
        ownerFee = _fee;
        return ownerFee;
    }

    function setDeadline(uint256 _timeInSeconds)
        public
        fromOwner
        stopInEmergency
        returns (bool)
    {
        if (_timeInSeconds <= deadlineLimit) {
            deadline = _timeInSeconds;
            return true;
        }
        revert();
    }

    function toggleContractActive() public fromOwner {
        stopped = !stopped;
    }

    function recoverBalance() public fromOwner onlyInEmergency returns (bool) {
        uint256 _bal = address(this).balance;
        if (_bal > 0) {
            emit Transfer(address(this), msg.sender, address(this).balance);
            payable(owner).transfer(address(this).balance);
            totalAmountFees = 0;
            totalAmountInHolding = 0;
            return true;
        }
        revert("something went wrong");
    }

    function getKey(bytes32 _hash1, bytes32 _hash2)
        public
        pure
        returns (bytes32)
    {
        return createKey(_hash1, _hash2);
    }
}