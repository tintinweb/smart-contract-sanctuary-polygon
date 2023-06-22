// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IMysteryBox.sol";

/**
 * @title AddReward
 * @dev A contract for adding rewards to the MysteryBox contract.
 */
contract AddReward {
    /**
     * @dev Emitted when a function is called.
     * @param func The name of the function.
     * @param gas The remaining gas after the function call.
     */
    event Log(string func, uint256 gas);

    /**
     * @dev Initializes the AddReward contract.
     */
    constructor() {}

    /**
     * @dev Adds a reward to the MysteryBox contract.
     * @param _type The type of the reward (false for tokens, true for NFTs).
     * @param addressContractReward The address of the reward contract.
     * @param to The address to which the reward is added.
     * @param id_or_quantity The ID or quantity of the reward.
     */
    function addReward(bool _type, address addressContractReward, address to, uint256 id_or_quantity) public {
        if (_type == false) {
            IERC20(addressContractReward).transferFrom(msg.sender, to, id_or_quantity);
            IMysteryBox(to).addReward(false, id_or_quantity, addressContractReward);
        } else {
            IERC721(addressContractReward).safeTransferFrom(msg.sender, to, id_or_quantity);
            IMysteryBox(to).addReward(true, id_or_quantity, addressContractReward);
        }
    }
    /**
     * @dev Fallback function that allows the contract to receive ether.
     */
    fallback() external payable {
        emit Log("fallback", gasleft());
    }

    /**
     * @dev Receive function that allows the contract to receive ether when `msg.data` is empty.
     */
    receive() external payable {
        emit Log("receive", gasleft());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IMysteryBox
 * @dev Interface for the MysteryBox contract.
 */
interface IMysteryBox {
    /**
     * @dev Retrieves the details of a reward token at the specified index.
     * @param index The index of the reward token
     * @return _type The type of the reward token (NFT or TOKEN)
     * @return _amount_id The amount or ID of the reward token
     * @return dropped A boolean indicating if the reward has been dropped
     * @return _contract The address of the reward token contract
     */
    function rewardTokens(uint index) external view returns (
        uint8 _type,
        uint256 _amount_id,
        bool dropped,
        address _contract
    );

    /**
     * @dev Retrieves the details of a reward NFT at the specified index.
     * @param index The index of the reward NFT
     * @return _type The type of the reward NFT (NFT or TOKEN)
     * @return _amount_id The amount or ID of the reward NFT
     * @return dropped A boolean indicating if the reward has been dropped
     * @return _contract The address of the reward NFT contract
     */
    function rewardNFTs(uint index) external view returns (
        uint8 _type,
        uint256 _amount_id,
        bool dropped,
        address _contract
    );

    /**
     * @dev Adds a reward to the MysteryBox.
     * @param _type The type of the reward (NFT or TOKEN)
     * @param _amount_id The amount or ID of the reward
     * @param _address The address of the reward contract
     */
    function addReward(bool _type, uint256 _amount_id, address _address) external;

    /**
     * @dev Retrieves the initial quantity of keys for the MysteryBox.
     * @return qty The initial quantity of keys
     */
    function initKeyQuantity() external view returns (uint qty);

    /**
     * @dev Retrieves the current quantity of keys for the MysteryBox.
     * @return qty The current quantity of keys
     */
    function currentKeyQuantity() external view returns (uint qty);

    /**
     * @dev Sets the quantity of keys for the MysteryBox.
     */
    function setKeyQuantity() external;

    /**
     * @dev Retrieves the count of reward NFTs in the MysteryBox.
     * @return _nftRewardsCount The count of reward NFTs
     */
    function nftRewardsCount() external view returns (uint _nftRewardsCount);

    /**
     * @dev Retrieves the count of reward tokens in the MysteryBox.
     * @return _tokensCounter The count of reward tokens
     */
    function tokensCounter() external view returns (uint _tokensCounter);

    /**
     * @dev Retrieves the address of the key contract associated with the MysteryBox.
     * @return keyAddress The address of the key contract
     */
    function keyContract() external view returns (address keyAddress);

    /**
     * @dev Transfers a reward NFT from one address to another.
     * @param erc721 The address of the reward NFT contract
     * @param from The address from which to transfer the NFT
     * @param to The address to which to transfer the NFT
     * @param ID The ID of the NFT to transfer
     */
    function transferNFT(address erc721, address from, address to, uint ID) external;

    /**
     * @dev Transfers a quantity of reward tokens from one address to another.
     * @param erc20 The address of the reward token contract
     * @param to The address to which to transfer the tokens
     * @param qty The quantity of tokens to transfer
     */
    function transferTokens(address erc20, address to, uint qty) external;

    /**
     * @dev Updates the amount of a reward token at the specified index.
     * @param index The index of the reward token
     * @param amount The new amount of the reward token
     */
    function updateRewardTokens(uint index, uint amount) external;

    /**
     * @dev Retrieves the count of reward token types in the MysteryBox.
     * @return tokenTypes The count of reward token types
     */
    function tokenRewardsType() external view returns (uint tokenTypes);
}