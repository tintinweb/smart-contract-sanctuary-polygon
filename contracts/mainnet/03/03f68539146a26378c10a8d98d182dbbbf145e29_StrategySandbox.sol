// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../SafeERC20.sol";
import "../SafeMath.sol";

import "../IUniswapRouterETH.sol";
import "../IUniswapV2Pair.sol";
import "../ISandbox.sol";
import "../StratManager.sol";
import "../FeeManager.sol";
import "../StringUtils.sol";

contract StrategySandbox is StratManager, FeeManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address public native;
    address public output;
    address public want;

    // Third party contracts
    address public chef;
    uint256 public lastClaim;
    uint256 public tokensPerYear;

    bool public harvestOnDeposit;
    uint256 public lastHarvest;
    string public pendingRewardsFunctionName;

    // Routes
    address[] public outputToNativeRoute;

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 protocolFees, uint256 holdersFees);

    constructor(
        address _want,
        address _chef,
        address _vault,
        address _unirouter,
        address _keeper,
        uint256 _weeklyRewards,
        address[] memory _outputToNativeRoute
    ) StratManager(_keeper, _keeper, _unirouter, _vault, _keeper) {
        want = _want;
        chef = _chef;
        tokensPerYear = _weeklyRewards * 54;

        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;
        
        _giveAllowances();
    }

    function _updateTokensPerYear(uint256 _weeklyRewards) external onlyManager {
        tokensPerYear = _weeklyRewards * 54;
    }

    // Calculate Performance for this strategy in NativeToken
    function strategyPerformance(uint256 toDeposit) public view returns (uint256) {
        return tokensPerYear.mul(balanceOfPool() + toDeposit).div(ISandboxChef(chef).totalSupply());
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            // Deposit to Sandbox
            ISandboxChef(chef).stake(wantBal);
            if (balanceOfPool() == 0) { // If Pool is empty, lock rewards for antiCompound duration
                lastClaim = block.timestamp;
            }
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            ISandboxChef(chef).withdraw(_amount.sub(wantBal));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    function harvest(address callFeeRecipient) external virtual {
        require(msg.sender == vault, "!vault");
        _harvest(callFeeRecipient);
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal whenNotPaused {
        if (block.timestamp > lastClaim + ISandboxChef(chef).antiCompound()) {
            lastClaim = block.timestamp;
            ISandboxChef(chef).getReward();
            uint256 outputBal = IERC20(output).balanceOf(address(this));
            if (outputBal > 0) {
                chargeFees(callFeeRecipient);
                uint256 wantHarvested = balanceOfWant();
                deposit();

                lastHarvest = block.timestamp;
                emit StratHarvest(msg.sender, wantHarvested, balanceOf());
            }
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 toNative = IERC20(output).balanceOf(address(this)).mul(VAULT_FEE).div(DENOMINATOR_FEE);
        if(toNative > 0) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(toNative, 0, outputToNativeRoute, address(this), block.timestamp);
        }

        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        uint256 callFeeAmount = nativeBal.mul(CALL_FEE).div(DENOMINATOR_FEE);
        IERC20(native).safeTransfer(callFeeRecipient, callFeeAmount);

        uint256 protocolFeeAmount = nativeBal.mul(PROTOCOL_FEE).div(DENOMINATOR_FEE);
        IERC20(native).safeTransfer(ProtocolFeeRecipient, protocolFeeAmount);
        uint256 holdersFeeAmount = IERC20(native).balanceOf(address(this));
        IERC20(native).safeTransfer(HoldersFeeRecipient, holdersFeeAmount);

        emit ChargedFees(callFeeAmount, protocolFeeAmount, holdersFeeAmount);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return ISandboxChef(chef).balanceOf(address(this));
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return ISandboxChef(chef).earned(address(this));
    }

    // native reward amount for calling harvest
    function callReward() public view returns (uint256) {
        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut = 0;
        
        if (outputBal > 0) {
            uint256[] memory amountOut = IUniswapRouterETH(unirouter).getAmountsOut(outputBal, outputToNativeRoute);
            nativeOut += amountOut[amountOut.length -1];
        }

        return nativeOut.mul(VAULT_FEE).div(DENOMINATOR_FEE).mul(CALL_FEE).div(DENOMINATOR_FEE);
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
    }

    function setMasterChef(address _masterChef) external onlyManager {
        chef = _masterChef;
        _giveAllowances();
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        ISandboxChef(chef).withdraw(balanceOfPool());

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        ISandboxChef(chef).withdraw(balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(chef, uint256(115792089237316195423570985008687907853269984665640564039457584007913129639935));
        IERC20(output).safeApprove(unirouter, uint256(115792089237316195423570985008687907853269984665640564039457584007913129639935));
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(chef, 0);
        IERC20(output).safeApprove(unirouter, 0);
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyManager {
        require(_token != want, "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}