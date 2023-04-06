/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

	function GetContractAddress(string calldata name) external view returns(address);
    function Owner() external view returns(address);
}

interface IOracle{

    function GetMATICPrice() external view returns(uint256);
    function GetMATICDecimals() external view returns(uint8, bool);
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

    uint16 private subscriptionCostPerDay = 3;
    //
    uint32 private subscriptionsToReward = 5;
    //
    uint32 private transactionsPerSeason = 50;
    uint32 private daysPerSeason = 30;
    uint16 private minimumUSDToCount = 50;


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

    function _getMATICPrice() private view returns (uint8, uint256){

        address oracleAddress = pt.GetContractAddress(".Corporation.Oracle");
        IOracle oc = IOracle(oracleAddress);

        (uint8 decimals, bool success) = oc.GetMATICDecimals();

        if(success != true)
            revert("Oracle unreachable");

        uint256 price = oc.GetMATICPrice();

        if(price <= 0)
            revert("Unaccepted Oracle price");

        return(decimals, price);
    }
    //
    function _trueAmount(uint16 _days,uint8 _decimals, uint256 _price) private view returns(uint256){

        uint256 amount = uint256( _days * subscriptionCostPerDay * 10**(_decimals + 18) / (_price * 100));

        return (amount); 
    }

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
    function GetSubscriptionCostPerDay() public view returns(uint16){

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

    function GetMinimumUSDToCount() public view returns(uint16){

        return (minimumUSDToCount);
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
    function Subscribe(uint16 _days, address _referrer) payable public returns(bool){

        if(allowSubscribing != true)
            revert("Subscribing disabled");

        if(msg.value == 0)
            revert("MATIC amount is zero");
        uint32 size;
        address subAddr = msg.sender;

        assembly{size := extcodesize(subAddr)}

        if(size != 0)
            revert("Contracts can not subscribe");

        (uint8 decimals, uint256 price) = _getMATICPrice();
        uint32 usdAmount = uint32(price * 100 * msg.value / (10**(decimals + 18)));

        if(uint32(_days * subscriptionCostPerDay) > usdAmount)
            revert("MATIC amount insufficient");

        Subscriber storage subscriber = subscribers[subAddr];

        uint32 subscribedUntil = subscriber.subscribedUntil;

        if(subscriber.lastTransaction == 0 && subscribedUntil == 0){

            if(subAddr != _referrer && _referrer != address(0)){

                assembly{size := extcodesize(_referrer)}

                if(size != 0)
                    revert("Referrer is contract");

                referrerSubscriptions[_referrer]++;
                subscriber.referredBy = _referrer;
            }

            if(_days < 15)
                revert("First subscription should be at least 15 days");
        }
        
        uint32 tnow = uint32(block.timestamp);

        if(tnow > subscribedUntil){
            
            subscribedUntil = tnow + uint32(_days * 1 days);
            delete subscriber.transactionCount;
        }
        else
            subscribedUntil += uint32(_days * 1 days);

        if(subscribedUntil > uint32(tnow + 120 days))
            revert("Total subscription can not exceed 120 days");

        subscriber.nextSeason = subscribedUntil + uint32(daysPerSeason * 1 days);
        subscriber.subscribedUntil = subscribedUntil;

        uint256 trueAmount = _trueAmount(_days, decimals, price); 
        uint256 subscriberAmount = msg.value - trueAmount;

        if(subscriber.referredBy != address(0)){

            subscriberAmount += trueAmount / 10;
            
            if(referrerSubscriptions[subscriber.referredBy] >= subscriptionsToReward)
                payable(subscriber.referredBy).call{value : ((msg.value - subscriberAmount) / 100)}("");
        }

        if(subscriberAmount > 0)
            payable(subAddr).call{value : (subscriberAmount)}("");

        payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : address(this).balance}("");

        emit Subscribed(subAddr, _days);
        return true;
    }
    //
    function SetSubscriptionCostPerDay(uint16 _usd) public ownerOnly returns(bool){

        if(_usd == 0)
            revert("Zero USD");

        subscriptionCostPerDay = _usd;

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

    function SetDaysPerSeason(uint16 _days) public ownerOnly returns(bool){

        if(_days == 0)
            revert("Zero days");

        daysPerSeason = _days;

        return (true);
    }

    function SetMinimumUSDToCount(uint16 _usd) public ownerOnly returns(bool){

        if(_usd == 0)
            revert("Zero USD");

        minimumUSDToCount = _usd;

        return (true);
    }
    //
    function AllowProcessing(address _subscriber, uint256 _amount) public returns (bool){

        if(pt.GetContractAddress(".Payment.Processor") != msg.sender)
            revert("Processor only");

        Subscriber storage subscriber = subscribers[_subscriber];

        uint32 tnow = uint32(block.timestamp);

        if(tnow <= subscriber.subscribedUntil){

            subscriber.nextSeason = subscriber.subscribedUntil + uint32(daysPerSeason * 1 days);
            subscriber.transactionCount++;
            subscriber.lastTransaction = tnow;

            return(true);
        }
        else if(tnow > subscriber.subscribedUntil){

            if(tnow > subscriber.nextSeason){

                subscriber.nextSeason = tnow + uint32(daysPerSeason * 1 days);
                delete subscriber.transactionCount;
            }

            if(subscriber.transactionCount >= transactionsPerSeason || _amount == 0)
                return(false);

            (uint8 decimals, uint256 price) = _getMATICPrice();
            uint32 usdAmount = uint32(price * 100 * _amount / (10**(decimals + 18)));

            if(usdAmount >= uint32(minimumUSDToCount))
                subscriber.transactionCount++;

            subscriber.lastTransaction = tnow;
            
            return(true);
        }

        return(false);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : msg.value}("");
    }

    fallback() external {}
}