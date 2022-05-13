// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IRobinHood.sol";
import "./interfaces/IWheat.sol";
import "./interfaces/IShillings.sol";
import "./interfaces/IRevolution.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev users stake their NFTs here
 */

struct UserInfo{
    uint farmShare;//current farm Share
    uint workShare;//current work Share
    uint trainShare;
    uint lastEpochUpdated;//stores the last epoch we paid out rewards
    EnumerableSet.UintSet farming;
    EnumerableSet.UintSet working;
    EnumerableSet.UintSet training;
    EnumerableSet.UintSet resting;
    uint withdrawalEpoch;
    uint wheat;
    uint shillings;
    uint experiencePoints;
}

struct EpochInfo{
    uint begin;//timestamp for when the epoch begins
    bool revolution;//true, revolution, false, nothing
    uint accWheatPerShare;//aacumulated wheat reward per share
    uint accShillingsPerShare;//amount of shillings reward for this allocation
    uint accExperiencePerShare;//amount of experience reward for this allocation
    uint totalWheatAllocation;//just used to make it easier for users to see
    uint totalShillingsAllocation;//50% auto added to revolution pot
    uint totalExperienceAllocation;
    uint epochAccWorkers;//epoch weighted average amount of characters working
    uint epochAccTrainers;//epoch weighted average amount of characters training
}

struct RevolutionInfo{
    uint lastEpoch;
    uint revolutionPrize;//$SHILLINGS accumulate in here
    uint scale;//0 -> 10k used to keep track of who is winning starts out at 5k initial attacks have higher chance of capture/kill
}
/**
 * could add in dynamic resource requirements to make it more expensive or cheaper to do stuff 
 resourceRequirements[0] * (current - lastEpoch)
 would change to
 current req - req last update
 then multiply by number of homies working
 */

