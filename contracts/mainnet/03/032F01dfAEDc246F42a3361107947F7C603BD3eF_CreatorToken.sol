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
import "lib/solmate/src/auth/Owned.sol";
import "lib/solmate/src/tokens/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/// @dev type of reward that can be given out
/// DO NOT CHANGE ORDERING, web3 service depends on this
enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

/// @dev status of a redeemable item
enum RedeemStatus {
    REDEEMED,
    PROCESSING,
    REJECTED
}

/// @dev data stored when an item is redeemed
struct Redemption {
    uint256 itemId;
    RedeemStatus status;
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
                        REDEEMABLE ITEMS
    //////////////////////////////////////////////////////////////*/

    /// @dev redeemed entries for a given address
    /// ticketId->Redemption
    mapping(bytes32 => Redemption) public redeemed;

    /// @notice redeeem a redeemable item
    /// @dev id must be within approved range of redeeemable items
    /// @param ticketId ticketId sent by ticketing service
    /// @param user address that wants to redeem the item
    /// @param id id of reward to redeem
    function redeemReward(
        bytes32 ticketId,
        address user,
        uint256 id
    ) external onlyOwner {
        RewardType reward = checkType(id);
        if (reward != RewardType.REDEEMABLE) revert InvalidId(id);
        redeemed[ticketId] = Redemption(id, RedeemStatus.PROCESSING);
        _burn(user, id, 1);
    }

