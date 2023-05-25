// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./libs/app/TokenAuth.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/ITaxManager.sol";
import "./interfaces/ILSD.sol";
import "./interfaces/IMENToken.sol";

contract METAHUBToken is IBEP20, TokenAuth {
  string public constant name = "TEST MetaHub";
  string public constant symbol = "TEST MEN";
  uint public constant decimals = 18;

  uint public constant MINTING_ALLOCATION = 630e24;
  uint public constant CLS_ALLOCATION = 63e24;
  uint public constant DEVELOPMENT_ALLOCATION = 7e24;
  uint public constant MAX_SUPPLY = 700e24;
  uint public constant BLOCK_IN_ONE_MONTH = 864000; // 30 * 24 * 60 * 20
  uint private constant DEVELOPMENT_VESTING_MONTH = 24;

  mapping (address => uint) internal _balances;
  mapping (address => mapping (address => uint)) private _allowed;
  mapping (address => bool) public waitingList;
  mapping (address => mapping (IMENToken.TaxType => bool)) public whitelistTax;
  mapping (IMENToken.TaxType => uint) public lsdDiscountTaxPercentages; // decimal 3
  struct Config {
    uint secondsInADay;
    uint hardCapCashOut;
    uint cashOutTaxPercentage;
    bool wait;
    bool waitingFunctionEnabled;
    uint[] sharkCheckpoints;
    uint[] sharkTaxPercentages;
    mapping (address => uint) lastCashOut;
    mapping (address => uint) softCap;
  }

  uint public totalSupply;
  uint public startVestingDevelopmentBlock;
  uint public lastReleaseDevelopmentBlock;
  uint public startVestingAdvisorAndTeamBlock;
  uint public maxMintingBeMinted;
  uint public developmentReleased;
  uint public maxCLSBeMinted;
  uint public clsReleased;
  IAddressBook public addressBook;
  ITaxManager public taxManager;
  ILSD public lsd;
  Config public config;
  uint private constant DECIMAL3 = 1000;

  event ConfigUpdated(
    uint secondsInADay,
    uint hardCapCashOut,
    uint cashOutTaxPercentage,
    uint[] sharkCheckpoints,
    uint[] sharkTaxPercentages,
    uint timestamp
  );
  event WaitStatusUpdated(bool status, uint timestamp);
  event WaitingStatusUpdated(address user, bool status, uint timestamp);

//  constructor() TokenAuth() { TODO uncomment on prod release
//    config.hardCapCashOut = 100 ether;
//    config.cashOutTaxPercentage = 20;
//    config.sharkCheckpoints = [0, 20000 ether, 30000 ether];
//    config.sharkTaxPercentages = [0, 150, 200];
//    config.waitingFunctionEnabled = true;
//    maxMintingBeMinted = MINTING_ALLOCATION;
//    maxCLSBeMinted = CLS_ALLOCATION;
//  }

  function initialize() public initializer {
    TokenAuth.init();
    config.hardCapCashOut = 100 ether;
    config.cashOutTaxPercentage = 20;
    config.sharkCheckpoints = [0, 20000 ether, 30000 ether];
    config.sharkTaxPercentages = [0, 150, 200];
    config.waitingFunctionEnabled = true;
    maxMintingBeMinted = MINTING_ALLOCATION;
    maxCLSBeMinted = CLS_ALLOCATION;
  }

  function releaseMintingAllocation(uint _amount) external onlyVault returns (bool) {
    require(developmentReleased + _amount <= maxMintingBeMinted, "Max staking allocation had released");
    developmentReleased += _amount;
    _mint(msg.sender, _amount);
    return true;
  }

  function releaseCLSAllocation(uint _amount) external onlyCLS returns (bool) {
    require(clsReleased + _amount <= maxCLSBeMinted, "Max CLS allocation had reached");
    clsReleased += _amount;
    _mint(msg.sender, _amount);
    return true;
  }

  function startVestingDevelopment() external onlyMn {
    require(startVestingDevelopmentBlock == 0, "VestingDevelopment had started already");
    require(developmentAddress != address(0), "Please setup development address first");
    startVestingDevelopmentBlock = block.number + BLOCK_IN_ONE_MONTH * 3;
    lastReleaseDevelopmentBlock = startVestingDevelopmentBlock;
    _mint(developmentAddress, DEVELOPMENT_ALLOCATION / 10);
  }

  function releaseDevelopment() external onlyDevelopment {
    require(startVestingDevelopmentBlock > 0 && block.number > startVestingDevelopmentBlock, "Please wait more time");
    uint maxBlockNumber = startVestingDevelopmentBlock + BLOCK_IN_ONE_MONTH * DEVELOPMENT_VESTING_MONTH;
    require(maxBlockNumber > lastReleaseDevelopmentBlock, "Development allocation had released");
    uint blockPass;
    if (block.number < maxBlockNumber) {
      blockPass = block.number - lastReleaseDevelopmentBlock;
      lastReleaseDevelopmentBlock = block.number;
    } else {
      blockPass = maxBlockNumber - lastReleaseDevelopmentBlock;
      lastReleaseDevelopmentBlock = maxBlockNumber;
    }
    uint releaseAmount = DEVELOPMENT_ALLOCATION * 9 * blockPass / (BLOCK_IN_ONE_MONTH * DEVELOPMENT_VESTING_MONTH) / 10;
    _mint(msg.sender, releaseAmount);
  }

  function balanceOf(address _owner) override external view returns (uint) {
    return _balances[_owner];
  }

  function getUserCap(address _owner) external view returns (uint, uint) {
    return (config.softCap[_owner], config.lastCashOut[_owner]);
  }

  function getSharkInfo() external view returns (uint[] memory, uint[] memory) {
    return (config.sharkCheckpoints, config.sharkTaxPercentages);
  }

  function allowance(address _owner, address _spender) override external view returns (uint) {
    return _allowed[_owner][_spender];
  }

  function transfer(address _to, uint _value) override external returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) override external returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) override external returns (bool) {
    _transfer(_from, _to, _value);
    _approve(_from, msg.sender, _allowed[_from][msg.sender] - _value);
    return true;
  }

  function increaseAllowance(address _spender, uint _addedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] + _addedValue);
    return true;
  }

  function decreaseAllowance(address _spender, uint _subtractedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] - _subtractedValue);
    return true;
  }

  function burn(uint _amount) external {
    _balances[msg.sender] = _balances[msg.sender] - _amount;
    totalSupply = totalSupply - _amount;
    emit Transfer(msg.sender, address(0), _amount);
  }

  function updateWaitStatus(bool _wait) external onlyMn {
    config.wait = _wait;
    emit WaitStatusUpdated(_wait, block.timestamp);
  }

  function updateWaitingStatus(address _address, bool _waited) external onlyMn {
    require(config.waitingFunctionEnabled, "Waiting function is disabled");
    waitingList[_address] = _waited;
  }

  function disableWaitingFunction() external onlyMn {
    config.waitingFunctionEnabled = false;
  }

  function updateMaxContractMinting(uint _maxMintingBeMinted, uint _maxCLSBeMinted) external onlyMn {
    require(maxMintingBeMinted <= MINTING_ALLOCATION, "Staking data invalid");
    require(maxCLSBeMinted <= CLS_ALLOCATION, "CLS data invalid");
    maxMintingBeMinted = _maxMintingBeMinted;
    maxCLSBeMinted = _maxCLSBeMinted;
  }

  function setAddressBook(address _addressBook) external onlyMn {
    addressBook = IAddressBook(_addressBook);
    _initDependentContracts();
  }

  function updateConfig(uint _secondsInDay, uint _hardCapCashOut, uint _cashOutTaxPercentage, uint[] calldata _sharkCheckpoints, uint[] calldata _sharkTaxPercentages) external onlyMn {
    require(_cashOutTaxPercentage <= 100, "Data invalid");
    require(_sharkCheckpoints.length == _sharkTaxPercentages.length, "Shark data invalid");
    config.secondsInADay = _secondsInDay;
    config.hardCapCashOut = _hardCapCashOut;
    config.cashOutTaxPercentage = _cashOutTaxPercentage;
    config.sharkCheckpoints = _sharkCheckpoints;
    config.sharkTaxPercentages = _sharkTaxPercentages;
    emit ConfigUpdated(_secondsInDay, _hardCapCashOut, _cashOutTaxPercentage, _sharkCheckpoints, _sharkTaxPercentages, block.timestamp);
  }

  function updateSoftCap(address _user, uint _softCap) external onlyMn {
    config.softCap[_user] = _softCap;
  }

  function updateTaxWhitelist(address _user, IMENToken.TaxType _type, bool _whitelisted) external onlyMn {
    whitelistTax[_user][_type] = _whitelisted;
  }

  function updateLSDTaxDiscount(IMENToken.TaxType  _type, uint _percentage) external onlyMn {
    require(_percentage <= 100 * DECIMAL3, "Data invalid");
    lsdDiscountTaxPercentages[_type] = _percentage;
  }

  function getWhitelistTax(address _to, IMENToken.TaxType _type) external view returns (bool) {
    return whitelistTax[_to][_type];
  }

  function _transfer(address _from, address _to, uint _value) private {
    _validateAbility(_from);
    _balances[_from] -= _value;

    uint tax = _calculateTax(_from, _to, _value);
    if (tax > 0) {
      _balances[_to] += _value - tax;
      _balances[address(taxManager)] += tax;
      emit Transfer(_from, address(taxManager), tax);
    } else {
      _balances[_to] += _value;
    }
    if (_to == address(0)) {
      totalSupply = totalSupply - _value;
    }
    emit Transfer(_from, _to, _value - tax);
  }

  function _approve(address _owner, address _spender, uint _value) private {
    require(_spender != address(0), "Can not approve for zero address");
    require(_owner != address(0));

    _allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }

  function _mint(address _owner, uint _amount) private {
    _validateAbility(_owner);
    require(totalSupply + _amount <= MAX_SUPPLY, "Amount invalid");
    _balances[_owner] += _amount;
    totalSupply += _amount;
    emit Transfer(address(0), _owner, _amount);
  }

  function _validateAbility(address _owner) private view {
    if (config.waitingFunctionEnabled) {
      require(!waitingList[_owner] && !config.wait, "You can not do this at the moment");
    } else {
      require(!config.wait, "You can not do this at the moment");
    }
  }

  function _calculateTax(address _from, address _to, uint _value) private returns (uint) {
    if (
      _to == addressBook.get("vault") ||
      _from == addressBook.get("cls") || _to == addressBook.get("cls") ||
      _from == addressBook.get("lsd") || _to == addressBook.get("lsd") ||
      _from == addressBook.get("shareManager") || _to == addressBook.get("shareManager") ||
      (_from == addressBook.get("swap") && _to == addressBook.get("lpToken")) ||
      (_from == addressBook.get("lpToken") && _to == addressBook.get("swap"))
    ) {
      return 0;
    }
    uint baseTax = _value * 1000 / taxManager.totalTaxPercentage();
    bool isBuyingToken = _from == addressBook.get("swap") || _from == addressBook.get("lpToken");
    if (isBuyingToken) {
      if (whitelistTax[_to][IMENToken.TaxType.Buy]) {
        return 0;
      }
      if(lsd.isQualifiedForTaxDiscount(_to) && lsdDiscountTaxPercentages[IMENToken.TaxType.Buy] > 0) {
        return baseTax * (DECIMAL3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Buy]) / DECIMAL3;
      }
    }
    if (_from == address(vault)) {
      if (whitelistTax[_to][IMENToken.TaxType.Claim]) {
        return 0;
      }
      if (config.sharkCheckpoints.length > 0) {
        (, uint totalClaimed) = vault.getUserInfo(_to);
        uint checkpointIndex;
        for(uint i = 0; i < config.sharkCheckpoints.length; i++) {
          if (totalClaimed >= config.sharkCheckpoints[i]) {
            checkpointIndex = i;
          }
        }
        if (checkpointIndex > 0) {
          return _value * config.sharkTaxPercentages[checkpointIndex] / DECIMAL3;
        }
      }

      if(lsd.isQualifiedForTaxDiscount(_to) && lsdDiscountTaxPercentages[IMENToken.TaxType.Claim] > 0) {
        return baseTax * (DECIMAL3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Claim]) / DECIMAL3;
      }
    }
    bool isSellingToken = _to == addressBook.get("lpToken") || _to == addressBook.get("swap");
    if (isSellingToken) {
      if (whitelistTax[_from][IMENToken.TaxType.Sell]) {
        return 0;
      }
      if (_from != address(taxManager)) {
        _validateSelling(_from, _value * vault.getTokenPrice() / DECIMAL3);
      }
      if(lsd.isQualifiedForTaxDiscount(_from) && lsdDiscountTaxPercentages[IMENToken.TaxType.Sell] > 0) {
        baseTax = baseTax * (DECIMAL3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Sell]) / DECIMAL3;
      }
      (uint deposited,) = vault.getUserInfo(_from);
      if (_value >= deposited * config.cashOutTaxPercentage / 100) {
        baseTax = _value / 2;
      }
    } else if (_from != address(vault) && lsd.isQualifiedForTaxDiscount(_from) && lsdDiscountTaxPercentages[IMENToken.TaxType.Transfer] > 0) {
      baseTax = baseTax * (DECIMAL3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Transfer]) / DECIMAL3;
    }
    return baseTax;
  }

  function _validateSelling(address _from, uint _valueInUsd) private {
    if (config.softCap[msg.sender] > 0) {
      require(_valueInUsd <= config.softCap[msg.sender], "MEN: amount reach soft cap");
    } else {
      require(_valueInUsd <= config.hardCapCashOut, "MEN: amount reach hard cap");
    }
    if (config.lastCashOut[_from] > 0) {
      require(block.timestamp - config.lastCashOut[_from] >= config.secondsInADay, "MEN: please wait more time");
    }
    config.lastCashOut[_from] = block.timestamp;
  }

  function _initDependentContracts() private {
    vault = IVault(addressBook.get("vault"));
    taxManager = ITaxManager(addressBook.get("taxManager"));
    lsd = ILSD(addressBook.get("lsd"));
    clsAddress = addressBook.get("cls");
    developmentAddress = addressBook.get("development");
  }
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

