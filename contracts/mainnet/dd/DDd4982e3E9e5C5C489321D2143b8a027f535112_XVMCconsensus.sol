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

// File: xvmc-contracts/consensus.sol



pragma solidity 0.8.0;






interface IXVMCgovernor {
    function costToVote() external view returns (uint256);
    function maximumVoteTokens() external view returns (uint256);
    function delayBeforeEnforce() external view returns (uint256);
    function eventFibonacceningActive() external view returns (bool);
    
    function fibonacciDelayed() external returns (bool);
    function delayFibonacci(bool _arg) external;
    function eligibleNewGovernor() external returns (address);
    function changeGovernorActivated() external returns (bool);
    function setNewGovernor(address beneficiary) external;
    function executeWithdraw(uint256 withdrawID) external;
    function treasuryRequest(address _tokenAddr, address _recipient, uint256 _amountToSend) external;
    function newGovernorRequestBlock() external returns (uint256);
    function enforceGovernor() external;

    function acPool1() external view returns (address);
    function acPool2() external view returns (address);
    function acPool3() external view returns (address);
    function acPool4() external view returns (address);
    function acPool5() external view returns (address);
    function acPool6() external view returns (address);
    
    function governorRejected() external;
}

interface IacPool {
    function totalShares() external view returns (uint256);
    function totalVotesForID(uint256 proposalID) external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
}

interface IToken {
    function governor() external view returns (address);
}

