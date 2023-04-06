pragma solidity ^0.8.4;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./RedditCollectibleAvatarsRouter.sol";
import "./GlobalConfig.sol";

/**
 *
 * An ERC1155-based NFT contract which includes support for partitioned (bucketed) IPFS routes.
 *
 * This contract is a standard ERC1155 contract with modifications to make the contract
 * allow for a dynamically-sized collection of NFTs to be minted on it over a prolonged
 * period of time.
 *
 * These differences are:
 *
 *   1. The contact leverages ownership of the contract (OwnableUpgradeable), however it also
 *      allows for the NFT minting method (`mintNFT`) to be only executable via a
 *      `minter` wallet.
 *
 *   2. The `uri` mechanism of the contract defers to a sub contract which acts as
 *      a router to determine what IPFS directory CID value will be used for the uri
 *      of the provided tokenId.
 *
 * While the behavior of "minting over a prolonged period of time" is something that isn't
 * common in the crypto space, the intent with this contract is to only allow for minting
 * to occur until the collection is complete. Once complete, ownership and minting on the
 * contract will be relinquished.
 *
 *
 * ## How the minting logic works
 *
 * The `mintNFT` method works much the same as any public minting function on an ERC721 or
 * ERC1155 contract. The main difference here is that only the `minter` wallet can execute
 * this method instead of the `owner` of the contract. The `minter` wallet is a standard
 * 0x0 address that can be set via the `setMinter()` method and it can be the same as the
 * owner of the wallet.
 *
 * The reason why this contract makes use of a minter/owner split is so that the deployment
 * and configuration of contract is done via an offline wallet while minting of new NFTs is
 * done using a wallet that is distributed on the backend.
 *
 *
 * ## How the `uri` assembling works
 *
 * With a standard ERC1155 contract, all NFT URI values (which point to their respective
 * metadata files) are bound to a single URI structure with a consistent domain/path prefix.
 * This design choice is done as such by ERC1155 to optimize storage of NFT entries within
 * the contract (since no URL values need to be stored).
 *
 * While this feature of ERC1155 works well, it doesn't allow for a collection of NFTs to
 * be extended without some kind of variable change to the prefix of the `uri`. In other
 * words, you would need to introduce a setter/getter value to change the IPFS prefix if
 * new NFT metadata files are introduced into the collection.
 *
 * The contract below changes how the `uri` method works by delegating the IPFS CID resolution
 * logic to a "router" contract. The router contract will execute its own logic given the `ID`
 * value and return the correct IPFS CID based on what IPFS directory that `ID` entry was
 * registered.
 *
 * See [RedditCollectibleAvatarsRouter.sol] for more info.
 *
 *
 * ## Operator Filtering
 *
 * According to [Operator Filtering](https://github.com/ProjectOpenSea/operator-filter-registry#creator-earnings-enforcement),
 * collection is eligible for creator earnings only if it restricts transfers for
 * [non-eligiable operators](https://github.com/ProjectOpenSea/operator-filter-registry#filtered-addresses).
 * This contract enforces the filtering of transfer operators configured by [GlobalConfig.sol].
 *
 */
error RedditCollectibleAvatars__NotMinter();
error RedditCollectibleAvatars__NotReddit();
error RedditCollectibleAvatars__InvalidArg_TokenAndAddressLengthMismatch();
error RedditCollectibleAvatars__InvalidArg_AddressZero();
error RedditCollectibleAvatars__InvalidArg_SellerFeeBasisPoints(uint16 basisPoints);
error RedditCollectibleAvatars__AlreadyMinted(uint256 tokenId);
error RedditCollectibleAvatars__NotImplemented();
/// @dev Following original Operator Filtering error signature to ensure compatibility
error OperatorNotAllowed(address operator);

