pragma solidity >=0.8.0 <0.9.0;
//Copyright of DataX Protocol contributors
//SPDX-License-Identifier: BSU-1.1

import "../../interfaces/defi/IAdapter.sol";
import "../../interfaces/ocean/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../interfaces/defi/IStorage.sol";
import "../utils/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakeRouter is ReentrancyGuard, Math {
    using SafeMath for uint256;
    IStorage store;
    uint8 public version;
    mapping(address => mapping(address => uint256)) public referralFees;
    string constant STAKE_FEE_TYPE = "STAKE";
    string constant UNSTAKE_FEE_TYPE = "UNSTAKE";

    event StakedETHInPool(
        address indexed pool,
        address indexed beneficiary,
        address referrer,
        uint256 amountInETH,
        uint256 amountInBasetoken
    );

    event StakedTokenInPool(
        address indexed pool,
        address indexed token,
        address indexed beneficiary,
        address referrer,
        uint256 amountInToken,
        uint256 amountInBasetoken
    );

    event UnstakedETHFromPool(
        address indexed pool,
        address indexed beneficiary,
        address referrer,
        uint256 amountInETH,
        uint256 amountInBasetoken
    );

    event UnstakedTokenFromPool(
        address indexed pool,
        address indexed token,
        address indexed beneficiary,
        address referrer,
        uint256 amountInToken,
        uint256 amountInBasetoken
    );

    event ReferralFeesClaimed(
        address indexed referrer,
        address indexed token,
        uint256 claimedAmout
    );

    struct StakeInfo {
        address[4] meta; //[pool, to, refAddress, adapterAddress]
        uint256[3] uints; //[amountIn/maxAmountIn, refFees, amountOut/minAmountOut]
        address[] path;
    }

    constructor(uint8 _version, address _storage) {
        version = _version;
        store = IStorage(_storage);
    }

    function stakeETHInDTPool(StakeInfo calldata info)
        external
        payable
        nonReentrant
        returns (uint256 poolTokensOut)
    {
        require(
            info.meta[2] != address(0),
            "StakeRouter: Destination address not provided"
        );

        require(info.path.length > 1, "StakeRouter: Path too short");

        //TODO: deduct trade fee + ref fee
        IAdapter adapter = IAdapter(info.meta[3]);
        IERC20 baseToken = IERC20(info.path[info.path.length - 1]);

        //handle Pool swap
        IPool pool = IPool(info.meta[0]);

        //swap ETH to base token
        uint256[] memory amounts = adapter.getAmountsOut(msg.value, info.path);
        uint256 baseAmountOutSansFee = adapter.swapExactETHForTokens{
            value: msg.value
        }(amounts[info.path.length - 1], info.path, address(this));

        //deduct fees
        (uint256 dataxFee, uint256 refFee) = calcFees(
            baseAmountOutSansFee,
            STAKE_FEE_TYPE,
            info.uints[1]
        );
        //collect ref Fees
        if (info.meta[2] != address(0)) {
            referralFees[info.meta[2]][address(baseToken)] = referralFees[
                info.meta[2]
            ][address(baseToken)].add(refFee);
        }

        // actual base amount minus fees
        uint256 baseAmountOut = bsub(
            baseAmountOutSansFee,
            badd(dataxFee, refFee)
        );
        //approve Pool to spend base token
        require(
            baseToken.approve(address(pool), baseAmountOut),
            "StakeRouter: Failed to approve Basetoken on Pool"
        );

        //stake tokens in Pool
        poolTokensOut = pool.joinswapExternAmountIn(
            baseAmountOut,
            info.uints[2]
        );

        //transfer pool tokens to destination address
        require(
            IERC20(info.meta[0]).transfer(info.meta[1], poolTokensOut),
            "StakeRouter: Pool Token transfer failed"
        );

        emit StakedETHInPool(
            info.meta[0],
            info.meta[1],
            info.meta[2],
            msg.value,
            baseAmountOut
        );
    }

    function unstakeETHFromDTPool(StakeInfo calldata info)
        external
        nonReentrant
        returns (uint256 ethAmountOut)
    {
        require(
            info.meta[2] != address(0),
            "StakeRouter: Destination address not provided"
        );

        require(
            info.uints[0] <=
                IERC20(info.meta[0]).allowance(msg.sender, address(this)),
            "StakeRouter: Not enough token allowance"
        );

        require(info.path.length > 1, "StakeRouter: Path too short");

        IERC20 baseToken = IERC20(info.path[0]);
        //unstake into baseToken
        IPool pool = IPool(info.meta[0]);
        IERC20(info.meta[0]).transferFrom(
            msg.sender,
            address(this),
            info.uints[0]
        );
        IERC20(info.meta[0]).approve(address(pool), info.uints[0]);

        //unstake baseToken from Pool
        uint256 baseAmountOutSansFee = pool.exitswapPoolAmountIn(
            info.uints[0],
            info.uints[2]
        );

        //deduct fees
        (uint256 dataxFee, uint256 refFee) = calcFees(
            baseAmountOutSansFee,
            UNSTAKE_FEE_TYPE,
            info.uints[1]
        );
        //collect ref Fees
        if (info.meta[2] != address(0)) {
            referralFees[info.meta[2]][address(baseToken)] = referralFees[
                info.meta[2]
            ][address(baseToken)].add(refFee);
        }
        // actual base amount minus fees
        uint256 baseAmountOut = bsub(
            baseAmountOutSansFee,
            badd(dataxFee, refFee)
        );

        baseToken.approve(info.meta[3], baseAmountOut);

        //swap to output token
        IAdapter adapter = IAdapter(info.meta[3]);
        //swap basetoken to ETH
        uint256[] memory amounts = adapter.getAmountsOut(
            baseAmountOut,
            info.path
        );
        ethAmountOut = adapter.swapExactTokensForETH(
            baseAmountOut,
            amounts[info.path.length - 1],
            info.path,
            info.meta[1]
        );

        emit UnstakedETHFromPool(
            info.meta[0],
            info.meta[1],
            info.meta[2],
            ethAmountOut,
            baseAmountOut
        );
    }

    function stakeTokenInDTPool(StakeInfo calldata info)
        external
        nonReentrant
        returns (uint256 poolTokensOut)
    {
        require(
            info.meta[2] != address(0),
            "StakeRouter: Destination address not provided"
        );

        require(
            info.uints[0] <=
                IERC20(info.path[0]).allowance(msg.sender, address(this)),
            "StakeRouter: Not enough token allowance"
        );

        IERC20 baseToken = IERC20(info.path[info.path.length - 1]);
        uint256 baseAmountOutSansFee = info.uints[0];

        require(
            IERC20(info.path[0]).balanceOf(msg.sender) >= info.uints[0],
            "StakeRouter: Not enough tokenIn balance"
        );
        IERC20(info.path[0]).transferFrom(
            msg.sender,
            address(this),
            info.uints[0]
        );

        //skip if tokenIn is baseToken
        if (info.path.length > 1) {
            IAdapter adapter = IAdapter(info.meta[3]);
            uint256[] memory amounts = adapter.getAmountsOut(
                info.uints[0],
                info.path
            );

            IERC20(info.path[0]).approve(info.meta[3], info.uints[0]);
            baseAmountOutSansFee = adapter.swapExactTokensForTokens(
                info.uints[0],
                amounts[info.path.length - 1],
                info.path,
                address(this)
            );
        }

        //deduct fees
        (uint256 dataxFee, uint256 refFee) = calcFees(
            baseAmountOutSansFee,
            STAKE_FEE_TYPE,
            info.uints[1]
        );
        //collect ref Fees
        if (info.meta[2] != address(0)) {
            referralFees[info.meta[2]][address(baseToken)] = referralFees[
                info.meta[2]
            ][address(baseToken)].add(refFee);
        }
        // actual base amount minus fees
        uint256 baseAmountOut = bsub(
            baseAmountOutSansFee,
            badd(dataxFee, refFee)
        );

        //handle Pool swap
        IPool pool = IPool(info.meta[0]);
        //approve Pool to spend base token
        require(
            baseToken.approve(info.meta[0], baseAmountOut),
            "StakeRouter: Failed to approve Basetoken on Pool"
        );

        //stake tokens in Pool
        poolTokensOut = pool.joinswapExternAmountIn(
            baseAmountOut,
            info.uints[2]
        );

        //transfer pool tokens to destination address
        require(
            IERC20(info.meta[0]).transfer(info.meta[1], poolTokensOut),
            "Error: Pool Token transfer failed"
        );

        emit StakedTokenInPool(
            info.meta[0],
            info.path[0],
            info.meta[1],
            info.meta[2],
            info.uints[0],
            baseAmountOut
        );
    }

    function unstakeTokenFromDTPool(StakeInfo calldata info)
        external
        nonReentrant
        returns (uint256 tokenAmountOut)
    {
        require(
            info.meta[2] != address(0),
            "StakeRouter: Destination address not provided"
        );

        require(
            info.uints[0] <=
                IERC20(info.meta[0]).allowance(msg.sender, address(this)),
            "StakeRouter: Not enough token allowance"
        );

        //unstake into baseToken
        IPool pool = IPool(info.meta[0]);
        IERC20(info.meta[0]).transferFrom(
            msg.sender,
            address(this),
            info.uints[0]
        );
        IERC20(info.meta[0]).approve(address(pool), info.uints[0]);

        //unstake baseToken from Pool
        uint256 baseAmountOutSansFee = pool.exitswapPoolAmountIn(
            info.uints[0],
            info.uints[2]
        );

        IERC20 baseToken = IERC20(info.path[0]);

        //deduct fees
        (uint256 dataxFee, uint256 refFee) = calcFees(
            baseAmountOutSansFee,
            UNSTAKE_FEE_TYPE,
            info.uints[1]
        );
        //collect ref Fees
        if (info.meta[2] != address(0)) {
            referralFees[info.meta[2]][address(baseToken)] = referralFees[
                info.meta[2]
            ][address(baseToken)].add(refFee);
        }
        // actual base amount minus fees
        uint256 baseAmountOut = bsub(
            baseAmountOutSansFee,
            badd(dataxFee, refFee)
        );

        //skip if tokenOut is the baseToken
        if (info.path.length > 1) {
            baseToken.approve(info.meta[3], baseAmountOut);
            //swap to output token
            IAdapter adapter = IAdapter(info.meta[3]);
            //swap basetoken to Destination token
            uint256[] memory amounts = adapter.getAmountsOut(
                baseAmountOut,
                info.path
            );
            tokenAmountOut = adapter.swapExactTokensForTokens(
                baseAmountOut,
                amounts[info.path.length - 1],
                info.path,
                info.meta[1]
            );
        } else {
            //send tokenOut to destination address
            require(
                baseToken.transfer(info.meta[1], baseAmountOut),
                "StakeRouter: Failed to transfer tokenOut"
            );
        }

        emit UnstakedTokenFromPool(
            info.meta[0],
            info.path[0],
            info.meta[1],
            info.meta[2],
            info.uints[0],
            baseAmountOut
        );
    }

    //if staking, expected pool amount out given exact token amount in
    function calcPoolOutGivenTokenIn(StakeInfo calldata info)
        public
        view
        returns (
            uint256 poolAmountOut,
            uint256 dataxFee,
            uint256 refFee
        )
    {
        uint256 amountIn = info.uints[0];

        //skip if tokenOut is the baseToken
        if (info.path.length > 1) {
            IAdapter adapter = IAdapter(info.meta[3]);
            uint256[] memory amounts = adapter.getAmountsOut(
                info.uints[0],
                info.path
            );
            amountIn = amounts[amounts.length - 1];
        }

        (dataxFee, refFee) = calcFees(amountIn, STAKE_FEE_TYPE, info.uints[1]);
        uint256 baseAmountIn = amountIn.sub(dataxFee.add(refFee));

        IPool pool = IPool(info.meta[0]);
        poolAmountOut = pool.calcPoolOutSingleIn(
            info.path[info.path.length - 1],
            baseAmountIn
        );
    }

    //if unstaking, calculate pool amount needed to get exact token amount out
    function calcPoolInGivenTokenOut(StakeInfo calldata info)
        public
        view
        returns (
            uint256 poolAmountIn,
            uint256 dataxFee,
            uint256 refFee
        )
    {
        uint256 amountOut = info.uints[2];

        //skip if tokenOut is the baseToken
        if (info.path.length > 1) {
            IAdapter adapter = IAdapter(info.meta[3]);
            uint256[] memory amounts = adapter.getAmountsIn(
                info.uints[2],
                info.path
            );
            amountOut = amounts[0];
        }

        (dataxFee, refFee) = calcFees(amountOut, STAKE_FEE_TYPE, info.uints[1]);
        uint256 baseAmountNeeded = amountOut.add(dataxFee.add(refFee));

        IPool pool = IPool(info.meta[0]);
        poolAmountIn = pool.calcPoolInSingleOut(info.path[0], baseAmountNeeded);
    }

    //if unstaking, expected tokens out given exact pool amount in
    function calcTokenOutGivenPoolIn(StakeInfo calldata info)
        public
        view
        returns (
            uint256 baseAmountOut,
            uint256 dataxFee,
            uint256 refFee
        )
    {
        IPool pool = IPool(info.meta[0]);
        uint256 baseAmountOutSansFee = pool.calcSingleOutPoolIn(
            info.path[0],
            info.uints[0]
        );

        (dataxFee, refFee) = calcFees(
            baseAmountOutSansFee,
            STAKE_FEE_TYPE,
            info.uints[1]
        );
        baseAmountOut = baseAmountOutSansFee.sub(dataxFee.add(refFee));

        //skip if tokenOut is the baseToken
        if (info.path.length > 1) {
            IAdapter adapter = IAdapter(info.meta[3]);
            uint256[] memory amountsOut = adapter.getAmountsOut(
                baseAmountOut,
                info.path
            );
            baseAmountOut = amountsOut[amountsOut.length - 1];
        }
    }

    //calculate fees
    function calcFees(
        uint256 baseAmount,
        string memory feeType,
        uint256 refFeeRate
    ) public view returns (uint256 dataxFee, uint256 refFee) {
        uint256 feeRate = store.getFees(feeType);
        require(
            refFeeRate <= bsub(BONE, feeRate),
            "StakeRouter: Ref Fees too high"
        );

        // DataX Fees
        if (feeRate != 0) {
            dataxFee = bsub(baseAmount, bmul(baseAmount, bsub(BONE, feeRate)));
        }
        // Referral fees
        if (refFeeRate != 0) {
            refFee = bsub(baseAmount, bmul(baseAmount, bsub(BONE, refFeeRate)));
        }
    }

    //claim collected Referral fees
    function claimRefFees(address token, address referrer)
        external
        nonReentrant
        returns (uint256 claimAmount)
    {
        IERC20 baseToken = IERC20(token);
        claimAmount = referralFees[referrer][token];
        require(claimAmount > 0, "StakeRouter: No tokens to claim");
        //reset claimable amount
        referralFees[referrer][token] = 0;
        //transfer tokens to referrer
        require(
            baseToken.transfer(referrer, claimAmount),
            "StakeRouter: Referral Token claim failed"
        );

        emit ReferralFeesClaimed(referrer, token, claimAmount);
    }

    //receive ETH
    receive() external payable {}
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: BSU-1.1

