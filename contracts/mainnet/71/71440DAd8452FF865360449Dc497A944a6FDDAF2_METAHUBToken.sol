// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./libs/app/TokenAuth.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/ITaxManager.sol";
import "./interfaces/ILSD.sol";

contract METAHUBToken is IBEP20, TokenAuth {
  string public constant name = "Test MetaHub";
  string public constant symbol = "Test MEN";
  uint public constant decimals = 18;

  uint public constant MINTING_ALLOCATION = 595e24;
  uint public constant LMS_ALLOCATION = 70e24;
  uint public constant DEVELOPMENT_ALLOCATION = 35e24;
  uint public constant MAX_SUPPLY = 700e24;
  uint public constant BLOCK_IN_ONE_MONTH = 864000; // 30 * 24 * 60 * 20
  uint private constant DEVELOPMENT_VESTING_MONTH = 9;

  mapping (address => uint) internal _balances;
  mapping (address => mapping (address => uint)) private _allowed;
  mapping (address => bool) public waitingList;
  enum TaxType {
    Buy,
    Sell,
    Transfer,
    Claim
  }
  mapping (address => mapping (TaxType => bool)) public whitelistTax;
  struct Config {
    uint secondsInADay;
    uint hardCapCashOut;
    uint cashOutTaxPercentage;
    bool wait;
    bool waitingFunctionEnabled;
    mapping (address => uint) lastCashOut;
    mapping (address => uint) softCap;
  }

  uint public totalSupply;
  uint public startVestingDevelopmentBlock;
  uint public lastReleaseDevelopmentBlock;
  uint public startVestingAdvisorAndTeamBlock;
  uint public maxMintingBeMinted;
  uint public developmentReleased;
  uint public maxLMSBeMinted;
  uint public lmsReleased;
  IAddressBook public addressBook;
  ITaxManager public taxManager;
  ILSD public lsd;
  Config public config;
  uint private constant DECIMAL3 = 1000;

  event ConfigUpdated(uint secondsInADay, uint hardCapCashOut, uint cashOutTaxPercentage, uint timestamp);
  event WaitStatusUpdated(bool status, uint timestamp);
  event WaitingStatusUpdated(address user, bool status, uint timestamp);

  constructor() TokenAuth() {
    config.hardCapCashOut = 100 ether;
    config.cashOutTaxPercentage = 20;
    config.waitingFunctionEnabled = true;
    maxMintingBeMinted = MINTING_ALLOCATION;
    maxLMSBeMinted = LMS_ALLOCATION;
  }

  function releaseMintingAllocation(uint _amount) external onlyVault returns (bool) {
    require(developmentReleased + _amount <= maxMintingBeMinted, "Max staking allocation had released");
    developmentReleased += _amount;
    _mint(msg.sender, _amount);
    return true;
  }

  function releaseLMSAllocation(uint _amount) external onlyLMS returns (bool) {
    require(lmsReleased + _amount <= maxLMSBeMinted, "Max LMS allocation had reached");
    lmsReleased += _amount;
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

  function updateMaxContractMinting(uint _maxMintingBeMinted, uint _maxLMSBeMinted) external onlyMn {
    require(maxMintingBeMinted <= MINTING_ALLOCATION, "Staking data invalid");
    require(maxLMSBeMinted <= LMS_ALLOCATION, "LMS data invalid");
    maxMintingBeMinted = _maxMintingBeMinted;
    maxLMSBeMinted = _maxLMSBeMinted;
  }

  function setAddressBook(address _addressBook) external onlyMn {
    addressBook = IAddressBook(_addressBook);
    _initDependentContracts();
  }

  function updateConfig(uint _secondsInDay, uint _hardCapCashOut, uint _cashOutTaxPercentage) external onlyMn {
    require(_cashOutTaxPercentage <= 100, "Data invalid");
    config.secondsInADay = _secondsInDay;
    config.hardCapCashOut = _hardCapCashOut;
    config.cashOutTaxPercentage = _cashOutTaxPercentage;
    emit ConfigUpdated(_secondsInDay, _hardCapCashOut, _cashOutTaxPercentage, block.timestamp);
  }

  function updateSoftCap(address _user, uint _softCap) external onlyMn {
    config.softCap[_user] = _softCap;
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
      _from == addressBook.get("lms") || _to == addressBook.get("lms") ||
      _from == addressBook.get("lsd") || _to == addressBook.get("lsd") ||
      _from == addressBook.get("shareManager") || _to == addressBook.get("shareManager") ||
      (_from == addressBook.get("swap") && _to == addressBook.get("pancake")) ||
      (_from == addressBook.get("pancake") && _to == addressBook.get("swap"))
    ) {
      return 0;
    }
    uint baseTax = _value * 1000 / taxManager.totalTaxPercentage();
    bool isBuyingToken = _from == addressBook.get("swap") || _from == addressBook.get("pancake");
    if (isBuyingToken && whitelistTax[_to][TaxType.Buy]) {
      return 0;
    }
    if (whitelistTax[_to][TaxType.Claim] && _from == address(vault)) {
      return 0;
    }
    bool isSellingToken = _to == addressBook.get("pancake") || _to == addressBook.get("swap");
    if (isSellingToken) {
      if (whitelistTax[_from][TaxType.Sell]) {
        return 0;
      }
      if (_from != address(taxManager)) {
        _validateSelling(_from, _value * vault.getTokenPrice() / DECIMAL3);
      }
      uint deposited = vault.getUserDeposited(_from);
      if (_value >= deposited * config.cashOutTaxPercentage / 100) {
        baseTax = _value / 2;
      }
    }

    if (_from != address(vault) && lsd.isQualifiedForTaxDiscount(_from)) {
      baseTax = baseTax / 2;
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
    lmsAddress = addressBook.get("lms");
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
  address internal lmsAddress;
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

  modifier onlyLMS() {
    require(msg.sender == lmsAddress, "TokenAuth: invalid caller");
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
  function getUserDeposited(address _user) external view returns (uint);
  function getTokenPrice() external view returns (uint);
}