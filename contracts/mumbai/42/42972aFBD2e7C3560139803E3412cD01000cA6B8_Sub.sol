// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// TODO make good name
contract Sub {
    event SubscriptionCreated(
        string name,
        uint256 subId,
        uint256 amount,
        uint256 startTime,
        address user,
        address receiver,
        uint256 minSecondsAllowed
    );
    
    event SubscriptionActivated(uint256 subId);
    event SubscriptionDeactivated(uint256 subId);
    event SubscriptionPaid(uint256 subId,uint256 monthsPaid);
    modifier userRefersToSub(address user,uint256 subsId) {
        require(subscriptions[subsId].user == user, "sub does not refer to sender");
        _;
    }

    modifier onlySubActive(address user, uint256 subsId) {
        require(subscriptions[subsId].active, "sub is not active");
        _;
    }

    modifier onlyPaymentLeft(uint256 subsId) {
        uint256 secondsPassed = getSecondsPassed(subsId);
        require(secondsPassed > 0, "all amount is already paid");
        _;
    }

    uint64 subscriptionCounter = 0;
    struct Subscription {
        string name;
        uint256 amount;
        uint256 recentPaidTime;
        address user;
        bool active;
        address payable receiver;
        uint256 minSecondsAllowed;
    }
    struct User {
        uint256 Balance;
    }

    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => User) public users;

    receive() external payable {
        uint256 newBalance = users[msg.sender].Balance + msg.value;
        users[msg.sender].Balance = newBalance;
    }

    function userAcceptSub(uint256 subId)
        public
        userRefersToSub(msg.sender, subId)
    {
        subscriptions[subId].active = true;
        emit SubscriptionActivated(subId);
    }

    function userRemoveSub(uint256 subId)
        public
        userRefersToSub(msg.sender, subId)
    {
        subscriptions[subId].active = false;
        emit SubscriptionDeactivated(subId);
    }

    function orgCreateSub(string memory name,uint256 amount, address user,uint256 minSecondsAllowed)
        public
        returns (uint64)
    {
        subscriptionCounter++;
        subscriptions[subscriptionCounter].name = name;
        subscriptions[subscriptionCounter].amount = amount;
        subscriptions[subscriptionCounter].recentPaidTime = block.timestamp;
        subscriptions[subscriptionCounter].user = user;
        subscriptions[subscriptionCounter].minSecondsAllowed = minSecondsAllowed;

        //TODO
        subscriptions[subscriptionCounter].receiver = payable(msg.sender);
        emit SubscriptionCreated(
            name,
            subscriptionCounter,
            amount,
            block.timestamp,
            user,
            msg.sender,
            minSecondsAllowed
        );
        return subscriptionCounter;
    }

    function userCanPay(address userAddr, uint256 amount)
        internal
        view
        returns (bool)
    {
        return users[userAddr].Balance >= amount;
    }

    function orgGetPayment(address userAddr, uint256 subsId,uint256 minSec)
        public
        userRefersToSub(userAddr, subsId)
        onlySubActive(userAddr, subsId)
        onlyPaymentLeft(subsId)
    {
        uint256 amount = getAmountToBePaid(subsId);
        require(userCanPay(userAddr, amount), "user don't have enough balance");
        require(
            address(this).balance > amount,
            "contract don't have required amount"
        );
        subscriptions[subsId].recentPaidTime =
            block.timestamp;
        users[userAddr].Balance = users[userAddr].Balance - amount;
        subscriptions[subsId].receiver.transfer(amount);
        subscriptions[subsId].minSecondsAllowed=minSec;
        emit SubscriptionPaid(subsId, subscriptions[subsId].recentPaidTime);
    }

    function getSecondsPassed(uint256 subsId) public view returns (uint256) {
        Subscription memory sub = subscriptions[subsId];
        uint256 recentPaidTime = sub.recentPaidTime;
        return block.timestamp - recentPaidTime;
    }

    function canAccess(uint256 subsId) public view returns (bool) {
        if (!subscriptions[subsId].active) {
            return false;
        }
        uint256 secondsPassed = getSecondsPassed(subsId);
        return secondsPassed<subscriptions[subsId].minSecondsAllowed;
    }

    function getAmountToBePaid(uint256 subsId) public view returns (uint256) {
        Subscription memory sub = subscriptions[subsId];
        uint256 subAmount = sub.amount;
        uint256 amount = getSecondsPassed(subsId) * subAmount;
        return amount;
    }
}