// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Activity/ActivityContract.sol";
import "./Task/Task.sol";
import "./Registration/Registration.sol";
import "./Donation/Donation.sol";

contract Minerva {
    UserRegistrationContract private i_UserRegistrationContract;
    ActivityInterface private i_MinervaActivityContract;
    TaskInterface private i_MinervaTaskContract;
    IDonationContract private i_MinervaDonationContract;

    constructor(
        address _UserRegistrationContract,
        address _MinervaActivityContract,
        address _MinervaTaskContract,
        address _MinervaDonationContract
    ) {
        i_UserRegistrationContract = UserRegistrationContract(
            _UserRegistrationContract
        );
        i_MinervaActivityContract = ActivityInterface(_MinervaActivityContract);
        i_MinervaTaskContract = TaskInterface(_MinervaTaskContract);
        i_MinervaDonationContract = IDonationContract(_MinervaDonationContract);
    }

    /**
     * @notice - Registration Interface
     * @dev - [Note]: This interface is used for the following functions:
     *  - registerUser()
     * - getUserCredits()
     * - isUserRegistered()
     * - addUserCredits()
     */

    //Events
    event UserRegistered(address userAddress, uint256 dateOfRegistration);

    //Functions
    function registerUser() public {
        i_UserRegistrationContract.registerUser(msg.sender);
        emit UserRegistered(msg.sender, block.timestamp);
    }

    function getUserCredits(address userAddress) public view returns (uint256) {
        return i_UserRegistrationContract.getUserCredits(userAddress);
    }

    function isUserRegistered(address userAddress) public view returns (bool) {
        return i_UserRegistrationContract.isUserRegistered(userAddress);
    }

    function addUserCredits(uint256 credits) public {
        i_UserRegistrationContract.addUserCredits(msg.sender, credits);
    }

    function getUserCount() public view returns (uint256) {
        return i_UserRegistrationContract.getUserCount();
    }

    /**
     * @notice - Activity Interface
     * @dev - [Note]: This interface is used for the following functions:
     * - createActivity()
     * - joinActivity()
     * - leaveActivity()
     * - addTermForActivity()
     */
    // ------------ Events ------------
    event ActivityCreated(
        address _owner,
        uint256 _id,
        string _title,
        string _desc,
        uint256 _totalTimeInMonths,
        uint256 _level,
        uint256 dateOfCreation
    );

    event MemberWhiteListed(uint256 _activityId, address _memberAddress);

    event MemberJoined(
        uint256 _activityId,
        address _memberAddress,
        uint256 _dateOfJoin,
        uint256 _tenureInMonths
    );

    event TermCreated(uint256 _activityId, string[] _title, string[] _desc);

    event MemberLeft(
        uint256 _activityId,
        address _memberAddress,
        uint256 _dateOfLeave
    );

    /**
     * @notice Creates a new activity and stores it in the MinervaActivityContract.
     * @param _id The unique identifier for the activity.
     * @param _username The username of the creator of the activity.
     * @param _title The title of the activity.
     * @param _desc The description of the activity.
     * @param _totalTimeInMonths The total time (in months) for which the activity will be active.
     * @param _price The price (in wei) for joining the activity.
     * @param _level The required level to join the activity.
     * @param _maxMembers The maximum number of members that can join the activity.
     * @param _waitingPeriodInMonths The waiting period (in months) before the activity can be joined.
     */
    function createActivity(
        uint256 _id,
        string memory _username,
        string memory _title,
        string memory _desc,
        uint256 _totalTimeInMonths,
        uint256 _price,
        uint256 _level,
        uint256 _maxMembers,
        uint256 _waitingPeriodInMonths
    ) public {
        i_MinervaActivityContract.createActivity(
            _id,
            _username,
            _title,
            _price,
            _level,
            _maxMembers,
            _waitingPeriodInMonths,
            msg.sender
        );
        emit ActivityCreated(
            msg.sender,
            _id,
            _title,
            _desc,
            _totalTimeInMonths,
            _level,
            block.timestamp
        );
    }

    /**
     * @notice Adds a member's address to the whitelist for a given activity.
     * @param _activityID The unique identifier for the activity.
     * @param _memberAddress The address of the member to be added to the whitelist.
     */
    function addToWhitelist(
        uint256 _activityID,
        address _memberAddress
    ) public {
        i_MinervaActivityContract.addToWhitelist(
            _activityID,
            _memberAddress,
            msg.sender
        );
        emit MemberWhiteListed(_activityID, _memberAddress);
    }

    /**
     * @notice Allows a member to join an activity by paying the required fee and providing their details.
     * @param _activityID The unique identifier for the activity.
     * @param _username The username of the member joining the activity.
     * @param _tenureInMonths The tenure (in months) for which the member will be a part of the activity.
     */
    function joinActivity(
        uint256 _activityID,
        string memory _username,
        uint256 _tenureInMonths
    ) public payable {
        i_MinervaActivityContract.joinActivity{value: msg.value}(
            _activityID,
            _username,
            msg.sender
        );
        emit MemberJoined(
            _activityID,
            msg.sender,
            block.timestamp,
            _tenureInMonths
        );
    }

    /**
     * @notice Allows a member to leave an activity.
     * @param _memberAddress The address of the member leaving the activity.
     * @param _activityID The unique identifier for the activity.
     */
    function leaveActivity(address _memberAddress, uint256 _activityID) public {
        i_MinervaActivityContract.leaveActivity(
            _memberAddress,
            _activityID,
            msg.sender
        );
        emit MemberLeft(_activityID, _memberAddress, block.timestamp);
    }

    /**
     * @notice Adds a new term to an existing activity.
     * @dev Calls the `addTermForActivity` function on the `i_MinervaActivityContract` interface.
     * Emits a `TermCreated` event upon successful creation of the new term.
     * @param _activityID The ID of the activity to which the new term will be added.
     * @param _title An array of strings representing the title of the new term.
     * @param _desc An array of strings representing the description of the new term.
     */
    function addTermForActivity(
        uint256 _activityID,
        string[] memory _title,
        string[] memory _desc
    ) public {
        i_MinervaActivityContract.addTermForActivity(
            _activityID,
            _title,
            _desc,
            msg.sender
        );
        emit TermCreated(_activityID, _title, _desc);
    }

    // Activity - Getter functions
    function getActivityCount() public view returns (uint256) {
        return i_MinervaActivityContract.getActivityCount();
    }

    function getActivity(
        uint256 _activityID
    ) public view returns (ActivityInterface.Activity memory) {
        return i_MinervaActivityContract.getActivity(_activityID);
    }

    function getMemberDetails(
        address _memberAddress
    ) public view returns (ActivityInterface.Member memory) {
        return i_MinervaActivityContract.getMemberDetails(_memberAddress);
    }

    function getTermsForActivity(
        uint256 _activityID
    ) public view returns (ActivityInterface.Terms memory) {
        return i_MinervaActivityContract.getTermsForActivity(_activityID);
    }

    /**
     * @notice - Donation Interface
     * @dev - [Note]: This interface is used for the following functions:
     * - donateToActivity()
     * - withdrawSelectiveMoney()
     * - withdrawAllMoney()
     */
    event DonationMade(
        address _sender,
        uint256 _activityID,
        uint256 _userPublicID,
        uint256 _donationAmount,
        uint256 _timeStamp
    );

    event MoneyWithdrawn(
        address _sender,
        uint256 _activityID,
        uint256 _amount,
        uint256 _timeStamp
    );

    /**
     * @notice Allows a user to donate funds to a specified activity.
     * @dev Calls the `donateToActivity` function on the `i_MinervaDonationContract` interface.
     * Emits a `DonationMade` event upon successful completion of the donation.
     * @param _activityID The ID of the activity to which the donation is being made.
     * @param _userPublicID The public ID of the user making the donation.
     */
    function donateToActivity(
        uint256 _activityID,
        uint256 _userPublicID
    ) public payable {
        i_MinervaDonationContract.donateToActivity{value: msg.value}(
            _activityID,
            _userPublicID,
            msg.sender
        );
        emit DonationMade(
            msg.sender,
            _activityID,
            _userPublicID,
            msg.value,
            block.timestamp
        );
    }

    /**
     * @notice Allows an activity owner to withdraw a specified amount of funds from an activity.
     * @dev Calls the `withdrawSelectiveMoney` function on the `i_MinervaDonationContract` interface.
     * Emits a `MoneyWithdrawn` event upon successful completion of the withdrawal.
     * @param _activityID The ID of the activity from which the funds will be withdrawn.
     * @param _amount The amount of funds to be withdrawn.
     */
    function withdrawSelectiveMoney(
        uint256 _activityID,
        uint256 _amount
    ) public {
        i_MinervaDonationContract.withdrawSelectiveMoney(
            _activityID,
            _amount,
            msg.sender
        );
        emit MoneyWithdrawn(msg.sender, _activityID, _amount, block.timestamp);
    }

    /**
     * @notice Allows the owner of an activity to withdraw all the funds collected by the activity
     * @param _activityID The ID of the activity whose funds need to be withdrawn
     */
    function withdrawAllMoney(uint256 _activityID) public {
        i_MinervaDonationContract.withdrawAllMoney(_activityID, msg.sender);
        emit MoneyWithdrawn(
            msg.sender,
            _activityID,
            i_MinervaActivityContract.getDonationBalance(_activityID),
            block.timestamp
        );
    }

    function getFunders(
        uint256 _activityID
    ) public view returns (IDonationContract.Funder[] memory) {
        return i_MinervaDonationContract.getActivityFunders(_activityID);
    }

    function doesAddressHavePermission() public view returns (bool) {
        return i_MinervaDonationContract.doesAddressHavePermission();
    }

    /**
     * @notice - Task Interface
     */
    // ------------ Events ------------
    event TaskCreated(
        address _creator,
        address _assignee,
        string _description,
        uint _rewardInD,
        uint _dueDate,
        uint _creditScoreReward,
        uint256 _timeStamp
    );

    event TaskCompleted(
        address _creator,
        address _assignee,
        uint256 _taskID,
        uint256 _activityID,
        uint256 _completionTime,
        bool _completed,
        uint256 _rewardValue
    );

    /**
     * @dev Creates a task for the given activity and assigns it to the specified user.
     * @param _activityID ID of the activity to which the task belongs.
     * @param _assignee Address of the user to whom the task is assigned.
     * @param _title Title of the task.
     * @param _description Description of the task.
     * @param _rewardInD Reward in USD for completing the task.
     * @param _dueDate Unix timestamp indicating the deadline for completing the task.
     * @param _creditScoreReward Credit score reward for completing the task.
     */
    function createTask(
        uint256 _activityID,
        address _assignee,
        string memory _title,
        string memory _description,
        uint _rewardInD,
        uint _dueDate,
        uint _creditScoreReward
    ) public payable {
        i_MinervaTaskContract.createTask{value: msg.value}(
            _activityID,
            _assignee,
            _title,
            _description,
            _rewardInD,
            _dueDate,
            _creditScoreReward,
            msg.sender
        );
        emit TaskCreated(
            msg.sender,
            _assignee,
            _description,
            _rewardInD,
            _dueDate,
            _creditScoreReward,
            block.timestamp
        );
    }

    /**
     * @notice Marks a task as complete for a given activity
     * @param _activityID The ID of the activity the task belongs to
     * @param _taskID The ID of the task to be marked as complete
     */
    function completeTask(uint256 _activityID, uint256 _taskID) public {
        i_MinervaTaskContract.completeTask(_activityID, _taskID, msg.sender);
        emit TaskCompleted(
            msg.sender,
            i_MinervaTaskContract
            .getActivityTasks(_activityID)[_taskID - 1].assignee,
            _taskID,
            _activityID,
            block.timestamp,
            true,
            i_MinervaTaskContract
            .getActivityTasks(_activityID)[_taskID - 1].rewardValue
        );
    }

    function getActivityTasks(
        uint256 _activityID
    ) public view returns (TaskInterface.Task[] memory) {
        return i_MinervaTaskContract.getActivityTasks(_activityID);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../Registration/Registration.sol";
import "../PriceConvertor/PriceConvertor.sol";

// 3. Interfaces, Libraries, Contracts
error Activity_NotOwner();
error Activity_NotWhiteListed();
error Activity_NotFound();

interface ActivityInterface {
    enum ActivityStatus {
        OPEN,
        IN_PROGRESS,
        CLOSED
    }
    struct Activity {
        uint256 id;
        address payable owner;
        string title;
        uint256 joinPrice;
        uint256 level;
        ActivityStatus status;
        uint256 dateOfCreation;
        uint256 maxMembers;
        address payable[] members;
        uint256 _waitUntil;
        uint256 donationReceived;
        uint256 donationBalance;
    }

    struct Member {
        string _id;
        uint256 dateOfJoin;
        uint256 forActivity;
        uint256 timeJoined;
        bool isEngaged;
    }

    struct Terms {
        string[] title;
        string[] desc;
    }

    function createActivity(
        uint256 _id,
        string calldata _username,
        string calldata _title,
        uint256 _price,
        uint256 _level,
        uint256 _maxMembers,
        uint256 _waitingPeriodInMonths,
        address userAddress
    ) external;

    function addToWhitelist(
        uint256 _activityID,
        address _memberAddress,
        address userAddress
    ) external;

    function joinActivity(
        uint256 _activityID,
        string calldata _username,
        address userAddress
    ) external payable;

    function leaveActivity(
        address _memberAddress,
        uint256 _activityID,
        address userAddress
    ) external;

    function addTermForActivity(
        uint256 _activityID,
        string[] calldata _title,
        string[] calldata _desc,
        address userAddress
    ) external;

    function getActivityCount() external view returns (uint256);

    function getActivity(
        uint256 activityID
    ) external view returns (Activity memory);

    function getDonationBalance(
        uint256 _activityID
    ) external view returns (uint256 balance);

    function getMemberDetails(
        address _memberAddress
    ) external view returns (Member memory);

    function getTermsForActivity(
        uint256 _activityID
    ) external view returns (Terms memory);
}

/**
 * @title Minerva Activity Contract
 * @author Slowqueso/Lynda Barn/Kartik Ranjan
 * @notice This contract allows users to create a MOU or Agreement between Activity hosts and Activity Members.
 * @dev Data Price Feeds are implemented for ETH / USD
 */
contract MinervaActivityContract {
    using PriceConvertorLibrary for uint256;
    UserRegistrationContract private i_UserRegistrationContract;
    address private immutable i_owner;
    uint256 private s_lastUpdated;
    address private immutable i_priceConvertorContractAddress;

    // ------------ Pre Defined Activity Levels ------------
    /**
     * @dev 4 States of Activity.
     * `OPEN `- The activity allows members to join
     * `IN_PROGRESS` - Checks for how long the progress is
     * `CLOSED` - Activity does not accept anymore members
     * `FAILED` - Activity deleted
     */
    enum ActivityStatus {
        OPEN,
        IN_PROGRESS,
        CLOSED
    }

    uint256[] internal maxJoiningPrice = [5, 10, 30, 50, 100];
    uint256[] internal minCredForActivity = [100, 300, 1000, 1500, 2000];
    mapping(uint256 => uint256) internal levelToMaxTasks;
    mapping(address => bool) public AddressesPermittedToAccess;

    constructor(
        address _UserRegistrationContractAddress,
        address _priceConvertorContractAddress
    ) {
        i_UserRegistrationContract = UserRegistrationContract(
            _UserRegistrationContractAddress
        );
        i_priceConvertorContractAddress = _priceConvertorContractAddress;
        i_owner = msg.sender;
        s_lastUpdated = block.timestamp;
        AddressesPermittedToAccess[msg.sender] = true;
    }

    // ------------ Global Counters ------------
    uint256 private s_activityCounter = 0;
    uint256 private s_ownerFunds = 0;
    uint256 private s_upkeepCounter;

    // ------------ Structs ------------
    /**
     * @notice struct for `Activities`
     */
    struct Activity {
        uint256 id;
        address payable owner;
        string title;
        uint256 joinPrice;
        uint256 level;
        ActivityStatus status;
        uint256 dateOfCreation;
        uint256 maxMembers;
        address payable[] members;
        uint256 _waitUntil;
        uint256 donationReceived;
        uint256 donationBalance;
    }

    /**
     * @notice struct for Activity Members
     * @dev `dateOfJoin` is in unix timestamp (block.timestamp).
     */
    struct Member {
        string _id;
        uint256 dateOfJoin;
        uint256 forActivity;
        uint256 timeJoined;
        bool isEngaged;
    }

    /**
     * @notice struct for each Terms and Conditions for Activities
     */
    struct Terms {
        string[] title;
        string[] desc;
    }

    // ------------ Arrays and Mappings ------------
    mapping(uint256 => Activity) Activities;
    mapping(uint256 => address[]) ActivityIdToWhiteListedUsers;
    mapping(address => Member) Members;
    mapping(uint256 => Terms) ActivityIdToTerms;
    uint256[] activitiesForUpkeep;

    /**
     * @notice This Array gets resetted to default i.e [] after every alteration
     * @dev strictly use for storing arrays into structs.
     */
    address payable[] memberAddress;

    // ------------ Modifiers ------------
    /**
     * @dev To allow functions to be executed only by Contract owner - Minerva
     */
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Activity_NotOwner();
        _;
    }

    // ------------ Functional Public Modifiers ------------
    function doesActivityExist(uint256 _id) public view returns (bool) {
        return Activities[_id].level > 0;
    }

    function isActivityOwner(
        uint256 _id,
        address sender
    ) public view returns (bool) {
        return Activities[_id].owner == sender;
    }

    /**
     * @dev to check if the sender is a member of the activity
     */
    modifier isMemberOfActivity(uint256 _id, address sender) {
        bool isNotMember = true;
        for (uint256 i = 0; i < Activities[_id].members.length; i++) {
            if (Activities[_id].members[i] == payable(sender)) {
                isNotMember = false;
            }
        }
        require(isNotMember, "You are already a member of this activity");
        _;
    }

    /**
     * @dev Checks if the user is registered
     */
    modifier isRegisteredUser(address sender) {
        require(
            i_UserRegistrationContract.isUserRegistered(sender),
            "User is not registered"
        );
        _;
    }

    /**
     * @dev Checks if user is whitelisted for activity
     */
    modifier isUserWhitelisted(uint256 _activityID, address sender) {
        bool isWhitelisted = false;
        for (
            uint256 i = 0;
            i < ActivityIdToWhiteListedUsers[_activityID].length;
            i++
        ) {
            if (ActivityIdToWhiteListedUsers[_activityID][i] == sender) {
                isWhitelisted = true;
            }
        }
        if (!isWhitelisted) revert Activity_NotWhiteListed();
        _;
    }

    /**
     * @dev Only allows function to be called by permitted addresses
     */
    modifier onlyPermitted() {
        require(
            AddressesPermittedToAccess[msg.sender],
            "Only permitted addresses can call this function"
        );
        _;
    }

    // ------------ Owner Functions ------------
    /**
     * @notice Function to add funds to the contract
     * @dev Only the owner of the contract can execute this function
     */
    function addFundsToContract() public payable onlyOwner {
        s_ownerFunds += msg.value;
    }

    function addPermittedAddress(address permittedAddress) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = true;
    }

    function removePermittedAddress(
        address permittedAddress
    ) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = false;
    }

    /**
     * @notice Function to withdraw funds from the contract
     * @dev Only the owner of the contract can execute this function
     */
    function withdrawFundsFromContract(uint256 _amount) public onlyOwner {
        require(_amount <= s_ownerFunds, "Not enough funds in the contract");
        s_ownerFunds -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // ------------ Activity Methods ------------
    // Create Activity
    /**
     * @notice Function for creating an Activity
     * @dev emits Event - `ActivityCreated`
     */
    function createActivity(
        uint256 _id,
        string memory _username,
        string memory _title,
        uint256 _price,
        uint256 _level,
        uint256 _maxMembers,
        uint256 _waitingPeriodInMonths,
        address userAddress
    ) external isRegisteredUser(userAddress) onlyPermitted {
        require(_price <= maxJoiningPrice[_level - 1], "ETH limit crossed");
        require(
            i_UserRegistrationContract.getUserCredits(userAddress) >=
                minCredForActivity[_level - 1],
            "Not Enough Credits for creating the activity!"
        );
        uint256 dateOfCreation = block.timestamp;
        s_activityCounter++;
        uint256 id = s_activityCounter;
        memberAddress.push(payable(userAddress));
        uint256 _waitUntil = block.timestamp +
            (_waitingPeriodInMonths * 30 days);
        Activity memory activity = Activity(
            _id,
            payable(userAddress),
            _title,
            _price,
            _level,
            ActivityStatus.OPEN,
            block.timestamp,
            _maxMembers,
            memberAddress,
            _waitUntil,
            0,
            0
        );
        Members[userAddress] = Member(
            _username,
            dateOfCreation,
            id,
            block.timestamp,
            true
        );
        Activities[id] = activity;
        delete memberAddress;
    }

    // Add Terms and Conditions
    /**
     * @dev Modifiers - `onlyActivityOwners`, `doesActivityExist`, Events emitted - `TermAdded`
     * @notice Method to allow activity owners to add terms and conditions to their Activities
     */
    function addTermForActivity(
        uint256 _activityID,
        string[] memory _title,
        string[] memory _desc,
        address userAddress
    ) external onlyPermitted isRegisteredUser(userAddress) {
        if (!doesActivityExist(_activityID)) revert Activity_NotFound();
        require(
            isActivityOwner(_activityID, userAddress),
            "User is not the owner of the activity"
        );
        Terms memory terms = Terms(_title, _desc);
        ActivityIdToTerms[_activityID] = terms;
    }

    // Add to whitelist
    /**
     * @notice Function for adding a user to the whitelist of an Activity
     * @dev emits Event - `MemberWhiteListed`
     */
    function addToWhitelist(
        uint256 _activityID,
        address _memberAddress,
        address userAddress
    ) external onlyPermitted {
        require(
            isActivityOwner(_activityID, userAddress),
            "User is not the owner of the activity"
        );
        ActivityIdToWhiteListedUsers[_activityID].push(_memberAddress);
    }

    // Join Activity
    /**
     * @dev Modifiers used - `isActivityJoinable`, `doesActivityExist`, `isMemberOfActivity`. Events emitted - `MemberJoined`.
     * @notice Function for external users (in terms of Activity) to participate in the Activity.
     */
    function joinActivity(
        uint256 _activityID,
        string memory _username,
        address userAddress
    )
        external
        payable
        isRegisteredUser(userAddress)
        isMemberOfActivity(_activityID, userAddress)
        isUserWhitelisted(_activityID, userAddress)
        onlyPermitted
    {
        require(
            Members[userAddress].isEngaged == false,
            "Already Engaged in activity"
        );
        if (!doesActivityExist(_activityID)) revert Activity_NotFound();
        uint256 _dateOfJoin = block.timestamp;
        Activity storage activity = Activities[_activityID];
        require(
            (activity.joinPrice - 1) <
                msg.value.getConversionRate(i_priceConvertorContractAddress) &&
                msg.value.getConversionRate(i_priceConvertorContractAddress) <=
                (activity.joinPrice + 1),
            "Not enough ETH"
        );
        Members[userAddress] = Member(
            _username,
            _dateOfJoin,
            _activityID,
            block.timestamp,
            true
        );
        activity.members.push(payable(userAddress));
        if (activity.status == ActivityStatus.OPEN) {
            activity.status = ActivityStatus.IN_PROGRESS;
        }
        (bool sent, ) = activity.owner.call{value: msg.value}("");
        require(sent, "Failed to send ETH");
    }

    // Leave Activity
    /**
     * @dev Modifiers used - `isActivityOwner`, `doesActivityExist`. Events emitted - `MemberLeft`.
     * @notice Function for external users (in terms of Activity) to leave the Activity.
     */
    function leaveActivity(
        address _memberAddress,
        uint256 _activityID,
        address userAddress
    ) external onlyPermitted {
        if (!doesActivityExist(_activityID)) revert Activity_NotFound();
        require(isActivityOwner(_activityID, userAddress));
        Members[_memberAddress].isEngaged = false;
        Members[_memberAddress].forActivity = 0;
    }

    /**
     * @notice - Function for receiving money from donations
     */
    function receiveDonationForActivity(
        uint256 _activityID,
        uint256 _donationReceived,
        uint256 _donationBalance
    ) external {
        Activities[_activityID].donationReceived += _donationReceived;
        Activities[_activityID].donationBalance += _donationBalance;
    }

    /**
     * @notice - Function for withdrawing Donation money from Activity
     */
    function withdrawDonationMoneyFromActivity(
        uint256 _activityID,
        uint256 _amount
    ) external {
        Activities[_activityID].donationBalance -= _amount;
    }

    // @Chainlink Keepers
    /**
     * @dev This function checks if any of the activities need an Upkeep
     * Going to be called inside `performUpkeep` to check for Activities that are expired.
     */
    function checkUpkeep() internal returns (bool upkeepNeeded) {
        bool activitiesAdded = false;
        bool hasBalance = address(this).balance > 0;
        Activity memory activity;
        if (s_activityCounter > 0) {
            for (uint256 i = 1; i < s_activityCounter + 1; i++) {
                activity = Activities[i];
                if (activity.status == ActivityStatus.OPEN) {
                    if ((block.timestamp >= activity._waitUntil)) {
                        if ((activity.members.length <= 1)) {
                            activitiesForUpkeep.push(i);
                            activitiesAdded = true;
                        }
                    }
                }
            }
        } else {
            return upkeepNeeded = false;
        }

        s_lastUpdated = block.timestamp;
        upkeepNeeded = (activitiesAdded && hasBalance);
    }

    /**
     * @dev `performUpkeep` is called by the Time-based Chainlink Keepers called on `1 0,12 * * *`
     */
    function performUpkeep() external {
        bool upkeepNeeded = checkUpkeep();
        require(upkeepNeeded, "Upkeep not needed");
        Activity storage activity;
        for (uint i = 0; i < activitiesForUpkeep.length; i++) {
            uint256 id = activitiesForUpkeep[i];
            activity = Activities[id];
            activity.status = ActivityStatus.CLOSED;
        }
        delete activitiesForUpkeep;
        s_lastUpdated = block.timestamp;
        s_upkeepCounter++;
    }

    // ------------ Getters ------------
    /**
     * @notice Function to get the owner of Activity
     */
    function getOwner() public view onlyOwner returns (address) {
        return (i_owner);
    }

    /**
     * @notice Function to get the details of an Activity
     */
    function getActivityCount() external view returns (uint256) {
        return s_activityCounter;
    }

    function getActivity(
        uint256 activityID
    ) external view returns (Activity memory) {
        Activity memory returnActivity = Activities[activityID];
        return (returnActivity);
    }

    function getTermsForActivity(
        uint256 _activityID
    ) external view returns (Terms memory) {
        return ActivityIdToTerms[_activityID];
    }

    /**
     * @notice - To get the donation balance of the activity
     */
    function getDonationBalance(
        uint256 _activityID
    ) external view returns (uint256) {
        return Activities[_activityID].donationBalance;
    }

    function getActivityLevel(
        uint256 _activityID
    ) external view returns (uint256) {
        Activity memory activity = Activities[_activityID];
        return activity.level;
    }

    /**
     * @notice Function to get the details of a Member
     */
    function getMemberDetails(
        address _memberAddress
    ) external view returns (Member memory) {
        Member memory member = Members[_memberAddress];
        return (member);
    }

    function getDonationBalanceForActivity(
        uint256 _activityID
    ) external view returns (uint256) {
        Activity memory activity = Activities[_activityID];
        return activity.donationBalance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../Registration/Registration.sol";
import "../PriceConvertor/PriceConvertor.sol";
import "../Activity/ActivityContract.sol";

// 3. Interfaces, Libraries, Contracts
error Task_NotOwner();
error Task__ActivityDoesNotExist();
error Task__AssigneeNotMember();

interface TaskInterface {
    struct Task {
        address creator;
        address assignee;
        string title;
        string description;
        uint rewardInD;
        uint dueDate;
        uint creditScoreReward;
        bool completed;
        uint256 assignedDate;
        uint256 rewardValue;
    }

    function createTask(
        uint256 _activityID,
        address _assignee,
        string calldata _title,
        string calldata _description,
        uint _rewardInD,
        uint _dueInDays,
        uint _creditScoreReward,
        address userAddress
    ) external payable;

    function completeTask(
        uint256 _activityID,
        uint256 _taskID,
        address userAddress
    ) external;

    function getActivityTasks(
        uint256 _activityID
    ) external view returns (Task[] calldata);
}

/**
 * @title Minerva Task Contract
 * @author Slowqueso/Lynda Barn/Kartik Ranjan
 * @notice This contract allows Activity owners to create and assign tasks for Activity Members.
 * @dev Data Price Feeds are implemented for ETH / USD
 */
contract MinervaTaskContract {
    UserRegistrationContract private i_UserRegistrationContract;
    MinervaActivityContract private i_ActivityContract;
    address private immutable i_owner;
    address private immutable i_priceFeedContractAddress;
    uint256 private taxPercentage;

    constructor(
        address _UserRegistrationContractAddress,
        address _ActivityContractAddress,
        address _priceFeedContractAddress
    ) {
        i_UserRegistrationContract = UserRegistrationContract(
            _UserRegistrationContractAddress
        );
        i_priceFeedContractAddress = _priceFeedContractAddress;
        i_ActivityContract = MinervaActivityContract(_ActivityContractAddress);
        i_owner = msg.sender;
        AddressesPermittedToAccess[msg.sender] = true;
    }

    // ------------ Structs ------------
    /**
     * @notice struct for `Tasks`
     */
    struct Task {
        address creator;
        address assignee;
        string title;
        string description;
        uint rewardInD;
        uint dueDate;
        uint creditScoreReward;
        bool completed;
        uint256 assignedDate;
        uint256 rewardValue;
    }

    // ------------ Arrays and Mappings ------------
    mapping(uint256 => Task[]) Tasks;
    mapping(address => bool) public AddressesPermittedToAccess;

    // ------------ Modifiers ------------
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Task_NotOwner();
        _;
    }

    modifier onlyActivityOwners(uint256 _activityID, address sender) {
        require(
            i_ActivityContract.isActivityOwner(_activityID, sender),
            "Only Activity Owners can create tasks"
        );
        _;
    }

    modifier doesActivityExist(uint256 _activityID) {
        if (!i_ActivityContract.doesActivityExist(_activityID))
            revert Task__ActivityDoesNotExist();
        _;
    }

    modifier onlyPermitted() {
        require(
            AddressesPermittedToAccess[msg.sender],
            "Only permitted addresses can call this function"
        );
        _;
    }

    // Owner Functions
    function setTaxPercentage(uint256 _percent) public onlyOwner {
        taxPercentage = _percent;
    }

    function addPermittedAddress(address permittedAddress) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = true;
    }

    function removePermittedAddress(
        address permittedAddress
    ) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = false;
    }

    // Tasks
    function retrieveTaxAmountForTask(
        uint256 _amount
    ) internal pure returns (uint256) {
        uint256 taxAmount = (_amount * 20) / 100;
        return taxAmount;
    }

    /**
     * @dev Modifiers - `onlyActivityOwners`, `doesActivityExist`, Events emitted - `TaskCreated`
     * @notice Method to allow activity owners to create tasks for their Activities
     */
    function createTask(
        uint256 _activityID,
        address _assignee,
        string memory _title,
        string memory _description,
        uint _rewardInD,
        uint _dueInDays,
        uint _creditScoreReward,
        address userAddress
    )
        external
        payable
        doesActivityExist(_activityID)
        onlyActivityOwners(_activityID, userAddress)
        onlyPermitted
    {
        if (
            i_ActivityContract.getMemberDetails(_assignee).forActivity !=
            _activityID
        ) revert Task__AssigneeNotMember();

        require(
            _creditScoreReward > 0,
            "Reward amount must be greater than zero"
        );

        if (i_ActivityContract.getActivityLevel(_activityID) > 2) {
            require(msg.value > 0, "Reward money must be greater than zero");
        }

        uint dueDate = block.timestamp + (_dueInDays * 1 days);
        Tasks[_activityID].push(
            Task(
                userAddress,
                _assignee,
                _title,
                _description,
                _rewardInD,
                dueDate,
                _creditScoreReward,
                false,
                block.timestamp,
                msg.value
            )
        );
    }

    /**
     * @notice - `completeTask` is the function called when the owner assures that the assigned task is completed.
     * @dev - `onlyActivityOwners`, `doesActivityExist`, Events emitted - `TaskCompleted`
     * @param _activityID - Activity ID for the task
     * @param _taskID - Task ID for the
     */
    function completeTask(
        uint256 _activityID,
        uint256 _taskID,
        address userAddress
    )
        public
        doesActivityExist(_activityID)
        onlyActivityOwners(_activityID, userAddress)
        onlyPermitted
    {
        Task[] storage task = Tasks[_activityID];
        Task storage taskToComplete = task[_taskID - 1];
        require(taskToComplete.completed == false, "Task already completed");
        if (block.timestamp > taskToComplete.dueDate) {
            checkTask(taskToComplete);
        }
        i_UserRegistrationContract.addUserCredits(
            taskToComplete.assignee,
            taskToComplete.creditScoreReward
        );
        uint256 taxAmount = retrieveTaxAmountForTask(
            taskToComplete.rewardValue
        );
        uint256 amountToPay = taskToComplete.rewardValue - taxAmount;
        (bool taxPaid, ) = payable(i_owner).call{value: taxAmount}("");
        (bool sent, ) = payable(taskToComplete.assignee).call{
            value: amountToPay
        }("");
        taskToComplete.completed = true;
        require(sent && taxPaid, "Failed to send ETH");
    }

    function checkTask(Task storage _task) internal {
        uint256 overdueDays = (block.timestamp - _task.dueDate) / 86400;
        uint256 amountToDeduct = (overdueDays * _task.rewardValue) / 30;
        uint256 creditScoreToDeduct = (overdueDays * _task.creditScoreReward) /
            30;
        _task.rewardValue -= amountToDeduct;
        _task.creditScoreReward -= creditScoreToDeduct;
    }

    function getActivityTasks(
        uint256 _activityID
    ) public view returns (Task[] memory) {
        return Tasks[_activityID];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract UserRegistrationContract {
    address private immutable i_owner;
    mapping(address => uint256) public UserIdToCredits;
    mapping(address => bool) public UserRegistration;
    mapping(address => bool) public AddressesPermittedToAccess;
    uint256 userCount;

    constructor() {
        i_owner = msg.sender;
        AddressesPermittedToAccess[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only owner can call this function");
        _;
    }

    modifier onlyPermitted() {
        require(
            AddressesPermittedToAccess[msg.sender],
            "Only permitted addresses can call this function"
        );
        _;
    }

    function addPermittedAddress(address permittedAddress) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = true;
    }

    function removePermittedAddress(
        address permittedAddress
    ) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = false;
    }

    function registerUser(address userAddress) external {
        require(!UserRegistration[userAddress], "User already registered");
        UserIdToCredits[userAddress] = 100;
        UserRegistration[userAddress] = true;
        userCount++;
    }

    function getUserCredits(address user) external view returns (uint256) {
        require(UserRegistration[user], "User not registered");
        return UserIdToCredits[user];
    }

    function isUserRegistered(address user) external view returns (bool) {
        return UserRegistration[user];
    }

    function addUserCredits(
        address user,
        uint256 credits
    ) external onlyPermitted {
        require(UserRegistration[user], "User not registered");
        UserIdToCredits[user] += credits;
    }

    function getUserCount() external view returns (uint256) {
        return userCount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../Activity/ActivityContract.sol";
import "../Registration/Registration.sol";
import "../PriceConvertor/PriceConvertor.sol";

// Interfaces, Libraries, Contracts
interface IDonationContract {
    struct Funder {
        address sender;
        uint256 userPublicID;
        uint256 donationAmount;
    }

    function donateToActivity(
        uint256 _activityID,
        uint256 _userPublicID,
        address userAddress
    ) external payable;

    function withdrawSelectiveMoney(
        uint256 _activityID,
        uint256 _amount,
        address userAddress
    ) external;

    function withdrawAllMoney(
        uint256 _activityID,
        address userAddress
    ) external;

    function getActivityFunders(
        uint256 _activityID
    ) external view returns (Funder[] calldata);

    function doesAddressHavePermission() external view returns (bool);
}

contract MinervaDonationContract {
    using PriceConvertorLibrary for uint256;
    address private immutable i_owner;
    address private immutable i_priceFeedContractAddress;
    MinervaActivityContract private i_MinervaActivityContract;
    UserRegistrationContract private i_UserRegistrationContract;
    mapping(address => bool) public AddressesPermittedToAccess;

    constructor(
        address _MinervaActivityContract,
        address _UserRegistration,
        address priceFeedContractAddress
    ) {
        i_MinervaActivityContract = MinervaActivityContract(
            _MinervaActivityContract
        );
        i_UserRegistrationContract = UserRegistrationContract(
            _UserRegistration
        );
        i_priceFeedContractAddress = priceFeedContractAddress;
        i_owner = msg.sender;
        AddressesPermittedToAccess[msg.sender] = true;
    }

    // ------------ Modifiers ------------
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only owner can call this function");
        _;
    }
    /**
     * @notice - This modifier checks if the user is registered
     */
    modifier isRegisteredUser(address sender) {
        require(
            i_UserRegistrationContract.isUserRegistered(sender),
            "User is not registered"
        );
        _;
    }

    modifier onlyPermitted() {
        require(
            AddressesPermittedToAccess[msg.sender],
            "Only permitted addresses can call this function"
        );
        _;
    }

    /*
     * @notice struct for the Funders/Donors for an activity
     */
    struct Funder {
        address sender;
        uint256 userPublicID;
        uint256 donationAmount;
    }

    mapping(uint256 => Funder[]) Funders;

    /**
     * @notice - This event is emitted when a donation is made to an activity
     */
    event DonationMade(
        address _sender,
        uint256 _activityID,
        uint256 _userPublicID,
        uint256 _donationAmount,
        uint256 _timeStamp,
        uint256 _totalDonationReceived
    );

    // ------------ Owner Function ------------
    function addPermittedAddress(address permittedAddress) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = true;
    }

    function removePermittedAddress(
        address permittedAddress
    ) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = false;
    }

    // ------------ Donation Methods ------------
    /**
     * @notice Function to cut taxes off the donation amount
     *
     */
    function retrieveDonatedAmount(
        uint256 _amount
    ) internal pure returns (uint256) {
        uint256 amount;
        require(_amount > 0, "Invalid Amount");
        amount = _amount - ((_amount * 25) / 100);
        return amount;
    }

    /**
     * @dev Modifiers - `isRegisteredUser`, `doesActivityExist`. Events emitted - `DonationMade`
     * @notice Function to allow users to donate to an Activity
     */
    function donateToActivity(
        uint256 _activityID,
        uint256 _userPublicID,
        address userAddress
    ) external payable isRegisteredUser(userAddress) onlyPermitted {
        if (!i_MinervaActivityContract.doesActivityExist(_activityID))
            revert Activity_NotFound();
        require(msg.value > 0, "Donation amount must be greater than 0");
        uint256 actualAmount = retrieveDonatedAmount(msg.value);
        uint256 taxAmount = msg.value - actualAmount;
        i_MinervaActivityContract.receiveDonationForActivity(
            _activityID,
            msg.value,
            actualAmount
        );
        Funders[_activityID].push(
            Funder(userAddress, _userPublicID, msg.value)
        );
        (bool sent, ) = payable(i_owner).call{value: taxAmount}("");
        uint256 credits = actualAmount.getConversionRate(
            i_priceFeedContractAddress
        ) * 10;
        i_UserRegistrationContract.addUserCredits(userAddress, credits);
        require(sent, "Failed to send ETH");
    }

    /**
     * @dev Modifiers - `doesActivityExist`, `onlyActivityOwners`. Events emitted - `MoneyWithdrawn`
     * @notice Function to allow Activity owners to withdraw selective amount of money from their Activity
     */
    function withdrawSelectiveMoney(
        uint256 _activityID,
        uint256 _amount,
        address userAddress
    ) external onlyPermitted {
        if (!i_MinervaActivityContract.doesActivityExist(_activityID))
            revert Activity_NotFound();
        require(
            i_MinervaActivityContract.isActivityOwner(_activityID, userAddress),
            "You are not the owner"
        );
        require(
            i_MinervaActivityContract.getDonationBalanceForActivity(
                _activityID
            ) >= _amount,
            "Insufficient funds"
        );
        (bool sent, ) = payable(userAddress).call{value: _amount}("");
        i_MinervaActivityContract.withdrawDonationMoneyFromActivity(
            _activityID,
            _amount
        );
        require(sent, "Failed to send ETH");
    }

    /**
     * @dev Modifiers - `doesActivityExist`, `onlyActivityOwners`. Events emitted - `MoneyWithdrawn`
     * @notice Function to allow Activity owners to withdraw all the money from their Activity
     */
    function withdrawAllMoney(
        uint256 _activityID,
        address userAddress
    ) public onlyPermitted {
        if (!i_MinervaActivityContract.doesActivityExist(_activityID))
            revert Activity_NotFound();
        require(
            i_MinervaActivityContract.isActivityOwner(_activityID, userAddress),
            "You are not the owner"
        );
        require(
            i_MinervaActivityContract.getDonationBalanceForActivity(
                _activityID
            ) > 0,
            "Insufficient funds"
        );
        uint256 amount = i_MinervaActivityContract
            .getDonationBalanceForActivity(_activityID);
        (bool sent, ) = payable(userAddress).call{value: amount}(
            "Money Withdrawn"
        );
        i_MinervaActivityContract.withdrawDonationMoneyFromActivity(
            _activityID,
            amount
        );
        require(sent, "Failed to send ETH");
    }

    /**
     * @notice Function to get the details of a Funder
     */
    function getActivityFunders(
        uint256 _activityID
    ) external view returns (Funder[] memory) {
        return Funders[_activityID];
    }

    function doesAddressHavePermission() external view returns (bool) {
        return AddressesPermittedToAccess[msg.sender];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertorLibrary {
    function getPrice(
        address _priceFeedAddress
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _priceFeedAddress
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount,
        address _priceFeedAddress
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeedAddress);
        uint256 ethAmountInUsd = (ethPrice * ethAmount);
        return ethAmountInUsd / 1e36;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}