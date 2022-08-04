// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IDemoMarketplace.sol";
import "./interfaces/IDemoNFT.sol";
import "./interfaces/IDemoCreator.sol";
import "./interfaces/IDemoRoyalty.sol";
import "./utils/EmergencyWithdraw.sol";

contract DemoMarketplace is
  OwnableUpgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable,
  EmergencyWithdraw,
  ERC721HolderUpgradeable,
  IDemoMarketplace
{
  uint256 private constant NOMINATOR = 10000;

  /**
   * priceType: 0 for fixed, 1 for auction dates range, 2 for auction infinity, 3 for rent
   * status: 0 for delist, 1 for listing
   */
  struct TokenSaleInfo {
    uint256 status;
    uint256 priceType;
    uint256 price; // min price for bid
  }

  struct SalePrice {
    address seller;
    uint256 price;
    uint256 royaltyPercentage;
  }

  mapping(uint256 => mapping(address => SalePrice)) private salePrice;
  mapping(uint256 => bool) private soldTokens;
  mapping(uint256 => mapping(address => TokenSaleInfo)) private tokenSaleInfo;

  uint256 public totalMarketFee;
  uint256 public marketFeePercentage; // 1 is 0.01%
  uint256 public chargeStatus; // 0 not charge anyone, 1 charge seller, 2 charge buyer, 3 charge both
  address public demoTokenAddress;
  address public demoNFTAddress;

  event Sold(address indexed _buyer, address indexed _seller, uint256 _price, uint256 _id);

  /**
   * @dev Upgradable initializer
   * @param _token address of clash token
   * @param _nft address of demo NFT
   */
  function __DemoMarketplace_init(address _token, address _nft) public initializer {
    __Ownable_init();
    __AccessControl_init();
    __ReentrancyGuard_init();
    __ERC721Holder_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    setAddresses(_token, _nft);
    setConfig(2, 300);
  }

  /**
   * @dev Set init config for marketplace
   * @param _chargeStatus uint256 for charge status
   * @param _marketFeePercentage uint256 market fee percentage
   */
  function setConfig(uint256 _chargeStatus, uint256 _marketFeePercentage) public onlyOwner {
    require(_marketFeePercentage <= NOMINATOR, "Marketplace:setConfig");
    chargeStatus = _chargeStatus;
    marketFeePercentage = _marketFeePercentage;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable) returns (bool) {
    return interfaceId == type(IDemoMarketplace).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev set token addresses
   * @param _token address of clash token
   * @param _nft address of demo NFT
   */
  function setAddresses(address _token, address _nft) public onlyOwner {
    require(_token != address(0), "Marketplace:setAddresses");
    require(_nft != address(0), "Marketplace:setAddresses");

    demoTokenAddress = _token;
    demoNFTAddress = _nft;
  }

  /**
   * @dev withdraw market fee
   * @param _token token address
   * @param _to receiver address
   */
  function withdrawMarketFee(address _token, address _to) external onlyOwner {
    uint256 amount = totalMarketFee;
    totalMarketFee = 0;
    IERC20 erc20 = IERC20(_token);
    erc20.transfer(_to, amount);
  }

  /**
   * @dev get price of the token
   * @param _id uint256 id of the token
   * @param _owner address owner of the token
   */
  function getSalePrice(uint256 _id, address _owner) external view returns (address seller, uint256 price) {
    return (salePrice[_id][_owner].seller, salePrice[_id][_owner].price);
  }

  /**
   * @dev get token sale info
   * @param _id uin256 id of the token.
   * @param _owner address of the token owner
   */
  function getTokenSaleInfo(uint256 _id, address _owner)
    external
    view
    returns (
      uint256 status,
      uint256 priceType,
      uint256 price
    )
  {
    return (tokenSaleInfo[_id][_owner].status, tokenSaleInfo[_id][_owner].priceType, tokenSaleInfo[_id][_owner].price);
  }

  /**
   * @dev add a token fixed price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _price price of the token
   */
  function createFixedPrice(uint256 _id, uint256 _price) external override {
    _validateBeforeSale(_id);
    address sender = _msgSender();
    _transferNFT(sender, address(this), _id);
    _createSalePrice(_id, _getRoyaltyFeePercentage(_id), _price, sender);
    tokenSaleInfo[_id][sender] = TokenSaleInfo(1, 0, _price);
  }

  /**
   * @dev edit token price for fixed price mode only
   * @param _id uint256 ID of the token.
   * @param _price uint256 token price
   */
  function editPrice(uint256 _id, uint256 _price) external override {
    address sender = _msgSender();
    require(tokenSaleInfo[_id][sender].priceType == 0, "Marketplace:editPrice01");
    require(tokenSaleInfo[_id][sender].status == 1, "Marketplace:editPrice02");
    require(_price > 0, "Marketplace:editPrice03");
    salePrice[_id][sender].price = _price;
    tokenSaleInfo[_id][sender].price = _price;
  }

  /**
   * @dev remove token from sale
   * @param _id uint256 ID of the token
   */
  function removeFromSale(uint256 _id) external override {
    address sender = _msgSender();
    require(tokenSaleInfo[_id][sender].status == 1, "Marketplace:removeFromSale01");
    _transferNFT(address(this), sender, _id);
    _removeFromSale(_id, sender);
  }

  /**
   * @dev purchase a token
   * @param _id uint256 ID of the token
   * @param _owner address owner of the token
   */
  function buy(uint256 _id, address _owner) public override nonReentrant {
    address sender = _msgSender();
    require(sender != address(0), "Marketplace:buy01");
    uint256 buyPrice = salePrice[_id][_owner].price;
    uint256 buyerMarketFee = _getBuyerMarketplaceFee(chargeStatus, buyPrice, marketFeePercentage);
    uint256 sellerMarketFee = _getSellerMarketplaceFee(chargeStatus, buyPrice, marketFeePercentage);
    uint256 royaltyFee = _calculateRoyaltyFee(_id, buyPrice);
    require(
      IERC20(demoTokenAddress).balanceOf(sender) >= (buyPrice + buyerMarketFee + royaltyFee),
      "Marketplace:buy03"
    );
    require(tokenSaleInfo[_id][_owner].status == 1, "Marketplace:buy04");
    require(tokenSaleInfo[_id][_owner].priceType == 0, "Marketplace:buy05");

    // send token to seller & marketplace
    IERC20(demoTokenAddress).transferFrom(_msgSender(), address(this), buyPrice + buyerMarketFee + royaltyFee);
    _payout(_owner, _id, buyPrice, sellerMarketFee, buyerMarketFee, royaltyFee);

    // _payoutFromBuyer(_owner, buyPrice, sellerMarketFee, buyerMarketFee);
    // totalMarketFee = totalMarketFee + buyerMarketFee + sellerMarketFee;
    // _transferRoyaltyFeeFromBuyer(_id, royaltyFee);

    if (IERC721(demoNFTAddress).ownerOf(_id) == address(this)) {
      _transferNFT(address(this), sender, _id);
    } else {
      _transferNFT(_owner, sender, _id);
    }
    _markTokenSold(_id, true);
    salePrice[_id][_owner] = SalePrice(address(0), 0, 0);
    _removeFromSale(_id, _owner);
    IDemoNFT(demoNFTAddress).setTokenOwner(sender, _id);
    emit Sold(sender, _owner, buyPrice, _id);
  }

  /**
   * @dev create a sale for the token
   * @param _id uint256 ID of the token
   * @param _owner address of the token owner
   */
  function _createSalePrice(
    uint256 _id,
    uint256 _royaltyPercentage,
    uint256 _price,
    address _owner
  ) private {
    require(_price > 0, "Marketplace:createSalePrice");
    salePrice[_id][_owner] = SalePrice(_owner, _price, _royaltyPercentage);
  }

  /**
   * @dev utility function for calculating the royalty fee for given amount of wei
   * @param _id tokenId
   */
  function _getRoyaltyFeePercentage(uint256 _id) private view returns (uint256) {
    return IDemoRoyalty(demoNFTAddress).getRoyaltyPercentage(_id);
  }

  /**
   * @dev utility function for calculating the royalty fee for given amount of wei
   * @param _id tokenId
   * @param _amount uint256 wei amount
   * @return uint256 wei fee
   */
  function _calculateRoyaltyFee(uint256 _id, uint256 _amount) private view returns (uint256) {
    return (_amount * IDemoRoyalty(demoNFTAddress).getRoyaltyPercentage(_id)) / NOMINATOR;
  }

  /**
   * @dev utility function for calculating the marketplace fee for given amount of wei
   * @param _chargeStatus uint256 charge status
   * @param _amount uint256 wei amount
   * @param _marketFeePercentage uint256 market fee percentage
   * @return uint256 wei fee
   */
  function _getSellerMarketplaceFee(
    uint256 _chargeStatus,
    uint256 _amount,
    uint256 _marketFeePercentage
  ) private pure returns (uint256) {
    return _chargeStatus == 0 || _chargeStatus == 2 ? 0 : (_amount * _marketFeePercentage) / NOMINATOR;
  }

  /**
   * @dev utility function for calculating the marketplace fee for given amount of wei
   * @param _chargeStatus uint256 charge status
   * @param _amount uint256 wei amount
   * @param _marketFeePercentage uint256 market fee percentage
   * @return uint256 wei fee
   */
  function _getBuyerMarketplaceFee(
    uint256 _chargeStatus,
    uint256 _amount,
    uint256 _marketFeePercentage
  ) private pure returns (uint256) {
    return _chargeStatus == 0 || _chargeStatus == 1 ? 0 : (_amount * _marketFeePercentage) / NOMINATOR;
  }

  function _getRequireCost(uint256 _price, uint256 _royaltyPercentage) private view returns (uint256) {
    return
      _price +
      _getBuyerMarketplaceFee(chargeStatus, _price, marketFeePercentage) +
      ((_price * _royaltyPercentage) / NOMINATOR);
  }

  /**
   * @dev check whether the ERC1155 token has sold at least once
   * @param _id uint256 token ID
   * @return bool of whether the token has sold
   */
  function hasTokenSold(uint256 _id) external view returns (bool) {
    return soldTokens[_id];
  }

  /**
   * @dev mark a token as sold
   * @param _id uint256 token ID
   * @param _hasSold bool of whether the token should be marked sold or not
   */
  function _markTokenSold(uint256 _id, bool _hasSold) private {
    soldTokens[_id] = _hasSold;
  }

  /**
   * @dev Checks that the sender has enough token
   * @param _id uint256 ID of the token
   */
  function _validateBeforeSale(uint256 _id) private view {
    address owner = IERC721(demoNFTAddress).ownerOf(_id);
    address sender = _msgSender();
    require(owner == sender, "Marketplace:validateBeforeSale01");
    require(tokenSaleInfo[_id][sender].status == 0, "Marketplace:enoughTokenAmount02");
  }

  function _transferNFT(
    address _from,
    address _to,
    uint256 _id
  ) private {
    IDemoNFT(demoNFTAddress).setApprovalForAllByMarketplace(_from, address(this), true);
    IERC721(demoNFTAddress).safeTransferFrom(_from, _to, _id);
  }

  /**
   * @dev transfer royalty fee
   * @param _id id nft
   * @param _amount royalty fee
   */
  function _transferRoyaltyFeeFromBuyer(uint256 _id, uint256 _amount) private {
    IERC20(demoTokenAddress).transferFrom(_msgSender(), IDemoCreator(demoNFTAddress).getCreator(_id), _amount);
  }

  function _transferRoyaltyFeeFromMarketplace(uint256 _id, uint256 _amount) private {
    IERC20(demoTokenAddress).transfer(IDemoCreator(demoNFTAddress).getCreator(_id), _amount);
  }

  /**
   * @dev transfer market fee
   * @param _amount market fee
   */
  function _transferMarketFee(uint256 _amount) private {
    IERC20(demoTokenAddress).transferFrom(_msgSender(), address(this), _amount);
  }

  function _payout(
    address _owner,
    uint256 _id,
    uint256 _price,
    uint256 _sellerMarketFee,
    uint256 _buyerMarketFee,
    uint256 _royalty
  ) private {
    totalMarketFee = totalMarketFee + _buyerMarketFee + _sellerMarketFee;
    IERC20(demoTokenAddress).transfer(_owner, _price - _sellerMarketFee);
    IERC20(demoTokenAddress).transfer(IDemoCreator(demoNFTAddress).getCreator(_id), _royalty);
  }

  // function _payoutFromBuyer(
  //   address _owner,
  //   uint256 _price,
  //   uint256 _sellerMarketFee,
  //   uint256 _buyerMarketFee
  // ) private {
  //   IERC20(demoTokenAddress).transferFrom(_msgSender(), _owner, _price - _sellerMarketFee);
  //   _transferMarketFee(_sellerMarketFee + _buyerMarketFee);
  // }

  // function _payoutFromMarketplace(
  //   address _owner,
  //   uint256 _price,
  //   uint256 _sellerMarketFee
  // ) private {
  //   IERC20(demoTokenAddress).transfer(_owner, _price - _sellerMarketFee);
  // }

  /**
   * @dev remove token from sale
   * @param _id uint256 id of the token.
   * @param _owner owner of the token
   */
  function _removeFromSale(uint256 _id, address _owner) private {
    tokenSaleInfo[_id][_owner] = TokenSaleInfo(0, 0, 0);
  }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDemoMarketplace {
  /**
   * @dev add a token fixed price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _price price of the token
   */
  function createFixedPrice(uint256 _id, uint256 _price) external;

  /**
   * @dev remove token from sale
   * @param _id uint256 ID of the token
   */
  function removeFromSale(uint256 _id) external;

  /**
   * @dev edit token price for fixed price mode only
   * @param _id uint256 ID of the token.
   * @param _price uint256 token price
   */
  function editPrice(uint256 _id, uint256 _price) external;

  /**
   * @dev purchase a token
   * @param _id uint256 ID of the token
   * @param _owner address owner of the token
   */
  function buy(uint256 _id, address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDemoNFT {
  /**
   * @dev Mintable
   */
  function mint(
    address _account,
    uint256 _id,
    uint256 _royaltyPercentage
  ) external; //by MINTER_ROLE

  /**
   * @dev Burnable
   */
  function burn(uint256 _id) external; //by BURNER_ROLE

  /**
   * @dev Burnable
   */
  function setTokenOwner(address _account, uint256 _id) external;

  /**
   * @dev redeem token from account
   * @param _creator address token owner
   * @param _id uint256 id token
   * @param _royaltyFeePercentage uint256 royalty fee percentage
   * @param _price uint256 token price
   * @param _buyNowPrice uint256 token buy now price
   * @param _priceType uint256 price type
   * @param _startTime uint256 start time
   * @param _endTime uint256 end time
   * @param _status uint256 sale status
   * @param _signature bytes signature
   */
  function redeem(
    address _creator,
    uint256 _id,
    uint256 _royaltyFeePercentage,
    uint256 _price,
    uint256 _buyNowPrice,
    uint256 _priceType,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _status,
    bytes calldata _signature
  ) external;

  /**
   * @dev set approval for all by marketplace
   * @param _creator address of the creator of the token.
   * @param _operator address of operator
   * @param _approved approve status
   */
  function setApprovalForAllByMarketplace(
    address _creator,
    address _operator,
    bool _approved
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDemoCreator {
  /**
   * @dev Gets the creator of the token
   * @param _id uint256 ID of the token
   * @return address of the creator
   */
  function getCreator(uint256 _id) external view returns (address);

  /**
   * @dev Sets the creator of the token
   * @param _id uint256 ID of the token
   * @param _creator address of the creator for the token
   */
  function setCreator(uint256 _id, address _creator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDemoRoyalty {
  /**
   * @dev Gets the royalty of the token
   * @param _id uint256 ID of the token
   * @return uint256 royalty percentage
   */
  function getRoyaltyPercentage(uint256 _id) external view returns (uint256);

  /**
   * @dev Sets the royalty of the token
   * @param _id uint256 ID of the token
   * @param _royaltyPercentage uint256 royalty percentage
   */
  function setRoyaltyPercentage(uint256 _id, uint256 _royaltyPercentage) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint amount);

  /**
   * @dev Allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev Get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() external view returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev Withdraw eth balance
   */
  function emergencyWithdrawEthBalance(address _to, uint _amount) external onlyOwner {
    require(_to != address(0), "Invalid to");
    payable(_to).transfer(_amount);
  }

  /**
   * @dev Get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) external view returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev Withdraw token balance
   * @param _tokenAddress token address
   */
  function emergencyWithdrawTokenBalance(
    address _tokenAddress,
    address _to,
    uint _amount
  ) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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