// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./libs/app/TokenAuth.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/ITaxManager.sol";
import "./interfaces/ILSD.sol";
import "./interfaces/IMENToken.sol";

contract METAHUBToken is IBEP20, TokenAuth {
  string public constant name = "MetaHub Finance";
  string public constant symbol = "MEN";
  uint public constant decimals = 6;

  uint public constant MINTING_ALLOCATION = 630e12;
  uint public constant CLS_ALLOCATION = 63e12;
  uint public constant DEVELOPMENT_ALLOCATION = 7e12;
  uint public constant MAX_SUPPLY = 700e12;
  uint public constant BLOCK_IN_ONE_MONTH = 1296000; // 30 * 24 * 60 * 30
  uint private constant DEVELOPMENT_VESTING_MONTH = 12;

  mapping (address => uint) internal _balances;
  mapping (address => mapping (address => uint)) private _allowed;
  mapping (address => bool) public waitingList;
  mapping (address => mapping (IMENToken.TaxType => WhitelistTax)) public whitelistTax;
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

  struct WhitelistTax {
    uint percentage;
    bool status;
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
  uint private constant DECIMAL9 = 1000000000;
  uint constant oneHundredPercentageDecimal3 = 100000;

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

  constructor() TokenAuth() {
    config.hardCapCashOut = 100e6;
    config.cashOutTaxPercentage = 20;
    config.sharkCheckpoints = [0, 20000e6, 30000e6];
    config.sharkTaxPercentages = [0, 15000, 20000];
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
    startVestingDevelopmentBlock = block.number + BLOCK_IN_ONE_MONTH * 1;
    lastReleaseDevelopmentBlock = startVestingDevelopmentBlock;
    _mint(developmentAddress, DEVELOPMENT_ALLOCATION * 20 / 100);
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
    uint releaseAmount = DEVELOPMENT_ALLOCATION * 8 * blockPass / (BLOCK_IN_ONE_MONTH * DEVELOPMENT_VESTING_MONTH) / 10;
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

  function updateTaxWhitelist(address _user, IMENToken.TaxType _type, uint _percentage, bool _whitelisted) external onlyMn {
    require(_percentage <= oneHundredPercentageDecimal3, "percentage invalid");
    whitelistTax[_user][_type] = WhitelistTax(_percentage, _whitelisted);
  }

  function updateLSDTaxDiscount(IMENToken.TaxType  _type, uint _percentage) external onlyMn {
    require(_percentage <= oneHundredPercentageDecimal3, "Data invalid");
    lsdDiscountTaxPercentages[_type] = _percentage;
  }

  function getWhitelistTax(address _to, IMENToken.TaxType _type) external view returns (uint, bool) {
    WhitelistTax memory userWhitelist = whitelistTax[_to][_type];
    return (userWhitelist.percentage, userWhitelist.status);
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

    if (_from == address(vault)) {
      vault.updateUserTotalClaimedInUSD(_to, _value * vault.getTokenPrice() / DECIMAL9);
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
    WhitelistTax storage userWhitelistTax;
    uint baseTax = _value * 1000 / taxManager.totalTaxPercentage();
    bool isBuyingToken = _from == addressBook.get("swap") || _from == addressBook.get("lpToken");
    if (isBuyingToken) {
      userWhitelistTax = whitelistTax[_to][IMENToken.TaxType.Buy];
      if (userWhitelistTax.status) {
        return userWhitelistTax.percentage > 0 ? _value * userWhitelistTax.percentage / oneHundredPercentageDecimal3 : 0;
      }
      if(lsd.isQualifiedForTaxDiscount(_to) && lsdDiscountTaxPercentages[IMENToken.TaxType.Buy] > 0) {
        return baseTax * (oneHundredPercentageDecimal3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Buy]) / oneHundredPercentageDecimal3;
      }
    }
    if (_from == address(vault)) {
      userWhitelistTax = whitelistTax[_to][IMENToken.TaxType.Claim];
      if (userWhitelistTax.status) {
        return userWhitelistTax.percentage > 0 ? _value * userWhitelistTax.percentage / oneHundredPercentageDecimal3 : 0;
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
          return _value * config.sharkTaxPercentages[checkpointIndex] / oneHundredPercentageDecimal3;
        }
      }

      if(lsd.isQualifiedForTaxDiscount(_to) && lsdDiscountTaxPercentages[IMENToken.TaxType.Claim] > 0) {
        return baseTax * (oneHundredPercentageDecimal3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Claim]) / oneHundredPercentageDecimal3;
      }
    }
    bool isSellingToken = _to == addressBook.get("lpToken") || _to == addressBook.get("swap");
    if (isSellingToken) {
      userWhitelistTax = whitelistTax[_from][IMENToken.TaxType.Sell];
      if (userWhitelistTax.status) {
        return userWhitelistTax.percentage > 0 ? _value * userWhitelistTax.percentage / oneHundredPercentageDecimal3 : 0;
      }
      if (_from != address(taxManager)) {
        _validateSelling(_from, _value * vault.getTokenPrice() / DECIMAL9);
      }
      if(lsd.isQualifiedForTaxDiscount(_from) && lsdDiscountTaxPercentages[IMENToken.TaxType.Sell] > 0) {
        baseTax = baseTax * (oneHundredPercentageDecimal3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Sell]) / oneHundredPercentageDecimal3;
      }
      (uint deposited,) = vault.getUserInfo(_from);
      if (_value >= deposited * config.cashOutTaxPercentage / 100) {
        baseTax = _value / 2;
      }
    } else if (_from != address(vault) && lsd.isQualifiedForTaxDiscount(_from) && lsdDiscountTaxPercentages[IMENToken.TaxType.Transfer] > 0) {
      baseTax = baseTax * (oneHundredPercentageDecimal3 - lsdDiscountTaxPercentages[IMENToken.TaxType.Transfer]) / oneHundredPercentageDecimal3;
    }

    userWhitelistTax = whitelistTax[_from][IMENToken.TaxType.Transfer];
    if (userWhitelistTax.status) {
      return userWhitelistTax.percentage > 0 ? _value * userWhitelistTax.percentage / oneHundredPercentageDecimal3 : 0;
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

contract TokenAuth is Context {
  address internal bk;
  address internal mn;
  address internal developmentAddress;
  address internal clsAddress;
  IVault public vault;

  constructor() {
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

  function updateMn(address _newMn) external onlyBk {
    require(_newMn != address(0), "TokenAuth: invalid new mn");
    mn = _newMn;
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
  function mint(uint _tokenAmount, uint _duration) external;
  function burn(uint _stAmount) external;
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
  function updateUserTotalClaimedInUSD(address _user, uint _usd) external;
}