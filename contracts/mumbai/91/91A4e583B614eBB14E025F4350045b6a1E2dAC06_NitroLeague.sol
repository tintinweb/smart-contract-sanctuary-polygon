/**
 *Submitted for verification at polygonscan.com on 2022-07-06
*/

//SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: @openzeppelin/contracts/utils/Counters.sol

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts/utils/TokenWithdrawer.sol

pragma solidity >=0.7.0 <0.9.0;

contract TokenWithdrawer is Ownable {
    constructor() {}

    /// Withdraw ETH to owner.
    /// Used for recovering value sent to contract.
    /// @param amount of ETH, in Wei, to withdraw.
    function withdrawETH(uint256 amount) external payable onlyOwner {
        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /// Withdraw ERC-20 token to owner.
    /// @param token as address.
    /// @param amount of tokens including decimals.
    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(_msgSender(), amount);
    }

    /// Withdraw ERC-721 token to owner.
    /// @param token as address.
    /// @param tokenID of NFT.
    function withdrawERC721(address token, uint256 tokenID) external onlyOwner {
        IERC721(token).transferFrom(address(this), owner(), tokenID);
    }

    /// Withdraw ERC1155 token to owner.
    /// @param token as address.
    /// @param tokenID of NFT.
    /// @param amount of NFT.
    function withdrawERC1155(
        address token,
        uint256 tokenID,
        uint256 amount
    ) external onlyOwner {
        IERC1155(token).safeTransferFrom(
            address(this),
            owner(),
            tokenID,
            amount,
            ""
        );
    }
}
// File: contracts/utils/RewardManager.sol

pragma solidity >=0.7.0 <0.9.0;

