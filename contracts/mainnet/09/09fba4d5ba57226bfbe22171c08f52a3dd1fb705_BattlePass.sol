// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Rewards.sol";

/** @dev Info stored each level
 * if you want to give out multiple rewards at a level then have the id correspond to a lootbox
 * xpToCompleteLevel: xp required to go from level x->x+1;
 * if info is for the last level then xpToCompleteLevel must be 0
 * freeRewardId: free reward id to give at level x
 * premiumRewardId: premium reward id to give at level x
 */
struct LevelInfo {
    uint256 xpToCompleteLevel;
    uint256 freeRewardId;
    uint256 freeRewardQty;
    uint256 premiumRewardId;
    uint256 premiumRewardQty;
}

/** @dev Info stored on each user for each season
 * xp: how much xp the user has
 * claimedPremiumPass: true if a user has claimed their first premium pass reward
 * need this because once a user gets a premium pass then
 * they can claim a premium reward after which they should not be able to
 * sell it but still be able to claim other premium rewards
 * claimed: has user claimed reward for given level and prem status
 */
struct User {
    uint256 xp;
    bool claimedPremiumPass;
    mapping(uint256 => mapping(bool => bool)) claimed;
}

/// @dev used when there is an error while creating a new season
error IncorrectSeasonDetails(address admin);
/// @dev used when user is trying to claim a reward for a level at which they are not
error NotAtLevelNeededToClaimReward(uint256 seasonId, address user, uint256 actualLevel, uint256 requiredLevel);
/// @dev used when user does not have premium pass and they are trying to redeem a premum reward
error NeedPremiumPassToClaimPremiumReward(uint256 seasonId, address user);
/// @dev used when reward has already been claimed by a user
error RewardAlreadyClaimed(uint256 seasonId, address user);

/**
 * @title A Battle Pass contract representing a Battle Pass as used in games.
 * @author rayquaza7
 */
