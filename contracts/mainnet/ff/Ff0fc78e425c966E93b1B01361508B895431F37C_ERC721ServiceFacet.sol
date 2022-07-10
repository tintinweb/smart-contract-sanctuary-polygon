// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { IERC721Receiver } from "@solidstate/contracts/token/ERC721/IERC721Receiver.sol";

import { ERC721Service } from "./ERC721Service.sol";
import { ERC721ServiceStorage } from "./ERC721ServiceStorage.sol";
import { IERC721ServiceFacet } from "../../interfaces/IERC721ServiceFacet.sol";

/**
 * @title ERC721ServiceFacet 
 */
contract ERC721ServiceFacet is IERC721ServiceFacet, ERC721Service, IERC721Receiver, OwnableInternal {
    using ERC721ServiceStorage for ERC721ServiceStorage.Layout;
    using ERC721ServiceStorage for ERC721ServiceStorage.Error;

    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) 
        public 
        override(IERC721ServiceFacet, IERC721Receiver)
        returns (bytes4) {
        
        emit Received(operator, from, tokenId, data, gasleft());
        return this.onERC721Received.selector;
    }

    /**
     * @notice return the current version of ERC721Facet
     */
    function erc721ServiceFacetVersion() external pure returns (string memory) {
        return "0.1.0.alpha";
    }

    function _beforeTransferERC721(address token, address to, uint256 tokenId) 
        internal
        virtual
        view 
        override 
        onlyOwner
    {
        super._beforeTransferERC721(token, to, tokenId);
    }

    function _beforeApproveERC721(address token, address spender, uint256 tokenId) 
        internal
        virtual
        view 
        override
        onlyOwner
    {
        super._beforeApproveERC721(token, spender, tokenId);
    }

    function _beforeRegisterERC721(address tokenAddress) internal virtual view override onlyOwner {
        super._beforeRegisterERC721(tokenAddress);
    }

    function _beforeRemoveERC721(address tokenAddress) internal virtual view override onlyOwner {
        super._beforeRemoveERC721(tokenAddress);
    }

    function _beforedepositERC721(address tokenAddress, uint256 tokenId) 
        internal
        virtual
        view 
        override 
        onlyOwner 
    {
        super._beforedepositERC721(tokenAddress, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IERC721Service } from "./IERC721Service.sol";
import { ERC721ServiceInternal } from "./ERC721ServiceInternal.sol";
import { ERC721ServiceStorage } from "./ERC721ServiceStorage.sol";

/**
 * @title ERC20Service 
 */
abstract contract ERC721Service is
    IERC721Service,
    ERC721ServiceInternal
{
    using ERC721ServiceStorage for ERC721ServiceStorage.Layout;

    /**
     * @inheritdoc IERC721Service
     */
    function getAllTrackedERC721Tokens() external view override returns (address[] memory) {
        return _getAllTrackedERC721Tokens();
    }

    /**
     * @inheritdoc IERC721Service
     */
    function balanceOfERC721(address token) external view override returns (uint256) {
        return IERC721(token).balanceOf(address(this));
    }

    /**
     * @inheritdoc IERC721Service
     */
    function ownerOfERC721(
        address token,
        uint256 tokenId
    ) external view override returns (address owner) {
        return IERC721(token).ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function transferERC721(address token, address to, uint256 tokenId) external override {
        _beforeTransferERC721(token, to, tokenId);

        IERC721(token).safeTransferFrom(to, address(this), tokenId);

        _afterTransferERC721(token, to, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function safeTransferERC721From(address token, address from, address to, uint256 tokenId, bytes calldata data) external override {
        _beforeSafeTransferERC721From(token, from, to, tokenId);

        IERC721(token).safeTransferFrom(from, to, tokenId, data);

        _afterSafeTransferERC721From(token, from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function safeTransferERC721From(address token, address from, address to, uint256 tokenId) external override {
        _beforeSafeTransferERC721From(token, from, to, tokenId);

        IERC721(token).safeTransferFrom(from, to, tokenId);

        _afterSafeTransferERC721From(token, from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function transferERC721From(address token, address from, address to, uint256 tokenId) external override {
        _beforeTransferERC721From(token, from, to, tokenId);

        IERC721(token).safeTransferFrom(from, to, tokenId);

        _afterTransferERC721From(token, from, to, tokenId);
    }
    

    /**
     * @inheritdoc IERC721Service
     */
    function approveERC721(address token, address spender, uint256 tokenId) external override {
        _beforeApproveERC721(token, spender, tokenId);

        IERC721(token).approve(spender, tokenId);

        _afterApproveERC721(token, spender, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function registerERC721(address token) external override {
        _beforeRegisterERC721(token);

        _registerERC721(token);

        _afterRegisterERC721(token);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function removeERC721(address token) external override {
        _beforeRemoveERC721(token);

        _removeERC721(token);

        _afterRemoveERC721(token);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function depositERC721(address token, uint256 tokenId) external {
        _beforedepositERC721(token, tokenId);

        _depositERC721(token, tokenId);
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);

        emit ERC721Deposited(token, tokenId);

        _afterDepositERC721(token, tokenId);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title ERC721Service Storage base on Diamond Standard Layout storage pattern
 */
library ERC721ServiceStorage {
    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    struct Layout {
        mapping(address => uint256) erc721TokenIndex;
        address[] erc721Tokens;
        bytes4 retval;
        Error error;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.ERC721Service");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice add an ERC721 token to the storage
     * @param tokenAddress: the address of the ERC721 token
     */
    function storeERC721(Layout storage s, address tokenAddress)
        internal {
            uint256 arrayIndex = s.erc721Tokens.length;
            uint256 index = arrayIndex + 1;
            s.erc721Tokens.push(tokenAddress);
            s.erc721TokenIndex[tokenAddress] = index;
    }

    /**
     * @notice delete an ERC721 token from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param tokenAddress: the address of the ERC20 token
     */
    function deleteERC721(Layout storage s, address tokenAddress)
        internal {
            uint256 index = s.erc721TokenIndex[tokenAddress];
            uint256 arrayIndex = index - 1;
            require(arrayIndex >= 0, "ERC721_NOT_EXISTS");
            if(arrayIndex != s.erc721Tokens.length - 1) {
                 s.erc721Tokens[arrayIndex] = s.erc721Tokens[s.erc721Tokens.length - 1];
                 s.erc721TokenIndex[s.erc721Tokens[arrayIndex]] = index;
            }
            s.erc721Tokens.pop();
            delete s.erc721TokenIndex[tokenAddress];
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC721Service } from "../token/ERC721/IERC721Service.sol";


/**
 * @title ERC721ServiceFacet interface
 */
interface IERC721ServiceFacet is IERC721Service {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);

    /**
     * @notice return the current version of ERC721Facet
     */
    function erc721ServiceFacetVersion() external pure returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IERC721ServiceInternal} from "./IERC721ServiceInternal.sol";

/**
 * @title ERC20Service interface.
 */
interface IERC721Service is IERC721ServiceInternal {
    /**
     * @notice safely transfers `tokenId` token from `from` to `to`.
     * @param token: the address of tracked token to move.
     * @param to: the address of the recipient.
     * @param tokenId: the tokenId to transfer.
     */
    function transferERC721(address token, address to, uint256 tokenId) external;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable.
     * @param token: the address of tracked token to move.
     * @param from sender of token.
     * @param to receiver of token.
     * @param tokenId token id.
     * @param data data payload.
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable.
     * @param token: the address of tracked token to move.
     * @param from sender of token.
     * @param to receiver of token.
     * @param tokenId token id.
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable.
     * @param token: the address of tracked token to move.
     * @param from sender of token.
     * @param to receiver of token.
     * @param tokenId token id.
     */
    function transferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice gives permission to `to` to transfer `tokenId` token to another account.
     * @param token: the address of tracked token to move.
     * @param spender: the address of the spender.
     * @param tokenId: the tokenId to approve.
     */
    function approveERC721(address token, address spender, uint256 tokenId) external;

    /**
     * @notice register a new ERC721 token.
     * @param token: the address of the ERC721 token.
     */
    function registerERC721(address token) external;

    /**
     * @notice remove a new ERC721 token from ERC721Service.
     * @param token: the address of the ERC721 token.
     */
    function removeERC721(address token) external;

     /**
     * @notice deposit a ERC721 token to ERC721Service.
     * @param token: the address of the ERC721 token.
     * @param tokenId: the tokenId of token to deposit.
     */
    function depositERC721(address token, uint256 tokenId) external;

    /**
     * @notice query all tracked ERC721 tokens.
     * @return tracked ERC721  tokens.
     */
    function getAllTrackedERC721Tokens() external view returns (address[] memory);

     /**
     * @notice query the token balance of the given ERC721 token for this address.
     * @param token : the address of the ERC721 token.
     * @return token balance.
     */
    function balanceOfERC721(address token) external view returns (uint256);

    /**
     * @notice query the owner of the `tokenId` token.
     * @param token: the address of tracked token to query.
     * @param tokenId: the tokenId of the token to query.
     *
     */
    function ownerOfERC721(address token, uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC721ServiceInternal } from "./IERC721ServiceInternal.sol";
import { ERC721ServiceStorage } from "./ERC721ServiceStorage.sol";

/**
 * @title ERC721Service internal functions, excluding optional extensions
 */
abstract contract ERC721ServiceInternal is IERC721ServiceInternal {
    using ERC721ServiceStorage for ERC721ServiceStorage.Layout;

    modifier erc721IsTracked(address tokenAddress) {
        require(_getERC721TokenIndex(tokenAddress) > 0, "ERC721Service: token not registered");
        _;
    }
   
    /**
     * @notice register a new ERC721 token
     * @param tokenAddress: the address of the ERC721 token
     */
    function _registerERC721(address tokenAddress) internal virtual {
        ERC721ServiceStorage.layout().storeERC721(tokenAddress);

        emit ERC721TokenTracked(tokenAddress);
    }

     /**
     * @notice remove a new ERC721 token from ERC721Service
     * @param tokenAddress: the address of the ERC721 token
     */
    function _removeERC721(address tokenAddress) internal virtual {
        ERC721ServiceStorage.layout().deleteERC721(tokenAddress);

        emit ERC721TokenRemoved(tokenAddress);
    }

    /**
     * @notice internal function: deposit a ERC721 token to ERC721Service.
     * @param token: the address of the ERC721 token.
     * @param tokenId: the tokenId of token deposited.
     */
    function _depositERC721(address token, uint256 tokenId) internal virtual {
        if (_getERC721TokenIndex(token) == 0) {
            _registerERC721(token);
        }
    }

    /**
     * @notice query the mapping index of ERC721 tokens
     */
    function _getERC721TokenIndex(address tokenAddress) internal view returns (uint256) {
        return ERC721ServiceStorage.layout().erc721TokenIndex[tokenAddress];
    }

     /**
     * @notice query all tracked ERC721 tokens
     */
    function _getAllTrackedERC721Tokens() internal view returns (address[] memory) {
        return ERC721ServiceStorage.layout().erc721Tokens;
    }

    /**
     * @notice hook that is called before transferERC721
     */
    function _beforeTransferERC721(address token, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after transferERC721
     */
    function _afterTransferERC721(address token, address to, uint256 tokenId) internal virtual view {}

    /**
     * @notice hook that is called before safeTransferERC721From
     */
    function _beforeSafeTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after safeTransferERC721From
     */
    function _afterSafeTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called before transferERC721From
     */
    function _beforeTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after transferERC721From
     */
    function _afterTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}


    /**
     * @notice hook that is called before approveERC721
     */
    function _beforeApproveERC721(address token, address spender, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after approveERC721
     */
    function _afterApproveERC721(address token, address spender, uint256 tokenId) internal virtual view erc721IsTracked(token) {}


    /**
     * @notice hook that is called before registerERC721
     */
    function _beforeRegisterERC721(address tokenAddress) internal virtual view {
        require(tokenAddress != address(0), "ERC721Service: tokenAddress is the zero address");
        require(_getERC721TokenIndex(tokenAddress) == 0, "ERC721Service: ERC721 token is already registered");
    }

    /**
     * @notice hook that is called after registerERC721
     */
    function _afterRegisterERC721(address tokenAddress) internal virtual view {}

     /**
     * @notice hook that is called before removeERC721
     */
    function _beforeRemoveERC721(address tokenAddress) internal virtual view {
        require(tokenAddress != address(0), "ERC721Service: tokenAddress is the zero address");
    }

     /**
     * @notice hook that is called after removeERC721
     */
    function _afterRemoveERC721(address tokenAddress) internal virtual view {}

     /**
     * @notice hook that is called before depositERC721
     */
    function _beforedepositERC721(address tokenAddress, uint256 tokenId) internal virtual view {
        require(tokenAddress != address(0), "ERC7211Service: tokenAddress is the zero address");
        require(tokenId > 0, "ERC20Service: tokenId is zero");
    }

    /**
     * @notice hook that is called after depositERC721
     */
    function _afterDepositERC721(address tokenAddress, uint256 tokenId) internal virtual view {}
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial ERC721Service interface needed by internal functions
 */
interface IERC721ServiceInternal {
    /**
     * @notice emitted when a new ERC721 token is registered
     * @param tokenAddress: the address of the ERC721 token
     */
    event ERC721TokenTracked(address indexed tokenAddress);

    /**
     * @notice emitted when a new ERC721 token is removed
     * @param tokenAddress: the address of the ERC721 token
     */
    event ERC721TokenRemoved(address indexed tokenAddress); 

     /**
     * @notice emitted when a ERC721 token is deposited.
     * @param tokenAddress: the address of the ERC721 token.
     * @param tokenId: the tokenId of token deposited.
     */
    event ERC721Deposited(address indexed tokenAddress, uint256 tokenId);
}