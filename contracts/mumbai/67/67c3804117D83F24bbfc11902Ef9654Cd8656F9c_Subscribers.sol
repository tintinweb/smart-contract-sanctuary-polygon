/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

	function GetContractAddress(string calldata name) external view returns(address);
    function Owner() external view returns(address);
}

contract Subscribers{

//-----------------------------------------------------------------------// v EVENTS

    event Subscribed(address subscriber, uint32 dayNumber);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool allowSubscribing = true;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x70C01604d020dBE3ec7aA77BAc1f2c8A8386598D;

//-----------------------------------------------------------------------// v NUMBERS

    uint256 private subscriptionCostPerDay = 2 * (10**17);
    //
    uint32 private subscriptionsToReward = 5;
    //
    uint32 private transactionsPerSeason = 50;
    uint32 private daysPerSeason = 30;
    uint256 private minimumToCount = 5 * (10**17);


//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Subscribers";

//-----------------------------------------------------------------------// v STRUCTS

    struct Subscriber{

        address referredBy;
        uint32 transactionCount;
        uint32 nextSeason;
        uint32 subscribedUntil;
        uint32 lastTransaction;  
    }

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(address => Subscriber) private subscribers;
    mapping(address => uint32) private referrerSubscriptions;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v INTERNAL FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetReferrerSubscriptions(address _referrer) public view returns(uint32){

        return (referrerSubscriptions[_referrer]);
    }
    //
    function GetAllowSubscribing() public view returns(bool){

        return (allowSubscribing);
    }
    //
    function SubscriberProfile(address _subscriber) public view returns (address referredBy, uint32 transactionCount, uint32 nextSeason, uint32 subscribedUntil, uint32 subscribtionDaysLeft, bool isSubscriber, uint32 lastTransaction){
    
        Subscriber memory subscriber = subscribers[_subscriber];

        referredBy = subscriber.referredBy;
        transactionCount = subscriber.transactionCount;
        nextSeason = subscriber.nextSeason;
        subscribedUntil = subscriber.subscribedUntil;
        lastTransaction = subscriber.lastTransaction;

        uint32 tnow = uint32(block.timestamp);

        subscribtionDaysLeft = (subscribedUntil >= tnow) ? ((subscribedUntil - tnow) / 1 days) : 0;
        isSubscriber =  (subscribedUntil >= tnow) ? true : false;
    }
    //
    function GetSubscriptionCostPerDay() public view returns(uint256){

        return (subscriptionCostPerDay);
    }
    //
    function GetSubscriptionsToReward() public view returns(uint32){

        return (subscriptionsToReward);
    }
   //
    function GetTransactionsPerSeason() public view returns(uint32){

        return (transactionsPerSeason);
    }

    function GetDaysPerSeason() public view returns(uint32){

        return (daysPerSeason);
    }

    function GetMinimumToCount() public view returns(uint256){

        return (minimumToCount);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function SetAllowSubscribing(bool _allow) public ownerOnly returns(bool){

        if(allowSubscribing == _allow)
            if(_allow == true)
                revert("Already allowed");
            else
                revert("Already disallowed");

        allowSubscribing = _allow;

        return (true);
    }
    //
    function Subscribe(uint32 _days, address _referrer) payable public returns(bool){

        if(allowSubscribing != true)
            revert("Subscribing disabled");

        uint32 size;
        address subAddr = msg.sender;

        assembly{size := extcodesize(subAddr)}

        if(size != 0)
            revert("Contracts can not subscribe");

        if(_days * subscriptionCostPerDay != msg.value)
            revert("Wrong MATIC amount");

        Subscriber storage subscriber = subscribers[subAddr];

        uint32 subscribedUntil = subscriber.subscribedUntil;

        if(subAddr != _referrer && _referrer != address(0) && subscriber.lastTransaction == 0 && subscribedUntil == 0){

           assembly{size := extcodesize(_referrer)}

            if(size != 0)
                revert("Referrer is contract");

            if(_days < 15)
                revert("First subscription should be at least 15 days");

            referrerSubscriptions[_referrer]++;
            subscriber.referredBy = _referrer;
        }

        uint32 tnow = uint32(block.timestamp);

        if(tnow > subscribedUntil){
            
            subscribedUntil = tnow + uint32(_days * 1 days);
            subscriber.transactionCount = 0;
        }
        else
            subscribedUntil += uint32(_days * 1 days);

        if(subscribedUntil > uint32(tnow + 120 days))
            revert("Total subscription can not exceed 120 days");

        subscriber.nextSeason = subscribedUntil + uint32(daysPerSeason * 1 days);
        subscriber.subscribedUntil = subscribedUntil;

        if(subscriber.referredBy != address(0)){

            uint256 subscriberReward = msg.value * 10 / 100;
            uint256 referrerReward = (msg.value - subscriberReward) / 100;

            payable(subAddr).call{value : subscriberReward}("");
            
            if(referrerSubscriptions[subscriber.referredBy] >= subscriptionsToReward)
                payable(subscriber.referredBy).call{value : referrerReward}("");
        }

        payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : address(this).balance}("");

        emit Subscribed(subAddr, _days);
        return true;
    }
    //
    function SetSubscriptionCostPerDay(uint256 _amount) public ownerOnly returns(bool){

        if(_amount == 0)
            revert("Zero amount");

        subscriptionCostPerDay = _amount;

        return (true);
    }
    //
    function SetSubscriptionsToReward(uint32 _subscriptions) public ownerOnly returns(bool){

        if(_subscriptions == 0)
            revert("Zero subscriptions");

        subscriptionsToReward = _subscriptions;

        return (true);
    }
    //
    function SetTransactionsPerSeason(uint32 _transactions) public ownerOnly returns(bool){

        if(_transactions == 0)
            revert("Zero transactions");

        transactionsPerSeason = _transactions;

        return (true);
    }

    function SetDaysPerSeason(uint32 _days) public ownerOnly returns(bool){

        if(_days == 0)
            revert("Zero days");

        daysPerSeason = _days;

        return (true);
    }

    function SetMinimumToCount(uint256 _amount) public ownerOnly returns(bool){

        if(_amount == 0)
            revert("Zero amount");

        minimumToCount = _amount;

        return (true);
    }
    //
    function AllowProcessing(address _subscriber, uint256 _amount) public returns (bool){

        if(pt.GetContractAddress(".Payment.Processor") != msg.sender)
            revert("Processor only");

        Subscriber storage subscriber = subscribers[_subscriber];

        uint32 tnow = uint32(block.timestamp);

        if(tnow <= subscriber.subscribedUntil)
            subscriber.nextSeason = subscriber.subscribedUntil + uint32(daysPerSeason * 1 days);
        else if(tnow > subscriber.subscribedUntil){

            if(tnow > subscriber.nextSeason){

                subscriber.nextSeason = tnow + uint32(daysPerSeason * 1 days);
                subscriber.transactionCount = 0;
            }

            if(subscriber.transactionCount >= transactionsPerSeason || _amount == 0)
                return(false);
        }

        if(_amount >= minimumToCount)
            subscriber.transactionCount++;

        subscriber.lastTransaction = tnow;

        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : msg.value}("");
        
    }

    fallback() external {}
}