contract BattlePass is Rewards {
    /// @dev emitted when a new season is created
    event NewSeason(uint256 indexed seasonId);

    /// @dev current season id
    uint256 public seasonId;

    /// @dev seasonId->level->LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;
    /// @dev user->seasonId->User, store user info for each season
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

    /// @notice give xp to a user upon completion of quests
    /// @dev only owner can give xp
    /// @param _seasonId season id for which xp is to be given
    /// @param xp how much xp to give
    /// @param user user to give xp to
    function giveXp(
        uint256 _seasonId,
        uint256 xp,
        address user
    ) external onlyOwner {
        userInfo[user][_seasonId].xp += xp;
    }

    /// @notice change xp required to complete a level
    /// @dev can set xp after season has been created; only owner can change xp
    /// @param _seasonId season id to change the xp for
    /// @param _level level for which the xp needs to be changed
    /// @param xp the new xp required to complete _level
    function setXp(
        uint256 _seasonId,
        uint256 _level,
        uint256 xp
    ) external onlyOwner {
        seasonInfo[_seasonId][_level].xpToCompleteLevel = xp;
    }

    /**
     * @notice create a new season
     * @dev only owner can call it
     * @param levelInfo info about each level, levelInfo[0] corresponds to info on level 0
     * last level must have xpToCompleteLevel == 0
     * last level is levelInfo.length - 1, since arrays are 0 indexed and levelInfo[0] contains info on 0 level
     * @return current season id
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
     * @notice claim reward upon reaching a new level
     * @dev
     * revert if trying to claim reward for level at which the user is not
     * revert if reward is already claimed
     * revert if trying to redeem premium reward and user is not eligible for it
     * if user has premium pass and it is their first time claiming a premium reward then
     * burn 1 pass from their balance and set claimedPremiumPass to be true. This is done
     * to prevent the user from selling their premium pass after claiming a premium reward.
     * A user can own multiple premium passes just like any other reward.
     * It will NOT be burned if the user has already claimed a premium reward.
     * @param _seasonId for which the reward is to be claimed
     * @param user user address that is claiming the reward
     * @param _level the level for which reward is being claimed
     * @param premium true if premium reward is to be claimed, false otherwise
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
            mint(user, seasonInfo[_seasonId][_level].freeRewardId, seasonInfo[_seasonId][_level].freeRewardQty);
        }
    }

    /// @notice add/update reward for a level and season
    /// @dev only owner can change it
    /// @param _seasonId season id to change the reward for
    /// @param _level level for which the reward needs to be changed
    /// @param premium true if adding/updating premium reward
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

    /// @notice check if the user has a premium pass
    /// @dev a user is not considered premium until they either own one premium pass
    /// or already have claimed a premium reward.
    /// @param user user address
    /// @param _seasonId season id for which the user might have a premium pass
    /// @return true if user has a premium pass, false otherwise
    function isUserPremium(address user, uint256 _seasonId) public view returns (bool) {
        if (userInfo[user][_seasonId].claimedPremiumPass || balanceOf[user][_seasonId] >= 1) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice calculate level of a user for a given season
    /// @param user user address to calculate the level for
    /// @param _seasonId season for which level is to be calculated
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

    /// @notice get max level for a given season id
    /// @dev max level is reached when xpToCompleteLevel == 0
    function getMaxLevel(uint256 _seasonId) public view returns (uint256 maxLevel) {
        uint256 xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        while (xpToCompleteLevel != 0) {
            maxLevel++;
            xpToCompleteLevel = seasonInfo[_seasonId][maxLevel].xpToCompleteLevel;
        }
    }

    /// @notice is reward claimed by user for given season id, level and prem status
    /// @return true if reward has been claimed
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

/// @dev type of reward that can be given out
/// DO NOT CHANGE ORDERING, web3 service depends on this
enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

/**
 *  @dev a lootbox takes in multiple LootboxOptions and rewards one to the user
 * rarityRange of 0-1 means that the user has a 10% chance of getting this
 * the rarity range of all lootboxes must add up to be 1
 * the lower bound is inclusive and the upper bound is exclusive
 * ids correspond to the array of ids to give out for this option
 * give qtys[x] of ids[x]
 * ids.length == qtys.length
 * if any of the ids is CREATOR_TOKEN_ID then call the creator token contract
 */
struct LootboxOption {
    uint256[2] rarityRange;
    uint256[] ids;
    uint256[] qtys;
}

/// @dev used when id is not within any of the approved id ranges or is not appropriate for the item
error InvalidId(uint256 id);
/// @dev used when ticket id does not exist
error TicketIdDoesNotExist(bytes32 ticketId);
/// @dev used when details for a new lootbox are incorrect
error IncorrectLootboxOptions();
/// @dev should never be called
error LOLHowDidYouGetHere(uint256 lootboxId);
/// @dev used when a non whitelisted address tries to mint or burn
error NotWhitelisted(address sender);

/**
 * @title Pass Rewards
 * @author rayquaza7
 * @notice mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items, etc.
 * @dev
 * ERC1155 is used since it allows for both fungible and non fungible tokens
 * crafting contract, owner and the game contract are allowed to mint burn items for a user
 * Premium passes: ids 1-999 reserved for issuing premium passes for new seasons.
 * seasons x needs to mint id x in order to give user a premium pass
 * Creator Token: NOT minted by the Battle Pass, it is minted by the creator token contract
 * however, a Battle Pass is allowed to give creator tokens as a reward.
 * So, the creator token whitelists the pass contract and when you want to give out the tokens
 * you specify id CREATOR_TOKEN_ID so that the contract knows that it has to call the token contract
 * Lootbox: ids 1001-9999 reserved for creating new lootboxes, a battle pass can give out new lootboxes as
 * a reward.
 * Redeemable: ids 10,000-19999 reserved for redeemable items. These are items that require manual intervention
 * by a creator
 * Special: ids 20000-29999 reserved for default items like nfts, game items, one off tokens, etc.
 * Currently defined special items:
 * - ids 20,100-20199 reserved for MTX game defender items
 * - ids 20,200-20299 reserved for MTX game attacker items
 * anything bove 30,000 is considered invalid to prevent mistakes
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

    /// @notice whitelist game, crafting and msg.sender
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

    /// @notice set token contract for creator
    function setCreatorTokenCtr(address _creatorTokenCtr) public onlyOwner {
        creatorTokenCtr = _creatorTokenCtr;
    }

    /// @notice add/remove address from the whitelist
    /// @param grantPower address to update in whitelist
    /// @param toggle true if want the address to have mint/burn priv
    function togglewhitelisted(address grantPower, bool toggle) external onlyOwner {
        whitelisted[grantPower] = toggle;
    }

    /*//////////////////////////////////////////////////////////////////////
                            WHITELISTED ACTIONS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice allow whitelisted address to mint tokens
    /// @dev revert if id is invalid
    /// @param to address to mint to
    /// @param id id to mint
    /// @param amount to mint
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

    /// @notice allow whitelisted address to burn tokens
    /// @dev revert if id is invalid
    /// @param from address to burn from
    /// @param id id to burn
    /// @param amount to burn
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

    /// @dev handle mintiting of tokens here since then the token contract
    /// only needs to whitelist its respective pass contract
    /// @param to user address to mint to
    /// @param amount amount to mint
    function mintCreatorToken(address to, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).mint(to, amount);
    }

    /// @dev handle burning of tokens here since then the token contract
    /// only needs to whitelist its respective pass contract
    /// will revert if user does not own sufficient amount of tokens
    /// @param from user address to burn from
    /// @param amount amount to burn
    function burnCreatorToken(address from, uint256 amount) private {
        ICreatorToken(creatorTokenCtr).burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    UTILS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice check reward type given id
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

    /// @dev uri for this contract
    string public tokenURI;

    /// @notice return uri for an id
    /// @return string in format ipfs://<uri>/id.json
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    /// @notice set uri for this contract
    /// @dev only owner can call it
    /// @param _uri new ipfs hash
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /*//////////////////////////////////////////////////////////////
                            LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /// @dev lootbox id incremented when a new lootbox is created
    uint256 public lootboxId = LOOTBOX_STARTING_ID;

    /// @dev lootbox id-> all options in a lootbox
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /**
     * @notice create a new lootbox
     * @dev
     * will revert if prob ranges dont add upto 10
     * will revert if  if length of ids != length of qtys
     * will rever if invalid ids are passed to be added
     * @param options all the options avaliable in a lootbox
     * @return new lootbox id
     */
    function newLootbox(LootboxOption[] memory options) external onlyOwner returns (uint256) {
        lootboxId++;
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < options.length; x++) {
            if (options[x].ids.length != options[x].qtys.length) revert IncorrectLootboxOptions();
            for (uint256 y; y < options[x].ids.length; y++) {
                checkType(options[x].ids[y]);
            }
            cumulativeProbability += options[x].rarityRange[1] - options[x].rarityRange[0];
            lootboxRewards[lootboxId].push(options[x]);
        }
        if (cumulativeProbability != 10) revert IncorrectLootboxOptions();
        return lootboxId;
    }

    /// @notice open a lootbox for a user
    /// @dev only owner can call it and user must own lootbox before
    /// revert if id trying to open is not a lootbox
    /// @param id id of lootbox trying to open
    /// @param user trying to open a lootbox
    function openLootbox(uint256 id, address user) public onlyOwner {
        RewardType reward = checkType(id);
        if (reward != RewardType.LOOTBOX) revert InvalidId(id);
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        for (uint256 x; x < option.ids.length; x++) {
            mint(user, option.ids[x], option.qtys[x]);
        }
    }

    /// @notice calculate index of a lootbox that a random number falls between
    /// @dev highly unlikely that a miner will want a creator token
    function calculateRandom(uint256 id) public view returns (uint256) {
        // returns a number between 0-9
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.timestamp, block.number, blockhash(block.number), block.difficulty)
            )
        ) % 10;
        LootboxOption[] memory options = lootboxRewards[id];
        for (uint256 x; x < options.length; x++) {
            // lower bound is inclusive but upper isnt
            if (random >= options[x].rarityRange[0] && random < options[x].rarityRange[1]) {
                return x;
            }
        }
        revert LOLHowDidYouGetHere(id);
    }

    /// @notice get lootbox option for a given lootbox and index
    function getLootboxOptionByIdx(uint256 id, uint256 idx) public view returns (LootboxOption memory option) {
        return lootboxRewards[id][idx];
    }

    /// @notice get number of options in a given lootbox id
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