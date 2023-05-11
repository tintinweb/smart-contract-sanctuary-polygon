// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import "contracts/interfaces/IERC20MintBurn.sol";
import "contracts/interfaces/IOwnable.sol";
import "contracts/interfaces/ISwapRouter.sol";
import "contracts/interfaces/IWETH9.sol";

import {ICurveFiPool} from "contracts/curvefi/ICurveFiPool.sol";
import {ICurveFiGauge} from "contracts/curvefi/ICurveFiGauge.sol";
import {IERC20MintBurn} from "contracts/interfaces/IERC20MintBurn.sol";

contract SwapV2 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error NotApprovedStablecoin();
    error NotEnoughCRUS();
    error NotEnoughLiquidity();
    error NotEqualLength();

    event Mint(
        address acceptedToken,
        uint256 amount,
        uint256 amountCRUS,
        uint256 tax
    );
    event Redeem(uint256 amountCRUS, uint256 tax, uint256 amountUSDC);
    event IncludeToken(address token, uint256 fee);
    event ExcludeToken(address token);
    event Rebalance(uint256 state);
    event LiquidityIncreased(uint256 amount);
    event LiquidityDecreased(uint256 amount);
    event BinanceReservation(uint256 amount);
    event RebalanceFailure();

    address private _trustedForwarder;
    uint256 public constant PRECISION = 1e6;
    uint256 public constant MIN_AMOUNT = 1e18;
    uint256 public constant LOWER_BORDER = 7 * PRECISION;
    uint256 public constant UPPER_BORDER = 10 * PRECISION;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    address payable public WETH;
    address public pool; // aave pool
    address public gauge; // aave gauge
    address public lpToken; // aave LP
    address public immutable CRUS;
    address public immutable USDC;

    // AggregatorV3Interface private _priceFeed;
    uint256 private _feeMint;
    uint256 private _feeRedeem;
    uint256 private _binanceBalance;

    address private _masterWallet; // the address to which USD is sent
    address private _operationWallet; // the address to which the commission is sent (USD)
    address private _CRUSWallet; // CRUS holder
    address private _binanceWallet;

    mapping(address => uint256) internal _totalProceeded;
    mapping(address => uint256) public mapTokenDecimals; // token=>decimals
    mapping(address => uint24) public mapUniFee;
    mapping(address => bool) public whitelist;

    ISwapRouterV3 internal _uniswapRouter;
    IQuoter internal _uniswapQuoter;
    uint256 _decimalCRUS;
    uint256 _decimalUSDC;

    constructor(
        address usdc,
        address crus,
        address payable weth,
        uint256 feeMint,
        uint256 feeRedeem,
        address[3] memory wallets,
        address CRUSWallet,
        address uniswapRouter,
        address uniswapQuoter,
        address[] memory poolAddreses,
        address forwarder
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(SERVICE_ROLE, ADMIN_ROLE);
        mapTokenDecimals[usdc] = IERC20Metadata(usdc).decimals();
        mapTokenDecimals[crus] = IERC20Metadata(crus).decimals();
        mapTokenDecimals[weth] = IERC20Metadata(weth).decimals();

        mapUniFee[weth] = 500;
        WETH = weth;
        CRUS = crus;
        USDC = usdc;

        _feeMint = feeMint;
        _feeRedeem = feeRedeem;

        pool = poolAddreses[0];
        lpToken = poolAddreses[1];

        _trustedForwarder = forwarder;
        _masterWallet = wallets[0];
        _operationWallet = wallets[1];
        _binanceWallet = wallets[2];
        _CRUSWallet = CRUSWallet;
        _uniswapRouter = ISwapRouterV3(uniswapRouter);
        _uniswapQuoter = IQuoter(uniswapQuoter);

        IERC20(weth).approve(address(_uniswapRouter), type(uint256).max);
    }

    function includeToken(
        address token,
        uint24 fee
    ) external onlyRole(ADMIN_ROLE) {
        mapTokenDecimals[token] = IERC20Metadata(token).decimals();
        mapUniFee[token] = fee;
        IERC20(token).approve(address(_uniswapRouter), type(uint256).max);
        emit IncludeToken(token, fee);
    }

    function excludeToken(address token) external onlyRole(ADMIN_ROLE) {
        delete (mapTokenDecimals[token]);
        delete (mapUniFee[token]);

        emit ExcludeToken(token);
    }

    function setFeeMint(uint256 fee) external onlyRole(ADMIN_ROLE) {
        _feeMint = fee;
    }

    function setFeeRedeem(uint256 fee) external onlyRole(ADMIN_ROLE) {
        _feeRedeem = fee;
    }

    function mint(address acceptedToken, uint256 amount, uint256 minAmount) external {
        require(amount > 0, "ZeroAmount");
        require(
            mapTokenDecimals[acceptedToken] > 0,
            "the token is not included in the whitelist"
        );
        // transferFrom USD
        IERC20(acceptedToken).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
        uint amountUSDC = amount;
        if (acceptedToken != USDC) {
            amountUSDC = _uniswapRouter.exactInputSingle(
                ISwapRouterV3.ExactInputSingleParams({
                    tokenIn: acceptedToken,
                    tokenOut: USDC,
                    fee: mapUniFee[acceptedToken],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }
        uint256 amountTransfer = amountUSDC;
        uint256 tax;
        if (!whitelist[_msgSender()]) {
            (amountTransfer, tax) = _subtractPercentage(
                amountUSDC,
                _feeMint
            );

            IERC20(USDC).safeTransfer(_operationWallet, tax);
        }

        uint256 amountCRUS = _swapUSDCForCRUS(amountTransfer);

        require(amountCRUS >= minAmount, "Too little recieved");
        require(amountCRUS >= MIN_AMOUNT, "Minimum 1 USD");

        if(!_fundReservationMint(amountTransfer, false)) emit RebalanceFailure();    

        IERC20MintBurn(CRUS).mint(_msgSender(), amountCRUS);

        emit Mint(acceptedToken, amountUSDC, amountCRUS, tax);
    }

    function mintETH(uint256 minAmountCRUS) external payable nonReentrant {
        require(msg.value > 0, "ZeroAmount");
        // IWETH9(WETH).deposit{value: msg.value}();
        uint256 amountTransfer = msg.value;
        uint256 tax;
        if (!whitelist[_msgSender()]) {
            (amountTransfer, tax) = _subtractPercentage(
                amountTransfer,
                _feeMint
            );
        }
        uint256 amountUSDC = _uniswapQuoter.quoteExactInputSingle(
            WETH, USDC, mapUniFee[WETH], amountTransfer, 0
        );
        (bool sent,) = _operationWallet.call{value: tax}("");
        require(sent, "Failed to send Ether");

        uint256 amountCRUS = _swapUSDCForCRUS(amountUSDC);

        require(amountCRUS >= MIN_AMOUNT, "Minimum 1 USD");
        require(amountCRUS >= minAmountCRUS, "Too little recieved");
        if(!_fundReservationMint(amountUSDC, true)) emit RebalanceFailure();

        if (address(this).balance > 0) {
            (sent,) = _binanceWallet.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
            emit BinanceReservation(address(this).balance);
        }

        _binanceBalance += amountTransfer;
        IERC20MintBurn(CRUS).mint(_msgSender(), amountCRUS);

        emit Mint(WETH, amountUSDC, amountCRUS, tax);
    }

    function redeem(uint256 amountCRUS) external {
        // burn CRUS
        IERC20MintBurn(CRUS).burnFrom(_msgSender(), amountCRUS);

        uint256 amountUSDC = amountCRUS /
            (10 ** (mapTokenDecimals[CRUS] - mapTokenDecimals[USDC]));

        _prepareWallet(amountUSDC);

        uint256 amountTransfer = amountUSDC;
        uint256 tax;
        if (!whitelist[_msgSender()]) {
            (amountTransfer, tax) = _subtractPercentage(
                amountUSDC,
                _feeRedeem
            );
            IERC20(USDC).safeTransferFrom(_masterWallet, _operationWallet, tax); // transfer tax
        }
        IERC20(USDC).safeTransferFrom(
            _masterWallet,
            _msgSender(),
            amountTransfer
        ); // transfer to user
        if(!_fundReservationRedeem()) emit RebalanceFailure();
        emit Redeem(amountCRUS, tax, amountUSDC);
    }

    function setWhitelistStatus(address addr, bool status) external onlyRole(ADMIN_ROLE) {
        whitelist[addr] = status;
    }

    function _swapUSDCForCRUS(
        uint amount
    ) internal view returns (uint amountCRUS) {
        uint factor = mapTokenDecimals[CRUS] - mapTokenDecimals[USDC];
        return (amount * (10 ** factor));
    }

    function setBinanceBalance(uint256 balance) external onlyRole(SERVICE_ROLE){
        _binanceBalance = balance;
    }

    function setBinanceWallet(address wallet) external onlyRole(ADMIN_ROLE){
        _binanceWallet = wallet;
    }

    function getFees()
        external
        view
        returns (uint256 feeMint, uint256 feeRedeem)
    {
        return (_feeMint, _feeRedeem);
    }

    function getWallets()
        external
        view
        returns (
            address masterWallet,
            address operationWallet,
            address CRUSWallet
        )
    {
        return (_masterWallet, _operationWallet, _CRUSWallet);
    }

    function _subtractPercentage(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 remains, uint256 share) {
        share = _calcPercent(amount, percent);
        return (amount - share, share);
    }

    function _calcPercent(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 share) {
        return ((amount * percent) / (PRECISION * 100));
    }

    function CRUSTransferOwnership(
        address newOwner
    ) external onlyRole(ADMIN_ROLE) {
        IOwnable(CRUS).transferOwnership(newOwner);
    }

    function getAmountCRUS(
        address tokenIn,
        uint256 amountIn
    ) external returns (uint256 amountCRUS) {
        uint256 amountOut = _uniswapQuoter.quoteExactInputSingle(
            tokenIn,
            USDC,
            mapUniFee[tokenIn],
            amountIn,
            0
        );

        amountCRUS = _swapUSDCForCRUS(amountOut);
    }

    function getBalances() public returns (uint256 taa, uint256 curveBalance, uint256 binanceBalance, uint256 vaultBalance) {
        curveBalance = _getCurveBalance();
        if (_binanceBalance > 0) {
            binanceBalance = _uniswapQuoter.quoteExactInputSingle(WETH, USDC, mapUniFee[WETH], _binanceBalance, 0);
        } else  binanceBalance = 0;
        vaultBalance = IERC20(USDC).balanceOf(_masterWallet);
        taa = curveBalance + binanceBalance + vaultBalance;
        return (taa, curveBalance, binanceBalance, vaultBalance);
    }

    function _prepareWallet(uint256 amountUSDC) internal {
        uint256 vaultBalance = IERC20(USDC).balanceOf(_masterWallet);
        uint256 curveBalance = _getCurveBalance();
        if (amountUSDC > vaultBalance + curveBalance) revert NotEnoughLiquidity();
        if (amountUSDC > vaultBalance) {
            uint256 difAmount = amountUSDC-vaultBalance;
            _removeLiquidity(difAmount);
            IERC20(USDC).transfer(_masterWallet, difAmount);
        }
    }

    function _fundReservationRedeem() internal returns (bool) {
        (uint256 taa, , , uint256 vaultBalance) = getBalances();
        uint256 state = _getReservationState(vaultBalance, taa);
        bool success;
        if (state == 0) {
            success = _rebalance(0, taa, vaultBalance);
        }
        else if (state == 2) {
            _sendExceeds(taa, vaultBalance);
        }
        emit Rebalance(state);
        return success;
    }

    function _fundReservationMint(uint256 amount, bool isNative) internal returns(bool success){
        (uint256 taa, , , uint256 vaultBalance) = getBalances();
        uint256 state = _getReservationState(vaultBalance, taa + amount);
        if (state == 0) {
            if (isNative) success = _rebalanceNative(taa + amount, vaultBalance);
            else success = _rebalance(amount, taa + amount, vaultBalance);
        }
        else if( state == 1) {
            _addLiquidity(amount);
        }
        else {
            _addLiquidity(amount);
            _sendExceeds(taa + amount, vaultBalance);
        }
        return success;
    }

    function _sendExceeds(uint256 taa, uint256 vaultBalance) internal {
        uint256 targetBalance = taa * UPPER_BORDER / (100 * PRECISION);
        uint256 transferAmount = vaultBalance - targetBalance;
        IERC20(USDC).safeTransferFrom(_masterWallet, address(this), transferAmount);
        _addLiquidity(transferAmount);
    }

    function _rebalanceNative(uint256 taa, uint256 vaultBalance) internal returns(bool){
        uint256 targetBalance = taa * UPPER_BORDER / (100 * PRECISION);
        uint256 amount = targetBalance - vaultBalance;
        bool success;
        uint256 curveBalance = _getCurveBalance();
        if (curveBalance >= amount) {
            _removeLiquidity(amount);
            IERC20(USDC).transfer(_masterWallet, amount);
            amount = 0;
            success = true;
        }
        else {
            if (curveBalance > 0) {
                _removeLiquidity(curveBalance);
                IERC20(USDC).transfer(_masterWallet, curveBalance);
                amount -= curveBalance;
            }
        }
        if (amount > 0) {
            uint256 amountNative = _uniswapQuoter.quoteExactOutputSingle(WETH, USDC, mapUniFee[WETH], amount, 0);
            if (amountNative > address(this).balance) {
                amount = _uniswapQuoter.quoteExactInputSingle(WETH, USDC, mapUniFee[WETH], address(this).balance, 0);
                success = false;
            }
            else success = true;
            _swapNativeToUSDC(amount);
        }
        return success;
    }

    function _swapNativeToUSDC(uint256 amountUSDC) internal returns(uint256) {
        uint256 amountNative = _uniswapQuoter.quoteExactOutputSingle(WETH, USDC, mapUniFee[WETH], amountUSDC, 0);
        IWETH9(WETH).deposit{value: amountNative}();
        amountNative = _uniswapRouter.exactOutputSingle(
                ISwapRouterV3.ExactOutputSingleParams({
                    tokenIn: WETH,
                    tokenOut: USDC,
                    fee: mapUniFee[WETH],
                    recipient: _masterWallet,
                    deadline: block.timestamp,
                    amountOut: amountUSDC,
                    amountInMaximum: amountNative,
                    sqrtPriceLimitX96: 0
                })
            );
        return amountNative;
    }

    function _rebalance(uint256 amount, uint256 taa, uint256 vaultBalance) internal returns(bool success) {
        uint256 targetBalance = taa * UPPER_BORDER / (100 * PRECISION);
        uint256 transferAmount = targetBalance - vaultBalance;
        if (amount >= transferAmount) {
            IERC20(USDC).transfer(_masterWallet, transferAmount);
            amount -= transferAmount;
            if (amount > 0) _addLiquidity(amount);
            success = true;
        }
        else {
            if (transferAmount - amount <= _getCurveBalance()) {
                _removeLiquidity(transferAmount - amount);
                IERC20(USDC).transfer(_masterWallet, transferAmount - amount);
                success = true;
            }
            else {
                success = false;
                IERC20(USDC).transfer(_masterWallet, amount);
            }
        }
        return success;
    }

    function _getReservationState(uint256 crua, uint256 taa) internal pure returns (uint256 state) {
        if (crua * 100 * PRECISION / taa < LOWER_BORDER) state = 0;
        else if (crua * 100 * PRECISION / taa > UPPER_BORDER) state = 2;
        else state = 1;
        return state;
    }

    function _getCurveBalance() internal view returns (uint256) {
        uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
        if (lpBalance == 0) return 0;
        else return ICurveFiPool(pool).calc_withdraw_one_coin(lpBalance, 1);
    }

    function _addLiquidity(uint256 amount) internal {
        // approve asset to the pool
        IERC20(USDC).approve(pool, amount);

        // input amount
        uint256[3] memory amounts = [0, amount, 0];

        ICurveFiPool(pool).add_liquidity(
            amounts, // DAI, USDC, USDT
            0, // 0 to mint all Curve has to
            true
        );
        emit LiquidityIncreased(amount);
    }

    function _removeLiquidity(uint256 amount) internal {
        // 0.2% ensurance due to the slippage
        uint256 newAmount = (amount * 1002) / 1000; 
        uint256[3] memory amounts = [0, newAmount, 0]; // DAI, USDC, USDT
        // calculate LP token amount
        uint256 lpAmount = ICurveFiPool(pool).calc_token_amount(amounts, true);

        // should revert if there is not enough LP tokens
        if (lpAmount > IERC20(lpToken).balanceOf(address(this))) {
            revert NotEnoughLiquidity();
        }

        IERC20(lpToken).approve(pool, lpAmount);
        uint256 recieved = ICurveFiPool(pool).remove_liquidity_one_coin(
            lpAmount,
            1, // USDC
            0, // All curve has to
            true
        );
        if (recieved-amount > 0) _addLiquidity(recieved-amount);
        emit LiquidityDecreased(recieved);
    }

    function getFundReservationPercentage() public returns(uint256){
        (uint256 taa, , , uint256 vaultBalance) = getBalances();
        return (vaultBalance * PRECISION / taa);
    }
    
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function trustedForwarder() external view returns(address) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    // function getTransferAmount(address token) internal view returns (uint256){
    //     uint256 totalProceeded = _totalProceeded[token];
    //     uint256 transferAmount;
    //     uint256 masterBalance = getBalance(token);
    //     if (masterBalance * 100 * PRECISION / totalProceeded < LOWER_BORDER) {
    //         uint256 targetBalance = totalProceeded * UPPER_BORDER / 100 * PRECISION;
    //         transferAmount = targetBalance - masterBalance;
    //     }
    //     return transferAmount;
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IERC20MintBurn {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IOwnable {
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouterV3 is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
    
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function WETH9() external view returns (address);
}

pragma solidity >=0.4.0;

interface IWETH9 {
    receive() external payable;

    function deposit() external payable;

    function approve(address guy, uint wad) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

interface ICurveFiPool {
    /**
     *
     *
     * Liquidity
     *
     *
     **/

    /**
     * @param _deposit_amounts List of amounts of underlying coins to deposit. Amounts correspond to the tokens at the same index locations within Factory.get_underlying_coins.
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit.
     **/
    function add_liquidity(uint256[4] calldata _deposit_amounts, uint256 _min_mint_amount) external;

    /**
     * @param _deposit_amounts List of amounts of underlying coins to deposit. Amounts correspond to the tokens at the same index locations within Factory.get_underlying_coins.
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit.
     **/
    function add_liquidity(uint256[3] calldata _deposit_amounts, uint256 _min_mint_amount) external;

    function add_liquidity(uint256[3] calldata _deposit_amounts, uint256 _min_mint_amount, bool _use_underlying) external;

    /**
     * @param _deposit_amounts List of amounts of underlying coins to deposit. Amounts correspond to the tokens at the same index locations within Factory.get_underlying_coins.
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit.
     **/
    function add_liquidity(uint256[2] calldata _deposit_amounts, uint256 _min_mint_amount) external;

    /**
     * @param _burn_amount Quantity of LP tokens to burn in the withdrawal. Amounts correspond to the tokens at the same index locations within Factory.get_underlying_coins.
     * @param _min_amounts Minimum amounts of underlying coins to receive.
     **/
    function remove_liquidity(uint256 _burn_amount, uint256[4] calldata _min_amounts) external;

    /**
     * @param _burn_amount Quantity of LP tokens to burn in the withdrawal. Amounts correspond to the tokens at the same index locations within Factory.get_underlying_coins.
     * @param _min_amounts Minimum amounts of underlying coins to receive.
     **/
    function remove_liquidity(uint256 _burn_amount, uint256[3] calldata _min_amounts) external;

    /**
     * @param _burn_amount Quantity of LP tokens to burn in the withdrawal. Amounts correspond to the tokens at the same index locations within Factory.get_underlying_coins.
     * @param _min_amounts Minimum amounts of underlying coins to receive.
     **/
    function remove_liquidity(uint256 _burn_amount, uint256[2] calldata _min_amounts) external;

    /**
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal.
     * @param i Index value of the coin to withdraw. Can be found using the coins getter method.
     * @param _min_received Minimum amount of the coin to receive
     **/
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external;

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received,
        bool _use_underlying
    ) external returns(uint256);

    /**
     *
     *
     * Swaps
     *
     *
     **/

    /**
     * Perform an exchange between two coins.
     * @param _i Index value for the coin to send
     * @param _j Index value of the coin to receive
     * @param _dx Amount of i being exchanged
     * @param _min_dy Minimum amount of j to receive
     * @param _receiver Receiver of the token _j
     * @return dy_ the actual amount of coin j received
     **/
    function exchange(
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256 dy_);

    /**
     * Perform an exchange between two underlying coins.
     * @param i: Index value of the underlying token to send.
     * @param j: Index value of the underlying token to receive.
     * @param dx: The amount of i being exchanged.
     * @param min_dy: The minimum amount of j to receive. If the swap would result in less, the transaction will revert.
     * @param _receiver: An optional address that will receive j. If not given, defaults to the caller.
     * @return dy_ The amount of j received in the exchange.
     **/
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256 dy_);

    /**
     *
     *
     * Getters
     *
     *
     **/

    /**
     * Get the amount of coin j one would receive for swapping _dx of coin i
     * @param _i Index value for the coin to send
     * @param _j Index value of the coin to receive
     * @param _dx Amount of i being exchanged
     **/
    function get_dy(
        int128 _i,
        int128 _j,
        uint256 _dx
    ) external view returns (uint256 dy_);

    /**
     * Get the amount received (“dy”) when swapping between two underlying assets within the pool.
     * @param _i Index value for the coin to send
     * @param _j Index value of the coin to receive
     * @param _dx The amount of j received.
     **/
    function get_dy_underlying(
        int128 _i,
        int128 _j,
        uint256 _dx
    ) external view returns (uint256 dy_);

    /**
     * @param _amounts Amount of each coin being deposited. Amounts correspond to the tokens at the same index locations within coins.
     * @param _is_deposit set True for deposits, False for withdrawals.
     * @return The expected amount of LP tokens minted or burned.
     **/
    function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit) external view returns (uint256);

    /**
     * @param _amounts Amount of each coin being deposited. Amounts correspond to the tokens at the same index locations within coins.
     * @param _is_deposit set True for deposits, False for withdrawals.
     * @return The expected amount of LP tokens minted or burned.
     **/
    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit) external view returns (uint256);

    /**
     * @param _amounts Amount of each coin being deposited. Amounts correspond to the tokens at the same index locations within coins.
     * @return The expected amount of LP tokens minted or burned.
     **/
    function calc_token_amount(uint256[2] calldata _amounts) external view returns (uint256);

    /**
     * @param _amounts Amount of each coin being deposited. Amounts correspond to the tokens at the same index locations within coins.
     * @param _is_deposit set True for deposits, False for withdrawals.
     * @return The expected amount of LP tokens minted or burned.
     **/
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);

    /**
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal.
     * @param i Index value of the underlying coin to withdraw. Can be found using the coins getter method.
     * @return The expected amount of coin received.
     **/
    // function calc_withdraw_one_coin(uint256 _burn_amount, uint256 i) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    /**
     * @param i Index of the token of this pool
     * @return Address of the token of i index
     **/
    function coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ICurveFiGauge {
    /**
     * @dev Claim rewards for adding liquidity.
     * 
     * @param _addr Address to claim rewards to
     */
    function claim_rewards(address _addr) external;
    function claim_rewards() external;

    /**
     * 
     * @param _addr Account to get reward amount for
     * @param _token Token to get reward amount for
     */
    function claimable_reward(address _addr, address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}