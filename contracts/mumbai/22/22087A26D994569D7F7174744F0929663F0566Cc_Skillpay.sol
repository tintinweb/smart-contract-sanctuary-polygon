/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

//SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/escrow.sol


pragma solidity ^0.8.7;



contract Escrow is Ownable{


    enum State{
        ACTIVE,
        DISPUTED,
        SETTLED,
        COMPLETED
    }

    State current_state;

    IERC20 public token;
    address public worker;
    address public provider;
    uint public milestoneCount;
    uint public amountPerMilestone;


    function deposit(address _provider, address _worker, IERC20 _token, uint _amount,uint _milestones) payable onlyOwner external {
        token = IERC20(_token);
        worker = _worker;
        /**
        Native token(WETH/BNB) can be used in a case where _token is Address(0) */
        provider = _provider;
        milestoneCount = _milestones;
        
        if(address(_token) != address(0)){
            require(IERC20(_token).balanceOf(msg.sender) >= _amount, "Insufficient fund");
            amountPerMilestone = _amount / _milestones;
            
            IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        }
        else{
            require(msg.value >= _amount,"Insufficient fund");
            amountPerMilestone = msg.value / _milestones;

            (bool sent,) = payable(address(this)).call{value: _amount}("");
            require(sent,"Failed to get Ether");
        }
        current_state = State.ACTIVE;

    }

    function onMilestoneDone() public payable onlyOwner {
        // require(msg.sender == provider, "Not authorized");
        require(!(milestoneCount <= 0),"No Milestone");

        if(address(token) != address(0)){
            IERC20(token).transfer(worker,amountPerMilestone);
        }
        else{
            (bool sent,) = payable(worker).call{value: amountPerMilestone}("");
            require(sent,"Couldn't send ether");
        }
        milestoneCount--;
        if(milestoneCount == 0){
            current_state = State.COMPLETED;
        }
    }

    function makeAppeal(address _appealer) external onlyOwner {
        require(_appealer == worker || _appealer == provider, "Can't make appeal");

        current_state = State.DISPUTED;
    }
    /**
    Function is called by admin after manually going through the appeal case
    - releases funds to worker for completed milestone
     */
    function resolveWorkerMilestoneAppeal() onlyOwner external{
        require(current_state == State.DISPUTED, "No Appeals raised");
        if(address(token) != address(0)){
            IERC20(token).transfer(worker,amountPerMilestone);
        }
        else{
            (bool sent,) = payable(worker).call{value: amountPerMilestone}("");
            require(sent,"Couldn't send ether");
        }

        current_state = State.SETTLED;
        milestoneCount--;

        
    }

    function resolveProviderAppeal() onlyOwner external{
        require(current_state == State.DISPUTED, "No Appeals raised");

        if(address(token) != address(0)){
            IERC20(token).transfer(provider,IERC20(token).balanceOf(address(this)));
        }
        else{
            (bool sent,) = payable(provider).call{value: address(this).balance}("");
            require(sent,"Couldn't send ether");
        }
        current_state = State.SETTLED;

        
    }

    function changeWorker(address _newWorker) onlyOwner external{
        worker = _newWorker;
    }
    receive() external payable {}

}
// File: contracts/skillpay.sol


pragma solidity ^0.8.7;