contract RewardManager is Context, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    /// EMPTY when no rewards are added.
    /// UNAWARDED once rewards are added.
    /// AWARDED once results are submitted.
    /// CLAIMED once all winners have claimed prize.
    enum RewardState {
        EMPTY,
        UNAWARDED,
        AWARDED,
        CLAIMED
    }
    RewardState public rewardState;

    /// Number of winning positions.
    uint256 public winningPositions;

    /// Token type of reward.
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }
    /// Used for all reward types.
    struct Reward {
        TokenType tokenType;
        address token;
        uint256 tokenID; // Not applicable to ERC-20.
        uint256 amount; // Not applicable to ERC-721.
        bool claimed;
    }

    /// Incrementally set Reward ID's.
    Counters.Counter public rewardIDCounter;
    /// Unique ID's for each Reward.
    mapping(uint256 => Reward) public rewards; // rewardID => Reward
    /// The rewards awarded to each winning position. First place is key 1.
    mapping(uint256 => uint256[]) public positionRewards; // position => [rewardID, ...]
    /// Final event results. First place is key 1.
    mapping(uint256 => address) public positionResults; // position => player
    /// Emitted on claimReward().
    event ClaimReward(address claimant, address token, uint256 amount);

    constructor() {}

    /// Set rewards for this RaceEvent.
    /// @param winningPositions_ as number of winners in this event.
    /// @param positions as uint256 array.
    /// @param tokenTypes as TokenType array.
    /// @param tokens as address array.
    /// @param tokenIDs of NFTs, where applicable. Use `0` for non-NFT Rewards.
    /// @param amounts of tokens, in decimals.
    function setRewards(
        uint256 winningPositions_,
        uint256[] memory positions,
        TokenType[] calldata tokenTypes,
        address[] memory tokens,
        uint256[] calldata tokenIDs,
        uint256[] calldata amounts
    ) external onlyOwner {
        winningPositions = winningPositions_;
        for (uint256 i = 0; i < positions.length; i++) {
            // Transfer reward token from owner to contract.
            bool transferred = false;
            if (tokenTypes[i] == TokenType.ERC20) {
                IERC20(tokens[i]).approve(address(this), amounts[i]);
                IERC20(tokens[i]).transferFrom(
                    _msgSender(),
                    address(this),
                    amounts[i]
                );
                transferred = true;
            } else if (tokenTypes[i] == TokenType.ERC721) {
                IERC721(tokens[i]).approve(address(this), tokenIDs[i]);
                IERC721(tokens[i]).transferFrom(
                    _msgSender(),
                    address(this),
                    tokenIDs[i]
                );
                transferred = true;
            } else if (tokenTypes[i] == TokenType.ERC1155) {
                IERC1155(tokens[i]).setApprovalForAll(address(this), true);
                IERC1155(tokens[i]).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    tokenIDs[i],
                    amounts[i],
                    ""
                );
                transferred = true;
            }
            require(transferred, "Failed to transfer reward(s)");
            // Create rewardID.
            uint256 rewardID = rewardIDCounter.current();
            // Assign Reward to rewardID.
            rewards[rewardID] = Reward(
                tokenTypes[i],
                tokens[i],
                tokenIDs[i],
                amounts[i],
                false
            );
            // Assign rewardID to position.
            positionRewards[positions[i]].push(rewardID);
            // Increment rewardID.
            rewardIDCounter.increment();
        }
        // Set reward state.
        rewardState = RewardState.UNAWARDED;
    }

    /// As winner, claim rewards for the won position.
    /// @param position to claim rewards for.
    function claimRewards(uint256 position) external nonReentrant {
        // Check claim validity.
        require(
            positionResults[position] == _msgSender(),
            "Caller did not win this reward"
        );
        // For each Reward awarded to this position.
        for (uint256 i = 0; i < positionRewards[position].length; i++) {
            // Get rewardID.
            uint256 rewardID = positionRewards[position][i];
            // If Reward is unclaimed.
            if (!rewards[rewardID].claimed) {
                // Get token type of Reward to claim.
                TokenType tokenType = rewards[rewardID].tokenType;
                // Transfer rewarded token to winner.
                if (tokenType == TokenType.ERC20) {
                    IERC20(rewards[rewardID].token).transfer(
                        _msgSender(),
                        rewards[rewardID].amount
                    );
                    rewards[rewardID].claimed = true;
                } else if (tokenType == TokenType.ERC721) {
                    IERC721(rewards[rewardID].token).transferFrom(
                        address(this),
                        _msgSender(),
                        rewards[rewardID].tokenID
                    );
                    rewards[rewardID].claimed = true;
                } else if (tokenType == TokenType.ERC1155) {
                    IERC1155(rewards[rewardID].token).safeTransferFrom(
                        address(this),
                        _msgSender(),
                        rewards[rewardID].tokenID,
                        rewards[rewardID].amount,
                        ""
                    );
                    rewards[rewardID].claimed = true;
                }
                // Emit ClaimReward.
                if (rewards[rewardID].claimed)
                    emit ClaimReward(
                        _msgSender(),
                        rewards[rewardID].token,
                        rewards[rewardID].amount
                    );
            }
        }
        // Check if all rewards are claimed.
        bool allClaimed = false;
        // For each winning position.
        for (uint256 i = 0; i < winningPositions; i++) {
            // For each reward in that position.
            for (uint256 j = 0; j < positionRewards[i].length; j++) {
                // Check if reward is claimed.
                allClaimed = rewards[positionRewards[i][j]].claimed;
            }
        }
        // Update reward state once all rewards are claimed.
        if (allClaimed) rewardState = RewardState.CLAIMED;
    }
}
// File: contracts/interfaces/IRace.sol

pragma solidity >=0.7.0 <0.9.0;

/// @title Nitro League Race.
/// @author Quinn Woods for Nitro League.
interface IRace {
    function setRaceSettings(
        uint256 raceAccess_,
        uint256[] memory minMaxPlayers,
        address feeToken_,
        uint256 feeAmount_,
        uint256 winningPositions_
    ) external;

    function setURI(string calldata uri_) external;

    function startRace() external;

    function endRace(address payable[] memory results_) external;

    function addPlayers(address payable[] memory players_) external;

    function joinRace() external;

    function setFeeToken(address feeToken_) external;

    function setfeeAmount(uint256 feeAmount_) external;
}
// File: contracts/interfaces/IRaceEvent.sol

pragma solidity >=0.7.0 <0.9.0;

interface IRaceEvent {
    function isRaceEvent() external returns (bool);

    function completeEvent(address payable[] memory results_) external;

    function cancelEvent() external;

    function createRace(
        string calldata raceID,
        string calldata title,
        string calldata uri,
        uint256 raceStartTime
    ) external returns (address);
}
// File: contracts/interfaces/INitroLeague.sol

pragma solidity >=0.7.0 <0.9.0;

interface INitroLeague {
    function getGame() external view returns (address);

    function setGame(address game_) external;

