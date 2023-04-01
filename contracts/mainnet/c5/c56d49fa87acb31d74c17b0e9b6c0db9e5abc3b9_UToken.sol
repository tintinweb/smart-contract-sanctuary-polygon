/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


            
pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}



            
pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


 
pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


            
pragma solidity ^0.5.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

            
pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

            
pragma solidity 0.5.16;

/**
 * @title InterestRateModel Interface
 *  @dev Calculate the borrowers' interest rate.
 */
interface IInterestRateModel {
    /**
     *  @dev Update interest parameters event
     *  @param interestRate New interest rate, 1e18 = 100%
     */
    event LogNewInterestParams(uint256 interestRate);

    /**
     * @dev Check to see if it is a valid interest rate model
     * @return Return true for a valid interest rate model
     */
    function isInterestRateModel() external pure returns (bool);

    /**
     * @dev Calculates the current borrow interest rate per block
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate() external view returns (uint256);

    /**
     * @dev Calculates the current suppier interest rate per block
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(uint256 reserveFactorMantissa) external view returns (uint256);

    /**
     * @dev Set the borrow interest rate per block
     */
    function setInterestRate(uint256 interestRatePerBlock_) external;
}


            
pragma solidity 0.5.16;

interface IDai {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


            
pragma solidity 0.5.16;

/**
 *  @title AssetManager Interface
 *  @dev Manage the token balances staked by the users and deposited by admins, and invest tokens to the integrated underlying lending protocols.
 */
interface IAssetManager {
    /**
     *  @dev Emit when making a deposit
     *  @param token Depositing token address
     *  @param account Account address
     *  @param amount Deposit amount, in wei
     */
    event LogDeposit(address indexed token, address indexed account, uint256 amount);
    /**
     *  @dev Emit when withdrawing from AssetManager
     *  @param token Depositing token address
     *  @param account Account address
     *  @param amount Withdraw amount, in wei
     *  @param remaining The amount cannot be withdrawn
     */
    event LogWithdraw(address indexed token, address indexed account, uint256 amount, uint256 remaining);
    /**
     *  @dev Emit when rebalancing among the integrated money markets
     *  @param tokenAddress The address of the token to be rebalanced
     *  @param percentages Array of the percentages of the tokens to deposit to the money markets
     */
    event LogRebalance(address tokenAddress, uint256[] percentages);

