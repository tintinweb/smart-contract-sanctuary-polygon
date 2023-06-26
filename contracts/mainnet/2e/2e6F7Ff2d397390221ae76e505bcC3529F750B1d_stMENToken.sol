// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./interfaces/ILSD.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/IVault.sol";

contract STTokenAuth is Context {

  address internal bk;
  address internal mn;
  ILSD public lsd;
  IVault public vault;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor() {
    mn = msg.sender;
    bk = msg.sender;
  }

  modifier onlyMn() {
    require(isMn(), "onlyMn");
    _;
  }

  modifier onlyBk() {
    require(isBk(), "onlyBk");
    _;
  }

  modifier onlyLSD() {
    require(msg.sender == address(lsd), "TokenAuth: invalid caller");
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

  function isMn() public view returns (bool) {
    return _msgSender() == mn;
  }

  function isBk() public view returns (bool) {
    return _msgSender() == bk;
  }
}

contract stMENToken is IBEP20, STTokenAuth {
  string public constant name = "st MetaHub Finance";
  string public constant symbol = "stMEN";
  uint public constant decimals = 6;

  uint public constant maxSupply = 700e12;

  mapping (address => bool) public waitingList;
  mapping (address => uint) internal _balances;
  mapping (address => mapping (address => uint)) private _allowed;

  uint public totalSupply;
  struct Config {
    bool wait;
    bool waitingFunctionEnabled;
  }
  IAddressBook public addressBook;
  Config public config;

  constructor() STTokenAuth() {
    config.waitingFunctionEnabled = true;
  }

  function mint(uint _amount) external onlyLSD returns (bool) {
    _mint(msg.sender, _amount);
    return true;
  }

  function balanceOf(address _owner) override external view returns (uint) {
    return _balances[_owner];
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

  function updateWaitStatus(bool _wait) onlyMn external {
    config.wait = _wait;
  }

  function updateWaitingStatus(address _address, bool _waited) onlyMn external {
    require(config.waitingFunctionEnabled, "Waiting function is disabled");
    waitingList[_address] = _waited;
  }

  function disableWaitingFunction() onlyMn external {
    config.waitingFunctionEnabled = false;
  }


  function _transfer(address _from, address _to, uint _value) private {
    _validateAbility(_from);
    _balances[_from] -= _value;
    _balances[_to] += _value;
    if (_to == address(0)) {
      totalSupply = totalSupply - _value;
    }
    lsd.transfer(_from, _to, _value);
    vault.updateQualifiedLevel(_from, _to);
    emit Transfer(_from, _to, _value);
  }

  function _approve(address _owner, address _spender, uint _value) private {
    require(_spender != address(0));
    require(_owner != address(0));

    _allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }

  function _mint(address _owner, uint _amount) private {
    _validateAbility(_owner);
    require(totalSupply + _amount <= maxSupply, "Amount invalid");
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

  function setAddressBook(address _addressBook) external onlyMn {
    addressBook = IAddressBook(_addressBook);
    _initDependentContracts();
  }

  function _initDependentContracts() private {
    lsd = ILSD(addressBook.get("lsd"));
    vault = IVault(addressBook.get("vault"));
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

interface IAddressBook {
  function get(string calldata _name) external view returns (address);
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