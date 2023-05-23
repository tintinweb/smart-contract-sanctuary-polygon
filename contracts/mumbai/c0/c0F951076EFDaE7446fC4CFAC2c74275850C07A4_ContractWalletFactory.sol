// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title OwnerPool contract for managing multiple owners
 *
 * @author FORCO LLC
 */
abstract contract OwnerPool is Context {
  event OwnerAdded(address indexed ownerAddress);
  event OwnerRemoved(address indexed ownerAddress);

  // Map of owner and their active state
  mapping(address => bool) internal _owner;

  /**
   * @dev Add new owner[s]
   *
   * @param _newOwnerList address[]
   */
  function addOwnerBatch(
    address[] calldata _newOwnerList
  ) public virtual onlyOwners {
    for (uint256 idx = 0; idx < _newOwnerList.length; idx++) {
      _addOwner(_newOwnerList[idx]);
    }
  }

  /**
   * @dev Add new owner
   *
   * @param _newOwner address
   */
  function addOwner(address _newOwner) public virtual onlyOwners {
    _addOwner(_newOwner);
  }

  /**
   * @dev [internal] Add new owner[s]
   *
   * @param _newOwnerList address[]
   */
  function _addOwnerBatch(address[] memory _newOwnerList) internal virtual {
    for (uint256 idx = 0; idx < _newOwnerList.length; idx++) {
      _addOwner(_newOwnerList[idx]);
    }
  }

  /**
   * @dev [internal] Add new owner
   *
   * @param _newOwner address
   */
  function _addOwner(address _newOwner) internal virtual {
    require(
      _newOwner != address(0),
      "Owner:addOwner newOwner is the zero address"
    );

    _owner[_newOwner] = true;
    emit OwnerAdded(_newOwner);
  }

  /**
   * @dev Removes an owner
   *
   * @param _ownerToRemove address
   */
  function removeOwner(address _ownerToRemove) public virtual onlyOwners {
    _removeOwner(_ownerToRemove);
  }

  /**
   * @dev [internal] Removes an owner
   *
   * @param _ownerToRemove address
   */
  function _removeOwner(address _ownerToRemove) internal virtual {
    require(
      _owner[_ownerToRemove],
      "Owner:removeOwner trying to remove non existing Owner"
    );

    delete _owner[_ownerToRemove];
    emit OwnerRemoved(_ownerToRemove);
  }

  /**
   * @dev Check is an address is owner
   *
   * @param _addressToCheck address
   */
  function isOwner(address _addressToCheck) public view virtual returns (bool) {
    return _owner[_addressToCheck];
  }

  /**
   * @dev Throws if called by any account other than Owner.
   */
  modifier onlyOwners() {
    require(_owner[_msgSender()], "Owner:onlyOwners caller is not an Owner");
    _;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../access/OwnerPool.sol";
import "../interfaces/IContractWallet.sol";

/**
 * @title ContractWallet contract for managing ERC20, ERC721, ERC1155
 *
 * @author FORCO LLC
 */
contract ContractWallet is OwnerPool, ERC2771Context, ERC165, IContractWallet {
  string private _metaDataURI;

  /**
   * @dev constructor
   *
   * @param metaDataURI string memory
   * @param initialOwners address[] memory
   * @param trustedForwarder address
   */
  constructor(
    string memory metaDataURI,
    address[] memory initialOwners,
    address trustedForwarder
  ) ERC2771Context(trustedForwarder) {
    _addOwnerBatch(initialOwners);
    _metaDataURI = metaDataURI;
  }

  /**
   * @dev [override] supportsInterface
   *
   * @param _interfaceId bytes4
   */
  function supportsInterface(
    bytes4 _interfaceId
  ) public view override(ERC165, IERC165) returns (bool) {
    return
      _interfaceId == type(IContractWallet).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /**
   * @dev [override] _msgSender
   */
  function _msgSender()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (address)
  {
    return ERC2771Context._msgSender();
  }

  /**
   * @dev [override] _msgData
   */
  function _msgData()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }

  /**
   * @dev To support acceptance of ETH with msg.data
   */
  fallback() external payable override {
    if (msg.value > 0) {
      emit ETHReceived(_msgSender(), msg.value);
    }
  }

  /**
   * @dev To support acceptance of ETH without msg.data
   */
  receive() external payable override {
    if (msg.value > 0) {
      emit ETHReceived(_msgSender(), msg.value);
    }
  }

  /**
   * @dev To receive ERC721 token
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @dev To receive ERC1155 token
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  /**
   * @dev To receive batch ERC1155 token
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @dev See {IContractWallet.transfer}
   *
   * Requirement
   * - onlyOwners can call
   */
  function transfer(
    AssetType assetType,
    address contractAddress,
    uint256 tokenId,
    uint256 amount,
    address to
  ) external override onlyOwners {
    if (assetType == AssetType.ERC20) {
      // ERC20
      bool success = IERC20(contractAddress).transfer(to, amount);
      require(success, "ContractWallet:transfer ERC20 transfer failed");
    } else if (assetType == AssetType.ERC721) {
      // ERC721
      IERC721(contractAddress).safeTransferFrom(address(this), to, tokenId);
    } else if (assetType == AssetType.ERC1155) {
      // ERC1155
      IERC1155(contractAddress).safeTransferFrom(
        address(this),
        to,
        tokenId,
        amount,
        bytes("")
      );
    } else {
      revert("ContractWallet:transfer unsupported assetType");
    }
  }

  /**
   * @dev See {IContractWallet.approve}
   *
   * Requirement
   * - onlyOwners can call
   */
  function approve(
    AssetType assetType,
    address contractAddress,
    uint256 tokenId,
    uint256 amount,
    address operator
  ) external override onlyOwners {
    if (assetType == AssetType.ERC20) {
      // ERC20
      bool success = IERC20(contractAddress).approve(operator, amount);
      require(success, "ContractWallet:approve ERC20 approve failed");
    } else if (assetType == AssetType.ERC721) {
      // ERC721
      IERC721(contractAddress).approve(operator, tokenId);
    } else {
      revert("ContractWallet:approve unsupported assetType");
    }
  }

  /**
   * @dev See {IContractWallet.setApprovalForAll}
   *
   * Requirement
   * - onlyOwners can call
   */
  function setApprovalForAll(
    AssetType assetType,
    address contractAddress,
    address operator,
    bool approved
  ) external override onlyOwners {
    if (assetType == AssetType.ERC721) {
      // ERC721
      IERC721(contractAddress).setApprovalForAll(operator, approved);
    } else if (assetType == AssetType.ERC1155) {
      // ERC1155
      IERC1155(contractAddress).setApprovalForAll(operator, approved);
    } else {
      revert("ContractWallet:setApprovalForAll unsupported assetType");
    }
  }

  /**
   * @dev See {IContractWallet.allowance}
   */
  function allowance(
    AssetType assetType,
    address contractAddress,
    address operator
  ) external view override returns (uint256) {
    if (assetType == AssetType.ERC20) {
      // ERC20
      return IERC20(contractAddress).allowance(address(this), operator);
    } else {
      revert("ContractWallet:allowance unsupported assetType");
    }
  }

  /**
   * @dev See {IContractWallet.isApprovedForAll}
   */
  function isApprovedForAll(
    AssetType assetType,
    address contractAddress,
    address operator
  ) external view override returns (bool) {
    if (assetType == AssetType.ERC721) {
      // ERC721
      return IERC721(contractAddress).isApprovedForAll(address(this), operator);
    } else if (assetType == AssetType.ERC1155) {
      // ERC1155
      return
        IERC1155(contractAddress).isApprovedForAll(address(this), operator);
    } else {
      revert("ContractWallet:isApprovedForAll unsupported assetType");
    }
  }

  /**
   * @dev See {IContractWallet.balance}
   */
  function balance(
    AssetType assetType,
    address contractAddress,
    uint256 tokenId
  ) external view override returns (uint256) {
    if (assetType == AssetType.ERC20) {
      // ERC20
      return IERC20(contractAddress).balanceOf(address(this));
    } else if (assetType == AssetType.ERC721) {
      // ERC721
      return IERC721(contractAddress).balanceOf(address(this));
    } else if (assetType == AssetType.ERC1155) {
      // ERC1155
      return IERC1155(contractAddress).balanceOf(address(this), tokenId);
    } else {
      revert("ContractWallet:transfer unsupported assetType");
    }
  }

  /**
   * @dev setMetadataURI
   *
   * @param metaDataURI string memory
   *
   * Requirement
   * - onlyOwners can call
   */
  function setMetadataURI(
    string memory metaDataURI
  ) external override onlyOwners {
    _metaDataURI = metaDataURI;
  }

  /**
   * @dev get metadataURI
   */
  function metadataURI() external view override returns (string memory) {
    return _metaDataURI;
  }

  /**
   * @dev See {IContractWallet.execute}
   *
   * Requirement
   * - onlyOwners can call
   */
  function execute(
    Request calldata req
  ) external payable override onlyOwners returns (bool, bytes memory) {
    require(
      msg.value >= req.value,
      "ContractWallet:execute not enough ETH sent"
    );

    (bool success, bytes memory returnData) = req.to.call{
      gas: req.gas,
      value: req.value
    }(abi.encodePacked(req.data));

    if (success == false) {
      if (returnData.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        /// @solidity memory-safe-assembly
        assembly {
          let returndata_size := mload(returnData)
          revert(add(32, returnData), returndata_size)
        }
      } else {
        revert("ContractWallet:execute failed to execute");
      }
    }

    // Validate that the caller has sent enough gas for the call.
    // See https://ronan.eth.link/blog/ethereum-gas-dangers/
    if (gasleft() <= req.gas / 63) {
      // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
      // neither revert or assert consume all gas since Solidity 0.8.0
      // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
      /// @solidity memory-safe-assembly
      assembly {
        invalid()
      }
    }

    return (success, returnData);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./ContractWallet.sol";
import "../access/OwnerPool.sol";

/**
 * @title ContractWalletFactory contract to create ContractWallet contract
 *
 * @author FORCO LLC
 */
contract ContractWalletFactory is OwnerPool, ERC2771Context {
  // Event will be fired with new SBT collection is deployed
  event ContractWalletCreated(
    IContractWallet indexed contractAddress,
    address indexed masterOwner
  );

  // Map of owner and its created SBT collection
  mapping(address => IContractWallet[]) private _contracts;
  address private _trustedForwarder;

  /**
   * @dev constructor
   *
   * @param trustedForwarder_ address
   */
  constructor(address trustedForwarder_) ERC2771Context(trustedForwarder_) {
    _trustedForwarder = trustedForwarder_;
    _addOwner(_msgSender());
  }

  /**
   * @dev [override] _msgSender
   */
  function _msgSender()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (address)
  {
    return ERC2771Context._msgSender();
  }

  /**
   * @dev [override] _msgData
   */
  function _msgData()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }

  /**
   * @dev Create and deploy new ContractWallet contract
   *
   * @param metaDataURI string memory
   * @param initialOwners address[] memory
   */
  function createContractWallet(
    string memory metaDataURI,
    address[] memory initialOwners
  ) external onlyOwners {
    require(
      initialOwners.length != 0,
      "ContractWalletFactory:createContractWallet zero initialOwners"
    );
    address masterOwner = initialOwners[0];

    ContractWallet cwContract = new ContractWallet(
      metaDataURI,
      initialOwners,
      _trustedForwarder
    );

    IContractWallet[] storage ownerContracts = _contracts[masterOwner];
    ownerContracts.push(IContractWallet(cwContract));

    emit ContractWalletCreated(IContractWallet(cwContract), masterOwner);
  }

  /**
   * @dev Get the list of SBT collection deployed by the respective owner
   *
   * @param owner_ address
   */
  function getContractByOwner(
    address owner_
  ) external view returns (IContractWallet[] memory) {
    return _contracts[owner_];
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title Interfact for ContractWallet
 *
 * @author FORCO LLC
 */
interface IContractWallet is IERC721Receiver, IERC1155Receiver {
  // Supported AssetType
  enum AssetType {
    ERC20,
    ERC721,
    ERC1155
  }

  // Event will be fired when ETH is received
  event ETHReceived(address indexed sender, uint256 amount);

  // To support acceptance of ETH with msg.data
  fallback() external payable;

  // To support acceptance of ETH without msg.data
  receive() external payable;

  /**
   * @dev Transfer from the implementing contract for [ERC20|ERC721|ERC1155]
   *
   * @param assetType AssetType
   * @param contractAddress address
   * @param tokenId uint256
   * @param amount uint256
   * @param to address
   */
  function transfer(
    AssetType assetType,
    address contractAddress,
    uint256 tokenId,
    uint256 amount,
    address to
  ) external;

  /**
   * @dev Approve operator for [ERC20|ERC721]
   *
   * @param assetType AssetType
   * @param contractAddress address
   * @param tokenId uint256
   * @param amount uint256
   * @param operator address
   */
  function approve(
    AssetType assetType,
    address contractAddress,
    uint256 tokenId,
    uint256 amount,
    address operator
  ) external;

  /**
   * @dev Set setApprovalForAll for [ERC721|ERC1155]
   *
   * @param assetType AssetType
   * @param contractAddress address
   * @param operator address
   * @param approved bool
   */
  function setApprovalForAll(
    AssetType assetType,
    address contractAddress,
    address operator,
    bool approved
  ) external;

  /**
   * @dev Get allowance of operator for the implementing contract for [ERC20]
   *
   * @param assetType AssetType
   * @param contractAddress address
   * @param operator address
   */
  function allowance(
    AssetType assetType,
    address contractAddress,
    address operator
  ) external returns (uint256);

  /**
   * @dev Get isApprovedForAll of operator for [ERC721|ERC1155]
   *
   * @param assetType AssetType
   * @param contractAddress address
   * @param operator address
   */
  function isApprovedForAll(
    AssetType assetType,
    address contractAddress,
    address operator
  ) external returns (bool);

  /**
   * @dev Get balanceOf stored in the implementing contract for [ERC20|ERC721|ERC1155]
   *
   * @param assetType AssetType
   * @param contractAddress address
   * @param tokenId uint256
   */
  function balance(
    AssetType assetType,
    address contractAddress,
    uint256 tokenId
  ) external returns (uint256);

  /**
   * @dev setMetadataURI
   *
   * @param metaDataURI string memory
   */
  function setMetadataURI(string memory metaDataURI) external;

  /**
   * @dev Get metadataURI
   *
   * @return string memory metadataURI
   */
  function metadataURI() external view returns (string memory);

  struct Request {
    address to;
    uint256 value;
    uint256 gas;
    bytes data;
  }

  /**
   * @dev Execute a function
   *
   * @param req Request calldata
   * @return bool status of call
   * @return bytes memory retuned value
   */
  function execute(
    Request calldata req
  ) external payable returns (bool, bytes memory);
}