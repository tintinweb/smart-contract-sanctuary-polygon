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
    address public winnerAddress;
    address private _owner;

    struct Pools {
        uint256 id;
        string name;
        string category;
        address cadidate_address;
        string uri;
        string description;
        uint256 totalVotes;
        address[] alreadyVotedAddress;
    }

    mapping(uint256 => Pools) public pools;

    Pools[] public poolsCollec;

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    //Transfer OwnerShip
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");

        _owner = newOwner;
    }

    function startVoting(uint256 _time) external onlyOwner {
        startTime = block.timestamp;
        endTime = block.timestamp + (_time * 1 minutes);
    }

    function setTokenAddress(address token_address) external onlyOwner {
        require(token_address != address(0), "Invalid token address"); // Ensure the new address is not zero
        token = IERC20(token_address);
    }

    function reset() external onlyOwner {
        for (uint256 i = 0; i < poolsCollec.length; i++) {
            delete pools[i];
        }
        delete poolsCollec;
        winnerAddress = address(0);
    }

    function getAllCandidates() public view returns (Pools[] memory) {
        uint256 length = poolsCollec.length;
        Pools[] memory values = new Pools[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = pools[i];
        }
        return values;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getCounts() public view returns (uint256) {
        return poolsCollec.length;
    }

    function addPools(
        string memory _name,
        string memory _category,
        string memory _uri,
        string memory _description,
        address _address
    ) public {
        require(
            poolsCollec.length < 5,
            "Max 5 Pools can be there in the election"
        );

        uint256 _uniqueId = counter;
        pools[_uniqueId].id = _uniqueId;
        pools[_uniqueId].name = _name;
        pools[_uniqueId].category = _category;
        pools[_uniqueId].uri = _uri;
        pools[_uniqueId].description = _description;
        pools[_uniqueId].totalVotes = 0;
        pools[_uniqueId].cadidate_address = _address;

        poolsCollec.push(pools[_uniqueId]);
        counter = counter + 1;
    }

    function vote(uint256 _pool_Id) public {
        // Check if voting is happening within 10 minutes or after 10 minutes.
        require(
            block.timestamp <= endTime,
            "Voting Time expired. Voting was only for 10 minutes."
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
        pools[_pool_Id].alreadyVotedAddress.push(msg.sender);
    }

    function getResult() public onlyOwner returns (uint256) {
        // Check if result is declaring after 10 minutes or not.
        require(
            block.timestamp > endTime,
            "Result will be declared after 10 minutes of Voting."
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
        address _recipient = pools[_winnerId].cadidate_address;
        winnerAddress = _recipient;
        return _winnerId;
    }

    function pay() external payable onlyOwner {
        if (winnerAddress != address(0))
            token.transferFrom(address(this), winnerAddress, 10);
    }
}