// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FractBaseStrategy.sol";
import "./SafeERC20.sol";
import "./ISwap.sol";
import "./IMiniChefV2.sol";

contract FractStableswapPolygon is FractBaseStrategy {
    using SafeERC20 for IERC20;

    //paraswap swapper contract
    address constant PARASWAP = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    //token transfer proxy
    address constant TOKENTRANSFERPROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;
    //stableswap pool
    address constant STABLESWAP = 0x85fCD7Dd0a1e1A9FCD5FD886ED522dE8221C3EE5;
    //imini chef
    address constant MINICHEF = 0x7875Af1a6878bdA1C129a4e2356A3fD040418Be5;
    //lp token
    address constant LPTOKEN = 0x7479e1Bc2F2473f9e78c89B4210eb6d55d33b645;
    //syn token
    address constant SYN = 0xf8F9efC0db77d8881500bb06FF5D6ABc3070E695;

    /**
     * @notice Deposit into the strategy. Can only be called by the fractVault
     * @param depositToken token to deposit.
     * @param amount amount of tokens to deposit.
     */

    function deposit(address depositToken, uint256 amount) public override onlyOwner
    {
        emit Deposit(msg.sender, amount);

        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraw from the strategy. Can only be called by the fractVault.
     * @param depositToken token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdraw(address depositToken, uint256 amount) public override onlyOwner
    {
        emit Withdraw(msg.sender, amount);

        IERC20(depositToken).safeTransfer(msg.sender, amount);
    }

    /*
     * @notice Function to run approvals for all tokens and spenders.
     * @dev Used to save gas instead of approving everytime we run a transaction
     * @param depositToken Deposit token to approve for lending pool. 
     */
    function runApprovals(address depositToken) public onlyOwner 
    {
        IERC20(depositToken).approve(STABLESWAP, type(uint256).max);
        IERC20(LPTOKEN).approve(STABLESWAP, type(uint256).max);
        IERC20(LPTOKEN).approve(MINICHEF, type(uint256).max);
        IERC20(SYN).approve(TOKENTRANSFERPROXY, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                        ADD/REMOVE LIQUIDTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function addLiquidityAndDeposit(
        uint256[] calldata amounts,
        uint256 slippageBips,
        uint256 pid) public onlyController 
    {
        uint256 calcAmount = ISwap(STABLESWAP).calculateTokenAmount(amounts, true);

        uint256 minAmount = (calcAmount * (BIPS_DIVISOR - slippageBips)) / BIPS_DIVISOR;

        ISwap(STABLESWAP).addLiquidity(amounts, minAmount, block.timestamp + 10);

        uint256 lpTokenBalance = IERC20(LPTOKEN).balanceOf(address(this));

        IMiniChefV2(MINICHEF).deposit(pid, lpTokenBalance, address(this));
    }

    function removeLiquidityAndWithdraw(
        uint256 pid,
        uint8 tokenIndex,
        uint256 slippageBips) public onlyController 
    {
        (uint256 lpTokenBalance,) = IMiniChefV2(MINICHEF).userInfo(1, address(this));

        IMiniChefV2(MINICHEF).withdraw(pid, lpTokenBalance, address(this));

        uint256 calcAmount = ISwap(STABLESWAP).calculateRemoveLiquidityOneToken(lpTokenBalance, tokenIndex);

        uint256 minAmount = (calcAmount * (BIPS_DIVISOR - slippageBips)) / BIPS_DIVISOR;

        ISwap(STABLESWAP).removeLiquidityOneToken(lpTokenBalance, tokenIndex, minAmount, block.timestamp + 10);
    }

    

    /*///////////////////////////////////////////////////////////////
                        HARVEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function getRewards(uint256 pid) public onlyController
    {
        IMiniChefV2(MINICHEF).harvest(pid, address(this));
    }

    /**
     * @notice Swap rewards via the paraswap router. 
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function swap(bytes memory callData) public payable onlyController
    {
        (bool success,) = PARASWAP.call(callData);

        require(success, "swap failed");  
    }
           
}