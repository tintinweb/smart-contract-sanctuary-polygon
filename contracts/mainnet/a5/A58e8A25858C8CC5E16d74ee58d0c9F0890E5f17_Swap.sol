// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./libs/app/Auth.sol";
import "./libs/app/MerkelProof.sol";
import "./interfaces/ILPToken.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/IMENToken.sol";
import "./interfaces/ITaxManager.sol";
import "./interfaces/IConcentratedLiquiditySystem.sol";
import "./interfaces/IVault.sol";
import "./abstracts/BaseContract.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/INFTPass.sol";
import "./interfaces/ILSD.sol";

contract Swap is BaseContract {
  struct Config {
    uint secondsInADay;
    uint dnoPrice;
    uint dnoUserCap;
    uint dnoSystemCap;
    uint dnoSold;
    uint dnoStakingRate; // decimal 18
    uint dnoDiscountPercentage; // decimal 3
    bool useUniswapForDNO;
    bool toUniswap;
    bytes32 rootHash;
    address treasury;
  }
  struct User {
    uint userBoughtDNO;
    bool bought;
  }
  Config public config;
  IMENToken public menToken;
  IBEP20 public busdToken; // TODO remove on next deployment
  IBEP20 public usdtToken;
  INFTPass public nftPass;
  IConcentratedLiquiditySystem public concentratedLiquiditySystem;
  IVault public vault;
  ITaxManager public taxManager;
  IUniswapV2Router02 public uniswapV2Router;
  uint private constant DECIMAL3 = 1000;
  mapping (address => User) public users;
  IBEP20 public usdcToken;
  IBEP20 public daiToken;
  ILSD public lsd;
  ILPToken public lpToken;
  uint private constant SLIPPAGE = 995; // decimal 3

  event ConfigUpdated(
    uint secondsInADay,
    uint dnoPrice,
    uint dnoUserCap,
    uint dnoSystemCap,
    uint dnoStakingRate,
    uint dnoDiscountPercentage,
    bool useUniswapForDNO,
    bool toUniswap,
    address treasury,
    uint timestamp
  );
  event DNOBought(address indexed buyer, uint quantity, uint price, bool whitelisted, ISwap.PaymentCurrency paymentCurrency, uint timestamp);
  event SeedCapUpdated(uint seedSaleHardCap, uint seedPersonalCap, uint timestamp);
  event TokenBought(address indexed buyer, uint usdAmount, uint tokenAmount, ISwap.PaymentCurrency paymentCurrency, bool autoStake, uint timestamp);
  event TokenSold(address indexed seller, uint tokenAmount, uint usdAmount, uint timestamp);

  function initialize() public initializer {
    BaseContract.init();
    config.dnoPrice = 100 ether;
    config.dnoUserCap = 1_000 ether;
    config.dnoSystemCap = 100_000;
    config.dnoStakingRate = 1000;
    config.secondsInADay = 86_400;
  }

  function swapUSDForToken(uint _usdAmount, ISwap.PaymentCurrency _paymentCurrency, bool _autoStake) external returns (uint) {
    IBEP20 usdToken = _loadUsdToken(_paymentCurrency);
    uint tokenAmount;
    if(config.toUniswap) {
      _takeFund(usdToken, _usdAmount, address(this));
      tokenAmount = _swapUSDForTokenViaUniswap(_usdAmount, _paymentCurrency);
    } else {
      _takeFund(usdToken, _usdAmount, config.treasury);
      tokenAmount = concentratedLiquiditySystem.swapUSDForToken(_usdAmount);
    }
    uint taxAmount = tokenAmount * taxManager.totalTaxPercentage() / DECIMAL3 / 100;
    uint netAmount = tokenAmount - taxAmount;
    if (_autoStake) {
      if(lsd.isQualifiedForTaxDiscount(msg.sender) && menToken.lsdDiscountTaxPercentages(IMENToken.TaxType.Buy) > 0) {
        taxAmount = taxAmount * (DECIMAL3 - menToken.lsdDiscountTaxPercentages(IMENToken.TaxType.Buy)) / DECIMAL3;
        netAmount = tokenAmount - taxAmount;
      }
      menToken.transfer(address(taxManager), taxAmount);
      menToken.transfer(address(vault), netAmount);
      vault.depositFor(msg.sender, netAmount, IVault.DepositType.swapUSDForToken);
    } else {
      menToken.transfer(msg.sender, tokenAmount);
      uint discountedTax = _calculateDiscountedTax(msg.sender, taxAmount);
      netAmount = netAmount + discountedTax;
    }

    emit TokenBought(msg.sender, _usdAmount, netAmount, _paymentCurrency, _autoStake, block.timestamp);
    return netAmount;
  }

  function swapTokenForUSDT(uint _amount, bool _cls) external {
    uint contractBalance = menToken.balanceOf(address(this));
    _takeFund(menToken, _amount, address(this));
    uint swappedToken = menToken.balanceOf(address(this)) - contractBalance;
    uint usdAmount;
    if (_cls) {
      usdAmount = concentratedLiquiditySystem.swapTokenForUSDT(swappedToken);
    } else if (config.toUniswap) {
      usdAmount = _swapTokenForUSDTViaUniswap(swappedToken);
    } else {
      usdAmount = concentratedLiquiditySystem.swapTokenForUSDT(swappedToken);
    }
    usdtToken.transfer(msg.sender, usdAmount);
    emit TokenSold(msg.sender, _amount, usdAmount, block.timestamp);
    menToken.transfer(address(concentratedLiquiditySystem), swappedToken);
  }

  function buyDNO(uint _quantity, ISwap.PaymentCurrency _paymentCurrency) external {
    uint orderValue = _quantity * config.dnoPrice;
    require(users[msg.sender].userBoughtDNO + orderValue <= config.dnoUserCap, "DNO: user cap reached");
    _buyDNO(_quantity, orderValue, _paymentCurrency);
    emit DNOBought(msg.sender, _quantity, config.dnoPrice, false, _paymentCurrency, block.timestamp);
  }

  function buyDNO2(uint _quantity, uint _price, ISwap.PaymentCurrency _paymentCurrency, bytes32[] calldata _path) external {
    uint orderValue = _quantity * _price;
    require(!users[msg.sender].bought, "DNO: bought");
    bytes32 hash = keccak256(abi.encodePacked(msg.sender, _quantity, _price));
    require(MerkleProof.verify(_path, config.rootHash, hash), "DNO: round invalid");
    users[msg.sender].bought = true;
    _buyDNO(_quantity, orderValue, _paymentCurrency);
    emit DNOBought(msg.sender, _quantity, _price, true, _paymentCurrency, block.timestamp);
  }

  function getDNOStakingRate() external view returns (uint) {
    return config.dnoStakingRate;
  }

  // AUTH FUNCTIONS

  function updateConfig(
    uint _secondsInADay,
    uint _dnoPrice,
    uint _dnoUserCap,
    uint _dnoSystemCap,
    uint _dnoStakingRate,
    uint _dnoDiscountPercentage,
    bool _useUniswapForDNO,
    bool _toUniswap,
    address _treasury
  ) external onlyMn {
    config.secondsInADay = _secondsInADay;
    config.dnoPrice = _dnoPrice;
    config.dnoUserCap = _dnoUserCap;
    config.dnoSystemCap = _dnoSystemCap;
    config.dnoStakingRate = _dnoStakingRate;
    config.dnoDiscountPercentage = _dnoDiscountPercentage;
    config.toUniswap = _toUniswap;
    config.useUniswapForDNO = _useUniswapForDNO;
    config.treasury = _treasury;

    emit ConfigUpdated(_secondsInADay, _dnoPrice, _dnoUserCap, _dnoSystemCap, _dnoStakingRate, _dnoDiscountPercentage, _useUniswapForDNO, _toUniswap, _treasury, block.timestamp);
  }

  function setRootHash(bytes32 _rootHash) external onlyMn {
    config.rootHash = _rootHash;
  }

  // PRIVATE METHODS

  function _getStakingRate() private view returns (uint) {
    if (config.useUniswapForDNO) {
      return vault.getTokenPrice();
    }
    return config.dnoStakingRate;
  }

  function _buyDNO(uint _quantity, uint _orderValue, ISwap.PaymentCurrency _paymentCurrency) private {
    require(config.dnoSold + _quantity <= config.dnoSystemCap, "DNO: system cap reached");
    users[msg.sender].userBoughtDNO += _orderValue;
    IBEP20 usdToken = _loadUsdToken(_paymentCurrency);
    uint orderNetValue = _orderValue * (100 * DECIMAL3 - config.dnoDiscountPercentage) / DECIMAL3 / 100;
    _takeFund(usdToken, orderNetValue, config.treasury);
    nftPass.mint(msg.sender, _quantity);
    uint stakingRate = _getStakingRate();
    vault.depositFor(msg.sender, _orderValue * DECIMAL3 / stakingRate, IVault.DepositType.swapBuyDNO);
    config.dnoSold += _quantity;
  }

  function _swapTokenForUSDTViaUniswap(uint _tokenAmount) private returns (uint) {
    address[] memory path = new address[](2);
    path[0] = address(menToken);
    path[1] = address(usdtToken);
    uint currentUsdtBalance = usdtToken.balanceOf(address(this));
    uint minOutput = (_tokenAmount * SLIPPAGE / DECIMAL3) * (_getTokenPrice() / DECIMAL3);
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_tokenAmount, minOutput, path, address(this), block.timestamp);
    return usdtToken.balanceOf(address(this)) - currentUsdtBalance;
  }

  function _swapUsdcOrDaiToUsdt(uint _usdAmount, address _tokenAddress) private returns (uint) {
    address[] memory path = new address[](2);
    path[0] = _tokenAddress;
    path[1] = address(usdtToken);
    uint currentUsdtBalance = usdtToken.balanceOf(address(this));
    uint minOutput = (_usdAmount * SLIPPAGE / DECIMAL3) / (_getTokenPrice() / DECIMAL3);
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_usdAmount, minOutput, path, address(this), block.timestamp);
    uint swappedUsdt = usdtToken.balanceOf(address(this)) - currentUsdtBalance;
    return swappedUsdt;
  }

  function _swapUSDForTokenViaUniswap(uint _usdAmount, ISwap.PaymentCurrency _paymentCurrency) private returns (uint) {
    address[] memory path = new address[](2);
    if (_paymentCurrency == ISwap.PaymentCurrency.usdc || _paymentCurrency == ISwap.PaymentCurrency.dai) {
      _usdAmount = _swapUsdcOrDaiToUsdt(_usdAmount, _paymentCurrency == ISwap.PaymentCurrency.usdc ? address(usdcToken) : address(daiToken));
    }
    path[0] = address(usdtToken);
    path[1] = address(menToken);
    uint currentMenBalance = menToken.balanceOf(address(this));
    uint minOutput = (_usdAmount * SLIPPAGE / DECIMAL3) / (_getTokenPrice() / DECIMAL3);
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_usdAmount, minOutput, path, address(this), block.timestamp);
    return menToken.balanceOf(address(this)) - currentMenBalance;
  }

  function _takeFund(IBEP20 _token, uint _amount, address _receiver) private {
    require(_token.allowance(msg.sender, address(this)) >= _amount, "Swap: allowance invalid");
    require(_token.balanceOf(msg.sender) >= _amount, "Swap: insufficient balance");
    _token.transferFrom(msg.sender, _receiver, _amount);
  }

  function _loadUsdToken(ISwap.PaymentCurrency _paymentCurrency) private view returns (IBEP20) {
    if (_paymentCurrency == ISwap.PaymentCurrency.usdt) {
      return usdtToken;
    } else if (_paymentCurrency == ISwap.PaymentCurrency.dai) {
      return daiToken;
    } else {
      return usdcToken;
    }
  }

  function _calculateDiscountedTax(address _to, uint _taxAmount) private returns (uint) {
    if (menToken.getWhitelistTax(_to, IMENToken.TaxType.Buy)) {
      return 0;
    }

    if(lsd.isQualifiedForTaxDiscount(_to) && menToken.lsdDiscountTaxPercentages(IMENToken.TaxType.Buy) > 0) {
      return _taxAmount * menToken.lsdDiscountTaxPercentages(IMENToken.TaxType.Buy) / DECIMAL3;
    }

    return 0;
  }

  function _getTokenPrice() private view returns (uint) {
    (uint r0, uint r1) = lpToken.getReserves();
    return r1 * DECIMAL3 / r0;
  }

  function _initDependentContracts() override internal {
    nftPass = INFTPass(addressBook.get("nftPass"));
    vault = IVault(addressBook.get("vault"));
    taxManager = ITaxManager(addressBook.get("taxManager"));
    lsd = ILSD(addressBook.get("lsd"));
    concentratedLiquiditySystem = IConcentratedLiquiditySystem(addressBook.get("cls"));
    address uniswapV2RouterAddress = addressBook.get("uniswapV2Router");
    uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
    lpToken = ILPToken(addressBook.get("lpToken"));
    menToken = IMENToken(addressBook.get("menToken"));
    menToken.approve(address(vault), type(uint).max);
    menToken.approve(address(uniswapV2Router), type(uint).max);
    usdtToken = IBEP20(addressBook.get("usdtToken"));
    usdtToken.approve(address(uniswapV2Router), type(uint).max);
    usdcToken = IBEP20(addressBook.get("usdcToken"));
    daiToken = IBEP20(addressBook.get("daiToken"));
  }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IAddressBook.sol";

