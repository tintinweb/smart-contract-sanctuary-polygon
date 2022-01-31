/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: newo.sol



pragma solidity 0.8.0;


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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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

interface IXVMCgovernor {
    function costToVote() external returns (uint256);
    function updateCostToVote(uint256 newCostToVote) external;
    function maximumVoteTokens() external returns (uint256);
    function updateDelayBeforeEnforce(uint256 newDelay) external; 
    function delayBeforeEnforce() external returns (uint256);
    function updateDurationForCalculation(uint256 newDuration) external;
    function setCallFee(address acPool, uint256 newCallFee, uint256 newCallFeeWithBonus) external;
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
}

contract XVMCbasics is Ownable {
    using SafeERC20 for IERC20;

    address public immutable token = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912; //XVMC token
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    //addresses for time-locked deposits(autocompounding pools)
    address public immutable acPool1 = 0x5E126F2d2483ce77e8c7D51ef1134e078A24849b;
    address public immutable acPool2 = 0x4d13bAD6F93E7bC48884940E66171C0987Ea8362;
    address public immutable acPool3 = 0xA54c234d231DDa3a907B22A18b494a5652B6D4f7;
    address public immutable acPool4 = 0x6ce6D8015BcefcF80FFb04E21965dd011FFd392c;
    address public immutable acPool5 = 0x151F1EC31F7429107396D88e9417e4720BF5E680;
    address public immutable acPool6 = 0x9e24A3Fcc61f24b899be12bBdB4cB1063f3AA387;
    
    struct ProposalMinDeposit {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
        uint256 proposedMinDeposit;
    }
    struct ProposeDelayBeforeEnforce {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
        uint256 proposedValue;
    }	
    struct ProposalDurationForCalculation {
        bool valid;
        uint256 duration;
        uint256 tokensSacrificedForVoting;
        uint256 firstCallTimestamp;
    }
    struct ProposalCallFee {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
        uint256 newCallFee;
        uint256 newCallFeeWithBonus;
    }
    
    ProposalMinDeposit[] public minDepositProposals;
    ProposeDelayBeforeEnforce[] public delayProposals;
    ProposalDurationForCalculation[] public proposeDurationCalculation;
	ProposalCallFee[] public callFeeProposal;
	
	event ProposeMinDeposit(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedMinDeposit, address enforcer);
    event VetoSetMinDeposit(uint256 proposalID, address enforcer);
    event ExecuteSetMinDeposit(uint256 proposalID, address enforcer);
    
    event DelayBeforeEnforce(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedMinDeposit, address enforcer);
    event VetoDelayBeforeEnforce(uint256 proposalID, address enforcer);
    event ExecuteDelayBeforeEnforce(uint256 proposalID, address enforcer);
    
    event InitiateProposalDurationForCalculation(uint256 proposalID, uint256 duration, uint256 tokensSacrificedForVoting, address enforcer);
    event VetoProposalDurationForCalculation(uint256 proposalID, address enforcer);
    event ExecuteProposalDurationForCalculation(uint256 proposalID, address enforcer);
    
    event InitiateSetCallFee(uint256 proposalID, uint256 depositingTokens, uint256 newCallFee, uint256 newCallFeeWithBonus, address enforcer);
    event VetoSetCallFee(uint256 proposalID, address enforcer);
    event ExecuteSetCallFee(uint256 proposalID, address enforcer);
    
    event ChangeGovernor(address newGovernor);
    
    modifier whenReady() {
      require(block.timestamp > 1636384802, "after Nov 8");
      _;
    }
    
    /**
     * Regulatory process for determining "IXVMCgovernor(ourMaster).IXVMCgovernor(ourMaster).costToVote()()"
     * Anyone should be able to cast a vote
     * Since all votes are deemed valid, unless rejected
     * All votes must be manually reviewed
     * minimum IXVMCgovernor(ourMaster).costToVote() prevents spam
    */
    function initiateSetMinDeposit(uint256 depositingTokens, uint256 newMinDeposit) external whenReady {
    	require(depositingTokens <= getTotalSupply() / 10000, "Anyone should be able to cast votes");
    	
    	if (newMinDeposit < IXVMCgovernor(owner()).costToVote()) {
    		require(depositingTokens == IXVMCgovernor(owner()).costToVote(), "Minimum cost to vote not met");
    		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    		minDepositProposals.push(
    		    ProposalMinDeposit(true, block.timestamp, depositingTokens, newMinDeposit)
    		   );
    	} else {
    		require(depositingTokens == newMinDeposit, "Must match new amount");
    		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
    		    minDepositProposals.push(
    		        ProposalMinDeposit(true, block.timestamp, depositingTokens, newMinDeposit)
    		   ); 
    	}
    	
    	emit ProposeMinDeposit(minDepositProposals.length - 1, depositingTokens, newMinDeposit, msg.sender);
    }
    function vetoSetMinDeposit(uint256 proposalID) external whenReady {
    	require(minDepositProposals[proposalID].valid == true, "Proposal already invalid");

    	IERC20(token).safeTransferFrom(msg.sender, owner(), minDepositProposals[proposalID].valueSacrificedForVote); 
    	minDepositProposals[proposalID].valid = false;  
    	
    	emit VetoSetMinDeposit(proposalID, msg.sender);
    }
    function executeSetMinDeposit(uint256 proposalID) external whenReady {
    	require(
    	    minDepositProposals[proposalID].valid &&
    	    minDepositProposals[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "Conditions not met"
    	   );

    	IXVMCgovernor(owner()).updateCostToVote(minDepositProposals[proposalID].proposedMinDeposit); 
    	minDepositProposals[proposalID].valid = false;
    	
    	emit ExecuteSetMinDeposit(proposalID, msg.sender);
    }

    
    /**
     * Regulatory process for determining "delayBeforeEnforce"
     * After a proposal is initiated, a period of time called
     * delayBeforeEnforce must pass, before the proposal can be enforced
     * This is the period of time where proposals can be voted against
	 * Small "flaw": you could Veto proposals just before they expire, wasting time
    */
    function initiateDelayBeforeEnforceProposal(uint256 depositingTokens, uint256 newDelay) external whenReady { 
    	require(newDelay >= 1 days, "Minimum 1 day");
    	require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "Preventing tyranny");
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	delayProposals.push(
    	    ProposeDelayBeforeEnforce(true, block.timestamp, depositingTokens, newDelay)
    	   );  
		   
        emit DelayBeforeEnforce(delayProposals.length - 1, depositingTokens, newDelay, msg.sender);
    }
    function vetoDelayBeforeEnforceProposal(uint256 proposalID) external whenReady {
    	require(delayProposals[proposalID].valid == true, "Proposal already invalid");
    	
		IERC20(token).safeTransferFrom(msg.sender, owner(), delayProposals[proposalID].valueSacrificedForVote); 
    	delayProposals[proposalID].valid = false;  
		
    	emit VetoDelayBeforeEnforce(proposalID, msg.sender);
    }
    function executeDelayBeforeEnforceProposal(uint256 proposalID) external whenReady {
    	require(
    	    delayProposals[proposalID].valid == true &&
    	    delayProposals[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "Conditions not met"
    	    );
        
    	IXVMCgovernor(owner()).updateDelayBeforeEnforce(delayProposals[proposalID].proposedValue); 
    	delayProposals[proposalID].valid = false;
		
    	emit ExecuteDelayBeforeEnforce(proposalID, msg.sender);
    }
    
  /**
     * Regulatory process for determining "durationForCalculation"
     * Not of great Use
     * Bitcoin difficulty adjusts to create new blocks every 10minutes
     * Our inflation is tied to the block production of Polygon network
     * In case the average block time changes significantly on the Polygon network  
     * the durationForCalculation is a period that we use to calculate 
     * average block time and consequentially use it to rebalance inflation
    */
    function initiateProposalDurationForCalculation(uint256 depositingTokens, uint256 duration) external whenReady { 
    	require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "No tyranny");
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "minimum cost to vote");
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	proposeDurationCalculation.push(
    	    ProposalDurationForCalculation(true, duration, depositingTokens, block.timestamp)
    	    );  
    	    
        emit InitiateProposalDurationForCalculation(proposeDurationCalculation.length - 1, duration,  depositingTokens, msg.sender);
    }
    function vetoProposalDurationForCalculation(uint256 proposalID) external whenReady {
    	require(minDepositProposals[proposalID].valid, "already invalid"); 
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), proposeDurationCalculation[proposalID].tokensSacrificedForVoting);
    	proposeDurationCalculation[proposalID].valid = false;  
    	
    	emit VetoProposalDurationForCalculation(proposalID, msg.sender);
    }

    function executeProposalDurationForCalculation(uint256 proposalID) external whenReady {
    	require(
    	    proposeDurationCalculation[proposalID].valid &&
    	    proposeDurationCalculation[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "conditions not met"
    	);
        
        IXVMCgovernor(owner()).updateDurationForCalculation(proposeDurationCalculation[proposalID].duration); 
    	proposeDurationCalculation[proposalID].valid = false; 
    	
    	emit ExecuteProposalDurationForCalculation(proposalID, msg.sender);
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
    function initiateSetCallFee(uint256 depositingTokens, uint256 newCallFee, uint256 newCallFeeWithBonus) external whenReady { 
    	require(depositingTokens == IXVMCgovernor(owner()).costToVote(), "Costs to vote");
    	require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "preventing tyranny, maximum 0.05% of tokens");
    	require(newCallFee >= 0 && newCallFee <= 100);
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	callFeeProposal.push(
    	    ProposalCallFee(true, block.timestamp, depositingTokens, newCallFee, newCallFeeWithBonus)
    	   );
    	   
        emit InitiateSetCallFee(callFeeProposal.length - 1, depositingTokens, newCallFee, newCallFeeWithBonus, msg.sender);
    }
    function vetoSetCallFee(uint256 proposalID) external whenReady {
    	require(callFeeProposal[proposalID].valid == true, "Proposal already invalid");

    	IERC20(token).safeTransferFrom(msg.sender, owner(), callFeeProposal[proposalID].valueSacrificedForVote); 
    	callFeeProposal[proposalID].valid = false;
    	
    	emit VetoSetCallFee(proposalID, msg.sender);
    }
    function executeSetCallFee(uint256 proposalID) external whenReady {
    	require(
    	    callFeeProposal[proposalID].valid && 
    	    callFeeProposal[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "Conditions not met"
    	   );
        
        IXVMCgovernor(owner()).setCallFee(acPool1, callFeeProposal[proposalID].newCallFee, callFeeProposal[proposalID].newCallFeeWithBonus);
        IXVMCgovernor(owner()).setCallFee(acPool2, callFeeProposal[proposalID].newCallFee, callFeeProposal[proposalID].newCallFeeWithBonus);
        IXVMCgovernor(owner()).setCallFee(acPool3, callFeeProposal[proposalID].newCallFee, callFeeProposal[proposalID].newCallFeeWithBonus);
        IXVMCgovernor(owner()).setCallFee(acPool4, callFeeProposal[proposalID].newCallFee, callFeeProposal[proposalID].newCallFeeWithBonus);
        IXVMCgovernor(owner()).setCallFee(acPool5, callFeeProposal[proposalID].newCallFee, callFeeProposal[proposalID].newCallFeeWithBonus);
        IXVMCgovernor(owner()).setCallFee(acPool6, callFeeProposal[proposalID].newCallFee, callFeeProposal[proposalID].newCallFeeWithBonus);
        
        callFeeProposal[proposalID].valid = false;
        
        emit ExecuteSetCallFee(proposalID, msg.sender);
    }

    //transfers ownership of this contract to new governor(if eligible)
    function changeGovernor() external {
        require(IXVMCgovernor(owner()).changeGovernorEnforced());
        address newGov = IXVMCgovernor(owner()).eligibleNewGovernor();
        transferOwnership(newGov);
        
        emit ChangeGovernor(newGov); //Leave a trail of Governors
    }

    function getTotalSupply() private view returns (uint256) {
        return IERC20(token).totalSupply() - IERC20(token).balanceOf(owner()) - IERC20(token).balanceOf(deadAddress);
    }
}