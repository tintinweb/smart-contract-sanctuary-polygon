/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
// SPDX-License-Identifier: MIT
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File contracts/Legacy.sol
pragma solidity 0.8.17;
contract  Legacy is ReentrancyGuard {
    bytes4 private constant ERC721_INTERFACE_ID = type(IERC721).interfaceId;
    struct Recepient {
        address receiver;
        uint8 sharePercentBps;
        uint denominator;
        uint id;
    }

    struct Asset {
        address assetAddress;
        uint32 expiresAt;
        uint allowance;
        Recepient[] recepients;
    }

    mapping(address => mapping(address => Asset)) private _wills;
    // mapping(address => uint32) private _expiresAt;

    event WillCreated(
        address indexed testator, 
        address assestAddress,
        uint32 createdAt, 
        uint32 expiresAt
    );
    event WillExecuted(
        address indexed testator, 
        address assetAddress,
        uint32 expiresAt,
        uint32 executedAt
    );

    function createWill(Asset memory asset) external nonReentrant {
        require(asset.expiresAt > uint32(block.timestamp), "expire time too small");
        validateAsset(asset);

        Asset storage will = _wills[msg.sender][asset.assetAddress];
        for(uint j = 0; j < asset.recepients.length; j++) {
            will.recepients.push(Recepient({
                receiver: asset.recepients[j].receiver,
                sharePercentBps: asset.recepients[j].sharePercentBps,
                denominator: asset.recepients[j].denominator,
                id: asset.recepients[j].id
            }));
        }
        will.assetAddress = asset.assetAddress;
        will.expiresAt = asset.expiresAt;
        will.allowance = asset.allowance;
        
        emit WillCreated(msg.sender, asset.assetAddress,uint32(block.timestamp), asset.expiresAt);
    }

    function executeWill(address testator, address assetAddress) external nonReentrant {
        Asset memory will = _wills[testator][assetAddress];


        if(
            IERC165(will.assetAddress).supportsInterface(ERC721_INTERFACE_ID)
        ) {
            _handleERC721Asset(testator, will);
        }
        else {
            _handleERC20Asset(testator, will);
        }

        delete _wills[testator][assetAddress];

        emit WillExecuted(testator, assetAddress,uint32(block.timestamp), will.expiresAt);
    }

    function validateAsset(Asset memory asset) internal view {

        require(asset.assetAddress != address(0), "zero asset address");
        require(asset.assetAddress.code.length > 0, "address not contract");

        for(uint j = 0; j < asset.recepients.length; j++) {
            Recepient memory recepient = asset.recepients[j];
            require(
                recepient.receiver != address(0), 
                "zero recepient address"
            );
            if(
                IERC165(asset.assetAddress).supportsInterface(ERC721_INTERFACE_ID)
            ) {
                require(recepient.id != 0, "zero token id");
                require(
                    msg.sender == IERC721(asset.assetAddress).ownerOf(
                        recepient.id
                    ), "caller not token owner"
                );
            }
            else {
                require(recepient.sharePercentBps > 0, "share percentage < 0");
                require(recepient.denominator >= 100, "percentage should be in bps");
            }
        }
    }

    function _handleERC20Asset(address testator, Asset memory asset) internal {
        uint balance = IERC20(asset.assetAddress).balanceOf(testator);
        if(balance > asset.allowance) {
            balance = asset.allowance;
        }
        for(uint i = 0; i < asset.recepients.length; i++) {
            Recepient memory recep = asset.recepients[i];
            uint amount = (balance * recep.sharePercentBps) / recep.denominator;
            if(amount > 0) {
                _handleERC20Transfer(
                    asset.assetAddress, 
                    testator, 
                    recep.receiver, 
                    amount
                );
            }
        }
    }

    function _handleERC721Asset(address testator, Asset memory asset) internal {
        for(uint i = 0; i < asset.recepients.length; i++) {
            Recepient memory recep = asset.recepients[i];
            _handleERC721Transfer(
                asset.assetAddress, 
                recep.id, 
                testator, 
                recep.receiver
            );
        }
    }
    
    function _handleERC20Transfer(
        address token,
        address from,
        address to,
        uint amount
    ) private {
        IERC20(token).transferFrom(from, to, amount);
    }

    function _handleERC721Transfer(
        address token,
        uint tokenId,
        address from,
        address to
    ) private {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }
}