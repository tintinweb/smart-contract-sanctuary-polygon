/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/interfaces/IERC20.sol

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IRBAC.sol

pragma solidity ^0.6.12;

interface IRBAC {
    function isAdmin(address user) external view returns (bool);
}


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.6.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a);
        return c;
    }
}


// File contracts/StakingPool.sol

pragma solidity ^0.6.12;



/**
 *  In order for user to become eligible to participate inside private sales, he must stake for at least
 *  N period of time. Given the situation, once user does deposit, he can't withdraw until the N period of time
 *  expires. Whenever stake is in the pool, your participation is getting into account how much is total staked,
 *  and given input (total staked, and your stake) is determined if you're eligible to participate in private sales
 */
contract StakingPool {

    // Using SafeMath library for mathematical operations over uint256
    using SafeMath for uint256;

    /// Representing stake structure
    struct Stake {
        address user;
        uint256 amount;
        uint256 timestamp;
        uint256 unlockingTime;
        bool isWithdrawn;
    }

    // Pointer to admin contract
    IRBAC public admin;

    // Array holding all stakes
    Stake [] public stakes;

    // Token being staked
    IERC20 public token;

    // Mapping user to his stakes
    mapping(address => uint256[]) userToHisStakeIds;

    // Total amount staked at the moment
    uint256 public totalStaked;

    // Minimal time to stake in order to get eligible to participate in private sales
    uint256 public minimalTimeToStake;

    // Minimal amount staked
    uint256 public minimalAmountToStake;

    event StakingRulesChanged(uint256 _minimalTimeToStake, uint256 _minimalAmountToStake);
    event DepositedTokens(address _account, uint256 _amount, uint256 _timestamp, uint256 _unlockingTime, uint256 _stakeId);
    event WithdrawStake(address _account, uint256 amount);

// Initially set token address and admin wallet address
    constructor (
        address _token,
        address _admin
    )
    public
    {
        require(_token != address(0), "_token can not be 0x0 address.");
        require(_admin != address(0), "_admin can not be 0x0 address.");

        token = IERC20(_token);
        admin = IRBAC(_admin);
    }

    // Function which can be called only by admin
    function setStakingRules(
        uint256 _minimalTimeToStake,
        uint256 _minimalAmountToStake
    )
    public
    {
        // Only admin can call this
        require(admin.isAdmin(msg.sender) == true, "Restricted only to admin address.");
        // Set minimal time to stake
        minimalTimeToStake = _minimalTimeToStake;
        // Set minimal amount to stake
        minimalAmountToStake = _minimalAmountToStake;

        emit StakingRulesChanged(minimalTimeToStake, minimalAmountToStake);
    }

    // Function to deposit tokens (create stake)
    function depositTokens(
        uint amount
    )
    public
    {
        // Require that user is meeting requirement for minimal stake amount
        require(amount >= minimalAmountToStake, "Amount is below threshold.");
        // Allow only direct calls from EOA (Externally owner wallets - flashloan prevention)
        require(msg.sender == tx.origin, "Only direct calls.");
        // Compute the ID of the stake
        uint stakeId = stakes.length;
        // Create new stake object
        Stake memory s = Stake({
            user: msg.sender,
            amount: amount,
            timestamp: now,
            unlockingTime: now.add(minimalTimeToStake),
            isWithdrawn: false
        });
        // Take tokens from the user
        bool status = token.transferFrom(msg.sender, address(this), amount);
        require(status, "Failed transfer.");
        // Push stake to array of all stakes
        stakes.push(s);
        // Add stakeId to array of users stake ids
        userToHisStakeIds[msg.sender].push(stakeId);
        // Increase how much is staked in total
        totalStaked = totalStaked.add(amount);

        emit DepositedTokens(msg.sender, s.amount, s.timestamp, s.unlockingTime, stakeId);
    }

    // Function where user can withdraw all his stakes
    function withdrawAllStakes()
    public
    {
        uint totalToWithdraw = 0;

        for(uint i = 0; i < userToHisStakeIds[msg.sender].length; i++) {
            uint stakeId = userToHisStakeIds[msg.sender][i];
            uint amountToWithdraw = withdrawStakeInternal(stakeId);
            totalToWithdraw = totalToWithdraw.add(amountToWithdraw);
        }

        if(totalToWithdraw > 0) {
            bool status = token.transfer(msg.sender, totalToWithdraw);
            require(status, "Failed transfer.");
        }

        emit WithdrawStake(msg.sender, totalToWithdraw);
    }

    function withdrawStake(
        uint stakeId
    )
    public
    {
        uint amount = withdrawStakeInternal(stakeId);
        require(amount > 0, "Amount must be greater than 0.");

        bool status = token.transfer(msg.sender, amount);
        require(status, "Failed transfer.");

        emit WithdrawStake(msg.sender, amount);
    }

    function withdrawStakeInternal(
        uint stakeId
    )
    internal
    returns (uint)
    {
        Stake storage s = stakes[stakeId];
        // Only user can withdraw his stakes
        require(s.user == msg.sender, "Only user can withdraw his stake.");
        // Stake can't be withdrawn more than once and time has to expire in order to make stake able to withdraw
        if(s.isWithdrawn == true || now < s.unlockingTime) {
            return 0;
        }
        else {
            // Mark stake that it's withdrawn
            s.isWithdrawn = true;
            // Reduce total amount staked
            totalStaked = totalStaked.sub(s.amount);
            // Transfer back tokens to user
            return s.amount;
        }
    }

    // Function to get all stake ids for specific user
    function getUserStakeIds(
        address user
    )
    public
    view
    returns (uint256[] memory)
    {
        return userToHisStakeIds[user];
    }

    function getHowManyStakesUserHas(
        address user
    )
    public
    view
    returns (uint)
    {
        return userToHisStakeIds[user].length;
    }

    function getAllUserStakes(
        address user
    )
    public
    view
    returns (
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        bool[] memory
    )
    {
        uint length = getHowManyStakesUserHas(user);

        uint [] memory amountsStaked = new uint[](length);
        uint [] memory timestamps = new uint[](length);
        uint [] memory unlockingTime = new uint[](length);
        bool [] memory isStakeWithdrawn = new bool[](length);

        for(uint i = 0; i < length; i++) {
            uint stakeId = userToHisStakeIds[user][i];
            Stake memory s = stakes[stakeId];

            amountsStaked[i] = s.amount;
            timestamps[i] = s.timestamp;
            unlockingTime[i] = s.unlockingTime;
            isStakeWithdrawn[i] = s.isWithdrawn;
        }

        return (amountsStaked, timestamps, unlockingTime, isStakeWithdrawn);
    }

    // Function to get total amount user staked in the contract
    function getTotalAmountUserStaked(
        address user
    )
    public
    view
    returns (uint)
    {
        uint256[] memory userStakeIds = userToHisStakeIds[user];

        uint256 totalUserStaked = 0;

        for(uint i = 0; i < userStakeIds.length; i++) {
            uint stakeId = userStakeIds[i];
            Stake memory s = stakes[stakeId];
            // Counts only active stakes
            if(!s.isWithdrawn) {
                totalUserStaked = totalUserStaked.add(s.amount);
            }
        }

        return totalUserStaked;
    }

    // Compute weight of the user
    function computeUserWeight(
        address user
    )
    public
    view
    returns (uint256)
    {
        uint totalUserStaked = getTotalAmountUserStaked(user);
        return totalUserStaked.mul(10**18).div(totalStaked);
    }

}