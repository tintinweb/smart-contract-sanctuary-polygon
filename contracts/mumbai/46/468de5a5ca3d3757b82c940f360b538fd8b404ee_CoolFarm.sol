/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// SPDX-License-Identifier: MIT
// Developed by https://t.me/LinksUltima
pragma solidity ^0.8.17;

abstract contract Ownable {
    error NotOwner();

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

library RevertReasonForwarder {
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

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

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    // If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance)
            revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        bool success;
        if (permit.length == 32 * 7) {
            success = _makeCalldataCall(
                token,
                IERC20Permit.permit.selector,
                permit
            );
        } else if (permit.length == 32 * 8) {
            success = _makeCalldataCall(
                token,
                IDaiLikePermit.permit.selector,
                permit
            );
        } else {
            revert SafePermitBadLength();
        }
        if (!success) RevertReasonForwarder.reRevert();
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function _makeCalldataCall(
        IERC20 token,
        bytes4 selector,
        bytes calldata args
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

interface iFarm {
    function getTotalMiners()
        external
        view
        returns (uint256 _USD, uint256 _eth);

    function getUserMiners(address account)
        external
        view
        returns (uint256 _USD, uint256 _eth);

    function getUserCoins(address account)
        external
        view
        returns (uint256 _USD, uint256 _eth);

    function getUserCollect(address account)
        external
        view
        returns (uint256 _USD, uint256 _eth);

    function getRates() external view returns (uint256 _USD, uint256 _eth);

    function buyMiners(
        address ref,
        uint256 amountUSD,
        bool diversification
    ) external payable;

    function sellCoins() external;

    function reinvestCoins() external;

    event BuyMiners_USD(uint256 amountUSD, address indexed account);
    event BuyMiners_ETH(uint256 amountETH, address indexed account);
    event CollectCoins(
        address indexed account,
        uint256 coins_USD,
        uint256 coins_ETH
    );
    event SellCoins(
        address indexed account,
        uint256 amountUSD,
        uint256 amountEth
    );
    event ReinvestCoins(
        address indexed account,
        uint256 amountUSD,
        uint256 amountEth
    );
}

contract CoolFarm is Ownable, iFarm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public devFeeVal = 3;
    uint256 public buybackFee = 2;
    uint256 public liquidityFee = 2;
    uint256 public marketFee = 3;
    uint256[8] private refFee_buy = [4, 3, 2, 1, 0, 0, 0, 0];
    uint256[8] private refFee_sell = [0, 0, 0, 0, 4, 3, 2, 1];

    uint256 public constant dayPercent = 50; // 0,5%
    uint256 public xLimit = 300;

    address public immutable WETH;
    address public immutable USD;
    address public immutable Token;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable liquidityAddress;
    address public immutable buybackAddress;

    uint256 public tokensToParticipate;
    uint256 public tokensToGetRefs;

    uint256 public maximumSecondsWithoutUpdate = 7 * 24 * 60 * 60; // 7 days

    uint256 private constant HUNDRED = 100;
    uint256 private constant VALUES_FACTOR = 10000;
    uint256 private constant _DECIMALFACTOR = 1e18;
    uint256 private constant _1DAY = 86400;

    uint256 private totalMiners_USD;
    mapping(address => uint256) private miners_USD;
    mapping(address => uint256) private coins_USD;
    mapping(address => uint256) private collect_USD;
    mapping(address => uint256) private collectFromLastBurn_USD;

    uint256 private totalMiners_ETH;
    mapping(address => uint256) private miners_ETH;
    mapping(address => uint256) private coins_ETH;
    mapping(address => uint256) private collect_ETH;
    mapping(address => uint256) private collectFromLastBurn_ETH;

    mapping(address => uint256) public lastChange;
    mapping(address => address[8]) private referrals;

    mapping(address => uint256) private totalRefUSDBuys;
    mapping(address => uint256) private totalRefEthBuys;
    mapping(address => uint256) private totalRefUSDCollect;
    mapping(address => uint256) private totalRefEthCollect;

    modifier onlyTokenHolder() {
        require(
            IERC20(Token).balanceOf(msg.sender) >= tokensToParticipate,
            "Buy more Tokens"
        );
        _;
    }

    constructor(
        address _token,
        address _USD,
        address _liq,
        address _bb,
        address _owner,
        IUniswapV2Router02 _uniswapV2Router
    ) payable {
        transferOwnership(_owner);
        Token = _token;
        USD = _USD;
        liquidityAddress = _liq;
        buybackAddress = _bb;
        uniswapV2Router = _uniswapV2Router;
        WETH = uniswapV2Router.WETH();
    }

    receive() external payable {
        require(
            IERC20(Token).balanceOf(msg.sender) >= tokensToParticipate,
            "Buy more Tokens"
        );
        collectCoins();

        uint256 amountETH = msg.value;
        require(amountETH > 0, "Send more ETH!");

        address ref = address(0);
        setAllRefs(msg.sender, ref);

        uint256 halfAmountETH = half(amountETH);

        IWETH9(WETH).deposit{value: halfAmountETH}();
        uint256 amountUSD = swapTokens(WETH, USD, halfAmountETH);

        buyMiners_ETH(halfAmountETH, msg.sender);
        emit BuyMiners_ETH(amountETH, ref);

        buyMiners_USD(amountUSD, msg.sender);
        emit BuyMiners_USD(amountUSD, ref);
    }

    function getRefFee(bool buy) external view returns (uint256[8] memory) {
        if (buy) {
            return refFee_buy;
        } else {
            return refFee_sell;
        }
    }

    function getRefStat(address account)
        external
        view
        returns (
            uint256 totalUSDBuys,
            uint256 totalEthBuys,
            uint256 _USD,
            uint256 _eth
        )
    {
        return (
            totalRefUSDBuys[account],
            totalRefEthBuys[account],
            totalRefUSDCollect[account],
            totalRefEthCollect[account]
        );
    }

    function getUserRefInfo(address account)
        external
        view
        returns (address[8] memory)
    {
        return referrals[account];
    }

    function getTotalMiners()
        external
        view
        returns (uint256 _USD, uint256 _eth)
    {
        return (totalMiners_USD, totalMiners_ETH);
    }

    function getUserCollectFromLastBurn(address account)
        external
        view
        returns (uint256 _USD, uint256 _eth)
    {
        return (
            collectFromLastBurn_USD[account],
            collectFromLastBurn_ETH[account]
        );
    }

    function getUserMiners(address account)
        external
        view
        returns (uint256 _USD, uint256 _eth)
    {
        return (miners_USD[account], miners_ETH[account]);
    }

    function getRates() external view returns (uint256 _USD, uint256 _eth) {
        return (getRate_USD(), getRate_ETH());
    }

    function getUserCoins(address account)
        external
        view
        returns (uint256 _USD, uint256 _eth)
    {
        return (coins_USD[account], coins_ETH[account]);
    }

    function getUserCollect(address account)
        external
        view
        returns (uint256 _USD, uint256 _eth)
    {
        return (collect_USD[account], collect_ETH[account]);
    }

    function getCanBurnMiners(address account)
        public
        view
        returns (bool _USD, bool _eth)
    {
        if (miners_USD[account] > 0) {
            if (
                collectFromLastBurn_USD[account] >=
                miners_USD[account].mul(xLimit).div(HUNDRED)
            ) {
                _USD = true;
            }
        }

        if (miners_ETH[account] > 0) {
            if (
                collectFromLastBurn_ETH[account] >=
                miners_ETH[account].mul(xLimit).div(HUNDRED)
            ) {
                _eth = true;
            }
        }
    }

    function setAllRefs(address account, address newRef) private {
        if (newRef == account) {
            newRef = address(this);
        }
        if (referrals[account][0] == address(0)) {
            referrals[account][0] = newRef;
        }
        if (
            referrals[account][1] == address(0) &&
            referrals[newRef][0] != account
        ) {
            referrals[account][1] = referrals[newRef][0];
        }
        if (
            referrals[account][2] == address(0) &&
            referrals[newRef][1] != account
        ) {
            referrals[account][2] = referrals[newRef][1];
        }
        if (
            referrals[account][3] == address(0) &&
            referrals[newRef][2] != account
        ) {
            referrals[account][3] = referrals[newRef][2];
        }
        if (
            referrals[account][4] == address(0) &&
            referrals[newRef][3] != account
        ) {
            referrals[account][4] = referrals[newRef][3];
        }
        if (
            referrals[account][5] == address(0) &&
            referrals[newRef][4] != account
        ) {
            referrals[account][5] = referrals[newRef][4];
        }
        if (
            referrals[account][6] == address(0) &&
            referrals[newRef][5] != account
        ) {
            referrals[account][6] = referrals[newRef][5];
        }
        if (
            referrals[account][7] == address(0) &&
            referrals[newRef][6] != account
        ) {
            referrals[account][7] = referrals[newRef][6];
        }
    }

    function getTotalRefPercent(bool buy) private view returns (uint256) {
        if (buy) {
            return (
                refFee_buy[0]
                    .add(refFee_buy[1])
                    .add(refFee_buy[2])
                    .add(refFee_buy[3])
                    .add(refFee_buy[4])
                    .add(refFee_buy[5])
                    .add(refFee_buy[6])
                    .add(refFee_buy[7])
            );
        }
        return (
            refFee_sell[0]
                .add(refFee_sell[1])
                .add(refFee_sell[2])
                .add(refFee_sell[3])
                .add(refFee_sell[4])
                .add(refFee_sell[5])
                .add(refFee_sell[6])
                .add(refFee_sell[7])
        );
    }

    function getValues(uint256 amount, bool buy)
        private
        view
        returns (
            uint256 devAmount,
            uint256 buybackAmount,
            uint256 liqAmount,
            uint256 marketAmount,
            uint256 refAmount,
            uint256 userAmount
        )
    {
        devAmount = amount.mul(devFeeVal * HUNDRED).div(VALUES_FACTOR);
        buybackAmount = amount.mul(buybackFee * HUNDRED).div(VALUES_FACTOR);
        liqAmount = amount.mul(liquidityFee * HUNDRED).div(VALUES_FACTOR);
        marketAmount = amount.mul(marketFee * HUNDRED).div(VALUES_FACTOR);
        refAmount = amount.mul(getTotalRefPercent(buy) * HUNDRED).div(
            VALUES_FACTOR
        );
        userAmount = getUserAmount(
            amount,
            devAmount,
            buybackAmount,
            liqAmount,
            marketAmount,
            refAmount
        );
    }

    function getUserAmount(
        uint256 amount,
        uint256 devAmount,
        uint256 buybackAmount,
        uint256 liqAmount,
        uint256 marketAmount,
        uint256 refAmount
    ) private pure returns (uint256) {
        uint256 fees = devAmount
            .add(buybackAmount)
            .add(liqAmount)
            .add(marketAmount)
            .add(refAmount);
        return amount.sub(fees);
    }

    function buyMiners(
        address ref,
        uint256 amountUSD,
        bool diversification
    ) external payable onlyTokenHolder {
        collectCoins();

        uint256 amountETH = msg.value;
        require(amountETH.add(amountUSD) > 0, "Send more USD or ETH");

        setAllRefs(msg.sender, ref);

        uint256 addUSD;

        if (amountETH > 0) {
            if (diversification) {
                IWETH9(WETH).deposit{value: half(amountETH)}();
                addUSD = swapTokens(WETH, USD, half(amountETH));
                buyMiners_ETH(half(amountETH), msg.sender);
            } else {
                buyMiners_ETH(amountETH, msg.sender);
            }
        }

        if (amountUSD.add(addUSD) > 0) {
            if (amountUSD > 0) {
                IERC20(USD).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amountUSD
                );
            }
            buyMiners_USD(amountUSD.add(addUSD), msg.sender);
        }
    }

    function buyMiners_ETH(uint256 amountETH, address account) private {
        (
            uint256 devAmount,
            uint256 buybackAmount,
            uint256 liqAmount,
            ,
            ,
            /*uint256 marketAmount*/
            /*uint256 refAmount*/
            uint256 userAmount
        ) = getValues(amountETH, true);

        safeTransferETH(owner(), devAmount);
        safeTransferETH(buybackAddress, buybackAmount);
        safeTransferETH(liquidityAddress, liqAmount);
        /*
        @dev: The sender and the recipient are the same
        safeTransferETH(address(this), marketAmount);
        */
        sendEthToRefs(amountETH, true, account);

        miners_ETH[account] = miners_ETH[account].add(userAmount);
        totalMiners_ETH = totalMiners_ETH.add(userAmount);

        emit BuyMiners_ETH(amountETH, account);
    }

    function buyMiners_USD(uint256 amountUSD, address account) private {
        (
            uint256 devAmount,
            uint256 buybackAmount,
            uint256 liqAmount,
            ,
            ,
            /*uint256 marketAmount*/
            /*uint256 refAmount*/
            uint256 userAmount
        ) = getValues(amountUSD, true);

        IERC20(USD).safeTransfer(owner(), devAmount);
        IERC20(USD).safeTransfer(buybackAddress, buybackAmount);
        IERC20(USD).safeTransfer(liquidityAddress, liqAmount);
        /*
        @dev: The sender and the recipient are the same
        IERC20(USD).safeTransfer(address(this), marketAmount);
        */
        sendUsdToRefs(amountUSD, true, account);

        miners_USD[account] = miners_USD[account].add(userAmount);
        totalMiners_USD = totalMiners_USD.add(userAmount);

        emit BuyMiners_USD(amountUSD, account);
    }

    function collectCoins() public onlyTokenHolder {
        (uint256 _coins_USD, uint256 _coins_ETH) = getCoinsFromLastCollect(
            msg.sender
        );

        lastChange[msg.sender] = block.timestamp;
        coins_USD[msg.sender] = coins_USD[msg.sender].add(_coins_USD);
        coins_ETH[msg.sender] = coins_ETH[msg.sender].add(_coins_ETH);

        emit CollectCoins(msg.sender, _coins_USD, _coins_ETH);
    }

    function sellCoins() public onlyTokenHolder {
        collectCoins();

        (uint256 amountUSD, ) = getAmountForCoins_USD(coins_USD[msg.sender]);
        (uint256 amountEth, ) = getAmountForCoins_ETH(coins_ETH[msg.sender]);

        require(amountUSD.add(amountEth) > 0, "Please wait!");

        if (amountUSD > 0) {
            coins_USD[msg.sender] = 0;
            (
                uint256 devAmount,
                uint256 buybackAmount,
                uint256 liqAmount,
                ,
                ,
                uint256 userAmount
            ) = getValues(amountUSD, false);

            collect_USD[msg.sender] = collect_USD[msg.sender].add(userAmount);

            collectFromLastBurn_USD[msg.sender] = collectFromLastBurn_USD[
                msg.sender
            ].add(userAmount);

            IERC20(USD).safeTransfer(owner(), devAmount);
            IERC20(USD).safeTransfer(buybackAddress, buybackAmount);
            IERC20(USD).safeTransfer(liquidityAddress, liqAmount);
            sendUsdToRefs(amountUSD, false, msg.sender);
            IERC20(USD).safeTransfer(msg.sender, userAmount);
        }

        if (amountEth > 0) {
            coins_ETH[msg.sender] = 0;
            (
                uint256 devAmount,
                uint256 buybackAmount,
                uint256 liqAmount,
                ,
                ,
                uint256 userAmount
            ) = getValues(amountEth, false);

            collect_ETH[msg.sender] = collect_ETH[msg.sender].add(userAmount);

            collectFromLastBurn_ETH[msg.sender] = collectFromLastBurn_ETH[
                msg.sender
            ].add(userAmount);

            safeTransferETH(owner(), devAmount);
            safeTransferETH(buybackAddress, buybackAmount);
            safeTransferETH(liquidityAddress, liqAmount);
            sendEthToRefs(amountEth, false, msg.sender);
            safeTransferETH(msg.sender, userAmount);
        }

        checkBurnMiners(msg.sender);
        emit SellCoins(msg.sender, amountUSD, amountEth);
    }

    function reinvestCoins() external onlyTokenHolder {
        collectCoins();

        (uint256 amountUSD, ) = getAmountForCoins_USD(coins_USD[msg.sender]);
        (uint256 amountEth, ) = getAmountForCoins_ETH(coins_ETH[msg.sender]);

        require(amountUSD.add(amountEth) > 0, "Please wait!");

        if (amountUSD > 0) {
            coins_USD[msg.sender] = 0;
            collect_USD[msg.sender] = collect_USD[msg.sender].add(amountUSD);
            collectFromLastBurn_USD[msg.sender] = collectFromLastBurn_USD[
                msg.sender
            ].add(amountUSD);
            totalMiners_USD = totalMiners_USD.add(amountUSD);
            miners_USD[msg.sender] = miners_USD[msg.sender].add(amountUSD);
        }

        if (amountEth > 0) {
            coins_ETH[msg.sender] = 0;
            collect_ETH[msg.sender] = collect_ETH[msg.sender].add(amountEth);
            collectFromLastBurn_ETH[msg.sender] = collectFromLastBurn_ETH[
                msg.sender
            ].add(amountEth);
            totalMiners_ETH = totalMiners_ETH.add(amountEth);
            miners_ETH[msg.sender] = miners_ETH[msg.sender].add(amountEth);
        }

        emit ReinvestCoins(msg.sender, amountUSD, amountEth);
    }

    function burnMyMiners() external {
        collectCoins();
        sellCoins();

        totalMiners_USD = totalMiners_USD.sub(miners_USD[msg.sender]);
        miners_USD[msg.sender] = 0;
        collectFromLastBurn_USD[msg.sender] = 0;

        totalMiners_ETH = totalMiners_ETH.sub(miners_ETH[msg.sender]);
        miners_ETH[msg.sender] = 0;
        collectFromLastBurn_ETH[msg.sender] = 0;
    }

    function getRefAmount(
        uint256 amount,
        uint8 ref,
        bool buy
    ) private view returns (uint256 refAmount) {
        if (buy) {
            return amount.mul(refFee_buy[ref] * HUNDRED).div(VALUES_FACTOR);
        } else {
            return amount.mul(refFee_sell[ref] * HUNDRED).div(VALUES_FACTOR);
        }
    }

    function canGetRefs(address account) private view returns (bool) {
        return IERC20(Token).balanceOf(account) >= tokensToGetRefs;
    }

    function sendEthToRefs(
        uint256 amount,
        bool buy,
        address account
    ) private {
        for (uint8 i; i < referrals[account].length; i++) {
            if (referrals[account][i] != address(0)) {
                uint256 tAmount = getRefAmount(amount, i, buy);
                if (tAmount > 0) {
                    if (canGetRefs(referrals[account][i])) {
                        updateRefInfo(
                            referrals[account][i],
                            tAmount,
                            true,
                            buy
                        );
                        if (referrals[account][i] != address(this)) {
                            safeTransferETH(referrals[account][i], tAmount);
                        }
                    }
                }
            }
        }
    }

    function sendUsdToRefs(
        uint256 amount,
        bool buy,
        address account
    ) private {
        for (uint8 i; i < referrals[account].length; i++) {
            if (referrals[account][i] != address(0)) {
                uint256 tAmount = getRefAmount(amount, i, buy);
                if (tAmount > 0) {
                    if (canGetRefs(referrals[account][i])) {
                        updateRefInfo(
                            referrals[account][i],
                            tAmount,
                            false,
                            buy
                        );
                        if (referrals[account][i] != address(this)) {
                            IERC20(USD).safeTransfer(
                                referrals[account][i],
                                tAmount
                            );
                        }
                    }
                }
            }
        }
    }

    function getCoinsFromLastCollect(address account)
        public
        view
        returns (uint256 _USD, uint256 _eth)
    {
        uint256 _seconds = getSeconds(account);
        _USD = (
            _seconds.mul(
                (miners_USD[account]).mul(dayPercent).div(VALUES_FACTOR)
            )
        ).div(_1DAY);
        _eth = (
            _seconds.mul(
                (miners_ETH[account]).mul(dayPercent).div(VALUES_FACTOR)
            )
        ).div(_1DAY);
    }

    function getSeconds(address account) public view returns (uint256) {
        if (lastChange[account] == 0) {
            return 0;
        }
        return
            min(
                maximumSecondsWithoutUpdate,
                block.timestamp.sub(lastChange[account])
            );
    }

    function getAmountForCoins_USD(uint256 amountCoins)
        public
        view
        returns (uint256, uint256)
    {
        uint256 slippage = amountCoins.mul(getRate_USD()).div(_DECIMALFACTOR);
        uint256 amountUSD = amountCoins
            .mul(getRateWithSlippage_USD(slippage))
            .div(_DECIMALFACTOR);
        return (amountUSD, slippage.sub(amountUSD));
    }

    function getRate_USD() private view returns (uint256) {
        uint256 rate = IERC20(USD)
            .balanceOf(address(this))
            .mul(_DECIMALFACTOR)
            .div(totalMiners_USD);
        return (rate);
    }

    function getRateWithSlippage_USD(uint256 slippage)
        private
        view
        returns (uint256)
    {
        uint256 rate = (IERC20(USD).balanceOf(address(this)).sub(slippage))
            .mul(_DECIMALFACTOR)
            .div(totalMiners_USD);
        return (rate);
    }

    function getAmountForCoins_ETH(uint256 amountCoins)
        public
        view
        returns (uint256, uint256)
    {
        uint256 slippage = amountCoins.mul(getRate_ETH()).div(_DECIMALFACTOR);
        uint256 amountEth = amountCoins
            .mul(getRateWithSlippage_ETH(slippage))
            .div(_DECIMALFACTOR);
        return (amountEth, slippage.sub(amountEth));
    }

    function getRate_ETH() private view returns (uint256) {
        uint256 rate = address(this).balance.mul(_DECIMALFACTOR).div(
            totalMiners_ETH
        );
        return (rate);
    }

    function getRateWithSlippage_ETH(uint256 slippage)
        private
        view
        returns (uint256)
    {
        uint256 rate = (address(this).balance.sub(slippage))
            .mul(_DECIMALFACTOR)
            .div(totalMiners_ETH);
        return (rate);
    }

    function updateRefInfo(
        address account,
        uint256 amount,
        bool isEth,
        bool buy
    ) private {
        if (isEth) {
            if (buy) {
                totalRefEthBuys[account]++;
            }
            totalRefEthCollect[account] = totalRefEthCollect[account].add(
                amount
            );
        } else {
            if (buy) {
                totalRefUSDBuys[account]++;
            }
            totalRefUSDCollect[account] = totalRefUSDCollect[account].add(
                amount
            );
        }
    }

    function checkBurnMiners(address account) private {
        (bool burn_USD, bool burn_ETH) = getCanBurnMiners(account);
        if (burn_USD) {
            miners_USD[account] = 0;
            collectFromLastBurn_USD[account] = 0;
        }
        if (burn_ETH) {
            miners_ETH[account] = 0;
            collectFromLastBurn_ETH[account] = 0;
        }
    }

    function half(uint256 amount) private pure returns (uint256) {
        return (amount * 5000) / 10000;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    function swapTokens(
        address token0,
        address token1,
        uint256 amount
    ) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        IERC20(token0).approve(address(uniswapV2Router), amount);

        uint256 balanceBefore = IERC20(token1).balanceOf(address(this));

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            address(this),
            block.timestamp
        );

        return IERC20(token1).balanceOf(address(this)).sub(balanceBefore);
    }

    function updateTokensToParticipateAndRefs(
        uint256 newAmountToParticipate,
        uint256 newTokensToGetRefs
    ) external onlyOwner {
        if (tokensToParticipate > 1) revert();
        tokensToParticipate = newAmountToParticipate;
        tokensToGetRefs = newTokensToGetRefs;
    }

    function updateMaximumSecondsWithoutUpdate(uint256 newAmount)
        external
        onlyOwner
    {
        if (newAmount < 3600) revert();
        maximumSecondsWithoutUpdate = newAmount;
    }

    function updateXLimit(uint256 newAmount) external onlyOwner {
        if (newAmount < 200) revert();
        xLimit = newAmount;
    }

    function updateFees(
        uint256 _devFeeVal,
        uint256 _buybackFee,
        uint256 _liquidityFee,
        uint256 _marketFee
    ) external onlyOwner {
        if (_devFeeVal.add(_buybackFee).add(_liquidityFee).add(_marketFee) > 50)
            revert();
        devFeeVal = _devFeeVal;
        buybackFee = _buybackFee;
        liquidityFee = _liquidityFee;
        marketFee = _marketFee;
    }

    function updateRefFees(
        uint256[8] memory newFees_buy,
        uint256[8] memory newFees_sell
    ) external onlyOwner {
        if (
            (newFees_buy[0] +
                (newFees_buy[1]) +
                (newFees_buy[2]) +
                (newFees_buy[3]) +
                (newFees_buy[4]) +
                (newFees_buy[5]) +
                (newFees_buy[6]) +
                (newFees_buy[7]) >
                20) ||
            (newFees_sell[0] +
                (newFees_sell[1]) +
                (newFees_sell[2]) +
                (newFees_sell[3]) +
                (newFees_sell[4]) +
                (newFees_sell[5]) +
                (newFees_sell[6]) +
                (newFees_sell[7]) >
                20)
        ) revert();

        refFee_buy = newFees_buy;
        refFee_sell = newFees_sell;
    }
}