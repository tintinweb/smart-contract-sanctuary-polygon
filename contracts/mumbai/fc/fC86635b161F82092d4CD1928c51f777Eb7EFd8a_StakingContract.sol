// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity 0.8.18;

interface ICraftingChroniclesToken {
    
    function buy(uint256 amount) external;
    function interalMint(address receiver, uint256 tokenId) external;
    function setCoin(address scoin) external;
    function mint(address recipient, uint256 amount) external;
    function setPrice(uint256 _price) external;
    function allowedList(address account) external;
    function removeAllowedList(address account) external;
    function isAllowedList(address account) external view returns (bool);
    function setAllowedContract(address _contract, bool _enabled) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICraftingChroniclesToken.sol";

contract StakingContract is Ownable, ERC721Holder {
    struct Staking {
        uint256 tokenId;
        uint256 stakedAt;
        address nftContractAddr;
    }

    struct NftCollection {
        uint256 nftReward;
        uint256 nftInterval;
    }

    ICraftingChroniclesToken public drkToken;
    // mapping(userAddress => {tokenId, stakedAt})
    mapping(address => Staking[]) public nftStaking;
    // mapping(nftContractAddress => {reward, interval});
    mapping(address => NftCollection) public nfts;

    uint256 disabledTime = 0;

    event Staked(
        address indexed owner,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 stakedAt
    );

    event Unstaked(
        address indexed owner,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 unstakedAt
    );

    event RewardPaid(address indexed owner, uint256 reward);

    constructor() {}

    function stake(address _nftContract, uint256 _tokenId) external {
        require(nfts[_nftContract].nftReward > 0, "NFT collection not handled");
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
            "Caller is not the owner of the NFT"
        );
        require(disabledTime == 0, "Staking is not enabled right now");

        nftStaking[msg.sender].push(
            Staking({
                tokenId: _tokenId,
                stakedAt: block.timestamp,
                nftContractAddr: _nftContract
            })
        );

        IERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        emit Staked(msg.sender, _nftContract, _tokenId, block.timestamp);
    }

