// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "interfaces/IRegistry.sol";
import "interfaces/IWallet.sol";
import "interfaces/IDistribution.sol";
import "interfaces/IVault.sol";
import "interfaces/IMemory.sol";
import "./libraries/TransferHelper.sol";

contract EthalendVaultsQuickSwapStrategy is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How much asset the user has provided.
        uint256 lpAmount; //How many LP tokens have been added for the user
        uint256 rewardTokensDebt; // Reward Tokens debited.
        uint256 ethaTokensDebt; // Etha Tokens debited.
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewards
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward tokens = (user.amount * pool.accRewardTokensPerShare) - user.rewardTokensDebt
        //   pending etha tokens = (user.amount * pool.accEthaTokensPerShare) - user.ethaTokensDebt
        //
        // Whenever a user deposits or withdraws asset tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardTokensPerShare` and `accEthaTokensPerShare` gets updated.
        //   2. User receives the pending rewards both etha and the rewardToken sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. Any added LPs update the user's lpAmount.
        //   5. User's `rewardTokensDebt` and `ethaTokensDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 accRewardTokensPerShare; // Accumulated wmatic/wbtc/link per share (depends on the rewardToken), times 1e12.
        uint256 accEthaTokensPerShare; // Accumulated etha per share, times 1e12.
    }

    // Contracts used by Ethalend.
    struct EthalendContracts {
        IRegistry registry; //ethalend registry contract
        address curvePool; // curvePool conntract address
        address transferLogic; //contract address used by ethalend underneath to transfer funds to ethalend before deposit.
        address curveLogic; //contract address used by ethalend underneath to swap/addLiquidity for curve pools.
        address quickSwapLogic; //contract address used by ethalend underneath to swap/addLiquidity to quickswap.
        address vaultLogic; //contract address used by ethalend underneath to deposit funds into vaults
        address eVault; //contract address used by ethalend. This is the vault address so if the reward token is weth, this will be weth Evault address
    }

    struct RewardsTransferMode {
        bool isEthaTokenEnabled;
        bool isRewardTokenEnabled;
    }

    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;

    PoolInfo public poolInfo;

    EthalendContracts public ethalendContracts;

    RewardsTransferMode public rewardsTransferMode;

    // whitelisted liquidityManagers
    mapping(address => bool) public liquidityManagers;

    IWallet public ethaWallet;
    IMemory public memoryContract; //This is the memory contract address used to retrieve variables stored in memory

    IERC20 public asset; //same which was used in staking pool
    IERC20 public secondaryAsset; //the token used as tokenB when providing liquidity.
    IERC20 public rewardToken; //wmatic/wbtc/link
    IERC20 public etha;

    address public feeAddress;
    uint256 public strategyWithdrawalFeeBP = 10; // 0.1% in ethalend. StrategyWithdraw fee in basis points. This is respective to ethalend and the token so there is no use of saving this in poolInfo
    uint256 public strategyDepositFeeBP = 0;
    uint256 public totalInputTokensStaked = 0;

    event LiquidityManagerStatus(address liquidityManager, bool status);
    event StrategyPoolUpdated(
        uint256 indexed accRewardTokensPerShare,
        uint256 indexed accEthaTokensPerShare
    );
    event StrategyDeposit(address indexed user, uint256 amount);
    event StrategyWithdraw(address indexed user, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed feeAddress);
    event RescueAsset(address liquidityManager, uint256 rescuedAssetAmount);

    modifier ensureNonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "No zero address");
        _;
    }

    modifier ensureValidTokenAddress(address _token) {
        require(_token != address(0), "No zero address");
        require(_token == address(asset), "Invalid token for deposit/withdraw");
        _;
    }

    modifier ensureValidLiquidityManager(address addressToCheck) {
        require(addressToCheck != address(0), "No zero address");
        require(liquidityManagers[addressToCheck], "Invalid Liquidity Manager");
        _;
    }

    /**
     * @notice Creates a new Ethalend Vault Strategy Contract
     * @param _asset usdc/usdt/dai token address. This is the input token for the pool and the vault.
     * @param _secondaryAsset This is the secondary asset which is introduced as a pair with the vaults.
     * @param _rewardToken Reward Token is the reward given out by the vaults (wbtc, wmatic, link)
     * @param _etha Etha Token Address
     * @param _registry; //ethalend registry contract
     * @param _curvePool; //curve pool contract used for swapping by curve
     * @param _transferLogic; //contract address used by ethalend underneath to transfer funds to ethalend.
     * @param _curveLogic; //contract address used by ethalend underneath to swap for curve pools.
     * @param _quickSwapLogic; //contract address used by ethalend underneath to swap/addLiquidity to quickswap.
     * @param _vaultLogic; //contract address used by ethalend underneath to deposit/withdraw funds for vaults
     * @param _eVault; //contract address used by ethalend which is the vault address so if the reward token is weth, this will be weth Evault address
     * @param _feeAddress //fee address used for transferring residue or unused tokens
     * @dev deployer of contract is set as owner
     */
    constructor(
        IERC20 _asset,
        IERC20 _secondaryAsset,
        IERC20 _rewardToken,
        IERC20 _etha,
        IRegistry _registry,
        address _curvePool,
        address _transferLogic,
        address _curveLogic,
        address _quickSwapLogic,
        address _vaultLogic,
        address _eVault,
        address _feeAddress
    ) {
        asset = _asset;
        secondaryAsset = _secondaryAsset;
        rewardToken = _rewardToken;
        etha = _etha;
        ethalendContracts.registry = _registry;
        ethalendContracts.curvePool = _curvePool;
        ethalendContracts.transferLogic = _transferLogic;
        ethalendContracts.curveLogic = _curveLogic;
        ethalendContracts.quickSwapLogic = _quickSwapLogic;
        ethalendContracts.vaultLogic = _vaultLogic;
        ethalendContracts.eVault = _eVault;
        feeAddress = _feeAddress;
        ethaWallet = IWallet(ethalendContracts.registry.deployWallet());
        require(address(ethaWallet) != address(0), "Etha Wallet not deployed");
        IERC20(asset).approve(address(ethaWallet), uint256(-1));
        memoryContract = IMemory(ethalendContracts.registry.memoryAddr());
        rewardsTransferMode.isEthaTokenEnabled = true;
        rewardsTransferMode.isRewardTokenEnabled = false;
    }

    /**
     * @notice Updates the liquidity manager for the strategy
     * @param _liquidityManager Address of the liquidity manager
     * @param _status status is if we need to enable/disable this liquidity manager
     * @dev Only owner can call and update the liquidity manager
     */
    function updateLiquidityManager(address _liquidityManager, bool _status)
        external
        onlyOwner
        ensureNonZeroAddress(_liquidityManager)
    {
        updatePool();
        liquidityManagers[_liquidityManager] = _status;
        emit LiquidityManagerStatus(_liquidityManager, _status);
    }

    /**
     * @notice Updates the secondary asset of the strategy. Should not be used since the funds will remain in the first vault
     * @param _secondaryAsset Address of the secondary asset
     * @dev Only owner can call and update the secondary asset
     */
    function updateSecondaryAsset(IERC20 _secondaryAsset)
        external
        onlyOwner
        ensureNonZeroAddress(address(_secondaryAsset))
    {
        updatePool();
        secondaryAsset = _secondaryAsset;
    }

    /**
     * @notice Updates the registry contract of the ethalend ecosystem.
     * @param _registry Address of the registry
     * @dev Only owner can call and update the registry contract of the ethalend registry
     */
    function updateRegistry(IRegistry _registry)
        external
        onlyOwner
        ensureNonZeroAddress(address(_registry))
    {
        updatePool();
        ethalendContracts.registry = _registry;
    }

    /**
     * @notice Updates the transferLogic contract of the ethalend ecosystem.
     * @param _transferLogic Address of the transferLogic contract
     * @dev Only owner can call and update the transferLogic contract of the ethalend ecosystem
     */
    function updateTransferLogicContract(address _transferLogic)
        external
        onlyOwner
        ensureNonZeroAddress(_transferLogic)
    {
        updatePool();
        ethalendContracts.transferLogic = _transferLogic;
    }

    /**
     * @notice Updates the curveLogic contract of the ethalend ecosystem.
     * @param _curveLogic Address of the curveLogic contract
     * @dev Only owner can call and update the curveLogic contract of the ethalend ecosystem
     */
    function updateCurveLogicContract(address _curveLogic)
        external
        onlyOwner
        ensureNonZeroAddress(_curveLogic)
    {
        updatePool();
        ethalendContracts.curveLogic = _curveLogic;
    }

    /**
     * @notice Updates the curvePool contract of the ethalend ecosystem.
     * @param _curvePool Address of the curvePool contract
     * @dev Only owner can call and update the curvePool contract of the ethalend ecosystem
     */
    function updateCurvePoolContract(address _curvePool)
        external
        onlyOwner
        ensureNonZeroAddress(_curvePool)
    {
        updatePool();
        ethalendContracts.curvePool = _curvePool;
    }

    /**
     * @notice Updates the quickSwapLogic contract of the ethalend ecosystem.
     * @param _quickSwapLogic Address of the quickSwapLogic contract
     * @dev Only owner can call and update the quickSwapLogic contract of the ethalend ecosystem
     */
    function updateEthalendQuickSwapLogicContract(address _quickSwapLogic)
        external
        onlyOwner
        ensureNonZeroAddress(_quickSwapLogic)
    {
        updatePool();
        ethalendContracts.quickSwapLogic = _quickSwapLogic;
    }

    /**
     * @notice Updates the vaultLogic contract of the ethalend ecosystem.
     * @param _vaultLogic Address of the vaultLogic contract
     * @dev Only owner can call and update the vaultLogic contract of the ethalend ecosystem
     */
    function updateEthalendVaultLogicContract(address _vaultLogic)
        external
        onlyOwner
        ensureNonZeroAddress(_vaultLogic)
    {
        updatePool();
        ethalendContracts.vaultLogic = _vaultLogic;
    }

    /**
     * @notice Updates the eVault contract of the ethalend ecosystem. This is the exact vault dependent on the rewardToken given out.
     * @param _eVault Address of the eVault contract
     * @dev Only owner can call and update the eVault contract of the ethalend ecosystem
     */
    function updateEthalendEVaultContract(address _eVault)
        external
        onlyOwner
        ensureNonZeroAddress(_eVault)
    {
        updatePool();
        ethalendContracts.eVault = _eVault;
    }

    /**
     * @notice Can be used by the owner to enable/disable mode for accumulated etha rewards being sent to user
     * @param _isEthaTokenEnabled Boolean flag if we need to enable/disable the reward transfer mode for etha tokens
     * @dev Only owner can call and update this mode.
     */
    function updateEthaTokenRewardsTransferMode(bool _isEthaTokenEnabled) external onlyOwner {
        updatePool();
        rewardsTransferMode.isEthaTokenEnabled = _isEthaTokenEnabled;
    }

    /**
     * @notice Can be used by the owner to enable/disable mode for accumulated reward token rewards being sent to user
     * @param _isRewardTokenEnabled Boolean flag if we need to enable/disable the reward transfer mode for reward tokens
     * @dev Only owner can call and update this mode.
     */
    function updateRewardTokenRewardsTransferMode(bool _isRewardTokenEnabled) external onlyOwner {
        updatePool();
        rewardsTransferMode.isRewardTokenEnabled = _isRewardTokenEnabled;
    }

    /**
     * @notice Can be used by the owner to update the address for reward token
     * @param _rewardToken ERC20 address for the new reward token
     * @dev Only owner can call and update the rewardToken.
     */
    function updateRewardToken(IERC20 _rewardToken)
        external
        onlyOwner
        ensureNonZeroAddress(address(_rewardToken))
    {
        updatePool();
        rewardToken = _rewardToken;
    }

    /**
     * @notice Can be used by the owner to update the address for etha token
     * @param _etha ERC20 address for the etha token
     * @dev Only owner can call and update the etha token address.
     */
    function updateETHA(IERC20 _etha) external onlyOwner ensureNonZeroAddress(address(_etha)) {
        updatePool();
        etha = _etha;
    }

    /**
     * @notice Can be used by the owner to update the withdrawal fee based on the ethalend contracts. Should not be modified unless ethalend updates it.
     * @param _strategyWithdrawalFeeBP New withdrawal fee of the ethalend vault contracts in basis points
     * @dev Only owner can call and update the ethalend withdrawal fee.
     */
    function updateStrategyWithdrawalFee(uint256 _strategyWithdrawalFeeBP) external onlyOwner {
        updatePool();
        strategyWithdrawalFeeBP = _strategyWithdrawalFeeBP;
    }

    /**
     * @notice Can be used by the owner to update the deposit fee based on the ethalend contracts. Currently there is no deposit fee
     * @param _strategyDepositFeeBP New deposit fee of the ethalend vault contracts in basis points
     * @dev Only owner can call and update the ethalend deposit fee.
     */
    function updateStrategyDepositFee(uint256 _strategyDepositFeeBP) external onlyOwner {
        updatePool();
        strategyDepositFeeBP = _strategyDepositFeeBP;
    }

    /**
     * @notice Update fee address
     * @param _feeAddress New fee address for receiving the residue rewards
     * @dev Only owner can update the fee address
     */
    function setFeeAddress(address _feeAddress)
        external
        ensureNonZeroAddress(_feeAddress)
        onlyOwner
    {
        updatePool();
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    /**
     * @notice transfer accumulated asset. Shouldn't be called since this will transfer community's residue asset to feeAddress
     * @param _withdrawFromEthaWallet true if rewards need to be withdrawn from ethawallet.
     * @dev Only owner can call and claim the residue assets
     */
    function transferAssetResidue(bool _withdrawFromEthaWallet) external onlyOwner {
        updatePool();
        if (_withdrawFromEthaWallet) {
            _withdrawTokenFromEthaWallet(address(asset), asset.balanceOf(address(ethaWallet)));
        }
        uint256 assetResidue = asset.balanceOf(address(this));
        TransferHelper.safeTransfer(address(asset), feeAddress, assetResidue);
    }

    /**
     * @notice transfer accumulated secodary asset. Shouldn't be called since this will transfer community's residue secondary asset to feeAddress
     * @param _withdrawFromEthaWallet true if rewards need to be withdrawn from ethawallet.
     * @dev Only owner can call and claim the secondary assets residue
     */
    function transferSecondaryAssetResidue(bool _withdrawFromEthaWallet) external onlyOwner {
        updatePool();
        if (_withdrawFromEthaWallet) {
            _withdrawTokenFromEthaWallet(
                address(secondaryAsset),
                secondaryAsset.balanceOf(address(ethaWallet))
            );
        }
        uint256 secondaryAssetResidue = secondaryAsset.balanceOf(address(this));
        TransferHelper.safeTransfer(address(secondaryAsset), feeAddress, secondaryAssetResidue);
    }

    /**
     * @notice transfer accumulated reward tokens. Shouldn't be called since this will transfer community's reward tokens to feeAddress
     * @dev Only owner can call and claim the reward tokens
     */
    function transferRewardTokenRewards(bool _withdrawFromEthaWallet) external onlyOwner {
        updatePool();
        if (_withdrawFromEthaWallet) {
            _withdrawTokenFromEthaWallet(
                address(rewardToken),
                rewardToken.balanceOf(address(ethaWallet))
            );
        }
        uint256 rewardTokenRewards = rewardToken.balanceOf(address(this));
        TransferHelper.safeTransfer(address(rewardToken), feeAddress, rewardTokenRewards);
    }

    /**
     * @notice transfer etha rewards tokens. Shouldn't be called since this will transfer community's etha to feeAddress.
     * @dev Only owner can call and claim the etha reward tokens
     */
    function transferEthaRewards(bool _withdrawFromEthaWallet) external onlyOwner {
        updatePool();
        if (_withdrawFromEthaWallet) {
            _withdrawTokenFromEthaWallet(address(etha), etha.balanceOf(address(ethaWallet)));
        }
        uint256 ethaTokenRewards = etha.balanceOf(address(this));
        TransferHelper.safeTransfer(address(etha), feeAddress, ethaTokenRewards);
    }

    /**
     * @dev View function to see pending etha rewards.
     */
    function getPendingEthaRewards() public view returns (uint256 pendingEthaRewards) {
        IDistribution distribution = IDistribution(IVault(ethalendContracts.eVault).distribution());
        pendingEthaRewards = distribution.earned(address(ethaWallet));
    }

    /**
     * @dev View function to get total LP staked in vaults.
     */
    function getTotalLPStakedInVaults() public view returns (uint256 totalLPStaked) {
        IVault vault = IVault(ethalendContracts.eVault);
        totalLPStaked = vault.balanceOf(address(ethaWallet));
    }

    /**
     * @dev View function to see pending reward tokens generated.
     */
    function getTotalRewardTokensGenerated()
        public
        view
        returns (uint256 totalRewardTokensGenerated)
    {
        totalRewardTokensGenerated = IVault(ethalendContracts.eVault).unclaimedProfit(
            address(ethaWallet)
        );
    }

    /**
     * @dev function to claim rewards (etha and rewardTokens to ethawallet)
     */
    function _claimRewardsToEthaWallet() internal {
        //These steps are for building the claim tx.
        address[] memory targets = new address[](1);
        bytes[] memory datas = new bytes[](1);

        targets[0] = ethalendContracts.vaultLogic;
        datas[0] = abi.encodeWithSignature(
            "claim(address,uint256)",
            address(ethalendContracts.eVault),
            0 //setId. Is zero since it doesn't matter
        );

        ethaWallet.execute(targets, datas);
    }

    // function to withdraw rewards (rewardTokens and etha tokens) from ethaWallet to contract.
    function _withdrawRewardsFromEthaWallet() internal {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(ethaWallet)); //withdraw full available balance of the reward tokens
        _withdrawTokenFromEthaWallet(address(rewardToken), rewardTokenBalance);
        uint256 ethaTokenBalance = etha.balanceOf(address(ethaWallet)); //withdraw full available balance of the etha tokens
        _withdrawTokenFromEthaWallet(address(etha), ethaTokenBalance);
    }

    /**
     * @dev function to withdraw token from ethaWallet to strategy contract.
     */
    function _withdrawTokenFromEthaWallet(address _token, uint256 _amountToWithdraw)
        internal
        returns (uint256 withdrawnAmount)
    {
        if (_amountToWithdraw > 0) {
            uint256 initialStrategyBalance = IERC20(_token).balanceOf(address(this));
            address[] memory targets = new address[](1);
            bytes[] memory datas = new bytes[](1);
            targets[0] = ethalendContracts.transferLogic;
            datas[0] = abi.encodeWithSignature(
                "withdraw(address,uint256)",
                _token,
                _amountToWithdraw
            );
            ethaWallet.execute(targets, datas);
            uint256 afterWithdrawStrategyBalance = IERC20(_token).balanceOf(address(this));
            withdrawnAmount = afterWithdrawStrategyBalance.sub(initialStrategyBalance);
            require(withdrawnAmount == _amountToWithdraw, "Invalid withdrawn amount processed");
        }
    }

    // function to deposit asset from contract to Ethalend Vaults.
    function _depositAssetToEthalendVaults(uint256 _amount) internal returns (uint256 lpDeposited) {
        uint256 initialLPBalanceInVaults = getTotalLPStakedInVaults();
        //These steps are for building the lego tx.
        address[] memory targets = new address[](4);
        bytes[] memory datas = new bytes[](4);

        //Step 1 - Transfer asset from strategy to created ethalend wallet.
        targets[0] = ethalendContracts.transferLogic;
        datas[0] = abi.encodeWithSignature("deposit(address,uint256)", asset, _amount);

        //Step 2- Swap half of asset to secondary asset using curveLogic contract
        targets[1] = ethalendContracts.curveLogic;
        datas[1] = abi.encodeWithSignature(
            "swap(address,address,address,uint256,uint256,uint256,uint256)",
            ethalendContracts.curvePool,
            asset,
            secondaryAsset,
            _amount.div(2),
            0, //getId
            1, //setId (for setting in memory where amount of B tokens are stored)
            1 //divider which is 1 by default
        );

        //Step 3 - Add Liquidity for asset and secondary asset using quickSwapLogic contract
        targets[2] = ethalendContracts.quickSwapLogic;
        datas[2] = abi.encodeWithSignature(
            "addLiquidity(address,address,uint256,uint256,uint256,uint256,uint256,uint256)",
            address(asset),
            address(secondaryAsset),
            _amount.div(2),
            0, //since this is fetched from the memory i.e. getId2
            0, //getId is 0, since amt tokenA is provided
            1, //getId2 is 1 since the amount swapped is stored at id - 1 in memory contract
            1, //setId is 1 since this is for the no.of lp tokens that are received and stored in memory
            1 //divider which is 1 by default
        );

        //Step 4 - Add Received LP Tokens in the respective e-vault contract through the vault logic contract
        targets[3] = ethalendContracts.vaultLogic;
        datas[3] = abi.encodeWithSignature(
            "deposit(address,uint256,uint256)",
            address(ethalendContracts.eVault),
            0, //can add this as anything since this is fetched from the memory
            1 //getId2 this is memory id for where the lp tokens are stored
        );

        ethaWallet.execute(targets, datas);
        uint256 finalLPBalanceInVaults = getTotalLPStakedInVaults();
        lpDeposited = memoryContract.getUint(1); //since this is for the no.of lp tokens that are received
        require(
            lpDeposited == finalLPBalanceInVaults.sub(initialLPBalanceInVaults),
            "Invalid LP amount deposited"
        );
    }

    // function to withdraw asset from Ethalend Vaults to ethawallet.
    function _withdrawAssetFromEthalendVaults(uint256 _lpAmountToWithdraw)
        internal
        returns (uint256 assetWithdrawnInEthaWallet)
    {
        uint256 initialAssetBalanceInEthaWallet = asset.balanceOf(address(ethaWallet));
        //These steps are for building the lego tx.
        address[] memory targets = new address[](3);
        bytes[] memory datas = new bytes[](3);

        //Step 1 - Remove LP tokens based on the number of tokens deposited.
        targets[0] = ethalendContracts.vaultLogic;
        datas[0] = abi.encodeWithSignature(
            "withdraw(address,uint256,uint256,uint256)",
            address(ethalendContracts.eVault),
            _lpAmountToWithdraw,
            0, //getId
            1 //setId (for setting in memory where amount of LP tokens removed are stored)
        );

        //Step 2- Remove Liquidity for these LP tokens

        targets[1] = ethalendContracts.quickSwapLogic;
        datas[1] = abi.encodeWithSignature(
            "removeLiquidity(address,address,address,uint256,uint256,uint256,uint256,uint256)",
            address(asset),
            address(secondaryAsset),
            address(IVault(ethalendContracts.eVault).underlying()),
            0, //amount of LP. Here zero since it will take from memory
            1, //getId for where LP tokens are stored
            1, //setId (for setting in memory where amount of asset tokens are stored)
            2, //setId2 (for setting in memory where amount of secondary asset tokens are stored)
            1 //divider which is 1 by default
        );

        //Step 3 - Swap secondary asset received to primary asset. This step is trickey. Need to know if we need to use quickswap to remove liquidity or curve.
        targets[2] = ethalendContracts.curveLogic;
        datas[2] = abi.encodeWithSignature(
            "swap(address,address,address,uint256,uint256,uint256,uint256)",
            ethalendContracts.curvePool,
            address(secondaryAsset),
            address(asset),
            0, //amount of source token. Here zero since it will take from memory
            2, //getId is 2 since the amount of tokenB is stored at 12 in memory contract
            3, //setId is 3. This is for the amount of asset received after swapping.
            1 //divider which is 1 by default
        );

        ethaWallet.execute(targets, datas);

        uint256 finalAssetBalanceInEthaWallet = asset.balanceOf(address(ethaWallet));
        assetWithdrawnInEthaWallet = memoryContract.getUint(1).add(memoryContract.getUint(3)); //swapped amout plus the amount received by removing liquidity

        //consider again if this is needed
        require(
            assetWithdrawnInEthaWallet ==
                finalAssetBalanceInEthaWallet.sub(initialAssetBalanceInEthaWallet),
            "Invalid amount of asset withdrawn"
        );
    }

    /**
     * @notice View function to see pending rewards on frontend.
     * @param _user Address of the user to see his pending rewards
     */
    function getPendingRewards(address _user)
        external
        view
        returns (uint256 pendingRewardTokens, uint256 pendingEthaTokens)
    {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokensPerShare = pool.accRewardTokensPerShare;
        uint256 accEthaTokensPerShare = pool.accEthaTokensPerShare;

        uint256 totalRewardTokensGenerated = getTotalRewardTokensGenerated();
        uint256 pendingEthaRewards = getPendingEthaRewards();
        uint256 totalLPStaked = getTotalLPStakedInVaults();

        if (totalLPStaked != 0) {
            if (rewardsTransferMode.isRewardTokenEnabled) {
                accRewardTokensPerShare = accRewardTokensPerShare.add(
                    totalRewardTokensGenerated.mul(1e12).div(totalLPStaked)
                );
            }
            if (rewardsTransferMode.isEthaTokenEnabled) {
                accEthaTokensPerShare = accEthaTokensPerShare.add(
                    pendingEthaRewards.mul(1e12).div(totalLPStaked)
                );
            }
        }
        pendingRewardTokens = user.lpAmount.mul(accRewardTokensPerShare).div(1e12).sub(
            user.rewardTokensDebt
        );
        pendingEthaTokens = user.lpAmount.mul(accEthaTokensPerShare).div(1e12).sub(
            user.ethaTokensDebt
        );
    }

    /**
     * @notice Update reward variables of the pool to be up-to-date. This also claims the rewards generated form vaults
     */
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        uint256 totalLPStaked = getTotalLPStakedInVaults();

        if (totalLPStaked == 0) {
            return;
        }

        uint256 totalRewardTokensGenerated = getTotalRewardTokensGenerated();
        uint256 pendingEthaRewards = getPendingEthaRewards();

        if (totalRewardTokensGenerated > 0 || pendingEthaRewards > 0) {
            _claimRewardsToEthaWallet();
            _withdrawRewardsFromEthaWallet();
        }

        if (rewardsTransferMode.isRewardTokenEnabled) {
            pool.accRewardTokensPerShare = pool.accRewardTokensPerShare.add(
                totalRewardTokensGenerated.mul(1e12).div(totalLPStaked)
            );
        }

        if (rewardsTransferMode.isEthaTokenEnabled) {
            pool.accEthaTokensPerShare = pool.accEthaTokensPerShare.add(
                pendingEthaRewards.mul(1e12).div(totalLPStaked)
            );
        }
        emit StrategyPoolUpdated(pool.accRewardTokensPerShare, pool.accEthaTokensPerShare);
    }

    /**
     * @notice function to deposit asset to ethalend vaults.
     * @param _token Address of the token. (Should be the same as the asset token)
     * @param _amount amount of asset token deposited.
     * @param _user Address of the user who is depositing the asset
     * @dev Can only be called from the liquidity manager
     */
    function deposit(
        address _token,
        uint256 _amount,
        address _user
    )
        external
        ensureValidTokenAddress(_token)
        ensureNonZeroAddress(_user)
        ensureValidLiquidityManager(msg.sender)
        nonReentrant
        returns (uint256 depositedAmount)
    {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        updatePool();
        _transferPendingRewards(_user);
        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            uint256 lpDeposited = _depositAssetToEthalendVaults(_amount);
            user.lpAmount = user.lpAmount.add(lpDeposited);
            depositedAmount = _amount;
        }
        totalInputTokensStaked = totalInputTokensStaked.add(_amount);
        user.ethaTokensDebt = user.lpAmount.mul(pool.accEthaTokensPerShare).div(1e12);
        user.rewardTokensDebt = user.lpAmount.mul(pool.accRewardTokensPerShare).div(1e12);
        emit StrategyDeposit(_user, _amount);
    }

    /**
     * @notice function to withdraw asset from ethalend vaults.
     * @param _token Address of the token. (Should be the same as the asset token)
     * @param _amount amount of asset token the user wants to withdraw.
     * @param _user Address of the user who is withdrawing the asset
     * @dev Can only be called from the liquidity manager
     */
    function withdraw(
        address _token,
        uint256 _amount,
        address _user
    )
        external
        ensureValidTokenAddress(_token)
        ensureNonZeroAddress(_user)
        ensureValidLiquidityManager(msg.sender)
        nonReentrant
        returns (uint256 withdrawnAmount)
    {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        _transferPendingRewards(_user);
        if (_amount > 0) {
            uint256 lpAmountToWithdraw = _amount.mul(user.lpAmount).div(user.amount);
            user.amount = user.amount.sub(_amount);
            user.lpAmount = user.lpAmount.sub(lpAmountToWithdraw);
            uint256 assetWithdrawnInEthaWallet = _withdrawAssetFromEthalendVaults(
                lpAmountToWithdraw
            );
            withdrawnAmount = _withdrawTokenFromEthaWallet(
                address(asset),
                assetWithdrawnInEthaWallet
            );
            IERC20(_token).approve(address(msg.sender), withdrawnAmount);
        }
        totalInputTokensStaked = totalInputTokensStaked.sub(_amount);
        user.ethaTokensDebt = user.lpAmount.mul(pool.accEthaTokensPerShare).div(1e12);
        user.rewardTokensDebt = user.lpAmount.mul(pool.accRewardTokensPerShare).div(1e12);
        emit StrategyWithdraw(_user, _amount);
    }

    // Function to transfer pending rewards (rewardToken and ethaToken) to the user.
    function _transferPendingRewards(address _user) internal {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];

        uint256 pendingRewardTokens = user.lpAmount.mul(pool.accRewardTokensPerShare).div(1e12).sub(
            user.rewardTokensDebt
        );
        if (rewardsTransferMode.isRewardTokenEnabled && pendingRewardTokens > 0) {
            TransferHelper.safeTransfer(address(rewardToken), _user, pendingRewardTokens);
        }
        uint256 pendingEthaTokens = user.lpAmount.mul(pool.accEthaTokensPerShare).div(1e12).sub(
            user.ethaTokensDebt
        );
        if (rewardsTransferMode.isEthaTokenEnabled && pendingEthaTokens > 0) {
            TransferHelper.safeTransfer(address(etha), _user, pendingEthaTokens);
        }
    }

    /**
     * @notice function to withdraw all asset and transfer back to liquidity holder.
     * @dev Can only be called from the liquidity manager by the owner
     */
    function rescueFunds(address _token)
        external
        ensureValidTokenAddress(_token)
        ensureValidLiquidityManager(msg.sender)
        returns (uint256 rescuedAssetAmount)
    {
        updatePool();
        uint256 totalLPStaked = getTotalLPStakedInVaults();

        if (totalLPStaked > 0) {
            _withdrawAssetFromEthalendVaults(totalLPStaked);
            _withdrawTokenFromEthaWallet(address(asset), asset.balanceOf(address(ethaWallet)));
            rescuedAssetAmount = asset.balanceOf(address(this));
            asset.approve(address(msg.sender), rescuedAssetAmount);
            emit RescueAsset(msg.sender, rescuedAssetAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title RegistryInterface Interface
 */
interface IRegistry {
    function logic(address logicAddr) external view returns (bool);

    function implementation(bytes32 key) external view returns (address);

    function notAllowed(address erc20) external view returns (bool);

    function deployWallet() external returns (address);

    function wallets(address user) external view returns (address);

    function getFee() external view returns (uint256);

    function getFeeManager() external view returns (address);

    function feeRecipient() external view returns (address);

    function memoryAddr() external view returns (address);

    function distributionContract(address token) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface IWallet {
    event LogMint(address indexed erc20, uint256 tokenAmt);
    event LogRedeem(address indexed erc20, uint256 tokenAmt);
    event LogBorrow(address indexed erc20, uint256 tokenAmt);
    event LogPayback(address indexed erc20, uint256 tokenAmt);
    event LogDeposit(address indexed erc20, uint256 tokenAmt);
    event LogWithdraw(address indexed erc20, uint256 tokenAmt);
    event LogSwap(address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event LogLiquidityRemove(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event VaultDeposit(address indexed erc20, uint256 tokenAmt);
    event VaultWithdraw(address indexed erc20, uint256 tokenAmt);
    event VaultClaim(address indexed erc20, uint256 tokenAmt);
    event DelegateAdded(address delegate);
    event DelegateRemoved(address delegate);
    event Claim(address indexed erc20, uint256 tokenAmt);
    event Staked(address indexed erc20, uint256 tokenAmt);
    event Unstaked(address indexed erc20, uint256 tokenAmt);

    function executeMetaTransaction(bytes memory sign, bytes memory data) external;

    function execute(address[] calldata targets, bytes[] calldata datas) external payable;

    function owner() external view returns (address);

    function registry() external view returns (address);

    function DELEGATE_ROLE() external view returns (bytes32);

    function hasRole(bytes32, address) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IDistribution {
    function stake(address user, uint256 redeemTokens) external;

    function withdraw(address user, uint256 redeemAmount) external;

    function getReward(address user) external;

    function balanceOf(address account) external view returns (uint256);

    function rewardsToken() external view returns (address);

    function earned(address account) external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardRate() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

interface IVault {
    function underlying() external view returns (IERC20Detailed);

    function target() external view returns (IERC20);

    function distribution() external view returns (address);

    function strat() external view returns (address);

    function timelock() external view returns (address payable);

    function balanceOf(address) external view returns (uint256);

    function calcTotalValue() external view returns (uint256);

    function changePerformanceFee(uint256 fee) external;

    function claim() external returns (uint256 claimed);

    function unclaimedProfit(address user) external view returns (uint256);

    function pending(address user) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IMemory {
    function getUint(uint256) external view returns (uint256);

    function setUint(uint256 id, uint256 value) external;

    function getAToken(address asset) external view returns (address);

    function setAToken(address asset, address _aToken) external;

    function getCrToken(address asset) external view returns (address);

    function setCrToken(address asset, address _crToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}