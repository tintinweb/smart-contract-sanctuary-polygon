/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/******************************************/
/*        INerveToken starts here         */
/******************************************/

interface INerveToken {

   
    // distribute new Nerve tokens in relation to paid fee, Ether conversion rate of the native token and current NERVE price.
    function mintNerve(address _to, uint256 _amount) external;
}

/******************************************/
/*        NerveSocial starts here         */
/******************************************/

contract NerveSocial
{
    mapping(address => bytes32) public addressRegister;
    mapping(bytes32 => address) public nameRegister;
    
    event NameRegistered(address indexed user, bytes32 registeredName);
    event SocialRegistered(address indexed user, string[] socialLinks, string[] socialIds);
    event LocationRegistered(address indexed user, uint256 latitude, uint256 longitude);  
    event UserBlacklisted(address indexed user, address userToBlacklist);

    function registerName(bytes32 registeredName) external
    {
        if (registeredName [0] != 0) 
        {
            require(nameRegister[registeredName] == address(0), "Name already taken.");
            bytes32 actualName;
            if (addressRegister[msg.sender] != 0) 
            {
                actualName = addressRegister[msg.sender]; 
                delete nameRegister[actualName];
            }
            addressRegister[msg.sender] = registeredName;
            nameRegister[registeredName] = msg.sender;

            emit NameRegistered(msg.sender, registeredName);
        }
    }

    function registerSocial(string[] memory registeredLink, string[] memory socialID) external
    {            
        uint256 arrayLength = registeredLink.length;
        string[] memory socialLinks = new string[](arrayLength);
        
        uint256 socialArrayLength = socialID.length;
        string[] memory socialIds = new string[](socialArrayLength);
        emit SocialRegistered(msg.sender, socialLinks, socialIds);
    }
    
    function setLocation(uint256 latitude, uint256 longitude) external
    {
        emit LocationRegistered(msg.sender, latitude, longitude);
    }

    function setBlacklistUser(address userToBlacklist) external
    {
        emit UserBlacklisted(msg.sender, userToBlacklist);
    }
}

/******************************************/
/*         NerveGlobal starts here        */
/******************************************/

