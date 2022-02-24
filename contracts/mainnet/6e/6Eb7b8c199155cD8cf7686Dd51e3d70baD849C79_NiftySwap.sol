// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.0;


// ######## ##     ## #### ########  ########  ##      ## ######## ########  
//    ##    ##     ##  ##  ##     ## ##     ## ##  ##  ## ##       ##     ## 
//    ##    ##     ##  ##  ##     ## ##     ## ##  ##  ## ##       ##     ## 
//    ##    #########  ##  ########  ##     ## ##  ##  ## ######   ########  
//    ##    ##     ##  ##  ##   ##   ##     ## ##  ##  ## ##       ##     ## 
//    ##    ##     ##  ##  ##    ##  ##     ## ##  ##  ## ##       ##     ## 
//    ##    ##     ## #### ##     ## ########   ###  ###  ######## ########

// ##     ##    ###     ######  ##    ## ##      ## ######## ######## ##    ## 
// ##     ##   ## ##   ##    ## ##   ##  ##  ##  ## ##       ##       ##   ##  
// ##     ##  ##   ##  ##       ##  ##   ##  ##  ## ##       ##       ##  ##   
// ######### ##     ## ##       #####    ##  ##  ## ######   ######   #####    
// ##     ## ######### ##       ##  ##   ##  ##  ## ##       ##       ##  ##   
// ##     ## ##     ## ##    ## ##   ##  ##  ##  ## ##       ##       ##   ##  
// ##     ## ##     ##  ######  ##    ##  ###  ###  ######## ######## ##    ## 


import { IMultiwrap } from "@thirdweb-dev/contracts/contracts/interfaces/IMultiwrap.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@thirdweb-dev/contracts/contracts/lib/CurrencyTransferLib.sol";

interface INiftySwap {

    struct Swap {
        IMultiwrap.WrappedContents bundleOffered;
        IMultiwrap.WrappedContents bundleWanted;
        address offeror;
        address ownerOfWanted;
        bool swapCompleted;
    }

    event Swapped(uint256 swapId, Swap swapInfo);
    event Offered(uint256 indexed swapId, address indexed _offeror, IMultiwrap.WrappedContents _bundleOffered, IMultiwrap.WrappedContents _bundleWanted);

    /// @dev Performs a swap between two bundles.
    function swap(uint256 _swapId) external;

    /// @dev Stores an offer.
    function offer(
        address ownerOfWanted,
        IMultiwrap.WrappedContents memory _bundleOffered,
        IMultiwrap.WrappedContents memory _bundleWanted
    ) external;
}