    function createRaceEvent(string calldata raceEventID, uint256 raceEventType)
        external
        returns (address);

    function raceIDExists(string calldata raceID) external returns (bool);

    function addRaceID(string calldata raceID) external;

    function getTreasuryWallet() external returns (address);

    function setTreasuryWallet(address treasuryWallet_) external;
}

// File: contracts/Race.sol

pragma solidity >=0.7.0 <0.9.0;

/// @title Nitro League Race.
/// @author Quinn Woods for Nitro League.
contract Race is IRace, Context, Ownable, RewardManager, TokenWithdrawer {
    ////////////
    // ACCESS //
    ////////////
    // See Ownable.

    /// Source of all RaceEvent's and Race's.
    INitroLeague public nitroLeague;
    /// Authorized to end race and set results.
    address public game;

    // METADATA //

    string public raceID;
    string public title;
    string public uri;
    uint256 public raceStartTime;

    //////////
    // GAME //
    //////////

    /// UNSCHEDULED once contract is deployed.
    /// SCHEDULED once setRaceSettings() is called.
    /// ACTIVE once startRace() is called.
    /// COMPLETE once endRace() is called.
    enum RaceState {
        UNSCHEDULED,
        SCHEDULED,
        ACTIVE,
        COMPLETE
    }
    RaceState public raceState;

    /// ADMIN where only the admin can add players.
    /// OPEN where anyone can join as a player.
    enum RaceAccess {
        ADMIN,
        OPEN
    }
    RaceAccess public raceAccess;

    /// List of joined players.
    address[] public players;
    uint256 public minPlayers;
    uint256 public maxPlayers;
    event AddPlayer(address player, uint256 numPlayers);

    /// Emitted on Race deployment.
    event ScheduleRace();
    /// Emitted on startRace().
    event StartRace();
    /// Emitted on endRace().
    event EndRace();

    //////////
    // FEES //
    //////////

    /// Fee receiver.
    address public treasuryWallet;
    /// Token paid by joining players.
    IERC20 public feeToken;
    /// Amount of feeToken paid by joining players.
    uint256 public feeAmount;

    /////////////////
    // CREATE RACE //
    /////////////////

    /// Create new race.
    /// @param nitroLeague_ as INitroLeague address.
    /// @param raceID_ as unique string.
    /// @param title_ as string name of race.
    /// @param uri_ as string location of metadata.
    /// @param raceStartTime_ as UNIX timestamp after which the race can begin.
    constructor(
        address nitroLeague_,
        string memory raceID_,
        string memory title_,
        string memory uri_,
        uint256 raceStartTime_
    ) {
        // Access.
        nitroLeague = INitroLeague(nitroLeague_);
        game = nitroLeague.getGame();
        // Transfer race ownership to race event owner.
        transferOwnership(tx.origin);

        // Metadata.
        raceID = raceID_;
        title = title_;
        uri = uri_;
        raceStartTime = raceStartTime_;

        // Game.
        raceState = RaceState.UNSCHEDULED;
    }

    /// Set race settings.
    /// @param raceAccess_ as uint256 index in RaceAccess type.
    /// @param minMaxPlayers as [min, max] players needed for the race to begin.
    /// @param feeToken_ as address of token paid to join game.
    /// @param feeAmount_ as amount of tokens paid to join game.
    /// @param winningPositions_ as number of winners in race.
    function setRaceSettings(
        uint256 raceAccess_,
        uint256[] memory minMaxPlayers,
        address feeToken_,
        uint256 feeAmount_,
        uint256 winningPositions_
    ) external override onlyOwner {
        // Game.
        raceState = RaceState.SCHEDULED;
        raceAccess = RaceAccess(raceAccess_);
        minPlayers = minMaxPlayers[0];
        maxPlayers = minMaxPlayers[1];

        // Fees.
        treasuryWallet = nitroLeague.getTreasuryWallet();
        feeToken = IERC20(feeToken_);
        feeAmount = feeAmount_;

        // Rewards.
        rewardState = RewardState.EMPTY;
        winningPositions = winningPositions_;

        // Race successfully created.
        emit ScheduleRace();
    }

    //////////////
    // METADATA //
    //////////////

    /// Set metadata URI.
    /// @param uri_ as string.
    function setURI(string calldata uri_) external override onlyOwner {
        uri = uri_;
    }

    //////////
    // GAME //
    //////////

    /// Start race.
    function startRace() external override onlyOwner {
        // Check race rules.
        require(block.timestamp > raceStartTime, "Not yet race start time");
        require(players.length >= minPlayers, "Not enough players");
        require(raceState == RaceState.SCHEDULED, "Race is not scheduled");
        // Check rewards.
        require(rewardState == RewardState.UNAWARDED, "No rewards added");
        // Start race.
        raceState = RaceState.ACTIVE;
        emit StartRace();
    }

    /// End race.
    /// @param results_ as address array of players.
    function endRace(address payable[] memory results_) external override {
        // Check caller is game.
        require(_msgSender() == game, "Only game can set results");
        // Set game results.
        for (uint256 i = 0; i <= results_.length; i++)
            positionResults[i + 1] = results_[i]; // Result mapping begins at 1.
        // End race.
        raceState = RaceState.COMPLETE;
        rewardState = RewardState.AWARDED;
        emit EndRace();
        // Transfer fees to treasury wallet.
        uint256 feeBalance = feeToken.balanceOf(address(this));
        if (feeBalance > 0) feeToken.transfer(treasuryWallet, feeBalance);
    }

    /////////////
    // PLAYERS //
    /////////////

    /// Add player(s) to the race.
    /// @dev Ensure that duplicate player is not being added. // TODO
    /// @param players_ as address array.
    function addPlayers(address payable[] memory players_)
        external
        override
        onlyOwner
    {
        // Check race rules.
        require(raceAccess == RaceAccess.ADMIN, "RaceAccess must be ADMIN");
        require(
            players.length + players_.length <= maxPlayers,
            "Too many players"
        );
        // Check rewards are added.
        require(
            rewardState == RewardState.UNAWARDED,
            "RewardState must be UNAWARDED"
        );
        // Add players.
        for (uint256 i = 0; i < players_.length; i++) {
            players.push(players_[i]);
            emit AddPlayer(players_[i], players.length);
        }
    }

    /// Join a race as a player.
    function joinRace() external override {
        // Check race rules.
        require(raceAccess == RaceAccess.OPEN, "RaceAccess must be open");
        require(players.length < maxPlayers, "Too many players");
        // Check rewards are added.
        require(
            rewardState == RewardState.UNAWARDED,
            "RewardState must be UNAWARDED"
        );
        // Take fee, if necessary.
        if (feeAmount > 0) {
            feeToken.approve(address(this), feeAmount);
            feeToken.transferFrom(_msgSender(), address(this), feeAmount);
        }
        players.push(_msgSender());
        emit AddPlayer(_msgSender(), players.length);
    }

    //////////
    // FEES //
    //////////

    /// Set fee token.
    /// @param feeToken_ as address of token.
    function setFeeToken(address feeToken_) external override onlyOwner {
        feeToken = IERC20(feeToken_);
    }

    /// Set fee amount.
    /// @param feeAmount_ as amount of tokens.
    function setfeeAmount(uint256 feeAmount_) external override onlyOwner {
        feeAmount = feeAmount_;
    }

    /////////////
    // REWARDS //
    /////////////
    // See RewardManager.
    // See TokenWithdrawer.
}
// File: contracts/interfaces/IRaceFactory.sol

