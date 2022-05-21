// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./QiDaoFolder.sol";
// import "forge-std/console.sol";

contract QiDaoFolderVGHST is QiDaoFolder {
  address internal constant MAI_ADDRESS = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
  address internal constant MAI_PAIR_ADDRESS = 0x160532D2536175d65C03B97b0630A9802c274daD; // quickswap mai / usdc
  address internal constant VGHST_VAULT_ADDRESS = 0x1F0aa72b980d65518e88841bA1dA075BD43fa933;
  address internal constant VGHST_ADDRESS = 0x51195e21BDaE8722B29919db56d95Ef51FaecA6C;
  address internal constant GHST_ADDRESS = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
  address internal constant AM3CRV_ADDRESS = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;
  address internal constant CURVE_AAVE_POOL_ADDRESS = 0x445FE580eF8d70FF569aB36e80c647af338db351;
  address internal constant CURVE_MAI_3POOL_ADDRESS = 0x447646e84498552e62eCF097Cc305eaBFFF09308; // coins: 0=mai, 1=am3crv
  address internal constant QI_ADDRESS = 0x580A84C73811E1839F75d86d75d88cCa0c241fF4;
  address internal constant USDC_ADDRESS = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address internal constant USDC_GHST_PAIR_ADDRESS = 0x096C5CCb33cFc5732Bcd1f3195C13dBeFC4c82f4;

  constructor() QiDaoFolder(MAI_ADDRESS, MAI_PAIR_ADDRESS, VGHST_VAULT_ADDRESS, VGHST_ADDRESS, QI_ADDRESS) {
  }

  function additionalFeeBps() pure internal override returns (uint) {
    return 50;
  }

  function _approveSwaps() internal override {
    IERC20(MAI_ADDRESS).approve(CURVE_MAI_3POOL_ADDRESS, type(uint).max);
    IERC20(AM3CRV_ADDRESS).approve(CURVE_MAI_3POOL_ADDRESS, type(uint).max);
    IERC20(MAI_ADDRESS).approve(AM3CRV_ADDRESS, type(uint).max);
    IERC20(AM3CRV_ADDRESS).approve(CURVE_AAVE_POOL_ADDRESS, type(uint).max);
    IERC20(USDC_ADDRESS).approve(CURVE_AAVE_POOL_ADDRESS, type(uint).max);
    IERC20(GHST_ADDRESS).approve(VGHST_ADDRESS, type(uint).max);
  }

  function _swapMaiForToken(uint _amountMai, uint _minAmountTokenReceived) internal override {
    // MAI -> AM3CRV
    uint gotAm3crv = IERC20(AM3CRV_ADDRESS).balanceOf(address(this));
    IAPool(CURVE_MAI_3POOL_ADDRESS).exchange(0, 1, _amountMai, 0);
    gotAm3crv = IERC20(AM3CRV_ADDRESS).balanceOf(address(this)) - gotAm3crv;

    // AM3CRV -> USDC
    uint gotUsdc = IERC20(USDC_ADDRESS).balanceOf(address(this));
    IAPool(CURVE_AAVE_POOL_ADDRESS).remove_liquidity_one_coin(gotAm3crv, 1, 0, true);
    gotUsdc = IERC20(USDC_ADDRESS).balanceOf(address(this)) - gotUsdc;

    // USDC -> GHST
    uint gotGhst = IERC20(GHST_ADDRESS).balanceOf(address(this));
    routerlessSwapFromAmountIn(USDC_GHST_PAIR_ADDRESS, USDC_ADDRESS, GHST_ADDRESS, gotUsdc);
    gotGhst = IERC20(GHST_ADDRESS).balanceOf(address(this)) - gotGhst;

    // GHST -> VGHST
    uint gotVghst = IERC20(VGHST_ADDRESS).balanceOf(address(this));
    IVGHST(VGHST_ADDRESS).enter(gotGhst);
    gotVghst = IERC20(VGHST_ADDRESS).balanceOf(address(this)) - gotVghst;

    require(
      gotVghst >= _minAmountTokenReceived,
      "too much slippage"
    );
    emit SwappedMaiForToken(_amountMai, gotVghst);
  }

  function _swapTokenForMai(uint _amountToken, uint _minAmountMaiReceived) internal override {
    // VGHST -> GHST
    uint gotGhst = IERC20(GHST_ADDRESS).balanceOf(address(this));
    IVGHST(VGHST_ADDRESS).leave(_amountToken);
    gotGhst = IERC20(GHST_ADDRESS).balanceOf(address(this)) - gotGhst;

    // GHST -> USDC
    uint gotUsdc = IERC20(USDC_ADDRESS).balanceOf(address(this));
    routerlessSwapFromAmountIn(USDC_GHST_PAIR_ADDRESS, GHST_ADDRESS, USDC_ADDRESS, gotGhst);
    gotUsdc = IERC20(USDC_ADDRESS).balanceOf(address(this)) - gotUsdc;

    // USDC -> AM3CRV
    uint gotAm3crv = IERC20(AM3CRV_ADDRESS).balanceOf(address(this));
    uint[3] memory amounts;
    amounts[1] = gotUsdc;
    IAPool(CURVE_AAVE_POOL_ADDRESS).add_liquidity(amounts, 0, true);
    gotAm3crv = IERC20(AM3CRV_ADDRESS).balanceOf(address(this)) - gotAm3crv;

    // AM3CRV -> MAI
    uint gotMai = IERC20(MAI_ADDRESS).balanceOf(address(this));
    IAPool(CURVE_MAI_3POOL_ADDRESS).exchange(1, 0, gotAm3crv, 0);
    gotMai = IERC20(MAI_ADDRESS).balanceOf(address(this)) - gotMai;

    require(
      gotMai >= _minAmountMaiReceived,
      "too much slippage"
    );
    emit SwappedTokenForMai(_amountToken, gotMai);
  }

  function routerlessSwapFromAmountIn(address _pairAddress, address _tokenFrom, address _tokenTo, uint _amountIn) internal {
    uint reservesFrom = IERC20(_tokenFrom).balanceOf(_pairAddress);
    uint reservesTo = IERC20(_tokenTo).balanceOf(_pairAddress);
    uint amountInWithFee = _amountIn * 997;
    uint numerator = amountInWithFee * reservesTo;
    uint denominator = (reservesFrom * 1000) + amountInWithFee;
    uint exactAmountOut = numerator / denominator;
    bool tokenToIsToken0 = _tokenTo < _tokenFrom;

    IERC20(_tokenFrom).transfer(_pairAddress, _amountIn);

    IUniswapV2Pair(_pairAddress).swap(
      tokenToIsToken0 ? exactAmountOut : 0,
      !tokenToIsToken0 ? exactAmountOut : 0,
      address(this),
      bytes("")
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
// import "forge-std/console.sol";

/// @title QiDao Debt Folding Contract
/// @dev This is an abstract contract that must be implemented for each vault type.
abstract contract QiDaoFolder {

  // erc20 event
  event Transfer(address indexed from, address indexed to, uint value);

  // other events
  event SwappedMaiForToken(uint amountMai, uint amountToken);
  event SwappedTokenForMai(uint amountToken, uint amountMai);

  // Constants
  enum RebalanceType { NONE, FOLD, UNFOLD, EMERGENCY_UNFOLD }
  uint constant PRICE_PRECISION = 1e8; // qidao oracles are USD with 1e8 decimals
  uint constant CDR_PRECISION = 1e4; // 4 decimals of precision, e.g. 11500 = 115%
  uint constant DEFAULT_FOLD_TRIGGER_DEVIATION = 100; // e.g. rebalance at 116%
  uint constant DEFAULT_MIN_AMOUNT_TO_FOLD = 5 * 1e18; // don't even bother looping for less than 5 MAI
  uint constant DEFAULT_MAX_FOLDS_PER_CALL = 10; // make sure to respect gas limits
  address constant GELATO_OPS_ADDRESS = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;

  // Immutables (set by child contract)

  address immutable owner; // Owner of this contract
  address immutable maiAddress; // Address of the MAI token
  address immutable maiPairAddress; // Address of a univ2 pair, used to flashloan MAI for "emergency unfolding"
  address immutable tokenAddress; // Address of the underlying token in the vault
  address immutable qiAddress; // Address of the QI token
  address immutable vaultAddress; // QiDao vault address

  // Storage variables: do not change order or remove, as this contract must be upgradeable

  // erc20 stuff
  string public name;
  string public symbol;
  uint public totalSupply;
  mapping(address => uint) private balances;

  // folder stuff
  uint public vaultId; // QiDao vault ID (created upon initialization)
  uint public targetCdr; // target CDR
  uint public maxFoldsPerCall; // maximium folds/unfolds to perform per tx
  uint public foldTriggerDeviation; // fold when CDR deviates by this amount
  mapping(address => bool) public depositors; // allowlist of addresses allowed to deposit in this vault
  uint public minAmountToFold; // don't even bother looping for less than this amount of MAI

  // Modifiers

  modifier onlyOwner() {
    require(owner == msg.sender, "not owner");
    _;
  }

  modifier onlyOwnerOrGelato() {
    require(owner == msg.sender || owner == GELATO_OPS_ADDRESS, "not owner or gelato");
    _;
  }

  modifier onlyDepositors() {
    require(depositors[msg.sender] || owner == msg.sender, "not depositor");
    _;
  }

  modifier onlyInitialized() {
    require(vaultId != 0, "not initialized");
    _;
  }

  // Initialization

  // sets immutable variables only, as this will be deployed behind a proxy
  constructor(address _maiAddress, address _maiPairAddress, address _vaultAddress, address _tokenAddress, address _qiAddress) {
    owner = msg.sender;
    maiAddress = _maiAddress;
    maiPairAddress = _maiPairAddress;
    vaultAddress = _vaultAddress;
    tokenAddress = _tokenAddress;
    qiAddress = _qiAddress;
  }

  /// @notice create a vault and initialize storage variables
  /// @param _targetCdr target collateral:debt ratio with 4 decimals of precision, e.g. "11500" for 115%
  function initialize(string memory _name, string memory _symbol, uint _targetCdr) external onlyOwner {
    require(vaultId == 0, "already initialized");
    name = _name;
    symbol = _symbol;
    maxFoldsPerCall = DEFAULT_MAX_FOLDS_PER_CALL;
    foldTriggerDeviation = DEFAULT_FOLD_TRIGGER_DEVIATION;
    minAmountToFold = DEFAULT_MIN_AMOUNT_TO_FOLD;
    _setTargetCdr(_targetCdr);
    _approveSwaps();
    IERC20(tokenAddress).approve(vaultAddress, type(uint).max);
    IERC20(maiAddress).approve(vaultAddress, type(uint).max);
    vaultId = QiDaoVault(vaultAddress).createVault();
  }

  // Tokenization

  function decimals() public pure returns (uint8) {
    return 18;
  }

  function balanceOf(address _account) public view returns (uint) {
    return balances[_account];
  }

  /// @notice invests underlying tokens and issues an ERC20 representing the depositor's share in the vault
  /// @param _amount amount of underlying tokens to invest in the folder
  function enter(uint _amount) external onlyDepositors onlyInitialized {
    require(_amount > 0, "_amount must be gt 0");

    uint toMint = totalSupply == 0 ? _amount : _amount * approximateBalanceOfUnderlying() / totalSupply;

    if (toMint != 0) {
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
      _mint(msg.sender, toMint);
    }
  }

  /// @notice burns ERC20 tokens and withdraws the appropriate amount of underlying tokens to the caller
  /// @param _amount amount of underlying tokens to invest in the folder
  function exit(uint _amount) external onlyDepositors onlyInitialized {
    require(totalSupply > 0, "totalSupply is zero");
    require(_amount > 0, "_amount must be gt 0");

    uint amountToWithdraw = _amount * approximateBalanceOfUnderlying() / totalSupply;
    require(amountToWithdraw <= tokenBalance(), "not enough tokens to withdraw, must unfold first");

    IERC20(tokenAddress).transfer(msg.sender, amountToWithdraw);
    _burn(msg.sender, _amount);
  }

  // no transfers allowed
  function transfer(address, uint) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint) public pure returns (bool) { return false; }
  function approve(address, uint) public pure returns (bool) { return false; }
  function allowance(address, address) public pure returns (uint) { return 0; }
  function increaseAllowance(address, uint) public pure returns (uint) { return 0; }
  function decreaseAllowance(address, uint) public pure returns (uint) { return 0; }

  // External

  /// @param _depositor address of the depositor to add
  function addDepositor(address _depositor) external onlyOwner {
    depositors[_depositor] = true;
  }

  /// @param _depositor address of the depositor to remove
  function removeDepositor(address _depositor) external onlyOwner {
    depositors[_depositor] = false;
  }

  /// @param _targetCdr target collateral:debt ratio with 4 decimals of precision, e.g. "11500" for 115%
  function setTargetCdr(uint _targetCdr) external onlyOwner onlyInitialized {
    _setTargetCdr(_targetCdr);
  }

  /// @param _maxFoldsPerCall maximium folds/unfolds to perform per tx
  function setMaxFoldsPerCall(uint _maxFoldsPerCall) external onlyOwner onlyInitialized {
    maxFoldsPerCall = _maxFoldsPerCall;
  }

  /// @param _foldTriggerDeviation rebalance when CDR deviates by this amount
  function setFoldTriggerDeviation(uint _foldTriggerDeviation) external onlyOwner onlyInitialized {
    foldTriggerDeviation = _foldTriggerDeviation;
  }

  /// @param _minAmountToFold don't bother folding for less than this amount of MAI
  function setMinAmountToFold(uint _minAmountToFold) external onlyOwner onlyInitialized {
    minAmountToFold = _minAmountToFold;
  }

  /// @notice Rebalances the vault based on the target CDR by either folding or unfolding if necessary.
  /// @param _minTokenReceivedPerMai minimum number of tokens to receive per MAI,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  /// @param _minMaiReceivedPerToken minimum number of MAI to receive per token,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  function rebalance(uint _minTokenReceivedPerMai, uint _minMaiReceivedPerToken) external onlyOwnerOrGelato onlyInitialized {
    RebalanceType rt = _getRebalanceType();
    require(rt != RebalanceType.NONE, "no rebalance needed");

    if (rt == RebalanceType.EMERGENCY_UNFOLD) {
      _emergencyUnfold(0);
    } else if (rt == RebalanceType.FOLD) {
      _fold(type(uint).max, _minTokenReceivedPerMai);
    } else if (rt == RebalanceType.UNFOLD) {
      _unfold(type(uint).max, _minMaiReceivedPerToken);
    }
  }

  function checkRebalanceGelato() external view returns (bool canExec, bytes memory execPayload) {
    RebalanceType rt = _getRebalanceType();

    if (rt != RebalanceType.NONE) {
      canExec = true;
      execPayload = abi.encodeWithSelector(QiDaoFolder.rebalance.selector, 0, 0); // TODO: set min amounts
    }
  }

  /// @notice "Folds" the vault's collateral by borrowing MAI, swapping for more
  /// collateral tokens, depositing those, borrowing MAI, and repeating this process.
  /// @param _minTokenReceivedPerMai minimum number of tokens to receive per MAI,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  function fold(uint _minTokenReceivedPerMai) external onlyOwner onlyInitialized {
    _fold(type(uint).max, _minTokenReceivedPerMai);
  }

  /// @notice "Folds" the vault's collateral by borrowing MAI, swapping for more
  /// collateral tokens, depositing those, borrowing MAI, and repeating this process.
  /// @param _maxNewDebtAmount the maximum amount of new MAI debt to borrow.
  /// By passing this parameter, we can specify a smaller "fold" in
  /// order to profit when the price of MAI is > $1.
  /// @param _minTokenReceivedPerMai minimum number of tokens to receive per MAI,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  function foldWithMaxNewDebtAmount(uint _maxNewDebtAmount, uint _minTokenReceivedPerMai) external onlyOwner onlyInitialized {
    _fold(_maxNewDebtAmount, _minTokenReceivedPerMai);
  }

  /// @notice "Unfolds" the vault's debt by withdrawing the maximium available amount
  /// of collateral, swapping it for MAI, repaying the vault's debt, then withdrawing more
  /// collateral, and repeating this process. This function will revert if the vault is already
  /// below the minimum CDR, in which case you must call emergencyUnfold() instead.
  /// @param _minMaiReceivedPerToken minimum number of MAI to receive per token,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  function unfold(uint _minMaiReceivedPerToken) external onlyOwner onlyInitialized {
    _unfold(type(uint).max, _minMaiReceivedPerToken);
  }

  /// @notice "Unfolds" the vault's debt to the target CDR by withdrawing the maximium available amount
  /// of collateral, swapping it for MAI, repaying the vault's debt, then withdrawing more
  /// collateral, and repeating this process. This function will revert if the vault is already
  /// below the minimum CDR, in which case you must call emergencyUnfold() instead.
  /// @param _maxAmountCollateralSold the maximum amount of collateral that we want to
  /// sell for MAI to repay the debt. By passing this parameter, we can specify a
  /// smaller "unfold" in order to profit when the price of MAI is < $1.
  /// @param _minMaiReceivedPerToken minimum number of MAI to receive per token,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  function unfoldWithMaxAmountCollateralSold(uint _maxAmountCollateralSold, uint _minMaiReceivedPerToken) external onlyOwner onlyInitialized {
    _unfold(_maxAmountCollateralSold, _minMaiReceivedPerToken);
  }

  /// @notice "Unfolds" as much of the vault's debt as possible, when the CDR is already below the
  /// minimum, and no collateral can be withdrawn. This is accomplished by first borrowing MAI
  /// from a UniV2 pool to repay some of the vault's debt, then withdrawing collateral,
  /// swapping it for MAI, repaying more debt, and repeating this process, all before
  /// repaying the UniV2 flash loan. In the future we could consider only unfolding to the
  /// target CDR instead, but since this is an "emergency" function, we can just unfold all the way
  /// for now.
  /// @param _minMaiReceivedPerToken minimum number of MAI to receive per token,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  function emergencyUnfold(uint _minMaiReceivedPerToken) external onlyOwner onlyInitialized {
    _emergencyUnfold(_minMaiReceivedPerToken);
  }

  // emergency unfold continuation:
  function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _params) external {
    require(msg.sender == address(maiPairAddress), "authorization: not mai pair");
    require(_sender == address(this), "authorization: not us");

    (bool _maiIsToken0, uint _minMaiReceivedPerToken) = abi.decode(_params, (bool, uint));
    uint amtReceived = _maiIsToken0 ? _amount0 : _amount1;
    uint amountToRepay = amtReceived + (amtReceived * 3 / 997) + 1;
    QiDaoVault(vaultAddress).payBackToken(vaultId, amtReceived);
    _unfold(type(uint).max, _minMaiReceivedPerToken);

    require(vaultDebt() == 0, "vault still has debt after emergency unfold");
    _withdrawCollateral(vaultCollateral());

    // We should probably swap for the correct amount instead of going back and forth like this.
    // But this is OK for now since this is the "emergency" function
    _swapTokenForMai(IERC20(tokenAddress).balanceOf(address(this)), 0);
    require(_maiBalance() > amountToRepay, "not enough mai to repay flashswap");
    IERC20(maiAddress).transfer(maiPairAddress, amountToRepay);
    _swapMaiForToken(IERC20(maiAddress).balanceOf(address(this)), 0);
  }

  /// @notice withdraws collateral tokens from the QiDao vault.
  /// can only be called once the vault no longer has any debt. (e.g. after unfolding completely)
  function withdrawFromVault() external onlyOwner onlyInitialized {
    require(vaultDebt() == 0, "vault still has debt");
    _withdrawCollateral(vaultCollateral());
  }

  /// @notice "Unfolds" the vault's debt by withdrawing collateral, swapping it for MAI, repaying the
  /// vault's debt, and withdrawing more collateral. This function is likely to be used when someone
  /// wants to exit the vault, and we need to free up a certain amount of capital for them to exit.
  /// @param _amountCollateralToWithdraw the exact amount of collateral that we want to
  /// sell for MAI to repay the debt.
  /// @param _minMaiReceivedPerToken minimum number of MAI to receive per token,
  /// expressed with PRICE_PRECISION decimals. if fewer tokens are receieved,
  /// the call will revert.
  function withdrawFromVaultWithUnfold(uint _amountCollateralToWithdraw, uint _minMaiReceivedPerToken) external onlyOwner onlyInitialized {
    require(vaultDebt() > 0, "vault has no debt, call withdrawFromVault instead");
    require(_amountCollateralToWithdraw <= vaultCollateral(), "not enough collateral to withdraw");

    // Find a temporary CDR target that will allow us to withdraw the appropriate amount of collateral
    uint percentCollateralToWithdraw = _amountCollateralToWithdraw * 1e18 / vaultCollateral();
    uint startCdr = targetCdr;
    targetCdr = targetCdr + (vaultCdr() * percentCollateralToWithdraw / 1e18) + 50; // add a small buffer
    _unfold(type(uint).max, _minMaiReceivedPerToken);
    targetCdr = startCdr;

    _withdrawCollateral(_amountCollateralToWithdraw);
  }

  /// @notice withdraws full balance of collateral tokens from this contract.
  function withdrawFunds() external onlyOwner onlyInitialized {
    IERC20(tokenAddress).transfer(owner, tokenBalance());
  }

  /// @notice withdraws full balance of Qi tokens from this contract.
  function withdrawQi() external onlyOwner onlyInitialized {
    IERC20(qiAddress).transfer(owner, qiBalance());
  }

  /// @notice deposits collateral tokens from this contract to the QiDao vault.
  /// @param _amount amount of tokens to deposit
  function depositCollateral(uint _amount) external onlyOwner onlyInitialized {
    _depositCollateral(_amount);
  }

  /// @notice withdraw the balance of a token from the contract
  /// @param _token token address
  /// @param _amount token amount
  function rescueToken(address _token, uint _amount) external onlyOwner {
    if (_token == address(0)) {
      payable(owner).transfer(_amount);
    } else {
      IERC20(_token).transfer(owner, _amount);
    }
  }

  /// @notice "bails out" by transferring the underlying vault NFT to the owner
  /// after this function is called, the folder can be initialized again if needed
  function bailout() external onlyOwner onlyInitialized {
    QiDaoVault(vaultAddress).safeTransferFrom(address(this), owner, vaultId);
    vaultId = 0; // clear vaultId
  }

  // Public

  /// @return amount of MAI that can be borrowed based on the CDR that we are targeting.
  /// The return value of this function will also be capped at the current debt ceiling of vault.
  /// Expressed with 1e18 decimals of precision.
  function availableBorrows() view public returns (uint) {
    uint borrowsBasedOnCdr = _availableBorrowsByTargetCdr();
    uint borrowsBasedOnMai = QiDaoVault(vaultAddress).getDebtCeiling();

    // return the min
    return borrowsBasedOnCdr < borrowsBasedOnMai ? borrowsBasedOnCdr : borrowsBasedOnMai;
  }

  /// @return approximate USD value of the vault collateral, subtracted by the value of the vault's
  /// debt, subtracted by the repayment fees. (swap fees are not currently taken into account.)
  function vaultValue() view public returns (uint) {
    uint debt = vaultDebt();
    uint repaymentFees = debt * QiDaoVault(vaultAddress).closingFee() / 10000;
    uint additionalFees = debt * additionalFeeBps() / 10000;
    return _vaultCollateralValue() - debt - repaymentFees + additionalFees;
  }

  /// @return approximate underlying collateral balance, calculating by taking the vault collateral balance
  /// and subtracting the debt and repayment fees, all converted to be in collateral units.
  /// Note that swap fees are not accounted for in this calculation
  function approximateBalanceOfUnderlying() view public returns (uint) {
    uint debt = vaultDebt();
    uint repaymentFees = debt * QiDaoVault(vaultAddress).closingFee() / 10000;
    uint debtAndFeesInCollateral = (debt + repaymentFees) * PRICE_PRECISION / _collateralPrice();
    require(debtAndFeesInCollateral == 0 || debtAndFeesInCollateral < vaultCollateral(), "how is there more debt than collateral?");
    return tokenBalance() + vaultCollateral() - debtAndFeesInCollateral;
  }

  /// @return number of underlying tokens in this contract
  function tokenBalance() view public returns (uint) {
    return IERC20(tokenAddress).balanceOf(address(this));
  }

  /// @return number of Qi tokens in this contract
  function qiBalance() view public returns (uint) {
    return IERC20(qiAddress).balanceOf(address(this));
  }

  /// @return amount of MAI debt in the QiDao vault
  function vaultDebt() view public returns (uint) {
    return QiDaoVault(vaultAddress).vaultDebt(vaultId);
  }

  /// @return amount of collateral locked in the QiDao vault
  function vaultCollateral() view public returns (uint) {
    return QiDaoVault(vaultAddress).vaultCollateral(vaultId);
  }

  /// @return current CDR for this vault, expressed with CDR_PRECISION decimals of precision
  function vaultCdr() view public returns (uint) {
    uint debt = vaultDebt();
    return debt == 0 ? type(uint).max : _vaultCollateralValue() * CDR_PRECISION / debt;
  }

  // Internal

  function _fold(uint _maxNewDebtAmount, uint _minTokenReceivedPerMai) internal {
    uint newDebtAmount;

    for (uint i = 0; i < maxFoldsPerCall; i++) {
      uint borrowAmount = availableBorrows();

      if (newDebtAmount + borrowAmount > _maxNewDebtAmount) {
        borrowAmount = _maxNewDebtAmount - newDebtAmount;
      }

      require(i > 0 || borrowAmount > 0, "no borrows available"); // only require borrowAmount > 0 on the first loop
      if (vaultCdr() <= targetCdr) { break; }
      if (borrowAmount <= minAmountToFold) { break; }

      // borrow MAI
      QiDaoVault(vaultAddress).borrowToken(vaultId, borrowAmount);
      uint collateralBalanceBefore = tokenBalance();
      _swapMaiForToken(borrowAmount, borrowAmount * _minTokenReceivedPerMai / PRICE_PRECISION);
      _depositCollateral(tokenBalance() - collateralBalanceBefore);
      newDebtAmount = newDebtAmount + borrowAmount;
    }
  }

  function _unfold(uint _maxAmountCollateralSold, uint _minMaiReceivedPerToken) internal {
    uint cdrBefore = vaultCdr();
    require(cdrBefore > _vaultMinimumCdr(), "below minimum cdr, must unfold with flashloan instead");
    require(vaultCdr() < targetCdr, "no need to unfold");

    uint amountCollateralSold;

    for (uint i = 0; i < maxFoldsPerCall; i++) {
      if (vaultDebt() == 0) { break; }
      if (vaultCdr() > targetCdr) { break; }

      // withdraw collateral to unfold with
      // TODO: withdraw less if necessary
      uint withdrawAmt = _maxWithdrawableCollateral();

      // check for _maxAmountCollateralSold
      if (amountCollateralSold + withdrawAmt > _maxAmountCollateralSold) {
        withdrawAmt = _maxAmountCollateralSold - amountCollateralSold;
      }

      uint approxMaiReceivedPerWithdraw = withdrawAmt * _collateralPrice() / PRICE_PRECISION;
      uint hypotheticalNewCdr = vaultDebt() <= approxMaiReceivedPerWithdraw ? type(uint).max : ((vaultCollateral() - withdrawAmt) * _collateralPrice() / PRICE_PRECISION) * CDR_PRECISION / (vaultDebt() - approxMaiReceivedPerWithdraw);

      // will the new CDR be too high? if so, adjust the amount we are withdrawing
      if (hypotheticalNewCdr > targetCdr) {
        uint currentCdr = vaultCdr();
        withdrawAmt = withdrawAmt * (targetCdr - currentCdr) / (hypotheticalNewCdr - currentCdr);
      }

      if (withdrawAmt == 0) { break; }

      _withdrawCollateral(withdrawAmt);
      amountCollateralSold = amountCollateralSold + withdrawAmt;

      // This is kinda hacky - ideally we can calculate the input amount needed
      // for the exactAmountOut that we want. For now, we just use the slippage params,
      // and swap any leftover MAI back to the token
      uint minAmountMaiOut = withdrawAmt * _minMaiReceivedPerToken / PRICE_PRECISION;

      if (minAmountMaiOut > vaultDebt()) {
        withdrawAmt = vaultDebt() * _minMaiReceivedPerToken / PRICE_PRECISION;
        minAmountMaiOut = withdrawAmt * _minMaiReceivedPerToken / PRICE_PRECISION;
      }

      _swapTokenForMai(withdrawAmt, minAmountMaiOut);
      _repayAvailableMaiDebt();

      // Swap leftover MAI back to the token...
      if (vaultDebt() == 0 && _maiBalance() > 0) {
        _swapMaiForToken(_maiBalance(), 0);
      }
    }

    require(vaultCdr() > cdrBefore, "cdr is not higher after unfold, what went wrong?");
  }

  function _emergencyUnfold(uint _minMaiReceivedPerToken) internal {
    targetCdr = type(uint).max;
    uint debt = vaultDebt();
    require(debt > 0, "vault has no debt");

    // borrow 20% of total debt for emergency unfold
    // TODO: this will fail if we are WAY below the minimum CDR, but I'm not sure when that
    // would ever happen...
    uint amountMaiToBorrow = debt / 5;

    bool maiIsToken0 = IUniswapV2Pair(maiPairAddress).token0() == maiAddress;

    bytes memory data = abi.encode(
      maiIsToken0,
      _minMaiReceivedPerToken
    );

    IUniswapV2Pair(maiPairAddress).swap(
      maiIsToken0 ? amountMaiToBorrow : 0,
      maiIsToken0 ? 0 : amountMaiToBorrow,
      address(this),
      data
    );
  }

  function _setTargetCdr(uint _targetCdr) internal {
    require(_targetCdr > _vaultMinimumCdr(), "targetCdr too low");
    targetCdr = _targetCdr;
  }

  function _depositCollateral(uint _amount) internal {
    require(_amount > 0, "must deposit more than 0 tokens");
    require(_amount <= tokenBalance(), "not enough collateral to deposit");
    QiDaoVault(vaultAddress).depositCollateral(vaultId, _amount);
  }

  function _withdrawCollateral(uint _amount) internal {
    QiDaoVault(vaultAddress).withdrawCollateral(vaultId, _amount);
  }

  function _repayAvailableMaiDebt() internal {
    uint amt = _maiBalance();
    uint debt = vaultDebt();

    if (amt > debt) {
      amt = debt;
    }

    if (amt > 0) {
      QiDaoVault(vaultAddress).payBackToken(vaultId, amt);
    }
  }

  function _getRebalanceType() view internal returns (RebalanceType rt) {
    require(vaultCollateral() > 0, "vault has no collateral");
    uint cdr = vaultCdr();

    if (cdr < _vaultMinimumCdr()) {
      rt = RebalanceType.EMERGENCY_UNFOLD;
    } else if (cdr > targetCdr + foldTriggerDeviation) {
      rt = RebalanceType.FOLD;
    } else if (cdr < targetCdr) {
      rt = RebalanceType.UNFOLD;
    }
  }

  function _collateralPrice() view internal returns (uint) {
    return QiDaoVault(vaultAddress).getEthPriceSource();
  }

  /// @return approximate USD value of the vault collateral, expressed with 1e18 decimals of precision
  function _vaultCollateralValue() view internal returns (uint) {
    return vaultCollateral() * _collateralPrice() / PRICE_PRECISION;
  }

  /// @return Minimum CDR for this vault, expressed with CDR_PRECISION decimals of precision
  function _vaultMinimumCdr() view internal returns (uint) {
    return QiDaoVault(vaultAddress)._minimumCollateralPercentage() * CDR_PRECISION / 1e2;
  }

  function _maiBalance() view internal returns (uint) {
    return IERC20(maiAddress).balanceOf(address(this));
  }

  /// @return Maximium amount of collateral that can be withdrawn from the vault without
  /// going below the vault's minimum CDR. (Used for unfolding.)
  function _maxWithdrawableCollateral() view internal returns (uint) {
    uint minCollateralBalance = _vaultMinimumCdr() * vaultDebt() * CDR_PRECISION / _collateralPrice();
    uint actualCollateralBalance = vaultCollateral();
    return actualCollateralBalance - minCollateralBalance - 1;
  }

  function _availableBorrowsByTargetCdr() view internal returns (uint) {
    uint maxTotalBorrowsInCollateral = _vaultCollateralValue() * CDR_PRECISION / targetCdr;
    return maxTotalBorrowsInCollateral - vaultDebt();
  }

  // ERC20 stuff

  function _mint(address _account, uint _amount) internal virtual {
    require(_account != address(0), "ERC20: mint to the zero address");
    totalSupply += _amount;
    balances[_account] += _amount;
    emit Transfer(address(0), _account, _amount);
  }

  function _burn(address _account, uint _amount) internal virtual {
    require(_account != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = balances[_account];
    require(accountBalance >= _amount, "ERC20: burn _amount exceeds balance");
    unchecked {
      balances[_account] = accountBalance - _amount;
    }
    totalSupply -= _amount;

    emit Transfer(_account, address(0), _amount);
  }

  // Overrides
  function _approveSwaps() internal virtual;
  function _swapMaiForToken(uint _amountMai, uint _minAmountTokenReceived) internal virtual;
  function _swapTokenForMai(uint _amountToken, uint _minAmountMaiReceived) internal virtual;

  function additionalFeeBps() pure internal virtual returns (uint) {
    return 0;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IYVault {
  function withdraw(uint shares) external;
  function deposit(uint amount) external;
}

interface IAPool {
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount, bool _use_underlying) external;
  function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount, bool _use_underlying) external;
}