contract NiftySwap is INiftySwap, ReentrancyGuard, ERC1155Holder {
    
    uint256 public nextSwapId;

    mapping(uint256 => Swap) public swapInfo;

    /// @dev Stores an offer.
    function offer(
        address _ownerOfWanted,
        IMultiwrap.WrappedContents memory _bundleOffered,
        IMultiwrap.WrappedContents memory _bundleWanted
    ) 
        external
    {

        verifyOwnership(msg.sender, _bundleOffered);
        verifyOwnership(_ownerOfWanted, _bundleWanted);

        uint256 id = nextSwapId;
        nextSwapId += 1;

        swapInfo[id] = Swap({
            bundleOffered: _bundleOffered,
            bundleWanted: _bundleWanted,
            offeror: msg.sender,
            ownerOfWanted: _ownerOfWanted,
            swapCompleted: false
        });

        emit Offered(id, msg.sender, _bundleOffered, _bundleWanted);
    }

    /// @dev Performs a swap between two bundles.
    function swap(uint256 _swapId) external {

        Swap memory swapInfoForTrade = swapInfo[_swapId];
        require(!swapInfoForTrade.swapCompleted, "already swapped");

        verifyOwnership(swapInfoForTrade.offeror, swapInfoForTrade.bundleOffered);
        verifyOwnership(swapInfoForTrade.ownerOfWanted, swapInfoForTrade.bundleWanted);

        require(msg.sender == swapInfoForTrade.ownerOfWanted, "not owner of wanted");

        swapInfoForTrade.swapCompleted = true;
        swapInfo[_swapId] = swapInfoForTrade;

        transferBundle(swapInfoForTrade.offeror, swapInfoForTrade.ownerOfWanted, swapInfoForTrade.bundleOffered);
        transferBundle(swapInfoForTrade.ownerOfWanted, swapInfoForTrade.offeror, swapInfoForTrade.bundleWanted);

        emit Swapped(_swapId, swapInfoForTrade);
    }

    /// @dev Returns all swaps; pending and non-pending.
    function getAllSwaps() external view returns (Swap[] memory allSwaps) {
        
        uint256 totalSwaps = nextSwapId;
        allSwaps = new Swap[](totalSwaps);

        for(uint256 i = 0; i < totalSwaps; i += 1) {
            allSwaps[i] = swapInfo[i];
        }
    }

    function transferBundle(
        address _from,
        address _to,
        IMultiwrap.WrappedContents memory _wrappedContents
    ) internal {
        transfer1155(_from, _to, _wrappedContents);
        transfer721(_from, _to, _wrappedContents);
        transfer20(_from, _to, _wrappedContents);
    }

    function transfer20(
        address _from,
        address _to,
        IMultiwrap.WrappedContents memory _wrappedContents
    ) internal {
        uint256 i;

        bool isValidData = _wrappedContents.erc20AssetContracts.length == _wrappedContents.erc20AmountsToWrap.length;
        require(isValidData, "invalid erc20 wrap");
        for (i = 0; i < _wrappedContents.erc20AssetContracts.length; i += 1) {
            CurrencyTransferLib.transferCurrency(
                _wrappedContents.erc20AssetContracts[i],
                _from,
                _to,
                _wrappedContents.erc20AmountsToWrap[i]
            );
        }
    }

    function transfer721(
        address _from,
        address _to,
        IMultiwrap.WrappedContents memory _wrappedContents
    ) internal {
        uint256 i;
        uint256 j;

        bool isValidData = _wrappedContents.erc721AssetContracts.length == _wrappedContents.erc721TokensToWrap.length;
        if (isValidData) {
            for (i = 0; i < _wrappedContents.erc721AssetContracts.length; i += 1) {
                IERC721 assetContract = IERC721(_wrappedContents.erc721AssetContracts[i]);

                for (j = 0; j < _wrappedContents.erc721TokensToWrap[i].length; j += 1) {
                    assetContract.safeTransferFrom(_from, _to, _wrappedContents.erc721TokensToWrap[i][j]);
                }
            }
        }
        require(isValidData, "invalid erc721 wrap");
    }

    function transfer1155(
        address _from,
        address _to,
        IMultiwrap.WrappedContents memory _wrappedContents
    ) internal {
        uint256 i;
        uint256 j;

        bool isValidData = _wrappedContents.erc1155AssetContracts.length ==
            _wrappedContents.erc1155TokensToWrap.length &&
            _wrappedContents.erc1155AssetContracts.length == _wrappedContents.erc1155AmountsToWrap.length;

        if (isValidData) {
            for (i = 0; i < _wrappedContents.erc1155AssetContracts.length; i += 1) {
                isValidData =
                    _wrappedContents.erc1155TokensToWrap[i].length == _wrappedContents.erc1155AmountsToWrap[i].length;

                if (!isValidData) {
                    break;
                }

                IERC1155 assetContract = IERC1155(_wrappedContents.erc1155AssetContracts[i]);

                for (j = 0; j < _wrappedContents.erc1155TokensToWrap[i].length; j += 1) {
                    assetContract.safeTransferFrom(
                        _from,
                        _to,
                        _wrappedContents.erc1155TokensToWrap[i][j],
                        _wrappedContents.erc1155AmountsToWrap[i][j],
                        ""
                    );
                }
            }
        }
        require(isValidData, "invalid erc1155 wrap");
    }

    /// @dev Verifies ownership of wrapped contents.
    function verifyOwnership(address _party, IMultiwrap.WrappedContents memory _bundle) public view {
        
        uint256 i;
        uint256 j;

        bool  isValidData = true;
        
        // ERC1155 tokens
        if(_bundle.erc1155AssetContracts.length != 0) {
            for(i = 0; i < _bundle.erc1155AssetContracts.length; i += 1) {
                if(!isValidData) {
                    break;
                }
                
                IERC1155 assetContract1155 = IERC1155(_bundle.erc1155AssetContracts[i]);
                for(j = 0; j < _bundle.erc1155TokensToWrap[i].length; j += 1) {
                    isValidData = assetContract1155.balanceOf(_party, _bundle.erc1155TokensToWrap[i][j]) >= _bundle.erc1155AmountsToWrap[i][j];
                }
                
                
            }
            require(isValidData, "not owned 1155");
        }

        // ERC721 tokens
        if(_bundle.erc721AssetContracts.length != 0) {
            for(i = 0; i < _bundle.erc721AssetContracts.length; i += 1) {
                
                if(!isValidData) {
                    break;
                }

                IERC721 assetContract721 = IERC721(_bundle.erc721AssetContracts[i]);
                
                for(j = 0; j < _bundle.erc721TokensToWrap[i].length; j += 1) {
                    address owner = assetContract721.ownerOf(_bundle.erc721TokensToWrap[i][j]);
                    isValidData = owner == _party;

                    if(!isValidData) {
                        break;
                    }
                }
            }
            require(isValidData, "not owned 721");
        }

        // ERC20 tokens
        if(_bundle.erc20AssetContracts.length != 0) {
            for(i = 0; i < _bundle.erc20AssetContracts.length; i += 1) {
                
                if(!isValidData) {
                    break;
                }

                IERC20 assetContract20 = IERC20(_bundle.erc20AssetContracts[i]);

                uint256 bal = assetContract20.balanceOf(_party);
                isValidData = bal >=  _bundle.erc20AmountsToWrap[i];
            }
            require(isValidData, "not owned 20");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IThirdwebContract.sol";
import "./IThirdwebRoyalty.sol";
import "./IThirdwebOwnable.sol";

interface IMultiwrap is IThirdwebContract, IThirdwebOwnable, IThirdwebRoyalty {
    struct WrappedContents {
        address[] erc1155AssetContracts;
        uint256[][] erc1155TokensToWrap;
        uint256[][] erc1155AmountsToWrap;
        address[] erc721AssetContracts;
        uint256[][] erc721TokensToWrap;
        address[] erc20AssetContracts;
        uint256[] erc20AmountsToWrap;
    }

    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, WrappedContents wrappedContents);

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed wrapper,
        address sentTo,
        uint256 indexed tokenIdOfShares,
        uint256 sharesUnwrapped,
        WrappedContents wrappedContents
    );

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address prevOwner, address newOwner);

    /**
     *  @notice Wrap multiple ERC1155, ERC721, ERC20 tokens into 'n' shares (i.e. variable supply of 1 ERC 1155 token)
     *
     *  @param wrappedContents The tokens to wrap.
     *  @param shares The number of shares to issue for the wrapped contents.
     *  @param uriForShares The URI for the shares i.e. wrapped token.
     */
    function wrap(
        WrappedContents calldata wrappedContents,
        uint256 shares,
        string calldata uriForShares
    ) external payable returns (uint256 tokenId);

    /**
     *  @notice Unwrap shares to retrieve underlying ERC1155, ERC721, ERC20 tokens.
     *
     *  @param tokenId The token Id of the tokens to unwrap.
     *  @param amountToRedeem The amount of shares to unwrap
     */
    function unwrap(uint256 tokenId, uint256 amountToRedeem, address _sendTo) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Helper interfaces
import { IWETH } from "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library CurrencyTransferLib {
    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeToken(_to, _amount, _nativeTokenWrapper);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeToken(_to, _amount, _nativeTokenWrapper);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        uint256 balBefore = IERC20(_currency).balanceOf(_to);
        bool success = _from == address(this)
            ? IERC20(_currency).transfer(_to, _amount)
            : IERC20(_currency).transferFrom(_from, _to, _amount);
        uint256 balAfter = IERC20(_currency).balanceOf(_to);

        require(success && (balAfter == balBefore + _amount), "currency transfer failed.");
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeToken(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{ value: value }();
            safeTransferERC20(_nativeTokenWrapper, address(this), to, value);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IThirdwebContract {
    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32);

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8);

    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IThirdwebRoyalty is IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IThirdwebOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}