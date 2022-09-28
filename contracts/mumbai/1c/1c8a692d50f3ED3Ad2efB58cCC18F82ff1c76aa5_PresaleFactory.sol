// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICorePool.sol";
import "./StarterInfo.sol";
import "./StarterPresale.sol";

contract PresaleFactory is Ownable {
  event PresaleCreated(bytes32 title, uint256 starterId, address creator);

  StarterInfo public immutable starterInfo;
  IERC20 public startToken;

  address payable public buyBackBurnAddress;

  constructor(
    address _starterInfoAddress,
    address _startToken,
    address payable _buyBackBurnAddress
  ) {
    starterInfo = StarterInfo(_starterInfoAddress);
    startToken = IERC20(_startToken);
    buyBackBurnAddress = _buyBackBurnAddress;
  }

  receive() external payable {}

  struct PresaleInfo {
    address tokenAddress;
    uint8 tokenDecimals;
    address unsoldTokensDumpAddress;
    address[] whitelistedAddresses;
    uint256 tokenPriceInWei;
    uint256 hardCapInWei;
    uint256 softCapInWei;
    uint256 maxInvestInWei;
    uint256 minInvestInWei;
    uint256 openTime;
    uint256 closeTime;
    uint256 presaleType; // 0: Private, 1:Guaranteed allocation, 2: Certified START
    uint256 guaranteedHours;
    uint256 releasePerCycle; // 25% monthly or 10% monthly
    uint256 releaseCycle; // 30 days or 1 week or 1 day
    address fundingTokenAddress; // MATIC, QUICK, USDC, or START
  }

  struct PresalePancakeSwapInfo {
    uint256 listingPriceInWei;
    uint256 liquidityAddingTime;
    uint256 lpTokensLockDurationInDays;
    uint256 liquidityPercentageAllocation;
    uint256 swapIndex;
  }

  struct PresaleStringInfo {
    bytes32 saleTitle;
    bytes32 linkTelegram;
    bytes32 linkGithub;
    bytes32 linkTwitter;
    bytes32 linkWebsite;
    string linkLogo;
    string kycInformation;
    string description;
    string whitepaper;
    uint256 categoryId; // category id = 0, 1, 2, 3, ...
  }

  modifier onlyStarterDev() {
    require(msg.sender == owner() || starterInfo.getStarterDev(msg.sender));
    _;
  }

  function initializePresale(
    StarterPresale _presale,
    uint256 _totalTokens,
    PresaleInfo calldata _info,
    PresalePancakeSwapInfo calldata _cakeInfo,
    PresaleStringInfo calldata _stringInfo
  ) internal {
    _presale.setAddressInfo(
      msg.sender,
      _info.tokenAddress,
      _info.tokenDecimals,
      _info.unsoldTokensDumpAddress,
      buyBackBurnAddress,
      _info.fundingTokenAddress
    );
    _presale.setGeneralInfo(
      _info.presaleType,
      _info.guaranteedHours,
      _info.releasePerCycle,
      _info.releaseCycle,
      false
    );
    _presale.setGeneralCapitalInfo(
      _totalTokens,
      _info.tokenPriceInWei,
      _info.hardCapInWei,
      _info.softCapInWei,
      _info.maxInvestInWei,
      _info.minInvestInWei,
      _info.openTime,
      _info.closeTime
    );
    _presale.setPancakeSwapInfo(
      _cakeInfo.listingPriceInWei,
      _cakeInfo.liquidityAddingTime,
      _cakeInfo.lpTokensLockDurationInDays,
      _cakeInfo.liquidityPercentageAllocation,
      _cakeInfo.swapIndex
    );
    _presale.setStringInfo(
      _stringInfo.saleTitle,
      _stringInfo.kycInformation,
      _stringInfo.description,
      _stringInfo.whitepaper,
      _stringInfo.categoryId
    );
    _presale.setLinksInfo(
      _stringInfo.linkTelegram,
      _stringInfo.linkGithub,
      _stringInfo.linkTwitter,
      _stringInfo.linkWebsite,
      _stringInfo.linkLogo
    );

    _presale.addWhitelistedAddresses(_info.whitelistedAddresses);

    address pool = starterInfo.getLpAddress(_info.fundingTokenAddress);
    ICorePool(pool).addPresaleAddress(address(_presale));
  }

  function createPresale(
    PresaleInfo calldata _info,
    PresalePancakeSwapInfo calldata _cakeInfo,
    PresaleStringInfo calldata _stringInfo
  ) external {
    uint256 startBalance = starterInfo.getStaked(
      _info.fundingTokenAddress,
      payable(msg.sender)
    );

    require(
      startBalance >=
        starterInfo.getMinCreatorStakedBalance(_info.fundingTokenAddress)
    );

    require(
      _info.presaleType != 2 ||
        starterInfo.getStarterDev(msg.sender) ||
        starterInfo.getPresaleCreatorDev(msg.sender)
    );

    IERC20 token = IERC20(_info.tokenAddress);
    StarterPresale presale = new StarterPresale(
      address(this),
      address(starterInfo),
      starterInfo.owner()
    );

    uint256 maxLiqPoolTokenAmount = (_info.hardCapInWei *
      (_cakeInfo.liquidityPercentageAllocation) *
      (uint256(10)**uint256(_info.tokenDecimals))) /
      (_cakeInfo.listingPriceInWei * (100));

    uint256 maxTokensToBeSold = ((_info.hardCapInWei *
      (100 + starterInfo.getDevPresaleTokenFee()))/
      100) * ((10**_info.tokenDecimals) /
      (_info.tokenPriceInWei));
    
    token.transferFrom(
      msg.sender,
      address(presale),
      maxLiqPoolTokenAmount + maxTokensToBeSold
    );

    initializePresale(
      presale,
      maxTokensToBeSold,
      _info,
      _cakeInfo,
      _stringInfo
    );

    address lpTokenAddress = starterInfo.getCakeV2LPAddress(
        address(token),
        _info.fundingTokenAddress,
        _cakeInfo.swapIndex
      );
    address starterLpAddress = starterInfo.getStarterSwapLPAddress(
        address(token),
        _info.fundingTokenAddress
      );
    uint256 devFeePercentage = starterInfo.getDevFeePercentage(_info.presaleType);

    uint256 minDevFeeInWei = starterInfo.getMinDevFeeInWei();
    address poolAddress = starterInfo.getLpAddress(_info.fundingTokenAddress);

    uint256 starterId = starterInfo.addPresaleAddress(address(presale));
    presale.setStarterInfo(
      lpTokenAddress,
      starterLpAddress,
      devFeePercentage,
      minDevFeeInWei,
      starterId,
      poolAddress
    );
    emit PresaleCreated(_stringInfo.saleTitle, starterId, msg.sender);
  }

  function migrate(address payable _newFactoryAddress) external onlyStarterDev {
    _newFactoryAddress.transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

pragma solidity 0.8.13;

import "./IPool.sol";

interface ICorePool is IPool {
  function vaultRewardsPerToken() external view returns (uint256);

  function poolTokenReserve() external view returns (uint256);

  function stakeAsPool(
    address _staker,
    uint256 _amount,
    uint256 _liquidPercent,
    uint256 _lockTime
  ) external;

  function receiveVaultRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPool.sol";
import "./CorePool.sol";

contract StarterInfo is Ownable {
  uint256 private minDevFeeInWei = 5 ether; // min fee amount going to dev AND  hodlers
  uint256 private minStakeTime = 1 minutes;
  uint256 private minUnstakeTime = 3 days;
  uint256 private creatorUnsoldClaimTime = 3 days;
  uint256 private devPresaleTokenFee = 2;
  uint256 private starterSwapLPPercent = 0; // Liquidity will go StarterSwap
  bytes32 private starterSwapICH =
    0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5; // StarterSwap InitCodeHash

  
  address private starterSwapRouter; // StarterSwap Router
  address private starterSwapFactory; // StarterSwap Factory
  address private wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
  address private devPresaleAllocationAddress;
  address private startVestingAddress;
  address private poolFactory;
  address private presaleFactory;

  uint256[] private devFeePercentage = [5, 2, 2];
  address[] private presaleAddresses; // track all presales created
  address[] private swapRouters = [
    address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff),
    address(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429)
  ]; // Array of Routers
  address[] private swapFactorys = [
    address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32),
    address(0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B)
  ]; // Array of Factorys

  mapping(address => uint256) private minInvestorBalance; // min amount to investors HODL  balance
  mapping(address => uint256) private minInvestorGuaranteedBalance;
  mapping(address => bytes32) private initCodeHash; // Mapping of INIT_CODE_HASH
  mapping(address => address) private lpAddresses; // TOKEN + START Pair Addresses
  mapping(address => uint256) private investmentLimit;
  mapping(address => bool) private starterDevs;
  mapping(address => bool) private presaleCreatorDevs;
  mapping(address => uint256) private minYesVotesThreshold; // minimum number of yes votes needed to pass
  mapping(address => uint256) private minCreatorStakedBalance;
  mapping(address => bool) private blacklistedAddresses;
  mapping(address => bool) public auditorWhitelistedAddresses; // addresses eligible to perform audits

  constructor() {
    starterDevs[address(0xf7e925818a20E5573Ee0f3ba7aBC963e17f2c476)] = true; // Chef
    starterDevs[address(0xcc887c71ABeB5763E896859B11530cc7942c7Bd5)] = true; // Cocktologist

    initCodeHash[
      address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32)
    ] = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f; //QuickSwap INIT_CODE_HASH

    initCodeHash[
      address(0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B)
    ] = 0xf187ed688403aa4f7acfada758d8d53698753b998a3071b06f1b777f4330eaf3; // DYFN INIT_CODE_HASH

    minYesVotesThreshold[wbnb] = 1000 * 1e18;
    minInvestorBalance[wbnb] = 3.5 * 1e18;
    minInvestorGuaranteedBalance[wbnb] = 35 * 1e18;
    investmentLimit[wbnb] = 1000 * 1e18;
    minCreatorStakedBalance[wbnb] = 3.5 * 1e18;
  }

  modifier onlyFactory() {
    require(
      presaleFactory == msg.sender ||
      poolFactory == msg.sender ||
        owner() == msg.sender ||
        starterDevs[msg.sender],
      "onlyFactoryOrDev"
    );
    _;
  }

  modifier onlyStarterDev() {
    require(owner() == msg.sender || starterDevs[msg.sender], "onlyStarterDev");
    _;
  }

  function getCakeV2LPAddress(
    address tokenA,
    address tokenB,
    uint256 swapIndex
  ) public view returns (address pair) {
    (address token0, address token1) = tokenA < tokenB
      ? (tokenA, tokenB)
      : (tokenB, tokenA);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              swapFactorys[swapIndex],
              keccak256(abi.encodePacked(token0, token1)),
              initCodeHash[swapFactorys[swapIndex]] // init code hash
            )
          )
        )
      )
    );
  }

  function getStarterSwapLPAddress(address tokenA, address tokenB)
    public
    view
    returns (address pair)
  {
    (address token0, address token1) = tokenA < tokenB
      ? (tokenA, tokenB)
      : (tokenB, tokenA);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              starterSwapFactory,
              keccak256(abi.encodePacked(token0, token1)),
              starterSwapICH // init code hash
            )
          )
        )
      )
    );
  }

  function getStarterDev(address _dev) external view returns (bool) {
    return starterDevs[_dev];
  }

  function setStarterDevAddress(address _newDev) external onlyOwner {
    starterDevs[_newDev] = true;
  }

  function removeStarterDevAddress(address _oldDev) external onlyOwner {
    delete starterDevs[_oldDev];
  }

  function getPresaleCreatorDev(address _dev) external view returns (bool) {
    return presaleCreatorDevs[_dev];
  }

  function setPresaleCreatorDevAddress(address _newDev)
    external
    onlyStarterDev
  {
    presaleCreatorDevs[_newDev] = true;
  }

  function removePresaleCreatorDevAddress(address _oldDev)
    external
    onlyStarterDev
  {
    delete presaleCreatorDevs[_oldDev];
  }

  function getPoolFactory() external view returns (address) {
    return poolFactory;
  }

  function setPoolFactory(address _newFactory)
    external
    onlyStarterDev
  {
    poolFactory = _newFactory;
  }

  function getPresaleFactory() external view returns (address) {
    return presaleFactory;
  }

  function setPresaleFactory(address _newFactory)
    external
    onlyStarterDev
  {
    presaleFactory = _newFactory;
  }

  function addPresaleAddress(address _presale)
    external
    onlyFactory
    returns (uint256)
  {
    presaleAddresses.push(_presale);
    return presaleAddresses.length - 1;
  }

  function getPresalesCount() external view returns (uint256) {
    return presaleAddresses.length;
  }

  function getPresaleAddress(uint256 id) external view returns (address) {
    return presaleAddresses[id];
  }

  function setPresaleAddress(uint256 id, address _newAddress)
    external
    onlyStarterDev
  {
    presaleAddresses[id] = _newAddress;
  }

  function getDevFeePercentage(uint256 presaleType)
    external
    view
    returns (uint256)
  {
    return devFeePercentage[presaleType];
  }

  function setDevFeePercentage(uint256 presaleType, uint256 _devFeePercentage)
    external
    onlyStarterDev
  {
    devFeePercentage[presaleType] = _devFeePercentage;
  }

  function getMinDevFeeInWei() external view returns (uint256) {
    return minDevFeeInWei;
  }

  function setMinDevFeeInWei(uint256 _minDevFeeInWei) external onlyStarterDev {
    minDevFeeInWei = _minDevFeeInWei;
  }

  function getMinInvestorBalance(address tokenAddress)
    external
    view
    returns (uint256)
  {
    return minInvestorBalance[tokenAddress];
  }

  function setMinInvestorBalance(
    address tokenAddress,
    uint256 _minInvestorBalance
  ) external onlyStarterDev {
    minInvestorBalance[tokenAddress] = _minInvestorBalance;
  }

  function getMinYesVotesThreshold(address tokenAddress)
    external
    view
    returns (uint256)
  {
    return minYesVotesThreshold[tokenAddress];
  }

  function setMinYesVotesThreshold(
    address tokenAddress,
    uint256 _minYesVotesThreshold
  ) external onlyStarterDev {
    minYesVotesThreshold[tokenAddress] = _minYesVotesThreshold;
  }

  function getMinCreatorStakedBalance(address fundingTokenAddress)
    external
    view
    returns (uint256)
  {
    return minCreatorStakedBalance[fundingTokenAddress];
  }

  function setMinCreatorStakedBalance(
    address fundingTokenAddress,
    uint256 _minCreatorStakedBalance
  ) external onlyStarterDev {
    minCreatorStakedBalance[fundingTokenAddress] = _minCreatorStakedBalance;
  }

  function getMinInvestorGuaranteedBalance(address tokenAddress)
    external
    view
    returns (uint256)
  {
    return minInvestorGuaranteedBalance[tokenAddress];
  }

  function setMinInvestorGuaranteedBalance(
    address tokenAddress,
    uint256 _minInvestorGuaranteedBalance
  ) external onlyStarterDev {
    minInvestorGuaranteedBalance[tokenAddress] = _minInvestorGuaranteedBalance;
  }

  function getMinStakeTime() external view returns (uint256) {
    return minStakeTime;
  }

  function setMinStakeTime(uint256 _minStakeTime) external onlyStarterDev {
    minStakeTime = _minStakeTime;
  }

  function getMinUnstakeTime() external view returns (uint256) {
    return minUnstakeTime;
  }

  function setMinUnstakeTime(uint256 _minUnstakeTime) external onlyStarterDev {
    minUnstakeTime = _minUnstakeTime;
  }

  function getCreatorUnsoldClaimTime() external view returns (uint256) {
    return creatorUnsoldClaimTime;
  }

  function setCreatorUnsoldClaimTime(uint256 _creatorUnsoldClaimTime)
    external
    onlyStarterDev
  {
    creatorUnsoldClaimTime = _creatorUnsoldClaimTime;
  }

  function getSwapRouter(uint256 index) external view returns (address) {
    return swapRouters[index];
  }

  function setSwapRouter(uint256 index, address _swapRouter)
    external
    onlyStarterDev
  {
    swapRouters[index] = _swapRouter;
  }

  function addSwapRouter(address _swapRouter) external onlyStarterDev {
    swapRouters.push(_swapRouter);
  }

  function getSwapFactory(uint256 index) external view returns (address) {
    return swapFactorys[index];
  }

  function setSwapFactory(uint256 index, address _swapFactory)
    external
    onlyStarterDev
  {
    swapFactorys[index] = _swapFactory;
  }

  function addSwapFactory(address _swapFactory) external onlyStarterDev {
    swapFactorys.push(_swapFactory);
  }

  function getInitCodeHash(address _swapFactory)
    external
    view
    returns (bytes32)
  {
    return initCodeHash[_swapFactory];
  }

  function setInitCodeHash(address _swapFactory, bytes32 _initCodeHash)
    external
    onlyStarterDev
  {
    initCodeHash[_swapFactory] = _initCodeHash;
  }

  function getStarterSwapRouter() external view returns (address) {
    return starterSwapRouter;
  }

  function setStarterSwapRouter(address _starterSwapRouter)
    external
    onlyStarterDev
  {
    starterSwapRouter = _starterSwapRouter;
  }

  function getStarterSwapFactory() external view returns (address) {
    return starterSwapFactory;
  }

  function setStarterSwapFactory(address _starterSwapFactory)
    external
    onlyStarterDev
  {
    starterSwapFactory = _starterSwapFactory;
  }

  function getStarterSwapICH() external view returns (bytes32) {
    return starterSwapICH;
  }

  function setStarterSwapICH(bytes32 _initCodeHash) external onlyStarterDev {
    starterSwapICH = _initCodeHash;
  }

  function getStarterSwapLPPercent() external view returns (uint256) {
    return starterSwapLPPercent;
  }

  function setStarterSwapLPPercent(uint256 _starterSwapLPPercent)
    external
    onlyStarterDev
  {
    starterSwapLPPercent = _starterSwapLPPercent;
  }

  function getWBNB() external view returns (address) {
    return wbnb;
  }

  function setWBNB(address _wbnb) external onlyStarterDev {
    wbnb = _wbnb;
  }

  function getVestingAddress() external view returns (address) {
    return startVestingAddress;
  }

  function setVestingAddress(address _newVesting) external onlyStarterDev {
    startVestingAddress = _newVesting;
  }

  function getInvestmentLimit(address tokenAddress)
    external
    view
    returns (uint256)
  {
    return investmentLimit[tokenAddress];
  }

  function setInvestmentLimit(address tokenAddress, uint256 _limit)
    external
    onlyStarterDev
  {
    investmentLimit[tokenAddress] = _limit;
  }

  function getLpAddress(address tokenAddress) public view returns (address) {
    return IPoolFactory(poolFactory).getPoolAddress(tokenAddress);
  }

  function getStartLpStaked(address lpAddress, address payable sender)
    public
    view
    returns (uint256)
  {
    (uint256 tokenAmount,,,,,,uint lastStakedTimestamp,,,) = CorePool(lpAddress).users(address(sender));

    uint256 totalHodlerBalance = 0;
    if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
      totalHodlerBalance = totalHodlerBalance + tokenAmount;
    }
    return totalHodlerBalance;
  }

  function getTotalStartLpStaked(address lpAddress)
    public
    view
    returns (uint256)
  {
    address token = IPool(lpAddress).poolToken();
    return IERC20(token).balanceOf(address(lpAddress));
  }

  function getStaked(address fundingTokenAddress, address payable sender)
    public
    view
    returns (uint256)
  {
    return getStartLpStaked(getLpAddress(fundingTokenAddress), sender);
  }

  function getTotalStaked(address fundingTokenAddress)
    public
    view
    returns (uint256)
  {
    return getTotalStartLpStaked(getLpAddress(fundingTokenAddress));
  }

  function getDevPresaleTokenFee() public view returns (uint256) {
    return devPresaleTokenFee;
  }

  function setDevPresaleTokenFee(uint256 _devPresaleTokenFee)
    external
    onlyStarterDev
  {
    devPresaleTokenFee = _devPresaleTokenFee;
  }

  function getDevPresaleAllocationAddress() public view returns (address) {
    return devPresaleAllocationAddress;
  }

  function setDevPresaleAllocationAddress(address _devPresaleAllocationAddress)
    external
    onlyStarterDev
  {
    devPresaleAllocationAddress = _devPresaleAllocationAddress;
  }

  function isBlacklistedAddress(address _sender) public view returns (bool) {
    return blacklistedAddresses[_sender];
  }

  function addBlacklistedAddresses(address[] calldata _blacklistedAddresses)
    external
    onlyStarterDev
  {
    for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
      blacklistedAddresses[_blacklistedAddresses[i]] = true;
    }
  }

  function removeBlacklistedAddresses(address[] calldata _blacklistedAddresses)
    external
    onlyStarterDev
  {
    for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
      blacklistedAddresses[_blacklistedAddresses[i]] = false;
    }
  }

  function isAuditorWhitelistedAddress(address _sender)
    public
    view
    returns (bool)
  {
    return auditorWhitelistedAddresses[_sender];
  }

  function addAuditorWhitelistedAddresses(
    address[] calldata _whitelistedAddresses
  ) external onlyStarterDev {
    for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
      auditorWhitelistedAddresses[_whitelistedAddresses[i]] = true;
    }
  }

  function removeAuditorWhitelistedAddresses(
    address[] calldata _whitelistedAddresses
  ) external onlyStarterDev {
    for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
      auditorWhitelistedAddresses[_whitelistedAddresses[i]] = false;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICorePool.sol";
import "./StarterInfo.sol";

interface IPancakeSwapV2Router02 {
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
}

interface IStarterVesting {
  function lockTokens(
    address _tokenAddress,
    address _withdrawalAddress,
    uint256 _lockAmount,
    uint256 _unlockTime
  ) external returns (uint256 _id);
}

interface WBNB {
  function deposit() external payable;
}

contract StarterPresale {
  address payable internal starterFactoryAddress; // address that creates the presale contracts
  address payable public starterDevAddress; // address where dev fees will be transferred to
  IERC20 public lpToken; // address where LP tokens will be locked
  IERC20 public starterLpToken; //address where starter LP tokens will be locked
  IPool public starterPool;
  StarterInfo public starterInfo;

  IERC20 public token; // token that will be sold
  uint8 public tokenDecimals = 18; // token decimals
  uint256 public tokenMagnitude = 1e18; // token magnitude

  address payable public presaleCreatorAddress; // address where percentage of invested wei will be transferred to
  address public unsoldTokensDumpAddress; // address where unsold tokens will be transferred to
  address payable public buyBackBurnAddress; // address where buy back burn tokens will be transferred to
  address public fundingTokenAddress; // token to accept as funds: MATIC, QUICK, USDC, START

  mapping(address => uint256) public investments; // total wei invested per address

  mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale
  mapping(address => uint256) public claimed; // if true, it means investor already claimed the tokens or got a refund

  uint256 private starterDevFeePercentage; // dev fee to support the development of BSCstarter
  uint256 private starterMinDevFeeInWei; // minimum fixed dev fee to support the development of BSCstarter
  uint256 public starterId; // used for fetching presale without referencing its address

  uint256 public totalInvestorsCount; // total investors count
  uint256 public presaleCreatorClaimTime; // time when presale creator can collect funds raise
  uint256 public totalCollectedWei; // total wei collected
  uint256 public totalTokens; // total tokens to be sold
  uint256 public tokensLeft; // available tokens to be sold
  uint256 public tokenPriceInWei; // token presale wei price per 1 token
  uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
  uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
  uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
  uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
  uint256 public openTime; // time when presale starts, investing is allowed
  uint256 public closeTime; // time when presale closes, investing is not allowed
  uint256 public presaleType; // 0: Private, 1: Public, 2: Certified START
  uint256 public guaranteedHours; // hours for guaranteed allocation
  uint256 public releasePerCycle = 10000; // 25% or 10% release
  uint256 public releaseCycle = 30 days; // 1month, 1day or 1 week

  uint256 public cakeListingPriceInWei; // token price when listed in PancakeSwap
  uint256 public cakeLiquidityAddingTime; // time when adding of liquidity in PancakeSwap starts, investors can claim their tokens afterwards
  uint256 public cakeLPTokensLockDurationInDays; // how many days after the liquity is added the presale creator can unlock the LP tokens
  uint256 public cakeLiquidityPercentageAllocation; // how many percentage of the total invested wei that will be added as liquidity

  uint256 public swapIndex; // exchange index

  mapping(address => uint256) public voters; // addresses voting on sale
  uint256 public noVotes; // total number of no votes
  uint256 public yesVotes; // total number of yes votes

  bool public cakeLiquidityAdded = false; // if true, liquidity is added in PancakeSwap and lp tokens are locked
  bool public onlyWhitelistedAddressesAllowed = false; // if true, only whitelisted addresses can invest
  bool public presaleCancelled = false; // if true, investing will not be allowed, investors can withdraw, presale creator can withdraw their tokens
  bool public claimAllowed = false; // if false, investor will not be allowed to be claimed

  bytes32 public saleTitle;
  bytes32 public linkTelegram;
  bytes32 public linkTwitter;
  bytes32 public linkGithub;
  bytes32 public linkWebsite;
  string public linkLogo;
  string public kycInformation;
  string public description;
  string public whitepaper;
  uint256 public categoryId;

  struct AuditorInfo {
    bytes32 auditor; // auditor name
    bool isVerified; // if true -> passed, false -> failed
    bool isWarning; // if true -> warning, false -> no warning
    string linkAudit; // stores content of audit summary (actual text)
  }
  AuditorInfo public auditInformation;

  constructor(
    address _starterFactoryAddress,
    address _starterInfo,
    address _starterDevAddress
  ) {
    require(_starterFactoryAddress != address(0));
    require(_starterDevAddress != address(0));

    starterFactoryAddress = payable(_starterFactoryAddress);
    starterDevAddress = payable(_starterDevAddress);
    starterInfo = StarterInfo(_starterInfo);
  }

  modifier onlyStarterDev() {
    require(
      starterFactoryAddress == msg.sender ||
        starterInfo.getStarterDev(msg.sender)
    );
    _;
  }

  modifier onlyPresaleCreatorOrFactory() {
    require(
      presaleCreatorAddress == msg.sender ||
        starterFactoryAddress == msg.sender ||
        starterInfo.getStarterDev(msg.sender)
    );
    _;
  }

  modifier onlyPresaleCreator() {
    require(presaleCreatorAddress == msg.sender);
    _;
  }

  modifier whitelistedAddressOnly() {
    require(
      !onlyWhitelistedAddressesAllowed || whitelistedAddresses[msg.sender]
    );
    _;
  }

  modifier notBlacklistedAddress() {
    require(!starterInfo.isBlacklistedAddress(msg.sender));
    _;
  }

  modifier presaleIsNotCancelled() {
    require(!presaleCancelled);
    _;
  }

  modifier investorOnly() {
    require(investments[msg.sender] > 0);
    _;
  }

  modifier notYetClaimedOrRefunded() {
    require(claimed[msg.sender] < getTokenAmount(investments[msg.sender]));
    _;
  }

  modifier votesPassed() {
    uint256 minYesVotesThreshold = starterInfo.getMinYesVotesThreshold(
      fundingTokenAddress
    );
    require(yesVotes >= noVotes + minYesVotesThreshold || presaleType != 1);
    _;
  }

  modifier whitelistedAuditorOnly() {
    require(starterInfo.isAuditorWhitelistedAddress(msg.sender));
    _;
  }

  modifier claimAllowedOrLiquidityAdded() {
    require(
      (presaleType == 0 && claimAllowed) ||
        (presaleType != 0 && cakeLiquidityAdded)
    );
    _;
  }

  function setAddressInfo(
    address _presaleCreator,
    address _tokenAddress,
    uint8 _tokenDecimals,
    address _unsoldTokensDumpAddress,
    address payable _buyBackBurnAddress,
    address _fundingTokenAddress
  ) external onlyStarterDev {
    presaleCreatorAddress = payable(_presaleCreator);
    unsoldTokensDumpAddress = _unsoldTokensDumpAddress;
    buyBackBurnAddress = _buyBackBurnAddress;
    fundingTokenAddress = _fundingTokenAddress;
    token = IERC20(_tokenAddress);
    tokenDecimals = _tokenDecimals;
    tokenMagnitude = uint256(10)**uint256(tokenDecimals);
  }

  function setStringInfo(
    bytes32 _saleTitle,
    string calldata _kycInformation,
    string calldata _description,
    string calldata _whitepaper,
    uint256 _categoryId
  ) external onlyPresaleCreatorOrFactory {
    saleTitle = _saleTitle;
    kycInformation = _kycInformation;
    description = _description;
    whitepaper = _whitepaper;
    categoryId = _categoryId;
  }

  function setLinksInfo(
    bytes32 _linkTelegram,
    bytes32 _linkGithub,
    bytes32 _linkTwitter,
    bytes32 _linkWebsite,
    string calldata _linkLogo
  ) external onlyPresaleCreatorOrFactory {
    linkTelegram = _linkTelegram;
    linkGithub = _linkGithub;
    linkTwitter = _linkTwitter;
    linkWebsite = _linkWebsite;
    linkLogo = _linkLogo;
  }

  function setGeneralCapitalInfo(
    uint256 _totalTokens,
    uint256 _tokenPriceInWei,
    uint256 _hardCapInWei,
    uint256 _softCapInWei,
    uint256 _maxInvestInWei,
    uint256 _minInvestInWei,
    uint256 _openTime,
    uint256 _closeTime
  ) external onlyStarterDev {
    require(_hardCapInWei <= _totalTokens * _tokenPriceInWei);
    require(_softCapInWei <= _hardCapInWei);
    require(_minInvestInWei <= _maxInvestInWei);
    require(_openTime < _closeTime);

    totalTokens = _totalTokens;
    tokensLeft = _totalTokens;
    tokenPriceInWei = _tokenPriceInWei;
    hardCapInWei = _hardCapInWei;
    softCapInWei = _softCapInWei;
    openTime = _openTime;

    maxInvestInWei = _maxInvestInWei;
    minInvestInWei = _minInvestInWei;
    closeTime = _closeTime;
  }

  function setGeneralInfo(
    uint256 _presaleType,
    uint256 _guaranteedHours,
    uint256 _releasePerCycle,
    uint256 _releaseCycle,
    bool _onlyWhitelistedAddressesAllowed
  ) external onlyStarterDev {
    presaleType = _presaleType;
    guaranteedHours = _guaranteedHours;
    releasePerCycle = _releasePerCycle;
    releaseCycle = _releaseCycle;
    onlyWhitelistedAddressesAllowed = _onlyWhitelistedAddressesAllowed;
  }

  function setPancakeSwapInfo(
    uint256 _cakeListingPriceInWei,
    uint256 _cakeLiquidityAddingTime,
    uint256 _cakeLPTokensLockDurationInDays,
    uint256 _cakeLiquidityPercentageAllocation,
    uint256 _swapIndex
  ) external onlyStarterDev {
    require(closeTime > 0 && _cakeLiquidityAddingTime >= closeTime);

    cakeListingPriceInWei = _cakeListingPriceInWei;
    cakeLiquidityAddingTime = _cakeLiquidityAddingTime;
    cakeLPTokensLockDurationInDays = _cakeLPTokensLockDurationInDays;
    cakeLiquidityPercentageAllocation = _cakeLiquidityPercentageAllocation;
    swapIndex = _swapIndex;
  }

  function allowClaim() external onlyPresaleCreatorOrFactory {
    claimAllowed = true;
  }

  function disableClaim() external onlyPresaleCreatorOrFactory {
    claimAllowed = false;
  }

  function setAuditorInfo(
    bytes32 _auditor,
    bool _isVerified,
    bool _isWarning,
    string calldata _linkAudit
  ) external whitelistedAuditorOnly {
    auditInformation.auditor = _auditor;
    auditInformation.isVerified = _isVerified;
    auditInformation.isWarning = _isWarning;
    auditInformation.linkAudit = _linkAudit;
  }

  function setStarterInfo(
    address _lpToken,
    address _starterLpToken,
    uint256 _starterDevFeePercentage,
    uint256 _starterMinDevFeeInWei,
    uint256 _starterId,
    address _starterPool
  ) external onlyStarterDev {
    lpToken = IERC20(_lpToken);
    starterLpToken = IERC20(_starterLpToken);
    starterDevFeePercentage = _starterDevFeePercentage;
    starterMinDevFeeInWei = _starterMinDevFeeInWei;
    starterId = _starterId;
    starterPool = IPool(_starterPool);
  }

  function addWhitelistedAddresses(address[] calldata _whitelistedAddresses)
    external
    onlyPresaleCreatorOrFactory
  {
    onlyWhitelistedAddressesAllowed = _whitelistedAddresses.length > 0;
    for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
      whitelistedAddresses[_whitelistedAddresses[i]] = true;
    }
  }

  function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return (_weiAmount * tokenMagnitude) / tokenPriceInWei;
  }

  function getGuaranteedAllocation(address payable user)
    public
    view
    returns (uint256)
  {
    uint256 startBalance = starterInfo.getStaked(fundingTokenAddress, user);
    uint256 totalStartStaked = starterInfo.getTotalStaked(fundingTokenAddress);
    return (totalTokens * startBalance) / totalStartStaked;
  }

  function getMaxInvestAmount(address payable user)
    public
    view
    returns (uint256)
  {
    uint256 minInvestorBSCSBalance = starterInfo.getMinInvestorBalance(
      fundingTokenAddress
    );
    uint256 minInvestorGuaranteedBalance = starterInfo
      .getMinInvestorGuaranteedBalance(fundingTokenAddress);
    uint256 startBalance = starterInfo.getStaked(fundingTokenAddress, user);
    if (startBalance < minInvestorBSCSBalance) {
      return 0;
    }
    uint256 calculatedAmount = (startBalance * maxInvestInWei * 1) /
      (minInvestorBSCSBalance + minInvestorGuaranteedBalance);

    if (openTime + guaranteedHours >= block.timestamp) {
      uint256 gaAllocation = getGuaranteedAllocation(user);
      uint256 gaAmount = (gaAllocation * tokenPriceInWei) / tokenMagnitude;
      if (startBalance < minInvestorGuaranteedBalance) {
        return 0;
      }
      if (gaAmount < calculatedAmount) {
        return gaAmount;
      }
    }

    return calculatedAmount;
  }

  function invest(uint256 _investAmount)
    public
    payable
    whitelistedAddressOnly
    notBlacklistedAddress
    presaleIsNotCancelled
    votesPassed
  {
    require(block.timestamp >= openTime && block.timestamp < closeTime);
    uint256 investAmount = _investAmount;
    if (address(fundingTokenAddress) == starterInfo.getWBNB()) {
      investAmount = msg.value;
    }

    require(
      totalCollectedWei < hardCapInWei && tokensLeft > 0 && investAmount > 0,
      "1"
    );
    uint256 startBalance = starterInfo.getStaked(
      fundingTokenAddress,
      payable(msg.sender)
    );

    require(
      investAmount <= (tokensLeft * tokenPriceInWei) / tokenMagnitude,
      "4"
    );

    if (totalCollectedWei + investAmount >= hardCapInWei) {
      investAmount = hardCapInWei - totalCollectedWei;
    }

    uint256 totalInvestmentInWei = investments[msg.sender] + investAmount;
    require(totalInvestmentInWei >= minInvestInWei, "5");
    uint256 minInvestorBSCSBalance = starterInfo.getMinInvestorBalance(
      fundingTokenAddress
    );

    if (presaleType != 0) {
      uint256 maximumInvestAmount = getMaxInvestAmount(payable(msg.sender));
      require(
        (maxInvestInWei == 0 || totalInvestmentInWei <= maximumInvestAmount) &&
          totalInvestmentInWei <=
          starterInfo.getInvestmentLimit(fundingTokenAddress),
        "6"
      );

      if (openTime + guaranteedHours >= block.timestamp) {
        uint256 guaranteedAllocation = getGuaranteedAllocation(
          payable(msg.sender)
        );
        require(guaranteedAllocation >= getTokenAmount(totalInvestmentInWei));
        uint256 minInvestorGuaranteedBalance = starterInfo
          .getMinInvestorGuaranteedBalance(fundingTokenAddress);
        require(
          minInvestorGuaranteedBalance == 0 ||
            startBalance >= minInvestorGuaranteedBalance
        );
      } else if (openTime + guaranteedHours * 2 >= block.timestamp) {
        require(
          starterPool.isLongStaker(
            msg.sender
          ),
          "8"
        );
      } else {
        require(startBalance >= minInvestorBSCSBalance, "9");
      }
    } else {
      require(
        totalInvestmentInWei <= maxInvestInWei &&
          startBalance >= minInvestorBSCSBalance,
        "a"
      );
    }

    if (investments[msg.sender] == 0) {
      totalInvestorsCount = totalInvestorsCount + 1;
    }

    totalCollectedWei = totalCollectedWei + investAmount;
    investments[msg.sender] = totalInvestmentInWei;
    tokensLeft = tokensLeft - getTokenAmount(investAmount);

    if (address(fundingTokenAddress) != starterInfo.getWBNB()) {
      require(
        IERC20(fundingTokenAddress).balanceOf(msg.sender) >= investAmount,
        "b"
      );
      IERC20(fundingTokenAddress).transferFrom(
        msg.sender,
        address(this),
        investAmount
      );
    }

    starterPool.updateLastInvestTimestamp(
      msg.sender, block.timestamp
    );
  }

  receive() external payable {
    invest(0);
  }

  function sendFeesToDevs() internal returns (uint256) {
    uint256 finalTotalCollectedWei = totalCollectedWei;
    uint256 starterDevFeeInWei;
    uint256 pctDevFee = (finalTotalCollectedWei * starterDevFeePercentage) /
      100;
    starterDevFeeInWei = pctDevFee > starterMinDevFeeInWei ||
      starterMinDevFeeInWei >= finalTotalCollectedWei
      ? pctDevFee
      : starterMinDevFeeInWei;
    if (starterDevFeeInWei > 0) {
      finalTotalCollectedWei = finalTotalCollectedWei - starterDevFeeInWei;
      if (address(fundingTokenAddress) == starterInfo.getWBNB()) {
        starterDevAddress.transfer(starterDevFeeInWei);
      } else {
        IERC20(fundingTokenAddress).transfer(
          starterDevAddress,
          starterDevFeeInWei
        );
      }
      if (presaleType != 0) {
        finalTotalCollectedWei = finalTotalCollectedWei - starterDevFeeInWei;
        if (address(fundingTokenAddress) == starterInfo.getWBNB()) {
          buyBackBurnAddress.transfer(starterDevFeeInWei);
        } else {
          IERC20(fundingTokenAddress).transfer(
            buyBackBurnAddress,
            starterDevFeeInWei
          );
        }
      }
    }

    return finalTotalCollectedWei;
  }

  function addLpToRouter(
    address router,
    uint256 poolAmount,
    uint256 poolTokenAmount,
    IERC20 lpAddress
  ) internal {
    IPancakeSwapV2Router02 swapRouter = IPancakeSwapV2Router02(address(router));

    token.approve(address(swapRouter), poolTokenAmount);
    if (address(fundingTokenAddress) == starterInfo.getWBNB()) {
      WBNB(fundingTokenAddress).deposit{value: poolAmount}();
    }
    IERC20(fundingTokenAddress).approve(address(swapRouter), poolAmount);
    swapRouter.addLiquidity(
      address(fundingTokenAddress),
      address(token),
      poolAmount,
      poolTokenAmount,
      0,
      0,
      address(this),
      block.timestamp + 15 minutes
    );

    IStarterVesting startVesting = IStarterVesting(
      starterInfo.getVestingAddress()
    );

    lpAddress.approve(
      address(startVesting),
      lpAddress.balanceOf(address(this))
    );
    startVesting.lockTokens(
      address(lpAddress),
      presaleCreatorAddress,
      lpAddress.balanceOf(address(this)),
      block.timestamp + (cakeLPTokensLockDurationInDays * 1 days)
    );
  }

  function addLiquidityAndLockLPTokens() external presaleIsNotCancelled {
    require(totalCollectedWei > 0 && !cakeLiquidityAdded && presaleType != 0);
    require(
      !onlyWhitelistedAddressesAllowed ||
        whitelistedAddresses[msg.sender] ||
        msg.sender == presaleCreatorAddress
    );
    if (block.timestamp < cakeLiquidityAddingTime) {
      require(
        (totalCollectedWei >= hardCapInWei - 1 ether &&
          msg.sender == presaleCreatorAddress)
      );
    } else {
      require(
        (msg.sender == presaleCreatorAddress || investments[msg.sender] > 0) &&
          totalCollectedWei >= softCapInWei
      );
    }

    cakeLiquidityAdded = true;

    uint256 finalTotalCollectedWei = sendFeesToDevs();
    uint256 liqPoolAmount = (finalTotalCollectedWei *
      cakeLiquidityPercentageAllocation) / 100;
    uint256 liqPoolTokenAmount = (liqPoolAmount * tokenMagnitude) /
      cakeListingPriceInWei;

    uint256 starterSwapLPPercent = starterInfo.getStarterSwapLPPercent();
    uint256 starterSwapLiqPoolAmount = (liqPoolAmount * starterSwapLPPercent) /
      100;
    uint256 starterSwapLiqPoolTokenAmount = (liqPoolTokenAmount *
      starterSwapLPPercent) / 100;

    liqPoolAmount = liqPoolAmount - starterSwapLiqPoolAmount;
    liqPoolTokenAmount = liqPoolTokenAmount - starterSwapLiqPoolTokenAmount;

    if (starterSwapLPPercent > 0) {
      addLpToRouter(
        starterInfo.getStarterSwapRouter(),
        starterSwapLiqPoolAmount,
        starterSwapLiqPoolTokenAmount,
        starterLpToken
      );
    }
    addLpToRouter(
      starterInfo.getSwapRouter(swapIndex),
      liqPoolAmount,
      liqPoolTokenAmount,
      lpToken
    );

    if (presaleType != 0) {
      uint256 tokenFeeAmount = (totalTokens *
        starterInfo.getDevPresaleTokenFee()) / 100;
      token.transfer(
        starterInfo.getDevPresaleAllocationAddress(),
        tokenFeeAmount
      );
    }

    presaleCreatorClaimTime = block.timestamp + 1 hours;
  }

  function vote(bool yes) external presaleIsNotCancelled {
    uint256 voterBalance = starterInfo.getStaked(
      fundingTokenAddress,
      payable(msg.sender)
    );

    require(
      voterBalance >=
        starterInfo.getMinInvestorBalance(fundingTokenAddress) &&
        voters[msg.sender] == 0 &&
        presaleType == 1
    );
    // public IDO only need Vote

    voters[msg.sender] = voterBalance;
    if (yes) {
      yesVotes = yesVotes + voterBalance;
    } else {
      noVotes = noVotes + voterBalance;
    }
  }

  function claimTokens()
    external
    whitelistedAddressOnly
    notBlacklistedAddress
    presaleIsNotCancelled
    investorOnly
    notYetClaimedOrRefunded
    claimAllowedOrLiquidityAdded
  {
    uint256 tokenAmount = getTokenAmount(investments[msg.sender]);
    uint256 releaseAmount = (tokenAmount * releasePerCycle) / 10000;
    require(
      block.timestamp >
        openTime + (claimed[msg.sender] * releaseCycle) / releaseAmount
    );

    if (claimed[msg.sender] + releaseAmount > tokenAmount) {
      releaseAmount = tokenAmount - claimed[msg.sender];
    }
    claimed[msg.sender] = claimed[msg.sender] + releaseAmount; // make sure this goes first before transfer to prevent reentrancy
    token.transfer(msg.sender, releaseAmount);
  }

  function getRefund()
    external
    whitelistedAddressOnly
    notBlacklistedAddress
    investorOnly
    notYetClaimedOrRefunded
  {
    require(
      presaleCancelled ||
        (block.timestamp >= closeTime &&
          softCapInWei > 0 &&
          totalCollectedWei < softCapInWei)
    );

    claimed[msg.sender] = getTokenAmount(investments[msg.sender]); // make sure this goes first before transfer to prevent reentrancy
    if (investments[msg.sender] > 0) {
      if (address(fundingTokenAddress) == starterInfo.getWBNB()) {
        payable(msg.sender).transfer(investments[msg.sender]);
      } else {
        IERC20(fundingTokenAddress).transfer(
          msg.sender,
          investments[msg.sender]
        );
      }
    }
  }

  function cancelAndTransferTokensToPresaleCreator() external {
    if (
      starterInfo.getStarterDev(msg.sender) ||
      (msg.sender == presaleCreatorAddress &&
        !cakeLiquidityAdded &&
        !claimAllowed)
    ) {
      presaleCancelled = true;
      token.transfer(presaleCreatorAddress, token.balanceOf(address(this)));
    }
  }

  function collectFundsRaised()
    external
    onlyPresaleCreator
    claimAllowedOrLiquidityAdded
  {
    require(
      !presaleCancelled &&
        block.timestamp >= presaleCreatorClaimTime &&
        auditInformation.isVerified
    );
    if (presaleType == 0) {
      sendFeesToDevs();
    }
    if (address(fundingTokenAddress) == starterInfo.getWBNB()) {
      presaleCreatorAddress.transfer(address(this).balance);
    } else {
      IERC20(fundingTokenAddress).transfer(
        presaleCreatorAddress,
        IERC20(fundingTokenAddress).balanceOf(address(this))
      );
    }
  }

  function sendUnsoldTokens() external onlyStarterDev {
    require(
      !presaleCancelled &&
        block.timestamp >=
        presaleCreatorClaimTime + starterInfo.getCreatorUnsoldClaimTime()
    ); // wait 2 days before allowing burn
    token.transfer(unsoldTokensDumpAddress, token.balanceOf(address(this)));
  }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @title Illuvium Pool
 *
 * @notice An abstraction representing a pool, see IlluviumPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool {
  /**
   * @dev Deposit is a key data structure used in staking,
   *      it represents a unit of stake with its amount, weight and term (time interval)
   */
  struct Deposit {
    // @dev token amount staked
    uint256 tokenAmount;
    // @dev stake weight
    uint256 weight;
    // @dev liquid percentage;
    uint256 liquidPercentage;
    // @dev locking period - from
    uint64 lockedFrom;
    // @dev locking period - until
    uint64 lockedUntil;
    // @dev indicates if the stake was created as a yield reward
    bool isYield;
  }

  /// @dev Data structure representing token holder using a pool
  struct User {
    // @dev Total staked amount
    uint256 tokenAmount;
    //@dev Total Liquid Staked Amount
    uint256 liquidAmount;
    // @dev Total weight
    uint256 totalWeight;
    // @dev Liquid weight;
    uint256 liquidWeight;
    // @dev Auxiliary variable for yield calculation
    uint256 subYieldRewards;
    // @dev Auxiliary variable for vault rewards calculation
    uint256 subVaultRewards;
    // @dev timestamp of last stake
    uint256 lastStakedTimestamp;
    // @dev timestamp of last unstake
    uint256 lastUnstakedTimestamp;
    // @dev timestamp of first stake
    uint256 firstStakedTimestamp;
    // @dev timestamp of last invest
    uint256 lastInvestTimestamp;
    // @dev An array of holder's deposits
    Deposit[] deposits;
  }

  function eli() external view returns (address);

  function poolToken() external view returns (address);

  function weight() external view returns (uint32);

  function lastYieldDistribution() external view returns (uint64);

  function yieldRewardsPerWeight() external view returns (uint256);

  function usersLockingWeight() external view returns (uint256);

  function pendingYieldRewards(address _user) external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function getDeposit(address _user, uint256 _depositId)
    external
    view
    returns (Deposit memory);

  function getDepositsLength(address _user) external view returns (uint256);

  function stake(uint256 _amount, uint64 _lockedUntil) external;

  function stakeFor(
    address _staker,
    uint256 _amount,
    uint64 _lockUntil
  ) external;

  function unstake(uint256 _depositId, uint256 _amount) external;

  function sync() external;

  function processRewards() external;

  function setWeight(uint32 _weight) external;

  function isLongStaker(address _sender) external view returns (bool);

  function updateLastInvestTimestamp(address _user, uint256 _timestamp) external;

  function addPresaleAddress(address _presale) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPoolFactory {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function endBlock() external view returns (uint32);

  function eliPerBlock() external view returns (uint192);

  function totalWeight() external view returns (uint32);

  function transferYieldTo(
    address _to,
    uint256 _amount,
    uint256 _liquidRewardAmount
  ) external;

  function unstakeBurnFee(address _tokenAddress)
    external
    view
    returns (uint256);

  function burnAddress() external view returns (address);

  function shouldUpdateRatio() external view returns (bool);

  function updateELIPerBlock() external;

  function getPoolAddress(address poolToken) external view returns (address);

  function owner() external view returns (address);

  function maximumRewardLock() external view returns (uint256);

  function minimumRewardLock() external view returns (uint256);

  function poolExists(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./PoolBase.sol";

/**
 * @title Elixir Core Pool
 *
 * @notice Core pools represent permanent pools like ELIXIR or ELIXIR/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See PoolBase for more details
 *
 */
contract CorePool is PoolBase, Initializable {
  /// @dev Link to deployed ElixirVault instance
  address public vault;

  /// @dev Used to calculate vault rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public vaultRewardsPerWeight;

  /// @dev Pool tokens value available in the pool;
  ///      pool token examples are ELIXIR (ELIXIR core pool) or ELIXIR/ETH pair (LP core pool)
  /// @dev For LP core pool this value doesnt' count for ELIXIR tokens received as Vault rewards
  ///      while for ELIXIR core pool it does count for such tokens as well
  uint256 public poolTokenReserve;

  /**
   * @dev Fired in receiveVaultRewards()
   *
   * @param _by an address that sent the rewards, always a vault
   * @param amount amount of tokens received
   */
  event VaultRewardsReceived(address indexed _by, uint256 amount);

  /**
   * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
   *
   * @param _by an address which executed the function
   * @param _to an address which received a reward
   * @param amount amount of reward received
   */
  event VaultRewardsClaimed(
    address indexed _by,
    address indexed _to,
    uint256 amount
  );

  /**
   * @dev Fired in setVault()
   *
   * @param _by an address which executed the function, always a factory owner
   */
  event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

  /**
   * @dev Creates/deploys an instance of the core pool
   *
   * @param _eli ELI ERC20 Token ElixirERC20 address
   * @param _factory factory PoolFactory instance/address
   * @param _poolToken token the pool operates on, for example ELIXIR or ELIXIR/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   * @param _starterInfo addres of starter info contract
   */
  constructor(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight,
    address _starterInfo
  ) PoolBase(_eli, _factory, _poolToken, _initBlock, _weight, _starterInfo) {}

  function initialize(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) public initializer {
    super.initConfig(_eli, _factory, _poolToken, _initBlock, _weight);
  }

  /**
   * @notice Calculates current vault rewards value available for address specified
   *
   * @dev Performs calculations based on current smart contract state only,
   *      not taking into account any additional time/blocks which might have passed
   *
   * @param _staker an address to calculate vault rewards value for
   * @return pending calculated vault reward value for the given address
   */
  function pendingVaultRewards(address _staker)
    public
    view
    returns (uint256 pending)
  {
    User memory user = users[_staker];

    pending =
      weightToReward(user.totalWeight, vaultRewardsPerWeight) -
      user.subVaultRewards;
  }

  /**
   * @dev Executed only by the factory owner to Set the vault
   *
   * @param _vault an address of deployed ElixirVault instance
   */
  function setVault(address _vault) external {
    // verify function is executed by the factory owner
    require(factory.owner() == msg.sender, "-1");

    // verify input is set
    require(_vault != address(0), "-2");

    // emit an event
    emit VaultUpdated(msg.sender, vault, _vault);

    // update vault address
    vault = _vault;
  }

  /**
   * @dev Executed by the vault to transfer vault rewards ELIXIR from the vault
   *      into the pool
   *
   * @dev This function is executed only for ELIXIR core pools
   *
   * @param _rewardsAmount amount of ELIXIR rewards to transfer into the pool
   */
  function receiveVaultRewards(uint256 _rewardsAmount) external {
    require(msg.sender == vault, "-3");
    // return silently if there is no reward to receive
    if (_rewardsAmount == 0) {
      return;
    }
    require(usersLockingWeight != 0, "-4");

    transferEliFrom(msg.sender, address(this), _rewardsAmount);

    vaultRewardsPerWeight += rewardToWeight(_rewardsAmount, usersLockingWeight);

    // update `poolTokenReserve` only if this is a ELIXIR Core Pool
    if (poolToken == eli) {
      poolTokenReserve += _rewardsAmount;
    }

    emit VaultRewardsReceived(msg.sender, _rewardsAmount);
  }

  /**
   * @notice Service function to calculate and pay pending vault and yield rewards to the sender
   *
   * @dev Internally executes similar function `_processRewards` from the parent smart contract
   *      to calculate and pay yield rewards; adds vault rewards processing
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   */
  function processRewards() external override {
    _processRewards(msg.sender, true);
  }

  /**
   * @dev Executed internally by the pool itself (from the parent `PoolBase` smart contract)
   *      as part of yield rewards processing logic (`PoolBase._processRewards` function)
   *
   * @param _staker an address which stakes (the yield reward)
   * @param _amount amount to be staked (yield reward amount)
   * @param _liquidPercent the liquid percentage of this stake
   * @param _rewardLockPeriod the amout of seconds that the deposit will be locked
   */
  function stakeAsPool(
    address _staker,
    uint256 _amount,
    uint256 _liquidPercent,
    uint256 _rewardLockPeriod
  ) external {
    require(factory.poolExists(msg.sender), "-5");
    _sync();
    User storage user = users[_staker];
    if (user.tokenAmount > 0) {
      _processRewards(_staker, false);
    }
    uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
    Deposit memory newDeposit = Deposit({
      tokenAmount: _amount,
      lockedFrom: uint64(block.timestamp),
      lockedUntil: uint64(block.timestamp + _rewardLockPeriod),
      weight: depositWeight,
      liquidPercentage: _liquidPercent,
      isYield: true
    });
    user.tokenAmount += _amount;
    user.totalWeight += depositWeight;
    user.deposits.push(newDeposit);

    usersLockingWeight += depositWeight;

    user.subYieldRewards = weightToReward(
      user.totalWeight,
      yieldRewardsPerWeight
    );
    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );

    // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc PoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockedUntil,
    bool _isYield,
    uint256 _liquidPercent
  ) internal override {
    super._stake(_staker, _amount, _lockedUntil, _isYield, _liquidPercent);
    User storage user = users[_staker];
    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );

    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc PoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount
  ) internal override {
    User storage user = users[_staker];
    Deposit memory stakeDeposit = user.deposits[_depositId];
    require(
      stakeDeposit.lockedFrom == 0 ||
        block.timestamp > stakeDeposit.lockedUntil,
      "-6"
    );
    poolTokenReserve -= _amount;
    super._unstake(_staker, _depositId, _amount);
    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );
  }

  /**
   * @inheritdoc PoolBase
   *
   * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
   *      and for ELIXIR pool updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _processRewards(address _staker, bool _withUpdate)
    internal
    override
    returns (uint256 pendingYield)
  {
    _processVaultRewards(_staker);
    pendingYield = super._processRewards(_staker, _withUpdate);

    // update `poolTokenReserve` only if this is a ELIXIR Core Pool
    if (poolToken == eli) {
      poolTokenReserve += pendingYield;
    }
  }

  /**
   * @dev Used internally to process vault rewards for the staker
   *
   * @param _staker address of the user (staker) to process rewards for
   */
  function _processVaultRewards(address _staker) private {
    User storage user = users[_staker];
    uint256 pendingVaultClaim = pendingVaultRewards(_staker);
    if (pendingVaultClaim == 0) return;
    // read ELIXIR token balance of the pool via standard ERC20 interface
    uint256 eliBalance = IERC20(eli).balanceOf(address(this));
    require(eliBalance >= pendingVaultClaim, "-7");

    // update `poolTokenReserve` only if this is a ELIXIR Core Pool
    if (poolToken == eli) {
      // protects against rounding errors
      poolTokenReserve -= pendingVaultClaim > poolTokenReserve
        ? poolTokenReserve
        : pendingVaultClaim;
    }

    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );

    // transfer fails if pool ELIXIR balance is not enough - which is a desired behavior
    transferEli(_staker, pendingVaultClaim);

    emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
  }

  /**
   * @dev Executes SafeERC20.safeTransfer on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferEli(address _to, uint256 _value) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransfer(IERC20(eli), _to, _value);
  }

  /**
   * @dev Executes SafeERC20.safeTransferFrom on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferEliFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransferFrom(IERC20(eli), _from, _to, _value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IPool.sol";
import "./interfaces/ICorePool.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IStarterInfo.sol";

/**
 * @title Pool Base
 *
 * @notice An abstract contract containing common logic for any pool,
 *      be it a flash pool (temporary pool like SNX) or a core pool (permanent pool like ELIXIR/ETH or ELIXIR pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (IPoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - ELIXIR token address
 *          - pool token address, it can be ELIXIR token address, ELIXIR/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 10% for ELIXIR pool and 90% for ELIXIR/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For ELIXIR Pool we use 100 as weight and for ELIXIR/ETH pool - 900.
 *
 */
