/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

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
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface Lootbox {
  function getLootboxStatus(uint256 _lootboxId) external view returns (uint256);
  function openLootbox(
    uint256 _lootboxId,
    address _buyer,
    uint256 _quantity) external returns (uint256[] memory);
}

contract CryptomedaSales is Ownable {

  event AddCurrency(uint256 currencyID, string tokenName, address tokenAddress);
  event RemoveCurrency(uint256 currencyID);
  event CreateSale(uint256 saleID, uint256 startTime, uint256 endTime, uint256 cap, uint256 price, uint256 currencyID, uint256 sharedCapID, uint256 lootboxID);
  event DeleteSale(uint256 saleID);
  event CloseSale(uint256 saleID, uint256 closeTime, uint256 soldAmount, uint256 raisedAmount, address cmdWallet);
  event AddSharedCap(uint256 sharedCapID, string name, uint256 cap, uint256 maxSalesCount);
  event RemoveSharedCap(uint256 sharedCapID);
  event Buy(uint256 saleID, uint256 quantity, uint256 serialNo, address indexed buyer, uint256[] lbAssetId);
  event ToggleAdmin(address indexed account, bool isAdmin);
  event ToggleSuperAdmin(address indexed account, bool isSuperAdmin);
  event ChangeCmdWallet(address newCmdWallet);
  event ChangeBurnWallet(address newCmdWallet);
  event ChangeLootboxContractAddress(address newLootboxContractAddress);
  event ChangeBurnPct(uint256 newBurnPct);
  event ChangeMaxSaleID(uint256 newMaxSaleID);
  event ChangeMaxSharedCapID(uint256 newMaxSharedCapID);
  event ChangeMaxLbBuyQuantity(uint256 maxSharedCapID);
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
    uint8 currencyID;
    uint16 priceDeltaPerMille; 
    uint32 startTime;
    uint32 endTime;
    uint24 cap;
    uint16 sharedCapID;
    uint16 lootboxID;
    bool isActive;
    uint24 soldAmount;
    uint256 raisedAmount; 
    uint256 originalPrice;
  }
  mapping (uint256 => Sale) public sales;

  struct SharedCap {
    uint24 cap;
    uint8 maxSalesCnt;
    uint8 salesCnt;
    uint192 saleIDs;
    uint24 soldAmount;
  }
  mapping (uint256 => SharedCap) public sharedCaps;

  mapping (address => bool) public isAdmin;
  mapping (address => bool) public isSuperAdmin;

  ERC20 ERC20Interface;
  Lootbox LootboxInterface;

  address public lootboxContractAddress;
  address public cmdWallet;
  address public burnWallet;

  uint16 public maxSaleID;
  uint16 public maxSharedCapID;
  uint8 public maxLbBuyQuantity;
  uint8 public burnPct;

  modifier onlyAdmin() {
      require(isAdmin[msg.sender] || isSuperAdmin[msg.sender] || msg.sender == owner(), "Not admin");
      _;
  }
  modifier onlySuperAdmin() {
      require(isSuperAdmin[msg.sender] || msg.sender == owner(), "Not superadmin");
      _;
  }
  modifier onlyValidAddress(address _recipient) {
    require(_recipient != address(0) && _recipient != address(this), "Invalid address");
    _;
  }
  modifier _positive(uint256 amount) {
    require(amount > 0, "Zero amount");
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
    require(_saleID > 0 && _saleID <= maxSaleID, "Invalid saleID");
    _;
  }
  modifier onlyActiveSale(uint256 _saleID) {
    require(sales[_saleID].isActive, "Inactive sale");
    _;
  }

  constructor () {
    burnPct = 5;
    maxLbBuyQuantity = 30;
    // Populate currencies with MATIC, TECH and USDC
    currencies.push(Currency(bytes12(bytes("MATIC")),address(0)));
    currencies.push(Currency(bytes12(bytes("TECH")),0x6286A9e6f7e745A6D884561D88F94542d6715698));
    currencies.push(Currency(bytes12(bytes("USDC")),0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174));
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
      emit AddCurrency(currencies.length-1,string(abi.encodePacked(_names[i])),_addresses[i]);
    }
  }

  /// @notice remove last currency
  function removeLastCurrency() external onlyAdmin {
    uint256 currId_ = currencies.length-1;
    require(currId_ > 2, "Cannot remove default currencies (MATIC,TECH,USDC)");
    currencies.pop();
    emit RemoveCurrency(currId_);
  }

  /// @notice create sale
  function createSale(
    uint256 _price,
    uint256 _currencyID,
    uint256 _priceDeltaPerMille,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _cap,
    uint256 _sharedCapID,
    uint256 _lootboxID
  )
    external
    onlyAdmin
  {
    require(_currencyID < currencies.length, "Invalid currencyID value");
    require(_price > 0 && _cap > 0, "Invalid price or cap value");
    require(block.timestamp < _startTime && _startTime < _endTime, "Invalid startTime or endTime value");
    require(_priceDeltaPerMille <= 1000, "Invalid permille value");
    require(_sharedCapID <= maxSharedCapID, "Invalid sharedCapID value");
    maxSaleID++;
    if (_sharedCapID > 0) {
      SharedCap storage sharedCap_ = sharedCaps[_sharedCapID];
      require(sharedCap_.salesCnt < sharedCap_.maxSalesCnt, "Cannot assign more sales to specified sharedCap");
      require(_cap <= sharedCap_.cap, "Indiviual sale's cap cannot exceed shared cap");
      uint256 saleIDs_ = sharedCap_.saleIDs;
      saleIDs_ |= uint256(maxSaleID) << (sharedCap_.salesCnt * 16);
      sharedCap_.salesCnt++;
      sharedCap_.saleIDs = uint192(saleIDs_);
    }
    if (_lootboxID > 0)
      require(_getLootboxStatus(_lootboxID)==1, "Invalid lootbox status");
    //
    Sale memory sale_ = Sale({
      price: _price,
      currencyID: uint8(_currencyID),
      priceDeltaPerMille: uint16(_priceDeltaPerMille),
      startTime: uint32(_startTime),
      endTime: uint32(_endTime),
      cap: uint24(_cap),
      sharedCapID: uint16(_sharedCapID),
      lootboxID: uint16(_lootboxID),
      isActive: true,
      soldAmount: 0,
      raisedAmount: 0,
      originalPrice: _price});
    sales[maxSaleID] = sale_;
    //
    emit CreateSale(
      maxSaleID,
      _startTime,
      _endTime,
      _cap,
      _price,
      _currencyID,
      _sharedCapID,
      _lootboxID);
  }

  function deleteSales(uint256[] calldata _saleId) external onlyAdmin {
    uint256 count_ = _saleId.length;
    for (uint256 i = 0; i < count_; i++) {
      if (
        sales[_saleId[i]].startTime > block.timestamp ||
        sales[_saleId[i]].isActive == false)
      {
        delete sales[_saleId[i]];
        emit DeleteSale(_saleId[i]);
      }
    }
  }

  function closeSale(uint256 _saleID)
    external
    onlyAdmin
    onlyActiveSale(_saleID)
    onlyValidAddress(cmdWallet)
    onlyValidAddress(burnWallet)
  {
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

  /// @notice add shared cap
  function addSharedCap (string calldata _name, uint256 _cap, uint256 _maxSalesCnt) external onlyAdmin {
    require(_maxSalesCnt >= 2 && _maxSalesCnt <= currencies.length, "Incorrect maxSalesCnt value");
    SharedCap memory sharedCap_ = SharedCap({
      cap: uint24(_cap),
      maxSalesCnt: uint8(_maxSalesCnt),
      salesCnt: 0,
      saleIDs: 0,
      soldAmount: 0});
    sharedCaps[++maxSharedCapID] = sharedCap_;
    emit AddSharedCap(maxSharedCapID,string(abi.encodePacked(_name)),_cap, _maxSalesCnt);
  }

  /// @notice remove last shared cap
  function removeLastSharedCap() external onlyAdmin {
    if (_removeSharedCap(maxSharedCapID)) {
      maxSharedCapID--;
    }
  }

  /// @notice remove shared cap
  function removeSharedCap(uint256[] calldata _sharedCapIds) external onlyAdmin {
    uint256 count_ = _sharedCapIds.length;
    for (uint256 i = 0; i < count_; i++) {
      _removeSharedCap(_sharedCapIds[i]);
    }
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
    require (sale_.soldAmount + _quantity <= sale_.cap, "Cannot exceed sale's cap");
    if (sale_.sharedCapID > 0) {
      SharedCap storage sharedCap_ = sharedCaps[sale_.sharedCapID];
      require (sharedCap_.soldAmount + _quantity <= sharedCap_.cap, "Cannot exceed shared cap");
      sharedCap_.soldAmount += uint24(_quantity);
    }
    address buyer_ = msg.sender;
    uint256[] memory lbAssetId_; 
    if (sale_.lootboxID > 0) {
      require(_quantity <= maxLbBuyQuantity, "Max lootbox quantity per transaction exceeded");
      lbAssetId_ = _openLootbox(sale_.lootboxID, buyer_, _quantity);
      require(lbAssetId_.length > 0, "Error when opening lootbox");
    } else {
      lbAssetId_ = new uint256[](0);
    }
    uint256 price_ = sale_.price * _quantity;
    sale_.soldAmount += uint24(_quantity);
    sale_.raisedAmount += price_;
    if (sale_.currencyID == 0) {
      require(msg.value == price_, "Insufficient matic value");
    } else {
      require(_tokenTransferFrom(buyer_, address(this), price_, currencies[sale_.currencyID].currAddress), "Error with token tranfer");
    }
    emit Buy(_saleID, _quantity, sale_.soldAmount, buyer_, lbAssetId_);
  }

  function changePrice(uint256[] calldata _saleID, uint256[] calldata _newPrice)
    external
    onlyAdmin
  {
    uint256 count_ = _saleID.length;
    require(_newPrice.length == count_, "saleID and newPrice lengths don't match");
    for (uint256 i=0; i<count_; i++) {
      require(
        sales[_saleID[i]].isActive &&
        sales[_saleID[i]].priceDeltaPerMille > 0 &&
        _newPrice[i] > 0, "Invalid saleID or newPrice");
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
    uint256 balance_ = ERC20(_tokenAddress).balanceOf(address(this));
    require(_amount <= balance_, "Token balance too low");
    uint256 withdrawalAmount_ = (_amount == 0 ? balance_ : _amount);
    require(_tokenTransfer(owner(), withdrawalAmount_, _tokenAddress), "Withdrawing stuck tokens failed");
  }

  function withdrawStuckMatic(uint256 _amount) external onlyAdmin {
    uint256 balance_ = address(this).balance;
    require(_amount <= balance_, "Matic balance too low");
    uint256 withdrawalAmount_ = (_amount == 0 ? balance_ : _amount);
    require(payable(owner()).send(withdrawalAmount_), "Withdrawing stuck matic failed");
  }

  function changeLootboxContractAddress(address _newLootboxContractAddress)
    external
    onlySuperAdmin
    onlyValidAddress(_newLootboxContractAddress)
  {
    lootboxContractAddress = _newLootboxContractAddress;
    emit ChangeLootboxContractAddress(_newLootboxContractAddress);
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
    maxSaleID = uint16(_newMaxSaleID) ;
    emit ChangeMaxSaleID(_newMaxSaleID);
  }

  function changeMaxSharedCapID(uint256 _newMaxSharedCapID) external onlySuperAdmin {
    maxSharedCapID = uint16(_newMaxSharedCapID) ;
    emit ChangeMaxSharedCapID(_newMaxSharedCapID);
  }

  function changeMaxLbMuyQuantity(uint256 _newMaxLbBuyQuantity) external onlySuperAdmin {
    maxLbBuyQuantity = uint8(_newMaxLbBuyQuantity) ;
    emit ChangeMaxLbBuyQuantity(_newMaxLbBuyQuantity);
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

  //  This function allows you to clean up / delete contract
  function kill(address payable _recipient) external onlyOwner {
    uint256 currenciesLength_ = currencies.length;
    for (uint256 i=1; i<currenciesLength_; i++) {
      require(ERC20(currencies[i].currAddress).balanceOf(address(this)) == 0, "Contract contains currency tokens");
    }
    selfdestruct(_recipient);
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


  function getSharedCapSaleIDs(uint256 _scID) external view returns (uint256[] memory){
    uint256 salesCount_ = sharedCaps[_scID].salesCnt;
    if (salesCount_ == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result_ = new uint256[](salesCount_);
      uint256 saleIDs_ = sharedCaps[_scID].saleIDs;
      for (uint256 i = 0; i < salesCount_; i++) {
        result_[i] = uint256(uint16(saleIDs_ >> 16*i));
      }
      return result_;
    }
  }

  function getActiveSaleIDs() external view returns (uint256[] memory) {
    uint256[] memory pom_ = new uint256[](maxSaleID);
    uint256 i; uint256 j;
    for (i=1; i<=maxSaleID; i++)
      if (sales[i].isActive)
        pom_[j++] = i;
    uint256[] memory saleIDs_ = new uint256[](j);
    for (i=0; i<j; i++){
      saleIDs_[i] = pom_[i];
    }
    return saleIDs_;
  }

  function _removeSharedCap(uint256 _sharedCapID) private returns (bool) {
    if (sharedCaps[_sharedCapID].salesCnt == 0) {
      delete sharedCaps[_sharedCapID];
      emit RemoveSharedCap(_sharedCapID);
      return true;
    }
    return false;
  }

  function _changePrice(uint256 _saleID, uint256 _newPrice) private {
    Sale storage sale_ = sales[_saleID];
    uint256 price_ = sale_.price;
    sale_.originalPrice = price_;
    sale_.price = _newPrice;
    emit ChangePrice(_saleID, sale_.originalPrice, sale_.price);
  }

  function _tokenTransferFrom(
    address allower_,
    address receiver_,
    uint256 amount_,
    address tokenAddress_
  ) private returns (bool) {
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

  function _openLootbox(uint256 _lootboxId, address _buyer, uint256 _quantity)
    private
    returns (uint256[] memory)
  {
    return Lootbox(lootboxContractAddress).openLootbox(_lootboxId, _buyer, _quantity);
  }

  function _getLootboxStatus(uint256 _lootboxId)
    private
    view
    returns (uint256)
  {
    return Lootbox(lootboxContractAddress).getLootboxStatus(_lootboxId);
  }

}