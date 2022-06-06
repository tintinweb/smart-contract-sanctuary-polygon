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

// File: xvmc-contracts/farms.sol



pragma solidity 0.8.0;






interface IXVMCgovernor {
    function costToVote() external view returns (uint256);
    function maximumVoteTokens() external view returns (uint256);
    function delayBeforeEnforce() external view returns (uint256);
    function setPool(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external; 
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
    function setDurationForCalculation(uint256 _newDuration) external;
    function updateAllPools() external;
	function treasuryWallet() external view returns (address);
	function burnFromOldChef(uint256 _amount) external;
	function setGovernorTax(uint256 _amount) external;
	function eventFibonacceningActive() external view returns (bool);
}

interface IMasterChef {
    function totalAllocPoint() external returns (uint256);
    function poolInfo(uint256) external returns (address, uint256, uint256, uint256, uint16);
    function XVMCPerBlock() external returns (uint256);
    function owner() external view returns (address);
	function massUpdatePools() external;
}

interface IOldChefOwner {
	function burnDelay() external view returns(uint256);
}

interface IToken {
    function governor() external view returns (address);
	function owner() external view returns (address);
}

//contract that regulates the farms for XVMC
contract XVMCfarms is Ownable {
    using SafeERC20 for IERC20;
    
	struct ProposalFarm {
        bool valid;
        uint256 poolid;
        uint256 newAllocation;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
        uint256 firstCallTimestamp;
        uint16 newDepositFee;
    }
    struct ProposalDecreaseLeaks {
        bool valid;
        uint256 farmMultiplier;
        uint256 memeMultiplier;
        uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
        uint256 firstCallTimestamp;
    }
     struct ProposalGovTransfer {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 proposedValue;
		uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
		bool isBurn; //if burn, burns tokens. Else transfers into treasury
		uint256 startTimestamp; //can schedule in advance when they are burned
    }
	
	//burns from old masterchef
   struct ProposalBurn {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 proposedValue;
		uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
		uint256 startTimestamp; //can schedule in advance when they are burned
    }
	
   struct ProposalTax {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 proposedValue;
		uint256 valueSacrificedForVote;
		uint256 valueSacrificedAgainst;
		uint256 delay;
    }
	
    ProposalBurn[] public burnProposals; 
    ProposalFarm[] public proposalFarmUpdate;
    ProposalDecreaseLeaks[] public proposeRewardReduction;
	ProposalGovTransfer[] public governorTransferProposals; 
	ProposalTax[] public govTaxProposals; 
    
    address public immutable token; //XVMC token(address!)
	
	address public masterchef;
	
	address public oldChef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
    
	uint256 public maxLpAllocation = 1250;
	uint256 public maxNftAllocation = 1000;
	uint256 public maxMemeAllocation = 500;
	
    //farms and meme pools rewards have no lock 
    //reduce the rewards during inflation boost
    //to prevent tokens reaching the market
    uint256 public farmMultiplierDuringBoost = 500;
    uint256 public memeMultiplierDuringBoost = 500;
    bool public isReductionEnforced; 
    
    event InitiateFarmProposal(
            uint256 proposalID, uint256 depositingTokens, uint256 poolid,
            uint256 newAllocation, uint16 depositFee, address indexed enforcer, uint256 delay
        );
    
    //reward reduction for farms and meme pools during reward boosts
    event ProposeRewardReduction(address enforcer, uint256 proposalID, uint256 farmMultiplier, uint256 memeMultiplier, uint256 depositingTokens, uint256 delay);
	
    event ProposeGovernorTransfer(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedAmount, address indexed enforcer, bool isBurn, uint256 startTimestamp, uint256 delay);
	
    event ProposeBurn(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedBurn, address indexed enforcer, uint256 startTimestamp, uint256 delay);
	
	event ProposeGovTax(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedTax, address indexed enforcer, uint256 delay);
	
	event AddVotes(uint256 _type, uint256 proposalID, address indexed voter, uint256 tokensSacrificed, bool _for);
	event EnforceProposal(uint256 _type, uint256 proposalID, address indexed enforcer, bool isSuccess);
    
	constructor (address _XVMC, address _masterchef)  {
		token = _XVMC;
		masterchef = _masterchef;
	}

	//ability to change max allocations without launching new contract
	function changeMaxAllocations(uint256 _lp, uint256 _nft, uint256 _meme) external onlyOwner {
		maxLpAllocation = _lp;
		maxNftAllocation = _nft;
		maxMemeAllocation = _meme;
	}
    
    /**
     * Regulatory process to regulate farm rewards 
     * And Meme pools
    */    
    function initiateFarmProposal(
            uint256 depositingTokens, uint256 poolid, uint256 newAllocation, uint16 depositFee, uint256 delay
        ) external { 
    	require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "there is a minimum cost to vote");
    	require(poolid == 0 || poolid == 1 || poolid == 8 || poolid == 9 || poolid == 10, "only allowed for these pools"); 
		
		//0 and 1 are XVMC-USDC and XVMC-wMatic pools
		//8 and 9 are meme pools
		//10 is for NFT staking(nfts and virtual land)
    	if(poolid == 0 || poolid == 1) {
    	    require(
    	        newAllocation <= (IMasterChef(masterchef).totalAllocPoint() * maxLpAllocation / 10000),
    	        "exceeds max allocation"
    	       );
    	} else if(poolid == 10) {
			require(
    	        newAllocation <= (IMasterChef(masterchef).totalAllocPoint() * maxNftAllocation / 10000),
    	        "exceeds max allocation"
    	       );
			require(depositFee == 0, "deposit fee must be 0 for NFTs");
		} else {
    	    require(
    	        newAllocation <= (IMasterChef(masterchef).totalAllocPoint() * maxMemeAllocation / 10000),
    	        "exceeds max allocation"
    	       ); 
    	}
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
    	proposalFarmUpdate.push(
    	    ProposalFarm(true, poolid, newAllocation, depositingTokens, 0, delay, block.timestamp, depositFee)
    	    ); 
    	emit InitiateFarmProposal(proposalFarmUpdate.length - 1, depositingTokens, poolid, newAllocation, depositFee, msg.sender, delay);
    }
	function voteFarmProposalY(uint256 proposalID, uint256 withTokens) external {
		require(proposalFarmUpdate[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		proposalFarmUpdate[proposalID].valueSacrificedForVote+= withTokens;
			
		emit AddVotes(0, proposalID, msg.sender, withTokens, true);
	}
	function voteFarmProposalN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(proposalFarmUpdate[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		proposalFarmUpdate[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoFarmProposal(proposalID); }

		emit AddVotes(0, proposalID, msg.sender, withTokens, false);
	}
    function vetoFarmProposal(uint256 proposalID) public {
    	require(proposalFarmUpdate[proposalID].valid, "already invalid");
		require(proposalFarmUpdate[proposalID].firstCallTimestamp + proposalFarmUpdate[proposalID].delay <= block.timestamp, "pending delay");
		require(proposalFarmUpdate[proposalID].valueSacrificedForVote < proposalFarmUpdate[proposalID].valueSacrificedAgainst, "needs more votes");
		
    	proposalFarmUpdate[proposalID].valid = false; 
    	
    	emit EnforceProposal(0, proposalID, msg.sender, false);
    }
    
    /**
     * Updates the rewards for the corresponding farm in the proposal
    */
    function updateFarm(uint256 proposalID) public {
        require(!isReductionEnforced, "reward reduction is active"); //only when reduction is not enforced
        require(proposalFarmUpdate[proposalID].valid, "invalid proposal");
        require(
            proposalFarmUpdate[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + proposalFarmUpdate[proposalID].delay  < block.timestamp,
            "delay before enforce not met"
            );
        
		if(proposalFarmUpdate[proposalID].valueSacrificedForVote >= proposalFarmUpdate[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).setPool(proposalFarmUpdate[proposalID].poolid, proposalFarmUpdate[proposalID].newAllocation, proposalFarmUpdate[proposalID].newDepositFee, true);
			proposalFarmUpdate[proposalID].valid = false;
			
			emit EnforceProposal(0, proposalID, msg.sender, true);
		} else {
			vetoFarmProposal(proposalID);
		}
    }

    /**
     * Regulatory process for determining rewards for 
     * farms and meme pools during inflation boosts
     * The rewards should be reduced for farms and pool tha toperate without time lock
     * to prevent tokens from hitting the market
    */
    function initiateRewardsReduction(uint256 depositingTokens, uint256 multiplierFarms, uint256 multiplierMemePools, uint256 delay) external {
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "minimum cost to vote");
		require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
		require(multiplierFarms <= 10000 && multiplierMemePools <= 10000, "out of range");
    	
		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
		    proposeRewardReduction.push(
		        ProposalDecreaseLeaks(true, multiplierFarms, multiplierMemePools, depositingTokens, 0, delay, block.timestamp)
		        );
    	
    	emit ProposeRewardReduction(msg.sender, proposeRewardReduction.length - 1, multiplierFarms, multiplierMemePools, depositingTokens, delay);
    }
	function voteRewardsReductionY(uint256 proposalID, uint256 withTokens) external {
		require(proposeRewardReduction[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		proposeRewardReduction[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(1, proposalID, msg.sender, withTokens, true);
	}
	function voteRewardsReductionN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(proposeRewardReduction[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		proposeRewardReduction[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoRewardsReduction(proposalID); }

		emit AddVotes(1, proposalID, msg.sender, withTokens, false);
	}
    function vetoRewardsReduction(uint256 proposalID) public {
    	require(proposeRewardReduction[proposalID].valid == true, "Proposal already invalid");
		require(proposeRewardReduction[proposalID].firstCallTimestamp + proposeRewardReduction[proposalID].delay <= block.timestamp, "pending delay");
		require(proposeRewardReduction[proposalID].valueSacrificedForVote < proposeRewardReduction[proposalID].valueSacrificedAgainst, "needs more votes");
		
    	proposeRewardReduction[proposalID].valid = false;  
    	
    	emit EnforceProposal(1, proposalID, msg.sender, false);
    }
    function executeRewardsReduction(uint256 proposalID) public {
		require(!isReductionEnforced, "reward reduction is active"); //only when reduction is not enforced
    	require(
    	    proposeRewardReduction[proposalID].valid &&
    	    proposeRewardReduction[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + proposeRewardReduction[proposalID].delay < block.timestamp,
    	    "Conditions not met"
    	   );
		   
		if(proposeRewardReduction[proposalID].valueSacrificedForVote >= proposeRewardReduction[proposalID].valueSacrificedAgainst) {
			farmMultiplierDuringBoost = proposeRewardReduction[proposalID].farmMultiplier;
			memeMultiplierDuringBoost = proposeRewardReduction[proposalID].memeMultiplier;
			proposeRewardReduction[proposalID].valid = false;
			
			emit EnforceProposal(1, proposalID, msg.sender, true);
		} else {
			vetoRewardsReduction(proposalID);
		}
    }
    
    /**
     * When event is active, reduction of rewards must be manually activated
     * Reduces the rewards by a factor
     * Call this to enforce and "un-enforce"
    */
    function enforceRewardReduction(bool withUpdate) public {
        uint256 allocPoint; uint16 depositFeeBP;
        if (IXVMCgovernor(owner()).eventFibonacceningActive() && !isReductionEnforced) {
            
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(0);
            IXVMCgovernor(owner()).setPool(
                0, allocPoint * farmMultiplierDuringBoost / 10000, depositFeeBP, false
            );
            
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(1);
            IXVMCgovernor(owner()).setPool(
                1, allocPoint * farmMultiplierDuringBoost / 10000, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(8);
            IXVMCgovernor(owner()).setPool(
                8, allocPoint * memeMultiplierDuringBoost / 10000, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(9);
            IXVMCgovernor(owner()).setPool(
                9, allocPoint * memeMultiplierDuringBoost / 10000, depositFeeBP, false
            );
            
            isReductionEnforced = true;
            
        } else if(!(IXVMCgovernor(owner()).eventFibonacceningActive()) && isReductionEnforced) {

        //inverses the formula... perhaps should keep last Reward
        //the mutliplier shall not change during event!
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(0);
            IXVMCgovernor(owner()).setPool(
                0, allocPoint * 10000 / farmMultiplierDuringBoost, depositFeeBP, false
            );
            
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(1);
            IXVMCgovernor(owner()).setPool(
                1, allocPoint * 10000 / farmMultiplierDuringBoost, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(8);
            IXVMCgovernor(owner()).setPool(
                8, allocPoint * 10000 / memeMultiplierDuringBoost, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(9);
            IXVMCgovernor(owner()).setPool(
                9, allocPoint * 10000 / memeMultiplierDuringBoost, depositFeeBP, false
            );
            
            isReductionEnforced = false;
        }
	
	if(withUpdate) { updateAllPools(); }
    }

	//updates all pools in masterchef
    function updateAllPools() public {
        IMasterChef(IToken(token).owner()).massUpdatePools();
    }

	/*
	* Transfer tokens from governor into treasury wallet OR burn them from governor
	* alternatively could change devaddr to the treasury wallet in masterchef(portion of inflation goes to devaddr)
	*/
  function proposeGovernorTransfer(uint256 depositingTokens, uint256 _amount, bool _isBurn, uint256 _timestamp, uint256 delay) external {
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "Costs to vote");
        require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
		require(_amount <= IERC20(token).balanceOf(owner()), "insufficient balance");
        
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	governorTransferProposals.push(
    	    ProposalGovTransfer(true, block.timestamp, _amount, depositingTokens, 0, delay, _isBurn, _timestamp)
    	    );
		
    	emit ProposeGovernorTransfer(
    	    governorTransferProposals.length - 1, depositingTokens, _amount, msg.sender, _isBurn, _timestamp, delay
    	   );
    }
	function voteGovernorTransferY(uint256 proposalID, uint256 withTokens) external {
		require(governorTransferProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		governorTransferProposals[proposalID].valueSacrificedForVote+= withTokens;
			
		emit AddVotes(2, proposalID, msg.sender, withTokens, true);
	}
	function voteGovernorTransferN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(governorTransferProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		governorTransferProposals[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoGovernorTransfer(proposalID); }

		emit AddVotes(2, proposalID, msg.sender, withTokens, false);
	}
    function vetoGovernorTransfer(uint256 proposalID) public {
    	require(governorTransferProposals[proposalID].valid == true, "Invalid proposal"); 
		require(governorTransferProposals[proposalID].firstCallTimestamp + governorTransferProposals[proposalID].delay <= block.timestamp, "pending delay");
		require(governorTransferProposals[proposalID].valueSacrificedForVote < governorTransferProposals[proposalID].valueSacrificedAgainst, "needs more votes");
		
    	governorTransferProposals[proposalID].valid = false;

		emit EnforceProposal(2, proposalID, msg.sender, false);
    }
    function executeGovernorTransfer(uint256 proposalID) public {
    	require(
    	    governorTransferProposals[proposalID].valid == true &&
    	    governorTransferProposals[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + governorTransferProposals[proposalID].delay  < block.timestamp,
    	    "conditions not met"
        );
		require(governorTransferProposals[proposalID].startTimestamp < block.timestamp, "Not yet eligible");
    	
		if(governorTransferProposals[proposalID].valueSacrificedForVote >= governorTransferProposals[proposalID].valueSacrificedAgainst) {
			if(governorTransferProposals[proposalID].isBurn) {
				IERC20(token).burnXVMC(owner(), governorTransferProposals[proposalID].proposedValue);
			} else {
				IERC20(token).safeTransferFrom(owner(), IXVMCgovernor(owner()).treasuryWallet(), governorTransferProposals[proposalID].proposedValue);
			}

			governorTransferProposals[proposalID].valid = false; 
			
			emit EnforceProposal(2, proposalID, msg.sender, true);
		} else {
			vetoGovernorTransfer(proposalID);
		}
    }
	
	//in case masterchef is changed
   function setMasterchef() external {
		address _chefo = IMasterChef(token).owner();
		
        masterchef = _chefo;
    }
   
    //transfers ownership of this contract to new governor
    //masterchef is the token owner, governor is the owner of masterchef
    function changeGovernor() external {
		_transferOwnership(IToken(token).governor());
    }
	
	//burn from old masterchef
	// 0 as proposed value will burn all the tokens held by contract
  function proposeBurn(uint256 depositingTokens, uint256 _amount, uint256 _timestamp, uint256 delay) external {
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "Costs to vote");
        require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
		require(_amount <= IERC20(token).balanceOf(IMasterChef(oldChef).owner()), "insufficient balance");
        
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	burnProposals.push(
    	    ProposalBurn(true, block.timestamp, _amount, depositingTokens, 0, delay, _timestamp)
    	    );
		
    	emit ProposeBurn(
    	    burnProposals.length - 1, depositingTokens, _amount, msg.sender, _timestamp, delay
    	   );
    }
	function voteBurnY(uint256 proposalID, uint256 withTokens) external {
		require(burnProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		burnProposals[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(3, proposalID, msg.sender, withTokens, true);
	}
	function voteBurnN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(burnProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		burnProposals[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoBurn(proposalID); }

		emit AddVotes(3, proposalID, msg.sender, withTokens, false);
	}
    function vetoBurn(uint256 proposalID) public {
    	require(burnProposals[proposalID].valid == true, "Invalid proposal");
		require(burnProposals[proposalID].firstCallTimestamp + burnProposals[proposalID].delay <= block.timestamp, "pending delay");
		require(burnProposals[proposalID].valueSacrificedForVote < burnProposals[proposalID].valueSacrificedAgainst, "needs more votes");
		
    	burnProposals[proposalID].valid = false;
    	
    	emit EnforceProposal(3, proposalID, msg.sender, false);
    }
    function executeBurn(uint256 proposalID) public {
    	require(
    	    burnProposals[proposalID].valid == true &&
    	    burnProposals[proposalID].firstCallTimestamp + IOldChefOwner(IMasterChef(oldChef).owner()).burnDelay() + burnProposals[proposalID].delay  < block.timestamp,
    	    "conditions not met"
        );
    	require(burnProposals[proposalID].startTimestamp <= block.timestamp, "Not yet eligible");
		
		if(burnProposals[proposalID].valueSacrificedForVote >= burnProposals[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).burnFromOldChef(burnProposals[proposalID].proposedValue); //burns the tokens
			burnProposals[proposalID].valid = false; 
			
			emit EnforceProposal(3, proposalID, msg.sender, true);
		} else {
			vetoBurn(proposalID);
		}
    }
	
	//Proposals to set governor 'tax'(in masterchef, on every mint this % of inflation goes to the governor)
	//1000 = 10%. Max 10%
	// ( mintTokens * thisAmount / 10 000 ) in the masterchef contract
  function proposeGovTax(uint256 depositingTokens, uint256 _amount, uint256 delay) external {
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "Costs to vote");
        require(delay <= IXVMCgovernor(owner()).delayBeforeEnforce(), "must be shorter than Delay before enforce");
		require(_amount <= 1000 && _amount > 0, "max 1000");
        
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	govTaxProposals.push(
    	    ProposalTax(true, block.timestamp, _amount, depositingTokens, 0, delay)
    	    );
		
    	emit ProposeGovTax(
    	    govTaxProposals.length - 1, depositingTokens, _amount, msg.sender, delay
    	   );
    }
	function voteGovTaxY(uint256 proposalID, uint256 withTokens) external {
		require(govTaxProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);

		govTaxProposals[proposalID].valueSacrificedForVote+= withTokens;

		emit AddVotes(4, proposalID, msg.sender, withTokens, true);
	}
	function voteGovTaxN(uint256 proposalID, uint256 withTokens, bool withAction) external {
		require(govTaxProposals[proposalID].valid, "invalid");
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), withTokens);
		
		govTaxProposals[proposalID].valueSacrificedAgainst+= withTokens;
		if(withAction) { vetoGovTax(proposalID); }

		emit AddVotes(4, proposalID, msg.sender, withTokens, false);
	}
    function vetoGovTax(uint256 proposalID) public {
    	require(govTaxProposals[proposalID].valid == true, "Invalid proposal");
		require(govTaxProposals[proposalID].firstCallTimestamp + govTaxProposals[proposalID].delay <= block.timestamp, "pending delay");
		require(govTaxProposals[proposalID].valueSacrificedForVote < govTaxProposals[proposalID].valueSacrificedAgainst, "needs more votes");
		
    	govTaxProposals[proposalID].valid = false;
    	
    	emit EnforceProposal(4, proposalID, msg.sender, false);
    }
    function executeGovTax(uint256 proposalID) public {
    	require(
    	    govTaxProposals[proposalID].valid == true &&
    	    govTaxProposals[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() + govTaxProposals[proposalID].delay  < block.timestamp,
    	    "conditions not met"
        );
		
		if(govTaxProposals[proposalID].valueSacrificedForVote >= govTaxProposals[proposalID].valueSacrificedAgainst) {
			IXVMCgovernor(owner()).setGovernorTax(govTaxProposals[proposalID].proposedValue); //burns the tokens
			govTaxProposals[proposalID].valid = false; 
			
			emit EnforceProposal(4, proposalID, msg.sender, true);
		} else {
			vetoGovTax(proposalID);
		}
    }
}