contract Skillpay is Ownable {

    uint private userIdCount;
    uint private taskIdCount;

    enum UserType{Provider,Worker}
    enum TaskStages{FREE,TAKEN,DISPUTED,SETTLED,COMPLETED}

    struct User{
        string name;
        uint userId;
        uint numTaskProvided;
        uint numberOfTaskTaken;
        uint taskCompleted;
        uint rating;
        UserType accountType;
    }

    struct EscrowData{
        address creator;
        address worker;
        Escrow escrowContract;
        uint createdAt;
    }

    struct Task{
        IERC20 token;
        address creator;
        address currentWorker;
        string metadata;
        uint taskId;
        uint duration;
        uint taskAmount;
        uint paymentPlan;
        uint milestonesCompleted;
        uint createdAt;
        TaskStages stage;
    }

    User[] private users;
    Task[] private tasks;

    mapping(address => User) public profile;
    mapping(address => Task[]) public userTasksTaken;
    mapping(address => Task[]) public userTasksProvided;
    mapping(uint => Task) public getTask;

    mapping(address => mapping(address => EscrowData)) public creatorAndClientToEscrow;

    event NewAccountCreated(string indexed _name, uint indexed _id, bool indexed _type);
    event AppealRaised(address _appealer, string _description);
    event TaskDone(uint indexed taskId, address indexed creator, address indexed worker);
    event WorkerSelected(uint indexed taskId, address indexed creator, address indexed worker);


    function createAccount(string memory _name, bool _provider) external {
        require(bytes(profile[msg.sender].name).length  == 0, "Account exists");
        UserType _type = _provider ? UserType.Provider : UserType.Worker;

        User memory user = User({
            userId: userIdCount,
            name: _name,
            accountType: _type,
            numTaskProvided: 0,
            numberOfTaskTaken: 0,
            taskCompleted: 0,
            rating: 0
        });


        users.push(user);
        profile[msg.sender] = user;

        emit NewAccountCreated(_name, userIdCount, _provider);
        userIdCount++;

    }

    function createTask(
        string memory _metadata,
        IERC20 _token,
        uint _amount,
        uint _duration,
        uint _paymentPlan
        ) external returns(bool)
        {
            require(bytes(profile[msg.sender].name).length  != 0, "Not registered");
            require(profile[msg.sender].accountType == UserType.Provider, "Can't create gig");
            require(_amount > 0,"Be serious");

            Task memory _task = Task({
                taskId: taskIdCount,
                metadata: _metadata,
                duration:  _duration,
                taskAmount: _amount,
                paymentPlan: _paymentPlan,
                createdAt: block.timestamp,
                creator: msg.sender,
                milestonesCompleted: 0,
                stage: TaskStages.FREE,
                currentWorker: address(0),
                token: IERC20(_token)
            });

            tasks.push(_task);
            userTasksProvided[msg.sender].push(_task);
            getTask[taskIdCount] = _task;


            taskIdCount++;

            return true;

        }

    function selectWorker(uint _taskId, address _workerAddress) external payable {

        Task storage _task = getTask[_taskId];

        require(bytes(profile[msg.sender].name).length  != 0, "Not registered");
        require(bytes(profile[_workerAddress].name).length  != 0, "Worker not registered");
        require((_task.creator != address(0) && _task.stage == TaskStages.FREE),"Not FREE");


        _task.stage = TaskStages.TAKEN;
        _task.currentWorker = _workerAddress;

        /**Fee */
        uint _fee = (_task.taskAmount * 100) / 10000;
        uint _newAmount = _task.taskAmount - _fee;

        /** Take Erc20 fees*/
        if(address(_task.token) != address(0)){
            _task.token.transfer(address(this),_fee);
        }

        /**Compute salt for escrow */
        uint _time = _task.createdAt;
        bytes memory _salt = abi.encode(msg.sender,_time);

        /**Create escrow */
        Escrow _newEscrow = new Escrow{salt: bytes32(_salt)}();
        
        _newEscrow.deposit{value: _newAmount}(msg.sender, _workerAddress, _task.token, _newAmount, _task.paymentPlan);


        EscrowData memory _escrowDetail = EscrowData(
            {
                creator: _task.creator,
                worker: _workerAddress,
                createdAt: block.timestamp,
                escrowContract: _newEscrow
            });
            creatorAndClientToEscrow[_task.creator][_workerAddress] = _escrowDetail;
            userTasksTaken[_workerAddress].push(_task);
        }

    function onMilestoneAchieved(uint _taskId) external {
        Task memory _task = getTask[_taskId];
        require(_task.currentWorker == msg.sender,"Not worker");

        emit TaskDone(_taskId,_task.creator,_task.currentWorker);

    }

    function ApproveTaskMilestoneAndPay(uint _taskId) payable external {
        Task storage _task = getTask[_taskId];
        require(_task.creator == msg.sender,"Not creator");

        EscrowData memory escrowinfo = creatorAndClientToEscrow[_task.creator][_task.currentWorker];
        Escrow(escrowinfo.escrowContract).onMilestoneDone();

        _task.milestonesCompleted++;

        if(_task.milestonesCompleted == _task.paymentPlan){
            _task.stage = TaskStages.COMPLETED;
            profile[_task.creator].taskCompleted++;
            profile[_task.currentWorker].taskCompleted++;
        }

    }

    function AppealByCreatorOrWorker(uint _taskId, string memory _description) external{
        Task storage _task = getTask[_taskId];
        require(msg.sender == _task.currentWorker || msg.sender == _task.creator, "Can't make appeal");

        EscrowData memory escrowinfo = creatorAndClientToEscrow[_task.creator][_task.currentWorker];
        Escrow(escrowinfo.escrowContract).makeAppeal(msg.sender);

        _task.stage = TaskStages.DISPUTED;
 
        emit AppealRaised(msg.sender,_description);
    }


    function changeWorker(uint _taskId, address _newWorker) external{
        Task storage _task = getTask[_taskId];
        require(_task.stage == TaskStages.DISPUTED,"Can't change without appeal");
        // require((block.timestamp - _task.duration) > 86400);

        //Old worker escrow data
        EscrowData memory escrowinfo = creatorAndClientToEscrow[_task.creator][_task.currentWorker];
        Escrow(escrowinfo.escrowContract).changeWorker(_newWorker);

        //Update data for new worker
        EscrowData memory newData = EscrowData({
            creator: _task.creator,
            worker: _newWorker,
            createdAt: escrowinfo.createdAt,
            escrowContract: escrowinfo.escrowContract
        });

        creatorAndClientToEscrow[_task.creator][_newWorker] = newData;
        _task.currentWorker = _newWorker;
    }


    /**
    ADMIN
     */

    function reverseToCreator(uint _taskId) external onlyOwner{
        Task storage _task = getTask[_taskId];

        EscrowData memory escrowinfo = creatorAndClientToEscrow[_task.creator][_task.currentWorker];
        Escrow(escrowinfo.escrowContract).resolveProviderAppeal();

        _task.stage = TaskStages.SETTLED;
    }

    function releaseFundsToWorker(uint _taskId) external onlyOwner{
        Task storage _task = getTask[_taskId];

        EscrowData memory escrowinfo = creatorAndClientToEscrow[_task.creator][_task.currentWorker];
        Escrow(escrowinfo.escrowContract).resolveWorkerMilestoneAppeal();

        _task.stage = TaskStages.SETTLED;

        
    }

    function retrieveFunds(address _token, uint _amount, address _to)external payable onlyOwner{

        if(_token == address(0)){
            (bool sent,) = payable(_to).call{value: _amount}("");
            require(sent);
        }
        else{
            IERC20(_token).transfer(_to, _amount);
        }

    }

    /**
    GETTERS
    */

    function getTasksByUser() public view returns(Task[] memory){
        if(profile[msg.sender].accountType == UserType.Provider){
            return userTasksProvided[msg.sender];
        }
        else{
            return userTasksTaken[msg.sender];
        }
    }

    function getTaskCreator(uint _taskId) public view returns(address){
        return getTask[_taskId].creator;
    }

    function getCurrentTaskWorker(uint _taskId) public view returns(address){
        return getTask[_taskId].currentWorker;
    }
    
    function getAllTasks() public view returns(Task[] memory){
        return tasks;
    }

    /**
    Precomputes escrow address for a task
    this can be used to grant ERC20 approval 
    before calling the selectWorker function
     */

    function createEscrowAddressForTask(uint _taskId) public view returns(Escrow) {
        uint _time = getTask[_taskId].createdAt;
        bytes memory _salt = abi.encode(msg.sender,_time);

        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            bytes32(_salt),
            keccak256(abi.encodePacked(
                type(Escrow).creationCode
            ))
        )))));
        return Escrow(payable(predictedAddress));
    }

    receive() external payable {}

}