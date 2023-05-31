/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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

    event Subscribed(address subscriber, uint32 daysNumber);
    event SubscriptionIncreased(address subscriber, uint32 daysNumber);
    event SubscriptionDecreased(address subscriber, uint32 daysNumber);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private allowSubscribing = true;
    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0xfc82AD7B08bC6AF0b0046ee8aE6b12df3457DE23;

//-----------------------------------------------------------------------// v NUMBERS

    uint16 private subscriptionCostPerDay = 33;
    //
    uint32 private subscriptionsToReward = 5;
    //
    uint32 private transactionsPerSeason = 50;
    uint32 private daysPerSeason = 30;
    uint16 private minimumUSDToCount = 50;
    //
    uint256 private maticPrice = 0;
    uint8 private maticDecimals = 0;


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

    struct Referrer{

        uint32 referralCount;
        uint256 earnings;
    }

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(address => Subscriber) private subscribers;
    mapping(address => Referrer) private referrers;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v INTERNAL FUNCTIONS

    function _renewMATICPrice() private returns (bool){

        IOracle oc = IOracle(pt.GetContractAddress(".Corporation.Oracle"));

        (uint8 decimals, bool success) = oc.GetMATICDecimals();
        uint256 price = oc.GetMATICPrice();

        if(success == true && price > 0){

            maticPrice = price;
            maticDecimals = decimals;

            return(true);
        }

        return(false);
    }
    //
    function _trueAmount(uint32 _days) private view returns(uint256){

        uint256 trueAmount = uint256( _days * subscriptionCostPerDay * 10**(maticDecimals + 18) / (maticPrice * 100));

        return (trueAmount); 
    }

    function _usdAmount(uint256 _amount) private view returns(uint32){

        uint32 usdAmount = uint32(maticPrice * 100 * _amount / (10**(maticDecimals + 18)));

        return (usdAmount); 
    }

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetAllowSubscribing() public view returns(bool){

        return (allowSubscribing);
    }
    //
    function Profile(address _client) public view returns (address referredBy, uint32 referralCount, uint256 referralEarnings, uint32 transactionCount, uint32 lastTransaction, bool isSubscriber, uint32 subscribedUntil, uint32 subscribtionDaysLeft, uint32 nextSeason, uint32 seasonDaysLeft){
    
        Subscriber memory subscriber = subscribers[_client];
        Referrer memory referrer = referrers[_client];

        referredBy = subscriber.referredBy;
        referralCount = referrer.referralCount;
        referralEarnings = referrer.earnings;

        transactionCount = subscriber.transactionCount;
        lastTransaction = subscriber.lastTransaction;

        uint32 tnow = uint32(block.timestamp);

        isSubscriber =  (subscriber.subscribedUntil >= tnow) ? true : false;
        subscribedUntil = subscriber.subscribedUntil;
        subscribtionDaysLeft = (subscribedUntil >= tnow) ? ((subscribedUntil - tnow) / 1 days) : 0;

        nextSeason = subscriber.nextSeason;
        seasonDaysLeft = isSubscriber ? daysPerSeason : ((nextSeason >= tnow) ? ((nextSeason - tnow) / 1 days) : 0);
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

        if(allowSubscribing == _allow){

            if(_allow == true)
                revert("Already allowed");
            else
                revert("Already disallowed");
        }

        allowSubscribing = _allow;

        return (true);
    }

    function AddToSubscription(address _subscriber, uint32 _days) public ownerOnly returns(bool){

        uint32 size;
        assembly{size := extcodesize(_subscriber)}

        if(size != 0)
            revert("Contracts can not be subscribed");

        Subscriber storage subscriber = subscribers[_subscriber];
      
        uint32 tnow = uint32(block.timestamp);

        if(tnow > subscriber.subscribedUntil)
            subscriber.subscribedUntil = tnow + uint32(_days * 1 days);
        else
            subscriber.subscribedUntil += uint32(_days * 1 days);

        if(subscriber.subscribedUntil > uint32(tnow + 365 days))
            revert("Total subscription can not exceed 365 days");

        subscriber.nextSeason = subscriber.subscribedUntil + uint32(daysPerSeason * 1 days);
        delete subscriber.transactionCount;

        emit SubscriptionIncreased(_subscriber, _days);
        return(true);
    }

    function RemoveFromSubscription(address _subscriber, uint32 _days) public ownerOnly returns(bool){

        if(_days > 365)
            revert("Too many days");

        Subscriber storage subscriber = subscribers[_subscriber];
      
        uint32 tnow = uint32(block.timestamp);

        if(tnow > subscriber.subscribedUntil)
            revert("Not a subscriber");
        else{

            subscriber.subscribedUntil -= uint32(_days * 1 days);

            if(tnow > subscriber.subscribedUntil)
                subscriber.subscribedUntil = tnow;
            
            subscriber.nextSeason = subscriber.subscribedUntil + uint32(daysPerSeason * 1 days);
        }

        emit SubscriptionDecreased(_subscriber, _days);
        return(true);
    }
    //
    function Subscribe(uint32 _days, address _referrer) payable public returns(bool){

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;

        if(allowSubscribing != true)
            revert("Subscribing disabled");

        if(msg.value == 0)
            revert("MATIC amount is zero");
            
        uint32 size;
        address subscriberAddress = msg.sender;

        assembly{size := extcodesize(subscriberAddress)}

        if(size != 0)
            revert("Contracts can not subscribe");

        if(_renewMATICPrice() != true)
            revert("MATIC to USD Oracle unavailable");

        if(uint32(_days * subscriptionCostPerDay) > _usdAmount(msg.value))
            revert("MATIC amount insufficient");

        Subscriber storage subscriber = subscribers[subscriberAddress];

        if(subscriber.lastTransaction == 0 && subscriber.subscribedUntil == 0){

            if(subscriberAddress != _referrer && _referrer != address(0)){

                assembly{size := extcodesize(_referrer)}

                if(size == 0){

                    subscriber.referredBy = _referrer;
                    referrers[subscriber.referredBy].referralCount++;
                }
            }
        }
        
        uint32 tnow = uint32(block.timestamp);

        if(tnow > subscriber.subscribedUntil)
            subscriber.subscribedUntil = tnow + uint32(_days * 1 days);
        else
            subscriber.subscribedUntil += uint32(_days * 1 days);

        if(subscriber.subscribedUntil > uint32(tnow + 365 days))
            revert("Total subscription can not exceed 365 days");

        subscriber.nextSeason = subscriber.subscribedUntil + uint32(daysPerSeason * 1 days);
        delete subscriber.transactionCount;

        uint256 trueAmount = _trueAmount(_days); 
        uint256 subscriberAmount = msg.value - trueAmount;

        if(subscriber.referredBy != address(0)){

            subscriberAmount += (trueAmount / 20);
            
            if(referrers[subscriber.referredBy].referralCount >= subscriptionsToReward){

                uint256 referrerAmount = ((msg.value - subscriberAmount) / 100);

                payable(address(subscriber.referredBy)).call{value : referrerAmount}("");
                referrers[subscriber.referredBy].earnings += referrerAmount;
            }
        }

        if(subscriberAmount > 0)
            payable(address(subscriberAddress)).call{value : (subscriberAmount)}("");

        payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : (address(this).balance)}("");

        reentrantLocked = false;

        emit Subscribed(subscriberAddress, _days);
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

    function SetDaysPerSeason(uint32 _days) public ownerOnly returns(bool){

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

        if(tnow > subscriber.subscribedUntil){

            if(tnow > subscriber.nextSeason){

                subscriber.nextSeason = tnow + uint32(daysPerSeason * 1 days);
                delete subscriber.transactionCount;
            }

            if(subscriber.transactionCount >= transactionsPerSeason || _amount == 0)
                return(false);

            _renewMATICPrice();

            if(_usdAmount(_amount) >= uint32(minimumUSDToCount))
                subscriber.transactionCount++;
        }

        subscriber.lastTransaction = tnow;
        
        return(true);    
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : msg.value}("");
    }

    fallback() external{
        
        revert("Subscribers fallback reverted");
    }
}