    function unstake(address _nftContract, uint256 _tokenId) external {
        Staking[] memory userNft = nftStaking[msg.sender];
        Staking memory targetStaking = getUserStaking(
            msg.sender,
            _nftContract,
            _tokenId
        );
        require(
            targetStaking.tokenId != 0,
            "You have no staking with this target NFT"
        );

        uint256 reward = calculateReward(targetStaking);

        for (uint256 i = 0; i < userNft.length; i++) {
            if (userNft[i].tokenId == _tokenId) {
                address nftAddress = nftStaking[msg.sender][i].nftContractAddr;
                nftStaking[msg.sender][i] = Staking({
                    tokenId: _tokenId,
                    stakedAt: 0,
                    nftContractAddr: nftAddress
                });
            }
        }

        IERC721(_nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        payReward(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
        emit Unstaked(msg.sender, _nftContract, _tokenId, block.timestamp);
    }

    function harvestAllByContract(address _nftContract) public {
        Staking[] memory userNftStaked = getUserAllStaking(msg.sender);
        uint256 reward = 0;

        for (uint256 i = 0; i < userNftStaked.length; i++) {
            if (
                userNftStaked[i].stakedAt != 0 &&
                userNftStaked[i].nftContractAddr == _nftContract
            ) {
                uint256 _tokenId = userNftStaked[i].tokenId;
                Staking memory targetStaking = getUserStaking(
                    msg.sender,
                    userNftStaked[i].nftContractAddr,
                    _tokenId
                );

                for (uint256 a = 0; a < nftStaking[msg.sender].length; a++) {
                    if (nftStaking[msg.sender][a].tokenId == _tokenId) {
                        address nftAddress = nftStaking[msg.sender][a]
                            .nftContractAddr;
                        nftStaking[msg.sender][a] = Staking({
                            tokenId: _tokenId,
                            stakedAt: block.timestamp,
                            nftContractAddr: nftAddress
                        });
                    }
                }

                reward = reward + calculateReward(targetStaking);
            }
        }

        require(reward > 0, "You have no reward to claim");
        payReward(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function harvestAll() public {
        Staking[] memory userNftStaked = getUserAllStaking(msg.sender);
        uint256 reward = 0;

        for (uint256 i = 0; i < userNftStaked.length; i++) {
            if (userNftStaked[i].stakedAt != 0) {
                uint256 _tokenId = userNftStaked[i].tokenId;
                Staking memory targetStaking = getUserStaking(
                    msg.sender,
                    userNftStaked[i].nftContractAddr,
                    _tokenId
                );

                for (uint256 a = 0; a < nftStaking[msg.sender].length; a++) {
                    if (nftStaking[msg.sender][a].tokenId == _tokenId) {
                        address nftAddress = nftStaking[msg.sender][a]
                            .nftContractAddr;
                        nftStaking[msg.sender][a] = Staking({
                            tokenId: _tokenId,
                            stakedAt: block.timestamp,
                            nftContractAddr: nftAddress
                        });
                    }
                }

                reward = reward + calculateReward(targetStaking);
            }
        }

        require(reward > 0, "You have no reward to claim");
        payReward(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function harvest(address _nftContract, uint256 _tokenId) public {
        Staking memory targetStaking = getUserStaking(
            msg.sender,
            _nftContract,
            _tokenId
        );
        uint256 reward = calculateReward(targetStaking);
        require(reward != 0, "You have no reward to claim");

        for (uint256 i = 0; i < nftStaking[msg.sender].length; i++) {
            if (nftStaking[msg.sender][i].tokenId == _tokenId) {
                address nftAddress = nftStaking[msg.sender][i].nftContractAddr;
                nftStaking[msg.sender][i] = Staking({
                    tokenId: _tokenId,
                    stakedAt: block.timestamp,
                    nftContractAddr: nftAddress
                });
            }
        }

        payReward(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function payReward(address receiver, uint256 amount) internal {
        drkToken.allowedList(receiver);
        drkToken.transfer(receiver, amount);
        drkToken.removeAllowedList(receiver);
    }

    function setNfts(
        address _nftAddress,
        uint256 _nftReward,
        uint256 _nftInterval
    ) public onlyOwner {
        nfts[_nftAddress] = NftCollection({
            nftReward: _nftReward,
            nftInterval: _nftInterval
        });
    }

    function switchDisableFarm(bool isEnabled) public onlyOwner {
        disabledTime = isEnabled ? block.timestamp : 0;
    }

    function getUserStaking(
        address user,
        address _nftContract,
        uint256 _tokenId
    ) public view returns (Staking memory staking) {
        Staking[] memory userNft = nftStaking[user];
        Staking memory targetStaking = Staking({
            tokenId: 0,
            stakedAt: 0,
            nftContractAddr: 0x0000000000000000000000000000000000000000
        });
        for (uint256 i = 0; i < userNft.length; i++) {
            if (
                userNft[i].tokenId == _tokenId &&
                userNft[i].nftContractAddr == _nftContract
            ) {
                require(
                    userNft[i].stakedAt != 0,
                    "Caller has not staked an NFT"
                );
                targetStaking = userNft[i];
            }
        }
        return targetStaking;
    }

    function getUserAllStaking(address user)
        public
        view
        returns (Staking[] memory userStakingNfts)
    {
        return nftStaking[user];
    }

    function checkReward(address user) public view returns (uint256 rewards) {
        Staking[] memory userStakingNfts = nftStaking[user];

        uint256 reward = 0;
        for (uint256 i = 0; i < userStakingNfts.length; i++) {
            bool hasNftStaked = userStakingNfts[i].stakedAt != 0;
            reward = hasNftStaked
                ? reward + calculateReward(userStakingNfts[i])
                : reward;
        }

        return reward;
    }

    function calculateReward(Staking memory _targetStaking)
        internal
        view
        returns (uint256)
    {
        uint256 reward = 0;
        NftCollection memory nftInfo = nfts[_targetStaking.nftContractAddr];
        uint256 elapsed = (disabledTime != 0 ? disabledTime : block.timestamp) -
            _targetStaking.stakedAt;
        reward = _targetStaking.stakedAt != 0
            ? (elapsed * nftInfo.nftReward) / nftInfo.nftInterval
            : 0;
        return reward;
    }

    function setDrkToken(address _drkToken) external onlyOwner {
        drkToken = ICraftingChroniclesToken(_drkToken);
    }
}