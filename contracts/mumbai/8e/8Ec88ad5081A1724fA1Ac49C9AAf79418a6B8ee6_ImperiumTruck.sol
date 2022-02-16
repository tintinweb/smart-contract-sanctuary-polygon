// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenIGC.sol";

contract ImperiumTruck is Token {

    event NewTruck(string message);

    uint public gamePool;
    uint public deadCoin;
    uint public miningCoin;
    uint public valueLocked;

    uint uniqueIdDigits = 12;
    uint uniqueIdModulus = 10 ** uniqueIdDigits;

    constructor() {
        gamePool = 200000 * 10 ** 8;
    }

    struct Truck {
        string name;
        uint uniqueId;
        uint value;
        uint32 level;
        uint32 fuelTime;
        uint32 repairTime;
        uint32 harvestTime;
        uint32 purchaseDate;
        address upline;
    }

    Truck[] public trucks;

    struct Staking {
        uint valueLocked;
        uint32 timeLocked;
        uint32 apy;
        uint estimatedReturn;
        bool rescue;
    }

    Staking[] public staking;

    mapping (uint => address) public truckToOwner;
    mapping (address => uint) public ownerTruckCount;
    mapping (uint => address) public codeRelationship;
    mapping (address => uint) public maximumRelationshipBonus;

    mapping (uint => address) public stakingToOwner;
    mapping (address => uint) public ownerStakingCount;

    function _createNewTruck(string memory _name, uint _uniqueId, uint _value, uint32 _cooldownTime_ToFuel, uint32 _cooldownTime_Repair, uint _codeUpline) private {
        require(balanceOf(msg.sender) >= (_value  * 10 ** 8), "Insufficient funds");
        gamePool += (_value * 10 ** 8);
        balances[msg.sender] -= (_value * 10 ** 8);
        address myUpline;
        if(codeRelationship[_codeUpline] == address(0)){
            myUpline = contractOwner;
        } else {
            myUpline = codeRelationship[_codeUpline];
        }
        trucks.push(Truck(_name, _uniqueId, _value, 1, uint32(block.timestamp + _cooldownTime_ToFuel), uint32(block.timestamp + _cooldownTime_Repair), uint32(block.timestamp + _cooldownTime_ToFuel + 1 minutes), uint32(block.timestamp), myUpline));
        uint id = trucks.length - 1;
        truckToOwner[id] = msg.sender;
        codeRelationship[_uniqueId] = msg.sender;
        maximumRelationshipBonus[msg.sender] += ((_value * 2) * 10 ** 8);
        ownerTruckCount[msg.sender]++;
        emit NewTruck("New truck successfully purchased");
    } 

    function _generateUniqueId(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str, block.difficulty, block.timestamp, msg.sender)));
        return rand % uniqueIdModulus;
    }

    function buyTruck(uint _value, uint _codeUpline) public {
        string memory truckName;
        uint32 cooldownTime_ToFuel;
        uint32 cooldownTime_Repair;
        bool validValue = false;
        if(_value == 100) {
            truckName = 'Silver';
            cooldownTime_ToFuel = 9 minutes;
            cooldownTime_Repair = 150 minutes;
            validValue = true;
        } else
        if(_value == 250) {
            truckName = 'Gold';
            cooldownTime_ToFuel = 7 minutes;
            cooldownTime_Repair = 144 minutes;
            validValue = true;
        } else
        if(_value == 600) {
            truckName = 'Ruby';
            cooldownTime_ToFuel = 5 minutes;
            cooldownTime_Repair = 114 minutes;
            validValue = true;
        }
        require(validValue == true, "Value not valid!");
        uint randId = _generateUniqueId(truckName);
        _createNewTruck(truckName, randId, _value, cooldownTime_ToFuel, cooldownTime_Repair, _codeUpline);
    }

    //IMPERIUM TRUCK ACTIONS
    event ReFuelEvent(string message);
    event RepairEvent(string message);
    event HavestEvent(string message);    

    function reFuel(uint _idTruck) public {   

        require(msg.sender == truckToOwner[_idTruck], "This truck doesn't belong to you");    
        require(trucks[_idTruck].repairTime >= block.timestamp, "Your truck needs repair"); 
        require(trucks[_idTruck].fuelTime < block.timestamp, "The fuel hasn't run out yet");

        uint valueFuel = (50 * 10 ** 8)  * trucks[_idTruck].level;

        require(balanceOf(msg.sender) >= valueFuel, "Insufficient funds");
        
        balances[msg.sender] -= valueFuel;

        balances[contractOwner] += ((valueFuel / 100) * 5);

        deadCoin += ((valueFuel / 100) * 5);
        totalSupply -= ((valueFuel / 100) * 5);

        if(maximumRelationshipBonus[trucks[_idTruck].upline] >= ((valueFuel / 100) * 5) ){
            balances[trucks[_idTruck].upline] += ((valueFuel / 100) * 5);
            maximumRelationshipBonus[trucks[_idTruck].upline] -= ((valueFuel / 100) * 5);
        } else {
            gamePool += ((valueFuel / 100) * 5);
        }

        gamePool += ((valueFuel / 100) * 85);

        uint32 cooldownTime_ToFuel;
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Silver"))))){
            cooldownTime_ToFuel = 9 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Gold"))))){
            cooldownTime_ToFuel = 7 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Ruby"))))){
            cooldownTime_ToFuel = 5 minutes;
        }

        trucks[_idTruck].fuelTime = uint32(block.timestamp + cooldownTime_ToFuel);

        emit ReFuelEvent("Your truck has been fueled");
    }

    function repair(uint _idTruck) public {

        require(msg.sender == truckToOwner[_idTruck], "This truck doesn't belong to you");  
        require(trucks[_idTruck].repairTime < block.timestamp, "Your truck still doesn't need repair");        
        require(balanceOf(msg.sender) >= (((trucks[_idTruck].value / 100) * 75) * 10 ** 8), "Insufficient funds");

        balances[msg.sender] -= (((trucks[_idTruck].value / 100) * 75) * 10 ** 8);

        gamePool += (((trucks[_idTruck].value / 100) * 75) * 10 ** 8);

        uint32 cooldownTime_Repair;
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Silver"))))){
            cooldownTime_Repair = 150 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Gold"))))){
            cooldownTime_Repair = 144 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Ruby"))))){
            cooldownTime_Repair = 114 minutes;
        }

        trucks[_idTruck].repairTime = uint32(block.timestamp + cooldownTime_Repair);

        emit RepairEvent("Your truck has been fixed");
    }

    function harvest(uint _idTruck) public {

        require(msg.sender == truckToOwner[_idTruck], "This truck doesn't belong to you");  
        require(trucks[_idTruck].fuelTime >= block.timestamp, "Your truck is out of fuel");
        require(trucks[_idTruck].repairTime >= block.timestamp, "Your truck needs repair");
        require(trucks[_idTruck].harvestTime < block.timestamp, "It's not yet time to reap your profits");   
         
        uint harvestValue;    
        uint32 cooldownTime_Harvest;
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Silver"))))){
            harvestValue = (75 * 10 ** 8) * trucks[_idTruck].level;
            cooldownTime_Harvest = 10 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Gold"))))){
            harvestValue = (105 * 10 ** 8) * trucks[_idTruck].level;
            cooldownTime_Harvest = 8 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Ruby"))))){
            harvestValue = (155 * 10 ** 8) * trucks[_idTruck].level;
            cooldownTime_Harvest = 6 minutes;
        }

        trucks[_idTruck].harvestTime = uint32(block.timestamp + cooldownTime_Harvest);

        if(gamePool >= harvestValue) {
            gamePool -= harvestValue;
            balances[msg.sender] += harvestValue;
        } else {
            totalSupply += harvestValue;
            miningCoin += harvestValue;
            balances[msg.sender] += harvestValue;
        }

        emit HavestEvent("Your bounty has been collected");
    }

    function getTrucksByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerTruckCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < trucks.length; i++) {
            if (truckToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    //IMPERIUM TRUCK UPGRADE
    event TruckUpgradeEvent(string message);

    function truckUpgrade(uint _idTruck) public {

        require(msg.sender == truckToOwner[_idTruck], "This truck doesn't belong to you");
        require(trucks[_idTruck].level < 10, "Maximum level reached");
        require(trucks[_idTruck].repairTime >= block.timestamp, "Your truck needs repair");

        uint truckValue;
        uint32 cooldownTime_ToFuel;
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Silver"))))){
            truckValue = 100;
            cooldownTime_ToFuel = 9 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Gold"))))){
            truckValue = 250;
            cooldownTime_ToFuel = 7 minutes;
        } else
        if((keccak256(abi.encodePacked((trucks[_idTruck].name))) == keccak256(abi.encodePacked(("Ruby"))))){
            truckValue = 600;
            cooldownTime_ToFuel = 5 minutes;
        }

        require(balanceOf(msg.sender) >= ((truckValue) * 10 ** 8), "Insufficient funds");

        balances[msg.sender] -= ((((truckValue) * 10 ** 8) / 100) * 95);

        gamePool += ((((truckValue) * 10 ** 8) / 100) * 95);

        trucks[_idTruck].level++;
        trucks[_idTruck].value += truckValue;
        trucks[_idTruck].fuelTime = uint32(block.timestamp + cooldownTime_ToFuel);
        trucks[_idTruck].harvestTime = uint32(block.timestamp + cooldownTime_ToFuel + 1 minutes);
        
        emit TruckUpgradeEvent("Your truck has been updated successfully");
    }

    //IMPERIUM TRUCK STAKING
    event NewValueLocked(string message);
    event StakingRescueEvent(string message);

    function stakingLocked(uint _value, uint _time) public {
        require(_value >= 250, "Minimum amount to locked is 250");
        require(balanceOf(msg.sender) >= ((_value) * 10 ** 8), "Insufficient funds");
        bool validTime = false;
        uint32 timeLocked;
        uint32 apy;
        uint32 divider = 100;
        uint32 dividerYear = 365;
        uint estimatedReturn;
        if(_time == 15){
            validTime = true;
            timeLocked = 15 minutes;
            apy = 10;            
            estimatedReturn = (((((_value * apy) * _time) / divider) / dividerYear) + _value);
        } else
        if(_time == 30){
            validTime = true;
            timeLocked = 30 minutes;
            apy = 20;
            estimatedReturn = (((((_value * apy) * _time) / divider) / dividerYear) + _value);
        } else
        if(_time == 90){
            validTime = true;
            timeLocked = 90 minutes;
            apy = 30;
            estimatedReturn = (((((_value * apy) * _time) / divider) / dividerYear) + _value);  
        } else
        if(_time == 180){
            validTime = true;
            timeLocked = 180 minutes;
            apy = 40;
            estimatedReturn = (((((_value * apy) * _time) / divider) / dividerYear) + _value);  
        } else
        if(_time == 360){
            validTime = true;
            timeLocked = 360 minutes;
            apy = 50;
            estimatedReturn = (((((_value * apy) * _time) / divider) / dividerYear) + _value);  
        }
        require(validTime == true, "Time not valid!");
        balances[msg.sender] -= ((_value) * 10 ** 8);
        gamePool += ((_value) * 10 ** 8);
        valueLocked += ((_value) * 10 ** 8);
        staking.push(Staking(((_value) * 10 ** 8), uint32(block.timestamp + timeLocked), apy, ((estimatedReturn) * 10 ** 8), false));
        uint id = staking.length - 1;
        stakingToOwner[id] = msg.sender;
        ownerStakingCount[msg.sender]++;
        emit NewValueLocked("You have successfully locked your tokens");
    }

    function stakingRescue(uint _idStaking) public {
        require(msg.sender == stakingToOwner[_idStaking], "This locked quota does not belong to you"); 
        require(staking[_idStaking].timeLocked < block.timestamp, "It's not yet time to reap your profits");
        require(staking[_idStaking].rescue == false, "You have already collected this reward");
        staking[_idStaking].rescue = true;
        valueLocked -= staking[_idStaking].valueLocked;
        if(gamePool >= staking[_idStaking].estimatedReturn) {
            gamePool -= staking[_idStaking].estimatedReturn;
            balances[msg.sender] += staking[_idStaking].estimatedReturn;
        } else {
            totalSupply += staking[_idStaking].estimatedReturn;
            miningCoin += staking[_idStaking].estimatedReturn;
            balances[msg.sender] += staking[_idStaking].estimatedReturn;
        }        
        emit StakingRescueEvent("Your bounty has been collected");
    }

    function getStakingByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerStakingCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < staking.length; i++) {
            if (stakingToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

}