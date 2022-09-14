/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Subscription {

    address public _owner;
    uint8 _referrerCommision;

    struct plan {
        string planDescription;
        uint256 cost;
        uint256 duration;
        bool firstTimeOnly;
    }

    plan[] public _currentPlans;
    mapping(address => uint256) private _endTimes;
    mapping(address => uint256) private _availableIncome;
    mapping(address => bool) private _referrerActive;

    constructor(uint8 referrerCommision) {
        _owner = msg.sender;
        require(referrerCommision<100,"commision needs to be less than 100%");
        _referrerCommision=referrerCommision;
    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner() {
        require(owner()==msg.sender, "You are not the owner");
        _;
    }

    function addPlan(string memory aPlanDescription, uint256 aCost, uint256 aDuration, bool aFirstTimeOnly)public onlyOwner{
        _currentPlans.push(plan({
            planDescription:aPlanDescription,
            cost:aCost,
            duration:aDuration,
            firstTimeOnly:aFirstTimeOnly
        }));
    }

    function modifyPlan(uint256 index,string memory aPlanDescription, uint256 aCost, uint256 aDuration, bool aFirstTimeOnly)public onlyOwner{
        _currentPlans[index].planDescription=aPlanDescription;
        _currentPlans[index].cost=aCost;
        _currentPlans[index].duration=aDuration;
        _currentPlans[index].firstTimeOnly=aFirstTimeOnly;
    }
    
    function modifyPlanCost(uint256 index, uint256 aCost)public onlyOwner{
        _currentPlans[index].cost=aCost;
    }

    function setReferrerCommision(uint8 newCommision)public onlyOwner{
        require(newCommision<100,"needs to be less than 100%");
        _referrerCommision=newCommision;
    }

    function totalPlans() public view returns(uint256){
        return _currentPlans.length;
    }

    function isReferrerActive(address aAddress) public view returns(bool){
        return _referrerActive[aAddress];
    }

    function activateReferrer(address aAddress) public onlyOwner{
        _referrerActive[aAddress]=true;
    }

    function deActivateReferrer(address aAddress) public onlyOwner{
        _referrerActive[aAddress]=false;
    }

    function buyPlan(uint256 index, address referrer)public payable{
        require(index<totalPlans(),"Invalid Plan");
        require(msg.value>=_currentPlans[index].cost,"Please pay the full cost");

        if(_currentPlans[index].firstTimeOnly){
            require(_endTimes[msg.sender]==0,"not a new user");
        }
        _addTime(index,msg.sender);
        if(isReferrerActive(referrer)){
            uint256 referrerIncome=_currentPlans[index].cost*_referrerCommision/100;
            _availableIncome[owner()]+=msg.value-referrerIncome;
            _availableIncome[referrer]+=referrerIncome;
        }else{
            _availableIncome[owner()]+=msg.value;
        }
    }

    function _addTime(uint256 planIndex,address aAddress) private {
        uint256 currentEndTime = block.timestamp > _endTimes[aAddress]
                ? block.timestamp
                : _endTimes[msg.sender];
        _endTimes[aAddress]=currentEndTime+=_currentPlans[planIndex].duration;
    }

    function addTimeAdmin(uint256 planIndex,address aAddress) public onlyOwner{
        require(planIndex<totalPlans(),"Invalid Plan");
        _addTime(planIndex,aAddress);
    }

    function isMembershipActive(address aAddress) public view returns(bool){
        return block.timestamp < _endTimes[aAddress];
    }

    function membershipEndTime(address aAddress) public view returns(uint256){
        return _endTimes[aAddress];
    }

    function collectIncome() public{
        uint256 myIncome=_availableIncome[msg.sender];
        require(myIncome>0,"No income to collect");
        _availableIncome[msg.sender]=0;
        payable(msg.sender).transfer(myIncome);
    }

    function _rescueIncome(address aAddress) public onlyOwner{
        uint256 myIncome=_availableIncome[aAddress];
        require(myIncome>0,"No income to rescue");
        _availableIncome[aAddress]=0;
        payable(owner()).transfer(myIncome);
    }

    function currentIncome(address aAddress) public view returns(uint256){
        return _availableIncome[aAddress];
    }

    function getPlanDescription(uint256 planIndex) public view returns(string memory){
        require(planIndex<totalPlans(),"Invalid Plan");
        return _currentPlans[planIndex].planDescription;
    }
    function getPlanCost(uint256 planIndex) public view returns(uint256){
        require(planIndex<totalPlans(),"Invalid Plan");
        return _currentPlans[planIndex].cost;
    }
    
    function getPlanDuration(uint256 planIndex) public view returns(uint256){
        require(planIndex<totalPlans(),"Invalid Plan");
        return _currentPlans[planIndex].duration;
    }    

    function isPlanForFirstTimeUsers(uint256 planIndex) public view returns(bool){
        require(planIndex<totalPlans(),"Invalid Plan");
        return _currentPlans[planIndex].firstTimeOnly;
    }        
}