contract XVMCconsensus is Ownable {
    using SafeERC20 for IERC20;
	
	struct HaltFibonacci {
		bool valid;
		bool enforced;
		uint256 consensusVoteID;
		uint256 startTimestamp;
		uint256 delayInSeconds;
	}
    struct TreasuryTransfer {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
		address tokenAddress;
        address beneficiary;
		uint256 amountToSend;
		uint256 consensusProposalID;
    }
	struct ConsensusVote {
        uint16 typeOfChange; // 0 == governor change, 1 == treasury transfer, 2 == halt fibonaccening
        address beneficiaryAddress; 
		uint256 timestamp;
    }
	struct GovernorInvalidated {
        bool isInvalidated; 
        bool hasPassed;
    }

	HaltFibonacci[] public haltProposal;
	TreasuryTransfer[] public treasuryProposal;
	ConsensusVote[] public consensusProposal;
	
	uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
    address public immutable token; //XVMC token (address)
	uint256 public governorCount; //count number of proposals
	
    //addresses for time-locked deposits(autocompounding pools)
    address public acPool1;
    address public acPool2;
    address public acPool3;
    address public acPool4;
    address public acPool5;
    address public acPool6;


    mapping(address => GovernorInvalidated) public isGovInvalidated;
	
	mapping(uint256 => uint256) public highestConsensusVotes; // *kinda* allows voting for multiple proposals
    
	constructor(address _XVMC) {
            consensusProposal.push(ConsensusVote(0, address(this), block.timestamp)); //0 is an invalid proposal(is default / neutral position)
			token = _XVMC;
    }
    
	
	event ProposalAgainstCommonEnemy(uint256 HaltID, uint256 consensusProposalID, uint256 startTimestamp, uint256 delayInSeconds, address indexed enforcer);
	event EnforceDelay(uint256 consensusProposalID, address indexed enforcer);
	event RemoveDelay(uint256 consensusProposalID, address indexed enforcer);
	
	event TreasuryProposal(uint256 proposalID, uint256 sacrificedTokens, address tokenAddress, address recipient, uint256 amount, uint256 consensusVoteID, address indexed enforcer, uint256 delay);
	event TreasuryEnforce(uint256 proposalID, address indexed enforcer, bool isSuccess);
    
    event ProposeGovernor(uint256 proposalID, address newGovernor, address indexed enforcer);
    event ChangeGovernor(uint256 proposalID, address indexed enforcer, bool status);
	
	event AddVotes(uint256 _type, uint256 proposalID,  address indexed voter, uint256 tokensSacrificed, bool _for);
    
	
	/*
	* If XVMC is to be listed on margin trading exchanges
	* As a lot of supply is printed during Fibonaccening events
	* It could provide "free revenue" for traders shorting XVMC
	* This is a mechanism meant to give XVMC holders an opportunity
	* to unite against the common enemy(shorters).
	* The function effectively delays the fibonaccening event
	* Requires atleast 15% votes, with less than 50% voting against
	*/
	function uniteAgainstTheCommonEnemy(uint256 startTimestamp, uint256 delayInSeconds) external {
		require(startTimestamp >= (block.timestamp + 3600) && delayInSeconds <= 72 * 3600); //no less than an hour before the event and can't last more than 3 days
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), 50 * IXVMCgovernor(owner()).costToVote());
		
		uint256 _consensusID = consensusProposal.length;
		
		//need to create consensus proposal because the voting is done by voting for a proposal ID(inside pool contracts)
		consensusProposal.push(
		    ConsensusVote(2, address(this), block.timestamp)
		    ); // vote for
    	consensusProposal.push(
    	    ConsensusVote(2, address(this), block.timestamp)
    	    ); // vote against
		
		 haltProposal.push(
    	    HaltFibonacci(true, false, _consensusID, startTimestamp, delayInSeconds)
    	   );  
	
        emit ProposalAgainstCommonEnemy(haltProposal.length - 1, _consensusID, startTimestamp, delayInSeconds, msg.sender);
	}
    function enforceDelay(uint256 fibonacciHaltID) external {
		require(haltProposal[fibonacciHaltID].valid && !haltProposal[fibonacciHaltID].enforced &&
		    haltProposal[fibonacciHaltID].startTimestamp <= block.timestamp &&
		    block.timestamp < haltProposal[fibonacciHaltID].startTimestamp + haltProposal[fibonacciHaltID].delayInSeconds);
		uint256 consensusID = haltProposal[fibonacciHaltID].consensusVoteID;

        uint256 _tokensCasted = tokensCastedPerVote(consensusID);
		 require(
            _tokensCasted >= totalXVMCStaked() * 15 / 100,
				"Atleast 15% of staked(weighted) tokens required"
        );
		
        require(
            tokensCastedPerVote(consensusID + 1) <= _tokensCasted / 2,
				"More than 50% are voting against!"
        );
		
		haltProposal[fibonacciHaltID].enforced = true;
		IXVMCgovernor(owner()).delayFibonacci(true);
		
		emit EnforceDelay(consensusID, msg.sender);
	}
	function removeDelay(uint256 haltProposalID) external {
		require(IXVMCgovernor(owner()).fibonacciDelayed() && haltProposal[haltProposalID].enforced && haltProposal[haltProposalID].valid);
		require(block.timestamp >= haltProposal[haltProposalID].startTimestamp + haltProposal[haltProposalID].delayInSeconds, "not yet expired");
		
		haltProposal[haltProposalID].valid = false;
		IXVMCgovernor(owner()).delayFibonacci(false);
		
		emit RemoveDelay(haltProposalID, msg.sender);
	}	

     /**
     * Initiates a request to transfer tokens from the treasury wallet
	 * Can be voted against during the "delay before enforce" period
	 * For extra safety
	 * Requires vote from long term stakers to enforce the transfer
	 * Requires 25% of votes to pass
	 * If only 5% of voters disagree, the proposal is rejected
	 *
	 * The possibilities here are endless
	 *
	 * Could act as a NFT marketplace too, could act as a treasury that pays "contractors",..
	 * Since it's upgradeable, this can be added later on anyways....
	 * Should probably make universal private function for Consensus Votes
     */
	function initiateTreasuryTransferProposal(uint256 depositingTokens,  address tokenAddress, address recipient, uint256 amountToSend, uint256 delay) external { 
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote() * 10,
    	    "atleast x10minCostToVote"
    	    );
		require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
		
		uint256 _consensusID = consensusProposal.length + 1;
		
		consensusProposal.push(
		    ConsensusVote(1, address(this), block.timestamp)
		    ); // vote for
    	consensusProposal.push(
    	    ConsensusVote(1, address(this), block.timestamp)
    	    ); // vote against
		
		 treasuryProposal.push(
    	    TreasuryTransfer(true, block.timestamp, depositingTokens, 0, delay, tokenAddress, recipient, amountToSend, _consensusID)
    	   );  
		   
        emit TreasuryProposal(
            treasuryProposal.length - 1, depositingTokens, tokenAddress, recipient, amountToSend, _consensusID, msg.sender, delay
            );
    }
	//can only vote with tokens during the delay+delaybeforeenforce period(then this period ends, and to approve the transfer, must be voted through voting with locked shares)
	function voteTreasuryTransferProposalY(uint256 proposalID, uint256 withTokens) external {
		require(treasuryProposal[proposalID].valid, "invalid");
		require(
			treasuryProposal[proposalID].firstCallTimestamp + treasuryProposal[proposalID].delay + IXVMCgovernor(owner()).delayBeforeEnforce() > block.timestamp,
			"can already be enforced"
		);
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		treasuryProposal[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(0, proposalID, msg.sender, withTokens, true);
	}
	function voteTreasuryTransferProposalN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(treasuryProposal[proposalID].valid, "invalid");
		require(
			treasuryProposal[proposalID].firstCallTimestamp + treasuryProposal[proposalID].delay + IXVMCgovernor(owner()).delayBeforeEnforce() > block.timestamp,
			"can already be enforced"
		);
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		treasuryProposal[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoTreasuryTransferProposal(proposalID); }

		emit AddVotes(0, proposalID, msg.sender, withTokens, false);
	}
    function vetoTreasuryTransferProposal(uint256 proposalID) public {
        require(proposalID != 0, "Invalid proposal ID");
    	require(treasuryProposal[proposalID].valid == true, "Proposal already invalid");
		require(
			treasuryProposal[proposalID].firstCallTimestamp + treasuryProposal[proposalID].delay + IXVMCgovernor(owner()).delayBeforeEnforce() >= block.timestamp,
			"past the point of no return"
		);
    	require(treasuryProposal[proposalID].valueSacrificedForVote < treasuryProposal[proposalID].valueSacrificedAgainst, "needs more votes");
		
    	treasuryProposal[proposalID].valid = false;  
		
    	emit TreasuryEnforce(proposalID, msg.sender, false);
    }
    /*
    * After delay+delayBeforeEnforce , the proposal effectively passes to be voted through consensus (token voting stops, voting with locked shares starts)
	* Another delayBeforeEnforce period during which users can vote with locked shares
    */
	function approveTreasuryTransfer(uint256 proposalID) public {
		require(treasuryProposal[proposalID].valid, "Proposal already invalid");
		uint256 consensusID = treasuryProposal[proposalID].consensusProposalID;
		updateHighestConsensusVotes(consensusID);
		updateHighestConsensusVotes(consensusID+1);
		require(
			treasuryProposal[proposalID].firstCallTimestamp + treasuryProposal[proposalID].delay + 2 * IXVMCgovernor(owner()).delayBeforeEnforce() <= block.timestamp,
			"Enough time must pass before enforcing"
		);
		
		uint256 _totalStaked = totalXVMCStaked();
		uint256 _castedInFavor = highestConsensusVotes[consensusID];
		if(treasuryProposal[proposalID].valueSacrificedForVote >= treasuryProposal[proposalID].valueSacrificedAgainst &&
				_castedInFavor >= _totalStaked * 15 / 100 ) {
			
			if(highestConsensusVotes[consensusID+1] >= _castedInFavor * 33 / 100) { //just third of votes voting against kills the treasury withdrawal
				treasuryProposal[proposalID].valid = false;
				emit TreasuryEnforce(proposalID, msg.sender, false);
			} else {
				IXVMCgovernor(owner()).treasuryRequest(
					treasuryProposal[proposalID].tokenAddress, treasuryProposal[proposalID].beneficiary, treasuryProposal[proposalID].amountToSend
				   );
				treasuryProposal[proposalID].valid = false;  
				
				emit TreasuryEnforce(proposalID, msg.sender, true);
			}
		} else {
			treasuryProposal[proposalID].valid = false;  
		
			emit TreasuryEnforce(proposalID, msg.sender, false);
		}
	}
	
	 /**
     * Kills treasury transfer proposal if more than 15% of weighted vote(of total staked)
     */
	function killTreasuryTransferProposal(uint256 proposalID) external {
		require(treasuryProposal[proposalID].valid, "Proposal already invalid");
		uint256 consensusID = treasuryProposal[proposalID].consensusProposalID;
		
        require(
            tokensCastedPerVote(consensusID+1) >= totalXVMCStaked() * 15 / 100,
				"15% weigted vote (voting against) required to kill the proposal"
        );
		
    	treasuryProposal[proposalID].valid = false;  
		
    	emit TreasuryEnforce(proposalID, msg.sender, false);
	}
	
	//updates highest votes collected
	function updateHighestConsensusVotes(uint256 consensusID) public {
		uint256 _current = tokensCastedPerVote(consensusID);
		if(_current > highestConsensusVotes[consensusID]) {
			highestConsensusVotes[consensusID] = _current;
		}
	}
	
	
    function proposeGovernor(address _newGovernor) external {
		governorCount++;
        IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote() * 100);
		
		consensusProposal.push(
    	    ConsensusVote(0, _newGovernor, block.timestamp)
    	    );
    	consensusProposal.push(
    	    ConsensusVote(0, _newGovernor, block.timestamp)
    	    ); //even numbers are basically VETO (for voting against)
    	
    	emit ProposeGovernor(consensusProposal.length - 2, _newGovernor, msg.sender);
    }
    
    /**
     * Atleast 33% of voters required
     * with 75% agreement required to reach consensus
	 * After proposing Governor, a period of time(delayBeforeEnforce) must pass 
	 * During this time, the users can vote in favor(proposalID) or against(proposalID+1)
	 * If voting succesfull, it can be submitted
	 * And then there is a period of roughly 6 days(specified in governing contract) before the change can be enforced
	 * During this time, users can still vote and reject change
	 * Unless rejected, governing contract can be updated and changes enforced
     */
    function changeGovernor(uint256 proposalID) external { 
		require(block.timestamp >= (consensusProposal[proposalID].timestamp + IXVMCgovernor(owner()).delayBeforeEnforce()), "Must wait delay before enforce");
        require(!(isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated), " alreadyinvalidated");
		require(!(isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].hasPassed), " already passed");
		require(consensusProposal.length > proposalID && proposalID % 2 == 1, "invalid proposal ID"); //can't be 0 either, but %2 solves that
        require(!(IXVMCgovernor(owner()).changeGovernorActivated()));
		require(consensusProposal[proposalID].typeOfChange == 0);

        require(
            tokensCastedPerVote(proposalID) >= totalXVMCStaked() * 33 / 100,
				"Requires atleast 33% of staked(weighted) tokens"
        );

        //requires 80% agreement
        if(tokensCastedPerVote(proposalID+1) >= tokensCastedPerVote(proposalID) / 5) {
            
                isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated = true;
                
				emit ChangeGovernor(proposalID, msg.sender, false);
				
            } else {
                IXVMCgovernor(owner()).setNewGovernor(consensusProposal[proposalID].beneficiaryAddress);
                
                isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].hasPassed = true;
                
                emit ChangeGovernor(proposalID, msg.sender, true);
            }
    }
    
    /**
     * After approved, still roughly 6 days to cancle the new governor, if less than 80% votes agree
	 * 6 days at beginning in case we need to make changes on the fly, and later on the period should be increased
	 * Note: The proposal IDs here are for the consensus ID
	 * After rejecting, call the governorRejected in governing contract(sets activated setting to false)
     */
    function vetoGovernor(uint256 proposalID, bool _withUpdate) external {
        require(proposalID % 2 == 1, "Invalid proposal ID");
        require(isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].hasPassed &&
					!isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated);

        if(tokensCastedPerVote(proposalID+1) >= tokensCastedPerVote(proposalID) / 5) {
              isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated = true;
			  emit ChangeGovernor(proposalID, msg.sender, false);
        }
		
		if(_withUpdate) { IXVMCgovernor(owner()).governorRejected(); }
    }
	//even if not approved, can be cancled at any time if 25% of weighted votes go AGAINST
    function vetoGovernor2(uint256 proposalID, bool _withUpdate) external {
        require(proposalID % 2 == 1, "Invalid proposal ID");

        if(tokensCastedPerVote(proposalID+1) >= totalXVMCStaked() * 25 / 100) { //25% of weighted total vote AGAINST kills the proposal as well
              isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated = true;
			  emit ChangeGovernor(proposalID, msg.sender, false);
        }
		
		if(_withUpdate) { IXVMCgovernor(owner()).governorRejected(); }
    }
    function enforceGovernor(uint256 proposalID) external {
        require(proposalID % 2 == 1, "invalid proposal ID"); //proposal ID = 0 is neutral position and not allowed(%2 applies)
        require(!isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated, "invalid");
        
        require(consensusProposal[proposalID].beneficiaryAddress == IXVMCgovernor(owner()).eligibleNewGovernor());
      
	  	IXVMCgovernor(owner()).enforceGovernor();
	  
        isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated = true;
    }

    /**
     * Updates pool addresses and token addresses from the governor
     */
    function updatePools() external {
        acPool1 = IXVMCgovernor(owner()).acPool1();
        acPool2 = IXVMCgovernor(owner()).acPool2();
        acPool3 = IXVMCgovernor(owner()).acPool3();
        acPool4 = IXVMCgovernor(owner()).acPool4();
        acPool5 = IXVMCgovernor(owner()).acPool5();
        acPool6 = IXVMCgovernor(owner()).acPool6();
    }
   
    
    //transfers ownership of this contract to new governor
    //masterchef is the token owner, governor is the owner of masterchef
    function changeGovernor() external {
		_transferOwnership(IToken(token).governor());
    }

	function treasuryRequestsCount() external view returns (uint256) {
		return treasuryProposal.length;
	}

    /**
     * Returns total XVMC staked accross all pools.
     */
    function totalXVMCStaked() public view returns(uint256) {
    	return IERC20(token).balanceOf(acPool1) + IERC20(token).balanceOf(acPool2) + IERC20(token).balanceOf(acPool3) +
                 IERC20(token).balanceOf(acPool4) + IERC20(token).balanceOf(acPool5) + IERC20(token).balanceOf(acPool6);
    }

    /**
     * Gets XVMC allocated per vote with ID for each pool
     * Process:
     * Gets votes for ID and calculates XVMC equivalent
     * ...and assigns weights to votes
     * Pool1(20%), Pool2(30%), Pool3(50%), Pool4(75%), Pool5(115%), Pool6(150%)
     */
    function tokensCastedPerVote(uint256 _forID) public view returns(uint256) {
        return (
            IacPool(acPool1).totalVotesForID(_forID) * IacPool(acPool1).getPricePerFullShare() / 1e19 * 2 + 
                IacPool(acPool2).totalVotesForID(_forID) * IacPool(acPool2).getPricePerFullShare() / 1e19 * 3 +
                    IacPool(acPool3).totalVotesForID(_forID) * IacPool(acPool3).getPricePerFullShare() / 1e19 * 5 +
                        IacPool(acPool4).totalVotesForID(_forID) * IacPool(acPool4).getPricePerFullShare() / 1e20 * 75 +
                            IacPool(acPool5).totalVotesForID(_forID) * IacPool(acPool5).getPricePerFullShare() / 1e20 * 115 +
                                IacPool(acPool6).totalVotesForID(_forID) * IacPool(acPool6).getPricePerFullShare() / 1e19 * 15
        );
    }
}