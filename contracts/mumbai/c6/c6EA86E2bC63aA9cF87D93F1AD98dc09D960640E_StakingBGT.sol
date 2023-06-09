/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: StakingBGT.sol


pragma solidity ^0.8.0;


struct NetWork {
    uint256 id;
    uint level;
    uint time;
    address sender_;
    address super_;
}

interface Invitation {

    function getAutoIds() external view returns (uint256);

    function getInfoForId(uint256 _id) external view returns (NetWork memory);

    function getInfo(address _sender) external view returns (NetWork memory);

    function getSuper(address _sender) external view returns (address);

    function post(address _sender, address _super) external;
}

interface BGT  {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;
 
    function burn(uint256 amount) external;
}

contract StakingBGT is Ownable {
    
    BGT private bgtToken;
    Invitation private invitation;
    uint256 private totalBalances;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private dposs;
    mapping(address => uint256) private interests;
    mapping(address => uint256) private lastUpdateTime;
    uint256 private dailyLimit;

    event Deposit(address indexed account, uint256 amount, uint256 balance);
    event Redeposit(address indexed account, uint256 amount, uint256 balance);
    event Withdrawal(address indexed account, uint256 amount, uint256 balance);
    event InterestClaimed(address indexed account, uint interest);

    constructor(address _bgtTokenAddress) {
        bgtToken = BGT(_bgtTokenAddress);
    }

    function setInvitation(address _invitation) external onlyOwner {
        invitation = Invitation(_invitation);
    }

    function postSuperAddress(address super_) external {
        invitation.post(msg.sender, super_);
    }

    function setDailyLimit(uint256 value, uint256 days_) external onlyOwner {
        if (days_ == 0)
            days_ = 365;
        dailyLimit = value * (10 ** bgtToken.decimals()) / days_;
    }

    function deposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(bgtToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        settlementInterest(msg.sender);

        address super_ = invitation.getSuper(msg.sender);
        require(super_ != address(0), "Bind the invitation relationship first");
        settlementInterest(super_);

        // Update the balance and the dpos
        balances[msg.sender] += amount;
        dposs[super_] += amount * 2;
        totalBalances += amount * 3;

        // Transfer BGT tokens from user to the contract
        bgtToken.transferFrom(msg.sender, address(this), amount);
    
        emit Deposit(msg.sender, amount, balances[msg.sender]);
    }

    function redeposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        settlementInterest(msg.sender);

        address super_ = invitation.getSuper(msg.sender);
        require(super_ != address(0), "Bind the invitation relationship first");
        settlementInterest(super_);

        require(interests[msg.sender] >= amount, "The Amount must be less than or equal to interest");

        // Update the interests and the balance and the dpos
        interests[msg.sender] -= amount;
        balances[msg.sender] += amount;
        dposs[super_] += amount * 2;
        totalBalances += amount * 3;

        // Mint BGT tokens from user to the contract
        bgtToken.mint(address(this), amount);
    
        emit Redeposit(msg.sender, amount, balances[msg.sender]);
    }

    function withdraw(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");
        settlementInterest(msg.sender);

        address super_ = invitation.getSuper(msg.sender);
        require(super_ != address(0), "Bind the invitation relationship first");
        settlementInterest(super_);

        // Update the balance and the dpos
        balances[msg.sender] -= amount;
        dposs[super_] -= amount * 2;
        totalBalances -= amount * 3;

        // Transfer the principal back to the user
        bgtToken.transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    function claimInterest() external {
        settlementInterest(msg.sender);

        uint256 interest = interests[msg.sender];
        require(interest > 0, "No interest available");

        interests[msg.sender] = 0;
        // Transfer the interest to the user
        bgtToken.mint(msg.sender, interest);

        emit InterestClaimed(msg.sender, interest);
    }

    function settlementInterest(address account) internal {
        uint256 interest = calculateInterest(msg.sender);
        if (interest > 0)
        {
            // Update the last update time
            interests[account] += interest;
        }
        lastUpdateTime[account] = block.timestamp;
    }

    function calculateInterest(address account) public view returns (uint256) {

        if (balances[account] == 0)
            return 0;

        uint currentTime = block.timestamp;
        uint lastUpdate = lastUpdateTime[account];
        uint elapsedTime = currentTime - lastUpdate;

        uint interest = dailyLimit * elapsedTime * (balances[account] + dposs[account]) / (1 days) / totalBalances;
        return interest;
    }

    function getUserInfo(address account) public view returns (uint256 balance, uint256 dpos, uint256 totalBalances_)
    {
        return (balances[account], dposs[account], totalBalances);
    }

    function gsetDailyLimit() public view returns (uint256)
    {
        return dailyLimit;
    }
}