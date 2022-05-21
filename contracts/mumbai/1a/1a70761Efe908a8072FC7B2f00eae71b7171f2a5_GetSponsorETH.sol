//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "ILendingPool.sol";
import "SponsoredPools.sol";
import "Ownable.sol";
import "IERC20.sol";

// Allow staking
// Aave staking

contract GetSponsorETH is Ownable {
    // example strategy detail
    struct SponsorshipDetail {
        uint id;
        uint startTime;
        uint timeToExpiry;
        string pledge;
        bool isPerpetual;
    }

    uint constant MAX_TIME_TO_EXPIRY = 365 days;

    mapping(uint256 => address) public ownerOf;
    mapping(uint => SponsoredPools) public sponsoredPools;
    mapping(uint256 => SponsorshipDetail) public sponsorships;
    mapping(address => bool) public isAllowedToken;
    mapping(address => uint) minAmountFund;
    mapping(address => address) aTokens;
    uint256 _counter = 1;

    // interface to interact with aToken
    ILendingPool public lendingPool;

    event NewSponsor(uint256 indexed idx, address indexed owner, string pledge);
    event Fund(
        uint256 indexed idx,
        address indexed token,
        address indexed from,
        bool isStaking,
        string author,
        string message
    );
    event Config(uint256 indexed idx, string valName, string value);
    event TokenAllowanceUpdate(address token, bool isAllowed);
    event StakeWithdrawn(
        uint indexed sponsorshipId,
        address indexed token,
        address indexed staked
    );
    event Claimed(uint indexed sponsorshipId, address indexed token);

    constructor(address _lendingPool) {
        lendingPool = ILendingPool(_lendingPool);
    }

    function createSponsor(
        uint timeToExpiry,
        string calldata pledge,
        bool isPerpetual
    ) external {
        ownerOf[_counter] = msg.sender;
        emit NewSponsor(_counter, msg.sender, pledge);

        SponsorshipDetail memory details = SponsorshipDetail({
            id: _counter,
            startTime: block.timestamp,
            timeToExpiry: timeToExpiry,
            pledge: pledge,
            isPerpetual: isPerpetual
        });
        sponsorships[_counter] = details;

        SponsoredPools sp = new SponsoredPools();
        sp.init(lendingPool, address(this), msg.sender);
        sponsoredPools[_counter] = sp;
        unchecked {
            _counter++;
        }
    }

    function fund(
        uint sponsorshipId,
        address token,
        bool isStaking,
        uint amount,
        string calldata user,
        string calldata message
    ) external payable {
        require(isAllowedToken[token], "!allowed token");
        require(amount >= minAmountFund[token], "small amount");
        require(_isNotExpired(sponsorshipId), "expired");

        if (isStaking) {
            _fundWithStaking(sponsorshipId, msg.sender, token, amount);
        } else {
            _fund(sponsorshipId, msg.sender, token, amount);
        }

        emit Fund(sponsorshipId, token, msg.sender, isStaking, user, message);
    }

    function withdrawStake(uint sponsorshipId, address token) external {
        SponsoredPools sp = sponsoredPools[sponsorshipId];
        sp.unstake(msg.sender, token);
        emit StakeWithdrawn(sponsorshipId, token, msg.sender);
    }

    function claim(uint sponsorshipId, address token) external {
        SponsoredPools sp = sponsoredPools[sponsorshipId];
        address aToken = aTokens[token];
        sp.claim(token, aToken);
        emit Claimed(sponsorshipId, token);
    }

    function config(
        uint256 sponsorId,
        string calldata valName,
        string calldata value
    ) public {
        require(ownerOf[sponsorId] == msg.sender, "not allowed");
        emit Config(sponsorId, valName, value);
    }

    function updateAllowed(
        address token,
        address aToken,
        bool isAllowed,
        uint minAmount
    ) external onlyOwner {
        require(isAllowedToken[token] != isAllowed, "!update");
        isAllowedToken[token] = isAllowed;

        if (isAllowed) {
            minAmountFund[token] = minAmount;
            IERC20(token).approve(address(lendingPool), type(uint256).max);
            aTokens[token] = aToken;
        } else {
            minAmountFund[token] = 0;
            IERC20(token).approve(address(lendingPool), 0);
        }

        emit TokenAllowanceUpdate(token, isAllowed);
    }

    function _fund(
        uint sponsorshipId,
        address sender,
        address token,
        uint amount
    ) internal {
        address owner = ownerOf[sponsorshipId];
        require(owner != address(0), "Sponsor not found");
        require(
            IERC20(token).transferFrom(sender, owner, amount),
            "transfer failed"
        );
    }

    function _fundWithStaking(
        uint sponsorshipId,
        address sender,
        address token,
        uint amount
    ) internal {
        address owner = ownerOf[sponsorshipId];
        require(owner != address(0), "Sponsor not found");
        require(
            IERC20(token).transferFrom(sender, address(this), amount),
            "transfer failed"
        );

        // get sponsored pool
        SponsoredPools sp = sponsoredPools[sponsorshipId];
        // Mint aToken and send it to contract address
        address aToken = aTokens[token];
        lendingPool.deposit(token, amount, address(sp), 0);
        sp.stake(sender, token, amount);
    }

    function _isNotExpired(uint sponsorshipId)
        internal
        view
        returns (bool isExpired)
    {
        SponsorshipDetail memory details = sponsorships[sponsorshipId];
        isExpired =
            details.isPerpetual ||
            (details.startTime + details.timeToExpiry) > block.timestamp;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "ILendingPoolAddressesProvider.sol";

interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  
  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "ILendingPool.sol";
import "GetSponsorETH.sol";
import "Ownable.sol";
import "IERC20.sol";

contract SponsoredPools is Ownable {
    GetSponsorETH public sponsorEth;
    address public beneficiary;
    ILendingPool public lendingPool;

    // supporter => amount
    mapping(address => uint256) public supporters;
    // token => supporter => amount
    mapping(address => mapping(address => uint)) tokensStaked;
    mapping(address => uint) totalStaked;

    function init(
        ILendingPool _lendingPool,
        address _sponsorEth,
        address _beneficiary
    ) public {
        require(beneficiary == address(0), "already initialized");

        sponsorEth = GetSponsorETH(_sponsorEth);
        beneficiary = _beneficiary;
        lendingPool = _lendingPool;
    }

    // Stakes the sent tokens
    function stake(
        address supporter,
        address token,
        uint amount
    ) public payable onlyOwner {
        tokensStaked[token][supporter] += amount;
        totalStaked[token] += amount;
    }

    // Unstake tokens for supporter
    function unstake(address supporter, address token) public onlyOwner {
        uint unstakeAmount = tokensStaked[token][supporter];
        require(unstakeAmount > 0, "no stake");
        tokensStaked[token][supporter] = 0;
        totalStaked[token] -= unstakeAmount;
        lendingPool.withdraw(token, unstakeAmount, supporter);
    }

    // claim yield generated by stake
    function claim(address token, address aToken) public onlyOwner {
        uint256 amount = claimable(token, aToken);
        lendingPool.withdraw(token, amount, beneficiary);
    }

    // claimable returns total stake claimable
    function claimable(address token, address aToken)
        public
        view
        returns (uint256 claimAmount)
    {
        uint total = totalStaked[token];
        uint aBalance = IERC20(aToken).balanceOf(address(this));
        claimAmount = aBalance - total;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}