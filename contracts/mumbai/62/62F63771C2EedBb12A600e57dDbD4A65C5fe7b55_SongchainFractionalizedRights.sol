// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./types/AccessControlled.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IAssets.sol"; 



contract SongchainFractionalizedRights is AccessControlled, Pausable {

  IAssets public Assets; // Songchain NFT contract
  ITreasury public treasury; // Songchain Treasury contract
  address public thisContract; // address of this contract

  // TODO: Move enums to interface
  // Types of time periods
  enum OWNERSHIP_TIMEFRAME {
    NON, // avoiding 0 index for enum
    MINUTES, HOURS, DAYS, WEEKS, MONTHS, YEARS, FOREVER
  }

  enum ASSET_STATUS { 
    NON, // avoiding 0 index for enum
    ASSET_ON_SALE, ASSET_SOLD, ASSET_CANCELLED, ASSET_ON_HOLD
  }

  enum FRACTION_STATUS { 
    NON, // avoiding 0 index for enum
    FRACTION_CREATED, FRACTION_COMPLETED, FRACTION_CANCELLED, FRACTION_WITHDRAWN 
  }

  // Asset struct
  struct Asset {
    uint256 id;
    address owner;
    uint256 pricePerFraction;
    uint256 releasedReserve;
    uint8 timeframe;
    uint256 timeAmount;
    ASSET_STATUS status;
  }

  // Rights Fraction struct
  struct Fraction {
    uint256 assetId;
    address owner;
    uint256 amount;
    uint256 startDate;
    uint256 songchainRoyalty;
    FRACTION_STATUS status;
  }

  address public owner; // for OpenSea collection ownership compatibility
  uint256 public defaultSongchainRoyalty; // default royalty for all songs

  mapping (uint256 => Asset) public assetOwner;
  mapping (address => uint256) public assetOwnerCount; // assetOwner => assetCount
  mapping (address => uint256[]) public assetOwnerIds; // fractionOwner => array of hashes of fractions owned 
  
  mapping (bytes32 => Fraction) public fractionRightsOwnersByHash; // keccak256(assetId, fractionOwner, timeframe, startDate) => Fraction // kind of a composite key
  mapping (address => uint256) public ownerFractions; // fractionOwner => amount of fractions owned
  mapping (address => bytes32[]) public ownerFractionHashes; // fractionOwner => array of hashes of fractions owned


  /*
  * @dev Constructor
  * @param _assets Address of the Assets contract
  * @param _authority Address of the Authority contract
  */
  constructor(address _assets, address _authority) AccessControlled(IAuthority(_authority)) {
    thisContract = address(this);
    owner = msg.sender;
    Assets = IAssets(_assets);
    defaultSongchainRoyalty = 1000; // 10%
    treasury = ITreasury(authority.vault());
  }

  /*
  * @dev Sets the owner of the asset
  * @param _assetId uint256 ID of the asset to set the owner of
  * @param _owner address to set as the owner
  * @param _supply uint256 amount of tokens to set as the supply
  * @param _pricePerFraction uint256 price per fraction
  * @param _timeframe uint8 timeframe of the asset
  * @param _timeAmount uint256 amount of right's time
  */
  function setAssetOwner(uint256 _assetId, address _owner, uint256 _supply, uint256 _pricePerFraction, uint8 _timeframe, uint256 _timeAmount) public onlyGovernor {
    Assets.mint(_owner, _assetId, _supply, "");
    assetOwner[_assetId] = Asset(_assetId, _owner, _pricePerFraction, Assets.balanceOf(_owner, _assetId), _timeframe, _timeAmount, ASSET_STATUS.ASSET_ON_SALE);
    Assets.setApprovalForAll(thisContract, true);
    assetOwnerCount[_owner] += 1;
    assetOwnerIds[_owner].push(_assetId);
  }

  /*
  * @dev Allow users to buy a fraction of the asset
  * @param _assetId uint256 ID of the asset to buy a fraction of
  * @param _amount uint256 amount of the asset to buy
  * @param _tokenAddress address of the token to pay with
  */
  function buyFraction(uint256 _assetId, uint256 _amount, address _tokenAddress) public {
    require(_amount > 0, "Amount must be greater than 0");
    require(_tokenAddress != address(0), "Token address must be valid");
    require(assetOwner[_assetId].owner != address(0), "Asset must have an owner");
    require(assetOwner[_assetId].owner != msg.sender, "Asset owner cannot buy their own asset");
    require(Assets.balanceOf(assetOwner[_assetId].owner, _assetId) >= _amount, "Not enough balance");
    verifyERC20(msg.sender, _tokenAddress, _amount);

    setFractionRightsContract(_assetId, msg.sender, _amount);


  }





  ///////////////////////// VIEW FUNCTIONS /////////////////////////


  /*
  * @dev Returns the remaining reserve of the asset
  * @param _assetId uint256 ID of the asset to get the remaining reserve of
  */
  function pendingReserveFor(uint256 _tokenId) public view returns(uint256) {
    return Assets.balanceOf(assetOwner[_tokenId].owner, _tokenId);
  }

  /*
  * @dev Returns the remaining reserve of the asset
  * @param _assetId uint256 ID of the asset to get the remaining reserve of
  */
  function pendingReleasedReserveFor(uint256 _tokenId) public view returns(uint256) {
    return Assets.balanceOf(assetOwner[_tokenId].owner, _tokenId) - assetOwner[_tokenId].releasedReserve;
  }

  /* @dev Sets the fraction rights contract for the asset, generates a hash and stores it in the mapping as a composite key
  * @param _assetId uint256 ID of the asset to set the contract for
  * @param _owner address to set as the owner
  * @param _timeframe uint256 timeframe ENUM Type of the asset (minutes, hours, days, weeks, months, years, forever)
  * @param _timeAmount uint256 amount of the timeframe
  * @param _amount uint256 amount of the fraction  
  */
  function setFractionRightsContract(uint256 _assetId, address _owner, uint256 _amount) internal {
    uint256 startDate = block.timestamp;
    bytes32 _hash = getFractionHash(_assetId, _owner, _amount);

    Fraction memory fraction = Fraction(_assetId, _owner, _amount, startDate, defaultSongchainRoyalty, FRACTION_STATUS.FRACTION_CREATED);

    fractionRightsOwnersByHash[_hash] = fraction;
    ownerFractions[_owner]++;
    ownerFractionHashes[_owner].push(_hash);
  }



  ///////////////////////// INTERNAL FUNCTIONS /////////////////////////

  function getFractionHash(uint256 _assetId, address _owner, uint256 _amount) internal view returns (bytes32) {
    uint256 startDate = block.timestamp;
    bytes32 _hash = keccak256(abi.encodePacked(_assetId, _owner, startDate, _amount));
    return _hash;
  }

  /* @dev Verifies that the user has enough balance in allowance of the token to buy the asset
  * @param _user address of the user
  * @param _tokenAddress address of the token
  * @param _amount uint256 amount of the token
  */
  function verifyERC20 (address _user, address _tokenAddress, uint256 amount) internal view returns (bool){
    require(amount <= IERC20(_tokenAddress).balanceOf(_user), 'ERROR: ERR_NOT_ENOUGH_FUNDS_ERC20');
    require(amount <= IERC20(_tokenAddress).allowance(_user, authority.vault() ), 'ERROR: ERR_NOT_ALLOW_SPEND_FUNDS');
    return true;
  }


  
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.9;

interface IAssets {
    /* ========== EVENTS ========== */

    event AssetMinted(address indexed account, uint256 indexed id, uint256 amount);
    event AssetBurned(address indexed account, uint256 indexed id, uint256 amount);

    /* ========== VIEW ========== */

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function totalSupplyBatch(uint256[] calldata ids) external view returns (uint256[] memory);

    function uri(uint256 id) external view returns (string memory);

    /* ========== MUTATIVE ========== */

    function mint(address account, uint256 id, uint256 amount, bytes calldata data) external;

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function burnBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) external;

    function setApprovalForAll(address operator, bool approved) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IAuthority.sol";

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract AccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IAuthority authority);
    event NewSigner(address signer, uint256 threshold);


    /* ========== STATE VARIABLES ========== */

    IAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IAuthority _authority) {
        require(address(_authority) != address(0), "Authority cannot be zero address");
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor {
	_onlyGovernor();
	_;
    }

    modifier onlyGuardian {
	_onlyGuardian();
	_;
    }

    modifier onlyPolicy {
	_onlyPolicy();
	_;
    }

    modifier onlyVault {
	_onlyVault();
	_;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IAuthority _newAuthority) internal {
        require(authority == IAuthority(address(0)), "AUTHORITY_INITIALIZED");
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function setAuthority(IAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        require(msg.sender == authority.governor(), "UNAUTHORIZED");
    }

    function _onlyGuardian() internal view {
        require(msg.sender == authority.guardian(), "UNAUTHORIZED");
    }

    function _onlyPolicy() internal view {
        require(msg.sender == authority.policy(), "UNAUTHORIZED");        
    }

    function _onlyVault() internal view {
        require(msg.sender == authority.vault(), "UNAUTHORIZED");                
    }

  
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.9;

interface ITreasury {
    /* ========== EVENTS ========== */

    event DepositERC20(address indexed token, uint256 amount);

    event WithdrawERC20(address indexed token, uint256 amount);

    /* ========== FUNCTIONS ========== */
    
    function deposit(
        uint256 _amount,
        address _token,        
        address _sender) external;

    function withdraw(address _token, address _creator, uint256 _creatorCounterpart, address _executor, uint256 _executorCounterpart, uint256 _cut) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.9;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

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