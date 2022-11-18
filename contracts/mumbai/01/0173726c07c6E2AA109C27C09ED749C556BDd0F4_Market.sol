// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "./AccessPresetPausable.sol";
import "./Certificate.sol";
import "./Errors.sol";
import "./IERC20WithPermit.sol";
import "./IMarket.sol";
import "./Removal.sol";
import "./RestrictedNORI.sol";

import {RemovalsByYearLib, RemovalsByYear} from "./RemovalsByYearLib.sol";
import {RemovalIdLib} from "./RemovalIdLib.sol";
import {UInt256ArrayLib, AddressArrayLib} from "./ArrayLib.sol";

/**
 * @title Nori Inc.'s carbon removal marketplace.
 * @author Nori Inc.
 * @notice Facilitates the exchange of bpNORI tokens for a non-transferrable certificate of carbon removal.
 * @dev Carbon removals are represented by ERC1155 tokens in the Removal contract, where the balance of a
 * given token represents the number of tonnes of carbon that were removed from the atmosphere for that specific
 * removal (different token IDs are used to represent different slices of carbon removal projects and years).
 * This contract facilitates the exchange of bpNORI tokens for ERC721 tokens managed by the Certificate contract.
 * Each of these certificates is a non-transferrable, non-fungible token that owns the specific removal tokens
 * and token balances that comprise the specific certificate for the amount purchased.
 *
 * The market maintains a "priority restricted threshold", which is a configurable threshold of supply that is
 * always reserved to sell only to buyers who have the `ALLOWLIST_ROLE`.  Purchases that would drop supply below
 * this threshold will revert without the correct role.
 *
 * ###### Additional behaviors and features
 *
 * - [Upgradeable](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
 * - [Pausable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable): all external functions that mutate
 * state are pausable.
 * - [Role-based access control](https://docs.openzeppelin.com/contracts/4.x/access-control)
 * - `MARKET_ADMIN_ROLE`: Can set the fee percentage, fee wallet address, and priority restricted threshold.
 * - `ALLOWLIST_ROLE`: Can purchase from priority restricted supply.
 * - [Can receive ERC1155 tokens](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155Receiver)
 *
 * ##### Inherits:
 *
 * - [IERC1155ReceiverUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155Receiver)
 * - [MulticallUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/access)
 * - [ContextUpgradeable](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable)
 * - [ERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#ERC165)
 *
 * ##### Implements:
 *
 * - [IERC1155](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155)
 * - [IAccessControlEnumerable](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 * - [IERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165)
 *
 * ##### Uses:
 *
 * - [EnumerableSetUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet)
 * for `EnumerableSetUpgradeable.UintSet`
 * - [SafeMathUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#SafeMath)
 * - `UInt256ArrayLib` for `uint256[]`
 * - `AddressArrayLib` for `address[]`
 */
