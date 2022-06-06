/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// File: xvmc-contracts/libs/standard/Address.sol


pragma solidity >=0.6.12 <=0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: xvmc-contracts/libs/custom/IERC20.sol


pragma solidity >=0.6.12 <=0.8.0;
//original: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

//added functions for mint, burn, burnXVMC, transferXVMC and transferOwnership
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
	
	function mint(address to, uint256 amount) external;
	function burn(uint256 amount) external;
    function burnXVMC(address account, uint256 amount) external returns (bool);
	function transferXVMC(address _sender, address _recipient, uint256 _amount) external returns (bool);
	function transferOwnership(address newOwner) external;

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

// File: xvmc-contracts/libs/custom/SafeERC20.sol


pragma solidity >=0.6.12 <=0.8.0;
//original: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
//using transferXVMC instead of transferFrom for safeTransferFrom



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferXVMC.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: xvmc-contracts/rewardBoost.sol



pragma solidity 0.8.0;






interface IXVMCgovernor {
    function costToVote() external view returns (uint256);
    function maximumVoteTokens() external view returns (uint256);
    function delayBeforeEnforce() external view returns (uint256);
    function thresholdFibonaccening() external view returns (uint256);
    function eventFibonacceningActive() external view returns (bool);
    function setThresholdFibonaccening(uint256 newThreshold) external;
    function fibonacciDelayed() external returns (bool);
    function setInflation(uint256 newInflation) external;
    function delayFibonacci(bool _arg) external;
    function totalFibonacciEventsAfterGrand() external returns (uint256);
    function lastRegularReward() external returns (uint256);
    function blocksPerSecond() external returns (uint256);
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
	function burnFromOldChef(uint256 _amount) external;
	function setActivateFibonaccening(bool _arg) external;
	function isInflationStatic() external returns (bool);
	function consensusContract() external view returns (address);
	function postGrandFibIncreaseCount() external;
	function rememberReward() external;
}

interface IMasterChef {
    function XVMCPerBlock() external returns (uint256);
    function owner() external view returns (address);
}

interface IToken {
    function governor() external view returns (address);
}

interface IConsensus {
	function totalXVMCStaked() external view returns(uint256);
	function tokensCastedPerVote(uint256 _forID) external view returns(uint256);
}