contract RedditCollectibleAvatars is ERC1155Upgradeable, OwnableUpgradeable, BaseRelayRecipient, IERC2981 {
  using AddressUpgradeable for address;

  struct RoyaltyInfo {
    address recipient;
    uint16 basisPoints;
  }

  event RouterAddressUpdated(address current, address previous);
  event TrustedForwarderUpdated(address current, address previous);
  event ContractURIUpdated(string current, string previous);
  event RoyaltiesUpdated(address currentRecipient, uint16 currentBasisPoints, address previousRecipient, uint16 previousBasisPoints);
  event ConfigUpdated(address current, address previous);

  // ------------------------------------------------------------------------------------
  // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

  /// @dev Required by BaseRelayRecipient
  string public override versionRecipient;

  /**
   * @dev Reference to the "router contract" that the `uri` method will call
   * See [RedditCollectibleAvatarsRouter] for more info.
   */
  RedditCollectibleAvatarsRouter public _router;
  RoyaltyInfo public royalties;

  string private _contractURI;

  /// @dev Mapping from token ID to owner
  mapping(uint256 => address) internal _owners;

  /**
  * @dev Global configuration for all collections
  * See [GlobalConfig.sol] for more info.
  */
  GlobalConfig public config;

  // END OF VARS
  // ------------------------------------------------------------------------------------

  modifier onlyMinter() {
    address sender = _msgSender();
    GlobalConfig conf = config;
    if (sender != conf.minter() && sender != conf.prevMinter()) {
      revert RedditCollectibleAvatars__NotMinter();
    }
    _;
  }

  modifier onlyReddit() {
    if (_msgSender() != config.owner()) {
      revert RedditCollectibleAvatars__NotReddit();
    }
    _;
  }

  modifier onlyAllowedOperator(address from) {
    // Allow spending tokens from addresses with balance
    // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    // from an EOA.
    address sender = _msgSender();
    if (sender != from) {
      _checkFilterOperator(sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) {
    _checkFilterOperator(operator);
    _;
  }

  function _checkFilterOperator(address operator) internal view {
    // Currently, this function will revert rather than return false,
    // but to eliminate misuse in the future while keeping the
    // same logic as the original filter implementation
    if (!config.isOperatorAllowed(operator)) {
      revert OperatorNotAllowed(operator);
    }
  }

  function initialize(
    RoyaltyInfo calldata _royalties,
    address routerAddress,
    address owner,
    address forwarder,
    address globalConfig,
    string calldata contracturi
  ) public initializer {
    __ERC1155_init("_");

    _updateRoyalties(_royalties);
    _setRouterAddress(routerAddress);
    _updateTrustedForwarder(forwarder);
    _setConfig(globalConfig);
    _contractURI = contracturi;

    OwnableUpgradeable.__Ownable_init();
    if (owner != _msgSender()) {
      OwnableUpgradeable.transferOwnership(owner);
    }

    versionRecipient = "1.0.0";
  }

  /**
   * OZ ERC1155 Function Overrides
   */

  /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
      require(account != address(0), "ERC1155: balance query for the zero address");
      return _owners[id] == account ? 1 : 0;
  }

  /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      The added modifier ensures that the operator is allowed by the operator filter.
     */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the operator filter.
     */
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, id, amount, data);
  }

  /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the operator filter.
     */
  function safeBatchTransferFrom(
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
      super.safeBatchTransferFrom(from, to, ids, amounts, data);
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
  ) internal virtual override {
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();
    uint256[] memory ids = __asSingletonArray(id);
    uint256[] memory amounts = __asSingletonArray(amount);

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    require(_owners[id] == from && amount < 2, "ERC1155: insufficient balance for transfer");

    // The ERC1155 spec allows for transferring zero tokens,
    // but only modify ownership if amount == 1
    if (amount == 1) {
      _owners[id] = to;
    }

    emit TransferSingle(operator, from, to, id, amount);

    _afterTokenTransfer(operator, from, to, ids, amounts, data);

    __doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function __doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function __asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
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
  ) internal virtual override {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      require(_owners[id] == from && amount < 2, "ERC1155: insufficient balance for transfer");
      // The ERC1155 spec allows for transferring zero tokens,
      // but only modify ownership if amount == 1
      if (amount == 1) {
        _owners[id] = to;
      }
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    __doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function __doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
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
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    if(_owners[id] != address(0)) {
      revert RedditCollectibleAvatars__AlreadyMinted(id);
    }

    address operator = _msgSender();

    _owners[id] = to;

    emit TransferSingle(operator, address(0), to, id, 1);

    __doSafeTransferAcceptanceCheck(operator, address(0), to, id, 1, data);
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
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) internal virtual override {
    revert RedditCollectibleAvatars__NotImplemented();
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
    address,
    uint256,
    uint256
  ) internal virtual override {
    revert RedditCollectibleAvatars__NotImplemented();
  }

  /**
    * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
    *
    * Requirements:
    *
    * - `ids` and `amounts` must have the same length.
    */
  function _burnBatch(
    address,
    uint256[] memory,
    uint256[] memory
  ) internal virtual override {
    revert RedditCollectibleAvatars__NotImplemented();
  }

  /**
   * IPFS Routing Functions
   */

  function setRouterAddress(address routerAddress) external onlyReddit {
    _setRouterAddress(routerAddress);
  }

  /**
   * Sets the contract address for the router contract (which is used to deterine the IPFS CID for each ID entry)
   */
  function _setRouterAddress(address routerAddress) internal {
    if (routerAddress == address(0)){
      revert RedditCollectibleAvatars__InvalidArg_AddressZero();
    }
    emit RouterAddressUpdated({current: routerAddress, previous: address(_router)});
    _router = RedditCollectibleAvatarsRouter(routerAddress);
  }

  /**
   * Minting Functions
   */

  /**
   * Mints a NFT on the contract (node that only the `minter` wallet can execute this action)
   */
  function mintNFT(uint256 tokenId, address ownerId) public onlyMinter {
    _mint(ownerId, tokenId, "");
  }


  /**
   * Returns a URL for the provided `id` value.
   *
   * This method will call the "router" contract to determine what the cid value of the
   * IPFS url will be for the provided `id` entry.
   */
  function uri(uint256 id) public view override returns (string memory) {
    string memory cid = _router.lookup(id);
    return string(
      abi.encodePacked(
        "ipfs://",
        cid,
        "/",
        Strings.toString(id),
        ".json"
      )
    );
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function updateContractURI(string calldata contracturi) external onlyReddit {
    emit ContractURIUpdated(contracturi, _contractURI);
    _contractURI = contracturi;
  }

  function batchMint(uint256[] calldata tokenIds, address[] calldata ownerIds) public onlyMinter {
    if (tokenIds.length != ownerIds.length) {
      revert RedditCollectibleAvatars__InvalidArg_TokenAndAddressLengthMismatch();
    }
    for (uint256 i=0; i < tokenIds.length; ++i) {
      _mint(ownerIds[i], tokenIds[i], "");
    }
  }

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
      receiver = royalties.recipient;
      royaltyAmount = (_salePrice * royalties.basisPoints) / 10000;
  }

  function updateRoyalties(RoyaltyInfo calldata _royalties) external onlyReddit {
    _updateRoyalties(_royalties);
  }

  function _updateRoyalties(RoyaltyInfo calldata _royalties) internal {
    if(_royalties.basisPoints > 10000){
      revert RedditCollectibleAvatars__InvalidArg_SellerFeeBasisPoints(_royalties.basisPoints);
    }
    emit RoyaltiesUpdated(_royalties.recipient, _royalties.basisPoints, royalties.recipient, royalties.basisPoints);
    royalties = _royalties;
  }

  function updateTrustedForwarder(address forwarder) external onlyReddit {
    _updateTrustedForwarder(forwarder);
  }

  function _updateTrustedForwarder(address forwarder) internal {
    emit TrustedForwarderUpdated(forwarder, trustedForwarder());
    _setTrustedForwarder(forwarder);
  }

  function setConfig(address newConfig) external onlyReddit {
    _setConfig(newConfig);
  }

  function _setConfig(address newConfig) internal {
    if (newConfig == address(0)){
      revert RedditCollectibleAvatars__InvalidArg_AddressZero();
    }
    emit ConfigUpdated({current: newConfig, previous: address(config)});
    config = GlobalConfig(newConfig);
  }

  function _msgSender() internal view override(BaseRelayRecipient, ContextUpgradeable) returns (address ret) {
    ret = BaseRelayRecipient._msgSender();
  }

  function _msgData() internal view override(BaseRelayRecipient, ContextUpgradeable) returns (bytes calldata ret) {
    ret = BaseRelayRecipient._msgData();
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, IERC165) returns (bool) {
    return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
  }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 *
 * A custom contract that acts as a CID registry for IPFS directories.
 *
 * This contract is a delegate contract used by the [RedditCollectibleAvatars] contract
 * for its `uri` contruction code. The purpose of it is to determine what IPFS CID
 * value to use for a given NFT ID.
 *
 * The reason why this code exists is to allow the RedditCollectibleAvatars ERC1155 contract
 * to allow for NFTs to be registered even if the underlying NFT collection expands in size.
 * This is usually not possible with a ERC1155 contract, unless IPFS isn't used (i.e. you
 * use your own domain to host the NFT metadata). Because IPFS directories (i.e. where the CID
 * reflects the contents of a directory) cannot be updated without the CID changing, this router
 * will handle that CID changing behavior throughout the collection being published. Once the
 * NFT collection is complete, then the ownership of this contract and the parent
 * RedditCollectibleAvatars contract will be relinquished so that the NFT collection stays immutable.
 *
 * ## How the "routing" works
 * This contract allows for two things:
 *   1. Registration of new routes
 *   2. Resolution of routes via the provided ID
 *
 * When the contract is instantiated for the first time, it will require a `itemsPerRoute` value
 * which specifies how many IPFS metadata files will be stored in each IPFS directory. Then,
 * when a route is registered (via the `registerRoute()` method), the provided `index` value is
 * used to reference which IPFS directory the route lives in (and what the `cid` value is).
 *
 * With routes registered, when the `lookup()` method is called, it can determine what directory
 * (or route) the provided `itemIndex` lives in (this happens by diving the `itemIndex` by
 * the `itemsPerRoute` value). Once determined, the CID value for that `itemIndex` is returned.
 *
 * The parent contract (RedditCollectibleAvatars) then uses the CID value and places that into the
 * IPFS URI that it assembles within the `uri()` method.
 *
 * ## What happens if the routes collection expands?
 * When instantiated, the contract below will pre-fill an array of routes (for performance
 * reasons) so that it doesn't have to expand the size of the array everytime a new route is
 * filled. If an when a new route is added that goes beyond the pre-fill size, the registration
 * code will expand the array by inserting additional cells up until the new route index.
 *
 */

