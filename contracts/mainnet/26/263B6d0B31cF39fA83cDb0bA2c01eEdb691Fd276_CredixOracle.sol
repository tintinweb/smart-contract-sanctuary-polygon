// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "../interfaces/ICredixOracle.sol";
import "../config/AlloyxConfig.sol";
import "../config/ConfigHelper.sol";

/**
 * @title CredixOracle
 * @notice NAV or statistics related to assets managed for Credix, the managed portfolios are contracts in Credix, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract CredixOracle is ICredixOracle, ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;
  using ConfigHelper for AlloyxConfig;
  using SafeMath for uint256;

  string public url;
  bytes32 private jobId;
  uint256 private fee;
  mapping(address => uint256) public vaultToUsdcValue;
  mapping(address => string) public vaultToWalletAddress;
  mapping(bytes32 => address) public requestIdToVault;

  AlloyxConfig public config;

  event ChangeUrl(address changer, string url);
  event ChangeJobId(address changer, bytes32 jobId);
  event SetUsdcValue(address changer, address indexed vaultAddress, uint256 usdcValue);
  event ChangeWalletAddress(address changer, address indexed vaultAddress, string walletAddress);
  event DepositUsdc(address depositor, address indexed vaultAddress, uint256 usdcValue);
  event RequestUsdcValue(bytes32 indexed requestId, address indexed vaultAddress, uint256 usdcValue);

  /**
   * @notice Initialize the oracle contract with job details
   * Goerli Testnet details:
   * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
   * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
   * jobId: ca98366cc7314957b8c012c72f05aeeb
   * Mainnet details:
   * Link Token: 0x514910771AF9Ca656af840dff83E8264EcF986CA
   * Oracle: 0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434 (Chainlink DevRel)
   * jobId: 7599d3c8f31e4ce78ad2b790cbcfc673
   */
  constructor(
    string memory _url,
    address _chainlinkToken,
    address _chainlinkOracle,
    address _configAddress,
    bytes32 _jobId
  ) ConfirmedOwner(msg.sender) {
    setChainlinkToken(_chainlinkToken);
    setChainlinkOracle(_chainlinkOracle);
    url = _url;
    jobId = _jobId;
    fee = (135 * LINK_DIVISIBILITY) / 100;
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice Initialize the oracle contract with job details
   * @param _vaultAddress  the vault address to get the wallet balance in solana
   */
  function requestUsdcValue(address _vaultAddress) public onlyOwner returns (bytes32) {
    Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
    req.add("get", string(abi.encodePacked(url, vaultToWalletAddress[_vaultAddress])));
    req.add("path", "vaultValue,uiAmount");
    int256 timesAmount = 10**6;
    req.addInt("multiply", timesAmount);
    bytes32 requestId = sendChainlinkRequest(req, fee);
    requestIdToVault[requestId] = _vaultAddress;
    return requestId;
  }

  /**
   * @notice Callback from oracle to set the value from solana wallet
   * @param _requestId the ID of the callback from oracle
   * @param _usdcValue the USDC value of the vault
   */
  function fulfill(bytes32 _requestId, uint256 _usdcValue) public recordChainlinkFulfillment(_requestId) {
    address vaultAddress = requestIdToVault[_requestId];
    vaultToUsdcValue[vaultAddress] = _usdcValue;
    emit RequestUsdcValue(_requestId, vaultAddress, _usdcValue);
  }

  /**
   * @notice Get the net asset value of vault
   * @param _vaultAddress the vault address to increase USDC value on
   */
  function getNetAssetValueInUsdc(address _vaultAddress) external view override returns (uint256) {
    return vaultToUsdcValue[_vaultAddress];
  }

  /**
   * @notice Set the net asset value of vault
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _usdcValue the USDC value of the vault
   */
  function setNetAssetValueInUsdc(address _vaultAddress, uint256 _usdcValue) external onlyOwner {
    vaultToUsdcValue[_vaultAddress] = _usdcValue;
    emit SetUsdcValue(msg.sender, _vaultAddress, _usdcValue);
  }

  /**
   * @notice Set the wallet address
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _walletAddress the wallet address bound to the vault
   */
  function setWalletAddress(address _vaultAddress, string memory _walletAddress) external onlyOwner {
    vaultToWalletAddress[_vaultAddress] = _walletAddress;
    emit ChangeWalletAddress(msg.sender, _vaultAddress, _walletAddress);
  }

  /**
   * @notice Increase the USDC value after the vault provides USDC to credix desk
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _increasedValue the increased value of the vault
   */
  function increaseUsdcValue(address _vaultAddress, uint256 _increasedValue) external override {
    require(msg.sender == config.credixDeskAddress(), "the value can only be called by credix desk during deposit");
    vaultToUsdcValue[_vaultAddress] = vaultToUsdcValue[_vaultAddress].add(_increasedValue);
    emit DepositUsdc(msg.sender, _vaultAddress, _increasedValue);
  }

  /**
   * @notice Set the URL
   * @param _url the URL of the oracle
   */
  function setUrl(string memory _url) external onlyOwner {
    url = _url;
    emit ChangeUrl(msg.sender, _url);
  }

  /**
   * @notice Set the jobID
   * @param _jobId the jobID of the oracle
   */
  function setJobId(bytes32 _jobId) external onlyOwner {
    jobId = _jobId;
    emit ChangeJobId(msg.sender, _jobId);
  }

  /**
   * @notice Withdraw link token to the caller
   */
  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }
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

  function getProtocolFeeProportion(AlloyxConfig config) internal view returns (uint256) {
    uint256 protocolFeeProportion = config.getNumber(uint256(ConfigOptions.Numbers.ProtocolFeeProportion));
    require(protocolFeeProportion <= 10000, "protocol proportion should be smaller or equal to 10000");
    return protocolFeeProportion;
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
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
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
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
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

/**
 * @title IAlloyxTreasury
 * @author AlloyX
 */
interface IAlloyxTreasury {

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
  function getClearPoolUsdcValueOfPoolMaster(address _vaultAddress, address _address) external returns (uint256);

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
  function getMapleWalletUsdcValueOfPool(address _vaultAddress, address _address) external returns (uint256);

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
  function getRibbonUsdcValueOfVault(address _vaultAddress, address _ribbonVault) external returns (uint256);

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
  function getTruefiWalletUsdcValueOfPortfolio(address _vaultAddress, address _address) external returns (uint256);
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
  function getRibbonLendUsdcValueOfPoolMaster(address _vaultAddress, address _address) external returns (uint256);
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
    ProtocolFeeProportion, // In 4 decimals, where 100 means 1%
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
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}