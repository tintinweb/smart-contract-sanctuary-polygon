// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "sismo-connect-solidity/SismoLib.sol"; // <--- add a Sismo Connect import

/*
 * @title Airdrop
 * @dev Simple Airdrop contract that mints a token to the msg.sender
 * This contract is used for tutorial purposes only
 * It will be used to demonstrate how to integrate Sismo Connect
 */
contract Airdrop is
  ERC721,
  SismoConnect // <--- add a Sismo Connect inheritance
{
  using SismoConnectHelper for SismoConnectVerifiedResult;

  error RegularERC721TransferFromAreNotAllowed();
  error RegularERC721SafeTransferFromAreNotAllowed();

  bytes16 public constant APP_ID = 0xf4977993e52606cfd67b7a1cde717069; // <--- add your appId as a constant
  bytes16 public constant GITCOIN_PASSPORT_HOLDERS_GROUP_ID = 0x1cde61966decb8600dfd0749bd371f12;
  bytes16 public constant TORNADO_CASH_HOLDERS_GROUP_ID = 0x7e47b71e43f993280bad03a937399333;

  constructor(
    string memory name,
    string memory symbol
  )
    ERC721(name, symbol)
    SismoConnect(APP_ID) // <--- Sismo Connect constructor
  {}

  function claimWithSismo(bytes memory response) public {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = buildAuth({authType: AuthType.VAULT});

    ClaimRequest[] memory claims = new ClaimRequest[](2);
    claims[0] = buildClaim({
      groupId: GITCOIN_PASSPORT_HOLDERS_GROUP_ID,
      claimType: ClaimType.GTE,
      value: 15
    });
    claims[1] = buildClaim({groupId: TORNADO_CASH_HOLDERS_GROUP_ID});

    SismoConnectVerifiedResult memory result = verify({
      responseBytes: response,
      // we want the user to prove that he owns a Sismo Vault
      // we are recreating the auth request made in the frontend to be sure that
      // the proofs provided in the response are valid with respect to this auth request
      auths: auths,
      claims: claims,
      // we also want to check if the signed message provided in the response is the signature of the user's address
      signature: buildSignature({message: abi.encode(msg.sender)})
    });

    // if the proofs and signed message are valid, we take the userId from the verified result
    // in this case the userId is the vaultId (since we used AuthType.VAULT in the auth request), the anonymous identifier of a user's vault for a specific app --> vaultId = hash(userVaultSecret, appId)
    // In this contract, we use this vaultId as the tokenId of the NFT we mint to the user
    // This way, all proofs that are generated from the same vault will try to mint the same tokenId
    // So if a user tries to claim twice with a proof from the same vault, the vaultId will be the same and the contract will revert
    uint256 tokenId = SismoConnectHelper.getUserId(result, AuthType.VAULT);
    _mint(msg.sender, tokenId);
  }

  function transferFrom(address, address, uint256) public virtual override {
    revert RegularERC721TransferFromAreNotAllowed();
  }

  function safeTransferFrom(address, address, uint256) public virtual override {
    revert RegularERC721SafeTransferFromAreNotAllowed();
  }

  function safeTransferFrom(address, address, uint256, bytes memory) public virtual override {
    revert RegularERC721SafeTransferFromAreNotAllowed();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title SismoLib
 * @author Sismo
 * @notice This is the Sismo Library of the Sismo protocol
 * It is designed to be the only contract that needs to be imported to integrate Sismo in a smart contract.
 * Its aim is to provide a set of sub-libraries with high-level functions to interact with the Sismo protocol easily.
 */

import "sismo-connect-onchain-verifier/src/libs/sismo-connect/SismoConnectLib.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
pragma solidity ^0.8.17;

import {RequestBuilder, SismoConnectRequest, SismoConnectResponse} from "../utils/RequestBuilder.sol";
import {AuthRequestBuilder, AuthRequest, Auth, VerifiedAuth, AuthType} from "../utils/AuthRequestBuilder.sol";
import {ClaimRequestBuilder, ClaimRequest, Claim, VerifiedClaim, ClaimType} from "../utils/ClaimRequestBuilder.sol";
import {SignatureBuilder, SignatureRequest, Signature} from "../utils/SignatureBuilder.sol";
import {ISismoConnectVerifier, SismoConnectVerifiedResult} from "../../interfaces/ISismoConnectVerifier.sol";
import {IAddressesProvider} from "../../periphery/interfaces/IAddressesProvider.sol";
import {SismoConnectHelper} from "../utils/SismoConnectHelper.sol";
import {IHydraS2Verifier} from "../../verifiers/IHydraS2Verifier.sol";

contract SismoConnect {
  uint256 public constant SISMO_CONNECT_LIB_VERSION = 2;

  IAddressesProvider public constant ADDRESSES_PROVIDER =
    IAddressesProvider(0x3340Ac0CaFB3ae34dDD53dba0d7344C1Cf3EFE05);

  ISismoConnectVerifier internal _sismoConnectVerifier;

  // external libraries
  AuthRequestBuilder internal _authRequestBuilder;
  ClaimRequestBuilder internal _claimRequestBuilder;
  SignatureBuilder internal _signatureBuilder;
  RequestBuilder internal _requestBuilder;

  bytes16 public appId;

  constructor(bytes16 appIdentifier) {
    appId = appIdentifier;
    _sismoConnectVerifier = ISismoConnectVerifier(
      ADDRESSES_PROVIDER.get(string("sismoConnectVerifier-v1"))
    );
    // external libraries
    _authRequestBuilder = AuthRequestBuilder(
      ADDRESSES_PROVIDER.get(string("authRequestBuilder-v1"))
    );
    _claimRequestBuilder = ClaimRequestBuilder(
      ADDRESSES_PROVIDER.get(string("claimRequestBuilder-v1"))
    );
    _signatureBuilder = SignatureBuilder(ADDRESSES_PROVIDER.get(string("signatureBuilder-v1")));
    _requestBuilder = RequestBuilder(ADDRESSES_PROVIDER.get(string("requestBuilder-v1")));
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    SismoConnectRequest memory request
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, namespace);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths);
    return _sismoConnectVerifier.verify(response, request);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims);
    return _sismoConnectVerifier.verify(response, request);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType, extraData);
  }

  function buildClaim(bytes16 groupId) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp);
  }

  function buildClaim(bytes16 groupId, uint256 value) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId, extraData);
  }

  function buildAuth(AuthType authType) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType);
  }

  function buildAuth(AuthType authType, bool isAnon) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon);
  }

  function buildAuth(AuthType authType, uint256 userId) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId);
  }

  function buildAuth(
    AuthType authType,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, extraData);
  }

  function buildAuth(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser, userId);
  }

  function buildSignature(bytes memory message) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser
  ) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser);
  }

  function buildSignature(
    bytes memory message,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, extraData);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser, extraData);
  }

  function buildSignature(bool isSelectableByUser) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser);
  }

  function buildSignature(
    bool isSelectableByUser,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser, extraData);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature, appId);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST(), appId);
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature, appId);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature, appId);
  }

  function buildRequest(
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST(), appId);
  }

  function buildRequest(
    AuthRequest memory auth
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST(), appId);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature, appId, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST(), appId, namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature, appId, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature, appId, namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST(), appId, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST(), appId, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature, appId);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST(), appId);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature, appId);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature, appId);
  }

  function buildRequest(
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST(), appId);
  }

  function buildRequest(
    AuthRequest[] memory auths
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST(), appId);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature, appId, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST(), appId, namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature, appId, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature, appId, namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST(), appId, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST(), appId, namespace);
  }

  function _GET_EMPTY_SIGNATURE_REQUEST() internal view returns (SignatureRequest memory) {
    return _signatureBuilder.buildEmpty();
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";
import {SignatureBuilder} from "./SignatureBuilder.sol";

contract RequestBuilder {
  // default value for namespace
  bytes16 public constant DEFAULT_NAMESPACE = bytes16(keccak256("main"));
  // default value for a signature request 
  SignatureRequest DEFAULT_SIGNATURE_REQUEST = SignatureRequest({message: "MESSAGE_SELECTED_BY_USER", isSelectableByUser: false, extraData: ""});

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 appId,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 appId,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 appId,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    bytes16 appId,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 appId,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    bytes16 appId,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 appId
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 appId
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 appId
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

    function build(
    AuthRequest memory auth,
    bytes16 appId
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }


  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 appId
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    bytes16 appId
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }


  // build with arrays for auths and claims
  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 appId,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 appId,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 appId,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    bytes16 appId,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 appId,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    bytes16 appId,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 appId
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 appId
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 appId
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    bytes16 appId
  ) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 appId
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    bytes16 appId
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        appId: appId,
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract AuthRequestBuilder {
  // default values for Auth Request
  bool public constant DEFAULT_AUTH_REQUEST_IS_ANON = false;
  uint256 public constant DEFAULT_AUTH_REQUEST_USER_ID = 0;
  bool public constant DEFAULT_AUTH_REQUEST_IS_OPTIONAL = false;
  bytes public constant DEFAULT_AUTH_REQUEST_EXTRA_DATA = "";

  error InvalidUserIdAndIsSelectableByUserAuthType();
  error InvalidUserIdAndAuthType();

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(AuthType authType) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, bool isAnon) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, uint256 userId) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  // allow dev to choose for isOptional
  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isOptional) and build(AuthType authType, bool isAnon)

  function build(AuthType authType, bool isOptional, bool isSelectableByUser) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, bool isOptional, bool isSelectableByUser, uint256 userId) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isAnon, bool isOptional) and build(AuthType authType, bool isOptional, bool isSelectableByUser)

  function build(
    AuthType authType,
    bool isAnon,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: _authIsSelectableDefaultValue(authType, userId),
        extraData: extraData
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    // When `userId` is 0, it means the app does not require a specific auth account and the user needs
    // to choose the account they want to use for the app.
    // When `isSelectableByUser` is true, the user can select the account they want to use.
    // The combination of `userId = 0` and `isSelectableByUser = false` does not make sense and should not be used.
    // If this combination is detected, the function will revert with an error.
    if (authType != AuthType.VAULT && userId == 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndIsSelectableByUserAuthType();
    }
    // When requesting an authType VAULT, the `userId` must be 0 and isSelectableByUser must be true.
    if (authType == AuthType.VAULT && userId != 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndAuthType();
    }
    return
      AuthRequest({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function _authIsSelectableDefaultValue(
    AuthType authType,
    uint256 requestedUserId
  ) internal pure returns (bool) {
    // isSelectableByUser value should always be false in case of VAULT authType.
    // This is because the user can't select the account they want to use for the app.
    // the userId = Hash(VaultSecret, AppId) in the case of VAULT authType.
    if (authType == AuthType.VAULT) {
      return false;
    }
    // When `requestedUserId` is 0, it means no specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `true`.
    if (requestedUserId == 0) {
      return true;
    }
    // When `requestedUserId` is not 0, it means a specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `false`.
    else {
      return false;
    }
    // However, the dev can still override this default value by setting `isSelectableByUser` to `true`.
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract ClaimRequestBuilder {
  // default value for Claim Request
  bytes16 public constant DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP = bytes16("latest");
  uint256 public constant DEFAULT_CLAIM_REQUEST_VALUE = 1;
  ClaimType public constant DEFAULT_CLAIM_REQUEST_TYPE = ClaimType.GTE;
  bool public constant DEFAULT_CLAIM_REQUEST_IS_OPTIONAL = false;
  bool public constant DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER = true;
  bytes public constant DEFAULT_CLAIM_REQUEST_EXTRA_DATA = "";

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        claimType: claimType,
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        claimType: claimType,
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(bytes16 groupId) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, bytes16 groupTimestamp) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, uint256 value) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, ClaimType claimType) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, bytes memory extraData) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  } 

  // allow dev to choose for isOptional
  // we force to also set isSelectableByUser
  // otherwise function signatures would be colliding
  // between build(bytes16 groupId, bool isOptional) and build(bytes16 groupId, bool isSelectableByUser)
  // we keep this logic for all function signature combinations 

  function build(bytes16 groupId, bool isOptional, bool isSelectableByUser) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract SignatureBuilder {
  // default values for Signature Request
  bytes public constant DEFAULT_SIGNATURE_REQUEST_MESSAGE = "MESSAGE_SELECTED_BY_USER";
  bool public constant DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER = false;
  bytes public constant DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA = "";

  function build(bytes memory message) external pure returns (SignatureRequest memory) {
    return SignatureRequest({message: message, isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER, extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA});
  }

  function build(bytes memory message, bool isSelectableByUser) external pure returns (SignatureRequest memory) {
    return SignatureRequest({message: message, isSelectableByUser: isSelectableByUser, extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA});
  }

  function build(bytes memory message, bytes memory extraData) external pure returns (SignatureRequest memory) {
    return SignatureRequest({message: message, isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER, extraData: extraData});
  }


  function build(bytes memory message, bool isSelectableByUser, bytes memory extraData) external pure returns (SignatureRequest memory) {
    return SignatureRequest({message: message, isSelectableByUser: isSelectableByUser, extraData: extraData});
  }

  function build(bool isSelectableByUser) external pure returns (SignatureRequest memory) {
    return SignatureRequest({message: DEFAULT_SIGNATURE_REQUEST_MESSAGE, isSelectableByUser: isSelectableByUser, extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA});
  }

  function build(bool isSelectableByUser, bytes memory extraData) external pure returns (SignatureRequest memory) {
    return SignatureRequest({message: DEFAULT_SIGNATURE_REQUEST_MESSAGE, isSelectableByUser: isSelectableByUser, extraData: extraData});
  }

  function buildEmpty() external pure returns (SignatureRequest memory) {
    return SignatureRequest({message: DEFAULT_SIGNATURE_REQUEST_MESSAGE, isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER, extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libs/utils/Structs.sol";

interface ISismoConnectVerifier {
  event VerifierSet(bytes32, address);

  error AppIdMismatch(bytes16 receivedAppId, bytes16 expectedAppId);
  error NamespaceMismatch(bytes16 receivedNamespace, bytes16 expectedNamespace);
  error VersionMismatch(bytes32 requestVersion, bytes32 responseVersion);
  error SignatureMessageMismatch(bytes requestMessageSignature, bytes responseMessageSignature);

  function verify(
    SismoConnectResponse memory response,
    SismoConnectRequest memory request
  ) external returns (SismoConnectVerifiedResult memory);

  function SISMO_CONNECT_VERSION() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAddressesProvider {
  /**
   * @dev Sets the address of a contract.
   * @param contractAddress Address of the contract.
   * @param contractName Name of the contract.
   */
  function set(address contractAddress, string memory contractName) external;

  /**
   * @dev Sets the address of multiple contracts.
   * @param contractAddresses Addresses of the contracts.
   * @param contractNames Names of the contracts.
   */
  function setBatch(address[] calldata contractAddresses, string[] calldata contractNames) external;

  /**
   * @dev Returns the address of a contract.
   * @param contractName Name of the contract (string).
   * @return Address of the contract.
   */
  function get(string memory contractName) external view returns (address);

  /**
   * @dev Returns the address of a contract.
   * @param contractNameHash Hash of the name of the contract (bytes32).
   * @return Address of the contract.
   */
  function get(bytes32 contractNameHash) external view returns (address);

  /**
   * @dev Returns the addresses of all contracts inputed.
   * @param contractNames Names of the contracts as strings.
   */
  function getBatch(string[] calldata contractNames) external view returns (address[] memory);

  /**
   * @dev Returns the addresses of all contracts inputed.
   * @param contractNamesHash Names of the contracts as strings.
   */
  function getBatch(bytes32[] calldata contractNamesHash) external view returns (address[] memory);

  /**
   * @dev Returns the addresses of all contracts in `_contractNames`
   * @return Names, Hashed Names and Addresses of all contracts.
   */
  function getAll() external view returns (string[] memory, bytes32[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

library SismoConnectHelper {
  error AuthTypeNotFoundInVerifiedResult(AuthType authType);

  function getUserId(SismoConnectVerifiedResult memory result, AuthType authType) internal pure returns (uint256) {
    // get the first userId that matches the authType
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        return result.auths[i].userId;
      }
    }
    revert AuthTypeNotFoundInVerifiedResult(authType);
  }

  function getUserIds(SismoConnectVerifiedResult memory result, AuthType authType) internal pure returns (uint256[] memory) {
    // get all userIds that match the authType
    uint256[] memory userIds = new uint256[](result.auths.length);
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        userIds[i] = result.auths[i].userId;
      }
    }
    return userIds;
  }

  function getSignedMessage(SismoConnectVerifiedResult memory result) internal pure returns (bytes memory) {
    return result.signedMessage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract IHydraS2Verifier {
  error InvalidProof();
  error OnlyOneAuthAndOneClaimIsSupported();

  error InvalidVersion(bytes32 version);
  error RegistryRootNotAvailable(uint256 inputRoot);
  error DestinationMismatch(address destinationFromProof, address expectedDestination);
  error CommitmentMapperPubKeyMismatch(
    bytes32 expectedX,
    bytes32 expectedY,
    bytes32 inputX,
    bytes32 inputY
  );

  error ClaimTypeMismatch(uint256 claimTypeFromProof, uint256 expectedClaimType);
  error RequestIdentifierMismatch(
    uint256 requestIdentifierFromProof,
    uint256 expectedRequestIdentifier
  );
  error InvalidExtraData(uint256 extraDataFromProof, uint256 expectedExtraData);
  error ClaimValueMismatch();
  error DestinationVerificationNotEnabled();
  error SourceVerificationNotEnabled();
  error AccountsTreeValueMismatch(
    uint256 accountsTreeValueFromProof,
    uint256 expectedAccountsTreeValue
  );
  error VaultNamespaceMismatch(uint256 vaultNamespaceFromProof, uint256 expectedVaultNamespace);
  error UserIdMismatch(uint256 userIdFromProof, uint256 expectedUserId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SismoConnectRequest {
  bytes16 appId;
  bytes16 namespace;
  AuthRequest[] auths;
	ClaimRequest[] claims;
  SignatureRequest signature;
}

struct AuthRequest {
  AuthType authType;
  uint256 userId; // default: 0
  // flags
  bool isAnon; // default: false -> true not supported yet, need to throw if true
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  // 
  bytes extraData; // default: ""
}

struct ClaimRequest {
  ClaimType claimType; // default: GTE
  bytes16 groupId;
  bytes16 groupTimestamp; // default: bytes16("latest")
  uint256 value; // default: 1
  // flags
  bool isOptional; // default: false 
  bool isSelectableByUser; // default: true
  // 
  bytes extraData; // default: ""
}

struct SignatureRequest {
  bytes message; // default: "MESSAGE_SELECTED_BY_USER"
  bool isSelectableByUser; // default: false
  bytes extraData; // default: ""
}

enum AuthType {
  VAULT,
  GITHUB,
  TWITTER,
  EVM_ACCOUNT
}

enum ClaimType {
  GTE,
  GT,
  EQ,
  LT,
  LTE
}

struct Auth {
  AuthType authType;
  bool isAnon;
  bool isSelectableByUser;
  uint256 userId;
  bytes extraData;
}

struct Claim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  bool isSelectableByUser;
  uint256 value;
  bytes extraData;
}

struct Signature {
  bytes message;
  bytes extraData;
}

struct SismoConnectResponse {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  bytes signedMessage;
  SismoConnectProof[] proofs;
}

struct SismoConnectProof {
  Auth[] auths;
  Claim[] claims;
  bytes32 provingScheme;
  bytes proofData;
  bytes extraData;
}

struct SismoConnectVerifiedResult {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  VerifiedAuth[] auths;
  VerifiedClaim[] claims;
  bytes signedMessage; 
}

struct VerifiedAuth {
  AuthType authType;
  bool isAnon;
  uint256 userId;
  bytes extraData;
  bytes proofData;
}

struct VerifiedClaim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  uint256 value;
  bytes extraData;
  uint256 proofId;
  bytes proofData;
}