contract NerveGlobal is NerveSocial
{
    INerveToken nerveToken;
    address nexusBurn;
    address dao;
    uint256 public taskFee = 20;

    uint256 internal currentTaskID;
    mapping(uint256 => taskInfo) public tasks;
    
    struct taskInfo 
    {
        uint96 amount;
        uint96 entranceAmount;
        uint40 endTask;
        uint24 participants;
        
        address recipient;
        bool executed;
        bool finished;
        uint24 positiveVotes;
        uint24 negativeVotes;

        mapping(address => uint256) stakes;
        mapping(address => bool) voted;       
    }

    event TaskAdded(address indexed initiator, uint256 indexed taskID, address indexed recipient, uint256 amount, uint256 entranceAmount, string description, uint256 endTask, string language, uint256 lat, uint256 lon);
    event TaskJoined(address indexed participant, uint256 indexed taskID, uint256 amount);
    event Voted(address indexed participant, uint256 indexed taskID, bool vote, bool finished);
    event RecipientRedeemed(address indexed recipient, uint256 indexed taskID, uint256 amount);
    event UserRedeemed(address indexed participant, uint256 indexed taskID, uint256 amount);
    event TaskProved(uint256 indexed taskID, string proofLink);

    modifier onlyDao() 
    {
        require(msg.sender == dao, "Caller is not DAO.");
        _;
    }

    constructor()
    { 
        currentTaskID = 0;
    }

/******************************************/
/*            Admin starts here           */
/******************************************/

    function initialize(address _dao, address payable _nerveToken, address _nexusBurn) public
    {
        require(address(nerveToken) == address(0), "Already initialized.");
        dao = _dao;
        nerveToken = INerveToken(_nerveToken);
        nexusBurn = _nexusBurn;
    }

    function setFee(uint256 _taskFee) external onlyDao
    {
        taskFee = _taskFee;
    }

    function emergencySetDao(address _dao) external onlyDao
    {
        dao = _dao;
    }

/******************************************/
/*          NerveTask starts here         */
/******************************************/

    function createTask(address recipient, string memory description, uint256 duration, string memory language, uint256 lat, uint256 lon) public payable
    {
        require(recipient != address(0), "0x00 address not allowed.");
        require(msg.value != 0, "No stake defined.");

        uint256 fee = msg.value / taskFee;
        uint256 stake = msg.value - fee;
        payable(nexusBurn).transfer(fee);
        nerveToken.mintNerve(msg.sender, fee);

        currentTaskID++;        
        taskInfo storage s = tasks[currentTaskID];
        s.recipient = recipient;
        s.amount = uint96(stake);
        s.entranceAmount = uint96(msg.value);
        s.endTask = uint40(duration + block.timestamp);
        s.participants++;
        s.stakes[msg.sender] = stake;

        emit TaskAdded(msg.sender, currentTaskID, recipient, stake, msg.value, description, s.endTask, language, lat, lon);
    }

    function joinTask(uint256 taskID) public payable
    {           
        require(msg.value != 0, "No stake defined.");
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].entranceAmount <= msg.value, "Sent ETH does not match tasks entrance amount.");
        require(tasks[taskID].stakes[msg.sender] == 0, "Already participating in task.");
        require(tasks[taskID].endTask > block.timestamp, "Task participation period has ended." );
        require(tasks[taskID].recipient != msg.sender, "User can't be a task recipient.");
        require(tasks[taskID].finished != true, "Task already finished.");

        uint256 fee = msg.value / taskFee;
        uint256 stake = msg.value - fee;
        payable(nexusBurn).transfer(fee);
        nerveToken.mintNerve(msg.sender, fee);

        tasks[taskID].amount = tasks[taskID].amount + uint96(stake);
        tasks[taskID].stakes[msg.sender] = stake;
        tasks[taskID].participants++;

        emit TaskJoined(msg.sender, taskID, stake);
    }
    
    function voteTask(uint256 taskID, bool vote) public
    { 
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].endTask > block.timestamp, "Task has already ended.");
        require(tasks[taskID].stakes[msg.sender] != 0, "Not participating in task.");
        require(tasks[taskID].voted[msg.sender] == false, "Vote has already been cast.");

        tasks[taskID].voted[msg.sender] = true;
        if (vote) {
            tasks[taskID].positiveVotes++;  
        } else {  
            tasks[taskID].negativeVotes++;                             
        }
        if (tasks[taskID].participants == tasks[taskID].negativeVotes + tasks[taskID].positiveVotes) {
            tasks[taskID].finished = true;
        }

        emit Voted(msg.sender, taskID, vote, tasks[taskID].finished);
    }

    function redeemRecipient(uint256 taskID) public
    {
        require(tasks[taskID].recipient == msg.sender, "This task does not belong to message sender.");
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes >= tasks[taskID].negativeVotes, "Streamer lost the vote.");
        require(tasks[taskID].executed != true, "Task reward already redeemed");

        tasks[taskID].executed = true;                                                  
        uint256 fee = uint256(tasks[taskID].amount) / taskFee;
        payable(msg.sender).transfer(uint256(tasks[taskID].amount) - fee);
        payable(nexusBurn).transfer(fee);
        nerveToken.mintNerve(msg.sender, fee);                                                          

        emit RecipientRedeemed(msg.sender, taskID, tasks[taskID].amount);
        
        delete tasks[taskID];
    }

    function redeemUser(uint256 taskID) public
    {
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes < tasks[taskID].negativeVotes, "Streamer fullfilled the task.");
        require(tasks[taskID].stakes[msg.sender] != 0, "User did not participate or has already redeemed his stakes.");

        uint256 tempStakes = tasks[taskID].stakes[msg.sender];
        tasks[taskID].stakes[msg.sender] = 0;       
        payable(msg.sender).transfer(tempStakes);

        emit UserRedeemed(msg.sender, taskID, tempStakes);
    }

    function proveTask(uint256 taskID, string memory proofLink) public
    {
        require(tasks[taskID].recipient == msg.sender, "Can only be proved by recipient.");

        emit TaskProved(taskID, proofLink);
    }
}