pragma solidity >=0.7.0 <0.9.0;

interface IRaceFactory {
    function newRace(
        address nitroLeague_,
        string memory raceID_,
        string memory title_,
        string memory uri_,
        uint256 raceStartTime_
    ) external returns (Race);
}
// File: contracts/RaceEvent.sol

pragma solidity >=0.7.0 <0.9.0;

/// @title Nitro League RaceEvent to create and manage Race's.
/// @author Quinn Woods for Nitro League.
contract RaceEvent is
    IRaceEvent,
    Context,
    Ownable,
    RewardManager,
    TokenWithdrawer
{
    ////////////
    // ACCESS //
    ////////////
    // See Ownable.

    /// Permit INitroLeague to create the RaceEvent.
    INitroLeague public nitroLeague;
    /// Generates Race's.
    IRaceFactory public raceFactory;

    ////////////////
    // RACE EVENT //
    ////////////////

    /// ACTIVE when contract is deployed.
    /// COMPLETE when results are set.
    /// CANCELLED only if rewardState is EMPTY.
    enum RaceEventState {
        ACTIVE,
        COMPLETE,
        CANCELLED
    }
    RaceEventState public raceEventState;

    /// DAILY when recurs once per day.
    /// WEEKLY when recurs once per week.
    /// MONTHLY when recurs once per month.
    /// TOURNAMENT when recurs intermittently.
    enum RaceEventType {
        DAILY,
        WEEKLY,
        MONTHLY,
        TOURNAMENT
    }
    RaceEventType public raceEventType;

    /// RaceEvent completed.
    event CompleteRaceEvent();
    /// RaceEvent cancelled.
    event CancelRaceEvent();

    ///////////
    // RACES //
    ///////////
    // Event => Race(s) is 1 => many.

    /// Race ID's and their Race.
    mapping(string => IRace) public races; // raceID => Race.
    /// Emitted on createRace().
    event CreateRace(string raceID, address raceAddress);

    ///////////////////////
    // CREATE RACE EVENT //
    ///////////////////////

    /// Create RaceEvent.
    /// @param nitroLeague_ as address of NitroLeague.
    /// @param raceFactory_ as address of RaceFactory.
    /// @param raceEventType_ as number for enum RaceEvent.RaceEventType.
    constructor(
        address nitroLeague_,
        address raceFactory_,
        uint256 raceEventType_
    ) {
        // Access.
        nitroLeague = INitroLeague(nitroLeague_);
        raceFactory = IRaceFactory(raceFactory_);
        // Transfer race event ownership to caller.
        transferOwnership(tx.origin);

        // Race Event.
        raceEventState = RaceEventState.ACTIVE;
        raceEventType = RaceEventType(raceEventType_);

        // Rewards.
        rewardState = RewardState.EMPTY;
    }

    /// Confirms to INitroLeague that this is a RaceEvent.
    /// @return bool as true.
    function isRaceEvent() external pure override returns (bool) {
        return true;
    }

    ////////////////
    // RACE EVENT //
    ////////////////

    /// Assign winners to complete Race Event.
    /// @param results_ as address array of players, where first index is winner.
    function completeEvent(address payable[] memory results_)
        external
        override
        onlyOwner
    {
        // Set event results.
        for (uint256 i = 0; i < results_.length; i++)
            positionResults[i + 1] = results_[i]; // Result mapping begins at 1.
        // End race event.
        raceEventState = RaceEventState.COMPLETE;
        rewardState = RewardState.AWARDED;
        emit CompleteRaceEvent();
    }

    /// Cancel Race Event.
    function cancelEvent() external override onlyOwner {
        // Check no awards added.
        require(
            rewardState == RewardState.EMPTY,
            "Cannot cancel race event with unawarded/unclaimed rewards"
        );
        // End race event.
        raceEventState = RaceEventState.CANCELLED;
        emit CancelRaceEvent();
    }

    ///////////
    // RACES //
    ///////////

    /// Create a new Race.
    /// @param raceID as unique string.
    /// @param title as string name of race.
    /// @param uri as string location of metadata.
    /// @param raceStartTime as UNIX timestamp.
    /// @return address of new race contract.
    function createRace(
        string calldata raceID,
        string calldata title,
        string calldata uri,
        uint256 raceStartTime
    ) external override onlyOwner returns (address) {
        // Check race ID.
        require(!nitroLeague.raceIDExists(raceID), "Race ID exists");
        // Check race event.
        require(raceEventState == RaceEventState.ACTIVE, "Event is not active");
        // Create race.
        IRace race = IRace(
            raceFactory.newRace(
                address(nitroLeague),
                raceID,
                title,
                uri,
                raceStartTime
            )
        );
        emit CreateRace(raceID, address(race));
        // Store race ID.
        races[raceID] = race;
        nitroLeague.addRaceID(raceID);
        // Return address of race.
        return address(race);
    }

    /////////////
    // REWARDS //
    /////////////
    // See RewardManager.
    // See TokenWithdrawer.
}
// File: contracts/interfaces/IRaceEventFactory.sol

