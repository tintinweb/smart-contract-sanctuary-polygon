// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

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

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getTotalAmounts() external view returns (uint256 reserve0, uint256 reserve1);
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
        function deposit(
        uint deposit0,
        uint deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    )external returns (uint shares);

    function getDepositAmount(
        address pos,
        address token,
        uint deposit
    ) external view returns(uint256, uint256);
}

interface IYeller {
    function deposit(uint256 _pid, uint256 _amount, address _depositor) external; 
    function withdraw(uint256 _pid, uint256 _amount) external;
    function getUserAmount(uint256 _pid, address _user) external returns (uint256);
    function getWethData() external view returns (uint256);
}

interface IWETH is IERC20 {
    function withdraw(uint256 wad) external;
}

interface IVault is IERC20 {
    function deposit(uint256 amount) external;
    function withdraw(uint256 shares) external;
    function want() external pure returns (address);
}

interface IMasterChef {
    function withdraw(uint256 _amount, address _to, address _from, uint256[4] memory minAmounts) external;
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract gammaUWZap is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IVault;

    AggregatorV3Interface internal priceFeedWeth;
    IYeller yeller;
    IUniswapV2Router02 public immutable router;
    IUniswapV2Router02 public immutable routerLiq;
    address public immutable WETH;
    uint256 public constant minimumAmount = 1000;
    uint256 public constant fee = 1;

    constructor(address _router, address _routerLiq, address _WETH, address _yeller, address _priceFeedWeth) {
        router = IUniswapV2Router02(_router);
        routerLiq = IUniswapV2Router02(_routerLiq);
        WETH = _WETH;
        yeller = IYeller(_yeller);
        priceFeedWeth = AggregatorV3Interface(_priceFeedWeth);
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function claimRewards() public {
        yeller.withdraw(0, 0);
    }

    function comeIn (address _vault, uint256 tokenAmountOutMin, address tokenIn, uint256 tokenInAmount) external {
        require(tokenInAmount >= minimumAmount, 'Zap: Insignificant input amount');
        require(IERC20(tokenIn).allowance(msg.sender, address(this)) >= tokenInAmount, 'Zap: Input token is not approved');

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount);

        _swapAndStake(_vault, tokenAmountOutMin, tokenIn);
    }

    function goOut (address _vault, uint256 _withdrawAmount, address _tokenOut) external {
        (IVault vault, IUniswapV2Pair pair) = _getVaultPair(_vault);
        require(yeller.getUserAmount(0, msg.sender) >= _withdrawAmount, "Zap: not enough balance from yeller");

        yeller.withdraw(0, _withdrawAmount);
        vault.withdraw(_withdrawAmount);
        _removeLiqudity(address(pair), _withdrawAmount);

        address[] memory tokens;
        uint balanceToken;
        uint tokenAmountOutMin;

        (, int price, , , ) = priceFeedWeth.latestRoundData();
        uint decimalsPriceFeed = priceFeedWeth.decimals();
        uint divisor = 10**decimalsPriceFeed;
        uint wethUsdtPrice = (uint(price) * 1e18) / divisor;

        if(_tokenOut == pair.token0()){
            balanceToken = IERC20(pair.token1()).balanceOf(address(this));
            uint amountInUsdc = balanceToken * wethUsdtPrice * 1e6 / 1e36;
            tokenAmountOutMin = amountInUsdc - (amountInUsdc * 10 / 100);

            tokens = new address[](2);
            tokens[0] = pair.token1();
            tokens[1] = pair.token0();

            _approveTokenIfNeeded(tokens[0], address(router));
            _approveTokenIfNeeded(tokens[1], address(router));
            router.swapExactTokensForTokens(balanceToken, tokenAmountOutMin, tokens, address(this), block.timestamp);

        } else if (_tokenOut == pair.token1()) {
            balanceToken = IERC20(pair.token0()).balanceOf(address(this));
            uint usdcToDecimals = balanceToken * 1e18 / 1e6;
            uint amountInWeth =  usdcToDecimals * 1e18 / wethUsdtPrice;
            tokenAmountOutMin = amountInWeth - (amountInWeth * 10 / 100);

            tokens = new address[](2);
            tokens[0] = pair.token0();
            tokens[1] = pair.token1();

            _approveTokenIfNeeded(tokens[0], address(router));
            _approveTokenIfNeeded(tokens[1], address(router));
            router.swapExactTokensForTokens(balanceToken, tokenAmountOutMin, tokens, address(this), block.timestamp);
        } else {
            tokens = new address[](2);
            tokens[0] = pair.token0();
            tokens[1] = pair.token1();
        }

        _returnAssets(tokens);
    }

