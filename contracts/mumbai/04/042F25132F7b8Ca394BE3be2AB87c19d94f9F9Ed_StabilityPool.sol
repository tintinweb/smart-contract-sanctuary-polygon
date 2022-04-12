// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IBorrowerOps.sol";
import "./IStabilityPool.sol";
import "./IVaultManager.sol";
import "./IOSDToken.sol";
import "./ISortedVaults.sol";
import "./ICommunityIssuance.sol";
import "./OrumBase.sol";
import "./OrumSafeMath128.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./IaMATICToken.sol";
import "./IRewardsPool.sol";
import "./IActivePool.sol";


contract StabilityPool is OrumBase, Ownable, CheckContract, IStabilityPool {

    string constant public NAME = "StabilityPool";

    IBorrowerOps public borrowerOps;

    IVaultManager public vaultManager;

    IaMATICToken public amatic_Token;

    IOSDToken public osdToken;

    IRewardsPool public rewardsPool;

    IaMATICToken public aMATICToken;

    //IActivePool public override activePool;    

    // Needed to check if there are pending liquidations
    ISortedVaults public sortedVaults;
    ICommunityIssuance public communityIssuance;


    uint256 internal ROSE;  // deposited ether tracker
    uint256 internal MATIC; // MATIC block rewards tracker

    // Tracker for OSD held in the pool. Changes when users deposit/withdraw, and when Vault debt is offset.
    uint256 internal totalOSDDeposits;

   // --- Data structures ---

    struct Snapshots {
        uint S;
        uint P;
        uint G;
        uint R;
        uint128 scale;
        uint128 epoch;
    }

    struct ContractsCacheStabilityPool {
        IaMATICToken  amatic_Token;
    }
    // struct Snapshots_R {
    //     uint S;
    //     uint P;
    //     uint G;
    //     uint128 scale;
    //     uint128 epoch;
    // }

    mapping (address => uint) public deposits;  // depositor address -> deposited amount
    mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct
    //mapping (address => Snapshots_R) public depositSnapshots_R; // depsoitor address -> snapshots struct

    /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
    * after a series of liquidations have occurred, each of which cancel some OSD debt with the deposit.
    *
    * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
    * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
    */
    uint public P = DECIMAL_PRECISION;

    uint public constant SCALE_FACTOR = 1e9;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;

    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    /* ROSE Gain sum 'S': During its lifetime, each deposit d_t earns an ROSE gain of ( d_t * [S - S_t] )/P_t, where S_t
    * is the depositor's snapshot of S taken at the time t when the deposit was made.
    *
    * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
    *
    * - The inner mapping records the sum S at different scales
    * - The outer mapping records the (scale => sum) mappings, for different epochs.
    */
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToSum;
    /*
    * Similarly, the sum 'G' is used to calculate LQTY gains. During it's lifetime, each deposit d_t earns a LQTY gain of
    *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
    *
    *  LQTY reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
    *  In each case, the LQTY reward is issued (i.e. G is updated), before other state changes are made.
    */
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToG;

    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToRewards;

    // Error tracker for the error correction in the LQTY issuance calculation
    uint public lastOrumError;
    uint public lastRewardsError;
    // Error trackers for the error correction in the offset calculation
    uint public lastROSEError_Offset;
    uint public lastOSDLossError_Offset;

    event TEST_error(uint _error);
    event TEST_all(uint _coll, uint _debt, uint _total);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _activePoolAddress,
        address _osdTokenAddress,
        address _sortedVaultsAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress,
        address _amatic_TokenAddress,
        address _rewardsPool,
        address _aMATICToken
    )
        external
        override
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_vaultManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_osdTokenAddress);
        checkContract(_sortedVaultsAddress);
        checkContract(_priceFeedAddress);
        checkContract(_communityIssuanceAddress);
        checkContract(_amatic_TokenAddress);
        checkContract(_rewardsPool);

        borrowerOps = IBorrowerOps(_borrowerOpsAddress);
        vaultManager = IVaultManager(_vaultManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        osdToken = IOSDToken(_osdTokenAddress);
        sortedVaults = ISortedVaults(_sortedVaultsAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
        amatic_Token = IaMATICToken(_amatic_TokenAddress);
        rewardsPool = IRewardsPool(_rewardsPool);
        aMATICToken = IaMATICToken(_aMATICToken);

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit OSDTokenAddressChanged(_osdTokenAddress);
        emit SortedVaultsAddressChanged(_sortedVaultsAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit CommunityIssuanceAddressChanged(_communityIssuanceAddress);
        emit Amatic_TokenAddressChanged(_amatic_TokenAddress);

    }

    // --- Getters for public variables. Required by IPool interface ---

    function getROSE() external view override returns (uint) {
        return ROSE;
    }

    function getTotalOSDDeposits() external view override returns (uint) {
        return totalOSDDeposits;
    }

    function getRewards() external view returns (uint) {
        return MATIC;
    }

    // --- External Depositor Functions ---

    /*  provideToSP():
    *
    * - Tags the deposit with the provided front end tag param, if it's a new deposit
    * - Sends depositor's accumulated gains (ROSE) to depositor
    * - Increases deposit and takes new snapshots.
    */
    function provideToSP(uint _amount) external override {
        _requireNonZeroAmount(_amount);

        uint initialDeposit = deposits[msg.sender];

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);


        uint depositorROSEGain = getDepositorROSEGain(msg.sender);
        uint compoundedOSDDeposit = getCompoundedOSDDeposit(msg.sender);
        uint OSDLoss = initialDeposit - compoundedOSDDeposit; // Needed only for event log

        uint depositorMATICRewards = getDepositorMATICRewards(msg.sender);

        _payOutOrumGains(communityIssuanceCached, msg.sender);

        _sendOSDtoStabilityPool(msg.sender, _amount);

        uint newDeposit = compoundedOSDDeposit + _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit ROSEGainWithdrawn(msg.sender, depositorROSEGain, OSDLoss); // OSD Loss required for event log

        _sendROSEGainToDepositor(depositorROSEGain);
        _sendMATICRewardsToDepositor(depositorMATICRewards);
     }

    /*  withdrawFromSP():
    * - Sends all depositor's accumulated gains (ROSE) to depositor
    * - Decreases deposit and takes new snapshots.
    *
    * If _amount > userDeposit, the user withdraws all of their compounded deposit.
    */
    function withdrawFromSP(uint _amount) external override {
        if (_amount !=0) {_requireNoUnderCollateralizedVaults();}
        uint initialDeposit = deposits[msg.sender];
        _requireUserHasDeposit(initialDeposit);
        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);

        uint depositorROSEGain = getDepositorROSEGain(msg.sender);

        uint depositorMATICRewards = getDepositorMATICRewards(msg.sender);
        //_payOutMATICRewards(msg.sender);

        uint compoundedOSDDeposit = getCompoundedOSDDeposit(msg.sender);
        uint OSDtoWithdraw = OrumMath._min(_amount, compoundedOSDDeposit);
        uint OSDLoss = initialDeposit - compoundedOSDDeposit; // Needed only for event log

        _payOutOrumGains(communityIssuanceCached, msg.sender);

        _sendOSDToDepositor(msg.sender, OSDtoWithdraw);

        // Update deposit
        uint newDeposit = compoundedOSDDeposit - OSDtoWithdraw;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit ROSEGainWithdrawn(msg.sender, depositorROSEGain, OSDLoss);  // OSD Loss required for event log

        _sendROSEGainToDepositor(depositorROSEGain);
        _sendMATICRewardsToDepositor(depositorMATICRewards);
    }

    // function withdrawMATICRewards() external override {
    //     uint initialDeposit = deposits[msg.sender];
    //     _requireUserHasDeposit(initialDeposit);

    //     uint depositorMATICRewardsGain = getDepositorMATICRewards(msg.sender);
    //     _payOutMATICRewards(msg.sender);

    //     _updateDepositAndSnapshots(msg.sender, _newValue);
    // }

    /* withdrawROSEGainToVault:
    * - Transfers the depositor's entire ROSE gain from the Stability Pool to the caller's vault
    * - Leaves their compounded deposit in the Stability Pool
    * - Updates snapshots for deposit */
    function withdrawROSEGainToVault(address _upperHint, address _lowerHint) external override {
        uint initialDeposit = deposits[msg.sender];
        _requireUserHasDeposit(initialDeposit);
        _requireUserHasVault(msg.sender);
        _requireUserHasROSEGain(msg.sender);

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);

        uint depositorROSEGain = getDepositorROSEGain(msg.sender);
        uint depositorMATICRewards = getDepositorMATICRewards(msg.sender);

        uint compoundedOSDDeposit = getCompoundedOSDDeposit(msg.sender);
        uint OSDLoss = initialDeposit - compoundedOSDDeposit; // Needed only for event log
        _payOutOrumGains(communityIssuanceCached, msg.sender);
        _sendMATICRewardsToDepositor(depositorMATICRewards);


        _updateDepositAndSnapshots(msg.sender, compoundedOSDDeposit);

        /* Emit events before transferring ROSE gain to Vault.
         This lets the event log make more sense (i.e. so it appears that first the ROSE gain is withdrawn
        and then it is deposited into the Vault, not the other way around). */
        emit ROSEGainWithdrawn(msg.sender, depositorROSEGain, OSDLoss);
        emit UserDepositChanged(msg.sender, compoundedOSDDeposit);

        ROSE -= depositorROSEGain;
        emit StabilityPoolROSEBalanceUpdated(ROSE);
        emit RoseSent(msg.sender, depositorROSEGain);

        borrowerOps.moveROSEGainToVault{ value: depositorROSEGain }(msg.sender, _upperHint, _lowerHint);
    }

    // --- LQTY issuance functions ---

    function _triggerOrumIssuance(ICommunityIssuance _communityIssuance) internal {
        uint orumIssuance = _communityIssuance.issueOrum();
       _updateG(orumIssuance);
    }

    function _updateG(uint _orumIssuance) internal {
        uint totalOSD = totalOSDDeposits; // cached to save an SLOAD
        /*
        * When total deposits is 0, G is not updated. In this case, the LQTY issued can not be obtained by later
        * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
        *
        */
        if (totalOSD == 0 || _orumIssuance == 0) {return;}

        uint orumPerUnitStaked;
        orumPerUnitStaked =_computeOrumPerUnitStaked(_orumIssuance, totalOSD);

        uint marginalOrumGain = orumPerUnitStaked * P;
        epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale] + marginalOrumGain;

        emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
    }

    function _computeOrumPerUnitStaked(uint _orumIssuance, uint _totalOSDDeposits) internal returns (uint) {
        /*  
        * Calculate the LQTY-per-unit staked.  Division uses a "feedback" error correction, to keep the 
        * cumulative error low in the running total G:
        *
        * 1) Form a numerator which compensates for the floor division error that occurred the last time this 
        * function was called.  
        * 2) Calculate "per-unit-staked" ratio.
        * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
        * 4) Store this error for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint orumNumerator = (_orumIssuance * DECIMAL_PRECISION) + lastOrumError;

        uint orumPerUnitStaked = (orumNumerator / _totalOSDDeposits);
        lastOrumError = orumNumerator - (orumPerUnitStaked * _totalOSDDeposits);

        return orumPerUnitStaked;
    }


    // --- Liquidation functions ---

    /*
    * Cancels out the specified debt against the OSD contained in the Stability Pool (as far as possible)
    * and transfers the Vault's ROSE collateral from ActivePool to StabilityPool.
    * Only called by liquidation functions in the VaultManager.
    */
    function offset(uint _debtToOffset, uint _collToAdd) external override {
        ContractsCacheStabilityPool memory contractsCacheStabilityPool = ContractsCacheStabilityPool(amatic_Token);
        _requireCallerIsVaultManager();
        uint totalOSD = totalOSDDeposits; // cached to save an SLOAD
        if (totalOSD == 0 || _debtToOffset == 0) { return; }

        _triggerOrumIssuance(communityIssuance);

        (uint ROSEGainPerUnitStaked,
            uint OSDLossPerUnitStaked) = _computeRewardsPerUnitStaked(_collToAdd, _debtToOffset, totalOSD);

        _updateRewardSumAndProduct(ROSEGainPerUnitStaked, OSDLossPerUnitStaked);  // updates S and P

        _moveOffsetCollAndDebt(contractsCacheStabilityPool.amatic_Token, _collToAdd, _debtToOffset);
        // _moveOffsetCollAndDebt(_collToAdd, _debtToOffset); //TODO
    }

    // --- Rewards functions ---
    function _rewards(uint _rewardsToAdd) internal {
        _requireCallerIsRewardsPool();
        uint totalOSD = totalOSDDeposits;
        if(_rewardsToAdd == 0 || totalOSD == 0) {
            return;
        }

        uint MATICRewardsPerUnitStaked = _computeMATICRewardsPerUnitStaked(_rewardsToAdd, totalOSD);
        // uint marginalMATICRewardsGain = MATICRewardsPerUnitStaked * P;

        // epochToScaleToRewards[currentEpoch][currentScale] += marginalMATICRewardsGain;

        _updateMATICRewardSumAndProduct(MATICRewardsPerUnitStaked, 0);

    }


    function _computeMATICRewardsPerUnitStaked(uint _rewardsToAdd, uint _totalOSDDeposits) internal returns (uint){
        uint RewardsNumerator = (_rewardsToAdd * DECIMAL_PRECISION) + lastRewardsError;
        // if(_totalOSDDeposits == 0){
        //     return;
        // }

        uint MATICRewardGainPerUnitStaked = RewardsNumerator / _totalOSDDeposits;
        lastRewardsError = RewardsNumerator - (MATICRewardGainPerUnitStaked * _totalOSDDeposits);

        return MATICRewardGainPerUnitStaked;    
    }

    // --- Offset helper functions ---

    function _computeRewardsPerUnitStaked(
        uint _collToAdd,
        uint _debtToOffset,
        uint _totalOSDDeposits
    )
        internal
        returns (uint ROSEGainPerUnitStaked, uint OSDLossPerUnitStaked)
    {
        /*
        * Compute the OSD and ROSE rewards. Uses a "feedback" error correction, to keep
        * the cumulative error in the P and S state variables low:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this 
        * function was called.  
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint ROSENumerator = (_collToAdd * DECIMAL_PRECISION) + lastROSEError_Offset;
        assert(_debtToOffset <= _totalOSDDeposits);
        if (_debtToOffset == _totalOSDDeposits) {
            OSDLossPerUnitStaked = DECIMAL_PRECISION;  // When the Pool depletes to 0, so does each deposit 
            lastOSDLossError_Offset = 0;
        } else {
            uint OSDLossNumerator = (_debtToOffset * DECIMAL_PRECISION) - lastOSDLossError_Offset;
            /*
            * Add 1 to make error in quotient positive. We want "slightly too much" OSD loss,
            * which ensures the error in any given compoundedOSDDeposit favors the Stability Pool.
            */
            OSDLossPerUnitStaked = (OSDLossNumerator / _totalOSDDeposits) + 1;
            lastOSDLossError_Offset = (OSDLossPerUnitStaked *_totalOSDDeposits) - OSDLossNumerator;
        }

        ROSEGainPerUnitStaked = ROSENumerator / _totalOSDDeposits;

        lastROSEError_Offset = ROSENumerator - (ROSEGainPerUnitStaked* _totalOSDDeposits);

        return (ROSEGainPerUnitStaked, OSDLossPerUnitStaked);
    }

    // Update the Stability Pool reward sum S and product P
    function _updateRewardSumAndProduct(uint _ROSEGainPerUnitStaked, uint _OSDLossPerUnitStaked) internal {
        uint currentP = P;
        uint newP;

        assert(_OSDLossPerUnitStaked <= DECIMAL_PRECISION);
        /*
        * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool OSD in the liquidation.
        * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - OSDLossPerUnitStaked)
        */
        uint newProductFactor = uint(DECIMAL_PRECISION - _OSDLossPerUnitStaked);

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];

        /*
        * Calculate the new S first, before we update P.
        * The ROSE gain for any given depositor from a liquidation depends on the value of their deposit
        * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
        *
        * Since S corresponds to ROSE gain, and P to deposit loss, we update S first.
        */
        uint marginalROSEGain = _ROSEGainPerUnitStaked * currentP;
        uint newS = currentS + marginalROSEGain;
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

    function _moveOffsetCollAndDebt(IaMATICToken _amaticToken, uint _collToAdd, uint _debtToOffset) internal {
        IActivePool activePoolCached = activePool;

        // Cancel the liquidated OSD debt with the OSD in the stability pool
        activePoolCached.decreaseOSDDebt(_debtToOffset);
        _decreaseOSD(_debtToOffset);

        // Burn the debt that was successfully offset
        osdToken.burn(address(this), _debtToOffset);

        activePoolCached.sendROSE(  _amaticToken, address(this), _collToAdd);
        ROSE += _collToAdd;
    }

    function _updateMATICRewardSumAndProduct(uint _MATICRewardsPerUnitStaked, uint _OSDLossPerUnitStaked) internal {
        uint currentP = P;
        uint newP;

        uint newProductFactor = uint(DECIMAL_PRECISION - _OSDLossPerUnitStaked);

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentR = epochToScaleToRewards[currentEpochCached][currentScaleCached];

        uint marginalMATICRewards = _MATICRewardsPerUnitStaked * currentP;
        uint newR = currentR + marginalMATICRewards;
        epochToScaleToRewards[currentEpochCached][currentScaleCached] = newR;
    }

    function _decreaseOSD(uint _amount) internal {
        uint newTotalOSDDeposits = totalOSDDeposits - _amount;
        totalOSDDeposits = newTotalOSDDeposits;
        emit StabilityPoolOSDBalanceUpdated(newTotalOSDDeposits);
    }

    // --- Reward calculator functions for depositor and front end ---

    /* Calculates the ROSE gain earned by the deposit since its last snapshots were taken.
    * Given by the formula:  E = d0 * (S - S(0))/P(0)
    * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorROSEGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];

        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint ROSEGain = _getROSEGainFromSnapshots(initialDeposit, snapshots);
        return ROSEGain;
    }

    function _getROSEGainFromSnapshots(uint initialDeposit, Snapshots memory snapshots) internal view returns (uint) {
        /*
        * Grab the sum 'S' from the epoch at which the stake was made. The ROSE gain may span up to one scale change.
        * If it does, the second portion of the ROSE gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint S_Snapshot = snapshots.S;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot] - S_Snapshot;
        uint secondPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint ROSEGain = ((initialDeposit* (firstPortion + secondPortion)) / P_Snapshot) / DECIMAL_PRECISION;

        return ROSEGain;
    }

    function getDepositorMATICRewards(address _depositor) public view returns (uint) {
        uint initialDeposit = deposits[_depositor];

        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint MATICRewards = _getMATICRewardsFromSnapshots(initialDeposit, snapshots);
        return MATICRewards;
    }

    function _getMATICRewardsFromSnapshots(uint initialDeposit, Snapshots memory snapshots) internal view returns (uint) {
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint R_Snapshot = snapshots.R;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToRewards[epochSnapshot][scaleSnapshot] - R_Snapshot;
        uint secondPortion = epochToScaleToRewards[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint MATICRewards = ((initialDeposit* (firstPortion + secondPortion)) / P_Snapshot) / DECIMAL_PRECISION;

        return MATICRewards;
    }

    /*
    * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
    * Given by the formula:  LQTY = d0 * (G - G(0))/P(0)
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
        * Grab the sum 'G' from the epoch at which the stake was made. The LQTY gain may span up to one scale change.
        * If it does, the second portion of the LQTY gain is scaled by 1e9.
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



    // --- Compounded deposit ---

    /*
    * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
    * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
    */
    function getCompoundedOSDDeposit(address _depositor) public view override returns (uint) {
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

    // --- Sender functions for OSD deposit, ROSE gains and LQTY gains ---

    // Transfer the OSD tokens from the user to the Stability Pool's address, and update its recorded OSD
    function _sendOSDtoStabilityPool(address _address, uint _amount) internal {
        osdToken.sendToPool(_address, address(this), _amount);
        uint newTotalOSDDeposits = totalOSDDeposits + _amount;
        totalOSDDeposits = newTotalOSDDeposits;
        emit StabilityPoolOSDBalanceUpdated(newTotalOSDDeposits);
    }

    //TODO: need to update the below fucntion as liquidation rewards are in aMATIC
    function _sendROSEGainToDepositor(uint _amount) internal {
        if (_amount == 0) {return;}
        uint newROSE = ROSE - _amount;
        ROSE = newROSE;
        emit StabilityPoolROSEBalanceUpdated(newROSE);
        emit RoseSent(msg.sender, _amount);

        //(bool success, ) = msg.sender.call{ value: _amount }("");
        //Sending aMATIC that was received from vault liqudation
        bool success = aMATICToken.transferFrom(address(this), msg.sender, _amount);
        require(success, "StabilityPool: sending ROSE failed");
    }

    function _sendMATICRewardsToDepositor(uint _amount) internal {
        if (_amount == 0) {return;}
        uint newMATIC = MATIC - _amount;
        MATIC = newMATIC;
        //emit StabilityPoolROSEBalanceUpdated(newROSE);
        //emit RoseSent(msg.sender, _amount);

        (bool success, ) = msg.sender.call{ value: _amount }("");
        require(success, "StabilityPool: sending MATIC failed");
    }

    // Send OSD to user and decrease OSD in Pool
    function _sendOSDToDepositor(address _depositor, uint OSDWithdrawal) internal {
        if (OSDWithdrawal == 0) {return;}

        osdToken.returnFromPool(address(this), _depositor, OSDWithdrawal);
        _decreaseOSD(OSDWithdrawal);
    }
    // --- Stability Pool Deposit Functionality ---

    function _updateDepositAndSnapshots(address _depositor, uint _newValue) internal {
        deposits[_depositor] = _newValue;

        if (_newValue == 0) {
            delete depositSnapshots[_depositor];
            emit DepositSnapshotUpdated(_depositor, 0, 0, 0);
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

        emit DepositSnapshotUpdated(_depositor, currentP, currentS, currentG);
    }

    function _payOutOrumGains(ICommunityIssuance _communityIssuance, address _depositor) internal {
        // Pay out depositor's LQTY gain
        uint depositorOrumGain = getDepositorOrumGain(_depositor);
        _communityIssuance.sendOrum(_depositor, depositorOrumGain);
        emit OrumPaidToDepositor(_depositor, depositorOrumGain);
    }

    function _payOutMATICRewards(address _depositor) internal {
        uint depsoitorRewards = getDepositorMATICRewards(_depositor);
        (bool success, ) = payable(_depositor).call{ value: depsoitorRewards }("");
        require(success, "StabiltyPool: sending depositor matic rewards failed");
    }
    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require( msg.sender == address(activePool), "StabilityPool: Caller is not ActivePool");
    }

    function _requireCallerIsVaultManager() internal view {
        require(msg.sender == address(vaultManager), "StabilityPool: Caller is not VaultManager");
    }

    function _requireCallerIsRewardsPool() internal view {
        require(msg.sender == address(rewardsPool), "StabilityPool: Caller is not RewardsPool");
    }

    function _requireNoUnderCollateralizedVaults() internal view {
        uint price = priceFeed.fetchPrice();
        address lowestVault = sortedVaults.getLast();
        uint ICR = vaultManager.getCurrentICR(lowestVault, price);
        require(ICR >= MCR, "StabilityPool: Cannot withdraw while there are vaults with ICR < MCR");
    }

    function _requireUserHasDeposit(uint _initialDeposit) internal pure {
        require(_initialDeposit > 0, 'StabilityPool: User must have a non-zero deposit');
    }

     function _requireUserHasNoDeposit(address _address) internal view {
        uint initialDeposit = deposits[_address];
        require(initialDeposit == 0, 'StabilityPool: User must have no deposit');
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, 'StabilityPool: Amount must be non-zero');
    }

    function _requireUserHasVault(address _depositor) internal view {
        require(vaultManager.getVaultStatus(_depositor) == 1, "StabilityPool: caller must have an active vault to withdraw ROSEGain to");
    }

    function _requireUserHasROSEGain(address _depositor) internal view {
        uint ROSEGain = getDepositorROSEGain(_depositor);
        require(ROSEGain > 0, "StabilityPool: caller must have non-zero ROSE Gain");
    }

    function _requireUserHasMATICRewards(address _depositor) internal view {
        uint MATICRewards = getDepositorMATICRewards(_depositor);
        require(MATICRewards > 0, "StabilityPool: caller must have non-zero MATIC rewards");
    }

    function changeMCR(uint _newMCR) onlyOwner external {
        MCR = _newMCR;
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsRewardsPool();
        MATIC += msg.value;

        _rewards(msg.value);
        emit StabilityPoolROSEBalanceUpdated(ROSE);
    }
}