contract Market is
  IMarket,
  AccessPresetPausable,
  IERC1155ReceiverUpgradeable,
  MulticallUpgradeable
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using RemovalsByYearLib for RemovalsByYear;
  using UInt256ArrayLib for uint256[];
  using AddressArrayLib for address[];

  /**
   * @notice Keeps track of order of suppliers by address using a circularly doubly linked list.
   * @param previous The address of the previous supplier in the linked list.
   * @param next The address of the next supplier in the linked list.
   */
  struct LinkedListNode {
    address previous;
    address next;
  }

  /**
   * @notice The Removal contract.
   */
  Removal private _removal;

  /**
   * @notice The Certificate contract.
   */
  Certificate private _certificate;

  /**
   * @notice The BridgedPolygonNORI contract.
   */
  IERC20WithPermit private _bridgedPolygonNORI;

  /**
   * @notice The RestrictedNORI contract.
   */
  RestrictedNORI private _restrictedNORI;

  /**
   * @notice Wallet address used for Nori's transaction fees.
   */
  address private _noriFeeWallet;

  /**
   * @notice Percentage of the fee sent to Nori from every transaction.
   */
  uint256 private _noriFeePercentage;

  /**
   * @notice Amount of supply withheld for customers with a priority role.
   */
  uint256 private _priorityRestrictedThreshold;

  /**
   * @notice Address of the supplier currently selling in the queue.
   */
  address private _currentSupplierAddress;

  /**
   * @notice Linked list of active suppliers.
   */
  mapping(address => LinkedListNode) internal _suppliers;

  /**
   * @notice All listed removal tokens in the market.
   * @dev Top-level keys are supplier addresses, `RemovalsByYear` further organizes removals by vintage.
   */
  mapping(address => RemovalsByYear) internal _listedSupply;

  /**
   * @notice Role conferring the ability to configure Nori's fee wallet, the fee percentage, and the priority
   * restricted threshold.
   */
  bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");

  /**
   * @notice Role conferring the ability to purchase supply when inventory is below the priority restricted threshold.
   */
  bytes32 public constant ALLOWLIST_ROLE = keccak256("ALLOWLIST_ROLE");

  /**
   * @notice Emitted on setting of `_priorityRestrictedThreshold`.
   * @param threshold The updated threshold for priority restricted supply.
   */
  event PriorityRestrictedThresholdSet(uint256 threshold);

  /**
   * @notice Emitted on updating the addresses for contracts.
   * @param removal The address of the new Removal contract.
   * @param certificate The address of the new Certificate contract.
   * @param bridgedPolygonNORI The address of the new BridgedPolygonNORI contract.
   * @param restrictedNORI The address of the new RestrictedNORI contract.
   */
  event ContractAddressesRegistered(
    Removal removal,
    Certificate certificate,
    IERC20WithPermit bridgedPolygonNORI,
    RestrictedNORI restrictedNORI
  );

  /**
   * @notice Emitted on setting of `_noriFeeWalletAddress`.
   * @param updatedWalletAddress The updated address of Nori's fee wallet.
   */
  event NoriFeeWalletAddressUpdated(address updatedWalletAddress);

  /**
   * @notice Emitted on setting of `_noriFeePercentage`.
   * @param updatedFeePercentage The updated fee percentage for Nori.
   */
  event NoriFeePercentageUpdated(uint256 updatedFeePercentage);

  /**
   * @notice Emitted when adding a supplier to `_listedSupply`.
   * @param added The supplier that was added.
   * @param next The next of the supplier that was added, updated to point to `addedSupplierAddress` as previous.
   * @param previous the previous address of the supplier that was added, updated to point to `addedSupplierAddress`
   * as next.
   */
  event SupplierAdded(
    address indexed added,
    address indexed next,
    address indexed previous
  );

  /**
   * @notice Emitted when removing a supplier from `_listedSupply`.
   * @param removed The supplier that was removed.
   * @param next The next of the supplier that was removed, updated to point to `previous` as previous.
   * @param previous the previous address of the supplier that was removed, updated to point to `next` as next.
   */
  event SupplierRemoved(
    address indexed removed,
    address indexed next,
    address indexed previous
  );

  /**
   * @notice Emitted when a removal is added to `_listedSupply`.
   * @param id The removal that was added.
   * @param supplierAddress The address of the supplier for the removal.
   */
  event RemovalAdded(uint256 indexed id, address indexed supplierAddress);

  /**
   * @notice Emitted when the call to RestrictedNORI.mint fails during a purchase.
   * For example, due to sending to a contract address that is not an ERC1155Receiver.
   * @param amount The amount of RestrictedNORI in the mint attempt.
   * @param removalId The removal id in the mint attempt.
   */
  event RestrictedNORIMintFailed(
    uint256 indexed amount,
    uint256 indexed removalId
  );

  /**
   * @notice Locks the contract, preventing any future re-initialization.
   * @dev See more [here](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--).
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializes the Market contract.
   * @dev Reverts if `_noriFeeWallet` is not set.
   * @param removal The address of the Removal contract.
   * @param bridgedPolygonNori The address of the BridgedPolygonNORI contract.
   * @param certificate The address of the Certificate contract.
   * @param restrictedNori The address of the RestrictedNORI contract.
   * @param noriFeeWalletAddress The address for Nori's fee wallet.
   * @param noriFeePercentage_ The percentage to take from every transaction. This fee is sent to the address
   * specified by `noriFeeWalletAddress`.
   */
  function initialize(
    Removal removal,
    IERC20WithPermit bridgedPolygonNori,
    Certificate certificate,
    RestrictedNORI restrictedNori,
    address noriFeeWalletAddress,
    uint256 noriFeePercentage_
  ) external initializer {
    if (noriFeeWalletAddress == address(0)) {
      revert NoriFeeWalletZeroAddress();
    }
    __Context_init_unchained();
    __ERC165_init_unchained();
    __Pausable_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Multicall_init_unchained();
    _removal = removal;
    _bridgedPolygonNORI = bridgedPolygonNori;
    _certificate = certificate;
    _restrictedNORI = restrictedNori;
    _noriFeePercentage = noriFeePercentage_;
    _noriFeeWallet = noriFeeWalletAddress;
    _priorityRestrictedThreshold = 0;
    _currentSupplierAddress = address(0);
    _grantRole({role: DEFAULT_ADMIN_ROLE, account: _msgSender()});
    _grantRole({role: ALLOWLIST_ROLE, account: _msgSender()});
    _grantRole({role: MARKET_ADMIN_ROLE, account: _msgSender()});
  }

  /**
   * @notice Releases a removal from the market.
   * @dev This function is called by the Removal contract when releasing removals.
   *
   * ##### Requirements:
   *
   * - Can only be used when this contract is not paused.
   * - The caller must be the Removal contract.
   * @param removalId The ID of the removal to release.
   * @param amount The amount of that removal to release.
   */
  function release(uint256 removalId, uint256 amount)
    external
    override
    whenNotPaused
  {
    if (_msgSender() != address(_removal)) {
      revert SenderNotRemovalContract();
    }
    address supplierAddress = RemovalIdLib.supplierAddress({
      removalId: removalId
    });
    uint256 removalBalance = _removal.balanceOf({
      account: address(this),
      id: removalId
    });
    if (removalBalance == 0) {
      _removeActiveRemoval({
        removalId: removalId,
        supplierAddress: supplierAddress
      });
    }
  }

  /**
   * @notice Register the market contract's asset addresses.
   * @dev Register the Removal, Certificate, BridgedPolygonNORI, and RestrictedNORI contracts so that they
   * can be referenced in this contract. Called as part of the market contract system deployment process.
   *
   * Emits a `ContractAddressesRegistered` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the caller has the `DEFAULT_ADMIN_ROLE` role.
   * - Can only be used when this contract is not paused.
   * @param removal The address of the Removal contract.
   * @param certificate The address of the Certificate contract.
   * @param bridgedPolygonNORI The address of the BridgedPolygonNORI contract.
   * @param restrictedNORI The address of the market contract.
   *
   */
  function registerContractAddresses(
    Removal removal,
    Certificate certificate,
    IERC20WithPermit bridgedPolygonNORI,
    RestrictedNORI restrictedNORI
  ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    _removal = removal;
    _certificate = certificate;
    _bridgedPolygonNORI = bridgedPolygonNORI;
    _restrictedNORI = restrictedNORI;
    emit ContractAddressesRegistered({
      removal: _removal,
      certificate: _certificate,
      bridgedPolygonNORI: _bridgedPolygonNORI,
      restrictedNORI: _restrictedNORI
    });
  }

  /**
   * @notice Sets the current value of the priority restricted threshold, which is the amount of inventory
   * that will always be reserved to sell only to buyers with the `ALLOWLIST_ROLE` role.
   * @dev Emits a `PriorityRestrictedThresholdSet` event.
   *
   * ##### Requirements:
   *
   * - Can only receive ERC1155 tokens from the Removal contract.
   * - Can only be used when this contract is not paused.
   * @param threshold The updated priority restricted threshold
   */
  function setPriorityRestrictedThreshold(uint256 threshold)
    external
    whenNotPaused
    onlyRole(MARKET_ADMIN_ROLE)
  {
    _priorityRestrictedThreshold = threshold;
    emit PriorityRestrictedThresholdSet({threshold: threshold});
  }

  /**
   * @notice Sets the fee percentage (as an integer) which is the percentage of each purchase that will be paid to Nori
   * as the marketplace operator.
   * @dev Emits a `NoriFeePercentageUpdated` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the caller has the `MARKET_ADMIN_ROLE` role.
   * - Can only be used when this contract is not paused.
   * @param noriFeePercentage_ The new fee percentage as an integer.
   */
  function setNoriFeePercentage(uint256 noriFeePercentage_)
    external
    onlyRole(MARKET_ADMIN_ROLE)
    whenNotPaused
  {
    if (noriFeePercentage_ > 100) {
      revert InvalidNoriFeePercentage();
    }
    _noriFeePercentage = noriFeePercentage_;
    emit NoriFeePercentageUpdated({updatedFeePercentage: noriFeePercentage_});
  }

  /**
   * @notice Sets Nori's fee wallet address (as an integer) which is the address to which the
   * marketplace operator fee will be routed during each purchase.
   * @dev Emits a `NoriFeeWalletAddressUpdated` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the caller has the `MARKET_ADMIN_ROLE` role.
   * - Can only be used when this contract is not paused.
   * @param noriFeeWalletAddress The wallet address where Nori collects market fees.
   */
  function setNoriFeeWallet(address noriFeeWalletAddress)
    external
    onlyRole(MARKET_ADMIN_ROLE)
    whenNotPaused
  {
    if (noriFeeWalletAddress == address(0)) {
      revert NoriFeeWalletZeroAddress();
    }
    _noriFeeWallet = noriFeeWalletAddress;
    emit NoriFeeWalletAddressUpdated({
      updatedWalletAddress: noriFeeWalletAddress
    });
  }

  /**
   * @notice Handles the receipt of multiple ERC1155 token types. This function is called at the end of a
   * `safeBatchTransferFrom` after the balances have been updated. To accept the transfer(s), this must return
   * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   * (i.e., 0xbc197c81, or its own function selector).
   * @dev See [IERC1155Receiver](
   * https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155Receiver) for more.
   *
   * ##### Requirements:
   *
   * - Can only receive ERC1155 tokens from the Removal contract.
   * - Can only be used when this contract is not paused.
   * @param ids An array containing the IDs of each removal being transferred (order and length must match values
   * array).
   * @return Returns `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if the
   * transfer is allowed.
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata ids,
    uint256[] calldata,
    bytes calldata
  ) external whenNotPaused returns (bytes4) {
    require(_msgSender() == address(_removal), "Market: Sender not Removal");
    for (uint256 i = 0; i < ids.length; ++i) {
      _addActiveRemoval({removalId: ids[i]});
    }
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @notice Handles the receipt of an ERC1155 token. This function is called at the end of a
   * `safeTransferFrom` after the balances have been updated. To accept the transfer(s), this must return
   * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   * (i.e., 0xf23a6e61, or its own function selector).
   * @dev See [IERC1155Receiver](
   * https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155Receiver) for more.
   *
   * ##### Requirements:
   *
   * - Can only receive an ERC1155 token from the Removal contract.
   * - Can only be used when this contract is not paused.
   * @param id The ID of the received removal.
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if the transfer is allowed.
   */
  function onERC1155Received(
    address,
    address,
    uint256 id,
    uint256,
    bytes calldata
  ) external whenNotPaused returns (bytes4) {
    require(_msgSender() == address(_removal), "Market: Sender not Removal");
    _addActiveRemoval({removalId: id});
    return this.onERC1155Received.selector;
  }

  /**
   * @notice Exchange bpNORI tokens for an ERC721 certificate by transferring ownership of the removals to the
   * certificate.
   * @dev See [ERC20Permit](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Permit) for more.
   * The message sender must present a valid permit to this contract to temporarily authorize this market
   * to transfer the sender's bpNORI to complete the purchase. A certificate is minted in the Certificate contract
   * to the specified recipient and bpNORI is distributed to the supplier of the carbon removal,
   * to the RestrictedNORI contract that controls any restricted bpNORI owed to the supplier, and finally
   * to Nori Inc. as a market operator fee.
   *
   * ##### Requirements:
   *
   * - Can only be used when this contract is not paused.
   * @param recipient The address to which the certificate will be issued.
   * @param amount The total purchase amount in bpNORI. This is the combined total of the number of removals being
   * purchased, and the fee paid to Nori.
   * @param deadline The EIP2612 permit deadline in Unix time.
   * @param v The recovery identifier for the permit's secp256k1 signature.
   * @param r The r value for the permit's secp256k1 signature.
   * @param s The s value for the permit's secp256k1 signature.
   */
  function swap(
    address recipient,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external whenNotPaused {
    uint256 certificateAmount = this
      .calculateCertificateAmountFromPurchaseTotal({purchaseTotal: amount});
    uint256 availableSupply = _removal.getMarketBalance();
    _validateSupply({
      certificateAmount: certificateAmount,
      availableSupply: availableSupply
    });
    _validatePrioritySupply({
      certificateAmount: certificateAmount,
      availableSupply: availableSupply
    });
    (
      uint256 countOfRemovalsAllocated,
      uint256[] memory ids,
      uint256[] memory amounts,
      address[] memory suppliers
    ) = _allocateSupply(certificateAmount);
    _bridgedPolygonNORI.permit({
      owner: _msgSender(),
      spender: address(this),
      value: amount,
      deadline: deadline,
      v: v,
      r: r,
      s: s
    });
    _fulfillOrder({
      certificateAmount: certificateAmount,
      operator: _msgSender(),
      recipient: recipient,
      countOfRemovalsAllocated: countOfRemovalsAllocated,
      ids: ids,
      amounts: amounts,
      suppliers: suppliers
    });
  }

  /**
   * @notice An overloaded version of `swap` that additionally accepts a supplier address and will exchange bpNORI
   * tokens for an ERC721 certificate token and transfers ownership of removal tokens supplied only from the specified
   * supplier to that certificate. If the specified supplier does not have enough carbon removals for sale to fulfill
   * the order the transaction will revert.
   * @dev See [here](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Permit) for more.
   * The message sender must present a valid permit to this contract to temporarily authorize this market
   * to transfer the sender's bpNORI to complete the purchase. A certificate is issued by the Certificate contract
   * to the specified recipient and bpNORI is distributed to the supplier of the carbon removal,
   * to the RestrictedNORI contract that controls any restricted bpNORI owed to the supplier, and finally
   * to Nori Inc. as a market operator fee.
   *
   *
   * ##### Requirements:
   *
   * - Can only be used when this contract is not paused.
   * @param recipient The address to which the certificate will be issued.
   * @param amount The total purchase amount in bpNORI. This is the combined total of the number of removals being
   * purchased, and the fee paid to Nori.
   * @param supplier The only supplier address from which to purchase carbon removals in this transaction.
   * @param deadline The EIP2612 permit deadline in Unix time.
   * @param v The recovery identifier for the permit's secp256k1 signature
   * @param r The r value for the permit's secp256k1 signature
   * @param s The s value for the permit's secp256k1 signature
   */
  function swapFromSupplier(
    address recipient,
    uint256 amount,
    address supplier,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external whenNotPaused {
    uint256 certificateAmount = this
      .calculateCertificateAmountFromPurchaseTotal({purchaseTotal: amount});
    _validatePrioritySupply({
      certificateAmount: certificateAmount,
      availableSupply: _removal.getMarketBalance()
    });
    (
      uint256 countOfRemovalsAllocated,
      uint256[] memory ids,
      uint256[] memory amounts
    ) = _allocateSupplySingleSupplier({
        certificateAmount: certificateAmount,
        supplier: supplier
      });
    address[] memory suppliers = new address[](countOfRemovalsAllocated).fill({
      val: supplier
    });
    _bridgedPolygonNORI.permit({
      owner: _msgSender(),
      spender: address(this),
      value: amount,
      deadline: deadline,
      v: v,
      r: r,
      s: s
    });
    _fulfillOrder({
      certificateAmount: certificateAmount,
      operator: _msgSender(),
      recipient: recipient,
      countOfRemovalsAllocated: countOfRemovalsAllocated,
      ids: ids,
      amounts: amounts,
      suppliers: suppliers
    });
  }

  /**
   * @notice Withdraws a removal to the supplier.
   * @dev Withdraws a removal to the supplier address encoded in the removal ID.
   *
   * ##### Requirements:
   *
   * - Can only be used when this contract is not paused.
   * @param removalId The ID of the removal to withdraw from the market.
   */
  function withdraw(uint256 removalId) external whenNotPaused {
    address supplierAddress = RemovalIdLib.supplierAddress({
      removalId: removalId
    });
    if (_isAuthorizedWithdrawal({owner: supplierAddress})) {
      _removeActiveRemoval({
        removalId: removalId,
        supplierAddress: supplierAddress
      });
      _removal.safeTransferFrom({
        from: address(this),
        to: supplierAddress,
        id: removalId,
        amount: _removal.balanceOf({account: address(this), id: removalId}),
        data: ""
      });
    } else {
      revert UnauthorizedWithdrawal();
    }
  }

  /**
   * @notice Returns the current value of the priority restricted threshold, which is the amount of inventory
   * that will always be reserved to sell only to buyers with the `ALLOWLIST_ROLE` role.
   * @return The threshold of supply allowed for priority customers only.
   */
  function priorityRestrictedThreshold() external view returns (uint256) {
    return _priorityRestrictedThreshold;
  }

  /**
   * @notice Returns the current value of the fee percentage, as an integer, which is the percentage of
   * each purchase that will be paid to Nori as the marketplace operator.
   * @return The percentage of each purchase that will be paid to Nori as the marketplace operator.
   */
  function noriFeePercentage() external view returns (uint256) {
    return _noriFeePercentage;
  }

  /**
   * @notice Returns the address to which the marketplace operator fee will be routed during each purchase.
   * @return The wallet address used for Nori's fees.
   */
  function noriFeeWallet() external view returns (address) {
    return _noriFeeWallet;
  }

  /**
   * @notice Calculates the Nori fee required for a purchase of `amount` tonnes of carbon removals.
   * @param amount The amount of carbon removals for the purchase.
   * @return The amount of the fee for Nori.
   */
  function calculateNoriFee(uint256 amount) external view returns (uint256) {
    return (amount * _noriFeePercentage) / 100;
  }

  /**
   * @notice Calculates the total quantity of bpNORI required to make a purchase of the specified `amount` (in tonnes of
   * carbon removals).
   * @param amount The amount of carbon removals for the purchase.
   * @return The total quantity of bpNORI required to make the purchase, including the fee.
   */
  function calculateCheckoutTotal(uint256 amount)
    external
    view
    returns (uint256)
  {
    return amount + this.calculateNoriFee({amount: amount});
  }

  /**
   * @notice Calculates the quantity of carbon removals being purchased given the purchase total and the
   * percentage of that purchase total that is due to Nori as a transaction fee.
   * @param purchaseTotal The total amount of Nori used for a purchase.
   * @return The amount for the certificate, excluding the transaction fee.
   */
  function calculateCertificateAmountFromPurchaseTotal(uint256 purchaseTotal)
    external
    view
    returns (uint256)
  {
    return (purchaseTotal * 100) / (100 + _noriFeePercentage);
  }

  /**
   * @notice Get the Removal contract address.
   * @return Returns the address of the Removal contract.
   */
  function removalAddress() external view returns (address) {
    return address(_removal);
  }

  /**
   * @notice Get the RestrictedNORI contract address.
   * @return Returns the address of the RestrictedNORI contract.
   */
  function restrictedNoriAddress() external view override returns (address) {
    return address(_restrictedNORI);
  }

  /**
   * @notice Get the Certificate contract address.
   * @return Returns the address of the Certificate contract.
   */
  function certificateAddress() external view returns (address) {
    return address(_certificate);
  }

  /**
   * @notice Get the BridgedPolygonNori contract address.
   * @return Returns the address of the BridgedPolygonNori contract.
   */
  function bridgedPolygonNoriAddress() external view returns (address) {
    return address(_bridgedPolygonNORI);
  }

  /**
   * @notice Get a list of all suppliers which have listed removals in the marketplace.
   * @return suppliers Returns an array of all suppliers that currently have removals listed in the market.
   */
  function getActiveSuppliers()
    external
    view
    returns (address[] memory suppliers)
  {
    uint256 supplierCount;
    if (_suppliers[_currentSupplierAddress].next != address(0)) {
      supplierCount = 1;
      address nextSupplier = _suppliers[_currentSupplierAddress].next;
      while (nextSupplier != _currentSupplierAddress) {
        nextSupplier = _suppliers[nextSupplier].next;
        ++supplierCount;
      }
    }
    address[] memory supplierArray = new address[](supplierCount);
    address currentSupplier = _currentSupplierAddress;
    LinkedListNode memory currentSupplierNode = _suppliers[currentSupplier];
    for (uint256 i = 0; i < supplierCount; ++i) {
      supplierArray[i] = currentSupplier;
      currentSupplier = currentSupplierNode.next;
      currentSupplierNode = _suppliers[currentSupplier];
    }
    return supplierArray;
  }

  /**
   * @notice Get all listed removal IDs for a given supplier.
   * @param supplier The supplier for which to return listed removal IDs.
   * @return removalIds The listed removal IDs for this supplier.
   */
  function getRemovalIdsForSupplier(address supplier)
    external
    view
    returns (uint256[] memory removalIds)
  {
    RemovalsByYear storage removalsByYear = _listedSupply[supplier];
    return removalsByYear.getAllRemovalIds();
  }

  /**
   * @notice Check whether this contract supports an interface.
   * @dev See [IERC165.supportsInterface](
   * https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165-supportsInterface-bytes4-) for more.
   * @param interfaceId The interface ID to check for support.
   * @return Returns true if the interface is supported, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerableUpgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return super.supportsInterface({interfaceId: interfaceId});
  }

  /**
   * @notice Fulfill an order.
   * @dev This function is responsible for paying suppliers, routeing tokens to the RestrictedNORI contract, paying Nori
   * the order fee, updating accounting, and minting the Certificate.
   * @param certificateAmount The total amount for the certificate.
   * @param operator The message sender.
   * @param recipient The recipient of the certificate.
   * @param countOfRemovalsAllocated The number of distinct removal IDs that are involved in fulfilling this order.
   * @param ids An array of removal IDs involved in fulfilling this order.
   * @param amounts An array of amounts being allocated from each corresponding removal token.
   * @param suppliers An array of suppliers.
   */
  function _fulfillOrder(
    uint256 certificateAmount,
    address operator,
    address recipient,
    uint256 countOfRemovalsAllocated,
    uint256[] memory ids,
    uint256[] memory amounts,
    address[] memory suppliers
  ) internal {
    uint256[] memory removalIds = ids.slice({
      from: 0,
      to: countOfRemovalsAllocated
    });
    uint256[] memory removalAmounts = amounts.slice({
      from: 0,
      to: countOfRemovalsAllocated
    });
    uint8 holdbackPercentage;
    uint256 restrictedSupplierFee;
    uint256 unrestrictedSupplierFee;
    for (uint256 i = 0; i < countOfRemovalsAllocated; i++) {
      unrestrictedSupplierFee = removalAmounts[i];
      holdbackPercentage = _removal.getHoldbackPercentage({id: removalIds[i]});
      if (holdbackPercentage > 0) {
        restrictedSupplierFee =
          (unrestrictedSupplierFee * holdbackPercentage) /
          100;
        unrestrictedSupplierFee -= restrictedSupplierFee;
        try
          _restrictedNORI.mint({
            amount: restrictedSupplierFee,
            removalId: removalIds[i]
          })
        {} catch {
          emit RestrictedNORIMintFailed({
            amount: restrictedSupplierFee,
            removalId: removalIds[i]
          });
        }

        _bridgedPolygonNORI.transferFrom({
          from: operator,
          to: address(_restrictedNORI),
          amount: restrictedSupplierFee
        });
      }
      _bridgedPolygonNORI.transferFrom({
        from: operator,
        to: _noriFeeWallet,
        amount: this.calculateNoriFee(removalAmounts[i])
      });
      _bridgedPolygonNORI.transferFrom({
        from: operator,
        to: suppliers[i],
        amount: unrestrictedSupplierFee
      });
    }
    bytes memory data = abi.encode(recipient, certificateAmount);
    _removal.safeBatchTransferFrom({
      from: address(this),
      to: address(_certificate),
      ids: removalIds,
      amounts: removalAmounts,
      data: data
    });
  }

  /**
   * @notice Add a removal to the list of active supply.
   * @dev Adds the specified removal ID to the `_listedSupply` data structure. If this is the supplier's
   * first listed removal, the supplier is also added to the active supplier queue.
   *
   * Emits a `RemovalAdded` event.
   * @param removalId The ID of the removal to add.
   */
  function _addActiveRemoval(uint256 removalId) internal {
    address supplierAddress = RemovalIdLib.supplierAddress({
      removalId: removalId
    });
    _listedSupply[supplierAddress].insert({removalId: removalId});
    if (
      _suppliers[supplierAddress].next == address(0) // If the supplier has sold out our a new supplier has been added
    ) {
      _addActiveSupplier({newSupplierAddress: supplierAddress});
    }
    emit RemovalAdded({id: removalId, supplierAddress: supplierAddress});
  }

  /**
   * @notice Remove a removal from the list of active supply.
   * @dev Removes the specified removal ID from the listed supply data structure. If this is the supplier's last
   * listed removal, the supplier is also removed from the active supplier queue.
   * @param removalId The ID of the removal to remove.
   * @param supplierAddress The address of the supplier of the removal.
   */
  function _removeActiveRemoval(uint256 removalId, address supplierAddress)
    internal
  {
    _listedSupply[supplierAddress].remove({removalId: removalId});
    if (_listedSupply[supplierAddress].isEmpty()) {
      _removeActiveSupplier({supplierToRemove: supplierAddress});
    }
  }

  /**
   * @notice Validates that the listed supply is enough to fulfill the purchase given the priority restricted threshold.
   * @dev Reverts if available stock is being reserved for priority buyers and buyer is not priority.
   * @param certificateAmount The number of carbon removals being purchased.
   * @param availableSupply The amount of listed supply in the market.
   */
  function _validatePrioritySupply(
    uint256 certificateAmount,
    uint256 availableSupply
  ) internal view {
    (, uint256 supplyAfterPurchase) = SafeMathUpgradeable.trySub({
      a: availableSupply,
      b: certificateAmount
    });
    if (supplyAfterPurchase < _priorityRestrictedThreshold) {
      if (!hasRole({role: ALLOWLIST_ROLE, account: _msgSender()})) {
        revert LowSupplyAllowlistRequired();
      }
    }
  }

  /**
   * @dev Authorizes withdrawal for the removal. Reverts if the caller is not the owner of the removal and
   * does not have the role `MARKET_ADMIN_ROLE`.
   * @param owner The owner of the removal.
   * @return Returns true if the caller is the owner, an approved spender, or has the role `MARKET_ADMIN_ROLE`,
   * false otherwise.
   */
  function _isAuthorizedWithdrawal(address owner) internal view returns (bool) {
    return (_msgSender() == owner ||
      hasRole({role: MARKET_ADMIN_ROLE, account: _msgSender()}) ||
      _removal.isApprovedForAll({account: owner, operator: _msgSender()}));
  }

  /**
   * @notice Validates if there is enough supply to fulfill the order.
   * @dev Reverts if total available supply in the market is not enough to fulfill the purchase.
   * @param certificateAmount The number of carbon removals being purchased.
   * @param availableSupply The amount of listed supply in the market.
   */
  function _validateSupply(uint256 certificateAmount, uint256 availableSupply)
    internal
    pure
  {
    if (certificateAmount > availableSupply) {
      revert InsufficientSupply();
    }
  }

  /**
   * @notice Allocates the removals, amounts, and suppliers needed to fulfill the purchase.
   * @param certificateAmount The number of carbon removals to purchase.
   * @return countOfRemovalsAllocated The number of distinct removal IDs used to fulfill this order.
   * @return ids An array of the removal IDs being drawn from to fulfill this order.
   * @return amounts An array of amounts being allocated from each corresponding removal token.
   * @return suppliers The address of the supplier who owns each corresponding removal token.
   */
  function _allocateSupply(uint256 certificateAmount)
    private
    returns (
      uint256 countOfRemovalsAllocated,
      uint256[] memory ids,
      uint256[] memory amounts,
      address[] memory suppliers
    )
  {
    uint256 remainingAmountToFill = certificateAmount;
    uint256 countOfListedRemovals = _removal.numberOfTokensOwnedByAddress({
      account: address(this)
    });
    uint256[] memory ids = new uint256[](countOfListedRemovals);
    uint256[] memory amounts = new uint256[](countOfListedRemovals);
    address[] memory suppliers = new address[](countOfListedRemovals);
    uint256 countOfRemovalsAllocated = 0;
    for (uint256 i = 0; i < countOfListedRemovals; ++i) {
      uint256 removalId = _listedSupply[_currentSupplierAddress]
        .getNextRemovalForSale();
      uint256 removalAmount = _removal.balanceOf({
        account: address(this),
        id: removalId
      });
      if (remainingAmountToFill < removalAmount) {
        /**
         * The order is complete, not fully using up this removal, don't increment currentSupplierAddress,
         * don't check about removing active supplier.
         */
        ids[countOfRemovalsAllocated] = removalId;
        amounts[countOfRemovalsAllocated] = remainingAmountToFill;
        suppliers[countOfRemovalsAllocated] = _currentSupplierAddress;
        remainingAmountToFill = 0;
      } else {
        /**
         * We will use up this removal while completing the order, move on to next one.
         */
        ids[countOfRemovalsAllocated] = removalId;
        amounts[countOfRemovalsAllocated] = removalAmount; // this removal is getting used up
        suppliers[countOfRemovalsAllocated] = _currentSupplierAddress;
        remainingAmountToFill -= removalAmount;
        _removeActiveRemoval({
          removalId: removalId,
          supplierAddress: _currentSupplierAddress
        });
        if (
          /**
           *  If the supplier is the only supplier remaining with supply, don't bother incrementing.
           */
          _suppliers[_currentSupplierAddress].next != _currentSupplierAddress
        ) {
          _incrementCurrentSupplierAddress();
        }
      }
      ++countOfRemovalsAllocated;
      if (remainingAmountToFill == 0) {
        break;
      }
    }
    return (countOfRemovalsAllocated, ids, amounts, suppliers);
  }

  /**
   * @notice Allocates supply for an amount using only a single supplier's removals.
   * @param certificateAmount The number of carbon removals to purchase.
   * @param supplier The supplier from which to purchase carbon removals.
   * @return countOfRemovalsAllocated The number of distinct removal IDs used to fulfill this order.
   * @return ids An array of the removal IDs being drawn from to fulfill this order.
   * @return amounts An array of amounts being allocated from each corresponding removal token.
   */
  function _allocateSupplySingleSupplier(
    uint256 certificateAmount,
    address supplier
  )
    private
    returns (
      uint256 countOfRemovalsAllocated,
      uint256[] memory ids,
      uint256[] memory amounts
    )
  {
    RemovalsByYear storage supplierRemovalQueue = _listedSupply[supplier];
    uint256 countOfListedRemovals;
    uint256 latestYear = supplierRemovalQueue.latestYear;
    for (
      uint256 vintage = supplierRemovalQueue.earliestYear;
      vintage <= latestYear;
      ++vintage
    ) {
      countOfListedRemovals += supplierRemovalQueue
        .yearToRemovals[vintage]
        .length();
    }
    if (countOfListedRemovals == 0) {
      revert InsufficientSupply();
    }
    uint256 remainingAmountToFill = certificateAmount;
    uint256[] memory ids = new uint256[](countOfListedRemovals);
    uint256[] memory amounts = new uint256[](countOfListedRemovals);
    uint256 countOfRemovalsAllocated = 0;
    for (uint256 i = 0; i < countOfListedRemovals; ++i) {
      uint256 removalId = supplierRemovalQueue.getNextRemovalForSale();
      uint256 removalAmount = _removal.balanceOf({
        account: address(this),
        id: removalId
      });
      /**
       * Order complete, not fully using up this removal.
       */
      if (remainingAmountToFill < removalAmount) {
        ids[countOfRemovalsAllocated] = removalId;
        amounts[countOfRemovalsAllocated] = remainingAmountToFill;
        remainingAmountToFill = 0;
        /**
         * We will use up this removal while completing the order, move on to next one.
         */
      } else {
        if (
          countOfRemovalsAllocated == countOfListedRemovals - 1 &&
          remainingAmountToFill > removalAmount
        ) {
          revert InsufficientSupply();
        }
        ids[countOfRemovalsAllocated] = removalId;
        amounts[countOfRemovalsAllocated] = removalAmount; // This removal is getting used up.
        remainingAmountToFill -= removalAmount;
        supplierRemovalQueue.remove({removalId: removalId});
        /**
         * If the supplier is out of supply, remove them from the active suppliers.
         */
        if (supplierRemovalQueue.isEmpty()) {
          _removeActiveSupplier({supplierToRemove: supplier});
        }
      }
      ++countOfRemovalsAllocated;
      if (remainingAmountToFill == 0) {
        break;
      }
    }
    return (countOfRemovalsAllocated, ids, amounts);
  }

  /**
   * @dev Updates `_currentSupplierAddress` to the next of whatever is the current supplier.
   * Used to iterate in a round-robin way through the linked list of active suppliers.
   */
  function _incrementCurrentSupplierAddress() private {
    _currentSupplierAddress = _suppliers[_currentSupplierAddress].next;
  }

  /**
   * @dev Adds a supplier to the active supplier queue. Called when a new supplier is added to the marketplace.
   * If the first supplier, initializes a circularly doubly-linked list, where initially the first supplier points
   * to itself as next and previous. When a new supplier is added, at the position of the current supplier, update
   * the previous pointer of the current supplier to point to the new supplier, and update the next pointer of the
   * previous supplier to the new supplier.
   *
   * Emits a `SupplierAdded` event.
   * @param newSupplierAddress the address of the new supplier to add
   */
  function _addActiveSupplier(address newSupplierAddress) private {
    // If this is the first supplier to be added, update the initialized addresses.
    if (_currentSupplierAddress == address(0)) {
      _currentSupplierAddress = newSupplierAddress;
      _suppliers[newSupplierAddress] = LinkedListNode({
        previous: newSupplierAddress,
        next: newSupplierAddress
      });
      emit SupplierAdded({
        added: newSupplierAddress,
        next: newSupplierAddress,
        previous: newSupplierAddress
      });
    } else {
      address previousOfCurrentSupplierAddress = _suppliers[
        _currentSupplierAddress
      ].previous;
      /**
       * Add the new supplier to the round robin order, with the current supplier as next and the current supplier's
       * previous supplier as previous.
       */
      _suppliers[newSupplierAddress] = LinkedListNode({
        next: _currentSupplierAddress,
        previous: previousOfCurrentSupplierAddress
      });
      /**
       * Update the previous supplier from the current supplier to point to the new supplier as next.
       */
      _suppliers[previousOfCurrentSupplierAddress].next = newSupplierAddress;
      /**
       * Update the current supplier to point to the new supplier as previous.
       */
      _suppliers[_currentSupplierAddress].previous = newSupplierAddress;
      emit SupplierAdded({
        added: newSupplierAddress,
        next: _currentSupplierAddress,
        previous: previousOfCurrentSupplierAddress
      });
    }
  }

  /**
   * @dev Removes a supplier from the active supplier queue. Called when a supplier's last removal is used for an order.
   * If the last supplier, resets the pointer for the `_currentSupplierAddress`. Otherwise, from the position of the
   * supplier to be removed, update the previous supplier to point to the next of the removed supplier, and the next of
   * the removed supplier to point to the previous address of the remove supplier. Then, set the next and previous
   * pointers of the removed supplier to the 0x address.
   *
   * Emits a `SupplierRemoved` event.
   * @param supplierToRemove the address of the supplier to remove
   */
  function _removeActiveSupplier(address supplierToRemove) private {
    address previousOfRemovedSupplierAddress = _suppliers[supplierToRemove]
      .previous;
    address nextOfRemovedSupplierAddress = _suppliers[supplierToRemove].next;
    /**
     * If this is the last supplier, clear all current tracked addresses.
     */
    if (supplierToRemove == nextOfRemovedSupplierAddress) {
      _currentSupplierAddress = address(0);
    } else {
      /**
       * Set the next of the previous supplier to point to the removed supplier's next.
       */
      _suppliers[previousOfRemovedSupplierAddress]
        .next = nextOfRemovedSupplierAddress;
      /**
       * Set the previous address of the next supplier to point to the removed supplier's previous.
       */
      _suppliers[nextOfRemovedSupplierAddress]
        .previous = previousOfRemovedSupplierAddress;
      /**
       * If the supplier is the current supplier, update that address to the next supplier.
       */
      if (supplierToRemove == _currentSupplierAddress) {
        _incrementCurrentSupplierAddress();
      }
    }
    /**
     * Remove `LinkedListNode` data from supplier.
     */
    _suppliers[supplierToRemove] = LinkedListNode({
      next: address(0),
      previous: address(0)
    });
    emit SupplierRemoved({
      removed: supplierToRemove,
      next: nextOfRemovedSupplierAddress,
      previous: previousOfRemovedSupplierAddress
    });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

/**
 * @title A preset contract that enables pausable access control.
 * @author Nori Inc.
 * @notice This preset contract affords an inheriting contract a set of standard functionality that allows role-based
 * access control and pausable functions.
 * @dev This contract is inherited by most of the other contracts in this project.
 *
 * ##### Inherits:
 *
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](
 * https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 */
abstract contract AccessPresetPausable is
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable
{
  /**
   * @notice Role conferring pausing and unpausing of this contract.
   */
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @notice Pauses all functions that can mutate state.
   * @dev Used to effectively freeze a contract so that no state updates can occur.
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE` role.
   */
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @notice Unpauses all token transfers.
   * @dev Re-enables functionality that was paused by `pause`.
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE` role.
   */
  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @notice Grants a role to an account.
   * @dev This function allows the role's admin to grant the role to other accounts.
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   *
   * @param role The role to grant.
   * @param account The account to grant the role to.
   */
  function _grantRole(bytes32 role, address account)
    internal
    virtual
    override
    whenNotPaused
  {
    super._grantRole({role: role, account: account});
  }

  /**
   * @notice Revokes a role from an account.
   * @dev This function allows the role's admin to revoke the role from other accounts.
   * ##### Requirements:
   *
   * - The contract must not be paused.
   *
   * @param role The role to revoke.
   * @param account The account to revoke the role from.
   */
  function _revokeRole(bytes32 role, address account)
    internal
    virtual
    override
    whenNotPaused
  {
    super._revokeRole({role: role, account: account});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

interface IERC20WithPermit is IERC20Upgradeable, IERC20PermitUpgradeable {}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/**
 * @notice Thrown when two arrays are not of equal length.
 * @param array1Name The name of the first array variable.
 * @param array2Name The name of the second array variable.
 */
error ArrayLengthMismatch(string array1Name, string array2Name);
/**
 * @notice Thrown when an unsupported function is called.
 */
error FunctionDisabled();
/**
 * @notice Thrown when a function that can only be called by the Removal contract is called by any address other than
 * the Removal contract.
 */
error SenderNotRemovalContract();
/**
 * @notice Thrown when a non-existent rNORI schedule is requested.
 * @param scheduleId The schedule ID that does not exist.
 */
error NonexistentSchedule(uint256 scheduleId);
/**
 * @notice Thrown when an rNORI schedule already exists for the given `scheduleId`.
 * @param scheduleId The schedule ID that already exists.
 */
error ScheduleExists(uint256 scheduleId);
/**
 * @notice Thrown when rNORI does not have enough unreleased tokens to fulfill a request.
 * @param scheduleId The schedule ID that does not have enough unreleased tokens.
 */
error InsufficientUnreleasedTokens(uint256 scheduleId);
/**
 * @notice Thrown when rNORI does not have enough claimable tokens to fulfill a withdrawal.
 * @param account The account that does not have enough claimable tokens.
 * @param scheduleId The schedule ID that does not have enough claimable tokens.
 */
error InsufficientClaimableBalance(address account, uint256 scheduleId);
/**
 * @notice Thrown when the caller does not have the role required to mint the tokens.
 * @param account the account that does not have the role.
 */
error InvalidMinter(address account);
/**
 * @notice Thrown when the rNORI duration provides is zero.
 */
error InvalidZeroDuration();
/**
 * @notice Thrown when a `removalId` does not have removals for the specified `year`.
 * @param removalId The removal ID that does not have removals for the specified `year`.
 * @param year The year that does not have removals for the specified `removalId`.
 */
error RemovalNotFoundInYear(uint256 removalId, uint256 year);
/**
 * @notice Thrown when the bytes contain unexpected uncapitalized characters.
 * @param country the country that contains unexpected uncapitalized characters.
 * @param subdivision the subdivision that contains unexpected uncapitalized characters.
 */
error UncapitalizedString(bytes2 country, bytes2 subdivision);
/**
 * @notice Thrown when a methodology is greater than the maximum allowed value.
 * @param methodology the methodology that is greater than the maximum allowed value.
 */
error MethodologyTooLarge(uint8 methodology);
/**
 * @notice Thrown when a methodology version is greater than the maximum allowed value.
 * @param methodologyVersion the methodology version that is greater than the maximum allowed value.
 */
error MethodologyVersionTooLarge(uint8 methodologyVersion);
/**
 * @notice Thrown when a removal ID uses an unsupported version.
 * @param idVersion the removal ID version that is not supported.
 */
error UnsupportedIdVersion(uint8 idVersion);
/**
 * @notice Thrown when a caller attempts to transfer a certificate.
 */
error ForbiddenTransferAfterMinting();
/**
 * @notice Thrown when there is insufficient supply in the market.
 */
error InsufficientSupply();
/**
 * @notice Thrown when the caller is not authorized to withdraw.
 */
error UnauthorizedWithdrawal();
/**
 * @notice Thrown when the supply of the market is too low to fulfill a request and the caller is not authorized to
 * access the reserve supply.
 */
error LowSupplyAllowlistRequired();
/**
 * @notice Thrown when the caller is not authorized to perform the action.
 */
error Unauthorized();
/**
 * @notice Thrown when transaction data contains invalid data.
 */
error InvalidData();
/**
 * @notice Thrown when the token specified by `tokenId` is transferred, but the type of transfer is unsupported.
 * @param tokenId The token ID that is used in the invalid transfer.
 */
error InvalidTokenTransfer(uint256 tokenId);
/**
 * @notice Thrown when the specified fee percentage is not a valid value.
 */
error InvalidNoriFeePercentage();
/**
 * @notice Thrown when a token is transferred, but the type of transfer is unsupported.
 */
error ForbiddenTransfer();
/**
 * @notice Thrown when the removal specified by `tokenId` has not been minted yet.
 * @param tokenId The removal token ID that is not minted yet.
 */
error RemovalNotYetMinted(uint256 tokenId);
/**
 * @notice Thrown when the caller specifies the zero address for the Nori fee wallet.
 */
error NoriFeeWalletZeroAddress();
/**
 * @notice Thrown when a holdback percentage greater than 100 is submitted to `mintBatch`.
 */
error InvalidHoldbackPercentage(uint8 holdbackPercentage);
/**
 * @notice Thrown when attempting to list for sale a removal that already belongs to the Certificate or Market contracts.
 */
error RemovalAlreadySoldOrConsigned(uint256 tokenId);

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./AccessPresetPausable.sol";
import "./Errors.sol";
import "./IERC20WithPermit.sol";
import "./IRemoval.sol";
import "./IRestrictedNORI.sol";
import {RestrictedNORILib, Schedule} from "./RestrictedNORILib.sol";
import {RemovalIdLib} from "./RemovalIdLib.sol";

/**
 * @notice View information for the current state of one schedule.
 * @param scheduleTokenId The schedule token ID.
 * @param startTime The start time of the schedule.
 * @param endTime The end time of the schedule.
 * @param totalSupply The total supply of the schedule.
 * @param totalClaimableAmount The total amount that can be claimed from the schedule.
 * @param totalClaimedAmount The total amount that has been claimed from the schedule.
 * @param totalQuantityRevoked The total quantity that has been revoked from the schedule.
 * @param tokenHolders The holders of the schedule.
 */
struct ScheduleSummary {
  uint256 scheduleTokenId;
  uint256 startTime;
  uint256 endTime;
  uint256 totalSupply;
  uint256 totalClaimableAmount;
  uint256 totalClaimedAmount;
  uint256 totalQuantityRevoked;
  address[] tokenHolders;
}

/**
 * @notice View information for one account's ownership of a schedule.
 * @param tokenHolder The token holder.
 * @param scheduleTokenId The schedule token ID.
 * @param balance The balance of the token holder.
 * @param claimableAmount The amount that can be claimed from the schedule by the token holder.
 * @param claimedAmount The amount that has been claimed from the schedule by the token holder.
 * @param quantityRevoked The quantity that has been revoked from the schedule by the token holder.
 */
struct ScheduleDetailForAddress {
  address tokenHolder;
  uint256 scheduleTokenId;
  uint256 balance;
  uint256 claimableAmount;
  uint256 claimedAmount;
  uint256 quantityRevoked;
}

/**
 * @title A wrapped ERC20 token contract for restricting the release of tokens for use as insurance
 * collateral.
 * @author Nori Inc.
 * @notice Based on the mechanics of a wrapped ERC-20 token, this contract layers schedules over the withdrawal
 * functionality to implement _restriction_, a time-based release of tokens that, until released, can be reclaimed
 * by Nori to enforce the permanence guarantee of carbon removals.
 *
 * ##### Behaviors and features:
 *
 * ###### Schedules
 *
 * - _Schedules_ define the release timeline for restricted tokens.
 * - A specific schedule is associated with one ERC1155 token ID and can have multiple token holders.
 *
 * ###### Restricting
 *
 * - _Restricting_ is the process of gradually releasing tokens that may need to be recaptured by Nori in the event
 * that the sequestered carbon for which the tokens were exchanged is found to violate its permanence guarantee.
 * In this case, tokens need to be recaptured to mitigate the loss and make the original buyer whole by using them to
 * purchase new NRTs on their behalf.
 * - Tokens are released linearly from the schedule's start time until its end time. As NRTs are sold, proceeds may
 * be routed to a restriction schedule at any point in the schedule's timeline, thus increasing the total balance of
 * the schedule as well as the released amount at the current timestamp (assuming it's after the schedule start time).
 *
 * ###### Transferring
 *
 * - A given schedule is a logical overlay to a specific 1155 token. This token can have any number of token holders,
 * and transferability via `safeTransferFrom` and `safeBatchTransferFrom` is enabled.
 * Ownership percentages only become relevant and are enforced during withdrawal and revocation.
 *
 * ###### Withdrawal
 *
 * - _Withdrawal_ is the process of a token holder claiming the tokens that have been released by the restriction
 * schedule. When tokens are withdrawn, the 1155 schedule token is burned, and the underlying ERC20 token being held
 * by this contract is sent to the address specified by the token holder performing the withdrawal.
 * Tokens are released by a schedule based on the linear release of the schedule's `totalSupply`, but a token holder
 * can only withdraw released tokens in proportion to their percentage ownership of the schedule tokens.
 *
 * ###### Revocation
 *
 * - _Revocation_ is the process of tokens being recaptured by Nori to enforce carbon permanence guarantees.
 * Only unreleased tokens can ever be revoked. When tokens are revoked from a schedule, the current number of released
 * tokens does not decrease, even as the schedule's total supply decreases through revocation (a floor is enforced).
 * When these tokens are revoked, the 1155 schedule token is burned, and the underlying ERC20 token held by this contract
 * is sent to the address specified by Nori. If a schedule has multiple token holders, tokens are burned from each
 * holder in proportion to their total percentage ownership of the schedule.
 *
 * ###### Additional behaviors and features
 *
 * - [Upgradeable](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance)
 * - [Pausable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable): all functions that mutate state are
 * pausable.
 * - [Role-based access control](https://docs.openzeppelin.com/contracts/4.x/access-control)
 * - `SCHEDULE_CREATOR_ROLE`: Can create restriction schedules without sending the underlying tokens to the contract. The
 * market contract has this role and sets up relevant schedules as removal tokens are listed for sale.
 * - `MINTER_ROLE`: Can call `mint` on this contract, which mints tokens of the correct schedule ID (token ID) for a
 * given removal. The market contract has this role and can mint RestrictedNORI while routing sale proceeds to this
 * contract.
 * - `TOKEN_REVOKER_ROLE`: Can revoke unreleased tokens from a schedule. Only Nori admin wallet should have this role.
 * - `PAUSER_ROLE`: Can pause and unpause the contract.
 * - `DEFAULT_ADMIN_ROLE`: This is the only role that can add/revoke other accounts to any of the roles.
 *
 * ##### Inherits:
 *
 * - [ERC1155Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155)
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/access)
 * - [ContextUpgradeable](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable)
 * - [ERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#ERC165)
 *
 * ##### Implements:
 *
 * - [IERC1155Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155)
 * - [IAccessControlEnumerable](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 * - [IERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165)
 *
 * ##### Uses:
 *
 * - [RestrictedNORILib](./RestrictedNORILib.md) for `Schedule`.
 * - [EnumerableSetUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet) for
 * `EnumerableSetUpgradeable.UintSet` and `EnumerableSetUpgradeable.AddressSet`.
 * - [MathUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Math)
 */
contract RestrictedNORI is
  IRestrictedNORI,
  ERC1155SupplyUpgradeable,
  AccessPresetPausable,
  MulticallUpgradeable
{
  using RestrictedNORILib for Schedule;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  /**
   * @notice Role conferring creation of schedules.
   * @dev The Market contract is granted this role after deployments.
   */
  bytes32 public constant SCHEDULE_CREATOR_ROLE =
    keccak256("SCHEDULE_CREATOR_ROLE");

  /**
   * @notice Role conferring sending of underlying ERC20 token to this contract for wrapping.
   * @dev The Market contract is granted this role after deployments.
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @notice Role conferring revocation of restricted tokens.
   * @dev Only Nori admin addresses should have this role.
   */
  bytes32 public constant TOKEN_REVOKER_ROLE = keccak256("TOKEN_REVOKER_ROLE");

  /**
   * @notice A mapping of methodology to version to schedule duration.
   */
  mapping(uint256 => mapping(uint256 => uint256))
    private _methodologyAndVersionToScheduleDuration;

  /**
   * @notice A mapping of schedule ID to schedule.
   */
  mapping(uint256 => Schedule) private _scheduleIdToScheduleStruct;

  /**
   * @notice An enumerable set containing all schedule IDs.
   */
  EnumerableSetUpgradeable.UintSet private _allScheduleIds;

  /**
   * @notice The underlying ERC20 token contract for which this contract wraps tokens.
   */
  IERC20WithPermit private _underlyingToken;

  /**
   * @notice The Removal contract that accounts for carbon removal supply.
   */
  IRemoval private _removal;

  /**
   * @notice Emitted on successful creation of a new schedule.
   * @param projectId The ID of the project for which the schedule was created.
   * @param startTime The start time of the schedule.
   * @param endTime The end time of the schedule.
   */
  event ScheduleCreated(
    uint256 indexed projectId,
    uint256 startTime,
    uint256 endTime
  );

  /**
   * @notice Emitted when unreleased tokens of an active schedule are revoked.
   * @param atTime The time at which the revocation occurred.
   * @param scheduleId The ID of the schedule from which tokens were revoked.
   * @param quantity The quantity of tokens revoked.
   * @param scheduleOwners The addresses of the schedule owners from which tokens were revoked.
   * @param quantitiesBurned The quantities of tokens burned from each schedule owner.
   */
  event TokensRevoked(
    uint256 indexed atTime,
    uint256 indexed scheduleId,
    uint256 quantity,
    address[] scheduleOwners,
    uint256[] quantitiesBurned
  );

  /**
   * @notice Emitted on withdrawal of released tokens.
   * @param from The address from which tokens were withdrawn.
   * @param to The address to which tokens were withdrawn.
   * @param scheduleId The ID of the schedule from which tokens were withdrawn.
   * @param quantity The quantity of tokens withdrawn.
   */
  event TokensClaimed(
    address indexed from,
    address indexed to,
    uint256 indexed scheduleId,
    uint256 quantity
  );

  /**
   * @notice Locks the contract, preventing any future re-initialization.
   * @dev See more [here](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--).
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the RestrictedNORI contract.
   */
  function initialize() external initializer {
    __ERC1155_init_unchained({
      uri_: "https://nori.com/api/restrictionschedule/{id}.json"
    });
    __Context_init_unchained();
    __ERC165_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Pausable_init_unchained();
    __ERC1155Supply_init_unchained();
    __Multicall_init_unchained();
    _grantRole({role: DEFAULT_ADMIN_ROLE, account: _msgSender()});
    _grantRole({role: PAUSER_ROLE, account: _msgSender()});
    _grantRole({role: SCHEDULE_CREATOR_ROLE, account: _msgSender()});
    _grantRole({role: TOKEN_REVOKER_ROLE, account: _msgSender()});
    setRestrictionDurationForMethodologyAndVersion({
      methodology: 1,
      methodologyVersion: 0,
      durationInSeconds: 315_569_520 // Seconds in 10 years (accounts for leap years)
    });
  }

  /**
   * @notice Revokes amount of tokens from the specified project (schedule) ID and transfers to `toAccount`.
   * @dev The behavior of this function can be used in two specific ways:
   * 1. To revoke a specific number of tokens as specified by the `amount` parameter.
   * 2. To revoke all remaining revokable tokens in a schedule by specifying 0 as the `amount`.
   *
   * Transfers any unreleased tokens in the specified schedule and reduces the total supply
   * of that token. Only unreleased tokens can be revoked from a schedule and no change is made to
   * balances that have released but not yet been claimed.
   * If a token has multiple owners, balances are burned proportionally to ownership percentage,
   * summing to the total amount being revoked.
   * Once the tokens have been revoked, the current released amount can never fall below
   * its current level, even if the linear release schedule of the new amount would cause
   * the released amount to be lowered at the current timestamp (a floor is established).
   *
   * Unlike in the `withdrawFromSchedule` function, here we burn RestrictedNORI
   * from the schedule owner but send that underlying ERC20 token back to Nori's
   * treasury or an address of Nori's choosing (the `toAccount` address).
   * The `claimedAmount` is not changed because this is not a claim operation.
   *
   * Emits a `TokensRevoked` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the caller has the `TOKEN_REVOKER_ROLE` role.
   * - The requirements of `_beforeTokenTransfer` apply to this function.
   * @param projectId The schedule ID from which to revoke tokens.
   * @param amount The amount to revoke.
   * @param toAccount The account to which the underlying ERC20 token should be sent.
   */
  function revokeUnreleasedTokens(
    uint256 projectId,
    uint256 amount,
    address toAccount
  ) external whenNotPaused onlyRole(TOKEN_REVOKER_ROLE) {
    Schedule storage schedule = _scheduleIdToScheduleStruct[projectId];
    if (!schedule.doesExist()) {
      revert NonexistentSchedule({scheduleId: projectId});
    }
    uint256 quantityRevocable = schedule.revocableQuantityForSchedule({
      scheduleId: projectId,
      totalSupply: totalSupply(projectId)
    });
    if (!(amount <= quantityRevocable)) {
      revert InsufficientUnreleasedTokens({scheduleId: projectId});
    }
    // amount of zero indicates revocation of all remaining tokens.
    uint256 quantityToRevoke = amount > 0 ? amount : quantityRevocable;
    // burn correct proportion from each token holder
    address[] memory tokenHoldersLocal = schedule.tokenHolders.values();
    uint256[] memory accountBalances = new uint256[](tokenHoldersLocal.length);
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < tokenHoldersLocal.length; ++i) {
        accountBalances[i] = balanceOf({
          account: tokenHoldersLocal[i],
          id: projectId
        });
      }
    }
    uint256[] memory quantitiesToBurnForHolders = new uint256[](
      tokenHoldersLocal.length
    );
    /**
     * Calculate the final holder's quantity to revoke by subtracting the sum of other quantities
     * from the desired total to revoke, thus avoiding any precision rounding errors from affecting
     * the total quantity revoked by up to several wei.
     */
    uint256 cumulativeQuantityToBurn = 0;
    for (uint256 i = 0; i < (tokenHoldersLocal.length - 1); ++i) {
      uint256 quantityToBurnForHolder = _quantityToRevokeForTokenHolder({
        totalQuantityToRevoke: quantityToRevoke,
        scheduleId: projectId,
        schedule: schedule,
        account: tokenHoldersLocal[i],
        balanceOfAccount: accountBalances[i]
      });
      quantitiesToBurnForHolders[i] = quantityToBurnForHolder;
      cumulativeQuantityToBurn += quantityToBurnForHolder;
    }
    quantitiesToBurnForHolders[tokenHoldersLocal.length - 1] =
      quantityToRevoke -
      cumulativeQuantityToBurn;
    for (uint256 i = 0; i < (tokenHoldersLocal.length); ++i) {
      super._burn({
        from: tokenHoldersLocal[i],
        id: projectId,
        amount: quantitiesToBurnForHolders[i]
      });
      schedule.quantitiesRevokedByAddress[
        tokenHoldersLocal[i]
      ] += quantitiesToBurnForHolders[i];
    }
    schedule.totalQuantityRevoked += quantityToRevoke;
    emit TokensRevoked({
      atTime: block.timestamp, // solhint-disable-line not-rely-on-time, this is time-dependent
      scheduleId: projectId,
      quantity: quantityToRevoke,
      scheduleOwners: tokenHoldersLocal,
      quantitiesBurned: quantitiesToBurnForHolders
    });
    _underlyingToken.transfer({to: toAccount, amount: quantityToRevoke});
  }

  /**
   * @notice Register the underlying assets used by this contract.
   * @dev Register the addresses of the Market, underlying ERC20, and Removal contracts in this contract.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `DEFAULT_ADMIN_ROLE` role.
   * @param wrappedToken The address of the underlying ERC20 contract for which this contract wraps tokens.
   * @param removal The address of the Removal contract that accounts for Nori's issued carbon removals.
   */
  function registerContractAddresses(
    IERC20WithPermit wrappedToken,
    IRemoval removal
  ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
    _underlyingToken = IERC20WithPermit(wrappedToken);
    _removal = IRemoval(removal);
  }

  /**
   * @notice Sets up a restriction schedule with parameters determined from the project ID.
   * @dev Create a schedule for a project ID and set the parameters of the schedule.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `SCHEDULE_CREATOR_ROLE` role.
   * @param projectId The ID that will be used as this schedule's token ID
   * @param startTime The schedule's start time in seconds since the unix epoch
   * @param methodology The methodology of this project, used to look up correct schedule duration
   * @param methodologyVersion The methodology version, used to look up correct schedule duration
   */
  function createSchedule(
    uint256 projectId,
    uint256 startTime,
    uint8 methodology,
    uint8 methodologyVersion
  ) external override whenNotPaused onlyRole(SCHEDULE_CREATOR_ROLE) {
    if (this.scheduleExists({scheduleId: projectId})) {
      revert ScheduleExists({scheduleId: projectId});
    }
    uint256 restrictionDuration = getRestrictionDurationForMethodologyAndVersion({
        methodology: methodology,
        methodologyVersion: methodologyVersion
      });
    _validateSchedule({
      startTime: startTime,
      restrictionDuration: restrictionDuration
    });
    _createSchedule({
      projectId: projectId,
      startTime: startTime,
      restrictionDuration: restrictionDuration
    });
  }

  /**
   * @notice Mint RestrictedNORI tokens for a schedule.
   * @dev Mint `amount` of RestrictedNORI to the schedule ID that corresponds to the provided `removalId`.
   * The schedule ID for this removal is looked up in the Removal contract. The underlying ERC20 asset is
   *  sent to this contract from the buyer by the Market contract during a purchase, so this function only concerns
   * itself with minting the RestrictedNORI token for the correct token ID.
   *
   * ##### Requirements:
   *
   * - Can only be used if the caller has the `MINTER_ROLE` role.
   * - The rules of `_beforeTokenTransfer` apply.
   * @param amount The amount of RestrictedNORI to mint.
   * @param removalId The removal token ID for which proceeds are being restricted.
   */
  function mint(uint256 amount, uint256 removalId) external {
    if (!hasRole({role: MINTER_ROLE, account: _msgSender()})) {
      revert InvalidMinter({account: _msgSender()});
    }
    uint256 projectId = _removal.getProjectId({id: removalId});
    address supplierAddress = RemovalIdLib.supplierAddress({
      removalId: removalId
    });
    super._mint({to: supplierAddress, id: projectId, amount: amount, data: ""});
    _scheduleIdToScheduleStruct[projectId].tokenHolders.add({
      value: supplierAddress
    });
  }

  /**
   * @notice Claim sender's released tokens and withdraw them to `recipient` address.
   *
   * @dev This function burns `amount` of RestrictedNORI for the given schedule ID
   * and transfers `amount` of underlying ERC20 token from the RestrictedNORI contract's
   * balance to `recipient`'s balance.
   * Enforcement of the availability of claimable tokens for the `_burn` call happens in `_beforeTokenTransfer`.
   *
   * Emits a `TokensClaimed` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * @param recipient The address receiving the unwrapped underlying ERC20 token.
   * @param scheduleId The schedule from which to withdraw.
   * @param amount The amount to withdraw.
   * @return Whether or not the tokens were successfully withdrawn.
   */
  function withdrawFromSchedule(
    address recipient,
    uint256 scheduleId,
    uint256 amount
  ) external returns (bool) {
    super._burn({from: _msgSender(), id: scheduleId, amount: amount});
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    schedule.totalClaimedAmount += amount;
    schedule.claimedAmountsByAddress[_msgSender()] += amount;
    emit TokensClaimed({
      from: _msgSender(),
      to: recipient,
      scheduleId: scheduleId,
      quantity: amount
    });
    _underlyingToken.transfer({to: recipient, amount: amount});
    return true;
  }

  /**
   * @notice Get all schedule IDs.
   * @return Returns an array of all existing schedule IDs, regardless of the status of the schedule.
   */
  function getAllScheduleIds() external view returns (uint256[] memory) {
    uint256[] memory allScheduleIdsArray = new uint256[](
      _allScheduleIds.length()
    );
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < allScheduleIdsArray.length; ++i) {
        allScheduleIdsArray[i] = _allScheduleIds.at({index: i});
      }
    }
    return allScheduleIdsArray;
  }

  /**
   * @notice Returns an account-specific view of the details of a specific schedule.
   * @param account The account for which to provide schedule details.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @return Returns a `ScheduleDetails` struct containing the details of the schedule.
   */
  function getScheduleDetailForAccount(address account, uint256 scheduleId)
    external
    view
    returns (ScheduleDetailForAddress memory)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      ScheduleDetailForAddress({
        tokenHolder: account,
        scheduleTokenId: scheduleId,
        balance: balanceOf({account: account, id: scheduleId}),
        claimableAmount: schedule.claimableBalanceForScheduleForAccount({
          scheduleId: scheduleId,
          account: account,
          totalSupply: totalSupply({id: scheduleId}),
          balanceOfAccount: balanceOf({account: account, id: scheduleId})
        }),
        claimedAmount: schedule.claimedAmountsByAddress[account],
        quantityRevoked: schedule.quantitiesRevokedByAddress[account]
      });
  }

  /**
   * @notice Batch version of `getScheduleDetailForAccount`.
   * @param account The account for which to provide schedule details.
   * @param scheduleIds The token IDs of the schedules for which to retrieve details.
   * @return Returns an array of `ScheduleDetails` structs containing the details of the schedules
   */
  function batchGetScheduleDetailsForAccount(
    address account,
    uint256[] memory scheduleIds
  ) external view returns (ScheduleDetailForAddress[] memory) {
    ScheduleDetailForAddress[]
      memory scheduleDetails = new ScheduleDetailForAddress[](
        scheduleIds.length
      );
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < scheduleIds.length; ++i) {
        if (_scheduleIdToScheduleStruct[scheduleIds[i]].doesExist()) {
          scheduleDetails[i] = this.getScheduleDetailForAccount({
            account: account,
            scheduleId: scheduleIds[i]
          });
        }
      }
    }
    return scheduleDetails;
  }

  /**
   * @notice Check the existence of a schedule.
   * @param scheduleId The token ID of the schedule for which to check existence.
   * @return Returns a boolean indicating whether or not the schedule exists.
   */
  function scheduleExists(uint256 scheduleId)
    external
    view
    override
    returns (bool)
  {
    return _scheduleIdToScheduleStruct[scheduleId].doesExist();
  }

  /**
   * @notice Returns an array of summary structs for the specified schedules.
   * @param scheduleIds The token IDs of the schedules for which to retrieve details.
   * @return Returns an array of `ScheduleSummary` structs containing the summary of the schedules.
   */
  function batchGetScheduleSummaries(uint256[] calldata scheduleIds)
    external
    view
    returns (ScheduleSummary[] memory)
  {
    ScheduleSummary[] memory scheduleSummaries = new ScheduleSummary[](
      scheduleIds.length
    );
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < scheduleIds.length; ++i) {
        scheduleSummaries[i] = getScheduleSummary({scheduleId: scheduleIds[i]});
      }
    }
    return scheduleSummaries;
  }

  /**
   * @notice Released balance less the total claimed amount at current block timestamp for a schedule.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @return Returns the claimable amount for the schedule.
   */
  function claimableBalanceForSchedule(uint256 scheduleId)
    external
    view
    returns (uint256)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      schedule.claimableBalanceForSchedule({
        scheduleId: scheduleId,
        totalSupply: totalSupply({id: scheduleId})
      });
  }

  /**
   * @notice A single account's claimable balance at current block timestamp for a schedule.
   * @dev Calculations have to consider an account's total proportional claim to the schedule's released tokens,
   * using totals constructed from current balances and claimed amounts, and then subtract anything that
   * account has already claimed.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @param account The account for which to retrieve details.
   * @return Returns the claimable amount for an account's schedule.
   */
  function claimableBalanceForScheduleForAccount(
    uint256 scheduleId,
    address account
  ) external view returns (uint256) {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      schedule.claimableBalanceForScheduleForAccount({
        scheduleId: scheduleId,
        account: account,
        totalSupply: totalSupply({id: scheduleId}),
        balanceOfAccount: balanceOf({account: account, id: scheduleId})
      });
  }

  /**
   * @notice Get the current number of revocable tokens for a given schedule at the current block timestamp.
   * @param scheduleId The schedule ID for which to revoke tokens.
   * @return Returns the number of revocable tokens for a given schedule at the current block timestamp.
   */
  function revocableQuantityForSchedule(uint256 scheduleId)
    external
    view
    returns (uint256)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      schedule.revocableQuantityForSchedule({
        scheduleId: scheduleId,
        totalSupply: totalSupply({id: scheduleId})
      });
  }

  /**
   * @notice Set the restriction duration for a methodology and version.
   * @dev Set the duration in seconds that should be applied to schedules created on behalf of removals
   * originating from the given methodology and methodology version.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `DEFAULT_ADMIN_ROLE` role.
   * @param methodology The methodology of carbon removal.
   * @param methodologyVersion The version of the methodology.
   * @param durationInSeconds The duration in seconds that insurance funds should be restricted for this
   * methodology and version.
   */
  function setRestrictionDurationForMethodologyAndVersion(
    uint256 methodology,
    uint256 methodologyVersion,
    uint256 durationInSeconds
  ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
    if (durationInSeconds == 0) {
      revert InvalidZeroDuration();
    }
    _methodologyAndVersionToScheduleDuration[methodology][
      methodologyVersion
    ] = durationInSeconds;
  }

  /**
   * @notice Token transfers disabled.
   * @dev Transfer is disabled because keeping track of claimable amounts as tokens are
   * claimed and transferred requires more bookkeeping infrastructure that we don't currently
   * have time to write but may implement in the future.
   */
  function safeTransferFrom(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public override {
    revert FunctionDisabled();
  }

  /**
   * @notice Token transfers disabled.
   * @dev Transfer is disabled because keeping track of claimable amounts as tokens are
   * claimed and transferred requires more bookkeeping infrastructure that we don't currently
   * have time to write but may implement in the future.
   */
  function safeBatchTransferFrom(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public override {
    revert FunctionDisabled();
  }

  /**
   * @notice Get a summary for a schedule.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @return Returns the schedule summary.
   */
  function getScheduleSummary(uint256 scheduleId)
    public
    view
    returns (ScheduleSummary memory)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    uint256 numberOfTokenHolders = schedule.tokenHolders.length();
    address[] memory tokenHoldersArray = new address[](numberOfTokenHolders);
    uint256[] memory scheduleIdArray = new uint256[](numberOfTokenHolders);
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < numberOfTokenHolders; ++i) {
        tokenHoldersArray[i] = schedule.tokenHolders.at({index: i});
        scheduleIdArray[i] = scheduleId;
      }
    }
    uint256 supply = totalSupply({id: scheduleId});
    return
      ScheduleSummary({
        scheduleTokenId: scheduleId,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        totalSupply: supply,
        totalClaimableAmount: schedule.claimableBalanceForSchedule({
          scheduleId: scheduleId,
          totalSupply: supply
        }),
        totalClaimedAmount: schedule.totalClaimedAmount,
        totalQuantityRevoked: schedule.totalQuantityRevoked,
        tokenHolders: tokenHoldersArray
      });
  }

  /**
   * @dev See [IERC165.supportsInterface](
   * https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165-supportsInterface-bytes4-) for more.
   * @param interfaceId The interface ID to check for support.
   * @return Returns true if the interface is supported, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface({interfaceId: interfaceId});
  }

  /**
   * @notice Get the schedule duration (in seconds) that has been set for a given methodology and methodology version.
   * @param methodology The methodology of carbon removal.
   * @param methodologyVersion The version of the methodology.
   * @return Returns the schedule duration in seconds.
   */
  function getRestrictionDurationForMethodologyAndVersion(
    uint256 methodology,
    uint256 methodologyVersion
  ) public view returns (uint256) {
    return
      _methodologyAndVersionToScheduleDuration[methodology][methodologyVersion];
  }

  /**
   * @notice Sets up a schedule for the specified project.
   * @dev Schedules are created when removal tokens are listed for sale in the market contract,
   * so this should only be invoked during `tokensReceived` in the exceptional case that
   * tokens were sent to this contract without a schedule set up.
   *
   * Revert strings are used instead of custom errors here for proper surfacing
   * from within the market contract `onERC1155BatchReceived` hook.
   *
   * Emits a `ScheduleCreated` event.
   * @param projectId The ID that will be used as the new schedule's ID.
   * @param startTime The schedule start time in seconds since the unix epoch.
   * @param restrictionDuration The duration of the schedule in seconds since the unix epoch.
   */
  function _createSchedule(
    uint256 projectId,
    uint256 startTime,
    uint256 restrictionDuration
  ) internal {
    Schedule storage schedule = _scheduleIdToScheduleStruct[projectId];
    schedule.startTime = startTime;
    schedule.endTime = startTime + restrictionDuration;
    _allScheduleIds.add({value: projectId});
    emit ScheduleCreated({
      projectId: projectId,
      startTime: startTime,
      endTime: schedule.endTime
    });
  }

  /**
   * @notice Hook that is called before any token transfer. This includes minting and burning, as well as batched
   * variants.
   * @dev Follows the rules of hooks defined [here](
   * https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks)
   *
   * See the ERC1155 specific version [here](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155).
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * - One of the following must be true:
   *    - The operation is a mint.
   *    - The operation is a burn, which only happens during revocation and withdrawal:
   *      - If the operation is a revocation, that permission is enforced by the `TOKEN_REVOKER_ROLE`.
   *      - If the operation is a withdrawal the burn amount must be <= the sender's claimable balance.
   *    - The operation is a transfer and _all_ the following must be true:
   *      - The operator is operating on their own balance (enforced in the inherited contract).
   *      - The operator has sufficient balance to transfer (enforced in the inherited contract).
   * @param operator The address which initiated the transfer (i.e. msg.sender).
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param ids The token IDs to transfer.
   * @param amounts The amounts of the token `id`s to transfer.
   * @param data The data to pass to the receiver contract.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155SupplyUpgradeable) whenNotPaused {
    bool isBurning = to == address(0);
    bool isWithdrawing = isBurning && from == operator;
    if (isBurning) {
      // Skip overflow check as for loop is indexed starting at zero.
      unchecked {
        for (uint256 i = 0; i < ids.length; ++i) {
          uint256 id = ids[i];
          Schedule storage schedule = _scheduleIdToScheduleStruct[id];
          if (isWithdrawing) {
            if (
              amounts[i] >
              schedule.claimableBalanceForScheduleForAccount({
                scheduleId: id,
                account: from,
                totalSupply: totalSupply({id: id}),
                balanceOfAccount: balanceOf({account: from, id: id})
              })
            ) {
              revert InsufficientClaimableBalance({
                account: from,
                scheduleId: id
              });
            }
          }
          schedule.releasedAmountFloor = schedule
            .releasedBalanceOfSingleSchedule({
              totalSupply: totalSupply({id: id})
            });
        }
      }
    }
    return
      super._beforeTokenTransfer({
        operator: operator,
        from: from,
        to: to,
        ids: ids,
        amounts: amounts,
        data: data
      });
  }

  /**
   * @notice Validates that the schedule start time and duration are non-zero.
   * @param startTime The schedule start time in seconds since the unix epoch.
   * @param restrictionDuration The duration of the schedule in seconds since the unix epoch.
   */
  function _validateSchedule(uint256 startTime, uint256 restrictionDuration)
    internal
    pure
  {
    require(startTime != 0, "rNORI: Invalid start time");
    require(restrictionDuration != 0, "rNORI: duration not set");
  }

  /**
   * @notice Calculates the quantity that should be revoked from a given token holder and schedule based on their
   * proportion of ownership of the schedule's tokens and the total number of tokens being revoked.
   * @param totalQuantityToRevoke The total quantity of tokens being revoked from this schedule.
   * @param scheduleId The schedule (token ID) from which tokens are being revoked.
   * @param schedule The schedule (struct) from which tokens are being revoked.
   * @param account The token holder for which to calculate the quantity that should be revoked.
   * @param balanceOfAccount The total balance of this token ID owned by `account`.
   * @return The quantity of tokens that should be revoked from `account` for the given schedule.
   */
  function _quantityToRevokeForTokenHolder(
    uint256 totalQuantityToRevoke,
    uint256 scheduleId,
    Schedule storage schedule,
    address account,
    uint256 balanceOfAccount
  ) private view returns (uint256) {
    uint256 scheduleTrueTotal = schedule.scheduleTrueTotal({
      totalSupply: totalSupply({id: scheduleId})
    });
    uint256 quantityToRevokeForAccount;
    // avoid division by or of 0
    if (scheduleTrueTotal == 0 || totalQuantityToRevoke == 0) {
      quantityToRevokeForAccount = 0;
    } else {
      uint256 claimedAmountForAccount = schedule.claimedAmountsByAddress[
        account
      ];
      quantityToRevokeForAccount =
        ((claimedAmountForAccount + balanceOfAccount) *
          (totalQuantityToRevoke)) /
        scheduleTrueTotal;
    }
    return quantityToRevokeForAccount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "./AccessPresetPausable.sol";
import "./ArrayLib.sol";
import "./Errors.sol";
import "./ICertificate.sol";
import "./IRemoval.sol";

/**
 * @title An ERC721a contract that issues non-transferable certificates of carbon removal.
 * @author Nori Inc.
 * @notice This contract issues sequentially increasing ERC721 token IDs to purchasers of certificates of carbon
 * removal in Nori's marketplace. The carbon removals that supply each certificate are accounted for using ERC1155
 * tokens in the Removal contract. Upon purchase, ownership of the relevant Removal token IDs and balances is
 * transferred to this contract.
 *
 *
 * ##### Additional behaviors and features:
 *
 * - [Upgradeable](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance)
 * - [Pausable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable): all functions that mutate state are
 * pausable.
 * - [Role-based access control](https://docs.openzeppelin.com/contracts/4.x/access-control)
 *    - `CERTIFICATE_OPERATOR_ROLE`: The only role that can transfer certificates after they are minted.
 *    - `PAUSER_ROLE`: Can pause and unpause the contract.
 *    - `DEFAULT_ADMIN_ROLE`: This is the only role that can add/revoke other accounts to any of the roles.
 * - [Can receive ERC1155 tokens](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155Receiver): A
 * certificate is minted and internal accounting ties the certificate to the ERC1155 tokens upon receipt.
 *
 * ##### Inherits:
 *
 * - [ERC721AUpgradeable](https://github.com/chiru-labs/ERC721A/blob/v4.2.3/contracts/ERC721A.sol)
 * - [ERC721ABurnableUpgradeable](
 * https://github.com/chiru-labs/ERC721A/blob/v4.2.3/contracts/extensions/ERC721ABurnable.sol)
 * - [MulticallUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/access)
 * - [ContextUpgradeable](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable)
 * - [ERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#ERC165)
 * - [AccessPresetPausable](../docs/AccessPresetPausable.md)
 *
 * ##### Implements:
 *
 * - [IERC721](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721)
 * - [IERC721Metadata](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721Metadata)
 * - [IERC721Enumerable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721Enumerable)
 * - [IAccessControlEnumerable](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 * - [IERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165)
 */
contract Certificate is
  ICertificate,
  ERC721ABurnableUpgradeable,
  ERC721AQueryableUpgradeable,
  MulticallUpgradeable,
  AccessPresetPausable
{
  using UInt256ArrayLib for uint256[];

  /**
   * @notice Role conferring operator permissions.
   * @dev Assigned to operators which are the only addresses which can transfer certificates outside
   * minting and burning.
   */
  bytes32 public constant CERTIFICATE_OPERATOR_ROLE =
    keccak256("CERTIFICATE_OPERATOR_ROLE");
  /**
   * @notice Keeps track of the original purchase amount for a certificate.
   */
  mapping(uint256 => uint256) private _purchaseAmounts;

  /**
   * @notice The Removal contract that accounts for carbon removal supply.
   */
  IRemoval private _removal;

  /**
   * @notice Base URI for token metadata.
   */
  string private _baseURIValue;

  /**
   * @notice Emitted when a batch of removals is received to create a certificate.
   * @param from The sender's address.
   * @param recipient The recipient address.
   * @param certificateId The ID of the certificate that the removals mint.
   * @param certificateAmount The total number of NRTs retired in this certificate.
   * @param removalIds The removal IDs used for the certificate.
   * @param removalAmounts The amounts from each removal used for the certificate.
   */
  event ReceiveRemovalBatch(
    address from,
    address indexed recipient,
    uint256 indexed certificateId,
    uint256 certificateAmount,
    uint256[] removalIds,
    uint256[] removalAmounts
  );

  /**
   * @notice Emitted on updating the addresses for contracts.
   * @param removal The address of the new Removal contract.
   */
  event ContractAddressesRegistered(IRemoval removal);

  /**
   * @notice Locks the contract, preventing any future re-initialization.
   * @dev See more [here](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--).
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the Certificate contract.
   * @param baseURI The base URI for all certificate NFTs.
   */
  function initialize(string memory baseURI)
    external
    initializerERC721A
    initializer
  {
    _baseURIValue = baseURI;
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721A_init_unchained("Certificate", "NCCR");
    __ERC721ABurnable_init_unchained();
    __ERC721AQueryable_init_unchained();
    __Pausable_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Multicall_init_unchained();
    _grantRole({role: DEFAULT_ADMIN_ROLE, account: _msgSender()});
    _grantRole({role: PAUSER_ROLE, account: _msgSender()});
    _grantRole({role: CERTIFICATE_OPERATOR_ROLE, account: _msgSender()});
  }

  /**
   * @notice Register the address of the Removal contract.
   * @dev This function emits a `ContractAddressesRegistered` event.
   *
   * ##### Requirements:
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `DEFAULT_ADMIN_ROLE` role.
   * @param removal The address of the Removal contract.
   */
  function registerContractAddresses(IRemoval removal)
    external
    whenNotPaused
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _removal = removal;
    emit ContractAddressesRegistered({removal: removal});
  }

  /**
   * @notice Receive a batch of child tokens.
   * @dev See [IERC1155Receiver](
   * https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155Receiver) for more.
   *
   * ##### Requirements:
   * - This contract must not be paused (enforced by `_beforeTokenTransfers`).
   * - `_msgSender` must be the removal contract.
   * - The certificate recipient and amount must be encoded in the `data` parameter.
   * @param removalIds The array of ERC1155 Removal IDs received.
   * @param removalAmounts The removal amounts per each removal ID.
   * @param data The bytes that encode the certificate's recipient address and total amount.
   * @return The selector of the function.
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata removalIds,
    uint256[] calldata removalAmounts,
    bytes calldata data
  ) external whenNotPaused returns (bytes4) {
    if (_msgSender() != address(_removal)) {
      revert SenderNotRemovalContract();
    }
    (address recipient, uint256 certificateAmount) = abi.decode(
      data,
      (address, uint256)
    );
    _receiveRemovalBatch({
      recipient: recipient,
      certificateAmount: certificateAmount,
      removalIds: removalIds,
      removalAmounts: removalAmounts
    });
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @notice Returns the address of the Removal contract.
   * @return The address of the Removal contract.
   */
  function removalAddress() external view returns (address) {
    return address(_removal);
  }

  function totalMinted() external view override returns (uint256) {
    return _totalMinted();
  }

  /**
   * @notice Returns the number of tonnes of carbon removals purchased.
   * @param certificateId The certificate for which to retrieve the original amount.
   * @return The tonnes of carbon removal purchased for the certificate.
   */
  function purchaseAmount(uint256 certificateId)
    external
    view
    returns (uint256)
  {
    return _purchaseAmounts[certificateId];
  }

  /**
   * @dev See [IERC165.supportsInterface](
   * https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165-supportsInterface-bytes4-) for more.
   * @param interfaceId The interface ID to check for support.
   * @return True if the interface is supported, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
      AccessControlEnumerableUpgradeable,
      ERC721AUpgradeable,
      IERC721AUpgradeable
    )
    returns (bool)
  {
    return
      super.supportsInterface({interfaceId: interfaceId}) ||
      interfaceId == 0x80ac58cd || // interface ID for ERC721
      interfaceId == 0x5b5e139f; // interface ID for ERC721Metadata
  }

  /**
   * @notice This function is unsupported and will always revert.
   * @dev Override to disable ERC721 operator approvals, since certificate tokens are non-transferable.
   */
  function setApprovalForAll(address, bool)
    public
    pure
    override(ERC721AUpgradeable, IERC721AUpgradeable)
  {
    revert FunctionDisabled();
  }

  /**
   * @notice This function is unsupported and will always revert.
   * @dev Override to disable ERC721 operator approvals, since certificate tokens are non-transferable.
   */
  function approve(address, uint256)
    public
    pure
    override(ERC721AUpgradeable, IERC721AUpgradeable)
  {
    revert FunctionDisabled();
  }

  /**
   * @notice A hook that is called before all transfers and is used to disallow non-minting, non-burning, and non-
   * certificate-operator (conferred by the `CERTIFICATE_OPERATOR_ROLE` role) transfers.
   * @dev Follows the rules of hooks defined [here](
   *  https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks).
   *
   * ##### Requirements:
   *
   * - This contract must not be paused.
   * - Can only be used when the caller has the `CERTIFICATE_OPERATOR_ROLE` role.
   * @param from The address of the sender.
   * @param to The address of the recipient.
   * @param startTokenId The ID of the first certificate in the transfer.
   * @param quantity The number of certificates in the transfer.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override whenNotPaused {
    bool isNotMinting = !(from == address(0));
    bool isNotBurning = !(to == address(0));
    bool isMissingOperatorRole = !hasRole({
      role: CERTIFICATE_OPERATOR_ROLE,
      account: _msgSender()
    });
    if (isNotMinting && isNotBurning && isMissingOperatorRole) {
      revert ForbiddenTransferAfterMinting();
    }
    super._beforeTokenTransfers({
      from: from,
      to: to,
      startTokenId: startTokenId,
      quantity: quantity
    });
  }

  /**
   * @notice Creates a new certificate for a batch of removals.
   * @dev Mints a new certificate token to the next sequential ID and updates the internal data structures
   * that track the relationship between the certificate and its constituent removal tokens and balances.
   *
   * Emits a `ReceiveRemovalBatch` event.
   * @param recipient The address receiving the new certificate.
   * @param certificateAmount The total number of tonnes of carbon removals represented by the new certificate.
   * @param removalIds The Removal token IDs that are being included in the certificate.
   * @param removalAmounts The balances of each corresponding removal token that are being included in the certificate.
   */
  function _receiveRemovalBatch(
    address recipient,
    uint256 certificateAmount,
    uint256[] calldata removalIds,
    uint256[] calldata removalAmounts
  ) internal {
    _validateReceivedRemovalBatch({
      removalIds: removalIds,
      removalAmounts: removalAmounts,
      certificateAmount: certificateAmount
    });
    uint256 certificateId = _nextTokenId();
    _purchaseAmounts[certificateId] = certificateAmount;
    _mint(recipient, 1);
    emit ReceiveRemovalBatch({
      from: _msgSender(),
      recipient: recipient,
      certificateId: certificateId,
      certificateAmount: certificateAmount,
      removalIds: removalIds,
      removalAmounts: removalAmounts
    });
  }

  /**
   * @notice Returns the sender of the transaction.
   * @dev In all cases currently, we expect that the `_msgSender()`, `_msgSenderERC721A()` and `msg.sender` all return
   * the same value. As such, this function exists solely for compatibility with OpenZeppelin and ERC721A
   * contracts. For more, see [here](https://github.com/chiru-labs/ERC721A/pull/281) and [here](
   * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol).
   * @return For regular transactions it returns `msg.sender` and for meta transactions it *can* be used to return the
   * end-user (rather than the relayer).
   */
  function _msgSenderERC721A() internal view override returns (address) {
    return _msgSender();
  }

  /**
   * @notice The baseUri for the certificate token.
   * @dev Base URI for computing `tokenURI`. If set, the resulting URI for each token will be the concatenation of the
   * `baseURI` and the `tokenId`. Empty by default, it can be overridden in child contracts.
   * @return The base URI for the certificate.
   */
  function _baseURI() internal view override returns (string memory) {
    return _baseURIValue;
  }

  /**
   * @notice Validates the incoming batch of removal token data by comparing the lengths of IDs and amounts.
   * @dev Reverts if the array lengths do not match.
   * @param removalIds Array of removal IDs.
   * @param removalAmounts Array of removal amounts.
   * @param certificateAmount The total number of tonnes of carbon removals represented by the new certificate.
   */
  function _validateReceivedRemovalBatch(
    uint256[] calldata removalIds,
    uint256[] calldata removalAmounts,
    uint256 certificateAmount
  ) internal pure {
    if (removalAmounts.sum() != certificateAmount) {
      revert("Incorrect supply allocation");
    }
    if (removalIds.length != removalAmounts.length) {
      revert ArrayLengthMismatch({
        array1Name: "removalIds",
        array2Name: "removalAmounts"
      });
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {RemovalIdLib} from "./RemovalIdLib.sol";
import {AddressArrayLib, UInt256ArrayLib} from "./ArrayLib.sol";
import "./Removal.sol";
import "./Errors.sol";

/**
 * @notice A data structure that stores the removals for a given year.
 * @param yearToRemovals A mapping from a year to the removals for that year.
 * @param earliestYear The earliest year for which there are removals.
 * @param latestYear The latest year for which there are removals.
 */
struct RemovalsByYear {
  mapping(uint256 => EnumerableSetUpgradeable.UintSet) yearToRemovals;
  uint256 earliestYear;
  uint256 latestYear;
}

/**
 * @title A library that provides a set of functions for managing removals by year.
 * @author Nori Inc.
 * @dev This library is used to manage the market's removal vintages.
 *
 * ##### Uses:
 *
 * - [EnumerableSetUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet) for
 * EnumerableSetUpgradeable.UintSet
 * - [AddressArrayLib](../docs/AddressArrayLib.md) for `address[]`
 * - [UInt256ArrayLib](../docs/UInt256ArrayLib.md) for `uint256[]`
 */
library RemovalsByYearLib {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using AddressArrayLib for address[];
  using UInt256ArrayLib for uint256[];

  uint256 private constant _DEFAULT_EARLIEST_YEAR = 2**256 - 1;
  uint256 private constant _DEFAULT_LATEST_YEAR = 0;

  /**
   * @notice Inserts a new removal into the collection.
   * @dev The removal is added to the Enumerable Set that maps to the year of its year.
   * @param collection the collection from storage.
   * @param removalId a new removal to insert.
   */
  function insert(RemovalsByYear storage collection, uint256 removalId)
    internal
  {
    uint256 year = RemovalIdLib.vintage({removalId: removalId});
    if (isEmpty({collection: collection})) {
      collection.earliestYear = year;
      collection.latestYear = year;
    } else if (year < collection.earliestYear) {
      collection.earliestYear = year;
    } else if (year > collection.latestYear) {
      collection.latestYear = year;
    }
    collection.yearToRemovals[year].add({value: removalId});
  }

  /**
   * @notice Removes a removal from the collection.
   * @dev Removes the removal from the Enumerable Set that corresponds to its year.
   * @param collection the collection to search through.
   * @param removalId the removal to remove.
   */
  function remove(RemovalsByYear storage collection, uint256 removalId)
    internal
  {
    uint256 year = RemovalIdLib.vintage({removalId: removalId});
    if (!collection.yearToRemovals[year].remove({value: removalId})) {
      revert RemovalNotFoundInYear({removalId: removalId, year: year});
    }
    // If all removals were removed, check to see if there are any updates to the struct we need to make.
    if (isEmptyForYear({collection: collection, year: year})) {
      if (collection.earliestYear == collection.latestYear) {
        // If there was only one year remaining, clear the values for latest and earliest years.
        collection.earliestYear = _DEFAULT_EARLIEST_YEAR;
        collection.latestYear = _DEFAULT_LATEST_YEAR;
      } else if (year == collection.earliestYear) {
        // If this was the earliest year, find the new earliest year and update the struct.
        for (
          uint256 currentYear = collection.earliestYear + 1;
          currentYear <= collection.latestYear;
          ++currentYear
        ) {
          if (collection.yearToRemovals[currentYear].length() > 0) {
            collection.earliestYear = currentYear;
            break;
          }
        }
      } else if (year == collection.latestYear) {
        // If this was the latest year, find the new latest year and update the struct.
        for (
          uint256 currentYear = collection.latestYear - 1;
          currentYear >= collection.earliestYear;
          currentYear--
        ) {
          if (collection.yearToRemovals[currentYear].length() > 0) {
            collection.latestYear = currentYear;
            break;
          }
        }
      }
    }
  }

  /**
   * @notice Checks if the collection is empty across all years.
   * @dev Uses the latestYear property to check if any years have been set.
   * @param collection the collection from storage.
   * @return True if empty, false otherwise.
   */
  function isEmpty(RemovalsByYear storage collection)
    internal
    view
    returns (bool)
  {
    return collection.latestYear == _DEFAULT_LATEST_YEAR;
  }

  /**
   * @notice Checks if the collection is empty for a particular year.
   * @param collection the collection from storage.
   * @param year the year to check.
   * @return True if empty, false otherwise.
   */
  function isEmptyForYear(RemovalsByYear storage collection, uint256 year)
    internal
    view
    returns (bool)
  {
    return getCountForYear({collection: collection, year: year}) == 0;
  }

  /**
   * @notice Gets the next removal in the collection for sale.
   * @dev Gets the first item from the Enumerable Set that corresponds to the earliest year.
   * @param collection the collection from storage.
   * @return The next removal to sell.
   */
  function getNextRemovalForSale(RemovalsByYear storage collection)
    internal
    view
    returns (uint256)
  {
    return collection.yearToRemovals[collection.earliestYear].at({index: 0});
  }

  /**
   * @notice Gets the count of unique removal IDs for a particular year.
   * @dev Gets the size of the Enumerable Set that corresponds to the given year.
   * @param collection the collection from storage.
   * @param year the year to check.
   * @return uint256 the size of the collection.
   */
  function getCountForYear(RemovalsByYear storage collection, uint256 year)
    internal
    view
    returns (uint256)
  {
    return collection.yearToRemovals[year].length();
  }

  /**
   * @notice Gets all removal IDs belonging to all vintages for a collection.
   * @param collection the collection from storage.
   * @return removalIds an array of all removal IDs in the collection.
   */
  function getAllRemovalIds(RemovalsByYear storage collection)
    internal
    view
    returns (uint256[] memory removalIds)
  {
    uint256 latestYear = collection.latestYear;
    EnumerableSetUpgradeable.UintSet storage removalIdSet;
    uint256 totalNumberOfRemovals = 0;
    uint256 nextInsertIndex = 0;
    for (uint256 year = collection.earliestYear; year <= latestYear; ++year) {
      removalIdSet = collection.yearToRemovals[year];
      totalNumberOfRemovals += removalIdSet.length();
    }
    uint256[] memory ids = new uint256[](totalNumberOfRemovals);
    for (uint256 year = collection.earliestYear; year <= latestYear; ++year) {
      removalIdSet = collection.yearToRemovals[year];
      // Skip overflow check as for loop is indexed starting at zero.
      unchecked {
        for (uint256 i = 0; i < removalIdSet.length(); ++i) {
          ids[nextInsertIndex++] = removalIdSet.at({index: i});
        }
      }
    }
    return ids;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IMarket {
  /**
   * @notice Get the RestrictedNORI contract address.
   * @return Returns the address of the RestrictedNORI contract.
   */
  function restrictedNoriAddress() external view returns (address);

  /**
   * @notice Releases a removal from the market.
   * @dev This function is called by the Removal contract when releasing removals.
   *
   * @param removalId The ID of the removal to release.
   * @param amount The amount of that removal to release.
   */
  function release(uint256 removalId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import {UnsupportedIdVersion, MethodologyVersionTooLarge, MethodologyTooLarge, UncapitalizedString} from "./Errors.sol";

/**
 * @notice Decoded removal data.
 * @dev Every removal is minted using this struct. The struct then undergoes bit-packing to create the removal ID.
 * @param idVersion The removal ID version.
 * @param methodology The removal's methodology type.
 * @param methodologyVersion The removal methodology type's version.
 * @param vintage The vintage of the removal.
 * @param country The country that the removal occurred in.
 * @param subdivision The subdivision of the country that the removal occurred in.
 * @param supplierAddress The supplier's original wallet address.
 * @param subIdentifier A unique sub-identifier (e.g., the parcel/field identifier).
 */
struct DecodedRemovalIdV0 {
  uint8 idVersion;
  uint8 methodology;
  uint8 methodologyVersion;
  uint16 vintage;
  bytes2 country;
  bytes2 subdivision;
  address supplierAddress;
  uint32 subIdentifier;
}

/**
 * @title A library for working with Removal IDs.
 * @author Nori Inc.
 * @notice Library encapsulating the logic around encoding and decoding removal IDs.
 * @dev The token IDs used for a given ERC1155 token in Removal encode information about the carbon removal in the
 * following format(s), where the first byte encodes the format version:
 *
 * ##### Removal ID Version 0:
 *
 * | Bytes Label | Description                                                 |
 * | ----------- | ----------------------------------------------------------- |
 * | tokIdV      | The token/removal ID version.                               |
 * | meth&v      | The removal's methodology version.                          |
 * | vintage     | The vintage of the removal.                                 |
 * | country     | The country that the removal occurred in.                   |
 * | subdiv      | The subdivision of the country that the removal occurred in.|
 * | supplier    | The supplier's original wallet address.                     |
 * | subid       | A unique sub-identifier (e.g., the parcel/field identifier).|
 *
 * | tokIdV | meth&v | vintage | country | subdiv  | supplier | subid   |
 * | ------ | ------ | ------- | ------- | ------- | -------- | ------- |
 * | 1 byte | 1 byte | 2 bytes | 2 bytes | 2 bytes | 20 bytes | 4 bytes |
 */
library RemovalIdLib {
  using RemovalIdLib for DecodedRemovalIdV0;

  /**
   * @notice The number of bits per byte.
   */
  uint256 public constant BITS_PER_BYTE = 8;
  /**
   * @notice The number of bytes allocated to the token/removal ID version.
   */
  uint256 public constant ID_VERSION_FIELD_LENGTH = 1;
  /**
   * @notice The number of bytes allocated to the methodology version.
   */
  uint256 public constant METHODOLOGY_DATA_FIELD_LENGTH = 1;
  /**
   * @notice The number of bytes allocated to the vintage.
   */
  uint256 public constant VINTAGE_FIELD_LENGTH = 2;
  /**
   * @notice The number of bytes allocated to the ISO 3166-2 country code.
   */
  uint256 public constant COUNTRY_CODE_FIELD_LENGTH = 2;
  /**
   * @notice The number of bytes allocated to the administrative region of the ISO 3166-2 subdivision.
   */
  uint256 public constant ADMIN1_CODE_FIELD_LENGTH = 2;
  /**
   * @notice The number of bytes allocated to the supplier's original wallet address.
   */
  uint256 public constant ADDRESS_FIELD_LENGTH = 20;
  /**
   * @notice The number of bytes allocated to the sub-identifier.
   */
  uint256 public constant SUBID_FIELD_LENGTH = 4;
  /**
   * @notice The bit offset of the ID version.
   */
  uint256 public constant ID_VERSION_OFFSET = 31;
  /**
   * @notice The bit offset of the methodology data.
   */
  uint256 public constant METHODOLOGY_DATA_OFFSET = 30;
  /**
   * @notice The bit offset of the vintage.
   */
  uint256 public constant VINTAGE_OFFSET = 28;
  /**
   * @notice The bit offset of the country code.
   */
  uint256 public constant COUNTRY_CODE_OFFSET = 26;
  /**
   * @notice The bit offset of the administrative region code.
   */
  uint256 public constant ADMIN1_CODE_OFFSET = 24;
  /**
   * @notice The bit offset of the original supplier wallet address.
   */
  uint256 public constant ADDRESS_OFFSET = 4;
  /**
   * @notice The bit offset of the sub-identifier.
   */
  uint256 public constant SUBID_OFFSET = 0;

  /**
   * @notice Check whether the provided character bytes are capitalized.
   * @param characters the character bytes to check.
   * @return valid True if the provided character bytes are capitalized, false otherwise.
   */
  function isCapitalized(bytes2 characters) internal pure returns (bool valid) {
    assembly {
      let firstCharacter := byte(0, characters)
      let secondCharacter := byte(1, characters)
      valid := and(
        and(lt(firstCharacter, 0x5B), gt(firstCharacter, 0x40)),
        and(lt(secondCharacter, 0x5B), gt(secondCharacter, 0x40))
      )
    }
  }

  /**
   * @notice Validate the removal struct.
   * @param removal The removal struct to validate.
   */
  function validate(DecodedRemovalIdV0 memory removal) internal pure {
    if (removal.idVersion != 0) {
      revert UnsupportedIdVersion({idVersion: removal.idVersion});
    }
    if (removal.methodologyVersion > 15) {
      revert MethodologyVersionTooLarge({
        methodologyVersion: removal.methodologyVersion
      });
    }
    if (removal.methodology > 15) {
      revert MethodologyTooLarge({methodology: removal.methodology});
    }
    if (
      !(isCapitalized({characters: removal.country}) &&
        isCapitalized({characters: removal.subdivision}))
    ) {
      revert UncapitalizedString({
        country: removal.country,
        subdivision: removal.subdivision
      });
    }
  }

  /**
   * @notice Packs data about a removal into a 256-bit removal ID for the removal.
   * @dev Performs some possible validations on the data before attempting to create the ID.
   * @param removal A removal in `DecodedRemovalIdV0` notation.
   * @return The removal ID.
   */
  function createRemovalId(
    DecodedRemovalIdV0 memory removal // todo rename create
  ) internal pure returns (uint256) {
    removal.validate();
    uint256 methodologyData = (removal.methodology << 4) |
      removal.methodologyVersion;
    return
      (uint256(removal.idVersion) << (ID_VERSION_OFFSET * BITS_PER_BYTE)) |
      (uint256(methodologyData) << (METHODOLOGY_DATA_OFFSET * BITS_PER_BYTE)) |
      (uint256(removal.vintage) << (VINTAGE_OFFSET * BITS_PER_BYTE)) |
      (uint256(uint16(removal.country)) <<
        (COUNTRY_CODE_OFFSET * BITS_PER_BYTE)) |
      (uint256(uint16(removal.subdivision)) <<
        (ADMIN1_CODE_OFFSET * BITS_PER_BYTE)) |
      (uint256(uint160(removal.supplierAddress)) <<
        (ADDRESS_OFFSET * BITS_PER_BYTE)) |
      (uint256(removal.subIdentifier) << (SUBID_OFFSET * BITS_PER_BYTE));
  }

  /**
   * @notice Unpacks a V0 removal ID into its component data.
   * @param removalId The removal ID to unpack.
   * @return The removal ID in `DecodedRemovalIdV0` notation.
   */
  function decodeRemovalIdV0(uint256 removalId)
    internal
    pure
    returns (DecodedRemovalIdV0 memory)
  {
    return
      DecodedRemovalIdV0(
        version({removalId: removalId}),
        methodology({removalId: removalId}),
        methodologyVersion({removalId: removalId}),
        vintage({removalId: removalId}),
        countryCode({removalId: removalId}),
        subdivisionCode({removalId: removalId}),
        supplierAddress({removalId: removalId}),
        subIdentifier({removalId: removalId})
      );
  }

  /**
   * @notice Extracts and returns the version field of a removal ID.
   * @param removalId The removal ID to extract the version field from.
   * @return The version field of the removal ID.
   */
  function version(uint256 removalId) internal pure returns (uint8) {
    return
      uint8(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: ID_VERSION_FIELD_LENGTH,
          numBytesOffsetFromRight: ID_VERSION_OFFSET
        })
      );
  }

  /**
   * @notice Extracts and returns the methodology field of a removal ID.
   * @param removalId The removal ID to extract the methodology field from.
   * @return The methodology field of the removal ID.
   */
  function methodology(uint256 removalId) internal pure returns (uint8) {
    return
      uint8(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: METHODOLOGY_DATA_FIELD_LENGTH,
          numBytesOffsetFromRight: METHODOLOGY_DATA_OFFSET
        }) >> 4
      ); // methodology encoded in the first nibble
  }

  /**
   * @notice Extracts and returns the methodology version field of a removal ID.
   * @param removalId The removal ID to extract the methodology version field from.
   * @return The methodology version field of the removal ID.
   */
  function methodologyVersion(uint256 removalId) internal pure returns (uint8) {
    return
      uint8(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: METHODOLOGY_DATA_FIELD_LENGTH,
          numBytesOffsetFromRight: METHODOLOGY_DATA_OFFSET
        }) & (2**4 - 1)
      ); // methodology version encoded in the second nibble
  }

  /**
   * @notice Extracts and returns the vintage field of a removal ID.
   * @param removalId The removal ID to extract the vintage field from.
   * @return The vintage field of the removal ID.
   */
  function vintage(uint256 removalId) internal pure returns (uint16) {
    return
      uint16(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: VINTAGE_FIELD_LENGTH,
          numBytesOffsetFromRight: VINTAGE_OFFSET
        })
      );
  }

  /**
   * @notice Extracts and returns the country code field of a removal ID.
   * @param removalId The removal ID to extract the country code field from.
   * @return The country code field of the removal ID.
   */
  function countryCode(uint256 removalId) internal pure returns (bytes2) {
    return
      bytes2(
        uint16(
          _extractValue({
            removalId: removalId,
            numBytesFieldLength: COUNTRY_CODE_FIELD_LENGTH,
            numBytesOffsetFromRight: COUNTRY_CODE_OFFSET
          })
        )
      );
  }

  /**
   * @notice Extracts and returns the subdivision field of a removal ID.
   * @param removalId The removal ID to extract the subdivision field from.
   * @return The subdivision field of the removal ID.
   */
  function subdivisionCode(uint256 removalId) internal pure returns (bytes2) {
    return
      bytes2(
        uint16(
          _extractValue({
            removalId: removalId,
            numBytesFieldLength: ADMIN1_CODE_FIELD_LENGTH,
            numBytesOffsetFromRight: ADMIN1_CODE_OFFSET
          })
        )
      );
  }

  /**
   * @notice Extracts and returns the supplier address field of a removal ID.
   * @param removalId The removal ID to extract the supplier address field from.
   * @return The supplier address field of the removal ID.
   */
  function supplierAddress(uint256 removalId) internal pure returns (address) {
    return
      address(
        uint160(
          _extractValue({
            removalId: removalId,
            numBytesFieldLength: ADDRESS_FIELD_LENGTH,
            numBytesOffsetFromRight: ADDRESS_OFFSET
          })
        )
      );
  }

  /**
   * @notice Extract and returns the `subIdentifier` field of a removal ID.
   * @param removalId The removal ID to extract the sub-identifier field from.
   * @return The sub-identifier field of the removal ID.
   */
  function subIdentifier(uint256 removalId) internal pure returns (uint32) {
    return
      uint32(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: SUBID_FIELD_LENGTH,
          numBytesOffsetFromRight: SUBID_OFFSET
        })
      );
  }

  /**
   * @notice Extract a field of the specified length in bytes, at the specified location, from a removal ID.
   * @param removalId The removal ID to extract the field from.
   * @param numBytesFieldLength The number of bytes in the field to extract.
   * @param numBytesOffsetFromRight The number of bytes to offset the field from the right.
   * @return The extracted field value.
   */
  function _extractValue(
    uint256 removalId,
    uint256 numBytesFieldLength,
    uint256 numBytesOffsetFromRight
  ) private pure returns (uint256) {
    bytes32 mask = bytes32(2**(numBytesFieldLength * BITS_PER_BYTE) - 1) <<
      (numBytesOffsetFromRight * BITS_PER_BYTE);
    bytes32 maskedValue = bytes32(removalId) & mask;
    return uint256(maskedValue >> (numBytesOffsetFromRight * BITS_PER_BYTE));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "./AccessPresetPausable.sol";
import "./Errors.sol";
import "./IMarket.sol";
import "./ICertificate.sol";
import "./IRemoval.sol";
import "./IRestrictedNORI.sol";
import {RemovalIdLib, DecodedRemovalIdV0} from "./RemovalIdLib.sol";

/**
 * @title An extended ERC1155 token contract for carbon removal accounting.
 * @author Nori Inc.
 * @notice This contract uses ERC1155 tokens as an accounting system for keeping track of carbon that Nori has
 * verified to have been removed from the atmosphere. Each token ID encodes information about the source of the
 * removed carbon (see the [RemovalIdLib docs](../docs/RemovalIdLib.md) for encoding details), and each token represents
 * the smallest unit of carbon removal accounting.  For example, in an agricultural methodology, a specific token ID
 * represents one parcel of land in a specific year.  The total supply of that token ID is the number of tonnes of
 * carbon removed.
 *
 * ##### Additional behaviors and features:
 *
 * ###### Minting
 * - Only accounts with the CONSIGNOR_ROLE can mint removal tokens, which should only be account(s) controlled by Nori.
 * - When removal tokens are minted, additional data about those removals are stored in a mapping keyed by the token ID,
 * such as a project ID and a holdback percentage (which determines the percentage of the sale proceeds from the token
 * that will be routed to the RestrictedNORI contract). A restriction schedule is created per `projectId` (if necessary)
 * in RestrictedNORI (see the [RestrictedNORI docs](../docs/RestrictedNORI.md)).
 * - Minting reverts when attempting to mint a token ID that already exists.
 * - The function `addBalance` can be used to mint additional balance to a token ID that already exists.
 *
 *
 * ###### Listing
 * - _Listing_ refers to the process of listing removal tokens for sale in Nori's marketplace (the Market contract).
 * - Removals are listed for sale by transferring ownership of the tokens to the Market contract via
 * `consign`. Alternatively, If the `to` argument to `mintBatch` is the address of the Market contract,
 * removal tokens will be listed in the same transaction that they are minted.
 * - Only accounts with the CONSIGNOR_ROLE can list removals for sale in the market.
 *
 *
 * ###### Releasing
 * - _Releasing_ refers to the process of accounting for carbon that has failed to meet its permanence guarantee
 * and has been released into the atmosphere prematurely.
 * - This accounting is performed by burning the affected balance of a removal that has been released.
 * - Only accounts with the RELEASER_ROLE can initiate a release.
 * - When a removal token is released, balances are burned in a specific order until the released amount
 * has been accounted for: Releasing burns first from unlisted balances, second from listed balances and third from the
 * certificate contract (see `Removal.release` for more).
 * - Affected certificates will have any released balances replaced by new removals purchased by Nori, though an
 * automated implementation of this process is beyond the scope of this version of the contracts.
 *
 *
 * ###### Token ID encoding and decoding
 * - This contract uses the inlined library RemovalIdLib for uint256.
 * - When minting tokens, an array of structs containing information about each removal is passed as an argument to
 * `mintBatch` and that data is used to generate the encoded token IDs for each removal.
 * - `decodeRemovalIdV0` is exposed externally for encoding and decoding Removal token IDs that contain uniquely
 * identifying information about the removal. See the [RemovalIdLib docs](../docs/RemovalIdLib.md) for encoding details.
 *
 * ###### Additional behaviors and features
 *
 * - [ERC-1155 functionality](https://eips.ethereum.org/EIPS/eip-1155)
 * - [Upgradeable](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance)
 * - [Pausable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable): all functions that mutate state are
 * pausable
 * - [Role-based access control](https://docs.openzeppelin.com/contracts/4.x/access-control)
 * - `CONSIGNOR_ROLE`: Can mint removal tokens and list them for sale in the Market contract.
 * - `RELEASER_ROLE`: Can release partial or full removal balances.
 * - `PAUSER_ROLE`: Can pause and unpause the contract.
 * - `DEFAULT_ADMIN_ROLE`: This is the only role that can add/revoke other accounts to any of the roles.
 *
 * ##### Inherits:
 *
 * - [ERC1155Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc11555)
 * - [ERC1155Supply](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155Supply)
 * - [MulticallUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/access)
 * - [ContextUpgradeable](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable)
 * - [ERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#ERC165)
 *
 * ##### Implements:
 *
 * - [IERC1155Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155)
 * - [IERC1155MetadataURI](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155MetadataURI)
 * - [IAccessControlEnumerable](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 * - [IERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165)
 *
 * ##### Uses:
 *
 * - [MathUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Math)
 * - [EnumerableSetUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet) for
 * `EnumerableSetUpgradeable.UintSet`
 */
contract Removal is
  IRemoval,
  ERC1155SupplyUpgradeable,
  AccessPresetPausable,
  MulticallUpgradeable
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  /**
   * @notice Role conferring the ability to mint removals as well as the ability to list minted removals that have yet
   * to be listed for sale.
   */
  bytes32 public constant CONSIGNOR_ROLE = keccak256("CONSIGNOR_ROLE");

  /**
   * @notice Role conferring the ability to mark a removal as released.
   */
  bytes32 public constant RELEASER_ROLE = keccak256("RELEASER_ROLE");

  /**
   * @notice The Market contract that removals can be bought and sold from.
   */
  IMarket internal _market;

  /**
   * @notice The Certificate contract that removals are retired into.
   */
  ICertificate private _certificate;

  /**
   * @dev Maps from a given project ID to the holdback percentage that will be used to determine what percentage of
   * proceeds are routed to the RestrictedNORI contract when removals from this project are sold.
   */
  mapping(uint256 => uint8) private _projectIdToHoldbackPercentage;

  /**
   * @dev Maps from a removal ID to the project ID it belongs to.
   */
  mapping(uint256 => uint256) private _removalIdToProjectId;

  /**
   * @notice Maps from an address to an EnumerableSet of the token IDs for which that address has a non-zero balance.
   */
  mapping(address => EnumerableSetUpgradeable.UintSet)
    private _addressToOwnedTokenIds;

  /**
   * @notice The current balance of across all removals listed in the market contract.
   */
  uint256 private _currentMarketBalance;

  /**
   * @notice Emitted on updating the addresses for contracts.
   * @param market The address of the new market contract.
   * @param certificate The address of the new certificate contract.
   */
  event ContractAddressesRegistered(IMarket market, ICertificate certificate);

  /**
   * @notice Emitted on releasing a removal from a supplier, the market, or a certificate.
   * @param id The id of the removal that was released.
   * @param fromAddress The address the removal was released from.
   * @param amount The amount that was released.
   */
  event RemovalReleased(
    uint256 indexed id,
    address indexed fromAddress,
    uint256 amount
  );

  /**
   * @notice Emitted when legacy removals are minted and then immediately used to migrate a legacy certificate.
   * @param certificateRecipient The recipient of the certificate to mint via migration.
   * @param certificateAmount The total amount of the certificate to mint via migration (denominated in NRTs).
   * @param certificateId The ID of the certificate to mint via migration.
   * @param removalIds The removal IDs to use to mint the certificate via migration.
   * @param removalAmounts The amounts for each corresponding removal ID to use to mint the certificate via migration.
   */
  event Migrate(
    address indexed certificateRecipient,
    uint256 indexed certificateAmount,
    uint256 indexed certificateId,
    uint256[] removalIds,
    uint256[] removalAmounts
  );

  /**
   * @notice Locks the contract, preventing any future re-initialization.
   * @dev See more [here](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--).
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializes the Removal contract.
   * @param baseURI The base URI for the removal NFTs.
   */
  function initialize(string memory baseURI) external initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC1155_init_unchained({uri_: string(abi.encodePacked(baseURI, "{id}"))});
    __Pausable_init_unchained();
    __ERC1155Supply_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Multicall_init_unchained();
    _grantRole({role: DEFAULT_ADMIN_ROLE, account: _msgSender()});
    _grantRole({role: PAUSER_ROLE, account: _msgSender()});
    _grantRole({role: CONSIGNOR_ROLE, account: _msgSender()});
    _grantRole({role: RELEASER_ROLE, account: _msgSender()});
  }

  /**
   * @notice Registers the market and certificate contracts so that they can be referenced in this contract.
   * Called as part of the market contract system deployment process.
   * @dev Emits a `ContractAddressesRegistered` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the caller has the `DEFAULT_ADMIN_ROLE` role.
   * - Can only be used when this contract is not paused.
   * @param market The address of the Market contract.
   * @param certificate The address of the Certificate contract.
   */
  function registerContractAddresses(IMarket market, ICertificate certificate)
    external
    whenNotPaused
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _market = market;
    _certificate = certificate;
    emit ContractAddressesRegistered({
      market: market,
      certificate: certificate
    });
  }

  /**
   * @notice Mints multiple removals at once (for a single supplier).
   * @dev If `to` is the market address, the removals are listed for sale in the market.
   *
   * ##### Requirements:
   * - Can only be used when the caller has the `CONSIGNOR_ROLE`
   * - Enforces the rules of `Removal._beforeTokenTransfer`
   * - Can only be used when this contract is not paused
   * - Cannot mint to a removal ID that already exists (use `addBalance` instead).
   * @param to The recipient of this batch of removals. Should be the supplier's address or the market address.
   * @param amounts Each removal's tonnes of CO2 formatted.
   * @param removals The removals to mint (represented as an array of `DecodedRemovalIdV0`). These removals are used
   * to encode the removal IDs.
   * @param projectId The project ID for this batch of removals.
   * @param scheduleStartTime The start time of the schedule for this batch of removals.
   * @param holdbackPercentage The holdback percentage for this batch of removals.
   */
  function mintBatch(
    address to,
    uint256[] calldata amounts,
    DecodedRemovalIdV0[] calldata removals,
    uint256 projectId,
    uint256 scheduleStartTime,
    uint8 holdbackPercentage
  ) external whenNotPaused onlyRole(CONSIGNOR_ROLE) {
    uint256[] memory ids = _createRemovals({
      removals: removals,
      projectId: projectId
    });
    if (holdbackPercentage > 100) {
      revert InvalidHoldbackPercentage({
        holdbackPercentage: holdbackPercentage
      });
    }
    _projectIdToHoldbackPercentage[projectId] = holdbackPercentage;
    _mintBatch({to: to, ids: ids, amounts: amounts, data: ""});
    IRestrictedNORI _restrictedNORI = IRestrictedNORI(
      _market.restrictedNoriAddress()
    );
    if (!_restrictedNORI.scheduleExists({scheduleId: projectId})) {
      _restrictedNORI.createSchedule({
        projectId: projectId,
        startTime: scheduleStartTime,
        methodology: removals[0].methodology,
        methodologyVersion: removals[0].methodologyVersion
      });
    }
  }

  /**
   * @notice Mints additional balance for multiple removals at once.
   * @dev If `to` is the market address, the removals are listed for sale in the market.
   *
   * ##### Requirements:
   * - Can only be used when the caller has the `CONSIGNOR_ROLE` role.
   * - Can only be used when this contract is not paused.
   * - IDs must already have been minted via `mintBatch`.
   * - Enforces the rules of `Removal._beforeTokenTransfer`.
   * @param to The supplier address or market address.
   * @param amounts Each removal's additional tonnes of CO2 formatted.
   * @param ids The removal IDs to add balance for.
   */
  function addBalance(
    address to,
    uint256[] calldata amounts,
    uint256[] calldata ids
  ) external whenNotPaused onlyRole(CONSIGNOR_ROLE) {
    for (uint256 i = 0; i < ids.length; ++i) {
      if (_removalIdToProjectId[ids[i]] == 0) {
        revert RemovalNotYetMinted({tokenId: ids[i]});
      }
    }
    _mintBatch({to: to, ids: ids, amounts: amounts, data: ""});
  }

  /**
   * @notice Lists the provided `amount` of the specified removal `id` for sale in Nori's marketplace.
   * @dev The Market contract implements `onERC1155Received`, which is invoked upon receipt of any tokens from
   * this contract, and handles the mechanics of listing this token for sale.
   * @param from The current owner of the specified token ID and amount
   * @param id The token ID of the removal token being listed for sale
   * @param amount The balance of this token ID to transfer to the Market contract
   */
  function consign(
    address from,
    uint256 id,
    uint256 amount
  ) external whenNotPaused onlyRole(CONSIGNOR_ROLE) {
    if (from == address(_certificate) || from == address(_market)) {
      revert RemovalAlreadySoldOrConsigned({tokenId: id});
    }
    _safeTransferFrom({
      from: from,
      to: address(_market),
      id: id,
      amount: amount,
      data: ""
    });
  }

  /**
   * @notice Transfers the provided `amounts` (denominated in NRTs) of the specified removal `ids` directly to the
   * Certificate contract to mint a legacy certificate. This function provides Nori the ability to execute a one-off
   * migration of legacy certificates and removals (legacy certificates and removals are those which existed prior to
   * our deployment to Polygon and covers all historic issuances and purchases up until the date that we start using the
   * Market contract).
   * @dev The Certificate contract implements `onERC1155BatchReceived`, which is invoked upon receipt of a batch of
   * removals (triggered via `_safeBatchTransferFrom`). This function circumvents the market contract's lifecycle by
   * transferring the removals from an account with the `CONSIGNOR_ROLE` role.
   *
   * It is necessary that the consignor holds the removals because of the following:
   * - `ids` can be composed of a list of removal IDs that belong to one or more suppliers.
   * - `_safeBatchTransferFrom` only accepts one `from` address.
   * - `Certificate.onERC1155BatchReceived` will mint a *new* certificate every time an additional batch is received, so
   * we must ensure that all the removals comprising the certificate to be migrated come from a single batch.
   *
   * ##### Requirements:
   * - The caller must have the `CONSIGNOR_ROLE` role.
   * - The contract must not be paused.
   * - The specified removal IDs must exist (e.g., via a prior call to the `mintBatch` function).
   * - The rules of `Removal._beforeTokenTransfer` are enforced.
   * @param ids An array of the removal IDs to add to transfer to the Certificate contract. This array can contain IDs
   * of removals that belong to one or more supplier address (designated in the encoding of the removal ID).
   * @param amounts An array of the removal amounts to add to transfer to the Certificate contract. Each amount in this
   * array corresponds to the removal ID with the same index in the `ids` parameter.
   * @param certificateRecipient The recipient of the certificate to be minted.
   * @param certificateAmount The total amount of the certificate.
   */
  function migrate(
    uint256[] calldata ids,
    uint256[] calldata amounts,
    address certificateRecipient,
    uint256 certificateAmount
  ) external whenNotPaused onlyRole(CONSIGNOR_ROLE) {
    emit Migrate({
      certificateRecipient: certificateRecipient,
      certificateAmount: certificateAmount,
      certificateId: _certificate.totalMinted(),
      removalIds: ids,
      removalAmounts: amounts
    });
    _safeBatchTransferFrom({
      from: _msgSender(),
      to: address(_certificate),
      ids: ids,
      amounts: amounts,
      data: abi.encode(certificateRecipient, certificateAmount)
    });
  }

  /**
   * @notice Accounts for carbon that has failed to meet its permanence guarantee and has been released into
   * the atmosphere prematurely.
   * @dev Releases `amount` of removal `id` by burning it. The replacement of released removals that had
   * already been included in certificates is beyond the scope of this version of the contracts.
   *
   * ##### Requirements:
   *
   * - Releasing burns first from unlisted balances, second from listed balances and third from certificates.
   * - If there is unlisted balance for this removal (e.g., owned by the supplier address encoded in the token ID),
   * that balance is burned up to `amount`.
   * - If the released amount has not yet been fully burned and the removal is listed, it is delisted from the market
   * and up to any remaining released amount is burned from the Market's balance.
   * - Finally, if the released amount is still not fully accounted for, the removal must be owned by one or more
   * certificates. The remaining released amount is burned from the Certificate contract's balance.
   * - The caller must have the `RELEASER_ROLE`.
   * - The rules of `_burn` are enforced.
   * - Can only be used when the contract is not paused.
   * @param id The ID of the removal to release some amount of.
   * @param amount The amount of the removal to release.
   */
  function release(uint256 id, uint256 amount)
    external
    whenNotPaused
    onlyRole(RELEASER_ROLE)
  {
    uint256 amountReleased = 0;
    uint256 unlistedBalance = balanceOf({
      account: RemovalIdLib.supplierAddress(id),
      id: id
    });
    if (unlistedBalance > 0) {
      uint256 amountToRelease = MathUpgradeable.min({
        a: amount,
        b: unlistedBalance
      });
      _releaseFromSupplier({id: id, amount: amountToRelease});
      amountReleased += amountToRelease;
    }
    if (amountReleased < amount) {
      uint256 listedBalance = balanceOf({
        account: this.marketAddress(),
        id: id
      });
      if (listedBalance > 0) {
        uint256 amountToRelease = MathUpgradeable.min({
          a: amount - amountReleased,
          b: listedBalance
        });
        _releaseFromMarket({amount: amountToRelease, id: id});
        amountReleased += amountToRelease;
      }
      if (amountReleased < amount) {
        if (balanceOf({account: this.certificateAddress(), id: id}) > 0) {
          uint256 amountToRelease = amount - amountReleased;
          _releaseFromCertificate({id: id, amount: amount - amountReleased});
          amountReleased += amountToRelease;
        }
      }
    }
  }

  /**
   * @notice Get the address of the Market contract.
   * @return The address of the Market contract.
   */
  function marketAddress() external view returns (address) {
    return address(_market);
  }

  /**
   * @notice Get the address of the Certificate contract.
   * @return The address of the Certificate contract.
   */
  function certificateAddress() external view returns (address) {
    return address(_certificate);
  }

  /**
   * @notice Get the project ID (which is the removal's schedule ID in RestrictedNORI) for a given removal ID.
   * @param id The removal token ID for which to retrieve the project ID.
   * @return The project ID for the removal token ID.
   */
  function getProjectId(uint256 id) external view override returns (uint256) {
    return _removalIdToProjectId[id];
  }

  /**
   * @notice Gets the holdback percentage for a removal.
   * @param id The removal token ID for which to retrieve the holdback percentage.
   * @return The holdback percentage for the removal token ID.
   */
  function getHoldbackPercentage(uint256 id) external view returns (uint8) {
    return _projectIdToHoldbackPercentage[_removalIdToProjectId[id]];
  }

  /**
   * @notice The current total balance of all removal tokens owned by the Market contract.
   * This sum is maintained as a running total for efficient lookup during purchases.
   * @return The total balance of all removal tokens owned by the Market contract.
   */
  function getMarketBalance() external view returns (uint256) {
    return _currentMarketBalance;
  }

  /**
   * @notice Returns an array of all token IDs currently owned by `owner`.
   * @param owner The account for which to retrieve owned token IDs.
   * @return An array of all Removal token IDs currently owned by `owner`.
   */
  function getOwnedTokenIds(address owner)
    external
    view
    returns (uint256[] memory)
  {
    return _addressToOwnedTokenIds[owner].values();
  }

  /**
   * @notice The number of unique token IDs owned by the given `account`.
   * Maintained for efficient lookup of the number of distinct removal tokens owned by the Market.
   * @param account The account for which to retrieve the unique number of token IDs owned.
   * @return The number of unique Removal token IDs owned by the given `account`.
   */
  function numberOfTokensOwnedByAddress(address account)
    external
    view
    returns (uint256)
  {
    return _addressToOwnedTokenIds[account].length();
  }

  /**
   * @notice Decodes a V0 removal ID into its component data.
   * @param id The removal ID to decode.
   * @return The decoded removal ID data.
   */
  function decodeRemovalIdV0(uint256 id)
    external
    pure
    returns (DecodedRemovalIdV0 memory)
  {
    return RemovalIdLib.decodeRemovalIdV0({removalId: id});
  }

  /**
   * @notice Transfers `amount` tokens of token type `id` from `from` to `to`.
   * @dev Calls `ERC1155Upgradeable.safeTransferFrom`
   *
   * Emits a `TransferSingle` event.
   *
   * ##### Requirements:
   *
   * - Can only be called by the Market contract.
   * - `to` cannot be the zero address.
   * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via `setApprovalForAll`.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement `IERC1155Receiver.onERC1155Received` and return the
   * acceptance magic value.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param id The removal ID to transfer.
   * @param amount The amount of removals to transfer.
   * @param data The data to pass to the receiver contract.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override whenNotPaused {
    if (_msgSender() != address(_market)) {
      revert ForbiddenTransfer();
    }
    super.safeTransferFrom({
      from: from,
      to: to,
      id: id,
      amount: amount,
      data: data
    });
  }

  /**
   * @notice Batched version of `safeTransferFrom`.
   * @dev Emits a `TransferBatch` event.
   *
   * ##### Requirements:
   *
   * - Can only be called by the Market contract.
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param ids The removal IDs to transfer.
   * @param amounts The amounts of removals to transfer.
   * @param data The data to pass to the receiver contract.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public override whenNotPaused {
    if (_msgSender() != address(_market)) {
      revert ForbiddenTransfer();
    }
    super.safeBatchTransferFrom({
      from: from,
      to: to,
      ids: ids,
      amounts: amounts,
      data: data
    });
  }

  /**
   * @notice Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`.
   * @dev Emits an `ApprovalForAll` event.
   *
   * ##### Requirements:
   * - Can only be used when the contract is not paused.
   * - `operator` cannot be the caller.
   * @param operator The address to grant or revoke approval from.
   * @param approved Whether or not the `operator` is approved to transfer the caller's tokens.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    override
    whenNotPaused
  {
    _setApprovalForAll({
      owner: _msgSender(),
      operator: operator,
      approved: approved
    });
  }

  /**
   * @notice Returns true if this contract implements the interface defined by
   * `interfaceId`.
   * @dev See the corresponding [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified) to
   * learn more about how these ids are created.
   * See [IERC165.supportsInterface](
   * https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165-supportsInterface-bytes4-) for more.
   * This function call must use less than 30,000 gas.
   * @param interfaceId A bytes4 value which represents an interface ID.
   * @return True if this contract implements the interface defined by `interfaceId`, otherwise false.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface({interfaceId: interfaceId});
  }

  /**
   * @notice Called during `mintBatch`, creates the removal IDs from the removal data, validates
   * the new IDs to prevent minting a pre-existing ID, stores the project ID in a mapping.
   * @param removals An array of `DecodedRemovalIdV0` structs containing data about each removal
   * @param projectId The project IDentifier for this batch of removals.
   * @return An array of removal IDs that were created.
   */
  function _createRemovals(
    DecodedRemovalIdV0[] calldata removals,
    uint256 projectId
  ) internal returns (uint256[] memory) {
    uint256[] memory ids = new uint256[](removals.length);
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < removals.length; ++i) {
        uint256 id = RemovalIdLib.createRemovalId({removal: removals[i]});
        _createRemoval({id: id, projectId: projectId});
        ids[i] = id;
      }
    }
    return ids;
  }

  /**
   * @notice Called by `_createRemovals`, validates the new IDs to prevent minting a pre-existing ID,
   * stores the project ID in a mapping.
   * @param id The removal ID being minted.
   * @param projectId The project ID for this removal.
   */
  function _createRemoval(uint256 id, uint256 projectId) internal {
    _validateRemoval({id: id});
    _removalIdToProjectId[id] = projectId;
  }

  /**
   * @notice Burns `amount` of token ID `id` from the supplier address encoded in the ID.
   * @dev Emits a `RemovalReleased` event.
   * @param id The token ID to burn.
   * @param amount The amount to burn.
   */
  function _releaseFromSupplier(uint256 id, uint256 amount) internal {
    address supplierAddress = RemovalIdLib.supplierAddress({removalId: id});
    super._burn({from: supplierAddress, id: id, amount: amount});
    emit RemovalReleased({
      id: id,
      fromAddress: supplierAddress,
      amount: amount
    });
  }

  /**
   * @notice Burns `amount` of token ID `id` from the Market's balance.
   * @dev Emits a `RemovalReleased` event.
   * @param id The token ID to burn.
   * @param amount The amount to burn.
   */
  function _releaseFromMarket(uint256 id, uint256 amount) internal {
    super._burn({from: this.marketAddress(), id: id, amount: amount});
    _market.release(id, amount);
    emit RemovalReleased({
      id: id,
      fromAddress: this.marketAddress(),
      amount: amount
    });
  }

  /**
   * @notice Burns `amount` of token ID `id` from the Certificate's balance.
   * @dev Emits a `RemovalReleased` event.
   * @param id The removal ID to burn.
   * @param amount The amount to burn.
   */
  function _releaseFromCertificate(uint256 id, uint256 amount) internal {
    address certificateAddress_ = this.certificateAddress();
    super._burn({from: certificateAddress_, id: id, amount: amount});
    emit RemovalReleased({
      id: id,
      fromAddress: certificateAddress_,
      amount: amount
    });
  }

  /**
   * @notice Hook that is called before any token transfer. This includes minting and burning, as well as
   * batched variants. Disables transfers to any address that is not the Market or Certificate contracts, the zero
   * address (for burning), the supplier address that is encoded in the token ID itself, or between consignors.
   * @dev Follows the rules of hooks defined [here](
   *  https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks)
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * - Enforces the rules of `ERC1155Upgradeable._beforeTokenTransfer`.
   * - Enforces the rules of `ERC1155SupplyUpgradeable._beforeTokenTransfer`.
   * @param operator The address to transfer from.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param ids The removal IDs to transfer.
   * @param amounts The amounts of removals to transfer.
   * @param data The data to pass to the receiver contract.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override whenNotPaused {
    address market = address(_market);
    address certificate = address(_certificate);
    bool isValidTransfer = to == market ||
      to == certificate ||
      to == address(0) ||
      (hasRole({role: CONSIGNOR_ROLE, account: _msgSender()}) &&
        (to == certificate || hasRole({role: CONSIGNOR_ROLE, account: to})));
    uint256 countOfRemovals = ids.length;
    for (uint256 i = 0; i < countOfRemovals; ++i) {
      uint256 id = ids[i];
      if (to == market) {
        if (amounts[i] == 0) {
          revert InvalidTokenTransfer({tokenId: id});
        }
        _currentMarketBalance += amounts[i];
      }
      if (from == market) {
        _currentMarketBalance -= amounts[i];
      }
      if (
        !isValidTransfer && to != RemovalIdLib.supplierAddress({removalId: id})
      ) {
        revert ForbiddenTransfer();
      }
    }
    super._beforeTokenTransfer({
      operator: operator,
      from: from,
      to: to,
      ids: ids,
      amounts: amounts,
      data: data
    });
  }

  /**
   * @notice Hook that is called after any token transfer. This includes minting and burning, as well as batched
   * variants.
   * @dev Updates the mapping from address to set of owned token IDs.
   *
   * The same hook is called on both single and batched variants. For single transfers, the length of the `id` and
   * `amount` arrays will be 1.
   *
   * ##### Requirements
   *
   * - When `from` and `to` are both non-zero, `amount`s of `from`'s tokens with IDs `id`s will be transferred to `to`.
   * - When `from` is zero, `amount`s tokens of token type `id` will be minted for `to`.
   * - When `to` is zero, `amount`s of `from`'s tokens with IDs `id`s will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   * @param operator The address to transfer from.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param ids The removal IDs to transfer.
   * @param amounts The amounts of removals to transfer.
   * @param data The data to pass to the receiver contract.
   */
  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    _updateOwnedTokenIds({from: from, to: to, ids: ids});
    super._afterTokenTransfer({
      operator: operator,
      from: from,
      to: to,
      ids: ids,
      amounts: amounts,
      data: data
    });
  }

  /**
   * @notice Updates the mapping from address to set of owned token IDs.
   * @dev Called during `_afterTokenTransfer`.
   * @param from The address from which tokens were transferred.
   * @param to The address to which tokens were transferred.
   * @param ids The token IDs that were transferred.
   */
  function _updateOwnedTokenIds(
    address from,
    address to,
    uint256[] memory ids
  ) internal {
    EnumerableSetUpgradeable.UintSet
      storage receiversOwnedRemovalIds = _addressToOwnedTokenIds[to];
    EnumerableSetUpgradeable.UintSet
      storage sendersOwnedRemovalIds = _addressToOwnedTokenIds[from];
    uint256 countOfRemovals = ids.length;
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < countOfRemovals; ++i) {
        uint256 id = ids[i];
        if (from != address(0)) {
          if (balanceOf({account: from, id: id}) == 0) {
            sendersOwnedRemovalIds.remove({value: id});
          }
        }
        if (to != address(0)) {
          receiversOwnedRemovalIds.add({value: id});
        }
      }
    }
  }

  /**
   * @notice Validates that the provided `id` should be minted.
   * @dev Reverts if a project ID has already been set for `id`.
   * @param id The ID to validate.
   */
  function _validateRemoval(uint256 id) internal view {
    if (_removalIdToProjectId[id] != 0) {
      revert InvalidData();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/**
 * @title An library for `uint256[]`.
 * @author Nori Inc.
 * @notice This library provides a set of functions to manipulate `uint256` arrays.
 * @dev The functions in this library use gas-efficient and concise syntax to improve both DX (via concision) and UX
 * (via gas efficiency).
 */
library UInt256ArrayLib {
  /**
   * @notice Fill an array.
   * @dev Fills all of the elements of a `uint256[]` with the specified `uint256` value.
   *
   * ##### Equivalence:
   *
   * ```solidity
   * for (let i = 1; i < len + 1; i++) arr[i] = val;
   * ```
   *
   * ##### Example usage:
   *
   * ```solidity
   * new uint256[](3).fill(1); // returns: [1, 1, 1]
   * ```
   * -
   * @param from The array to fill.
   * @param val The value to fill all the indexes of the array with.
   * @return arr An array filled with the value of `val`.
   */
  function fill(uint256[] memory from, uint256 val)
    internal
    pure
    returns (uint256[] memory arr)
  {
    uint256 len = from.length;
    arr = new uint256[](len);
    assembly {
      // equivalent to `for (let i = 1; i < len + 1; i++) arr[i] = val;`
      for {
        let i := 1
      } lt(i, add(len, 1)) {
        i := add(i, 1)
      } {
        mstore(add(arr, mul(32, i)), val)
      }
    }
  }

  /**
   * @notice Sum an array.
   * @dev Sums all the elements of a `uint256[]` array.
   *
   * ##### Equivalence:
   *
   * ```solidity
   * for (let i = 0; i < data.length + 1; i++) total += arr[i];
   * ```
   *
   * ##### Example usage:
   *
   * ```solidity
   * new uint256[](10).fill(1).sum(); // sum: 10
   * ```
   * -
   * @param data The array to sum.
   * @return total The sum total of the array.
   */
  function sum(uint256[] memory data) internal pure returns (uint256 total) {
    assembly {
      // equivalent to `for (let i = 0; i < data.length + 1; i++) total += arr[i];`
      let len := mload(data)
      let element := add(data, 32)
      for {
        let end := add(element, mul(len, 32))
      } lt(element, end) {
        element := add(element, 32)
      } {
        let initialTotal := total
        total := add(total, mload(element))
        if lt(total, initialTotal) {
          revert(0, 0)
        }
      }
    }
  }

  /**
   * @notice Slice an array.
   * @dev Slice an array `arr` at index `from` to an index `to`.
   * @param arr The array to slice.
   * @param from The starting index of the slice.
   * @param to The ending index of the slice.
   * @return ret The sliced array.
   */
  function slice(
    uint256[] memory arr,
    uint256 from,
    uint256 to
  ) internal pure returns (uint256[] memory ret) {
    assert(from <= to);
    assert(to <= arr.length);
    assembly {
      ret := add(arr, mul(32, from))
      mstore(ret, sub(to, from))
    }
  }

  /**
   * @notice Copy an array.
   * @dev Copy an array `from` to an array `to`.
   * @param from The array to copy from.
   * @param to The array to copy to.
   * @return The copied array.
   */
  function copy(uint256[] memory from, uint256[] memory to)
    internal
    pure
    returns (uint256[] memory)
  {
    uint256 n = from.length;
    unchecked {
      for (uint256 i = 0; i < n; ++i) to[i] = from[i];
    }
    return to;
  }
}

/**
 * @title A library for `address[]`.
 * @author Nori Inc.
 * @notice This library provides a set of functions to manipulate `address` arrays.
 * @dev The functions in this library use gas-efficient and concise syntax to improve both DX (via concision) and UX
 * (via gas efficiency).
 */
library AddressArrayLib {
  /**
   * @notice Fill an array.
   * @dev Fills all the elements of an `address` array with a value.
   *
   * ##### Equivalence:
   *
   * ```solidity
   * for (let i = 1; i < len + 1; i++) arr[i] = val;
   * ```
   *
   * ##### Example usage:
   *
   * ```solidity
   * new address[](3).fill(address(0); // returns: [address(0), address(0), address(0)]
   * ```
   * -
   * @param from The array to fill.
   * @param val The value to fill all the indexes of the array with.
   * @return arr An array filled with the value of `val`.
   */
  function fill(address[] memory from, address val)
    internal
    pure
    returns (address[] memory arr)
  {
    uint256 len = from.length;
    arr = new address[](len);
    assembly {
      // equivalent to `for (let i = 1; i < len + 1; i++) arr[i] = val;`
      for {
        let i := 1
      } lt(i, add(len, 1)) {
        i := add(i, 1)
      } {
        mstore(add(arr, mul(32, i)), val)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
library EnumerableSetUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IRemoval {
  /**
   * @notice Get the project ID (which is the removal's schedule ID in RestrictedNORI) for a given removal ID.
   * @param id The removal token ID for which to retrieve the project ID.
   * @return The project ID for the removal token ID.
   */
  function getProjectId(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IRestrictedNORI {
  /**
   * @notice Check the existence of a schedule.
   * @param scheduleId The token ID of the schedule for which to check existence.
   * @return Returns a boolean indicating whether or not the schedule exists.
   */
  function scheduleExists(uint256 scheduleId) external view returns (bool);

  /**
   * @notice Sets up a restriction schedule with parameters determined from the project ID.
   * @dev Create a schedule for a project ID and set the parameters of the schedule.
   *
   * @param projectId The ID that will be used as this schedule's token ID
   * @param startTime The schedule's start time in seconds since the unix epoch
   * @param methodology The methodology of this project, used to look up correct schedule duration
   * @param methodologyVersion The methodology version, used to look up correct schedule duration
   */
  function createSchedule(
    uint256 projectId,
    uint256 startTime,
    uint8 methodology,
    uint8 methodologyVersion
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Errors.sol";

/**
 * @notice The internal governing parameters and data for a RestrictedNORI schedule.
 */
struct Schedule {
  uint256 startTime;
  uint256 endTime;
  uint256 totalClaimedAmount;
  uint256 totalQuantityRevoked;
  uint256 releasedAmountFloor;
  EnumerableSetUpgradeable.AddressSet tokenHolders;
  mapping(address => uint256) claimedAmountsByAddress;
  mapping(address => uint256) quantitiesRevokedByAddress;
}

/**
 * @title Library encapsulating the logic around restriction schedules.
 * @author Nori Inc.
 * @notice This library contains logic for restriction schedules used by the RestrictedNORI contract.
 *
 * ##### Behaviors and features:
 *
 * ###### Time
 *
 * All time parameters are in unix time for ease of comparison with `block.timestamp`.
 *
 * ##### Uses:
 *
 * - [EnumerableSetUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet)
 * for `EnumerableSetUpgradeable.UintSet`
 * - RestrictedNORILib for `Schedule`
 */
library RestrictedNORILib {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using RestrictedNORILib for Schedule;

  /**
   * @notice Get the total amount of released tokens available at the current block timestamp for the schedule.
   * @dev Takes the maximum of either the calculated linearly released amount based on the schedule parameters,
   * or the released amount floor, which is set at the current released amount whenever the balance of a
   * schedule is decreased through revocation or withdrawal.
   * @param schedule The schedule to calculate the released amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The total amount of released tokens available at the current block timestamp for the schedule.
   */
  function releasedBalanceOfSingleSchedule(
    Schedule storage schedule,
    uint256 totalSupply
  ) internal view returns (uint256) {
    return
      MathUpgradeable.max({
        a: schedule.linearReleaseAmountAvailable({totalSupply: totalSupply}),
        b: schedule.releasedAmountFloor
      });
  }

  /**
   * @notice Get the linearly released balance for a single schedule at the current block timestamp, ignoring any
   * released amount floor that has been set for the schedule.
   * @param schedule The schedule to calculate the released amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The total amount of released tokens available at the current block timestamp for the schedule.
   */
  function linearReleaseAmountAvailable(
    Schedule storage schedule,
    uint256 totalSupply
  ) internal view returns (uint256) {
    uint256 linearAmountAvailable;
    /* solhint-disable not-rely-on-time, this is time-dependent */
    if (block.timestamp >= schedule.endTime) {
      linearAmountAvailable = schedule.scheduleTrueTotal({
        totalSupply: totalSupply
      });
    } else {
      uint256 rampTotalTime = schedule.endTime - schedule.startTime;
      linearAmountAvailable = block.timestamp < schedule.startTime
        ? 0
        : (schedule.scheduleTrueTotal({totalSupply: totalSupply}) *
          (block.timestamp - schedule.startTime)) / rampTotalTime;
    }
    /* solhint-enable not-rely-on-time */
    return linearAmountAvailable;
  }

  /**
   * @notice Reconstruct a schedule's true total based on claimed and unclaimed tokens.
   * @dev Claiming burns the ERC1155 token, so the true total of a schedule has to be reconstructed
   * from the `totalSupply` and any claimed amount.
   * @param schedule The schedule to calculate the true total for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The true total of the schedule.
   */
  function scheduleTrueTotal(Schedule storage schedule, uint256 totalSupply)
    internal
    view
    returns (uint256)
  {
    return schedule.totalClaimedAmount + totalSupply;
  }

  /**
   * @notice Get the released balance less the total claimed amount at current block timestamp for a schedule.
   * @param schedule The schedule to calculate the claimable amount for.
   * @param schedule The schedule ID to calculate the claimable amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The released balance less the total claimed amount at current block timestamp for a schedule.
   */
  function claimableBalanceForSchedule(
    Schedule storage schedule,
    uint256 scheduleId,
    uint256 totalSupply
  ) internal view returns (uint256) {
    if (!schedule.doesExist()) {
      revert NonexistentSchedule({scheduleId: scheduleId});
    }
    return
      schedule.releasedBalanceOfSingleSchedule({totalSupply: totalSupply}) -
      schedule.totalClaimedAmount;
  }

  /**
   * @notice A single account's claimable balance at current `block.timestamp` for a schedule.
   * @dev Calculations have to consider an account's total proportional claim to the schedule's released tokens,
   * using totals constructed from current balances and claimed amounts, and then subtract anything that
   * account has already claimed.
   * @param schedule The schedule to calculate the claimable amount for.
   * @param scheduleId The schedule ID to calculate the claimable amount for.
   * @param account The account to calculate the claimable amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @param balanceOfAccount The current balance of the account for the schedule.
   * @return The claimable balance for the account at current `block.timestamp` for a schedule.
   */
  function claimableBalanceForScheduleForAccount(
    Schedule storage schedule,
    uint256 scheduleId,
    address account,
    uint256 totalSupply,
    uint256 balanceOfAccount
  ) internal view returns (uint256) {
    uint256 scheduleTotal = schedule.scheduleTrueTotal({
      totalSupply: totalSupply
    });
    uint256 claimableForAccount;
    // avoid division by or of 0
    if (scheduleTotal == 0 || balanceOfAccount == 0) {
      claimableForAccount = 0;
    } else {
      uint256 claimedAmountForAccount = schedule.claimedAmountsByAddress[
        account
      ];
      uint256 linearReleasedAmountFullSchedule = schedule
        .releasedBalanceOfSingleSchedule({totalSupply: totalSupply});
      uint256 accountTrueTotal = balanceOfAccount + claimedAmountForAccount;
      uint256 theoreticalMaxClaimableForAccount = ((linearReleasedAmountFullSchedule *
          accountTrueTotal) / scheduleTotal);
      claimableForAccount =
        theoreticalMaxClaimableForAccount -
        claimedAmountForAccount;
    }
    return claimableForAccount;
  }

  /**
   * @notice Check the revocable balance of a schedule.
   * @param schedule The schedule to check the revocable balance for.
   * @param scheduleId The schedule ID to check the revocable balance for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The current number of revocable tokens for a given schedule at the current block timestamp.
   */
  function revocableQuantityForSchedule(
    Schedule storage schedule,
    uint256 scheduleId,
    uint256 totalSupply
  ) internal view returns (uint256) {
    if (!schedule.doesExist()) {
      revert NonexistentSchedule({scheduleId: scheduleId});
    }
    return
      schedule.scheduleTrueTotal({totalSupply: totalSupply}) -
      schedule.releasedBalanceOfSingleSchedule({totalSupply: totalSupply});
  }

  /**
   * @notice Check if a schedule exists.
   * @param schedule The schedule to check.
   * @return True if the schedule exists, false otherwise.
   */
  function doesExist(Schedule storage schedule) internal view returns (bool) {
    return schedule.endTime != 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155PausableUpgradeable is Initializable, ERC1155Upgradeable, PausableUpgradeable {
    function __ERC1155Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC1155Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity =0.8.17;

interface ICertificate {
  /**
   * @notice Returns the total number of certificates that have been minted.
   * @dev Includes burned certificates.
   * @return Total number of certificates that have been minted.
   */
  function totalMinted() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryableUpgradeable.sol';
import '../ERC721AUpgradeable.sol';
import '../ERC721A__Initializable.sol';

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryableUpgradeable is
    ERC721A__Initializable,
    ERC721AUpgradeable,
    IERC721AQueryableUpgradeable
{
    function __ERC721AQueryable_init() internal onlyInitializingERC721A {
        __ERC721AQueryable_init_unchained();
    }

    function __ERC721AQueryable_init_unchained() internal onlyInitializingERC721A {}

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721ABurnableUpgradeable.sol';
import '../ERC721AUpgradeable.sol';
import '../ERC721A__Initializable.sol';

/**
 * @title ERC721ABurnable.
 *
 * @dev ERC721A token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnableUpgradeable is
    ERC721A__Initializable,
    ERC721AUpgradeable,
    IERC721ABurnableUpgradeable
{
    function __ERC721ABurnable_init() internal onlyInitializingERC721A {
        __ERC721ABurnable_init_unchained();
    }

    function __ERC721ABurnable_init_unchained() internal onlyInitializingERC721A {}

    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {ERC721A__InitializableStorage} from './ERC721A__InitializableStorage.sol';

abstract contract ERC721A__Initializable {
    using ERC721A__InitializableStorage for ERC721A__InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerERC721A() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            ERC721A__InitializableStorage.layout()._initializing
                ? _isConstructor()
                : !ERC721A__InitializableStorage.layout()._initialized,
            'ERC721A__Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !ERC721A__InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = true;
            ERC721A__InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingERC721A() {
        require(
            ERC721A__InitializableStorage.layout()._initializing,
            'ERC721A__Initializable: contract is not initializing'
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AUpgradeable.sol';
import {ERC721AStorage} from './ERC721AStorage.sol';
import './ERC721A__Initializable.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is ERC721A__Initializable, IERC721AUpgradeable {
    using ERC721AStorage for ERC721AStorage.Layout;

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
        ERC721AStorage.layout()._currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return ERC721AStorage.layout()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        ERC721AStorage.layout()._packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(ERC721AStorage.layout()._packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (ERC721AStorage.layout()._packedOwnerships[index] == 0) {
            ERC721AStorage.layout()._packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < ERC721AStorage.layout()._currentIndex) {
                    uint256 packed = ERC721AStorage.layout()._packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = ERC721AStorage.layout()._packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        ERC721AStorage.layout()._tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return ERC721AStorage.layout()._tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        ERC721AStorage.TokenApprovalRef storage tokenApproval = ERC721AStorage.layout()._tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data)
        returns (bytes4 retval) {
            return retval == ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            ERC721AStorage.layout()._currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            ERC721AStorage.layout()._currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = ERC721AStorage.layout()._currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (ERC721AStorage.layout()._currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            ERC721AStorage.layout()._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            ERC721AStorage.layout()._burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        ERC721AStorage.layout()._packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721AUpgradeable.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryableUpgradeable is IERC721AUpgradeable {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library ERC721A__InitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.initializable.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721AStorage {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => ERC721AStorage.TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721AUpgradeable.sol';

/**
 * @dev Interface of ERC721ABurnable.
 */
interface IERC721ABurnableUpgradeable is IERC721AUpgradeable {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}