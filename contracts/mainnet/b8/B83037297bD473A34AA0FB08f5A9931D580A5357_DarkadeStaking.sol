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
pragma solidity 0.8.18;

import "./IERC721DarksPass.sol";
import "./ICraftingChroniclesToken.sol";

contract DarkadeStaking {
    struct Staking {
        uint256 tokenId;
        uint256 stakedAt;
        address nftContractAddr;
    }

    struct NftCollection {
        uint256 nftReward;
        uint256 nftInterval;
    }

    ICraftingChroniclesToken public cctToken;
    mapping(address => Staking[]) public nftStaking;
    mapping(address => NftCollection) public nfts;
    address public admin;

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

    constructor(address _admin) {
        admin = _admin;
    }

    function stake(address _nftContract, uint256 _tokenId) external {
        require(nfts[_nftContract].nftReward > 0, "NFT collection not handled");
        require(
            IERC721DarksPass(_nftContract).ownerOf(_tokenId) == msg.sender,
            "Caller is not the owner of the NFT"
        );
        require(disabledTime == 0, "Staking is not enabled right now");

        if (hasPrevStaking(msg.sender, _nftContract, _tokenId)) {
            uint256 prevStakingIndex = indexPrevStaking(
                msg.sender,
                _nftContract,
                _tokenId
            );
            nftStaking[msg.sender][prevStakingIndex].stakedAt = block.timestamp;
        } else {
            nftStaking[msg.sender].push(
                Staking({
                    tokenId: _tokenId,
                    stakedAt: block.timestamp,
                    nftContractAddr: _nftContract
                })
            );
        }

        IERC721DarksPass(_nftContract).safeTransferFrom(
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

        IERC721DarksPass(targetStaking.nftContractAddr).allowedList(msg.sender);
        IERC721DarksPass(_nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        IERC721DarksPass(targetStaking.nftContractAddr).removeAllowedList(
            msg.sender
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
        cctToken.allowedList(receiver);
        cctToken.transfer(receiver, amount);
        cctToken.removeAllowedList(receiver);
    }

    function setNfts(
        address _nftAddress,
        uint256 _nftReward,
        uint256 _nftInterval
    ) public onlyAdmin {
        nfts[_nftAddress] = NftCollection({
            nftReward: _nftReward,
            nftInterval: _nftInterval
        });
    }

    function switchDisableFarm(bool isEnabled) public onlyAdmin {
        disabledTime = isEnabled ? block.timestamp : 0;
    }

    function hasPrevStaking(
        address user,
        address _nftContract,
        uint256 _tokenId
    ) internal view returns (bool) {
        Staking[] memory userNft = nftStaking[user];
        for (uint256 i = 0; i < userNft.length; i++) {
            if (
                userNft[i].tokenId == _tokenId &&
                userNft[i].nftContractAddr == _nftContract
            ) {
                return true;
            }
        }
        return false;
    }

    function indexPrevStaking(
        address user,
        address _nftContract,
        uint256 _tokenId
    ) internal view returns (uint256) {
        Staking[] memory userNft = nftStaking[user];
        for (uint256 i = 0; i < userNft.length; i++) {
            if (
                userNft[i].tokenId == _tokenId &&
                userNft[i].nftContractAddr == _nftContract
            ) {
                return i;
            }
        }
        return 0;
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
                userNft[i].nftContractAddr == _nftContract &&
                userNft[i].stakedAt != 0
            ) {
                require(
                    userNft[i].stakedAt != 0,
                    "Caller has not staked this NFT"
                );
                targetStaking = userNft[i];
            }
        }
        return targetStaking;
    }

    function getUserAllStaking(
        address user
    ) public view returns (Staking[] memory userStakingNfts) {
        return nftStaking[user];
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
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

    function calculateReward(
        Staking memory _targetStaking
    ) internal view returns (uint256) {
        uint256 reward = 0;
        NftCollection memory nftInfo = nfts[_targetStaking.nftContractAddr];
        uint256 elapsed = (disabledTime != 0 ? disabledTime : block.timestamp) -
            _targetStaking.stakedAt;
        reward = _targetStaking.stakedAt != 0
            ? (elapsed * nftInfo.nftReward) / nftInfo.nftInterval
            : 0;
        return reward;
    }

    function setCctToken(address _cctToken) external onlyAdmin {
        cctToken = ICraftingChroniclesToken(_cctToken);
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721DarksPass is IERC165 {
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

    function removeAllowedList(address account) external;

    function allowedList(address account) external;
}