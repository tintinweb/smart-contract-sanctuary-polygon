// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../interfaces/IAlloyxVault.sol";
import "../interfaces/IAlloyxVaultToken.sol";

/**
 * @title AlloyxVault
 * @notice Alloyx Vault holds the logic for stakers and investors to interact with different protocols
 * @author AlloyX
 */
contract AlloyxVault is IAlloyxVault, AdminUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ConfigHelper for AlloyxConfig;
  using SafeMath for uint256;

  uint256 internal constant DURA_MANTISSA = uint256(10)**uint256(18);
  uint256 internal constant USDC_MANTISSA = uint256(10)**uint256(6);
  uint256 internal constant ONE_YEAR_IN_SECONDS = 365.25 days;

  bool internal locked;
  uint256 totalAlyxClaimable;
  uint256 snapshotIdForLiquidation;
  uint256 preTotalUsdcValue;
  uint256 preTotalInvestorUsdcValue;
  uint256 preProtocolFee;
  uint256 prePermanentStakerGain;
  uint256 preRegularStakerGain;


  State public state;
  AlloyxConfig public config;
  IAlloyxVaultToken public vaultToken;
  Component[] public components;

  // snapshot=>(investor=>claimed)
  mapping(uint256 => mapping(address => bool)) internal hasClaimedLiquidationCompensation;
  uint256 lastProtocolFeeTimestamp;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event SetComponent(address indexed creatorAddress, address poolAddress, uint256 proportion, uint256 tranche, Source source);
  event SetState(State _state);

  /**
   * @notice Ensure there is no reentrant
   */
  modifier nonReentrant() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "operations paused");
    _;
  }

  /**
   * @notice If operation is not paused
   */
  modifier notPaused() {
    require(!config.isPaused(), "pause first");
    _;
  }

  /**
   * @notice If address is whitelisted
   */
  modifier isWhitelisted() {
    require(config.getWhitelist().isUserWhitelisted(msg.sender), "not whitelisted");
    _;
  }

  /**
   * @notice If the vault is at the right state
   */
  modifier atState(State _state) {
    require(state == _state, "wrong state");
    _;
  }

  /**
   * @notice If the transaction is triggered from manager contract
   */
  modifier onlyManager() {
    require(msg.sender == config.managerAddress(), "only manager");
    _;
  }

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   * @param _vaultTokenAddress the address of vault token contract
   */
  function initialize(address _configAddress, address _vaultTokenAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
    vaultToken = IAlloyxVaultToken(_vaultTokenAddress);
  }

  /**
   * @notice Set the state of the vault
   * @param _state the state of the contract
   */
  function setState(State _state) internal {
    state = _state;
    emit SetState(_state);
  }

  /**
   * @notice Get address of the vault token
   */
  function getTokenAddress() external view override returns (address) {
    return address(vaultToken);
  }

  /**
   * @notice Check if the vault is at certain state
   * @param _state the state to check
   */
  function isAtState(State _state) internal view returns (bool) {
    return state == _state;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Start the vault by setting up the portfolio of the vault and initial depositors' info
   * @param _components the initial setup of the portfolio for this vault
   * @param _usdcDepositorArray the array of DepositAmount containing the amount and address of the USDC depositors
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   * @param _totalUsdc total amount of USDC to start the vault with
   */
  function startVault(
    Component[] calldata _components,
    DepositAmount[] memory _usdcDepositorArray,
    DepositAmount[] memory _alyxDepositorArray,
    uint256 _totalUsdc
  ) external override onlyManager atState(State.INIT) {
    for (uint256 i = 0; i < _usdcDepositorArray.length; i++) {
      vaultToken.mint(usdcToAlloyxDura(_usdcDepositorArray[i].amount), _usdcDepositorArray[i].depositor);
    }

    for (uint256 i = 0; i < _alyxDepositorArray.length; i++) {
      permanentlyStake(_alyxDepositorArray[i].depositor, _alyxDepositorArray[i].amount);
    }

    preTotalInvestorUsdcValue = _totalUsdc;
    preTotalUsdcValue = _totalUsdc;
    lastProtocolFeeTimestamp = block.timestamp;

    setComponents(_components);
    setState(State.STARTED);
  }

  /**
   * @notice Reinstate governance called by manager contract only
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   */
  function reinstateGovernance(DepositAmount[] memory _alyxDepositorArray) external override onlyManager atState(State.NON_GOVERNANCE) {
    for (uint256 i = 0; i < _alyxDepositorArray.length; i++) {
      permanentlyStake(_alyxDepositorArray[i].depositor, _alyxDepositorArray[i].amount);
    }
    setState(State.STARTED);
  }

  /**
   * @notice Accrue the protocol fee by minting vault tokens to the treasury
   */
  function accrueProtocolFee() external override onlyManager {
    uint256 totalSupply = vaultToken.totalSupply();
    uint256 timeSinceLastFee = block.timestamp.sub(lastProtocolFeeTimestamp);
    uint256 totalTokenToMint = totalSupply.mul(timeSinceLastFee).mul(config.getInflationPerYearForProtocolFee()).div(10000).div(ONE_YEAR_IN_SECONDS);
    vaultToken.mint(totalTokenToMint, config.treasuryAddress());
    lastProtocolFeeTimestamp = block.timestamp;
  }

  /**
   * @notice Stake certain amount of ALYX as permanent staker, this can only be called internally during starting vault or reinstating governance
   */
  function permanentlyStake(address _account, uint256 _amount) internal {
    config.getStakeDesk().addPermanentStakeInfo(_account, _amount);
  }

  /**
   * @notice Stake certain amount of ALYX as regular staker, user needs to approve ALYX before calling this
   */
  function stake(uint256 _amount) external isWhitelisted notPaused nonReentrant {
    _transferERC20From(msg.sender, config.alyxAddress(), address(this), _amount);
    config.getStakeDesk().addRegularStakeInfo(msg.sender, _amount);
  }

  /**
   * @notice Unstake certain amount of ALYX as regular staker, user needs to approve ALYX before calling this
   */
  function unstake(uint256 _amount) external isWhitelisted notPaused nonReentrant {
    config.getStakeDesk().subRegularStakeInfo(msg.sender, _amount);
    _transferERC20(config.alyxAddress(), msg.sender, _amount);
  }

  /**
   * @notice Claim the available USDC and update the checkpoints
   */
  function claim() external isWhitelisted notPaused nonReentrant {
    updateUsdcValuesAndGains(0, 0);
    (uint256 regularGain, uint256 permanentGain) = claimable();
    _transferERC20(config.usdcAddress(), msg.sender, regularGain.add(permanentGain));
    preRegularStakerGain = preRegularStakerGain.sub(regularGain);
    prePermanentStakerGain = prePermanentStakerGain.sub(permanentGain);
    preTotalInvestorUsdcValue = preTotalInvestorUsdcValue.sub(regularGain.add(permanentGain));
    preTotalUsdcValue = preTotalUsdcValue.sub(regularGain.add(permanentGain));
    config.getStakeDesk().clearStakeInfoAfterClaiming(msg.sender);
  }

  /**
   * @notice Claimable USDC for ALYX stakers
   * @return the claimable USDC for regular staked ALYX
   * @return the claimable USDC for permanent staked ALYX
   */
  function claimable() public view returns (uint256, uint256) {
    uint256 totalRegularGain = getRegularStakerGainInVault();
    uint256 totalPermanentGain = getPermanentStakerGainInVault();
    uint256 regularGain = config.getStakeDesk().getRegularStakerProrataGain(msg.sender, totalRegularGain);
    uint256 permanentGain = config.getStakeDesk().getPermanentStakerProrataGain(msg.sender, totalPermanentGain);
    return (regularGain, permanentGain);
  }

  /**
   * @notice Liquidate the vault by unstaking from all permanent and regular stakers and burn all the governance tokens issued
   */
  function liquidate() external override onlyManager atState(State.STARTED) {
    config.getStakeDesk().unstakeAllStakersAndBurnAllGovTokens();
    totalAlyxClaimable = config.getAlyx().balanceOf(address(this));
    snapshotIdForLiquidation = vaultToken.snapshot();
    setState(State.NON_GOVERNANCE);
  }

  /**
   * @notice Claim liquidation compensation by user who has active investment at the time of liquidation
   */
  function claimLiquidationCompensation() external notPaused {
    require(snapshotIdForLiquidation > 0, "invalid snapshot id");
    uint256 balance = vaultToken.balanceOfAt(msg.sender, snapshotIdForLiquidation);
    require(balance > 0, "no balance at liquidation");
    require(!hasClaimedLiquidationCompensation[snapshotIdForLiquidation][msg.sender], "already claimed");
    uint256 supply = vaultToken.totalSupplyAt(snapshotIdForLiquidation);
    uint256 reward = totalAlyxClaimable.mul(balance).div(supply);
    _transferERC20(config.alyxAddress(), msg.sender, reward);
    hasClaimedLiquidationCompensation[snapshotIdForLiquidation][msg.sender] = true;
  }

  /**
   * @notice Update the internal checkpoint of total asset value, asset value for investors, the gains for permanent and regular stakers, and protocol fee
   * @param _increaseAmount the increase of amount for USDC by deposit
   * @param _decreaseAmount the decrease of amount for USDC by withdrawal
   */
  function updateUsdcValuesAndGains(uint256 _increaseAmount, uint256 _decreaseAmount) internal {
    (uint256 totalInvestorUsdcValue, uint256 permanentStakerGain, uint256 regularStakerGain) = getTotalInvestorUsdcValueAndAdditionalGains();
    preTotalUsdcValue = config.getOperator().getTotalBalanceInUsdc(address(this)).add(_increaseAmount).sub(_decreaseAmount);
    preTotalInvestorUsdcValue = totalInvestorUsdcValue.add(_increaseAmount).sub(_decreaseAmount);
    prePermanentStakerGain = prePermanentStakerGain.add(permanentStakerGain);
    preRegularStakerGain = preRegularStakerGain.add(regularStakerGain);
  }

  /**
   * @notice A Liquidity Provider can deposit USDC for Alloy Tokens
   * @param _tokenAmount Number of stable coin
   */
  function deposit(uint256 _tokenAmount) external isWhitelisted notPaused nonReentrant {
    uint256 amountToMint = usdcToAlloyxDura(_tokenAmount);
    updateUsdcValuesAndGains(_tokenAmount, 0);
    _transferERC20From(msg.sender, config.usdcAddress(), address(this), _tokenAmount);
    vaultToken.mint(amountToMint, msg.sender);
  }

  /**
   * @notice An Alloy token holder can deposit their tokens and redeem them for USDC
   * @param _tokenAmount Number of Alloy Tokens
   */
  function withdraw(uint256 _tokenAmount) external override isWhitelisted notPaused nonReentrant {
    uint256 amountToWithdraw = alloyxDuraToUsdc(_tokenAmount);
    vaultToken.burn(_tokenAmount, msg.sender);
    updateUsdcValuesAndGains(0, amountToWithdraw);
    _transferERC20(config.usdcAddress(), msg.sender, amountToWithdraw);
  }

  /**
   * @notice Rebalance the vault by performing deposits to different third party protocols based on the proportion defined
   */
  function rebalance() external onlyAdmin {
    updateUsdcValuesAndGains(0, 0);
    uint256 usdcValue = config.getUSDC().balanceOf(address(this));
    require(usdcValue > preRegularStakerGain.add(prePermanentStakerGain), "not enough usdc");
    uint256 amountToInvest = usdcValue.sub(preRegularStakerGain).sub(prePermanentStakerGain);
    for (uint256 i = 0; i < components.length; i++) {
      uint256 additionalInvestment = config.getOperator().getAdditionalDepositAmount(
        components[i].source,
        components[i].poolAddress,
        components[i].tranche,
        components[i].proportion,
        preTotalInvestorUsdcValue
      );
      if (additionalInvestment > 0 && amountToInvest > 0) {
        if (additionalInvestment > amountToInvest) {
          additionalInvestment = amountToInvest;
        }
        performDeposit(components[i].source, components[i].poolAddress, components[i].tranche, additionalInvestment);
        amountToInvest = amountToInvest.sub(additionalInvestment);
        if (amountToInvest == 0) {
          break;
        }
      }
    }
  }

  /**
   * @notice Get the total investor value aka the vault asset value, the additional gain from the last checkpoint for protocol, permanent staker, regular staker
   * @return the total investor value aka the vault asset value
   * @return the additional gain from last checkpoint for permanent stakers
   * @return the additional gain from last checkpoint for regular stakers
   */
  function getTotalInvestorUsdcValueAndAdditionalGains()
    private
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 totalValue = config.getOperator().getTotalBalanceInUsdc(address(this));
    if (totalValue > preTotalUsdcValue) {
      uint256 interest = totalValue.sub(preTotalUsdcValue);
      uint256 permanentStakerGain = config.getPermanentStakerProportion().mul(interest).div(10000);
      uint256 regularStakerGain = config.getRegularStakerProportion().mul(interest).div(10000);
      uint256 investorGain = interest.sub(permanentStakerGain).sub(regularStakerGain);
      uint256 totalInvestorUsdcValue = investorGain.add(preTotalInvestorUsdcValue);
      return (totalInvestorUsdcValue, permanentStakerGain, regularStakerGain);
    } else {
      uint256 loss = preTotalUsdcValue.sub(totalValue);
      uint256 totalInvestorUsdcValue = preTotalInvestorUsdcValue.sub(loss);
      return (totalInvestorUsdcValue, 0, 0);
    }
  }

  /**
   * @notice Get the USDC value of the total supply of DURA in this Vault
   */
  function getTotalUsdcValueForDuraInVault() public view returns (uint256) {
    (uint256 totalInvestorValue, , ) = getTotalInvestorUsdcValueAndAdditionalGains();
    return totalInvestorValue;
  }

  /**
   * @notice Get total the regular staker gain
   */
  function getRegularStakerGainInVault() public view returns (uint256) {
    (, , uint256 regularStakerGain) = getTotalInvestorUsdcValueAndAdditionalGains();
    return regularStakerGain.add(preRegularStakerGain);
  }

  /**
   * @notice Get total the permanent staker gain
   */
  function getPermanentStakerGainInVault() public view returns (uint256) {
    (, uint256 permanentStakerGain, ) = getTotalInvestorUsdcValueAndAdditionalGains();
    return permanentStakerGain.add(prePermanentStakerGain);
  }

  /**
   * @notice Set components of the vault
   * @param _components the components of this vault, including the address of the vault to invest
   */
  function setComponents(Component[] memory _components) public {
    require(msg.sender == config.managerAddress() || isAdmin(msg.sender), "only manager or admin");
    uint256 sumOfProportion = 0;
    for (uint256 i = 0; i < _components.length; i++) {
      sumOfProportion += _components[i].proportion;
    }
    require(sumOfProportion == 10000, "not equal to 100%");
    delete components;
    for (uint256 i = 0; i < _components.length; i++) {
      components.push(Component(_components[i].proportion, _components[i].poolAddress, _components[i].tranche, _components[i].source));
      emit SetComponent(msg.sender, _components[i].poolAddress, _components[i].proportion, _components[i].tranche, _components[i].source);
    }
  }

  function getComponents() public view returns (Component[] memory) {
    return components;
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _tokenId the token ID to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC721(
    address _tokenAddress,
    address _account,
    uint256 _tokenId
  ) public onlyAdmin {
    IERC721(_tokenAddress).safeTransferFrom(address(this), _account, _tokenId);
  }

  /**
   * @notice Migrate certain ERC20 to an address
   * @param _tokenAddress the token address to migrate
   * @param _to the address to transfer tokens to
   */
  function migrateERC20(address _tokenAddress, address _to) external onlyAdmin {
    uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    IERC20Upgradeable(_tokenAddress).safeTransfer(_to, balance);
  }

  /**
   * @notice Convert USDC Amount to Alloyx DURA
   * @param _amount the amount of usdc to convert to DURA token
   */
  function usdcToAlloyxDura(uint256 _amount) public view returns (uint256) {
    if (isAtState(State.INIT)) {
      return _amount.mul(DURA_MANTISSA).div(USDC_MANTISSA);
    }
    return _amount.mul(vaultToken.totalSupply()).div(getTotalUsdcValueForDuraInVault());
  }

  /**
   * @notice Convert Alloyx DURA to USDC amount
   * @param _amount the amount of DURA token to convert to usdc
   */
  function alloyxDuraToUsdc(uint256 _amount) public view returns (uint256) {
    if (isAtState(State.INIT)) {
      return _amount.mul(USDC_MANTISSA).div(DURA_MANTISSA);
    }
    return _amount.mul(getTotalUsdcValueForDuraInVault()).div(vaultToken.totalSupply());
  }

  /**
   * @notice Perform deposit operation to different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tranche the tranche to deposit
   * @param _amount the amount to deposit
   */
  function performDeposit(
    Source _source,
    address _poolAddress,
    uint256 _tranche,
    uint256 _amount
  ) public onlyAdmin nonReentrant {
    _transferERC20(config.usdcAddress(), config.operatorAddress(), _amount);
    config.getOperator().performDeposit(_source, _poolAddress, _tranche, _amount);
  }

  /**
   * @notice Perform withdrawal operation for different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tokenId the token ID
   * @param _amount the amount to withdraw
   */
  function performWithdraw(
    Source _source,
    address _poolAddress,
    uint256 _tokenId,
    uint256 _amount,
    WithdrawalStep _step
  ) public onlyAdmin nonReentrant {
    config.getOperator().performWithdraw(_source, _poolAddress, _tokenId, _amount, _step);
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function _transferERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) internal {
    IERC20Upgradeable(_tokenAddress).safeTransfer(_account, _amount);
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _from the address to transfer from
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function _transferERC20From(
    address _from,
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) internal {
    IERC20Upgradeable(_tokenAddress).safeTransferFrom(_from, _account, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IAlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title AlloyX Configuration
 * @notice The config information which contains all the relevant smart contracts and numeric and boolean configuration
 * @author AlloyX
 */

contract AlloyxConfig is IAlloyxConfig, AdminUpgradeable {
  mapping(uint256 => address) private addresses;
  mapping(uint256 => uint256) private numbers;
  mapping(uint256 => bool) private booleans;

  event AddressUpdated(address owner, uint256 index, address oldValue, address newValue);
  event NumberUpdated(address owner, uint256 index, uint256 oldValue, uint256 newValue);
  event BooleanUpdated(address owner, uint256 index, bool oldValue, bool newValue);

  function initialize() external initializer {
    __AdminUpgradeable_init(msg.sender);
  }

  /**
   * @notice Set the bool of certain index
   * @param booleanIndex the index to set
   * @param newBoolean new address to set
   */
  function setBoolean(uint256 booleanIndex, bool newBoolean) public override onlyAdmin {
    emit BooleanUpdated(msg.sender, booleanIndex, booleans[booleanIndex], newBoolean);
    booleans[booleanIndex] = newBoolean;
  }

  /**
   * @notice Set the address of certain index
   * @param addressIndex the index to set
   * @param newAddress new address to set
   */
  function setAddress(uint256 addressIndex, address newAddress) public override onlyAdmin {
    require(newAddress != address(0));
    emit AddressUpdated(msg.sender, addressIndex, addresses[addressIndex], newAddress);
    addresses[addressIndex] = newAddress;
  }

  /**
   * @notice Set the number of certain index
   * @param index the index to set
   * @param newNumber new number to set
   */
  function setNumber(uint256 index, uint256 newNumber) public override onlyAdmin {
    emit NumberUpdated(msg.sender, index, numbers[index], newNumber);
    numbers[index] = newNumber;
  }

  /**
   * @notice Copy from other config
   * @param _initialConfig the configuration to copy from
   * @param numbersLength the length of the numbers to copy from
   * @param addressesLength the length of the addresses to copy from
   * @param boolsLength the length of the bools to copy from
   */
  function copyFromOtherConfig(
    address _initialConfig,
    uint256 numbersLength,
    uint256 addressesLength,
    uint256 boolsLength
  ) external onlyAdmin {
    IAlloyxConfig initialConfig = IAlloyxConfig(_initialConfig);
    for (uint256 i = 0; i < numbersLength; i++) {
      setNumber(i, initialConfig.getNumber(i));
    }

    for (uint256 i = 0; i < addressesLength; i++) {
      setAddress(i, initialConfig.getAddress(i));
    }

    for (uint256 i = 0; i < boolsLength; i++) {
      setBoolean(i, initialConfig.getBoolean(i));
    }
  }

  /**
   * @notice Get address for index
   * @param index the index to get address from
   */
  function getAddress(uint256 index) external view override returns (address) {
    return addresses[index];
  }

  /**
   * @notice Get number for index
   * @param index the index to get number from
   */
  function getNumber(uint256 index) external view override returns (uint256) {
    return numbers[index];
  }

  /**
   * @notice Get bool for index
   * @param index the index to get bool from
   */
  function getBoolean(uint256 index) external view override returns (bool) {
    return booleans[index];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../goldfinch/interfaces/ISeniorPool.sol";
import "../../goldfinch/interfaces/IPoolTokens.sol";
import "../interfaces/IAlloyxWhitelist.sol";
import "../interfaces/IAlloyxTreasury.sol";
import "../interfaces/IGoldfinchDesk.sol";
import "../interfaces/ITruefiDesk.sol";
import "../interfaces/IBackerRewards.sol";
import "../interfaces/IMapleDesk.sol";
import "../interfaces/IClearPoolDesk.sol";
import "../interfaces/IRibbonDesk.sol";
import "../interfaces/IRibbonLendDesk.sol";
import "../interfaces/ICredixDesk.sol";
import "../interfaces/ICredixOracle.sol";
import "../interfaces/IAlloyxManager.sol";
import "../interfaces/IAlloyxStakeInfo.sol";
import "../interfaces/IAlloyxOperator.sol";
import "../interfaces/IStakeDesk.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IFluxDesk.sol";
import "../interfaces/IBackedDesk.sol";
import "../interfaces/IBackedOracle.sol";
import "../interfaces/IERC20Token.sol";
import "./AlloyxConfig.sol";
import "./ConfigOptions.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the AlloyxConfig contract
 * @author AlloyX
 */

library ConfigHelper {
  function managerAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Manager));
  }

  function alyxAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ALYX));
  }

  function treasuryAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Treasury));
  }

  function configAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Config));
  }

  function permanentStakeInfoAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PermanentStakeInfo));
  }

  function regularStakeInfoAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.RegularStakeInfo));
  }

  function stakeDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.StakeDesk));
  }

  function goldfinchDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchDesk));
  }

  function truefiDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TruefiDesk));
  }

  function mapleDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.MapleDesk));
  }

  function clearPoolDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ClearPoolDesk));
  }

  function ribbonDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.RibbonDesk));
  }

  function ribbonLendDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.RibbonLendDesk));
  }

  function credixDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CredixDesk));
  }

  function credixOracleAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CredixOracle));
  }

  function backerRewardsAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackerRewards));
  }

  function whitelistAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Whitelist));
  }

  function poolTokensAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PoolTokens));
  }

  function seniorPoolAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SeniorPool));
  }

  function fiduAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.FIDU));
  }

  function gfiAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GFI));
  }

  function usdcAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.USDC));
  }

  function mplAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.MPL));
  }

  function wethAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.WETH));
  }

  function swapRouterAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SwapRouter));
  }

  function operatorAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Operator));
  }

  function fluxTokenAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.FluxToken));
  }

  function fluxDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.FluxDesk));
  }

  function backedDeskAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackedDesk));
  }

  function backedOracleAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackedOracle));
  }

  function backedTokenAddress(AlloyxConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackedToken));
  }

  function getManager(AlloyxConfig config) internal view returns (IAlloyxManager) {
    return IAlloyxManager(managerAddress(config));
  }

  function getAlyx(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(alyxAddress(config));
  }

  function getTreasury(AlloyxConfig config) internal view returns (IAlloyxTreasury) {
    return IAlloyxTreasury(treasuryAddress(config));
  }

  function getPermanentStakeInfo(AlloyxConfig config) internal view returns (IAlloyxStakeInfo) {
    return IAlloyxStakeInfo(permanentStakeInfoAddress(config));
  }

  function getRegularStakeInfo(AlloyxConfig config) internal view returns (IAlloyxStakeInfo) {
    return IAlloyxStakeInfo(regularStakeInfoAddress(config));
  }

  function getConfig(AlloyxConfig config) internal view returns (IAlloyxConfig) {
    return IAlloyxConfig(treasuryAddress(config));
  }

  function getStakeDesk(AlloyxConfig config) internal view returns (IStakeDesk) {
    return IStakeDesk(stakeDeskAddress(config));
  }

  function getGoldfinchDesk(AlloyxConfig config) internal view returns (IGoldfinchDesk) {
    return IGoldfinchDesk(goldfinchDeskAddress(config));
  }

  function getTruefiDesk(AlloyxConfig config) internal view returns (ITruefiDesk) {
    return ITruefiDesk(truefiDeskAddress(config));
  }

  function getMapleDesk(AlloyxConfig config) internal view returns (IMapleDesk) {
    return IMapleDesk(mapleDeskAddress(config));
  }

  function getClearPoolDesk(AlloyxConfig config) internal view returns (IClearPoolDesk) {
    return IClearPoolDesk(clearPoolDeskAddress(config));
  }

  function getRibbonDesk(AlloyxConfig config) internal view returns (IRibbonDesk) {
    return IRibbonDesk(ribbonDeskAddress(config));
  }

  function getRibbonLendDesk(AlloyxConfig config) internal view returns (IRibbonLendDesk) {
    return IRibbonLendDesk(ribbonLendDeskAddress(config));
  }

  function getCredixDesk(AlloyxConfig config) internal view returns (ICredixDesk) {
    return ICredixDesk(credixDeskAddress(config));
  }

  function getCredixOracle(AlloyxConfig config) internal view returns (ICredixOracle) {
    return ICredixOracle(credixOracleAddress(config));
  }

  function getBackerRewards(AlloyxConfig config) internal view returns (IBackerRewards) {
    return IBackerRewards(backerRewardsAddress(config));
  }

  function getWhitelist(AlloyxConfig config) internal view returns (IAlloyxWhitelist) {
    return IAlloyxWhitelist(whitelistAddress(config));
  }

  function getPoolTokens(AlloyxConfig config) internal view returns (IPoolTokens) {
    return IPoolTokens(poolTokensAddress(config));
  }

  function getSeniorPool(AlloyxConfig config) internal view returns (ISeniorPool) {
    return ISeniorPool(seniorPoolAddress(config));
  }

  function getFIDU(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(fiduAddress(config));
  }

  function getGFI(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(gfiAddress(config));
  }

  function getUSDC(AlloyxConfig config) internal view returns (IERC20Token) {
    return IERC20Token(usdcAddress(config));
  }

  function getMPL(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(mplAddress(config));
  }

  function getWETH(AlloyxConfig config) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(wethAddress(config));
  }

  function getSwapRouter(AlloyxConfig config) internal view returns (ISwapRouter) {
    return ISwapRouter(swapRouterAddress(config));
  }

  function getOperator(AlloyxConfig config) internal view returns (IAlloyxOperator) {
    return IAlloyxOperator(operatorAddress(config));
  }

  function getFluxToken(AlloyxConfig config) internal view returns (ICToken) {
    return ICToken(fluxTokenAddress(config));
  }

  function getFluxDesk(AlloyxConfig config) internal view returns (IFluxDesk) {
    return IFluxDesk(fluxDeskAddress(config));
  }

  function getBackedDesk(AlloyxConfig config) internal view returns (IBackedDesk) {
    return IBackedDesk(backedDeskAddress(config));
  }

  function getBackedOracle(AlloyxConfig config) internal view returns (IBackedOracle) {
    return IBackedOracle(backedOracleAddress(config));
  }

  function getBackedToken(AlloyxConfig config) internal view returns (IERC20Token) {
    return IERC20Token(backedTokenAddress(config));
  }

  function getInflationPerYearForProtocolFee(AlloyxConfig config) internal view returns (uint256) {
    uint256 inflationPerYearForProtocolFee = config.getNumber(uint256(ConfigOptions.Numbers.InflationPerYearForProtocolFee));
    require(inflationPerYearForProtocolFee <= 10000, "inflation per year should be smaller or equal to 10000");
    return inflationPerYearForProtocolFee;
  }

  function getRegularStakerProportion(AlloyxConfig config) internal view returns (uint256) {
    uint256 regularStakerProportion = config.getNumber(uint256(ConfigOptions.Numbers.RegularStakerProportion));
    require(regularStakerProportion <= 10000, "regular staker proportion should be smaller or equal to 10000");
    return regularStakerProportion;
  }

  function getPermanentStakerProportion(AlloyxConfig config) internal view returns (uint256) {
    uint256 permanentStakerProportion = config.getNumber(uint256(ConfigOptions.Numbers.PermanentStakerProportion));
    require(permanentStakerProportion <= 10000, "permanent staker should be smaller or equal to 10000");
    return permanentStakerProportion;
  }

  function getUniswapFeeBasePoint(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.UniswapFeeBasePoint));
  }

  function getMinDelay(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.MinDelay));
  }

  function getQuorumPercentage(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.QuorumPercentage));
  }

  function getVotingPeriod(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.VotingPeriod));
  }

  function getVotingDelay(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.VotingDelay));
  }

  function getThresholdAlyxForVaultCreation(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ThresholdAlyxForVaultCreation));
  }

  function getThresholdUsdcForVaultCreation(AlloyxConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ThresholdUsdcForVaultCreation));
  }

  function isPaused(AlloyxConfig config) internal view returns (bool) {
    return config.getBoolean(uint256(ConfigOptions.Booleans.IsPaused));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IAlloyx.sol";

/**
 * @title IAlloyxVault
 * @author AlloyX
 */
interface IAlloyxVault is IAlloyx {
  /**
   * @notice Start the vault by setting up the portfolio of the vault and initial depositors' info
   * @param _components the initial setup of the portfolio for this vault
   * @param _usdcDepositorArray the array of DepositAmount containing the amount and address of the USDC depositors
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   * @param _totalUsdc total amount of USDC to start the vault with
   */
  function startVault(
    Component[] calldata _components,
    DepositAmount[] memory _usdcDepositorArray,
    DepositAmount[] memory _alyxDepositorArray,
    uint256 _totalUsdc
  ) external;

  /**
   * @notice Reinstate governance called by manager contract only
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   */
  function reinstateGovernance(DepositAmount[] memory _alyxDepositorArray) external;

  /**
   * @notice Liquidate the vault by unstaking from all permanent and regular stakers and burn all the governance tokens issued
   */
  function liquidate() external;

  /**
   * @notice Accrue the protocol fee by minting vault tokens to the treasury
   */
  function accrueProtocolFee() external;

  /**
   * @notice An Alloy token holder can deposit their tokens and redeem them for USDC
   * @param _tokenAmount Number of Alloy Tokens
   */
  function withdraw(uint256 _tokenAmount) external;

  /**
   * @notice Get address of the vault token
   */
  function getTokenAddress() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IAlloyxVaultToken
 * @author AlloyX
 */
interface IAlloyxVaultToken {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function mint(uint256 _tokenToMint, address _address) external;

  function burn(uint256 _tokenBurn, address _address) external;

  function snapshot() external returns (uint256);

  function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

  function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title AdminUpgradeable
 * @notice Base class for all the contracts which need convenience methods to operate admin rights
 * @author AlloyX
 */
abstract contract AdminUpgradeable is AccessControlUpgradeable {
  function __AdminUpgradeable_init(address deployer) internal onlyInitializing {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, deployer);
  }

  /**
   * @notice Only admin users can perform
   */
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Restricted to admins");
    _;
  }

  /**
   * @notice Check if the account is one of the admins
   * @param account The account to check
   */
  function isAdmin(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxConfig
 * @author AlloyX
 */
interface IAlloyxConfig {
  function getNumber(uint256 index) external returns (uint256);

  function getAddress(uint256 index) external returns (address);

  function getBoolean(uint256 index) external returns (bool);

  function setAddress(uint256 index, address newAddress) external;

  function setNumber(uint256 index, uint256 newNumber) external;

  function setBoolean(uint256 booleanIndex, bool newBoolean) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxTreasury
 * @author AlloyX
 */
interface IAlloyxTreasury {
  /**
   * @notice Withdraw the protocol fee from one vault, restricted to manager
   * @param _vaultAddress the vault address to collect fee
   */
  function withdrawProtocolFee(address _vaultAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ITruefiDesk
 * @author AlloyX
 */
interface ITruefiDesk {
  /**
   * @notice Get the USDC value of the truefi wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getTruefiWalletUsdcValue(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Deposit treasury USDC to truefi tranche vault
   * @param _vaultAddress the vault address
   * @param _address the address of tranche vault
   * @param _amount the amount to deposit
   */
  function depositToTruefi(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external;

  /**
   * @notice Withdraw USDC from truefi Tranche portfolio and deposit to treasury
   * @param _vaultAddress the vault address
   * @param _address the address of Tranche portfolio
   * @param _amount the amount to withdraw in USDC
   * @return shares to burn during withdrawal https://github.com/trusttoken/contracts-carbon/blob/c9694396fc01c851a6c006d65c9e3420af723ee2/contracts/TrancheVault.sol#L262
   */
  function withdrawFromTruefi(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Get the USDC value of the truefi wallet on one tranche vault address
   * @param _vaultAddress the pool address of which we calculate the balance
   * @param _address the address of Tranche portfolio
   */
  function getTruefiWalletUsdcValueOfPortfolio(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Get the Truefi Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getTruefiVaultAddressesForAlloyxVault(address _vaultAddress) external view returns (address[] memory);

  /**
   * @notice Get the Truefi Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _truefiVault the address of Truefi vault
   */
  function getTruefiVaultShareForAlloyxVault(address _vaultAddress, address _truefiVault) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxWhitelist
 * @author AlloyX
 */
interface IAlloyxWhitelist {
  /**
   * @notice Check whether user is whitelisted
   * @param _whitelistedAddress The address to whitelist.
   */
  function isUserWhitelisted(address _whitelistedAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./ITranchedPool.sol";

abstract contract ISeniorPool {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  function withdrawInFidu(uint256 fiduAmount) external virtual returns (uint256 amount);

  function sweepToCompound() public virtual;

  function sweepFromCompound() public virtual;

  function invest(ITranchedPool pool) public virtual;

  function estimateInvestment(ITranchedPool pool) public view virtual returns (uint256);

  function redeem(uint256 tokenId) public virtual;

  function writedown(uint256 tokenId) public virtual;

  function calculateWritedown(uint256 tokenId) public view virtual returns (uint256 writedownAmount);

  function assets() public view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IGoldfinchDesk
 * @author AlloyX
 */
interface IGoldfinchDesk {
  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getGoldFinchPoolTokenBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _poolAddress the pool address of which we calculate the balance
   * @param _tranche the tranche
   */
  function getGoldFinchPoolTokenBalanceInUsdcForPool(
    address _vaultAddress,
    address _poolAddress,
    uint256 _tranche
  ) external returns (uint256);

  /**
   * @notice Widthdraw GFI from pool token
   * @param _vaultAddress the vault address
   * @param _tokenIDs the IDs of token to sell
   */
  function withdrawGfiFromMultiplePoolTokens(address _vaultAddress, uint256[] calldata _tokenIDs) external;

  /**
   * @notice Fidu Value in Vault in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getFiduBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Purchase pool token to get pooltoken
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   * @param _poolAddress the pool address to buy from
   * @param _tranche the tranch id
   */
  function purchasePoolToken(
    address _vaultAddress,
    uint256 _amount,
    address _poolAddress,
    uint256 _tranche
  ) external;

  /**
   * @notice Widthdraw from junior token to get repayments
   * @param _vaultAddress the vault address
   * @param _tokenID the ID of token to sell
   * @param _amount the amount to withdraw
   * @param _poolAddress the pool address to withdraw from
   */
  function withdrawFromJuniorToken(
    address _vaultAddress,
    uint256 _tokenID,
    uint256 _amount,
    address _poolAddress
  ) external;

  /**
   * @notice Purchase FIDU
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   */
  function purchaseFIDU(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Sell senior token to redeem FIDU
   * @param _vaultAddress the vault address
   * @param _amount the amount of FIDU to sell
   */
  function sellFIDU(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice GoldFinch PoolToken IDs
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getGoldFinchPoolTokenIds(address _vaultAddress) external view returns (uint256[] memory);

  /**
   * @notice Using the Goldfinch contracts, read the principal, redeemed and redeemable values
   * @param _tokenID The backer NFT id
   */
  function getJuniorTokenValue(uint256 _tokenID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IBackerRewards
 * @author AlloyX
 */
interface IBackerRewards {
  /**
   * @notice PoolToken request to withdraw multiple PoolTokens allocated rewards
   * @param tokenIds Array of pool token id
   */
  function withdrawMultiple(uint256[] calldata tokenIds) external;

  /**
   * @notice PoolToken request to withdraw all allocated rewards
   * @param tokenId Pool token id
   */
  function withdraw(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPoolTokens is IERC721, IERC721Enumerable {
  event TokenMinted(address indexed owner, address indexed pool, uint256 indexed tokenId, uint256 amount, uint256 tranche);

  event TokenRedeemed(address indexed owner, address indexed pool, uint256 indexed tokenId, uint256 principalRedeemed, uint256 interestRedeemed, uint256 tranche);
  event TokenBurned(address indexed owner, address indexed pool, uint256 indexed tokenId);

  struct TokenInfo {
    address pool;
    uint256 tranche;
    uint256 principalAmount;
    uint256 principalRedeemed;
    uint256 interestRedeemed;
  }

  struct MintParams {
    uint256 principalAmount;
    uint256 tranche;
  }

  function mint(MintParams calldata params, address to) external returns (uint256);

  function redeem(
    uint256 tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed
  ) external;

  function burn(uint256 tokenId) external;

  function onPoolCreated(address newPool) external;

  function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory);

  function validPool(address sender) external view returns (bool);

  function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IMapleDesk
 * @author AlloyX
 */
interface IMapleDesk {
  /**
   * @notice Maple Wallet Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getMapleWalletUsdcValue(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get the Usdc value of the truefi wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool
   */
  function getMapleWalletUsdcValueOfPool(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Get the Maple balance
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool
   */
  function getMapleBalanceOfPool(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) external;

  /**
   * @notice Deposit treasury USDC to Maple pool
   * @param _vaultAddress the vault address
   * @param _address the address of pool
   * @param _amount the amount to deposit
   */
  function depositToMaple(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Withdraw USDC from Maple managed portfolio and deposit to treasury
   * @param _vaultAddress the vault address
   * @param _address the address of pool
   * @param _amount the amount to withdraw in USDC
   */
  function withdrawFromMaple(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Initiate the countdown from the lockup period on Maple side
   * @param _vaultAddress the vault address
   */
  function requestWithdraw(
    address _vaultAddress,
    address _address,
    uint256 _shares
  ) external;

  /**
   * @notice Get the Maple Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getMaplePoolAddressesForVault(address _vaultAddress) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IClearPoolDesk
 * @author AlloyX
 */
interface IClearPoolDesk {
  /**
   * @notice Get the Usdc value of the Clear Pool wallet
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getClearPoolWalletUsdcValue(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get the Usdc value of the Clear Pool wallet on one pool master address
   * @param _vaultAddress the pool address of which we calculate the balance
   * @param _address the address of pool master
   */
  function getClearPoolUsdcValueOfPoolMaster(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Deposit treasury USDC to ClearPool pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to deposit
   */
  function provide(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Withdraw USDC from ClearPool pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to withdraw in pool master tokens
   */
  function redeem(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Get the ClearPool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getClearPoolAddressesForVault(address _vaultAddress) external view returns (address[] memory);

  /**
   * @notice Get the ClearPool balance for the alloyx vault
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   */
  function getClearPoolBalanceForVault(address _vaultAddress, address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ICredixOracle
 * @author AlloyX
 */
interface ICredixOracle {
  /**
   * @notice Get the net asset value of vault
   * @param _vaultAddress the vault address to increase USDC value on
   */
  function getNetAssetValueInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Increase the USDC value after the vault provides USDC to credix desk
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _increasedValue the increased value of the vault
   */
  function increaseUsdcValue(address _vaultAddress, uint256 _increasedValue) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ICredixDesk
 * @author AlloyX
 */
interface ICredixDesk {
  /**
   * @notice Get the Usdc value of the credix wallet
   * @param _poolAddress the address of pool
   */
  function getCredixWalletUsdcValue(address _poolAddress) external view returns (uint256);

  /**
   * @notice Deposit the Usdc value
   * @param _vaultAddress the vault address
   * @param _amount the amount to transfer
   */
  function increaseUsdcValueForPool(address _vaultAddress, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IRibbonLendDesk
 * @author AlloyX
 */
interface IRibbonLendDesk {
  /**
   * @notice Deposit vault USDC to RibbonLend pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to deposit
   */
  function provide(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Withdraw USDC from RibbonLend pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to withdraw in pool master tokens
   */
  function redeem(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Get the USDC value of the Clear Pool wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getRibbonLendWalletUsdcValue(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get the USDC value of the Clear Pool wallet on one pool master address
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool master
   */
  function getRibbonLendUsdcValueOfPoolMaster(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Get the RibbonLend Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getRibbonLendVaultAddressesForAlloyxVault(address _vaultAddress) external view returns (address[] memory);

  /**
   * @notice Get the RibbonLend Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _ribbonLendVault the address of RibbonLend vault
   */
  function getRibbonLendVaultShareForAlloyxVault(address _vaultAddress, address _ribbonLendVault) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IFluxDesk
 * @author AlloyX
 */
interface IFluxDesk {
  /**
   * @notice Purchase Flux
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   */
  function mint(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Redeem FLUX
   * @param _vaultAddress the vault address
   * @param _amount the amount of FLUX to sell
   */
  function redeem(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Fidu Value in Vault in term of USDC
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getFluxBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Flux Balance in Vault in term
   * @param _vaultAddress the pool address
   */
  function getFluxBalance(address _vaultAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IBackedDesk
 * @author AlloyX
 */
interface IBackedDesk {
  /**
   * @notice Deposit USDC to the desk and prepare for being taken to invest in Backed
   * @param _vaultAddress the address of vault
   * @param _amount the amount of USDC
   */
  function deposit(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Deposit USDC to the desk and prepare for being taken to invest in Backed
   * @param _vaultAddress the address of vault
   */
  function getBackedTokenValueInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get the amount of Backed token for vault
   * @param _vaultAddress the address of vault
   */
  function getConfirmedBackedTokenAmount(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get pending values in USDC for vault
   * @param _vaultAddress the address of vault
   */
  function getPendingVaultUsdcValue(address _vaultAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxManager
 * @author AlloyX
 */
interface IAlloyxManager {
  /**
   * @notice Check if the vault is a vault created by the manager
   * @param _vault the address of the vault
   * @return true if it is a vault otherwise false
   */
  function isVault(address _vault) external returns (bool);

  /**
   * @notice Get all the addresses of vaults
   * @return the addresses of vaults
   */
  function getVaults() external returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IStakeDesk
 * @author AlloyX
 */
interface IStakeDesk {
  /**
   * @notice Set map from vault address to gov token address
   * @param _vaultAddress the address of the vault
   * @param _govTokenAddress the address of the governance token
   */
  function setGovTokenForVault(address _vaultAddress, address _govTokenAddress) external;

  /**
   * @notice Stake more ALYX into the vault, which will cause to mint govToken for the staker
   * @param _account the account to add stake
   * @param _amount the amount the message sender intending to stake in
   */
  function addPermanentStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Unstake some from the vault, which will cause the vault to burn govToken for the staker
   * @param _account the account to reduce stake
   * @param _amount the amount the message sender intending to unstake
   */
  function subPermanentStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Stake more into the vault,which will cause to mint govToken for the staker
   * @param _account the account to add stake
   * @param _amount the amount the message sender intending to stake in
   */
  function addRegularStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Unstake some from the vault, which will cause the vault to burn govToken for the staker
   * @param _account the account to reduce stake
   * @param _amount the amount the message sender intending to unstake
   */
  function subRegularStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Unstake all the regular and permanent stakers and burn all govTokens
   */
  function unstakeAllStakersAndBurnAllGovTokens() external;

  /**
   * @notice Get the prorated gain for regular staker
   * @param _staker the staker to calculate the gain to whom the gain is entitled
   * @param _gain the total gain for all regular stakers
   */
  function getRegularStakerProrataGain(address _staker, uint256 _gain) external view returns (uint256);

  /**
   * @notice Get the prorated gain for permanent staker
   * @param _staker the staker to calculate the gain to whom the gain is entitled
   * @param _gain the total gain for all permanent stakers
   */
  function getPermanentStakerProrataGain(address _staker, uint256 _gain) external view returns (uint256);

  /**
   * @notice Clear all stake info for staker
   * @param _staker the staker to clear the stake info for
   */
  function clearStakeInfoAfterClaiming(address _staker) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our AlloyxConfig contract
 * @author AlloyX
 */

library ConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER chan ge the order.
  enum Booleans {
    IsPaused
  }
  enum Numbers {
    InflationPerYearForProtocolFee, // In 4 decimals, where 100 means 1%
    RegularStakerProportion, // In 4 decimals, where 100 means 1%
    PermanentStakerProportion, // In 4 decimals, where 100 means 1%
    MinDelay,
    QuorumPercentage,
    VotingPeriod,
    VotingDelay,
    ThresholdAlyxForVaultCreation,
    ThresholdUsdcForVaultCreation,
    UniswapFeeBasePoint
  }
  enum Addresses {
    Manager,
    ALYX,
    Treasury,
    PermanentStakeInfo,
    RegularStakeInfo,
    Config,
    StakeDesk,
    GoldfinchDesk,
    TruefiDesk,
    MapleDesk,
    ClearPoolDesk,
    RibbonDesk,
    RibbonLendDesk,
    CredixDesk,
    CredixOracle,
    Whitelist,
    BackerRewards,
    PoolTokens,
    SeniorPool,
    FIDU,
    GFI,
    USDC,
    MPL,
    WETH,
    SwapRouter,
    Operator,
    FluxToken,
    FluxDesk,
    BackedDesk,
    BackedOracle,
    BackedToken
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IAlloyx.sol";

/**
 * @title IAlloyxOperator
 * @author AlloyX
 */
interface IAlloyxOperator is IAlloyx {
  /**
   * @notice Alloy DURA Token Value in terms of USDC from all the protocols involved
   * @param _vaultAddress the address of vault
   */
  function getTotalBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get additional amount to deposit using the proportion of the component of the vault and total vault value
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tranche the tranche to deposit
   * @param _proportion the proportion to deposit
   * @param _investableUsdc the amount of usdc investable
   */
  function getAdditionalDepositAmount(
    Source _source,
    address _poolAddress,
    uint256 _tranche,
    uint256 _proportion,
    uint256 _investableUsdc
  ) external returns (uint256);

  /**
   * @notice Perform deposit operation to different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tranche the tranche to deposit
   * @param _amount the amount to deposit
   */
  function performDeposit(
    Source _source,
    address _poolAddress,
    uint256 _tranche,
    uint256 _amount
  ) external;

  /**
   * @notice Perform withdrawal operation for different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tokenId the token ID
   * @param _amount the amount to withdraw
   */
  function performWithdraw(
    Source _source,
    address _poolAddress,
    uint256 _tokenId,
    uint256 _amount,
    WithdrawalStep _step
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IRibbonDesk
 * @author AlloyX
 */
interface IRibbonDesk {
  function getRibbonWalletUsdcValue(address _alloyxVault) external view returns (uint256);

  /**
   * @notice Get the Usdc value of the Ribbon wallet
   * @param _vaultAddress the address of alloyx vault
   */
  function getRibbonUsdcValueOfVault(address _vaultAddress, address _ribbonVault) external view returns (uint256);

  /**
   * @notice Deposits the `asset` from vault.
   * @param _vaultAddress the vault address
   * @param _amount is the amount of `asset` to deposit
   * @param _ribbonVault is the address of the vault
   */
  function deposit(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _amount
  ) external;

  /**
   * @notice Initiates a withdrawal that can be processed once the round completes
   * @param _vaultAddress the vault address
   * @param _numShares is the number of shares to withdraw
   * @param _ribbonVault is the address of the vault
   */
  function initiateWithdraw(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _numShares
  ) external;

  /**
   * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
   * @param _vaultAddress the vault address
   * @param _poolAddress the pool address
   */
  function completeWithdraw(address _vaultAddress, address _poolAddress) external;

  /**
   * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
   * @param _vaultAddress the vault address
   * @param _ribbonVault is the address of the vault
   * @param _amount is the amount to withdraw in USDC https://github.com/ribbon-finance/ribbon-v2/blob/e9270281c7aa7433851ecee7f326c37bce28aec1/contracts/vaults/YearnVaults/RibbonThetaYearnVault.sol#L236
   */
  function withdrawInstantly(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _amount
  ) external;

  /**
   * @notice Get the Ribbon Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getRibbonVaultAddressesForAlloyxVault(address _vaultAddress) external view returns (address[] memory);

  /**
   * @notice Get the Ribbon Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _ribbonVault the address of ribbon vault
   */
  function getRibbonVaultShareForAlloyxVault(address _vaultAddress, address _ribbonVault) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxStakeInfo
 * @author AlloyX
 */
interface IAlloyxStakeInfo {
  function getAllStakers(address _vaultAddress) external returns (address[] memory);

  /**
   * @notice Add stake for a staker
   * @param _vaultAddress The vault address
   * @param _staker The person intending to stake
   * @param _stake The size of the stake to be created.
   */
  function addStake(
    address _vaultAddress,
    address _staker,
    uint256 _stake
  ) external;

  /**
   * @notice Remove stake for a staker
   * @param _vaultAddress The vault address
   * @param _staker The person intending to remove stake
   * @param _stake The size of the stake to be removed.
   */
  function removeStake(
    address _vaultAddress,
    address _staker,
    uint256 _stake
  ) external;

  /**
   * @notice Remove all stakes with regards to one vault
   * @param _vaultAddress The vault address
   */
  function removeAllStake(address _vaultAddress) external;

  /**
   * @notice Total receiver temporal stakes
   * @param _vaultAddress The vault address
   * @param _receiver the address of receiver
   */
  function receiverTemporalStake(address _vaultAddress, address _receiver) external view returns (uint256);

  /**
   * @notice Total vault temporal stakes
   * @param _vaultAddress The vault address
   */
  function vaultTemporalStake(address _vaultAddress) external view returns (uint256);

  /**
   * @notice A method for a stakeholder to clear a stake with some leftover temporal stakes
   * @param _vaultAddress The vault address
   * @param _staker the address of the staker
   * @param _temporalStake the leftover temporal stake
   */
  function resetStakeTimestampWithTemporalStake(
    address _vaultAddress,
    address _staker,
    uint256 _temporalStake
  ) external;

  /**
   * @notice Retrieve the stake for a stakeholder.
   * @param _staker The staker
   * @return stakes The amount staked and the time since when it's staked.
   */
  function totalStakeForUser(address _staker) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title ICToken
 * @author AlloyX
 */
interface ICToken is IERC20Upgradeable {
  function mint(uint256 depositAmount) external;

  function redeem(uint256 sharesAmount) external;

  function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IBackedToken
 * @author AlloyX
 */
interface IERC20Token is IERC20Upgradeable {
  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IBackedOracle
 * @author AlloyX
 */
interface IBackedOracle {
  function latestAnswer() external view returns (int256);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./IV2CreditLine.sol";

abstract contract ITranchedPool {
  IV2CreditLine public creditLine;
  uint256 public createdAt;

  enum Tranches {
    Reserved,
    Senior,
    Junior
  }

  struct TrancheInfo {
    uint256 id;
    uint256 principalDeposited;
    uint256 principalSharePrice;
    uint256 interestSharePrice;
    uint256 lockedUntil;
  }

  struct PoolSlice {
    TrancheInfo seniorTranche;
    TrancheInfo juniorTranche;
    uint256 totalInterestAccrued;
    uint256 principalDeployed;
  }

  struct SliceInfo {
    uint256 reserveFeePercent;
    uint256 interestAccrued;
    uint256 principalAccrued;
  }

  struct ApplyResult {
    uint256 interestRemaining;
    uint256 principalRemaining;
    uint256 reserveDeduction;
    uint256 oldInterestSharePrice;
    uint256 oldPrincipalSharePrice;
  }

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public virtual;

  function getTranche(uint256 tranche) external view virtual returns (TrancheInfo memory);

  function pay(uint256 amount) external virtual;

  function lockJuniorCapital() external virtual;

  function lockPool() external virtual;

  function initializeNextSlice(uint256 _fundableAt) external virtual;

  function totalJuniorDeposits() external view virtual returns (uint256);

  function drawdown(uint256 amount) external virtual;

  function setFundableAt(uint256 timestamp) external virtual;

  function deposit(uint256 tranche, uint256 amount) external virtual returns (uint256 tokenId);

  function assess() external virtual;

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 tokenId);

  function availableToWithdraw(uint256 tokenId) external view virtual returns (uint256 interestRedeemable, uint256 principalRedeemable);

  function withdraw(uint256 tokenId, uint256 amount) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMax(uint256 tokenId) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMultiple(uint256[] calldata tokenIds, uint256[] calldata amounts) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./ICreditLine.sol";

abstract contract IV2CreditLine is ICreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess()
    external
    virtual
    returns (
      uint256,
      uint256,
      uint256
    );

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;

  function updateGoldfinchConfig() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

interface ICreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyx
 * @author AlloyX
 */
interface IAlloyx {
  /**
   * @notice Source denotes the protocol to which the component is going to invest
   */
  enum Source {
    USDC,
    GOLDFINCH,
    FIDU,
    TRUEFI,
    MAPLE,
    RIBBON,
    RIBBON_LEND,
    CLEAR_POOL,
    CREDIX,
    FLUX,
    BACKED
  }

  /**
   * @notice State refers to the pool status
   */
  enum State {
    INIT,
    STARTED,
    NON_GOVERNANCE
  }

  /**
   * @notice State refers to the pool status
   */
  enum WithdrawalStep {
    DEFAULT,
    INIT,
    COMPLETE
  }

  /**
   * @notice Component is the structure containing the information of which protocol to invest in
   * how much to invest, where the proportion has 4 decimals, meaning that 100 is 1%
   */
  struct Component {
    uint256 proportion;
    address poolAddress;
    uint256 tranche;
    Source source;
  }

  /**
   * @notice DepositAmount is the structure containing the information of an address and amount
   */
  struct DepositAmount {
    address depositor;
    uint256 amount;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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