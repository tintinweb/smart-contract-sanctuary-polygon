/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author DeTask team
/// @title Interface to access the TaskRewardTreasuryConfig smart contract in the blockchain
interface ITaskRewardTreasuryConfig {
    function calcFee(uint _value, uint _percent) external pure returns(uint256);
    function getTreasuryFeePercent(address _sender) external view returns (uint256);
    function getTreasuryFeeValue(uint _value, address _sender) external view returns (uint256);
    function getTreasuryAddress() external view returns (address);
    function getAffiliateCommision(address _affiliate) external view returns (uint8);
    function canArbitrate(address _sender) external view returns (bool);
}

/// @author DeTask team
/// @title The configuration was created to adjust fees and manage affiliate, partner, and treasury addresses when creating a task
contract TaskRewardTreasuryConfig {
    ///Address responsable for administrate the smart contract data
    address private owner;
    ///The percentage that will be charged on each task
    uint256 private treasuryFee;
    ///ADO address that will receive the task fees
    address private treasuryAddress;
    ///Affiliated commission fee. The fee will be deducted from the DeTask fee
    mapping(address => uint8) private affiliateCommision;
    ///Partner addresses that will pay a different fee
    mapping(address => uint256) private partnerFee;
    ///Partner related to an address
    mapping(address => address) private partners;
    //Arbitrators that has power over tasks
    mapping(address => bool) private arbitrators;

    ///Public events on the blockchain
    event TreasuryChanged(address indexed _approver, address _treasuryAddress, uint256 _treasuryFee, uint256 indexed _date);
    event SetupAffiliateCommission(address indexed _sender, address _affiliate, uint8 _commission, uint256 indexed _date);
    event SetupPartnerFee(address indexed _sender, address _partner, uint256 _fee, uint256 indexed _date);
    event SetupArbitrators(address indexed _sender, address _arbitrator, bool _permission, uint256 indexed _date);
    event AddPartner(address indexed _sender, address _partner, address _wallet, uint256 indexed _date);

    modifier restricted() {
        require(msg.sender == owner, "Only owner can change config!");
        _;
    }

    constructor() {
        owner = msg.sender;
        treasuryFee = 4;
        treasuryAddress = 0xaC1bf0bCf59Dd336269a7905aA3143aD75988f73;
    }

    /** @notice Change the ADO treasury address
      * @dev Store the address on the variable `treasuryAddress`
      * @param _newAddress The new ADO treasury address value to receive the task’s fee
      */
    function changeTreasuryAddress(address _newAddress) public restricted {
        treasuryAddress = _newAddress;
        emit TreasuryChanged(owner, _newAddress, treasuryFee, block.timestamp);
    }

    /** @notice Change the config fee that is calculated on each task
      * @dev Store the number on the variable `treasuryFee`
      * @param _newFee The new fee value that will be used to charge new tasks
      */
    function changeTreasuryFee(uint256 _newFee) public restricted {
        treasuryFee = _newFee;
        emit TreasuryChanged(owner, treasuryAddress, _newFee, block.timestamp);
    }

    /** @notice Add or update an affiliate address and commission on the config list
      * @dev Store the affiliate address and commision inside the mapping `affiliateCommision`
      * @param _affiliate is the address of a wallet or DAO that will receive the affiliated commission 
      * @param _commission is the affiliate commission percentage number
      */
    function setupAffiliateCommission(address _affiliate, uint8 _commission) public restricted {
        require(_affiliate != address(0), "Affiliate address cannot be zero!");
        affiliateCommision[_affiliate] = _commission;
        emit SetupAffiliateCommission(msg.sender, _affiliate, _commission, block.timestamp);
    }

    /** @notice Add or update a partner address and fee on the config list
      * @dev Store the partner address and fee inside the mapping `partnerFee`
      * @param _partner is the address of a wallet that will receive a special fee during a task creation 
      * @param _fee is the partner special fee percentage number
      */
    function setupPartnerFee(address _partner, uint256 _fee) public restricted {
        require(_partner != address(0), "Partner address cannot be zero!");
        partnerFee[_partner] = _fee;
        emit SetupPartnerFee(msg.sender, _partner, _fee, block.timestamp);
    }

    /** @notice Add or update a arbitrator address
      * @dev Store the arbitrator address and permission inside the mapping `arbitrators`
      * @param _arbitrator is the address of a wallet that will arbitrate some tasks function 
      * @param _permission is the permission arbitrate
      */
    function setupArbitrator(address _arbitrator, bool _permission) public restricted {
        require(_arbitrator != address(0), "Partner address cannot be zero!");
        arbitrators[_arbitrator] = _permission;
        emit SetupArbitrators(msg.sender, _arbitrator, _permission, block.timestamp);
    }

    /** @notice Add a partner to an address
      * @dev Store the partner to the mapping `partners`
      * @param _partner is the address that be associated with an wallet
      * @param _sender is the user wallet
      */
    function addPartner(address _partner, address _sender) public restricted {
        require(_partner != address(0), "Partner address cannot be zero!");
        require(_sender != address(0), "Sender address cannot be zero!");
        partners[_sender] = _partner;
        emit AddPartner(msg.sender, _partner, _sender, block.timestamp);
    }

    /** @notice Calculate the fee that will be used on the task
      * @dev Verify if the partner is valid and calculate the appropriate fee for the task
      * @param _partner The wallet address of the manager who is creating the task
      * @return the fee number value
      */
    function calculateFeePercent(address _partner) private view returns(uint256){
        if (_partner == address(0)){
            return treasuryFee;
        }
        else{
            uint256 fee = partnerFee[_partner];
            if (fee == 0)
            {
                return treasuryFee;
            }
            else
            {
                return fee;
            }
        }
    }

    /** @notice Calculate the percentage of a giving number
      * @dev Calculate a percentage of a number
      * @param _value the number you want to calculate the percentage
      * @param _percent the percentage you want to calculate
      * @return The calculated percentage value o a number 
      */
    function calculateTreasuryFee(uint _value, uint _percent) private pure returns(uint256){
        return _value * _percent / 10000;
    }

    /** @notice Calculate the fee that will be used on the task
      * @dev Verify if the partner is valid and calculate the appropriate fee for the task
      * @param _value the value the fee will be calculated
      * @param _sender The wallet address of the manager who is creating the task
      * @return the fee number value
      */
    function getTreasuryFeeValue(uint _value, address _sender) external view returns (uint256) {
      uint256 fee = calculateFeePercent(partners[_sender]);
      return calculateTreasuryFee(_value, fee);
    }

    /** @notice Retrieve the fee that will be used on the task
      * @dev call the function `calculateFeePercent`
      * @param _sender The wallet address of the manager who is creating the task
      * @return the fee number value
      */
    function getTreasuryFeePercent(address _sender) external view returns (uint256) {
        return calculateFeePercent(partners[_sender]);
    }

    /** @notice Calculate the percentage of a giving number
      * @dev Calculate a percentage of a number
      * @param _value the number you want to calculate the percentage
      * @param _percent the percentage you want to calculate
      * @return The calculated percentage value o a number 
      */
    function calcFee(uint _value, uint _percent) external pure returns(uint256){
        return calculateTreasuryFee(_value, _percent);
    }

    /** @notice Get the current DAO treasury address
      * @dev retrieves the value of the variable `treasuryAddress`
      * @return the treasury address value
      */
    function getTreasuryAddress() external view returns (address) {
        return treasuryAddress;
    }

    /** @notice Get an affiliate commission percentage fee
      * @dev retrieves the number out of the mapping `affiliateCommision`
      * @param _affiliate is the address of a wallet or DAO 
      * @return the commission number value of an affiliate
      */
    function getAffiliateCommision(address _affiliate) external view returns (uint8) {
        return affiliateCommision[_affiliate];
    }

    /** @notice Get a partner fee
      * @dev retrieves the number out of the mapping `partnerFee`
      * @param _partner is the address of a wallet
      * @return the fee number value of a partner
      */
    function getPartnerFee(address _partner) external view returns (uint256) {
        return partnerFee[_partner];
    }

    /** @notice Get a partner address
      * @dev retrieves the partner address from mapping `partners`
      * @param _sender is the address of a user wallet
      * @return the partner address
      */
    function getPartner(address _sender) external view returns (address) {
        return partners[_sender];
    }

    /** @notice Check if the sender can arbitrate
      * @dev retrieves the arbitrate address from mapping `arbitrators`
      * @param _sender is the address of a user wallet
      * @return a if the address can arbitrate
      */
    function canArbitrate(address _sender) external view returns (bool) {
        return arbitrators[_sender];
    }

    /** @notice Return the data from the contract
      * @dev Retrieves a list of variables from the contract
      * @return owner is the address of who creates the contract
      * @return treasuryAddress is the address of the treasury that will receive the task's fee
      * @return treasuryFee is the number in percentage that a task should pay when approved 
      */
    function getSummary() public view returns (address, address, uint256) {
        return (
          owner,
          treasuryAddress,
          treasuryFee
        );
    }
    
}

