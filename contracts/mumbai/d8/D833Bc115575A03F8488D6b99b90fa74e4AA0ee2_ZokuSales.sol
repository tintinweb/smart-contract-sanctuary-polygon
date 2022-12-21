// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IERC721Standard.sol";
import "./interfaces/ISales.sol";
import "./interfaces/ISettings.sol";

contract ZokuSales is Ownable, Initializable, ISales {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  event Deposit(
    address indexed sender,
    uint amount,
    uint balance
  );

  struct User {
    address user;
    uint256 allocation;
    uint256 consumed;
  }

  struct Item {
    uint256 price;
    uint256 allocation;
    uint256 consumed;
    mapping(address => User) user;
    uint256 userCount;
  }

  struct Stage {
    uint256 start;
    uint256 end;
    StageStatus status;
    mapping(uint32 => Item) item; 
    uint256 allocation;
    uint256 consumed;
  }

  struct Payment {
    uint256 paid;
    uint256 refunded;
  }
  
  EnumerableSet.UintSet private _stageIndex;

  mapping(uint8 => Stage) private _stages;
  mapping(uint8 => EnumerableSet.UintSet) private _itemIndex;
  mapping(uint8 => mapping(uint32 => EnumerableSet.AddressSet)) private _userIndex;
  mapping(address => mapping(uint256 => Payment)) private _mintedPayments;

  ISettings public settings;

  function initialize(address _settings) external initializer {
    settings = ISettings(_settings);

    _transferOwnership(_msgSender());
  }

  modifier isAddress(address _address) {
    require(_address != address(0), "Sales: Invalid address");
    _;
  }

  modifier onlyAdmin() {
    require(settings.isAdmin(_msgSender()), "Sales: Not operator");
    _;
  }

  modifier existStage(uint8 _stage) {
    require(_stageIndex.contains(_stage), "Sales: Stage is not exists");
    _;
  }

  modifier notExistStage(uint8 _stage) {
    require(!_stageIndex.contains(_stage), "Sales: Stage is exists");
    _;
  }

  /**
   * @notice Receive deposit of token (ETH)
   */
  receive() external payable {
    emit Deposit(msg.sender, msg.value, address(this).balance);
  }

  function addStage(
    uint8 _stage,
    uint256 _start,
    uint256 _end,
    StageStatus _status
  ) external onlyAdmin notExistStage(_stage) {
    _stages[_stage].start = _start;
    _stages[_stage].end = _end;
    _stages[_stage].status = _status;
    _stages[_stage].allocation = 0;
    _stages[_stage].consumed = 0;
    
    _stageIndex.add(_stage);
    
    emit StageCreated(_stage, _start, _end, _status, _msgSender());
  }
  
  function removeStage(uint8 _stage) external onlyAdmin existStage(_stage) {
    delete _stages[_stage];
    _stageIndex.remove(_stage);

    emit StageRemoved(_stage, _msgSender());
  }

  function getStages() public view returns(uint8[] memory) {
    uint8[] memory stages = new uint8[](_stageIndex.length());

    for (uint256 i = 0; i < _stageIndex.length(); i++) {
      stages[i] = uint8(_stageIndex.at(i));
    }

    return stages;
  }

  function getStage(uint8 _stage) public view returns(uint256 start, uint256 end, StageStatus status, uint256 allocation, uint256 consumed) {
    Stage storage stage = _stages[_stage];
    
    return (
      stage.start,
      stage.end,
      stage.status,
      stage.allocation,
      stage.consumed
    );
  }

  function addItem(
    uint8 _stage,
    uint32 _item,
    uint256 _price,
    uint256 _allocation
  ) external onlyAdmin {
    require(_stageIndex.contains(_stage), "Sales: Stage not found");
    require(_validateAllocation(_allocation), "Sales: Maximum allowance for stage");

    Item storage item = _stages[_stage].item[_item];
    item.price = _price;
    item.allocation = _allocation;
    
    if (!_itemIndex[_stage].contains(_item)) {
      _itemIndex[_stage].add(_item);
    }

    _stages[_stage].allocation += _allocation;

    emit ItemCreated(_stage, _item, _price, _allocation, _msgSender());
  }

  function getItems(uint8 _stage) public view returns(uint256[] memory) {
    return _itemIndex[_stage].values();
  }

  function getItem(uint8 _stage, uint32 _item) public view returns(uint256 price, uint256 allocation, uint256 consumed) {
    Item storage item = _stages[_stage].item[_item];
    
    return (
      item.price,
      item.allocation,
      item.consumed
    );
  }

  function removeItem(uint8 _stage, uint32 _item) external onlyAdmin {
    Item storage item = _stages[_stage].item[_item];
    
    _stages[_stage].allocation -= item.allocation;

    delete _stages[_stage].item[_item];

    emit ItemRemoved(_stage, _item, _msgSender());
  }

  function getUsers(uint8 _stage, uint32 _item) public view returns(address[] memory) {
    return _userIndex[_stage][_item].values();
  }

  function getUser(uint8 _stage, uint32 _item, address _user) public view returns(uint256 allocation, uint256 consumed) {
    User storage user = _stages[_stage].item[_item].user[_user];
    
    return (
      user.allocation,
      user.consumed
    );
  }

  function setStageStatus(uint8 _stage, StageStatus _status) external onlyAdmin existStage(_stage) {
    Stage storage stage = _stages[_stage];
    stage.status = _status;

    emit StageStatusUpdated(_stage, _status, _msgSender());
  }

  function setStagePeriod(
    uint8 _stage,
    uint256 _start,
    uint256 _end
  ) external onlyAdmin existStage(_stage) {
    Stage storage stage = _stages[_stage];
    stage.start = _start;
    stage.end = _end;

    emit StagePeriodUpdated(_stage, _start, _end, _msgSender());
  }

  function setItemPrice(
    uint8 _stage,
    uint32 _item,
    uint256 _price
  ) external onlyAdmin {
    Item storage item = _stages[_stage].item[_item];
    item.price = _price;
  }

  function addUser(
    uint8 _stage,
    uint32 _item,
    address _user,
    uint256 _multiplier
  ) external isAddress(_user) onlyAdmin {
    require((_stages[_stage].item[_item].allocation - _multiplier) >= _multiplier, "Sales: Maximum item allocation");
    _addUser(_stage, _item, _user, _multiplier);
  }

  function _addUser(
    uint8 _stage,
    uint32 _item,
    address _user,
    uint256 _multiplier
  ) internal isAddress(_user) {
    Item storage item = _stages[_stage].item[_item];

    if (item.user[_user].user != address(0)) {
      /// current user
      item.user[_user].allocation += _multiplier;
    } else {
      /// new user
      item.user[_user].user = _user;
      item.user[_user].allocation = _multiplier;
      item.user[_user].consumed = 0;
      item.userCount += 1;

      _userIndex[_stage][_item].add(_user);
    }

    emit WhitelistUserCreated(_stage, _item, _user, _multiplier, _msgSender());
  }

  function addBatchUser(
    uint8 _stage,
    uint32 _item,
    address[] memory _users,
    uint256 _multiplier
  ) external onlyAdmin {
    require(_users.length > 0, "Sales: No provided users");
    require(_multiplier > 0, "Sales: Invalid multiplier");

    uint256 newAllocation = _users.length * _multiplier;
    require((_stages[_stage].item[_item].allocation - newAllocation) >= newAllocation, "Sales: Maximum item allocation");

    for (uint256 i; i < _users.length; i++) {
      _addUser(_stage, _item, _users[i], _multiplier);
    }
  }

  function removeUser(
    uint8 _stage,
    uint32 _item,
    address _user
  ) external isAddress(_user) onlyAdmin {
    Item storage item = _stages[_stage].item[_item];

    delete item.user[_user];

    /// substract user count
    if (item.userCount > 0) {
      item.userCount -= 1;
    }

    _userIndex[_stage][_item].remove(_user);

    emit WhitelistUserRemoved(_stage, _item, _user, _msgSender());
  }

  function isWhitelisted(
    uint8 _stage,
    uint32 _item,
    address _user
  ) public view isAddress(_user) returns(bool) {
    Stage storage stage = _stages[_stage];

    if (stage.status != StageStatus.Disabled) {
      if (stage.start > block.timestamp || stage.end < block.timestamp) {
        return false;
      }
      
      /// validate item allocation but ignoring user allocation
      if (stage.status == StageStatus.Unwhitelisted) {
        return (stage.item[_item].allocation - stage.item[_item].consumed) > 0;
      }

      /// validate user allocation
      if (stage.status == StageStatus.Whitelisted) {
        return (stage.item[_item].user[_user].allocation - stage.item[_item].user[_user].consumed) > 0;
      }
    }

    return false;
  }

  function consume(
    uint8 _stage,
    uint32 _item,
    uint256 _quantity
  ) external {
    Stage storage stage = _stages[_stage];
    Item storage item = stage.item[_item];

    (bool success, string memory _message) = _canConsume(_stage, _item, _msgSender(), _quantity);

    require(success, _message);

    item.user[_msgSender()].consumed += _quantity;
    item.consumed += _quantity;
    stage.consumed += _quantity;
  }

  function _consume(
    uint8 _stage,
    uint32 _item,
    uint256 _quantity
  ) internal {
    Stage storage stage = _stages[_stage];
    Item storage item = stage.item[_item];

    (bool success, string memory _message) = _canConsume(_stage, _item, _msgSender(), _quantity);

    require(success, _message);

    item.user[_msgSender()].consumed += _quantity;
    item.consumed += _quantity;
    stage.consumed += _quantity;
  }

  function canConsume(
    uint8 _stage,
    uint32 _item,
    address _user,
    uint256 _quantity
  ) external view returns(bool result, string memory message) {
    (bool success, string memory _message) = _canConsume(_stage, _item, _user, _quantity);

    return (success, _message);
  }

  function getConsumed(
    uint8 _stage,
    uint32 _item,
    address _user
  ) external view returns(uint256) {
    User storage user = _stages[_stage].item[_item].user[_user];
    return user.consumed;
  }

  function totalAllocation() public view returns(uint256 allocation, uint256 consumed) {
    return _totalAllocation();
  }

  function transferOwnership(address newOwner) public override(Ownable, ISales) onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    super._transferOwnership(newOwner);
  }

  function renounceOwnership() public override(Ownable, ISales) onlyOwner {
    super._transferOwnership(address(0));
  }

  function _canConsume(
    uint8 _stage,
    uint32 _item,
    address _user,
    uint256 _quantity
  ) internal view returns(bool, string memory) {
    if (_quantity <= 0) {
      return (false, "Sales: Require non zero number");
    }

    Stage storage stage = _stages[_stage];
    Item storage item = stage.item[_item];
    User storage user = item.user[_user];

    /// disabled stage
    if (stage.status == StageStatus.Disabled) {
      return (false, "Sales: Stage is disabled");
    }

    /// validate period
    if (stage.start > block.timestamp || stage.end < block.timestamp) {
      return (false, "Sales: Stage is out of period");
    }

    /// all allocation quantity in the stage are sold out
    if (item.allocation == item.consumed) {
      return (false, "Sales: Items sold out");
    }

    if (stage.status == StageStatus.Whitelisted) {
      /// member doesn't have allocated quantity or they are not whitelisted
      if (user.allocation == 0) {
        return (false, "Sales: User is not whitelisted");
      }

      /// allocation is not enough
      if ((user.allocation - user.consumed) < _quantity) {
        return (false, "Sales: Quantity exceeds max allowance");
      }
    }

    /// all good and return true
    return (true, "Sales: Great");
  }

  function _itemsAllocated(uint8 _stage) internal view returns(uint256, uint256) {
    uint256 _allocation = 0;
    uint256 _consumed = 0;

    for (uint256 i = 0; i < _itemIndex[_stage].length(); i++) {
      Item storage item = _stages[_stage].item[uint32(_itemIndex[_stage].at(i))];
      _allocation += item.allocation;
      _consumed += item.consumed;
    }

    return (_allocation, _consumed);
  }

  function _totalAllocation() public view returns(uint256, uint256) {
    uint256 _allocation = 0;
    uint256 _consumed = 0;

    for (uint256 i = 0; i < _stageIndex.length(); i++) {
      _allocation += _stages[uint8(_stageIndex.at(i))].allocation;
      _consumed += _stages[uint8(_stageIndex.at(i))].consumed;
    }

    return (_allocation, _consumed);
  }

  function _validateAllocation(uint256 _allocation) internal returns(bool) {
    address token = settings.token();
    uint256 maxSupply = IERC721Standard(token).maxSupply();
    (uint256 allocated,) = _totalAllocation();
    
    return (allocated + _allocation) <= maxSupply;
  }

  function _pay(uint256 price) internal {
    if (settings.isNativeToken()) {
      uint256 ethValue = msg.value;
      require(price <= ethValue, "Sales: Insufficent Funds");
      uint256 adminFees = price * settings.adminFee() / 1000;
      
      /// transfer to fund receiver
      (bool success, ) = settings.fundReceiver().call{value: (price - adminFees)}("");
      /// transfer to admin fee receiver
      (bool success2, ) = settings.adminFeeReceiver().call{value: adminFees}("");
      
      require(success, "Sales: Could not send funds to project");
      require(success2, "Sales: Could not send funds to admin");
    } else {
      require(price <= IERC20(settings.paymentToken()).allowance(_msgSender(), address(this)), "Sales: Insufficent allowance");
      require(price <= IERC20(settings.paymentToken()).balanceOf(_msgSender()), "Sales: Insufficent Funds");

      uint256 adminFees = price * settings.adminFee() / 1000;

      /// transfer to fund receiver
      SafeERC20.safeTransferFrom(IERC20(settings.paymentToken()), _msgSender(), settings.fundReceiver(), price - adminFees);
      /// transfer to admin fee receiver
      SafeERC20.safeTransferFrom(IERC20(settings.paymentToken()), _msgSender(), settings.adminFeeReceiver(), adminFees);
    }
  }

  function mint(
    uint8 _stage,
    uint32 _item,
    string memory _tokenURI
  ) external payable returns(uint256 tokenId) {
    require(settings.token() != address(0), "Sales: Project not found");

    (uint256 price, uint256 qty, uint256 consumedQty) = getItem(_stage, _item);
    (bool _success, string memory _msgText) = _canConsume(_stage, _item, _msgSender(), 1);
    
    require(_success, _msgText);
    require(uint256(consumedQty + 1) <= uint256(qty), "Sales: All item minted");
    require(1 <= qty, "Sales: Exceeds max amount per mint");
    
    _pay(price);
    _consume(_stage, _item, 1);
    
    tokenId = IERC721Standard(settings.token()).mint(_msgSender(), _tokenURI);
    _mintedPayments[settings.paymentToken()][tokenId].paid = price;
    
    emit SalesTokenMinted(settings.token(), _stage, _item, 1, _msgSender(), tokenId, _tokenURI);
  }

  function batchMint(
    uint8 _stage,
    uint32 _item,
    uint256 _quantity,
    string[] memory _tokenURI
  ) external payable {
    require(settings.token() != address(0), "Sales: Project not found");
    require(_tokenURI.length == _quantity, "Sales: Invalid token URIs count");

    (uint256 price, uint256 qty, uint256 consumedQty) = getItem(_stage, _item);
    (bool _success, string memory _msgText) = _canConsume(_stage, _item, _msgSender(), _quantity);
    
    require(_success, _msgText);
    require(uint256(consumedQty + _quantity) <= uint256(qty), "Sales: All item minted");
    require(_quantity <= settings.maxPerMint(), "Sales: Exceeds max amount per mint");
    
    _pay(price * _quantity);
    _consume(_stage, _item, _quantity);

    for (uint256 i = 0; i < _quantity; i++) {
      uint256 tokenId = IERC721Standard(settings.token()).mint(_msgSender(), _tokenURI[i]);
      _mintedPayments[settings.paymentToken()][tokenId].paid = price;
      
      emit SalesTokenMinted(settings.token(), _stage, _item, 1, _msgSender(), tokenId, _tokenURI[i]);
    }
  }

  function refund() external {
    IERC721Standard tokenContract = IERC721Standard(settings.token());
    (uint256[] memory tokenIds) = tokenContract.getTokens(_msgSender());

    uint256 paid = 0;
    uint256 refunded = 0;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      paid += _mintedPayments[settings.paymentToken()][tokenIds[i]].paid;
      refunded += _mintedPayments[settings.paymentToken()][tokenIds[i]].refunded;
    }
    
    require(settings.refundable(), "Sales: No refundable");
    require(paid > refunded, "Sales: No refundable for you");

    (uint256 refundFixedFee, uint256 refundPercentageFee) = settings.refundFees();
    uint256 amountToRefund = paid - refunded;
    uint256 refundFee = 0;

    if (refundFixedFee > 0) {
      refundFee += refundFixedFee;
    }

    if (refundPercentageFee > 0) {
      refundFee += amountToRefund * refundPercentageFee / 1000;
    }

    if (settings.isNativeToken()) {
      require(address(this).balance >= (amountToRefund - refundFee), "Sales: Insufficent funds to refund");
      payable(_msgSender()).transfer(amountToRefund - refundFee);
    } else {
      require(IERC20(settings.paymentToken()).balanceOf(address(this)) >= (amountToRefund - refundFee), "Sales: Insufficent funds to refund");
      SafeERC20.safeTransfer(IERC20(settings.paymentToken()), payable(_msgSender()), (amountToRefund - refundFee));
    }

    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenContract.burn(tokenIds[i]);
      emit Burned(settings.token(), tokenIds[i], _msgSender());
    }

    emit Refunded(_msgSender(), amountToRefund, settings.paymentToken());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Standard is IERC721 {
  function initialize(address settings) external;
  function mint(address _to, string memory _tokenURI) external returns(uint256);
  function maxSupply() external returns(uint256);
  function transferOwnership(address newOwner) external;
  function renounceOwnership() external;
  function burn(uint256 tokenId) external;
  function setMinter(address minter) external;
  function getTokens(address owner) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISales {
  enum StageStatus {
    Disabled,
    Whitelisted,
    Unwhitelisted
  }

  // stage events
  event StageCreated(uint8 indexed stage, uint256 start, uint256 end, StageStatus status, address sender);
  event StageRemoved(uint8 indexed stage, address sender);
  event StageStatusUpdated(uint8 indexed stage, StageStatus status, address sender);
  event StagePeriodUpdated(uint8 indexed stage, uint256 start, uint256 end, address sender);

  // item events
  event ItemCreated(uint8 stage, uint32 item, uint256 price, uint256 allocation, address sender);
  event ItemRemoved(uint8 stage, uint32 item, address sender);

  // whitelist events
  event WhitelistUserCreated(uint8 stage, uint32 item, address user, uint256 quantity, address sender);
  event WhitelistUserRemoved(uint8 stage, uint32 item, address user, address sender);

  // minting
  event SalesTokenMinted(address token, uint8 stage, uint32 item, uint256 amount, address user, uint256 tokenId, string tokenURI);
  event Refunded(address user, uint256 amount, address paymentToken);
  event Burned(address token, uint256 tokenId, address user);

  function initialize(address settings) external;

  // stage functions
  function addStage(uint8 stage, uint256 start, uint256 end, StageStatus status) external;
  function removeStage(uint8 stage) external;
  function getStages() external view returns(uint8[] memory);
  function getStage(uint8 stage) external view returns(uint256 start, uint256 end, StageStatus status, uint256 allocation, uint256 consumed);
  function setStageStatus(uint8 stage, StageStatus status) external;
  function setStagePeriod(uint8 stage, uint256 start, uint256 end) external;
  
  // item functions
  function addItem(uint8 stage, uint32 item, uint256 price, uint256 allocation) external;
  function getItems(uint8 _stage) external view returns(uint256[] memory);
  function getItem(uint8 stage, uint32 item) external view returns(uint256 price, uint256 allocation, uint256 consumed);
  function removeItem(uint8 stage, uint32 item) external;
  function setItemPrice(uint8 stage, uint32 item, uint256 price) external;
  
  // user functions
  function getUsers(uint8 _stage, uint32 _item) external view returns(address[] memory);
  function getUser(uint8 stage, uint32 item, address user) external view returns(uint256 allocation, uint256 consumed);
  
  // user functions
  function addUser(uint8 stage, uint32 item, address user, uint256 multiplier) external;
  function addBatchUser(uint8 stage, uint32 item, address[] memory users, uint256 multiplier) external;
  function removeUser(uint8 stage, uint32 item, address user) external;
  function isWhitelisted(uint8 stage, uint32 item, address user) external view returns(bool);
  
  // consume functions
  function consume(uint8 stage, uint32 item, uint256 quantity) external;
  function canConsume(uint8 stage, uint32 item, address user, uint256 quantity) external view returns(bool result, string memory message);
  function getConsumed(uint8 stage, uint32 item, address user) external view returns(uint256);
  function totalAllocation() external view returns(uint256 allocation, uint256 consumed);

  function transferOwnership(address newOwner) external;
  function renounceOwnership() external;
  function mint(uint8 stage, uint32 item, string memory tokenURI) external payable returns(uint256 tokenId);
  function batchMint(uint8 stage, uint32 item, uint256 quantity, string[] memory tokenURI) external payable;
  function refund() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISettings {
  /// events
  event AdminCreated(address admin, address sender);
  event AdminRemoved(address admin, address sender);
  event AdminFeeUpdated(uint256 adminFee, address sender);
  event AdminFeeReceiverUpdated(address adminFeeReceiver, address sender);
  event RoyaltyFeeUpdated(uint256 royaltyFee, address sender);
  event RoyaltyFeeReceiverUpdated(address royaltyFeeReceiver, address sender);
  event FundReceiverUpdated(address fundReceiver, address sender);
  event TokenOwnerUpdated(address tokenOwner, address sender);
  event PaymentTokenUpdated(address paymentToken, address sender);
  event RefundableUpdated(bool refundable, uint256 refundableFixedFee, uint256 refundablePercentageFee, address sender);
  event ProtocolsUpdated(address factory, address sales, address marketplace);
  event MaxPerMintUpdated(uint256 quantity);

  function initialize(
    address token,
    string memory tokenName,
    string memory tokenSymbol,
    string memory tokenBaseURI,
    uint256 tokenMaxSupply
  ) external;

  /// getters (should be immutable)
  function token() external view returns(address);
  function tokenName() external view returns(string memory);
  function tokenSymbol() external view returns(string memory);
  function tokenMaxSupply() external view returns(uint256);
  function tokenBaseURI() external view returns(string memory);
  function nativeToken() external view returns(address);

  /// getters (should be mutable)
  function isNativeToken() external view returns(bool);
  function isAdmin(address admin) external view returns(bool);
  function getAdmins() external view returns (address[] memory);
  function royaltyFeeReceiver() external view returns(address payable);
  function royaltyFee() external view returns(uint256);
  function adminFeeReceiver() external view returns(address payable);
  function fundReceiver() external view returns(address payable);
  function adminFee() external view returns(uint256);
  function tokenOwner() external view returns(address);
  function paymentToken() external view returns(address);
  function refundable() external view returns(bool);
  function refundFees() external view returns(uint256, uint256);
  function protocols() external view returns(address, address, address);
  function maxPerMint() external view returns(uint256);

  /// setters
  function addAdmin(address admin) external;
  function removeAdmin(address admin) external;
  function setRoyaltyFeeReceiver(address payable royaltyFeeReceiver) external;
  function setRoyaltyFee(uint256 royaltyFee) external;
  function setAdminFeeReceiver(address payable adminFeeReceiver) external;
  function setFundReceiver(address payable fundFeeReceiver) external;
  function setAdminFee(uint256 adminFee) external;
  function setTokenOwner(address tokenOwner) external;
  function setPaymentToken(address paymentToken) external;
  function setRefundable(bool refundable, uint256 fixedFee, uint256 percentageFee) external;
  function setProtocols(address factory, address sales, address marketplace) external;
  function setMaxPerMint(uint256 quantity) external;

  function transferOwnership(address newOwner) external;
  function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}