// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/Interfaces.sol";
import "./SharedLib.sol";

contract Raids is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Boss {
        uint32 hp;
        uint16 pAttack;
        uint16 mAttack;
        uint16 pDefense;
        uint16 mDefense;
        uint256 firstFightId;
        uint256 lastFightId;
        uint256 skullPrice;
    }

    struct Fight {
        uint256 beastRepresentation;
        bytes32 requestId;
        uint16 beastId;
        uint32 bossId;
        uint32 result;
        uint32 rounds;
        bool resolved;
        address wallet;
        uint256 resolveBlock;
    }

    struct ExternalFight {
        uint256 fightId;
        uint256 beastRepresentation;
        uint16 beastId;
        uint32 bossId;
        uint32 result;
        uint32 rounds;
        bool resolved;
        address wallet;
        bool isResolveAvailable;
    }

    struct Round {
        uint32 beastHp;
        uint32 bossHp;
        bool isCritical;
        bool isDodged;
    }

    struct FightStats {
        uint256 bossHp;
        uint256 bossDamage;
        uint256 beastHp;
        uint256 beastDamage;
        uint256 beastDodge;
        uint256 beastCrit;
    }

    address public beastAddress;
    address public skullAddress;
    address public beastStakerAddress;
    address public randomOracleAddress;

    uint256 private _fightIds;
    uint256 public currentBossId;
    uint32 public availableFights;
    mapping(uint256 => Boss) public bosses;
    mapping(uint256 => Fight) public fights;
    mapping(uint256 => uint256[]) public bossUniqueBeasts;
    mapping(uint256 => mapping(uint256 => uint256)) public beastBestFights; // beastId => bossId => result
    mapping(address => mapping(uint256 => uint256[])) private _walletFightsByBoss;

    function initialize() public initializer {
        __Ownable_init();
    }

    function fight(uint256[] memory beastIds) external {
        require(beastIds.length > 0, "invalid beasts");
        require(availableFights > beastIds.length, "no more fighting");
        availableFights -= uint32(beastIds.length);
        Boss storage currentBoss = bosses[currentBossId];
        IRagnarokERC20(skullAddress).transferFrom(msg.sender, address(this), currentBoss.skullPrice * beastIds.length);

        if (currentBoss.firstFightId == 0) {
            currentBoss.firstFightId = _fightIds;
        }

        for (uint256 index = 0; index < beastIds.length; index++) {
            uint256 beastId = beastIds[index];
            require(IBeastStaker(beastStakerAddress).isOwnerOfBeast(msg.sender, beastId), "not owner");
            _fightIds++;
            _walletFightsByBoss[msg.sender][currentBossId].push(_fightIds);

            uint256 beastRepresentation = IBeast(beastAddress).getBeastRepresentation(beastId);

            Fight memory _fight = Fight({
                beastRepresentation: beastRepresentation,
                requestId: "",
                beastId: uint16(beastId),
                bossId: uint32(currentBossId),
                result: 0,
                rounds: 0,
                resolved: false,
                wallet: msg.sender,
                resolveBlock: block.number + 30
            });

            _fight.requestId = IRandomOracle(randomOracleAddress).requestRandomNumber();
            fights[_fightIds] = _fight;
        }
        currentBoss.lastFightId = _fightIds;
    }

    function resolveFight(uint256 fightId) external {
        _resolveFight(fightId);
    }

    function resolveAll(uint256 bossId) external {
        uint256[] memory fightIds = _walletFightsByBoss[msg.sender][bossId];
        for (uint256 index = 0; index < fightIds.length; index++) {
            _resolveFight(fightIds[index]);
        }
    }

    function _resolveFight(uint256 fightId) internal {
        Fight storage _fight = fights[fightId];
        if (_fight.resolved) return;
        uint256 randomSeed = IRandomOracle(randomOracleAddress).getRandomNumber(_fight.requestId);
        require(randomSeed > 0, "not ready");
        _fight.resolved = true;
        uint32 fightResult = _getFightResult(fightId);
        Fight memory bestFight = fights[beastBestFights[_fight.beastId][_fight.bossId]];
        if (fightResult > bestFight.result) {
            beastBestFights[_fight.beastId][_fight.bossId] = fightId;
            if (bestFight.result == 0) {
                bossUniqueBeasts[_fight.bossId].push(_fight.beastId);
            }
        }
        _fight.result = fightResult;
    }

    function getFightResult(uint256 fightId) external view returns (uint32) {
        require(fights[fightId].resolved, "invalid");
        return fights[fightId].result;
    }

    function getFightRounds(uint256 fightId) external view returns (Round[] memory) {
        (Round[] memory rounds, uint8 roundsCount) = _getFightRounds(fightId);
        Round[] memory tempRounds = new Round[](roundsCount);

        for (uint8 index = 0; index < roundsCount; index++) {
            tempRounds[index] = rounds[index];
        }
        return tempRounds;
    }

    function getBossFights(uint256 bossId) external view returns (ExternalFight[] memory) {
        uint256[] memory fighters = bossUniqueBeasts[bossId];
        ExternalFight[] memory bossFights = new ExternalFight[](fighters.length);
        for (uint256 index = 0; index < fighters.length; index++) {
            uint256 fightId = beastBestFights[fighters[index]][bossId];
            bossFights[index] = _buildExternalFight(fightId);
        }
        return bossFights;
    }

    function getAllBossFights(uint256 bossId) external view returns (ExternalFight[] memory) {
        Boss memory boss = bosses[bossId];
        if (boss.firstFightId == 0) return new ExternalFight[](0);
        uint256 totalFights = boss.lastFightId - boss.firstFightId + 1;
        ExternalFight[] memory bossFights = new ExternalFight[](totalFights);
        for (uint256 index = 0; index < totalFights; index++) {
            bossFights[index] = _buildExternalFight(boss.firstFightId + index);
        }
        return bossFights;
    }

    function getWalletFights(address wallet, uint256 bossId) public view returns (ExternalFight[] memory) {
        uint256[] memory fightIds = _walletFightsByBoss[wallet][bossId];
        ExternalFight[] memory walletFights = new ExternalFight[](fightIds.length);
        for (uint256 index = 0; index < fightIds.length; index++) {
            walletFights[index] = _buildExternalFight(fightIds[index]);
        }
        return walletFights;
    }

    function getCurrentBoss() external view returns (Boss memory) {
        return bosses[currentBossId];
    }

    function _buildExternalFight(uint256 fightId) internal view returns (ExternalFight memory) {
        Fight memory _fight = fights[fightId];
        return
            ExternalFight({
                fightId: fightId,
                beastRepresentation: _fight.beastRepresentation,
                beastId: _fight.beastId,
                bossId: _fight.bossId,
                result: _fight.result,
                rounds: _fight.rounds,
                resolved: _fight.resolved,
                wallet: _fight.wallet,
                isResolveAvailable: block.number > _fight.resolveBlock
            });
    }

    function _getFightRounds(uint256 fightId) internal view returns (Round[] memory, uint8) {
        Fight memory _fight = fights[fightId];
        if (!_fight.resolved) return (new Round[](0), 0);
        uint256 noncedRandom = IRandomOracle(randomOracleAddress).getRandomNumber(_fight.requestId) +
            _fight.beastId +
            _fight.bossId;

        FightStats memory fightStats = _getStats(_fight.beastRepresentation, _fight.bossId);

        Round[] memory tempRounds = new Round[](50);
        uint8 roundIndex;
        tempRounds[roundIndex++] = Round(uint32(fightStats.beastHp), uint32(fightStats.bossHp), false, false);
        bool isCritical;
        bool isDodged;
        while (fightStats.beastHp > 0 && fightStats.bossHp > 0 && roundIndex < 50) {
            (fightStats.beastHp, , isDodged) = _doDamage(
                fightStats.bossDamage,
                fightStats.beastHp,
                fightStats.beastDodge,
                0,
                noncedRandom++
            );
            (fightStats.bossHp, isCritical, ) = _doDamage(
                fightStats.beastDamage,
                fightStats.bossHp,
                0,
                fightStats.beastCrit,
                noncedRandom++
            );
            tempRounds[roundIndex++] = Round(
                uint32(fightStats.beastHp),
                uint32(fightStats.bossHp),
                isCritical,
                isDodged
            );
        }

        return (tempRounds, roundIndex);
    }

    function _getFightResult(uint256 fightId) internal view returns (uint32) {
        (Round[] memory rounds, uint8 roundsCount) = _getFightRounds(fightId);
        Round memory firstRound = rounds[0];
        Round memory finalRound = rounds[roundsCount - 1];
        return finalRound.beastHp + (firstRound.bossHp - finalRound.bossHp);
    }

    function _getStats(uint256 beastRepresentation, uint256 bossId)
        internal
        view
        returns (FightStats memory fightStats)
    {
        SharedLib.Beast memory beast = SharedLib.representationToBeast(beastRepresentation);
        Boss memory boss = bosses[bossId];

        fightStats.bossHp = boss.hp;
        fightStats.beastHp = 100 + (beast.stats.con * 10) + beast.level;
        bool isMagicDamage = _isMagicDamage(beast.faction, beast.class);
        uint256 bossDefense = 100 - (isMagicDamage ? boss.mDefense : boss.pDefense);

        uint256 baseDamageModifier = isMagicDamage
            ? beast.stats.intell + (beast.stats.wis / 2)
            : beast.stats.str + (beast.stats.dex / 2);
        fightStats.beastDamage = (baseDamageModifier) * 5 + beast.level / 2;
        fightStats.beastDamage = (fightStats.beastDamage * bossDefense) / 100;
        fightStats.beastDodge = beast.stats.dex + (beast.level / 9);
        fightStats.beastCrit = beast.stats.dex + beast.stats.wis;

        uint256 beastPDefense = 100 - (beast.stats.con + beast.stats.str);
        uint256 beastMDefense = 100 - (beast.stats.con + beast.stats.intell);
        uint256 bossPDamage = (boss.pAttack * beastPDefense) / 100;
        uint256 bossMDamage = (boss.mAttack * beastMDefense) / 100;
        fightStats.bossDamage = bossPDamage > bossMDamage ? bossPDamage : bossMDamage;
    }

    function _isMagicDamage(uint256 faction, uint256 class) internal pure returns (bool) {
        return (faction == 1 && class == 2) || (faction != 1 && class == 1);
    }

    function _doDamage(
        uint256 damage,
        uint256 hp,
        uint256 dodge,
        uint256 crit,
        uint256 rand
    )
        internal
        view
        returns (
            uint256,
            bool,
            bool
        )
    {
        bool isDodged = _getRandomNumber(rand, hp, 100) < dodge;
        if (isDodged) return (hp, false, true);

        bool isCritical = _getRandomNumber(rand, damage, 100) < crit;
        uint256 finalDamage = isCritical ? damage * 2 : damage;
        if (finalDamage >= hp) {
            return (0, isCritical, false);
        }
        return (hp - finalDamage, isCritical, false);
    }

    function _getRandomNumber(
        uint256 seed,
        uint256 nonce,
        uint256 limit
    ) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, nonce, msg.sender))) % limit;
    }

    // OWNER FUNCTIONS

    function registerBoss(
        uint32 id,
        uint32 hp,
        uint16 pAttack,
        uint16 mAttack,
        uint16 pDefense,
        uint16 mDefense,
        uint256 skullPrice
    ) external onlyOwner {
        bosses[id] = Boss(
            hp,
            pAttack,
            mAttack,
            pDefense,
            mDefense,
            bosses[id].firstFightId,
            bosses[id].lastFightId,
            skullPrice
        );
    }

    function setCurrentBoss(uint32 id, uint32 _availableFights) external onlyOwner {
        require(bosses[id].hp > 0, "invalid boss");
        currentBossId = id;
        availableFights = _availableFights;
    }

    function setAddresses(
        address _beastAddress,
        address _randomOracleAddress,
        address _beastStakerAddress,
        address _skullAddress
    ) external onlyOwner {
        beastAddress = _beastAddress;
        skullAddress = _skullAddress;
        randomOracleAddress = _randomOracleAddress;
        beastStakerAddress = _beastStakerAddress;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity ^0.8.7;

import "../SharedLib.sol";

interface IRagnarokItem {
    function mint(address to, uint16 id) external;

    function mintRandom(
        address to,
        uint16 rarity,
        uint256 randomSeed
    ) external;

    function getItemsByRarity(uint16 rarity) external view returns (uint16[] memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function getItemType(uint16 itemTypeId) external view returns (uint256);
}

interface IRagnarokERC20 {
    function balanceOf(address from) external view returns (uint256 balance);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function mint(address from, uint256 amount) external;

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IFreyjaRelic {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(uint256 id, uint256 amount) external;

    function burnBatch(uint256[] calldata ids, uint256[] memory amounts) external;

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatchFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;
}

interface IBeast {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function transfer(address to, uint256 id) external;

    function ownerOf(uint256 id) external returns (address owner);

    function mint(address to, uint256 tokenid) external;

    function getBeastClassNumberRepresentation(uint256 beastId) external view returns (uint16);

    function giveExperience(uint256 beastId, uint32 experience) external returns (uint256);

    function getBeastRepresentation(uint256 beastId) external view returns (uint256);

    function pull(address owner, uint256[] calldata ids) external;
}

interface IRagnarokConsumable {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;
}

interface IERC721Puller {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface IRandomOracle {
    function getRandomNumber(bytes32 requestId) external view returns (uint256);

    function requestRandomNumber() external returns (bytes32 requestId);
}

interface IBeastStaker {
    function getStakedBeasts(address player) external view returns (uint256[] memory);

    function isOwnerOfBeast(address player, uint256 beastId) external view returns (bool);
}

interface IExperienceTable {
    function getLevelUpExperience(uint8 currentLvl) external pure returns (uint32);

    function getNewBeastLevel(uint8 currentLvl, uint32 newExperience) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SharedLib {
    uint256 public constant FACTIONS = 6;
    uint256 public constant CLASSES = FACTIONS * 2;

    struct Stats {
        uint256 hp;
        uint256 mana;
        uint256 con;
        uint256 str;
        uint256 dex;
        uint256 wis;
        uint256 intell;
    }

    struct TightStats {
        uint16 hp;
        uint16 mana;
        uint8 con;
        uint8 str;
        uint8 dex;
        uint8 wis;
        uint8 intell;
    }

    struct AdditionalStats {
        Stats relic;
        Stats assignment;
    }

    struct Beast {
        uint256 level;
        uint256 experience;
        uint256 faction;
        uint256 class;
        Stats stats;
        uint256 slot0;
        uint256 slot1;
        uint256 slot2;
        uint256 slot3;
    }

    struct TightBeast {
        uint8 level;
        uint32 experience;
        uint8 faction;
        uint8 class;
        uint16 hp;
        uint16 mana;
        uint8 con;
        uint8 str;
        uint8 dex;
        uint8 wis;
        uint8 intell;
        uint16 slot0;
        uint16 slot1;
        uint16 slot2;
        uint16 slot3;
    }

    function statsToRepresentation(Stats memory stats) internal pure returns (uint256) {
        uint256 representation = uint256(stats.hp);
        representation |= stats.mana << 16;
        representation |= stats.con << 32;
        representation |= stats.str << 40;
        representation |= stats.dex << 48;
        representation |= stats.wis << 56;
        representation |= stats.intell << 64;

        return representation;
    }

    function representationToStats(uint256 representation) internal pure returns (Stats memory stats) {
        stats.hp = uint16(representation);
        stats.mana = uint16(representation >> 16);
        stats.con = uint8(representation >> 32);
        stats.str = uint8(representation >> 40);
        stats.dex = uint8(representation >> 48);
        stats.wis = uint8(representation >> 56);
        stats.intell = uint8(representation >> 64);
    }

    function beastToRepresentation(Beast memory beast) internal pure returns (uint256) {
        uint256 representation = uint256(beast.level);
        representation |= beast.experience << 8;
        representation |= beast.faction << 40;
        representation |= beast.class << 48;

        representation |= beast.stats.hp << 56;
        representation |= beast.stats.mana << 72;
        representation |= beast.stats.con << 88;
        representation |= beast.stats.str << 96;
        representation |= beast.stats.dex << 104;
        representation |= beast.stats.wis << 112;
        representation |= beast.stats.intell << 120;
        representation |= beast.slot0 << 136;
        representation |= beast.slot1 << 152;
        representation |= beast.slot2 << 168;
        representation |= beast.slot3 << 184;

        return representation;
    }

    function representationToBeast(uint256 representation) internal pure returns (Beast memory beast) {
        beast.level = uint8(representation);
        beast.experience = uint32(representation >> 8);
        beast.faction = uint8(representation >> 40);
        beast.class = uint8(representation >> 48);
        beast.stats = representationToStats(representation >> 56);
        beast.slot0 = uint16(representation >> 136); // this leaves a uint8 empty slot
        beast.slot1 = uint16(representation >> 152);
        beast.slot2 = uint16(representation >> 168);
        beast.slot3 = uint16(representation >> 184);
    }

    function additionalStatsToRepresentation(AdditionalStats memory additionalStats) internal pure returns (uint256) {
        uint256 representation = uint256(statsToRepresentation(additionalStats.relic));
        representation |= statsToRepresentation(additionalStats.assignment) << 72;

        return representation;
    }

    function representationToAdditionalStats(uint256 representation)
        internal
        pure
        returns (AdditionalStats memory additionalStats)
    {
        additionalStats.relic = representationToStats(representation);
        additionalStats.assignment = representationToStats(representation >> 72);
    }

    struct ItemType {
        uint256 rarity;
        uint256 levelRequirement;
        uint256 con;
        uint256 str;
        uint256 dex;
        uint256 wis;
        uint256 intell;
        uint256[4] slots;
        uint256[6] classes;
    }
    struct TightItemType {
        uint8 rarity;
        uint8 levelRequirement;
        uint8 con;
        uint8 str;
        uint8 dex;
        uint8 wis;
        uint8 intell;
        uint8[4] slots;
        uint8[6] classes;
    }

    function itemTypeToRepresentation(ItemType memory itemType) internal pure returns (uint256) {
        uint256 representation = uint256(itemType.rarity);
        representation |= itemType.levelRequirement << 8;
        representation |= itemType.con << 16;
        representation |= itemType.str << 32;
        representation |= itemType.dex << 40;
        representation |= itemType.wis << 48;
        representation |= itemType.intell << 56;
        uint8 lastPosition = 56;
        for (uint256 index = 0; index < 4; index++) {
            lastPosition += 8;
            representation |= itemType.slots[index] << lastPosition;
        }
        for (uint256 index = 0; index < 6; index++) {
            lastPosition += 8;
            representation |= itemType.classes[index] << lastPosition;
        }

        return representation;
    }

    function itemTypeToStats(ItemType memory itemType) internal pure returns (Stats memory stats) {
        stats.con = itemType.con;
        stats.str = itemType.str;
        stats.dex = itemType.dex;
        stats.wis = itemType.wis;
        stats.intell = itemType.intell;
    }

    function representationToItemType(uint256 representation) internal pure returns (ItemType memory itemType) {
        itemType.rarity = uint8(representation);
        itemType.levelRequirement = uint8(representation >> 8);
        itemType.con = uint8(representation >> 16);
        itemType.str = uint8(representation >> 32);
        itemType.dex = uint8(representation >> 40);
        itemType.wis = uint8(representation >> 48);
        itemType.intell = uint8(representation >> 56);
        uint8 lastPosition = 56;
        for (uint256 index = 0; index < 4; index++) {
            lastPosition += 8;
            itemType.slots[index] = uint8(representation >> lastPosition);
        }
        for (uint256 index = 0; index < 6; index++) {
            lastPosition += 8;
            itemType.classes[index] = uint8(representation >> lastPosition);
        }
    }

    function classToNumberRepresentation(uint8 faction, uint8 class) internal pure returns (uint8) {
        if (class == 0) {
            return 0;
        }
        return uint8(faction * FACTIONS + class);
    }

    function numberRepresentationToFaction(uint16 numberRepresentation) internal pure returns (uint8) {
        return uint8(numberRepresentation / FACTIONS);
    }

    function numberRepresentationToClass(uint8 numberRepresentation) internal pure returns (uint8) {
        return uint8(numberRepresentation % FACTIONS);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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