// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

struct InterestRateInfo {
    uint64 lastTimestamp;
    uint64 timeSpan; 
    uint64 ratePerSec;
    uint64 optimalUtilization;
    uint64 baseRate;
    uint64 slope1;
    uint64 slope2;
}

library InterestRate {
    uint256 public constant UTILIZATION_PRECISION = 1e5;

    function calculateInterestRate(
        InterestRateInfo memory _interestRateInfo,
        uint256 totalAssetAmount,
        uint256 totalBorrowAmount
    ) internal pure returns (uint256 _newRatePerSec) {
        uint256 utilization = (UTILIZATION_PRECISION * totalBorrowAmount) /
            totalAssetAmount;

        uint256 optimalUtilization = uint256(
            _interestRateInfo.optimalUtilization
        );
        uint256 baseRate = uint256(_interestRateInfo.baseRate); 
        uint256 slope1 = uint256(_interestRateInfo.slope1);
        uint256 slope2 = uint256(_interestRateInfo.slope2);

        if (utilization <= optimalUtilization) {
            uint256 _slope = (slope1 * UTILIZATION_PRECISION) / optimalUtilization;
            _newRatePerSec = uint64( baseRate * UTILIZATION_PRECISION + ((utilization * _slope)/UTILIZATION_PRECISION));
        } 
        else {
            uint256 _slope = ((slope2 * UTILIZATION_PRECISION) / (UTILIZATION_PRECISION - optimalUtilization));
            _newRatePerSec = uint256(baseRate * UTILIZATION_PRECISION + ((slope1 + (utilization - optimalUtilization) * _slope) / UTILIZATION_PRECISION));
        }
    }
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./InterestRate.sol";

pragma solidity ^0.8.7;

// All the error Codes
error LendHub__NeedMoreThanZero(uint256 amount);
error LendHub__NotSupplied();
error LendHub__CannotWithdrawMoreThanSupplied(uint256 amount);
error LendHub__CouldNotBorrowMoreThan80PercentOfCollateral();
error LendHub__ThisTokenIsNotAvailable(address tokenAddress);
error LendHub__NotAllowedBeforeRepayingExistingLoan(uint256 amount);
error LendHub__TransactionFailed();
error LendHub__SorryWeCurrentlyDoNotHaveThisToken(address tokenAddress);
error LendHub__UpKeepNotNeeded();
error InvalidLiquidation();
error BorrowerIsSolvant();
error TransferFailed();

contract LendHub is ReentrancyGuard, AutomationCompatibleInterface, Ownable {
    //store all the allowed token address
    address[] private LH_tokens_allowed;

    // store the list of supplier address
    address[] private LH_suppliers;

    // store the list of borrower address
    address[] private LH_borrowers;

    // stores the minimum time interval after which operations such as liquidation and interest rate charges are performed
    uint256 private immutable i_interval;

    // stores the last time stamp when operations such as liquidation and interest rate charges were performed
    uint256 private LH_lastTimeStamp;

    // Define the threshold after which liquidation takes place
    uint256 public constant LIQUIDATION_THRESHOLD = 80; // 80% --> if the supplied token of the user

    // Min health factor is used along with liquidation to help in liquidation process determination
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;

    // This is used to determine interest rate to a precision of 1e5
    uint256 public interestRatePrecision = 10e5;

    struct Pool {
        uint256 amount;
        uint256 interestrate;
        uint256 timestamp;
        uint256 timespan;
        uint256 totalborrow;
        InterestRateInfo interestinfo;
    }

    event TokenSupplied(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenWithdrawn(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenBorrowed(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenRepaid(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event Liquidated(address user, address liquidator);

    // tokenAddress -> structPool
    mapping(address => Pool) private LH_SupplyPool;

    // tokenAddress & user address -> their supplied balances
    mapping(address => mapping(address => uint256)) private LH_token_User_SupplyBalance;

    // tokenAddress & user adddress -> their borrowed balance
    mapping(address => mapping(address => uint256)) private LH_token_User_BorrowBalance;

    // token address -> price feeds
    mapping(address => AggregatorV3Interface) private LH_tokenPrices;

    // userAddress -> all of his unique supplied tokens
    mapping(address => address[]) private LH_supplierTokens;

    // userAddress -> all of his unique borrowed tokens
    mapping(address => address[]) private LH_borrowerTokens;

    modifier hasSupplied() {
        bool success;
        for (uint256 i = 0; i < LH_tokens_allowed.length; i++) {
            if (LH_token_User_SupplyBalance[LH_tokens_allowed[i]][msg.sender] > 0) {
                success = true;
            }
        }

        if (!success) {
            revert LendHub__NotSupplied();
        }
        _;
    }

    modifier notZero(uint256 amount) {
        if (amount <= 0) {
            revert LendHub__NeedMoreThanZero(amount);
        }
        _;
    }

    modifier isTokenAllowed(address tokenAddress) {
        bool execute;
        for (uint256 i = 0; i < LH_tokens_allowed.length; i++) {
            if (LH_tokens_allowed[i] == tokenAddress) {
                execute = true;
            }
        }
        if (!execute) {
            revert LendHub__ThisTokenIsNotAvailable(tokenAddress);
        }
        _;
    }

    //************************************  Main  contract functions start here

    InterestRateInfo public interestRateInfo =
        InterestRateInfo({
            lastTimestamp: 0, // Set this to your desired value
            timeSpan: 0, // Set this to your desired value
            ratePerSec: 0, // Set this to your desired value
            optimalUtilization: 80000, // 0.8 in fixed point format
            baseRate: 1, // Set this to your desired value
            slope1: 7000, // 0.07 in fixed point format
            slope2: 12000 // 1 in fixed point format
        });

    constructor(
        address[] memory allowedTokens,
        address[] memory priceFeeds,
        uint256 updateInterval
    ) {
        LH_tokens_allowed = allowedTokens;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            LH_tokenPrices[allowedTokens[i]] = AggregatorV3Interface(priceFeeds[i]);
            LH_SupplyPool[allowedTokens[i]].amount = 0;
            LH_SupplyPool[allowedTokens[i]].timespan = 0;
            LH_SupplyPool[allowedTokens[i]].interestinfo = interestRateInfo;
        }
        i_interval = updateInterval;
        LH_lastTimeStamp = block.timestamp;
    }

    function supply(
        address tokenAddress,
        uint256 amount
    ) external payable isTokenAllowed(tokenAddress) notZero(amount) nonReentrant {
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert LendHub__TransactionFailed();
        }
        LH_SupplyPool[tokenAddress].amount += amount;
        LH_token_User_SupplyBalance[tokenAddress][msg.sender] += amount;
        addSupplier(msg.sender);
        addUniqueToken(LH_supplierTokens[msg.sender], tokenAddress);
        emit TokenSupplied(tokenAddress, msg.sender, amount);
    }

    function withdraw(
        address tokenAddress,
        uint256 amount
    ) external payable hasSupplied notZero(amount) nonReentrant {
        if (amount > LH_token_User_SupplyBalance[tokenAddress][msg.sender]) {
            revert LendHub__CannotWithdrawMoreThanSupplied(amount);
        }

        revertIfHighBorrowing(tokenAddress, msg.sender, amount);
        LH_token_User_SupplyBalance[tokenAddress][msg.sender] -= amount;
        LH_SupplyPool[tokenAddress].amount -= amount;
        removeSupplierAndUniqueToken(tokenAddress, msg.sender);
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    function borrow(
        address tokenAddress,
        uint256 amount
    ) external payable isTokenAllowed(tokenAddress) hasSupplied notZero(amount) nonReentrant {
        if (LH_SupplyPool[tokenAddress].amount <= 0) {
            revert LendHub__SorryWeCurrentlyDoNotHaveThisToken(tokenAddress);
        }
        notMoreThanMaxBorrow(tokenAddress, msg.sender, amount);
        addBorrower(msg.sender);
        addUniqueToken(LH_borrowerTokens[msg.sender], tokenAddress);
        LH_token_User_BorrowBalance[tokenAddress][msg.sender] += amount;
        LH_SupplyPool[tokenAddress].amount -= amount;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenBorrowed(tokenAddress, msg.sender, amount);
    }

    function repay(
        address tokenAddress,
        uint256 amount
    ) external payable notZero(amount) nonReentrant {
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert LendHub__TransactionFailed();
        }
        LH_token_User_BorrowBalance[tokenAddress][msg.sender] -= amount;
        LH_SupplyPool[tokenAddress].amount += amount;
        if (LH_token_User_BorrowBalance[tokenAddress][msg.sender] == 0)
            removeBorrowerAndUniqueToken(tokenAddress, msg.sender);
        emit TokenRepaid(tokenAddress, msg.sender, amount);
    }

    function checkUpkeep(
        bytes memory
    ) public view override returns (bool upkeepNeeded, bytes memory) {
        bool hasUsers = (LH_borrowers.length > 0) || (LH_suppliers.length > 0);
        bool isTimePassed = (block.timestamp - LH_lastTimeStamp) > i_interval;
        upkeepNeeded = (hasUsers && isTimePassed);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert LendHub__UpKeepNotNeeded();
        }
        for (uint i = 0; i < LH_tokens_allowed.length; i++) {
            _calculateInterestRate(LH_tokens_allowed[i]);
            uint256 _newRate = LH_SupplyPool[LH_tokens_allowed[i]].interestrate;
            uint256 time = LH_SupplyPool[LH_tokens_allowed[i]].timespan;
            for (uint256 j = 0; j < LH_borrowers.length; j++) {
                uint256 interest = (LH_token_User_BorrowBalance[LH_tokens_allowed[i]][
                    LH_borrowers[j]
                ] *
                    time *
                    _newRate) / (interestRatePrecision * 1e18);
                LH_token_User_BorrowBalance[LH_tokens_allowed[i]][LH_borrowers[j]] += interest;
            }
            for (uint256 j = 0; j < LH_suppliers.length; j++) {
                uint256 interest = (LH_token_User_SupplyBalance[LH_tokens_allowed[i]][
                    LH_suppliers[j]
                ] *
                    time *
                    _newRate) / (interestRatePrecision * 1e18);
                LH_token_User_SupplyBalance[LH_tokens_allowed[i]][LH_suppliers[j]] += interest;
            }
        }

        // liquidate
        for (uint256 j = 0; j < LH_borrowers.length; j++) {
            if (healthFactor(LH_borrowers[j]) < MIN_HEALTH_FACTOR) {
                for (uint256 index = 0; index < LH_tokens_allowed.length; index++) {
                    LH_token_User_BorrowBalance[LH_tokens_allowed[index]][LH_borrowers[j]] = 0;
                    LH_token_User_SupplyBalance[LH_tokens_allowed[index]][LH_borrowers[j]] = 0;
                }
            }
        }

        LH_lastTimeStamp = block.timestamp;
    }

    function _calculateInterestRate(address token) internal {
        if (LH_SupplyPool[token].amount == 0) {
            return;
        } else if (LH_SupplyPool[token].timestamp == block.timestamp) {
            return;
        } else {
            uint256 _deltaTime = block.timestamp - LH_SupplyPool[token].timestamp;
            LH_SupplyPool[token].timespan = _deltaTime;

            uint256 _newRate = InterestRate.calculateInterestRate(
                LH_SupplyPool[token].interestinfo,
                this.getTokenTotalSupply(token),
                this.getTokenTotalBorrow(token)
            );

            LH_SupplyPool[token].interestrate = _newRate;
            LH_SupplyPool[token].timestamp = uint64(block.timestamp);
        }
    }

    function faucet(address tokenAddress) external {
        IERC20(tokenAddress).transfer(msg.sender, 10000 * 10 ** 18);
    }

    // Helper functions ////

    function revertIfHighBorrowing(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) private view {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            ((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80));

        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        uint256 askedAmountValue = amount * (price / 10 ** decimals);

        if (askedAmountValue > availableAmountValue) {
            revert LendHub__NotAllowedBeforeRepayingExistingLoan(amount);
        }
    }

    function notMoreThanMaxBorrow(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) private view {
        uint256 maxBorrow = getMaxBorrow(userAddress);
        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        uint256 askedAmountValue = amount * (price / 10 ** decimals);

        if (askedAmountValue > maxBorrow) {
            revert LendHub__CouldNotBorrowMoreThan80PercentOfCollateral();
        }
    }

    function addUniqueToken(address[] storage uniqueTokenArray, address tokenAddress) private {
        if (uniqueTokenArray.length == 0) {
            uniqueTokenArray.push(tokenAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < uniqueTokenArray.length; i++) {
                if (uniqueTokenArray[i] == tokenAddress) {
                    add = false;
                }
            }
            if (add) {
                uniqueTokenArray.push(tokenAddress);
            }
        }
    }

    function addSupplier(address userAddress) private {
        if (LH_suppliers.length == 0) {
            LH_suppliers.push(userAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < LH_suppliers.length; i++) {
                if (LH_suppliers[i] == userAddress) {
                    add = false;
                }
            }
            if (add) {
                LH_suppliers.push(userAddress);
            }
        }
    }

    function addBorrower(address userAddress) private {
        if (LH_borrowers.length == 0) {
            LH_borrowers.push(userAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < LH_borrowers.length; i++) {
                if (LH_borrowers[i] == userAddress) {
                    add = false;
                }
            }
            if (add) {
                LH_borrowers.push(userAddress);
            }
        }
    }

    function removeSupplierAndUniqueToken(address tokenAddress, address userAddress) private {
        if (LH_token_User_SupplyBalance[tokenAddress][userAddress] <= 0) {
            remove(LH_supplierTokens[userAddress], tokenAddress);
        }

        if (LH_supplierTokens[userAddress].length == 0) {
            remove(LH_suppliers, userAddress);
        }
    }

    function removeBorrowerAndUniqueToken(address tokenAddress, address userAddress) private {
        if (LH_token_User_BorrowBalance[tokenAddress][userAddress] <= 0) {
            remove(LH_borrowerTokens[userAddress], tokenAddress);
        }
        if (LH_borrowerTokens[userAddress].length == 0) {
            remove(LH_borrowers, userAddress);
        }
    }

    function remove(address[] storage array, address removingAddress) private {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == removingAddress) {
                array[i] = array[array.length - 1];
                array.pop();
            }
        }
    }

    ///   getter functions   ///

    function getTokenTotalSupply(address tokenAddress) external view returns (uint256) {
        return LH_SupplyPool[tokenAddress].amount;
    }

    function getTokenTotalBorrow(address tokenAddress) external view returns (uint256) {
        uint256 total = 0;
        for (uint64 i = 0; i < LH_borrowers.length; i++) {
            total += LH_token_User_BorrowBalance[tokenAddress][LH_borrowers[i]];
        }
        return total;
    }

    function getAllTokenSupplyInUsd() external view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < LH_tokens_allowed.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(LH_tokens_allowed[i]);

            totalValue += ((price / 10 ** decimals) * LH_SupplyPool[LH_tokens_allowed[i]].amount);
        }
        return totalValue;
    }

    function getSupplyBalance(
        address tokenAddress,
        address userAddress
    ) external view returns (uint256) {
        return LH_token_User_SupplyBalance[tokenAddress][userAddress];
    }

    function getBorrowedBalance(
        address tokenAddress,
        address userAddress
    ) external view returns (uint256) {
        return LH_token_User_BorrowBalance[tokenAddress][userAddress];
    }

    function getLatestPrice(address tokenAddress) public view returns (uint256, uint256) {
        (, int256 price, , , ) = LH_tokenPrices[tokenAddress].latestRoundData();
        uint256 decimals = uint256(LH_tokenPrices[tokenAddress].decimals());
        return (uint256(price), decimals);
    }

    function getMaxBorrow(address userAddress) public view returns (uint256) {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            ((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80));

        return (availableAmountValue * uint256(80)) / uint256(100);
    }

    function getMaxWithdraw(
        address tokenAddress,
        address userAddress
    ) external view returns (uint256) {
        uint256 availableAmount = LH_token_User_SupplyBalance[tokenAddress][userAddress] -
            ((uint256(100) * LH_token_User_BorrowBalance[tokenAddress][userAddress]) /
                uint256(80));

        return availableAmount;
    }

    function getMaxTokenBorrow(
        address tokenAddress,
        address userAddress
    ) external view returns (uint256) {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            ((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80));

        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        return ((availableAmountValue / (price / 10 ** decimals)) * uint256(80)) / uint256(100);
    }

    function getTotalSupplyValue(address userAddress) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < LH_tokens_allowed.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(LH_tokens_allowed[i]);

            totalValue += ((price / 10 ** decimals) *
                LH_token_User_SupplyBalance[LH_tokens_allowed[i]][userAddress]);
        }
        return totalValue;
    }

    function getTotalBorrowValue(address userAddress) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < LH_tokens_allowed.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(LH_tokens_allowed[i]);
            totalValue += ((price / 10 ** decimals) *
                LH_token_User_BorrowBalance[LH_tokens_allowed[i]][userAddress]);
        }
        return totalValue;
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return LH_tokens_allowed;
    }

    function getSuppliers() external view returns (address[] memory) {
        return LH_suppliers;
    }

    function getBorrowers() external view returns (address[] memory) {
        return LH_borrowers;
    }

    function getUserTotalCollateral(address user) public view returns (uint256 totalInDai) {
        uint256 len = LH_tokens_allowed.length;
        for (uint256 i; i < len; ) {
            address token = LH_tokens_allowed[i];

            uint256 tokenAmount = LH_token_User_SupplyBalance[token][user];

            if (tokenAmount != 0) {
                totalInDai += getTokenPrice(token) * tokenAmount;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getUserTotalBorrow(address user) public view returns (uint256 totalInDai) {
        uint256 len = LH_tokens_allowed.length;
        for (uint256 i; i < len; ) {
            address token = LH_tokens_allowed[i];

            uint256 tokenAmount = LH_token_User_BorrowBalance[token][user];
            if (tokenAmount != 0) {
                totalInDai += getTokenPrice(token) * tokenAmount;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getUserTokenCollateralAndBorrow(
        address user,
        address token
    ) external view returns (uint256 tokenCollateralAmount, uint256 tokenBorrowAmount) {
        tokenCollateralAmount = LH_token_User_SupplyBalance[token][user];
        tokenBorrowAmount = LH_token_User_BorrowBalance[token][user];
    }

    function healthFactor(address user) public view returns (uint256 factor) {
        uint256 totalCollateralAmount = getUserTotalCollateral(user);
        uint256 totalBorrowAmount = getUserTotalBorrow(user);

        if (totalBorrowAmount == 0) return 2 * MIN_HEALTH_FACTOR;

        uint256 collateralAmountWithThreshold = (totalCollateralAmount * LIQUIDATION_THRESHOLD) /
            100;
        factor = (collateralAmountWithThreshold * MIN_HEALTH_FACTOR) / totalBorrowAmount;
    }

    function getTokenPrice(address token) public view returns (uint256) {
        AggregatorV3Interface priceFeed = LH_tokenPrices[token];
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return uint256(price) / 10 ** decimals;
    }

    function getUniqueSupplierTokens(
        address userAddress
    ) external view returns (address[] memory) {
        return LH_supplierTokens[userAddress];
    }

    function getUniqueBorrowerTokens(
        address userAddress
    ) external view returns (address[] memory) {
        return LH_borrowerTokens[userAddress];
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getInterestRate(address token) external view returns (uint256) {
        return LH_SupplyPool[token].interestrate;
    }
}