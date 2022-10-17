//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Privileges.sol";

abstract contract TokenBalancePrivileges is Privileges {

    address internal tokenAddress;

    mapping(address => uint256) addresses;

    constructor(uint256 _price, address _tokenAddress, uint256 _limitPerWallet, uint256 _allowedLimit ,uint _startTime, uint _endTime) Privileges(_price, _limitPerWallet, _allowedLimit,  _startTime, _endTime){
        tokenAddress = _tokenAddress;
    }

    function updateLimit(address userAddress, uint256 minted) external override {
        uint256 previous = addresses[userAddress]; 
        addresses[userAddress] = previous + minted;
    }

    function userLimit(address userAddress) external view override returns(uint256){
        return limitPerWallet - addresses[userAddress];
    }
}

contract ERC721BalanceBenefits is TokenBalancePrivileges {

    constructor(uint256 _price, address _tokenAddress, uint256 _limitPerWallet, uint256 _allowedLimit ,uint _startTime, uint _endTime) 
    TokenBalancePrivileges(_price, _tokenAddress, _limitPerWallet, _allowedLimit ,_startTime, _endTime){

    }

    function isUserEligible(address userAddress) external override view returns(bool){
        return IERC721(tokenAddress).balanceOf(userAddress) > 0;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IPrivileges.sol";

abstract contract Privileges is IPrivileges {

    uint256 internal price;
    uint internal startTime;
    uint internal endTime;
    uint256 internal limitPerWallet;
    uint256 private allowedLimit;
    uint256 internal totalMinted;

    constructor(uint256 _price, uint256 _limitPerWallet, uint256 _allowedLimit, uint _startTime, uint _endTime){
        price = _price;
        startTime = _startTime;
        endTime = _endTime;
        limitPerWallet = _limitPerWallet;
        allowedLimit = _allowedLimit;
    }

    function availableLimit() external view returns(uint256){
        return allowedLimit - totalMinted;
    }

    function getPrice() external view override returns(uint256){
        return price;
    }

    function hasSaleStarted() external view returns(bool){
        return block.timestamp >= startTime;
    }

    function hasSaleEnded() external view returns(bool){
        return block.timestamp >= endTime;
    }

    function updateLimit(address userAddress, uint256 minted) external virtual;

    function userLimit(address userAddress) external virtual view returns(uint256);

    function isUserEligible(address userAddress) external virtual view returns(bool);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IPrivileges {
    function getPrice() external view returns(uint256);

    function hasSaleStarted() external view returns(bool);

    function hasSaleEnded() external view returns(bool);

    function updateLimit(address userAddress, uint256 minted) external;

    function userLimit(address userAddress) external view returns(uint256);

    function availableLimit() external view returns(uint256);

    function isUserEligible(address userAddress) external view returns(bool);
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