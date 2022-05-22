/**
 *Submitted for verification at polygonscan.com on 2022-05-22
*/

// CMSale.12.14.TEST.sol

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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
    _setOwner(_msgSender());
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
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// File: CMSale.sol

pragma solidity 0.8.9;

interface ERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

contract CMSale is Ownable {

  event AddCurrency(uint256 currencyID, string tokenName, address tokenAddress);
  event RemoveCurrency(uint256 currencyID);
  event CreateSale(uint256 saleID, string name, uint256 startTime, uint256 endTime, uint256 cap, uint256 price, uint256 currencyID);
  event DeleteSale(uint256 saleID);
  event CloseSale(uint256 saleID, uint256 closeTime, uint256 soldAmount, uint256 raisedAmount, address cmdWallet);
  event Buy(uint256 saleID, uint256 quantinty, uint256 serialNo, address indexed buyer);
  event ToggleAdmin(address indexed account, bool isAdmin);
  event ToggleSuperAdmin(address indexed account, bool isSuperAdmin);
  event ChangeCmdWallet(address cmdWallet);
  event ChangeBurnWallet(address cmdWallet);
  event ChangeBurnPct(uint256 burnPct);
  event ChangeMaxSaleID(uint256 maxSaleID);
  event ChangePrice(uint256 saleID, uint256 originalPrice, uint256 newPrice);
  event IncreaseCapByAmount(uint256 saleID, uint256 addAmount, uint256 newCap);
  event IncreaseEndTimeBySeconds(uint256 saleID, uint256 addSeconds, uint256 newEndTime);

  struct Currency {
    bytes12 currName;
    address currAddress;
  }
  Currency[] currencies;

  struct Sale {
    uint256 price;
    bytes32 name;
    uint8 currencyID;
    bool hasDynamicPrice;
    uint16 priceDeltaPerMille; 
    uint32 startTime;
    uint32 endTime;
    uint24 cap;
    bool isActive;
    uint24 soldAmount;
    uint256 raisedAmount; 
    uint256 originalPrice;
  }
  mapping (uint256 => Sale) public sales;

  mapping (address => bool) public isAdmin;
  mapping (address => bool) public isSuperAdmin;

  ERC20 ERC20Interface;

  uint256 public maxSaleID;
  address public cmdWallet;
  address public burnWallet;
  uint8 public burnPct;

  modifier onlyAdmin() {
      require(isAdmin[msg.sender] || isSuperAdmin[msg.sender] || msg.sender == owner(), "Only admin");
      _;
  }
  modifier onlySuperAdmin() {
      require(isSuperAdmin[msg.sender] || msg.sender == owner(), "Only superadmin");
      _;
  }
  modifier onlyValidAddress(address _recipient) {
    require(_recipient != address(0) && _recipient != address(this), "Invalid address");
    _;
  }
  modifier _positive(uint256 amount) {
    require(amount > 0, "Not positive amount");
    _;
  }
  modifier _hasAllowance(address allower_, uint256 amount_, address tokenAddress_) {
    // Make sure the allower has provided the right allowance.
    ERC20Interface = ERC20(tokenAddress_);
    uint256 ourAllowance = ERC20Interface.allowance(allower_, address(this));
    require(
      amount_ <= ourAllowance,
      "Not enough allowance"
    );
    _;
  }
  modifier _realAddress(address addr) {
    require(addr != address(0), "Zero address");
    _;
  }
  modifier onlyValidSaleID(uint256 _saleID) {
    require(_saleID > 0 && _saleID <= maxSaleID, "Only valid saleID");
    _;
  }
  modifier onlyActiveSale(uint256 _saleID) {
    require(sales[_saleID].isActive, "Only active sale");
    _;
  }

  constructor () {
    // Populate currencies with MATIC (ID 0) and TECH (ID 1)
    currencies.push(Currency(bytes12(bytes("MATIC")),address(0)));
    currencies.push(Currency(bytes12(bytes("TEST_TECH")),0xd3B0535Ed6Ab103Be55f66af7057B4d965b290AB));
    // currencies.push(Currency(bytes12(bytes("TECH")),0x6286A9e6f7e745A6D884561D88F94542d6715698));
  }

  /// @notice add currency
  function addCurrencies (string[] calldata _names, address[] calldata _addresses) external onlyAdmin {
    uint256 count_ = _names.length;
    require(count_ == _addresses.length,"Names and addresses lengths don't match");
    uint256 currLength_ = currencies.length;
    for (uint256 i=0; i<count_; i++) {
      for (uint j=0; j<currLength_; j++) {
        require(_addresses[i] != currencies[j].currAddress, "Currency address already added");
      }
      currencies.push(Currency(bytes12(bytes(_names[i])),_addresses[i]));
      emit AddCurrency(currencies.length,string(abi.encodePacked(_names[i])),_addresses[i]);
    }
  }

  /// @notice remove last currency
  function removeLastCurrency() external onlyAdmin {
    uint256 currLen_ = currencies.length;
    require(currencies.length > 2, "Cannot remove MATIC and TECH");
    currencies.pop();
    emit RemoveCurrency(currLen_);
  }

  /// @notice create sale
  function createSale(
    uint256 _price,
    string calldata _name,
    uint256 _currencyID,
    bool _hasDynamicPrice,
    uint256 _priceDeltaPerMille,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _cap
  )
    external
    onlyAdmin
  {
    require(_currencyID < currencies.length, "Invalid currencyID value");
    require(_price > 0 && _cap > 0, "Invalid price or cap value");
    require(block.timestamp < _startTime && _startTime < _endTime, "Invalid startTime or endTime value");
    require(!_hasDynamicPrice || (_priceDeltaPerMille > 0 && _priceDeltaPerMille <= 1000), "Invalid permille value");
    //
    Sale memory sale_ = Sale({
      price: _price,
      name: bytes32(bytes(_name)),
      currencyID: uint8(_currencyID),
      hasDynamicPrice: _hasDynamicPrice,
      priceDeltaPerMille: uint16(_priceDeltaPerMille),
      startTime: uint32(_startTime),
      endTime: uint32(_endTime),
      cap: uint24(_cap),
      isActive: true,
      soldAmount: 0,
      raisedAmount: 0,
      originalPrice: _price});
    sales[++maxSaleID] = sale_;
    //
    emit CreateSale(
      maxSaleID,
      string(abi.encodePacked(_name)),
      _startTime,
      _endTime,
      _cap,
      _price,
      _currencyID);
  }

  function deleteLastSale() external onlyAdmin {
    if (_deleteSale(maxSaleID)) {
      maxSaleID--;
    }
  }

  function deleteSale(uint256[] calldata _saleIds) external onlyAdmin {
    uint256 count_ = _saleIds.length;
    for (uint256 i = 0; i < count_; i++) {
      _deleteSale(_saleIds[i]);
    }
  }

  function closeSale(uint256 _saleID) external onlyAdmin onlyActiveSale(_saleID) {
    Sale storage sale_ = sales[_saleID];    
    sale_.isActive = false;
    uint256 amount_ = sale_.raisedAmount;
    if (amount_ > 0) {
      uint256 currencyID_ = sale_.currencyID;
      if (currencyID_ == 0) {
        //cmdWallet.transfer(amount_);
        require(payable(cmdWallet).send(amount_), "Matic transfer to cmdWallet failed");
      } else {
        address currAddress_ = currencies[currencyID_].currAddress;
        if (currencyID_ == 1 && burnPct > 0) {
          uint256 burnAmount_ = amount_ * burnPct / 100;
          require(_tokenTransfer(burnWallet, burnAmount_, currAddress_), "Token transfer to burnWallet failed");
          amount_ -= burnAmount_;
        }
        require(_tokenTransfer(cmdWallet, amount_, currAddress_), "Token transfer to cmdWallet failed");
      }
    }
    emit CloseSale(_saleID, block.timestamp, sale_.soldAmount, sale_.raisedAmount, cmdWallet);
  }

  /// @notice buy item
  function buy(uint256 _saleID, uint256 _quantity)
    external
    onlyActiveSale(_saleID)
    _positive(_quantity)
    payable
  {
    Sale storage sale_ = sales[_saleID];
    require (block.timestamp >= sale_.startTime && block.timestamp <= sale_.endTime, "Out of sale's timeframe"); 
    require (sale_.soldAmount < sale_.cap, "Sale's cap already reached");
    address buyer_ = msg.sender;
    uint256 price_ = sale_.price * _quantity;
    sale_.soldAmount += uint24(_quantity);
    sale_.raisedAmount += price_;
    if (sale_.currencyID == 0) {
      require(msg.value == price_, "Insufficient matic value");
    } else {
    require(_tokenTransferFrom(buyer_, address(this), price_, currencies[sale_.currencyID].currAddress), "Error with token tranfer");
    }
    emit Buy(_saleID, _quantity, sale_.soldAmount, buyer_);
  }

  function changePrice(uint256[] calldata _saleID, uint256[] calldata _newPrice)
    external
    onlyAdmin
  {
    uint256 count_ = _saleID.length;
    require(_newPrice.length == count_, "saleID and newPrice lengths don't match");
    for (uint256 i=0; i<count_; i++) {
      _changePrice(_saleID[i], _newPrice[i]);
    }
  }

  function toggleAdmin(address _account) external onlySuperAdmin {
    bool isAdmin_ = !isAdmin[_account];
    isAdmin[_account] = isAdmin_;
    emit ToggleAdmin(_account, isAdmin_);
  }

  function toggleSuperAdmin(address _account) external onlyOwner {
    bool isSuperAdmin_ = !isSuperAdmin[_account];
    isSuperAdmin[_account] = isSuperAdmin_;
    emit ToggleSuperAdmin(_account, isSuperAdmin_);
  }

  function withdrawStuckTokens(uint256 _amount, address _tokenAddress) external onlyAdmin {
    require(_tokenTransfer(owner(), _amount, _tokenAddress), "Withdrawing stuck tokens failed");
  }

  function withdrawStuckMatic(uint256 _amount) external onlyAdmin {
    require(payable(owner()).send(_amount), "Withdrawing stuck matic failed");
  }

  function changeCmdWallet(address _newCmdWallet)
    external
    onlySuperAdmin
    onlyValidAddress(_newCmdWallet)
  {
    cmdWallet = _newCmdWallet;
    emit ChangeCmdWallet(_newCmdWallet);
  }

  function changeBurnWallet(address _newBurnWallet)
    external
    onlySuperAdmin
    onlyValidAddress(_newBurnWallet)
  {
    burnWallet = _newBurnWallet;
    emit ChangeBurnWallet(_newBurnWallet);
  }

  function changeBurnPct(uint256 _newBurnPct)
    external
    onlySuperAdmin
  {
    require(_newBurnPct>0 && _newBurnPct<=100, "Invalid percentage value");
    burnPct = uint8(_newBurnPct);
    emit ChangeBurnPct(_newBurnPct);
  }

  function changeMaxSaleID(uint256 _newMaxSaleID) external onlySuperAdmin {
    require(_newMaxSaleID > maxSaleID, "New maxSaleID has to be greater than current value");
    maxSaleID = _newMaxSaleID;
    emit ChangeMaxSaleID(_newMaxSaleID);
  }

  function increaseCapByAmount(uint256 _saleID, uint256 _amount)
    external
    onlyActiveSale(_saleID)
    _positive(_amount)
    onlyAdmin
  {
    Sale storage sale_ = sales[_saleID];    
    sale_.cap += uint24(_amount);
    emit IncreaseCapByAmount(_saleID, _amount, sale_.cap);
  }

  function increaseEndTimeBySeconds(uint256 _saleID, uint256 _seconds)
    external
    onlyActiveSale(_saleID)
    _positive(_seconds)
    onlyAdmin
  {
    Sale storage sale_ = sales[_saleID];    
    sale_.endTime += uint32(_seconds);
    emit IncreaseEndTimeBySeconds(_saleID, _seconds, sale_.endTime);
  }

  function getCurrencyInfo(uint256 _currencyID)
    external
    view
    returns (string memory, address)
  {
    return (
      string(abi.encodePacked(currencies[_currencyID].currName)),
      currencies[_currencyID].currAddress);
  }

  function getSaleName(uint256 _saleID)
    external
    view
    returns (string memory)
  {
    return string(abi.encodePacked(sales[_saleID].name));
  }

  function _deleteSale(uint256 _saleId) private returns (bool) {
    if (
      sales[_saleId].startTime > block.timestamp ||
      sales[_saleId].isActive == false)
    {
      delete sales[_saleId];
      emit DeleteSale(_saleId);
      return true;
    }
    return false;
  }

  function _changePrice(uint256 _saleID, uint256 _newPrice)
    private
    onlyActiveSale(_saleID)
    _positive(_newPrice)
    returns (bool)
  {
    if (sales[_saleID].isActive && sales[_saleID].hasDynamicPrice) {
      Sale storage sale_ = sales[_saleID];
      uint256 price_ = sale_.price;
      sale_.originalPrice = price_;
      sale_.price = _newPrice;
      emit ChangePrice(_saleID, sale_.originalPrice, sale_.price);
      return true;
    }
    return false;
  }

  function _tokenTransferFrom(
    address allower_,
    address receiver_,
    uint256 amount_,
    address tokenAddress_
  ) private _hasAllowance(allower_, amount_, tokenAddress_) returns (bool) {
    ERC20Interface = ERC20(tokenAddress_);
    return ERC20Interface.transferFrom(allower_, receiver_, amount_);
  }

  function _tokenTransfer(address to_, uint256 amount_, address tokenAddress_)
    private
    _realAddress(to_)
    _positive(amount_)
    returns (bool)
  {
    ERC20Interface = ERC20(tokenAddress_);
    return ERC20Interface.transfer(to_, amount_);
  }

}