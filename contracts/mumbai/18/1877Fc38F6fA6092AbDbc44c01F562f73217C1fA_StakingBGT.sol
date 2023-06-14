/**
 *Submitted for verification at polygonscan.com on 2023-06-14
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

struct AnnualInterestRateConfig {
    uint index;
    uint256 rQuantity;
    uint256 annualInterestRate;
}

contract StakingBGT is Ownable {
    
    BGT private bgtToken;
    Invitation private invitation;
    uint256 private totalPos;
    uint256 private totalFPos;
    uint256 private totalDPos;
    mapping(address => uint256) private poss;
    mapping(address => uint256) private fposs;
    mapping(address => uint256) private dposs;
    mapping(address => uint256) private interests;
    mapping(address => uint256) private lastUpdateTime;
    mapping(uint => AnnualInterestRateConfig) private annualInterestRateConfig;
    uint[] private poolLevelUpdateTimes;
    uint256 private nextRQuantity;
    uint256 private annualEarnings;

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

    function ggg() external view returns (uint256 nextRQuantity_, uint256 length, uint256[] memory rQuantitys, uint256[] memory annualInterestRates)
    {
        length = poolLevelUpdateTimes.length;
        rQuantitys = new uint256[](poolLevelUpdateTimes.length);
        annualInterestRates = new uint256[](poolLevelUpdateTimes.length);
        for (uint i=0; i<length; i++)
        {
            rQuantitys[i] = annualInterestRateConfig[i].rQuantity;
            annualInterestRates[i] = annualInterestRateConfig[i].annualInterestRate;
        }

            nextRQuantity_ = nextRQuantity;
    }

    function setAnnualEarnings(uint256 _annualEarnings) public onlyOwner {

        annualEarnings = _annualEarnings * 10 ** bgtToken.decimals();

        if (poolLevelUpdateTimes.length == 0)
        {
            poolLevelUpdateTimes.push(0);
        }
        else 
        {
            poolLevelUpdateTimes.push(block.timestamp);
        }
        uint256 _nextRQuantity = getNextRQuantity(nextRQuantity);
        nextRQuantity = _setConfig(poolLevelUpdateTimes.length - 1, _nextRQuantity);
    }

    function _setConfig(uint256 _index, uint256 _rQuantity) internal returns (uint256) {
        uint256 _nextRQuantity = getNextRQuantity(_rQuantity);
        uint256 _annualInterestRate = 100 * annualEarnings * 7 / 30 / _nextRQuantity;
        annualInterestRateConfig[_index] = AnnualInterestRateConfig(_index, _rQuantity * (10 ** bgtToken.decimals()), _annualInterestRate);
        return _nextRQuantity;
    }

    function getNextRQuantity(uint256 _rQuantity) internal view returns (uint256)
    {
        return _rQuantity == 0 ? 18000000 * 10 ** bgtToken.decimals() : (_rQuantity * (5263157 + 100000000) / 100000000);
    }

    function upgrades() internal {
        
        if (totalPos + totalFPos >= nextRQuantity)
        {
            poolLevelUpdateTimes.push(block.timestamp);
            uint256 _nextRQuantity = getNextRQuantity(nextRQuantity);
            nextRQuantity = _setConfig(poolLevelUpdateTimes.length - 1, _nextRQuantity);
        }
    }

    function deposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(bgtToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        address super_ = settlement(msg.sender);

        // Update the balance and the dpos
        poss[msg.sender] += amount;
        dposs[super_] += amount * 2;
        totalPos += amount;
        totalDPos += amount * 2;

        // Transfer BGT tokens from user to the contract
        bgtToken.transferFrom(msg.sender, address(this), amount);
    
        upgrades();

        emit Deposit(msg.sender, amount, poss[msg.sender]);
    }

    function redeposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(interests[msg.sender] >= amount, "The Amount must be less than or equal to interest");
        address super_ = settlement(msg.sender);

        // Update the interests and the balance and the dpos
        interests[msg.sender] -= amount;
        poss[msg.sender] += amount;
        dposs[super_] += amount * 2;
        totalPos += amount;
        totalDPos += amount * 2;

        // Mint BGT tokens from user to the contract
        bgtToken.mint(address(this), amount);
    
        upgrades();

        emit Redeposit(msg.sender, amount, poss[msg.sender]);
    }

    function withdraw(uint amount) external {
        require(amount <= poss[msg.sender], "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");
        address super_ = settlement(msg.sender);

        // Update the balance and the dpos
        poss[msg.sender] -= amount;
        dposs[super_] -= amount * 2;
        totalPos -= amount;
        totalDPos -= amount * 2;
        uint256 subfposs = (fposs[msg.sender] >= amount) ? amount : fposs[msg.sender];
        fposs[msg.sender] = fposs[msg.sender] - subfposs;
        totalFPos -= subfposs;
        // Transfer the principal back to the user
        bgtToken.transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, amount, poss[msg.sender]);
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

    function settlement(address account) internal returns (address) {
        settlementInterest(account);

        address super_ = invitation.getSuper(account);
        require(super_ != address(0), "Bind the invitation relationship first");
        settlementInterest(super_);
        return super_;
    }

    function settlementInterest(address account) internal {
        uint256 interest = calculateInterest(account);
        if (interest > 0)
        {
            // Update the last update time
            interests[account] += interest;
        }
        lastUpdateTime[account] = block.timestamp;
    }

    function calculateInterest(address account) public view returns (uint256) {

        if (poss[account] == 0)
            return 0;

        uint currentTime = block.timestamp;
        uint lastUpdate = lastUpdateTime[account];

        uint userIndex = getIndex(account);
        
        uint interest = 0;
        for (uint i=userIndex; i<poolLevelUpdateTimes.length; i++)
        {
            uint elapsedTime = 0;
            if (i == poolLevelUpdateTimes.length - 1)
            {
                elapsedTime = currentTime - poolLevelUpdateTimes[i];
            }
            else if (i == userIndex)
            {
                elapsedTime = poolLevelUpdateTimes[i+1] - lastUpdate;
            }
            else 
            {
                elapsedTime = poolLevelUpdateTimes[i+1] - poolLevelUpdateTimes[i];
            }
            interest = annualInterestRateConfig[i].annualInterestRate * elapsedTime * (poss[account] + dposs[account] + fposs[account]) / (365 days) / 100;
        }
        return interest;
    }

    function getIndex(address account) public view returns (uint)
    {
        uint index = poolLevelUpdateTimes.length - 1;
        uint i = poolLevelUpdateTimes.length;
        while (true)
        {
            i--;
            if (lastUpdateTime[account] <= poolLevelUpdateTimes[i] || i == 0)
            {
                index = i;
                break; 
            }
        }
        return index;
    }

    function getUserInfo(address account) public view returns (uint256 pos, uint256 fpos, uint256 dpos, uint256 totalPos_, uint256 totalFPos_, uint256 totalDPos_)
    {
        return (poss[account], fposs[account], dposs[account], totalPos, totalFPos, totalDPos);
    }

}