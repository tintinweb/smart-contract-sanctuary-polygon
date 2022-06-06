/**
 *Submitted for verification at polygonscan.com on 2022-06-06
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

// File: xvmc-contracts/libs/standard/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: xvmc-contracts/libs/standard/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: xvmc-contracts/governor.sol



pragma solidity 0.8.0;




interface IacPool {
    function setCallFee(uint256 _callFee) external;
    function totalShares() external returns (uint256);
    function totalVotesFor(uint256 proposalID) external returns (uint256);
    function setAdmin(address _admin, address _treasury) external;
    function setTreasury(address _treasury) external;
	function addAndExtendStake(address _recipientAddr, uint256 _amount, uint256 _stakeID, uint256 _lockUpTokensInSeconds) external;
    function giftDeposit(uint256 _amount, address _toAddress, uint256 _minToServeInSecs) external;
    function harvest() external;
	function calculateHarvestXVMCRewards() external view returns (uint256);
}

interface IMasterChef {
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external;
    function updateEmissionRate(uint256 _gajPerBlock) external;
    function setFeeAddress(address _feeAddress) external;
    function dev(address _devaddr) external;
    function transferOwnership(address newOwner) external;
    function XVMCPerBlock() external returns (uint256);
    function totalAllocPoint() external returns (uint256);
    function updatePool(uint256 _pid) external;
    function owner() external returns (address);
	function setGovernorFee(uint256 _amount) external;
}

interface IXVMCtreasury {
    function requestWithdraw(address _token, address _receiver, uint _value) external;
}

interface IOldChef {
	function burnTokens(uint256 _amount) external;
}

interface IConsensus {
	function totalXVMCStaked() external view returns(uint256);
	function tokensCastedPerVote(uint256 _forID) external view returns(uint256);
	function isGovInvalidated(address _failedGov) external view returns(bool, bool);
}

interface IPolygonMultisig {
	function isOwner(address) external view returns(bool);
}

interface IRewardBoost {
	function updateDelayBetweenEvents(uint256 _delay) external;
	function updateGrandEventLength(uint256 _length) external;
}

    /**
     * XVMC governor is a decentralized masterchef governed by it's users
     * Works as a decentralized cryptocurrency with no third-party control
     * Effectively creating a DAO through time-deposits
     *
     * In order to earn staking rewards, users must lock up their tokens.
     * Certificates of deposit or time deposit are the biggest market in the world
     * The longer the lockup period, the higher the rewards(APY) and voting power 
     * The locked up stakers create the governance council, through which
     * the protocol can be upgraded in a decentralized manner.
     *
     * Users are utilized as oracles through on-chain voting regulating the entire system(events,
     * rewards, APYs, fees, bonuses,...)
     * The token voting is overpowered by the consensus mechanism(locked up stakers)
     *
     * It is a real DAO creating an actual decentralized finance ecosystem
     *
     * https://macncheese.finance/
    */

    
