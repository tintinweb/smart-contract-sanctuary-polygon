// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// TODO make good name
contract Sub {
    event SubscriptionCreated(
        string name,
        uint256 subId,
        uint256 amount,
        uint256 recentPaidTime,
        address user,
        address receiver,
        uint256 minSecondsAllowed,
        uint256 planId
    );

    event PlanCreated(uint256 planId);
    
    event SubscriptionActivated(uint256 subId);
    event SubscriptionDeactivated(uint256 subId);
    event SubscriptionPaid(uint256 subId,uint256 recentPaidTime);
    modifier userRefersToSub(address user,uint256 subsId) {
        require(subscriptions[subsId].user == user, "sub does not refer to sender");
        _;
    }

    modifier onlySubActive(uint256 subsId) {
        require(subscriptions[subsId].subState==SubState.STARTED, "sub is not active");
        _;
    }

    modifier onlySubNew(uint256 subsId) {
        require(subscriptions[subsId].subState==SubState.NEW, "sub is not active");
        _;
    }

    modifier onlyPaymentLeft(uint256 subsId) {
        Subscription memory sub = subscriptions[subsId]; 
        uint256 secondsPassed = getSecondsPassed(subsId);
        require(secondsPassed/sub.minSecondsAllowed > 0, "all amount is already paid");
        _;
    }

    modifier onlyPlanOwner(uint256 planId){
        Plan memory plan = plans[planId];
        require(plan.owner==msg.sender, "sender is not owner of plan");
        _;
    }

    modifier canCompletedInitialPayment(uint256 subId){
           Subscription memory sub = subscriptions[subId]; 
           uint256 amount =  sub.amount;
           require(!sub.needsPayment || users[sub.user].Balance >= amount ,"subscription requires to be paid at start");
           _;
    }

    enum SubState{ NEW, STARTED, STOPPED }
    uint256 subscriptionCounter = 0;
    uint256 planCounter = 0;
    struct Subscription {
        string name;
        uint256 amount;
        uint256 recentPaidTime;
        address user;
        SubState subState;
        bool needsPayment;
        address payable receiver;
        uint256 minSecondsAllowed;
        uint256 planId;
    }
    struct User {
        uint256 Balance;
        mapping(uint256=>uint256) plansToSubId;
    }

    struct Plan {
        address owner;
    }
    mapping(uint256 => Plan) public plans;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => User) public users;

    receive() external payable {
        uint256 newBalance = users[msg.sender].Balance + msg.value;
        users[msg.sender].Balance = newBalance;
    }

    function userStartSub(uint256 subId)
        payable
        public
        userRefersToSub(msg.sender, subId)
        canCompletedInitialPayment(subId)
        onlySubNew(subId)
    {
        Subscription memory sub = subscriptions[subId];
        if(!subscriptions[subId].needsPayment){
            require(userCanPay(sub.user, sub.amount), "user don't have enough balance");
            users[sub.user].Balance=users[sub.user].Balance-sub.amount;
            sub.receiver.transfer(sub.amount);
            subscriptions[subId].needsPayment = false;
        }
        subscriptions[subId].subState = SubState.STARTED;
        subscriptions[subId].recentPaidTime = block.timestamp;
        emit SubscriptionActivated(subId);
    }

    function userStopSub(uint256 subId)
        public
        userRefersToSub(msg.sender, subId)
        onlySubActive(subId)
    {
        subscriptions[subId].subState = SubState.STOPPED;
        emit SubscriptionDeactivated(subId);
    }

    function orgCreatePlan() public returns (uint256){
        planCounter++;
        plans[planCounter].owner=msg.sender;
        emit PlanCreated(planCounter);
        return planCounter;
    }

    function orgCreateSub(string memory name,uint256 amount, address user,uint256 minSecondsAllowed,uint256 planId,bool initPaymentNeeded)
        public
        onlyPlanOwner(planId)
        returns (uint256)
    {
        subscriptionCounter++;
        subscriptions[subscriptionCounter].name = name;
        subscriptions[subscriptionCounter].amount = amount;
        subscriptions[subscriptionCounter].recentPaidTime = block.timestamp;
        subscriptions[subscriptionCounter].user = user;
        subscriptions[subscriptionCounter].minSecondsAllowed = minSecondsAllowed;
        subscriptions[subscriptionCounter].planId = planId;
        subscriptions[subscriptionCounter].needsPayment = initPaymentNeeded;

        users[user].plansToSubId[planId] = subscriptionCounter;
        //TODO
        subscriptions[subscriptionCounter].receiver = payable(msg.sender);
        emit SubscriptionCreated(
            name,
            subscriptionCounter,
            amount,
            block.timestamp,
            user,
            msg.sender,
            minSecondsAllowed,
            planId
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
        onlySubActive(subsId)
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
        emit SubscriptionPaid(subsId, subscriptions[subsId].recentPaidTime);
    }

    function getSecondsPassed(uint256 subsId) public view returns (uint256) {
        Subscription memory sub = subscriptions[subsId];
        uint256 recentPaidTime = sub.recentPaidTime;
        return block.timestamp - recentPaidTime;
    }

    function canAccess(address userAddr,uint256 planId) public view returns (bool) {
        uint256 subId = users[userAddr].plansToSubId[planId];
        if (
            subscriptions[subId].subState==SubState.NEW ||
            subscriptions[subId].subState==SubState.STOPPED
        ) {
            return false;
        }
        uint256 secondsPassed = getSecondsPassed(subId);
        return secondsPassed<subscriptions[subId].minSecondsAllowed;
    }

    function getAmountToBePaid(uint256 subsId) public view returns (uint256) {
        Subscription memory sub = subscriptions[subsId];
        uint256 subAmount = sub.amount;
        uint256 amount = (getSecondsPassed(subsId)/sub.minSecondsAllowed) * subAmount;
        return amount;
    }
}