/// @author DeTask team
/// @title This DAO smart contract was created to save all fees paid from the tasks and trades
/// @notice Only authorized address can request withdraw from this treasury DAO and must have 50% approval to complete the transaction 
contract TaskRewardTreasury {
    ///Used to store withdraw request information    
    struct Request {
        ///Withdraw description
        string description;
        ///Withdraw value that will be transferred from the ADO 
        uint value;
        ///Destination wallet address
        address recipient;
        ///Flag to inform if the request was already completed
        bool complete;
        ///How many address approve the request
        uint approvalCount;
        ///List of addresses that vote to approve or disapprove the request 
        mapping(address => bool) approvals;
    }

    ///Address that creates the treasury. Only this address can add or remove provers.
    address private owner;
    ///List of all requests created
    mapping (uint => Request) public requests;
    ///Total number of requests created
    uint private requestsCount;
    ///List of addresses that can vote to approve a request
    mapping(address => bool) public approvers;
    ///Total number of approvers
    uint private approversCount;

    //This generates a public event on the blockchain on task update
    event AddApprovers(address indexed _approver, uint256 indexed _date);
    event DeleteApprovers(address indexed _approver, uint256 indexed _date);
    event Deposited(address indexed _sender, uint _amount, uint256 indexed _date);
    event RequestCreated(address indexed _sender, uint indexed _id, uint256 indexed _date);
    event RequestApproved(address indexed _sender, uint indexed _id, uint256 indexed _date);
    event RequestFinalized(address indexed _sender, uint indexed _id, uint256 indexed _date);


    modifier restricted() {
        require(msg.sender == owner, "Only owner can add approvers!");
        _;
    }

    modifier approvereds() {
        require((msg.sender == owner) || (approvers[msg.sender]), "Only owner and approvers can request withdraw!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /** @notice This function enable this contract to receive money from Task or any other source 
      */
    receive() external payable {
      emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /** @notice Add a wallet address to vote for the new requests
      * @dev Add an address to the mapping `approvers` and increment the numeric `approversCount`
      * @param _approver the wallet address of the voter who will be able to vote in a withdraw request
      */
    function addApprover(address _approver) public restricted {
        approvers[_approver] = true;
        approversCount++;

        emit AddApprovers(_approver, block.timestamp);
    }

    /** @notice Disable a wallet address to vote for the new requests
      * @dev Flag false the approver’s address in the mapping `approvers` and decrement the numeric `approversCount`
      * @param _approver The wallet address of the voter who will not be able to vote anymore in a withdraw request
      */
    function removeApprover(address _approver) public restricted {
        approvers[_approver] = false;
        approversCount--;

        emit DeleteApprovers(_approver, block.timestamp);
    }

    /** @notice Add a new withdraw request
      * @dev Increment the number of requests with the numeric `requestsCount`. Create a new request record and add on the mapping `requests` 
      * @param description The text explaining the reason the money should be withdrawn from the treasury
      * @param value The numeric amount of withdraw
      * @param recipient The wallet address that will receive the money 
      */
    function createRequest(string memory description, uint value, address recipient) public approvereds {
        Request storage r = requests[requestsCount++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;

        emit RequestCreated(msg.sender, requestsCount, block.timestamp);
    }

    /** @notice Vote to approve a request by index
      * @dev Locate the request by index on the mappin `requests`. Set true, approve request,  the address on the `requests` list and increment the number `approvalCount` on the `requests`
      * @param index The number that identify a request on the mappin
      */
    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender], "Only approvers can approve the request");
        require(!request.approvals[msg.sender], "Address already approved the request");

        request.approvals[msg.sender] = true;
        request.approvalCount++;

        emit RequestApproved(msg.sender, index, block.timestamp);
    }

    /** @notice Validate if the majority approves the request and send the money to the destination recipient address
      * @dev Locate the request by index on the mappin `requests`. Verify if the request has more than 50% approval. Transfer the `request` money numeric field `value` to a destination address `recipient`, and update the `request` boolean field `complete` as true
      * @param index The number that identify a request on the mappin
      */
    function finalizeRequest(uint index) public approvereds {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2), "Not enought approval to finish the request");
        require(!request.complete, "Request was already finished");

        (bool success, ) = payable(request.recipient).call{value: request.value}("");
        require(success, "Transfer failed.");
        request.complete = true;

        emit RequestFinalized(msg.sender, index, block.timestamp);
    }
    
    /** @notice Return the summary data from the contract
      * @dev Retrieves a list of variables from the contract
      * @return balance is the numeric total money stored on the smart contract
      * @return requestsCount is the numeric total requests created on the smart contract
      * @return approversCount is the numeric total addresses added to approve requests on the smart contract
      * @return owner the address that creates the smart contract and responsible to add approvers
      */    
    function getSummary() public view returns (
      uint, uint, uint, address
      ) {
        return (
          address(this).balance,
          requestsCount,
          approversCount,
          owner
        );
    }

    /** @notice Get the total requests created on the smart contract
      * @dev return the number of the field `requestsCount`
      * @return requestsCount is the numeric total requests created on the smart contract
      */
    function getRequestsCount() public view returns (uint) {
        return requestsCount;
    }
}

