//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


/** Interfaces */
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

interface IYield {
    function stake(address user, uint256 amount) external;
}

interface ISTS {
    function sellFeeRecipient() external view returns (address);
    function sellFee() external view returns (uint256);
    function getOwner() external view returns (address);
}

contract CustomizedRewards {

    struct FarmCustomization {
        uint256 compoundPercent; // percent to be compounded
        uint256 claimPercent; // percent to be claimed
        uint256 liquidatePercent; // percent to be liquidated to STS+
        bool claimToStaking; // whether or not to claim to STS Staking
    }

    struct StakingCustomization {
        uint256 compoundPercent; // percent to be compounded
        uint256 claimPercent; // percent to be claimed
        uint256 liquidatePercent; // percent to be liquidated to STS+
    }

    struct UserInfo {
        FarmCustomization STSPlusFarmRewards;
        FarmCustomization MATICFarmRewards;
        StakingCustomization StakingRewards;
    }

    // Maps user to their reward customizations
    mapping ( address => UserInfo ) public userInfo;


    // Addresses needed for customization
    address public immutable STS;
    address public immutable STSPlus;
    address public immutable STSStaking;
    address public immutable STSPlusFarm;
    address public immutable MATICFarm;
    IUniswapV2Router02 public immutable router;

    // Liquidate Fee Denominator
    uint256 public constant TAX_DENOM = 10000;

    constructor(
        address STS_,
        address STSPlus_,
        address STSStaking_,
        address STSPlusFarm_,
        address MATICFarm_,
        address router_
    ) {
        STS = STS_;
        STSPlus = STSPlus_;
        STSStaking = STSStaking_;
        STSPlusFarm = STSPlusFarm_;
        MATICFarm = MATICFarm_;
        router = IUniswapV2Router02(router_);
    }

    function setCustomizedFarmRewards(
        bool maticFarm,
        uint256 compound_,
        uint256 claim_,
        uint256 liquidate_,
        bool claimToStaking_
    ) external {

        FarmCustomization memory reward = FarmCustomization({
            compoundPercent: compound_,
            claimPercent: claim_,
            liquidatePercent: liquidate_,
            claimToStaking: claimToStaking_
        });

        if (maticFarm) {
            userInfo[msg.sender].MATICFarmRewards = reward;
        } else {
            userInfo[msg.sender].STSPlusFarmRewards = reward;
        }

    }

    function setCustomizedStakingRewards(
        uint256 compound_,
        uint256 claim_,
        uint256 liquidate_
    ) external {

        userInfo[msg.sender].StakingRewards = StakingCustomization({
            compoundPercent: compound_,
            claimPercent: claim_,
            liquidatePercent: liquidate_
        });

    }

    function trigger(address user, uint256 amount, address yieldToken) external {

        uint256 compound;
        uint256 claim;
        uint256 liquidate;
        uint256 total;

        uint256 bal = IERC20(STS).balanceOf(address(this));
        if (amount > bal) {
            amount = bal;
        }
        if (amount == 0) {
            return;
        }

        if (msg.sender == STSStaking) {
            // STS Staking

            // determine how to process rewards
            compound = userInfo[user].StakingRewards.compoundPercent;
            claim = userInfo[user].StakingRewards.claimPercent;
            liquidate = userInfo[user].StakingRewards.liquidatePercent;
            total = compound + claim + liquidate;

            if (total == 0) {
                // simply claim reward
                require(
                    IERC20(STS).transfer(user, amount),
                    'Failure On Token Claim'
                );
            } else {

                if (claim > 0) {
                    uint256 claimAmount = ( amount * claim ) / total;
                    if (claimAmount > 0) {
                        _claim(claimAmount, user, false);
                    }
                }

                if (liquidate > 0) {
                    uint256 liquidateAmount = ( amount * liquidate ) / total;
                    if (liquidateAmount > 0) {
                        _liquidate(liquidateAmount, user);
                    }
                }

                if (compound > 0) {
                    uint256 compoundAmount = ( amount * compound ) / total;
                    if (compoundAmount > 0) {
                        IERC20(yieldToken).approve(msg.sender, compoundAmount);
                        IYield(msg.sender).stake(user, compoundAmount);
                    }
                }

            }

        } else if (msg.sender == STSPlusFarm) {
            // STSPlus Farm

            // determine how to process rewards
            compound = userInfo[user].STSPlusFarmRewards.compoundPercent;
            claim = userInfo[user].STSPlusFarmRewards.claimPercent;
            liquidate = userInfo[user].STSPlusFarmRewards.liquidatePercent;
            total = compound + claim + liquidate;

            if (total == 0) {
                // simply claim reward
                require(
                    IERC20(STS).transfer(user, amount),
                    'Failure On Token Claim'
                );
            } else {

                if (claim > 0) {
                    uint256 claimAmount = ( amount * claim ) / total;
                    if (claimAmount > 0) {
                        _claim(claimAmount, user, userInfo[user].STSPlusFarmRewards.claimToStaking);
                    }
                }

                if (liquidate > 0) {
                    uint256 liquidateAmount = ( amount * liquidate ) / total;
                    if (liquidateAmount > 0) {
                        _liquidate(liquidateAmount, user);
                    }
                }

                if (compound > 0) {
                    uint256 compoundAmount = ( amount * compound ) / total;
                    if (compoundAmount > 1) {

                        // convert STS into STS-STS+ LP Tokens
                        uint256 half = compoundAmount / 2;

                        // swap path for STS into MATIC
                        address[] memory path = new address[](2);
                        path[0] = STS;
                        path[1] = STSPlus;

                        // swap half STS into STS+, approve full amount for adding liquidity
                        IERC20(STS).approve(address(router), compoundAmount);
                        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            half, 1, path, address(this), block.timestamp + 100
                        );

                        // approve of STSPlus Balance
                        uint256 STSPBal = IERC20(STSPlus).balanceOf(address(this));
                        IERC20(STSPlus).approve(address(router), STSPBal);

                        // clear memory
                        delete path;

                        // add maticReceived and the other half of matic into liquidity
                        // there will be STS+ dust left over from this, which will be sent back to the contract
                        // to avoid users taking advantage of dust, we track MATIC balance before and after
                        // owner can convert STS+ dust into more STS for rewards if he/she so chooses
                        // by calling the function `rollOverDustIntoRewards()`
                        router.addLiquidity(
                            STS, STSPlus, compoundAmount - half, STSPBal, 1, 1, address(this), block.timestamp + 100
                        );

                        // refund STS+ dust to yield farm
                        STSPBal = IERC20(STSPlus).balanceOf(address(this));
                        if (STSPBal > 0) {
                            IERC20(STSPlus).transfer(msg.sender, STSPBal);
                        }

                        // compound LP Balance
                        _compoundYield(yieldToken, user);
                    }
                }

            }

        } else if (msg.sender == MATICFarm) {
            // MATIC Farm

            // determine how to process rewards
            compound = userInfo[user].MATICFarmRewards.compoundPercent;
            claim = userInfo[user].MATICFarmRewards.claimPercent;
            liquidate = userInfo[user].MATICFarmRewards.liquidatePercent;
            total = compound + claim + liquidate;

            if (total == 0) {
                // simply claim reward
                require(
                    IERC20(STS).transfer(user, amount),
                    'Failure On Token Claim'
                );
            } else {

                if (claim > 0) {
                    uint256 claimAmount = ( amount * claim ) / total;
                    if (claimAmount > 0) {
                        _claim(claimAmount, user, userInfo[user].MATICFarmRewards.claimToStaking);
                    }
                }

                if (liquidate > 0) {
                    uint256 liquidateAmount = ( amount * liquidate ) / total;
                    if (liquidateAmount > 0) {
                        _liquidate(liquidateAmount, user);
                    }
                }

                if (compound > 0) {
                    uint256 compoundAmount = ( amount * compound ) / total;
                    if (compoundAmount > 1) {

                        // convert STS into STS-MATIC LP Tokens
                        uint256 half = compoundAmount / 2;

                        // swap path for STS into MATIC
                        address[] memory path = new address[](2);
                        path[0] = STS;
                        path[1] = router.WETH();

                        // swap half STS into MATIC, approve full amount for adding liquidity
                        IERC20(STS).approve(address(router), compoundAmount);
                        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                            half, 1, path, address(this), block.timestamp + 100
                        );

                        // clear memory
                        delete path;

                        // add maticReceived and the other half of matic into liquidity
                        // there will be MATIC dust left over from this
                        // to avoid users taking advantage of dust, we track MATIC balance before and after
                        // owner can convert MATIC dust into more STS for rewards if he/she so chooses
                        // by calling the function `rollOverDustIntoRewards()`
                        router.addLiquidityETH{value: address(this).balance}(
                            STS, compoundAmount - half, 1, 1, address(this), block.timestamp + 100
                        );

                        // refund MATIC dust to yield farm
                        if (address(this).balance > 0) {
                            (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
                            require(s);
                        }

                        // compound LP Balance
                        _compoundYield(yieldToken, user);
                    }
                }

            }

        }
    }

    function _takeSTSSellFee(uint256 amount) internal returns (uint256){
        uint256 fee = ( amount * ISTS(STS).sellFee() ) / TAX_DENOM;
        if (fee > 0) {
            address recipient = ISTS(STS).sellFeeRecipient();
            if (recipient != address(0)) {
                IERC20(STS).transfer(recipient, fee);
            }
        }
        return amount - fee;
    }

    function _liquidate(uint256 amount, address user) internal {
        // liquidate token for STS+ using MATIC router
        address[] memory path = new address[](2);
        path[0] = STS;
        path[1] = STSPlus;

        // TAKE FEE IN STS
        uint256 sellAmount = _takeSTSSellFee(amount);

        // liquidates token for STS+
        IERC20(STS).approve(address(router), sellAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sellAmount, 1, path, user, block.timestamp + 100
        );

        // clear memory
        delete path;
    }

    function _claim(uint256 amount, address user, bool toStaking) internal {

        if (toStaking) {
            // deposit claimAmount into staking contract on behalf of user
            IERC20(STS).approve(STSStaking, amount);
            IYield(STSStaking).stake(user, amount);
        } else {
            // transfer claimAmount tokens to user
            require(
                IERC20(STS).transfer(user, amount),
                'Failure On Token Claim'
            );
        }
    }

    function _compoundYield(address yieldToken, address user) internal {
        
        // get LP balance received
        uint256 LPBalance = IERC20(yieldToken).balanceOf(address(this));

        // approve of yield farm
        IERC20(yieldToken).approve(msg.sender, LPBalance);

        // stake balance for user for user
        IYield(msg.sender).stake(user, LPBalance);
    }

    function withdraw(address token) external {
        require(msg.sender == ISTS(STS).getOwner(), 'Only Owner');
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function withdrawETH() external {
        require(msg.sender == ISTS(STS).getOwner(), 'Only Owner');
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    receive() external payable{}

    function getMaticFarmCustomization(address user) external view returns (FarmCustomization memory) {
        return userInfo[user].MATICFarmRewards;
    }

    function getSTSPlusFarmCustomization(address user) external view returns (FarmCustomization memory) {
        return userInfo[user].STSPlusFarmRewards;
    }

    function getStakingCustomization(address user) external view returns (StakingCustomization memory) {
        return userInfo[user].StakingRewards;
    }

}