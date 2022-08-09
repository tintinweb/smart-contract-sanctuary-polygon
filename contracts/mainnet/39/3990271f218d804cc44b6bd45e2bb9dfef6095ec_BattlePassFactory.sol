// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BattlePass.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

/// @title BattlePass Factory
/// @dev  adapted from https://github.com/Rari-Capital/vaults/blob/main/src/VaultFactory.sol
/// @notice Factory which enables deploying a BattlePass for any creatorId
contract BattlePassFactory is Owned {
    using Bytes32AddressLib for bytes32;

    address public immutable craftingProxy;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a BattlePass factory.
    constructor(address _craftingProxy) Owned(msg.sender) {
        craftingProxy = _craftingProxy;
    }

    /*///////////////////////////////////////////////////////////////
                        BattlePass DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new BattlePass is deployed.
    /// @param bp The newly deployed BattlePass contract.
    /// @param creatorId The underlying creatorId the new BattlePass accepts.
    event BattlePassDeployed(BattlePass bp, uint256 creatorId);

    /// @notice Deploys a new BattlePass which supports a specific underlying creatorId.
    /// @dev This will revert if a BattlePass that accepts the same underlying creatorId has already been deployed.
    /// @param creatorId The creatorId that the BattlePass should accept.
    /// @return bp The newly deployed BattlePass contract
    function deployBattlePass(uint256 creatorId) external onlyOwner returns (BattlePass bp) {
        bp = new BattlePass{salt: bytes32(creatorId)}(creatorId, craftingProxy);
        emit BattlePassDeployed(bp, creatorId);
    }

    /*///////////////////////////////////////////////////////////////
                        BATTLEPASS LOOKUP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes a BattlePass's address from its accepted underlying creatorId
    /// @param creatorId The creatorId that the BattlePass should accept.
    /// @return The address of a BattlePass which accepts the provided underlying creatorId.
    /// @dev The BattlePass returned may not be deployed yet. Use isBattlePassDeployed to check.
    function getBattlePassFromUnderlying(uint256 creatorId) external view returns (BattlePass) {
        return BattlePass(
            payable(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xFF),
                        address(this),
                        creatorId,
                        keccak256(abi.encodePacked(type(BattlePass).creationCode, abi.encode(creatorId, craftingProxy)))
                    )
                )
                    // Prefix:
                    // Creator:
                    // Salt:
                    // Bytecode hash:
                    // Deployment bytecode:
                    // Constructor arguments:
                    .fromLast20Bytes() // Convert the CREATE2 hash into an address.
            )
        );
    }

    /// @notice Returns if a BattlePass at an address has already been deployed.
    /// @param bp The address of a BattlePass which may not have been deployed yet.
    /// @return A boolean indicating whether the BattlePass has been deployed already.
    /// @dev This function is useful to check the return values of getBattlePassFromUnderlying,
    /// as it does not check that the BattlePass addresses it computes have been deployed yet.
    function isBattlePassDeployed(BattlePass bp) external view returns (bool) {
        return address(bp).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Rewards.sol";

/**
 * @dev stores info for each level
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

/**
 * @dev stores user info
 * xp: user's xp
 * claimedPremiumPass: set to true when the user claims their *first* premium reward
 * user can claim premium rewards when claimedPremiumPass is true or when the user owns a premium pass
 * if a user owns a premium pass and claims their first premium reward,
 * it is burned and claimedPremiumPass is set to true.
 * if the user owns a premium pass and claimedPremiumPass is true, then no premium pass gets burned
 * this is because a user cannot sell the premium pass after redeeming premium rewards
 * claimed: true when reward is claimed at level and status {free or prem}
 */
struct User {
    uint256 xp;
    bool claimedPremiumPass;
    // level->prem?->claimed?
    mapping(uint256 => mapping(bool => bool)) claimed;
}

/// @dev use when an error occurrs while creating a new season
error IncorrectSeasonDetails();

/// @dev use when user claims a reward for a level at which they are NOT
error NotAtLevelNeededToClaimReward();

/// @dev use when user claims a premium reward without owning a premium pass or claimedPremiumPass is false
error NeedPremiumPassToClaimPremiumReward();

/// @dev use when user claims an already claimed reward
error RewardAlreadyClaimed();

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
    /// @dev current active seasonId
    uint256 public seasonId;

    /// @dev seasonId->level->LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;

    /// @dev user->seasonId->User
    mapping(address => mapping(uint256 => User)) public userInfo;

    /// @dev crafting is allowed to mint burn tokens in battle pass
    constructor(uint256 creatorId, address crafting) Rewards(creatorId, crafting) {}

    /// @notice gives xp to a user upon completion of quests
    /// @dev only owner can give xp
    /// @param _seasonId seasonId for which to give xp
    /// @param xp amount of xp to give
    /// @param user user to give xp to
    function giveXp(uint256 _seasonId, uint256 xp, address user) external onlyOwner {
        userInfo[user][_seasonId].xp += xp;
    }

    /// @notice sets required xp to levelup
    /// @param _seasonId seasonId for which to change xp
    /// @param _level level at which to change xp
    /// @param xp new xp required to levelup
    function setXp(uint256 _seasonId, uint256 _level, uint256 xp) external onlyOwner {
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
        if (levelInfo[lastLevel].xpToCompleteLevel != 0) {
            revert IncorrectSeasonDetails();
        }
        for (uint256 x; x <= lastLevel; x++) {
            seasonInfo[seasonId][x].xpToCompleteLevel = levelInfo[x].xpToCompleteLevel;
            if (levelInfo[x].freeRewardId != 0) {
                addReward(seasonId, x, false, levelInfo[x].freeRewardId, levelInfo[x].freeRewardQty);
            }
            if (levelInfo[x].premiumRewardId != 0) {
                addReward(seasonId, x, true, levelInfo[x].premiumRewardId, levelInfo[x].premiumRewardQty);
            }
        }

        return seasonId;
    }

    /// @notice sets a reward for a seasonId and at level
    /// @dev only owner can set rewards
    /// @param _seasonId seasonId for which to change the reward
    /// @param _level level at which to change the reward
    /// @param premium true when setting a premium reward
    /// @param id new reward id
    /// @param qty new reward qty
    function addReward(uint256 _seasonId, uint256 _level, bool premium, uint256 id, uint256 qty) public onlyOwner {
        if (premium) {
            seasonInfo[_seasonId][_level].premiumRewardId = id;
            seasonInfo[_seasonId][_level].premiumRewardQty = qty;
        } else {
            seasonInfo[_seasonId][_level].freeRewardId = id;
            seasonInfo[_seasonId][_level].freeRewardQty = qty;
        }
    }

    /**
     * @notice claims a reward for a seasonId and at level
     * @dev reverts when:
     * user claims a reward for a level at which they are NOT
     * user claims an already claimed reward
     * user claims a premium reward, but is NOT eligible for it
     * when a user has a premium pass and it is their first time claiming a premium reward then
     * burn 1 pass from their balance and set claimedPremiumPass to be true
     * a user can own multiple premium passes just like any other reward
     * it will NOT be burned if the user has already claimed a premium reward
     * @param _seasonId seasonId for which to claim the reward
     * @param _level level at which to claim the reward
     * @param premium true when claiming a premium reward
     */
    function claimReward(uint256 _seasonId, uint256 _level, bool premium) external {
        address user = _msgSender();
        if (level(user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward();
        }

        User storage tempUserInfo = userInfo[user][_seasonId];

        if (tempUserInfo.claimed[_level][premium]) {
            revert RewardAlreadyClaimed();
        }
        tempUserInfo.claimed[_level][premium] = true;

        if (premium) {
            if (seasonInfo[_seasonId][_level].premiumRewardId == 0) {
                return;
            }
            if (isUserPremium(user, _seasonId)) {
                if (!tempUserInfo.claimedPremiumPass) {
                    tempUserInfo.claimedPremiumPass = true;
                    _burn(user, _seasonId, 1);
                }
                _mint(user, seasonInfo[_seasonId][_level].premiumRewardId, seasonInfo[_seasonId][_level].premiumRewardQty, "");
            } else {
                revert NeedPremiumPassToClaimPremiumReward();
            }
        } else {
            if (seasonInfo[_seasonId][_level].freeRewardId == 0) {
                return;
            }
            _mint(user, seasonInfo[_seasonId][_level].freeRewardId, seasonInfo[_seasonId][_level].freeRewardQty, "");
        }
    }

    /*//////////////////////////////////////////////////////////////////////
                            UTILS
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
            if (cumulativeXP > userXp) {
                break;
            }
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
    function isRewardClaimed(address user, uint256 _seasonId, uint256 _level, bool premium) external view returns (bool) {
        return userInfo[user][_seasonId].claimed[_level][premium];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";

/// @dev DO NOT CHANGE ORDERING, web3 service depends on this
enum RewardType {
    PREMIUM_PASS,
    CREATOR_TOKEN,
    LOOTBOX,
    REDEEMABLE,
    SPECIAL
}

/**
 * @dev a lootbox is a collection of LootboxOptions
 * rarity is rarityRange[1] - rarityRange[0]
 * the rarity of all LootboxOptions must add up to 100
 * rarityRange[0] is inclusive and rarityRange[1] is exclusive
 * give qtys[x] of ids[x]  (ids.length == qtys.length)
 */
struct LootboxOption {
    uint256[2] rarityRange;
    uint256[] ids;
    uint256[] qtys;
}

/// @dev used when an id is not within any of the approved id ranges
error InvalidId(uint256 id);

/// @dev used when the details for a new lootbox are incorrect
error IncorrectLootboxOptions();

/// @dev pls dont get here
error LOLHowDidYouGetHere(uint256 lootboxId);

/// @dev used when a non owner/crafting address tries to mint/burn
error NoAccess();

/**
 * @title Rewards given out by a Battle Pass
 * @author rayquaza7
 * @notice Mint creator specific tokens, premium passes, lootboxes, nfts, redeemable items
 * @dev
 * ERC1155 allows for both fungible and non-fungible tokens
 * | Token ID      | Description                                                                             |
 * |---------------|-----------------------------------------------------------------------------------------|
 * | 0             | Empty Reward                                                                            |
 * | 1-999         | Premium Passes (id === season_id); mint id x to give user a premium pass for season x   |
 * | 1000          | Creator's token; CreatorToken handles this token.                                       |
 * | 1,001-9,999   | Lootboxes                                                                               |
 * | 10,000-19,999 | Redeemable Items                                                                        |
 * | 20,000-29,999 | Special NFTs/tokens                                                                     |
 * | >30000        | Invalid, prevents errors                                                                |
 * allows for meta transactions
 */
abstract contract Rewards is ERC1155, Owned, ERC2771Context {
    /// @dev crafting contract address
    address public crafting;
    uint256 public immutable creatorId;
    string public tokenURI;

    uint256 public constant PREMIUM_PASS_STARTING_ID = 1;
    uint256 public constant CREATOR_TOKEN_ID = 1000;
    uint256 public constant LOOTBOX_STARTING_ID = 1001;
    uint256 public constant REDEEMABLE_STARTING_ID = 10000;
    uint256 public constant SPECIAL_STARTING_ID = 20000;
    uint256 public constant INVALID_STARTING_ID = 30000;

    event LootboxOpened(uint256 indexed lootboxId, uint256 indexed idxOpened, address indexed user);

    constructor(uint256 _creatorId, address _crafting) Owned(msg.sender) ERC2771Context(msg.sender) {
        tokenURI = "https://matrix-metadata-server.zeet-matrix.zeet.app";
        creatorId = _creatorId;
        crafting = _crafting;
    }

    /// @notice allows the owner/crafting contract to mint tokens
    /// @param to mint to address
    /// @param id mint id
    /// @param amount mint amount
    function mint(address to, uint256 id, uint256 amount) external {
        if (owner == msg.sender || msg.sender == crafting) {
            _mint(to, id, amount, "");
        } else {
            revert NoAccess();
        }
    }

    /// @notice allows the owner/crafting contract to burn tokens
    /// @param to burn from address
    /// @param id burn id
    /// @param amount burn amount
    function burn(address to, uint256 id, uint256 amount) external {
        if (owner == msg.sender || msg.sender == crafting) {
            _burn(to, id, amount);
        } else {
            revert NoAccess();
        }
    }

    /// @notice sets the uri
    /// @dev only owner can set it
    /// @param _uri new string with the format https://<>/creatorId/id.json
    function setURI(string memory _uri) external onlyOwner {
        tokenURI = _uri;
    }

    /// @notice sets the crafting proxy address
    /// @dev only owner can set it
    /// @param _crafting new address
    function setCrafting(address _crafting) external onlyOwner {
        crafting = _crafting;
    }

    /*//////////////////////////////////////////////////////////////
                            LOOTBOX
    //////////////////////////////////////////////////////////////*/

    /// @dev lootboxId increments when a new lootbox is created
    uint256 public lootboxId = LOOTBOX_STARTING_ID - 1;

    /// @dev lootboxId->[all LootboxOptions]
    mapping(uint256 => LootboxOption[]) internal lootboxRewards;

    /**
     * @notice creates a new lootbox
     * @dev reverts when:
     * joint rarity of all LootboxOptions does not add up to 100
     * ids.length != qtys.length
     * ids are invalid
     * @param options all the LootboxOptions avaliable in a lootbox
     * @return new lootboxId
     */
    function newLootbox(LootboxOption[] memory options) external onlyOwner returns (uint256) {
        lootboxId++;
        uint256 cumulativeProbability;
        for (uint256 x = 0; x < options.length; x++) {
            if (options[x].ids.length != options[x].qtys.length) {
                revert IncorrectLootboxOptions();
            }
            cumulativeProbability += options[x].rarityRange[1] - options[x].rarityRange[0];
            lootboxRewards[lootboxId].push(options[x]);
        }
        if (cumulativeProbability != 100) {
            revert IncorrectLootboxOptions();
        }

        return lootboxId;
    }

    /// @notice opens a lootbox
    /// @dev upto user to not send a bad id here.
    /// @param id lootboxId to open
    function openLootbox(uint256 id) external returns (uint256) {
        address user = _msgSender();
        _burn(user, id, 1);
        uint256 idx = calculateRandom(id);
        LootboxOption memory option = lootboxRewards[id][idx];
        _batchMint(user, option.ids, option.qtys, "");
        emit LootboxOpened(id, idx, user);
        return idx;
    }

    /// @notice calculates a pseudorandom index between 0-99
    function calculateRandom(uint256 id) public view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number), block.difficulty))) % 100;
        LootboxOption[] memory options = lootboxRewards[id];
        for (uint256 x; x < options.length; x++) {
            if (random >= options[x].rarityRange[0] && random < options[x].rarityRange[1]) {
                return x;
            }
        }
        revert LOLHowDidYouGetHere(id);
    }

    /// @notice gets a lootboxOption by lootboxId and index
    function getLootboxOptionByIdx(uint256 id, uint256 idx) external view returns (LootboxOption memory option) {
        return lootboxRewards[id][idx];
    }

    /// @notice gets a lootboxOptions length by lootboxId
    function getLootboxOptionsLength(uint256 id) external view returns (uint256) {
        return lootboxRewards[id].length;
    }

    /*//////////////////////////////////////////////////////////////////////
                            CREATOR TOKEN
    //////////////////////////////////////////////////////////////////////*/

    /// @notice tracks who delegates to whom and how much
    /// @dev delegator->delegatee->amount
    mapping(address => mapping(address => uint256)) public delegatedBy;

    /// @dev tracks the total delegated amount to an address
    mapping(address => uint256) public delegatedTotal;

    /// @dev emit when tokens are delegated
    event Delegated(address indexed delegator, address indexed delegatee, uint256 indexed amount);

    /// @dev emit when tokens are undelegated
    event Undelegated(address indexed delegator, address indexed delegatee, uint256 indexed amount);

    /// @notice delegates msg.sender's tokens to a delegatee
    /// @dev revert if balance is insufficient
    /// @param delegatee the address receiving the delegated tokens
    /// @param amount the amount of tokens to delegate
    function delegate(address delegatee, uint256 amount) external {
        address user = _msgSender();
        balanceOf[user][CREATOR_TOKEN_ID] -= amount;
        delegatedBy[user][delegatee] += amount;
        delegatedTotal[delegatee] += amount;
        emit Delegated(user, delegatee, amount);
    }

    /// @notice undelegates the tokens from a delegatee
    /// @dev revert if msg.sender tries to undelegate more tokens than they delegated
    /// @param delegatee the address who recevied the delegated tokens
    /// @param amount the amount of tokens to undelegate
    function undelegate(address delegatee, uint256 amount) external {
        address user = _msgSender();
        balanceOf[user][CREATOR_TOKEN_ID] += amount;
        delegatedBy[user][delegatee] -= amount;
        delegatedTotal[delegatee] -= amount;
        emit Undelegated(user, delegatee, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    UTILS
    //////////////////////////////////////////////////////////////////////*/

    /// @notice checks a reward type by id; will revert for 0
    function checkType(uint256 id) external pure returns (RewardType) {
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

    /// @notice returns uri by id
    /// @return string with the format ipfs://<uri>/id.json
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(creatorId), "/", Strings.toString(id), ".json");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
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