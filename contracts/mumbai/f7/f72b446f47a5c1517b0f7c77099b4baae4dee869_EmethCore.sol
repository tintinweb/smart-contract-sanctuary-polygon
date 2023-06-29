/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

abstract contract VerifierRole {
    address public verifier;

    constructor () {
        verifier = msg.sender;
    }

    modifier onlyVerifier() {
        require(isVerifier(msg.sender), "Verifiable: msg.sender does not have the Verifier role");
        _;
    }

    function isVerifier(address _addr) public view returns (bool) {
        return (_addr == verifier);
    }

    function setVerifier(address _addr) public onlyVerifier {
        verifier = _addr;
    }
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function mint(address _to, uint256 _value) external returns (bool);
    function burn(uint256 _value) external returns (bool);
}

contract EmethCore is VerifierRole {
    using SafeMath for uint256;

    address owner;

    // Constants
    uint256 constant REQUESTED = 1;
    uint256 constant PROCESSING = 2;
    uint256 constant SUBMITTED = 3;
    uint256 constant VERIFIED = 4;
    uint256 constant CANCELED = 5;
    uint256 constant TIMEOUT = 6;
    uint256 constant FAILED = 7;
    uint256 constant DECLINED = 8;

    // Paramters
    uint256 public TIMEOUT_PENALTY_RATE = 25000; // 25% of fee
    uint256 public DECLINE_PENALTY_RATE = 25000; // 25% of fee
    uint256 public FAILED_PENALTY_RATE = 25000; // 25% of fee
    uint256 public DEPOSIT_RATE = 100000; // 100% of fee
    uint256 public MAX_SLOT_FUEL_PER_NODE = 10000000000;
    //uint256 public VERIFIER_FEE = 10000000000000000000; // 10 EMT
    uint256 public VERIFIER_FEE_RATE = 5000; // 5% of fee

    // EMT
    IERC20 immutable public emtToken;
    uint256 constant DECIMAL_FACTOR = 1e18;
    uint256 constant BASE_SLOT_REWARD = 12000 * 24 * DECIMAL_FACTOR; // 12,000 EMT x 24
    uint256 constant SLOT_INTERVAL = 24 hours;
    uint256 constant DECREMENT_PER_SLOT = 600 * 24 * DECIMAL_FACTOR / 365; // 600 EMT
    uint256 immutable public startSlot;

    // Slots
    mapping (uint256 => uint256) private slotTotalFuel; // (slotNumber => totalFuel)
    mapping (uint256 => mapping(address => uint256)) public slotFuel; // (slotNumber => (nodeAddress => reward))
    mapping (uint256 => mapping(address => uint256)) public slotBalances; // (slotNumber => (nodeAddress => reward))
    mapping (address => uint256[]) public nodeSlots; // (nodeAddress => listOfSlots) for iteration
    mapping (address => mapping(uint256 => bool)) public nodeSlotUnique; // (nodeAddress => (slot => bool)) for unique check

    // Jobs
    // (required)
    mapping(bytes16 => Job) public jobs;
    mapping(bytes16 => JobDetail) public jobDetails;
    mapping(bytes16 => JobAssign) public jobAssigns;
    mapping(address => bytes16[]) public jobAssignedHistory;
    mapping(bytes16 => bytes16[]) public jobChildren;
    bytes16[] public jobIndexes;

    // Programs
    mapping(uint256 => Program) public programs;

    // Events
    event Status(bytes16 indexed jobId, address sender, uint256 status);

    // Structs
    struct Job {
        bool exist;
        bytes16 jobId;
        bytes16 parentJob;
        address owner;
        uint256 deadline;
        uint256 fuelLimit;
        uint256 fuelPrice;
        uint256 status; //0: requested, 1: assigned, 2: processing, 3: completed, 4: canceled
        uint256 requestedAt;
    }

    struct JobDetail {
        uint256 programId;
        uint256 numParallel;
        uint256 numEpoch;
        string param;
        string dataset;
        string result;
    }

    struct JobAssign {
        address node;
        uint256 deposit;
        uint256 fuelUsed;
        uint256 startedAt;
        uint256 submittedAt;
        uint256 verifiedAt;
    }

    struct Program {
        uint256 programId;
        string programName;
        uint256 algoComplexity;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'insufficient privilege');
        _;
    }

    modifier onlyAssignedNode(bytes16 _jobId) {
        require(jobAssigns[_jobId].node == msg.sender, "EmethCore: job is not assigned to your node");
        _;
    }

    modifier onlyRequestedNode(bytes16 _jobId) {
        require(jobs[_jobId].owner == msg.sender, "EmethCore: job is not requested by your node");
        _;
    }

    // Constructor
    constructor(address _tokenAddress) {
        owner = msg.sender;
        emtToken= IERC20(_tokenAddress);
        startSlot = block.timestamp.div(SLOT_INTERVAL);
    }

    // Functions for Requester
    function request(
        bytes16 _jobId,
        uint256 _programId,
        bytes16 _parentJob,
        uint256 _numParallel,
        uint256 _numEpoch,
        string calldata _dataset,
        string calldata _param,
        uint256 _fuelLimit,
        uint256 _fuelPrice,
        uint256 _deadline
    ) external returns (bool) {
        require(!jobs[_jobId].exist, "Job ID already exists");

        {
          uint256 feeLimit = _fuelLimit.mul(_fuelPrice);
          uint256 feeTotal = feeLimit.add(feeLimit.mul(VERIFIER_FEE_RATE).div(100000));
          require(emtToken.balanceOf(msg.sender) >= feeTotal, "EmethCore: insufficient balance for feeTotal");
          require(emtToken.allowance(msg.sender, address(this)) >= feeTotal, "EmethCore: insufficient allowance for feeTotal");
          emtToken.transferFrom(msg.sender, address(this), feeTotal);
        }

        jobs[_jobId] = Job({
            exist: true,
            jobId: _jobId,
            parentJob: _parentJob,
            owner: msg.sender,
            deadline: _deadline,
            fuelLimit: _fuelLimit,
            fuelPrice: _fuelPrice,
            status: REQUESTED,
            requestedAt: block.timestamp
        });

        jobDetails[_jobId] = JobDetail({
            programId: _programId,
            numParallel: _numParallel,
            numEpoch: _numEpoch,
            param: _param,
            dataset: _dataset,
            result: ""
        });

        jobAssigns[_jobId] = JobAssign({
            node: address(0),
            deposit: 0,
            fuelUsed: 0,
            startedAt: 0,
            submittedAt: 0,
            verifiedAt: 0
        });

        jobIndexes.push(_jobId);
        if(_parentJob != bytes16(0)) jobChildren[_parentJob].push(_jobId); 

        emit Status(_jobId, msg.sender, REQUESTED);
        return true;
    }

    function cancel(bytes16 _jobId) external onlyRequestedNode(_jobId) returns (bool) {
        Job storage job = jobs[_jobId];

        require(job.exist, "EmethCore: job doesn't exist");
        require(job.status == REQUESTED, "Job is already being processed or canceled");

        job.status = CANCELED;

        uint256 feeLimit = job.fuelLimit.mul(job.fuelPrice);
        uint256 verifierFee = feeLimit.mul(VERIFIER_FEE_RATE).div(100000);
        uint256 feeTotal = feeLimit.add(verifierFee);
        emtToken.transfer(msg.sender, feeTotal);

        emit Status(_jobId, msg.sender, CANCELED);
        return true;
    }

    // Functions for Node 
    function process(bytes16 _jobId) external returns (bool) {
        Job storage job = jobs[_jobId];
        JobAssign storage jobAssign = jobAssigns[_jobId];

        require(job.exist, "EmethCore: job doesn't exist");
        require(job.status == REQUESTED);

        uint256 feeLimit = job.fuelLimit.mul(job.fuelPrice);
        uint256 verifierFee = feeLimit.mul(VERIFIER_FEE_RATE).div(100000);
        uint256 deposit = feeLimit.mul(DEPOSIT_RATE).div(100000);
        require(emtToken.balanceOf(msg.sender) >= deposit, "EmethCore: insufficient balance for deposit");
        require(emtToken.allowance(msg.sender, address(this)) >= deposit, "EmethCore: insufficient allowance for deposit");
        emtToken.transferFrom(msg.sender, address(this), deposit.add(verifierFee));

        job.status = PROCESSING;
        jobAssign.node = msg.sender;
        jobAssign.deposit = deposit.add(verifierFee);
        jobAssign.startedAt = block.timestamp;
        jobAssignedHistory[jobAssign.node].push(_jobId);

        emit Status(_jobId, msg.sender, PROCESSING);
        return true;
    }

    function decline(bytes16 _jobId) external onlyAssignedNode(_jobId) returns (bool) {
        Job storage job = jobs[_jobId];
        JobAssign storage jobAssign = jobAssigns[_jobId];

        require(job.exist, "EmethCore: job doesn't exist");
        require(job.status == PROCESSING, "EmethCore: job is not being processed");

        job.status = DECLINED;

        // Fee Refund
        uint256 feeLimit = job.fuelLimit.mul(job.fuelPrice);
        uint256 verifierFee = feeLimit.mul(VERIFIER_FEE_RATE).div(100000);
        uint256 feeTotal = feeLimit.add(verifierFee);
        emtToken.transfer(job.owner, feeTotal);

        // Deposit Refund with Penalty
        uint256 penalty = feeLimit.mul(DECLINE_PENALTY_RATE).div(100000);
        if(penalty < jobAssign.deposit) {
            emtToken.transfer(msg.sender, jobAssign.deposit.sub(penalty));
            emtToken.burn(penalty);
        }

        emit Status(_jobId, msg.sender, DECLINED);
        return true;
    }

    function submit(bytes16 _jobId, string calldata _result, uint256 _fuelUsed) external onlyAssignedNode(_jobId) returns (bool) {
        Job storage job = jobs[_jobId];
        JobDetail storage jobDetail = jobDetails[_jobId];
        JobAssign storage jobAssign = jobAssigns[_jobId];

        require(job.exist, "EmethCore: job doesn't exist");
        require(job.status == PROCESSING, "EmethCore: job is not being processed");
        require(job.fuelLimit >= _fuelUsed, "EmethCore: fuelUsed exceeds fuelLimit");

        job.status = SUBMITTED;
        jobDetail.result = _result;
        jobAssign.fuelUsed = _fuelUsed;
        jobAssign.submittedAt = block.timestamp;

        emit Status(_jobId, msg.sender, SUBMITTED);
        return true;
    }

    function withdrawSlotReward(uint256 _slot) external returns (bool) {
        require(_slot < block.timestamp.div(SLOT_INTERVAL), "The slot has not been closed");
        require(slotBalances[_slot][msg.sender] > 0, "The slot reward is empty");

        uint256 reward = slotReward(_slot).mul(slotBalances[_slot][msg.sender]).div(slotTotalFuel[_slot]);
        emtToken.mint(msg.sender, reward);

        slotBalances[_slot][msg.sender] = 0;

        return true;
    }

    // Functions for Verifier
    function verify(bytes16 _jobId) external onlyVerifier returns (bool) {
        Job storage job = jobs[_jobId];
        JobAssign storage jobAssign = jobAssigns[_jobId];

        require(job.exist, "EmethCore: job doesn't exist");
        require(job.status == SUBMITTED, "EmethCore: job result is not submitted");

        job.status = VERIFIED;

        // Put in Reward Slot
        _putSlotReward(_jobId);

        // Return Deposit
        emtToken.transfer(jobAssign.node, jobAssign.deposit);

        // Distribute Fee
        uint256 feeLimit = job.fuelLimit.mul(job.fuelPrice);
        uint256 verifierFee = feeLimit.mul(VERIFIER_FEE_RATE).div(100000);
        uint256 feeUsed = jobAssign.fuelUsed.mul(job.fuelPrice);
        uint256 refund = feeLimit.sub(feeUsed);
        emtToken.transfer(jobAssign.node, feeUsed);
        emtToken.transfer(job.owner, refund);

        // Verifier Fee
        emtToken.transfer(verifier, verifierFee);

        emit Status(_jobId, msg.sender, VERIFIED);
        return true;
    }

    function timeout(bytes16 _jobId) external onlyVerifier returns (bool) {
        Job storage job = jobs[_jobId];
        JobAssign storage jobAssign = jobAssigns[_jobId];

        require(job.exist, "EmethCore: job doesn't exist");
        require(job.status == PROCESSING || job.status == REQUESTED, "EmethCore: job is not in requested or processing status");
        require(job.deadline <= block.timestamp, "EmethCore: still earlier than the deadline");
       
        job.status = TIMEOUT;

        // Tx Fee Refund
        uint256 feeLimit = jobAssign.fuelUsed.mul(job.fuelPrice);
        uint256 verifierFee = feeLimit.mul(VERIFIER_FEE_RATE).div(100000);
        uint256 feeTotal = feeLimit.add(verifierFee);
        emtToken.transfer(job.owner, feeTotal);

        // Deposit Refund with Penalty
        if(job.status == PROCESSING) {
            uint256 penalty = feeLimit.mul(TIMEOUT_PENALTY_RATE).div(100000);
            if(penalty < jobAssign.deposit) {
                emtToken.transfer(jobAssign.node, jobAssign.deposit.sub(penalty));
                emtToken.burn(penalty);
            }
        }

        emit Status(_jobId, msg.sender, TIMEOUT);
        return true;
    }

    function rejectResult(bytes16 _jobId) external onlyVerifier returns (bool) {
        Job storage job = jobs[_jobId];
        JobAssign storage jobAssign = jobAssigns[_jobId];

        require(job.exist, "EmethCore: job doesn't exist");
        require(jobs[_jobId].status == SUBMITTED, "EmethCore: job result is not submitted");

        job.status = FAILED;

        // Tx Fee Refund
        uint256 feeLimit = jobAssign.fuelUsed.mul(job.fuelPrice);
        uint256 verifierFee = feeLimit.mul(VERIFIER_FEE_RATE).div(100000);
        uint256 feeTotal = feeLimit.add(verifierFee);
        emtToken.transfer(job.owner, feeTotal);

        // Deposit Refund with Penalty
        uint256 penalty = feeLimit.mul(FAILED_PENALTY_RATE).div(100000);
        if(penalty < jobAssign.deposit) {
            emtToken.transfer(jobAssign.node, jobAssign.deposit.sub(verifierFee).sub(penalty));
            emtToken.burn(penalty);
        }

        // Verifier Fee
        emtToken.transfer(verifier, verifierFee);

        emit Status(_jobId, msg.sender, FAILED);
        return true;
    }

    // Admin
    function setProgram(uint256 _programId, string memory _programName, uint256 _algoComplexity) external onlyOwner returns (bool) {
        programs[_programId] = Program(_programId, _programName, _algoComplexity);
        return true;
    }

    // Utilities
    // Public
    function jobAssignedCount(address _node) external view returns (uint256) {
        return jobAssignedHistory[_node].length;
    }

    function getEstimatedFuel(uint256 _datasetSizeMB, uint256 _algoComplexity) external pure returns (uint256) {
        return _datasetSizeMB.mul(_algoComplexity).div(1000);
    }

    function currentSlotReward() external view returns (uint256) {
        return slotReward(currentSlot());
    }

    function currentSlot() public view returns (uint256) {
        return block.timestamp.div(SLOT_INTERVAL);
    }

    function nodeSlotCount(address _node) external view returns (uint256) {
        return nodeSlots[_node].length;
    }

    function slots(uint256 _slot) external view returns (uint256 _totalFuel, uint256 _totalReward) {
        return (slotTotalFuel[_slot], slotReward(_slot));
    }

    // Private
    function _putSlotReward(bytes16 _jobId) private returns (uint256) {
        JobAssign storage jobAssign = jobAssigns[_jobId];
        address node = jobAssigns[_jobId].node;
        uint256 slot = block.timestamp.div(SLOT_INTERVAL);

        uint256 fuelCounted = jobAssign.fuelUsed;
        if(slotFuel[slot][node].add(jobAssign.fuelUsed) >= MAX_SLOT_FUEL_PER_NODE) {
            fuelCounted = MAX_SLOT_FUEL_PER_NODE - slotFuel[slot][node];
        }

        slotTotalFuel[slot] = slotTotalFuel[slot].add(fuelCounted);
        slotFuel[slot][node] = slotFuel[slot][node].add(fuelCounted);
        slotBalances[slot][node] = slotBalances[slot][node].add(fuelCounted);
        if(!nodeSlotUnique[node][slot]) {
            nodeSlots[node].push(slot);
            nodeSlotUnique[node][slot] = true;
        }

        return slot;
    }

    function slotReward(uint256 _slot) private view returns (uint256) {
        uint256 reward = 0;
        uint256 halvingAmount = _slot.sub(startSlot).mul(DECREMENT_PER_SLOT);
        if(BASE_SLOT_REWARD > halvingAmount) {
            reward = BASE_SLOT_REWARD.sub(halvingAmount);
        }
        return reward;
    }

}