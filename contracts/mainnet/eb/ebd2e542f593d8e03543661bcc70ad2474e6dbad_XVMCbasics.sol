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

// File: xvmc-contracts/basicSettings.sol


pragma solidity 0.8.0;






interface IXVMCgovernor {
    function costToVote() external view returns (uint256);
    function updateCostToVote(uint256 newCostToVote) external;
    function updateDelayBeforeEnforce(uint256 newDelay) external; 
    function delayBeforeEnforce() external view returns (uint256);
    function updateDurationForCalculation(uint256 newDuration) external;
    function setCallFee(address acPool, uint256 newCallFee) external;
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
	function updateRolloverBonus(address _forPool, uint256 bonus) external;
    function acPool1() external view returns (address);
    function acPool2() external view returns (address);
    function acPool3() external view returns (address);
    function acPool4() external view returns (address);
    function acPool5() external view returns (address);
    function acPool6() external view returns (address);
	function maximumVoteTokens() external view returns (uint256);
	function getTotalSupply() external view returns (uint256);
    function setThresholdFibonaccening(uint256 newThreshold) external;
    function updateGrandEventLength(uint256 _amount) external;
    function updateDelayBetweenEvents(uint256 _amount) external;
}

interface IToken {
    function governor() external view returns (address);
}

//compile with optimization enabled(60runs)
contract XVMCbasics is Ownable {
    using SafeERC20 for IERC20;

    address public immutable token; //XVMC token (address)
    
    //addresses for time-locked deposits(autocompounding pools)
    address public acPool1;
    address public acPool2;
    address public acPool3;
    address public acPool4;
    address public acPool5;
    address public acPool6;
    
    struct ProposalStructure {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay; //delay is basically time before users can vote against the proposal
        uint256 proposedValue;
    }
    struct RolloverBonusStructure {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
        address poolAddress;
        uint256 newBonus;
    }
    struct ParameterStructure {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay; //delay is basically time before users can vote against the proposal
        uint256 proposedValue1; // delay between events
        uint256 proposedValue2; // duration when the print happens
    }
    
    ProposalStructure[] public minDepositProposals;
    ProposalStructure[] public delayProposals;
    ProposalStructure[] public proposeDurationCalculation;
	ProposalStructure[] public callFeeProposal;
	RolloverBonusStructure[] public rolloverBonuses;
	ProposalStructure[] public minThresholdFibonacceningProposal; 
    ParameterStructure[] public grandSettingProposal;
	
	event ProposeMinDeposit(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedMinDeposit, address enforcer, uint256 delay);
    
    event DelayBeforeEnforce(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedMinDeposit, address enforcer, uint256 delay);
    
    event InitiateProposalDurationForCalculation(uint256 proposalID, uint256 duration, uint256 tokensSacrificedForVoting, address enforcer, uint256 delay);
    
    event InitiateSetCallFee(uint256 proposalID, uint256 depositingTokens, uint256 newCallFee, address enforcer, uint256 delay);
    
    event InitiateRolloverBonus(uint256 proposalID, uint256 depositingTokens, address forPool, uint256 newBonus, address enforcer, uint256 delay);
	
	event ProposeSetMinThresholdFibonaccening(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedMinDeposit, address indexed enforcer, uint256 delay);

    event ProposeSetGrandParameters(uint256 proposalID, uint256 valueSacrificedForVote, address indexed enforcer, uint256 delay, uint256 delayBetween, uint256 duration);
    
	
	event AddVotes(uint256 _type, uint256 proposalID, address indexed voter, uint256 tokensSacrificed, bool _for);
	event EnforceProposal(uint256 _type, uint256 proposalID, address indexed enforcer, bool isSuccess);

    event ChangeGovernor(address newGovernor);
    
	constructor(address _XVMC) {
		token = _XVMC;
	}
    
    /**
     * Regulatory process for determining "IXVMCgovernor(owner()).IXVMCgovernor(owner()).costToVote()()"
     * Anyone should be able to cast a vote
     * Since all votes are deemed valid, unless rejected
     * All votes must be manually reviewed
     * minimum IXVMCgovernor(owner()).costToVote() prevents spam
	 * Delay is the time during which you can vote in favor of the proposal(but can't veto/cancle it)
	 * Proposal is submitted. During delay you can vote FOR the proposal. After delay expires the proposal
	 * ... can be cancled(veto'd) if more tokens are commited against than in favor
	 * If not cancled, the proposal can be enforced after (delay + delayBeforeEnforce) expires
	 * ...under condition that more tokens have been sacrificed in favor rather than against
    */
    function initiateSetMinDeposit(uint256 depositingTokens, uint256 newMinDeposit, uint256 delay) external {
		require(newMinDeposit <= IXVMCgovernor(owner()).maximumVoteTokens(), 'Maximum 0.01% of all tokens');
		require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
    	
    	if (newMinDeposit < IXVMCgovernor(owner()).costToVote()) {
    		require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "Minimum cost to vote not met");
    		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	} else {
    		require(depositingTokens >= newMinDeposit, "Must match new amount");
    		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
    	}
		
		minDepositProposals.push(
    		        ProposalStructure(true, block.timestamp, depositingTokens, 0, delay, newMinDeposit)
    		   ); 
    	
    	emit ProposeMinDeposit(minDepositProposals.length - 1, depositingTokens, newMinDeposit, msg.sender, delay);
    }
	function voteSetMinDepositY(uint256 proposalID, uint256 withTokens) external {
		require(minDepositProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		minDepositProposals[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(0, proposalID, msg.sender, withTokens, true);
	}
	function voteSetMinDepositN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(minDepositProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		minDepositProposals[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoSetMinDeposit(proposalID); }

		emit AddVotes(0, proposalID, msg.sender, withTokens, false);
	}
    function vetoSetMinDeposit(uint256 proposalID) public {
    	require(minDepositProposals[proposalID].valid == true, "Proposal already invalid");
		require(minDepositProposals[proposalID].firstCallTimestamp + minDepositProposals[proposalID].delay < block.timestamp, "pending delay");
		require(minDepositProposals[proposalID].valueSacrificedForVote < minDepositProposals[proposalID].valueSacrificedAgainst, "needs more votes");

    	minDepositProposals[proposalID].valid = false;  
    	
    	emit EnforceProposal(0, proposalID, msg.sender, false);
    }
    function executeSetMinDeposit(uint256 proposalID) public {
    	require(
    	    minDepositProposals[proposalID].valid &&
    	    minDepositProposals[proposalID].firstCallTimestamp + minDepositProposals[proposalID].delay + IXVMCgovernor(owner()).delayBeforeEnforce() <= block.timestamp,
    	    "Conditions not met"
    	   );
		   
		 if(minDepositProposals[proposalID].valueSacrificedForVote >= minDepositProposals[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).updateCostToVote(minDepositProposals[proposalID].proposedValue); 
			minDepositProposals[proposalID].valid = false;
			
			emit EnforceProposal(0, proposalID, msg.sender, true);
		 } else {
			 vetoSetMinDeposit(proposalID);
		 }
    }

    
    /**
     * Regulatory process for determining "delayBeforeEnforce"
     * After a proposal is initiated, a period of time called
     * delayBeforeEnforce must pass, before the proposal can be enforced
     * During this period proposals can be vetod(voted against = rejected)
    */
    function initiateDelayBeforeEnforceProposal(uint256 depositingTokens, uint256 newDelay, uint256 delay) external { 
    	require(newDelay >= 1 days && newDelay <= 14 days && delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "Minimum 1 day");
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	delayProposals.push(
    	    ProposalStructure(true, block.timestamp, depositingTokens, 0, delay, newDelay)
    	   );  
		   
        emit DelayBeforeEnforce(delayProposals.length - 1, depositingTokens, newDelay, msg.sender, delay);
    }
	function voteDelayBeforeEnforceProposalY(uint256 proposalID, uint256 withTokens) external {
		require(delayProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		delayProposals[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(1, proposalID, msg.sender, withTokens, true);
	}
	function voteDelayBeforeEnforceProposalN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(delayProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		delayProposals[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoDelayBeforeEnforceProposal(proposalID); }

		emit AddVotes(1, proposalID, msg.sender, withTokens, false);
	}
    function vetoDelayBeforeEnforceProposal(uint256 proposalID) public {
    	require(delayProposals[proposalID].valid == true, "Proposal already invalid");
		require(delayProposals[proposalID].firstCallTimestamp + delayProposals[proposalID].delay < block.timestamp, "pending delay");
		require(delayProposals[proposalID].valueSacrificedForVote < delayProposals[proposalID].valueSacrificedAgainst, "needs more votes");
    	
    	delayProposals[proposalID].valid = false;  
		
    	emit EnforceProposal(1, proposalID, msg.sender, false);
    }
    function executeDelayBeforeEnforceProposal(uint256 proposalID) public {
    	require(
    	    delayProposals[proposalID].valid == true &&
    	    delayProposals[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + delayProposals[proposalID].delay < block.timestamp,
    	    "Conditions not met"
    	    );
        
		if(delayProposals[proposalID].valueSacrificedForVote >= delayProposals[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).updateDelayBeforeEnforce(delayProposals[proposalID].proposedValue); 
			delayProposals[proposalID].valid = false;
			
			emit EnforceProposal(1, proposalID, msg.sender, true);
		} else {
			vetoDelayBeforeEnforceProposal(proposalID);
		}
    }
    
  /**
     * Regulatory process for determining "durationForCalculation"
     * Not of great Use (no use until the "grand fibonaccening
     * Bitcoin difficulty adjusts to create new blocks every 10minutes
     * Our inflation is tied to the block production of Polygon network
     * In case the average block time changes significantly on the Polygon network  
     * the durationForCalculation is a period that we use to calculate 
     * average block time and consequentially use it to rebalance inflation
    */
    function initiateProposalDurationForCalculation(uint256 depositingTokens, uint256 duration, uint256 delay) external {
		require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");		
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "minimum cost to vote");
		require(duration <= 7 * 24 * 3600, "less than 7 days");
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	proposeDurationCalculation.push(
    	    ProposalStructure(true, block.timestamp, depositingTokens, 0, delay, duration)
    	    );  
    	    
        emit InitiateProposalDurationForCalculation(proposeDurationCalculation.length - 1, duration,  depositingTokens, msg.sender, delay);
    }
	function voteProposalDurationForCalculationY(uint256 proposalID, uint256 withTokens) external {
		require(proposeDurationCalculation[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		proposeDurationCalculation[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(2, proposalID, msg.sender, withTokens, true);
	}
	function voteProposalDurationForCalculationN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(proposeDurationCalculation[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		proposeDurationCalculation[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoProposalDurationForCalculation(proposalID); }

		emit AddVotes(2, proposalID, msg.sender, withTokens, false);
	}
    function vetoProposalDurationForCalculation(uint256 proposalID) public {
    	require(proposeDurationCalculation[proposalID].valid, "already invalid"); 
		require(proposeDurationCalculation[proposalID].firstCallTimestamp + proposeDurationCalculation[proposalID].delay < block.timestamp, "pending delay");
		require(proposeDurationCalculation[proposalID].valueSacrificedForVote < proposeDurationCalculation[proposalID].valueSacrificedAgainst, "needs more votes");

    	proposeDurationCalculation[proposalID].valid = false;  
    	
    	emit EnforceProposal(2, proposalID, msg.sender, false);
    }

    function executeProposalDurationForCalculation(uint256 proposalID) public {
    	require(
    	    proposeDurationCalculation[proposalID].valid &&
    	    proposeDurationCalculation[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + proposeDurationCalculation[proposalID].delay < block.timestamp,
    	    "conditions not met"
    	);
		if(proposeDurationCalculation[proposalID].valueSacrificedForVote >= proposeDurationCalculation[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).updateDurationForCalculation(proposeDurationCalculation[proposalID].proposedValue); 
			proposeDurationCalculation[proposalID].valid = false; 
			
			emit EnforceProposal(2, proposalID, msg.sender, true);
		} else {
			vetoProposalDurationForCalculation(proposalID);
		}
    }
    
  /**
     * Regulatory process for setting rollover bonuses
    */
    function initiateProposalRolloverBonus(uint256 depositingTokens, address _forPoolAddress, uint256 _newBonus, uint256 delay) external { 
		require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "minimum cost to vote");
		require(_newBonus <= 1500, "bonus too high, max 15%");
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	rolloverBonuses.push(
    	    RolloverBonusStructure(true, block.timestamp, depositingTokens, 0, delay, _forPoolAddress, _newBonus)
    	    );  
    	    
        emit InitiateRolloverBonus(rolloverBonuses.length - 1, depositingTokens, _forPoolAddress, _newBonus, msg.sender, delay);
    }
	function voteProposalRolloverBonusY(uint256 proposalID, uint256 withTokens) external {
		require(rolloverBonuses[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		rolloverBonuses[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(3, proposalID, msg.sender, withTokens, true);
	}
	function voteProposalRolloverBonusN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(rolloverBonuses[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		rolloverBonuses[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoProposalRolloverBonus(proposalID); }

		emit AddVotes(3, proposalID, msg.sender, withTokens, false);
	}
    function vetoProposalRolloverBonus(uint256 proposalID) public {
    	require(rolloverBonuses[proposalID].valid, "already invalid"); 
		require(rolloverBonuses[proposalID].firstCallTimestamp + rolloverBonuses[proposalID].delay < block.timestamp, "pending delay");
		require(rolloverBonuses[proposalID].valueSacrificedForVote < rolloverBonuses[proposalID].valueSacrificedAgainst, "needs more votes");
 
    	rolloverBonuses[proposalID].valid = false;  
    	
    	emit EnforceProposal(3, proposalID, msg.sender, false);
    }

    function executeProposalRolloverBonus(uint256 proposalID) public {
    	require(
    	    rolloverBonuses[proposalID].valid &&
    	    rolloverBonuses[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + rolloverBonuses[proposalID].delay < block.timestamp,
    	    "conditions not met"
    	);
        
		if(rolloverBonuses[proposalID].valueSacrificedForVote >= rolloverBonuses[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).updateRolloverBonus(rolloverBonuses[proposalID].poolAddress, rolloverBonuses[proposalID].newBonus); 
			rolloverBonuses[proposalID].valid = false; 
			
			emit EnforceProposal(3, proposalID, msg.sender, true);
		} else {
			vetoProposalRolloverBonus(proposalID);
		}
    }
    
    
	 /**
     * The auto-compounding effect is achieved with the help of the users that initiate the
     * transaction and pay the gas fee for re-investing earnings into the Masterchef
     * The call fee is paid as a reward to the user
     * This is handled in the auto-compounding contract
     * 
     * This is a process to change the Call fee(the reward) in the autocompounding contracts
     * This contract is an admin for the autocompound contract
     */
    function initiateSetCallFee(uint256 depositingTokens, uint256 newCallFee, uint256 delay) external { 
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "below minimum cost to vote");
    	require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
    	require(newCallFee <= 100, "maximum 1%");
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	callFeeProposal.push(
    	    ProposalStructure(true, block.timestamp, depositingTokens, 0, delay, newCallFee)
    	   );
    	   
        emit InitiateSetCallFee(callFeeProposal.length - 1, depositingTokens, newCallFee, msg.sender, delay);
    }
	function voteSetCallFeeY(uint256 proposalID, uint256 withTokens) external {
		require(callFeeProposal[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		callFeeProposal[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(4, proposalID, msg.sender, withTokens, true);
	}
	function voteSetCallFeeN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(callFeeProposal[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		callFeeProposal[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoSetCallFee(proposalID); }

		emit AddVotes(4, proposalID, msg.sender, withTokens, false);
	}
    function vetoSetCallFee(uint256 proposalID) public {
    	require(callFeeProposal[proposalID].valid == true, "Proposal already invalid");
		require(callFeeProposal[proposalID].firstCallTimestamp + callFeeProposal[proposalID].delay < block.timestamp, "pending delay");
		require(callFeeProposal[proposalID].valueSacrificedForVote < callFeeProposal[proposalID].valueSacrificedAgainst, "needs more votes");

    	callFeeProposal[proposalID].valid = false;
    	
    	emit EnforceProposal(4, proposalID, msg.sender, false);
    }
    function executeSetCallFee(uint256 proposalID) public {
    	require(
    	    callFeeProposal[proposalID].valid && 
    	    callFeeProposal[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + callFeeProposal[proposalID].delay < block.timestamp,
    	    "Conditions not met"
    	   );
        
		if(callFeeProposal[proposalID].valueSacrificedForVote >= callFeeProposal[proposalID].valueSacrificedAgainst) {

			IXVMCgovernor(owner()).setCallFee(acPool1, callFeeProposal[proposalID].proposedValue);
			IXVMCgovernor(owner()).setCallFee(acPool2, callFeeProposal[proposalID].proposedValue);
			IXVMCgovernor(owner()).setCallFee(acPool3, callFeeProposal[proposalID].proposedValue);
			IXVMCgovernor(owner()).setCallFee(acPool4, callFeeProposal[proposalID].proposedValue);
			IXVMCgovernor(owner()).setCallFee(acPool5, callFeeProposal[proposalID].proposedValue);
			IXVMCgovernor(owner()).setCallFee(acPool6, callFeeProposal[proposalID].proposedValue);
			
			callFeeProposal[proposalID].valid = false;
			
			emit EnforceProposal(4, proposalID, msg.sender, true);
		} else {
			vetoSetCallFee(proposalID);
		}
    }
	
    /**
     * Regulatory process for determining fibonaccening threshold,
     * which is the minimum amount of tokens required to be collected,
     * before a "fibonaccening" event can be scheduled;
     * 
     * Bitcoin has "halvening" events every 4 years where block rewards reduce in half
     * XVMC has "fibonaccening" events, which can can be scheduled once
     * this smart contract collects the minimum(threshold) of tokens. 
     * 
     * Tokens are collected as penalties from premature withdrawals, as well as voting costs inside this contract
     *
     * It's basically a mechanism to re-distribute the penalties(though the rewards can exceed the collected penalties)
     * 
     * It's meant to serve as a volatility-inducing event that attracts new users with high rewards
     * 
     * Effectively, the rewards are increased for a short period of time. 
     * Once the event expires, the tokens collected from penalties are
     * burned to give a sense of deflation AND the global inflation
     * for XVMC is reduced by a Golden ratio
    */
    function proposeSetMinThresholdFibonaccening(uint256 depositingTokens, uint256 newMinimum, uint256 delay) external {
        require(newMinimum >= IXVMCgovernor(owner()).getTotalSupply() / 1000, "Min 0.1% of supply");
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "Costs to vote");
        require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
        
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	minThresholdFibonacceningProposal.push(
    	    ProposalStructure(true, block.timestamp, depositingTokens, 0, delay, newMinimum)
    	    );
		
    	emit ProposeSetMinThresholdFibonaccening(
    	    minThresholdFibonacceningProposal.length - 1, depositingTokens, newMinimum, msg.sender, delay
    	   );
    }
	function voteSetMinThresholdFibonacceningY(uint256 proposalID, uint256 withTokens) external {
		require(minThresholdFibonacceningProposal[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		minThresholdFibonacceningProposal[proposalID].valueSacrificedForVote+= withTokens;
			
		emit AddVotes(5, proposalID, msg.sender, withTokens, true);
	}
	function voteSetMinThresholdFibonacceningN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(minThresholdFibonacceningProposal[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		minThresholdFibonacceningProposal[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoSetMinThresholdFibonaccening(proposalID); }

		emit AddVotes(5, proposalID, msg.sender, withTokens, false);
	}
    function vetoSetMinThresholdFibonaccening(uint256 proposalID) public {
    	require(minThresholdFibonacceningProposal[proposalID].valid == true, "Invalid proposal"); 
		require(minThresholdFibonacceningProposal[proposalID].firstCallTimestamp + minThresholdFibonacceningProposal[proposalID].delay <= block.timestamp, "pending delay");
		require(minThresholdFibonacceningProposal[proposalID].valueSacrificedForVote < minThresholdFibonacceningProposal[proposalID].valueSacrificedAgainst, "needs more votes");

    	minThresholdFibonacceningProposal[proposalID].valid = false;
    	
    	emit EnforceProposal(5, proposalID, msg.sender, false);
    }
    function executeSetMinThresholdFibonaccening(uint256 proposalID) public {
    	require(
    	    minThresholdFibonacceningProposal[proposalID].valid == true &&
    	    minThresholdFibonacceningProposal[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + minThresholdFibonacceningProposal[proposalID].delay < block.timestamp,
    	    "conditions not met"
        );
    	
		if(minThresholdFibonacceningProposal[proposalID].valueSacrificedForVote >= minThresholdFibonacceningProposal[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).setThresholdFibonaccening(minThresholdFibonacceningProposal[proposalID].proposedValue);
			minThresholdFibonacceningProposal[proposalID].valid = false; 
			
			emit EnforceProposal(5, proposalID, msg.sender, true);
		} else {
			vetoSetMinThresholdFibonaccening(proposalID);
		}
    }

    //proposal to set delay between events and duration during which the tokens are printed
    //this is only to be used for "the grand fibonaccening"... Won't happen for some time
    function proposeSetGrandParameters(uint256 depositingTokens, uint256 delay, uint256 _delayBetween, uint256 _duration) external {
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "Costs to vote");
        require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
        require(_delayBetween > 24*3600 && _delayBetween <= 7*24*3600, "not within range limits");
        require(_duration > 3600 && _duration < 14*24*3600, "not within range limits");
        
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	grandSettingProposal.push(
    	    ParameterStructure(true, block.timestamp, depositingTokens, 0, delay, _delayBetween, _duration)
    	    );
		
    	emit ProposeSetGrandParameters(
    	    grandSettingProposal.length - 1, depositingTokens, msg.sender, delay, _delayBetween, _duration
    	   );
    }
	function voteSetGrandParametersY(uint256 proposalID, uint256 withTokens) external {
		require(grandSettingProposal[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		grandSettingProposal[proposalID].valueSacrificedForVote+= withTokens;
			
		emit AddVotes(6, proposalID, msg.sender, withTokens, true);
	}
	function voteSetGrandParametersN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(grandSettingProposal[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		grandSettingProposal[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoSetGrandParameters(proposalID); }

		emit AddVotes(6, proposalID, msg.sender, withTokens, false);
	}
    function vetoSetGrandParameters(uint256 proposalID) public {
    	require(grandSettingProposal[proposalID].valid == true, "Invalid proposal"); 
		require(grandSettingProposal[proposalID].firstCallTimestamp + grandSettingProposal[proposalID].delay <= block.timestamp, "pending delay");
		require(grandSettingProposal[proposalID].valueSacrificedForVote < grandSettingProposal[proposalID].valueSacrificedAgainst, "needs more votes");

    	grandSettingProposal[proposalID].valid = false;
    	
    	emit EnforceProposal(6, proposalID, msg.sender, false);
    }
    function executeSetGrandParameters(uint256 proposalID) public {
    	require(
    	    grandSettingProposal[proposalID].valid == true &&
    	    grandSettingProposal[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + grandSettingProposal[proposalID].delay < block.timestamp,
    	    "conditions not met"
        );	
    	
		if(grandSettingProposal[proposalID].valueSacrificedForVote >= grandSettingProposal[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).updateDelayBetweenEvents(grandSettingProposal[proposalID].proposedValue1); //delay
            IXVMCgovernor(owner()).updateGrandEventLength(grandSettingProposal[proposalID].proposedValue2); //duration
			grandSettingProposal[proposalID].valid = false; 
			
			emit EnforceProposal(6, proposalID, msg.sender, true);
		} else {
			vetoSetGrandParameters(proposalID);
		}
    }

    //transfers ownership of this contract to new governor
    //masterchef is the token owner, governor is the owner of masterchef
    function changeGovernor() external {
		_transferOwnership(IToken(token).governor());
    }

    function updatePools() external {
        acPool1 = IXVMCgovernor(owner()).acPool1();
        acPool2 = IXVMCgovernor(owner()).acPool2();
        acPool3 = IXVMCgovernor(owner()).acPool3();
        acPool4 = IXVMCgovernor(owner()).acPool4();
        acPool5 = IXVMCgovernor(owner()).acPool5();
        acPool6 = IXVMCgovernor(owner()).acPool6();
    }

}