interface IVGHST {
  function enter(uint256 _amount) external;
  function leave(uint256 _share) external;
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);
  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);
  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);
  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

interface QiDaoVault {
  function _minimumCollateralPercentage() external view returns (uint256);

  function approve(address to, uint256 tokenId) external;

  function balanceOf(address owner) external view returns (uint256);

  function baseURI() external view returns (string memory);

  function borrowToken(uint256 vaultID, uint256 amount) external;

  function burn(uint256 amountToken) external;

  function changeEthPriceSource(address ethPriceSourceAddress) external;

  function checkCollateralPercentage(uint256 vaultID)
      external
      view
      returns (uint256);

  function checkCost(uint256 vaultID) external view returns (uint256);

  function checkExtract(uint256 vaultID) external view returns (uint256);

  function checkLiquidation(uint256 vaultID) external view returns (bool);

  function closingFee() external view returns (uint256);

  function collateral() external view returns (address);

  function createVault() external returns (uint256);

  function debtRatio() external view returns (uint256);

  function depositCollateral(uint256 vaultID, uint256 amount) external;

  function destroyVault(uint256 vaultID) external;

  function ethPriceSource() external view returns (address);

  function exists(uint256 vaultID) external view returns (bool);

  function gainRatio() external view returns (uint256);

  function getApproved(uint256 tokenId) external view returns (address);

