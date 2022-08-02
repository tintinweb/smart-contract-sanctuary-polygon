// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Rewards.sol";

/** @dev stores info for each level
 * xpToCompleteLevel: xp required to levelup, x->x+1;
 * at the final level the xpToCompleteLevel must be 0
 * freeReward: free reward id to give at level x
 * premiumReward: premium reward id to give at level x
 * use lootbox (with 1 lootboxOption) to give multiple rewards at level x
 */
struct LevelInfo {
    uint256 xpToCompleteLevel;
    uint256 freeRewardId;
    uint256 freeRewardQty;
    uint256 premiumRewardId;
    uint256 premiumRewardQty;
}

/** @dev stores user info
 * xp: user's xp 
 * premium pass gets burned when used for the first time 
 * claimedPremiumPass: true when the user claims their *first* premium reward
 * user can claim premium rewards when claimedPremiumPass is true or when the user owns a premium pass
 * if the user owns a premium pass and claimedPremiumPass is true, then no premium pass gets burned 
 * claimed: true when reward is claimed at level and status {free or prem}
 */
struct User {
    uint256 xp;
    bool claimedPremiumPass;
    // level->prem?->claimed? 
    mapping(uint256 => mapping(bool => bool)) claimed;
}

/// @dev use when an error occurrs while creating a new season
error IncorrectSeasonDetails(address admin);
/// @dev use when user claims a reward for a level at which they are NOT
error NotAtLevelNeededToClaimReward(uint256 seasonId, address user, uint256 actualLevel, uint256 requiredLevel);
/// @dev use when user claims a premium reward without owning a premium pass or claimedPremiumPass is false
error NeedPremiumPassToClaimPremiumReward(uint256 seasonId, address user);
/// @dev use when user claima an already claimed reward 
error RewardAlreadyClaimed(uint256 seasonId, address user);

/**
 * @title A Battle Pass 
 * @author rayquaza7
 * @notice
 * Battle Pass is a system that rewards users for completing creator specific quests 
 * during established time periods known as seasons
 * Each creator gets 1 unique Battle Pass and the contract allows multiple seasons
 * Tracks user progress at each level and across seasons
 * Allows for giving out rewards at specified levels
 * Rewards can be { NFTs, Tokens, Lootboxes, Redeemables }
 */
