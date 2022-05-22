// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "./Events.sol";

// TODO make good name
contract Sub {

    modifier userRefersToSub(address user,uint256 subsId) {
        require(subscriptions[subsId].user == user, "sub does not refer to sender");
        _;
    }

    modifier onlySubActive(address user, uint256 subsId) {
        require(subscriptions[subsId].active, "sub is not active");
        _;
    }

    modifier onlyPaymentLeft(uint256 subsId) {
        uint256 monthsLeft = getMonthsLeft(subsId);
        require(monthsLeft > 0, "all amount is already paid");
        _;
    }

    uint64 subscriptionCounter = 0;
    struct Subscription {
        uint256 amount;
        uint256 startTime;
        uint256 monthsPaid;
        address user;
        bool active;
        address payable receiver;
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
        emit Events.SubscriptionActivated(subId);
    }

    function userRemoveSub(uint256 subId)
        public
        userRefersToSub(msg.sender, subId)
    {
        subscriptions[subId].active = false;
        emit Events.SubscriptionDeactivated(subId);
    }

    function orgCreateSub(uint256 amount, address user)
        public
        returns (uint64)
    {
        subscriptionCounter++;
        subscriptions[subscriptionCounter].amount = amount;
        subscriptions[subscriptionCounter].startTime = block.timestamp;
        subscriptions[subscriptionCounter].user = user;
        //TODO
        subscriptions[subscriptionCounter].receiver = payable(msg.sender);
        emit Events.SubscriptionCreated(
            subscriptionCounter,
            amount,
            block.timestamp,
            user,
            msg.sender
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

    function orgGetPayment(address userAddr, uint256 subsId)
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
        subscriptions[subsId].monthsPaid =
            getMonthsLeft(subsId) +
            subscriptions[subsId].monthsPaid;
        users[userAddr].Balance = users[userAddr].Balance - amount;
        subscriptions[subsId].receiver.transfer(amount);
        emit Events.SubscriptionPaid(subsId, subscriptions[subsId].monthsPaid);
    }

    function getMonthsLeft(uint256 subsId) internal view returns (uint256) {
        Subscription memory sub = subscriptions[subsId];
        uint256 monthsPaid = sub.monthsPaid;
        uint256 startTime = sub.startTime;
        uint256 timePassed = block.timestamp - startTime;
        //TODO days by user
        uint256 monthsPassed = timePassed / 60 / 60 / 24 / 12;
        return monthsPassed - monthsPaid;
    }

    function canAccess(uint256 subsId) public view returns (bool) {
        if (!subscriptions[subsId].active) {
            return false;
        }
        uint256 monthsLeft = getMonthsLeft(subsId);
        return monthsLeft == 0;
    }

    function getAmountToBePaid(uint256 subsId) internal view returns (uint256) {
        Subscription memory sub = subscriptions[subsId];
        uint256 subAmount = sub.amount;
        uint256 amount = getMonthsLeft(subsId) * subAmount;
        return amount;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library Events{
 event SubscriptionCreated(
        uint256 subId,
        uint256 amount,
        uint256 startTime,
        address user,
        address receiver
        );
    
    event SubscriptionActivated(uint256 subId);
    event SubscriptionDeactivated(uint256 subId);
    event SubscriptionPaid(uint256 subId,uint256 monthsPaid);
}