abstract contract PoolBase is IPool, ReentrancyGuard {
  address public override eli;

  address[] public history;
  /// @dev Token holder storage, maps token holder address to their data record
  mapping(address => User) public users;

  /// @dev Link to the pool factory IPoolFactory instance
  IPoolFactory public factory;

  /// @dev Link to the pool token instance, for example ELIXIR or ELIXIR/ETH pair
  address public override poolToken;

  /// @dev Pool weight, 100 for ELIXIR pool or 900 for ELIXIR/ETH
  uint32 public override weight;

  /// @dev Block number of the last yield distribution event
  uint64 public override lastYieldDistribution;

  /// @dev Used to calculate yield rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public override yieldRewardsPerWeight;

  /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
  uint256 public override usersLockingWeight;

  /**
   * @dev Stake weight is proportional to deposit amount and time locked, precisely
   *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
   * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
   *      weight is stored multiplied by 1e6 constant, as an integer
   * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
   * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
   *      weight is a deposit amount multiplied by 2 * 1e6
   */
  uint256 internal WEIGHT_MULTIPLIER = 1e6;

  /** @dev Stake weight for Liquid Guys (its 1/10 of Normal Weight Multiplier)
   */
  uint256 internal LIQUID_MULTIPLIER = 1e5;

  /**
   * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
   *      we use simplified calculation and use the following constant instead previos one
   */
  uint256 internal YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

  /**
   * @dev Rewards per weight are stored multiplied by 1e12, as integers.
   */
  uint256 internal REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

  /**
   * @dev burn fee for each fee cycle: [5%, 3%, 1%, 0.5%, 0%]
   */
  uint256[] public burnFees = [500, 300, 100, 50, 0];
  /**
   * @dev days of each fee cycle
   */
  uint256[] public feeCycle = [2 days, 5 days, 10 days, 14 days];

  /**
   * @dev days of min stake to be Diamond
   */
  uint256 public minStakeTimeForDiamond = 7 days;

  mapping(address => bool) public presales;

  /**
   * @dev starter devs information
   */
  IStarterInfo public starterInfo;

  /**
   * @dev Fired in _stake() and stake()
   *
   * @param _by an address which performed an operation, usually token holder
   * @param _from token holder address, the tokens will be returned to that address
   * @param amount amount of tokens staked
   */
  event Staked(address indexed _by, address indexed _from, uint256 amount);

  /**
   * @dev Fired in _updateStakeLock() and updateStakeLock()
   *
   * @param _by an address which performed an operation
   * @param depositId updated deposit ID
   * @param lockedFrom deposit locked from value
   * @param lockedUntil updated deposit locked until value
   */
  event StakeLockUpdated(
    address indexed _by,
    uint256 depositId,
    uint64 lockedFrom,
    uint64 lockedUntil
  );

  /**
   * @dev Fired in _unstake() and unstake()
   *
   * @param _by an address which performed an operation, usually token holder
   * @param _to an address which received the unstaked tokens, usually token holder
   * @param amount amount of tokens unstaked
   */
  event Unstaked(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param yieldRewardsPerWeight updated yield rewards per weight value
   * @param lastYieldDistribution usually, current block number
   */
  event Synchronized(
    address indexed _by,
    uint256 yieldRewardsPerWeight,
    uint64 lastYieldDistribution
  );

  /**
   * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param _to an address which claimed the yield reward
   * @param amount amount of yield paid
   */
  event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Fired in setWeight()
   *
   * @param _by an address which performed an operation, always a factory
   * @param _fromVal old pool weight value
   * @param _toVal new pool weight value
   */
  event PoolWeightUpdated(address indexed _by, uint32 _fromVal, uint32 _toVal);

  /**
   * @dev Fired in setConfiguration()
   *
   * @param _by an address which performed an operation, always a factory
   * @param _fromRewardPerWeightMultiplier old value of REWARD_PER_WEIGHT_MULTIPLIER
   * @param _toRewardPerWeightMultiplier new value of REWARD_PER_WEIGHT_MULTIPLIER
   * @param _fromYearStakeWeightMultiplier old value of YEAR_STAKE_WEIGHT_MULTIPLIER
   * @param _toYearStakeWeightMultiplier new value of YEAR_STAKE_WEIGHT_MULTIPLIER
   * @param _fromWeightMultiplier old value of WEIGHT_MULTIPLIER
   * @param _toWeightMultiplier new value of WEIGHT_MULTIPLIER
   * @param _fromLiquidMultiplier old value of LIQUID_MULTIPLIER
   * @param _toLiquidMultiplier new value of LIQUID_MULTIPLIER
   */
  event PoolConfigurationUpdated(
    address indexed _by,
    uint256 _fromRewardPerWeightMultiplier,
    uint256 _toRewardPerWeightMultiplier,
    uint256 _fromYearStakeWeightMultiplier,
    uint256 _toYearStakeWeightMultiplier,
    uint256 _fromWeightMultiplier,
    uint256 _toWeightMultiplier,
    uint256 _fromLiquidMultiplier,
    uint256 _toLiquidMultiplier
  );

  modifier onlyStarterDevOrFactory() {
    require(
      starterInfo.getStarterDev(msg.sender) ||
        starterInfo.getPresaleFactory() == msg.sender,
      "-1"
    );
    _;
  }

  /**
   * @dev Overridden in sub-contracts to construct the pool
   *
   * @param _eli ELI ERC20 Token ElixirERC20 address
   * @param _factory Pool factory IPoolFactory instance/address
   * @param _poolToken token the pool operates on, for example ELIXIR or ELIXIR/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   */
  constructor(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight,
    address _starterInfo
  ) {
    require(address(_factory) != address(0), "-2");
    require(_poolToken != address(0), "-3");
    require(_initBlock != 0, "-4");
    require(_weight != 0, "-5");
    require(_starterInfo != address(0), "-6");

    // save the inputs into internal state variables
    eli = _eli;
    factory = _factory;
    poolToken = _poolToken;
    weight = _weight;
    starterInfo = IStarterInfo(_starterInfo);

    // init the dependent internal state variables
    lastYieldDistribution = _initBlock;
  }

  function initConfig(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) internal {
    eli = _eli;
    factory = _factory;
    poolToken = _poolToken;
    weight = _weight;
    lastYieldDistribution = _initBlock;
  }

  /**
   * @notice Calculates current yield rewards value available for address specified
   *
   * @param _staker an address to calculate yield rewards value for
   * @return calculated yield reward value for the given address
   */
  function pendingYieldRewards(address _staker)
    external
    view
    override
    returns (uint256)
  {
    // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
    uint256 newYieldRewardsPerWeight;

    // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
    // is outdated and we need to recalculate it in order to calculate pending rewards correctly
    if (block.number > lastYieldDistribution && usersLockingWeight != 0) {
      uint256 endBlock = factory.endBlock();
      uint256 multiplier = block.number > endBlock
        ? endBlock - lastYieldDistribution
        : block.number - lastYieldDistribution;
      uint256 eliRewards = (multiplier * weight * factory.eliPerBlock()) /
        factory.totalWeight();

      // recalculated value for `yieldRewardsPerWeight`
      newYieldRewardsPerWeight =
        rewardToWeight(eliRewards, usersLockingWeight) +
        yieldRewardsPerWeight;
    } else {
      // if smart contract state is up to date, we don't recalculate
      newYieldRewardsPerWeight = yieldRewardsPerWeight;
    }

    // based on the rewards per weight value, calculate pending rewards;
    User memory user = users[_staker];
    uint256 pending = weightToReward(
      user.totalWeight,
      newYieldRewardsPerWeight
    ) - user.subYieldRewards;

    return pending;
  }

  /**
   * @notice Returns total staked token balance for the given address
   *
   * @param _user an address to query balance for
   * @return total staked token balance
   */
  function balanceOf(address _user) external view override returns (uint256) {
    // read specified user token amount and return
    return users[_user].tokenAmount;
  }

  /**
   * @notice Returns information on the given deposit for the given address
   *
   * @dev See getDepositsLength
   *
   * @param _user an address to query deposit for
   * @param _depositId zero-indexed deposit ID for the address specified
   * @return deposit info as Deposit structure
   */
  function getDeposit(address _user, uint256 _depositId)
    external
    view
    override
    returns (Deposit memory)
  {
    // read deposit at specified index and return
    return users[_user].deposits[_depositId];
  }

  /**
   * @notice Returns number of deposits for the given address. Allows iteration over deposits.
   *
   * @dev See getDeposit
   *
   * @param _user an address to query deposit length for
   * @return number of deposits for the given address
   */
  function getDepositsLength(address _user)
    external
    view
    override
    returns (uint256)
  {
    // read deposits array length and return
    return users[_user].deposits.length;
  }

  /**
   * @notice Stakes specified amount of tokens for the specified amount of time,
   *      and pays pending yield rewards if any
   *
   * @dev Requires amount to stake to be greater than zero
   *
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   */
  function stake(uint256 _amount, uint64 _lockUntil) external override {
    // delegate call to an internal function
    _stake(msg.sender, _amount, _lockUntil, false, 0);
    history.push(msg.sender);
  }

  /**
   * @notice Stakes specified amount of tokens to an user for the specified amount of time,
   *      and pays pending yield rewards if any
   *
   * @dev Requires amount to stake to be greater than zero
   *
   * @param _staker address to stake
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   */
  function stakeFor(
    address _staker,
    uint256 _amount,
    uint64 _lockUntil
  ) external override {
    require(_staker != msg.sender, "-7");
    // delegate call to an internal function
    _stake(_staker, _amount, _lockUntil, false, 0);
    history.push(_staker);
  }

  /**
   * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
   *
   * @dev Requires amount to unstake to be greater than zero
   *
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   */
  function unstake(uint256 _depositId, uint256 _amount) external override {
    // delegate call to an internal function
    _unstake(msg.sender, _depositId, _amount);
    history.push(msg.sender);
  }

  /**
   * @notice Extends locking period for a given deposit
   *
   * @dev Requires new lockedUntil value to be:
   *      higher than the current one, and
   *      in the future, but
   *      no more than 1 year in the future
   *
   * @param depositId updated deposit ID
   * @param lockedUntil updated deposit locked until value
   */
  function updateStakeLock(uint256 depositId, uint64 lockedUntil) external {
    // sync and call processRewards
    _sync();
    _processRewards(msg.sender, false);
    // delegate call to an internal function
    _updateStakeLock(msg.sender, depositId, lockedUntil);
  }

  /**
   * @notice Service function to synchronize pool state with current time
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      at least one block passes between synchronizations
   * @dev Executed internally when staking, unstaking, processing rewards in order
   *      for calculations to be correct and to reflect state progress of the contract
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   */
  function sync() external override {
    // delegate call to an internal function
    _sync();
  }

  /**
   * @notice Service function to calculate and pay pending yield rewards to the sender
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when staking and unstaking, executes sync() under the hood
   *      before making further calculations and payouts
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   */
  function processRewards() external virtual override {
    // delegate call to an internal function
    _processRewards(msg.sender, true);
  }

  /**
   * @dev Executed by the factory to modify pool weight; the factory is expected
   *      to keep track of the total pools weight when updating
   *
   * @dev Set weight to zero to disable the pool
   *
   * @param _weight new weight to set for the pool
   */
  function setWeight(uint32 _weight) external override {
    // verify function is executed by the factory
    require(msg.sender == address(factory), "-8");

    // emit an event logging old and new weight values
    emit PoolWeightUpdated(msg.sender, weight, _weight);

    // set the new weight value
    weight = _weight;
  }

  /**
   * @dev Similar to public pendingYieldRewards, but performs calculations based on
   *      current smart contract state only, not taking into account any additional
   *      time/blocks which might have passed
   *
   * @param _staker an address to calculate yield rewards value for
   * @return pending calculated yield reward value for the given address
   */
  function _pendingYieldRewards(address _staker)
    internal
    view
    returns (uint256 pending)
  {
    // read user data structure into memory
    User memory user = users[_staker];

    // and perform the calculation using the values read
    return
      weightToReward(user.totalWeight, yieldRewardsPerWeight) -
      user.subYieldRewards;
  }

  /**
   * @dev Used internally, mostly by children implementations, see stake()
   *
   * @param _staker an address which stakes tokens and which will receive them back
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   * @param _isYield a flag indicating if that stake is created to store yield reward
   *      from the previously unstaked stake
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockUntil,
    bool _isYield,
    uint256 _liquidPercent
  ) internal virtual {
    // validate the inputs
    require(_amount != 0, "-9");
    require(
      _lockUntil == 0 ||
        (_lockUntil > block.timestamp &&
          _lockUntil - block.timestamp <= 365 days),
      "-10"
    );

    // update smart contract state
    _sync();

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // process current pending rewards if any
    if (user.tokenAmount > 0) {
      _processRewards(_staker, false);
    }

    // in most of the cases added amount `addedAmount` is simply `_amount`
    // however for deflationary tokens this can be different

    // read the current balance
    uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
    // transfer `_amount`; note: some tokens may get burnt here
    transferPoolTokenFrom(address(msg.sender), address(this), _amount);
    // read new balance, usually this is just the difference `previousBalance - _amount`
    uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
    // calculate real amount taking into account deflation
    uint256 addedAmount = newBalance - previousBalance;

    if (user.firstStakedTimestamp == 0) {
      user.firstStakedTimestamp = block.timestamp;
    }
    if (user.lastUnstakedTimestamp == 0) {
      user.lastUnstakedTimestamp = block.timestamp;
    }
    user.lastStakedTimestamp = block.timestamp;
    user.lastInvestTimestamp = block.timestamp;

    // set the `lockFrom` and `lockUntil` taking into account that
    // zero value for `_lockUntil` means "no locking" and leads to zero values
    // for both `lockFrom` and `lockUntil`
    uint64 lockFrom = _lockUntil > 0 ? uint64(block.timestamp) : 0;
    uint64 lockUntil = _lockUntil;

    uint256 weightMultiplier = lockUntil > 0
      ? WEIGHT_MULTIPLIER
      : LIQUID_MULTIPLIER;

    // stake weight formula rewards for locking
    uint256 stakeWeight = (((lockUntil - lockFrom) * weightMultiplier) /
      365 days +
      weightMultiplier) * addedAmount;

    // makes sure stakeWeight is valid
    if (lockUntil != 0) {
      assert(stakeWeight > 0);
    }

    // create and save the deposit (append it to deposits array)
    Deposit memory deposit = Deposit({
      tokenAmount: addedAmount,
      weight: stakeWeight,
      liquidPercentage: _isYield ? _liquidPercent : 0,
      lockedFrom: lockFrom,
      lockedUntil: lockUntil,
      isYield: _isYield
    });
    // deposit ID is an index of the deposit in `deposits` array
    user.deposits.push(deposit);

    // update user record
    user.tokenAmount += addedAmount;
    user.totalWeight += stakeWeight;
    if (lockUntil == 0) {
      user.liquidAmount += addedAmount;
      user.liquidWeight += stakeWeight;
    }
    user.subYieldRewards = weightToReward(
      user.totalWeight,
      yieldRewardsPerWeight
    );

    // update global variable
    usersLockingWeight += stakeWeight;

    // emit an event
    emit Staked(msg.sender, _staker, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see unstake()
   *
   * @param _staker an address which unstakes tokens (which previously staked them)
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount
  ) internal virtual {
    // verify an amount is set
    require(_amount != 0, "-11");

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];

    // deposit structure may get deleted, so we save isYield and liquidPercetange to be able to use it
    bool isYield = stakeDeposit.isYield;
    uint256 liquidPercentage = stakeDeposit.liquidPercentage;

    // verify available balance
    // if staker address ot deposit doesn't exist this check will fail as well
    require(stakeDeposit.tokenAmount >= _amount, "-12");

    // update smart contract state
    _sync();
    // and process current pending rewards if any
    _processRewards(_staker, false);

    // recalculate deposit weight
    uint256 previousWeight = stakeDeposit.weight;
    uint256 stakeWeightMultiplier = stakeDeposit.lockedUntil == 0
      ? LIQUID_MULTIPLIER
      : WEIGHT_MULTIPLIER;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) *
      stakeWeightMultiplier) /
      365 days +
      stakeWeightMultiplier) * (stakeDeposit.tokenAmount - _amount);

    if (stakeDeposit.lockedUntil == 0) {
      user.liquidAmount -= _amount;
      user.liquidWeight = user.liquidWeight - previousWeight + newWeight;
    }

    // update the deposit, or delete it if its depleted
    if (stakeDeposit.tokenAmount - _amount == 0) {
      delete user.deposits[_depositId];
    } else {
      stakeDeposit.tokenAmount -= _amount;
      stakeDeposit.weight = newWeight;
    }

    // update user record
    user.tokenAmount -= _amount;
    user.totalWeight = user.totalWeight - previousWeight + newWeight;
    user.subYieldRewards = weightToReward(
      user.totalWeight,
      yieldRewardsPerWeight
    );

    if (user.tokenAmount == 0) {
      user.firstStakedTimestamp = 0;
      user.lastStakedTimestamp = 0;
      user.lastUnstakedTimestamp = 0;
      user.lastInvestTimestamp = 0;
    } else {
      user.firstStakedTimestamp = block.timestamp;
      user.lastStakedTimestamp = block.timestamp;
      user.lastUnstakedTimestamp = block.timestamp;
    }

    // update global variable
    usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

    // if the deposit was created by the pool itself as a yield reward
    if (isYield) {
      // transfer the yield via the factory
      uint256 liquidRewardAmount = (_amount * liquidPercentage) / 100;
      factory.transferYieldTo(msg.sender, _amount, liquidRewardAmount);
    } else {
      uint256 burnAmount = (_amount * getTokenBurnFee(msg.sender)) / 10000;
      // otherwise just return tokens back to holder
      if (burnAmount > 0) {
        transferPoolToken(
          address(0x000000000000000000000000000000000000dEaD),
          burnAmount
        );
      }
      if (burnAmount < _amount) {
        transferPoolToken(msg.sender, _amount - burnAmount);
      }
    }

    // emit an event
    emit Unstaked(msg.sender, _staker, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see sync()
   *
   * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
   *      updates factory state via `updateELIPerBlock`
   */
  function _sync() internal virtual {
    // update ELIXIR per block value in factory if required
    if (factory.shouldUpdateRatio()) {
      factory.updateELIPerBlock();
    }

    // check bound conditions and if these are not met -
    // exit silently, without emitting an event
    uint256 endBlock = factory.endBlock();
    if (lastYieldDistribution >= endBlock) {
      return;
    }
    if (block.number <= lastYieldDistribution) {
      return;
    }
    // if locking weight is zero - update only `lastYieldDistribution` and exit
    if (usersLockingWeight == 0) {
      lastYieldDistribution = uint64(block.number);
      return;
    }

    // to calculate the reward we need to know how many blocks passed, and reward per block
    uint256 currentBlock = block.number > endBlock ? endBlock : block.number;
    uint256 blocksPassed = currentBlock - lastYieldDistribution;
    uint256 eliPerBlock = factory.eliPerBlock();

    // calculate the reward
    uint256 eliReward = (blocksPassed * eliPerBlock * weight) /
      factory.totalWeight();

    // update rewards per weight and `lastYieldDistribution`
    yieldRewardsPerWeight += rewardToWeight(eliReward, usersLockingWeight);
    lastYieldDistribution = uint64(currentBlock);

    // emit an event
    emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
  }

  /**
   * @dev Used internally, mostly by children implementations, see processRewards()
   *
   * @param _staker an address which receives the reward (which has staked some tokens earlier)
   * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
   * @return pendingYield the rewards calculated and optionally re-staked
   */
  function _processRewards(address _staker, bool _withUpdate)
    internal
    virtual
    returns (uint256 pendingYield)
  {
    // update smart contract state if required
    if (_withUpdate) {
      _sync();
    }

    // calculate pending yield rewards, this value will be returned
    pendingYield = _pendingYieldRewards(_staker);

    // if pending yield is zero - just return silently
    if (pendingYield == 0) return 0;

    // get link to a user data structure, we will write into it later
    User storage user = users[_staker];

    if (poolToken == eli) {
      // calculate pending yield weight,
      // 2e6 is the bonus weight when staking for 1 year
      uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

      // if the pool is ELIXIR Pool - create new ELIXIR deposit
      // and save it - push it into deposits array
      Deposit memory newDeposit = Deposit({
        tokenAmount: pendingYield,
        lockedFrom: uint64(block.timestamp),
        lockedUntil: uint64(block.timestamp + getRewardLockPeriod(_staker)), // staking yield for Reward Lock Period
        weight: depositWeight,
        liquidPercentage: (user.liquidWeight * 100) / user.totalWeight,
        isYield: true
      });
      user.deposits.push(newDeposit);

      // update user record
      user.tokenAmount += pendingYield;
      user.totalWeight += depositWeight;

      // update global variable
      usersLockingWeight += depositWeight;
    } else {
      // for other pools - stake as pool
      address eliPool = factory.getPoolAddress(eli);
      ICorePool(eliPool).stakeAsPool(
        _staker,
        pendingYield,
        (user.liquidWeight * 100) / user.totalWeight,
        getRewardLockPeriod(_staker)
      );
    }

    // update users's record for `subYieldRewards` if requested
    if (_withUpdate) {
      user.subYieldRewards = weightToReward(
        user.totalWeight,
        yieldRewardsPerWeight
      );
    }

    // emit an event
    emit YieldClaimed(msg.sender, _staker, pendingYield);
  }

  /**
   * @dev See updateStakeLock()
   *
   * @param _staker an address to update stake lock
   * @param _depositId updated deposit ID
   * @param _lockedUntil updated deposit locked until value
   */
  function _updateStakeLock(
    address _staker,
    uint256 _depositId,
    uint64 _lockedUntil
  ) internal {
    // validate the input time
    require(_lockedUntil > block.timestamp, "-13");

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];

    // validate the input against deposit structure
    require(_lockedUntil > stakeDeposit.lockedUntil, "-14");

    // verify locked from and locked until values
    if (stakeDeposit.lockedFrom == 0) {
      require(_lockedUntil - block.timestamp <= 365 days, "-15");
      stakeDeposit.lockedFrom = uint64(block.timestamp);
    } else {
      require(_lockedUntil - stakeDeposit.lockedFrom <= 365 days, "-16");
    }

    // update locked until value, calculate new weight
    stakeDeposit.lockedUntil = _lockedUntil;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) *
      WEIGHT_MULTIPLIER) /
      365 days +
      WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

    // save previous weight
    uint256 previousWeight = stakeDeposit.weight;
    // update weight
    stakeDeposit.weight = newWeight;

    // update user total weight and global locking weight
    user.totalWeight = user.totalWeight - previousWeight + newWeight;
    usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

    // emit an event
    emit StakeLockUpdated(
      _staker,
      _depositId,
      stakeDeposit.lockedFrom,
      _lockedUntil
    );
  }

  /**
   * @dev Converts stake weight (not to be mixed with the pool weight) to
   *      ELIXIR reward value, applying the 10^12 division on weight
   *
   * @param _weight stake weight
   * @param rewardPerWeight ELIXIR reward per weight
   * @return reward value normalized to 10^12
   */
  function weightToReward(uint256 _weight, uint256 rewardPerWeight)
    public
    view
    returns (uint256)
  {
    // apply the formula and return
    return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
  }

  /**
   * @dev Converts reward ELIXIR value to stake weight (not to be mixed with the pool weight),
   *      applying the 10^12 multiplication on the reward
   *      - OR -
   * @dev Converts reward ELIXIR value to reward/weight if stake weight is supplied as second
   *      function parameter instead of reward/weight
   *
   * @param reward yield reward
   * @param rewardPerWeight reward/weight (or stake weight)
   * @return stake weight (or reward/weight)
   */
  function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
    public
    view
    returns (uint256)
  {
    // apply the reverse formula and return
    return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
  }

  /**
   * @dev Executes SafeERC20.safeTransfer on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferPoolToken(address _to, uint256 _value)
    internal
    nonReentrant
  {
    // just delegate call to the target
    SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
  }

  /**
   * @dev Executes SafeERC20.safeTransferFrom on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferPoolTokenFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
  }

  /** @dev Get History Length */
  function getHistoryLength() external view returns (uint256) {
    return history.length;
  }

  /** @dev Get tokens to burn */
  function getTokenBurnFee(address _staker) public view returns (uint256) {
    User memory user = users[_staker];
    for (uint256 i = 0; i < feeCycle.length; i++) {
      if (
        (block.timestamp < user.lastUnstakedTimestamp + feeCycle[i]) ||
        block.timestamp < user.lastInvestTimestamp + feeCycle[i]
      ) {
        return burnFees[i];
      }
    }
    return burnFees[feeCycle.length];
  }

  function setStakingConfig(
    uint256 _index,
    uint256 _cycle,
    uint256 _fee,
    uint256 _minStakeTime,
    address _newStarterInfo
  ) external onlyStarterDevOrFactory {
    feeCycle[_index] = _cycle;
    burnFees[_index] = _fee;
    minStakeTimeForDiamond = _minStakeTime;
    starterInfo = IStarterInfo(_newStarterInfo);
  }

  function isLongStaker(address _sender) external view returns (bool) {
    User memory user = users[_sender];
    return
      user.tokenAmount > 0 &&
      user.firstStakedTimestamp > 0 &&
      user.firstStakedTimestamp + minStakeTimeForDiamond < block.timestamp;
  }

  function updateLastInvestTimestamp(address _user, uint256 _timestamp)
    external
  {
    require(
      starterInfo.getStarterDev(msg.sender) || presales[msg.sender],
      "-17"
    );
    users[_user].lastInvestTimestamp = _timestamp;
  }

  /** @dev Clearing History for more updates */
  function clearHistory() external {
    require(msg.sender == factory.owner(), "-18");
    delete history;
  }

  function setConfiguration(
    uint256 _rewardPerWeightMultiplier,
    uint256 _yearStakeWeightMultiplier,
    uint256 _weightMultiplier,
    uint256 _liquidMultiplier
  ) external {
    require(msg.sender == factory.owner(), "-19");

    emit PoolConfigurationUpdated(
      msg.sender,
      REWARD_PER_WEIGHT_MULTIPLIER,
      _rewardPerWeightMultiplier,
      YEAR_STAKE_WEIGHT_MULTIPLIER,
      _yearStakeWeightMultiplier,
      WEIGHT_MULTIPLIER,
      _weightMultiplier,
      LIQUID_MULTIPLIER,
      _liquidMultiplier
    );

    REWARD_PER_WEIGHT_MULTIPLIER = _rewardPerWeightMultiplier;
    YEAR_STAKE_WEIGHT_MULTIPLIER = _yearStakeWeightMultiplier;
    WEIGHT_MULTIPLIER = _weightMultiplier;
    LIQUID_MULTIPLIER = _liquidMultiplier;
  }

  function setInitialSettings(address _factory, address _poolToken) external {
    require(msg.sender == factory.owner(), "-20");
    factory = IPoolFactory(_factory);
    poolToken = _poolToken;
  }

  /** @dev Get Reward Lock Time */
  function getRewardLockPeriod(address _staker) public view returns (uint256) {
    User storage user = users[_staker];
    if (user.tokenAmount == 0) {
      return factory.maximumRewardLock();
    }

    uint256 i;
    uint256 totalSum = 0;
    for (i = 0; i < user.deposits.length; i++) {
      Deposit storage stakeDeposit = user.deposits[i];
      if (!stakeDeposit.isYield) {
        totalSum =
          totalSum +
          stakeDeposit.tokenAmount *
          (stakeDeposit.lockedUntil - stakeDeposit.lockedFrom);
      }
    }
    uint256 averageLocked = factory.maximumRewardLock() -
      totalSum /
      user.tokenAmount;
    if (averageLocked < factory.minimumRewardLock()) {
      return factory.minimumRewardLock();
    }
    if (averageLocked > factory.maximumRewardLock()) {
      return factory.maximumRewardLock();
    }
    return averageLocked;
  }

  function addPresaleAddress(address _presale)
    external
    onlyStarterDevOrFactory
  {
    presales[_presale] = true;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

interface IStarterInfo {
  function owner() external returns (address);

  function getCakeV2LPAddress(
    address tokenA,
    address tokenB,
    uint256 swapIndex
  ) external view returns (address pair);

  function getStarterSwapLPAddress(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function getStarterDev(address _dev) external view returns (bool);

  function setStarterDevAddress(address _newDev) external;

  function removeStarterDevAddress(address _oldDev) external;

  function getPresaleCreatorDev(address _dev) external view returns (bool);

  function setPresaleCreatorDevAddress(address _newDev) external;

  function removePresaleCreatorDevAddress(address _oldDev) external;

  function getPoolFactory() external view returns (address);

  function setPoolFactory(address _newFactory) external;

  function getPresaleFactory() external view returns (address);

  function setPresaleFactory(address _newFactory) external;

  function addPresaleAddress(address _presale) external returns (uint256);

  function getPresalesCount() external view returns (uint256);

  function getPresaleAddress(uint256 bscsId) external view returns (address);

  function setPresaleAddress(uint256 bscsId, address _newAddress) external;

  function getDevFeePercentage(uint256 presaleType)
    external
    view
    returns (uint256);

  function setDevFeePercentage(uint256 presaleType, uint256 _devFeePercentage)
    external;

  function getMinDevFeeInWei() external view returns (uint256);

  function setMinDevFeeInWei(uint256 _minDevFeeInWei) external;

  function getMinInvestorBalance(address tokenAddress)
    external
    view
    returns (uint256);

  function setMinInvestorBalance(
    address tokenAddress,
    uint256 _minInvestorBalance
  ) external;

  function getMinYesVotesThreshold(address tokenAddress)
    external
    view
    returns (uint256);

  function setMinYesVotesThreshold(
    address tokenAddress,
    uint256 _minYesVotesThreshold
  ) external;

  function getMinCreatorStakedBalance(address fundingTokenAddress)
    external
    view
    returns (uint256);

  function setMinCreatorStakedBalance(
    address fundingTokenAddress,
    uint256 _minCreatorStakedBalance
  ) external;

  function getMinInvestorGuaranteedBalance(address tokenAddress)
    external
    view
    returns (uint256);

  function setMinInvestorGuaranteedBalance(
    address tokenAddress,
    uint256 _minInvestorGuaranteedBalance
  ) external;

  function getMinStakeTime() external view returns (uint256);

  function setMinStakeTime(uint256 _minStakeTime) external;

  function getMinUnstakeTime() external view returns (uint256);

  function setMinUnstakeTime(uint256 _minUnstakeTime) external;

  function getCreatorUnsoldClaimTime() external view returns (uint256);

  function setCreatorUnsoldClaimTime(uint256 _creatorUnsoldClaimTime) external;

  function getSwapRouter(uint256 index) external view returns (address);

  function setSwapRouter(uint256 index, address _swapRouter) external;

  function addSwapRouter(address _swapRouter) external;

  function getSwapFactory(uint256 index) external view returns (address);

  function setSwapFactory(uint256 index, address _swapFactory) external;

  function addSwapFactory(address _swapFactory) external;

  function getInitCodeHash(address _swapFactory)
    external
    view
    returns (bytes32);

  function setInitCodeHash(address _swapFactory, bytes32 _initCodeHash)
    external;

  function getStarterSwapRouter() external view returns (address);

  function setStarterSwapRouter(address _starterSwapRouter) external;

  function getStarterSwapFactory() external view returns (address);

  function setStarterSwapFactory(address _starterSwapFactory) external;

  function getStarterSwapICH() external view returns (bytes32);

  function setStarterSwapICH(bytes32 _initCodeHash) external;

  function getStarterSwapLPPercent() external view returns (uint256);

  function setStarterSwapLPPercent(uint256 _starterSwapLPPercent) external;

  function getWBWB() external view returns (address);

  function setWBNB(address _wmatic) external;

  function getVestingAddress() external view returns (address);

  function setVestingAddress(address _newVesting) external;

  function getInvestmentLimit(address tokenAddress)
    external
    view
    returns (uint256);

  function setInvestmentLimit(address tokenAddress, uint256 _limit) external;

  function getLpAddress(address tokenAddress) external view returns (address);

  function setLpAddress(address tokenAddress, address lpAddress) external;

  function getStartLpStaked(address lpAddress, address payable sender)
    external
    view
    returns (uint256);

  function getTotalStartLpStaked(address lpAddress)
    external
    view
    returns (uint256);

  function getStaked(address fundingTokenAddress, address payable sender)
    external
    view
    returns (uint256);

  function getTotalStaked(address fundingTokenAddress)
    external
    view
    returns (uint256);

  function getDevPresaleTokenFee() external view returns (uint256);

  function setDevPresaleTokenFee(uint256 _devPresaleTokenFee) external;

  function getDevPresaleAllocationAddress() external view returns (address);

  function setDevPresaleAllocationAddress(address _devPresaleAllocationAddress)
    external;

  function isBlacklistedAddress(address _sender) external view returns (bool);

  function addBlacklistedAddresses(address[] calldata _blacklistedAddresses)
    external;

  function removeBlacklistedAddresses(address[] calldata _blacklistedAddresses)
    external;

  function isAuditorWhitelistedAddress(address _sender)
    external
    view
    returns (bool);

  function addAuditorWhitelistedAddresses(
    address[] calldata _whitelistedAddresses
  ) external;

  function removeAuditorWhitelistedAddresses(
    address[] calldata _whitelistedAddresses
  ) external;
}