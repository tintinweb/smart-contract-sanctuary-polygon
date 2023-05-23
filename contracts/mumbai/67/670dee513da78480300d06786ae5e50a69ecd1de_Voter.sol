// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/access/Ownable.sol";
import '../../interfaces/IVoteLogic.sol';
import '../../interfaces/IBribe.sol';
import './AggregateBribe.sol';

// | |/ /_ _| \ | |__  /  / \   
// | ' / | ||  \| | / /  / _ \  
// | . \ | || |\  |/ /_ / ___ \ 
// |_|\_\___|_| \_/____/_/   \_\

/// @notice XKZA - Kinza protocol Voter
/// @title Voter
/// @notice vote for underlying AToken/DToken holder
///         for receiving KZA emission on BaseRewardPool
contract Voter is Ownable {

    /*//////////////////////////////////////////////////////////////
                      CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    uint internal constant DURATION = 7 days; // rewards are released over 7 days
    address public immutable xToken; // the xtoken that can vote on this contract

    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    // simple re-entrancy check
    uint internal _unlocked = 1;

    IVoteLogic public voteLogic; // the voteLogic that can aggregate balance of XToken for this voter

    address public bribeAssetRegistry;

    uint public totalWeight; // total voting weight

    address[] public markets; // all underlying viable for incentives

    mapping(address => address) public bribes; // underlying => external bribe (external bribes)

    mapping(address => uint256) public weights; // underlying => weight
    mapping(address => mapping(address => uint256)) public votes; // holder => underlying => votes
    mapping(address => address[]) public poolVote; // holder => underlying(s) that are voted
    mapping(address => uint) public usedWeights;  // address => total voting weight of user
    mapping(address => uint) public lastVoted; // holder => timestamp of last vote, to ensure one vote per epoch

    mapping(address => address) public delegation;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event Voted(
        address indexed voter, 
        address pool, 
        uint256 weight, 
        uint256 epoch
    );

    event MarketBribeCreated(
        address market, 
        address bribe
    );

    event MarketBribeRemoved(
        address market
    );

    event NewVoteLogic(
        address newVoteLogic
    );
    

    event Abstained(
        address voter, 
        uint256 weight, 
        uint256 epoch
    );

    event SetDelegation(
        address voter, 
        address delegatee
    );

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
    
    modifier onlyXToken() {
        require(msg.sender == xToken, "caller not xToken");
        _;
    }

    modifier onlyNewEpoch(address _xTokenHolder) {
        // ensure new epoch since last vote 
        require((block.timestamp / DURATION) * DURATION > lastVoted[_xTokenHolder], "holder already voted in this epoch");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _xToken, address _voteLogic, address  _bribeAssetRegistry, address _governance) {
        xToken = _xToken;
        voteLogic = IVoteLogic(_voteLogic);
        bribeAssetRegistry = _bribeAssetRegistry;
        transferOwnership(_governance);
        emit NewVoteLogic(_voteLogic);
    }


    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/
    function isDelegatedOrOwner(address _delegatee, address _voter) public view returns(bool) {
        return delegation[_voter] == _delegatee || msg.sender == _voter;
    }

    /// @notice helper function to get number of votable market
    function marketLength() external view returns (uint) {
        return markets.length;
    }

    /*//////////////////////////////////////////////////////////////
                            OWNABLE
    //////////////////////////////////////////////////////////////*/
    
    /// @param _underlying underlying assets which can be voted
    /// @dev only the underlying(s) that exist in the pool contract would be calculated
    ///      check minter update_period logic
    function pushUnderlying(address _underlying) external onlyOwner {
        require(bribes[_underlying] == address(0), "exists");
        address bribe = _createBribe(address(this), bribeAssetRegistry);
        bribes[_underlying] = bribe;
        markets.push(_underlying);
        emit MarketBribeCreated(_underlying, bribe);
    }

    function removeUnderlying(address _underlying) external onlyOwner {
        require(bribes[_underlying] != address(0), "assets not a voting candidate");
        bribes[_underlying] = address(0);
        // by now l > 0 since there is at least 1 underlying.
        uint256 l = markets.length;
        for (uint256 i; i < l;) {
            if (markets[i] == _underlying) {
                markets[l-1] = markets[i];
                markets.pop();
                emit MarketBribeRemoved(_underlying);
                return;
            }
            unchecked {
                ++i;
            }
        }
        // only sanity check, the _underlying is certain to exist in the list
        // if it exists in the bribes mapping and pass the initial require
        revert();
        
    }

    function updateVoteLogic(address _newVoteLogic) external onlyOwner {
        voteLogic = IVoteLogic(_newVoteLogic);
        emit NewVoteLogic(_newVoteLogic);
    }

    // repeat the last vote (same ratio) but update user with his latest balance
    // this is only callable from XToken
    function reVote(address _xTokenHolder) onlyXToken external {
        // if the user has never voted, no refreshing is needed
        if(lastVoted[_xTokenHolder] == 0) {
            return;
        }
        lastVoted[_xTokenHolder] = block.timestamp;

        address[] memory _poolVote = poolVote[_xTokenHolder];
        uint _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint i = 0; i < _poolCnt; i ++) {
            _weights[i] = votes[_xTokenHolder][_poolVote[i]];
        }
        _vote(_xTokenHolder, _poolVote, _weights);
    }

    /*//////////////////////////////////////////////////////////////
                         USER INTERACTION
    //////////////////////////////////////////////////////////////*/

    /// @notice user can update their vote, only the last vote before an epoch is counted
    /// @param _account the owner of the bribe, essentially this contract
    /// @param _poolVote the list of pool addresses
    /// @param _weights the list of relative weights for each pool
    function vote(address _account, address[] calldata _poolVote, uint256[] calldata _weights) external {
        require(isDelegatedOrOwner(msg.sender, _account), "not owner or delegated");
        require(_poolVote.length == _weights.length, "number of pools and weights do not match");
        lastVoted[_account] = block.timestamp;
        // _vote would erase all records and re-cast vote, quite gas expensive
        _vote(_account, _poolVote, _weights);
    }

    /// @param _delegatee the address that user would like to delegate
    function updateDelegate(address _delegatee) external {
        delegation[msg.sender] = _delegatee;
        emit SetDelegation(msg.sender, _delegatee);
    }
    
    /// @notice in external bribe u can choose which token to claim
    /// @param _bribes each address of the bribe deployment
    /// @param _tokens for each bribe, the token(s) to claim
    /// @param _to the recipient
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, address _to) external {
        require(_bribes.length > 0 && _tokens.length == _bribes.length, "bribe input validation fails");
        address bribe;
        for (uint i = 0; i < _bribes.length; i++) {
            bribe = _bribes[i];
            require(bribe != address(0), "bribe addresses cannot be zero");
            IBribe(bribe).getRewardForOwner(_tokens[i], msg.sender, _to);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @param _owner the owner of the bribe, essentially this contract
    /// @param _registry the whitelist asset registry
    /// @return bribe the address of the newly deployed bribe contract
    function _createBribe(address _owner, address _registry) internal returns(address bribe) {
        bribe = address(new AggregateBribe(_owner, _registry));
    }

    /// @param _account the owner of the bribe, essentially this contract
    /// @param _poolVote the list of pool addresses
    /// @param _weights the list of relative weights for each pool
    /// @dev make sure neither 
    ///      1.) the sum of _weights 
    ///      2.) each _weight * balanceOf 
    ///      does not exceeds 2**256 -1
    ///      or the function would revert due to overflow
    function _vote(address _account, address[] memory _poolVote, uint256[] memory _weights) internal {
        _reset(_account);
        uint256 _weight = IVoteLogic(voteLogic).balanceOf(_account);
        if (_weight == 0) {
            return;
        }
        uint _poolCnt = _poolVote.length;
        uint256 _totalVoteWeight;
        uint256 _poolWeight;
        address _pool;

        for (uint i; i < _poolCnt;) {
            _totalVoteWeight += _weights[i];
            // save gas
            unchecked {
                ++i;
            }
        }
        for (uint i; i < _poolCnt;) {
            _pool = _poolVote[i];
            // _poolWeight is the actual weight, xToken 1 : 1
            _poolWeight = _weights[i] * _weight / _totalVoteWeight;
            // sanity check, it's always true given the _reset executes prior
            require(votes[_account][_pool] == 0, "non-zero existing vote");
            // a _weight of 0 should NOT be passed to this function
            require(_poolWeight != 0, "zero pool weight");
            poolVote[_account].push(_pool);

            weights[_pool] += _poolWeight;
            votes[_account][_pool] += _poolWeight;
            IBribe(bribes[_pool])._deposit(uint256(_poolWeight), _account);
            emit Voted(_account, _pool, _poolWeight, block.timestamp / DURATION);
            // save gas
            unchecked {
                ++i;
            }
        }
        usedWeights[_account] = _weight;
        totalWeight += _weight;
    }

    /// @notice remove the last vote of the user
    /// @param _account the account to reset votes
    function _reset(address _account) internal {
        address[] storage _poolVote = poolVote[_account];
        uint _poolVoteCnt = _poolVote.length;
        uint256 last_weight = usedWeights[_account];
        // each underlying that gets voted in the last voted epoch
        for (uint i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_account][_pool];

            if (_votes != 0) {
                weights[_pool] -= _votes;
                votes[_account][_pool] -= _votes;
                IBribe(bribes[_pool])._withdraw(uint256(_votes), _account);
                emit Abstained(_account, _votes, block.timestamp / DURATION);
            }
        }
        totalWeight -= last_weight;
        usedWeights[_account] = 0;
        delete poolVote[_account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

interface IVoteLogic {
    function balanceOf(address account) external returns(uint256);
}

interface IBribe {
    function _deposit(uint256 _poolWeight, address _account) external;
    function _withdraw(uint256 _poolWeight, address _account) external;
    function getRewardForOwner(address[] memory _tokens, address _account, address _to) external;
    function getRewardForOwner(address _account, address _to) external;

    function notifyRewardAmount(address token, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/utils/math/Math.sol';
import '@openzeppelin/token/ERC20/IERC20.sol';
import '../../interfaces/IBribeAssetRegistry.sol';


// | |/ /_ _| \ | |__  /  / \   
// | ' / | ||  \| | / /  / _ \  
// | . \ | || |\  |/ /_ / ___ \ 
// |_|\_\___|_| \_/____/_/   \_\

/// @notice KZA - Kinza protocol bribe contract for each underlying asset
/// @title AggregateBribe
/// @notice Bribe pay out rewards for a given pool based on the votes 
///         that were received from the user through the contract Voter
contract AggregateBribe {
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    address public immutable voter; // only voter can modify balances (since it only happens on vote())
    address public immutable bribeAssetRegistry;

    uint internal constant DURATION = 7 days; // rewards are released over the voting period

    /*//////////////////////////////////////////////////////////////
                        STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/
    uint internal _unlocked = 1;
    uint public totalSupply;
    // user => balanceOf (virtual), updated during vote
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(uint => uint)) public tokenRewardsPerEpoch;
    // token => timestamp
    mapping(address => uint) public periodFinish;
    // token => user => amount
    mapping(address => mapping(address => uint)) public lastEarn;

    /// @notice A record of balance checkpoints for each account, by index
    mapping (address => mapping (uint => Checkpoint)) public checkpoints;
    /// @notice The number of checkpoints for each account at each change(s)
    mapping (address => uint) public numCheckpoints;
    /// @notice A record of total supply checkpoints, by index
    mapping (uint => SupplyCheckpoint) public supplyCheckpoints;
    /// @notice The number of checkpoints
    uint public supplyNumCheckpoints;

    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint timestamp;
        uint balanceOf;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint timestamp;
        uint supply;
    }

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(
        address indexed from, 
        address account, 
        uint amount
    );

    event Withdraw(
        address indexed from, 
        address account, 
        uint amount
    );

    event NotifyReward(
        address indexed from, 
        address indexed reward, 
        uint epoch, 
        uint amount
    );

    event ClaimRewards(
        address indexed from, 
        address indexed reward, 
        uint amount
    );

    /*//////////////////////////////////////////////////////////////
                          MODIFIER
    //////////////////////////////////////////////////////////////*/
    /// @notice simple re-entrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _voter, address _bribeAssetRegistry) {
        voter = _voter;
        bribeAssetRegistry = _bribeAssetRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER / VIEW
    //////////////////////////////////////////////////////////////*/

    /// @param timestamp timestamp in second
    /// @return return the start of an epoch for that timestamp
    function getEpochStart(uint timestamp) public pure returns (uint) {
        uint bribeStart = _bribeStart(timestamp);
        uint bribeEnd = bribeStart + DURATION;
        return timestamp < bribeEnd ? bribeStart : bribeStart + 7 days;
    }

    /// @notice Determine the prior balance for an account as of a block number
    /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    /// @param account The address of user
    /// @param timestamp The timestamp to get the balance at
    /// @return The balance index the account had as of the given timestamp
    function getPriorBalanceIndex(address account, uint timestamp) public view returns (uint) {
        uint nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }
        // Next check implicit zero balance
        if (checkpoints[account][0].timestamp > timestamp) {
            return 0;
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @notice Determine the prior total supply as of a timestamp
    /// @param timestamp timestamp in second
    function getPriorSupplyIndex(uint timestamp) public view returns (uint) {
        uint nCheckpoints = supplyNumCheckpoints;
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (supplyCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // Next check implicit zero balance
        if (supplyCheckpoints[0].timestamp > timestamp) {
            return 0;
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            SupplyCheckpoint memory cp = supplyCheckpoints[center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @param token the reward token
    /// @return the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(address token) public view returns (uint) {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    /// @notice function to return the earned/claimable reward for a user
    /// @param token reward token
    /// @param account target user
    /// @return the claimable
    function earned(address token, address account) public view returns (uint) {
        uint _startTimestamp = lastEarn[token][account];
        if (numCheckpoints[account] == 0) {
            return 0;
        }

        uint _startIndex = getPriorBalanceIndex(account, _startTimestamp);
        uint _endIndex = numCheckpoints[account]-1;

        uint reward = 0;
        // you only earn once per epoch (after it's over)
        Checkpoint memory prevRewards; // reuse struct to avoid stack too deep
        prevRewards.timestamp = _bribeStart(_startTimestamp);
        uint _prevSupply = 1;

        if (_endIndex > 0) {
            for (uint i = _startIndex; i <= _endIndex - 1; i++) {
                Checkpoint memory cp0 = checkpoints[account][i];
                uint _nextEpochStart = _bribeStart(cp0.timestamp);
                // check that you've earned it
                // this won't happen until a week has passed
                if (_nextEpochStart > prevRewards.timestamp) {
                  reward += prevRewards.balanceOf;
                }

                prevRewards.timestamp = _nextEpochStart;
                _prevSupply = supplyCheckpoints[getPriorSupplyIndex(_nextEpochStart + DURATION)].supply;
                prevRewards.balanceOf = cp0.balanceOf * tokenRewardsPerEpoch[token][_nextEpochStart] / _prevSupply;
            }
        }

        Checkpoint memory cp = checkpoints[account][_endIndex];
        uint _lastEpochStart = _bribeStart(cp.timestamp);
        uint _lastEpochEnd = _lastEpochStart + DURATION;

        if (block.timestamp > _lastEpochEnd) {
          reward += cp.balanceOf * tokenRewardsPerEpoch[token][_lastEpochStart] / supplyCheckpoints[getPriorSupplyIndex(_lastEpochEnd)].supply;
        }

        return reward;
    }

    /// @notice get latest total reward for a token
    /// @param token the token address to view
    function left(address token) external view returns (uint) {
        uint adjustedTstamp = getEpochStart(block.timestamp);
        return tokenRewardsPerEpoch[token][adjustedTstamp];
    }

    /*//////////////////////////////////////////////////////////////
                            USER INTERACTION
    //////////////////////////////////////////////////////////////*/

    /// @notice allows a user to claim rewards for a given token
    /// @param tokens the reward token to claim
    function getReward(address[] memory tokens) external lock  {
        for (uint i = 0; i < tokens.length; i++) {
            uint _reward = earned(tokens[i], msg.sender);
            lastEarn[tokens[i]][msg.sender] = block.timestamp;
            if (_reward > 0) _safeTransfer(tokens[i], msg.sender, _reward);

            emit ClaimRewards(msg.sender, tokens[i], _reward);
        }
    }
    /// @notice allow batched reward claims
    /// @param tokens the reward token to claim
    /// @param account the reward token to claim
    /// @param to the reward token to claim
    function getRewardForOwner(address[] memory tokens, address account, address to) external lock  {
        require(msg.sender == voter || msg.sender == account, "only voter or self claim");
        for (uint i = 0; i < tokens.length; i++) {
            uint _reward = earned(tokens[i], account);
            lastEarn[tokens[i]][account] = block.timestamp;
            if (_reward > 0) _safeTransfer(tokens[i], to, _reward);

            emit ClaimRewards(account, tokens[i], _reward);
        }
    }


    /// @notice This is an external function, but internal notation is used 
    ///         since it can only be called "internally" from Voter
    /// @param amount amount of vote to be accounted
    /// @param account voter address
    function _deposit(uint amount, address account) external {
        require(msg.sender == voter, "not voter");

        totalSupply += amount;
        balanceOf[account] += amount;

        _writeCheckpoint(account, balanceOf[account]);
        _writeSupplyCheckpoint();

        emit Deposit(msg.sender, account, amount);
    }

    /// @notice This is an external function, but internal notation is used 
    ///         since it can only be called "internally" from Voter
    /// @param amount amount of vote to be accounted
    /// @param account voter address
    function _withdraw(uint amount, address account) external {
        require(msg.sender == voter);

        totalSupply -= amount;
        balanceOf[account] -= amount;

        _writeCheckpoint(account, balanceOf[account]);
        _writeSupplyCheckpoint();

        emit Withdraw(msg.sender, account, amount);
    }

    /// @notice entry point to send in bribe token, prior whitelist on registry is needed
    ///         bribe sender also has to approve the quantity to enable transferFrom
    /// @param token token to send in
    /// @param amount amount to send in
    function notifyRewardAmount(address token, uint amount) external lock {
        require(amount > 0, "non zero bribe is needed");
        require(IBribeAssetRegistry(bribeAssetRegistry).isWhitelisted(token), "bribe token must be whitelisted");
        // bribes kick in at the start of next bribe period
        uint adjustedTstamp = getEpochStart(block.timestamp);
        uint epochRewards = tokenRewardsPerEpoch[token][adjustedTstamp];

        _safeTransferFrom(token, msg.sender, address(this), amount);
        tokenRewardsPerEpoch[token][adjustedTstamp] = epochRewards + amount;

        periodFinish[token] = adjustedTstamp + DURATION;

        emit NotifyReward(msg.sender, token, adjustedTstamp, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice general transferFrom of tokens
    /// @param token token to transfer 
    /// @param from sender
    /// @param to receiver
    /// @param value amount of token
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    /// @notice general transfer of tokens from this contract
    /// @param token token to transfer 
    /// @param to receiver
    /// @param value amount of token
    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    /// @notice writing checkpoint of account and their vote balance
    /// @param account voter address
    /// @param balance vote balance
    function _writeCheckpoint(address account, uint balance) internal {
        uint _timestamp = block.timestamp;
        uint _nCheckPoints = numCheckpoints[account];
        if (_nCheckPoints > 0 && checkpoints[account][_nCheckPoints - 1].timestamp == _timestamp) {
            checkpoints[account][_nCheckPoints - 1].balanceOf = balance;
        } else {
            checkpoints[account][_nCheckPoints] = Checkpoint(_timestamp, balance);
            numCheckpoints[account] = _nCheckPoints + 1;
        }
    }

    /// @notice writing checkpoint of total supply, which is vote balance
    function _writeSupplyCheckpoint() internal {
        uint _nCheckPoints = supplyNumCheckpoints;
        uint _timestamp = block.timestamp;

        if (_nCheckPoints > 0 && supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp) {
            supplyCheckpoints[_nCheckPoints - 1].supply = totalSupply;
        } else {
            supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(_timestamp, totalSupply);
            supplyNumCheckpoints = _nCheckPoints + 1;
        }
    }

    /// @param timestamp timestamp in second
    /// @return the start time of the epoch corresponds to that timestamp
    function _bribeStart(uint timestamp) internal pure returns (uint) {
        return timestamp - (timestamp % (7 days));
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IBribeAssetRegistry {
    function isWhitelisted(address _asset) external returns(bool);
}