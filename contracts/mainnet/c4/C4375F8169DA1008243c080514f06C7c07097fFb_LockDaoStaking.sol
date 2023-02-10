// SPDX-License-Identifier: proprietary
pragma solidity 0.8.9;

//import "hardhat/console.sol";
import "./external/IERC20.sol";
import "./external/SafeOwn.sol";
import "./external/ISelfkeyIdAuthorization.sol";

struct StakingTimeLock {
    uint256 timestamp;
    uint amount;
}

contract LockDaoStaking is SafeOwn {
    event StakeAdded(address _account, uint _amount);
    event StakeWithdraw(address _account, uint _amount);
    event RewardsMinted(address _account, uint _amount);

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    ISelfkeyIdAuthorization public authorizationContract;
    address public immutable rewardsTokenAddress;

    address public owner;

    uint public minStakeAmount;
    uint public minWithdrawAmount;
    uint public timeLockDuration;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    mapping(address => StakingTimeLock[]) private _timeLockEntries;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(address _stakingToken, address _rewardToken, address _authorizationContract) SafeOwn(14400) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        authorizationContract = ISelfkeyIdAuthorization(_authorizationContract);
        rewardsTokenAddress = _rewardToken;

        minStakeAmount = 0;
        minWithdrawAmount = 0;
        timeLockDuration = 0;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function setMinStakeAmount(uint _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        minStakeAmount = _amount;
    }

    function setMinWithdrawAmount(uint _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        minWithdrawAmount = _amount;
    }

    function setTimeLockDuration(uint _duration) external onlyOwner {
        timeLockDuration = _duration;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
    }

    // Stake KEY
    function stake(address _account, uint256 _amount, bytes32 _param, uint _timestamp, address _signer,bytes memory signature) external updateReward(_account) {
        authorizationContract.authorize(address(this), _account, _amount, 'mint:lock:staking', _param, _timestamp, _signer, signature);
        require(_amount > 0, "Amount is invalid");
        require(_amount >= minStakeAmount, "Amount is below minimum");
        require(stakingToken.balanceOf(_account) >= _amount, "Not enough funds");

        stakingToken.transferFrom(_account, address(this), _amount);
        balanceOf[_account] += _amount;
        totalSupply += _amount;

        _timeLockEntries[_account].push(StakingTimeLock(block.timestamp + timeLockDuration, _amount));

        emit StakeAdded(_account, _amount);
    }

    // Withdraw Stake KEY
    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Amount = 0");
        require(_amount >= minWithdrawAmount, "Amount is below minimum");
        require(_amount <= balanceOf[msg.sender], "Not enough funds");
        require(_amount <= availableOf(msg.sender), "Not enough funds available");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);

        emit StakeWithdraw(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint) {
        return ((balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) + rewards[_account];
    }

    function availableOf(address _account) public view returns(uint) {
        uint _available = 0;
        uint _balance = balanceOf[_account];
        StakingTimeLock[] memory _accountRecords = _timeLockEntries[_account];
        for(uint i=0; i<_accountRecords.length; i++) {
            StakingTimeLock memory _record = _accountRecords[i];
            if (_record.timestamp < block.timestamp) {
                _available = _available + _record.amount;
            }
        }
        return _available < _balance ? _available : _balance;
    }

    function notifyRewardMinted(address _account, uint _amount) external updateReward(_account) {
        require(msg.sender == rewardsTokenAddress, "Invalid");
        uint reward = rewards[_account];
        if (reward > 0 && _amount > 0) {
            rewards[_account] = reward - _amount;
            emit RewardsMinted(_account, _amount);
        }
    }

    /*
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }
    */

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        // require(rewardRate * duration <= rewardsToken.balanceOf(address(this)), "reward amount > balance");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}

// SPDX-License-Identifier: proprietary
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// @author Razzor https://twitter.com/razzor_tweet
pragma solidity 0.8.9;
     /**
     * @dev Contract defines a 2-step Access Control for the owner of the contract in order
     * to avoid risks. Such as accidentally transferring control to an undesired address or renouncing ownership.
     * The contracts mitigates these risks by using a 2-step process for ownership transfers and a time margin
     * to renounce ownership. The owner can propose the ownership to the new owner, and the pending owner can accept
     * the ownership in order to become the new owner. If an undesired address has been passed accidentally, Owner
     * can propose the ownership again to the new desired address, thus mitigating the risk of losing control immediately.
     * Also, an owner can choose to retain ownership if renounced accidentally prior to future renounce time.
     * The Owner can choose not to have this feature of time margin while renouncing ownership, by initialising _renounceInterval as 0.
     */
abstract contract SafeOwn{
    bool private isRenounced;
    address private _Owner;
    address private _pendingOwner;
    uint256 private _renounceTime;
    uint256 private _renounceInterval;

     /**
     * @dev Emitted when the Ownership is transferred or renounced. AtTime may hold
     * a future time value, if there exists a _renounceInterval > 0 for renounceOwnership transaction.
     */
    event ownershipTransferred(address indexed currentOwner, address indexed newOwner, uint256 indexed AtTime);
     /**
     * @dev Emitted when the Ownership is retained by the current Owner.
     */
    event ownershipRetained(address indexed currentOwner, uint256 indexed At);

     /**
     * @notice Initializes the Deployer as the Owner of the contract.
     * @param renounceInterval time in seconds after which the Owner will be removed.
     */

    constructor(uint256 renounceInterval){
        _Owner = msg.sender;
        _renounceInterval = renounceInterval;
        emit ownershipTransferred(address(0), _Owner, block.timestamp);
    }
     /**
     * @notice Throws if the caller is not the Owner.
     */

    modifier onlyOwner(){
        require(Owner() == msg.sender, "SafeOwn: Caller is the not the Owner");
        _;
    }

     /**
     * @notice Throws if the caller is not the Pending Owner.
     */

    modifier onlyPendingOwner(){
        require(_pendingOwner == msg.sender, "SafeOwn: Caller is the not the Pending Owner");
        _;
    }

     /**
     * @notice Returns the current Owner.
     * @dev returns zero address after renounce time, if the Ownership is renounced.
     */

    function Owner() public view virtual returns(address){
        if(block.timestamp >= _renounceTime && isRenounced){
            return address(0);
        }
        else{
            return _Owner;
        }
    }
     /**
     * @notice Returns the Pending Owner.
     */

    function pendingOwner() public view virtual returns(address){
        return _pendingOwner;
    }

     /**
     * @notice Returns the renounce parameters.
     * @return bool value determining whether Owner has called renounceOwnership or not.
     * @return Renounce Interval in seconds after which the Ownership will be renounced.
     * @return Renounce Time at which the Ownership was/will be renounced. 0 if Ownership retains.
     */
    function renounceParams() public view virtual returns(bool, uint256, uint256){
        return (isRenounced, _renounceInterval, _renounceTime);
    }
     /**
     * @notice Owner can propose ownership to a new Owner(newOwner).
     * @dev Owner can not propose ownership, if it has called renounceOwnership and
     * not retained the ownership yet.
     * @param newOwner address of the new owner to propose ownership to.
     */
    function proposeOwnership(address newOwner) public virtual onlyOwner{
        require(!isRenounced, "SafeOwn: Ownership has been Renounced");
        require(newOwner != address(0), "SafeOwn: New Owner can not be a Zero Address");
        _pendingOwner = newOwner;
    }

     /**
     * @notice Pending Owner can accept the ownership proposal and become the new Owner.
     */
    function acceptOwnership() public virtual onlyPendingOwner{
        address currentOwner = _Owner;
        address newOwner = _pendingOwner;
        _Owner = _pendingOwner;
        _pendingOwner = address(0);
        emit ownershipTransferred(currentOwner, newOwner, block.timestamp);
    }

     /**
     * @notice Owner can renounce ownership. Owner will be removed from the
     * contract after _renounceTime.
     * @dev Owner will be immediately removed if the _renounceInterval is 0.
     * @dev Pending Owner will be immediately removed.
     */
    function renounceOwnership() public virtual onlyOwner{
        require(!isRenounced, "SafeOwn: Already Renounced");
        if(_pendingOwner != address(0)){
             _pendingOwner = address(0);
        }
        _renounceTime = block.timestamp + _renounceInterval;
        isRenounced = true;
        emit ownershipTransferred(_Owner, address(0), _renounceTime);
    }

     /**
     * @notice Owner can retain its ownership and cancel the renouncing(if initiated
     * by Owner).
     */

    function retainOwnership() public virtual onlyOwner{
        require(isRenounced, "SafeOwn: Already Retained");
        _renounceTime = 0;
        isRenounced = false;
        emit ownershipRetained(_Owner, block.timestamp);
    }

}

// SPDX-License-Identifier: proprietary
pragma solidity >=0.8.0;

interface ISelfkeyIdAuthorization {

    function authorize(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp, address _signer, bytes memory _signature) external;

    function getMessageHash(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp) external view returns (bytes32);

    function getEthSignedMessageHash(bytes32 _messageHash) external view returns (bytes32);

    function verify(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp, address _signer, bytes memory _signature) external view returns (bool);

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) external view returns (address);

    function splitSignature(bytes memory sig) external view returns (bytes32 r, bytes32 s, uint8 v);
}