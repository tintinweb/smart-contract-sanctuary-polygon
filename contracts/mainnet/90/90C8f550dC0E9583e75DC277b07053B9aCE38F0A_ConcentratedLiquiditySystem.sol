// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IMENToken.sol";
import "./interfaces/ILPToken.sol";
import "./abstracts/BaseContract.sol";

contract ConcentratedLiquiditySystem is BaseContract {
  struct Config {
    uint minTokenReserved;
    uint minUsdtReserved;
  }
  Config public config;
  IMENToken public menToken;
  IBEP20 public usdtToken;
  ILPToken public lpToken;
  address public swapAddress;
  IUniswapV2Router02 public uniswapV2Router;
  uint private constant DECIMAL3 = 1000;
  IBEP20 public usdcToken;
  IBEP20 public daiToken;
  uint private constant DECIMAL9 = 1000000000;
  IBEP20 public stToken;

  modifier onlySwapContract() {
    require(msg.sender == swapAddress, "ConcentratedLiquiditySystem: only swap contract");
    _;
  }

  event ConfigUpdated(uint minUsdtReserved, uint minTokenReserved, uint timestamp);
  event TokenBought(uint usdtAmount, uint swapedMeh, uint timestamp);
  event TokenSold(uint tokenAmount, uint swapedUsdt, uint timestamp);

  function initialize() public initializer {
    BaseContract.init();
  }

  function swapUSDForToken(uint _usdAmount) external onlySwapContract returns (uint) {
    uint tokenAmount = _usdAmount * DECIMAL9 / _getTokenPrice();
    uint contractBalance = menToken.balanceOf(address(this));
    require(contractBalance >= config.minTokenReserved, "ConcentratedLiquiditySystem: contract insufficient balance");
    if(contractBalance < tokenAmount) {
      menToken.releaseCLSAllocation(tokenAmount - contractBalance);
    }
    menToken.transfer(msg.sender, tokenAmount);
    return tokenAmount;
  }

  function swapTokenForUSDT(address _seller, uint _amount) external onlySwapContract returns (uint) {
    _takeFund(_amount);
    uint usdtAmount = _amount * _getTokenPrice() / DECIMAL9;
    uint contractBalance = usdtToken.balanceOf(address(this));
    require(contractBalance > usdtAmount && contractBalance >= config.minUsdtReserved, "ConcentratedLiquiditySystem: contract insufficient balance");
    usdtToken.transfer(_seller, usdtAmount);
    return usdtAmount;
  }

  // AUTH FUNCTIONS

  function updateConfig(uint _minUsdtReserved, uint _minTokenReserved) external onlyMn {
    config.minUsdtReserved = _minUsdtReserved;
    config.minTokenReserved = _minTokenReserved;
    emit ConfigUpdated(_minUsdtReserved, _minTokenReserved, block.timestamp);
  }

  function buyToken(uint _amount) external onlyContractCall {
    require(usdtToken.balanceOf(address(this)) >= _amount, "ConcentratedLiquiditySystem: contract insufficient balance");
    address[] memory path = new address[](2);
    path[0] = address(usdtToken);
    path[1] = address(menToken);
    uint currentMehBalance = menToken.balanceOf(address(this));
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 0, path, address(this), block.timestamp);
    uint swappedMeh = menToken.balanceOf(address(this)) - currentMehBalance;
    emit TokenBought(_amount, swappedMeh, block.timestamp);
  }

  function sellToken(uint _amount) external onlyContractCall {
    uint contractBalance = menToken.balanceOf(address(this));
    if (contractBalance < _amount) {
      menToken.releaseCLSAllocation(_amount - contractBalance);
    }
    address[] memory path = new address[](2);
    path[0] = address(menToken);
    path[1] = address(usdtToken);
    uint currentUsdtBalance = usdtToken.balanceOf(address(this));
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 0, path, address(this), block.timestamp);
    uint swappedUsdt = usdtToken.balanceOf(address(this)) - currentUsdtBalance;
    emit TokenSold(_amount, swappedUsdt, block.timestamp);
  }

  function addLiquidity(uint _usdtAmount, uint _lpTokenBurnPercentage) external onlyContractCall {
    require(_lpTokenBurnPercentage <= 100 * DECIMAL3, "ConcentratedLiquiditySystem: burn percentage invalid");
    require(usdtToken.balanceOf(address(this)) >= _usdtAmount, "ConcentratedLiquiditySystem: contract insufficient usdt balance");
    uint tokenAmount = _usdtAmount * DECIMAL9 / _getTokenPrice();
    uint contractBalance = menToken.balanceOf(address(this));
    if (contractBalance < tokenAmount) {
      menToken.releaseCLSAllocation(tokenAmount - contractBalance);
    }
    uint lpBalanceBefore = lpToken.balanceOf(address(this));
    uniswapV2Router.addLiquidity(
      address(menToken),
      address(usdtToken),
      tokenAmount,
      _usdtAmount,
      0,
      0,
      address(this),
      block.timestamp
    );
    if (_lpTokenBurnPercentage > 0) {
      uint newLPAmount = lpToken.balanceOf(address(this)) - lpBalanceBefore;
      lpToken.transfer(address(0), newLPAmount * _lpTokenBurnPercentage / 100 / DECIMAL3);
    }
  }

  function addMenAndStMenLiquidity(uint _amount) external onlyContractCall {
    uniswapV2Router.addLiquidity(
      address(menToken),
      address(stToken),
        _amount,
        _amount,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  function removeLiquidity(uint _lpToken) external onlyMn {
    require(_lpToken <= lpToken.balanceOf(address(this)), "ConcentratedLiquiditySystem: contract insufficient balance");
    uniswapV2Router.removeLiquidity(
      address(menToken),
      address(usdtToken),
      _lpToken,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  function convertDAIToUsdt(uint _daiAmount) external onlyMn {
    require(daiToken.balanceOf(address(this)) >= _daiAmount, "ConcentratedLiquiditySystem: contract insufficient DAI balance");
    address[] memory path = new address[](2);
    path[0] = address(daiToken);
    path[1] = address(usdtToken);
    uniswapV2Router.swapExactTokensForTokens(_daiAmount, 0, path, address(this), block.timestamp);
  }

  function convertUsdcToUsdt(uint _usdcAmount) external onlyMn {
    require(usdcToken.balanceOf(address(this)) >= _usdcAmount, "ConcentratedLiquiditySystem: contract insufficient USDC balance");
    address[] memory path = new address[](2);
    path[0] = address(usdcToken);
    path[1] = address(usdtToken);
    uniswapV2Router.swapExactTokensForTokens(_usdcAmount, 0, path, address(this), block.timestamp);
  }

  function mint(uint _amount) external onlyMn {
    menToken.releaseCLSAllocation(_amount);
  }

  // PRIVATE FUNCTIONS

  function _getTokenPrice() private view returns (uint) {
    (uint r0, uint r1) = ILPToken(addressBook.get("LPToken")).getReserves();
    return r0 * DECIMAL9 / r1;
  }

  function _takeFund(uint _amount) private {
    require(menToken.allowance(msg.sender, address(this)) >= _amount, "ConcentratedLiquiditySystem: allowance invalid");
    require(menToken.balanceOf(msg.sender) >= _amount, "ConcentratedLiquiditySystem: insufficient balance");
    menToken.transferFrom(msg.sender, address(this), _amount);
  }

  function _initDependentContracts() override internal {
    uniswapV2Router = IUniswapV2Router02(addressBook.get("uniswapV2Router"));
    menToken = IMENToken(addressBook.get("menToken"));
    menToken.approve(address(uniswapV2Router), type(uint).max);
    usdtToken = IBEP20(addressBook.get("usdtToken"));
    usdtToken.approve(address(uniswapV2Router), type(uint).max);
    lpToken = ILPToken(addressBook.get("lpToken"));
    lpToken.approve(address(uniswapV2Router), type(uint).max);
    swapAddress = addressBook.get("swap");
    usdcToken = IBEP20(addressBook.get("usdcToken"));
    usdcToken.approve(address(uniswapV2Router), type(uint).max);
    daiToken = IBEP20(addressBook.get("daiToken"));
    daiToken.approve(address(uniswapV2Router), type(uint).max);
    stToken = IBEP20(addressBook.get("stToken"));
    stToken.approve(address(uniswapV2Router), type(uint).max);
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
  function getWhitelistTax(address _to, TaxType _type) external returns (uint, bool);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface ILPToken is IBEP20 {
  function getReserves() external view returns (uint, uint);
  function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.9;

import "../libs/app/Auth.sol";
import "../interfaces/IAddressBook.sol";

abstract contract BaseContract is Auth {
  uint constant DECIMAL12 = 1e12;
  function init() virtual public {
    Auth.init(msg.sender);
  }

  function convertDecimal18ToDecimal6(uint _amount) internal view returns (uint) {
    return _amount / DECIMAL12;
  }
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
    bk = _mn;
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

  function updateMn(address _newMn) external onlyBk {
    require(_newMn != address(0), "TokenAuth: invalid new mn");
    mn = _newMn;
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

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IAddressBook {
  function get(string calldata _name) external view returns (address);
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