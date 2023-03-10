/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

pragma solidity ^0.8.9;

interface ILock {
    function keyPrice() external view returns (uint);
    function getHasValidKey(address _user) external view returns (bool);
    function getCancelAndRefundValue(uint _tokenId) external view returns (uint refund);
    function expireAndRefundFor(uint256 _tokenId, uint256 amount) external;
}

error Expired(string reason);
error ExceedsCapacity(string reason);
error UnexpectedUsageRemoval(string reason);
error CallerIsNotAPlan(string reason);

contract SubscriptionManager {
    mapping(uint256 => address) plans;
    mapping(address => uint256) capacities;

    struct Subscription {
        uint256 usage;
        uint256 tokenId;
        ILock plan;
    }

    mapping(address => Subscription) subscriptions;

    constructor() {
        address basicPlan = 0xc8c2e7228c319c9721878f9F90f43E225D2688d8;
        plans[0] = basicPlan;
        capacities[basicPlan] = 3;

        address teamPlan = 0xe1654AdC4b2b52c9270039a30dFe3A7A6176F8bA;
        plans[1] = teamPlan;
        capacities[teamPlan] = 15;
    }

    /// checks if msg.sender caller is one of the plan contracts set above
    modifier isBotExecutionPlan() {
        bool found;
        for (uint256 i = 0; i < 2; i++) {
            if (plans[i] == msg.sender) {
                found = true;
                break;
            }
        }
        if (!found) {
            revert CallerIsNotAPlan("caller is not a plan");
        }
        _;
    }

    /// bot registry calls this method to increment the usage
    function incrementBotOwnerUsage(address botOwner, uint256 addedUsage) external {
        Subscription memory subscription = subscriptions[botOwner];

        if (!subscription.plan.getHasValidKey(botOwner)) {
            revert Expired("expired");
        }

        uint256 capacity = capacities[address(subscription.plan)];
        subscription.usage += addedUsage;
        if (subscription.usage > capacity) {
            revert ExceedsCapacity("exceeds capacity");
        }

        subscriptions[botOwner] = subscription;
    }

    /// bot registry calls this method to decrement the usage
    function decrementBotOwnerUsage(address botOwner, uint256 removedUsage) external {
        Subscription memory subscription = subscriptions[botOwner];

        if (!subscription.plan.getHasValidKey(botOwner)) {
            revert Expired("expired");
        }

        if (subscription.usage < removedUsage) {
            revert UnexpectedUsageRemoval("unexpected amount of usage is being removed");
        }

        subscription.usage -= removedUsage;        
        subscriptions[botOwner] = subscription;
    }

    /// returns false if the usage is over capacity or there are no valid keys
    function botOwnerIsOverCapacity(address botOwner) public view returns (bool) {
        Subscription memory subscription = subscriptions[botOwner];

        if (!subscription.plan.getHasValidKey(botOwner)) {
            return true;
        }

        uint256 capacity = capacities[address(subscription.plan)];
        return subscription.usage > capacity;
    }

    /// bot owners enter the contract through this callback
    /// WARNING: this contract needs to be a lock manager for this to work
    function onKeyPurchase(
        uint256 tokenId,
        address from,
        address botOwner,
        address referrer,
        bytes calldata data,
        uint256 minKeyPrice,
        uint256 pricePaid
    ) external {
        address purchasedPlanAddr = msg.sender;
        uint256 initialTokenId = subscriptions[botOwner].tokenId;
        for (uint256 i = 0; i < 2; i++) {
            ILock plan = ILock(plans[i]);
            // save the new plan
            if (address(plan) == purchasedPlanAddr) {
                subscriptions[botOwner].tokenId = tokenId;
                subscriptions[botOwner].plan = plan;
                continue;
            }
            // cancel and refund remaining amount if there are other plans
            if (plan.getHasValidKey(botOwner)) {
                uint256 refundValue = plan.getCancelAndRefundValue(initialTokenId);
                plan.expireAndRefundFor(initialTokenId, refundValue);
            }
        }
    }

    // needed for completing onKeyPurchase hook integration
    function keyPurchasePrice(
        address from,
        address recipient,
        address referrer,
        bytes calldata data
    ) external view returns (uint minKeyPrice) {
        return ILock(msg.sender).keyPrice();
    }
}