import "@openzeppelin/contracts/utils/Context.sol";
import "../../interfaces/IVault.sol";

//contract TokenAuth is Context {

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
contract TokenAuth is Context, Initializable {
  address internal bk;
  address internal mn;
  address internal developmentAddress;
  address internal clsAddress;
  IVault public vault;

  //  constructor() { TODO uncomment on prod release
  //    mn = msg.sender;
  //    bk = msg.sender;
  //  }

  function init() public {
    mn = msg.sender;
    bk = msg.sender;
  }

  modifier onlyMn() {
    require(isOwner(), "onlyMn");
    _;
  }

  modifier onlyBk() {
    require(isBk(), "onlyBk");
    _;
  }

  modifier onlyDevelopment() {
    require(_msgSender() == developmentAddress || isOwner(), "TokenAuth: invalid caller");
    _;
  }

  modifier onlyCLS() {
    require(msg.sender == clsAddress, "TokenAuth: invalid caller");
    _;
  }

  modifier onlyVault() {
    require(msg.sender == address(vault), "TokenAuth: invalid caller");
    _;
  }

  function updateBk(address _newBk) external onlyBk {
    require(_newBk != address(0), "TokenAuth: invalid new bk");
    bk = _newBk;
  }

  function setDevelopmentAddress(address _address) external onlyMn {
    require(_address != address(0), "TokenAuth: development address is the zero address");
    developmentAddress = _address;
  }

  function isOwner() public view returns (bool) {
    return _msgSender() == mn;
  }

  function isBk() public view returns (bool) {
    return _msgSender() == bk;
  }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IAddressBook {
  function get(string calldata _name) external view returns (address);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ITaxManager {
  function totalTaxPercentage() external view returns (uint);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface ILSD {
  function isQualifiedForTaxDiscount(address _user) external view returns (bool);
  function transfer(address _from, address _to, uint _stAmount) external;
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