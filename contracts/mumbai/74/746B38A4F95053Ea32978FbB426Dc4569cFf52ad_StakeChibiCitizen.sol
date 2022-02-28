// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IStakeChibiCitizen.sol";
import "./interfaces/IChibiCitizen.sol";
import "./interfaces/IShin.sol";
import "./Base.sol";

contract StakeChibiCitizen is
    IStakeChibiCitizen,
    IERC721Receiver,
    Pausable,
    Base
{
    /** --------------------STORAGE VARIABLES-------------------- */
    /**
     * max tokens can be processed per transaction
     */
    uint256 public constant MAX_TOKENS_PER_TX = 50;
    /**
     * minimum time staked before claiming
     */
    uint256 public constant MINIMUM_TIME_TO_CLAIM = 2 days;
    /**
     * tax percentage for Soldiers & Chibi Legends
     */
    uint256 public constant TAX_PERCENTAGE_FOR_SOLDIERS = 20;
    uint256 public constant TAX_PERCENTAGE_FOR_CHIBI_LEGENDS = 10;
    /**
     * total number of Genesis Chibi Legends
     */
    uint256 public constant NUMBER_OF_GENESIS_LEGENDS = 5555;
    /**
     * number of workers, sodilers staked
     */
    uint256 public numberOfWorkersStaked = 0;
    uint256 public numberOfSoldiersStaked = 0;
    /**
     * total amount of $SHIN minted
     */
    uint256 public totalShinMinted = 0;
    /**
     * total amount of $SHIN minted paid to soldier
     */
    uint256 public totalShinPaidToSoldiers = 0;
    /**
     * unlock date. Users can only unstake citizens & claim $SHIN after this date
     */
    uint256 public unlockDate;
    /**
     * mapping of exp required (equal to accumulated staked days) for each level
     */
    mapping(uint8 => uint16) public expRequiredByLevel;
    /**
     * mapping of number of $SHIN can be minted per day for each level
     */
    mapping(uint8 => uint256) public shinMintedByLevel;
    /**
     * external contracts
     */
    IChibiCitizen public chibiCitizenContract;
    IERC721 public chibiCitizenContractERC721;
    IERC721 public chibiLegendContract;
    IShin public shinContract;
    /**
     * used to divide $SHIN in pool
     */
    uint256 private _totalLevelsOfStakedSoldiers = 0;
    /**
     * stake mapping data
     */
    mapping(uint256 => Stake) private _citizensStaked;
    /**
     * mapping how much $SHIN has been claimed by chibi legends
     */
    mapping(uint256 => uint256) private _chibiLegendClaimed;

    /** --------------------STORAGE VARIABLES-------------------- */

    /** --------------------MODIFIERS-------------------- */
    /**
     * check if exceeding maximum tokens all allowed per transaction
     */
    modifier onlyWhenNotExceedMaximumTokensPerTx(uint256 numberOfTokens) {
        require(
            numberOfTokens <= MAX_TOKENS_PER_TX,
            "CHIBI::EXCEED_MAXIMUM_TOKENS_PER_TRANSACTION"
        );
        _;
    }

    /** --------------------MODIFIERS-------------------- */

    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * See {IStakeChibiCitizen-stakeCitizens}
     */
    function stakeCitizens(uint16[] calldata tokenIds)
        external
        override
        whenNotPaused
        nonReentrant
        onlyWhenNotExceedMaximumTokensPerTx(tokenIds.length)
    {
        require(tokenIds.length > 0, "CHIBI::CITIZENS_ARE_REQUIRED");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stakeCitizen(tokenIds[i]);
        }
    }

    /**
     * See {IStakeChibiCitizen-claimCitizens}
     */
    function claimCitizens(uint16[] calldata tokenIds, bool unstake)
        external
        override
        nonReentrant
        onlyWhenNotExceedMaximumTokensPerTx(tokenIds.length)
    {
        require(block.timestamp >= unlockDate, "CHIBI::LOCKED");
        require(tokenIds.length > 0, "CHIBI::CITIZENS_ARE_REQUIRED");
        uint256 earnings = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            earnings += _claimCitizen(tokenIds[i], unstake, false);
        }
        // mint shin
        if (earnings >= 0) {
            shinContract.mint(_msgSender(), earnings);
        }
    }

    /**
     * See {IStakeChibiCitizen-getStakeStatuses}
     */
    function getStakeStatuses(uint16[] calldata tokenIds)
        external
        view
        override
        returns (Stake[] memory statuses)
    {
        statuses = new Stake[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            statuses[i] = _citizensStaked[tokenIds[i]];
        }
    }

    /**
     * See {IStakeChibiCitizen-canUnstake}
     */
    function canUnstake(uint16[] calldata tokenIds)
        external
        view
        override
        returns (bool[] memory statuses)
    {
        statuses = new bool[](tokenIds.length);
        if (block.timestamp > unlockDate) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (
                    _citizensStaked[tokenIds[i]].stakedAt > 0 &&
                    (block.timestamp - _citizensStaked[tokenIds[i]].stakedAt) >
                    MINIMUM_TIME_TO_CLAIM
                ) {
                    statuses[i] = true;
                }
            }
        }
    }

    /**
     * See {IStakeChibiCitizen-getAccumulatedRewards}
     */
    function getAccumulatedRewards(uint16[] calldata tokenIds)
        external
        view
        override
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IChibiCitizen.Citizen memory citizen = chibiCitizenContract
                .getToken(tokenIds[i]);
            if (citizen.class == IChibiCitizen.CitizenClass.SOLDIER) {
                rewards[i] = _getEarningsOfSoldier(citizen);
            } else {
                rewards[i] = _getEarningsOfWoker(citizen);
            }
        }
    }

    /**
     * See {IStakeChibiCitizen-payTaxToChibiLegends}
     */
    function payTaxToChibiLegends(uint16[] calldata tokenIds)
        external
        override
        onlyOwner
    {
        require(tokenIds.length > 0, "CHIBI::LEGENDS_ARE_REQUIRED");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 earnings = ((totalShinMinted *
                TAX_PERCENTAGE_FOR_CHIBI_LEGENDS) /
                100 -
                _chibiLegendClaimed[tokenIds[i]]) / NUMBER_OF_GENESIS_LEGENDS;
            // should only pay when earnings > 1 $SHIN
            if (earnings > 1 ether) {
                address owner = chibiLegendContract.ownerOf(tokenIds[i]);
                _chibiLegendClaimed[tokenIds[i]] += earnings;
                shinContract.mint(owner, earnings);
                emit ChibiLegendTaxPaid(
                    owner,
                    tokenIds[i],
                    block.timestamp,
                    earnings
                );
            }
        }
    }

    /**
     * See {IStakeChibiCitizen-setPauseStaking}
     */
    function setPauseStaking(bool isPaused) external override onlyOwner {
        if (isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * See {IStakeChibiCitizen-setExternalContractAddresses}
     */
    function setExternalContractAddresses(
        address chibiCitizenAddr,
        address chibiLegendContractAddr,
        address shinAddr
    ) external override onlyOwner {
        chibiCitizenContract = IChibiCitizen(chibiCitizenAddr);
        chibiCitizenContractERC721 = IERC721(chibiCitizenAddr);
        chibiLegendContract = IERC721(chibiLegendContractAddr);
        shinContract = IShin(shinAddr);
    }

    /**
     * See {IStakeChibiCitizen-setShinMintedByLevel}
     */
    function setShinMintedByLevel(
        uint8[] calldata levels,
        uint256[] calldata shinMinted
    ) external override onlyOwner {
        require(
            levels.length == shinMinted.length,
            "CHIBI:ARRAY_LENGTHS_MUST_MATCH"
        );
        for (uint256 i = 0; i < levels.length; i++) {
            shinMintedByLevel[levels[i]] = shinMinted[i];
        }
    }

    /**
     * See {IStakeChibiCitizen-setExpRequiredByLevel}
     */
    function setExpRequiredByLevel(
        uint8[] calldata levels,
        uint16[] calldata expRequired
    ) external override onlyOwner {
        require(
            levels.length == expRequired.length,
            "CHIBI:ARRAY_LENGTHS_MUST_MATCH"
        );
        for (uint256 i = 0; i < levels.length; i++) {
            expRequiredByLevel[levels[i]] = expRequired[i];
        }
    }

    /**
     * See {IStakeChibiCitizen-setUnlockDate}
     */
    function setUnlockDate(uint256 newUnlockDate) external override onlyOwner {
        unlockDate = newUnlockDate;
    }

    /**
     * See {IStakeChibiCitizen-forceReleaseCitizens}
     */
    function forceReleaseCitizens(uint256[] calldata tokenIds)
        external
        override
        onlyOwner
    {
        require(tokenIds.length > 0, "CHIBI::CITIZENS_ARE_REQUIRED");
        uint256 earnings = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            earnings = _claimCitizen(tokenIds[i], true, true);
            // mint shin
            if (earnings >= 0) {
                shinContract.mint(_citizensStaked[tokenIds[i]].owner, earnings);
            }
        }
    }

    /**
     * required by IERC721Receiver
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /** --------------------EXTERNAL FUNCTIONS-------------------- */

    /** --------------------PRIVATE FUNCTIONS-------------------- */
    /**
     * stake a citizen
     */
    function _stakeCitizen(uint256 tokenId) private {
        address owner = chibiCitizenContractERC721.ownerOf(tokenId);
        require(
            owner == _msgSender(),
            string(
                abi.encodePacked(
                    "CHIBI::MUST_BE_OWNER_OF_CITIZEN(",
                    Strings.toString(tokenId),
                    ")"
                )
            )
        );

        IChibiCitizen.Citizen memory citizen = chibiCitizenContract.getToken(
            tokenId
        );
        uint40 timestamp = uint40(block.timestamp);
        _citizensStaked[tokenId] = Stake({
            tokenId: uint16(tokenId),
            class: citizen.class,
            stakedAt: timestamp,
            lastClaimedAt: timestamp,
            owner: owner
        });

        if (citizen.class == IChibiCitizen.CitizenClass.SOLDIER) {
            numberOfSoldiersStaked += 1;
            _totalLevelsOfStakedSoldiers += citizen.level;
        } else {
            numberOfWorkersStaked += 1;
        }

        chibiCitizenContractERC721.safeTransferFrom(
            owner,
            address(this),
            tokenId
        );
        emit CitizenStaked(owner, tokenId, block.timestamp);
    }

    /**
     * realize $SHIN earnings for a single citizen
     * @param tokenId the ID of the citizen
     * @param unstake whether or not to unstake the citizen
     * @param forced force unstaking by contract owner
     * @return earnings - the amount of $SHIN earned
     */
    function _claimCitizen(
        uint256 tokenId,
        bool unstake,
        bool forced
    ) private returns (uint256 earnings) {
        Stake memory stake = _citizensStaked[tokenId];
        IChibiCitizen.Citizen memory citizen = chibiCitizenContract.getToken(
            tokenId
        );
        require(
            stake.stakedAt != 0,
            string(
                abi.encodePacked(
                    "CHIBI::CITIZEN_NOT_FOUND(",
                    Strings.toString(tokenId),
                    ")"
                )
            )
        );
        require(
            stake.owner == _msgSender() || forced,
            string(
                abi.encodePacked(
                    "CHIBI::MUST_BE_OWNER_OF_CITIZEN(",
                    Strings.toString(tokenId),
                    ")"
                )
            )
        );
        uint256 stakedDuration = block.timestamp - stake.stakedAt;
        require(
            stakedDuration >= MINIMUM_TIME_TO_CLAIM,
            string(
                abi.encodePacked(
                    "CHIBI::CAN_NOT_CLAIM_CITIZEN_YET(",
                    Strings.toString(tokenId),
                    ")"
                )
            )
        );

        if (stake.class == IChibiCitizen.CitizenClass.SOLDIER) {
            require(
                unstake == true,
                string(
                    abi.encodePacked(
                        "CHIBI::MUST_UNSTAKE_SOLDIER_CITIZEN(",
                        Strings.toString(tokenId),
                        ")"
                    )
                )
            );
            earnings = _claimShinForSoldier(citizen);
        } else {
            earnings = _claimShinForWorker(citizen);
        }

        if (unstake) {
            // update level & exp
            uint16 newExp = citizen.exp +
                uint16((stakedDuration * 10) / 1 days);
            uint8 newLevel = citizen.level;
            if (
                expRequiredByLevel[citizen.level + 1] > 0 &&
                newExp >= expRequiredByLevel[citizen.level + 1]
            ) {
                newLevel = citizen.level + 1;
            }
            chibiCitizenContract.setLevel(tokenId, newLevel, newExp);
            // remove count
            if (citizen.class == IChibiCitizen.CitizenClass.SOLDIER) {
                numberOfSoldiersStaked -= 1;
            } else {
                numberOfWorkersStaked -= 1;
            }
            // remove stake data
            delete _citizensStaked[tokenId];
            // Always transfer last to guard against reentrance
            chibiCitizenContractERC721.safeTransferFrom(
                address(this),
                stake.owner,
                tokenId
            );
        } else {
            stake.lastClaimedAt = uint40(block.timestamp);
        }
        emit CitizenClaimed(
            _msgSender(),
            tokenId,
            block.timestamp,
            earnings,
            unstake
        );
    }

    /**
     * realize $SHIN earnings for a single worker then pay tax to Soldiers & Chibi Legends
     * @param worker the worker
     * @return earnings - the amount of $SHIN earned
     */
    function _claimShinForWorker(IChibiCitizen.Citizen memory worker)
        private
        returns (uint256 earnings)
    {
        uint256 minted = _getEarningsOfWoker(worker);

        // calculate $SHIN earned
        earnings =
            (minted *
                (100 -
                    TAX_PERCENTAGE_FOR_SOLDIERS -
                    TAX_PERCENTAGE_FOR_CHIBI_LEGENDS)) /
            100;

        // update total $SHIN minted (to calculate tax later)
        totalShinMinted += minted;
    }

    /**
     * realize $SHIN earnings for a single soldier
     * @param soldier the soldier
     * @return earnings - the amount of $SHIN earned
     */
    function _claimShinForSoldier(IChibiCitizen.Citizen memory soldier)
        private
        returns (uint256 earnings)
    {
        earnings = _getEarningsOfSoldier(soldier);
        totalShinPaidToSoldiers += earnings;
    }

    /**
     * realize $SHIN earnings for a single worker
     * @param worker the worker
     * @return earnings - the amount of $SHIN earned
     */
    function _getEarningsOfWoker(IChibiCitizen.Citizen memory worker)
        private
        view
        returns (uint256 earnings)
    {
        uint256 unclaimedDuration = block.timestamp -
            _citizensStaked[worker.tokenId].lastClaimedAt;
        earnings =
            (unclaimedDuration * shinMintedByLevel[worker.level] * 1 ether) /
            1 days;
    }

    /**
     * realize $SHIN earnings for a single soldier
     * @param soldier the worker
     * @return earnings - the amount of $SHIN earned
     */
    function _getEarningsOfSoldier(IChibiCitizen.Citizen memory soldier)
        private
        view
        returns (uint256 earnings)
    {
        if (_totalLevelsOfStakedSoldiers == 0) {
            return 0;
        }
        earnings =
            (((totalShinMinted * TAX_PERCENTAGE_FOR_SOLDIERS) /
                100 -
                totalShinPaidToSoldiers) * soldier.level) /
            _totalLevelsOfStakedSoldiers;
    }
    /** --------------------PRIVATE FUNCTIONS-------------------- */
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

import "./IChibiCitizen.sol";

/**
 * Stake Chibi Citizens
 * Workers start at Level 1 and will Level Up Based on the accumulated number of Days they have been staked:
 * - Level 1 -> Level 2: 10 Days
 * - Level 2 -> Level 3: 20 Days
 * - Level 3 -> Level 4: 30 Days
 * - Level 4 -> Level 5: 40 Days
 * Rewards for staking Workers
 * - Level 1: 100 SHIN/day
 * - Level 2: 125 SHIN/day
 * - Level 3: 150 SHIN/day
 * - Level 4: 175 SHIN/day
 * - Level 5: 200 SHIN/day
 * Soldiers collect $SHIN from Workers.
 * Soldiers start at Level 1 and will Level Up Based on the accumulated number of Days they have been staked:
 * - Level 1 -> Level 2: 10 Days
 * - Level 2 -> Level 3: 20 Days
 * - Level 3 -> Level 4: 30 Days
 * - Level 4 -> Level 5: 40 Days
 * Both workers & soldiers can only be unstaked after 2 days
 * Rewards calculation:
 * The Workers receive protection from Soldiers against beasts, monsters and other unknown threats. In exchange, the Soldiers collect 10% of the Workers’ claimed $SHIN.
 * In addition, the Chibi Legends collect 10% of the Workers’ claimed $SHIN as the governors and commanders of this new land.
 * This 10% goes into a Treasury that accumulates over time, is split for all Chibi Legends, and can be claimed by Legend holders at any time
 * Shin may be locked till an exact date
 */
interface IStakeChibiCitizen {
    /**
     * struct to store a stake's token, owner, and earning values
     */
    struct Stake {
        uint16 tokenId;
        IChibiCitizen.CitizenClass class;
        uint40 stakedAt;
        uint40 lastClaimedAt;
        address owner;
    }

    event CitizenStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed stakedAt
    );

    event CitizenClaimed(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed claimedAt,
        uint256 earned,
        bool unstake
    );

    event ChibiLegendTaxPaid(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed paidAt,
        uint256 amount
    );

    /**
     * stake citizens
     */
    function stakeCitizens(uint16[] calldata tokenIds) external;

    /**
     * claim rewards from citizens & unstake
     * must unstake soldiers, workers are optional
     */
    function claimCitizens(uint16[] calldata tokenIds, bool unstake) external;

    /**
     * return accumulated rewards of Citizens
     */
    function getStakeStatuses(uint16[] calldata tokenIds)
        external
        view
        returns (Stake[] memory statuses);

    /**
     * check if tokens can be unstaked
     */
    function canUnstake(uint16[] calldata tokenIds)
        external
        view
        returns (bool[] memory statuses);

    /**
     * return accumulated rewards of Citizens
     */
    function getAccumulatedRewards(uint16[] calldata tokenIds)
        external
        view
        returns (uint256[] memory rewards);

    /**
     * pay tax in pool to chibi legends - only contract owner
     */
    function payTaxToChibiLegends(uint16[] calldata tokenIds) external;

    /**
     * pause/unpause staking - only contract owner
     */
    function setPauseStaking(bool isPaused) external;

    /**
     * set external contract addresses (ChibiCitizen, ChibiLegend, Shin) - only contract owner
     */
    function setExternalContractAddresses(
        address chibiCitizenAddr,
        address chibiLegendContractAddr,
        address shinAddr
    ) external;

    /**
     * set amount of $SHIN minted for each level
     */
    function setShinMintedByLevel(
        uint8[] calldata levels,
        uint256[] calldata shinMinted
    ) external;

    /**
     * set exp required to upgrade level
     */
    function setExpRequiredByLevel(
        uint8[] calldata levels,
        uint16[] calldata expRequired
    ) external;

    /**
     * Set unlock date - only contract owner
     * Only after that date can users unstake citizens & claim $SHIN
     */
    function setUnlockDate(uint256 unlockDate) external;

    /**
     * Force release citizens - only contract owner
     */
    function forceReleaseCitizens(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

interface IChibiCitizen {
    /**
     * Mint method: 0 - Shin, 1 - Seal, 2 - Whitelist
     */
    event Minted(
        uint256 indexed tokenId,
        uint8 indexed generation,
        CitizenClass indexed class,
        uint16 classId,
        uint8 mintMethod
    );
    event LevelChanged(
        uint256 indexed tokenId,
        uint8 indexed level,
        uint16 indexed exp
    );
    event MetadataChanged(
        uint256 indexed tokenId,
        uint8 indexed generation,
        CitizenClass indexed class,
        uint16 classId,
        uint8 level,
        uint16 exp
    );

    enum CitizenClass {
        SOLDIER,
        FARMER,
        TRADER,
        CRAFTSMAN
    }

    /**
     * Metadata of citizen
     */
    struct Citizen {
        CitizenClass class;
        uint16 classId;
        /** citizen generation from 0 => 5 */
        uint8 generation;
        /** default 1 */
        uint8 level;
        /** default 0 */
        uint16 exp;
        bool minted;
        uint256 tokenId;
    }

    /**
     * mint Citizen - only minters, which are other smart contracts (such as CitizenStaking contract)
     */
    function safeMint(
        address to,
        uint8 generation,
        CitizenClass citizenClass,
        uint16 classId,
        uint8 mintMethod
    ) external;

    /**
     * update citizen's level & exp - only level managers
     */
    function setLevel(
        uint256 tokenId,
        uint8 level,
        uint16 exp
    ) external;

    /**
     * update Citizen metadata - metadata managers, mostly to fix when something goes wrong
     */
    function setMetadata(
        uint256 tokenId,
        uint8 generation,
        CitizenClass citizenClass,
        uint16 classId,
        uint8 level,
        uint16 exp
    ) external;

    /**
     * set base token URI to use fixed metadata or dynamic metadata (including level, experience) - only contract owner
     */
    function setBaseTokenURI(
        string calldata baseTokenURI,
        bool useFixedMetadata
    ) external;

    /**
     * return token
     */
    function getToken(uint256 tokenId) external view returns (Citizen memory);

    /**
     * return all tokens
     */
    function getTokens(uint256 startIndex, uint256 numberOfTokens)
        external
        view
        returns (Citizen[] memory tokens);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

interface IShin {
    /**
     * Only minters can mint SHIN, which are other smart contracts (such as CitizenStaking contract)
     */
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./AccessControl.sol";
import "./interfaces/IBase.sol";

/**
 * Base contract
 */
abstract contract Base is IBase, AccessControl, ReentrancyGuard {
    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * see {IBase-withdrawAllERC20}
     */
    function withdrawAllERC20(IERC20 token)
        external
        override
        onlyOwner
        nonReentrant
    {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "CHIBI::BALANCE_MUST_BE_GREATER_THAN_0");

        token.transfer(owner(), balance);
    }
    /** --------------------EXTERNAL FUNCTIONS-------------------- */
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IAccessControl.sol";

/**
 * Get the idea from Openzeppelin AccessControl
 */
abstract contract AccessControl is IAccessControl, Ownable {
    /** --------------------STORAGE VARIABLES-------------------- */
    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;
    /** --------------------STORAGE VARIABLES-------------------- */

    /** --------------------MODIFIERS-------------------- */
    /**
     * Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /** --------------------MODIFIERS-------------------- */

    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * see {IAccessControl-hasRole}
     */
    function hasRole(bytes32 role, address account)
        external
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * see {IAccessControl-grantRole}
     */
    function grantRole(bytes32 role, address account)
        external
        virtual
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    /**
     * see {IAccessControl-revokeRole}
     */
    function revokeRole(bytes32 role, address account)
        external
        virtual
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    /**
     * see {IAccessControl-renounceRole}
     */
    function renounceRole(bytes32 role, address account)
        external
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /** --------------------EXTERNAL FUNCTIONS-------------------- */

    /** --------------------INTERNAL FUNCTIONS-------------------- */
    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _roles[role].members[account];
    }
    /** --------------------INTERNAL FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Base contract
 */
interface IBase {
    /**
     * withdraw all ERC20 tokens - contract owner only
     */
    function withdrawAllERC20(IERC20 token) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.2;

interface IAccessControl {
    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}