    function _removeLiqudity(address pair, uint _withdrawAmount) private {
        uint256[4] memory minIn = [uint256(0), uint256(0), uint256(0), uint256(0)];
        IMasterChef(pair).withdraw(_withdrawAmount, address(this), address(this), minIn);
    }

    function _getVaultPair (address _vault) private pure returns (IVault vault, IUniswapV2Pair pair) {
        vault = IVault(_vault);
        pair = IUniswapV2Pair(vault.want());
    }

    function _swapAndStake(address _vault, uint256 tokenAmountOutMin, address tokenIn) private {
        (IVault vault, IUniswapV2Pair pair) = _getVaultPair(_vault);

        (uint256 reserveA, uint256 reserveB) = pair.getTotalAmounts();
        require(reserveA > minimumAmount && reserveB > minimumAmount, 'Zap: Liquidity pair reserves too low');

        require(pair.token0() == tokenIn, 'Zap: Input token not present in liqudity pair');

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = pair.token1();

        uint256 fullInvestment = IERC20(tokenIn).balanceOf(address(this));
        uint256 swapAmountIn = _getSwapAmount(fullInvestment, reserveA, reserveB);

        _approveTokenIfNeeded(path[0], address(router));
        uint256[] memory swapedAmounts = router
            .swapExactTokensForTokens(swapAmountIn, tokenAmountOutMin, path, address(this), block.timestamp);

        uint middleAmount = getLiqAmount(address(pair), path[1], swapedAmounts[1]);

        _approveTokenIfNeeded(path[0], address(pair)); 
        _approveTokenIfNeeded(path[1], address(pair)); 
        uint256[4] memory minIn = [uint256(0), uint256(0), uint256(0), uint256(0)];
        uint256 amountLiquidity = routerLiq
              .deposit(middleAmount, swapedAmounts[1], address(this), address(pair), minIn);

        _approveTokenIfNeeded(address(pair), address(vault));
        vault.deposit(amountLiquidity);
        vault.safeTransfer(address(this), vault.balanceOf(address(this)));

        uint sharesBal = vault.balanceOf(address(this));
        vault.approve(address(yeller), sharesBal);
        yeller.deposit(0, sharesBal, msg.sender);
        
        _returnAssets(path);
    }

    function getLiqAmount(address _pair, address _path, uint _swapedAmounts) internal view returns(uint) {
        (uint256 amountNeededUsdcMin, uint256 amountNeededUsdcMax)= routerLiq.getDepositAmount(_pair, _path, _swapedAmounts);
        uint middleAmount = (amountNeededUsdcMin + amountNeededUsdcMax) / 2;
        return middleAmount;
    }

    function _returnAssets(address[] memory tokens) private {
        uint256 balance;
        for (uint256 i; i < tokens.length; i++) {
            balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                if (tokens[i] == WETH) {
                    IWETH(WETH).withdraw(balance);
                    (bool success,) = msg.sender.call{value: balance}(new bytes(0));
                    require(success, 'Zap: ETH transfer failed');
                } else {
                    IERC20(tokens[i]).safeTransfer(msg.sender, balance);
                }
            }
        }
    }

    function _getSwapAmount(uint256 investmentA, uint256 reserveA, uint256 reserveB) private view returns (uint256 swapAmount) {
        uint wethPriceUsdt = yeller.getWethData();
        
        uint wethUsdt = reserveB * wethPriceUsdt / 1e18;
        uint stableUsdt = reserveA * 1e18 / 1e6;
        
        uint stablesInLp = wethUsdt + stableUsdt;
        uint partWethInLp = wethUsdt * 1e18 / stablesInLp;

        swapAmount = investmentA * partWethInLp / 1e18;
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint).max);
        }
    }

    function newYeller(address _yeller) external onlyOwner {
        yeller = IYeller(_yeller);
    }

    function yellerAddr() public view returns(address){
        return address(yeller);
    }
}