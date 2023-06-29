// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: APACHE

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {
    uint256 counter = 0;
    uint256 public startTime;
    uint256 public endTime;
    IERC20 public token;
    uint256 public winnerid;
    address private _owner;
    bool public _start;
    uint256 public minimun = 100;
    address[] public candidateaddress;
    

    event addpools(uint256 poolId);
    event votersid(uint256 poolId, address voter);
    event winner(uint256 _winnerId, address[] candidateVoterAddress);
   // event allcandidates(uint256 value);

    struct Pools {
        uint256 id;
        string name;
        string category;
        address cadidate_address;
        string uri;
        string description;
        uint256 totalVotes;
        address[] alreadyVotedAddress;
        // address[] voteraddress;
    }

    mapping(uint256 => Pools) public pools;
  //mapping(address => bool) public isCreated;
    mapping(uint256 => uint256) public votes;
    mapping(uint256 => address[]) public candidateVoters;

   

    Pools[] public poolsCollec;

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    // modifier onlyExistingPool(address _address) {
    //     // require(pools[poolId].exists, "Pool does not exist");
    //     require(isCreated[_address], "no pool added");
    //     _;
    // }

    constructor() {
        _owner = msg.sender;    
    }

    //Transfer OwnerShip
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        _owner = newOwner;
    }

    function startVoting(uint256 _time) external onlyOwner {
        _start = false;
        startTime = block.timestamp;
        // endTime = block.timestamp + (_time * 1 minutes);
        endTime = _time + 2 minutes;
    }
    function endVoute() external onlyOwner() {
        endTime = block.timestamp;
    }

    function setTokenAddress(address token_address) external onlyOwner {
        require(token_address != address(0), "Invalid token address"); // Ensure the new address is not zero
        token = IERC20(token_address);
    }
    function setMinimumBalance(uint256 minbalance) external onlyOwner() {
        minimun = minbalance;
    }
    function reset() external onlyOwner {
        for (uint256 i = 0; i < poolsCollec.length; i++) {
            delete pools[i];
        }
        delete poolsCollec;
      //  winnerAddress = address(0);
    }    
    function deletePool() external onlyOwner() {
        delete poolsCollec;
        counter = 0;
      //  winnerAddress = address(0);
    }
    function getAllCandidates() public view returns (Pools[] memory) {
        uint256 length = poolsCollec.length;
        Pools[] memory values = new Pools[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = pools[i];
        }
        //  emit allcandidates(values);
        return values;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getMinimumBalance() public view returns (uint256) {
        return minimun;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }
    

    function getCounts() public view returns (uint256) {
        return poolsCollec.length;
    }
      function getVoteCount(uint256 voterid) external view returns (uint256) {
        return votes[voterid];
    }

    function addPools(
        string memory _name,
        string memory _category,
        string memory _uri,
        string memory _description
       // address _address
    ) public {
        require(
            poolsCollec.length < 5,
            "Max 5 Pools can be there in the election"
        );
    //    require(!isCreated[_address], "Already pool added for this address");
         require(
            _start == false,
            "voting has started"
        );


        uint256 _uniqueId = counter;
        pools[_uniqueId].id = _uniqueId;
        pools[_uniqueId].name = _name;
        pools[_uniqueId].category = _category;
        pools[_uniqueId].uri = _uri;
        pools[_uniqueId].description = _description;
        pools[_uniqueId].totalVotes = 0;
       // pools[_uniqueId].cadidate_address = _address;

        poolsCollec.push(pools[_uniqueId]);
        counter = counter + 1;
        //isCreated[_address] = true;
        emit addpools(_uniqueId);
    }
    function vote(uint256 _pool_Id) public {
        //Check if voting is happening within 10 minutes or after 10 minutes.
         require(
            IERC20(token).balanceOf(msg.sender) >= minimun,
            "Minimum balance is low."
        );
       
        require(
            block.timestamp <= endTime,
            "Voting Time expired."
        );
       
        // Balance Check
        // uint256 balance = token.balanceOf(msg.sender);
        // require(balance == 0, "You don't have enough balance to vote");
        bool _isAlreadyVoted = false;
        Pools memory _pool = pools[_pool_Id];
        for (uint i = 0; i < _pool.alreadyVotedAddress.length; i++) {
            if (_pool.alreadyVotedAddress[i] == msg.sender) {
                _isAlreadyVoted = true;
            }
        }
        require(
            (_isAlreadyVoted == false &&
                _pool.alreadyVotedAddress.length <= 10),
            "Max 10 voters can vote to this Pool and same voter can't vote more than once."
        );
        pools[_pool_Id].totalVotes += 1;
        // address voteraddress = pools[_pool_Id].alreadyVotedAddress.push(msg.sender);
         uint256 cadidatid = pools[_pool_Id].id;
        votes[pools[_pool_Id].id] += _pool_Id;
       // votes[msg.sender] += _pool_Id;
        //  voteraddress = msg.sender;
        candidateVoters[cadidatid].push(msg.sender);
        emit votersid(_pool_Id, msg.sender);
        }


    // function addVoter(address candidate, address voter) public {
    //     candidateVoters[candidate].push(voter);
    // }
    function getResult() public onlyOwner returns (uint256) {
        // Check if result is declaring after 10 minutes or not.
        require(
            block.timestamp >= endTime,
            "Result will be declared after time ends for Voting."
        );
        uint256 _maxVotes = 0;
        uint256 _winnerId = 0;
        for (uint i = 0; i <= poolsCollec.length; i++) {
            _winnerId = (pools[i].totalVotes > _maxVotes)
                ? pools[i].id
                : _winnerId;
            _maxVotes = (pools[i].totalVotes > _maxVotes)
                ? pools[i].totalVotes
                : _maxVotes;
        }
        uint256 _recipient = pools[_winnerId].id;
        // address voters = pools[_winnerId].voteraddress;
        winnerid = _recipient;
        candidateaddress =  candidateVoters[winnerid]; 
        emit winner(_winnerId,candidateaddress);
        return _winnerId;
        // return candidateVoters[winnerAddress];   
    }
    function getVoters() public view returns (address[] memory) {
        return candidateVoters[winnerid];
    }
    // function pay() external payable onlyOwner {
    //     if (winnerAddress != address(0))
    //         token.transferFrom(address(this), winnerAddress, 10);
    // }    
}