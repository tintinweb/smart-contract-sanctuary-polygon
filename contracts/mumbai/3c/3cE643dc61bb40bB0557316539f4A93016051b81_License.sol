// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.8.4;

/// @@@  @@@   @@@@@@   @@@       @@@   @@@@@@   @@@@@@@
/// @@@  @@@  @@@@@@@@  @@@       @@@  @@@@@@@   @@@@@@@
/// @@!  @@@  @@!  @@@  @@!       @@!  [email protected]@         @@!
/// [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!       [email protected]!  [email protected]!         [email protected]!
/// @[email protected] [email protected]!  @[email protected][email protected][email protected]!  @!!       [email protected] [email protected]@!!      @!!
/// [email protected]!  !!!  [email protected]!!!!  !!!       !!!   [email protected]!!!     !!!
/// :!:  !!:  !!:  !!!  !!:       !!:       !:!    !!:
///  ::!!:!   :!:  !:!   :!:      :!:      !:!     :!:
///   ::::    ::   :::   :: ::::   ::  :::: ::      ::
///    :       :   : :  : :: : :  :    :: : :       :

import "../core/Registry.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title Valist License contract
contract License is ERC1155, IERC2981 {
  using SafeERC20 for IERC20;

  /// @dev emitted when mint price is changed.
  event PriceChanged(
    uint _projectID,
    address _token,
    uint _price,
    address _sender
  );

  /// @dev emitted when limit is changed.
  event LimitChanged(
    uint _projectID,
    uint _limit,
    address _sender
  );

  /// @dev emitted when royalty is changed.
  event RoyaltyChanged(
    uint _projectID,
    address _recipient,
    uint _amount,
    address _sender
  );

  /// @dev emitted when balance is withdrawn.
  event BalanceWithdrawn(
    uint _projectID,
    address _token,
    uint _balance,
    address _recipient,
    address _sender
  );

  /// @dev emitted when a product is purchased.
  event ProductPurchased(
    uint _projectID,
    address _token,
    uint _price,
    address _recipient,
    address _sender
  );

  struct Product {
    /// @dev supply limit
    uint limit;
    /// @dev total supply
    uint supply;
    /// @dev price in wei
    uint price;
    /// @dev balance in wei
    uint balance;
    /// @dev royalty recipient address
    address royaltyRecipient;
    /// @dev royalty amount in basis points
    uint royaltyAmount;
    /// @dev mapping of address to token info
    mapping(IERC20 => Token) tokens;
  }

  struct Token {
    /// @dev token price
    uint price;
    /// @dev token balance
    uint balance;
  }

  /// @dev mapping of project ID to product info
  mapping(uint => Product) private productByID;

  /// @dev token symbol
  string public symbol = "LICENSE";
  /// @dev token display name
  string public name = "Valist Product License";
  /// @dev address of contract owner
  address payable public owner;
  /// @dev protocol fee in basis points
  uint public protocolFee;
  /// @dev address of the valist registry
  Registry public registry;

  /// Creates a Valist License contract.
  ///
  /// @param _registry Address of the Valist Registry.
  constructor(address _registry) ERC1155("") {
    owner = payable(msg.sender);
    registry = Registry(_registry);
  }

  /// Purchase a product using native tokens.
  ///
  /// @param _projectID ID of the project.
  /// @param _recipient Address of the recipient.
  function purchase(uint _projectID, address _recipient) public payable {
    uint price = productByID[_projectID].price;
    require(price > 0 && msg.value == price, "err-price");

    uint limit = productByID[_projectID].limit;
    uint supply = productByID[_projectID].supply;
    require(limit == 0 || supply < limit, "err-limit");

    uint fee = price * protocolFee / 10000;

    // increase product balance and supply
    productByID[_projectID].balance += price - fee;
    productByID[_projectID].supply += 1;

    // send protocol fee to owner
    Address.sendValue(owner, fee);

    _mint(_recipient, _projectID, 1, "");
    emit ProductPurchased(_projectID, address(0), price, _recipient, _msgSender());
  }

  /// Purchase a product using ERC20 tokens.
  ///
  /// @param _token ERC20 token address.
  /// @param _projectID ID of the project.
  /// @param _recipient Address of the recipient.
  function purchase(IERC20 _token, uint _projectID, address _recipient) public {
    uint price = productByID[_projectID].tokens[_token].price;
    uint allowance = _token.allowance(_msgSender(), address(this));
    require(price > 0 && allowance >= price, "err-price");

    uint limit = productByID[_projectID].limit;
    uint supply = productByID[_projectID].supply;
    require(limit == 0 || supply < limit, "err-limit");

    uint fee = price * protocolFee / 10000;

    // increase product balance and supply
    productByID[_projectID].tokens[_token].balance += price - fee;
    productByID[_projectID].supply += 1;

    // transfer tokens and send protocol fee to owner
    _token.safeTransferFrom(_msgSender(), address(this), price);
    _token.safeTransfer(owner, fee);

    _mint(_recipient, _projectID, 1, "");
    emit ProductPurchased(_projectID, address(_token), price, _recipient, _msgSender());
  }

  /// Set the mint price of a product in native tokens.
  ///
  /// @param _projectID ID of the project.
  /// @param _price Mint price in wei.
  function setPrice(uint _projectID, uint _price) public {
    uint accountID = registry.getProjectAccountID(_projectID);
    require(registry.isAccountMember(accountID, _msgSender()), "err-not-member");

    productByID[_projectID].price = _price;
    emit PriceChanged(_projectID, address(0), _price, _msgSender());
  }

  /// Set the mint price of a product in ERC20 tokens.
  ///
  /// @param _token ERC20 token address.
  /// @param _projectID ID of the project.
  /// @param _price Mint price in ERC20 tokens.
  function setPrice(IERC20 _token, uint _projectID, uint _price) public {
    uint accountID = registry.getProjectAccountID(_projectID);
    require(registry.isAccountMember(accountID, _msgSender()), "err-not-member");

    productByID[_projectID].tokens[_token].price = _price;
    emit PriceChanged(_projectID, address(_token), _price, _msgSender());
  }

  /// Withdraw product balance in native tokens.
  ///
  /// @param _projectID ID of the project.
  /// @param _recipient Address of the recipient.
  function withdraw(uint _projectID, address payable _recipient) public {
    uint accountID = registry.getProjectAccountID(_projectID);
    require(registry.isAccountMember(accountID, _msgSender()), "err-not-member");

    uint balance = productByID[_projectID].balance;
    require(balance > 0, "err-balance");

    productByID[_projectID].balance = 0;
    Address.sendValue(_recipient, balance);

    emit BalanceWithdrawn(_projectID, address(0), balance, _recipient, _msgSender());
  }

  /// Withdraw product balance in ERC20 tokens.
  ///
  /// @param _token ERC20 token address.
  /// @param _projectID ID of the project.
  /// @param _recipient Address of the recipient.
  function withdraw(IERC20 _token, uint _projectID, address payable _recipient) public {
    uint accountID = registry.getProjectAccountID(_projectID);    
    require(registry.isAccountMember(accountID, _msgSender()), "err-not-member");

    uint balance = productByID[_projectID].tokens[_token].balance;
    require(balance > 0, "err-balance");

    productByID[_projectID].tokens[_token].balance = 0;
    _token.safeTransfer(_recipient, balance);

    emit BalanceWithdrawn(_projectID, address(_token), balance, _recipient, _msgSender());
  }

  /// Set a limit on the supply of a product.
  ///
  /// @param _projectID ID of the project.
  /// @param _limit Supply limit. Set to zero for unlimited.
  function setLimit(uint _projectID, uint _limit) public {
    uint accountID = registry.getProjectAccountID(_projectID);
    require(registry.isAccountMember(accountID, _msgSender()), "err-not-member");

    uint supply = productByID[_projectID].supply;
    require(_limit == 0 || _limit >= supply, "err-limit");

    productByID[_projectID].limit = _limit;
    emit LimitChanged(_projectID, _limit, _msgSender());
  }

  /// Set a royalty on product resales.
  ///
  /// @param _projectID ID of the project.
  /// @param _recipient Address of the recipient.
  /// @param _amount Royalty amount in basis points.
  function setRoyalty(uint _projectID, address _recipient, uint _amount) public {
    require(_amount < 10000, "err-bps");

    uint accountID = registry.getProjectAccountID(_projectID);
    require(registry.isAccountMember(accountID, _msgSender()), "err-not-member");

    productByID[_projectID].royaltyRecipient = _recipient;
    productByID[_projectID].royaltyAmount = _amount;
    emit RoyaltyChanged(_projectID, _recipient, _amount, _msgSender());
  }

  /// Returns the URI of the token
  ///
  /// @param _projectID ID of the project.
  function uri(uint _projectID) public view virtual override returns (string memory) {
    return registry.metaByID(_projectID);
  }

  /// @dev See {IERC165-supportsInterface}
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /// Returns the royalty recipient address and amount owed.
  ///
  /// @param _projectID ID of the project.
  /// @param _price Sale price of license.
  function royaltyInfo(uint _projectID, uint _price) public view virtual override returns (address, uint256) {
    address recipient = productByID[_projectID].royaltyRecipient;
    uint amount = productByID[_projectID].royaltyAmount;
    return (recipient, _price * amount / 10000);
  }

  /// Returns the balance of the product in wei.
  ///
  /// @param _projectID ID of the project.
  function getBalance(uint _projectID) public view returns(uint) {
    return productByID[_projectID].balance;
  }

  /// Returns the balance of the product in ERC20 tokens.
  ///
  /// @param _token ERC20 token address.
  /// @param _projectID ID of the project.
  function getBalance(IERC20 _token, uint _projectID) public view returns(uint) {
    return productByID[_projectID].tokens[_token].balance;
  }

  /// Returns the mint price of the product in wei.
  ///
  /// @param _projectID ID of the project.
  function getPrice(uint _projectID) public view returns(uint) {
    return productByID[_projectID].price;
  }

  /// Returns the mint price of the product in ERC20 tokens.
  ///
  /// @param _token ERC20 token address.
  /// @param _projectID ID of the project.
  function getPrice(IERC20 _token, uint _projectID) public view returns(uint) {
    return productByID[_projectID].tokens[_token].price;
  }

  /// Returns the supply limit of a product.
  ///
  /// @param _projectID ID of the project.
  function getLimit(uint _projectID) public view returns (uint) {
    return productByID[_projectID].limit;
  }

  /// Returns the total supply of a product.
  ///
  /// @param _projectID ID of the project.
  function getSupply(uint _projectID) public view returns (uint) {
    return productByID[_projectID].supply;
  }

  /// Sets the valist registry address. Owner only.
  ///
  /// @param _registry Address of the Valist Registry.
  function setRegistry(address _registry) public onlyOwner {
    registry = Registry(_registry);
  }

  /// Sets the owner address. Owner only.
  ///
  /// @param _owner Address of the new owner.
  function setOwner(address payable _owner) public onlyOwner {
    owner = _owner;
  }

  /// Sets the protocol fee. Owner only.
  ///
  /// @param _protocolFee Protocol fee in basis points.
  function setProtocolFee(uint _protocolFee) public onlyOwner {
    require(_protocolFee < 10000, "err-bps");
    protocolFee = _protocolFee;
  }

  /// Modifier that ensures only the owner can call a function.
  modifier onlyOwner() {
    require(owner == _msgSender(), "caller is not the owner");
    _;
  }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.8.4;

/// @@@  @@@   @@@@@@   @@@       @@@   @@@@@@   @@@@@@@
/// @@@  @@@  @@@@@@@@  @@@       @@@  @@@@@@@   @@@@@@@
/// @@!  @@@  @@!  @@@  @@!       @@!  [email protected]@         @@!
/// [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!       [email protected]!  [email protected]!         [email protected]!
/// @[email protected] [email protected]!  @[email protected][email protected][email protected]!  @!!       [email protected] [email protected]@!!      @!!
/// [email protected]!  !!!  [email protected]!!!!  !!!       !!!   [email protected]!!!     !!!
/// :!:  !!:  !!:  !!!  !!:       !!:       !:!    !!:
///  ::!!:!   :!:  !:!   :!:      :!:      !:!     :!:
///   ::::    ::   :::   :: ::::   ::  :::: ::      ::
///    :       :   : :  : :: : :  :    :: : :       :

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Valist registry contract
///
/// @custom:err-empty-meta metadata URI is required
/// @custom:err-empty-members atleast one member is required
/// @custom:err-empty-name name is required
/// @custom:err-name-claimed name has already been claimed
/// @custom:err-not-member sender is not a member
/// @custom:err-member-exist member already exists
/// @custom:err-member-not-exist member does not exist
/// @custom:err-not-exist account, project, or release does not exist
contract Registry is BaseRelayRecipient {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @dev emitted when an account is created
  event AccountCreated(
    uint _accountID,
    string _name,
    string _metaURI,
    address _sender
  );

  /// @dev emitted when an account is updated
  event AccountUpdated(
    uint _accountID,
    string _metaURI,
    address _sender
  );

  /// @dev emitted when an account member is added
  event AccountMemberAdded(
    uint _accountID,
    address _member,
    address _sender
  );
  
  /// @dev emitted when an account member is removed
  event AccountMemberRemoved(
    uint _accountID,
    address _member,
    address _sender
  );

  /// @dev emitted when a new project is created
  event ProjectCreated(
    uint _accountID,
    uint _projectID,
    string _name,
    string _metaURI, 
    address _sender
  );

  /// @dev emitted when an existing project is updated
  event ProjectUpdated(
    uint _projectID,
    string _metaURI,
    address _sender
  );

  /// @dev emitted when a new project member is added
  event ProjectMemberAdded(
    uint _projectID,
    address _member,
    address _sender
  );

  /// @dev emitted when an existing project member is removed
  event ProjectMemberRemoved(
    uint _projectID,
    address _member,
    address _sender
  );

  /// @dev emitted when a new release is created
  event ReleaseCreated(
    uint _projectID,
    uint _releaseID,
    string _name,
    string _metaURI, 
    address _sender
  );

  /// @dev emitted when a release is approved by a signer
  event ReleaseApproved(
    uint _releaseID,
    address _sender
  );

  /// @dev emitted when a release approval is revoked by a signer.
  event ReleaseRevoked(
    uint _releaseID,
    address _sender
  );

  struct Account {
    /// @dev set of member addresses.
    EnumerableSet.AddressSet members;
  }

  struct Project {
    /// @dev ID of the parent account.
    uint accountID;
    /// @dev ID of the latest release.
    uint releaseID;
    /// @dev set of member addresses.
    EnumerableSet.AddressSet members;
  }

  struct Release {
    /// @dev ID of the parent project.
    uint projectID;
    /// @dev ID of the previous release.
    uint releaseID;
    /// @dev set of signer addresses.
    EnumerableSet.AddressSet signers;
  }

  /// @dev mapping of account ID to account
  mapping(uint => Account) private accountByID;
  /// @dev mapping of project ID to project
  mapping(uint => Project) private projectByID;
  /// @dev mapping of release ID to release
  mapping(uint => Release) private releaseByID;
  /// @dev mapping of account, project, and release ID to meta URI
  mapping(uint => string) public metaByID;

  /// @dev version of BaseRelayRecipient this contract implements
  string public override versionRecipient = "2.2.3";
  /// @dev address of contract owner
  address payable public owner;
  /// @dev account name claim fee
  uint public claimFee;

  /// Creates a Valist Registry contract.
  ///
  /// @param _forwarder Address of meta transaction forwarder.
  constructor(address _forwarder) {
    owner = payable(msg.sender);
    _setTrustedForwarder(_forwarder);
  }

  /// Creates an account with the given members.
  ///
  /// @param _name Unique name used to identify the account.
  /// @param _metaURI URI of the account metadata.
  /// @param _members List of members to add to the account.
  function createAccount(
    string calldata _name,
    string calldata _metaURI,
    address[] calldata _members
  )
    public
    payable
  {
    require(msg.value >= claimFee, "err-value");
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(_name).length > 0, "err-empty-name");
    require(_members.length > 0, "err-empty-members");

    uint accountID = generateID(block.chainid, _name);
    require(bytes(metaByID[accountID]).length == 0, "err-name-claimed");

    metaByID[accountID] = _metaURI;
    emit AccountCreated(accountID, _name, _metaURI, _msgSender());

    for (uint i = 0; i < _members.length; ++i) {
      accountByID[accountID].members.add(_members[i]);
      emit AccountMemberAdded(accountID, _members[i], _msgSender());
    }

    Address.sendValue(owner, msg.value);
  }
  
  /// Creates a new project. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account to create the project under.
  /// @param _name Unique name used to identify the project.
  /// @param _metaURI URI of the project metadata.
  /// @param _members Optional list of members to add to the project.
  function createProject(
    uint _accountID,
    string calldata _name,
    string calldata _metaURI,
    address[] calldata _members
  )
    public
  {
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(_name).length > 0, "err-empty-name");

    uint projectID = generateID(_accountID, _name);
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(bytes(metaByID[projectID]).length == 0, "err-name-claimed");

    metaByID[projectID] = _metaURI;
    projectByID[projectID].accountID = _accountID;
    emit ProjectCreated(_accountID, projectID, _name, _metaURI, _msgSender());

    for (uint i = 0; i < _members.length; ++i) {
      projectByID[projectID].members.add(_members[i]);
      emit ProjectMemberAdded(projectID, _members[i], _msgSender());
    }
  }

  /// Creates a new release. Requires the sender to be a member of the project.
  ///
  /// @param _projectID ID of the project create the release under.
  /// @param _name Unique name used to identify the release.
  /// @param _metaURI URI of the project metadata.
  function createRelease(
    uint _projectID,
    string calldata _name,
    string calldata _metaURI
  )
    public
  {
    require(bytes(_name).length > 0, "err-empty-name");
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");

    uint releaseID = generateID(_projectID, _name);
    require(bytes(metaByID[releaseID]).length == 0, "err-name-claimed");

    uint accountID = getProjectAccountID(_projectID);
    require(
      isProjectMember(_projectID, _msgSender()) ||
      isAccountMember(accountID, _msgSender()),
      "err-not-member"
    );

    uint previousID = projectByID[_projectID].releaseID;
    projectByID[_projectID].releaseID = releaseID;

    metaByID[releaseID] = _metaURI;
    releaseByID[releaseID].releaseID = previousID;
    releaseByID[releaseID].projectID = _projectID;
    emit ReleaseCreated(_projectID, releaseID, _name, _metaURI, _msgSender());
  }

  /// Approve the release by adding the sender's address to the approvers list.
  ///
  /// @param _releaseID ID of the release.
  function approveRelease(uint _releaseID) public {
    require(bytes(metaByID[_releaseID]).length > 0, "err-not-exist");
    require(!releaseByID[_releaseID].signers.contains(_msgSender()), "err-member-exist");

    releaseByID[_releaseID].signers.add(_msgSender());
    emit ReleaseApproved(_releaseID, _msgSender());
  }

  /// Revoke a release signature by removing the sender's address from the approvers list.
  ///
  /// @param _releaseID ID of the release.
  function revokeRelease(uint _releaseID) public {
    require(bytes(metaByID[_releaseID]).length > 0, "err-not-exist");
    require(releaseByID[_releaseID].signers.contains(_msgSender()), "err-member-exist");

    releaseByID[_releaseID].signers.remove(_msgSender());
    emit ReleaseRevoked(_releaseID, _msgSender());
  }

  /// Add a member to the account. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account.
  /// @param _address Address of member.
  function addAccountMember(uint _accountID, address _address) public {
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(!isAccountMember(_accountID, _address), "err-member-exist");

    accountByID[_accountID].members.add(_address);
    emit AccountMemberAdded(_accountID, _address, _msgSender());
  }

  /// Remove a member from the account. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account.
  /// @param _address Address of member.
  function removeAccountMember(uint _accountID, address _address) public {
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(isAccountMember(_accountID, _address), "err-member-not-exist");

    accountByID[_accountID].members.remove(_address);
    emit AccountMemberRemoved(_accountID, _address, _msgSender());
  }

  /// Add a member to the project. Requires the sender to be a member of the parent account.
  ///
  /// @param _projectID ID of the project.
  /// @param _address Address of member.
  function addProjectMember(uint _projectID, address _address) public {
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");
    require(!isProjectMember(_projectID, _address), "err-member-exist");

    uint accountID = getProjectAccountID(_projectID);
    require(isAccountMember(accountID, _msgSender()), "err-not-member");

    projectByID[_projectID].members.add(_address);
    emit ProjectMemberAdded(_projectID, _address, _msgSender());
  }

  /// Remove a member from the project. Requires the sender to be a member of the parent account.
  ///
  /// @param _projectID ID of the project.
  /// @param _address Address of member.
  function removeProjectMember(uint _projectID, address _address) public {
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");
    require(isProjectMember(_projectID, _address), "err-member-not-exist"); 

    uint accountID = getProjectAccountID(_projectID);
    require(isAccountMember(accountID, _msgSender()), "err-not-member");

    projectByID[_projectID].members.remove(_address);
    emit ProjectMemberRemoved(_projectID, _address, _msgSender());   
  }

  /// Sets the account metadata URI. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account.
  /// @param _metaURI Metadata URI.
  function setAccountMetaURI(uint _accountID, string calldata _metaURI) public {
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(bytes(metaByID[_accountID]).length > 0, "err-not-exist");

    metaByID[_accountID] = _metaURI;
    emit AccountUpdated(_accountID, _metaURI, _msgSender());
  }

  /// Sets the project metadata URI. Requires the sender to be a member of the parent account.
  ///
  /// @param _projectID ID of the project.
  /// @param _metaURI Metadata URI.
  function setProjectMetaURI(uint _projectID, string calldata _metaURI) public {
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");

    uint accountID = getProjectAccountID(_projectID);
    require(isAccountMember(accountID, _msgSender()), "err-not-member");

    metaByID[_projectID] = _metaURI;
    emit ProjectUpdated(_projectID, _metaURI, _msgSender());
  }

  /// Generates account, project, or release ID.
  ///
  /// @param _parentID ID of the parent account or project. Use `block.chainid` for accounts.
  /// @param _name Name of the account, project, or release.
  function generateID(uint _parentID, string calldata _name) public pure returns (uint) {
    return uint(keccak256(abi.encodePacked(_parentID, keccak256(bytes(_name)))));
  }

  /// Returns true if the address is a member of the team.
  ///
  /// @param _accountID ID of the account.
  /// @param _member Address of member.
  function isAccountMember(uint _accountID, address _member) public view returns (bool) {
    return accountByID[_accountID].members.contains(_member);
  }

  /// Returns true if the address is a member of the project.
  ///
  /// @param _projectID ID of the project.
  /// @param _member Address of member.
  function isProjectMember(uint _projectID, address _member) public view returns (bool) {
    return projectByID[_projectID].members.contains(_member);
  }

  /// Returns true if the address is a signer of the release.
  ///
  /// @param _releaseID ID of the release.
  /// @param _signer Address of the signer.
  function isReleaseSigner(uint _releaseID, address _signer) public view returns (bool) {
    return releaseByID[_releaseID].signers.contains(_signer);
  }

  /// Returns a list of account members.
  ///
  /// @param _accountID ID of the account.
  function getAccountMembers(uint _accountID) public view returns (address[] memory) {
    return accountByID[_accountID].members.values();
  }

  /// Returns a list of project members.
  ///
  /// @param _projectID ID of the project.
  function getProjectMembers(uint _projectID) public view returns (address[] memory) {
    return projectByID[_projectID].members.values();
  }

  /// Returns a list of release signers.
  ///
  /// @param _releaseID ID of the release.
  function getReleaseSigners(uint _releaseID) public view returns (address[] memory) {
    return releaseByID[_releaseID].signers.values();
  }

  /// Returns the parent account ID for the project.
  ///
  /// @param _projectID ID of the project.
  function getProjectAccountID(uint _projectID) public view returns (uint) {
    return projectByID[_projectID].accountID;
  }

  /// Returns the parent project ID for the release.
  /// 
  /// @param _releaseID ID of the release.
  function getReleaseProjectID(uint _releaseID) public view returns (uint) {
    return releaseByID[_releaseID].projectID;
  }

  /// Returns the latest release ID for the project.
  ///
  /// @param _projectID ID of the project.
  function getLatestReleaseID(uint _projectID) public view returns (uint) {
    return projectByID[_projectID].releaseID;
  }

  /// Returns the previous release ID for the release.
  ///
  /// @param _releaseID ID of the release.
  function getPreviousReleaseID(uint _releaseID) public view returns (uint) {
    return releaseByID[_releaseID].releaseID;
  }

  /// Sets the owner address. Owner only.
  ///
  /// @param _owner Address of the new owner.
  function setOwner(address payable _owner) public onlyOwner {
    owner = _owner;
  }

  /// Sets the account claim fee. Owner only.
  ///
  /// @param _claimFee Claim fee amount in wei.
  function setClaimFee(uint _claimFee) public onlyOwner {
    claimFee = _claimFee;
  }

  /// Sets the trusted forward address. Owner only.
  ///
  /// @param _forwarder Address of meta transaction forwarder.
  function setTrustedForwarder(address _forwarder) public onlyOwner {
    _setTrustedForwarder(_forwarder);
  }

  /// Modifier that ensures only the owner can call a function.
  modifier onlyOwner() {
    require(owner == _msgSender(), "caller is not the owner");
    _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";