error RedditCollectibleAvatarsRouter__UndefinedRouteForItemIndex(uint256 itemIndex, uint totalRoutes, uint256 itemsPerRoute);
error RedditCollectibleAvatarsRouter__NotRouteRegisterer();
error RedditCollectibleAvatarsRouter__InvalidArg_AddressZero();
error RedditCollectibleAvatarsRouter__InvalidArg_ItemsPerRouteZero();

contract RedditCollectibleAvatarsRouter is OwnableUpgradeable {
  event RouteRegistered(uint256 index, string cid);
  event RouteRegistererUpdated(address current, address previous);
  event ItemsPerRouteUpdated(uint256 current, uint256 previous);

  mapping(uint256 => string) public routes;
  uint256 internal _totalRoutes;
  uint256 public itemsPerRoute;
  address public routeRegisterer;

  /**
   * @param _itemsPerRoute used to specify how many entries will live in each route (in each IPFS dir)
   */
  function initialize(uint256 _itemsPerRoute, address _routeRegisterer, address owner) public initializer {
    itemsPerRoute = _itemsPerRoute;
    routeRegisterer = _routeRegisterer;
  
    OwnableUpgradeable.__Ownable_init();
    if (owner != _msgSender()) {
      OwnableUpgradeable.transferOwnership(owner);
    }
  }

  /**
   * Registers a new route in the contract
   *
   * @param index the index of the route (IFPS directory index)
   * @param cid the IPFS cid value for that route (IPFS directory)
   */
  function registerRoute(uint256 index, string calldata cid) public {
    if (_msgSender() != routeRegisterer) {
      revert RedditCollectibleAvatarsRouter__NotRouteRegisterer();
    }
    if (bytes(routes[index]).length == 0){
      _totalRoutes += 1;
    }
    if (bytes(cid).length == 0){
      _totalRoutes -= 1;
    }
    routes[index] = cid;
    emit RouteRegistered(index, cid);
  }

  /**
   * Returns the CID value for the given `itemIndex` by looking up the associated route
   *
   * @param itemIndex the index of the item (the NFT token ID)
   */
  function lookup(uint256 itemIndex) public view returns (string memory) {
    uint256 index = itemIndex / itemsPerRoute;
    string memory cid = routes[index];
    if (bytes(cid).length == 0) {
      revert RedditCollectibleAvatarsRouter__UndefinedRouteForItemIndex({itemIndex: itemIndex, totalRoutes: _totalRoutes, itemsPerRoute: itemsPerRoute});
    }
    return cid;
  }

  /**
   * Returns how many routes have been registered
   *
   * Note that this value is effected by the `initialRoutesCount` value as well.
   */
  function getTotalRoutes() public view returns (uint) {
    return _totalRoutes;
  }

  /**
   * Sets the `routeRegisterer` wallet address on the contract (note that only the `owner` wallet can execute this action)
   */
  function setRouteRegisterer(address account) public onlyOwner {
    if (account == address(0)){
      revert RedditCollectibleAvatarsRouter__InvalidArg_AddressZero();
    }
    emit RouteRegistererUpdated({current: account, previous: routeRegisterer});
    routeRegisterer = account;
  }

  /**
   * Sets `itemsPerRoute` (note that only the `owner` wallet can execute this action)
   * This function should be used cautiously. This redistributes tokenIDs to potentially different CIDs.
   */
  function setItemsPerRoute(uint256 _itemsPerRoute) public onlyOwner {
    if (_itemsPerRoute == 0){
      revert RedditCollectibleAvatarsRouter__InvalidArg_ItemsPerRouteZero();
    }
    emit ItemsPerRouteUpdated({current: _itemsPerRoute, previous: itemsPerRoute});
    itemsPerRoute = _itemsPerRoute;
  }
}

