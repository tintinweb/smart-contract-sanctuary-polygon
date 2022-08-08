/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;



contract ImbueToken {

    // imbue event detail....    
    struct EventDetail {

        uint _index;
        address _owner; // event's owner
        string _name; // event's name
        uint _start; // when event start...
        uint _duration;
        string _description; // descriptiong about event...
        uint _price; // event's price
        string _thumbnail;
        string _chainId;
        string _streamData;
    }

            // imbue subscriptions detail....    
    struct SubscritptionDetail {
        uint _index;
        address _owner; // subscritpion's owner
        string _name; // subscritpion's name
        string _description; // descriptiong about subscritpion...
        uint _price; // subscritpion's price
    }

    struct subscriptions_creator_map {

        uint _index;
        bool _is_subscription_created;
    }


    mapping(uint => mapping(address => bool)) _subscriber; 
    mapping(uint => SubscritptionDetail) public _subscritptions;
    mapping(address => subscriptions_creator_map) public _subscritption_creator;
       
    mapping(uint => mapping(address => bool)) _purchased_persons; 
    mapping(uint => EventDetail) public _events;
    mapping(string => string) public _thumbnails;
    uint public _event_count = 0;
    uint public _subscritption_count = 0;

    event eventAdded(address who);
    event purchaseDone(bool);

    function addEvent(string memory name, uint datetime,uint duration, string memory description, uint price,string memory streamId,string memory thumbnail,string memory chainId, string memory streamData ) public {
        _events[_event_count] = EventDetail(_event_count, msg.sender, name, datetime,duration, description, price, thumbnail, chainId,streamData);
        _event_count++;
        _thumbnails[streamId] = thumbnail;
        emit eventAdded(msg.sender);
    }

    function getSubscriptions() public view returns (SubscritptionDetail[] memory) {
        
//  SubscritptionDetail[] memory _subscritption_list = new SubscritptionDetail[](_subscritption_cout);

       uint _subscritption_list_count = 0;
       for(uint i = 0; i < _subscritption_count; i++)
            if(_subscritptions[i]._owner != msg.sender)
                    _subscritption_list_count++;
            SubscritptionDetail[] memory _subscritption_list = new SubscritptionDetail[](_subscritption_list_count);
            uint _index = 0;
            for(uint i = 0; i < _subscritption_count; i++){
                
                if( _subscritptions[i]._owner != msg.sender){
                    _subscritption_list[_index] = _subscritptions[i];
                    _index++;
                }
            } 
        return _subscritption_list;
    }

    function getUpcomingEvents(address owner, uint _now) public view returns(EventDetail[] memory){
        uint _upcoming_events_count = 0;
        // this is for purchase case...
        if(owner == address(0)){
            for(uint i = 0; i < _event_count; i++)
                if((_events[i]._start + _events[i]._duration * 60 > _now) && _events[i]._owner != msg.sender)
                    _upcoming_events_count++;
            EventDetail[] memory _upcoming_events = new EventDetail[](_upcoming_events_count);
            uint _index = 0;
            for(uint i = 0; i < _event_count; i++){
                
                if((_events[i]._start + _events[i]._duration * 60 > _now) && _events[i]._owner != msg.sender){
                    _upcoming_events[_index] = _events[i];
                    _index++;
                }
            }
            return _upcoming_events;
        }
        // this is for create event case...
        else{
            for(uint i = 0; i < _event_count; i++)
                if((_events[i]._start + _events[i]._duration * 60 > _now) && _events[i]._owner == owner)
                    _upcoming_events_count++;
            EventDetail[] memory _upcoming_events = new EventDetail[](_upcoming_events_count);
            uint _index = 0;
            for(uint i = 0; i < _event_count; i++){
                
                if((_events[i]._start + _events[i]._duration * 60 > _now) && _events[i]._owner == owner){
                    _upcoming_events[_index] = _events[i];
                    _index++;
                }
            }
            return _upcoming_events;
        }
    }

    function addPerson(uint eventIndex) external payable {
        require(eventIndex < _event_count && eventIndex >= 0,"index error");
        EventDetail storage _event = _events[eventIndex];
        require(msg.value >= _event._price, "error occured!");
        require(msg.sender != _event._owner,"owner can`t purchase");
        require(!_purchased_persons[eventIndex][msg.sender], "you already bought this event...");
        _purchased_persons[eventIndex][msg.sender] = true;
        payable(_event._owner).transfer(msg.value);
        emit purchaseDone(true);
    }

    function isPurchased(uint eventIndex) public view returns(bool){
       address event_owner = _events[eventIndex]._owner;
       bool have_subscription;
        if( _subscritption_creator[event_owner]._is_subscription_created){
           have_subscription = _subscriber[_subscritption_creator[event_owner]._index][msg.sender];
        }

        return _purchased_persons[eventIndex][msg.sender] || have_subscription;
    }

    function addSubscritpion(string memory name, string memory description, uint price  ) public {
        require(!_subscritption_creator[msg.sender]._is_subscription_created,"You can only create subscription plane at once.");
        _subscritptions[_subscritption_count] = SubscritptionDetail(_subscritption_count, msg.sender, name,description, price);
        _subscritption_creator[msg.sender] = subscriptions_creator_map(_subscritption_count,true);
        _subscritption_count++;

    }

    function subscribe(uint subscription_index) external payable {
        require(subscription_index < _subscritption_count && subscription_index >= 0,"index error");
        SubscritptionDetail storage _subscritption = _subscritptions[subscription_index];
        // require(msg.value >= _subscritption._price, "error occured!");
        require(msg.sender != _subscritption._owner,"owner can`t purchase his subscription plan");
        require(!_subscriber[subscription_index][msg.sender], "you already bought this subscription...");
        _subscriber[subscription_index][msg.sender] = true;
        payable(_subscritption._owner).transfer(msg.value);
    }

    function isSubscriptionPurchesed(uint subscription_index) public view returns(bool){
        //require(!_purchased_persons[eventIndex][msg.sender], "error occured!");
        return _subscriber[subscription_index][msg.sender];
    }

    function cancelSubscriptions(uint subscription_index) public  {
        _subscriber[subscription_index][msg.sender] = false;
    }
}