  function getClosingFee() external view returns (uint256);

  function getDebtCeiling() external view returns (uint256);

  function getEthPriceSource() external view returns (uint256);

  function getPaid() external;

  function getTokenPriceSource() external view returns (uint256);

  function isApprovedForAll(address owner, address operator)
      external
      view
      returns (bool);

  function isOwner() external view returns (bool);

  function liquidateVault(uint256 vaultID) external;

  function mai() external view returns (address);

  function maticDebt(address) external view returns (uint256);

  function name() external view returns (string memory);

  function owner() external view returns (address);

  function ownerOf(uint256 tokenId) external view returns (address);

  function payBackToken(uint256 vaultID, uint256 amount) external;

  function priceSourceDecimals() external view returns (uint256);

  function renounceOwnership() external;

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external;

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
  ) external;

  function setApprovalForAll(address to, bool approved) external;

  function setDebtRatio(uint256 _debtRatio) external;

  function setGainRatio(uint256 _gainRatio) external;

  function setMinCollateralRatio(uint256 minimumCollateralPercentage)
      external;

  function setStabilityPool(address _pool) external;

  function setTokenURI(string memory _uri) external;

  function setTreasury(uint256 _treasury) external;

  function stabilityPool() external view returns (address);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function symbol() external view returns (string memory);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index)
      external
      view
      returns (uint256);

  function tokenPeg() external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalBorrowed() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external;

  function transferOwnership(address newOwner) external;

  function treasury() external view returns (uint256);

  function uri() external view returns (string memory);

  function vaultCollateral(uint256) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaultDebt(uint256) external view returns (uint256);

  function withdrawCollateral(uint256 vaultID, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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