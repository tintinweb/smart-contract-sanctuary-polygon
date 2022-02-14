/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

/**
 *  SourceUnit: evveland/contracts/vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
    Ownership contract
    Modified https://eips.ethereum.org/EIPS/eip-173
    Added ownership transfer confirmation to prevent form giving ownership to wrong address
 */
contract Ownable {
    /// Current contract owner
    address public owner;
    /// New contract owner to be confirmed
    address public newOwner;
    /// Emit on every owner change
    event OwnershipChanged(address indexed from, address indexed to);

    /**
        Set default owner as contract deployer
     */
    constructor() {
        owner = msg.sender;
    }

    /**
        Use this modifier to limit function to contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only for Owner");
        _;
    }

    /**
        Prepare to change ownersip. New owner need to confirm it.
        @param user address delegated to be new contract owner
     */
    function giveOwnership(address user) external onlyOwner {
        require(user != address(0x0), "renounceOwnership() instead");
        newOwner = user;
    }

    /**
        Accept contract ownership by new owner.
     */
    function acceptOwnership() external {
        require(
            newOwner != address(0x0) && msg.sender == newOwner,
            "Only newOwner can accept"
        );
        emit OwnershipChanged(owner, newOwner);
        owner = newOwner;
        delete newOwner;
    }

    /**
        Renounce ownership of the contract.
        Any function uses "onlyOwner" modifier will be inaccessible.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipChanged(owner, address(0x0));
        delete owner;
    }
}

/**
 *  SourceUnit: evveland/contracts/vesting.sol
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
 *  SourceUnit: evveland/contracts/vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC20.sol";
////import "./Ownable.sol";

/**
    ERC20 token and native coin recovery functions
 */
abstract contract Recoverable is Ownable {
    string internal constant ERR_NOTHING = "Nothing to recover";

    /// Recover native coin from contract
    function recoverETH() external onlyOwner {
        uint256 amt = address(this).balance;
        require(amt > 0, ERR_NOTHING);
        payable(owner).transfer(amt);
    }

    /**
        Recover ERC20 token from contract
        @param token address of token to witdraw
        @param amount of tokens to withdraw (if 0 - take all, useful for "pay fee" tokens)
     */
    function recoverERC20(address token, uint256 amount)
        external
        virtual
        onlyOwner
    {
        uint256 amt = IERC20(token).balanceOf(address(this));
        require(amt > 0, ERR_NOTHING);
        if (amount != 0) {
            amt = amount;
        }
        IERC20(token).transfer(owner, amt);
    }
}

/**
 *  SourceUnit: evveland/contracts/vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
    Minimal interface for future Stake contract
    Functions needed by Vesting contract
 */
interface IStake {
    /// Vesting contract address
    function vestingAddress() external view returns (address);

    /// Function to call by vesting contract
    function claim2stake(address user, uint256 amount) external returns (bool);

    /// Event emited on successfull stake
    event Staked(address indexed user, uint256 amount);
}

/**
 *  SourceUnit: evveland/contracts/vesting.sol
 */

//SPDX-License-Identifier: MIT

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

    /**
        Get all vestings for given user.
        Will return empty array if no vests configured.
        @param user address to list
        @return array of vests
     */
    function getVestings(address user) external view returns (Vest[] memory);

    /**
        Return number of vestings for given user
        @param user address to check
        @return number of vestings for user
     */
    function getVestingCount(address user) external view returns (uint256);

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
 *  SourceUnit: evveland/contracts/vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.10;

////import "./IVesting.sol";
////import "./Ownable.sol";
////import "./IERC20.sol";
////import "./IStake.sol";
////import "./Recovery.sol";

/**
    Vesting contract for EVVELAND projct
 */
contract EvveVesting is IVesting, Ownable, Recoverable {
    /// address of EVVE token
    address public immutable tokenAddress;

    /// amount of vested tokens
    uint256 public vested;

    // vesting list per user, can be multiple per user
    mapping(address => Vest[]) private _vestings;

    //
    // constructor
    //
    /**
        Contract constructor
        @param token address to be used in contract
     */
    constructor(address token) {
        tokenAddress = token;
    }

    /**
        Create vesting for user.
        Owner need to approve contract earlier and have tokens on address.
        @param user address of user that can claim from lock
        @param startDate timestamp when user can start caliming and get startTokens
        @param endDate timestamp after which totalTokens can be claimed
        @param startTokens tokens released at startDate (cliff)
        @param totalTokens total number of coins to be released
     */
    function createVest(
        address user,
        uint256 startDate,
        uint256 endDate,
        uint256 startTokens,
        uint256 totalTokens
    ) external {
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                totalTokens
            ),
            "Token transfer failed!" // this will revert in token
        );
        require(user != address(0x0), "Zero address");
        require(totalTokens > 0, "Zero amount");
        require(endDate > startDate, "Timestamps missconfigured");
        require(startDate > block.timestamp, "startDate below current time");
        // prevent from someone to spam contract
        require(_vestings[user].length < 10, "Too many vestings");

        Vest memory c = Vest(startDate, endDate, startTokens, totalTokens, 0);
        _vestings[user].push(c);
        vested += totalTokens;
        emit VestAdded(user, startDate, endDate, startTokens, totalTokens);
    }

    /**
        Check how much tokens can be claimed at given moment
        @param user address to calculate
        @return sum number of tokens to claim (with 18 decimals)
    */
    function claimable(address user) external view returns (uint256 sum) {
        uint256 len = _vestings[user].length;
        if (len > 0) {
            uint256 time = block.timestamp;
            uint256 i;
            for (i; i < len; i++) {
                sum += _claimable(_vestings[user][i], time);
            }
        }
    }

    /**
        Count number of tokens claimable form given vesting
        @param c Vesting struct data
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
                uint256 pct = ((time - c.startDate) * 1 ether) /
                    (c.endDate - c.startDate);
                amt =
                    c.startTokens +
                    ((c.totalTokens - c.startTokens) * pct) /
                    1 ether;
            }
            amt -= c.claimed; // some may be already claimed
        }
    }

    /**
       Claim all possible tokens
    */
    function claim() external {
        uint256 sum = _claim(msg.sender);
        require(
            IERC20(tokenAddress).transfer(msg.sender, sum),
            "" // will fail in token on transfer error
        );
    }

    /**
        Internal claim function
        @param user address to calculate
        @return sum number of tokens claimed
     */
    function _claim(address user) internal returns (uint256 sum) {
        uint256 len = _vestings[user].length;
        require(len > 0, "No locks for user");
        uint256 time = block.timestamp;
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

    /**
        All vestings of given address in one call
        @param user address to check
        @return tuple of all locks
     */
    function getVestings(address user) public view returns (Vest[] memory) {
        return _vestings[user];
    }

    /**
        Check number of vestings for given user
        @param user address to check
        @return number of vestings for user
     */
    function getVestingCount(address user) external view returns (uint256) {
        return _vestings[user].length;
    }

    /**
        Return single vesting info
        @param user address to check
        @param index of vesting to show
     */
    function getVesting(address user, uint256 index)
        external
        view
        returns (Vest memory)
    {
        require(index < _vestings[user].length, "Index out of range");
        return _vestings[user][index];
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
        require(stakeAddress == address(0x0), "Contract already set");
        // Check in stake contract that this contract is referred
        require(
            IStake(stake).vestingAddress() == address(this),
            "Wrong contract address"
        );
        // approve stake contract to pull tokens from vesting
        require(
            IERC20(tokenAddress).approve(stake, type(uint256).max),
            "Token approval failed"
        );
        // set contract variable
        stakeAddress = stake;
    }

    /**
        Claim possible tokens and stake directly to contract
     */
    function claim2stake() external {
        require(stakeAddress != address(0x0), "Stake contract not set");
        // get all tokens that user can claim
        uint256 sum = _claim(msg.sender);
        // call stake contract to take tokens and stake for user
        require(
            IStake(stakeAddress).claim2stake(msg.sender, sum),
            "Claim2stake call failed"
        );
    }

    //
    // Token recovery override, disallow vested tokens withdrawal
    //
    function recoverERC20(address token, uint256 amount)
        external
        override
        onlyOwner
    {
        uint256 amt = IERC20(token).balanceOf(address(this));

        if (token == tokenAddress) {
            amt -= vested;
        } else {
            if (amount != 0 && amount < amt) amt = amount;
        }
        require(amt > 0, ERR_NOTHING);
        IERC20(token).transfer(owner, amt);
    }

    //
    // Imitate ERC20 token, show unclaimed tokens
    //

    string public constant name = "vested Evveland";
    string public constant symbol = "vEVVE";
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
        uint256 sum = _claim(msg.sender);
        require(
            IERC20(tokenAddress).transfer(msg.sender, sum),
            "" // will throw in token contract on transfer fail
        );
        return true;
    }
}