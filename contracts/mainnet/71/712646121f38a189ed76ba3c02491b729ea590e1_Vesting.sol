/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

/**
 *  SourceUnit: contracts/Vesting.sol
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStake {
    // Info of each user in pool
    struct UserInfo {
        uint256 endTime; // timestamp when tokens can be released
        uint256 totalAmount; // total reward to be withdrawn
    }

    // Info about staking pool
    struct PoolInfo {
        uint256 minStake; // minimum stake per user
        uint256 maxStake; // maximum stake per user
        uint256 startTime; // start of stake start window
        uint256 endTime; // end of stake start windows
        uint256 rewardPermill; // permill of reward (1permill of 1000 = 1, 20 will be 2%)
        uint256 lockPeriod; // required stake length
        uint256 maxTotalStaked; // maximum total tokens stoked on this
        uint256 totalStaked; // total tokens already staked
        bytes32 poolHash; // unique pool id needed to keep track of user deposits
    }

    function getPools() external view returns (PoolInfo[] memory);

    function getPoolCount() external view returns (uint256);

    function poolInfo(uint256 poolId) external view returns (PoolInfo memory);

    function addStakePool(
        uint256 minStake,
        uint256 maxStake,
        uint256 startTime,
        uint256 endTime,
        uint256 rewardPermill,
        uint256 lockPeriod,
        uint256 maxTotalStaked
    ) external;

    /// Claim all possible tokens
    function claim() external;

    /// Claim tokens only from given user stake
    function claimStake(uint256 index) external;

    /// Address of Vesting contract for claim2stake
    function vestingAddress() external view returns (address);

    /// Address of ERC20 token used for staking
    function tokenAddress() external view returns (address);

    /**
        Total user staked tokens and rewards
     */
    function totalStakedTokens() external view returns (uint256);

    /**
        Free reward tokens available for staking
     */
    function rewardsAvailable() external view returns (uint256);

    /**
        Stake tokens directly from Vesting contract.
        Can be call only from Vesting contract.
        Can fail, if stake requirements are not met.
        @param user address of user that is calling claim2stake in Vesting
        @param poolIndex chosen pool index to stake
        @param amount of tokens claimed to stake
     */
    function claim2stake(
        address user,
        uint256 poolIndex,
        uint256 amount
    ) external returns (bool);

    /**
        Deposit tokens to given pool.
        @param poolId index of staking pool to deposit
        @param amount of tokens to be staked
     */
    function deposit(uint256 poolId, uint256 amount) external;

    /// Event emited on successful deposit.
    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 timeout
    );

    /// Event emited on successful claim
    event Withdraw(address indexed user, uint256 amount);
}

/**
 *  SourceUnit: contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IVesting {
    struct Vest {
        uint256 startDate;
        uint256 endDate;
        uint256 startTokens;
        uint256 totalTokens;
        uint256 claimed;
    }

    /**
        Get all coins that can be claimed from contract
        @param user address of user to check
        @return sum number of tokens to be claimed
     */
    function claimable(address user) external view returns (uint256 sum);

    /// Event emited on claim
    event Claimed(address indexed user, uint256 amount);

    /**
        Claim tokens by msg.sender
        Emits Claimed event
     */
    function claim() external;

    /// Event emited on creating new vest
    event VestAdded(
        address indexed user,
        uint256 startDate,
        uint256 endDate,
        uint256 startTokens,
        uint256 totalTokens
    );

    /**
        Create vesting for user
        Function restricted
        Emits VestAdded event
        @param user address of user
        @param startDate strat timestamp of vesting (can not be in past)
        @param endDate end timestamp of vesting (must be higher than startDate)
        @param startTokens number of tokens to be released on start date (can be zero)
        @param totalTokens total number of tokens to be released on end date (must be greater than startTokens)
     */
    function createVest(
        address user,
        uint256 startDate,
        uint256 endDate,
        uint256 startTokens,
        uint256 totalTokens
    ) external;

    /// Mass create vestings
    function massCreateVest(
        address[] calldata user,
        uint256[] calldata startDate,
        uint256[] calldata endDate,
        uint256[] calldata startTokens,
        uint256[] calldata totalTokens
    ) external;

    /**
        Get all vestings for given user.
        Will return empty array if no vests configured.
        @param user address to list
        @return array of vests
     */
    function getVestings(address user) external view returns (Vest[] memory);

    /**
        Get one vesting for given user
        Will throw if user have no vestings configured
        @param user address to check
        @param index number of vesting to show
        @return single vest struct
     */
    function getVesting(address user, uint256 index)
        external
        view
        returns (Vest memory);
}

/**
 *  SourceUnit: contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
    Modified ERC173 Ownership contract
 */
