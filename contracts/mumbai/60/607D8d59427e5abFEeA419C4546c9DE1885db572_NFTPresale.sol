// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/ICNTNFT.sol";
import "../libraries/TransferHelper.sol";

/**
 * @dev {NFTPresale} contract, including:
 *
 *  - ability to mint NFTs using merkle proofs
 *  - allows to update params by `owner`
 *  - allows to start/stop NFT sale
 *  - allows to buy NFTs
 */
contract NFTPresale is Ownable {
    event Redeemed(address _user, uint256 _nftId);

    // Merkle root which consists of whitelisted users.
    bytes32 public root;

    // Number of NFTs per user.
    uint256 public userLimit;

    // Number of NFTs allowed for airdrop.
    uint256 public maxMintingAllowed;

    // NFT to be airdropped.
    ICNTNFT public erc721;

    // Token address which will be used to NFTs.
    IERC20 public buyToken;

    // Amount which is paid to buy NFTs.
    uint256 public buyAmount;

    // If true user can buy NFTs.
    bool public presaleStatus;

    // If true anyone without merkleproofs can buy NFTs.
    bool public openBuy;

    // Total number NFTs minted per address
    mapping(address => uint256) public mintedNFTs;

    // Total number NFTs minted.
    uint256 public totalNFTsMinted;

    struct TokenInfo {
        uint256 amount;
        bool isActive;
    }

    mapping(address => TokenInfo) public allowedBuyTokenInfo;

    /**
     * Constructor
     */
    constructor(
        uint256 _userLimit,
        uint256 _maxMintingAllowed,
        bytes32 _merkleroot,
        ICNTNFT _erc721,
        IERC20 _buyToken,
        uint256 _buyAmount
    ) {
        userLimit = _userLimit;
        maxMintingAllowed = _maxMintingAllowed;
        root = _merkleroot;
        erc721 = _erc721;
        buyToken = _buyToken;

        allowedBuyTokenInfo[address(_buyToken)] = TokenInfo({
            amount: buyAmount,
            isActive: true
        });

        buyAmount = _buyAmount;
    }

    /**
     * @notice Only owner can update the merkle root.
     *
     * @param _root New merkle root.
     */
    function updateMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    /**
     * @notice Only owner can update allowed minting of NFTs through this contract.
     *
     * @param _maxMintingAllowed Allowed number of NFTs.
     */
    function updateMaxMintingAllowed(uint256 _maxMintingAllowed)
        external
        onlyOwner
    {
        maxMintingAllowed = _maxMintingAllowed;
    }

    /**
     * @notice Only owner can update allowed minting of NFTs through this contract.
     *
     * @param _userLimit Allowed number of NFTs user is allowed to mint.
     */
    function updateUserLimit(uint256 _userLimit) external onlyOwner {
        userLimit = _userLimit;
    }

    /**
     * @notice Only owner can update allowed erc721 contract address.
     *
     * @param _erc721 Address of NFT contract.
     */
    function updateERC721(ICNTNFT _erc721) external onlyOwner {
        erc721 = _erc721;
    }

    /**
     * @notice It allows to start/stop NFT sale. It can be only set by owner.
     *
     * @param _presaleStatus If true sale of NFTs is allowed.
     */
    function updatePresaleStatus(bool _presaleStatus) external onlyOwner {
        presaleStatus = _presaleStatus;
    }

    /**
     * @notice It allows to allow anyone to buy NFTs. It can be only set by owner.
     *
     * @param _openBuy If true anyone can buy NFTs without providing merkle proof.
     */
    function updateOpenBuy(bool _openBuy) external onlyOwner {
        openBuy = _openBuy;
    }

    /**
     * @notice It sets the token address which will be used to buy NFTs.
     *
     * @param _buyToken Token address.
     */
    function updateBuyToken(IERC20 _buyToken) external onlyOwner {
        buyToken = _buyToken;
    }

    /**
     * @notice It sets amount to be paid by users to buy NFTs.
     *
     * @param _buyAmount Amount to used to buy NFTs.
     */
    function updateBuyAmount(uint256 _buyAmount) external onlyOwner {
        buyAmount = _buyAmount;
    }

    function addBuyToken(address _buyToken, uint256 _buyAmount)
        external
        onlyOwner
    {
        require(_buyToken != address(0), "Invalid buy token");
        require(!allowedBuyTokenInfo[_buyToken].isActive, "Already present");

        allowedBuyTokenInfo[_buyToken] = TokenInfo({
            amount: _buyAmount,
            isActive: true
        });
    }

    function updateBuyAmount(address _buyToken, uint256 _buyAmount)
        external
        onlyOwner
    {
        require(_buyToken != address(0), "Invalid buy token");
        require(
            allowedBuyTokenInfo[_buyToken].isActive,
            "Buy token not present"
        );

        allowedBuyTokenInfo[_buyToken].amount = _buyAmount;
    }

    function updateBuyActiveness(address _buyToken, bool _isActive)
        external
        onlyOwner
    {
        require(_buyToken != address(0), "Invalid buy token");

        allowedBuyTokenInfo[_buyToken].isActive = _isActive;
    }

    /**
     * Private method which mints NFTs.
     */
    function _redeemInternal(address _account, address _token) internal {
        require(presaleStatus, "Presale is closed");
        require(
            totalNFTsMinted < maxMintingAllowed,
            "Allowed NFTs are already airdropped"
        );

        TokenInfo memory buyTokenInfo = allowedBuyTokenInfo[_token];

        require(buyTokenInfo.isActive, "Token not allowed for buying");

        require(
            mintedNFTs[_account] < userLimit,
            "Max allowed NFTs per address are minted"
        );

        TransferHelper.safeTransferFrom(
            address(_token),
            _account,
            address(this),
            buyTokenInfo.amount
        );

        erc721.mint(_account);

        mintedNFTs[_account] = mintedNFTs[_account] + (uint256(1));
        totalNFTsMinted = totalNFTsMinted + (uint256(1));

        emit Redeemed(_account, erc721.currentNFTID());
    }

    /**
     * @notice If sale is started, then users can buy NFTs.
     *         It allows to buy NFTs without proofs if `openBuy` flag is true.
     *
     * @param _account Address of user which will be minted NFTs.
     * @param _token Token which is used for buying.
     */
    function _redeem(address _account, address _token) internal {
        require(openBuy, "Buying is allowed only using proof");
        _redeemInternal(_account, _token);
    }

    function redeem(address _account, address _token) external {
        _redeem(_account, _token);
    }

    /**
     * @notice If sale is started, then users can buy NFTs.
     *         It allows to buy NFTs without proofs if `openBuy` flag is true.
     *
     * @param _account Address of user which will be minted NFTs.
     * @param _proof Merkle Proof.
     * @param _token Token which is used for buying.
     */
    function _redeemWithProof(
        address _account,
        bytes32[] calldata _proof,
        address _token
    ) internal {
        require(!openBuy, "Buying not allowed using proof");

        require(_verify(_leaf(_account), _proof), "Invalid merkle proof");

        _redeemInternal(_account, _token);
    }

    function redeemWithProof(
        address _account,
        bytes32[] calldata _proof,
        address _token
    ) external {
        _redeemWithProof(_account, _proof, _token);
    }

    function batchRedeem(
        address _account,
        address _token,
        uint256 _totalMinting
    ) external {
        for (uint256 i = 0; i < _totalMinting; i++) {
            _redeem(_account, _token);
        }
    }

    function batchRedeemWithProof(
        address _account,
        bytes32[] calldata _proof,
        address _token,
        uint256 _totalMinting
    ) external {
        for (uint256 i = 0; i < _totalMinting; i++) {
            _redeemWithProof(_account, _proof, _token);
        }
    }

    /**
     * @notice It allows owner to withdraw `buyToken` amount in this contract.
     */
    function withdraw() external onlyOwner {
        uint256 value = buyToken.balanceOf(address(this));
        if (value > 0) {
            TransferHelper.safeTransfer(address(buyToken), msg.sender, value);
        }
    }

    /**
     * @notice Does hashing of the account.
     *
     * @param _account Address of user.
     */
    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
     * @notice Merkle verification is done.
     *
     * @param _leaf Leaf in the merkle tree.
     * @param _proof Merkle Proof which includes `_leaf`.
     */
    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, root, _leaf);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICNTNFT is IERC721 {
    /**
     * Returns current NFT token id available.
     */
    function currentNFTID() external view returns (uint256);

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
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