interface IAdapter {
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        address refundTo
    ) external payable returns (uint256 amtOut, uint256 refund);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amtOut);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amtOut);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        address refundTo
    ) external payable returns (uint256 tokenAmountIn, uint256 refund);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint256 amtOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        address refundTo
    ) external returns (uint256 amtOut, uint256 refund);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

pragma solidity >=0.8.0 <0.9.0;

//Copyright of DataX Protocol contributors
//SPDX-License-Identifier: BSU-1.1

interface IPool {
    function balanceOf(address) external view returns (uint256);

    function swapExactAmountIn(
        address[3] calldata tokenInOutMarket, //[tokenIn,tokenOut,marketFeeAddress]
        uint256[4] calldata amountsInOutMaxFee //[tokenAmountIn,minAmountOut,maxPrice,_swapMarketFee]
    ) external returns (uint256, uint256);

    function swapExactAmountOut(
        address[3] calldata tokenInOutMarket, // [tokenIn,tokenOut,marketFeeAddress]
        uint256[4] calldata amountsInOutMaxFee // [maxAmountIn,tokenAmountOut,maxPrice,_swapMarketFee]
    ) external returns (uint256, uint256);

    function getAmountInExactOut(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 _consumeMarketSwapFee
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAmountOutExactIn(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountIn,
        uint256 _consumeMarketSwapFee
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function exitswapPoolAmountIn(uint256 poolAmountIn, uint256 minAmountOut)
        external
        returns (uint256);

    function joinswapExternAmountIn(
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256);

    function calcPoolInSingleOut(address tokenOut, uint256 tokenAmountOut)
        external
        view
        returns (uint256);

    function calcSingleOutPoolIn(address tokenOut, uint256 poolAmountIn)
        external
        view
        returns (uint256);

    function calcSingleInPoolOut(address tokenIn, uint256 poolAmountOut)
        external
        view
        returns (uint256);

    function calcPoolOutSingleIn(address tokenIn, uint256 tokenAmountIn)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: BSU-1.1

interface IStorage {
    function getContractAdd(string calldata name, uint8 version)
        external
        view
        returns (address);

    function getCurrentVersion(string calldata name)
        external
        view
        returns (uint8);

    function updateContractVersion(
        string calldata name,
        uint8 version,
        address value
    ) external;

    function getFees(string calldata key) external view returns (uint256);

    function updateFees(string calldata key, uint256 value) external;
}

pragma solidity >=0.8.0 <0.9.0;
//Copyright of DataX Protocol contributors
//SPDX-License-Identifier: BSU-1.1

import "./Const.sol";

contract Math is Const {
    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 b = a;
        uint256 z = n % 2 != 0 ? b : BONE;

        for (n /= 2; n != 0; n /= 2) {
            b = bmul(b, b);

            if (n % 2 != 0) {
                z = bmul(z, b);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity >=0.8.0 <0.9.0;
//Copyright of DataX Protocol contributors
//SPDX-License-Identifier: BSU-1.1

contract Const {
    uint256 public constant BONE = 1e18;
    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 1e10;
}