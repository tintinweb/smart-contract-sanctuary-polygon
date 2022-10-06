// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./InterFaces.sol";

contract LiquidityAndStakingV2 is OwnableUpgradeable {
    // uniswapRouter address
    address public uniswapRouterAddress;

    // gain token address
    address public GainTokenAddress;

    // gain amount to be swapped and added to liquidity
    uint256 public GainAmount;

    // reward rate for staking
    uint256 public rewardRate;

    // time interval for reward
    uint256 public timePeriod;

    // temporary values
    uint256 public amountA;
    uint256 public amountB;
    uint256 public liquidityAB;

    // temporary array of address
    address[] public PAIR1_GAIN;
    address[] public PAIR2_GAIN;

    // stake structure
    struct StakeInfo {
        uint256 stakeId;
        address User;
        address LPAddress;
        uint256 LPTokens;
        uint256 ClaimedReward;
        uint256 LastClaimedTimestamp;
    }
    
    // mapping stake id with its stake information
    mapping(uint256 => StakeInfo) public StakeInformation;

    // mapping of address w.r.t their owned take ids
    mapping(address => uint256[]) public stakeOwner;

    // stake counter
    uint256 public stakeCounter;

    // stken token mapping
    mapping(address => bool) public stakeToken;
    
    struct History {
        uint256 stakeId;
        uint256 createdAt;
    }
    mapping(address => History[]) public StakeHistory;
    /**
     * @dev Emitted when gain amount is swapped and added into liquidity
     */

    event TokenDetails(uint256 GainAmount, uint256 Pair1Amount, uint256 Pair2Amount);

    /**
     * @dev Emitted when user stakes amount of LP tokens.
     */
    event Stake(uint256 stakeId, address User, address LPAddress, uint256 Amount);

    /**
     * @dev Emitted when user unstakes LP tokens.
     */
    event Unstake(uint256 stakeId, address User, address LPAddress, uint256 Amount);

    /**
     * @dev Emitted when user claims the reward for lp tokens.
     */
    event Claimed(address User, address[] LPAddress, uint256 Amount);

    // initilization part
    function initialize() public initializer {
        __Ownable_init();
        uniswapRouterAddress = 0x8954AfA98594b838bda56FE4C12a09D7739D179b;
        GainTokenAddress = 0xa568A77c70a1f89af60Eb7d505647Ca4195ADcae;
        GainAmount = 100 * (10**18);

        rewardRate = 100000000000000000;
        timePeriod = 300;
    }

    /**
     * @dev updates gain token address.
     *
     * @param _gain_token_address gain token address
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateGainTokenAddress(address _gain_token_address) external onlyOwner {
        GainTokenAddress = _gain_token_address;
    }

    /**
     * @dev withdraw any ERC20 tokens from contract.
     *
     * Requirements:
     * - only owner can update value.
     */

    function withdrawErc20Token(address _tokenAddress)
        external
        virtual
        onlyOwner
    {
        IGain(_tokenAddress).transfer(
            owner(),
            IGain(_tokenAddress).balanceOf(address(this))
        );
    }

    /**
     * @dev withdraw ETH/MATIC tokens from contract.
     *
     * Requirements:
     * - only owner can update value.
     */

    function withdraw() external virtual onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    /**
     * @dev updates gain total amount to be swapped and add to liquidity, 
     * reward rate and time intervals.
     *
     * @param _amount amount of tokens.
     * @param _rewardRate reward rate.
     * @param _timeInterval time interval for rewards.
     *
     * Requirements:
     * - only owner can update value.
     */

    function changeTotalGainAmount(uint256 _amount, uint256 _rewardRate, uint256 _timeInterval) external onlyOwner {
        GainAmount = _amount;
        rewardRate = _rewardRate;
        timePeriod = _timeInterval;
    }

    /**
     * @dev this method swaps the 25%-25% with two pair addresses 
     * and 25%-25% add into liquidity with two pair address. 
     *
     * @param pair1 first pair token address.
     * @param pair2 second pair token address.
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     * Returns
     * - boolean.
     *
     * Emits a {TokenDetails} event.
     */

    function tokenSwap(address pair1, address pair2)
        external
        onlyOwner
        returns (bool)
    {
        uint256 deadline = block.timestamp + 30000 days;

        IGain tokenAddress = IGain(GainTokenAddress);
        uint256 balance = tokenAddress.balanceOf(
            IGain(GainTokenAddress).GLWallet()
        );

        require(balance >= GainAmount, "$LIQ&STAK: GL-wallet has less balance");

        tokenAddress.safeTransfer(
            IGain(GainTokenAddress).GLWallet(),
            address(this),
            GainAmount
        );
        uint256 amount = GainAmount / 4;

        PAIR1_GAIN = [GainTokenAddress, pair1];
        PAIR2_GAIN = [GainTokenAddress, pair2];

        tokenAddress.approve(
            uniswapRouterAddress,
            IGain(tokenAddress).balanceOf(address(this))
        );

        swapFromContract(
            pair1,
            amount,
            PAIR1_GAIN,
            address(this),
            deadline
        );
        uint256 pair1Amt = IGain(pair1).balanceOf(address(this));

        addLiquidityFromContract(
            pair1,
            amount,
            pair1Amt,
            1,
            1,
            IGain(GainTokenAddress).GLWallet(),
            deadline
        );

        swapFromContract(
            pair2,
            amount,
            PAIR2_GAIN,
            address(this),
            deadline
        );
        uint256 pair2Amt = IGain(pair2).balanceOf(address(this));

        addLiquidityFromContract(
            pair2,
            amount,
            pair2Amt,
            1,
            1,
            IGain(GainTokenAddress).GLWallet(),
            deadline
        );

        emit TokenDetails(amount, pair1Amt, pair2Amt);
        return true;
    }

    /**
     * @dev user stakes LP tokens and gain rewards on it.
     *
     * @param _amount amount of LP tokens.
     * @param _lp_address second pair token address.
     *
     * Requirements:
     * - msg.sender must be have LP tokens of GAIN token address(ex. DAI/GAIN, USDC/GAIN, etc)
     *
     * Returns
     * - boolean.
     *
     * Emits a {Stake} event.
     */

    function stake(uint256 _amount, address _lp_address) external virtual {
        require(isLpTokenValid(_lp_address) || stakeToken[_lp_address], "$LIQ&STAK: Invalid LP tokens");
        require(
            IUniswapV2Pair(_lp_address).allowance(msg.sender, address(this)) >=
                _amount,
            "$LIQ&STAK: Not enough allowance"
        );
        stakeCounter += 1;

        IUniswapV2Pair(_lp_address).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        StakeInfo memory _data = StakeInfo(
            stakeCounter,
            msg.sender,
            _lp_address,
            _amount,
            0,
            block.timestamp
        );
        StakeInformation[stakeCounter] = _data;
        stakeOwner[msg.sender].push(stakeCounter);

        History memory _hist_data = History(
            stakeCounter,
            block.timestamp
        );
        StakeHistory[msg.sender].push(_hist_data);

        emit Stake(stakeCounter, msg.sender, _lp_address, _amount);
    }

    /**
     * @dev user can unstake the LP tokens w.r.t to their stake Id. 
     * User stops getting reward and LP tokens ar return to the user.
     *
     * @param stakeId stake Id to be unstaked.
     *
     * Requirements:
     * - msg.sender must be owner of stake Id.
     *
     * Emits a {Unstake} event.
     */

    function unstake(uint256 stakeId) external virtual {
        require(
            (StakeInformation[stakeId]).LPTokens > 0,
            "$LIQ&STAK: Invalid stake Id"
        );

        (StakeInformation[stakeId]).LPTokens = 0;

        IUniswapV2Pair(StakeInformation[stakeId].LPAddress).transfer(msg.sender, StakeInformation[stakeId].LPTokens);

        emit Unstake(stakeId, msg.sender, StakeInformation[stakeId].LPAddress, StakeInformation[stakeId].LPTokens);
    }

    /**
     * @dev user can view his/her stake details.
     *
     * @param _user user wallet address.
     *
     * Returns
     *  - TotalIds,
     *  - StakedTokens,
     *  - LpAddresses,
     *  - TotalRewards,
     *  - ClaimedRewards,
     *  - RemainingRewards
     *
     */

    function viewRewards(address _user)
        public
        view
        returns (
            uint256[] memory TotalIds,
            uint256[] memory StakedTokens,
            address[] memory LpAddresses,
            uint256[] memory TotalRewards,
            uint256[] memory ClaimedRewards,
            uint256[] memory RemainingRewards
        )
    {
        uint256 number = stakeOwner[_user].length;
        TotalIds = new uint256[](number);
        LpAddresses = new address[](number);
        ClaimedRewards = new uint256[](number);
        RemainingRewards = new uint256[](number);
        TotalRewards = new uint256[](number);
        StakedTokens = new uint256[](number);

        for(uint256 i = 0; i < stakeOwner[_user].length; i++){
            TotalIds[i] = stakeOwner[_user][i];
            LpAddresses[i] = StakeInformation[stakeOwner[_user][i]].LPAddress;
            ClaimedRewards[i] = StakeInformation[stakeOwner[_user][i]].ClaimedReward;
            StakedTokens[i] = StakeInformation[stakeOwner[_user][i]].LPTokens;

            if(StakeInformation[stakeOwner[_user][i]].LPTokens > 0){

                uint256 rate = (StakeInformation[stakeOwner[_user][i]].LPTokens *
                    rewardRate) / (10**18);
                
                uint256 num = (block.timestamp -
                    StakeInformation[stakeOwner[_user][i]].LastClaimedTimestamp) /
                    timePeriod;

                RemainingRewards[i] = num * rate;
            }
            TotalRewards[i] = RemainingRewards[i] + ClaimedRewards[i];
       }
    }

    /**
     * @dev user can claim total rewards.
     *
     * Requirements:
     * - msg.sender must be owner of stake Id.
     *
     * Returns
     * - boolean.
     *
     * Emits a {Claimed} event.
     */

    function Claim() external virtual {
        ( uint256[] memory TotalIds, ,address[] memory LpAddresses, , ,uint256[] memory RemainingRewards) = viewRewards(msg.sender);
        uint256 _amount;
        address[] memory LpAddress = new address[](TotalIds.length);
        uint256 j = 0;

        for(uint256 i = 0; i < TotalIds.length; i++){
            if(RemainingRewards[i] > 0){

                _amount += RemainingRewards[i];
                LpAddress[j] = LpAddresses[i];
                j++;

                StakeInformation[TotalIds[i]].ClaimedReward += RemainingRewards[i];
                StakeInformation[TotalIds[i]].LastClaimedTimestamp = block.timestamp;
            }
        }
        require(_amount > 0, "$LIQ&STAK: No rewards generated for user");
        IGain(GainTokenAddress).transfer(msg.sender, _amount);

        emit Claimed(msg.sender, LpAddresses, _amount);
    }

    /**
     * @dev user can view LP tokens are valid or not.
     *
     * @param _lp_address Lp token address.
     *
     * Returns
     *  - boolean
     *
     */

    function isLpTokenValid(address _lp_address) public view returns (bool) {
        return (IUniswapV2Pair(_lp_address).token0() == GainTokenAddress ||
            IUniswapV2Pair(_lp_address).token1() == GainTokenAddress);
    }

    /**
     * @dev adds the liquidity from the contract and transfers the LP tokens to the GL wallet.
     */

    function addLiquidityFromContract(
        address tokenAddress,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) internal returns (bool) {
        IGain tokenAddressB = IGain(tokenAddress);

        tokenAddressB.approve(
            uniswapRouterAddress,
            IGain(tokenAddress).balanceOf(address(this))
        );

        IUniswapV2Router01 addLiq = IUniswapV2Router01(uniswapRouterAddress);
        (amountA, amountB, liquidityAB) = addLiq.addLiquidity(
            GainTokenAddress,
            tokenAddress,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        return true;
    }

    /**
     * @dev swaps gain token with pair address and 
     * returns the pair tokens into this contract for adding liquidity.
     */

    function swapFromContract(
        address tokenAddress,
        uint256 amountIn,
        address[] memory path,
        address to,
        uint256 deadline
    ) internal {
        IGain tokenAddress_ = IGain(tokenAddress);

        tokenAddress_.approve(
            uniswapRouterAddress,
            IGain(tokenAddress).balanceOf(address(this))
        );

        IUniswapV2Router01 swapLiq = IUniswapV2Router01(uniswapRouterAddress);

        swapLiq.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            1,
            path,
            to,
            deadline
        );
    }
    
    /**
     * @dev updates token address for staking
     *
     * @param _token_address token address.
     * @param _status status.
     *
     * Requirements:
     * - only owner can update value.
     */

    function addStakeTokenContract(address _token_address, bool _status) external onlyOwner {
        stakeToken[_token_address] = _status;
    }

    function showHistory(address _user) external view returns(address User, History[] memory UserHistory){
        User = _user;
        uint256 number = StakeHistory[_user].length;
        UserHistory = new History[](number);
        for(uint256 i = 0; i < StakeHistory[_user].length; i++){
            UserHistory[i] = StakeHistory[_user][i];
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGain {

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
     * @dev Moves `amount` tokens from the `from` account to `to` account.
     *
     * Emits a {Transfer} event.
     */

    function safeTransfer(address from, address to, uint256 amount) external;

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
     * @dev Returns a Gain staking wallet address.
     *
     */

    function GSTKWallet() external view returns (address);

    /**
     * @dev Returns a Gain stability wallet address.
     *
     */

    function GSWallet() external view returns (address);

    /**
     * @dev Returns a Gain liquidity wallet address.
     *
     */

    function GLWallet() external view returns (address);

    /**
     * @dev Returns a Gain voucher wallet address.
     *
     */

    function GVWallet() external view returns (address);
}

interface IUniswapV2Router01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}