abstract contract Auth is Initializable {

  address public bk;
  address public mn;
  address public contractCall;
  IAddressBook public addressBook;

  event ContractCallUpdated(address indexed _newOwner);

  function init(address _mn) virtual public {
    mn = _mn;
    contractCall = _mn;
  }

  modifier onlyBk() {
    require(_isBk(), "onlyBk");
    _;
  }

  modifier onlyMn() {
    require(_isMn(), "Mn");
    _;
  }

  modifier onlyContractCall() {
    require(_isContractCall() || _isMn(), "onlyContractCall");
    _;
  }

  function updateContractCall(address _newValue) external onlyMn {
    require(_newValue != address(0x0));
    contractCall = _newValue;
    emit ContractCallUpdated(_newValue);
  }

  function setAddressBook(address _addressBook) external onlyMn {
    addressBook = IAddressBook(_addressBook);
    _initDependentContracts();
  }

  function reloadAddresses() external onlyMn {
    _initDependentContracts();
  }

  function updateBk(address _newBk) external onlyBk {
    require(_newBk != address(0), "TokenAuth: invalid new bk");
    bk = _newBk;
  }

  function reload() external onlyBk {
    mn = addressBook.get("mn");
    contractCall = addressBook.get("contractCall");
  }

  function _initDependentContracts() virtual internal;

  function _isBk() internal view returns (bool) {
    return msg.sender == bk;
  }

  function _isMn() internal view returns (bool) {
    return msg.sender == mn;
  }

  function _isContractCall() internal view returns (bool) {
    return msg.sender == contractCall;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library MerkleProof {
  function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }
    return computedHash == root;
  }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface ILPToken is IBEP20 {
  function getReserves() external view returns (uint, uint);
  function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ISwap {
  enum PaymentCurrency {
    usdt,
    usdc,
    dai
  }
  function swapTokenForUSDT(uint _amount, bool _cls) external;
  function swapUSDForToken(uint _amount, PaymentCurrency _paymentCurrency, bool _autoStake) external returns (uint);
  function getDNOStakingRate() external view returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface IMENToken is IBEP20 {
  enum TaxType {
    Buy,
    Sell,
    Transfer,
    Claim
  }
  function releaseMintingAllocation(uint _amount) external returns (bool);
  function releaseCLSAllocation(uint _amount) external returns (bool);
  function burn(uint _amount) external;
  function mint(uint _amount) external returns (bool);
  function lsdDiscountTaxPercentages(TaxType _type) external returns (uint);
  function getWhitelistTax(address _to, TaxType _type) external returns (bool);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ITaxManager {
  function totalTaxPercentage() external view returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IConcentratedLiquiditySystem {
  function swapUSDForToken(uint _amount) external returns (uint);
  function swapTokenForUSDT(uint _amount) external returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IVault {
  enum DepositType {
    vaultDeposit,
    swapUSDForToken,
    swapBuyDNO
  }

  function updateQualifiedLevel(address _user1Address, address _user2Address) external;
  function depositFor(address _userAddress, uint _amount, DepositType _depositType) external;
  function getUserInfo(address _user) external view returns (uint, uint);
  function getTokenPrice() external view returns (uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.9;

import "../libs/app/Auth.sol";
import "../interfaces/IAddressBook.sol";

abstract contract BaseContract is Auth {

  function init() virtual public {
    Auth.init(msg.sender);
  }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface INFTPass is IERC721Upgradeable {
  function mint(address _owner, uint _quantity) external;
  function getOwnerNFTs(address _owner) external view returns(uint[] memory);
  function waitingList(address _user) external view returns (bool);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ILSD {
  function isQualifiedForTaxDiscount(address _user) external view returns (bool);
  function transfer(address _from, address _to, uint _stAmount) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IAddressBook {
  function get(string calldata _name) external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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