contract Nottingham is KeeperCompatibleInterface, VRFConsumerBaseV2, ERC721Holder, Ownable{
    using EnumerableSet for EnumerableSet.UintSet;

    //VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 1000000;
    uint32 numWords =  4;
    uint16 requestConfirmations = 3;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    mapping(address => UserInfo) userInfo;
    uint public currentEpoch;
    uint public epochLength; //used to determine when keepers calls function to advance epoch
    mapping(uint => EpochInfo) public epochInfo;
    uint public totalFarmingShares;//all users farming Shares summed together
    uint public totalWorkingShares;//all users working Shares summed together
    uint public totalTrainingShares;//all users working Shares summed together
    uint public totalWorkers;
    uint public totalTrainers;
    uint public lastRevolutionEpoch;// starts out at a 5% chance, then every epoch, the chance increases 5%
    uint public maxEpochsWithoutRevolution = 20;
    uint public revolutionTax = 4000; //between 1 -> 10k

    uint public resourceRequirement = 100 * 10**18;//how much Wheat and Shillings characters need to do actions
    uint public epochsToAverage = 5;

    uint[] public baseWeights = [10000, 80000, 80000];
    uint public baseWheatAllocation = 10000 * 10**18;
    uint public baseShillingsAllocation = 10000 * 10**18;
    uint public baseExperienceAllocation = 1000000 * 10**18; //1M EXP per epoch on average, need 40M EXP total to level up all characters to lvl 100, so ~40 epochs
    uint public resourceBaseBoost = 5000; //sets the min % of demand a resource will be emitted for. IE 5000 is 50% 7500 is 75%
    //raising above number increases emmissions

    IRobinHood Characters;
    IWheat Wheat;
    IShillings Shillings;
    IRevolution Revolution;

    //can mayube change this so that is pays out rewards to the current epoch - 1, so that the epoch has to be done to get rewards
    modifier update(address _user){
        //if the users last updated epoch is not this one, then assign the current weights to the users epoch weights
        uint lastEpoch = userInfo[_user].lastEpochUpdated;
        uint epochToUse;
        if(currentEpoch > 0){
            epochToUse = currentEpoch - 1;//set current to be the previous epoch since it is completed
        }
        else{
            epochToUse = 0;
        }
        if(epochToUse > lastEpoch){
            UserInfo storage user = userInfo[_user];
            EpochInfo memory last = epochInfo[lastEpoch];
            EpochInfo memory current = epochInfo[epochToUse];
            
            //pay out rewards
            //calculate $WHEAT owed
            user.wheat += (current.accWheatPerShare - last.accWheatPerShare) * user.farmShare;

            //calculate $SHILLINGS owed
            uint resourceRequired = user.working.length() * resourceRequirement * (epochToUse - lastEpoch);
            if(resourceRequired > user.wheat){
                user.shillings += user.wheat * (current.accShillingsPerShare - last.accShillingsPerShare) * user.workShare / (resourceRequired);
                user.wheat = 0;
            }
            else{
                user.shillings += (current.accShillingsPerShare - last.accShillingsPerShare) * user.workShare;
                user.wheat -= resourceRequired;
            }

            //calculate experience points owed
            resourceRequired = user.training.length() * resourceRequirement * (epochToUse - lastEpoch);

            if(user.wheat < user.shillings){//wheat is limiter
                if(resourceRequired > user.wheat){
                    user.experiencePoints += user.wheat * (current.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare / (resourceRequired);
                    user.shillings -= user.wheat;
                    user.wheat -= user.wheat;//zeroes it out
                }
                else{
                    user.experiencePoints += (current.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare;
                    user.wheat -= resourceRequired;
                    user.shillings -= resourceRequired;
                }
            }
            else{//shillings is limiter
                if(resourceRequired > user.shillings){
                    user.experiencePoints += user.shillings * (current.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare / (resourceRequired);
                    user.wheat -= user.shillings;
                    user.shillings -= user.shillings;//zeroes it out
                }
                else{
                    user.experiencePoints += (current.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare;
                    user.wheat -= resourceRequired;
                    user.shillings -= resourceRequired;
                }
            }
            user.lastEpochUpdated = epochToUse;
        }
        _;
    }
    ///@dev epoch 0 will have NO rewards
    constructor(uint[] memory _startingResources, uint _gameStart, address _characters, address _wheat, address _shillings, uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator){
        Characters = IRobinHood(_characters);
        Wheat = IWheat(_wheat);
        Shillings = IShillings(_shillings);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
 
        //set up epoch 1
        EpochInfo storage info = epochInfo[currentEpoch+1];//set for epoch zero
        info.begin = block.timestamp + _gameStart;
        info.totalWheatAllocation = _startingResources[0];
        info.totalShillingsAllocation =  _startingResources[1];
        info.totalExperienceAllocation =  _startingResources[2];
        info.revolution = false;
        epochLength = 300;
    }

    function setEpochLength(uint _length) external{
        epochLength = _length;
    }

    function viewUser(address _user) external view returns(uint _wheat, uint _shillings, uint _exp, uint _farm, uint _work, uint _train, uint _last){
        UserInfo storage info = userInfo[_user];
        return(info.wheat, info.shillings, info.farmShare, info.experiencePoints, info.workShare, info.trainShare, info.lastEpochUpdated);
    }

    function setRevolution(address _revolution) external onlyOwner{
        Revolution = IRevolution(_revolution);
    }

    function useExperience(address _from, uint _amount) external update(_from){
        require(msg.sender == address(Characters), "NFT contract only one approved to spend experience");
        UserInfo storage info = userInfo[_from];
        require(info.experiencePoints >= _amount, "Not enough experience");
        info.experiencePoints -= _amount;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
        {
        if(block.timestamp >= epochInfo[currentEpoch+1].begin){
            //trigger keepers to call epoch
            upkeepNeeded = true;
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        //set all info for this epoch
        require(block.timestamp >= epochInfo[currentEpoch+1].begin, "epoch not set to start");
        if(currentEpoch > 0){
            EpochInfo storage info = epochInfo[currentEpoch];
            EpochInfo storage prev = epochInfo[currentEpoch-1];
            //set accumulated rewards
            uint revolutionShillings = revolutionTax * info.totalShillingsAllocation / 10000;
            info.accWheatPerShare = prev.accWheatPerShare + ((totalFarmingShares > 0) ? (info.totalWheatAllocation / totalFarmingShares) : 0);
            info.accShillingsPerShare = prev.accShillingsPerShare + ((totalWorkingShares > 0) ? ((info.totalShillingsAllocation - revolutionShillings) / totalWorkingShares) : 0);//w 40% tax, only 60% of shillings are emitted
            info.accExperiencePerShare = prev.accExperiencePerShare + ((totalTrainingShares > 0) ? (info.totalExperienceAllocation / totalTrainingShares) : 0);
            Shillings.mint(address(Revolution), revolutionShillings);//send $SHILLINGS to revolution contract
            Revolution.updateRevolution(revolutionShillings);
            info.epochAccWorkers = prev.epochAccWorkers + totalWorkers;
            info.epochAccTrainers = prev.epochAccTrainers + totalTrainers;
        }

        //request randomness for next epoch
        /**Off for local testnet */
        //DONT NEED TO CALL this when moving to epoch 1 cuz it was set in the constructor
        if(currentEpoch > 1){
            requestRandomWords();
        }
        /**Off for local testnet */
        currentEpoch++;//advance epoch by one
        //set next epochs begin time
        epochInfo[currentEpoch+1].begin = block.timestamp + epochLength;

        if(epochInfo[currentEpoch].revolution){//newly started epoch is a revolution so log how many characters are in the revolution contract
            Revolution.logRevolutionCharacters();
            lastRevolutionEpoch = currentEpoch;
        }
        /*
        ///@dev only for testing
        if(currentEpoch > 1){
            uint[4] memory randomWords = [uint(9999),uint(9999),uint(9999),uint(9999)];
            (uint wheatAllocation, uint shillingsAllocation) = _getResourceDemand();
            EpochInfo storage info1 = epochInfo[currentEpoch+1];
            info1.begin = block.timestamp + epochLength;
            info1.totalWheatAllocation = ((randomWords[0] % 10000) + resourceBaseBoost) * wheatAllocation / 10000; //get rng between 5k -> 10k, then divide by 10k to make first number a decimal
            info1.totalShillingsAllocation = ((randomWords[1] % 10000) + resourceBaseBoost) * shillingsAllocation / 10000;
            info1.totalExperienceAllocation = ((randomWords[2] % 10000) + resourceBaseBoost) * baseExperienceAllocation / 10000;
            info1.revolution = (currentEpoch - lastRevolutionEpoch) >= ((randomWords[3] % maxEpochsWithoutRevolution) + 1);
        }
        */
    }

    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
          keyHash,
          s_subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          numWords
        );
    }   

    function fulfillRandomWords(
      uint256, /* requestId */
      uint256[] memory randomWords
    ) internal override {
        EpochInfo storage info = epochInfo[currentEpoch+1];
        (uint wheatAllocation, uint shillingsAllocation) = _getResourceDemand();
        info.totalWheatAllocation = ((randomWords[0] % 10000) + resourceBaseBoost) * wheatAllocation / 10000; //get rng between 5k -> 10k, then divide by 10k to make first number a decimal
        info.totalShillingsAllocation = ((randomWords[1] % 10000) + resourceBaseBoost) * shillingsAllocation / 10000;
        info.totalExperienceAllocation = ((randomWords[2] % 10000) + resourceBaseBoost) * baseExperienceAllocation / 10000;
        info.revolution = (currentEpoch - lastRevolutionEpoch) >= ((randomWords[3] % maxEpochsWithoutRevolution) + 1);
    }
    //change second array to a single number so it works with a drop down menu
    function move(uint[] memory _ids, uint _to) external update(msg.sender){
        require(_to < 4, "_to not known");
        uint cType;
        UserInfo storage info = userInfo[msg.sender];
        for(uint i=0; i< _ids.length; i++){
            cType = Characters.characterType(_ids[i]);
            uint oldShare;
            //start by removing them from their current set
            if(info.working.contains(_ids[i])){
                info.working.remove(_ids[i]);
                oldShare = _calculateWeight(_ids[i], cType, 0);
                info.workShare -= oldShare;
                totalWorkingShares -= oldShare;
                totalWorkers--;
            }
            else if(info.training.contains(_ids[i])){
                info.training.remove(_ids[i]);
                oldShare = _calculateWeight(_ids[i], cType, 1);
                info.trainShare -= oldShare;
                totalTrainingShares -= oldShare;
                totalTrainers--;
            }
            else if(info.resting.contains(_ids[i])){
                info.resting.remove(_ids[i]);
            }
            else if(cType == 0 && info.farming.contains(_ids[i])){//check if they are farming
                info.farming.remove(_ids[i]);
                oldShare = _calculateWeight(_ids[i], cType, 3);
                info.farmShare -= oldShare;
                totalFarmingShares -= oldShare;
            }
            else{
                revert("Character not found");
            }

            //now add them to their new set
            uint characterShare = _calculateWeight(_ids[i], cType, _to);
            if(_to == 0){//add them to working
                info.working.add(_ids[i]);
                info.workShare += characterShare;
                totalWorkingShares += characterShare;
                totalWorkers++;
            }
            else if(_to == 1){//add them to training
                info.training.add(_ids[i]);
                info.trainShare += characterShare;
                totalTrainingShares += characterShare;
                totalTrainers++;
            }
            else if(_to == 2){//add them to resting
                info.resting.add(_ids[i]);
                info.withdrawalEpoch = currentEpoch + 1;//update epoch withdrawal
            }
            else if(_to == 3){//add them to farming
                require(cType == 0, "Only villagers can farm");
                info.farming.add(_ids[i]);
                info.farmShare += characterShare;
                totalFarmingShares += characterShare;
            }
        }
    }

    //TODO DO I need to call update? Don't think so cuz we aren't altering shares
    function enterTown(uint[] memory _ids) external{
        require(_ids.length > 0, "_ids is empty");
        UserInfo storage info = userInfo[msg.sender];
        for(uint i=0; i<_ids.length; i++){
            Characters.safeTransferFrom(msg.sender, address(this), _ids[i], "");
            info.resting.add(_ids[i]);//add them to the resting array
        }
    }

    function enterTownAll() external{
        require(Characters.balanceOf(msg.sender) > 0, "Caller doesn't have anything to stake");
        UserInfo storage info = userInfo[msg.sender];
        uint bal = Characters.balanceOf(msg.sender);
        uint id;
        for(uint i=0; i<bal; i++){
            id = Characters.tokenOfOwnerByIndex(msg.sender, 0);
            Characters.safeTransferFrom(msg.sender, address(this), id, "");
            info.resting.add(id);//add them to the resting array
        }
    }

    //TODO DO I need to call update? Don't think so cuz we aren't altering shares
    function leaveTown(uint[] memory _ids) external{
        require(_ids.length > 0, "_ids is empty");
        UserInfo storage info = userInfo[msg.sender];
        require(info.withdrawalEpoch <= currentEpoch, "Can unstake next epoch");
        for(uint i=0; i<_ids.length; i++){
            if(info.resting.contains(_ids[i])){
                info.resting.remove(_ids[i]);//remove them from the resting array
                Characters.safeTransferFrom(address(this), msg.sender, _ids[i], "");
            }
            else{
                revert("Character not found resting");
            }
        }
    }

    function leaveTownAll() external{
        UserInfo storage info = userInfo[msg.sender];
        require(info.resting.length() > 0, "Caller has no characters to withdraw");
        uint bal = info.resting.length();
        uint id;
        require(info.withdrawalEpoch <= currentEpoch, "Can unstake next epoch");
        for(uint i=0; i<bal; i++){
            id = info.resting.at(0);
            info.resting.remove(id);//remove them from the resting array
            Characters.safeTransferFrom(address(this), msg.sender,id, "");
        }
    }

    function updateUser() external update(msg.sender){}

    //update here too just in case they try to add more wheat before harvesting rewards
    function depositWheat(uint _amount) external update(msg.sender){
        //burns $WHEAT
        Wheat.burn(msg.sender, _amount);
        userInfo[msg.sender].wheat += _amount;
    }

    function withdrawWheat(uint _amount) external update(msg.sender){
        //mints $WHEAT
        userInfo[msg.sender].wheat -= _amount;
        Wheat.mint(msg.sender, _amount);
    }

    function depositShillings(uint _amount) external update(msg.sender){
        //burns $SHILLINGS
        Shillings.burn(msg.sender, _amount);
        userInfo[msg.sender].shillings += _amount;
    }

    function withdrawShillings(uint _amount) external update(msg.sender){
        //mints $SHILLINGS
        userInfo[msg.sender].shillings -= _amount;
        Shillings.mint(msg.sender, _amount);
    }

    function isRevolution() external view returns(bool){
        EpochInfo storage info = epochInfo[currentEpoch];
        return info.revolution;
    }

    function revolutionChance() external view returns(uint){
        //returns chance revolution will happen in 2 epochs
        return 10000 * (currentEpoch - lastRevolutionEpoch)/ (maxEpochsWithoutRevolution);
    }

    function amountThatCanLeaveNow(address _user) external view returns(uint){
        UserInfo storage info = userInfo[_user];
        if(info.withdrawalEpoch >= currentEpoch){
            return info.resting.length();
        }
        return 0;
    }

    function viewShares(address _user) external view returns(uint farm, uint work, uint train){
        UserInfo storage info = userInfo[_user];
        farm = (totalFarmingShares > 0) ? (info.farmShare * 10000 / totalFarmingShares) : 0;
        work = (totalWorkingShares > 0) ? (info.workShare * 10000 / totalWorkingShares) : 0;
        train = (totalTrainingShares > 0) ? (info.trainShare * 10000 / totalTrainingShares) : 0;
    }

    function viewAllocations(uint _epoch) external view returns(uint wheat, uint shillings, uint experience){
        EpochInfo storage info = epochInfo[_epoch];
        wheat = info.totalWheatAllocation;
        shillings = info.totalShillingsAllocation;
        experience = info.totalExperienceAllocation;
    }

    function viewEarnedResources(address _user) external view returns(uint wheat, uint shillings, uint experiencePoints){
        if(currentEpoch == 0){return (0,0,0);}//no resources have been earned
        UserInfo storage user = userInfo[_user];
        EpochInfo memory last = epochInfo[user.lastEpochUpdated];
        EpochInfo memory lastCompleted = epochInfo[currentEpoch-1];//Rewards have been set for this epoch
        uint timeElapsed = (currentEpoch - 1) - user.lastEpochUpdated;
        //calculate $WHEAT owed
        wheat = user.wheat;
        shillings = user.shillings;
        experiencePoints = user.experiencePoints;
        if(timeElapsed == 0){
            return (wheat, shillings, experiencePoints);
        }
        wheat += (lastCompleted.accWheatPerShare - last.accWheatPerShare) * user.farmShare;
        //calculate $SHILLINGS owed
        uint resourceRequired = user.working.length() * resourceRequirement * timeElapsed;
        if(resourceRequired > wheat){
            shillings += wheat * (lastCompleted.accShillingsPerShare - last.accShillingsPerShare) * user.workShare / (resourceRequired);
            wheat = 0;
        }
        else{
            shillings += (lastCompleted.accShillingsPerShare - last.accShillingsPerShare) * user.workShare;
            wheat -= resourceRequired;
        }
        //calculate experience points owed
        resourceRequired = user.training.length() * resourceRequirement * timeElapsed;
        if(wheat < shillings){//wheat is limiter
            if(resourceRequired > wheat){
                experiencePoints += wheat * (lastCompleted.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare / (resourceRequired);
                shillings -= wheat;
                wheat -= wheat;//zeroes it out
            }
            else{
                experiencePoints += (lastCompleted.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare;
                wheat -= resourceRequired;
                shillings -= resourceRequired;
            }
        }
        else{//shillings is limiter
            if(resourceRequired > shillings){
                experiencePoints += shillings * (lastCompleted.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare / (resourceRequired);
                wheat -= shillings;
                shillings -= shillings;//zeroes it out
            }
            else{
                experiencePoints += (lastCompleted.accExperiencePerShare - last.accExperiencePerShare) * user.trainShare;
                wheat -= resourceRequired;
                shillings -= resourceRequired;
            }
        }
    }

    ///Only for the CURRENT epoch
    function viewPendingResources(address _user) external view returns(uint pendingWheat, uint pendingShillings, uint pendingExperiencePoints, uint pendingNegWheat, uint pendingNegShillings){
        UserInfo storage user = userInfo[_user];
        EpochInfo memory current = epochInfo[currentEpoch];
        //find current accumulated rewards per share
        uint revolutionShillings = revolutionTax * current.totalShillingsAllocation / 10000;
        uint accWheatPerShare = ((totalFarmingShares > 0) ? (current.totalWheatAllocation / totalFarmingShares) : 0);
        uint accShillingsPerShare = ((totalWorkingShares > 0) ? ((current.totalShillingsAllocation - revolutionShillings) / totalWorkingShares) : 0);
        uint accExperiencePerShare = ((totalTrainingShares > 0) ? (current.totalExperienceAllocation / totalTrainingShares) : 0);

        //calculate user credit and debt for this epoch
        pendingWheat = accWheatPerShare * user.farmShare;
        pendingShillings = accShillingsPerShare * user.workShare;
        pendingExperiencePoints = accExperiencePerShare * user.trainShare;
        pendingNegWheat = (user.working.length() + user.training.length()) * resourceRequirement;
        pendingNegShillings = user.training.length() * resourceRequirement;
    }

    function _calculateWeight(uint _id, uint _type, uint _category) internal view returns(uint){
        return baseWeights[_type] + Characters.characterLevel(_id) * Characters.getItemBoost(_id, _category) / 10**18;
    }

    function _getResourceDemand() internal view returns(uint avgWheatDemand, uint avgShillingsDemand){
        uint epochStart;
        uint lastEpoch = currentEpoch - 1;
        if(lastEpoch > epochsToAverage){
            epochStart = lastEpoch - epochsToAverage;
        }
        else{
            epochStart  = 0;
        }
        avgShillingsDemand = resourceRequirement * (epochInfo[lastEpoch].epochAccTrainers - epochInfo[epochStart].epochAccTrainers) / (lastEpoch - epochStart);//per epoch
        avgWheatDemand = avgShillingsDemand + (resourceRequirement  * (epochInfo[lastEpoch].epochAccWorkers - epochInfo[epochStart].epochAccWorkers) / (lastEpoch - epochStart));//per epoch
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IRobinHood is IERC721Enumerable{
    function characterType(uint id) external view returns(uint);
    function characterLevel(uint id) external view returns(uint);
    function maxLevel() external view returns(uint);
    function burn(uint id) external;
    function getItemBoost(uint _id, uint _category) external view returns(uint);
    function equippedItem(uint _id) external view returns(uint);
    function consumeItem(uint _characterId, uint _id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWheat is IERC20{
    function mint(address _to, uint _amount) external;
    function burn(address _from, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IShillings is IERC20{
    function mint(address _to, uint _amount) external;
    function burn(address _from, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IRevolution{
    function updateRevolution(uint _amount) external;
    function logRevolutionCharacters() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}