contract XVMCgovernor {
    using SafeERC20 for IERC20;
    
    uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
	address public immutable oldToken = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912;
    address public immutable token = 0x970ccEe657Dd831e9C37511Aa3eb5302C1Eb5EEe; //XVMC token
    
    //masterchef address
    address public immutable masterchef = 0x6ff40a8a1fe16075bD6008A48befB768BE08b4b0;
    address public immutable oldChefOwner = 0x27771BB243c37B35091b0A1e8b69C816249c2E71;
	
	//https://docs.polygon.technology/docs/faq/commit-chain-multisigs/
	address public immutable polygonMultisig = 0x355b8E02e7F5301E6fac9b7cAc1D6D9c86C0343f; 
	
    address public immutable consensusContract = 0xDDd4982e3E9e5C5C489321D2143b8a027f535112;
    address public immutable farmContract = 0xdf47e7a036A6a85F92898176b5A8B4B4b9fBF25A;
    address public immutable fibonacceningContract = 0xff5a8072565726A055690bd14924022DE020623A; //reward boost contract
    address public immutable basicContract = 0xEBD2e542F593d8E03543661BCc70ad2474e6DBad;
	
	address public immutable nftStakingContract = 0xD7bf9953d090D6Eb5fC8f6707e88Ea057beD08cB;
	address public immutable nftAllocationContract = 0x765A3045902B164dA1a7619BEc58DE64cf7Bdfe2;
    
    //Addresses for treasuryWallet and NFT wallet
    address public treasuryWallet = 0xC44D3FB20a7fA7eff7437c1C39d34A68A2046BA7;
    address public nftWallet = 0xcCb906C2233A39aA14f60d2F836EB24492D83713;
    
    //addresses for time-locked deposits(autocompounding pools)
    address public immutable acPool1 = 0xfFB71361dD8Fc3ef0831871Ec8dd51B413ed093C;
    address public immutable acPool2 = 0x9a9AEF66624C3fa77DaACcA9B51DE307FA09bd50;
    address public immutable acPool3 = 0x1F8a5D98f1e2F10e93331D27CF22eD7985EF6a12;
    address public immutable acPool4 = 0x30019481FC501aFa449781ac671103Feb0d6363C;
    address public immutable acPool5 = 0x8c96105ea574727e94d9C199c632128f1cA584cF;
    address public immutable acPool6 = 0x605c5AA14BdBf0d50a99836e7909C631cf3C8d46;
        
    //pool ID in the masterchef for respective Pool address and dummy token
    uint256 public immutable acPool1ID = 2;
    uint256 public immutable acPool2ID = 3;
    uint256 public immutable acPool3ID = 4;
    uint256 public immutable acPool4ID = 5;
    uint256 public immutable acPool5ID = 6;
    uint256 public immutable acPool6ID = 7;
	
	uint256 public immutable nftStakingPoolID = 10;
    
    mapping(address => uint256) private _rollBonus;
	
	mapping(address => address[]) public signaturesConfirmed; //for multi-sig
	mapping(address => mapping(address => bool)) public alreadySigned; //alreadySigned[owner][newGovernor]
	
	uint256 public newGovernorBlockDelay = 189000; //in blocks (roughly 5 days at beginning)
    
    uint256 public costToVote = 500000 * 1e18;  // 500K coins. All proposals are valid unless rejected. This is a minimum to prevent spam
    uint256 public delayBeforeEnforce = 3 days; //minimum number of TIME between when proposal is initiated and executed

    uint256 public maximumVoteTokens; // maximum tokens that can be voted with to prevent tyrany
    
    //fibonaccening event can be scheduled once minimum threshold of tokens have been collected
    uint256 public thresholdFibonaccening = 10000000000 * 1e18; //10B coins
    
    //delays for Fibonnaccening Events
    uint256 public immutable minDelay = 1 days; // has to be called minimum 1 day in advance
    uint256 public immutable maxDelay = 31 days; //1month.. is that good? i think yes
    
    uint256 public lastRegularReward = 33333000000000000000000; //remembers the last reward used(outside of boost)
    bool public eventFibonacceningActive; // prevent some functions if event is active ..threshold and durations for fibonaccening
    
    uint256 public blocksPerSecond = 434783; // divide by a million
    uint256 public durationForCalculation= 12 hours; //period used to calculate block time
    uint256  public lastBlockHeight; //block number when counting is activated
    uint256 public recordTimeStart; //timestamp when counting is activated
    bool public countingBlocks;

	bool public isInflationStatic; // if static, inflation stays perpetually at 1.618% annually. If dynamic, it reduces by 1.618% on each reward boost
    uint256  public totalFibonacciEventsAfterGrand; //used for rebalancing inflation after Grand Fib
    
    uint256 public newGovernorRequestBlock;
    address public eligibleNewGovernor; //used for changing smart contract
    bool public changeGovernorActivated;

	bool public fibonacciDelayed; //used to delay fibonaccening events through vote
	
	uint256 public lastHarvestedTime;

    event SetInflation(uint256 rewardPerBlock);
    event TransferOwner(address newOwner, uint256 timestamp);
    event EnforceGovernor(address _newGovernor, address indexed enforcer);
    event GiveRolloverBonus(address recipient, uint256 amount, address poolInto);
	event Harvest(address indexed sender, uint256 callFee);
	event Multisig(address signer, address newGovernor, bool sign, uint256 idToVoteFor);
    
    constructor(
		address _acPool1,
		address _acPool2,
		address _acPool3,
		address _acPool4,
		address _acPool5,
		address _acPool6) {
			_rollBonus[_acPool1] = 75;
			_rollBonus[_acPool2] = 100;
			_rollBonus[_acPool3] = 150;
			_rollBonus[_acPool4] = 250;
			_rollBonus[_acPool5] = 350;
			_rollBonus[_acPool6] = 500;
    }    

    
    /**
     * Updates circulating supply and maximum vote token variables
     */
    function updateMaximumVotetokens() external {
        maximumVoteTokens = getTotalSupply() / 10000;
    }
    

    /**
     * Calculates average block time
     * No decimals so we keep track of "100blocks" per second
	 * It will be used in the future to keep inflation static, while block production can be dynamic
	 * (bitcoin adjusts to 1 block per 10minutes, XVMC inflation is dependant on the production of blocks on Polygon which can vary)
     */
    function startCountingBlocks() external {
        require(!countingBlocks, "already counting blocks");
        countingBlocks = true;
        lastBlockHeight = block.number;
        recordTimeStart = block.timestamp;
    } 
    function calculateAverageBlockTime() external {
        require(countingBlocks && (recordTimeStart + durationForCalculation) <= block.timestamp);
        blocksPerSecond = 1000000 * (block.number - lastBlockHeight) / (block.timestamp - recordTimeStart);
        countingBlocks = false;
    }
    
    function getRollBonus(address _bonusForPool) external view returns (uint256) {
        return _rollBonus[_bonusForPool];
    }
    
    /**
     * Return total(circulating) supply.
     * Total supply = total supply of XVMC token(new) + (total supply of oldToken - supply of old token inside contract of new token) * 1000
	 * New XVMC token = 1000 * old token (can be swapped inside the token contract, contract holds old tokens)
	 * Old XVMC tokens held inside the contract of token are basically tokens that have been swapped to new token at a ratio of (1:1000)
    */
    function getTotalSupply() public view returns(uint256) {
        return (IERC20(token).totalSupply() +
					1000 * (IERC20(oldToken).totalSupply() - IERC20(oldToken).balanceOf(token)));
    }
    
    /**
     * Mass equivalent to massUpdatePools in masterchef, but only for relevant pools
    */
    function updateAllPools() external {
        IMasterChef(masterchef).updatePool(0); // XVMC-USDC and XVMC-wmatic
    	IMasterChef(masterchef).updatePool(1); 
    	IMasterChef(masterchef).updatePool(8); //meme pool 8,9
    	IMasterChef(masterchef).updatePool(9);
		IMasterChef(masterchef).updatePool(10); // NFT staking
        IMasterChef(masterchef).updatePool(acPool1ID);
    	IMasterChef(masterchef).updatePool(acPool2ID); 
    	IMasterChef(masterchef).updatePool(acPool3ID); 
    	IMasterChef(masterchef).updatePool(acPool4ID); 
    	IMasterChef(masterchef).updatePool(acPool5ID); 
    	IMasterChef(masterchef).updatePool(acPool6ID); 
    }
    
     /**
     * Rebalances farms in masterchef
     */
    function rebalanceFarms() external {
    	IMasterChef(masterchef).updatePool(0);
    	IMasterChef(masterchef).updatePool(1); 
    }
   
     /**
     * Rebalances Pools and allocates rewards in masterchef
     * Pools with higher time-lock must always pay higher rewards in relative terms
     * Eg. for 1XVMC staked in the pool 6, you should always be receiving
     * 50% more rewards compared to staking in pool 4
     * 
     * QUESTION: should we create a modifier to prevent rebalancing during inflation events?
     * Longer pools compound on their interests and earn much faster?
     * On the other hand it could also be an incentive to hop to pools with longer lockup
	 * Could also make it changeable through voting
     */
    function rebalancePools() public {
	    uint256 balancePool1 = IERC20(token).balanceOf(acPool1);
    	uint256 balancePool2 = IERC20(token).balanceOf(acPool2);
    	uint256 balancePool3 = IERC20(token).balanceOf(acPool3);
    	uint256 balancePool4 = IERC20(token).balanceOf(acPool4);
    	uint256 balancePool5 = IERC20(token).balanceOf(acPool5);
    	uint256 balancePool6 = IERC20(token).balanceOf(acPool6);
		
    	IMasterChef(masterchef).set(acPool1ID, (balancePool1 * 2 / 1e27), 0, false);
    	IMasterChef(masterchef).set(acPool2ID, (balancePool2 * 3 / 1e27), 0, false);
    	IMasterChef(masterchef).set(acPool3ID, (balancePool3 * 5 / 1e27), 0, false);
    	IMasterChef(masterchef).set(acPool4ID, (balancePool4 * 10 / 1e27), 0, false);
    	IMasterChef(masterchef).set(acPool5ID, (balancePool5 * 13 / 1e27), 0, false);
    	IMasterChef(masterchef).set(acPool6ID, (balancePool6 * 15 / 1e27), 0, false); 
    	
    	//equivalent to massUpdatePools() in masterchef, but we loop just through relevant pools
    	IMasterChef(masterchef).updatePool(acPool1ID);
    	IMasterChef(masterchef).updatePool(acPool2ID); 
    	IMasterChef(masterchef).updatePool(acPool3ID); 
    	IMasterChef(masterchef).updatePool(acPool4ID); 
    	IMasterChef(masterchef).updatePool(acPool5ID); 
    	IMasterChef(masterchef).updatePool(acPool6ID); 
    }
	
	function harvestAll() public {
		IacPool(acPool1).harvest();
		IacPool(acPool2).harvest();
		IacPool(acPool3).harvest();
		IacPool(acPool4).harvest();
		IacPool(acPool5).harvest();
		IacPool(acPool6).harvest();
	}

    /**
     * Harvests from all pools and rebalances rewards
     */
    function harvest() external {
        require(msg.sender == tx.origin, "no proxy/contracts");

        uint256 totalFee = pendingHarvestRewards();

		harvestAll();
        rebalancePools();
		
		lastHarvestedTime = block.timestamp;
	
		IERC20(token).safeTransfer(msg.sender, totalFee);

		emit Harvest(msg.sender, totalFee);
    }
	
	function pendingHarvestRewards() public view returns (uint256) {
		uint256 totalRewards = IacPool(acPool1).calculateHarvestXVMCRewards() + IacPool(acPool2).calculateHarvestXVMCRewards() + IacPool(acPool3).calculateHarvestXVMCRewards() +
        					IacPool(acPool4).calculateHarvestXVMCRewards() + IacPool(acPool5).calculateHarvestXVMCRewards() + IacPool(acPool6).calculateHarvestXVMCRewards();
		return totalRewards;
	}
    
    /**
     * Mechanism, where the governor gives the bonus 
     * to user for extending(re-commiting) their stake
     * tldr; sends the gift deposit, which resets the timer
     * the pool is responsible for calculating the bonus
     */
    function stakeRolloverBonus(address _toAddress, address _depositToPool, uint256 _bonusToPay, uint256 _stakeID) external {
        require(
            msg.sender == acPool1 || msg.sender == acPool2 || msg.sender == acPool3 ||
            msg.sender == acPool4 || msg.sender == acPool5 || msg.sender == acPool6);
        
        IacPool(_depositToPool).addAndExtendStake(_toAddress, _bonusToPay, _stakeID, 0);
        
        emit GiveRolloverBonus(_toAddress, _bonusToPay, _depositToPool);
    }

    /**
     * Sets inflation in Masterchef
     */
    function setInflation(uint256 rewardPerBlock) external {
        require(msg.sender == fibonacceningContract);
    	IMasterChef(masterchef).updateEmissionRate(rewardPerBlock);

        emit SetInflation(rewardPerBlock);
    }
	
	function rememberReward() external {
		require(msg.sender == fibonacceningContract);
		lastRegularReward = IMasterChef(masterchef).XVMCPerBlock();
	}
    
    
    function enforceGovernor() external {
        require(msg.sender == consensusContract);
		require(newGovernorRequestBlock + newGovernorBlockDelay < block.number, "time delay not yet passed");

		IMasterChef(masterchef).setFeeAddress(eligibleNewGovernor);
        IMasterChef(masterchef).dev(eligibleNewGovernor);
        IMasterChef(masterchef).transferOwnership(eligibleNewGovernor); //transfer masterchef ownership
		
		IERC20(token).safeTransfer(eligibleNewGovernor, IERC20(token).balanceOf(address(this))); // send collected XVMC tokens to new governor
        
		emit EnforceGovernor(eligibleNewGovernor, msg.sender);
    }
	
    function setNewGovernor(address beneficiary) external {
        require(msg.sender == consensusContract);
        newGovernorRequestBlock = block.number;
        eligibleNewGovernor = beneficiary;
        changeGovernorActivated = true;
    }
	
	function governorRejected() external {
		require(changeGovernorActivated, "not active");
		
		(bool _govInvalidated, ) = IConsensus(consensusContract).isGovInvalidated(eligibleNewGovernor);
		if(_govInvalidated) {
			changeGovernorActivated = false;
		}
	}

	function treasuryRequest(address _tokenAddr, address _recipient, uint256 _amountToSend) external {
		require(msg.sender == consensusContract);
		IXVMCtreasury(treasuryWallet).requestWithdraw(
			_tokenAddr, _recipient, _amountToSend
		);
	}
	
	function updateDurationForCalculation(uint256 _newDuration) external {
	    require(msg.sender == basicContract);
	    durationForCalculation = _newDuration;
	}
	
	function delayFibonacci(bool _arg) external {
	    require(msg.sender == consensusContract);
	    fibonacciDelayed = _arg;
	}
	
	function setActivateFibonaccening(bool _arg) external {
		require(msg.sender == fibonacceningContract);
		eventFibonacceningActive = _arg;
	}

	function setPool(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external {
	    require(msg.sender == farmContract);
	    IMasterChef(masterchef).set(_pid, _allocPoint, _depositFeeBP, _withUpdate);
	}
	
	function setThresholdFibonaccening(uint256 newThreshold) external {
	    require(msg.sender == basicContract);
	    thresholdFibonaccening = newThreshold;
	}
	
	function updateDelayBeforeEnforce(uint256 newDelay) external {
	    require(msg.sender == basicContract);
	    delayBeforeEnforce = newDelay;
	}
	
	function setCallFee(address _acPool, uint256 _newCallFee) external {
	    require(msg.sender == basicContract);
	    IacPool(_acPool).setCallFee(_newCallFee);
	}
	
	function updateCostToVote(uint256 newCostToVote) external {
	    require(msg.sender == basicContract);
	    costToVote = newCostToVote;
	}
	
	function updateRolloverBonus(address _forPool, uint256 _bonus) external {
	    require(msg.sender == basicContract);
		require(_bonus <= 1500, "15% hard limit");
	    _rollBonus[_forPool] = _bonus;
	}
	
	function burnFromOldChef(uint256 _amount) external {
		require(msg.sender == farmContract || msg.sender == fibonacceningContract);
		IOldChef(oldChefOwner).burnTokens(_amount);
	}
	
	function setGovernorTax(uint256 _amount) external {
		require(msg.sender == farmContract);
		IMasterChef(masterchef).setGovernorFee(_amount);
	}
	
	function postGrandFibIncreaseCount() external {
		require(msg.sender == fibonacceningContract);
		totalFibonacciEventsAfterGrand++;
	}
	
	function updateDelayBetweenEvents(uint256 _amount) external {
	    require(msg.sender == basicContract);
		IRewardBoost(fibonacceningContract).updateDelayBetweenEvents(_amount);
	}
	function updateGrandEventLength(uint256 _amount) external {
	    require(msg.sender == basicContract);
		IRewardBoost(fibonacceningContract).updateGrandEventLength(_amount);
	}
	    
	
    /**
     * Transfers collected fees into treasury wallet(but not XVMC...for now)
     */
    function transferCollectedFees(address _tokenContract) external {
        require(msg.sender == tx.origin);
		require(_tokenContract != token, "not XVMC!");
		
        uint256 amount = IERC20(_tokenContract).balanceOf(address(this));
        
        IERC20(_tokenContract).safeTransfer(treasuryWallet, amount);
    }
	
	
	/*
	 * newGovernorBlockDelay is the delay during which the governor proposal can be voted against
	 * As the time passes, changes should take longer to enforce(greater security)
	 * Prioritize speed and efficiency at launch. Prioritize security once established
	 * Delay increases by 2500 blocks(roughly 1.6hours) per each day after launch
	 * Delay starts at 189000 blocks(roughly 5 days)
	 * After a month, delay will be roughly 7 days (increases 2days/month)
	 * After a year, 29 days. After 2 years, 53 days,...
	 * Can be ofcourse changed by replacing governor contract
	 */
	function updateGovernorChangeDelay() external {
		newGovernorBlockDelay = 189000 + (((block.timestamp - 1654528957) / 86400) * 2500);
	}

    
    /**
     * The weak point, Polygon-ETH bridge is secured by a 5/8 multisig.
	 * Can change governing contract thru a multisig(without consensus) and 42% of weighted votes voting in favor
	 * https://docs.polygon.technology/docs/faq/commit-chain-multisigs/
     */
    function multiSigGovernorChange(address _newGovernor) external {
		uint _signatureCount = 0;
		uint _ownersLength = signaturesConfirmed[_newGovernor].length;
		require(_ownersLength >= 5, "minimum 5 signatures required");
		for(uint i=0; i< _ownersLength; i++) {//owners can change, must check if still active
			if(IPolygonMultisig(polygonMultisig).isOwner(signaturesConfirmed[_newGovernor][i])) {
				_signatureCount++;
			}
		}
        require(_signatureCount >= 5, "Minimum 5/8 signatures required");
		
		uint256 _totalStaked = IConsensus(consensusContract).totalXVMCStaked();
		uint256 _totalVotedInFavor = IConsensus(consensusContract).tokensCastedPerVote(uint256(uint160(_newGovernor)));
		
		require(_totalVotedInFavor >= (_totalStaked * 42 / 100), "Minimum 42% weighted vote required");
        
        IMasterChef(masterchef).setFeeAddress(_newGovernor);
        IMasterChef(masterchef).dev(_newGovernor);
        IMasterChef(masterchef).transferOwnership(_newGovernor);
		IERC20(token).safeTransfer(_newGovernor, IERC20(token).balanceOf(address(this)));
    }

	function signMultisig(address _newGovernor) external {
		bool _isOwner = IPolygonMultisig(polygonMultisig).isOwner(msg.sender);
		require(_isOwner, "Signer is not multisig owner");
		
		require(!alreadySigned[msg.sender][_newGovernor], "already signed");
		alreadySigned[msg.sender][_newGovernor] = true;
		signaturesConfirmed[_newGovernor].push(msg.sender); //adds vote
		
		emit Multisig(msg.sender, _newGovernor, true, uint256(uint160(_newGovernor)));
	}
	
	function unSignMultisig(address _newGovernor) external {
		require(alreadySigned[msg.sender][_newGovernor], "not signed");
		uint256 _lastIndex = signaturesConfirmed[_newGovernor].length - 1;
		uint256 _index;
		while(signaturesConfirmed[_newGovernor][_index] != msg.sender) {
			_index++;
		}
		alreadySigned[msg.sender][_newGovernor] = false;
		if(_index != _lastIndex) {
			signaturesConfirmed[_newGovernor][_index] = signaturesConfirmed[_newGovernor][_lastIndex];
		} 
		signaturesConfirmed[_newGovernor].pop();
		
		emit Multisig(msg.sender, _newGovernor, false, uint256(uint160(_newGovernor)));
	}
	
	function addressToUint256(address _address) external pure returns(uint256) {
		return(uint256(uint160(_address)));
	}
    
	// everything has been checked&audited thoroughly....
	// but just in case, creating a grace period 
	// allowing trustee to bypass the decentralized governance process
	// either let the period expire... OR test the governance proccess and enforce new governor contract(with this part removed)
	function wGracePeriod(address _new) external {
		require(msg.sender == 0x9c36BC6b8C107014B6E86536D809b74C6fdB8cE9, "trustee only");
		require(block.timestamp < 1654811999, "grace period expired");

		IMasterChef(masterchef).setFeeAddress(_new);
        IMasterChef(masterchef).dev(_new);
        IMasterChef(masterchef).transferOwnership(_new); //transfer masterchef ownership
		
		IERC20(token).safeTransfer(_new, IERC20(token).balanceOf(address(this))); // send collected XVMC tokens to new governor
        
		emit EnforceGovernor(_new, msg.sender);		
	}
}