pragma solidity >=0.7.0 <0.9.0;

interface IRaceEventFactory {
    function newRaceEvent(
        address nitroLeague_,
        address raceFactory_,
        uint256 raceEventType_
    ) external returns (RaceEvent);
}
// File: contracts/NitroLeague.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title NitroLeague contract to create and manage RaceEvents.
 * @dev NitroLeague generates RaceEvent's (1 to many).
 *      Each RaceEvent generates Race's (1 to many).
 *      When RaceEvent is updated, a new NitroLeague should be deployed.
 *      The current NitroLeague's state can be migrated using sendNitroLeague().
 * @author Quinn Woods for Nitro League.
 */
contract NitroLeague is INitroLeague, Context, Ownable, TokenWithdrawer {
    ////////////
    // ACCESS //
    ////////////
    // See Ownable.

    /// Generates RaceEvent's.
    IRaceEventFactory public raceEventFactory;
    /// Generates Race's.
    IRaceFactory public raceFactory;
    /// Authorized to end race and set results.
    address private _game;

    /////////////////
    // RACE EVENTS //
    /////////////////

    /// Unique ID's of all RaceEvents.
    string[] public raceEventIDsList;
    /// RaceEvent ID is true if it exists.
    mapping(string => bool) public raceEventIDs;
    /// RaceEvent ID and its RaceEvent.
    mapping(string => IRaceEvent) public raceEvents;
    /// Emitted by createRaceEvent().
    event CreateRaceEvent(string raceEventID, address raceEvent);

    ///////////
    // RACES //
    ///////////

    /// Unique ID's of all Races.
    string[] public raceIDsList;
    /// Race ID is true if it exists.
    mapping(string => bool) public raceIDs;
    /// Receiver of Race fees.
    address private _treasuryWallet;

    /////////////////
    // CONSTRUCTOR //
    /////////////////

    /// Create a new NitroLeague.
    /// @param game_ as address of the game engine account.
    /// @param raceEventFactory_ as address of RaceEventFactory.
    /// @param raceFactory_ as address of RaceFactory.
    constructor(
        address game_,
        address raceEventFactory_,
        address raceFactory_
    ) {
        _game = game_;
        raceEventFactory = IRaceEventFactory(raceEventFactory_);
        raceFactory = IRaceFactory(raceFactory_);
    }

    ////////////
    // ACCESS //
    ////////////

    /// Get address of the game engine account.
    /// @return address of game.
    function getGame() external view override returns (address) {
        return _game;
    }

    /// Set address of the game engine account.
    /// @param game_ as address.
    function setGame(address game_) external override onlyOwner {
        _game = game_;
    }

    /////////////////
    // RACE EVENTS //
    /////////////////

    /// Create a new RaceEvent.
    /// @param raceEventID as string.
    /// @param raceEventType as number for index in RaceEvent.RaceEventType enum.
    /// @return address of new RaceEvent.
    function createRaceEvent(string calldata raceEventID, uint256 raceEventType)
        external
        override
        returns (address)
    {
        // Check race ID is unique.
        require(!raceEventIDs[raceEventID], "RaceEvent ID already exists");
        // Create race event.
        IRaceEvent raceEvent = IRaceEvent(
            raceEventFactory.newRaceEvent(
                address(this),
                address(raceFactory),
                raceEventType
            )
        );
        // Store new Race Event.
        raceEventIDsList.push(raceEventID);
        raceEventIDs[raceEventID] = true;
        raceEvents[raceEventID] = raceEvent;
        emit CreateRaceEvent(raceEventID, address(raceEvent));
        // Return RaceEvent address.
        return address(raceEvent);
    }

    ///////////
    // RACES //
    ///////////

    /// Check if a given Race ID exists.
    /// @param raceID as string.
    /// @return bool as true if raceID exists.
    function raceIDExists(string calldata raceID)
        external
        view
        override
        returns (bool)
    {
        return raceIDs[raceID];
    }

    /// Track all Race ID's to prevent collisions.
    /// @param raceID as string of the unique Race ID.
    function addRaceID(string calldata raceID) external override {
        // Only RaceEvent's can add a Race ID.
        require(
            IRaceEvent(_msgSender()).isRaceEvent(),
            "Caller is not RaceEvent"
        );
        // Record this new Race ID.
        raceIDsList.push(raceID);
        raceIDs[raceID] = true;
    }

    /// Get address of the treasury wallet fee receiver.
    /// @return address of account.
    function getTreasuryWallet() external view override returns (address) {
        return _treasuryWallet;
    }

    /// Set treasury wallet receiver of fee.
    /// @param treasuryWallet_ as address.
    function setTreasuryWallet(address treasuryWallet_)
        external
        override
        onlyOwner
    {
        _treasuryWallet = treasuryWallet_;
    }
}