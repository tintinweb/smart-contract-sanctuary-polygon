/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

pragma solidity ^0.8.9;

interface ILock {
    function keyPrice() external view returns (uint);
    function getHasValidKey(address _user) external view returns (bool);
    function isValidKey(uint _tokenId) external view returns (bool);
    function getCancelAndRefundValue(uint _tokenId) external view returns (uint refund);
    function ownerOf(uint _tokenId) external view returns(address);

    function expireAndRefundFor(uint256 _tokenId, uint256 amount) external;
}

error Expired(string reason);
error NotSubscribed(string reason);
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
    modifier onlyBotExecutionPlan() {
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

        if (address(subscription.plan) == address(0x0)) {
            revert NotSubscribed("not subscribed");
        }

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

        if (address(subscription.plan) == address(0x0)) {
            revert NotSubscribed("not subscribed");
        }

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
        (uint256 usage, uint256 capacity) = getUsageAndCapacity(botOwner);
        return usage > capacity;
    }

    /// returns the current capacity of the bot owner
    function getUsageAndCapacity(address botOwner) public view returns (uint256 usage, uint256 capacity) {
        Subscription memory subscription = subscriptions[botOwner];

        if (address(subscription.plan) == address(0x0)) {
            return (subscription.usage, 0);
        }

        if (!subscription.plan.getHasValidKey(botOwner)) {
            return (subscription.usage, 0);
        }

        uint256 capacity = capacities[address(subscription.plan)];
        return (subscription.usage, capacity);
    }

    /// bot owners enter the contract through this callback
    /// WARNING: this contract needs to be set as lock manager for this to work
    function onKeyPurchase(
        uint256 tokenId,
        address from,
        address botOwner,
        address referrer,
        bytes calldata data,
        uint256 minKeyPrice,
        uint256 pricePaid
    ) external onlyBotExecutionPlan {
        address newPlanAddr = msg.sender;
        uint256 prevTokenId = subscriptions[botOwner].tokenId;

        subscriptions[botOwner].tokenId = tokenId;
        subscriptions[botOwner].plan = ILock(newPlanAddr);

        refundFromOtherPlans(botOwner, newPlanAddr, prevTokenId);
    }

    function refundFromOtherPlans(address botOwner, address newPlanAddr, uint256 prevTokenId) internal {
        for (uint256 i = 0; i < 2; i++) {
            ILock plan = ILock(plans[i]);
            if (address(plan) == newPlanAddr) {
                continue;
            }
            // cancel and refund remaining amount if there are subscriptions in this plan
            if (plan.getHasValidKey(botOwner)) {
                uint256 refundValue = plan.getCancelAndRefundValue(prevTokenId);
                plan.expireAndRefundFor(prevTokenId, refundValue);
                return; // exclusively one plan at a time
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

    /// switching between the plans require extending previously expired keys - this helps there
    /// WARNING: this contract needs to be set as lock manager for this to work
    function onKeyExtend(
        uint tokenId,
        address from,
        uint newTimestamp,
        uint prevTimestamp
    ) external onlyBotExecutionPlan {
        address newPlanAddr = msg.sender;
        address botOwner = ILock(newPlanAddr).ownerOf(tokenId);
        uint256 prevTokenId = tokenId;

        subscriptions[botOwner].tokenId = tokenId;
        subscriptions[botOwner].plan = ILock(newPlanAddr);

        refundFromOtherPlans(botOwner, newPlanAddr, prevTokenId);
    }
}