    /**
     *  @dev Returns the balance of asset manager, plus the total amount of tokens deposited to all the underlying lending protocols.
     *  @param tokenAddress ERC20 token address
     *  @return Lending pool balance
     */
    function getPoolBalance(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Returns the amount of the lending pool balance minus the amount of total staked.
     *  @param tokenAddress ERC20 token address
     *  @return Amount can be borrowed
     */
    function getLoanableAmount(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols without side effects.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupply(address tokenAddress) external returns (uint256);

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols, but without side effects. Safe to call anytime, but may not get the most updated number for the current block. Call totalSupply() for that purpose.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupplyView(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Check if there is an underlying protocol available for the given ERC20 token.
     *  @param tokenAddress ERC20 token address
     *  @return Whether is supported
     */
    function isMarketSupported(address tokenAddress) external view returns (bool);

    /**
     *  @dev Deposit tokens to AssetManager, and those tokens will be passed along to adapters to deposit to integrated asset protocols if any is available.
     *  @param token ERC20 token address
     *  @param amount Deposit amount, in wei
     *  @return Deposited amount
     */
    function deposit(address token, uint256 amount) external returns (bool);

    /**
     *  @dev Withdraw from AssetManager
     *  @param token ERC20 token address
     *  @param account User address
     *  @param amount Withdraw amount, in wei
     *  @return Withdraw amount
     */
    function withdraw(
        address token,
        address account,
        uint256 amount
    ) external returns (bool);

    /**
     *  @dev Add a new ERC20 token to support in AssetManager
     *  @param tokenAddress ERC20 token address
     */
    function addToken(address tokenAddress) external;

    /**
     *  @dev Add a new adapter for the underlying lending protocol
     *  @param adapterAddress adapter address
     */
    function addAdapter(address adapterAddress) external;

    /**
     *  @dev For a give token set allowance for all integrated money markets
     *  @param tokenAddress ERC20 token address
     */
    function approveAllMarketsMax(address tokenAddress) external;

    /**
     *  @dev For a give moeny market set allowance for all underlying tokens
     *  @param adapterAddress Address of adaptor for money market
     */
    function approveAllTokensMax(address adapterAddress) external;

    /**
     *  @dev Set withdraw sequence
     *  @param newSeq priority sequence of money market indices to be used while withdrawing
     */
    function changeWithdrawSequence(uint256[] calldata newSeq) external;

    /**
     *  @dev Rebalance the tokens between integrated lending protocols
     *  @param tokenAddress ERC20 token address
     *  @param percentages Proportion
     */
    function rebalance(address tokenAddress, uint256[] calldata percentages) external;

    /**
     *  @dev Claim the tokens left on AssetManager balance, in case there are tokens get stuck here.
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokens(address tokenAddress, address recipient) external;

    /**
     *  @dev Claim the tokens stuck in the integrated adapters
     *  @param index MoneyMarkets array index
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokensFromAdapter(
        uint256 index,
        address tokenAddress,
        address recipient
    ) external;

    /**
     *  @dev Get the number of supported underlying protocols.
     *  @return MoneyMarkets length
     */
    function moneyMarketsCount() external view returns (uint256);

    /**
     *  @dev Get the count of supported tokens
     *  @return Number of supported tokens
     */
    function supportedTokensCount() external view returns (uint256);

    /**
     *  @dev Get the supported lending protocol
     *  @param tokenAddress ERC20 token address
     *  @param marketId MoneyMarkets array index
     *  @return tokenSupply
     */
    function getMoneyMarket(address tokenAddress, uint256 marketId) external view returns (uint256, uint256);

    /**
     *  @dev debt write off
     *  @param tokenAddress ERC20 token address
     *  @param amount WriteOff amount
     */
    function debtWriteOff(address tokenAddress, uint256 amount) external;
}

            
pragma solidity 0.5.16;

/**
 * @title UserManager Interface
 * @dev Manages the Union members credit lines, and their vouchees and borrowers info.
 */
interface IUserManager {
    /**
     *  @dev Update new credit limit model event
     *  @param newCreditLimitModel New credit limit model address
     */
    event LogNewCreditLimitModel(address newCreditLimitModel);

    /**
     *  @dev Add new member event
     *  @param member New member address
     */
    event LogAddMember(address member);

    /**
     *  @dev Update vouch for existing member event
     *  @param staker Trustee address
     *  @param borrower The address gets vouched for
     *  @param trustAmount Vouch amount
     */
    event LogUpdateTrust(address indexed staker, address indexed borrower, uint256 trustAmount);

    /**
     *  @dev New member application event
     *  @param account New member's voucher address
     *  @param borrower New member address
     */
    event LogRegisterMember(address indexed account, address indexed borrower);

    /**
     *  @dev Cancel vouching for other member event
     *  @param account New member's voucher address
     *  @param borrower The address gets vouched for
     */
    event LogCancelVouch(address indexed account, address indexed borrower);

    /**
     *  @dev Stake event
     *  @param account The staker's address
     *  @param amount The amount of tokens to stake
     */
    event LogStake(address indexed account, uint256 amount);

    /**
     *  @dev Unstake event
     *  @param account The staker's address
     *  @param amount The amount of tokens to unstake
     */
    event LogUnstake(address indexed account, uint256 amount);

    /**
     *  @dev DebtWriteOff event
     *  @param staker The staker's address
     *  @param borrower The borrower's address
     *  @param amount The amount of write off
     */
    event LogDebtWriteOff(address indexed staker, address indexed borrower, uint256 amount);

    /**
     *  @dev Check if the account is a valid member
     *  @param account Member address
     *  @return Address whether is member
     */
    function checkIsMember(address account) external view returns (bool);

    /**
     *  @dev Get member borrowerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getBorrowerAddresses(address account) external view returns (address[] memory);

    /**
     *  @dev Get member stakerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getStakerAddresses(address account) external view returns (address[] memory);

    /**
     *  @dev Get member backer asset
     *  @param account Member address
     *  @param borrower Borrower address
     *  @return Trust amount, vouch amount, and locked stake amount
     */
    function getBorrowerAsset(address account, address borrower)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     *  @dev Get member stakers asset
     *  @param account Member address
     *  @param staker Staker address
     *  @return Vouch amount and lockedStake
     */
    function getStakerAsset(address account, address staker)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     *  @dev Get the member's available credit line
     *  @param account Member address
     *  @return Limit
     */
    function getCreditLimit(address account) external view returns (int256);

    function totalStaked() external view returns (uint256);

    function totalFrozen() external view returns (uint256);

    function getFrozenCoinAge(address staker, uint256 pastBlocks) external view returns (uint256);

    /**
     *  @dev Add a new member
     *  Accept claims only from the admin
     *  @param account Member address
     */
    function addMember(address account) external;

    /**
     *  @dev Update the trust amount for exisitng members.
     *  @param borrower Borrower address
     *  @param trustAmount Trust amount
     */
    function updateTrust(address borrower, uint256 trustAmount) external;

    /**
     *  @dev Apply for membership, and burn UnionToken as application fees
     *  @param newMember New member address
     */
    function registerMember(address newMember) external;

    /**
     *  @dev Stop vouch for other member.
     *  @param staker Staker address
     *  @param account Account address
     */
    function cancelVouch(address staker, address account) external;

    /**
     *  @dev Change the credit limit model
     *  Accept claims only from the admin
     *  @param newCreditLimitModel New credit limit model address
     */
    function setCreditLimitModel(address newCreditLimitModel) external;

    /**
     *  @dev Get the user's locked stake from all his backed loans
     *  @param staker Staker address
     *  @return LockedStake
     */
    function getTotalLockedStake(address staker) external view returns (uint256);

    /**
     *  @dev Get staker's defaulted / frozen staked token amount
     *  @param staker Staker address
     *  @return Frozen token amount
     */
    function getTotalFrozenAmount(address staker) external view returns (uint256);

    /**
     *  @dev Update userManager locked info
     *  @param borrower Borrower address
     *  @param amount Borrow or repay amount(Including previously accrued interest)
     *  @param isBorrow True is borrow, false is repay
     */
    function updateLockedData(
        address borrower,
        uint256 amount,
        bool isBorrow
    ) external;

    /**
     *  @dev Get the user's deposited stake amount
     *  @param account Member address
     *  @return Deposited stake amount
     */
    function getStakerBalance(address account) external view returns (uint256);

    /**
     *  @dev Stake
     *  @param amount Amount
     */
    function stake(uint256 amount) external;

    /**
     *  @dev Unstake
     *  @param amount Amount
     */
    function unstake(uint256 amount) external;

    /**
     *  @dev Update total frozen
     *  @param account borrower address
     *  @param isOverdue account is overdue
     */
    function updateTotalFrozen(address account, bool isOverdue) external;

    /**
     *  @dev Repay user's loan overdue, called only from the lending market
     *  @param account User address
     *  @param lastRepay Last repay block number
     */
    function repayLoanOverdue(
        address account,
        address token,
        uint256 lastRepay
    ) external;
}

      
pragma solidity 0.5.16;

////import ";
////import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";

/**
 * @title Controller component
 * @dev For easy access to any core components
 */
contract Controller is Initializable {
    using Roles for Roles.Role;

    Roles.Role private _admins;
    bool private _paused;
    address public pauseGuardian;

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    modifier onlyAdmin() {
        require(
            _admins.has(msg.sender),
            "Controller: caller does not have the admin role"
        );
        _;
    }

    modifier onlyGuardian() {
        require(
            pauseGuardian == msg.sender,
            "Controller: caller does not have the guardian role"
        );
        _;
    }

    //When using minimal deploy, do not call initialize directly during deploy, because msg.sender is the proxyFactory address, and you need to call it manually
    function initialize(address admin_) public initializer {
        _paused = false;
        _admins.add(admin_);
        pauseGuardian = admin_;
    }

    /**
     * @dev Check if the address provided is the admin
     * @param account Account address
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    /**
     * @dev Add a new admin account
     * @param account Account address
     */
    function addAdmin(address account) public onlyAdmin {
        _admins.add(account);
    }

    /**
     * @dev Set pauseGuardian account
     * @param account Account address
     */
    function setGuardian(address account) public onlyAdmin {
        pauseGuardian = account;
    }

    /**
     * @dev Renouce the admin from the sender's address
     */
    function renounceAdmin() public {
        _admins.remove(msg.sender);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyGuardian whenNotPaused() {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyGuardian whenPaused() {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    uint256[50] private ______gap;
}



            
pragma solidity ^0.5.0;

////import ";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    uint256[50] private ______gap;
}

            
pragma solidity ^0.5.0;

////import ";
////import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

            
pragma solidity ^0.5.0;

////import ";

////import "../../GSN/Context.sol";
////import "./IERC20.sol";
////import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

            
pragma solidity ^0.5.0;

////import "./IERC20.sol";
////import "../../math/SafeMath.sol";
////import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity 0.5.16;

////import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
////import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
////import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
////import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
////import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

////import "../Controller.sol";
////import "../interfaces/IUserManager.sol";
////import "../interfaces/IAssetManager.sol";
////import "../interfaces/IDai.sol";
////import "../interfaces/IInterestRateModel.sol";

/**
 *  @title UToken Contract
 *  @dev Union accountBorrows can borrow and repay thru this component.
 */
contract UToken is Controller, ReentrancyGuard, ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public constant IS_UTOKEN = true;
    uint256 public constant WAD = 1e18;
    uint256 internal constant BORROW_RATE_MAX_MANTISSA = 0.0005e16; //Maximum borrow rate that can ever be applied (.0005% / block)
    uint256 internal constant RESERVE_FACTORY_MAX_MANTISSA = 1e18; //Maximum fraction of interest that can be set aside for reserves

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    address public underlying;
    IInterestRateModel public interestRateModel;
    uint256 internal initialExchangeRateMantissa; //Initial exchange rate used when minting the first UTokens (used when totalSupply = 0)
    uint256 public reserveFactorMantissa; //Fraction of interest currently set aside for reserves
    uint256 public accrualBlockNumber; //Block number that interest was last accrued at
    uint256 public borrowIndex; //Accumulator of the total earned interest rate since the opening of the market
    uint256 public totalBorrows; //Total amount of outstanding borrows of the underlying in this market
    uint256 public totalReserves; //Total amount of reserves of the underlying held in this marke
    uint256 public totalRedeemable; //Calculates the exchange rate from the underlying to the uToken
    uint256 public overdueBlocks; //overdue duration, based on the number of blocks
    uint256 public originationFee;
    uint256 public debtCeiling; //The debt limit for the whole system
    uint256 public maxBorrow;
    uint256 public minBorrow;
    address public assetManager;
    address public userManager;

    struct BorrowSnapshot {
        uint256 principal;
        uint256 interest;
        uint256 interestIndex;
        uint256 lastRepay; //Calculate if it is overdue
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    //A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /**
     *  @dev Change of the interest rate model
     *  @param oldInterestRateModel Old interest rate model address
     *  @param newInterestRateModel New interest rate model address
     */
    event LogNewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);

    event LogMint(address minter, uint256 underlyingAmount, uint256 uTokenAmount);

    event LogRedeem(address redeemer, uint256 redeemTokensIn, uint256 redeemAmountIn, uint256 redeemAmount);

    event LogReservesAdded(address reserver, uint256 actualAddAmount, uint256 totalReservesNew);

    event LogReservesReduced(address receiver, uint256 reduceAmount, uint256 totalReservesNew);

    /**
     *  @dev Event borrow
     *  @param account Member address
     *  @param amount Borrow amount
     *  @param fee Origination fee
     */
    event LogBorrow(address indexed account, uint256 amount, uint256 fee);

    /**
     *  @dev Event repay
     *  @param account Member address
     *  @param amount Repay amount
     */
    event LogRepay(address indexed account, uint256 amount);

    /**
     *  @dev modifier limit member
     */
    modifier onlyMember(address account) {
        require(IUserManager(userManager).checkIsMember(account), "UToken: caller is not a member");
        _;
    }

    modifier onlyAssetManager() {
        require(msg.sender == assetManager, "UToken: caller is not assetManager");
        _;
    }

    modifier onlyUserManager() {
        require(msg.sender == userManager, "UToken: caller is not userManager");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address underlying_,
        uint256 initialExchangeRateMantissa_,
        uint256 reserveFactorMantissa_,
        uint256 originationFee_,
        uint256 debtCeiling_,
        uint256 maxBorrow_,
        uint256 minBorrow_,
        uint256 overdueBlocks_,
        address admin_
    ) public initializer {
        require(initialExchangeRateMantissa_ > 0, "initial exchange rate must be greater than zero.");
        require(address(underlying_) != address(0), "underlying token is zero");
        require(
            reserveFactorMantissa_ >= 0 && reserveFactorMantissa_ <= RESERVE_FACTORY_MAX_MANTISSA,
            "reserveFactorMantissa error"
        );
        ERC20Detailed.initialize(name, symbol, decimals);
        Controller.initialize(admin_);
        ReentrancyGuard.initialize();
        underlying = underlying_;
        originationFee = originationFee_;
        debtCeiling = debtCeiling_;
        maxBorrow = maxBorrow_;
        minBorrow = minBorrow_;
        overdueBlocks = overdueBlocks_;
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        reserveFactorMantissa = reserveFactorMantissa_;
        accrualBlockNumber = getBlockNumber();
        borrowIndex = WAD;
    }

    function setAssetManager(address assetManager_) external onlyAdmin {
        assetManager = assetManager_;
    }

    function setUserManager(address userManager_) external onlyAdmin {
        userManager = userManager_;
    }

    /**
     *  @dev Change loan origination fee value
     *  Accept claims only from the admin
     *  @param originationFee_ Fees deducted for each loan transaction
     */
    function setOriginationFee(uint256 originationFee_) external onlyAdmin {
        originationFee = originationFee_;
    }

    /**
     *  @dev Update the market debt ceiling to a fixed amount, for example, 1 billion DAI etc.
     *  Accept claims only from the admin
     *  @param debtCeiling_ The debt limit for the whole system
     */
    function setDebtCeiling(uint256 debtCeiling_) external onlyAdmin {
        debtCeiling = debtCeiling_;
    }

    /**
     *  @dev Update the minimum loan size
     *  Accept claims only from the admin
     *  @param minBorrow_ Minimum loan amount per user
     */
    function setMinBorrow(uint256 minBorrow_) external onlyAdmin {
        minBorrow = minBorrow_;
    }

    /**
     *  @dev Update the max loan size
     *  Accept claims only from the admin
     *  @param maxBorrow_ Max loan amount per user
     */
    function setMaxBorrow(uint256 maxBorrow_) external onlyAdmin {
        maxBorrow = maxBorrow_;
    }

    /**
     *  @dev Change loan overdue duration, based on the number of blocks
     *  Accept claims only from the admin
     *  @param overdueBlocks_ Maximum late repayment block. The number of arrivals is a default
     */
    function setOverdueBlocks(uint256 overdueBlocks_) external onlyAdmin {
        overdueBlocks = overdueBlocks_;
    }

    /**
     *  @dev Change to a different interest rate model
     *  Accept claims only from the admin
     *  @param newInterestRateModel New interest rate model address
     */
    function setInterestRateModel(address newInterestRateModel) external onlyAdmin {
        _setInterestRateModelFresh(newInterestRateModel);
    }

    function setReserveFactor(uint256 reserveFactorMantissa_) external onlyAdmin {
        require(
            reserveFactorMantissa_ >= 0 && reserveFactorMantissa_ <= RESERVE_FACTORY_MAX_MANTISSA,
            "reserveFactorMantissa error"
        );
        reserveFactorMantissa = reserveFactorMantissa_;
    }

    /**
     *  @dev Returns the remaining amount that can be borrowed from the market.
     *  @return Remaining total amount
     */
    function getRemainingLoanSize() public view returns (uint256) {
        if (debtCeiling >= totalBorrows) {
            return debtCeiling.sub(totalBorrows);
        } else {
            return 0;
        }
    }

    /**
     *  @dev Get the last repay block
     *  @param account Member address
     *  @return Block number
     */
    function getLastRepay(address account) public view returns (uint256 lastRepay) {
        lastRepay = accountBorrows[account].lastRepay;
    }

    /**
     *  @dev Get member interest index
     *  @param account Member address
     *  @return Interest index
     */
    function getInterestIndex(address account) public view returns (uint256 interestIndex) {
        interestIndex = accountBorrows[account].interestIndex;
    }

    /**
     *  @dev Check if the member's loan is overdue
     *  @param account Member address
     *  @return Check result
     */
    function checkIsOverdue(address account) public view returns (bool isOverdue) {
        if (getBorrowed(account) == 0) {
            isOverdue = false;
        } else {
            uint256 lastRepay = getLastRepay(account);
            uint256 diff = getBlockNumber().sub(lastRepay);
            isOverdue = (overdueBlocks < diff);
        }
    }

    /**
     *  @dev Get the origination fee
     *  @param amount Amount to be calculated
     *  @return Handling fee
     */
    function calculatingFee(uint256 amount) public view returns (uint256) {
        return originationFee.mul(amount).div(WAD);
    }

    /**
     *  @dev Get member loan data
     *  @param member Member address
     *  @return Loan
     */
    function getLoan(address member)
        public
        view
        returns (
            uint256 principal,
            uint256 totalBorrowed,
            address asset,
            uint256 apr,
            int256 limit,
            bool isOverdue,
            uint256 lastRepay
        )
    {
        principal = accountBorrows[msg.sender].principal;
        totalBorrowed = borrowBalanceStoredInternal(member);
        asset = underlying;
        apr = borrowRatePerBlock();
        lastRepay = getLastRepay(member);
        limit = _getCreditLimit(member);
        isOverdue = checkIsOverdue(member);
    }

    /**
     *  @dev Get the borrowed principle
     *  @param account Member address
     *  @return Borrowed amount
     */
    function getBorrowed(address account) public view returns (uint256 borrowed) {
        borrowed = accountBorrows[account].principal;
    }

    /**
     *  @dev Get a member's current owed balance, including the principle and interest but without updating the user's states.
     *  @param account Member address
     *  @return Borrowed amount
     */
    function borrowBalanceView(address account) public view returns (uint256) {
        return accountBorrows[account].principal.add(calculatingInterest(account));
    }

    /**
     *  @dev Get a member's total owed, including the principle and the interest calculated based on the interest index.
     *  @param account Member address
     *  @return Borrowed amount
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
        BorrowSnapshot memory loan = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (loan.principal == 0) {
            return 0;
        }

        uint256 principalTimesIndex = loan.principal.add(loan.interest).mul(borrowIndex);
        return principalTimesIndex.div(loan.interestIndex);
    }

    /**
     *  @dev Get the borrowing interest rate per block
     *  @return Borrow rate
     */
    function borrowRatePerBlock() public view returns (uint256) {
        uint256 borrowRateMantissa = interestRateModel.getBorrowRate();
        require(borrowRateMantissa <= BORROW_RATE_MAX_MANTISSA, "borrow rate is absurdly high");
        return borrowRateMantissa;
    }

    /**
     * @notice Returns the current per-block supply interest rate for this UToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() public view returns (uint256) {
        return interestRateModel.getSupplyRate(reserveFactorMantissa);
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public nonReentrant returns (uint256) {
        require(accrueInterest(), "UToken: accrue interest failed");
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the UToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) {
            return initialExchangeRateMantissa;
        } else {
            return totalRedeemable.mul(WAD).div(totalSupply_);
        }
    }

    /**
     *  @dev Calculating member's borrowed interest
     *  @param account Member address
     *  @return Interest amount
     */
    function calculatingInterest(address account) public view returns (uint256) {
        BorrowSnapshot memory loan = accountBorrows[account];

        if (loan.principal == 0) {
            return 0;
        }

        uint256 borrowRate = borrowRatePerBlock();
        uint256 currentBlockNumber = getBlockNumber();
        uint256 blockDelta = currentBlockNumber.sub(accrualBlockNumber);
        uint256 simpleInterestFactor = borrowRate.mul(blockDelta);
        uint256 borrowIndexNew = simpleInterestFactor.mul(borrowIndex).div(WAD).add(borrowIndex);

        uint256 principalTimesIndex = loan.principal.add(loan.interest).mul(borrowIndexNew);
        uint256 balance = principalTimesIndex.div(loan.interestIndex);

        return balance.sub(accountBorrows[account].principal);
    }

    /**
     *  @dev Borrowing from the market
     *  Accept claims only from the member
     *  Borrow amount must in the range of creditLimit, minBorrow, maxBorrow, debtCeiling and not overdue
     *  @param amount Borrow amount
     */
    function borrow(uint256 amount) external onlyMember(msg.sender) whenNotPaused() nonReentrant {
        IAssetManager assetManagerContract = IAssetManager(assetManager);
        require(amount >= minBorrow, "UToken: amount less than loan size min");

        require(amount <= getRemainingLoanSize(), "UToken: amount more than loan global size max");

        uint256 fee = calculatingFee(amount);
        require(
            borrowBalanceView(msg.sender).add(amount).add(fee) <= maxBorrow,
            "UToken: amount large than borrow size max"
        );

        require(!checkIsOverdue(msg.sender), "UToken: Member has loans overdue");

        require(amount <= assetManagerContract.getLoanableAmount(underlying), "UToken: Not enough to lend out");
        require(
            uint256(_getCreditLimit(msg.sender)) >= amount.add(fee),
            "UToken: The loan amount plus fee is greater than credit limit"
        );

        require(accrueInterest(), "UToken: accrue interest failed");

        uint256 borrowedAmount = borrowBalanceStoredInternal(msg.sender);

        //Set lastRepay init data
        if (accountBorrows[msg.sender].lastRepay == 0) {
            accountBorrows[msg.sender].lastRepay = getBlockNumber();
        }

        uint256 accountBorrowsNew = borrowedAmount.add(amount).add(fee);
        uint256 totalBorrowsNew = totalBorrows.add(amount).add(fee);
        uint256 oldPrincipal = accountBorrows[msg.sender].principal;

        accountBorrows[msg.sender].principal = accountBorrows[msg.sender].principal.add(amount).add(fee);
        uint256 newPrincipal = accountBorrows[msg.sender].principal;
        IUserManager(userManager).updateLockedData(msg.sender, newPrincipal.sub(oldPrincipal), true);
        accountBorrows[msg.sender].interest = accountBorrowsNew.sub(accountBorrows[msg.sender].principal);
        accountBorrows[msg.sender].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;
        // The origination fees contribute to the reserve
        totalReserves = totalReserves.add(fee);

        require(assetManagerContract.withdraw(underlying, msg.sender, amount), "UToken: Failed to withdraw");

        emit LogBorrow(msg.sender, amount, fee);
    }

    function repayBorrow(uint256 repayAmount) external whenNotPaused() nonReentrant returns (uint256) {
        _repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        whenNotPaused()
        nonReentrant
        returns (uint256)
    {
        _repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    /**
     *  @dev Repay the loan
     *  Accept claims only from the member
     *  Updated member lastPaymentEpoch only when the repayment amount is greater than interest
     *  @param payer Payer address
     *  @param borrower Borrower address
     *  @param amount Repay amount
     */
    function _repayBorrowFresh(
        address payer,
        address borrower,
        uint256 amount
    ) private {
        IERC20 assetToken = IERC20(underlying);
        //In order to prevent the state from being changed, put the value at the top
        bool isOverdue = checkIsOverdue(borrower);
        uint256 oldPrincipal = accountBorrows[borrower].principal;
        require(accrueInterest(), "UToken: accrue interest failed");
        require(accrualBlockNumber == getBlockNumber(), "UToken: market not fresh");

        uint256 interest = calculatingInterest(borrower);
        uint256 borrowedAmount = borrowBalanceStoredInternal(borrower);

        uint256 repayAmount;
        if (amount > borrowedAmount) {
            repayAmount = borrowedAmount;
        } else {
            repayAmount = amount;
        }

        require(repayAmount > 0, "UToken: repay amount or owed amount is zero");

        require(assetToken.allowance(payer, address(this)) >= repayAmount, "UToken: Not enough allowance to repay");

        uint256 toReserveAmount;
        uint256 toRedeemableAmount;
        if (repayAmount >= interest) {
            toReserveAmount = interest.mul(reserveFactorMantissa).div(WAD);
            toRedeemableAmount = interest.sub(toReserveAmount);

            if (isOverdue) {
                IUserManager(userManager).updateTotalFrozen(borrower, false);
                IUserManager(userManager).repayLoanOverdue(borrower, underlying, accountBorrows[borrower].lastRepay);
            }
            accountBorrows[borrower].principal = borrowedAmount.sub(repayAmount);
            accountBorrows[borrower].interest = 0;

            if (accountBorrows[borrower].principal == 0) {
                //LastRepay is cleared when the arrears are paid off, and reinitialized the next time the loan is borrowed
                accountBorrows[borrower].lastRepay = 0;
            } else {
                accountBorrows[borrower].lastRepay = getBlockNumber();
            }
        } else {
            toReserveAmount = repayAmount.mul(reserveFactorMantissa).div(WAD);
            toRedeemableAmount = repayAmount.sub(toReserveAmount);
            accountBorrows[borrower].interest = interest.sub(repayAmount);
        }

        totalReserves = totalReserves.add(toReserveAmount);
        totalRedeemable = totalRedeemable.add(toRedeemableAmount);

        uint256 newPrincipal = accountBorrows[borrower].principal;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrows.sub(repayAmount);

        IUserManager(userManager).updateLockedData(borrower, oldPrincipal.sub(newPrincipal), false);

        assetToken.safeTransferFrom(payer, address(this), repayAmount);

        assetToken.safeApprove(assetManager, 0);
        assetToken.safeApprove(assetManager, repayAmount);

        require(IAssetManager(assetManager).deposit(underlying, repayAmount), "UToken: Deposit failed");

        emit LogRepay(borrower, repayAmount);
    }

    function repayBorrowWithPermit(
        address borrower,
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public whenNotPaused() {
        IDai erc20Token = IDai(underlying);
        erc20Token.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);

        _repayBorrowFresh(msg.sender, borrower, amount);
    }

    /**
     *  @dev Accrue interest
     *  @return Accrue interest finished
     */
    function accrueInterest() public returns (bool) {
        uint256 borrowRate = borrowRatePerBlock();
        uint256 currentBlockNumber = getBlockNumber();
        uint256 blockDelta = currentBlockNumber.sub(accrualBlockNumber);

        uint256 simpleInterestFactor = borrowRate.mul(blockDelta);
        uint256 interestAccumulated = simpleInterestFactor.mul(totalBorrows).div(WAD);
        uint256 totalBorrowsNew = interestAccumulated.add(totalBorrows);
        uint256 borrowIndexNew = simpleInterestFactor.mul(borrowIndex).div(WAD).add(borrowIndex);

        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;

        return true;
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256) {
        return exchangeRateCurrent().mul(balanceOf(owner));
    }

    function mint(uint256 mintAmount) external whenNotPaused() nonReentrant {
        require(accrueInterest(), "UToken: accrue interest failed");
        uint256 exchangeRate = exchangeRateStored();
        IERC20 assetToken = IERC20(underlying);
        uint256 balanceBefore = assetToken.balanceOf(address(this));
        require(assetToken.allowance(msg.sender, address(this)) >= mintAmount, "UToken: Not enough allowance");
        assetToken.safeTransferFrom(msg.sender, address(this), mintAmount);
        uint256 balanceAfter = assetToken.balanceOf(address(this));
        uint256 actualMintAmount = balanceAfter.sub(balanceBefore);
        totalRedeemable = totalRedeemable.add(actualMintAmount);
        uint256 mintTokens = actualMintAmount.mul(WAD).div(exchangeRate);
        _mint(msg.sender, mintTokens);

        assetToken.safeApprove(assetManager, 0);
        assetToken.safeApprove(assetManager, actualMintAmount);

        require(IAssetManager(assetManager).deposit(underlying, actualMintAmount), "UToken: Deposit failed");

        emit LogMint(msg.sender, actualMintAmount, mintTokens);
    }

    /**
     * @notice Sender redeems uTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of uTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external whenNotPaused() nonReentrant {
        require(accrueInterest(), "UToken: accrue interest failed");
        _redeemFresh(msg.sender, redeemTokens, 0);
    }

    /**
     * @notice Sender redeems uTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming uTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external whenNotPaused() nonReentrant {
        require(accrueInterest(), "UToken: accrue interest failed");
        _redeemFresh(msg.sender, 0, redeemAmount);
    }

    /**
     * @notice User redeems uTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of uTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming uTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    function _redeemFresh(
        address payable redeemer,
        uint256 redeemTokensIn,
        uint256 redeemAmountIn
    ) internal {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        IAssetManager assetManagerContract = IAssetManager(assetManager);

        uint256 exchangeRate = exchangeRateStored();

        uint256 redeemTokens;
        uint256 redeemAmount;

        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            redeemTokens = redeemTokensIn;
            redeemAmount = redeemTokensIn.mul(exchangeRate).div(WAD);
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */
            redeemTokens = redeemAmountIn.mul(WAD).div(exchangeRate);
            redeemAmount = redeemAmountIn;
        }

        require(totalRedeemable >= redeemAmount, "redeem amount error");
        totalRedeemable = totalRedeemable.sub(redeemAmount);
        _burn(redeemer, redeemTokens);

        require(assetManagerContract.withdraw(underlying, redeemer, redeemAmount), "UToken: Failed to withdraw");

        emit LogRedeem(redeemer, redeemTokensIn, redeemAmountIn, redeemAmount);
    }

    function addReserves(uint256 addAmount) external whenNotPaused() nonReentrant {
        require(accrueInterest(), "UToken: accrue interest failed");
        IERC20 assetToken = IERC20(underlying);
        uint256 balanceBefore = assetToken.balanceOf(address(this));
        require(assetToken.allowance(msg.sender, address(this)) >= addAmount, "UToken: Not enough allowance");
        assetToken.safeTransferFrom(msg.sender, address(this), addAmount);
        uint256 balanceAfter = assetToken.balanceOf(address(this));
        uint256 actualAddAmount = balanceAfter.sub(balanceBefore);

        uint256 totalReservesNew = totalReserves.add(actualAddAmount);
        /* Revert on overflow */
        require(totalReservesNew >= totalReserves, "add reserves unexpected overflow");
        totalReserves = totalReservesNew;

        assetToken.safeApprove(assetManager, 0);
        assetToken.safeApprove(assetManager, balanceAfter);

        require(IAssetManager(assetManager).deposit(underlying, balanceAfter), "UToken: Deposit failed");

        emit LogReservesAdded(msg.sender, actualAddAmount, totalReservesNew);
    }

    function removeReserves(address receiver, uint256 reduceAmount) external whenNotPaused() nonReentrant onlyAdmin {
        require(accrueInterest(), "UToken: accrue interest failed");
        require(reduceAmount <= totalReserves, "amount is large than totalReserves");

        IAssetManager assetManagerContract = IAssetManager(assetManager);

        uint256 totalReservesNew = totalReserves.sub(reduceAmount);
        // We checked reduceAmount <= totalReserves above, so this should never revert.
        require(totalReservesNew <= totalReserves, "reduce reserves unexpected underflow");

        totalReserves = totalReservesNew;

        require(assetManagerContract.withdraw(underlying, receiver, reduceAmount), "UToken: Failed to withdraw");

        emit LogReservesReduced(receiver, reduceAmount, totalReservesNew);
    }

    function debtWriteOff(address borrower, uint256 amount) external whenNotPaused() onlyUserManager {
        uint256 oldPrincipal = accountBorrows[borrower].principal;
        uint256 repayAmount;
        if (amount > oldPrincipal) {
            repayAmount = oldPrincipal;
        } else {
            repayAmount = amount;
        }

        accountBorrows[borrower].principal = oldPrincipal.sub(repayAmount);
        totalBorrows = totalBorrows.sub(repayAmount);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    function _setInterestRateModelFresh(address newInterestRateModel_) private {
        address oldInterestRateModel = address(interestRateModel);
        address newInterestRateModel = newInterestRateModel_;
        require(
            IInterestRateModel(newInterestRateModel).isInterestRateModel(),
            "UToken: new model is not a interestRateModel"
        );
        interestRateModel = IInterestRateModel(newInterestRateModel);

        emit LogNewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    /**
     *  @dev Update borrower overdue info
     *  @param account Borrower address
     */
    function updateOverdueInfo(address account) external whenNotPaused() {
        if (checkIsOverdue(account)) {
            IUserManager(userManager).updateTotalFrozen(account, true);
        }
    }

    /**
     *  @dev Batch update borrower overdue info
     *  @param accounts Borrowers address
     */
    function batchUpdateOverdueInfos(address[] calldata accounts) external whenNotPaused() {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (checkIsOverdue(accounts[i])) {
                IUserManager(userManager).updateTotalFrozen(accounts[i], true);
            }
        }
    }

    /**
     *  @dev Get a member's available credit limit
     *  @param account Member address
     *  @return Member credit limit
     */
    function _getCreditLimit(address account) private view returns (int256) {
        return IUserManager(userManager).getCreditLimit(account);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "UToken: EXPIRED");
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                getChainId(),
                address(this)
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "UToken: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}