contract BattlePass is Rewards {
    /// @dev emitted when a new season is created
    event NewSeason(uint256 indexed seasonId);

    /// @dev current active seasonId
    uint256 public seasonId;

    /// @dev seasonId->level->LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;
    /// @dev user->seasonId->User
    /// stores user info for each season
    mapping(address => mapping(uint256 => User)) public userInfo;

    constructor(
        string memory _uri,
        address crafting,
        address game,
        address creatorTokenCtr
    ) Rewards(_uri, crafting, game, creatorTokenCtr) {}

    /*//////////////////////////////////////////////////////////////////////
                                ADMIN 
    //////////////////////////////////////////////////////////////////////*/

    /// @notice gives xp to a user upon completion of quests
    /// @dev only owner can give xp
    /// @param _seasonId seasonId for which to give xp 
    /// @param xp amount of xp to give
    /// @param user user to give xp to
    function giveXp(
        uint256 _seasonId,
        uint256 xp,
        address user
    ) external onlyOwner {
        userInfo[user][_seasonId].xp += xp;
    }

    /// @notice sets required xp to levelup
    /// @dev owner can set xp after season creation
    /// @param _seasonId seasonId for which to change xp
    /// @param _level level at which to change xp
    /// @param xp new xp required to levelup
    function setXp(
        uint256 _seasonId,
        uint256 _level,
        uint256 xp
    ) external onlyOwner {
        seasonInfo[_seasonId][_level].xpToCompleteLevel = xp;
    }

    /**
     * @notice creates a new season
     * @dev only owner can call it
     * @param levelInfo info about each level, levelInfo[0] corresponds to info on a level 0
     * last level must be (levelInfo.length - 1) and must have xpToCompleteLevel == 0
     * @return current active seasonId
     */
    function newSeason(LevelInfo[] calldata levelInfo) external onlyOwner returns (uint256) {
        seasonId++;
        uint256 lastLevel = levelInfo.length - 1;
        if (levelInfo[lastLevel].xpToCompleteLevel != 0) revert IncorrectSeasonDetails(msg.sender);
        for (uint256 x; x <= lastLevel; x++) {
            seasonInfo[seasonId][x].xpToCompleteLevel = levelInfo[x].xpToCompleteLevel;
            addReward(seasonId, x, false, levelInfo[x].freeRewardId, levelInfo[x].freeRewardQty);
            addReward(seasonId, x, true, levelInfo[x].premiumRewardId, levelInfo[x].premiumRewardQty);
        }
        emit NewSeason(seasonId);
        return seasonId;
    }

    /**
     * @notice claims a reward for a seasonId and at level
     * @dev reverts when:
     *      user claims a reward for a level at which they are NOT
     *      user claims an already claimed reward 
     *      user claims a premium reward, but is NOT eligible for it
     * when a user has a premium pass and it is their first time claiming a premium reward then
     * burn 1 pass from their balance and set claimedPremiumPass to be true
     * a user can own multiple premium passes just like any other reward
     * it will NOT be burned if the user has already claimed a premium reward
     * @param _seasonId seasonId for which to claim the reward
     * @param user user address claiming the reward
     * @param _level level at which to claim the reward 
     * @param premium true when claiming a premium reward
     */
    function claimReward(
        uint256 _seasonId,
        address user,
        uint256 _level,
        bool premium
    ) external onlyOwner {
        if (level(user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward(_seasonId, user, level(user, _seasonId), _level);
        }

        User storage tempUserInfo = userInfo[user][_seasonId];

        if (tempUserInfo.claimed[_level][premium]) {
            revert RewardAlreadyClaimed(_seasonId, user);
        }
        tempUserInfo.claimed[_level][premium] = true;

        if (premium) {
            if (seasonInfo[_seasonId][_level].premiumRewardId == 0) return;
            if (isUserPremium(user, _seasonId)) {
                if (!tempUserInfo.claimedPremiumPass) {
                    tempUserInfo.claimedPremiumPass = true;
                    burn(user, _seasonId, 1);
                }
                mint(
                    user,
                    seasonInfo[_seasonId][_level].premiumRewardId,
                    seasonInfo[_seasonId][_level].premiumRewardQty
                );
            } else {
                revert NeedPremiumPassToClaimPremiumReward(_seasonId, user);
            }
        } else {
            if (seasonInfo[_seasonId][_level].freeRewardId == 0) return;
            mint(user, seasonInfo[_seasonId][_level].freeRewardId, seasonInfo[_seasonId][_level].freeRewardQty);
        }
    }

    /// @notice sets a reward for a seasonId and at level
    /// @dev only owner can set rewards
    /// @param _seasonId seasonId for which to change the reward
    /// @param _level level at which to change the reward
    /// @param premium true when setting a premium reward
    /// @param id new reward id
    /// @param qty new reward qty
    function addReward(
        uint256 _seasonId,
        uint256 _level,
        bool premium,
        uint256 id,
        uint256 qty
    ) public onlyOwner {
        if (premium) {
            seasonInfo[_seasonId][_level].premiumRewardId = id;
            seasonInfo[_seasonId][_level].premiumRewardQty = qty;
        } else {
            seasonInfo[_seasonId][_level].freeRewardId = id;
            seasonInfo[_seasonId][_level].freeRewardQty = qty;
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                            READ/VIEW
    //////////////////////////////////////////////////////////////////////*/

    /// @notice checks if a user has premium pass
    /// @dev user is considered premium when:
    ///     they own one premium pass or
    ///     they have already claimed a premium reward
    /// @param user user address
    /// @param _seasonId seasonId for which to check for premium pass
    /// @return true when user has premium status
    function isUserPremium(address user, uint256 _seasonId) public view returns (bool) {
        if (userInfo[user][_seasonId].claimedPremiumPass || balanceOf[user][_seasonId] >= 1) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice gets user level for a seasonId
    /// @dev breaks at the last level, where xpToCompleteLevel is 0
    /// @param user user address for which to get level
    /// @param _seasonId seasonId for which to get level
    /// @return userLevel current user level
    function level(address user, uint256 _seasonId) public view returns (uint256 userLevel) {
        uint256 maxLevelInSeason = getMaxLevel(_seasonId);
        uint256 userXp = userInfo[user][_seasonId].xp;
        uint256 cumulativeXP;
        for (uint256 x; x < maxLevelInSeason; x++) {
            cumulativeXP += seasonInfo[_seasonId][x].xpToCompleteLevel;
            if (cumulativeXP > userXp) break;
            userLevel++;
        }
    }

    /// @notice gets the max level for a seasonId
    /// @dev max level is reached when xpToCompleteLevel == 0
    function getMaxLevel(uint256 _seasonId) public view returns (uint256 maxLevel) {
        uint256 xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        while (xpToCompleteLevel != 0) {
            maxLevel++;
            xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        }
    }

    /// @notice checks a user claim status on a reward for a seasonId and at level
    /// @param user user address for which to check
    /// @param _seasonId seasonId for which to check
    /// @param _level level at which to check
    /// @param premium true when checking for premium rewards
    /// @return true when reward is claimed
    function isRewardClaimed(
        address user,
        uint256 _seasonId,
        uint256 _level,
        bool premium
    ) public view returns (bool) {
        return userInfo[user][_seasonId].claimed[_level][premium];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ICreatorToken.sol";
import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

/// @dev DO NOT CHANGE ORDERING, web3 service depends on this
enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

/**
 *  @dev a lootbox is a collection of LootboxOptions
 * rarity is rarityRange[1] - rarityRange[0]
 * the rarity of all LootboxOptions must add up to 100
 * rarityRange[0] is inclusive and rarityRange[1] is exclusive
 * give qtys[x] of ids[x]  (ids.length == qtys.length)
 * if any of the ids is CREATOR_TOKEN_ID then call the creator token contract
 */
struct LootboxOption {
    uint256[2] rarityRange;
    uint256[] ids;
    uint256[] qtys;
}

/// @dev use when an id is not within any of the approved id ranges
error InvalidId(uint256 id);
/// @dev use when a ticket id does not exist
error TicketIdDoesNotExist(bytes32 ticketId);
/// @dev use when the details for a new lootbox are incorrect
error IncorrectLootboxOptions();
/// @dev fail-safe guard
error LOLHowDidYouGetHere(uint256 lootboxId);
/// @dev use when a non-whitelisted address attempts to mint or burn
error NotWhitelisted(address sender);

/**
 * @title Pass Rewards
 * @author rayquaza7
 * @notice
 * Mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items, etc.
 * @dev
 * ERC1155 allows for both fungible and non-fungible tokens
 * Crafting/Game contracts and owner can mint and burn items for a user
 * | Token ID      | Description                                                                             |
 * |---------------|-----------------------------------------------------------------------------------------|
 * | 0             | Empty Reward                                                                            |
 * | 1-999         | Premium Passes (id === season_id); mint id x to give user a premium pass for season x   |
 * | 1000          | Creator's token; CreatorToken handles this token.                                       |
 * |               | Battle Pass is whitelisted to distribute and calls CreatorToken when id === 1000        |
 * | 1,001-9,999   | Lootboxes                                                                               |
 * | 10,000-19,999 | Redeemable Items                                                                        |
 * | 20,000-29,999 | Special NFTs/tokens                                                                     |
 * | 20,100-20,199 |        MTX-Game: defender items                                                         |
 * | 20,200-20,299 |        MTX-Game: attacker items                                                         |
 * | >30000        | Invalid, prevents errors                                                                |
 */
abstract contract Rewards is ERC1155, Owned {
    /// @dev adddresses that are allowed to mint/burn tokens
    mapping(address => bool) public whitelisted;
    /// @dev creator token contract address
    address public creatorTokenCtr;

    uint256 public constant PREMIUM_PASS_STARTING_ID = 1;
    uint256 public constant CREATOR_TOKEN_ID = 1_000;
    uint256 public constant LOOTBOX_STARTING_ID = 1_001;
    uint256 public constant REDEEMABLE_STARTING_ID = 10_000;
    uint256 public constant SPECIAL_STARTING_ID = 20_000;
    uint256 public constant INVALID_STARTING_ID = 30_000;

    event LootboxOpened(uint256 indexed lootboxId, uint256 indexed idxOpened, address indexed user);

    /// @notice whitelists game, crafting and msg.sender
    constructor(
        string memory _uri,
        address crafting,
        address game,
        address _creatorTokenCtr
    ) Owned(msg.sender) {
        tokenURI = _uri;
        whitelisted[msg.sender] = true;
        whitelisted[crafting] = true;
        whitelisted[game] = true;
        creatorTokenCtr = _creatorTokenCtr;
    }

    /// @notice sets the creator token contract
    /// @dev only owner can call it
    /// @param _creatorTokenCtr new creator token contract address
    function setCreatorTokenCtr(address _creatorTokenCtr) public onlyOwner {
        creatorTokenCtr = _creatorTokenCtr;
    }

    /// @notice add/remove address from the whitelist
    /// @param grantPower address to update permission
    /// @param toggle to give mint and burn permission
    function togglewhitelisted(address grantPower, bool toggle) external onlyOwner {
        whitelisted[grantPower] = toggle;
    }

    /*//////////////////////////////////////////////////////////////////////
                            WHITELISTED ACTIONS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice allows the whitelisted address to mint tokens
    /// @dev reverts when id is invalid
    /// @param to mint to address
    /// @param id mint id
    /// @param amount mint amount
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        if (!whitelisted[msg.sender]) revert NotWhitelisted(msg.sender);
        RewardType reward = checkType(id);
        if (reward == RewardType.CREATOR_TOKEN) {
            mintCreatorToken(to, amount);
        } else {
            _mint(to, id, amount, "");
        }
    }

    /// @notice allows the whitelisted address to burn tokens
    /// @dev reverts when id is invalid
    /// @param from burn from address
    /// @param id burn id
    /// @param amount burn amount
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        if (!whitelisted[msg.sender]) revert NotWhitelisted(msg.sender);
        RewardType reward = checkType(id);
        if (reward == RewardType.CREATOR_TOKEN) {
            burnCreatorToken(from, amount);
        } else {
            _burn(from, id, amount);
        }
    }

    /// @notice mints creator tokens
    /// @dev must be whitelisted by the CreatorToken
    /// @param to mint to address
    /// @param amount mint amount
    function mintCreatorToken(address to, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).mint(to, amount);
    }

    /// @notice burns creator tokens
    /// @dev must be whitelisted by the CreatorToken
    /// reverts when a user does NOT own sufficient amount of tokens
    /// @param from user address to burn from
    /// @param amount amount to burn
    function burnCreatorToken(address from, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    UTILS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice checks a reward type by id
    function checkType(uint256 id) public pure returns (RewardType) {
        if (id == CREATOR_TOKEN_ID) {
            return RewardType.CREATOR_TOKEN;
        } else if (id >= PREMIUM_PASS_STARTING_ID && id < CREATOR_TOKEN_ID) {
            return RewardType.PREMIUM_PASS;
        } else if (id >= LOOTBOX_STARTING_ID && id < REDEEMABLE_STARTING_ID) {
            return RewardType.LOOTBOX;
        } else if (id >= REDEEMABLE_STARTING_ID && id < SPECIAL_STARTING_ID) {
            return RewardType.REDEEMABLE;
        } else if (id >= SPECIAL_STARTING_ID && id < INVALID_STARTING_ID) {
            return RewardType.SPECIAL;
        } else {
            revert InvalidId(id);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI
    //////////////////////////////////////////////////////////////*/

    /// @dev uri with the format ipfs://
    string public tokenURI;

    /// @notice returns uri by id
    /// @return string with the format ipfs://<uri>/id.json
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    /// @notice sets the uri
    /// @dev only owner can call it
    /// @param _uri new string with the format ipfs://<uri>/
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /*//////////////////////////////////////////////////////////////
                            LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /// @dev lootboxId increments when a new lootbox is created
    uint256 public lootboxId = LOOTBOX_STARTING_ID;

    /// @dev lootboxId->[all LootboxOptions]
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /**
     * @notice creates a new lootbox
     * @dev reverts when:
     *      joint rarity of all LootboxOptions does not add up to 100
     *      ids.length != qtys.length
     *      ids are invalid
     * @param options all the LootboxOptions avaliable in a lootbox
     * @return new lootboxId
     */
    function newLootbox(LootboxOption[] memory options) external onlyOwner returns (uint256) {
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < options.length; x++) {
            if (options[x].ids.length != options[x].qtys.length) revert IncorrectLootboxOptions();
            for (uint256 y; y < options[x].ids.length; y++) {
                checkType(options[x].ids[y]);
            }
            cumulativeProbability += options[x].rarityRange[1] - options[x].rarityRange[0];
            lootboxRewards[lootboxId].push(options[x]);
        }
        if (cumulativeProbability != 100) revert IncorrectLootboxOptions();
        lootboxId++;
        return lootboxId;
    }

    /// @notice opens a lootbox for a user
    /// @dev only owner can call it and user must own lootbox before
    /// reverts when id is not a lootbox
    /// @param id lootboxId to open
    /// @param user mint lootboxOption rewards to user address
    function openLootbox(uint256 id, address user) public onlyOwner {
        RewardType reward = checkType(id);
        if (reward != RewardType.LOOTBOX) revert InvalidId(id);
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        for (uint256 x; x < option.ids.length; x++) {
            mint(user, option.ids[x], option.qtys[x]);
        }
        emit LootboxOpened(id, idx, user);
    }

    /// @notice calculates a pseudorandom index between 0-99
    /// @dev vulnerable to timing attacks
    function calculateRandom(uint256 id) public view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.timestamp, block.number, blockhash(block.number), block.difficulty)
            )
        ) % 100;
        LootboxOption[] memory options = lootboxRewards[id];
        for (uint256 x; x < options.length; x++) {
            // rarityRange[0] is inclusive and rarityRange[1] is exclusive
            if (random >= options[x].rarityRange[0] && random < options[x].rarityRange[1]) {
                return x;
            }
        }
        revert LOLHowDidYouGetHere(id);
    }

    /// @notice gets a lootboxOption by lootboxId and index
    function getLootboxOptionByIdx(uint256 id, uint256 idx) public view returns (LootboxOption memory option) {
        return lootboxRewards[id][idx];
    }

    /// @notice gets a lootboxOptions length by lootboxId
    function getLootboxOptionsLength(uint256 id) public view returns (uint256) {
        return lootboxRewards[id].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICreatorToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}