/// @author DeTask team
/// @title Use this contract to administrate and access all tasks created in the blockchain
/// @notice Task's owners and affiliates can filter all tasks associated to them 
contract TaskFactory {
    ///Address that creates the factory. Only this address can change data in this smart contract
    address private owner;
    ///The address that points to the Treasury Configuration. The configuration has all fees, affiliate, and partner value
    address private treasuryConfig;
    ///The address that points to the main empty task created on the block chain. The empty task will be used to generate a clone and avoid high fees
    address private masterContract;
    ///Array of all tasks deployed on the factory smart contract
    address[] private deployedTasks;
    ///Total number deployed tasks
    uint256 private totalDeployedTasks;
    ///Store all tasks created for an affiliate address
    mapping(address => address[]) private affiliateTasks;
    ///Total number of tasks created to an affiliate
    mapping(address => uint256) private totalAffiliateTasks;
    ///Store all tasks created for a manager address or job creator
    mapping(address => address[]) private managerTasks;
    ///Total number of tasks created to a manager
    mapping(address => uint256) private totalManagerTasks;

    modifier restricted() {
        require(msg.sender == owner, "Only the Owner can change or call the Factory Contract!");
        _;
    }

    constructor(address _masterContract, address _treasuryConfig){
        owner = msg.sender;
        masterContract = _masterContract;
        treasuryConfig = _treasuryConfig;
    }

    /** @notice Create a new task and add on the factory
      * @dev Clone the master task address `masterContract` from the block chain. Add the new task on the factory array `deployedTasks` and increment the numeric field `totalDeployedTasks`.  Add the new task to the manager array inside the mapping `managerTasks` and increment the mapping numeric field `totalManagerTasks`. If there is a valid affiliated address, add the new task to the array inside the mapping `affiliateTasks` and increment the numeric field `totalAffiliateTasks` . Call the setup method `setTaskConfig` for the new task to store and calculate the fees. Call `init` to initialize the task and transfer the balance to the task.
      * @param _affiliate the affiliate address that may receive a commission when the task is completed
      * @param _parentTask the manager wallet address that may have a special fee loaded from the configuration smart contract
      * @param _category is the task's tag
      * @param _description is the task's description used and agreement between the owner and specialist. It should contain the detailed information about the task’s job
      * @param _developer is the specialist's waller address that will receive the payment
      * @param _regularReward is the amount the specialist will receive when complete the task
      * @param _regularDueTime the time the task should be completed
      * @param _speederDueTime the speeder time the task should be completed
      * @param _dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @param _publicDescription specifies if the description can be visible for anyone. If false, only the owner and specialist can see the information on the description field
      * @param _title is the task's title that is visible for anyone
      */
    function createTask(address _affiliate, address _parentTask, string memory _category, string memory _description, address _developer, uint256 _regularReward, uint16 _regularDueTime, uint16 _speederDueTime, uint8 _dueTimeType, bool _publicDescription, string memory _title) external payable {
        require(masterContract != address(0), "Master contract is not register!");
        address newTask = address(Task(createClone(masterContract)));
        deployedTasks.push(newTask);
        managerTasks[msg.sender].push(newTask);
        totalManagerTasks[msg.sender] += 1;
        totalDeployedTasks += 1;
        if (_affiliate != address(0))
        {
            affiliateTasks[_affiliate].push(newTask);
            totalAffiliateTasks[_affiliate] += 1;
        }
        Task(newTask).setTaskConfig(treasuryConfig, msg.sender, _affiliate, _parentTask);
        Task(newTask).init{value: msg.value}(_category, _description, _developer, _regularReward, _regularDueTime, _speederDueTime, msg.sender, _dueTimeType, _publicDescription, _title);
    }

    /** @notice Create a clone from an existing address on the block chain. This function reduce the block chain fee in 90% compared to the `create` smart contract function 
      * @dev Search for an existing contract address and make a clone for it. Deploys and returns the address of a clone that mimics the behavior of `implementation`.
      * @param target the address we want to clone from the block chain
      * @return result the new address that was cloned
      */
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    /** @notice Get the list of task address deployed in the factory
      * @dev return the array address of the field `deployedTasks`
      * @return all address save on the array `deployedTasks`
      */
    function getDeployedTasks() public view returns(address[] memory){
        return deployedTasks;
    }

    /** @notice Get the total number of tasks created in the factory 
      * @dev return the number of the field `totalDeployedTasks`
      * @return totalDeployedTasks is the numeric total tasks created on the factory
      */
    function getTotalDeployedTasks() public view returns(uint256){
        return totalDeployedTasks;
    }

    /** @notice Retrieve the task by an specific index 
      * @dev return the address of a task on the array `deployedTasks`
      * @param _index The number that identify a task on the array
      * @return the task address located in the array `deployedTasks`
      */
    function getDeployedTasksByIndex(uint _index) public view returns(address){
        return deployedTasks[_index];
    }

    /** @notice Get the total number of tasks by manager wallet address
      * @dev return the number of tasks from mapping `totalManagerTasks`
      * @param _manager is a wallet address to get the total task created for it
      * @return The numeric total tasks by manager
      */
    function getTotalDeployedTasksByManager(address _manager) public view returns(uint){
        return totalManagerTasks[_manager];
    }

    /** @notice Get the list of task addresses by manager
      * @dev return the array of address inside the mapping `managerTasks` by manager wallet address
      * @param _manager is a wallet address to get the associated list of tasks
      * @return The list of task addresses stored by manager
      */
    function getDeployedTasksByManager(address _manager) public view returns(address[] memory){
        return managerTasks[_manager];
    }

    /** @notice Get the total number of tasks by affiliate wallet address
      * @dev return the number of tasks from mapping `totalAffiliateTasks`
      * @param _affiliate is a wallet address to get the total task created for it
      * @return The numeric total tasks by affiliate
      */
    function getTotalDeployedTasksByAffiliate(address _affiliate) public view returns(uint){
        return totalAffiliateTasks[_affiliate];
    }

    /** @notice Get the list of task addresses by affiliate
      * @dev return the array of address inside the mapping `affiliateTasks` by affiliate wallet address
      * @param _affiliate is a wallet address to get the associated list of tasks
      * @return The list of task addresses stored by affiliate
      */
    function getDeployedTasksByAffiliate(address _affiliate) public view returns(address[] memory){
        return affiliateTasks[_affiliate];
    }

    /** @notice Retrieve the task address by manager address and index
      * @dev return a task address from the mapping `managerTasks` by address and array index   
      * @param _manager is a wallet address to get the list of tasks
      * @param _index is the task position inside the array
      * @return A task address
      */
    function getDeployedTaskByManagerAndIndex(address _manager, uint _index) public view returns(address){
        return managerTasks[_manager][_index];
    }

    /** @notice Return the address of the task master contract used to create a clone
      * @dev get the task master address contract field `masterContract`
      * @return The task master contract
      */
    function getMasterContract() public view restricted returns(address){
        return masterContract;
    }

    /** @notice Retrieve the current treasury fee
      * @dev return the numerical fee from the Treasury Configuration through the interface `ITaskRewardTreasuryConfig`  
      * @param _partner is the partner wallet address that may have a special fee
      * @return The fee that will be paid by the user
      */
    function getTreasuryFeePercent(address _partner) public view returns(uint256){
        return ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryFeePercent(_partner);
    }

    /** @notice Retrieve the current treasury fee
      * @dev return the numerical fee from the Treasury Configuration through the interface `ITaskRewardTreasuryConfig`  
      * @param _sender is the wallet address that may have a special fee
      * @return The fee that will be paid by the user
      */
    function getTreasuryFeeValue(uint _value, address _sender) public view returns(uint256){
        return ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryFeeValue(_value, _sender);
    }

    /** @notice Return the address of the owner that creates the factory
      * @dev get the owner address that create the contract field `owner`
      * @return The address of factory the contract owner
      */
    function getOwner() public view returns(address){
        return owner;
    }

    /** @notice Return the address of the treasury configuration that has the tasks fees, affiliate commission, and partner fee discount
      * @dev get the treasury address that calculates the task fees field `treasuryConfig`
      * @return The address of the treasury configuration
      */
    function getTreasuryConfig() public view restricted returns(address){
        return treasuryConfig;
    }

    /** @notice Update the master contract task address with a new address
      * @dev Update the master contract task address in the field `masterContract`
      * @param _newMasterContract is the address of an empty task publicated on the block chain 
      */
    function setMasterContract(address _newMasterContract) public restricted {
        masterContract = _newMasterContract;
    }

    /** @notice Update the treasury address with a new address
      * @dev Update the treasury address in the field `treasuryConfig`
      * @param _newTreasuryConfig is the address of a new treasure configuration that has the tasks fees, affiliate commission, and partner fee discount
      */
    function setTreasuryConfig(address _newTreasuryConfig) public restricted {
        treasuryConfig = _newTreasuryConfig;
    }

    /** @notice Return balance of the Factory 
      * @dev get the actual balance of the Factory. This balance should be always zero because the factory transfer all balance to the task during the create method
      * @return balance of the Factory
      */
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

}