abstract contract Ownable {
    address public owner;
    address public newOwner;

    address internal constant ZERO_ADDRESS = address(0x0);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(ZERO_ADDRESS, msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for Owner");
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(newOwner != ZERO_ADDRESS, "newOwner not set");
        require(msg.sender == newOwner, "Only newOwner");
        emit OwnershipTransferred(owner, newOwner);
        newOwner = ZERO_ADDRESS;
        owner = msg.sender;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, ZERO_ADDRESS);
        owner = ZERO_ADDRESS;
    }
}

/**
 *  SourceUnit: contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 *  SourceUnit: contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.10;

////import "./IERC20.sol";
////import "./Ownable.sol";
////import "./IVesting.sol";
////import "./IStake.sol";

contract Vesting is Ownable, IVesting {
    mapping(address => Vest[]) private _vestings;

    /// Amount of tokens inside vesting contract
    uint256 public vested;
    /// Address of ERC20 token contract
    address public immutable tokenAddress;

    /**
        Contract constructor
        @param token address of ERC20 token to be vested
     */
    constructor(address token) {
        tokenAddress = token;
        name = concat("vested ", IERC20(token).name());
        symbol = concat("v", IERC20(token).symbol());
    }

    /**
        Concat two strings
        @param a first string
        @param b second string
        @return concatenated strings
     */
    function concat(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    // Internal add vesting function
    function _addVesting(
        address user,
        uint256 startDate,
        uint256 endDate,
        uint256 startTokens,
        uint256 totalTokens
    ) internal {
        require(user != ZERO_ADDRESS, "Address 0x0 is prohibited");
        require(user.code.length == 0, "Contracts are prohibited");
        require(startDate > block.timestamp, "Start date in past");
        require(endDate >= startDate, "Date setup mismatch");
        require(totalTokens > startTokens, "Token number mismatch");
        _vestings[user].push(
            Vest(startDate, endDate, startTokens, totalTokens, 0)
        );
        emit VestAdded(user, startDate, endDate, startTokens, totalTokens);
        vested += totalTokens;
    }

    /**
        Create single Vesting in contract
        @param user address of the user
        @param startDate timestamp on which user can start claiming
        @param endDate timestamp on which all tokens are freed
        @param startTokens amount of tokens on cliff startDate
        @param totalTokens total amount of tokens in this vesting
     */
    function createVest(
        address user,
        uint256 startDate,
        uint256 endDate,
        uint256 startTokens,
        uint256 totalTokens
    ) external onlyOwner {
        _addVesting(user, startDate, endDate, startTokens, totalTokens);
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                totalTokens
            ),
            "" // this will revert in token if no allowance or balance
        );
    }

    /**
        Create many vestings in one call
        @param user array of user addresses
        @param startDate array of start timestamps
        @param endDate array of end timestamps
        @param startTokens array of tokens on cliff
        @param totalTokens array of total tokens vested
     */
    function massCreateVest(
        address[] calldata user,
        uint256[] calldata startDate,
        uint256[] calldata endDate,
        uint256[] calldata startTokens,
        uint256[] calldata totalTokens
    ) external onlyOwner {
        uint256 len = user.length;
        require(
            len == startTokens.length &&
                len == endDate.length &&
                len == startTokens.length &&
                len == totalTokens.length,
            "Data size mismatch"
        );
        uint256 total;
        uint256 i;
        for (i; i < len; i++) {
            uint256 tokens = totalTokens[i];
            total += tokens;
            _addVesting(
                user[i],
                startDate[i],
                endDate[i],
                startTokens[i],
                tokens
            );
        }
        require(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), total),
            "" // this will revert in token if no allowance or balance
        );
    }

    /**
        Get all vestings for given user
        @param user address to check
        @return array of Vest struct
     */
    function getVestings(address user) external view returns (Vest[] memory) {
        return _vestings[user];
    }

    /**
        Read number of vests created for given user
        @param user address to check
        @return number of vestings
     */
    function getVestingCount(address user) external view returns (uint256) {
        return _vestings[user].length;
    }

    /**
        Get singe vesting parameters for given user
        @param user address to check
        @param index index of vesting to read
        @return single Vest struct
     */
    function getVesting(address user, uint256 index)
        external
        view
        returns (Vest memory)
    {
        require(index < _vestings[user].length, "Index out out bounds");
        return _vestings[user][index];
    }

    /**
        How much tokens can be claimed now by given user
        @param user address to check
        @return sum of tokens available to claim
     */
    function claimable(address user) external view returns (uint256 sum) {
        uint256 len = _vestings[user].length;
        uint256 time = block.timestamp;
        if (len > 0) {
            uint256 i;
            for (i; i < len; i++) {
                sum += _claimable(_vestings[user][i], time);
            }
        }
    }

    /**
        Count number of tokens claimable from vesting at given time
        @param c Vesting struct data
        @param time timestamp to calculate
        @return amt number of tokens possible to claim
     */
    function _claimable(Vest memory c, uint256 time)
        internal
        pure
        returns (uint256 amt)
    {
        if (time > c.startDate) {
            if (time > c.endDate) {
                // all coins can be released
                amt = c.totalTokens;
            } else {
                // we need calculate how much can be released
                uint256 pct = ((time - c.startDate) * 1 gwei) /
                    (c.endDate - c.startDate);
                amt =
                    c.startTokens +
                    ((c.totalTokens - c.startTokens) * pct) /
                    1 gwei;
            }
            amt -= c.claimed; // some may be already claimed
        }
    }

    /**
        Claim all possible vested tokens by caller
     */
    function claim() external {
        uint256 sum = _claim(msg.sender, block.timestamp);
        require(
            IERC20(tokenAddress).transfer(msg.sender, sum),
            "" // will fail in token on transfer error
        );
    }

    /**
        Claim tokens for someone (pay network fees)
        @param user address of vested user to claim
     */
    function claimFor(address user) external {
        uint256 sum = _claim(user, block.timestamp);
        require(
            IERC20(tokenAddress).transfer(user, sum),
            "" // will fail in token on transfer error
        );
    }

    /**
        Claim one of vestings for given user.
        Can be handy if many vestings per account.
        @param user address to claim
        @param index index of vesting to be claimed
     */
    function claimOneFor(address user, uint256 index) external {
        require(index < _vestings[user].length, "Index out of bounds");
        Vest storage c = _vestings[user][index];
        uint256 amt = _claimable(c, block.timestamp);
        require(amt > 0, "Nothing to claim");
        c.claimed += amt;
        vested -= amt;
        require(
            IERC20(tokenAddress).transfer(user, amt),
            "" // will fail in token on transfer error
        );
        emit Claimed(user, amt);
    }

    /**
        Internal claim function
        @param user address to calculate
        @return sum number of tokens claimed
     */
    function _claim(address user, uint256 time) internal returns (uint256 sum) {
        uint256 len = _vestings[user].length;
        require(len > 0, "No locks for user");

        uint256 i;
        for (i; i < len; i++) {
            Vest storage c = _vestings[user][i];
            uint256 amt = _claimable(c, time);
            c.claimed += amt;
            sum += amt;
        }

        require(sum > 0, "Nothing to claim");
        vested -= sum;
        emit Claimed(user, sum);
    }

    //
    // Stake/Claim2stake
    //
    /// Address of stake contract
    address public stakeAddress;

    /**
        Set address of stake contract (once, only owner)
        @param stake contract address
     */
    function setStakeAddress(address stake) external onlyOwner {
        require(stakeAddress == ZERO_ADDRESS, "Contract already set");
        stakeAddress = stake;
        require(
            IStake(stake).vestingAddress() == address(this),
            "Wrong contract address"
        );
        require(
            IERC20(tokenAddress).approve(stake, type(uint256).max),
            "Token approval failed"
        );
    }

    /**
        Claim possible tokens and stake directly to stake pool
     */
    function claim2stake(uint256 index) external {
        require(stakeAddress != ZERO_ADDRESS, "Stake contract not set");
        uint256 sum = _claim(msg.sender, block.timestamp);
        require(
            IStake(stakeAddress).claim2stake(msg.sender, index, sum),
            "Claim2stake call failed"
        );
    }

    //
    // ETH/ERC20 recovery
    //
    string internal constant ERR_NTR = "Nothing to recover";

    /**
        Recover accidentally send ETH or ERC20 tokens
        @param token address of ERC20 token contract, 0x0 if ETH recovery
        @param amount amount of coins/tokens to recover, 0=all
     */
    function recover(address token, uint256 amount) external onlyOwner {
        if (token == ZERO_ADDRESS) {
            uint256 balance = address(this).balance;
            require(balance > 0, ERR_NTR);
            if (amount > 0 && amount < balance) balance = amount;
            payable(owner).transfer(balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            require(balance > 0, ERR_NTR);
            if (token == tokenAddress) {
                balance -= vested; // vested tokens can not be removed
            }
            if (amount > 0 && amount < balance) balance = amount;

            require(IERC20(token).transfer(owner, balance), "");
        }
    }

    //
    // Imitate ERC20 token, show unclaimed tokens
    //

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    /**
        Read total unclaimed balance for given user
        @param user address to check
        @return amount of unclaimed tokens locked in contract
     */
    function balanceOf(address user) external view returns (uint256 amount) {
        uint256 len = _vestings[user].length;
        if (len > 0) {
            uint256 i;
            for (i; i < len; i++) {
                Vest memory v = _vestings[user][i];
                amount += (v.totalTokens - v.claimed);
            }
        }
    }

    /**
        Imitation of ERC20 transfer() function to claim from wallet.
        Ignoring parameters, returns true if claim succeed.
     */
    function transfer(address, uint256) external returns (bool) {
        uint256 sum = _claim(msg.sender, block.timestamp);
        require(
            IERC20(tokenAddress).transfer(msg.sender, sum),
            "" // will throw in token contract on transfer fail
        );
        return true;
    }
}