/*
    SPDX-License-Identifier: Apache-2.0
    Copyright 2023 Reddit, Inc
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

error GlobalConfig__ZeroAddress();
error GlobalConfig__TokenIsNotAuthorized();
error GlobalConfig__TokenAlreadyAuthorized();
error GlobalConfig__AddressIsNotFiltered(address operator);
error GlobalConfig__AddressAlreadyFiltered(address operator);
error GlobalConfig__CodeHashIsNotFiltered(bytes32 codeHash);
error GlobalConfig__CodeHashAlreadyFiltered(bytes32 codeHash);
error GlobalConfig__CannotFilterEOAs();
/// @dev Following original Operator Filtering error signature to ensure compatibility
error AddressFiltered(address filtered);
/// @dev Following original Operator Filtering error signature to ensure compatibility
error CodeHashFiltered(address account, bytes32 codeHash);

/**
 * @title GlobalConfig
 * @notice One contract that maintains config values that other contracts read from - so if you need to change, only need to change here.
 * @dev Used by the [Splitter.sol] and [RedditCollectibleAvatars.sol].
 */
contract GlobalConfig is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;

  event RedditRoyaltyAddressUpdated(address indexed oldAddress, address indexed newAddress);
  event AuthorizedERC20sUpdated(bool indexed removed, address indexed token, uint length);
  event FilteredOperatorUpdated(bool indexed filtered, address indexed operator, uint length);
  event FilteredCodeHashUpdated(bool indexed filtered, bytes32 indexed codeHash, uint length);
  event MinterUpdated(address current, address prevMinter, address removedMinter);
  event PreviousMinterCleared(address removedMinter);

  /// @dev Initialized accounts have a nonzero codehash (see https://eips.ethereum.org/EIPS/eip-1052)
  bytes32 constant private EOA_CODEHASH = keccak256("");

  // ------------------------------------------------------------------------------------
  // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

  /// @dev Referenced by the royalty splitter contract to withdraw reddit's share of NFT royalties
  address public redditRoyalty;

  /// @dev Set of ERC20 tokens authorized for royalty withdrawal by Reddit in the splitter contract
  EnumerableSet.AddressSet private authorizedERC20s;

  /// @dev Set of filtered (restricted/blocked) operator addresses
  EnumerableSet.AddressSet private filteredOperators;
  /// @dev Set of filtered (restricted/blocked) code hashes
  EnumerableSet.Bytes32Set private filteredCodeHashes;

  /// @dev Wallet address of the `minter` wallet
  address public minter;
  /// @dev Wallet address of the previous `minter` wallet to have no downtime during minter rotation
  address public prevMinter;

  // END OF VARS
  // ------------------------------------------------------------------------------------

  constructor(
    address _owner, 
    address _redditRoyalty, 
    address _minter,
    address[] memory _authorizedERC20s,
    address[] memory _filteredOperators,
    bytes32[] memory _filteredCodeHashes
  ) {
    _updateRedditRoyaltyAddress(_redditRoyalty);
    _updateMinter(_minter);

    for (uint i=0; i < _authorizedERC20s.length;) {
      authorizedERC20s.add(_authorizedERC20s[i]);
      unchecked { ++i; }
    }

    for (uint i=0; i < _filteredOperators.length;) {
      filteredOperators.add(_filteredOperators[i]);
      unchecked { ++i; }
    }

    for (uint i=0; i < _filteredCodeHashes.length;) {
      filteredCodeHashes.add(_filteredCodeHashes[i]);
      unchecked { ++i; }
    }

    if (_owner != _msgSender()) {
      Ownable.transferOwnership(_owner);
    }
  }

  /// @notice Update address of Reddit royalty receiver
  function updateRedditRoyaltyAddress(address newRedditAddress) external onlyOwner {
    _updateRedditRoyaltyAddress(newRedditAddress);
  }

  /// @notice Delete an authorized ERC20 token
  function deleteAuthorizedToken(address token) external onlyOwner {
    emit AuthorizedERC20sUpdated(true, token, authorizedERC20s.length() - 1);
    if (!authorizedERC20s.remove(token)) {
      revert GlobalConfig__TokenIsNotAuthorized();
    }
  }

  /// @notice Add an authorized ERC20 token
  function addAuthorizedToken(address token) external onlyOwner {
    emit AuthorizedERC20sUpdated(false, token, authorizedERC20s.length() + 1);
    if (!authorizedERC20s.add(token)) {
      revert GlobalConfig__TokenAlreadyAuthorized();
    }
  }

  /// @notice Array of authorized ERC20 tokens
  function authorizedERC20sArray() external view returns (address[] memory) {
    return authorizedERC20s.values();
  }

  /// @notice Checks if ERC20 token is authorized
  function authorizedERC20(address token) external view returns (bool) {
    return authorizedERC20s.contains(token);
  }

  /// @notice Add a filtered (restricted) operator address
  function addFilteredOperator(address operator) external onlyOwner {
    emit FilteredOperatorUpdated(true, operator, filteredOperators.length() + 1);
    if (!filteredOperators.add(operator)) {
      revert GlobalConfig__AddressAlreadyFiltered(operator);
    }
  }

  /// @notice Delete a filtered (restricted) operator address
  function deleteFilteredOperator(address operator) external onlyOwner {
    emit FilteredOperatorUpdated(false, operator, filteredOperators.length() - 1);
    if (!filteredOperators.remove(operator)) {
      revert GlobalConfig__AddressIsNotFiltered(operator);
    }
  }

  /// @notice Add a filtered (restricted) code hash
  /// @dev This will allow adding the bytes32(0) codehash, which could result in unexpected behavior,
  ///      since calling `isCodeHashFiltered` will return true for bytes32(0), which is the codeHash of any
  ///      un-initialized account. Since un-initialized accounts have no code, the registry will not validate
  ///      that an un-initalized account's codeHash is not filtered. By the time an account is able to
  ///      act as an operator (an account is initialized or a smart contract exclusively in the context of its
  ///      constructor), it will have a codeHash of EOA_CODEHASH, which cannot be filtered.
  function addFilteredCodeHash(bytes32 codeHash) external onlyOwner {
    if (codeHash == EOA_CODEHASH) {
      revert GlobalConfig__CannotFilterEOAs();
    }
    emit FilteredCodeHashUpdated(true, codeHash, filteredCodeHashes.length() + 1);
    if (!filteredCodeHashes.add(codeHash)) {
      revert GlobalConfig__CodeHashAlreadyFiltered(codeHash);
    }
  }

  /// @notice Delete a filtered (restricted) code hash
  function deleteFilteredCodeHash(bytes32 codeHash) external onlyOwner {
    if (codeHash == EOA_CODEHASH) {
      revert GlobalConfig__CannotFilterEOAs();
    }
    emit FilteredCodeHashUpdated(false, codeHash, filteredCodeHashes.length() - 1);
    if (!filteredCodeHashes.remove(codeHash)) {
      revert GlobalConfig__CodeHashIsNotFiltered(codeHash);
    }
  } 

  /// @notice Returns true if operator is not filtered, either by address or codeHash.
  /// @dev Will *revert* if an operator or its codehash is filtered with an error that is
  ///      more informational than a false boolean.
  function isOperatorAllowed(address operator) external view returns (bool) {
    if (filteredOperators.contains(operator)) {
      revert AddressFiltered(operator);
    }
    if (operator.code.length > 0) {
      bytes32 codeHash = operator.codehash;
      if (filteredCodeHashes.contains(codeHash)) {
        revert CodeHashFiltered(operator, codeHash);
      }
    }
    return true;
  }

  /**
   * @notice Updates the `minter` wallet address on the contract 
   * (note that only the `owner` wallet can execute this action)
   */
  function updateMinter(address account) public onlyOwner {
    _updateMinter(account);
  }

  function clearPreviousMinter() public onlyOwner {
    emit PreviousMinterCleared({removedMinter: prevMinter});
    prevMinter = address(0);
  }

  function _updateRedditRoyaltyAddress(address newRedditAddress) internal {
    if (newRedditAddress == address(0)) {
      revert GlobalConfig__ZeroAddress();
    }
    emit RedditRoyaltyAddressUpdated(redditRoyalty, newRedditAddress);
    redditRoyalty = newRedditAddress;
  }

  function _updateMinter(address newMinter) internal {
    if (newMinter == address(0)){
      revert GlobalConfig__ZeroAddress();
    }
    emit MinterUpdated({current: newMinter, prevMinter: minter, removedMinter: prevMinter});
    prevMinter = minter;
    minter = newMinter;
  }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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