/// @author DeTask team
/// @title Contract used to store information such as payment, due date, and job description that was negotiated between a manager and a specialist 
contract Task {

    ///Status type
    uint8 private constant STATUS_CREATED = 0;
    uint8 private constant STATUS_STARTED = 1;
    uint8 private constant STATUS_COMPLETED = 2;
    uint8 private constant STATUS_APPROVED = 3;
    uint8 private constant STATUS_CANCELED = 4;
    uint8 private constant STATUS_CANCEL_ARBITRATE = 5;
    /// Time calculation type (Days or Hours)
    uint8 private constant TASK_BY_HOUR = 0;
    uint8 private constant TASK_BY_DAY = 1;

    //Task’s owner waltet address
    address private manager;
    ///Specialist’s waltet address who will execute the task 
    address private developer;
    ///Descriptive info about what should be execute in the task
    string private title;
    string private category;
    ///If false, the description will be visible only to the manager and specialist
    bool private publicDescription;
    string private description;
    ///Amount of money the manager should pay to the specialist when complete the task prior the express time
    uint256 private speederReward;
    ///Amount to be paid if the express time expire
    uint256 private regularReward;
    ///Total amount already anticipated to the specialist
    uint256 private anticipatedReward;
    ///Current status of the task
    uint8 private status;
    ///Regular time to complete the task
    uint16 private regularDueTime;
    ///Express time to complete the task get the extra reward
    uint16 private speederDueTime;
    ///Type of due time for the task (Hour or Days)
    uint8 private dueTimeType;
    ///Dates to control the task
    uint256 private startDate;
    uint256 private endDate;
    ///Rate the task's completion job. Number from 1 to 5
    uint8 private developerRate;
    uint8 private managerRate;
    ///Treasury info
    address private treasuryAddress;
    uint256 private treasuryFee;
    uint256 private treasuryFeeValue;
    ///Treasury Config
    address private treasuryConfig;
    ///Task relation
    address private parentTask;
    ///Task Affiliate info 
    address private affiliateAddress;
    uint8 private affiliateCommission;
    uint256 private affiliateCommissionValue;
    ///Task partner info 
    address private partnerAddress;
    //Enable contract arbitration option
    bool private arbitration;
    //Developer agreement to arbitrate
    bool private arbitrationAgreed;
    //Undo status prior the arbitration
    uint8 private statusPriorArbitrate;

    //********** TASK LOG EVENTS **********
    //This generates a public event on the blockchain on task update
    event DeveloperChanged(address indexed _old, address indexed _new, uint256 indexed _date);
    event RewardAdded(address _from, uint256 indexed _reward, uint256 indexed _date);
    event DueTimeChanged(uint16 indexed _old, uint16 indexed _new, uint256 indexed _date);
    event RateAdded(address indexed _from, uint8 indexed _rate, string _reason, uint256 indexed _date);
    event ParentTaskChanged(address indexed _manager, address indexed _old, address _new, uint256 indexed _date);
    event PublicDescriptionChanged(address indexed _manager, bool indexed _public, uint256 indexed _date);
    event DescriptionChanged(address _manager, string  _reason, uint256 indexed _date);
    event CategoryChanged(address _manager, string _old, string _new, uint256 indexed _date);
    event TitleChanged(address _manager, string _old, string _new, uint256 indexed _date);
    event ArbitrationChanged(address _manager, bool _enable, uint256 indexed _date);
    event ArbitrationAgreed(address _developer, bool _agree, uint256 indexed _date);
    //This generates a public event on the blockchain for task status
    event Created(address indexed _manager, uint256 indexed _date);
    event Started(address indexed _manager, uint256 indexed _date);
    event Completed(address indexed _developer, uint256 indexed _date);
    event UndoCompleted(address indexed _developer, string _reason, uint256 indexed _date);
    event Approved(address indexed _manager, address indexed _developer, uint256 _reward, uint256 indexed _date);
    event Canceled(address indexed _manager, address indexed _developer, string _reason, uint256 _refund, uint256 indexed _date);
    event Arbitrate(address indexed _arbitrate, string _reason, bool _approve, uint256 indexed _date);
    event RequestArbitration(address indexed _manager, string _reason, uint256 indexed _date);
    event AnticipatedReward(address indexed _developer, uint256 _value, string _reason, uint256 indexed _date);
    //Treasury Events
    event PaidTreasuryFee(address indexed _address, uint256 _fee, uint256 _value, uint256 indexed _date);
    event PaidAffiliateCommission(address indexed _address, uint256 _commission, uint256 _value, uint256 indexed _date);

    //********** RULES TO CHANGE THE TASK **********
    modifier restricted() {
        require(msg.sender == manager, "Only the manager can change the task!");
        _;
    }

    modifier notStarted() {
        require(status == STATUS_CREATED, "This task was already started and can not be updated!");
        _;
    }

    modifier isStarted() {
        require(status == STATUS_STARTED, "This task is not started!");
        _;
    }

    modifier isCompleted() {
        require(status == STATUS_COMPLETED, "This task is not completed!");
        _;
    }

    modifier isApproved() {
        require(status != STATUS_APPROVED, "This task is already approved!");
        _;
    }

    modifier isApprovedOrCanceled() {
        require((status == STATUS_APPROVED) || (status == STATUS_CANCELED), "This task is not approved or canceled!");
        _;
    }

    modifier validateDeveloper() {
        require(developer != address(0), "There is not developer for this task!");
        require(developer == msg.sender, "You are not the developer for this task!");
        _;
    }

    modifier hasReward(){
        require(address(this).balance > 0, "There is not reward for this contract!");
        _;
    }

    modifier isArbitrated() {
        require(arbitration == true, "This task is not arbitrated!");
        _;
    }

    modifier arbitrationApproved() {
        require((arbitration == false) || ((arbitration == true) && (arbitrationAgreed == true)), "Task needs to approve arbitration!");
        _;
    }

    modifier canArbitrate() {
        require((status == STATUS_CANCEL_ARBITRATE) && (ITaskRewardTreasuryConfig(treasuryConfig).canArbitrate(msg.sender)), "This task is not arbitrated or address does not have permission to arbitrate!");
        _;
    }

    //********** FUNCTIONS FOR TREASURY **********
    /** @notice Calculate if the task has a fee
      * @dev Verify if the task has fee to avoid error during the payment
      * @return True if the task has any fee
      */    
    function shouldTakeFee() private view returns(bool){
        return ((treasuryAddress != address(0)) && (treasuryFeeValue > 0) && (treasuryFeeValue < address(this).balance));
    }

    /** @notice Transfer the fee from the task to the affiliate and treasury
      * @dev Verify if there is a fee to charge using the function `shouldTakeFee`. Check if the affiliate has commission `affiliateCommission`.  The affiliate commision will be calculated and transferred after deducted from the treasure fee. The treasure fee `treasuryFeeValue` will be calculated and transferred deducting the `affiliateCommission`.
      */    
    function transferTreasuryFee() private {
        //Transfer fee to treasury
        if (shouldTakeFee() == true){

            uint256 affiliateValue = 0;

            if (affiliateAddress != address(0) || affiliateCommission >= 0)
            {
              if (affiliateCommissionValue == 0)
                affiliateCommissionValue = ITaskRewardTreasuryConfig(treasuryConfig).calcFee(treasuryFeeValue, affiliateCommission);

              affiliateValue = affiliateCommissionValue;
              (bool successA, ) = payable(affiliateAddress).call{value: affiliateValue}("");
              require(successA, "Transfer failed.");
              emit PaidAffiliateCommission(affiliateAddress, affiliateCommission, affiliateValue, block.timestamp);
            } 

            (bool success, ) = payable(treasuryAddress).call{value: (treasuryFeeValue - affiliateValue)}("");
            require(success, "Transfer failed.");
            emit PaidTreasuryFee(treasuryAddress, treasuryFee, (treasuryFeeValue - affiliateValue), block.timestamp);

        }
    }

    /** @notice Get the current DAO treasury address
      * @dev retrieves the value of the variable `treasuryAddress`
      * @return the treasury address value
      */
    function getTreasuryAddress() public view returns(address){
        return treasuryAddress;
    } 

    /** @notice Return the treasury percentage fee for the task
      * @dev retrieves the numeric value of the variable `treasuryFee`
      * @return the treasury fee value
      */
    function getTreasuryFee() public view returns(uint256){
        return treasuryFee;
    } 

    /** @notice Return the treasury fee value for the task
      * @dev retrieves the numeric value of the variable `treasuryFeeValue`
      * @return the treasury fee value
      */
    function getTreasuryFeeValue() public view returns(uint256){
        return treasuryFeeValue;
    } 

    //********** FUNCTIONS TO UPDATE TASK **********
    /** @notice Load and save all the fees and addresses from the configuration smart contract. It is executed as soon as the contract is created
      * @dev Store the data treasury config address at `treasuryConfig`, task owner address at `manager`, treasury address at `treasuryAddress`, task fee at `treasuryFee`, affiliated address and commission at `affiliateAddress` and `affiliateCommission`
      * @param _treasuryAddress the DAO address where the fees will be deposited 
      * @param _managerAddress the owner of the task. Only owner can manipulate the task after creation
      * @param _affiliateAddress the wallet address that will receive a commission over the task fee if the address is setup on the config file
      * @param _parentTask associated with a parent task
      */
    function setTaskConfig(address _treasuryAddress, address _managerAddress, address _affiliateAddress, address _parentTask) public {
        require(treasuryConfig == address(0), "Treasury config already setup!");
        require(manager == address(0), "Manager in the task already setup!");
        treasuryConfig = _treasuryAddress;
        manager = _managerAddress;
        parentTask = _parentTask;
        treasuryAddress = ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryAddress();
        treasuryFee = ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryFeePercent(_managerAddress);
        affiliateAddress = _affiliateAddress;
        affiliateCommission = ITaskRewardTreasuryConfig(treasuryConfig).getAffiliateCommision(_affiliateAddress);
    }

    /** @notice Set the public description visibility. If the flag is false, only the task’s owner and specialist can see the description
      * @dev Update the public description field `publicDescription`
      * @param _publicDescription boolean to set the description public
      */
    function setPublicDescription(bool _publicDescription) public restricted {
        emit PublicDescriptionChanged(msg.sender, _publicDescription, block.timestamp);
        publicDescription = _publicDescription;
    }

    /** @notice Replace the task‘s description
      * @dev Set the new value to the field `description`. This field can only be changed if the task is not started
      * @param _description is the new description
      * @param _reason is a text info explaining why the owner needs to change the description
      */
    function setDescription(string memory _description, string memory _reason) public restricted notStarted{
        emit DescriptionChanged(msg.sender, _reason, block.timestamp);
        description = _description;
    }

    /** @notice Replace the task‘s category
      * @dev Set the new value to the field `category`. This field can only be changed if the task is not started
      * @param _category is the new task's category
      */
    function setCategory(string memory _category) public restricted notStarted{
        emit CategoryChanged(msg.sender, category, _category, block.timestamp);
        category = _category;
    }

    /** @notice Replace the task‘s title
      * @dev Set the new value to the field `title`. This field can only be changed if the task is not started
      * @param _title is the new task's title
      */
    function setTitle(string memory _title) public restricted notStarted{
        emit TitleChanged(msg.sender, title, _title, block.timestamp);
        title = _title;
    }

    /** @notice Update the task‘s arbitration
      * @dev Set the new value to the field `arbitration`. This field can only be changed if the task is not started
      * @param _enable true or false to enable task arbitration
      */
    function createArbitration(bool _enable) public restricted notStarted{
        emit ArbitrationChanged(msg.sender, _enable, block.timestamp);
        arbitration = _enable;
    }

    /** @notice Confirme the task‘s arbitration
      * @dev Developer set the new value to the field `arbitrationAgreed`. This field can only be changed if the task is not started
      * @param _agree true or false to confirm task arbitration
      */
    function agreeArbitration(bool _agree) public validateDeveloper notStarted isArbitrated{
        emit ArbitrationAgreed(msg.sender, _agree, block.timestamp);
        arbitrationAgreed = _agree;
    }

    /** @notice Replace the specialist wallet address
      * @dev Set the new value to the field `title`. This field can only be changed if the task is not started
      * @param _developer si the new developer wallet address
      */
    function setDeveloper(address _developer) public restricted notStarted{
        emit DeveloperChanged(developer, _developer, block.timestamp);
        developer = _developer;
    }

    /** @notice This function creates a relationship with an existing task
      * @dev Set the new value for the field `parentTask`
      * @param _parentTask is the task's address you need to associate the current task
      */
    function setParentTask(address _parentTask) public restricted {
        emit ParentTaskChanged(msg.sender, parentTask, _parentTask, block.timestamp);
        parentTask = _parentTask;
    }

    /** @notice Update the due time the specialist has to complete the task
      * @dev The due time cannot be greater than speeder time. It will set a new value for the variable `regularDueTime`. This field can only be changed if the task is not started
      * @param _regularDueTime the new int value for the field `regularDueTime`
      */
    function setRegurarDueTime(uint16 _regularDueTime) public restricted notStarted{
        require(_regularDueTime > 0, "Regurar Due Day must be greater than zero!");
        require(_regularDueTime >= speederDueTime, "Regurar Due Time cannot be less then Speeder Due Day!");
        emit DueTimeChanged(regularDueTime, _regularDueTime, block.timestamp);
        regularDueTime = _regularDueTime;
    }

    /** @notice Update the due time the specialist has to complete the task faster
      * @dev The faster due time must be greater than regular time. It will set a new value for the variable `speederDueTime`. This field can only be changed if the task is not started
      * @param _speederDueTime the new int value for the field `speederDueTime`
      */
    function setSpeederDueTime(uint16 _speederDueTime) public restricted notStarted{
        require(regularDueTime >= _speederDueTime, "Speeder Due Time cannot be greater than Regular Due Day!");
        require(_speederDueTime > 0, "Speeder Due Day must be greater than zero!");
        emit DueTimeChanged(speederDueTime, _speederDueTime, block.timestamp);
        speederDueTime = _speederDueTime;
    }

    /** @notice This function will add more money to the task
      * @dev Validate if the parameter `_regularReward` is less than the amount received. Add the `regularReward` with the parameter `_regularReward`. Increment the task’s balance with the amount received. Add the amount received to the variable `speederReward`. This function can only run if the task is not started
      * @param _regularReward the amount to be added to the current field `regularReward`
      */
    function addReward(uint256 _regularReward) external payable restricted notStarted{
        require(_regularReward <= msg.value, "Regular reward can not be greater than speeder reward!");
        emit RewardAdded(manager, msg.value, block.timestamp);
        regularReward += _regularReward;
        speederReward += msg.value;
    }

    /** @notice Only the owner can give a score from 1 to 5 to the specialist, and also a reason for the rate.
      * @dev Rate should be from 1 to 5. The rate value will be stored in the variable `developerRate`. A log will be created in the task  with the parameter `_reason`. This function can only be called when the contract is approved or canceled.
      * @param _rate is the integer score from 1 to 5
      * @param _reason is the description that justify the rate
      */
    function rateDeveloper(uint8 _rate, string memory _reason) public restricted isApprovedOrCanceled{
        require((_rate >= 1) && (_rate <= 5), "Rate should be between 1 to 5!");
        require(developerRate == 0, "Developer has a rate already!");
        developerRate = _rate;
        emit RateAdded(manager, _rate, _reason, block.timestamp);
    }

    /** @notice Only the specialist can give a score from 1 to 5 to the owner, and also a reason for the rate. 
      * @dev Rate should be from 1 to 5. The rate value will be stored in the variable `developerRate`. A log will be created in the task  with the parameter `_reason`. This function can only be called when the contract is approved or canceled.
      * @param _rate is the integer score from 1 to 5
      * @param _reason is the description that justify the rate
      */
    function rateManager(uint8 _rate, string memory _reason) public validateDeveloper isApprovedOrCanceled{
        require((_rate >= 1) && (_rate <= 5), "Rate should be between 1 to 5!");
        require(managerRate == 0, "Manager has a rate already!");
        managerRate = _rate;
        emit RateAdded(developer, _rate, _reason, block.timestamp);
    }

    //********** FUNCTIONS TO CREATE ACTIONS ON TASK **********
    /** @notice Transfer partial money from the task to the specialist wallet
      * @dev Anticipation cannot be greater than regular reward. The specialist address must be filled. Transfer the amount informed in the variable `_value` from the task to the specialist wallet, and increase the amount transferred to the variable `anticipatedReward`
      * @param _value is the amount that should be transferred from the task
      * @param _reason is the justification for transferring the amount from the task
      */
    function anticipateReward(uint256 _value, string memory _reason) public restricted hasReward {
        require(_value < (regularReward - anticipatedReward), "Antecipation cannot be greater or equal regular reward!");
        require(developer != address(0), "There is not developer for this task!");

        (bool successDev, ) = payable(developer).call{value: _value}("");
        require(successDev, "Transfer failed.");
        anticipatedReward += _value;
        emit AnticipatedReward(developer, _value, _reason, block.timestamp);
    }

    /** @notice Initiate the job and the clock to complete the task
      * @dev Update the task’s variable status `status` to start. Set the date and time `startDate` of the task to started. The task can only be stated once and there must be a specialist wallet address setup. Only the owner can start the task
      */
    function start() public notStarted restricted hasReward arbitrationApproved{
        status = STATUS_STARTED;
        startDate = block.timestamp;
        emit Started(msg.sender, block.timestamp);
    }

    /** @notice Update the task status from started to completed
      * @dev Update the task’s variable status `status` to completion. Set the date and time `endDate` the task completed. Only the specialist can set the task as completed
      */
    function complete() public isStarted validateDeveloper{
        status = STATUS_COMPLETED;
        endDate = block.timestamp;
        emit Completed(developer, block.timestamp);
    }

    /** @notice This function invalidate the specialist job task completion
      * @dev Update the task’s variable status `status` to start again. Reset the date and time `endDate` to zero. Log the specification from the parameter `_reason` explaining why the task was not approved. Only the owner can reset this function 
      * @param _reason explanation of why the task was not approved
      */
    function undoComplete(string memory _reason) public restricted isCompleted{
        status = STATUS_STARTED;
        endDate = 0;
        emit UndoCompleted(developer, _reason, block.timestamp);
    }

    /** @notice Cancelation of the task validating
      * @dev Update the task’s variable status `status` to cancel or wait for arbitrage. If canceled, all the money saved on the task will be transferred back to the  owner's wallet. Only the owner can cancel the task. Log the description from the parameter `_reason` explaining why the task was canceled. There is no undo after cancelation
      */
    function executeCancelation() private {
        uint256 amountCanceled = address(this).balance;
        (bool success, ) = payable(manager).call{value: amountCanceled}("");
        require(success, "Transfer failed.");
        status = STATUS_CANCELED;
    }

    /** @notice Cancelation of the task
      * @dev Update the task’s variable status `status` to cancel or wait for arbitrage. If canceled, call the function `executeCancelation`
      * @param _reason explanation of why the task was canceled
      */
    function cancel(string memory _reason) public restricted isApproved{
        if (arbitration && (status != STATUS_CREATED)) {
          if (status != STATUS_CANCEL_ARBITRATE){
            statusPriorArbitrate = status;
          }
          status = STATUS_CANCEL_ARBITRATE;
          emit RequestArbitration(manager, _reason, block.timestamp);
        }
        else{
          executeCancelation();
          emit Canceled(manager, developer, _reason, address(this).balance, block.timestamp);
        }
    }

    /** @notice DeTask team approve arbitration
      * @dev Update the task’s variable status `status` to the previews status if not approved. If approved, all the money on the task will be transferred back to the manager's wallet. Only the auth wallet can arbitrage the task. Log the description from the parameter `_reason` explaining the reason.
      * @param _reason explanation of why the task was arbitrated
      * @param _approve true or false about the arbitration
      */
    function arbitrate(string memory _reason, bool _approve) public canArbitrate{
      emit Arbitrate(msg.sender, _reason, _approve, block.timestamp);
      if (_approve == false) {
        status = statusPriorArbitrate;
      }
      else{
        executeCancelation();
      }
    }

    /** @notice Approve the specialist job
      * @dev Update the task’s variable status `status` to approval. Calculate and transfer the DeTask fee using the function `transferTreasuryFee`. Calculate the task completion time using the function `getTimeCompleted`. Transfer all task’s money to the specialist if the completion time `completedTime` was prior to the speeder time `speederDueTime`. If the completion time was after the speeder time, the task will transfer the regular reward `regularReward` minus the anticipated money `anticipatedReward` to the specialist and transfer the left over balance back to the owner wallet address
      */
    function approve() external restricted isCompleted hasReward {
        //Any smart contract that uses transfer() or send() is taking a hard dependency on gas costs by forwarding a fixed amount of gas: 2300.
        //payable(developer).transfer(msg.value);

        //Transfer fee to treasury
        transferTreasuryFee();

        uint16 completedTime = getTimeCompleted();
        uint256 amountTransfered = 0;
        //Rule 1: Delivery day =< speederDueDay: Transfer full amount to the developer
        //Rule 2: Delivery day > speederDueDay: Transfer regularReward to the developer, the rest send back to the manager 
        if (completedTime <= speederDueTime){
            amountTransfered = address(this).balance;
            (bool success, ) = payable(developer).call{value: address(this).balance}("");
            require(success, "Transfer failed.");
        } else {
            amountTransfered = (regularReward - anticipatedReward);
            (bool successDev, ) = payable(developer).call{value: amountTransfered}("");
            require(successDev, "Transfer failed.");

            (bool successManager, ) = payable(manager).call{value: address(this).balance}("");
            require(successManager, "Transfer failed.");
        }

        status = STATUS_APPROVED;
        emit Approved(manager, developer, amountTransfered, block.timestamp);
    }

    //********** FUNCTIONS TO RETRIEVE DATA FROM TASK **********
    /** @notice Return the task's description
      * @dev Validate if the description is public by checking the field `publicDescription`. If it is not public, only the owner or specialist will get the description
      * @return The task description
      */
    function returnDescription() private view returns(string memory){
        string memory _description = "";
        if ((publicDescription) || ((publicDescription == false) && (msg.sender == manager || msg.sender == developer))) {
            _description = description;
        }

        return _description;
    }

    /** @notice Calculate the completion time of the task
      * @dev Check to see if the completion date is filled. Verify if the task was set up per date or hour by variable `dueTimeType`. Calculate the difference of the dates
      * @return the difference between the start and completion date
      */
    function getTimeCompleted() public view returns(uint16){
        uint256 diff = 0;

        if (endDate > 0)
        {
            if (dueTimeType == TASK_BY_HOUR){
                diff = (endDate - startDate) / 3600;
            } 
            else
            {
                diff = (endDate - startDate) / 60 / 60 / 24;
            }
        }
            
        return uint16(diff);
    }
    
    /** @notice Return the task's description
      * @dev call the method `returnDescription()`
      * @return The task description
      */
    function getDescription() public view returns(string memory){
        return returnDescription();
    }

    /** @notice Return the task’s main fields
      * @dev Get the task basic information
      * @return category is the task's tags
      * @return title is the task's title
      * @return manager is the address wallet's owner who create the task 
      * @return developer is the specialist who will delivery the task
      * @return regularReward is the amount the specialist will receive when complete the task
      * @return speederReward is the amount the specialist will receive if he or she complete the task sooner
      * @return balance the current money stored on the task 
      * @return regularDueTime the time the task should be completed
      * @return speederDueTime the speeder time the task should be completed
      * @return status the current status of the task
      * @return startDate is the date and time the task was started
      * @return endDate is the date and time the task was completed
      */
    function getSummary() public view returns(string memory, string memory, address, address, uint256, uint256, uint256, uint16, uint16, uint8, uint256, uint256){

        return (
            category,
            title,
            manager,
            developer,
            regularReward,
            speederReward,
            address(this).balance,
            regularDueTime,
            speederDueTime,
            status,
            startDate,
            endDate
        );
    }

    /** @notice Return the task’s fees values
      * @dev Get the information related to task’s
      * @return treasuryAddress is the DAO address of the treasury that will receive the fee
      * @return treasuryFee is the percentage the task will pay to the treasury
      * @return treasuryFeeValue is the amount the treasury will receive when complete the task 
      * @return affiliateAddress wallet address of the affiliate
      * @return affiliateCommission the percentage commission that affiliate will receive
      * @return the calculate commission fee the affiliate will receive
      * @return developerRate the rate score the owner of the task give to the specialist
      * @return managerRate the rate score the specialist of the task give to the owner
      * @return anticipatedReward is the amount of money the owner of the task anticipate to the specialist 
      * @return dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @return timeCompleted the calculated time to complete the task
      * returnDescription() Validate if the description is public by checking the field `publicDescription`. If it is not public, only the owner or specialist will get the description
      */
    function getSummary2() public view returns(address, uint256, uint256, address, uint8, uint256, uint8, uint8, uint256, uint8, uint16, string memory){

        uint16 timeCompleted = getTimeCompleted();

        return(
            treasuryAddress,
            treasuryFee,
            treasuryFeeValue,
            affiliateAddress,
            affiliateCommission,
            affiliateCommissionValue,
            developerRate,
            managerRate,
            anticipatedReward,
            dueTimeType,
            timeCompleted,
            returnDescription()
        );
    }

    /** @notice Return the task’s fees values
      * @dev Get the information related to task’s
      * @return treasuryAddress is the DAO address of the treasury that will receive the fee
      * @return treasuryFee is the percentage the task will pay to the treasury
      * @return ParentTask is the address of an associated task
      */
    function getSummary3() public view returns(bool, bool, address){

        return(
            arbitration,
            arbitrationAgreed,
            parentTask
        );
    }    

    /** @notice Enter the basic information on the task and receive the task’s money from the owner’s wallet
      * @dev Fill the information from the task by parameters and calculate the treasury fee by calling the function `calculateFee`. The payment received from owners wallet is collected from this method and saved on the task and in the field `speederReward`
      * @param _category is the task's tag
      * @param _description is the task's description used and agreement between the owner and specialist. It should contain the detailed information about the task’s job
      * @param _developer is the specialist's waller address that will receive the payment
      * @param _regularReward is the amount the specialist will receive when complete the task
      * @param _regularDueTime the time the task should be completed
      * @param _speederDueTime the speeder time the task should be completed
      * @param _sender the contract manager
      * @param _dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @param _publicDescription specifies if the description can be visible for anyone. If false, only the owner and specialist can see the information on the description field
      * @param _title is the task's title that is visible for anyone
      */
    function init(string memory _category, string memory _description, address _developer, uint256 _regularReward, uint16 _regularDueTime, uint16 _speederDueTime, address _sender, uint8 _dueTimeType, bool _publicDescription, string memory _title) external payable {
        require(_regularReward <= msg.value, "Regular reward can not be greater than speeder reward pluss fee!");
        require(manager == _sender, "This is not the manager for this task!");
        description = _description;
        category = _category;
        developer = _developer;
        regularReward = _regularReward;
        treasuryFeeValue = ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryFeeValue(_regularReward, _sender);
        speederReward = msg.value - treasuryFeeValue;
        regularDueTime = _regularDueTime;
        speederDueTime = _speederDueTime;
        status = STATUS_CREATED;
        publicDescription = _publicDescription;
        dueTimeType = _dueTimeType;
        title = _title;
        affiliateCommissionValue = ITaskRewardTreasuryConfig(treasuryConfig).calcFee(treasuryFeeValue, affiliateCommission);

        emit Created(_sender, block.timestamp);
    }

}