// reward boost contract
// tldr; A reward boost is called 'Fibonaccening', could be compared to Bitcoin halvening
// When A threshold of tokens are collected, a reward boost event can be scheduled
// During the event there is a period of boosted rewards
// After the event ends, the tokens are burned and the global inflation is reduced
contract XVMCfibonaccening is Ownable {
    using SafeERC20 for IERC20;
    
    struct FibonacceningProposal {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
        uint256 rewardPerBlock;
        uint256 duration;
        uint256 startTime;
    }
    struct ProposeGrandFibonaccening{
        bool valid;
        uint256 eventDate; 
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
        uint256 finalSupply;
    }
    
    FibonacceningProposal[] public fibonacceningProposals;
    ProposeGrandFibonaccening[] public grandFibonacceningProposals;

    //WARNING: careful where we are using 1e18 and where not
    uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
    IERC20 public immutable token; //XVMC token
	
	address public immutable oldToken = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912;
	
	address public immutable oldMasterchef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
 
    
    //masterchef address
    address public masterchef;
    
    uint256 public lastCallFibonaccening; //stores timestamp of last grand fibonaccening event
    
    bool public eligibleGrandFibonaccening; // when big event is ready
    bool public grandFibonacceningActivated; // if upgrading the contract after event, watch out this must be true
    uint256 public desiredSupplyAfterGrandFibonaccening; // Desired supply to reach for Grand Fib Event
    
    uint256 public targetBlock; // used for calculating target block
    bool public isRunningGrand; //we use this during Grand Fib Event

    uint256 public fibonacceningActiveID;
    uint256 public fibonacceningActivatedBlock;
    
    bool public expiredGrandFibonaccening;
    
    uint256 public tokensForBurn; //tokens we draw from governor to burn for fib event

	uint256 public grandEventLength = 14 * 24 * 3600; // default Duration for the Grand Fibonaccening(the time in which 61.8% of the supply is printed)
	uint256 public delayBetweenEvents = 48 * 3600; // delay between when grand events can be triggered(default 48hrs)

    event ProposeFibonaccening(uint256 proposalID, uint256 valueSacrificedForVote, uint256 startTime, uint256 durationInBlocks, uint256 newRewardPerBlock , address indexed enforcer, uint256 delay);

    event EndFibonaccening(uint256 proposalID, address indexed enforcer);
    event CancleFibonaccening(uint256 proposalID, address indexed enforcer);
    
    event RebalanceInflation(uint256 newRewardPerBlock);
    
    event InitiateProposeGrandFibonaccening(uint256 proposalID, uint256 depositingTokens, uint256 eventDate, uint256 finalSupply, address indexed enforcer, uint256 delay);
	
	event AddVotes(uint256 _type, uint256 proposalID, address indexed voter, uint256 tokensSacrificed, bool _for);
	event EnforceProposal(uint256 _type, uint256 proposalID, address indexed enforcer, bool isSuccess);
    
    event ChangeGovernor(address newGovernor);
	
	constructor (IERC20 _XVMC, address _masterchef) {
		token = _XVMC;
		masterchef = _masterchef;
		
		fibonacceningProposals.push(
		    FibonacceningProposal(true, 0, 1e40, 0, 0, 169*1e21, 185000, 1654097100)
		    );
	}
    
    
    /**
     * Regulatory process for scheduling a "fibonaccening event"
    */    
    function proposeFibonaccening(uint256 depositingTokens, uint256 newRewardPerBlock, uint256 durationInBlocks, uint256 startTimestamp, uint256 delay) external {
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "costs to submit decisions");
        require(IERC20(token).balanceOf(owner()) >= IXVMCgovernor(owner()).thresholdFibonaccening(), "need to collect penalties before calling");
        require(!(IXVMCgovernor(owner()).eventFibonacceningActive()), "Event already running");
        require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
        require(
            startTimestamp > block.timestamp + delay + (24*3600) + IXVMCgovernor(owner()).delayBeforeEnforce() && 
            startTimestamp - block.timestamp <= 21 days, "max 21 days"); 
        require(
            (newRewardPerBlock * durationInBlocks) < (getTotalSupply() * 23 / 100),
            "Safeguard: Can't print more than 23% of tokens in single event"
        );
		require(newRewardPerBlock > goldenRatio || (!isRunningGrand && expiredGrandFibonaccening),
					"can't go below goldenratio"); //would enable grand fibonaccening
		//duration(in blocks) must be lower than amount of blocks mined in 30days(can't last more than roughly 30days)
		//30(days)*24(hours)*3600(seconds)  = 2592000
		uint256 amountOfBlocksIn30Days = 2592 * IXVMCgovernor(owner()).blocksPerSecond() / 1000;
		require(durationInBlocks <= amountOfBlocksIn30Days, "maximum 30days duration");
    
		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
        fibonacceningProposals.push(
            FibonacceningProposal(true, block.timestamp, depositingTokens, 0, delay, newRewardPerBlock, durationInBlocks, startTimestamp)
            );
    	
    	emit ProposeFibonaccening(fibonacceningProposals.length - 1, depositingTokens, startTimestamp, durationInBlocks, newRewardPerBlock, msg.sender, delay);
    }
	function voteFibonacceningY(uint256 proposalID, uint256 withTokens) external {
		require(fibonacceningProposals[proposalID].valid, "invalid");
		require(fibonacceningProposals[proposalID].firstCallTimestamp + fibonacceningProposals[proposalID].delay + IXVMCgovernor(owner()).delayBeforeEnforce() > block.timestamp, "past the point of no return"); 
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		fibonacceningProposals[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(0, proposalID, msg.sender, withTokens, true);
	}
	function voteFibonacceningN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(fibonacceningProposals[proposalID].valid, "invalid");
		require(fibonacceningProposals[proposalID].firstCallTimestamp + fibonacceningProposals[proposalID].delay + IXVMCgovernor(owner()).delayBeforeEnforce() > block.timestamp, "past the point of no return"); 
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		fibonacceningProposals[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoFibonaccening(proposalID); }
		
		emit AddVotes(0, proposalID, msg.sender, withTokens, false);
	}
    function vetoFibonaccening(uint256 proposalID) public {
    	require(fibonacceningProposals[proposalID].valid == true, "Invalid proposal"); 
		require(fibonacceningProposals[proposalID].firstCallTimestamp + fibonacceningProposals[proposalID].delay <= block.timestamp, "pending delay");
		require(fibonacceningProposals[proposalID].valueSacrificedForVote < fibonacceningProposals[proposalID].valueSacrificedAgainst, "needs more votes");
 
    	fibonacceningProposals[proposalID].valid = false; 
    	
    	emit EnforceProposal(0, proposalID, msg.sender, false);
    }

    /**
     * Activates a valid fibonaccening event
     * 
    */
    function leverPullFibonaccening(uint256 proposalID) public {
		require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
        require(
            IERC20(token).balanceOf(owner()) >= IXVMCgovernor(owner()).thresholdFibonaccening(),
            "needa collect penalties");
    	require(fibonacceningProposals[proposalID].valid == true, "invalid proposal");
    	require(block.timestamp >= fibonacceningProposals[proposalID].startTime, "can only start when set");
    	require(!(IXVMCgovernor(owner()).eventFibonacceningActive()), "already active");
		require(!grandFibonacceningActivated || (expiredGrandFibonaccening && !isRunningGrand), "not available during the grand boost event");
    	
    	if(fibonacceningProposals[proposalID].valueSacrificedForVote >= fibonacceningProposals[proposalID].valueSacrificedAgainst) {
			//IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote()); 
			tokensForBurn = IXVMCgovernor(owner()).thresholdFibonaccening();
			IERC20(token).safeTransferFrom(owner(), address(this), tokensForBurn); 
			
			IXVMCgovernor(owner()).rememberReward(); // remembers last regular rewar(before boost)
			IXVMCgovernor(owner()).setInflation(fibonacceningProposals[proposalID].rewardPerBlock);
			
			fibonacceningProposals[proposalID].valid = false;
			fibonacceningActiveID = proposalID;
			fibonacceningActivatedBlock = block.number;
			IXVMCgovernor(owner()).setActivateFibonaccening(true);
			
			emit EnforceProposal(0, proposalID, msg.sender, true);
		} else {
			vetoFibonaccening(proposalID);
		}
    }
    
     /**
     * Ends fibonaccening event 
     * sets new inflation  
     * burns the tokens
    */
    function endFibonaccening() external {
        require(IXVMCgovernor(owner()).eventFibonacceningActive(), "no active event");
        require(
            block.number >= fibonacceningActivatedBlock + fibonacceningProposals[fibonacceningActiveID].duration, 
            "not yet expired"
           ); 
        
        uint256 newAmount = calculateUpcomingRewardPerBlock();
        
        IXVMCgovernor(owner()).setInflation(newAmount);
        IXVMCgovernor(owner()).setActivateFibonaccening(false);
        
    	IERC20(token).burn(tokensForBurn); // burns the tokens - "fibonaccening" sacrifice
		IXVMCgovernor(owner()).burnFromOldChef(0); //burns all the tokens in old chef
		
		//if past 'grand fibonaccening' increase event count
		if(!isRunningGrand && expiredGrandFibonaccening) {
			IXVMCgovernor(owner()).postGrandFibIncreaseCount();
		}
		
    	emit EndFibonaccening(fibonacceningActiveID, msg.sender);
    }
    

    /**
     * In case we have multiple valid fibonaccening proposals
     * When the event is enforced, all other valid proposals can be invalidated
     * Just to clear up the space
    */
    function cancleFibonaccening(uint256 proposalID) external {
        require(IXVMCgovernor(owner()).eventFibonacceningActive(), "fibonaccening active required");

        require(fibonacceningProposals[proposalID].valid, "must be valid to negate ofc");
        
        fibonacceningProposals[proposalID].valid = false;
        emit CancleFibonaccening(proposalID, msg.sender);
    }
    
    /**
     * After the Grand Fibonaccening event, the inflation reduces to roughly 1.618% annually
     * On each new Fibonaccening event, it further reduces by Golden ratio(in percentile)
	 *
     * New inflation = Current inflation * ((100 - 1.618) / 100)
     */
    function rebalanceInflation() external {
        require(IXVMCgovernor(owner()).totalFibonacciEventsAfterGrand() > 0, "Only after the Grand Fibonaccening event");
        require(!(IXVMCgovernor(owner()).eventFibonacceningActive()), "Event is running");
		bool isStatic = IXVMCgovernor(owner()).isInflationStatic();
        
		uint256 initialSupply = getTotalSupply();
		uint256 _factor = goldenRatio;
		
		// if static, then inflation is 1.618% annually
		// Else the inflation reduces by 1.618%(annually) on each event
		if(!isStatic) {
			for(uint256 i = 0; i < IXVMCgovernor(owner()).totalFibonacciEventsAfterGrand(); i++) {
				_factor = _factor * 98382 / 100000; //factor is multiplied * 1000 (number is 1618, when actual factor is 1.618)
			}
		}
		
		// divide by 1000 to turn 1618 into 1.618% (and then divide farther by 100 to convert percentage)
        uint256 supplyToPrint = initialSupply * _factor / 100000; 
		
        uint256 rewardPerBlock = supplyToPrint / (365 * 24 * 36 * IXVMCgovernor(owner()).blocksPerSecond() / 10000);
        IXVMCgovernor(owner()).setInflation(rewardPerBlock);
       
        emit RebalanceInflation(rewardPerBlock);
    }
    
     /**
     * If inflation is to drop below golden ratio, the grand fibonaccening event is ready
	 * IMPORTANT NOTE: the math for the grand fibonaccening needs a lot of additional checks
	 * It is almost certain that fixes will be required. The event won't happen for quite some time.
	 * Giving enough time for additional fixes and changes to be adapted
     */
    function isGrandFibonacceningReady() external {
		require(!eligibleGrandFibonaccening);
        if((IMasterChef(masterchef).XVMCPerBlock() - goldenRatio * 1e18) <= goldenRatio * 1e18) { //we x1000'd the supply so 1e18
            eligibleGrandFibonaccening = true;
        }
    }

    /**
     * The Grand Fibonaccening Event, only happens once
	 * A lot of Supply is printed (x1.618 - x1,000,000)
	 * People like to buy on the way down
	 * People like high APYs
	 * People like to buy cheap coins
	 * Grand Fibonaccening ain't happening for quite some time... 
	 * We could add a requirement to vote through consensus for the "Grand Fibonaccening" to be enforced
     */    
    function initiateProposeGrandFibonaccening(uint256 depositingTokens, uint256 eventDate, uint256 finalSupply, uint256 delay) external {
    	require(eligibleGrandFibonaccening && !grandFibonacceningActivated);
		require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "there is a minimum cost to vote");
		uint256 _totalSupply = getTotalSupply();
    	require(finalSupply >= (_totalSupply * 1618 / 1000) && finalSupply <= (_totalSupply * 1000000));
    	require(eventDate > block.timestamp + delay + (7*24*3600) + IXVMCgovernor(owner()).delayBeforeEnforce());
    	
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	grandFibonacceningProposals.push(
    	    ProposeGrandFibonaccening(true, eventDate, block.timestamp, depositingTokens, 0, delay, finalSupply)
    	    );
    
        emit EnforceProposal(1, grandFibonacceningProposals.length - 1, msg.sender, true);
    }
	function voteGrandFibonacceningY(uint256 proposalID, uint256 withTokens) external {
		require(grandFibonacceningProposals[proposalID].valid, "invalid");
		require(grandFibonacceningProposals[proposalID].eventDate - (7*24*3600) > block.timestamp, "past the point of no return"); //can only be cancled up until 7days before event
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		grandFibonacceningProposals[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(1, proposalID, msg.sender, withTokens, true);
	}
	function voteGrandFibonacceningN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(grandFibonacceningProposals[proposalID].valid, "invalid");
		require(grandFibonacceningProposals[proposalID].eventDate - (7*24*3600) > block.timestamp, "past the point of no return"); //can only be cancled up until 7days before event
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		grandFibonacceningProposals[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoProposeGrandFibonaccening(proposalID); }

		emit AddVotes(1, proposalID, msg.sender, withTokens, false);
	}
	/*
	* can be vetto'd during delayBeforeEnforce period.
	* afterwards it can not be cancled anymore
	* but it can still be front-ran by earlier event
	*/
    function vetoProposeGrandFibonaccening(uint256 proposalID) public {
    	require(grandFibonacceningProposals[proposalID].valid, "already invalid");
		require(grandFibonacceningProposals[proposalID].firstCallTimestamp + grandFibonacceningProposals[proposalID].delay + IXVMCgovernor(owner()).delayBeforeEnforce() <= block.timestamp, "pending delay");
		require(grandFibonacceningProposals[proposalID].valueSacrificedForVote < grandFibonacceningProposals[proposalID].valueSacrificedAgainst, "needs more votes");

    	grandFibonacceningProposals[proposalID].valid = false;  
    	
    	emit EnforceProposal(1, proposalID, msg.sender, false);
    }
    
	
    function grandFibonacceningEnforce(uint256 proposalID) public {
        require(!grandFibonacceningActivated, "already called");
        require(grandFibonacceningProposals[proposalID].valid && grandFibonacceningProposals[proposalID].eventDate <= block.timestamp, "not yet valid");
		
		address _consensusContract = IXVMCgovernor(owner()).consensusContract();
		
		uint256 _totalStaked = IConsensus(_consensusContract).totalXVMCStaked();
		
		//to approve grand fibonaccening, more tokens have to be sacrificed for vote ++
		// more stakes(locked shares) need to vote in favor than against it
		//to vote in favor, simply vote for proposal ID of maximum uint256 number - 1
		uint256 _totalVotedInFavor = IConsensus(_consensusContract).tokensCastedPerVote(type(uint256).max - 1);
		uint256 _totalVotedAgainst= IConsensus(_consensusContract).tokensCastedPerVote(type(uint256).max);
		
        require(_totalVotedInFavor >= _totalStaked * 25 / 100
                    || _totalVotedAgainst >= _totalStaked * 25 / 100,
                             "minimum 25% weighted vote required");

		if(grandFibonacceningProposals[proposalID].valueSacrificedForVote >= grandFibonacceningProposals[proposalID].valueSacrificedAgainst
				&& _totalVotedInFavor > _totalVotedAgainst) {
			grandFibonacceningActivated = true;
			grandFibonacceningProposals[proposalID].valid = false;
			desiredSupplyAfterGrandFibonaccening = grandFibonacceningProposals[proposalID].finalSupply;
			
			emit EnforceProposal(1, proposalID, msg.sender, true);
		} else {
			grandFibonacceningProposals[proposalID].valid = false;  
    	
			emit EnforceProposal(1, proposalID, msg.sender, false);
		}
    }
    
    /**
     * Function handling The Grand Fibonaccening
	 *
     */
    function grandFibonacceningRunning() external {
        require(grandFibonacceningActivated && !expiredGrandFibonaccening);
        
        if(isRunningGrand){
            require(block.number >= targetBlock, "target block not yet reached");
            IXVMCgovernor(owner()).setInflation(0);
            isRunningGrand = false;
			
			//incentive to stop the event in time
			if(IERC20(token).balanceOf(owner()) >= IXVMCgovernor(owner()).costToVote() * 42) {
				IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote() * 42);
			}
        } else {
			require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
			uint256 _totalSupply = getTotalSupply();
            require(
                ( _totalSupply * goldenRatio * goldenRatio / 1000000) < desiredSupplyAfterGrandFibonaccening, 
                "Last 2 events happen at once"
                );
			// Just a simple implementation that allows max once per day at a certain time
            require(
                (block.timestamp % 86400) / 3600 >= 16 && (block.timestamp % 86400) / 3600 <= 18,
                "can only call between 16-18 UTC"
            );
			require(block.timestamp - lastCallFibonaccening > delayBetweenEvents);
			
			lastCallFibonaccening = block.timestamp;
            uint256 targetedSupply =  _totalSupply * goldenRatio / 1000;
			uint256 amountToPrint = targetedSupply - _totalSupply; // (+61.8%)
            
			//printing the amount(61.8% of supply) in uint256(grandEventLength) seconds ( blocks in second are x100 )
            uint256 rewardPerBlock = amountToPrint / (grandEventLength * IXVMCgovernor(owner()).blocksPerSecond() / 1000000); 
			targetBlock = block.number + (amountToPrint / rewardPerBlock);
            IXVMCgovernor(owner()).setInflation(rewardPerBlock);
			
            isRunningGrand = true;
        }
    
    }
    
    /**
     * During the last print of the Grand Fibonaccening
     * It prints up to "double the dose" in order to reach the desired supply
     * Why? to create a big decrease in the price, moving away from everyone's 
     * buy point. It creates a big gap with no overhead resistance, creating the potential for
     * the price to move back up effortlessly
     */
    function startLastPrintGrandFibonaccening() external {
        require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
        require(grandFibonacceningActivated && !expiredGrandFibonaccening && !isRunningGrand);
		uint256 _totalSupply = getTotalSupply();
        require(
             _totalSupply * goldenRatio * goldenRatio / 1000000 >= desiredSupplyAfterGrandFibonaccening,
            "on the last 2 we do it in one, call lastprint"
            );
        
		require(block.timestamp - lastCallFibonaccening > delayBetweenEvents, "pending delay");
        require((block.timestamp % 86400) / 3600 >= 16, "only after 16:00 UTC");
        
        uint256 rewardPerBlock = ( desiredSupplyAfterGrandFibonaccening -  _totalSupply ) / (grandEventLength * IXVMCgovernor(owner()).blocksPerSecond() / 1000000); //prints in desired time
		targetBlock = (desiredSupplyAfterGrandFibonaccening -  _totalSupply) / rewardPerBlock;
        IXVMCgovernor(owner()).setInflation(rewardPerBlock);
                
        isRunningGrand = true;
        expiredGrandFibonaccening = true;
    }
    function expireLastPrintGrandFibonaccening() external {
        require(isRunningGrand && expiredGrandFibonaccening);
        require(block.number >= (targetBlock-7));
        
		uint256 _totalSupply = getTotalSupply();
		uint256 tokensToPrint = (_totalSupply * goldenRatio) / 100000; // 1618 => 1.618 (/1000), 1.618 => 1.618% (/100)
		
        uint256 newEmissions =  tokensToPrint / (365 * 24 * 36 * IXVMCgovernor(owner()).blocksPerSecond() / 10000); 
		
        IXVMCgovernor(owner()).setInflation(newEmissions);
        isRunningGrand = false;
		
		//incentive to stop the event in time
		if(IERC20(token).balanceOf(owner()) >= IXVMCgovernor(owner()).costToVote() * 50) {
			IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote() * 50);
		}
    }
	
  function setMasterchef() external {
		masterchef = IMasterChef(address(token)).owner();
    }
    
    //transfers ownership of this contract to new governor
    //masterchef is the token owner, governor is the owner of masterchef
    function changeGovernor() external {
		_transferOwnership(IToken(address(token)).governor());
    }
    
    // this is unneccesary until the Grand Fibonaccening is actually to happen
    // Should perhaps add a proposal to regulate the length and delay
    function updateDelayBetweenEvents(uint256 _delay) external onlyOwner {
		delayBetweenEvents = _delay;
    }
    function updateGrandEventLength(uint256 _length) external onlyOwner {
    	grandEventLength = _length;
    }
    
    function getTotalSupply() private view returns (uint256) {
         return (token.totalSupply() +
					1000 * (IERC20(oldToken).totalSupply() - IERC20(oldToken).balanceOf(address(token))));
    }

    
    /**
     * After the Fibonaccening event ends, global inflation reduces
     * by -1.618 tokens/block prior to the Grand Fibonaccening and
     * by 1.618 percentile after the Grand Fibonaccening ( * ((100-1.618) / 100))
    */
    function calculateUpcomingRewardPerBlock() public returns(uint256) {
        if(!expiredGrandFibonaccening) {
            return IXVMCgovernor(owner()).lastRegularReward() - goldenRatio * 1e18;
        } else {
            return IXVMCgovernor(owner()).lastRegularReward() * 98382 / 100000; 
        }
    }
}