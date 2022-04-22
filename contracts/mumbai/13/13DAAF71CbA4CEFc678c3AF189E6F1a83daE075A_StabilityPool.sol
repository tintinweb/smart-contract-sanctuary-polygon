/**
 *Submitted for verification at polygonscan.com on 2022-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: ICommunityIssuance

interface ICommunityIssuance { 
    
    // --- Events ---
    
    event OrumTokenAddressSet(address _orumTokenAddress);
    event StabilityPoolAddressSet(address _stabilityPoolAddress);
    event TotalOrumIssuedUpdated(uint _totalOrumIssued);

    // --- Functions ---

    function setAddresses(address _orumTokenAddress, address _stabilityPoolAddress) external;

    function issueOrum() external returns (uint);

    function sendOrum(address _account, uint _orumAmount) external;
}

// Part: IERC20

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// Part: IERC2612

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// Part: IPool

// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event oMATICBalanceUpdated(uint _newBalance);
    event USDCBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event oMATICSent(address _to, uint _amount);

    // --- Functions ---
    
    function getoMATIC() external view returns (uint);

    function getUSDCDebt() external view returns (uint);

    function increaseUSDCDebt(uint _amount) external;

    function decreaseUSDCDebt(uint _amount) external;
}

// Part: IPriceFeed

interface IPriceFeed {
    // -- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // ---Function---
    function fetchPrice() external view returns (uint);
}

// Part: IOrumBase

interface IOrumBase {
    function priceFeed() external view returns (IPriceFeed);
}

// Part: IUSDCToken

interface IUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);

    event USDCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// Part: IoMATICToken

interface IoMATICToken is IERC20, IERC2612 { 
    
    // --- Events ---


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// Part: IActivePool

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolUSDCDebtUpdated(uint _USDCDebt);
    event ActivePooloMATICBalanceUpdated(uint oMATIC);
    event SentoMATICActiveVault(address _to,uint _amount );
    event swapoMATICAndSendMATICEvent(address _to,uint _amount);
    event ActivePoolReceivedMATIC(uint _MATIC);

    // --- Functions ---
    function sendoMATIC(IoMATICToken _oMATIC_Token, address _account, uint _amount) external;
    function swapoMATICAndSendMATIC(address _account, uint _amount) external;
    function receiveoMATIC(uint new_coll) external;

}

// Part: IStabilityPool

interface IStabilityPool {
    // Events
    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);
    event StabilityPoolUSDCBalanceUpdated(uint _newBalance);
    event StabilityPoolReceivedMATIC(uint value);
    // Functions
    function setAddresses(
        address _usdcTokenAddress,
        address _borrowerOpsAddress,
        address _oMATICToken,
        address _vaultManagerAddress,
        address _communityIssuanceAddress,
        address _activePoolAddress,
        address _rewardsPoolAddress
    ) external;

    function provideToStabilityPool(uint _amount) external;
    function decreaseLentAmount(uint _amount) external;

    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event SentoMATICStabilityPool(address _to,uint _amount);
    event USDCSent(address _to,uint _amount);

    function allowBorrow() external view returns (bool);

    function withdrawFromStabilityPool(uint _amount) external;

    function sendUSDCtoBorrower(IUSDCToken _usdc_token , address _to, uint _amount) external;

    function offset(uint _debt, uint _coll) external;

    function rewardsOffset(uint _rewards) external;

    function getTotalUSDCDepositsIncludingLent() external view returns (uint);

    function getDepositorMATICGain(address _depositor) external returns (uint);

    function getCompoundedUSDCDeposit(address _depositor) external returns (uint);

    function getDepositorOrumGain(address _depositor) external returns (uint);

    function getUSDCDeposits() external returns (uint);

    function getUSDCinSP() external view returns (uint);

    function getUtilisationRatio() external view returns (uint);
}

// Part: IVaultManager

// Common interface for the Vault Manager.
interface IVaultManager is IOrumBase {
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event USDCTokenAddressChanged(address _newUSDCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oMATICTokenAddressChanged(address _newoMATICTokenAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _USDCGasCompensation);
    event Test_LiquidationoMATICFee(uint _oMATICFee);
    event Redemption(uint _attemptedUSDCAmount, uint _actualUSDCAmount, uint _oMATICSent, uint _oMATICFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event VaultIndexUpdated(address _borrower, uint _newIndex);
    event TEST_error(uint _debtInoMATIC, uint _collToSP, uint _collToOrum, uint _totalCollProfits);
    event TEST_liquidationfee(uint _totalCollToSendToSP, uint _totalCollToSendToOrumRevenue);
    event TEST_account(address _borrower, uint _amount);
    event TEST_normalModeCheck(bool _mode, address _borrower, uint _amount, uint _coll, uint _debt, uint _price);
    event TEST_debt(uint _debt);
    event TEST_offsetValues(uint _debtInoMATIC, uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint _totalCollProfit);
    event Coll_getOffsetValues(uint _debt, uint _coll);
    // --- Functions ---
    function getVaultOwnersCount() external view returns (uint);

    function getVaultFromVaultOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);

    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateVaults(uint _n) external;

    function batchLiquidateVaults(address[] calldata _VaultArray) external; 

    function addVaultOwnerToArray(address _borrower) external returns (uint index);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll
    );

    function closeVault(address _borrower) external;

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint USDCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _USDCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getVaultStatus(address _borrower) external view returns (uint);

    function getVaultDebt(address _borrower) external view returns (uint);

    function getVaultColl(address _borrower) external view returns (uint);

    function setVaultStatus(address _borrower, uint num) external;

    function increaseVaultColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseVaultColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseVaultDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// File: StabilityPool.sol

contract StabilityPool is IStabilityPool {
    IUSDCToken public usdc_token;
    address borrowerOpsAddress;
    address rewardsPoolAddress;

    IoMATICToken public oMATICToken;

    IVaultManager public vaultManager;

    ICommunityIssuance public communityIssuance;
    IActivePool public activePool;

    uint256 internal totalUSDCDeposits;
    uint256 public USDC_Lent;
    uint constant public DECIMAL_PRECISION = 1e18;
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToSum;

    // Error trackers for the error correction in the offset calculation
    uint256 public lastMATICError_Offset;
    uint256 public lastUSDCLossError_Offset;
    mapping(address => uint256) rewards;
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;
    

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;
    uint256 internal MATIC;
    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;
    uint256 public constant SCALE_FACTOR = 1e9;

    mapping(uint128 => mapping(uint128 => uint256))
    public epochToScaleToRewards;
    uint256 public lastOrumError;
    uint256 public lastRewardsError;

    // Rewards snapshots
    struct Snapshots {
        uint S;
        uint P;
        uint G;
        uint R;
        uint128 scale;
        uint128 epoch;
    }
    uint256 public P = DECIMAL_PRECISION;
    mapping (address => uint) public deposits;  // depositor address -> deposited amount
    mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct



    function setAddresses(
        address _usdcTokenAddress,
        address _borrowerOpsAddress,
        address _oMATICToken,
        address _vaultManagerAddress,
        address _communityIssuanceAddress,
        address _activePoolAddress,
        address _rewardsPoolAddress
    ) 
    external 
    override 
    {
        usdc_token = IUSDCToken(_usdcTokenAddress);
        vaultManager = IVaultManager(_vaultManagerAddress);
        oMATICToken = IoMATICToken(_oMATICToken);
        borrowerOpsAddress = _borrowerOpsAddress;
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
        activePool = IActivePool(_activePoolAddress);
        rewardsPoolAddress = _rewardsPoolAddress;

        emit USDCTokenAddressChanged(_usdcTokenAddress);
    }

    // --- Getters for public variables. ---


    function getUSDCDeposits() external view override returns (uint) {
        return totalUSDCDeposits;
    }

    function getRewards() external view returns (uint) {
        return MATIC;
    }

    function sendUSDCtoBorrower(
        IUSDCToken _usdc_token,
        address _to,
        uint256 _amount
    ) external override {
        _requireCallerIsBorrowerOps();
        // emit ActivePooloMATICBalanceUpdated();
        emit USDCSent(_to, _amount);

        if (_amount > 0) {
            bool sucess = _usdc_token.transfer(payable(_to), _amount);
            require(sucess, "Stability Pool: sendUSDCtoBorrower failed");
            USDC_Lent += _amount;
            emit SentoMATICStabilityPool(_to, _amount);
        }
    }

    function decreaseLentAmount(uint256 _amount) external override {
        USDC_Lent -= _amount;
    }

    function _requireCallerIsBorrowerOps() internal view {
        require(
            msg.sender == borrowerOpsAddress,
            "StabilityPool: Caller is not BorrowerOps"
        );
    }

    function withdrawFromStabilityPool(uint _amount) external override {
        require(_amount <= usdc_token.balanceOf(address(this)), "StabilityPool: withdrawal amount greater than SP balance");
        uint initialDeposit = deposits[msg.sender];
        require(initialDeposit > 0, "StabilityPool: Initial deposit is 0");
        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);

        uint depositorMATICGain = getDepositorMATICGain(msg.sender);

        uint compoundedUSDCDeposit = getCompoundedUSDCDeposit(msg.sender);
        uint USDCtoWithdraw = _amount > compoundedUSDCDeposit ? compoundedUSDCDeposit : _amount;
        uint USDCLoss = initialDeposit - compoundedUSDCDeposit; // Needed only for event log

        _payOutOrumGains(communityIssuanceCached, msg.sender);

        _sendUSDCToDepositor(msg.sender, USDCtoWithdraw);

        // Update deposit
        uint newDeposit = compoundedUSDCDeposit - USDCtoWithdraw;
        _updateDepositAndSnapshots(msg.sender, newDeposit);

        _sendMATICGainToDepositor(depositorMATICGain);
    }

    function provideToStabilityPool(uint256 _amount) external override {
        bool allow = _allowDeposit();
        require(allow, "StabilityPool: Stable coin deposit not allowed");

        uint initialDeposit = deposits[msg.sender];

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);

        uint depositorMATICGain = getDepositorMATICGain(msg.sender);
        uint compoundedUSDCDeposit = getCompoundedUSDCDeposit(msg.sender);
        uint USDCLoss = initialDeposit - compoundedUSDCDeposit;

        _payOutOrumGains(communityIssuanceCached, msg.sender);

        //Stable coin transfer from lender to SP
        //usdc_token.approve(address(this), _amount);
        _sendUSDCtoStabilityPool(msg.sender, address(this), _amount);
        // usdc_token.transfer(address(this), _amount);
        // totalUSDCDeposits += _amount ;

        uint newDeposit = compoundedUSDCDeposit + _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);

        _sendMATICGainToDepositor(depositorMATICGain);
    }

    // --- Compounded deposit ---

    /*
    * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
    * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
    */
    function getCompoundedUSDCDeposit(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint compoundedDeposit = _getCompoundedStakeFromSnapshots(initialDeposit, snapshots);
        return compoundedDeposit;
    }

    // Internal function, used to calculcate compounded deposits and compounded front end stakes.
    function _getCompoundedStakeFromSnapshots(
        uint initialStake,
        Snapshots memory snapshots
    )
        internal
        view
        returns (uint)
    {
        uint snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) { return 0; }

        uint compoundedStake;
        uint128 scaleDiff = currentScale - scaleSnapshot;

        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
        * account for it. If more than one scale change was made, then the stake has decreased by a factor of
        * at least 1e-9 -- so return 0.
        */
        if (scaleDiff == 0) {
            compoundedStake = initialStake * P / snapshot_P;
        } else if (scaleDiff == 1) {
            compoundedStake = ((initialStake *P)/snapshot_P) / SCALE_FACTOR;
        } else { // if scaleDiff >= 2
            compoundedStake = 0;
        }

        /*
        * If compounded deposit is less than a billionth of the initial deposit, return 0.
        *
        * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
        * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
        * than it's theoretical value.
        *
        * Thus it's unclear whether this line is still really needed.
        */
        if (compoundedStake < initialStake /1e9) {return 0;}

        return compoundedStake;
    }

    // --- Reward calculator functions for depositor and front end ---

    /* Calculates the MATIC gain earned by the deposit since its last snapshots were taken.
    * Given by the formula:  E = d0 * (S - S(0))/P(0)
    * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorMATICGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];

        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint MATICGain = _getMATICGainFromSnapshots(initialDeposit, snapshots);
        return MATICGain;
    }

    function _getMATICGainFromSnapshots(uint initialDeposit, Snapshots memory snapshots) internal view returns (uint) {
        /*
        * Grab the sum 'S' from the epoch at which the stake was made. The MATIC gain may span up to one scale change.
        * If it does, the second portion of the MATIC gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint S_Snapshot = snapshots.S;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot] - S_Snapshot;
        uint secondPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint MATICGain = ((initialDeposit* (firstPortion + secondPortion)) / P_Snapshot) / DECIMAL_PRECISION;

        return MATICGain;
    }

    function _updateDepositAndSnapshots(address _depositor, uint _newValue) internal {
        deposits[_depositor] = _newValue;

        if (_newValue == 0) {
            delete depositSnapshots[_depositor];
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentP = P;

        // Get S and G for the current epoch and current scale
        uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];
        uint currentG = epochToScaleToG[currentEpochCached][currentScaleCached];
        uint currentR = epochToScaleToRewards[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P and sum S for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].S = currentS;
        depositSnapshots[_depositor].G = currentG;
        depositSnapshots[_depositor].R = currentR;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;
    }

    function getUtilisationRatio() external view override returns (uint) {
        return _getUtilisationRatio();
    }

    function _getUtilisationRatio() internal view returns (uint) {
        uint utilisationRatio = totalUSDCDeposits == 0 ? 100 * DECIMAL_PRECISION : (USDC_Lent * 100 * DECIMAL_PRECISION) / totalUSDCDeposits;
        return utilisationRatio;
    }

    function allowBorrow() external view override returns (bool) {
        bool allowed;
        uint256 utilisationRatio;

        utilisationRatio = _getUtilisationRatio();
        allowed = utilisationRatio >= (90 * DECIMAL_PRECISION) ? false : true;

        return allowed;
    }

    function allowDeposit() external view returns (bool) {
        return _allowDeposit();
    }

    function _allowDeposit() internal view returns (bool) {
        uint256 utilisationRatio;
        bool allow;
        utilisationRatio = _getUtilisationRatio();

        allow = utilisationRatio >= (80 * DECIMAL_PRECISION) ? true : false;
        return allow;
    }

    function getUSDCinSP() external override view returns (uint) {
        return usdc_token.balanceOf(address(this));
    }

    // --- Liquidation functions ---

    /*
     * Cancels out the specified debt against the USDC contained in the Stability Pool (as far as possible)
     * and transfers the Vault's MATIC collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the VaultManager.
     */
    function offset(uint256 _debtToOffset, uint256 _collToAdd)
        external
        override
    {
        _requireCallerIsVaultManagerOrRewardsPool();
        uint256 totalUSDC = totalUSDCDeposits; // cached to save an SLOAD
        if (_debtToOffset == 0 && _collToAdd == 0) {
            return;
        }

        _triggerOrumIssuance(communityIssuance);

        (uint MATICGainPerUnitStaked,
            uint USDCLossPerUnitStaked) = _computeRewardsPerUnitStaked(_collToAdd, _debtToOffset, totalUSDC);

        _updateRewardSumAndProduct(MATICGainPerUnitStaked, USDCLossPerUnitStaked);  // updates S and P

        if(msg.sender != address(rewardsPoolAddress)){
            _moveOffsetCollAndDebt(_collToAdd, _debtToOffset);
        }

        _decreaseUSDC(_debtToOffset);
        USDC_Lent -= _debtToOffset;
    }

    function rewardsOffset(uint256 _rewardsToAdd)
        external
        override
    {
        _requireCallerIsVaultManagerOrRewardsPool();
        uint256 totalUSDC = totalUSDCDeposits; // cached to save an SLOAD

        uint MATICGainPerUnitStaked = _computeBlockRewardsPerUnitStaked(_rewardsToAdd, totalUSDC);

        _updateRewardSumAndProduct(MATICGainPerUnitStaked, 0);        
    }

    function _computeBlockRewardsPerUnitStaked(
        uint _collToAdd,
        uint _totalUSDCDeposits
    ) 
        internal 
        returns (uint MATICGainPerUnitStaked)
    {
        uint MATICNumerator = (_collToAdd * DECIMAL_PRECISION) + lastMATICError_Offset;

        MATICGainPerUnitStaked = MATICNumerator / _totalUSDCDeposits;

        lastMATICError_Offset = MATICNumerator - (MATICGainPerUnitStaked* _totalUSDCDeposits);

        return (MATICGainPerUnitStaked);
    }

    function _computeRewardsPerUnitStaked(
        uint _collToAdd,
        uint _debtToOffset,
        uint _totalUSDCDeposits
    ) 
        internal 
        returns (uint MATICGainPerUnitStaked, uint USDCLossPerUnitStaked)
    {
        /*
        * Compute the USDC and MATIC rewards. Uses a "feedback" error correction, to keep
        * the cumulative error in the P and S state variables low:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this 
        * function was called.  
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint MATICNumerator = (_collToAdd * DECIMAL_PRECISION) + lastMATICError_Offset;
        assert(_debtToOffset <= _totalUSDCDeposits);
        if (_debtToOffset == _totalUSDCDeposits) {
            USDCLossPerUnitStaked = DECIMAL_PRECISION;  // When the Pool depletes to 0, so does each deposit 
            lastUSDCLossError_Offset = 0;
        } else {
            uint USDCLossNumerator = (_debtToOffset * DECIMAL_PRECISION) - lastUSDCLossError_Offset;
            /*
            * Add 1 to make error in quotient positive. We want "slightly too much" USDC loss,
            * which ensures the error in any given compoundedUSDCDeposit favors the Stability Pool.
            */
            USDCLossPerUnitStaked = (USDCLossNumerator / _totalUSDCDeposits) + 1;
            lastUSDCLossError_Offset = (USDCLossPerUnitStaked *_totalUSDCDeposits) - USDCLossNumerator;
        }

        MATICGainPerUnitStaked = MATICNumerator / _totalUSDCDeposits;

        lastMATICError_Offset = MATICNumerator - (MATICGainPerUnitStaked* _totalUSDCDeposits);

        return (MATICGainPerUnitStaked, USDCLossPerUnitStaked);
    }

    // Update the Stability Pool reward sum S and product P
    function _updateRewardSumAndProduct(uint _MATICGainPerUnitStaked, uint _USDCLossPerUnitStaked) internal {
        uint currentP = P;
        uint newP;

        assert(_USDCLossPerUnitStaked <= DECIMAL_PRECISION);
        /*
        * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool USDC in the liquidation.
        * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - USDCLossPerUnitStaked)
        */
        uint newProductFactor = uint(DECIMAL_PRECISION - _USDCLossPerUnitStaked);

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];

        /*
        * Calculate the new S first, before we update P.
        * The MATIC gain for any given depositor from a liquidation depends on the value of their deposit
        * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
        *
        * Since S corresponds to MATIC gain, and P to deposit loss, we update S first.
        */
        uint marginalMATICGain = _MATICGainPerUnitStaked * currentP;
        uint newS = currentS + marginalMATICGain;
        epochToScaleToSum[currentEpochCached][currentScaleCached] = newS;
        emit S_Updated(newS, currentEpochCached, currentScaleCached);

        // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
        if (newProductFactor == 0) {
            currentEpoch = currentEpochCached + 1;
            emit EpochUpdated(currentEpoch);
            currentScale = 0;
            emit ScaleUpdated(currentScale);
            newP = DECIMAL_PRECISION;

        // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
        } else if (currentP * newProductFactor / DECIMAL_PRECISION < SCALE_FACTOR) {
            newP = (currentP * newProductFactor * SCALE_FACTOR) / DECIMAL_PRECISION; 
            currentScale = currentScaleCached + 1;
            emit ScaleUpdated(currentScale);
        } else {
            newP = currentP * newProductFactor / DECIMAL_PRECISION;
        }

        assert(newP > 0);
        P = newP;

        emit P_Updated(newP);
    }

    function _moveOffsetCollAndDebt(
        uint256 _collToAdd,
        uint256 _debtToOffset
    ) internal {
        IActivePool activePoolCached = activePool;

        // Cancel the liquidated USDC debt with the USDC in the stability pool
        activePoolCached.decreaseUSDCDebt(_debtToOffset);

        activePoolCached.swapoMATICAndSendMATIC(address(this), _collToAdd);
        MATIC+= _collToAdd;
    }

    // Transfer the USDC tokens from the user to the Stability Pool's address, and update its recorded USDC
    function _sendUSDCtoStabilityPool(address _sender, address _address, uint _amount) internal {
        usdc_token.transferFrom(_sender, _address, _amount);
        totalUSDCDeposits += _amount ;
        emit StabilityPoolUSDCBalanceUpdated(totalUSDCDeposits);
    }

    function _decreaseUSDC(uint256 _amount) internal {
        uint256 newTotalUSDCDeposits = totalUSDCDeposits - _amount;
        totalUSDCDeposits = newTotalUSDCDeposits;
        emit StabilityPoolUSDCBalanceUpdated(newTotalUSDCDeposits);
    }

    // --- ORUM issuance functions ---

    function _triggerOrumIssuance(ICommunityIssuance _communityIssuance)
        internal
    {
        uint256 orumIssuance = _communityIssuance.issueOrum();
        _updateG(orumIssuance);
    }

    function _updateG(uint256 _orumIssuance) internal {
        uint256 totalUSDC = totalUSDCDeposits; // cached to save an SLOAD
        /*
         * When total deposits is 0, G is not updated. In this case, the ORUM issued can not be obtained by later
         * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
         *
         */
        if (totalUSDC == 0 || _orumIssuance == 0) {
            return;
        }

        uint256 orumPerUnitStaked;
        orumPerUnitStaked = _computeOrumPerUnitStaked(_orumIssuance, totalUSDC);

        uint256 marginalOrumGain = orumPerUnitStaked * P;
        epochToScaleToG[currentEpoch][currentScale] =
            epochToScaleToG[currentEpoch][currentScale] +
            marginalOrumGain;

        emit G_Updated(
            epochToScaleToG[currentEpoch][currentScale],
            currentEpoch,
            currentScale
        );
    }

    function _computeOrumPerUnitStaked(
        uint256 _orumIssuance,
        uint256 _totalUSDCDeposits
    ) internal returns (uint256) {
        /*
         * Calculate the ORUM-per-unit staked.  Division uses a "feedback" error correction, to keep the
         * cumulative error low in the running total G:
         *
         * 1) Form a numerator which compensates for the floor division error that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratio.
         * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
         * 4) Store this error for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 orumNumerator = (_orumIssuance * DECIMAL_PRECISION) +
            lastOrumError;

        uint256 orumPerUnitStaked = (orumNumerator / _totalUSDCDeposits);
        lastOrumError =
            orumNumerator -
            (orumPerUnitStaked * _totalUSDCDeposits);

        return orumPerUnitStaked;
    }

    function getTotalUSDCDepositsIncludingLent() external view override returns (uint) {
        return totalUSDCDeposits;
    }

    function _requireCallerIsVaultManager() internal view {
        require(
            msg.sender == address(vaultManager),
            "StabilityPool: Caller is not VaultManager"
        );
    }

    function _requireCallerIsVaultManagerOrRewardsPool() internal view {
        require(
            msg.sender == address(vaultManager) || msg.sender == address(rewardsPoolAddress),
            "StabilityPool: Caller is not VaultManager or RewardsPool"
        );
    }

    function _payOutOrumGains(ICommunityIssuance _communityIssuance, address _depositor) internal {
        // Pay out depositor's ORUM gain
        uint depositorOrumGain = getDepositorOrumGain(_depositor);
        _communityIssuance.sendOrum(_depositor, depositorOrumGain);
    }

    /*
    * Calculate the ORUM gain earned by a deposit since its last snapshots were taken.
    * Given by the formula:  ORUM = d0 * (G - G(0))/P(0)
    * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorOrumGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) {return 0;}

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint orumGain = _getOrumGainFromSnapshots(initialDeposit, snapshots);

        return orumGain;
    }

    function _getOrumGainFromSnapshots(uint initialStake, Snapshots memory snapshots) internal view returns (uint) {
       /*
        * Grab the sum 'G' from the epoch at which the stake was made. The ORUM gain may span up to one scale change.
        * If it does, the second portion of the ORUM gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint G_Snapshot = snapshots.G;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot] - G_Snapshot;
        uint secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint orumGain = (initialStake * (firstPortion + secondPortion)) / P_Snapshot / DECIMAL_PRECISION;

        return orumGain;
    }

    function _sendMATICGainToDepositor(uint _amount) internal {
        if (_amount == 0) {return;}

        (bool success, ) = payable(msg.sender).call{ value: _amount }("");

        require(success, "StabilityPool: sending MATIC failed");
    }

    // Send USDC to user and decrease USDC in Pool
    function _sendUSDCToDepositor(address _depositor, uint USDCWithdrawal) internal {
        if (USDCWithdrawal == 0) {return;}

        usdc_token.transfer(_depositor, USDCWithdrawal);
        _decreaseUSDC(USDCWithdrawal);
    }

    receive() external payable {
        emit StabilityPoolReceivedMATIC(msg.value);
    }
}