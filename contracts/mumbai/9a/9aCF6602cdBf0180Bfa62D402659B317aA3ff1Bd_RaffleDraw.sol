// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./Base.sol";
import "./interfaces/IRaffleDraw.sol";
import "./interfaces/IChibiLuckyToken.sol";

contract RaffleDraw is Base, IRaffleDraw {
    /** --------------------STORAGE VARIABLES-------------------- */
    using Counters for Counters.Counter;
    /**
     * raffle draws
     */
    mapping(uint256 => Draw) public raffleDraws;
    /**
     * the total number of raffle draws
     */
    uint256 public totalRaffleDraws;
    /**
     * draw => player => entries mapping
     */
    mapping(uint256 => mapping(address => uint256[]))
        public raffleDrawPlayerEntryMapping;
    /**
     * draw => entry => player mapping
     */
    mapping(uint256 => mapping(uint256 => address))
        public raffleDrawEntryPlayerMapping;
    /**
     * role for managing raffle draws
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /**
     * external contracts
     */
    IERC1155 public luckyTokenContract;
    /**
     * winner mapping by entries
     */
    mapping(uint256 => DrawWinner)
        private _raffleDrawWinners;
    /**
     * raffle id counter
     */
    Counters.Counter private _raffleDrawIdCounter;

    /** --------------------STORAGE VARIABLES-------------------- */

    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * see {IRaffleDraw-buyEntries}
     */
    function buyEntries(
        uint256 drawId,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external override {
        require(drawId < totalRaffleDraws, "CHIBI:INVALID_ID");
        require(
            luckyTokenIds.length == numberOfTokens.length,
            "CHIBI:ARRAY_LENGTHS_MUST_MATCH"
        );
        require(luckyTokenIds.length > 0, "CHIBI:INVALID_LUCKY_TOKENS");
        Draw memory draw = raffleDraws[drawId];
        require(draw.status == DrawStatus.ACTIVE, "CHIBI:INVALID_STATUS");
        require(
            draw.endDate >= block.timestamp,
            "CHIBI:TOO_LATE_TO_BUY_ENTRIES"
        );

        uint256 newEntries = _calculateNumberOfEntries(
            draw.tier,
            luckyTokenIds,
            numberOfTokens
        );
        require(
            (draw.currentEntries + newEntries) <= draw.totalEntries,
            "CHIBI:EXCEED_MAXIMUM_AVAILABLE_ENTRIES"
        );
        require(
            (raffleDrawPlayerEntryMapping[drawId][msg.sender].length +
                newEntries) <= draw.maxEntriesPerWallet,
            "CHIBI:EXCEED_MAXIMUM_AVAILABLE_ENTRIES_FOR_A_WALLET"
        );

        uint256[] memory newEntryIndexes = new uint256[](newEntries);
        for (uint256 i = 0; i < newEntries; i++) {
            uint256 newEntry = draw.currentEntries + i;
            // add entries to player
            raffleDrawPlayerEntryMapping[draw.id][msg.sender].push(
                newEntry
            );
            // mapping entry => player
            raffleDrawEntryPlayerMapping[draw.id][newEntry] = msg
                .sender;
            newEntryIndexes[i] = newEntry;
        }
        // update currentEntries;
        raffleDraws[drawId].currentEntries += newEntries;

        emit RaffleDrawEntriesBought(drawId, msg.sender, newEntryIndexes);
    }

    /**
     * see {IRaffleDraw-findRaffleDraws}
     */
    function findRaffleDraws(uint256[] calldata drawIds)
        external
        view
        override
        returns (Draw[] memory draws)
    {
        draws = new Draw[](drawIds.length);
        for (uint256 i; i < draws.length; i++) {
            draws[i] = raffleDraws[i];
        }
    }

    /**
     * see {IRaffleDraw-getDrawPlayerStatus}
     */
    function getDrawPlayerStatus(uint256[] calldata drawIds)
        external
        view
        override
        returns (DrawPlayerStatus[] memory statuses)
    {
        statuses = new DrawPlayerStatus[](drawIds.length);
        for (uint256 i = 0; i < drawIds.length; i++) {
            Draw memory draw = raffleDraws[drawIds[i]];
            bool canBuyEntries = (draw.totalEntries > draw.currentEntries) &&
                (draw.maxEntriesPerWallet >
                    raffleDrawPlayerEntryMapping[draw.id][msg.sender].length);
            uint256 availableEntries = draw.maxEntriesPerWallet -
                raffleDrawPlayerEntryMapping[draw.id][msg.sender].length;
            if (availableEntries > draw.totalEntries - draw.currentEntries) {
                availableEntries = draw.totalEntries - draw.currentEntries;
            }
            statuses[i] = DrawPlayerStatus({
                canBuyEntries: canBuyEntries,
                availableEntries: availableEntries
            });
        }
    }

    /**
     * see {IRaffleDraw-calculateNumberOfEntries}
     */
    function calculateNumberOfEntries(
        Tier tier,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external pure override returns (uint256 numberOfEntries) {
        numberOfEntries = _calculateNumberOfEntries(
            tier,
            luckyTokenIds,
            numberOfTokens
        );
    }

    /**
     * see {IRaffleDraw-pickWinners}
     */
    function pickWinners(uint256 drawId) external override onlyRole(MANAGER_ROLE){
        Draw memory draw = raffleDraws[drawId];
        require(drawId < totalRaffleDraws, "CHIBI:INVALID_ID");
        require(draw.status == DrawStatus.ACTIVE, "CHIBI:INVALID_STATUS");
        require(
            draw.endDate < block.timestamp,
            "CHIBI:CANNOT_PICK_WINNER_YET"
        );

        uint256[] memory winnerEntries;
        address[] memory winners;
        if (draw.currentEntries <= draw.numberOfPrizes) {
            // all are winners
            winnerEntries = new uint256[](draw.currentEntries);
            for (uint256 i = 0; i < draw.currentEntries; i++){
                winnerEntries[i] = i;
                winners[i] = raffleDrawEntryPlayerMapping[drawId][winnerEntries[i]];
                _raffleDrawWinners[drawId].entryMapping[winnerEntries[i]] = true;
            }
            _raffleDrawWinners[drawId].entries = winnerEntries;
        } else {
            winnerEntries = new uint256[](draw.numberOfPrizes);
            for (uint256 i = 0; i < draw.numberOfPrizes; i++){
                uint256 randomEntry = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.number,
                            i == 0 ? address(0) : winners[i] // previous winner
                        )
                    )
                ) % draw.currentEntries;
                while (_raffleDrawWinners[drawId].entryMapping[randomEntry]){
                    // move to the first next entry which is not picked yet
                    randomEntry = (randomEntry + 1) % draw.currentEntries;
                }
                winnerEntries[i] = randomEntry;
                winners[i] = raffleDrawEntryPlayerMapping[drawId][winnerEntries[i]];
                _raffleDrawWinners[drawId].entryMapping[winnerEntries[i]] = true;
            }
        }

        emit RaffleDrawWinnerPicked(drawId, winnerEntries, winners);

        raffleDraws[drawId].status = DrawStatus.COMPLETED;
        emit RaffleDrawStatusUpdated(drawId, DrawStatus.COMPLETED);
    }

    /**
     * see {IRaffleDraw-addRaffleDraw}
     */
    function addRaffleDraw(
        Tier tier,
        uint40 endDate,
        uint256 totalEntries,
        uint256 maxEntriesPerWallet,
        uint256 numberOfPrizes,
        string calldata name
    ) external override onlyRole(MANAGER_ROLE) {
        uint256 id = _raffleDrawIdCounter.current();
        _raffleDrawIdCounter.increment();
        raffleDraws[id] = Draw({
            id: id,
            tier: tier,
            status: DrawStatus.INACTIVE,
            endDate: endDate,
            totalEntries: totalEntries,
            maxEntriesPerWallet: maxEntriesPerWallet,
            numberOfPrizes: numberOfPrizes,
            name: name,
            description: "",
            imageUrl: "",
            currentEntries: 0
        });
        totalRaffleDraws += 1;

        emit RaffleDrawAdded(
            id,
            DrawStatus.INACTIVE,
            tier,
            endDate,
            totalEntries,
            maxEntriesPerWallet,
            numberOfPrizes,
            name
        );
    }

    /**
     * see {IRaffleDraw-updateRaffleDraw}
     */
    function updateRaffleDraw(
        uint256 id,
        Tier tier,
        uint40 endDate,
        uint256 totalEntries,
        uint256 maxEntriesPerWallet,
        uint256 numberOfPrizes
    ) external override onlyRole(MANAGER_ROLE) {
        require(id < totalRaffleDraws, "CHIBI:INVALID_ID");
        require(
            raffleDraws[id].status == DrawStatus.INACTIVE,
            "CHIBI:INVALID_STATUS"
        );

        raffleDraws[id].tier = tier;
        raffleDraws[id].endDate = endDate;
        raffleDraws[id].totalEntries = totalEntries;
        raffleDraws[id].maxEntriesPerWallet = maxEntriesPerWallet;
        raffleDraws[id].numberOfPrizes = numberOfPrizes;

        emit RaffleDrawUpdated(
            id,
            tier,
            endDate,
            totalEntries,
            maxEntriesPerWallet,
            numberOfPrizes
        );
    }

    /**
     * see {IRaffleDraw-updateRaffleDrawDesc}
     */
    function updateRaffleDrawDesc(
        uint256 id,
        string calldata name,
        string calldata description,
        string calldata imageUrl
    ) external override onlyRole(MANAGER_ROLE) {
        require(id < totalRaffleDraws, "CHIBI:INVALID_ID");
        require(
            raffleDraws[id].status == DrawStatus.INACTIVE,
            "CHIBI:INVALID_STATUS"
        );

        raffleDraws[id].name = name;
        raffleDraws[id].description = description;
        raffleDraws[id].imageUrl = imageUrl;

        emit RaffleDrawDescUpdated(id, name, description, imageUrl);
    }

    /**
     * see {IRaffleDraw-setRaffleDrawStatus}
     */
    function setRaffleDrawStatus(uint256 id, DrawStatus status)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(id < totalRaffleDraws, "CHIBI:INVALID_ID");

        raffleDraws[id].status = status;
        emit RaffleDrawStatusUpdated(id, status);
    }

    /**
     * see {IRaffleDraw-setExternalContractAddresses}
     */
    function setExternalContractAddresses(address luckyTokenAddr)
        external
        override
        onlyOwner
    {
        luckyTokenContract = IERC1155(luckyTokenAddr);
    }

    /** --------------------EXTERNAL FUNCTIONS-------------------- */

    /** --------------------PRIVATE FUNCTIONS-------------------- */
    /**
     * calculate number of entries can be bought using luck tokens (based on tier)
     */
    function _calculateNumberOfEntries(
        Tier tier,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) private pure returns (uint256 numberOfEntries) {
        for (uint256 i = 0; i < luckyTokenIds.length; i++) {
            if (tier == Tier.Common) {
                // Common Raffles: Gold(1) tokens = 4 entries, Silver(2) token = 2 entries, Bronze(3) token = 1 entry.
                require(
                    luckyTokenIds[i] >= 1 && luckyTokenIds[i] <= 3,
                    "CHIBI:INVALID_TOKEN_ID"
                );
                if (luckyTokenIds[i] == 1) {
                    numberOfEntries += 4 * numberOfTokens[i];
                } else if (luckyTokenIds[i] == 2) {
                    numberOfEntries += 2 * numberOfTokens[i];
                } else {
                    numberOfEntries += numberOfTokens[i];
                }
            } else if (tier == Tier.Rare) {
                // Rare Raffles: Gold token = 2 entries, Silver token = 1 entry.
                require(
                    luckyTokenIds[i] >= 1 && luckyTokenIds[i] <= 2,
                    "CHIBI:INVALID_TOKEN_ID"
                );
                if (luckyTokenIds[i] == 1) {
                    numberOfEntries += 2 * numberOfTokens[i];
                } else {
                    numberOfEntries += numberOfTokens[i];
                }
            } else {
                // Epic Raffles: Gold token = 1 entry.
                require(luckyTokenIds[i] == 1, "CHIBI:INVALID_TOKEN_ID");
                numberOfEntries += numberOfTokens[i];
            }
        }
    }
    /** --------------------PRIVATE FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT
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

    /**
     * see {IBase-withdrawERC721}
     */
    function withdrawERC721(IERC721 token, uint256[] calldata tokenIds)
        external
        override
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.safeTransferFrom(address(this), owner(), tokenIds[i]);
        }
    }
    /** --------------------EXTERNAL FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

interface IRaffleDraw {
    enum Tier {
        Common,
        Rare,
        Epic
    }

    enum DrawStatus {
        ACTIVE,
        COMPLETED,
        INACTIVE
    }

    struct Draw {
        uint256 id;
        DrawStatus status;
        Tier tier;
        uint40 endDate;
        uint256 totalEntries;
        uint256 currentEntries;
        uint256 maxEntriesPerWallet;
        uint256 numberOfPrizes;
        string name;
        string description;
        string imageUrl;
    }

    struct DrawPlayerStatus {
        bool canBuyEntries;
        uint256 availableEntries;
    }

    struct DrawWinner {
        uint256[] entries;
        mapping(uint256 => bool) entryMapping;
    }

    event RaffleDrawAdded(
        uint256 indexed id,
        DrawStatus indexed status,
        Tier indexed tier,
        uint40 endDate,
        uint256 totalEntries,
        uint256 maxEntriesPerWallet,
        uint256 numberOfPrizes,
        string name
    );

    event RaffleDrawUpdated(
        uint256 indexed id,
        Tier indexed tier,
        uint40 endDate,
        uint256 totalEntries,
        uint256 maxEntriesPerWallet,
        uint256 numberOfPrizes
    );

    event RaffleDrawDescUpdated(
        uint256 indexed id,
        string name,
        string description,
        string imageUrl
    );

    event RaffleDrawStatusUpdated(uint256 indexed id, DrawStatus status);

    event RaffleDrawEntriesBought(uint256 indexed id, address player, uint256[] entries);

    event RaffleDrawWinnerPicked(uint256 indexed id, uint256[] entries, address[] winners);

    /**
     * buy entries in a Raffle Draw with Luck tokens
     * Common Raffles: Gold tokens = 4 entries, Silver token = 2 entries, Bronze token = 1 entry.
     * Rare Raffles: Gold token = 2 entries, Silver token = 1 entry.
     * Epic Raffles: Gold token = 1 entry.
     */
    function buyEntries(
        uint256 drawId,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external;

    /**
     * get draw status for a player
     */
    function findRaffleDraws(uint256[] calldata drawIds)
        external
        view
        returns (Draw[] memory draws);

    /**
     * get draw status for a player
     */
    function getDrawPlayerStatus(uint256[] calldata drawIds)
        external
        view
        returns (DrawPlayerStatus[] memory statuses);

    /**
     * calculate number of entries can be bought using luck tokens (based on tier)
     */
    function calculateNumberOfEntries(
        Tier tier,
        uint256[] calldata luckyTokenIds,
        uint256[] calldata numberOfTokens
    ) external pure returns (uint256 numberOfEntries);

    /**
     * pick winners - manager only
     */
    function pickWinners(uint256 drawId) external;

    /**
     * add new raffle draw
     */
    function addRaffleDraw(
        Tier tier,
        uint40 endDate,
        uint256 totalEntries,
        uint256 maxEntriesPerWallet,
        uint256 numberOfPrizes,
        string calldata name
    ) external;

    /**
     * update raffle draw end date
     */
    function updateRaffleDraw(
        uint256 id,
        Tier tier,
        uint40 endDate,
        uint256 totalEntries,
        uint256 maxEntriesPerWallet,
        uint256 numberOfPrizes
    ) external;

    /**
     * update raffle draw end date
     */
    function updateRaffleDrawDesc(
        uint256 id,
        string calldata name,
        string calldata description,
        string calldata imageUrl
    ) external;

    /**
     * set raffle draw status
     */
    function setRaffleDrawStatus(uint256 id, DrawStatus status) external;

    /**
     * set external contract addresses
     */
    function setExternalContractAddresses(address luckyTokenAddr) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

interface IChibiLuckyToken {
    /**
     * free mint, each wallet can only mint one token
     */
    function freeMint() external;

    /**
     * mint tokens with $SHIN
     */
    function mintWithShin(uint256 numberOfTokens) external;

    /**
     * mint tokens with Seals. Each seal can only be used once.
     */
    function mintWithSeal(uint256[] calldata sealTokenIds) external;

    /**
     * mint tokens with Chibi Legends. Each Legend can only be used once.
     */
    function mintWithChibiLegends(uint256[] calldata legendTokenIds) external;

    /**
     * check if can use Seals to mint
     */
    function canUseSeals(uint16[] calldata sealTokenIds)
        external
        view
        returns (bool[] memory statuses);

    /**
     * check if can use Chibi Legends to mint
     */
    function canUseChibiLegends(uint16[] calldata legendTokenIds)
        external
        view
        returns (bool[] memory statuses);

    /**
     * mint - only minter
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * mint batch - only minter
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /**
     * set base token URI & extension - only contract owner
     */
    function setURI(string memory newUri, string memory newExtension) external;

    /**
     * set external contract addresses (Shin) - only contract owner
     */
    function setExternalContractAddresses(
        address shinAddr,
        address chibiLegendAddr,
        address sealAddr
    ) external;

    /*
     * enable/disable mint - only contract owner
     */
    function enableMint(bool shouldEnableMintWithShin) external;

    /*
     * set mint cost ($SHIN) - only contract owner
     */
    function setMintCost(uint256 newCost) external;

    /**
     * set Chibi Legend - Lucky Token mapping
     */
    function setChibiLegendLuckyTokenMapping(
        uint256[] calldata chibiLegendTokenIds,
        uint256[] calldata luckyTokenIds
    ) external;

    /**
     * set Seal - Lucky Token mapping
     */
    function setSealLuckyTokenMapping(
        uint256[] calldata sealTokenIds,
        uint256[] calldata luckyTokenIds
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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * Base contract
 */
interface IBase {
    /**
     * withdraw all ERC20 tokens - contract owner only
     */
    function withdrawAllERC20(IERC20 token) external;

    /**
     * withdraw ERC721 tokens in an emergency case - contract owner only
     */
    function withdrawERC721(IERC721 token, uint256[] calldata tokenIds)
        external;
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