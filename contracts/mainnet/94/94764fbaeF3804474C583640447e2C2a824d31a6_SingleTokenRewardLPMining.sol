// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IStakingRewards.sol";
import "./QuickSwapStrategy.sol";
import "../../interfaces/IPair.sol";
import "../../interfaces/IDragonLiar.sol";

contract SingleTokenRewardLPMining is QuickSwapStrategy {
    IERC20 private token0;
    IERC20 private token1;
    IPair public depositToken;
    IStakingRewards public stakingRewards;
    IDragonLiar public dragonsliar;

    constructor(
        address _WETH,
        address _dragonsliar,
        address _depositToken,
        address _quick,
        address _stakingRewards,
        address _router,
        uint256 _autoCompoundTokenPerBlock,
        address _ops,
        address _treasury
    ) {
        WETH = _WETH;
        ops = _ops;
        treasury = _treasury;
        quick = _quick;
        dragonsliar = IDragonLiar(_dragonsliar);
        depositToken = IPair(_depositToken);
        stakingRewards = IStakingRewards(_stakingRewards);
        router = IRouter(_router);

        autoCompoundTokenPerBlock = _autoCompoundTokenPerBlock;
        startBlock = block.number;
        lastRewardBlock = startBlock;

        address _token0 = IPair(_depositToken).token0();
        address _token1 = IPair(_depositToken).token1();

        token0 = IERC20(_token0);
        token1 = IERC20(_token1);

        name = string(
            abi.encodePacked(
                "Autocompound: ",
                depositToken.symbol(),
                " ",
                IERC20(_token0).symbol(),
                "-",
                IERC20(_token1).symbol()
            )
        );

        setAllowances();
        emit Reinvest(0, 0);
    }

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external override nonReentrant {
        _deposit(amount, false);
    }

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param amount0 Amount of tokens0 to deposit
     * @param _token0 address of token0
     * @param amount1 Amount of tokens1 to deposit
     * @param _token1 address of token1
     */

    function dualTokenDeposit(
        uint256 amount0,
        address _token0,
        uint256 amount1,
        address _token1,
        uint256 slippage
    ) external nonReentrant {
        require(
            amount0 > 0 && amount1 > 0,
            "SingleTokenRewardLPMining::dualTokenDeposit: Can not deposit zero amount"
        );

        require(
            ((_token0 == address(token0)) &&
                (_token1 == address(token1)) &&
                (_token0 != _token1)),
            "SingleTokenRewardLPMining::dualTokenDeposit: Invalid token address"
        );
        require(
            slippage >= 1 && slippage < 500,
            "SingleTokenRewardLPMining::dualTokenDeposit: Invalid slippage"
        );

        uint256 amountAmin = (amount0 * slippage) / SLIPPAGE_DIVISOR;
        uint256 amountBmin = (amount1 * slippage) / SLIPPAGE_DIVISOR;
        _dualTokenDeposit(
            amount0,
            _token0,
            amountAmin,
            amount1,
            _token1,
            amountBmin,
            true
        );
    }

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param amount Amount of tokens to deposit
     * @param _token address of token
     */

    function singleTokenDeposit(
        uint256 amount,
        address _token,
        uint256 slippage
    ) external nonReentrant {
        require(
            amount > 0,
            "SingleTokenRewardLPMining::singleTokenDeposit: Can not deposit zero amount"
        );
        require(
            slippage >= 1 && slippage < 500,
            "SingleTokenRewardLPMining::singleTokenDeposit: Invalid slippage"
        );
        require(
            _token == address(token0) || _token == address(token1),
            "SingleTokenRewardLPMining::singleTokenDeposit: Invalid token address"
        );

        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            amount
        );
        uint256 amountIn = amount / 2;
        address[] memory path0 = new address[](2);
        path0[0] = _token;
        path0[1] = path0[0] == address(token0)
            ? address(token1)
            : address(token0);

        uint256[] memory amountsOutToken0 = router.getAmountsOut(
            amountIn,
            path0
        );
        uint256 amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
        router.swapExactTokensForTokens(
            amountIn,
            amountOutToken0,
            path0,
            address(this),
            block.timestamp + 1800
        );
        uint256 amountAmin = (amountIn * slippage) / SLIPPAGE_DIVISOR;
        uint256 amountBmin = (amountOutToken0 * slippage) / SLIPPAGE_DIVISOR;

        _dualTokenDeposit(
            amountIn,
            path0[0],
            amountAmin,
            amountOutToken0,
            path0[1],
            amountBmin,
            false
        );
    }

    /**
     * @notice Withdraw LP tokens by redeeming receipt tokens
     * @param amount Amount of receipt tokens to redeem
     */

    function withdraw(uint256 amount) external override nonReentrant {
        _withdraw(amount, false);
    }

    /**
     * @notice Withdraw tokens by redeeming receipt tokens
     * @param amount Amount of LP to redeem in terms of tokens
     * @param _token Address of token
     */
    function singleWithdraw(uint256 amount, address _token)
        external
        nonReentrant
    {
        require(
            _token == address(token0) || _token == address(token1),
            "SingleTokenRewardLPMining::singleWithdraw: Invalid token address"
        );
        uint256 depositTokenAmount = getDepositTokensForShares(amount);
        _withdraw(amount, true);

        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            address(token0),
            address(token1),
            depositTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 1800
        );
        address[] memory path0 = new address[](2);

        uint256 amountIN;
        uint256 amountOUT;
        if (_token == address(token0)) {
            amountIN = amount1;
            amountOUT = amount0;
            path0[0] = address(token1);
            path0[1] = address(token0);
        } else {
            amountIN = amount0;
            amountOUT = amount1;
            path0[0] = address(token0);
            path0[1] = address(token1);
        }
        uint256[] memory amountsOutToken0 = router.getAmountsOut(
            amountIN,
            path0
        );
        uint256 amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
        router.swapExactTokensForTokens(
            amountIN,
            amountOutToken0,
            path0,
            address(this),
            block.timestamp + 1800
        );

        TransferHelper.safeTransfer(
            _token,
            msg.sender,
            amountOutToken0 + amountOUT
        );
    }

    /**
     * @notice Withdraw tokens by redeeming receipt tokens
     * @param amount Amount of LP to redeem in terms of tokens
     */
    function dualWithdraw(uint256 amount) external nonReentrant {
        uint256 depositTokenAmount = getDepositTokensForShares(amount);
        _withdraw(amount, true);
        router.removeLiquidity(
            address(token0),
            address(token1),
            depositTokenAmount,
            0,
            0,
            msg.sender,
            block.timestamp + 1800
        );
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     * @dev This external function requires minimum tokens to be met
     */
    function reinvest() external onlyEOA nonReentrant {
        _reinvest(msg.sender);
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     * @dev This external function requires minimum tokens to be met
     */
    function reinvestOps() external onlyOps nonReentrant {
        _reinvest(treasury);
    }

    /**
     * @notice Allows exit from Staking Contract without additional logic
     * @dev Reward tokens are not automatically collected
     * @dev New deposits will be effectively disabled
     */
    function emergencyWithdraw() external onlyOwner {
        stakingRewards.exit();
        totalDeposits = 0;
    }

    /**
     * @notice Estimate reinvest reward for caller
     * @return Estimated rewards tokens earned for calling `reinvest()`
     */
    function estimateReinvestReward() external view returns (uint256) {
        uint256 dQuickAmount = stakingRewards.earned(address(this));
        uint256 quickAmount = dragonsliar.dQUICKForQUICK(dQuickAmount);

        return (quickAmount * REINVEST_REWARD_BIPS) / BIPS_DIVISOR;
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Restricted to avoid griefing attacks
     */
    function setAllowances() public onlyOwner {
        TransferHelper.safeApprove(
            address(depositToken),
            address(stakingRewards),
            UINT_MAX
        );
        TransferHelper.safeApprove(
            address(depositToken),
            address(router),
            UINT_MAX
        );
        TransferHelper.safeApprove(quick, address(router), UINT_MAX);
        TransferHelper.safeApprove(address(token0), address(router), UINT_MAX);
        TransferHelper.safeApprove(address(token1), address(router), UINT_MAX);
    }

    function _reinvest(address recipient) internal {
        uint256 dQuickAmount = stakingRewards.earned(address(this));
        uint256 quickAmount = dragonsliar.dQUICKForQUICK(dQuickAmount);

        stakingRewards.getReward();
        dragonsliar.leave(dQuickAmount);

        uint256 stakingFunds = (quickAmount * ADMIN_FEE_BIPS) / BIPS_DIVISOR;
        if (stakingFunds > 0) {
            _convertRewardTokensToAC(stakingFunds);
        }

        uint256 reinvestFee = (quickAmount * REINVEST_REWARD_BIPS) /
            BIPS_DIVISOR;
        if (reinvestFee > 0) {
            TransferHelper.safeTransfer(quick, recipient, reinvestFee);
        }

        uint256 lpTokenAmount = _convertRewardTokensToDepositTokens(
            quickAmount - stakingFunds - reinvestFee
        );
        stakingRewards.stake(lpTokenAmount);
        totalDeposits += lpTokenAmount;

        emit Reinvest(totalDeposits, totalSupply);
    }

    function _convertRewardTokensToDepositTokens(uint256 amount)
        internal
        returns (uint256)
    {
        uint256 amountIn = amount / 2;
        require(
            amountIn > 0,
            "SingleTokenRewardLPMining::_convertRewardTokensToDepositTokens: amount too low"
        );

        // swap to token0
        // address[] memory path0 = new address[](2);
        // path0[0] = quick;
        // path0[1] = address(token0);
        address[] memory path0 = new address[](3);
        path0[0] = quick;
        path0[1] = WETH;
        path0[2] = address(token0);

        uint256[] memory amountsOutToken0 = router.getAmountsOut(
            amountIn,
            path0
        );
        uint256 amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
        router.swapExactTokensForTokens(
            amountIn,
            amountOutToken0,
            path0,
            address(this),
            block.timestamp + 1800
        );

        // swap to token1
        // address[] memory path1 = new address[](2);
        // path1[0] = path0[0];
        // path1[1] = address(token1);
        address[] memory path1 = new address[](3);
        path1[0] = path0[0];
        path1[1] = WETH;
        path1[2] = address(token1);

        uint256[] memory amountsOutToken1 = router.getAmountsOut(
            amountIn,
            path1
        );
        uint256 amountOutToken1 = amountsOutToken1[amountsOutToken1.length - 1];
        router.swapExactTokensForTokens(
            amountIn,
            amountOutToken1,
            path1,
            address(this),
            block.timestamp + 1800
        );

        (, , uint256 liquidity) = router.addLiquidity(
            path0[2],
            path1[2],
            amountOutToken0,
            amountOutToken1,
            0,
            0,
            address(this),
            block.timestamp + 1800
        );

        return liquidity;
    }

    function _deposit(uint256 amount, bool check) internal {
        require(
            totalDeposits >= totalSupply,
            "SingleTokenRewardLPMining::_deposit: deposit failed"
        );
        if (REQUIRE_REINVEST_BEFORE_DEPOSIT) {
            _reinvest(msg.sender);
        }
        if (!check) {
            TransferHelper.safeTransferFrom(
                address(depositToken),
                msg.sender,
                address(this),
                amount
            );
        }
        stakingRewards.stake(amount);
        UserInfo storage user = userInfo[msg.sender];
        user.amount += uint128(amount);
        _mint(msg.sender, getSharesForDepositTokens(amount));
        totalDeposits += amount;
        emit Deposit(msg.sender, amount);
    }

    function _dualTokenDeposit(
        uint256 amount0,
        address _token0,
        uint256 amountAmin,
        uint256 amount1,
        address _token1,
        uint256 amountBmin,
        bool check
    ) internal {
        if (check) {
            TransferHelper.safeTransferFrom(
                _token0,
                msg.sender,
                address(this),
                amount0
            );
            TransferHelper.safeTransferFrom(
                _token1,
                msg.sender,
                address(this),
                amount1
            );
        }

        (, , uint256 liquidity) = router.addLiquidity(
            _token0,
            _token1,
            amount0,
            amount1,
            amountAmin,
            amountBmin,
            address(this),
            block.timestamp + 1800
        );
        _deposit(liquidity, true);
    }

    function _withdraw(uint256 amount, bool check) internal {
        uint256 depositTokenAmount = getDepositTokensForShares(amount);
        if (depositTokenAmount > 0) {
            stakingRewards.withdraw(depositTokenAmount);

            if (!check) {
                TransferHelper.safeTransfer(
                    address(depositToken),
                    msg.sender,
                    depositTokenAmount
                );
            }

            if (MINT_AUTOCOMPOUND_TOKEN) {
                uint256 supply = autoCompoundToken.tokenMintedStrategies();
                uint256 maxSupply = autoCompoundToken.MAX_SUPPLY_STRATEGIES();
                UserInfo storage user = userInfo[msg.sender];
                updatePool(user.amount, user.rewardDebt, supply, maxSupply);
                require(
                    user.amount >= amount,
                    "SingleTokenRewardLPMining::_withdraw: Can't withdraw this much amount"
                );
                user.amount -= uint128(amount);
                supply = autoCompoundToken.tokenMintedStrategies();
                if (maxSupply != supply) {
                    user.rewardDebt = uint128(
                        (user.amount * autoCompoundTokenPerShare) / 1e12
                    );
                }
            }

            _burn(msg.sender, amount);
            totalDeposits -= depositTokenAmount;
            emit Withdraw(msg.sender, depositTokenAmount);
        } else {
            require(
                false,
                "SingleTokenRewardLPMining::_withdraw: withdraw amount can,t be zero"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../../libraries/TransferHelper.sol";
import "../../interfaces/IRouter.sol";
import "../../interfaces/IERC20AutoCompound.sol";
import "../../interfaces/IQuickSwapStrategy.sol";
import "../../interfaces/IERC20.sol";

abstract contract QuickSwapStrategy is
    Ownable,
    ReentrancyGuard,
    IQuickSwapStrategy
{
    // Info of each user.
    struct UserInfo {
        uint128 amount; // How many LP tokens the user has provided.
        uint128 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of autoCompoundTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * autoCompoundTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `autoCompoundTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    IRouter public router;
    IERC20AutoCompound public constant autoCompoundToken =
        IERC20AutoCompound(0x12e9a9dcDc8f276c71524Ddd102343525ddAbB26);
    address public constant acStakingContract =
        0x451C4fac7faA4217224b1de067Ef13B7031731C9;
    // IERC20AutoCompound public autoCompoundToken;
    // address public acStakingContract;
    address public quick;
    address public WETH;

    address public ops;
    address public treasury;

    uint256 public ADMIN_FEE_BIPS = 500;
    uint256 public REINVEST_REWARD_BIPS = 300;
    uint256 internal constant BIPS_DIVISOR = 10000;
    uint256 internal constant SLIPPAGE_DIVISOR = 1000;
    uint256 internal constant UINT_MAX = type(uint256).max;
    uint256 lastRewardBlock; // Last block number that autoCompoundTokens distribution occurs.
    uint256 public autoCompoundTokenPerShare; // Accumulated autoCompoundTokens per share, times 1e12. See below.
    // autoCompoundToken tokens created per block.
    uint256 public autoCompoundTokenPerBlock;
    // Bonus muliplier for early autoCompoundToken makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The block number when autoCompoundToken mining starts.
    uint256 public startBlock;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    bool public REQUIRE_REINVEST_BEFORE_DEPOSIT;
    bool public MINT_AUTOCOMPOUND_TOKEN;
    // uint256 public MIN_TOKENS_TO_REINVEST_BEFORE_DEPOSIT = 20;

    string public name = "AutocompoundStrategy";
    string public symbol = "ACS";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public totalDeposits;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;

    mapping(address => uint256) public nonces;

    constructor() {}

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * It is recommended to use increaseAllowance and decreaseAllowance instead
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint256).max) {
            require(
                spenderAllowance >= amount,
                "QuickSwapStartegy::transferFrom: transfer amount exceeds allowance"
            );
            uint256 newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Revoke token allowance
     * @dev Restricted to avoid griefing attacks
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender)
        external
        onlyOwner
    {
        TransferHelper.safeApprove(token, spender, 0);
    }

    /**
     * @notice Update admin fee
     * @dev Total fees cannot be greater than BIPS_DIVISOR (100%)
     * @param newValue specified in BIPS
     */
    function updateAdminFee(uint256 newValue) external onlyOwner {
        require(
            newValue + ADMIN_FEE_BIPS <= BIPS_DIVISOR,
            "QuickSwapStrategy::updateAdminFee: admin fee too high"
        );
        emit UpdateAdminFee(ADMIN_FEE_BIPS, newValue);
        ADMIN_FEE_BIPS = newValue;
    }

    /**
     * @notice Update reinvest reward
     * @dev Total fees cannot be greater than BIPS_DIVISOR (100%)
     * @param newValue specified in BIPS
     */
    function updateReinvestReward(uint256 newValue) external onlyOwner {
        require(
            newValue + ADMIN_FEE_BIPS <= BIPS_DIVISOR,
            "QuickSwapStrategy::updateReinvestReward : reinvest reward too high"
        );
        emit UpdateReinvestReward(REINVEST_REWARD_BIPS, newValue);
        REINVEST_REWARD_BIPS = newValue;
    }

    /**
     * @notice Toggle requirement to reinvest before deposit
     */
    function updateRequireReinvestBeforeDeposit() external onlyOwner {
        REQUIRE_REINVEST_BEFORE_DEPOSIT = !REQUIRE_REINVEST_BEFORE_DEPOSIT;
        emit UpdateRequireReinvestBeforeDeposit(
            REQUIRE_REINVEST_BEFORE_DEPOSIT
        );
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAmount > 0,
            "QuickSwapStrategy::recoverERC20: amount too low"
        );
        TransferHelper.safeTransfer(tokenAddress, msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Recover recoverNativeAsset from contract
     * @param amount amount
     */
    function recoverNativeAsset(uint256 amount) external onlyOwner {
        require(
            amount > 0,
            "QuickSwapStrategy::recoverNativeAsset: amount too low"
        );
        TransferHelper.safeTransferETH(payable(msg.sender), amount);
        emit Recovered(address(0), amount);
    }

    /**
     * @notice Function to update autocompound token
     * @param multiplierNumber multiplier that can increase or decrease autocompound minting on withdraw
     */

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    /**
     * @notice Function to update minimum tokens to to be minted
     */

    function mintAutocompoundTokens() external onlyOwner {
        MINT_AUTOCOMPOUND_TOKEN = !MINT_AUTOCOMPOUND_TOKEN;
    }

    /**
     * @notice Function to update autocompound token minting per block
     * @param _autoCompoundTokenPerBlock amount autocompound token to mint per block
     */

    function updateAutoCompoundTokenPerBlock(uint256 _autoCompoundTokenPerBlock)
        external
        onlyOwner
    {
        autoCompoundTokenPerBlock = _autoCompoundTokenPerBlock;
    }

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param amount Amount of tokens to deposit
     */

    function deposit(uint256 amount) external virtual {}

    /**
     * @notice Withdraw LP tokens by redeeming receipt tokens
     * @param amount Amount of receipt tokens to redeem
     */

    function withdraw(uint256 amount) external virtual {}

    /**
     * @notice Function to receive recoverNativeAsset
     */

    receive() external payable {}

    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint256 amount)
        public
        view
        returns (uint256)
    {
        if (totalSupply * totalDeposits == 0) {
            return amount;
        }
        return (amount * totalSupply) / totalDeposits;
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount)
        public
        view
        returns (uint256)
    {
        if (totalSupply * totalDeposits == 0) {
            return 0;
        }
        return (amount * totalDeposits) / totalSupply;
    }

    function updatePool(
        uint256 amount,
        uint256 rewardDebt,
        uint256 supply,
        uint256 maxSupply
    ) internal {
        if (block.number <= lastRewardBlock || maxSupply == supply) {
            return;
        }
        uint256 lpSupply = totalDeposits;
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);

        uint256 autoCompoundTokenReward = multiplier *
            autoCompoundTokenPerBlock;

        autoCompoundTokenPerShare =
            autoCompoundTokenPerShare +
            ((autoCompoundTokenReward * 1e12) / lpSupply);

        lastRewardBlock = block.number;
        uint256 pending = ((amount * autoCompoundTokenPerShare) / 1e12) -
            rewardDebt;

        if (pending > 0) {
            uint256 amountToMint;
            if (pending + supply <= maxSupply) {
                amountToMint = pending;
            } else {
                amountToMint = (pending + supply) - maxSupply;
                amountToMint = pending - amountToMint;
            }
            if (amountToMint > 0) {
                autoCompoundToken.mint(msg.sender, amountToMint);
            }
        }
    }

    /**
     * @dev Throws if called by smart contract
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "QuickSwapStrategy::onlyEOA: onlyEOA");
        _;
    }

    /**
     * @dev Throws if called by smart contract
     */
    modifier onlyOps() {
        require(msg.sender == ops, "QuickSwapStrategy::onlyOps: onlyOps");
        _;
    }

    function _convertRewardTokensToAC(uint256 amount)
        internal
        virtual
        returns (uint256)
    {
        require(
            amount > 0,
            "QuickSwapStrategy::_convertRewardTokensToAC: amount too low"
        );

        // swap to depositToken
        address[] memory path0 = new address[](3);
        path0[0] = quick;
        path0[1] = WETH;
        path0[2] = address(autoCompoundToken);

        uint256[] memory amountsOutToken0 = router.getAmountsOut(amount, path0);
        uint256 amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
        if (amountOutToken0 > 0) {
            router.swapExactTokensForTokens(
                amount,
                amountOutToken0,
                path0,
                acStakingContract,
                block.timestamp + 1800
            );
        }

        return amountOutToken0;
    }

    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "QuickSwapStartegy::_approve: owner zero address"
        );
        require(
            spender != address(0),
            "QuickSwapStartegy::_approve: spender zero address"
        );
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(
        address from,
        address to,
        uint256 value
    ) internal {
        require(
            to != address(0),
            "QuickSwapStartegy:: _transferTokens: cannot transfer to the zero address"
        );

        require(
            balances[from] >= value,
            "QuickSwapStartegy:: _transferTokens: transfer exceeds from balance"
        );

        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(
            balances[from] >= value,
            "QuickSwapStartegy::_burn: burn amount exceeds from balance"
        );
        balances[from] = balances[from] - value;
        require(
            totalSupply >= value,
            "QuickSwapStartegy::_burn: burn amount exceeds total supply"
        );
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        return (_to - _from) * BONUS_MULTIPLIER;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./IERC20.sol";


interface IPair is IERC20 {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function mint(address to) external returns (uint256 liquidity);

    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./IERC20.sol";

interface IDragonLiar is IERC20 {
    function leave(uint256 _dQuickAmount) external;

    function QUICKBalance(address _account)
        external
        view
        returns (uint256 quickAmount_);

    function dQUICKForQUICK(uint256 _dQuickAmount)
        external
        view
        returns (uint256 quickAmount_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IRouter {
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

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20AutoCompound {
    function mint(address to, uint256 amount) external;

    function MAX_SUPPLY_STRATEGIES() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function tokenMintedStrategies() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IQuickSwapStrategy {
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Reinvest(uint256 newTotalDeposits, uint256 newTotalSupply);
    event Recovered(address token, uint256 amount);
    event UpdateAdminFee(uint256 oldValue, uint256 newValue);
    event UpdateReinvestReward(uint256 oldValue, uint256 newValue);
    // event UpdateMinTokensToReinvest(uint256 oldValue, uint256 newValue);
    event UpdateRequireReinvestBeforeDeposit(bool newValue);
    // event UpdateMinTokensToReinvestBeforeDeposit(
    //     uint256 oldValue,
    //     uint256 newValue
    // );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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