    /// @notice update redemption status of ticketId
    /// @dev revert if ticket id does not exist
    /// @param ticketId ticketId sent by ticketing service
    /// @param status new status
    function updateStatus(bytes32 ticketId, RedeemStatus status) external onlyOwner {
        Redemption storage redeemedByUser = redeemed[ticketId];
        if (redeemedByUser.itemId == 0) revert TicketIdDoesNotExist(ticketId);
        redeemedByUser.status = status;
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
        uint256 cumulativeProbability = 0;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./EternalGlory.sol";
import "./DPDSkins.sol";
import "./AssetStats.sol";
import "../../battle-pass/IRewards.sol";
import {InvalidId} from "../../battle-pass/Rewards.sol";

/// @dev track info on asset placed on a grid location
/// health determines if slot is empty or not
struct Asset {
    address owner;
    uint256 health;
    uint256 id;
}

/**
 * @title MTX Game
 * @notice logic and state for the MTX Game
 * @author rayquaza7
 */
contract Engine is EternalGlory, Owned {
    /// @dev emitted when asset dies
    event AssetDead(uint256 indexed _x, uint256 indexed _y);
    /// @dev emitted when asset inflicts damage
    event UpdateHealth(uint256 indexed _x, uint256 indexed _y, uint256 _xDamaged, uint256 _yDamaged);
    /// @dev emitted when game's over; winner is true if the defenders won
    event GameOver(bool indexed winner);
    /// @dev emiited when an attacker moves
    event AttackerMove(uint256 _x, uint256 _y, uint256 newX, uint256 newY);

    /// @dev grid size of the board
    uint256 public constant X = 14;
    uint256 public constant Y = 14;
    /// @dev castle is put in the middle
    uint256 public constant CASTLE_X = (X + 1) / 2;
    uint256 public constant CASTLE_Y = (Y + 1) / 2;

    uint256 public constant DEFENDER_STARTING_ID = 20_100;
    uint256 public constant CASTLE_ID = 20_100;
    uint256 public constant TURRET_ID = 20_101;
    uint256 public constant WALL_ID = 20_102;
    uint256 public constant GENERATOR_ID = 20_103;

    uint256 public constant ATTACKER_STARTING_ID = 20_200;
    uint256 public constant BOMBER_ID = 20_200;
    uint256 public constant RANGED_ID = 20_201;
    uint256 public constant MELEE_ID = 20_202;
    uint256 public constant EXPLOSIVE_ID = 20_203;

    /// @dev uses for actions that can only be undertaken when game is either ongoing or stoppped
    /// @param _start true if need game to have already started, false otherwise
    modifier gameStatus(bool _start) {
        require(_start == start, "Cannot perform action in this game state");
        _;
    }

    /// @dev add castle in the middle
    /// @param uri SBT uri
    constructor(string memory uri) EternalGlory(uri) Owned(msg.sender) {
        asset[CASTLE_X][CASTLE_Y] = Asset(address(this), CASTLE_HEALTH, CASTLE_ID);
    }

    /*//////////////////////////////////////////////////////////////////////
                                ADMIN 
    //////////////////////////////////////////////////////////////////////*/

    /// @dev battle pass address associated with this board
    address public battlePass;
    /// @dev true if game has started
    bool public start;

    /// @notice toggle game start/stop
    /// @dev only admin can toggle game
    /// @param toggle set to true to start game, false otherwise
    function toggleGame(bool toggle) external onlyOwner {
        start = toggle;
    }

    /// @notice set pass address
    function setPass(address _battlePass) external onlyOwner gameStatus(false) {
        battlePass = _battlePass;
    }

    /*//////////////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////////////*/

    /**
     * @notice check if a given asset is a defense unit or an attacking unit
     * @param assetId asset id of asset to check
     * @return true if defender, false if attacker
     */
    function checkType(uint256 assetId) public pure returns (bool) {
        if (assetId >= DEFENDER_STARTING_ID && assetId < ATTACKER_STARTING_ID) {
            return true;
        } else if (assetId >= ATTACKER_STARTING_ID) {
            return false;
        } else {
            revert InvalidId(assetId);
        }
    }

    /**
     * @notice check if a given asset can be placed at _x,_y acc to rules
     * @dev attacking units can only be placed at the boundary of the grid
     * similarly defender units cannot be placed at the boundary
     * revert if rules are not followed
     * @param _x x coordinate to place it in
     * @param _y y coordinate to place it in
     * @param isDefender true if defender is being placed
     */
    function checkPlaceConditions(
        uint256 _x,
        uint256 _y,
        bool isDefender
    ) public view {
        require(asset[_x][_y].health == 0, "space occupied");
        bool onBoundary = _x == 0 || _y == 0 || _x == X || _y == Y;
        if (isDefender) {
            require(!onBoundary, "invalid defender location");
        } else {
            require(onBoundary, "invalid attacker location");
        }
    }

    /**
     * @notice return health for asset id
     * @dev revert if id is invalid
     * @param assetId asset id of asset to check
     * @return health of asset
     */
    function getHealthForAsset(uint256 assetId) public pure returns (uint256 health) {
        if (assetId == TURRET_ID) {
            health = TURRET_HEALTH;
        } else if (assetId == BOMBER_ID) {
            health = BOMBER_HEALTH;
        } else if (assetId == GENERATOR_ID) {
            health = GENERATOR_HEALTH;
        } else if (assetId == WALL_ID) {
            health = WALL_HEALTH;
        } else if (assetId == MELEE_ID) {
            health = MELEE_HEALTH;
        } else if (assetId == RANGED_ID) {
            health = RANGED_HEALTH;
        } else if (assetId == EXPLOSIVE_ID) {
            health = EXPLOSIVE_HEALTH;
        } else {
            revert InvalidId(assetId);
        }
    }

    /// @notice adjust x y coordinates according to board size and its range
    function adjustInRange(
        uint256 _x,
        uint256 _y,
        uint256 range
    ) public pure returns (uint256 xRange, uint256 yRange) {
        xRange = _x + range;
        if (xRange > X) xRange = X;
        yRange = _y + range;
        if (yRange > Y) yRange = Y;
    }

    /**
     * @notice check if there is a generator around _x,_y
     * @dev adjust for board size
     * @return yes true if there is a generator
     */
    function isGeneratorAround(uint256 _x, uint256 _y) public view returns (bool yes) {
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, GENERATOR_RANGE);

        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                Asset memory _asset = asset[a][b];
                if (_asset.id == GENERATOR_ID) yes = true;
            }
        }
    }

    /**
     * @notice find first enemy within range for asset at _x,_y
     * @dev skip empty slots, find attackers for defenders and vice versa
     * adjust for board size
     * @param _x x coordinate of asset
     * @param _y y coordinate of asset
     * @param range range of asset
     * @param isDefender true if defender
     * @return _xEnemy x coordinate of enemy
     * @return _yEnemy y coordinate of enemy
     * @return exists true if exists, if we didnt have this then
     * since the default value of uint is 0, the coordinates would have been
     * 0,0 which is a valid location on the board
     */
    function find(
        uint256 _x,
        uint256 _y,
        uint256 range,
        bool isDefender
    )
        public
        view
        returns (
            uint256 _xEnemy,
            uint256 _yEnemy,
            bool exists
        )
    {
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, range);

        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                Asset memory _asset = asset[a][b];
                if (!(isDefender && checkType(_asset.id))) {
                    _xEnemy = a;
                    _yEnemy = b;
                    exists = true;
                    break;
                }
            }
        }
    }

    /**
     * @notice find all enemies within range for asset at _x,_y
     * @dev skip empty slots, find attackers for defenders and vice versa
     * adjust for board size
     * @param _x x coordinate of asset
     * @param _y y coordinate of asset
     * @param range range of asset
     * @param isDefender true if defender
     * @return _xEnemy x coordinate of enemies
     * @return _yEnemy y coordinate of enemies
     * @return exists true if exists, if we didnt have this then
     * since the default value of uint is 0, the coordinates would have been
     * 0,0 which is a valid location on the board
     */
    function findAll(
        uint256 _x,
        uint256 _y,
        uint256 range,
        bool isDefender
    )
        public
        view
        returns (
            uint256[] memory _xEnemy,
            uint256[] memory _yEnemy,
            bool exists
        )
    {
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, range);
        // max added elemets will always be xRange * yRange -1 since this asset
        // wont be added to it.
        _xEnemy = new uint256[](xRange * yRange);
        _yEnemy = new uint256[](xRange * yRange);
        uint256 count;
        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                Asset memory _asset = asset[a][b];
                if (!(isDefender && checkType(_asset.id))) {
                    _xEnemy[count] = a;
                    _yEnemy[count] = b;
                    exists = true;
                    count++;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                                PLACE/UNPLACE
    //////////////////////////////////////////////////////////////////////*/

    /// @dev x->y->Asset info
    mapping(uint256 => mapping(uint256 => Asset)) public asset;
    /// @dev updated when attackers are added or they die
    uint256 public numberOfAttackers;

    /**
     * @notice place asset at _x,_y
     * @dev has to abide by game rules and owner needs to own id
     * update number of attackers if an attacker is being placed
     * @param _x x coordinate to place it in
     * @param _y y coordinate to place it in
     * @param owner address that owns the asset
     * @param id id of the asset to place
     */
    function place(
        uint256 _x,
        uint256 _y,
        address owner,
        uint256 id
    ) external gameStatus(false) onlyOwner {
        bool isDefender = checkType(id);
        if (!isDefender) numberOfAttackers++;
        IRewards(battlePass).burn(owner, id, 1);
        checkPlaceConditions(_x, _y, isDefender);
        uint256 health = getHealthForAsset(id);
        asset[_x][_y] = Asset(owner, health, id);
    }

    /**
     * @notice unplace asset at _x,_y
     * @dev owner must own the asset at _x,_y
     * decrease number of attackers
     * @param _x x coordinate to place it in
     * @param _y y coordinate to place it in
     * @param owner address that owns the asset
     */
    function unplace(
        uint256 _x,
        uint256 _y,
        address owner
    ) external gameStatus(false) {
        Asset memory _asset = asset[_x][_y];
        bool isDefender = checkType(_asset.id);
        if (!isDefender) numberOfAttackers--;
        IRewards(battlePass).mint(owner, _asset.health, 1);
        delete asset[_x][_y];
    }

    /*//////////////////////////////////////////////////////////////////////
                                FUN
    //////////////////////////////////////////////////////////////////////*/

    /// @dev number of times the action function has been called
    uint256 public ticks;

    /**
     * @notice keeper will call this function for all _x,_y on board
     * @dev checks if unit has health > 0, if yes that means its dead or empty
     * call action function for corresponding asset at that location;
     * all action functions then call the update function
     * add ticks
     * castle does not defend itself
     * for defender actions, a generator must be around
     */
    function action(uint256 _x, uint256 _y) external gameStatus(true) {
        Asset memory _asset = asset[_x][_y];
        uint256 assetId = _asset.id;
        bool isDefender = checkType(assetId);

        if (_asset.health == 0) return;
        uint256 range;
        uint256 damage;
        if (isDefender && isGeneratorAround(_x, _y)) {
            if (assetId == TURRET_ID) {
                range = TURRET_RANGE;
                damage = TURRET_DAMAGE;
            } else if (assetId == BOMBER_ID) {
                if (ticks % BOMBER_FIRE_TICKS == 0) {
                    defendBomber(_x, _y);
                }
                ticks++;
                return;
            }
        } else {
            if (assetId == EXPLOSIVE_ID) {
                if (ticks % EXPLOSIVE_FIRE_TICKS == 0) {
                    range = EXPLOSIVE_RANGE;
                    damage = EXPLOSIVE_DAMAGE;
                }
            } else if (assetId == RANGED_ID) {
                range = RANGED_RANGE;
                damage = RANGED_DAMAGE;
            } else if (assetId == MELEE_ID) {
                range = MELEE_RANGE;
                damage = MELEE_DAMAGE;
            }
        }
        (uint256 _xEnemy, uint256 _yEnemy, bool exists) = find(_x, _y, TURRET_RANGE, isDefender);
        if (exists) {
            update(_xEnemy, _yEnemy, TURRET_DAMAGE, _x, _y);
        }
        ticks++;
    }

    /// @dev execute bomber's defense action
    function defendBomber(uint256 _x, uint256 _y) private {
        (uint256[] memory _xEnemies, uint256[] memory _yEnemies, bool enemiesExist) = findAll(
            _x,
            _y,
            BOMBER_RANGE,
            true
        );
        if (enemiesExist) {
            for (uint256 z; z < _xEnemies.length; z++) {
                update(_xEnemies[z], _yEnemies[z], BOMBER_DAMAGE, _x, _y);
            }
        }
        return;
    }

    /**
     * @dev update health of asset at _xDamaged,_yDamaged
     * assume find function filters out empty slots and there is an alive asset at these coordinates
     * if health is being set to 0, then delete that asset; emit AssetDead event
     * emit UpdatHealth event with new health
     * if an attacker is dead then update number of attackers on the board
     * @param _xDamaged x coordinate of asset thats damaged
     * @param _yDamaged y coordinate of asset thats damaged
     * @param damage amount to subtract from _xDamaged,_yDamaged's health
     * @param _x x coordinate of asset inflicting damage
     * @param _y y coordinate of asset inflicting damage
     */
    function update(
        uint256 _xDamaged,
        uint256 _yDamaged,
        uint256 damage,
        uint256 _x,
        uint256 _y
    ) private {
        Asset storage _asset = asset[_xDamaged][_yDamaged];
        if (_asset.health > damage) {
            _asset.health -= damage;
            emit UpdateHealth(_x, _y, _xDamaged, _yDamaged);
        } else {
            bool isDefender = checkType(_asset.id);
            if (!isDefender) numberOfAttackers--;
            delete asset[_xDamaged][_yDamaged];
            emit AssetDead(_xDamaged, _yDamaged);
        }
    }

    /**
     * @notice check if game is over or not
     * @dev require game to be onmgoing
     * we dont want to calculate number of alive attackers by looping so we maintain another variable
     * game is over if castle health == 0 or number of attackers == 0
     * if game is over then terminate game
     * emit GameOver event
     * give SBT of win/lose
     * @return over true if over false otherwise
     */
    function isGameOver() public onlyOwner returns (bool over) {
        Asset memory _asset = asset[CASTLE_X][CASTLE_Y];
        if (_asset.health == 0) {
            over = true;
            start = false;
            mintSBT(false);
            emit GameOver(false);
        } else if (numberOfAttackers == 0) {
            over = true;
            start = false;
            mintSBT(true);
            emit GameOver(true);
        } else {}
    }

    /**
     * @notice move attackers, called for every unit in grid once action and check for isGameOver is made
     * @dev
     * return if health of unit == 0 or is a defender
     * check if there are any defences in range; if yes then dont move
     * if not then move towards the castle making sure that u dont go where another attacker already is
     * will revert if game ended
     * @param _x x coordinate
     * @param _y y coordinate
     */
    function move(uint256 _x, uint256 _y) external gameStatus(true) {
        Asset memory _asset = asset[_x][_y];
        bool defenderExists;
        if (_asset.health == 0 || checkType(_asset.id)) return;
        if (_asset.id == MELEE_ID && ticks % MELEE_MOVE_TICKS == 0) {
            (, , defenderExists) = find(_x, _y, MELEE_RANGE, false);
        } else if (_asset.id == RANGED_ID && ticks % RANGED_MOVE_TICKS == 0) {
            (, , defenderExists) = find(_x, _y, RANGED_RANGE, false);
        } else if (_asset.id == EXPLOSIVE_ID) {
            (, , defenderExists) = find(_x, _y, EXPLOSIVE_RANGE, false);
        }
        if (defenderExists) return;

        uint256 newX = _x;
        uint256 newY = _y;
        // each attacker can only move once per tick
        (uint256 xRange, uint256 yRange) = adjustInRange(_x, _y, 1);
        uint256 xDistance = (_x << 2) + (CASTLE_X << 2) - (2 * _x * CASTLE_X);
        uint256 yDistance = (_y << 2) + (Y << 2) - (2 * _y * Y);
        uint256 distance = sqrt(xDistance + yDistance);

        //if there is someone else in moving range skip that location
        //if distnace to centre from a point is more than the current distance, skip that
        //if distance is less then move there
        for (uint256 a = _x; a <= xRange; a++) {
            for (uint256 b = _y; b <= yRange; b++) {
                //save computation
                if (a == _x && b == _y) continue;
                // dont go there if there is an attacker there already
                if (asset[a][b].health != 0) continue;
                uint256 dist = sqrt(
                    (a << 2) + (CASTLE_X << 2) - (2 * a * CASTLE_X) + (b << 2) + (Y << 2) - (2 * b * Y)
                );
                if (dist < distance) {
                    newX = a;
                    newY = b;
                    distance = dist;
                }
            }
        }
        asset[newX][newY] = _asset;
        delete asset[_x][_y];
        emit AttackerMove(_x, _y, newX, newY);
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     * copied from OZ since I dont wanna use an  entire lib to use 1 function
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/solmate/src/tokens/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

uint256 constant SBT_WIN_ID = 1;
uint256 constant SBT_LOSE_ID = 2;

/// @title ETERNAL GLORY OR SHAME
/// @notice Soul Bound token for when a community loses or wins a game
/// @dev no transfer or burn function good luck
abstract contract EternalGlory is ERC1155 {
    constructor(string memory _uri) {
        tokenURI = _uri;
    }

    /// @notice give this communnity's game a SBT if they win or lose a game
    /// @param win true if won the game, false otherwise
    function mintSBT(bool win) internal {
        if (win) {
            _mint(address(this), SBT_WIN_ID, 1, "");
        } else {
            _mint(address(this), SBT_LOSE_ID, 1, "");
        }
    }

    string public tokenURI;

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public override {
        return;
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public override {
        return;
    }

    function setApprovalForAll(address, bool) public override {
        return;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/solmate/src/auth/Owned.sol";

/// @title DPDRepository
/// @notice The Decentralized Programmable Data (DPD) Repository stores data content identifiers, versions, authorized owners, and upgraders.
/// @dev edited to meet Pathfinder's requirements
/// each asset is a DPD, the communnity decides what their in game assets looks like
/// @author David Lucid <[email protected]>
abstract contract DPDSkins is Owned {
    /// @dev asset id->dpd data
    mapping(uint256 => bytes) public dpds;

    constructor() Owned(msg.sender) {}

    /// @notice Function to add/update a new DPD.
    /// @param assetId asset id
    /// @param cid DPD CID (content identifier).
    function updateDpd(uint256 assetId, bytes calldata cid) external onlyOwner {
        require(owner == msg.sender, "NO");
        dpds[assetId] = cid;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

uint256 constant BOMBER_HEALTH = 4;
uint256 constant BOMBER_DAMAGE = 3;
uint256 constant BOMBER_RANGE = 2;
//can only fire once every 3 ticks
uint256 constant BOMBER_FIRE_TICKS = 3;

uint256 constant CASTLE_HEALTH = 10;

///@dev special: all other defences need a generator within 2 blocks of it or else they cannot defend
uint256 constant GENERATOR_HEALTH = 5;
uint256 constant GENERATOR_RANGE = 2;

uint256 constant TURRET_HEALTH = 5;
uint256 constant TURRET_DAMAGE = 1;
uint256 constant TURRET_RANGE = 2;

uint256 constant WALL_HEALTH = 10;

uint256 constant RANGED_HEALTH = 3;
uint256 constant RANGED_DAMAGE = 1;
uint256 constant RANGED_RANGE = 2;
uint256 constant RANGED_MOVE_TICKS = 3;

uint256 constant MELEE_HEALTH = 10;
uint256 constant MELEE_DAMAGE = 2;
uint256 constant MELEE_RANGE = 1;
//1 move per tick
uint256 constant MELEE_MOVE_TICKS = 2;

uint256 constant EXPLOSIVE_HEALTH = 5;
uint256 constant EXPLOSIVE_DAMAGE = 5;
uint256 constant EXPLOSIVE_RANGE = 1;
uint256 constant EXPLOSIVE_MOVE_TICKS = 1;
uint256 constant EXPLOSIVE_FIRE_TICKS = 3;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IRewards {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./battle-pass/IRewards.sol";
import "lib/solmate/src/auth/Owned.sol";

/// @dev used when trying to craft a recipe thats not active
error RecipeNotActive(uint256 recipeId, address user);
/// @dev used when trying to create recipe with incorrect details
error IncorrectRecipeDetails();

/**
 * @dev ingredients for a recipe
 * tokens: list of addresses to add
 * ids: list of ids
 * qtys: list of qtys
 */
struct Ingredients {
    address[] tokens;
    uint256[] ids;
    uint256[] qtys;
}

/// @notice Allows a user to burn owned pre defined tokens for new ones
/// @author rayquaza7
contract Crafting is Owned {
    /// @dev emitted when new recipe is created
    event NewRecipe(uint256 indexed recipeId, uint256 indexed creatorId);
    /// @dev emitted when item is crafted
    event Crafted(uint256 indexed recipeId, address indexed user);

    /// @dev current number of recipes created
    uint256 public recipeId;
    /// @dev creatorId->list of recipes
    mapping(uint256 => uint256[]) public creatorRecipes;
    /// @dev recipe id->input ingredients
    mapping(uint256 => Ingredients) internal inputIngredients;
    /// @dev recipe id->output ingredients
    mapping(uint256 => Ingredients) internal outputIngredients;
    /// @dev recipe id->active
    mapping(uint256 => bool) public isActive;

    constructor() Owned(msg.sender) {}

    /**
     * @notice create a new recipe
     * @dev assumes that the ids you are adding are valid based on the spec in BattlePass.sol
     * will revert if length of ids is not equal to length of ids and tokens
     * assume that all ids are valid
     * @param input ingredients
     * @param output ingredients
     * @param creatorId creator the recipe belongs to
     * @return recipe id
     */
    function addRecipe(
        Ingredients calldata input,
        Ingredients calldata output,
        uint256 creatorId
    ) external onlyOwner returns (uint256) {
        if (
            input.tokens.length != input.ids.length ||
            input.ids.length != input.qtys.length ||
            output.tokens.length != output.ids.length ||
            output.ids.length != output.qtys.length
        ) {
            revert IncorrectRecipeDetails();
        }

        unchecked {
            recipeId++;
        }
        creatorRecipes[creatorId].push(recipeId);
        inputIngredients[recipeId] = input;
        outputIngredients[recipeId] = output;
        isActive[recipeId] = true;
        emit NewRecipe(recipeId, creatorId);
        return recipeId;
    }

    /**
     * @notice craft new items based on given recipe id
     * @dev revert if user does not own input items
     * revert if recipe is not active
     * @param _recipeId given recipe id
     * @param user address of user
     */
    function craft(uint256 _recipeId, address user) external onlyOwner {
        if (!isActive[_recipeId]) revert RecipeNotActive(_recipeId, user);

        Ingredients memory input = inputIngredients[_recipeId];
        Ingredients memory output = outputIngredients[_recipeId];
        for (uint256 x; x < input.tokens.length; x++) {
            IRewards(input.tokens[x]).burn(user, input.ids[x], input.qtys[x]);
        }
        for (uint256 x; x < output.tokens.length; x++) {
            IRewards(output.tokens[x]).mint(user, output.ids[x], output.qtys[x]);
        }
        emit Crafted(_recipeId, user);
    }

    /// @notice toggle recipe on or off
    function toggleRecipe(uint256 _recipeId, bool toggle) public onlyOwner {
        isActive[_recipeId] = toggle;
    }

    /// @notice get input ingredients for a recipe id
    function getInputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return inputIngredients[_recipeId];
    }

    /// @notice get output ingredients for a recipe id
    function getOutputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return outputIngredients[_recipeId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/solmate/src/auth/Owned.sol";
import "lib/solmate/src/utils/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract SoupcansNFT is ERC721, Owned, ReentrancyGuard {
    /// @dev of the form ipfs://wefewewr/
    string public baseTokenURI;
    /// @dev true id mint has started
    bool public mintStart;
    /// @dev mint price
    /// @dev in wei
    uint256 public price;
    /// @dev mint id
    uint256 public mintId;
    /// @dev reserved for private auction
    uint256 public constant RESERVED_PRIVATE = 5;
    /// @dev total supply
    uint256 public constant TOTAL_SUPPLY = 1000;

    constructor(string memory _baseTokenURI) ERC721("NAME", "SYMBOL") Owned(msg.sender) {
        baseTokenURI = _baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////////////*/

    /// @notice set uri for this contract
    /// @dev only owner can call it
    /// @param _baseTokenURI new ipfs hash
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice start/stop mint
    function toggleMint(bool toggle) external onlyOwner {
        mintStart = toggle;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /// @notice mint first 5 for private auction
    function mintForAuction() public onlyOwner {
        if (mintId <= RESERVED_PRIVATE) {
            mintId++;
            _mint(msg.sender, mintId);
        }
    }

    /// @notice withdraw eth
    /// @dev only owner can call it
    function withdraw(address payable to) public onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "TRY DIFFERENT ADDRESS");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return string.concat(baseTokenURI, Strings.toString(tokenId), ".json");
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINT
    //////////////////////////////////////////////////////////////////////*/

    /// @notice mint called by msg.sender
    /// @dev mint must have started
    function mint() public payable nonReentrant {
        require(mintStart, "MINT HAS NOT STARTED");
        require(msg.value >= price, "MINT PRICE MORE THAN ETH SENT");
        require(mintId < TOTAL_SUPPLY, "SOLD OUT");
        mintId++;
        _mint(msg.sender, mintId);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/solmate/src/auth/Owned.sol";
import "lib/solmate/src/tokens/ERC20.sol";

/// @dev used when delagator tries to delegate more than they have or undelegate more than they delegated
error InsufficientBalance(address delegator, uint256 owned, uint256 delegatedAmount);

/// @notice contract for erc20 token specific to the creator with delegation
contract CreatorToken is ERC20, Owned {
    /// @dev addresses that can mint/burn tokens
    /// @dev Pass contract for the creator and msg.sender will be whitelisted
    mapping(address => bool) public whitelist;

    /// @dev delegator->delegatee->amount; track who delegates to whom and how much
    mapping(address => mapping(address => uint256)) public delegatedBy;
    /// @dev track total delegated to an address
    mapping(address => uint256) public delegatedTotal;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address pass
    ) ERC20(_name, _symbol, _decimals) Owned(msg.sender) {
        whitelist[pass] = true;
        whitelist[msg.sender] = true;
    }

    /// @notice toggle true/false addy in whitelist
    function toggleWhitelist(address addy, bool toggle) public onlyOwner {
        whitelist[addy] = toggle;
    }

    /// @notice delegate tokens to delegatee
    /// @param delegator the address delegating tokens
    /// @param delegatee the address tokens are being delegated to
    /// @param amount the amount of tokens to delegate
    function delegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyOwner {
        uint256 owned = balanceOf[delegator];
        if (owned < amount) revert InsufficientBalance(delegator, owned, amount);
        balanceOf[delegator] -= amount;
        delegatedBy[delegator][delegatee] += amount;
        delegatedTotal[delegatee] += amount;
    }

    /// @notice undeledelegate tokens from delegatee
    /// @param delegator the address that delegated tokens
    /// @param delegatee the address tokens were delegated to
    /// @param amount the amount of tokens to undelegate
    function undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) public onlyOwner {
        uint256 amountDelegated = delegatedBy[delegator][delegatee];
        if (amountDelegated < amount) revert InsufficientBalance(delegator, amountDelegated, amount);
        balanceOf[delegator] += amount;
        delegatedBy[delegator][delegatee] -= amount;
        delegatedTotal[delegator] -= amount;
    }

    /// @notice enable mint access
    function mint(address to, uint256 amount) public {
        require(whitelist[msg.sender], "NOT ALLOWED");
        _mint(to, amount);
    }

    /// @notice enable burn access
    function burn(address from, uint256 amount) public {
        require(whitelist[msg.sender], "NOT ALLOWED");
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}